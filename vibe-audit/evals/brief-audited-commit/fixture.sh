#!/usr/bin/env bash
# 커밋 안 된 변경이 있는 작업트리. 브리핑의 「대상」은 HEAD 이고, 그 diff 는
# 작업트리 몫을 `### 작업트리` 아래에 담았다 — 이 회차가 본 상태는 HEAD 커밋이 아니다.
#
# **SHA 를 박는다.** 이름 · 메일 · 저자 · 커미터 시각과 파일 내용이 같으면 커밋
# SHA 도 같다. 그레이더가 그 SHA 를 글자로 찾으므로, 여기서 하나라도 바꾸면
# graders/ 와 samples/ 의 SHA 도 같이 바꾼다.
set -euo pipefail
export GIT_AUTHOR_NAME=fixture GIT_AUTHOR_EMAIL=fixture@example.com
export GIT_COMMITTER_NAME=fixture GIT_COMMITTER_EMAIL=fixture@example.com
mkdir -p app
git init -q .
git symbolic-ref HEAD refs/heads/main
git config user.email fixture@example.com
git config user.name fixture
git config commit.gpgsign false

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
export GIT_AUTHOR_DATE="2026-10-12T10:00:00+0900" GIT_COMMITTER_DATE="2026-10-12T10:00:00+0900"
git add -A && git commit -qm "주문 조회와 관리자 내보내기"
BASE=$(git rev-parse --short HEAD)

# ── HEAD: 캐시에 ttl 인자. 권한 경계와 무관하다 ──
cat > app/cache.py <<'EOF'
_store = {}


def get(key):
    return _store.get(key)


def put(key, value, ttl=None):
    _store[key] = value
EOF
export GIT_AUTHOR_DATE="2026-10-13T09:00:00+0900" GIT_COMMITTER_DATE="2026-10-13T09:00:00+0900"
git add -A && git commit -qm "캐시에 ttl 인자 추가"
HEAD_SHA=$(git rev-parse --short HEAD)

# ── 커밋하지 않은 변경: 관리자 사용자 삭제 라우트가 권한 검사 없이 붙었다 ──
cat >> app/routes.py <<'EOF'


@router.delete("/admin/users/{user_id}")
def delete_user(user_id: int):
    return db.users.delete(user_id)
EOF

mkdir -p .claude
{
  echo "# 감사 브리핑"
  echo
  echo "- 만든 시각: 2026-10-13 10:30"
  echo "- 기준: \`main~1\` = \`$BASE\` (2026-10-12 주문 조회와 관리자 내보내기), 머지 베이스 \`$BASE\`"
  echo "- 대상: \`$HEAD_SHA\` (브랜치 \`$(git branch --show-current)\`)"
  echo "- 커밋 안 된 변경: 있음 — \`app/routes.py\`, 아래 diff 에 포함(\`### 작업트리\`)"
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
  echo "작업트리: \`app/routes.py\`(커밋 안 된 변경)"
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
  echo "### 작업트리"
  echo
  echo '```diff'
  git diff --no-color --cached
  git diff --no-color
  echo '```'
  echo
  echo "## 이 브리핑이 담지 않은 것"
  echo
  echo "- 실행 결과 · 테스트 통과 여부"
  echo "- 저장소 설정(브랜치 보호 · 룰셋 · 시크릿 저장소)"
  echo "- 배포 환경 · 운영 데이터 · 배포 이력"
  echo "- 잘라낸 것 없음"
} > .claude/audit-brief.md
