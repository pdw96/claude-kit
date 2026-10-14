#!/usr/bin/env bash
# 네 눈 어느 것에도 해당하지 않는 DDL — 0002 는 운영 중인 orders 에 CONCURRENTLY 로 인덱스를 단다.
# 엔진 · 판은 저장소에 적혀 있다(PostgreSQL 16 — CLAUDE.md · compose · 드라이버). PostgreSQL 의
# CREATE INDEX CONCURRENTLY 는 SHARE UPDATE EXCLUSIVE 만 잡아 쓰기를 막지 않는다 — 셋째 눈 「동시
# 생성 옵션 없는 인덱스」를 닮았지만 거기 걸리지 않는다. 트랜잭션 블록 안에서는 돌 수 없으므로
# autocommit_block 으로 트랜잭션 밖에서 돌게 했고(넷째 눈 「잠금이 언제 풀리는가」도 비켜 간다),
# 리비전이 그 잠금을 그대로 적었다. 고칠 것이 없다.
# 새 문구: 「위 네 눈 어느 것에도 해당하지 않는다 → 적합」. 옛 표에는 그 갈래가 없어 판정이
# 확인불가 · 해당 없음 · 부적합으로 갈릴 수 있다.
# 대조군(항목 3 밖의 진짜 NC): app/checkout.py 가 열린 트랜잭션 안에서 외부 결제를 부른다(항목 5).
set -euo pipefail
mkdir -p app migrations/versions

cat > CLAUDE.md <<'MD'
# 주문 서비스 작업 규칙

## 스택
- Python 3.12 · FastAPI · SQLAlchemy 2.0 · Alembic
- DB 는 PostgreSQL 16 — 운영과 로컬이 같은 판이다(`docker-compose.yml`)
- DB 접속은 `DATABASE_URL` 환경변수로 받는다

## 작업 방식
- 스키마 변경은 Alembic 리비전으로만 한다
- 리비전 독스트링에 그 DDL 이 잡는 잠금을 적는다
MD

cat > PRD.md <<'MD'
# 주문 서비스

## 현재
운영 중이다. 주문은 하루 종일 들어오고, 점검 시간을 따로 두지 않는다.

## 이번에 더하는 것
- 고객별 주문 조회 화면 — 고객의 주문을 최근 순으로 보여 준다.

## 하지 않을 일
- 다중 통화
MD

cat > docker-compose.yml <<'YML'
services:
  db:
    image: postgres:16.4
    environment:
      POSTGRES_DB: orders
      POSTGRES_PASSWORD: local-only
    ports:
      - "5432:5432"
YML

cat > pyproject.toml <<'TOML'
[project]
name = "orders"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
  "fastapi>=0.115",
  "sqlalchemy>=2.0",
  "alembic>=1.13",
  "psycopg[binary]>=3.2",
  "httpx>=0.27",
]
TOML

cat > alembic.ini <<'INI'
[alembic]
script_location = migrations
sqlalchemy.url = ${DATABASE_URL}
INI

cat > app/__init__.py <<'PY'
PY

cat > app/db.py <<'PY'
import os

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine(os.environ["DATABASE_URL"])
SessionLocal = sessionmaker(engine)
PY

cat > app/models.py <<'PY'
from sqlalchemy import Column, DateTime, Index, Integer, Numeric, String, func
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class Order(Base):
    __tablename__ = "orders"
    __table_args__ = (Index("ix_orders_customer_id", "customer_id"),)
    id = Column(Integer, primary_key=True)
    customer_id = Column(Integer, nullable=False)
    amount = Column(Numeric(12, 2), nullable=False)
    status = Column(String(20), nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
PY

cat > app/payments.py <<'PY'
import httpx

PG_URL = "https://api.payments.example.com/v1/charges"


def charge(customer_id: int, amount, idempotency_key: str) -> str:
    """외부 결제사에 승인을 요청한다. 승인되면 돈이 빠져나간다 — 되돌리려면 취소 API 를 따로 불러야 한다."""
    r = httpx.post(
        PG_URL,
        json={"customer": customer_id, "amount": str(amount)},
        headers={"Idempotency-Key": idempotency_key},
        timeout=10,
    )
    r.raise_for_status()
    return r.json()["id"]
PY

cat > app/checkout.py <<'PY'
from app import payments
from app.db import SessionLocal
from app.models import Order


def checkout(customer_id: int, amount) -> int:
    with SessionLocal.begin() as session:
        order = Order(customer_id=customer_id, amount=amount, status="pending")
        session.add(order)
        session.flush()
        # 결제 승인은 트랜잭션 안에서 부른다. 아래 커밋이 실패하면 주문은 롤백되지만 승인은 남는다.
        payments.charge(customer_id, amount, idempotency_key=f"order-{order.id}")
        order.status = "paid"
        return order.id
PY

cat > migrations/versions/0001_create_orders.py <<'PY'
"""orders 를 만든다."""
from alembic import op
import sqlalchemy as sa

revision = "0001"
down_revision = None


def upgrade():
    op.create_table(
        "orders",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("customer_id", sa.Integer, nullable=False),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("status", sa.String(20), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )


def downgrade():
    op.drop_table("orders")
PY

cat > migrations/versions/0002_orders_customer_index.py <<'PY'
"""고객별 주문 조회가 느려 orders.customer_id 에 인덱스를 단다.

잠금: CONCURRENTLY 로 만든다. PostgreSQL 16 에서 CREATE INDEX CONCURRENTLY 는 SHARE UPDATE EXCLUSIVE
잠금만 잡아, 인덱스를 만드는 동안 orders 의 읽기 · 쓰기를 막지 않는다. CONCURRENTLY 는 트랜잭션
블록 안에서 돌 수 없으므로 autocommit_block 으로 트랜잭션 밖에서 돈다 — 앞선 리비전의 트랜잭션은 그
전에 커밋된다. 도중에 실패하면 INVALID 인덱스가 남는다 — 그때는 downgrade 로 지우고 다시 돌린다.
downgrade 의 DROP INDEX CONCURRENTLY 도 같은 잠금만 잡는다.
"""
from alembic import op

revision = "0002"
down_revision = "0001"


def upgrade():
    with op.get_context().autocommit_block():
        op.create_index(
            "ix_orders_customer_id",
            "orders",
            ["customer_id"],
            postgresql_concurrently=True,
        )


def downgrade():
    with op.get_context().autocommit_block():
        op.drop_index(
            "ix_orders_customer_id",
            table_name="orders",
            postgresql_concurrently=True,
        )
PY
