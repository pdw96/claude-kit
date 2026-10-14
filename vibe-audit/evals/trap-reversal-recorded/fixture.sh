#!/usr/bin/env bash
# 결정이 ADR 밖에도 산다 — 이 저장소는 결정을 `docs/adr/` 와 `docs/schema.md` 「결정」 표 둘에 남긴다고
# CLAUDE.md 에 적었다. ADR 0002 는 「취소한 주문은 행을 지운다」였는데, 코드는 지우지 않고
# `status='cancelled'` · `cancelled_at` 으로 남긴다. 그 뒤집힘은 `docs/schema.md` 「결정」 표에 날짜와
# 함께 「ADR 0002 를 뒤집는다」로 적혀 있다 — 새 ADR 은 없다.
#
# 덫(FB-34 · 8): 원본 항목 10 의 「새 ADR 없이 뒤집혔는가」를 글자대로 읽으면 이 뒤집힘이 NC 가 된다.
# 저장소가 정한 결정 자리에 새 기록이 함께 갔으므로 부적합이 아니다.
# 진짜 부적합(대조군): CLAUDE.md 「금지」는 로그에 고객 이메일을 남기지 않는다인데 `app/signup.py` 가
# 가입마다 이메일을 로그에 찍는다.
#
# 판 2(조각 18 PR B) — 판 1(같은 저장소, 브리핑 없음)은 옛 문구로도 3/3 이었다. 이 판은 뒤집힘을 커밋 하나로
# 두고 브리핑(diff)을 놓는다. diff 에는 코드 고침과 「결정」 표의 새 줄만 있고 ADR 은 없다 — 옛 항목 10 의
# 「새 ADR 없이 뒤집혔는가」가 판정할 수 있는 질문이 되고, 그 글자대로의 답은 「그렇다」다.
#
# 진짜 부적합은 하나뿐이어야 한다 — 스택 · 의존성 · 스키마 문서 · 작업 방식은 코드가 받친다.
#
# **SHA 를 박는다.** 이름 · 메일 · 저자 · 커미터 시각과 파일 내용이 같으면 커밋 SHA 도 같다.
set -euo pipefail
export GIT_AUTHOR_NAME=fixture GIT_AUTHOR_EMAIL=fixture@example.com
export GIT_COMMITTER_NAME=fixture GIT_COMMITTER_EMAIL=fixture@example.com
mkdir -p app docs/adr
git init -q .
git symbolic-ref HEAD refs/heads/main
git config user.email fixture@example.com
git config user.name fixture
git config commit.gpgsign false

cat > CLAUDE.md <<'MD'
# 주문 서비스 작업 규칙

범위는 `PRD.md`, 데이터 모델은 `docs/schema.md`.

## 스택
- Python 3.12 · FastAPI 0.115 · SQLAlchemy 2.0

## 결정 기록
- 대안이 있던 결정은 `docs/adr/` 에 남긴다.
- 스키마와 데이터 보존에 관한 결정은 `docs/schema.md` 의 「결정」 표에 남긴다 — 줄마다 날짜를 박고,
  지난 줄은 고치지 않는다.

## 금지
- 로그에 고객 이메일 · 전화번호를 남기지 않는다
MD

cat > PRD.md <<'MD'
# 주문 서비스

## 문제
작은 쇼핑몰이 주문 접수와 취소를 메신저로 받아 엑셀에 옮겨 적는다.

## 하는 일
- 회원 가입 · 주문 접수 · 주문 취소

## 하지 않을 일
- 결제 대행 연동
- 재고 관리
MD

cat > docs/schema.md <<'MD'
# 데이터 모델

## 엔티티

| 엔티티 | 열 |
|---|---|
| `customers` | `id` · `email` · `phone` · `created_at` |
| `orders` | `id` · `customer_id` → `customers.id` · `status`(`placed`) · `created_at` |

## 결정

| 날짜 | 결정 | 왜 |
|---|---|---|
| 2026-07-20 | 고객 연락처는 `customers` 에만 둔다 — `orders` 에 복사하지 않는다 | 연락처를 고칠 자리를 하나로 |
MD

cat > docs/adr/0001-fastapi.md <<'MD'
# 0001 — 웹 프레임워크는 FastAPI

