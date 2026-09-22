#!/usr/bin/env bash
set -euo pipefail
mkdir -p app docs/adr
cat > CLAUDE.md <<'EOF'
# 규칙

- 스택: Python 3.12 · FastAPI · SQLAlchemy 2.x · PostgreSQL
- **앵커볼트**(바꾸려면 먼저 물어볼 것): 스키마 · 권한 모델 · 공개 API 응답 형식
- **금지**: 마이그레이션 없는 스키마 변경, 코드에 박힌 시크릿
- 캐시는 쓰지 않는다 — 상태가 두 군데 생기는 것을 먼저 피한다
EOF
cat > PRD.md <<'EOF'
# 장바구니

## 하지 않을 일

- 쿠폰 · 프로모션
- 다중 통화
EOF
cat > pyproject.toml <<'EOF'
[project]
name = "shop"
requires-python = ">=3.12"
dependencies = ["fastapi>=0.110", "sqlalchemy>=2.0", "redis>=5.0"]
EOF
cat > app/cart.py <<'EOF'
import redis

cache = redis.Redis()


def cart_total(user_id: int, coupon: str | None = None):
    cached = cache.get(f"cart:{user_id}")
    if cached:
        return float(cached)
    total = db.carts.total(user_id)
    if coupon:
        total *= 1 - db.coupons.rate(coupon)
    cache.set(f"cart:{user_id}", total, ex=60)
    return total
EOF
cat > docs/adr/0003-no-cache.md <<'EOF'
# ADR-0003 · 캐시를 두지 않는다

상태가 애플리케이션과 캐시 두 군데 생기면 무효화 규칙이 필요해지고, 그 규칙이
틀렸을 때 나는 버그는 재현이 어렵다. 1단계에서는 DB 직접 조회로 간다.

상태: 채택
EOF
