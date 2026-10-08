#!/usr/bin/env bash
# `vibe-slice` 의 스킬(`slice-docs` · `slice-review` …)을 대상 레포의 .claude/skills/ 에 다 심는다.
#
# 클라우드 레인은 마켓플레이스 설치를 받지 못하므로(README 의 이슈 셋) 스킬이 레포에
# 있어야 뜬다. 대화형 세션은 `vibe-slice` 플러그인으로 받는다(ADR 0013 의 1).
#
#   ./scripts/sync-slice.sh ~/src/ERP
#   ./scripts/sync-slice.sh ~/src/ERP --force    # 있는 사본을 폴더째 덮는다
#
# 감사자 사본(`sync-agents.sh`)과 규칙이 다르다(ADR 0013 의 5 · 7) — 대장(copies.json)에 적지
# 않고, 비교 · 되먹임의 대상이 아니며, 덮을 때는 폴더째 덮는다. 출처는 사본 SKILL.md 머리 한 줄이
# 든다. 보장하는 것은 조각 5 설계 ② C1 ~ C5 이고, 조각 6 설계 ② 가 그것을 스킬 하나에서
# `vibe-slice/skills/` 아래 스킬 전부로 넓혔다 — 스킬마다 고르게 하면 한 레포 안에서 두 스킬의 판이
# 갈린다(ADR 0014 의 7). 조각 8 설계 ② 가 P1 · L1 ~ L3 · H1 을 더했다 — 절차 지도 링크를 출처 커밋으로
# 박고, 원격에 없는 원본은 심지 않는다(ADR 0017).

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
REL="vibe-slice/skills"
TARGET="$(cd "$TARGET" && pwd)"

if ! SHA="$(git -C "$SRC" rev-parse --short HEAD 2>/dev/null)"; then
  echo "원본($SRC)의 HEAD 를 읽지 못한다 — 출처를 적을 커밋이 없으므로 심지 않는다." >&2
  exit 1
fi
# 링크는 전체 sha 로 박는다 — 짧은 sha 는 저장소가 커져 앞자리가 겹치면 GitHub 이 열지 못한다. 출처
# 줄은 짧은 sha 그대로다(ADR 0017 의 6).
FULL="$(git -C "$SRC" rev-parse HEAD)"

# P1 **원격 가지에 없는 원본은 심지 않는다.** 사본의 절차 지도 링크가 이 커밋을 가리키므로, 푸시하지
# 않은 커밋이면 그 링크가 열리지 않는다. 로컬에 받아 온 원격 추적 가지만 본다(ADR 0017 의 4).
if [ -z "$(git -C "$SRC" branch -r --contains HEAD 2>/dev/null)" ]; then
  echo "원본 HEAD($SHA)가 원격 가지 어디에도 없다 — 사본의 링크가 열리지 않으므로 심지 않는다." >&2
  echo "푸시했으면 받아 와라(git fetch)." >&2
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

# 심을 스킬 — HEAD 에 추적된 `vibe-slice/skills/<스킬>/` 폴더마다 하나. 없으면 심을 것이 없다.
SKILLS=()
while IFS= read -r d; do SKILLS+=("${d#"$REL"/}"); done < <(git -C "$SRC" ls-tree -d --name-only HEAD -- "$REL/")
if [ "${#SKILLS[@]}" -eq 0 ]; then
  echo "원본 HEAD 에 $REL/ 아래 스킬 폴더가 없다 — 심을 것이 없다." >&2
  exit 1
fi

# L2 **받는 claude-kit 링크 꼴은 `github.com/pdw96/claude-kit/blob/main/` 하나다.** 그 밖의 꼴(`tree/main` ·
# 다른 가지 · 커밋 · `raw`)이 심을 파일에 있으면 고정 없이 사본에 새므로 심지 않는다 — 원본에 새 꼴을
# 더한 PR 이 이 꼴을 넓힌다(조각 8 설계 ③).
LINK='github.com/pdw96/claude-kit/blob/main/'
bad=""
while IFS= read -r rel; do
  hits="$(git -C "$SRC" show "HEAD:$rel" | sed 's#github\.com/pdw96/claude-kit/blob/main/##g' \
    | grep -n -E 'github(usercontent)?\.com/pdw96/claude-kit' || true)"
  [ -z "$hits" ] || bad="$bad$(printf '%s\n' "$hits" | awk -v f="$rel" '{ print "  " f ":" $0 }')"$'\n'