2026-06-10 · 결정함

## 맥락
주문 접수 API 하나와 관리 화면 몇 개가 필요하다.

## 대안
1. **FastAPI** / Django / Flask

## 결정
FastAPI. 화면은 적고 API 가 중심이다.
MD

cat > docs/adr/0002-order-cancel-delete.md <<'MD'
# 0002 — 취소한 주문은 행을 지운다

2026-06-18 · 결정함

## 맥락
취소한 주문이 목록에 섞여 접수 담당이 헷갈린다.

## 대안
1. **취소하면 행을 지운다** / 상태 열로 남긴다

## 결정
취소하면 `orders` 의 행을 지운다. 지난 주문을 다시 볼 일이 없다.
MD

cat > pyproject.toml <<'TOML'
[project]
name = "order-service"
requires-python = ">=3.12"
dependencies = [
  "fastapi==0.115.0",
  "sqlalchemy==2.0.30",
]
TOML

cat > app/__init__.py <<'PY'
PY

cat > app/db.py <<'PY'
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine("sqlite:///orders.db")
SessionLocal = sessionmaker(bind=engine)
PY

cat > app/models.py <<'PY'
import sqlalchemy as sa
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class Customer(Base):
    __tablename__ = "customers"

    id = sa.Column(sa.Integer, primary_key=True)
    email = sa.Column(sa.String(255), nullable=False, unique=True)
    phone = sa.Column(sa.String(32), nullable=True)
    created_at = sa.Column(sa.DateTime, nullable=False, server_default=sa.func.now())


class Order(Base):
    __tablename__ = "orders"

    id = sa.Column(sa.Integer, primary_key=True)
    customer_id = sa.Column(sa.ForeignKey("customers.id"), nullable=False)
    status = sa.Column(sa.String(16), nullable=False, default="placed")
    created_at = sa.Column(sa.DateTime, nullable=False, server_default=sa.func.now())
PY

cat > app/orders.py <<'PY'
from fastapi import APIRouter, HTTPException

from .db import SessionLocal
from .models import Order

router = APIRouter()


@router.post("/orders")
def place_order(customer_id: int) -> dict:
    with SessionLocal() as s:
        order = Order(customer_id=customer_id, status="placed")
        s.add(order)
        s.commit()
        return {"id": order.id, "status": order.status}


@router.post("/orders/{order_id}/cancel")
def cancel_order(order_id: int) -> dict:
    with SessionLocal() as s:
        order = s.get(Order, order_id)
        if order is None:
            raise HTTPException(404)
        s.delete(order)
        s.commit()
        return {"id": order_id, "status": "deleted"}


@router.get("/orders")
def list_orders() -> list[dict]:
    with SessionLocal() as s:
        rows = s.query(Order).all()
        return [{"id": o.id, "customer_id": o.customer_id} for o in rows]
PY

cat > app/signup.py <<'PY'
import logging

from fastapi import APIRouter
from pydantic import BaseModel

from .db import SessionLocal
from .models import Customer

log = logging.getLogger(__name__)
router = APIRouter()


class SignupIn(BaseModel):
    email: str
    phone: str | None = None


@router.post("/signup")
def signup(payload: SignupIn) -> dict:
    with SessionLocal() as s:
        customer = Customer(email=payload.email, phone=payload.phone)
        s.add(customer)
        s.commit()
        log.info("signup ok: id=%s email=%s", customer.id, payload.email)
        return {"id": customer.id}
PY

cat > app/main.py <<'PY'
from fastapi import FastAPI

from . import orders, signup

app = FastAPI()
app.include_router(signup.router)
app.include_router(orders.router)
PY

export GIT_AUTHOR_DATE="2026-08-20T10:00:00+0900" GIT_COMMITTER_DATE="2026-08-20T10:00:00+0900"
git add -A && git commit -qm "가입 · 주문 접수 · 주문 취소"
BASE=$(git rev-parse --short HEAD)

# ── HEAD: 취소한 주문을 지우지 않고 상태로 남긴다. 결정은 「결정」 표에 — ADR 은 없다 ──
cat > docs/schema.md <<'MD'
# 데이터 모델

## 엔티티

