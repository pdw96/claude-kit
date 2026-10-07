#!/usr/bin/env bash
# 조각 문서 스킬(`vibe-slice` 의 `slice-docs`)을 대상 레포의 .claude/skills/ 에 심는다.
#
# 클라우드 레인은 마켓플레이스 설치를 받지 못하므로(README 의 이슈 셋) 스킬이 레포에
# 있어야 뜬다. 대화형 세션은 `vibe-slice` 플러그인으로 받는다(ADR 0013 의 1).
#
#   ./scripts/sync-slice.sh ~/src/ERP
#   ./scripts/sync-slice.sh ~/src/ERP --force    # 있는 사본을 폴더째 덮는다
#
# 감사자 사본(`sync-agents.sh`)과 규칙이 다르다(ADR 0013 의 5 · 7) — 대장(copies.json)에 적지
# 않고, 비교 · 되먹임의 대상이 아니며, 덮을 때는 폴더째 덮는다. 출처는 사본 SKILL.md 머리 한 줄이
# 든다. 보장하는 것은 조각 5 설계 ② C1 ~ C5.

set -euo pipefail

usage() { echo "사용법: $0 <대상 레포 경로> [--force]" >&2; exit 2; }

FORCE=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -*) echo "모르는 옵션: $arg" >&2; usage ;;
    *)
      if [ -n "$TARGET" ]; then echo "대상 경로는 하나만 받는다: $TARGET · $arg" >&2; usage; fi
      TARGET="$arg" ;;
  esac
done
[ -n "$TARGET" ] || usage
if [ ! -d "$TARGET" ]; then
  echo "그런 디렉터리가 없다: $TARGET" >&2
  exit 1
fi

SRC="$(cd "$(dirname "$0")/.." && pwd)"
REL="vibe-slice/skills/slice-docs"
TARGET="$(cd "$TARGET" && pwd)"

if ! SHA="$(git -C "$SRC" rev-parse --short HEAD 2>/dev/null)"; then
  echo "원본($SRC)의 HEAD 를 읽지 못한다 — 출처를 적을 커밋이 없으므로 심지 않는다." >&2
  exit 1
fi

# C2 **커밋 안 된 원본은 심지 않는다.** 출처에 HEAD 를 적으므로, 고치던 중인 틀을 심으면 사본이
# 「그 커밋에서 왔다」고 거짓을 적는다.
dirty="$(git -C "$SRC" status --porcelain -- "$REL")"
if [ -n "$dirty" ]; then
  echo "원본에 커밋 안 된 변경이 있다 — 심지 않는다:" >&2
  echo "$dirty" >&2
  exit 1
fi
# C2 **HEAD 에 없는 파일도 심지 않는다.** `status --porcelain` 은 무시된(ignored) 파일을 안 보여
# 준다 — 폴더의 파일을 하나씩 HEAD 와 맞댄다(sync-agents.sh 가 같은 까닭으로 그렇게 한다).
untracked=""
while IFS= read -r -d '' f; do
  rel="${f#"$SRC"/}"
  git -C "$SRC" cat-file -e "HEAD:$rel" 2>/dev/null || untracked="$untracked $rel"
done < <(find "$SRC/$REL" \( -type f -o -type l \) -print0)
if [ -n "$untracked" ]; then
  echo "원본에 HEAD 에 없는 파일이 있다 — 출처를 적을 수 없어 심지 않는다:$untracked" >&2
  exit 1
fi

# C4 **심을 자리가 링크이거나 폴더가 아니면 --force 여도 멈춘다.** 링크를 따라가면 대상 레포 밖에
# 쓰고, 파일 · 끊긴 링크를 지우고 가면 사본이 아닌 것을 지운다.
DEST="$TARGET/.claude/skills/slice-docs"
for d in "$TARGET/.claude" "$TARGET/.claude/skills" "$DEST"; do
  if [ -L "$d" ]; then
    echo "심을 자리가 링크다: $d — 레포 밖에 쓰지 않으려고 아무것도 심지 않았다." >&2
    exit 1
  fi
  if [ -e "$d" ] && [ ! -d "$d" ]; then
    echo "폴더가 설 자리에 폴더가 아닌 것이 있다: $d — 아무것도 심지 않았다." >&2
    exit 1
  fi
done

# C3 **사본이 폴더로 있으면 --force 없이는 덮지 않는다.** 사본은 그 레포에 맞게 고쳐도 되는
# 것이라, 덮으면 그 특화가 사라진다. --force 면 폴더째 비우고 다시 심는다.
if [ -d "$DEST" ]; then
  if [ "$FORCE" -eq 0 ]; then
    echo "사본이 이미 있다: $DEST — 아무것도 심지 않았다." >&2
    echo "이 커밋의 것으로 덮으려면 --force (그 레포에서 고친 것은 사라진다)." >&2
    exit 1
  fi
  rm -rf "$DEST"
fi

mkdir -p "$DEST"
HDR="<!-- pdw96/claude-kit@$SHA 에서 옴. 이 레포에 맞게 고쳐도 된다 — 원본으로 되먹이지 않는다. -->"
count=0
while IFS= read -r rel; do
  out="$DEST/${rel#"$REL"/}"
  mkdir -p "$(dirname "$out")"
  if [ "$rel" = "$REL/SKILL.md" ]; then
    # 출처는 프론트매터 **뒤**에 넣는다 — 앞에 한 줄이라도 있으면 머리말이 안 읽힌다.
    git -C "$SRC" show "HEAD:$rel" | awk -v hdr="$HDR" '
      /^---$/ { c++; print; if (c == 2) { print ""; print hdr } next }
      { print }
    ' > "$out"
  else
    git -C "$SRC" show "HEAD:$rel" > "$out"
  fi
  count=$((count + 1))
done < <(git -C "$SRC" ls-tree -r --name-only HEAD -- "$REL")

echo "→ $DEST (파일 $count · 출처 pdw96/claude-kit@$SHA)"
echo "  대상 레포에 커밋하는 것은 그 레포의 일이다. 클라우드 세션에서는 /slice-docs 로 부른다."
