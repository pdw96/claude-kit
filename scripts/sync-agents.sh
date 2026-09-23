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

# **이름이 같은 다른 레포를 덮지 않는다.** 대장은 레포 이름(경로의 끝)으로 줄을
# 가르므로, 다른 조직의 `service` 둘을 심으면 둘째가 첫째 줄을 지워 첫째가
# verify-copies.py 에서 조용히 사라진다(Codex 리뷰). 같은 이름 · 다른 자리면 멈춘다.
python3 - "$SRC/copies.json" "$(basename "$TARGET")" "$DEST" <<'CLASH' || exit 1
import json, os, pathlib, sys
reg, repo, dest = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
if not reg.exists():
    sys.exit(0)
for c in json.loads(reg.read_text(encoding="utf-8")).get("copies", []):
    if c.get("repo") == repo and os.path.normpath(c.get("agents_path", "")) != os.path.normpath(dest):
        sys.exit(f"대장에 같은 이름 {repo!r} 의 다른 사본이 있다: {c.get('agents_path')}\n"
                 f"덮으면 그 사본이 대장에서 사라진다. 대장을 손으로 정리한 뒤 다시 돌려라.")
CLASH

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

# 심은 자리를 대장에 적는다. 이게 없으면 사본이 어디에 있는지 아는 사람이
# 심은 사람뿐이고, verify-copy.py 는 견줄 상대를 못 찾아 아무도 안 돌린다.
python3 - "$SRC" "$DEST" "$SHA" <<'REG'
import json, pathlib, subprocess, sys, datetime
src, dest, sha = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
reg = src / "copies.json"
d = json.loads(reg.read_text(encoding="utf-8")) if reg.exists() else {"copies": []}
full = subprocess.run(["git", "-C", str(src), "rev-parse", "HEAD"],
                      capture_output=True, text=True).stdout.strip() or sha
repo = pathlib.Path(dest).parent.parent.name
row = {"repo": repo, "agents_path": dest, "synced_commit": full,
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
