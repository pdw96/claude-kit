#!/usr/bin/env bash
# 회원권 신청을 직원이 승인하면 회원권이 선다. 기준 데이터(시드)가 만료일을 세는 법을 적어 두었다.
# 실제 저장소에서 옮긴 결함이다 — 출처는 case.yaml. 다른 결함을 일부러 심지 않는다.
set -euo pipefail
mkdir -p app/services migrations seed docs

cat > requirements.txt <<'EOF'
FastAPI==0.141.1
SQLAlchemy==2.0.36
psycopg[binary]==3.2.3
alembic==1.14.0
EOF

cat > docs/schema.md <<'EOF'
# 데이터 모델

| 표 | 무엇 |
|---|---|
| `plans` | 회원권 종류. 기간(일)과 값. 기준 데이터라 `seed/plans.sql` 이 심는다 |
| `applications` | 회원이 낸 신청. `applied_on` 은 회원이 창구에 온 날이다 |
| `memberships` | 승인된 회원권. `valid_until` 이 지나면 출입 단말이 막는다 |

승인은 신청 다음 날이나 그 뒤에 직원이 몰아서 한다 — 주말 신청은 월요일에 승인된다.
EOF

cat > seed/plans.sql <<'EOF'
-- 회원권 종류. 이 표의 description 은 화면의 안내 문구로도 나간다.
INSERT INTO plans (code, name, duration_days, price, description) VALUES
  ('M1',  '1개월',  30, 70000,  '신청일로부터 30일. 만료일은 신청일 + 기간에서 시스템이 계산해 단다.'),
  ('M3',  '3개월',  90, 180000, '신청일로부터 90일. 만료일은 신청일 + 기간에서 시스템이 계산해 단다.'),
  ('M12', '12개월', 365, 600000, '신청일로부터 365일. 만료일은 신청일 + 기간에서 시스템이 계산해 단다.');
EOF

cat > app/__init__.py <<'EOF'
EOF
cat > app/services/__init__.py <<'EOF'
EOF

cat > app/models.py <<'EOF'
import sqlalchemy as sa
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class Plan(Base):
    __tablename__ = "plans"

    code = sa.Column(sa.String(10), primary_key=True)
    name = sa.Column(sa.String(50), nullable=False)
    duration_days = sa.Column(sa.Integer, nullable=False)
    price = sa.Column(sa.Integer, nullable=False)
    description = sa.Column(sa.String(200), nullable=False)


class Application(Base):
    __tablename__ = "applications"

    id = sa.Column(sa.Integer, primary_key=True)
    member_id = sa.Column(sa.Integer, nullable=False)
    plan_code = sa.Column(sa.ForeignKey("plans.code"), nullable=False)
    applied_on = sa.Column(sa.Date, nullable=False)
    status = sa.Column(sa.String(10), nullable=False, server_default="pending")


class Membership(Base):
    __tablename__ = "memberships"
    __table_args__ = (sa.CheckConstraint("valid_until > starts_on", name="memberships_period"),)

    id = sa.Column(sa.Integer, primary_key=True)
    application_id = sa.Column(sa.ForeignKey("applications.id"), nullable=False, unique=True)
    member_id = sa.Column(sa.Integer, nullable=False)
    starts_on = sa.Column(sa.Date, nullable=False)
    valid_until = sa.Column(sa.Date, nullable=False)
    approved_at = sa.Column(sa.DateTime(timezone=True), nullable=False)
    approved_by = sa.Column(sa.String(50), nullable=False)
EOF

cat > app/services/memberships.py <<'EOF'
"""신청을 승인해 회원권을 세운다."""

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from app.models import Application, Membership, Plan


class RefusedApproval(Exception):
    pass


@dataclass(frozen=True)
class Approved:
    membership_id: int
    valid_until: str


def approve(session: Session, application_id: int, approved_by: str) -> Approved:
    application = session.get(Application, application_id)
    if application is None:
        raise RefusedApproval(f"없는 신청이다: {application_id}")
    if application.status != "pending":
        raise RefusedApproval(f"이미 처리한 신청이다: {application_id}")
    plan = session.get(Plan, application.plan_code)

    approved_at = datetime.now(timezone.utc)
    starts_on = approved_at.date()
    membership = Membership(
        application_id=application.id,
        member_id=application.member_id,
        starts_on=starts_on,
        valid_until=starts_on + timedelta(days=plan.duration_days),
        approved_at=approved_at,
        approved_by=approved_by,
    )
    application.status = "approved"
    session.add(membership)
    session.flush()
    return Approved(membership_id=membership.id, valid_until=membership.valid_until.isoformat())
EOF

cat > app/main.py <<'EOF'
from collections.abc import Iterator
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.services.memberships import Approved, RefusedApproval, approve

app = FastAPI(title="체육관 — 회원권")
_sessions = sessionmaker(bind=create_engine("postgresql+psycopg://gym@localhost/gym"))


def session() -> Iterator[Session]:
    s = _sessions()
    try:
        yield s
    finally:
        s.close()


class ApprovalIn(BaseModel):
    approved_by: str = Field(min_length=1, max_length=50)


@app.post("/applications/{application_id}/approval", status_code=status.HTTP_201_CREATED)
def post_approval(application_id: int, payload: ApprovalIn, s: Annotated[Session, Depends(session)]) -> Approved:
    try:
        done = approve(s, application_id, payload.approved_by)
    except RefusedApproval as refused:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=str(refused)) from refused
    s.commit()
    return done
EOF

cat > migrations/0001_memberships.py <<'EOF'
"""회원권 종류 · 신청 · 회원권"""

import sqlalchemy as sa
from alembic import op

revision = "0001"
down_revision = None


def upgrade():
    op.create_table(
        "plans",
        sa.Column("code", sa.String(10), primary_key=True),
        sa.Column("name", sa.String(50), nullable=False),
        sa.Column("duration_days", sa.Integer, nullable=False),
        sa.Column("price", sa.Integer, nullable=False),
        sa.Column("description", sa.String(200), nullable=False),
    )
    op.create_table(
        "applications",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("member_id", sa.Integer, nullable=False),
        sa.Column("plan_code", sa.ForeignKey("plans.code"), nullable=False),
        sa.Column("applied_on", sa.Date, nullable=False),
        sa.Column("status", sa.String(10), nullable=False, server_default="pending"),
    )
    op.create_table(
        "memberships",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("application_id", sa.ForeignKey("applications.id"), nullable=False, unique=True),
        sa.Column("member_id", sa.Integer, nullable=False),
        sa.Column("starts_on", sa.Date, nullable=False),
        sa.Column("valid_until", sa.Date, nullable=False),
        sa.Column("approved_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("approved_by", sa.String(50), nullable=False),
        sa.CheckConstraint("valid_until > starts_on", name="memberships_period"),
    )


def downgrade():
    bind = op.get_bind()
    if bind.execute(sa.text("SELECT EXISTS (SELECT 1 FROM memberships)")).scalar():
        raise RuntimeError("회원권이 있어 되돌리지 않는다")
    op.drop_table("memberships")
    op.drop_table("applications")
    op.drop_table("plans")
EOF
