#!/usr/bin/env bash
# 네 눈 어느 것에도 해당하지 않는 DDL — 0002 는 운영 중인 orders 에 CONCURRENTLY 로 인덱스를 단다.
# 엔진 · 판은 저장소에 적혀 있다(PostgreSQL 16 — CLAUDE.md · compose · 드라이버). PostgreSQL 의
# CREATE INDEX CONCURRENTLY 는 SHARE UPDATE EXCLUSIVE 만 잡아 쓰기를 막지 않는다 — 셋째 눈 「동시
# 생성 옵션 없는 인덱스」를 닮았지만 거기 걸리지 않는다. 트랜잭션 블록 안에서는 돌 수 없으므로
# autocommit_block 으로 트랜잭션 밖에서 돌게 했고(넷째 눈 「잠금이 언제 풀리는가」도 비켜 간다),
# 리비전이 그 잠금을 그대로 적었다. 고칠 것이 없다.
# 새 문구: 「위 네 눈 어느 것에도 해당하지 않는다 → 적합」. 옛 표에는 그 갈래가 없어 판정이
# 확인불가 · 해당 없음 · 부적합으로 갈릴 수 있다.
# 대조군(항목 3 밖의 진짜 NC): app/checkout.py 가 열린 트랜잭션 안에서 확인 메일을 보낸다(항목 5).
#
# 판 2(2026-10-14) — 판 1 의 옛 쪽 떨어짐은 항목 3 의 판정(세 회차 다 적합)이 아니라 0002 를 언급한
# 잡음 NC(0001 의 파괴적 downgrade 표시 · env.py 없음 · 틀린 실패 복구 안내)였다. 그것을 걷었다 —
# 다시 돌리면 남은 INVALID 인덱스를 먼저 지운다. docs/eval-log/2026-10.md.
set -euo pipefail
mkdir -p app migrations/versions

cat > CLAUDE.md <<'MD'
# 주문 서비스 작업 규칙

## 스택
- Python 3.12 · FastAPI · SQLAlchemy 2.0 · Alembic
- DB 는 PostgreSQL 16 — 운영과 로컬이 같은 판이다(`docker-compose.yml`)
- DB 접속은 `DATABASE_URL` 환경변수로 받는다(`migrations/env.py` 가 읽는다)
- 고객은 회원 서비스가 가진다 — `customer_id` 는 그 서비스의 ID 이고, 이 DB 에 고객 표는 없다

## 작업 방식
- 스키마 변경은 Alembic 리비전으로만 한다. 리비전마다 자기 트랜잭션에서 돈다(`env.py` 의 `transaction_per_migration`)
- 리비전 독스트링에 그 DDL 이 잡는 잠금을 적는다
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
INI

cat > migrations/env.py <<'PY'
import os

from alembic import context
from sqlalchemy import create_engine

from app.models import Base

target_metadata = Base.metadata


def run_migrations_online():
    engine = create_engine(os.environ["DATABASE_URL"])
    with engine.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            transaction_per_migration=True,
        )
        with context.begin_transaction():
            context.run_migrations()


run_migrations_online()
PY

cat > migrations/script.py.mako <<'MAKO'
"""${message}"""
from alembic import op
import sqlalchemy as sa

revision = ${repr(up_revision)}
down_revision = ${repr(down_revision)}


def upgrade():
    ${upgrades if upgrades else "pass"}


def downgrade():
    ${downgrades if downgrades else "pass"}
MAKO

cat > app/__init__.py <<'PY'
PY

cat > app/db.py <<'PY'
import os

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine(os.environ["DATABASE_URL"])
SessionLocal = sessionmaker(engine)
PY

cat > app/mailer.py <<'PY'
import httpx

MAIL_API = "https://api.mail.example.com/v1/messages"


def send_order_confirmation(customer_id: int, order_id: int) -> None:
    """메일 발송 서비스에 주문 확인 메일을 보낸다. 한 번 나간 메일은 거둘 수 없다."""
    r = httpx.post(MAIL_API, json={"customer": customer_id, "template": "order-confirmed", "order": order_id}, timeout=10)
    r.raise_for_status()
PY

cat > app/checkout.py <<'PY'
from app import mailer
from app.db import SessionLocal
from app.models import Order


def place_order(request_id: str, customer_id: int, amount) -> int:
    """주문을 넣는다. 같은 request_id 로 다시 부르면 유니크 제약에 걸려 두 번 들어가지 않는다."""
    with SessionLocal.begin() as session:
        order = Order(request_id=request_id, customer_id=customer_id, amount=amount, status="placed")
        session.add(order)
        session.flush()
        # 확인 메일은 트랜잭션 안에서 보낸다. 아래 커밋이 실패하면 주문은 롤백되지만 메일은 이미 나갔다.
        mailer.send_order_confirmation(customer_id, order.id)
        return order.id
PY

cat > migrations/versions/0001_create_orders.py <<'PY'
"""orders 를 만든다.

잠금: 새 표를 만든다 — 다른 표의 쓰기를 막지 않는다.
downgrade 는 orders 를 지운다 — 주문이 다 사라지고 되돌릴 수 없다. 첫 리비전이라 운영에서는 내리지 않는다.
"""
from alembic import op
import sqlalchemy as sa

revision = "0001"
down_revision = None


def upgrade():
    op.create_table(
        "orders",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("request_id", sa.String(36), nullable=False, unique=True),
        sa.Column("customer_id", sa.Integer, nullable=False),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("status", sa.String(20), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )


def downgrade():
    op.drop_table("orders")
PY

cat > PRD.md <<'MD'
# 주문 서비스

## 현재
운영 중이다. 주문은 하루 종일 들어오고, 점검 시간을 따로 두지 않는다.

## 이번에 더하는 것
- 고객별 주문 조회 화면 — 고객의 주문을 최근 순으로 보여 준다.

## 하지 않을 일
- 다중 통화
MD

cat > app/models.py <<'PY'
from sqlalchemy import Column, DateTime, Index, Integer, Numeric, String, func
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class Order(Base):
    __tablename__ = "orders"
    __table_args__ = (Index("ix_orders_customer_id", "customer_id"),)
    id = Column(Integer, primary_key=True)
    request_id = Column(String(36), nullable=False, unique=True)
    customer_id = Column(Integer, nullable=False)
    amount = Column(Numeric(12, 2), nullable=False)
    status = Column(String(20), nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
PY

cat > migrations/versions/0002_orders_customer_index.py <<'PY'
"""고객별 주문 조회가 느려 orders.customer_id 에 인덱스를 단다.

잠금: CONCURRENTLY 로 만든다. PostgreSQL 16 에서 CREATE INDEX CONCURRENTLY 는 SHARE UPDATE EXCLUSIVE
잠금만 잡아, 인덱스를 만드는 동안 orders 의 읽기 · 쓰기를 막지 않는다. CONCURRENTLY 는 트랜잭션
블록 안에서 돌 수 없으므로 autocommit_block 으로 트랜잭션 밖에서 돈다.
도중에 실패하면 INVALID 인덱스가 남는다 — 그래서 만들기 전에 같은 이름의 인덱스를 DROP INDEX
CONCURRENTLY IF EXISTS 로 지운다(같은 잠금만 잡는다). 실패한 뒤 다시 돌리면 그 자리에서 이어 간다.
downgrade 의 DROP INDEX CONCURRENTLY 도 같은 잠금만 잡는다.
"""
from alembic import op

revision = "0002"
down_revision = "0001"


def upgrade():
    with op.get_context().autocommit_block():
        op.execute("DROP INDEX CONCURRENTLY IF EXISTS ix_orders_customer_id")
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
