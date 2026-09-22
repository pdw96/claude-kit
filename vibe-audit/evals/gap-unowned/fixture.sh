#!/usr/bin/env bash
# 주인 없는 결함 둘과 담당인 결함 하나를 함께 둔다.
#
# (b) 여섯 어디에도 언급조차 없는 것 — 의존성 공급망
# (a) 「보지 않는 것」에 적혀 있으나 담당이 없는 것 — 성능
# 대조군 — audit-secrets 담당인 무인증 라우트
set -euo pipefail
mkdir -p app

cat > requirements.txt <<'EOF'
fastapi
requests>=2.0
pyyaml
sqlalchemy>=1.4
cryptography
EOF

cat > Dockerfile <<'EOF'
FROM python:latest

WORKDIR /srv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0"]
EOF

cat > app/report.py <<'EOF'
def monthly_report(session, year, month):
    orders = session.query(Order).filter_by(year=year, month=month).all()
    rows = []
    for o in orders:
        user = session.query(User).get(o.user_id)
        items = session.query(OrderItem).filter_by(order_id=o.id).all()
        for it in items:
            sku = session.query(Sku).get(it.sku_id)
            rows.append((user.name, sku.name, it.qty))
    return rows
EOF

cat > app/routes.py <<'EOF'
from fastapi import APIRouter, Depends

from .auth import current_user, require_admin

router = APIRouter()


@router.get("/orders")
def list_orders(user=Depends(current_user)):
    return db.orders.for_user(user.id)


@router.get("/admin/settings")
def admin_settings(user=Depends(require_admin)):
    return db.settings.all()


@router.get("/admin/export")
def admin_export():
    return db.everything.dump()
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
    year = sa.Column(sa.Integer, nullable=False)
    month = sa.Column(sa.Integer, nullable=False)
EOF

cat > CLAUDE.md <<'EOF'
# 규칙

- 스택: Python 3.12 · FastAPI · SQLAlchemy 2.x · PostgreSQL
- **금지**: 마이그레이션 없는 스키마 변경, 코드에 박힌 시크릿, 권한 우회 임시 코드
EOF
