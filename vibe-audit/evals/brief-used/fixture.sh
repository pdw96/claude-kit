#!/usr/bin/env bash
# 권한 검사가 조용히 사라진 커밋. 지금 파일만 보면 「원래 없었다」와
# 구분되지 않는다 — diff 가 있어야 판정된다. 이 픽스처는 브리핑을 둔다.
set -euo pipefail
export GIT_AUTHOR_NAME=fixture GIT_AUTHOR_EMAIL=fixture@example.com
export GIT_COMMITTER_NAME=fixture GIT_COMMITTER_EMAIL=fixture@example.com
mkdir -p app
git init -q .
git config user.email fixture@example.com
git config user.name fixture

# ── 기준 커밋: /admin/export 에 권한 검사가 있다 ──
cat > app/routes.py <<'EOF'
from fastapi import APIRouter, Depends

from .auth import current_user, require_admin

router = APIRouter()


@router.get("/orders")
def list_orders(user=Depends(current_user)):
    return db.orders.for_user(user.id)


@router.get("/admin/export")
def admin_export(user=Depends(require_admin)):
    return db.everything.dump()
EOF
cat > app/cache.py <<'EOF'
_store = {}


def get(key):
    return _store.get(key)


def put(key, value):
    _store[key] = value
EOF
git add -A && git commit -qm "주문 조회와 관리자 내보내기"
BASE=$(git rev-parse --short HEAD)

# ── HEAD: 권한 검사가 조용히 사라졌다. 파일만 보면 읽히지 않는다 ──
cat > app/routes.py <<'EOF'
from fastapi import APIRouter, Depends

from .auth import current_user

router = APIRouter()


@router.get("/orders")
def list_orders(user=Depends(current_user)):
    return db.orders.for_user(user.id)


@router.get("/admin/export")
def admin_export():
    return db.everything.dump()
EOF
cat > app/cache.py <<'EOF'
_store = {}


def get(key):
    return _store.get(key)


def put(key, value, ttl=None):
    _store[key] = value
EOF
git add -A && git commit -qm "내보내기 성능 개선 · 캐시에 ttl 인자 추가"

mkdir -p .claude
{
  echo "# 감사 브리핑"
  echo
  echo "- 만든 시각: 2026-09-22"
  echo "- 기준: \`$BASE\` = \`$BASE\` (2026-09-22 주문 조회와 관리자 내보내기)"
  echo "- 대상: \`$(git rev-parse --short HEAD)\` (브랜치 \`$(git branch --show-current)\`)"
  echo "- 커밋 안 된 변경: 없음"
  echo "- 추적 안 된 파일: 없음"
  echo "- 자름: 없음"
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
  git diff "$BASE"...HEAD
  echo '```'
  echo
  echo "## 이 브리핑이 담지 않은 것"
  echo
  echo "- 실행 결과 · 테스트 통과 여부"
  echo "- 저장소 설정(브랜치 보호 · 룰셋 · 시크릿 저장소)"
  echo "- 배포 환경 · 운영 데이터 · 배포 이력"
  echo "- 잘라낸 것 없음"
} > .claude/audit-brief.md
