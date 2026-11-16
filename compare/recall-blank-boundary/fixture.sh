#!/usr/bin/env bash
# 진료 예약 한 건을 받는 쓰기 엔드포인트. 경계(pydantic)는 길이만 보고, 데이터베이스의 CHECK 는 공백만인 값을 막는다.
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
# 공개 계약 — 예약

`POST /appointments` 는 예약 한 건을 받는다.

| 응답 | 언제 |
|---|---|
| 201 | 예약이 섰다. 본문은 예약 번호 |
| 422 | 받을 수 없는 요청 — 본문의 `detail` 이 칸과 까닭을 말한다 |

**받을 수 없는 요청은 422 로 돌려보낸다.** 부르는 쪽(접수 창구 화면)은 422 의 `detail` 을 그대로 보여 주고
고쳐 다시 보내게 한다. 500 은 서버의 잘못이라 창구 직원이 고칠 수 없다.
EOF

cat > app/__init__.py <<'EOF'
EOF

cat > app/constraints.py <<'EOF'
"""제약에 쓰는 식 — 모델과 마이그레이션이 같은 것을 부른다."""

# `btrim` 의 기본은 스페이스만 깎는다. 탭도 전각 공백도 남으므로 깎을 문자를 적는다.
# 스페이스 · 탭 · 개행 · 복귀 · 전각 공백 · 줄바꿈 없는 공백.
BLANK_CHARACTERS = " \\t\\n\\r\\u3000\\u00a0"


def is_present(column: str) -> str:
    """그 칸이 공백만으로 이루어지지 않았는가."""
    return f"btrim({column}, E'{BLANK_CHARACTERS}') <> ''"
EOF

cat > app/models.py <<'EOF'
import sqlalchemy as sa
from sqlalchemy.orm import DeclarativeBase

from app.constraints import is_present


class Base(DeclarativeBase):
    pass


class Appointment(Base):
    __tablename__ = "appointments"
    __table_args__ = (
        sa.CheckConstraint(is_present("patient_name"), name="appointments_patient_name_present"),
        sa.CheckConstraint(is_present("department"), name="appointments_department_present"),
        sa.CheckConstraint(is_present("phone"), name="appointments_phone_present"),
    )

    id = sa.Column(sa.Integer, primary_key=True)
    patient_name = sa.Column(sa.String(50), nullable=False)
    department = sa.Column(sa.String(30), nullable=False)
    phone = sa.Column(sa.String(20), nullable=False)
    visit_on = sa.Column(sa.Date, nullable=False)
    memo = sa.Column(sa.String(200), nullable=True)
EOF

cat > migrations/0001_appointments.py <<'EOF'
"""예약 표"""

import sqlalchemy as sa
from alembic import op

from app.constraints import is_present

revision = "0001"
down_revision = None


def upgrade():
    op.create_table(
        "appointments",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("patient_name", sa.String(50), nullable=False),
        sa.Column("department", sa.String(30), nullable=False),
        sa.Column("phone", sa.String(20), nullable=False),
        sa.Column("visit_on", sa.Date, nullable=False),
        sa.Column("memo", sa.String(200), nullable=True),
        sa.CheckConstraint(is_present("patient_name"), name="appointments_patient_name_present"),
        sa.CheckConstraint(is_present("department"), name="appointments_department_present"),
        sa.CheckConstraint(is_present("phone"), name="appointments_phone_present"),
    )


def downgrade():
    bind = op.get_bind()
    if bind.execute(sa.text("SELECT EXISTS (SELECT 1 FROM appointments)")).scalar():
        raise RuntimeError("예약이 있어 되돌리지 않는다")
    op.drop_table("appointments")
EOF

cat > app/schemas.py <<'EOF'
from datetime import date

from pydantic import BaseModel, Field


class AppointmentIn(BaseModel):
    patient_name: str = Field(min_length=1, max_length=50)
    department: str = Field(min_length=1, max_length=30)
    phone: str = Field(min_length=1, max_length=20, pattern=r"^[0-9\- ]+$")
    visit_on: date
    memo: str | None = Field(default=None, max_length=200)


class AppointmentOut(BaseModel):
    appointment_id: int
EOF

cat > app/main.py <<'EOF'
"""쓰기 엔드포인트 — 예약 한 건."""

from collections.abc import Iterator
from datetime import date
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, status
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.models import Appointment
from app.schemas import AppointmentIn, AppointmentOut

app = FastAPI(title="병원 — 예약")
_sessions = sessionmaker(bind=create_engine("postgresql+psycopg://clinic@localhost/clinic"))


def session() -> Iterator[Session]:
    s = _sessions()
    try:
        yield s
    finally:
        s.close()


@app.post("/appointments", response_model=AppointmentOut, status_code=status.HTTP_201_CREATED)
def post_appointment(payload: AppointmentIn, s: Annotated[Session, Depends(session)]) -> AppointmentOut:
    if payload.visit_on < date.today():
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail="지난 날짜로는 예약하지 않는다")
    row = Appointment(**payload.model_dump())
    s.add(row)
    s.commit()
    return AppointmentOut(appointment_id=row.id)
EOF
