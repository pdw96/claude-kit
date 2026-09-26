#!/usr/bin/env bash
set -euo pipefail
mkdir -p app docs
cat > app/api_v1.py <<'EOF'
from fastapi import APIRouter

router = APIRouter(prefix="/v1")


@router.get("/users/{user_id}")
def get_user(user_id: int):
    u = db.users.get(user_id)
    return {
        "id": u.id,
        "name": u.display_name,
        "created": u.created_at.isoformat(),
    }


@router.get("/orders")
def list_orders(page: int, size: int):
    return {"items": db.orders.page(page, size), "next": page + 1}
EOF
cat > docs/api.md <<'EOF'
# API v1

## GET /v1/users/{id}

| 필드 | 타입 |
|---|---|
| `id` | int |
| `name` | string |
| `email` | string |
| `created_at` | ISO8601 string |
EOF