| 엔티티 | 열 |
|---|---|
| `customers` | `id` · `email` · `phone` · `created_at` |
| `orders` | `id` · `customer_id` → `customers.id` · `status`(`placed` · `cancelled`) · `created_at` · `cancelled_at` |

## 결정

| 날짜 | 결정 | 왜 |
|---|---|---|
| 2026-07-20 | 고객 연락처는 `customers` 에만 둔다 — `orders` 에 복사하지 않는다 | 연락처를 고칠 자리를 하나로 |
| 2026-09-02 | 주문은 지우지 않는다. 취소는 `status='cancelled'` 와 `cancelled_at` 으로 남긴다 — ADR 0002 를 뒤집는다 | 카드사 환불 대사에 취소한 주문이 있어야 한다 |
MD

cat > app/models.py <<'PY'
import sqlalchemy as sa
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class Customer(Base):
    __tablename__ = "customers"

    id = sa.Column(sa.Integer, primary_key=True)
    email = sa.Column(sa.String(255), nullable=False, unique=True)
    phone = sa.Column(sa.String(32), nullable=True)
    created_at = sa.Column(sa.DateTime, nullable=False, server_default=sa.func.now())


class Order(Base):
    __tablename__ = "orders"

    id = sa.Column(sa.Integer, primary_key=True)
    customer_id = sa.Column(sa.ForeignKey("customers.id"), nullable=False)
    status = sa.Column(sa.String(16), nullable=False, default="placed")
    created_at = sa.Column(sa.DateTime, nullable=False, server_default=sa.func.now())
    cancelled_at = sa.Column(sa.DateTime, nullable=True)
PY

cat > app/orders.py <<'PY'
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException

from .db import SessionLocal
from .models import Order

router = APIRouter()


@router.post("/orders")
def place_order(customer_id: int) -> dict:
    with SessionLocal() as s:
        order = Order(customer_id=customer_id, status="placed")
        s.add(order)
        s.commit()
        return {"id": order.id, "status": order.status}


@router.post("/orders/{order_id}/cancel")
def cancel_order(order_id: int) -> dict:
    with SessionLocal() as s:
        order = s.get(Order, order_id)
        if order is None:
            raise HTTPException(404)
        order.status = "cancelled"
        order.cancelled_at = datetime.now(timezone.utc)
        s.commit()
        return {"id": order.id, "status": order.status}


@router.get("/orders")
def list_orders() -> list[dict]:
    with SessionLocal() as s:
        rows = s.query(Order).filter(Order.status == "placed").all()
        return [{"id": o.id, "customer_id": o.customer_id} for o in rows]
PY

export GIT_AUTHOR_DATE="2026-09-02T15:00:00+0900" GIT_COMMITTER_DATE="2026-09-02T15:00:00+0900"
git add -A && git commit -qm "주문 취소를 지우지 않고 상태로 남긴다"
HEAD_SHA=$(git rev-parse --short HEAD)

mkdir -p .claude
{
  echo "# 감사 브리핑"
  echo
  echo "- 만든 시각: 2026-09-02 15:30"
  echo "- 기준: \`main~1\` = \`$BASE\` (2026-08-20 가입 · 주문 접수 · 주문 취소), 머지 베이스 \`$BASE\`"
  echo "- 대상: \`$HEAD_SHA\` (브랜치 \`$(git branch --show-current)\`)"
  echo "- 커밋 안 된 변경: 없음"
  echo "- 추적 안 된 파일: 없음"
  echo "- 자름: 없음"
  echo "- 검사: PASS"
  echo
  echo "## 변경 파일"
  echo
  echo '```'
  git diff --stat "$BASE"...HEAD
  echo '```'
  echo
  echo "## 커밋"
  echo
  echo '```'
  git log --oneline "$BASE"..HEAD
  echo '```'
  echo
  echo "## diff"
  echo
  echo '```diff'
  git diff --no-color "$BASE"...HEAD
  echo '```'
  echo
  echo "## 이 브리핑이 담지 않은 것"
  echo
  echo "- 실행 결과 · 테스트 통과 여부"
  echo "- 저장소 설정(브랜치 보호 · 룰셋 · 시크릿 저장소)"
  echo "- 배포 환경 · 운영 데이터 · 배포 이력"
  echo "- 잘라낸 것 없음"
} > .claude/audit-brief.md
