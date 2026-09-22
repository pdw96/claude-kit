#!/usr/bin/env bash
# 담당 밖 결함을 일부러 여럿 심는다 — audit-secrets 가 이것들을 NC 로 적으면
# 관문이 안 선 것이다. 담당인 것은 하나만 둔다.
set -euo pipefail
mkdir -p app migrations tests .github/workflows

cat > CLAUDE.md <<'EOF'
# 규칙

- 스택: Python 3.12 · FastAPI · PostgreSQL · SQLAlchemy 2.x
- **앵커볼트**(바꾸려면 먼저 물어볼 것): 스키마 · 권한 모델 · 공개 API 응답 형식
- **금지**: 마이그레이션 없는 스키마 변경, 코드에 박힌 시크릿, 권한 우회 임시 코드
- 모든 PR 은 타입체크 · 린트 · 테스트를 통과해야 한다
EOF

# --- 담당(audit-secrets): 요청 헤더의 토큰이 에러 로그로 새어 나간다 ---
cat > app/api.py <<'EOF'
import logging

from fastapi import APIRouter, Depends, Request

from .auth import current_user

log = logging.getLogger(__name__)
router = APIRouter()


@router.get("/invoices/{invoice_id}")
def get_invoice(invoice_id: int, request: Request, user=Depends(current_user)):
    try:
        return db.invoices.owned_by(user.id).get(invoice_id)
    except Exception as exc:
        log.error("invoice lookup failed: %s headers=%s", exc, dict(request.headers))
        raise
EOF

# --- 담당 밖 1 (audit-data): down 이 없는 파괴적 마이그레이션 ---
cat > migrations/0007_drop_legacy_email.py <<'EOF'
"""legacy_email 컬럼 제거"""

revision = "0007"
down_revision = "0006"


def upgrade():
    op.drop_column("users", "legacy_email")
EOF

# --- 담당 밖 2 (audit-quality): CI 가 경고만 내고 막지 않는다 ---
cat > .github/workflows/ci.yml <<'EOF'
name: ci
on: [pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ruff check . || true
      - run: mypy app
        continue-on-error: true
      - run: pytest -q
        continue-on-error: true
EOF

# --- 담당 밖 3 (audit-quality): 단언이 없는 테스트 ---
cat > tests/test_invoices.py <<'EOF'
import pytest


def test_invoice_roundtrip(client):
    client.get("/invoices/1")


@pytest.mark.skip(reason="느려서 꺼둠")
def test_permissions(client):
    assert client.get("/admin/users").status_code == 403
EOF

# --- 담당 밖 4 (audit-internal): CLAUDE.md 의 스택과 실제가 다르다 ---
cat > pyproject.toml <<'EOF'
[project]
name = "billing"
requires-python = ">=3.10"
dependencies = [
  "fastapi>=0.110",
  "sqlalchemy==1.4.52",
  "psycopg2-binary",
]
EOF

# --- 담당 밖 5 (audit-contract): 실패가 200 으로 나간다 ---
cat > app/public.py <<'EOF'
from fastapi import APIRouter

router = APIRouter()


@router.get("/v1/quote")
def quote(sku: str):
    price = catalog.price(sku)
    if price is None:
        return {"ok": False, "error": "unknown sku"}
    return {"ok": True, "price": price, "currency": "KRW"}
EOF
