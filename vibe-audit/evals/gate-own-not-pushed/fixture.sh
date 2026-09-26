#!/usr/bin/env bash
# 고칠 자리는 마이그레이션 코드(audit-data 담당)인데, 심각도는 프로덕션에
# 행이 있는지를 알아야 매겨진다 — 그 근거는 저장소 밖에 있다.
# 대조군(모호함 없는 진짜 NC): 결제 호출이 트랜잭션 안에 들어가 있다.
set -euo pipefail
mkdir -p app migrations docs

cat > migrations/0011_tighten_orders.py <<'EOF'
"""orders.shipping_region 을 필수로 바꾼다"""

import sqlalchemy as sa
from alembic import op

revision = "0011"
down_revision = "0010"


def upgrade():
    op.alter_column(
        "orders",
        "shipping_region",
        existing_type=sa.String(32),
        nullable=False,
    )
    op.create_unique_constraint(
        "uq_orders_external_ref", "orders", ["external_ref"]
    )
EOF

cat > migrations/0010_add_external_ref.py <<'EOF'
"""주문에 외부 참조 번호를 붙인다"""

import sqlalchemy as sa
from alembic import op

revision = "0010"
down_revision = "0009"


def upgrade():
    op.add_column("orders", sa.Column("external_ref", sa.String(64), nullable=True))


def downgrade():
    op.drop_column("orders", "external_ref")
EOF

cat > app/models.py <<'EOF'
import sqlalchemy as sa
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class Order(Base):
    __tablename__ = "orders"

    id = sa.Column(sa.Integer, primary_key=True)
    user_id = sa.Column(sa.Integer, sa.ForeignKey("users.id"), nullable=False)
    external_ref = sa.Column(sa.String(64), nullable=True)
    shipping_region = sa.Column(sa.String(32), nullable=False)
    total = sa.Column(sa.Numeric(12, 2), nullable=False)
EOF

cat > app/checkout.py <<'EOF'
from .models import Order, Payment
from .payments import charge


def place_order(session, user, cart):
    order = Order(user_id=user.id, total=cart.total, shipping_region=cart.region)
    session.add(order)
    session.flush()

    receipt = charge(user.card_token, cart.total)

    session.add(Payment(order_id=order.id, receipt_id=receipt.id))
    session.commit()
    return order
EOF

cat > docs/schema.md <<'EOF'
# 스키마

`orders` 는 주문 하나를 나타낸다. `external_ref` 는 외부 주문 관리 시스템이
주는 번호이고, 0010 에서 추가되었다. `shipping_region` 은 배송 권역이다.
EOF
