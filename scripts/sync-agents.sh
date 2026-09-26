#!/usr/bin/env bash
# 감사자 여섯과 브리핑 커맨드를 대상 레포의 .claude/ 에 심는다.
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
TARGET="$(cd "$TARGET" && pwd)"
DEST="$TARGET/.claude/agents"

# **커밋 안 된 원본은 심지 않는다.** 심는 것은 작업트리의 바이트인데 출처에는
# HEAD 를 적으므로, 고치던 중인 감사자를 심으면 대장이 「그 커밋에서 왔다」고
# 거짓을 적는다. 사본 경로가 안 닿는 CI 는 그 출처를 그대로 믿는다(Codex 리뷰).
dirty="$(git -C "$SRC" status --porcelain -- vibe-audit/agents vibe-audit/commands 2>/dev/null || true)"
if [ -n "$dirty" ]; then
  echo "원본에 커밋 안 된 변경이 있다 — 출처를 적을 커밋이 없으므로 심지 않는다:" >&2
  echo "$dirty" >&2
  echo "커밋한 뒤 다시 돌려라." >&2
  exit 1
fi

# **심을 파일은 모두 HEAD 에 추적돼 있어야 한다.** `status --porcelain` 은 무시된(ignored) 파일을
# 안 보여 주는데 아래 고리는 *.md 를 다 심는다 — `.git/info/exclude` 에 넣은 커맨드가 출처 없이
# 퍼졌고, 그 커밋에 없던 이름이라 verify-copies.py 도 레포 고유 파일로 봤다(Codex 리뷰).
untracked=""
for f in "$SRC"/vibe-audit/agents/*.md "$SRC"/vibe-audit/commands/*.md; do
  [ -e "$f" ] || continue
  rel="${f#"$SRC"/}"
  git -C "$SRC" cat-file -e "HEAD:$rel" 2>/dev/null || untracked="$untracked $rel"
done
if [ -n "$untracked" ]; then
  echo "원본에 HEAD 에 없는 파일이 있다 — 출처를 적을 수 없어 심지 않는다:$untracked" >&2
  echo "커밋하거나 치운 뒤 다시 돌려라." >&2
  exit 1
fi

# **--force 는 원본의 역사가 다 있어야 한다.** 물러난 감사자 · 커맨드를 역사에서 찾아 지우므로,
# 얕은 복제에서는 경계 앞에서 물러난 것을 못 보고 남긴 채 대장만 새 커밋으로 옮긴다(Codex 리뷰).
if [ "$FORCE" -eq 1 ] && [ "$(git -C "$SRC" rev-parse --is-shallow-repository 2>/dev/null)" = true ]; then
  echo "원본이 얕은 복제다 — 물러난 감사자 · 커맨드를 가릴 역사가 없어 --force 를 하지 않는다." >&2
  echo "git -C \"$SRC\" fetch --unshallow 로 역사를 받은 뒤 다시 돌려라." >&2
  exit 1
fi

# **이름이 같은 다른 레포를 덮지 않는다.** 대장은 레포 이름(경로의 끝)으로 줄을
# 가르므로, 다른 조직의 `service` 둘을 심으면 둘째가 첫째 줄을 지워 첫째가
# verify-copies.py 에서 조용히 사라진다(Codex 리뷰). 같은 이름 · 다른 자리면 멈춘다.
python3 - "$SRC/copies.json" "$(basename "$TARGET")" "$DEST" <<'CLASH' || exit 1
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
if [ "$FORCE" -eq 0 ]; then
  existing=""
  missing=""
  for f in "$SRC"/vibe-audit/agents/*.md; do
    if [ -e "$DEST/$(basename "$f")" ]; then existing="$existing $(basename "$f")"; else missing="$missing $(basename "$f")"; fi
  done
  for f in "$SRC"/vibe-audit/commands/*.md; do
    [ -e "$f" ] || continue
    if [ -e "$TARGET/.claude/commands/$(basename "$f")" ]; then existing="$existing $(basename "$f")"; else missing="$missing $(basename "$f")"; fi
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

mkdir -p "$DEST"

# 출처는 프론트매터 **뒤**에 넣는다. 앞에 한 줄이라도 있으면 YAML 머리말이
# 파일 첫 줄이 아니게 되어 에이전트가 통째로 안 읽힌다. 두 고리 **앞에서** 정한다 —
# 감사자가 다 있어 첫 고리가 전부 건너뛰면, 새로 생긴 커맨드를 심는 둘째 고리가
# `set -u` 에 `HDR: unbound variable` 로 죽었다(Codex 리뷰).
HDR="<!-- pdw96/claude-kit@$SHA 에서 옴. 이 레포에 맞게 고쳐도 된다 — 원본으로 되먹이지 않는다. -->"

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
  if [ -e "$out" ] && [ "$FORCE" -eq 0 ]; then
    echo "  건너뜀 $name — 이미 있다 (되돌리려면 --force)"
    cskipped=$((cskipped + 1))
    continue
  fi
  awk -v hdr="$HDR" '
    /^---$/ { c++; print; if (c == 2) { print ""; print hdr } next }
    { print }
  ' "$f" > "$out"
  echo "  심음   $name"
  cmds=$((cmds + 1))
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
      *) continue ;;
    esac
    [ -e "$SRC/$gone" ] && continue
    if [ -e "$dir/$(basename "$gone")" ]; then
      rm -f "$dir/$(basename "$gone")"
      echo "  지움   $(basename "$gone") — 원본에서 물러났다"
    fi
  done < <(git -C "$SRC" log --format= --name-only -- vibe-audit/agents vibe-audit/commands | sort -u)
fi

# **하나라도 건너뛰었으면 출처를 다시 적지 않는다.** 건너뛴 파일은 예전 원본에서
# 온 그대로인데 README 와 대장에 지금 HEAD 를 적으면, 원본이 앞서 나간 뒤에도
# 사본이 「지금 것」으로 적힌다. CI 에서는 사본 경로가 안 닿아 verify-copies.py 가
# 대조를 못 하므로 그 거짓 출처를 그대로 믿고 거리 0 을 찍는다(Codex 리뷰).
# 출처는 전부 새로 심었을 때만 옮긴다 — 그 사본이 정말 이 커밋의 것일 때만.
if [ "$skipped" -gt 0 ] || [ "$cskipped" -gt 0 ]; then
  echo
  echo "→ $DEST (감사자 심음 $copied · 건너뜀 $skipped, 커맨드 심음 $cmds · 건너뜀 $cskipped)"
  echo "  건너뛴 것이 있어 출처를 옮기지 않았다 — README · copies.json 은 그대로다."
  echo "  사본을 따라잡았으면 verify-copy.py 로 PASS 를 확인한 뒤 출처를 손으로 옮긴다."
  exit 0
fi

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
echo "  호출: @audit-secrets · @audit-data · @audit-quality · @audit-ops · @audit-contract · @audit-internal"
echo "  PR · 커밋 범위를 볼 때는 먼저: /audit-brief <기준> <감사자>"