done < <(git -C "$SRC" ls-tree -r --name-only HEAD -- "$REL")
if [ -n "$bad" ]; then
  echo "원본에 받지 않는 claude-kit 링크 꼴이 있다 — 고정할 수 없어 아무것도 심지 않았다:" >&2
  printf '%s' "$bad" >&2
  exit 1
fi

# C4 **심을 자리가 링크이거나 폴더가 아니면 --force 여도 멈춘다.** 링크를 따라가면 대상 레포 밖에
# 쓰고, 파일 · 끊긴 링크를 지우고 가면 사본이 아닌 것을 지운다. 스킬 폴더마다 본다.
SPOTS=("$TARGET/.claude" "$TARGET/.claude/skills")
for k in "${SKILLS[@]}"; do SPOTS+=("$TARGET/.claude/skills/$k"); done
for d in "${SPOTS[@]}"; do
  if [ -L "$d" ]; then
    echo "심을 자리가 링크다: $d — 레포 밖에 쓰지 않으려고 아무것도 심지 않았다." >&2
    exit 1
  fi
  if [ -e "$d" ] && [ ! -d "$d" ]; then
    echo "폴더가 설 자리에 폴더가 아닌 것이 있다: $d — 아무것도 심지 않았다." >&2
    exit 1
  fi
done

# C3 **심을 스킬 가운데 하나라도 폴더로 있으면 --force 없이는 덮지 않는다.** 사본은 그 레포에 맞게
# 고쳐도 되는 것이라, 덮으면 그 특화가 사라진다. --force 면 심을 스킬 폴더를 다 비우고 다시 심는다 —
# 대상 .claude/skills/ 의 그 밖 폴더(그 레포의 다른 스킬)는 건드리지 않는다.
have=""
for k in "${SKILLS[@]}"; do
  [ -d "$TARGET/.claude/skills/$k" ] && have="$have $k"
done
if [ -n "$have" ]; then
  if [ "$FORCE" -eq 0 ]; then
    echo "사본이 이미 있다:$have — 아무것도 심지 않았다." >&2
    echo "이 커밋의 것으로 덮으려면 --force (그 레포에서 고친 것은 사라진다)." >&2
    exit 1
  fi
  for k in "${SKILLS[@]}"; do rm -rf "${TARGET:?}/.claude/skills/$k"; done
fi

# H1 출처 줄 — `sync-agents.sh` 의 HDR 과 글자 그대로 같다(H2, test-sync-slice.py 가 견준다).
HDR="<!-- pdw96/claude-kit@$SHA 에서 옴. 이 레포에서만 참인 고침은 이 사본에만 산다 — 다른 레포에서도 같은 말이면 원본으로 넘긴다. -->"
count=0
while IFS= read -r rel; do
  out="$TARGET/.claude/skills/${rel#"$REL"/}"
  mkdir -p "$(dirname "$out")"
  # L1 링크가 든 파일만 바꿔 쓴다 — 나머지는 바이트 그대로다. grep -q 는 다 읽기 전에 끝나 앞의
  # git show 가 SIGPIPE 로 죽고, pipefail 이 그것을 「없다」로 읽는다 — 그래서 다 읽힌다.
  if git -C "$SRC" show "HEAD:$rel" | grep -F "$LINK" >/dev/null; then
    pin() { sed "s#github\.com/pdw96/claude-kit/blob/main/#github.com/pdw96/claude-kit/blob/$FULL/#g"; }
  else
    pin() { cat; }
  fi
  if [ "$(basename "$rel")" = "SKILL.md" ] && [ "$(dirname "$(dirname "$rel")")" = "$REL" ]; then
    # 출처는 프론트매터 **뒤**에 넣는다 — 앞에 한 줄이라도 있으면 머리말이 안 읽힌다.
    git -C "$SRC" show "HEAD:$rel" | pin | awk -v hdr="$HDR" '
      /^---$/ { c++; print; if (c == 2) { print ""; print hdr } next }
      { print }
    ' > "$out"
  else
    git -C "$SRC" show "HEAD:$rel" | pin > "$out"
  fi
  count=$((count + 1))
done < <(git -C "$SRC" ls-tree -r --name-only HEAD -- "$REL")

echo "→ $TARGET/.claude/skills/{$(IFS=,; echo "${SKILLS[*]}")} (파일 $count · 출처 pdw96/claude-kit@$SHA · 링크 blob/$FULL/)"
echo "  대상 레포에 커밋하는 것은 그 레포의 일이다. 클라우드 세션에서는 /slice-docs · /slice-review 로 부른다."
