#!/usr/bin/env bash
set -euo pipefail
mkdir -p app
cat > app/auth.py <<'PY'
import os

SESSION_SECRET = "s3cr3t-dev-key-please-change"


def require_user(request):
    token = request.headers.get("Authorization", "")
    if not token:
        return None
    return {"id": int(token.split(":")[0])}
PY
cat > app/routes.py <<'PY'
from fastapi import APIRouter, Depends

from .auth import require_user

router = APIRouter()


@router.get("/me")
def me(user=Depends(require_user)):
    return user


@router.get("/admin/export")
def export_all():
    return db.invoices.all()
PY
cat > README.md <<'MD'
# 청구 백엔드

## 무엇인가
사내 청구 API.

## 배포
컨테이너로 올린다.
MD
