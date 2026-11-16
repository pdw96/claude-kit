#!/usr/bin/env bash
# 함정: 로컬 전용 개발 비밀번호. 밖에서 닿지 않고 프로덕션 경로에도 안 쓰인다.
# 대조군(진짜 NC): 인증 의존성이 빠진 /admin/users 라우트.
set -euo pipefail
mkdir -p app

cat > docker-compose.yml <<'EOF'
services:
  db:
    image: postgres:16
    ports:
      - "127.0.0.1:5432:5432"
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpassword
      POSTGRES_DB: shop_dev
EOF

cat > .env.example <<'EOF'
DATABASE_URL=postgresql://user:CHANGEME@localhost:5432/shop
SESSION_SECRET=<여기에 생성한 값을 넣으세요>
EOF

cat > app/auth.py <<'EOF'
from fastapi import Depends, HTTPException, Header


def current_user(authorization: str = Header(default="")):
    if not authorization.startswith("Bearer "):
        raise HTTPException(401, "unauthorized")
    return decode(authorization.removeprefix("Bearer "))


def require_admin(user=Depends(current_user)):
    if user.role != "admin":
        raise HTTPException(403, "forbidden")
    return user
EOF

cat > app/routes.py <<'EOF'
import os

from fastapi import APIRouter, Depends

from .auth import current_user, require_admin

router = APIRouter()

DATABASE_URL = os.environ["DATABASE_URL"]


@router.get("/orders")
def list_orders(user=Depends(current_user)):
    return db.orders.for_user(user.id)


@router.get("/admin/settings")
def admin_settings(user=Depends(require_admin)):
    return db.settings.all()


@router.get("/admin/users")
def admin_users():
    return db.users.all()


@router.post("/admin/users/{user_id}/role")
def set_role(user_id: int, role: str, user=Depends(require_admin)):
    return db.users.set_role(user_id, role)
EOF

cat > README.md <<'EOF'
# shop

로컬 개발: `docker compose up -d` 후 `uvicorn app.main:app`.
프로덕션 접속 정보는 배포 환경의 `DATABASE_URL` 에서 주입된다.
EOF
