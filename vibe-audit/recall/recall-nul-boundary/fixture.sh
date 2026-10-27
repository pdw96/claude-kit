#!/usr/bin/env bash
# 행사 참가 신청을 받는 공개 쓰기 엔드포인트. 경계가 문자열 칸을 검증하고 PostgreSQL text 칸에 넣는다.
# 실제 저장소에서 옮긴 결함이다 — 출처는 case.yaml. 다른 결함을 일부러 심지 않는다.
set -euo pipefail
mkdir -p app migrations docs

cat > requirements.txt <<'EOF'
FastAPI==0.141.1
starlette==1.6.0
SQLAlchemy==2.0.36
psycopg[binary]==3.2.3
alembic==1.14.0
EOF

cat > docs/api.md <<'EOF'
# 공개 계약 — 참가 신청

`POST /registrations` 는 참가 신청 한 건을 받는다. 데이터베이스는 PostgreSQL 이다.

| 응답 | 언제 |
|---|---|
| 201 | 신청이 섰다 |
| 422 | 받을 수 없는 요청 — `detail` 이 칸과 까닭을 말한다 |

받을 수 없는 요청은 경계에서 422 로 돌려보낸다. 경계를 지난 요청은 저장된다.
EOF

cat > app/__init__.py <<'EOF'
EOF

cat > app/models.py <<'EOF'
import sqlalchemy as sa
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class Registration(Base):
    __tablename__ = "registrations"

    id = sa.Column(sa.Integer, primary_key=True)
    event_code = sa.Column(sa.Text, nullable=False)
    attendee_name = sa.Column(sa.Text, nullable=False)
    organization = sa.Column(sa.Text, nullable=True)
    note = sa.Column(sa.Text, nullable=True)
EOF

cat > migrations/0001_registrations.py <<'EOF'
"""참가 신청 표"""

import sqlalchemy as sa
from alembic import op

revision = "0001"
down_revision = None


def upgrade():
    op.create_table(
        "registrations",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("event_code", sa.Text, nullable=False),
        sa.Column("attendee_name", sa.Text, nullable=False),
        sa.Column("organization", sa.Text, nullable=True),
        sa.Column("note", sa.Text, nullable=True),
    )


def downgrade():
    bind = op.get_bind()
    if bind.execute(sa.text("SELECT EXISTS (SELECT 1 FROM registrations)")).scalar():
        raise RuntimeError("신청이 있어 되돌리지 않는다")
    op.drop_table("registrations")
EOF

cat > app/schemas.py <<'EOF'
"""경계 — 받을 수 없는 값은 여기서 이름을 말하고 돌려보낸다."""

from typing import Annotated

from pydantic import AfterValidator, BaseModel, Field

# 눈에는 비어 보이는 값 — 스페이스 · 탭 · 개행 · 복귀 · 전각 공백 · 줄바꿈 없는 공백.
_BLANK = " \t\n\r　 "


def _present(value: str) -> str:
    """공백만인 값을 거른다. 데이터베이스까지 가면 이름 없는 실패가 된다."""
    if not value.strip(_BLANK):
        raise ValueError("비어 있다")
    return value


Present = Annotated[str, AfterValidator(_present)]


class RegistrationIn(BaseModel):
    event_code: Present = Field(min_length=1, max_length=20)
    attendee_name: Present = Field(min_length=1, max_length=50)
    organization: Present | None = Field(default=None, max_length=100)
    note: str | None = Field(default=None, max_length=500)


class RegistrationOut(BaseModel):
    registration_id: int
EOF

cat > app/main.py <<'EOF'
"""쓰기 엔드포인트 — 참가 신청 한 건."""

from collections.abc import Iterator
from typing import Annotated

from fastapi import Depends, FastAPI, status
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.models import Registration
from app.schemas import RegistrationIn, RegistrationOut

app = FastAPI(title="행사 — 참가 신청")
_sessions = sessionmaker(bind=create_engine("postgresql+psycopg://events@localhost/events"))


def session() -> Iterator[Session]:
    s = _sessions()
    try:
        yield s
    finally:
        s.close()


@app.post("/registrations", response_model=RegistrationOut, status_code=status.HTTP_201_CREATED)
def post_registration(payload: RegistrationIn, s: Annotated[Session, Depends(session)]) -> RegistrationOut:
    row = Registration(**payload.model_dump())
    s.add(row)
    s.commit()
    return RegistrationOut(registration_id=row.id)
EOF
