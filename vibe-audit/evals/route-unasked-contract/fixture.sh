#!/usr/bin/env bash
set -euo pipefail
mkdir -p app docs
cat > app/api_v1.py <<'EOF'
from fastapi import APIRouter

router = APIRouter(prefix="/v1")


@router.get("/users/{user_id}")
def get_user(user_id: int):
    u = db.users.get(user_id)
    return {"id": u.id, "display_name": u.display_name}
EOF
cat > docs/api.md <<'EOF'
# API v1 — 외부 파트너가 쓴다

## GET /v1/users/{id}

| 필드 | 타입 |
|---|---|
| `id` | int |
| `name` | string |
EOF
