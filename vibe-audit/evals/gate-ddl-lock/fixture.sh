#!/usr/bin/env bash
# 엔진을 모른다 — 0013 은 운영 중인 orders 에 인덱스와 CHECK 를 건다. 잠그는지는 엔진과
# 판에 달렸는데(PostgreSQL 은 동시 생성 없는 인덱스 · NOT VALID 없는 CHECK 가 쓰기를 막고,
# 다른 엔진 · 판은 다르다), 저장소 어디에도 엔진이 적혀 있지 않다 — 접속 URL 은 환경변수다.
# 새 문구: 엔진 · 판을 확인하지 못하면 잠금 판정은 확인불가. 옛 문구에는 이 규칙이 없어
# 흔한 엔진을 가정하고 부적합을 단정하거나, 「통과한다」로 적합을 낸다.
# 대조군(모호함 없는 진짜 NC): 0012 가 컬럼을 지우는데 downgrade 가 pass 이고 되돌릴 수
# 없다는 표시도 없다.
set -euo pipefail
mkdir -p app migrations/versions

cat > CLAUDE.md <<'MD'
# 주문 서비스 작업 규칙

## 스택
- Python 3.12 · FastAPI · SQLAlchemy 2.0 · Alembic
- DB 접속은 `DATABASE_URL` 환경변수로 받는다

## 작업 방식
- 스키마 변경은 Alembic 리비전으로만 한다
MD

cat > PRD.md <<'MD'
# 주문 서비스

## 현재
운영 중이다. 주문은 하루 종일 들어오고, 점검 시간을 따로 두지 않는다.

## 하지 않을 일
- 다중 통화
MD

cat > alembic.ini <<'INI'
[alembic]
script_location = migrations
sqlalchemy.url = ${DATABASE_URL}
INI

cat > app/models.py <<'PY'
from sqlalchemy import Column, Integer, Numeric, String
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class Order(Base):
    __tablename__ = "orders"
    id = Column(Integer, primary_key=True)
    customer_id = Column(Integer, nullable=False)
    amount = Column(Numeric(12, 2), nullable=False)
    status = Column(String(20), nullable=False)
PY

cat > migrations/versions/0012_drop_legacy_note.py <<'PY'
"""orders.legacy_note 를 지운다 — 쓰는 곳이 없다."""
from alembic import op
import sqlalchemy as sa

revision = "0012"
down_revision = "0011"


def upgrade():
    op.drop_column("orders", "legacy_note")


def downgrade():
    pass
PY

cat > migrations/versions/0013_orders_customer_index.py <<'PY'
"""고객별 주문 조회가 느려 customer_id 인덱스를 단다. 금액은 늘 양수라 CHECK 도 건다.

기존 행은 모두 amount > 0 이므로 이 리비전은 그대로 통과한다.
"""
from alembic import op

revision = "0013"
down_revision = "0012"


def upgrade():
    op.create_index("ix_orders_customer_id", "orders", ["customer_id"])
    op.create_check_constraint("ck_orders_amount_positive", "orders", "amount > 0")


def downgrade():
    op.drop_constraint("ck_orders_amount_positive", "orders", type_="check")
    op.drop_index("ix_orders_customer_id", table_name="orders")
PY
