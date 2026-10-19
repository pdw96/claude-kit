#!/usr/bin/env bash
# 감사자 여섯과 브리핑 커맨드 · 브리핑 검사기를 대상 레포의 .claude/ 에 심는다.
#
# 클라우드 레인은 마켓플레이스 설치를 받지 못하므로(README 의 이슈 셋) 파일이
# 레포에 있어야 뜬다. 이 스크립트는 그 사본을 만들고 머리에 출처를 박는다.
#
#   ./scripts/sync-agents.sh ~/src/ERP            # 처음 심기
#   ./scripts/sync-agents.sh ~/src/ERP --merge    # 다시 심기 — 늘 이것
#
# 사본이 이미 있으면 덮어쓰지 않고 멈춘다. 사본은 그 레포에 특화되도록
# 두는 것이 정책이고(README), 덮어쓰면 그 특화가 사라진다.
# 다시 심기는 늘 --merge 다 — 대장의 synced_commit 을 밑으로 파일마다 세 쪽 병합하고, 하나라도 걸리면
# 아무것도 쓰지 않는다(ADR 0038). 사본을 일부러 원본으로 되돌리려면 --force.

set -euo pipefail

FORCE=0
MERGE=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --merge) MERGE=1 ;;
    -*) echo "모르는 옵션: $arg" >&2; exit 2 ;;
    *) TARGET="$arg" ;;
  esac
done

# --merge 의 멈춤마다 이유 코드 한 줄을 stderr 에 찍는다 — bite-gates.sh 가 이 파일의 `merge:<코드>` 를 모아 코드마다
# 그것을 기대하는 시험이 있는지 문다(ADR 0038 의 13). --merge 가 아닌 길은 찍지 않는다 — 그 길의 출력은 그대로다.
why() { if [ "$MERGE" -eq 1 ]; then echo "$1" >&2; fi; }

# P1 — 덮기와 병합은 하나만. 아무것도 보기 전에 멈춘다.
if [ "$FORCE" -eq 1 ] && [ "$MERGE" -eq 1 ]; then
  echo "--force 와 --merge 는 함께 줄 수 없다 — 덮을지 병합할지 하나만 고른다." >&2
  why merge:force-and-merge
  exit 2
fi

if [ -z "$TARGET" ]; then
  echo "사용법: $0 <대상 레포 경로> [--force | --merge]" >&2
  why merge:no-target
  exit 2
fi
if [ ! -d "$TARGET" ]; then
  echo "그런 디렉터리가 없다: $TARGET" >&2
  why merge:target-missing
  exit 1
fi

SRC="$(cd "$(dirname "$0")/.." && pwd)"
SHA="$(git -C "$SRC" rev-parse --short HEAD 2>/dev/null || echo unknown)"
TARGET="$(cd "$TARGET" && pwd)"
DEST="$TARGET/.claude/agents"

# **커밋 안 된 원본은 심지 않는다.** 심는 것은 작업트리의 바이트인데 출처에는
# HEAD 를 적으므로, 고치던 중인 감사자를 심으면 대장이 「그 커밋에서 왔다」고
# 거짓을 적는다. 사본 경로가 안 닿는 CI 는 그 출처를 그대로 믿는다(Codex 리뷰).
dirty="$(git -C "$SRC" status --porcelain -- vibe-audit/agents vibe-audit/commands vibe-audit/scripts 2>/dev/null || true)"
if [ -n "$dirty" ]; then
  echo "원본에 커밋 안 된 변경이 있다 — 출처를 적을 커밋이 없으므로 심지 않는다:" >&2
  echo "$dirty" >&2
  echo "커밋한 뒤 다시 돌려라." >&2
  why merge:src-dirty
  exit 1
fi

