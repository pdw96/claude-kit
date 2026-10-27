#!/usr/bin/env bash
# 주문 한 건의 환불을 세우는 쓰기 경로. 환불 방식과 사유는 공통코드에서 고른다.
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
| `common_codes` | 공통코드 — 그룹(`REFUND_METHOD` · `REFUND_REASON`)과 코드 |
| `orders` | 주문 |
| `refunds` | 환불 한 건. 방식과 사유는 공통코드를 가리킨다 |

## 원칙

1. **일어난 일은 지우지 않는다.** 환불은 고치지 않고 되돌리는 환불을 새로 세운다.
2. **공통코드는 지우지 않는다** — `common_codes` 의 독스트링.
EOF

cat > seed/codes.sql <<'EOF'
INSERT INTO common_codes (group_code, code, name, is_active) VALUES
  ('REFUND_METHOD', 'CARD',    '카드 취소',     TRUE),
  ('REFUND_METHOD', 'ACCOUNT', '계좌 입금',     TRUE),
  ('REFUND_METHOD', 'POINT',   '적립금',        FALSE),
  ('REFUND_REASON', 'DAMAGED', '파손',          TRUE),
  ('REFUND_REASON', 'WRONG',   '오배송',        TRUE),
  ('REFUND_REASON', 'CHANGE',  '단순 변심',     TRUE),
  ('REFUND_REASON', 'PROMO',   '행사 보상',     FALSE);
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


class CommonCode(Base):
    """공통코드 한 줄.

    **삭제 칸이 없다.** 지우면 그 코드로 적힌 과거 기록이 뜻을 잃으므로, 지우는 대신 `is_active` 를 끈다 —
    새 기록에서는 못 고르고 옛 기록에서는 읽힌다.
    """

    __tablename__ = "common_codes"

    group_code = sa.Column(sa.String(30), primary_key=True)
    code = sa.Column(sa.String(30), primary_key=True)
    name = sa.Column(sa.String(100), nullable=False)
    # 삭제 대신 이것을 끈다.
    is_active = sa.Column(sa.Boolean, nullable=False, server_default=sa.true())


class Order(Base):
    __tablename__ = "orders"

    id = sa.Column(sa.Integer, primary_key=True)
    amount = sa.Column(sa.Integer, nullable=False)
    refunded = sa.Column(sa.Integer, nullable=False, server_default="0")


class Refund(Base):
    __tablename__ = "refunds"
    __table_args__ = (
        sa.ForeignKeyConstraint(["method_group", "method"], ["common_codes.group_code", "common_codes.code"]),
        sa.ForeignKeyConstraint(["reason_group", "reason"], ["common_codes.group_code", "common_codes.code"]),
        sa.CheckConstraint("method_group = 'REFUND_METHOD'", name="refunds_method_group"),
        sa.CheckConstraint("reason_group = 'REFUND_REASON'", name="refunds_reason_group"),
        sa.CheckConstraint("amount > 0", name="refunds_amount_positive"),
    )

    id = sa.Column(sa.Integer, primary_key=True)
    order_id = sa.Column(sa.ForeignKey("orders.id"), nullable=False)
    amount = sa.Column(sa.Integer, nullable=False)
    method_group = sa.Column(sa.String(30), nullable=False, server_default="REFUND_METHOD")
    method = sa.Column(sa.String(30), nullable=False)
    reason_group = sa.Column(sa.String(30), nullable=False, server_default="REFUND_REASON")
    reason = sa.Column(sa.String(30), nullable=False)
EOF

cat > app/services/refunds.py <<'EOF'
"""환불 한 건을 세운다."""

from dataclasses import dataclass

from sqlalchemy.orm import Session

from app.models import CommonCode, Order, Refund


class RefusedRefund(Exception):
    pass


@dataclass(frozen=True)
class RefundRequest:
    order_id: int
    amount: int
    method: str
    reason: str


