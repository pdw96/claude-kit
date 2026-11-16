#!/usr/bin/env bash
# 밖에서 보이는 권한 실패(정지된 사용자가 그대로 로그인돼 있다)의 뿌리가 데이터 모델에 있다 —
# 사용자를 지우지 않고 `deleted_at` 으로 표시만 하는데(소프트 삭제), 신원을 푸는 조회가 그 표시를
# 거르지 않는다. 실패는 audit-secrets, 소프트 삭제 모델과 조회 규약이 옳은가는 audit-data.
#
# 첫 판(송장에 소유 열이 없다)과 둘째 판(역할 열의 기본값이 admin)은 옛 문구도 자기 NC 로
# 적어 가르지 못했다(5.5). 이 판은 실패가 「모든 조회가 deleted_at 을 걸러야 한다」는 **데이터
# 규약의 빈칸**으로 보인다 — 옛 문구의 「권한 경계가 데이터 모델에 기대도 그 모델은 audit-data」에
# 통째로 걸리는 모양이다.
# 대조군(모호함 없는 진짜 NC): JWT 서명을 검증하지 않는다.
set -euo pipefail
mkdir -p app docs

cat > app/models.py <<'PY'
import sqlalchemy as sa
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id = sa.Column(sa.Integer, primary_key=True)
    email = sa.Column(sa.String(255), nullable=False)
    deleted_at = sa.Column(sa.DateTime, nullable=True)
PY

cat > app/repo.py <<'PY'
from sqlalchemy import select

from .db import session
from .models import User


def active_users():
    return session.scalars(select(User).where(User.deleted_at.is_(None))).all()


def find_by_email(email: str):
    return session.scalars(
        select(User).where(User.email == email, User.deleted_at.is_(None))
    ).first()
PY

cat > app/auth.py <<'PY'
import jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer

from .db import session
from .models import User

bearer = HTTPBearer()


def current_user(cred=Depends(bearer)) -> User:
    try:
        claims = jwt.decode(cred.credentials, options={"verify_signature": False})
    except jwt.PyJWTError:
        raise HTTPException(status_code=401)
    user = session.get(User, int(claims["sub"]))
    if user is None:
        raise HTTPException(status_code=401)
    return user
PY

cat > app/admin.py <<'PY'
from datetime import datetime, timezone

from fastapi import APIRouter, Depends

from .auth import current_user
from .db import session
from .models import User

router = APIRouter()


@router.post("/admin/users/{user_id}/ban")
def ban(user_id: int, admin=Depends(current_user)):
    user = session.get(User, user_id)
    user.deleted_at = datetime.now(timezone.utc)
    session.commit()
    return {"ok": True}
PY

cat > app/db.py <<'PY'
import os

from sqlalchemy import create_engine
from sqlalchemy.orm import Session

engine = create_engine(os.environ["DATABASE_URL"])
session = Session(engine)
PY

cat > docs/schema.md <<'MD'
# 스키마

## users
행을 지우지 않는다. 정지 · 탈퇴는 `deleted_at` 에 시각을 적는 것으로 한다(소프트 삭제).
`deleted_at` 이 있는 사용자는 **없는 사용자**로 다룬다.

토큰 수명은 30일이다.
MD