# **심을 파일은 모두 HEAD 에 추적돼 있어야 한다.** `status --porcelain` 은 무시된(ignored) 파일을
# 안 보여 주는데 아래 고리는 *.md 를 다 심는다 — `.git/info/exclude` 에 넣은 커맨드가 출처 없이
# 퍼졌고, 그 커밋에 없던 이름이라 verify-copies.py 도 레포 고유 파일로 봤다(Codex 리뷰).
untracked=""
for f in "$SRC"/vibe-audit/agents/*.md "$SRC"/vibe-audit/commands/*.md "$SRC"/vibe-audit/scripts/*.py; do
  [ -e "$f" ] || continue
  rel="${f#"$SRC"/}"
  git -C "$SRC" cat-file -e "HEAD:$rel" 2>/dev/null || untracked="$untracked $rel"
done
if [ -n "$untracked" ]; then
  echo "원본에 HEAD 에 없는 파일이 있다 — 출처를 적을 수 없어 심지 않는다:$untracked" >&2
  echo "커밋하거나 치운 뒤 다시 돌려라." >&2
  why merge:src-untracked
  exit 1
fi

# **--force 는 원본의 역사가 다 있어야 한다.** 물러난 감사자 · 커맨드를 역사에서 찾아 지우므로,
# 얕은 복제에서는 경계 앞에서 물러난 것을 못 보고 남긴 채 대장만 새 커밋으로 옮긴다(Codex 리뷰).
if [ "$FORCE" -eq 1 ] && [ "$(git -C "$SRC" rev-parse --is-shallow-repository 2>/dev/null)" = true ]; then
  echo "원본이 얕은 복제다 — 물러난 감사자 · 커맨드를 가릴 역사가 없어 --force 를 하지 않는다." >&2
  echo "git -C \"$SRC\" fetch --unshallow 로 역사를 받은 뒤 다시 돌려라." >&2
  exit 1
fi
# P2 — **--merge 도 원본의 역사가 다 있어야 한다.** 밑이 대장의 synced_commit 의 작업트리다(ADR 0038 의 2).
if [ "$MERGE" -eq 1 ] && [ "$(git -C "$SRC" rev-parse --is-shallow-repository 2>/dev/null)" = true ]; then
  echo "원본이 얕은 복제다 — 밑을 세울 synced_commit 을 찾을 역사가 없어 --merge 를 하지 않는다." >&2
  echo "git -C \"$SRC\" fetch --unshallow 로 역사를 받은 뒤 다시 돌려라." >&2
  why merge:shallow
  exit 1
fi

# **이름이 같은 다른 레포를 덮지 않는다.** 대장은 레포 이름(경로의 끝)으로 줄을
# 가르므로, 다른 조직의 `service` 둘을 심으면 둘째가 첫째 줄을 지워 첫째가
# verify-copies.py 에서 조용히 사라진다(Codex 리뷰). 같은 이름 · 다른 자리면 멈춘다.
python3 - "$SRC/copies.json" "$(basename "$TARGET")" "$DEST" <<'CLASH' || { why merge:name-clash; exit 1; }
import json, os, pathlib, sys
reg, repo, dest = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
if not reg.exists():
    sys.exit(0)
for c in json.loads(reg.read_text(encoding="utf-8")).get("copies", []):
    if c.get("repo") == repo and os.path.normpath(os.path.expanduser(c.get("agents_path", ""))) != os.path.normpath(dest):
        sys.exit(f"대장에 같은 이름 {repo!r} 의 다른 사본이 있다: {c.get('agents_path')}\n"
                 f"덮으면 그 사본이 대장에서 사라진다. 대장을 손으로 정리한 뒤 다시 돌려라.")
CLASH

# **대장에 없는 자리에 사본이 이미 있으면 아무것도 쓰기 전에 멈춘다.** 그대로
# 가면 있는 파일은 건너뛰고 없는 파일만 심은 뒤, 건너뛴 것이 있어 대장에는 안
# 적는다 — 섞인 사본이 **대장 밖에** 남아 verify-copies.py 가 영영 못 본다(Codex
# 리뷰). 대장에 이미 있는 자리면 지금처럼 있는 것은 두고 출처를 옮기지 않는다.
# --merge 는 이 둘 대신 아래 --merge 블록의 M2 가 묶음을 본다(설계 ② P5).
if [ "$FORCE" -eq 0 ] && [ "$MERGE" -eq 0 ]; then
  existing=""
  missing=""
  for f in "$SRC"/vibe-audit/agents/*.md; do
    if [ -e "$DEST/$(basename "$f")" ] || [ -L "$DEST/$(basename "$f")" ]; then existing="$existing $(basename "$f")"; else missing="$missing $(basename "$f")"; fi
  done
  for f in "$SRC"/vibe-audit/commands/*.md; do
    [ -e "$f" ] || continue
    if [ -e "$TARGET/.claude/commands/$(basename "$f")" ] || [ -L "$TARGET/.claude/commands/$(basename "$f")" ]; then existing="$existing $(basename "$f")"; else missing="$missing $(basename "$f")"; fi
  done
  for f in "$SRC"/vibe-audit/scripts/*.py; do
    [ -e "$f" ] || continue
    if [ -e "$TARGET/.claude/scripts/$(basename "$f")" ] || [ -L "$TARGET/.claude/scripts/$(basename "$f")" ]; then existing="$existing $(basename "$f")"; else missing="$missing $(basename "$f")"; fi
  done
  if [ -n "$existing" ]; then
    python3 - "$SRC/copies.json" "$DEST" <<'KNOWN' || {
import json, os, pathlib, sys
reg, dest = pathlib.Path(sys.argv[1]), os.path.normpath(sys.argv[2])
rows = json.loads(reg.read_text(encoding="utf-8")).get("copies", []) if reg.exists() else []
sys.exit(0 if any(os.path.normpath(os.path.expanduser(c.get("agents_path", ""))) == dest for c in rows) else 1)
KNOWN
      echo "대장에 없는 자리에 사본이 이미 있다:$existing" >&2
      echo "빠진 것만 심으면 섞인 사본이 대장 밖에 남는다. 아무것도 심지 않았다." >&2
      echo "그 사본을 이 커밋으로 덮으려면 --force, 지키려면 대장에 먼저 적어라." >&2
      exit 1
    }
  fi
  # **대장에 있는 자리라도 일부만 있으면 쓰기 전에 멈춘다.** 빠진 것만 심으면 건너뛴 것이
  # 있어 출처를 안 옮기므로, 새로 심은 파일이 옛 synced_commit 아래 들어간다 — 그 커밋에
  # 없던 이름은 verify-copies.py 가 레포 고유 파일로 보고 아무 대조도 안 한다(Codex 리뷰).
  # 섞인 사본을 만들지 않는다. 손으로 따라잡거나 --force 로 이 커밋의 것으로 다 덮는다.
  if [ -n "$existing" ] && [ -n "$missing" ]; then
    echo "사본이 일부만 있다 — 빠진 것:$missing" >&2
    echo "빠진 것만 심으면 그 파일의 출처가 대장에 안 남는다. 아무것도 심지 않았다." >&2
    echo "손으로 옮기고 verify-copy.py 로 PASS 를 본 뒤 대장의 synced_commit 을 옮기거나, --force 로 다 덮어라." >&2
    exit 1
  fi
fi

# 있는지는 `-e` 와 `-L` 로 함께 본다 — 끊긴 링크는 `-e` 로는 없는 것처럼 보여 앞 폴더에 다
# 심은 뒤 cp 에서 멈춘다(Codex 리뷰). --force 로 덮을 때 링크는 지우고 새 파일로 쓴다.
# **쓰기 전에 심을 폴더 자리를 본다.** 그 자리에 파일 · 끊긴 링크가 있으면 앞 폴더에 다 심은
# 뒤 mkdir 에서 멈춰, 대장에 없는 반쪽 사본이 남는다 — 다시 돌리면 섞인 사본으로 거절되고
# --force 도 폴더를 못 만든다(Codex 리뷰).
for d in "$TARGET/.claude" "$DEST" "$TARGET/.claude/commands" "$TARGET/.claude/scripts"; do
  if { [ -e "$d" ] || [ -L "$d" ]; } && [ ! -d "$d" ]; then
    echo "폴더가 설 자리에 폴더가 아닌 것이 있다: $d — 아무것도 심지 않았다." >&2
    why merge:dir-slot-not-dir
    exit 1
  fi
  # 링크로 된 폴더는 `-d` 로는 폴더로 보여, 링크가 가리키는 사본 밖에 심고 대장만 옮긴다(Codex 리뷰)
  if [ -L "$d" ]; then
    echo "폴더가 설 자리가 링크다: $d — 사본 밖에 쓰지 않으려고 아무것도 심지 않았다." >&2
    why merge:dir-slot-link
    exit 1
  fi
done
# 파일이 설 자리에 폴더가 있어도 쓰기 전에 멈춘다 — --force 의 cp 는 그 폴더 **안에** 심고 성공하므로
# 커맨드가 부르는 자리는 여전히 폴더로 남는다(Codex 리뷰)
for f in "$SRC"/vibe-audit/agents/*.md "$SRC"/vibe-audit/commands/*.md "$SRC"/vibe-audit/scripts/*.py; do
  [ -e "$f" ] || continue
  case "$f" in
    */vibe-audit/agents/*)   o="$DEST/$(basename "$f")" ;;
    */vibe-audit/commands/*) o="$TARGET/.claude/commands/$(basename "$f")" ;;
    *)                       o="$TARGET/.claude/scripts/$(basename "$f")" ;;
  esac
  if [ -d "$o" ] && [ ! -L "$o" ]; then
    echo "파일이 설 자리에 폴더가 있다: $o — 아무것도 심지 않았다." >&2
    why merge:file-slot-dir
    exit 1
  fi
done

# ── --merge — 특화가 있는 사본을 다시 심는다(조각 27 · ADR 0038) ─────────────────────────────────────────
# 파일마다 밑(대장의 synced_commit 을 그 커밋의 이 스크립트로 빈 자리에 심은 모양) · 사본 · 새 원본(HEAD 를 같은 식으로
# 심은 모양)으로 `git merge-file` 을 돌린다. 다 사본 밖 임시 폴더 하나에서 하고, 하나라도 걸리면 사본 · 대장에
# 아무것도 쓰지 않는다. 걸리는 자리마다 `merge:<코드>` 를 찍는다 — 번호는 조각 27 설계 ② 다.
if [ "$MERGE" -eq 1 ]; then
  WORK=""
  KEEP=0
  merge_cleanup() {
    [ -n "$WORK" ] || return 0
    local w
    # 작업트리는 비운 대장과 그 커밋의 스크립트가 적은 줄로 더럽다 — --force 없이는 지우지 못한다(M8)
    for w in "$WORK/wt-base" "$WORK/wt-new"; do
      if [ -e "$w" ]; then git -C "$SRC" worktree remove --force "$w" >/dev/null 2>&1 || true; fi
    done
    if [ "$KEEP" -eq 0 ]; then rm -rf "$WORK"; fi
  }
  trap merge_cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM

  # P3 — 대장에 대상 자리를 가리키는 줄이 정확히 하나. `~` 를 풀어 견준다. 줄을 바꿔 다시 쓸 때 다른 줄의 바이트가
  # 그대로이려면 대장이 이 스크립트가 쓰는 꼴이어야 한다(M6).
  if ! row="$(python3 - "$SRC/copies.json" "$DEST" <<'ROW'
import json, os, pathlib, sys
reg, dest = pathlib.Path(sys.argv[1]), os.path.normpath(sys.argv[2])
def stop(code, msg):
    print(f"{code}\t{msg}")
    sys.exit(1)
text = reg.read_text(encoding="utf-8") if reg.is_file() else ""
d = json.loads(text) if text else {"copies": []}
rows = [c for c in d.get("copies", [])
        if os.path.normpath(os.path.expanduser(str(c.get("agents_path", "")))) == dest]
if not rows:
    stop("merge:no-ledger-row", f"대장에 {dest} 를 가리키는 줄이 없다 — 밑으로 삼을 synced_commit 이 없다. 사본을 처음 심는 것은 --merge 없이 돌린다.")
if len(rows) > 1:
    stop("merge:many-ledger-rows", f"대장에 {dest} 를 가리키는 줄이 {len(rows)} 개다({', '.join(str(c.get('repo')) for c in rows)}) — 어느 것이 밑인지 모른다. 대장을 손으로 정리한 뒤 다시 돌려라.")
if json.dumps(d, ensure_ascii=False, indent=2) + "\n" != text:
    stop("merge:ledger-not-canonical", "copies.json 이 이 스크립트가 쓰는 꼴(indent 2)이 아니다 — 그 줄만 바꿔 다시 쓰면 다른 줄의 바이트도 바뀐다. 꼴을 맞춘 뒤 다시 돌려라.")
print(rows[0].get("synced_commit", ""))
ROW
)"; then
    echo "${row#*	}" >&2
    why "${row%%	*}"
    exit 1
  fi
  if [ -z "$row" ] || ! git -C "$SRC" cat-file -e "$row^{commit}" 2>/dev/null; then
    echo "대장의 synced_commit ${row:-(빔)} 이 이 저장소에 없다 — 밑을 세울 수 없다." >&2
    why merge:base-missing
    exit 1
  fi
  BASE="$(git -C "$SRC" rev-parse "$row^{commit}")"
  BASE_SHORT="$(git -C "$SRC" rev-parse --short "$BASE")"
  HEAD_FULL="$(git -C "$SRC" rev-parse HEAD)"

  # P6 — 사본 레포. compare-copies.py 와 같은 기준이다(ADR 0003 · ADR 0038 의 8) — 못 읽거나 못 받으면 「최신」으로 두지 않는다.
  if ! git -C "$TARGET" rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "대상이 git 저장소 안이 아니다: $TARGET — 원격과 견줄 수 없어 병합하지 않는다." >&2
    why merge:copy-not-git
    exit 1
  fi
  branch="$(git -C "$TARGET" ls-remote --symref origin HEAD 2>/dev/null \
    | awk '$1 == "ref:" && $3 == "HEAD" { sub("^refs/heads/", "", $2); print $2; exit }' || true)"
  if [ -z "$branch" ]; then
    echo "사본 레포의 원격 origin 의 기본 가지를 못 읽었다 — 사본이 최신인지 모른다." >&2
    why merge:remote-unknown
    exit 1
  fi
  if ! git -C "$TARGET" fetch --quiet origin "refs/heads/$branch" 2>/dev/null; then
    echo "사본 레포가 origin/$branch 를 못 받았다 — 사본이 최신인지 모른다." >&2
    why merge:fetch-failed
    exit 1
  fi
  behind="$(git -C "$TARGET" rev-list --count HEAD..FETCH_HEAD 2>/dev/null || echo '?')"
  if [ "$behind" != 0 ]; then
    echo "사본 레포 HEAD 가 origin/$branch 보다 $behind 커밋 뒤다 — 원격의 특화를 빠뜨린 병합이 된다. 받은 뒤 다시 돌려라." >&2
    why merge:copy-behind
    exit 1
  fi
  if ! st="$(git -C "$TARGET" status --porcelain --untracked-files=all -- .claude/agents .claude/commands .claude/scripts 2>/dev/null)" \
     || [ -n "$st" ]; then
    echo "사본 자리(감사자 · 커맨드 · 검사기)에 커밋 안 된 것이 있거나 상태를 못 읽었다 — 곧 커밋될 고침일 수 있어 병합하지 않는다:" >&2
    [ -n "${st:-}" ] && echo "$st" >&2
    why merge:copy-dirty
    exit 1
  fi

  # M1 — 재료. 밑과 새 원본은 그 커밋의 작업트리에서 그 커밋의 이 스크립트를 빈 자리에 돌린 모양이다(ADR 0038 의 2).
  # 돌리기 전에 작업트리의 대장을 비운다 — 그 스크립트는 대장에 같은 이름(base · new)의 다른 자리가 있으면 멈춘다.
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/sync-merge.XXXXXX")"
  merge_build() {  # $1=base|new  $2=커밋
    git -C "$SRC" worktree add --detach --quiet "$WORK/wt-$1" "$2" >/dev/null 2>&1 || return 1
    printf '{"copies": []}\n' > "$WORK/wt-$1/copies.json"
    mkdir "$WORK/$1"
    local log
    if ! log="$("$WORK/wt-$1/scripts/sync-agents.sh" "$WORK/$1" 2>&1)"; then
      echo "$log" >&2
      return 1
    fi
  }
  if ! merge_build base "$BASE"; then
    echo "밑을 세우지 못했다 — $BASE_SHORT 의 sync-agents.sh 가 빈 자리에 심다가 멈췄다. 아무것도 쓰지 않았다." >&2
    why merge:base-build-failed
    exit 1
  fi
  if ! merge_build new HEAD; then
    echo "새 원본을 세우지 못했다 — HEAD($SHA)의 sync-agents.sh 가 빈 자리에 심다가 멈췄다. 아무것도 쓰지 않았다." >&2
    why merge:new-build-failed
    exit 1
  fi

  # M2 — 사본 파일 묶음: 밑과 새 원본의 agents/*.md(README.md 포함) · commands/*.md · scripts/*.py. 두 쪽이 같아야 하고
  # (ADR 0038 의 3), 사본에 다 일반 파일로 있어야 한다. 쓰기 전 검사는 묶음에 똑같이 진다(ADR 0038 의 11).
  merge_names() {
    (cd "$1/.claude" 2>/dev/null && for f in agents/*.md commands/*.md scripts/*.py; do
       if [ -e "$f" ] || [ -L "$f" ]; then echo "$f"; fi
     done) | LC_ALL=C sort
  }
  names="$(merge_names "$WORK/base")"
  if [ "$names" != "$(merge_names "$WORK/new")" ]; then
    echo "원본의 파일 묶음이 $BASE_SHORT 와 HEAD($SHA) 사이에 다르다 — 새 파일 · 물러난 파일은 손으로 심는다(ADR 0038 의 3):" >&2
    diff <(echo "$names") <(merge_names "$WORK/new") | sed -n 's/^</  밑에만    /p; s/^>/  새 원본에만/p' >&2 || true
    why merge:bundle-differs
    exit 1
  fi
  bad=""
  while IFS= read -r n; do
    if [ -L "$TARGET/.claude/$n" ] || [ ! -f "$TARGET/.claude/$n" ]; then bad="$bad $n"; fi
  done <<<"$names"
  if [ -n "$bad" ]; then
    echo "사본에 묶음의 파일이 일반 파일로 있지 않다(없음 · 링크 · 폴더):$bad — 아무것도 쓰지 않았다." >&2
    why merge:copy-not-file
    exit 1
  fi
  # P6 의 끝 — 묶음은 다 사본 레포 HEAD 에 추적돼 있다. status 는 무시된 파일을 보이지 않는다.
  bad=""
  while IFS= read -r n; do
    git -C "$TARGET" cat-file -e "HEAD:./.claude/$n" 2>/dev/null || bad="$bad $n"
  done <<<"$names"
  if [ -n "$bad" ]; then
    echo "사본 레포 HEAD 에 없는(무시됐거나 추적 안 된) 묶음 파일이 있다:$bad — 커밋된 사본만 병합한다." >&2
    why merge:copy-not-tracked
    exit 1
  fi

  # P4 — 밑이 HEAD 면 쓸 것이 없다. P5 · P6 을 다 지난 뒤에 본다 — 뒤처지거나 더러운 사본은 같은 커밋이어도 멈춘다.
  if [ "$BASE" = "$HEAD_FULL" ]; then
    echo "대장의 synced_commit 이 HEAD($SHA)와 같다 — 쓸 것이 없다. 아무것도 쓰지 않았다."
    why merge:up-to-date
    exit 0
  fi

  # M3 — README 밖의 여덟은 세 쪽 병합. 충돌 수가 하나라도 0 이 아니면(오류 포함) 멈춘다.
  mkdir -p "$WORK/copy" "$WORK/merged"
  results=""
  conflicted=0
  while IFS= read -r n; do
    mkdir -p "$WORK/copy/$(dirname "$n")" "$WORK/merged/$(dirname "$n")"
    cp -p "$TARGET/.claude/$n" "$WORK/copy/$n"
    [ "$n" = agents/README.md ] && continue
    rc=0
    git merge-file -p -L "사본" -L "밑 $BASE_SHORT" -L "새 원본 $SHA" \
      "$WORK/copy/$n" "$WORK/base/.claude/$n" "$WORK/new/.claude/$n" >"$WORK/merged/$n" 2>/dev/null || rc=$?
    # 1 ~ 127 은 충돌 수, 그 밖(음수가 255 로 온다)은 오류다 — 둘 다 멈춘다
    if [ "$rc" -ne 0 ]; then conflicted=1; fi
    results="$results$n $rc"$'\n'
  done <<<"$names"
  merge_table() {  # $1: 「<이름> <rc>」 줄들 — 사본 대비 병합본에서 더한 줄을 센다. 사본 레포 PR 본문의 파일별 표다.
    python3 - "$WORK" "$1" <<'TABLE'
import difflib, pathlib, sys
work = pathlib.Path(sys.argv[1])
print("| 파일 | 충돌 | 바뀐 줄 |")
print("|---|---|---|")
for line in sys.argv[2].splitlines():
    name, rc = line.rsplit(" ", 1)
    rc = int(rc)
    a = (work / "copy" / name).read_bytes().splitlines(keepends=True)
    m = work / "merged" / name
    b = m.read_bytes().splitlines(keepends=True) if m.is_file() else []
    sm = difflib.SequenceMatcher(None, a, b, autojunk=False)
    added = sum(j2 - j1 for tag, _, _, j1, j2 in sm.get_opcodes() if tag in ("replace", "insert"))
    print(f"| {name} | {rc if rc < 128 else '오류'} | {added} |")
TABLE
  }
  if [ "$conflicted" -eq 1 ]; then
    merge_table "$results"
    KEEP=1
    echo "충돌이 있다 — 사본 · 대장에 아무것도 쓰지 않았다. 그 레포의 PR 에서 ADR 0027 의 2 로 푼다." >&2
    echo "재료와 충돌 표시 병합본: $WORK (base · new · copy · merged — 다 쓰면 지운다)" >&2
    why merge:conflict
    exit 1
  fi

  # M4 — README 는 출처 SHA 한 자리만 바꾼다(ADR 0038 의 1). 세 README 다 출처가 정확히 하나여야 하고, 사본의 것이 밑의 것이다.
  if ! why4="$(python3 - "$WORK" "$BASE_SHORT" "$SHA" <<'README'
import pathlib, re, sys
work, bs, ns = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
pat = re.compile(rb"pdw96/claude-kit@([0-9a-f]+)")
def one(path, who, want):
    data = path.read_bytes()
    hits = list(pat.finditer(data))
    if len(hits) != 1:
        print(f"merge:readme-source-count\t{who} README 에 출처 pdw96/claude-kit@<SHA> 가 {len(hits)} 자리다 — 하나가 아니면 어느 것이 출처인지 가를 수 없다.")
        sys.exit(1)
    got = hits[0].group(1).decode()
    if got != want:
        print(f"merge:readme-source-mismatch\t{who} README 의 출처가 {got} 다 — {want} 여야 한다.")
        sys.exit(1)
    return data, hits[0]
one(work / "base/.claude/agents/README.md", "밑", bs)
one(work / "new/.claude/agents/README.md", "새 원본", ns)
data, hit = one(work / "copy/agents/README.md", "사본", bs)
(work / "merged/agents/README.md").write_bytes(data[:hit.start(1)] + ns.encode() + data[hit.end(1):])
README
)"; then
    echo "${why4#*	} 아무것도 쓰지 않았다." >&2
    why "${why4%%	*}"
    exit 1
  fi
  results="$(printf '%sagents/README.md 0\n' "$results" | LC_ALL=C sort)"

  # M5 — 대장을 옮기는 근거(CLAUDE.md 「금지」)
  if ! vlog="$(python3 "$SRC/scripts/verify-copy.py" "$SRC/vibe-audit/agents" "$WORK/merged/agents" 2>&1)"; then
    echo "$vlog" >&2
    echo "병합본이 verify-copy.py 를 지나지 못한다 — 사본 · 대장에 아무것도 쓰지 않았다." >&2
    why merge:verify-copy-failed
    exit 1
  fi

  # M6 — 쓰기. 묶음을 제자리에 쓰고(파일의 모드는 사본의 것 그대로), 대장의 그 줄의 synced_commit · synced_at 만 바꾼다.
  while IFS= read -r n; do
    cat "$WORK/merged/$n" > "$TARGET/.claude/$n"
  done <<<"$names"
  python3 - "$SRC/copies.json" "$DEST" "$HEAD_FULL" <<'REG'
import datetime, json, os, pathlib, sys
reg, dest, full = pathlib.Path(sys.argv[1]), os.path.normpath(sys.argv[2]), sys.argv[3]
d = json.loads(reg.read_text(encoding="utf-8"))
for c in d["copies"]:
    if os.path.normpath(os.path.expanduser(str(c.get("agents_path", "")))) == dest:
        c["synced_commit"] = full
        c["synced_at"] = datetime.date.today().isoformat()
        print(f"  대장에 적음 {c.get('repo')} → {reg.name} ({full[:12]})")
reg.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
REG

  # M7 — 표와 끝 줄
  echo
  echo "→ $TARGET/.claude — $BASE_SHORT → $SHA 세 쪽 병합"
  merge_table "$results"
  if main_ref="$(git -C "$SRC" for-each-ref --format='%(refname)' refs/remotes/origin/main refs/remotes/origin/master | head -1)" \
     && [ -n "$main_ref" ] && ! git -C "$SRC" merge-base --is-ancestor HEAD "$main_ref" 2>/dev/null; then
    echo "  경고: HEAD($SHA)가 ${main_ref#refs/remotes/} 에 없다 — squash 머지 뒤 이 출처가 사라질 수 있다." >&2
    echo "        머지 뒤 copies.json 의 synced_commit 을 같은 내용의 기본 브랜치 커밋으로 옮겨라." >&2
  fi
  echo "  copies.json 은 사본 레포 PR 이 머지된 뒤에 커밋한다 — 그 PR 이 머지 없이 닫히면 copies.json 의 고침을 되돌린다(ADR 0038 의 9)."
  exit 0
fi

mkdir -p "$DEST"

# 출처는 프론트매터 **뒤**에 넣는다. 앞에 한 줄이라도 있으면 YAML 머리말이
# 파일 첫 줄이 아니게 되어 에이전트가 통째로 안 읽힌다. 두 고리 **앞에서** 정한다 —
# 감사자가 다 있어 첫 고리가 전부 건너뛰면, 새로 생긴 커맨드를 심는 둘째 고리가
# `set -u` 에 `HDR: unbound variable` 로 죽었다(Codex 리뷰).
# 출처 줄은 `sync-slice.sh` 의 HDR 과 글자 그대로 같다 — test-sync-slice.py 가 견준다(ADR 0017 의 5).
HDR="<!-- pdw96/claude-kit@$SHA 에서 옴. 이 레포에서만 참인 고침은 이 사본에만 산다 — 다른 레포에서도 같은 말이면 원본으로 넘긴다. -->"

copied=0
skipped=0
for f in "$SRC"/vibe-audit/agents/*.md; do
  name="$(basename "$f")"
  out="$DEST/$name"
  if { [ -e "$out" ] || [ -L "$out" ]; } && [ "$FORCE" -eq 0 ]; then
    echo "  건너뜀 $name — 이미 있다 (특화됐을 수 있다. 되돌리려면 --force)"
    skipped=$((skipped + 1))
    continue
  fi
  if [ -L "$out" ]; then rm -f "$out"; fi  # 링크를 따라 사본 밖에 쓰지 않는다
  awk -v hdr="$HDR" '
    /^---$/ { c++; print; if (c == 2) { print ""; print hdr } next }
    { print }
  ' "$f" > "$out"
  echo "  심음   $name"
  copied=$((copied + 1))
done

# 브리핑 커맨드도 심는다. 감사자는 Read · Grep · Glob 만 가져 diff 를 스스로
# 구하지 못하므로, 이것이 없으면 「무엇이 바뀌었나」 부류가 전부 확인불가로
# 남는다. 커맨드는 부르는 세션이 돌리므로 감사자의 도구 제한과 무관하다.
CMDDEST="$TARGET/.claude/commands"
mkdir -p "$CMDDEST"
cmds=0
cskipped=0
for f in "$SRC"/vibe-audit/commands/*.md; do
  [ -e "$f" ] || continue
  name="$(basename "$f")"
  out="$CMDDEST/$name"
  if { [ -e "$out" ] || [ -L "$out" ]; } && [ "$FORCE" -eq 0 ]; then
    echo "  건너뜀 $name — 이미 있다 (되돌리려면 --force)"
    cskipped=$((cskipped + 1))
    continue
  fi
  if [ -L "$out" ]; then rm -f "$out"; fi  # 링크를 따라 사본 밖에 쓰지 않는다
  awk -v hdr="$HDR" '
    /^---$/ { c++; print; if (c == 2) { print ""; print hdr } next }
    { print }
  ' "$f" > "$out"
  echo "  심음   $name"
  cmds=$((cmds + 1))
done

# 브리핑 검사기도 심는다. 커맨드가 감사자를 부르기 전에 브리핑을 git 과 대조하는데,
# 플러그인 커맨드 본문에서는 플러그인 폴더 경로가 안 풀리므로(`${CLAUDE_PLUGIN_ROOT}` 는
# 훅 · MCP 설정에서만) 사본은 레포 안의 `.claude/scripts/` 에서 부른다. 머리말을 붙이지
# 않고 바이트 그대로 옮긴다 — 파이썬 파일이라 붙일 자리가 마땅치 않고, 출처는 대장이 든다.
SCRIPTDEST="$TARGET/.claude/scripts"
scripts=0
sskipped=0
for f in "$SRC"/vibe-audit/scripts/*.py; do
  [ -e "$f" ] || continue
  name="$(basename "$f")"
  out="$SCRIPTDEST/$name"
  if { [ -e "$out" ] || [ -L "$out" ]; } && [ "$FORCE" -eq 0 ]; then
    echo "  건너뜀 $name — 이미 있다 (되돌리려면 --force)"
    sskipped=$((sskipped + 1))
    continue
  fi
  if [ -L "$out" ]; then rm -f "$out"; fi  # 링크를 따라 사본 밖에 쓰지 않는다
  mkdir -p "$SCRIPTDEST"
  cp "$f" "$out"
  echo "  심음   $name"
  scripts=$((scripts + 1))
done

# **--force 면 원본에서 물러난 것을 지운다.** 원본 역사에는 있었는데 지금 커밋에 없는
# 감사자 · 커맨드가 사본에 남으면, 대장은 새 커밋을 적는데 옛 커맨드는 여전히 불리고
# verify-copies.py 는 그것을 물러난 것으로 떨어뜨린다(Codex 리뷰). 원본에 한 번도 없던
# 이름은 레포 고유 파일이므로 건드리지 않는다.
if [ "$FORCE" -eq 1 ]; then
  while IFS= read -r gone; do
    case "$gone" in
      vibe-audit/agents/*.md)   dir="$DEST" ;;
      vibe-audit/commands/*.md) dir="$CMDDEST" ;;
      vibe-audit/scripts/*.py)  dir="$SCRIPTDEST" ;;
      *) continue ;;
    esac
    [ -e "$SRC/$gone" ] && continue
    if [ -e "$dir/$(basename "$gone")" ]; then
      rm -f "$dir/$(basename "$gone")"
      echo "  지움   $(basename "$gone") — 원본에서 물러났다"
    fi
  done < <(git -C "$SRC" log --format= --name-only -- vibe-audit/agents vibe-audit/commands vibe-audit/scripts | sort -u)
fi

# **하나라도 건너뛰었으면 출처를 다시 적지 않는다.** 건너뛴 파일은 예전 원본에서
# 온 그대로인데 README 와 대장에 지금 HEAD 를 적으면, 원본이 앞서 나간 뒤에도
# 사본이 「지금 것」으로 적힌다. CI 에서는 사본 경로가 안 닿아 verify-copies.py 가
# 대조를 못 하므로 그 거짓 출처를 그대로 믿고 거리 0 을 찍는다(Codex 리뷰).
# 출처는 전부 새로 심었을 때만 옮긴다 — 그 사본이 정말 이 커밋의 것일 때만.
if [ "$skipped" -gt 0 ] || [ "$cskipped" -gt 0 ] || [ "$sskipped" -gt 0 ]; then
  echo
  echo "→ $DEST (감사자 심음 $copied · 건너뜀 $skipped, 커맨드 심음 $cmds · 건너뜀 $cskipped, 검사기 심음 $scripts · 건너뜀 $sskipped)"
  echo "  건너뛴 것이 있어 출처를 옮기지 않았다 — README · copies.json 은 그대로다."
  echo "  사본을 따라잡았으면 verify-copy.py 로 PASS 를 확인한 뒤 출처를 손으로 옮긴다."
  exit 0
fi

cat > "$DEST/README.md" <<EOF
# 감사자

\`pdw96/claude-kit@$SHA\` 의 \`vibe-audit\` 플러그인에서 온 사본이다.

**이 레포에서만 참인 고침은 이 사본에만 산다.** 원본은 아무 레포에도 안 들어가 본
일반형으로 남아 있어야 하므로, 이 레포의 특화는 그쪽으로 올리지 않는다 — 갈리는 것이
정상인 관계다. 다른 레포에서도 같은 말인 고침(감사자 자체의 결함)은 원본으로 넘긴다.

체크 항목을 이 레포에 맞게 좁히는 것이 사본을 두는 이유다 — 다만 **첫 감사를
돌린 뒤에** 실제 발견에서 뽑는다. 미리 지어낸 항목은 재지 않고 단정한 것이다.

여섯 다 \`tools: ["Read", "Grep", "Glob"]\` 이라 고칠 도구가 없다. 그 줄을 지우면
이것들은 감사자가 아니게 된다.
EOF

# **기능 브랜치의 커밋이면 경고한다.** 대장은 이 HEAD 를 출처로 적는데, 그 커밋이 squash · rebase 로
# 머지되고 브랜치가 지워지면 가리킬 커밋이 사라져 verify-copies.py 가 떨어진다(Codex 리뷰). 기본
# 브랜치에서 심는 것이 정석이고, 기능 브랜치에서 심었다면 머지 뒤 대장의 synced_commit 을 같은 내용의
# 기본 브랜치 커밋으로 옮긴다(evals/README.md 34차).
if main_ref="$(git -C "$SRC" for-each-ref --format='%(refname)' refs/remotes/origin/main refs/remotes/origin/master | head -1)" \
   && [ -n "$main_ref" ] && ! git -C "$SRC" merge-base --is-ancestor HEAD "$main_ref" 2>/dev/null; then
  echo "  경고: HEAD($SHA)가 ${main_ref#refs/remotes/} 에 없다 — squash 머지 뒤 이 출처가 사라질 수 있다." >&2
  echo "        머지 뒤 copies.json 의 synced_commit 을 같은 내용의 기본 브랜치 커밋으로 옮겨라." >&2
fi

# 심은 자리를 대장에 적는다. 이게 없으면 사본이 어디에 있는지 아는 사람이
# 심은 사람뿐이고, verify-copy.py 는 견줄 상대를 못 찾아 아무도 안 돌린다.
python3 - "$SRC" "$DEST" "$SHA" <<'REG'
import json, os, pathlib, subprocess, sys, datetime
src, dest, sha = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
reg = src / "copies.json"
d = json.loads(reg.read_text(encoding="utf-8")) if reg.exists() else {"copies": []}
full = subprocess.run(["git", "-C", str(src), "rev-parse", "HEAD"],
                      capture_output=True, text=True).stdout.strip() or sha
repo = pathlib.Path(dest).parent.parent.name
# 홈 아래면 `~/…` 로 적는다. 대장은 커밋되는 파일이라 절대 경로를 적으면 심은 사람의
# 계정 이름과 비공개 디렉터리 이름이 저장소에 남는다(Codex 리뷰). verify-copies.py 는
# `expanduser()` 로 풀어 읽으므로, 같은 자리에 둔 다른 사람의 기계에서도 닿는다.
home = os.path.expanduser("~")
where = "~" + dest[len(home):] if home not in ("", "/") and (dest == home or dest.startswith(home + os.sep)) else dest
row = {"repo": repo, "agents_path": where, "synced_commit": full,
       "synced_at": datetime.date.today().isoformat()}
rows = [c for c in d.get("copies", []) if c.get("repo") != repo]
rows.append(row)
d["copies"] = sorted(rows, key=lambda c: c["repo"])
reg.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"  대장에 적음 {repo} → {reg.name}")
REG

echo
echo "→ $DEST (감사자 심음 $copied · 건너뜀 $skipped)"
echo "→ $CMDDEST (커맨드 심음 $cmds)"
echo "→ $SCRIPTDEST (검사기 심음 $scripts)"
echo "  호출: @audit-secrets · @audit-data · @audit-quality · @audit-ops · @audit-contract · @audit-internal"
echo "  PR · 커밋 범위를 볼 때는 먼저: /audit-brief <기준> <감사자>"