def _must_be_a_code(session: Session, group: str, code: str) -> None:
    if session.get(CommonCode, (group, code)) is None:
        raise RefusedRefund(f"그런 코드가 없다: {group}.{code}")


def refund(session: Session, request: RefundRequest) -> int:
    order = session.get(Order, request.order_id, with_for_update=True)
    if order is None:
        raise RefusedRefund(f"없는 주문이다: {request.order_id}")
    _must_be_a_code(session, "REFUND_METHOD", request.method)
    _must_be_a_code(session, "REFUND_REASON", request.reason)
    if request.amount <= 0 or order.refunded + request.amount > order.amount:
        raise RefusedRefund(f"환불할 수 있는 금액을 넘는다: {request.amount}")

    order.refunded += request.amount
    row = Refund(order_id=order.id, amount=request.amount, method=request.method, reason=request.reason)
    session.add(row)
    session.flush()
    return row.id
EOF

cat > app/main.py <<'EOF'
from collections.abc import Iterator
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.services.refunds import RefundRequest, RefusedRefund, refund

app = FastAPI(title="쇼핑몰 — 환불")
_sessions = sessionmaker(bind=create_engine("postgresql+psycopg://shop@localhost/shop"))


def session() -> Iterator[Session]:
    s = _sessions()
    try:
        yield s
    finally:
        s.close()


class RefundIn(BaseModel):
    amount: int = Field(gt=0)
    method: str = Field(min_length=1, max_length=30)
    reason: str = Field(min_length=1, max_length=30)


@app.post("/orders/{order_id}/refunds", status_code=status.HTTP_201_CREATED)
def post_refund(order_id: int, payload: RefundIn, s: Annotated[Session, Depends(session)]) -> dict:
    try:
        refund_id = refund(s, RefundRequest(order_id=order_id, **payload.model_dump()))
    except RefusedRefund as refused:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=str(refused)) from refused
    s.commit()
    return {"refund_id": refund_id}
EOF

cat > migrations/0001_refunds.py <<'EOF'
"""공통코드 · 주문 · 환불"""

import sqlalchemy as sa
from alembic import op

revision = "0001"
down_revision = None


def upgrade():
    op.create_table(
        "common_codes",
        sa.Column("group_code", sa.String(30), primary_key=True),
        sa.Column("code", sa.String(30), primary_key=True),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.true()),
    )
    op.create_table(
        "orders",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("amount", sa.Integer, nullable=False),
        sa.Column("refunded", sa.Integer, nullable=False, server_default="0"),
    )
    op.create_table(
        "refunds",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("order_id", sa.ForeignKey("orders.id"), nullable=False),
        sa.Column("amount", sa.Integer, nullable=False),
        sa.Column("method_group", sa.String(30), nullable=False, server_default="REFUND_METHOD"),
        sa.Column("method", sa.String(30), nullable=False),
        sa.Column("reason_group", sa.String(30), nullable=False, server_default="REFUND_REASON"),
        sa.Column("reason", sa.String(30), nullable=False),
        sa.ForeignKeyConstraint(["method_group", "method"], ["common_codes.group_code", "common_codes.code"]),
        sa.ForeignKeyConstraint(["reason_group", "reason"], ["common_codes.group_code", "common_codes.code"]),
        sa.CheckConstraint("method_group = 'REFUND_METHOD'", name="refunds_method_group"),
        sa.CheckConstraint("reason_group = 'REFUND_REASON'", name="refunds_reason_group"),
        sa.CheckConstraint("amount > 0", name="refunds_amount_positive"),
    )


def downgrade():
    bind = op.get_bind()
    if bind.execute(sa.text("SELECT EXISTS (SELECT 1 FROM refunds)")).scalar():
        raise RuntimeError("환불 기록이 있어 되돌리지 않는다")
    op.drop_table("refunds")
    op.drop_table("orders")
    op.drop_table("common_codes")
EOF
