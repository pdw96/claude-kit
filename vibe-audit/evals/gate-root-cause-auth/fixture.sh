#!/usr/bin/env bash
# 밖에서 보이는 권한 실패(ID 만 맞으면 남의 송장이 나온다)의 뿌리가 스키마에 있다 —
# invoices 에 소유 회사 열이 없어 라우트가 확인할 것이 없다. 실패는 audit-secrets,
# 모델이 옳은가는 audit-data.
# 대조군(모호함 없는 진짜 NC): JWT 서명을 검증하지 않는다.
set -euo pipefail
mkdir -p app migrations docs

cat > app/models.py <<'PY'
import sqlalchemy as sa
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id = sa.Column(sa.Integer, primary_key=True)
    company_id = sa.Column(sa.Integer, nullable=False)
    email = sa.Column(sa.String(255), nullable=False, unique=True)


class Invoice(Base):
    __tablename__ = "invoices"

    id = sa.Column(sa.Integer, primary_key=True)
    number = sa.Column(sa.String(32), nullable=False, unique=True)
    customer_name = sa.Column(sa.String(128), nullable=False)
    amount = sa.Column(sa.Numeric(12, 2), nullable=False)
PY

cat > migrations/0003_invoices.py <<'PY'
"""송장 표를 만든다"""

import sqlalchemy as sa
from alembic import op

revision = "0003"
down_revision = "0002"


def upgrade():
    op.create_table(
        "invoices",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("number", sa.String(32), nullable=False, unique=True),
        sa.Column("customer_name", sa.String(128), nullable=False),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
    )


def downgrade():
    op.drop_table("invoices")
PY

cat > app/auth.py <<'PY'
import jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer

from .db import session
from .models import User

bearer = HTTPBearer()


def current_user(cred=Depends(bearer)) -> User:
    try:
        claims = jwt.decode(cred.credentials, options={"verify_signature": False})
    except jwt.PyJWTError:
        raise HTTPException(status_code=401)
    user = session.get(User, int(claims["sub"]))
    if user is None:
        raise HTTPException(status_code=401)
    return user
PY

cat > app/routes.py <<'PY'
from fastapi import APIRouter, Depends, HTTPException

from .auth import current_user
from .db import session
from .models import Invoice

router = APIRouter()


@router.get("/invoices/{invoice_id}")
def read_invoice(invoice_id: int, user=Depends(current_user)):
    # 회사별로 거르는 것은 invoices 에 company_id 가 생기면 붙인다
    invoice = session.get(Invoice, invoice_id)
    if invoice is None:
        raise HTTPException(status_code=404)
    return {"number": invoice.number, "customer": invoice.customer_name, "amount": str(invoice.amount)}
PY

cat > app/db.py <<'PY'
import os

from sqlalchemy import create_engine
from sqlalchemy.orm import Session

engine = create_engine(os.environ["DATABASE_URL"])
session = Session(engine)
PY

cat > docs/schema.md <<'MD'
# 스키마

여러 회사가 한 서비스를 쓴다. 사용자는 한 회사에 속한다(`users.company_id`).
송장(`invoices`)은 회사가 고객에게 내는 청구서다.
MD
