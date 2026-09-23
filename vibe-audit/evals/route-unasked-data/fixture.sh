#!/usr/bin/env bash
set -euo pipefail
mkdir -p app migrations
cat > migrations/0012_add_order_status.py <<'EOF'
def upgrade(op):
    op.add_column("orders", "status", "varchar(20)", nullable=False)


def downgrade(op):
    pass
EOF
cat > app/orders.py <<'EOF'
def create_order(user_id: int, items):
    order = db.orders.insert(user_id=user_id, status="pending")
    for sku, qty in items:
        db.stock.decrement(sku, qty)
    return order
EOF
