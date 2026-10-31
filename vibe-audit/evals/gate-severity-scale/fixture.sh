#!/usr/bin/env bash
# 등급의 양 끝 — 같은 감사자의 담당 안에 부적합 둘을 둔다.
#
# 높음 꼴: CLAUDE.md 는 탈퇴를 소프트 삭제(`deleted_at`)로 정하고 30일 복구를 약속하며, 운영 DB 에
# 백업이 없다고 적는다. 그런데 `app/users.py` 의 탈퇴는 행을 실제로 지우고 주문까지 함께 지운다 —
# 놔두면 지워진 데이터가 돌아오지 않는다(ADR 0061 의 높음).
# 낮음 꼴(대조군): CLAUDE.md 는 부품이 바뀌면 `docs/architecture.md` 를 같은 PR 에서 고치라고 하는데,
# 그 문서는 결제 부품을 옛 이름 `app/billing.py` 로 적는다. 파일은 `app/payments.py` 이고 동작은 같다 —
# 문서만 어긋난다(낮음).
set -euo pipefail
mkdir -p app docs

cat > CLAUDE.md <<'MD'
# 회원 서비스 작업 규칙

## 스택
- Python 3.12 · FastAPI 0.115 · SQLAlchemy 2.0

## 데이터
- 회원 탈퇴는 **소프트 삭제**다 — `users.deleted_at` 을 채우고 행을 지우지 않는다. 약관 7조에 따라
  탈퇴 뒤 30일 안에는 복구 요청을 받는다.
- 운영 DB 는 무료 요금제라 백업이 없다.

## 작업 방식
- 부품을 더하거나 이름을 바꾸면 `docs/architecture.md` 를 같은 PR 에서 고친다.
MD

cat > PRD.md <<'MD'
# 회원 서비스

## 문제
작은 쇼핑몰의 회원 가입 · 탈퇴 · 주문 내역을 한곳에서 다룬다.

## 하지 않을 일
- 소셜 로그인
- 여러 쇼핑몰 동시 운영
MD

cat > pyproject.toml <<'TOML'
[project]
name = "member-service"
requires-python = ">=3.12"
dependencies = [
  "fastapi==0.115.0",
  "sqlalchemy==2.0.30",
]
TOML

cat > docs/architecture.md <<'MD'
# 구조

| 부품 | 파일 | 하는 일 |
|---|---|---|
| 회원 | `app/users.py` | 가입 · 탈퇴 |
| 결제 | `app/billing.py` | 주문 결제 |
| DB | `app/db.py` | 세션 |
MD

cat > app/models.py <<'PY'
import sqlalchemy as sa
from sqlalchemy.orm import DeclarativeBase, relationship


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id = sa.Column(sa.Integer, primary_key=True)
    email = sa.Column(sa.String, nullable=False, unique=True)
    deleted_at = sa.Column(sa.DateTime, nullable=True)
    orders = relationship("Order", cascade="all, delete-orphan")


class Order(Base):
    __tablename__ = "orders"

    id = sa.Column(sa.Integer, primary_key=True)
    user_id = sa.Column(sa.ForeignKey("users.id"), nullable=False)
    amount = sa.Column(sa.Integer, nullable=False)
PY

cat > app/db.py <<'PY'
import os

from sqlalchemy import create_engine
from sqlalchemy.orm import Session

engine = create_engine(os.environ["DATABASE_URL"])
session = Session(engine)
PY

cat > app/users.py <<'PY'
from fastapi import APIRouter, HTTPException

from .db import session
from .models import User

router = APIRouter()


@router.post("/users")
def sign_up(email: str):
    user = User(email=email)
    session.add(user)
    session.commit()
    return {"id": user.id}


@router.delete("/users/{user_id}")
def withdraw(user_id: int):
    user = session.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404)
    session.delete(user)
    session.commit()
    return {"ok": True}
PY

cat > app/payments.py <<'PY'
from fastapi import APIRouter

from .db import session
from .models import Order

router = APIRouter()


@router.post("/orders")
def pay(user_id: int, amount: int):
    order = Order(user_id=user_id, amount=amount)
    session.add(order)
    session.commit()
    return {"id": order.id}
PY

cat > README.md <<'MD'
# member-service

회원 가입 · 탈퇴와 주문 결제.

## 실행

```bash
export DATABASE_URL=postgresql://localhost/members
uvicorn app.users:router --port 8050
```
MD
