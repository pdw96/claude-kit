#!/usr/bin/env bash
# 피할 형태가 없는 잠금을 리비전이 맞게 적었다 — 0002 는 운영 중인 orders 에 상수 기본값을 단
# NOT NULL 컬럼을 더한다. 엔진 · 판은 저장소에 적혀 있다(PostgreSQL 16 — CLAUDE.md · compose ·
# 드라이버). PostgreSQL 11 이상에서 이 DDL 은 표를 다시 쓰지 않지만 ALTER TABLE 이라 ACCESS
# EXCLUSIVE 를 잡아, 커밋까지 orders 의 쓰기가 멈춘다. 이 잠금을 줄이는 다른 형태는 없고, 리비전이
# 그것을 그대로 적었으며 앞선 트랜잭션 뒤에 줄을 서지 않게 lock_timeout 을 건다. 고칠 것이 없다.
# 새 문구: 「쓰기를 멈추는데 피할 형태가 없다」는 적합 — 잠금 사실 · 전제와 「영향은 저장소 밖」을
# 근거에 적는다. 옛 문구의 그 줄은 「심각도 확인불가」라 판정이 확인불가로 남는다.
# 대조군(항목 3 밖의 진짜 NC): app/checkout.py 가 열린 트랜잭션 안에서 확인 메일을 보낸다(항목 5).
#
# 판 2(2026-10-14) — 판 1 은 옛 쪽 세 회차가 다 떨어졌지만, 항목 3 을 확인불가로 둔 까닭이 갈래가
# 아니라 픽스처의 빈자리였다(env.py 가 없어 SET LOCAL 이 듣는지 모른다). 그 밖의 잡음 NC — 0001 의
# 파괴적 downgrade 표시 · 재시도 중복 · channel 값 집합 — 도 함께 걷었다. docs/eval-log/2026-10.md.
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
- 주문이 들어온 경로(`channel`)를 남긴다. 지금까지의 주문은 모두 웹(`web`)으로 들어왔다.

## 하지 않을 일
- 다중 통화
MD

cat > app/models.py <<'PY'
from sqlalchemy import Column, DateTime, Integer, Numeric, String, func
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class Order(Base):
    __tablename__ = "orders"
    id = Column(Integer, primary_key=True)
    request_id = Column(String(36), nullable=False, unique=True)
    customer_id = Column(Integer, nullable=False)
    amount = Column(Numeric(12, 2), nullable=False)
    status = Column(String(20), nullable=False)
    channel = Column(String(10), nullable=False, server_default="web")
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
PY

cat > migrations/versions/0002_orders_channel.py <<'PY'
"""orders 에 주문이 들어온 경로(channel)를 단다 — NOT NULL, 기본값 'web'. 지금까지의 주문은 모두 웹이다.

잠금: PostgreSQL 16 에서 상수 기본값을 단 컬럼 추가는 표를 다시 쓰지 않는다 — 기본값은 카탈로그에만
적히고 기존 행은 건드리지 않는다. 다만 ALTER TABLE 이라 orders 에 ACCESS EXCLUSIVE 잠금을 잡고, 이
리비전의 트랜잭션이 커밋될 때까지 orders 의 읽기 · 쓰기가 멈춘다. 컬럼 추가에는 이 잠금을 줄이는 다른
형태가 없다. 앞선 긴 트랜잭션 뒤에 줄을 서며 그 뒤의 쓰기까지 붙잡지 않도록 lock_timeout 을 5초로
건다(SET LOCAL — 이 리비전의 트랜잭션에만 듣는다). 넘으면 이 리비전은 아무것도 바꾸지 않고 실패하고, 다시 돌린다.
downgrade 의 DROP COLUMN 도 같은 잠금을 잡고 피할 형태가 없다 — 같은 lock_timeout 을 건다.
downgrade 는 channel 을 지우므로 그 사이 남은 경로 값을 잃는다 — 되돌리면 그 값은 돌아오지 않는다.
"""
from alembic import op
import sqlalchemy as sa

revision = "0002"
down_revision = "0001"


def upgrade():
    op.execute("SET LOCAL lock_timeout = '5s'")
    op.add_column(
        "orders",
        sa.Column("channel", sa.String(10), nullable=False, server_default="web"),
    )


def downgrade():
    op.execute("SET LOCAL lock_timeout = '5s'")
    op.drop_column("orders", "channel")
PY
