#!/usr/bin/env bash
# 감사자 여섯을 대상 레포의 .claude/agents/ 에 심는다.
#
# 클라우드 레인은 마켓플레이스 설치를 받지 못하므로(README 의 이슈 셋) 파일이
# 레포에 있어야 뜬다. 이 스크립트는 그 사본을 만들고 머리에 출처를 박는다.
#
#   ./scripts/sync-agents.sh ~/src/ERP
#
# 사본이 이미 있으면 덮어쓰지 않고 멈춘다. 사본은 그 레포에 특화되도록
# 두는 것이 정책이고(README), 덮어쓰면 그 특화가 사라진다.
# 일부러 되돌리려면 --force.

set -euo pipefail

FORCE=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -*) echo "모르는 옵션: $arg" >&2; exit 2 ;;
    *) TARGET="$arg" ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "사용법: $0 <대상 레포 경로> [--force]" >&2
  exit 2
fi
if [ ! -d "$TARGET" ]; then
  echo "그런 디렉터리가 없다: $TARGET" >&2
  exit 1
fi

SRC="$(cd "$(dirname "$0")/.." && pwd)"
SHA="$(git -C "$SRC" rev-parse --short HEAD 2>/dev/null || echo unknown)"
DEST="$TARGET/.claude/agents"

mkdir -p "$DEST"

copied=0
skipped=0
for f in "$SRC"/vibe-audit/agents/*.md; do
  name="$(basename "$f")"
  out="$DEST/$name"
  if [ -e "$out" ] && [ "$FORCE" -eq 0 ]; then
    echo "  건너뜀 $name — 이미 있다 (특화됐을 수 있다. 되돌리려면 --force)"
    skipped=$((skipped + 1))
    continue
  fi
  # 출처는 프론트매터 **뒤**에 넣는다. 앞에 한 줄이라도 있으면 YAML 머리말이
  # 파일 첫 줄이 아니게 되어 에이전트가 통째로 안 읽힌다.
  HDR="<!-- pdw96/claude-kit@$SHA 에서 옴. 이 레포에 맞게 고쳐도 된다 — 원본으로 되먹이지 않는다. -->"
  awk -v hdr="$HDR" '
    /^---$/ { c++; print; if (c == 2) { print ""; print hdr } next }
    { print }
  ' "$f" > "$out"
  echo "  심음   $name"
  copied=$((copied + 1))
done

cat > "$DEST/README.md" <<EOF
# 감사자

\`pdw96/claude-kit@$SHA\` 의 \`vibe-audit\` 플러그인에서 온 사본이다.

**이 사본이 이 레포의 진실이다.** 원본은 아무 레포에도 안 들어가 본 일반형으로
남아 있어야 하므로, 여기서 고친 것을 그쪽으로 올리지 않는다. 갈리는 것이 정상인
관계다.

체크 항목을 이 레포에 맞게 좁히는 것이 사본을 두는 이유다 — 다만 **첫 감사를
돌린 뒤에** 실제 발견에서 뽑는다. 미리 지어낸 항목은 재지 않고 단정한 것이다.

여섯 다 \`tools: ["Read", "Grep", "Glob"]\` 이라 고칠 도구가 없다. 그 줄을 지우면
이것들은 감사자가 아니게 된다.
EOF

echo
echo "→ $DEST (심음 $copied · 건너뜀 $skipped)"
echo "  호출: @audit-secrets · @audit-data · @audit-quality · @audit-ops · @audit-contract · @audit-internal"
