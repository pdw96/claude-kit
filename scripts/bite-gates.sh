#!/usr/bin/env bash
# 키 없이 도는 검사가 **무는지** 본다 — 검사마다 변조본을 만들어 떨어지는지 본다. 모델도 API 도 안 쓴다.
#
#   ./scripts/bite-gates.sh      # gates.sh 가 부른다
#
# **왜 여기 있나.** 이 본문은 CI 「게이트가 무는가」 스텝(`eval.yml`)이었다. `eval.yml` 은 수트에 깃발을 넘겨
# 통째로 수트 지문(`eval-key.py`)에 들어, 변조본만 고쳐도 route 수트가 다시 돌았다. 그래서 스텝의 본문을 글자
# 그대로 옮기고 `gates.sh` 가 부른다(ADR 0020 의 1 · 2). 스텝과 다른 자리는 여섯뿐이다 — 이 머리, 저장소 맨 위를
# git 에서 읽는 것(CI 의 `$GITHUB_WORKSPACE` 대신), 임시 폴더를 한 폴더에 모아 끝날 때 지우는 것, 제자리 변조를
# 백업에서 되돌리는 것(ADR 0020 의 3), 수트 모델 id 를 `run-evals.sh` 에서 읽는 것(ADR 0020 의 4), 끝의 「변조본
# 파일이 수트 지문 밖인가」(ADR 0020 의 6).
#
# **제자리에서 흔드는 파일.** `copies.json` 과 지문 시험의 파일은 사본이 아니라 제자리에서 흔든다. 흔들기 전에
# 실행 비트까지 임시 폴더로 베끼고 거기서 되돌린다 — 변조본이 떨어져 끝나도 · INT · TERM 으로 끊겨도 trap 이
# 되돌리므로 커밋 안 한 수정이 남는다. SIGKILL 에는 trap 이 돌지 않는다 — 처음에 찍는 자리에 남은 파일을
# 저장소 맨 위의 같은 경로로 손으로 되돌려 놓는다. 같은 작업트리에서 둘을 함께 돌리지 않는다 — 서로 흔든다.
#
# `::error::` 는 CI 에서 주석이 되고 로컬에서는 글자 그대로 찍힌다. `sync-agents.sh` 변조본은 저장소를 clone
# 해 심으므로 커밋한 `sync-agents.sh` 를 본다.
set -euo pipefail
R=$(git rev-parse --show-toplevel)
cd "$R"

# 임시 폴더는 다 한 폴더 아래 만들고 끝날 때 지운다 — 본문의 mktemp 는 지우지 않아, 로컬에서 돌릴 때마다 /tmp 에
# 서른 남짓 · 45MB 쯤이 남았다(CI 는 러너를 버려 몰랐다). 조각 11 설계 끝 「PR B 에서 정했다」.
tmp=$(mktemp -d)
export TMPDIR="$tmp"

# 제자리 변조의 백업(ADR 0020 의 3). hold 는 흔들기 전에 실행 비트까지 베끼고, undo 는 거기서 되돌린 뒤 백업을
# 지운다. 끝날 때 남은 백업은 trap 이 되돌린 뒤 임시 폴더를 지운다 — 떨어져 끝나도 · INT · TERM 으로 끊겨도.
held=$(mktemp -d)
echo "제자리에서 흔드는 파일은 흔들기 전에 $held 에 베낀다 — 되돌리지 못하고 죽으면 거기 남은 파일을 저장소 맨 위의 같은 경로로 되돌려 놓는다"
hold() {  # $1=저장소 맨 위 기준 경로
  [ -e "$held/$1" ] && return 0
  mkdir -p "$held/$(dirname "$1")"; cp -p "$1" "$held/$1"
}
undo() {  # $1=hold 한 경로 — 지운 파일 · 뺀 실행 비트도 돌아온다
  cp -p "$held/$1" "$R/$1"; rm "$held/$1"
}
undo_all() {
  (cd "$held" && find . -type f -print0) | while IFS= read -r -d '' p; do undo "${p#./}"; done
  rm -rf "$held"
}
trap 'st=$?; undo_all; rm -rf "$tmp"; exit $st' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# 수트 모델 id 는 run-evals.sh 의 DEFAULT_MODEL= 한 줄만 든다(ADR 0020 의 4). 가짜 트레이스가 그 id 로 돌았다고
# 적어야 러너가 받으므로 여기서 읽는다 — 수트 모델을 바꿔도 이 파일은 그대로다. 읽은 id 로 변조본이 무는지
# 설 수 없는 꼴이면 아무 변조본도 돌리기 전에 멈춘다. 조각 11 설계 ② D1 ~ D3.
n=$(grep -cE '^[[:space:]]*DEFAULT_MODEL=' scripts/run-evals.sh || true)
model=$(sed -nE 's/^[[:space:]]*DEFAULT_MODEL=//p' scripts/run-evals.sh | head -1)
id_re='^([A-Za-z0-9._-]+)(\[[A-Za-z0-9._-]*\])?$'
if [ "$n" != 1 ] || ! [[ "$model" =~ $id_re ]]; then
  echo "::error::run-evals.sh 의 DEFAULT_MODEL= 줄이 하나가 아니거나($n) 값이 모델 id 가 아니다('$model')"; exit 1
fi
# 이름이 겹치는 딴 모델 — 꼬리표([…])와 날짜(-<여덟 자리>)를 뗀 이름에서 마지막 -<조각> 을 뗀 것. 러너는 꼬리표 ·
# 날짜만 다른 이름을 같은 모델로 받으므로 그것부터 뗀다. 그 이름을 요청했는데 수트 모델로 돈 회차는 받으면 안 된다
name=${BASH_REMATCH[1]}
if [[ "$name" =~ ^(.+)-[0-9]{8}$ ]]; then name=${BASH_REMATCH[1]}; fi
near=${name%-*}
if [ "$near" = "$name" ]; then
  echo "::error::수트 모델 id($model)에 꼬리표 · 날짜 말고 - 가 없어 이름이 겹치는 딴 모델을 만들 수 없다"; exit 1
fi
# 딴 모델(claude-haiku-4-5)과 날짜가 붙은 같은 모델(claude-haiku-4-5-20251001)은 글자 그대로다 — 수트 모델이
# 그 이름이면 딴 모델이 딴 모델이 아니다
if [[ "$model" == claude-haiku-4-5* ]]; then
  echo "::error::수트 모델 id($model)가 claude-haiku-4-5 로 시작해 딴 모델 변조본이 서지 않는다"; exit 1
fi
export BITE_MODEL="$model"
echo "수트 모델: $model (run-evals.sh) — 이름이 겹치는 딴 모델: $near"

# verify-copy.py — tools 를 변조한 사본은 실패해야 한다
python3 scripts/verify-copy.py vibe-audit/agents
t=$(mktemp -d); cp vibe-audit/agents/*.md "$t/"
sed -i 's/^tools: .*/tools: ["Read", "Grep", "Glob", "Edit"]/' "$t/audit-secrets.md"
if python3 scripts/verify-copy.py "$t" >/dev/null 2>&1; then
  echo "::error::verify-copy.py 가 tools 변조를 통과시켰다"; exit 1
fi
# verify-copy.py — 원본 폴더에 감사자가 아닌 에이전트가 있으면 실패해야 한다(Codex 33차)
t=$(mktemp -d); cp vibe-audit/agents/*.md "$t/"
printf -- '---\nname: helper\ndescription: x\ntools: ["Read", "Edit", "Write"]\n---\n' > "$t/helper.md"
if python3 scripts/verify-copy.py "$t" "$t" >/dev/null 2>&1; then
  echo "::error::verify-copy.py 가 감사자가 아닌 에이전트가 섞인 원본을 통과시켰다"; exit 1
fi
# README.md 라는 이름도 예외가 아니다 — 플러그인에서는 agents/*.md 가 다 에이전트다(Codex 34차)
rm "$t/helper.md"; printf -- '---\nname: readme\ndescription: x\ntools: ["Read", "Edit", "Write"]\n---\n' > "$t/README.md"
if python3 scripts/verify-copy.py "$t" "$t" >/dev/null 2>&1; then
  echo "::error::verify-copy.py 가 README.md 로 숨긴 에이전트를 통과시켰다"; exit 1
fi
# 원본 감사자의 머리말 name 이 파일 이름과 다르면 실패해야 한다(Codex 35차)
t=$(mktemp -d); cp vibe-audit/agents/*.md "$t/"
sed -i '0,/^name: .*/s//name: audit-opx/' "$t/audit-ops.md"
if python3 scripts/verify-copy.py "$t" "$t" >/dev/null 2>&1; then
  echo "::error::verify-copy.py 가 name 이 파일 이름과 다른 원본 감사자를 통과시켰다"; exit 1
fi

# sync-agents.sh — 대장에 있는 사본에 커맨드만 빠졌으면 **아무것도 쓰지 않고** 멈춰야 한다.
# 빠진 것만 심으면 그 파일이 옛 synced_commit 아래 들어가 대조 밖에 남는다(Codex 28차).
# --force 면 다 덮고 대장을 이 커밋으로 옮긴다. 감사자가 다 있어 첫 고리가 전부
# 건너뛰면 HDR 이 안 정해져 `set -u` 로 죽던 것(18차)도 --force 쪽에서 같이 본다
c=$(mktemp -d); git clone -q "$R" "$c/src"; mkdir -p "$c/svc"
HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc" >/dev/null
# 대장에는 홈 기준 경로를 적는다 — 절대 경로는 계정 이름 · 비공개 디렉터리를 커밋에 남긴다
if ! grep -q '"agents_path": "~/svc/.claude/agents"' "$c/src/copies.json"; then
  echo "::error::sync-agents.sh 가 대장에 홈 기준이 아닌 경로를 적었다"; cat "$c/src/copies.json"; exit 1
fi
# 브리핑 검사기도 심어야 한다 — 커맨드는 사본 안의 .claude/scripts/ 에서 부른다
if [ ! -f "$c/svc/.claude/scripts/verify-brief.py" ]; then
  echo "::error::sync-agents.sh 가 브리핑 검사기를 심지 않았다"; exit 1
fi
rm "$c/svc/.claude/commands/audit-brief.md"
if HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc" >"$c/out" 2>&1 || [ -e "$c/svc/.claude/commands/audit-brief.md" ]; then
  echo "::error::sync-agents.sh 가 일부만 있는 사본에 빠진 커맨드만 심었다"; cat "$c/out"; exit 1
fi
if ! HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc" --force >"$c/out" 2>&1 || [ ! -f "$c/svc/.claude/commands/audit-brief.md" ]; then
  echo "::error::sync-agents.sh --force 가 빠진 커맨드를 못 심었다"; cat "$c/out"; exit 1
fi
# 심을 폴더 자리에 파일이 있으면 **아무것도 쓰기 전에** 멈춰야 한다 — 앞 폴더에 다 심고
# mkdir 에서 죽으면 대장에 없는 반쪽 사본이 남는다(Codex 리뷰)
mkdir -p "$c/svc3/.claude"; : > "$c/svc3/.claude/scripts"
if HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc3" >"$c/out" 2>&1 || [ -e "$c/svc3/.claude/agents" ]; then
  echo "::error::sync-agents.sh 가 폴더 자리의 파일을 쓰기 전에 못 봤다"; cat "$c/out"; exit 1
fi
# 심을 파일 자리에 끊긴 링크가 있어도 쓰기 전에 멈춰야 한다 — `-e` 로는 없는 것처럼 보여
# 앞 폴더에 다 심고 cp 에서 죽었다(Codex 리뷰)
mkdir -p "$c/svc4/.claude/scripts"; ln -s nowhere "$c/svc4/.claude/scripts/verify-brief.py"
if HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc4" >"$c/out" 2>&1 || [ -e "$c/svc4/.claude/agents" ]; then
  echo "::error::sync-agents.sh 가 끊긴 링크 자리를 쓰기 전에 못 봤다"; cat "$c/out"; exit 1
fi
# 파일 자리에 폴더가 있으면 --force 여도 쓰기 전에 멈춰야 한다 — cp 가 그 폴더 안에 심고
# 성공한 것으로 대장을 옮겼다(Codex 리뷰)
mkdir -p "$c/svc5/.claude/scripts/verify-brief.py"
if HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc5" --force >"$c/out" 2>&1 || [ -e "$c/svc5/.claude/agents" ]; then
  echo "::error::sync-agents.sh --force 가 파일 자리의 폴더를 쓰기 전에 못 봤다"; cat "$c/out"; exit 1
fi
# 폴더 자리가 바깥 폴더를 가리키는 링크여도 쓰기 전에 멈춰야 한다 — `-d` 는 링크를 따라가
# 바깥에 심고 대장을 옮겼다(Codex 리뷰)
mkdir -p "$c/svc6/.claude" "$c/outside"; ln -s "$c/outside" "$c/svc6/.claude/scripts"
if HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc6" >"$c/out" 2>&1 || [ -e "$c/svc6/.claude/agents" ] || [ -n "$(ls -A "$c/outside")" ]; then
  echo "::error::sync-agents.sh 가 링크로 된 폴더 자리를 쓰기 전에 못 봤다"; cat "$c/out"; exit 1
fi
# --force 는 원본에서 물러난 커맨드를 사본에서 지워야 한다 — 남으면 옛 커맨드가 불리고 대장만 새 커밋을 적는다(Codex 29차)
(cd "$c/src" && git rm -q vibe-audit/commands/audit-brief.md && git -c user.name=t -c user.email=t@t commit -qm retire)
if ! HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc" --force >"$c/out" 2>&1 || [ -e "$c/svc/.claude/commands/audit-brief.md" ]; then
  echo "::error::sync-agents.sh --force 가 원본에서 물러난 커맨드를 남겼다"; cat "$c/out"; exit 1
fi
# --force 는 얕은 복제에서 거절해야 한다 — 경계 앞에서 물러난 것을 못 본다(Codex 32차)
git clone -q --depth 1 "file://$c/src" "$c/shallow"
if HOME="$c" "$c/shallow/scripts/sync-agents.sh" "$c/svc" --force >"$c/out" 2>&1; then
  echo "::error::sync-agents.sh --force 가 얕은 복제에서 돌았다"; cat "$c/out"; exit 1
fi
# 무시된(ignored) 원본 파일은 심지 않아야 한다 — HEAD 에 없어 출처가 없다(Codex 34차)
mkdir -p "$c/svc2" "$c/src/vibe-audit/commands"; echo 'vibe-audit/commands/local.md' >> "$c/src/.git/info/exclude"
printf -- '---\ndescription: x\n---\n' > "$c/src/vibe-audit/commands/local.md"
if HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc2" >"$c/out" 2>&1 || [ -e "$c/svc2/.claude/commands/local.md" ]; then
  echo "::error::sync-agents.sh 가 HEAD 에 없는 무시된 커맨드를 심었다"; cat "$c/out"; exit 1
fi
rm "$c/src/vibe-audit/commands/local.md"

# sync-agents.sh --merge — 조각 27 설계 ② 「시험」. 꼴마다 새 고정물 F 에서 돈다: src(이 저장소의 clone) · svc(src 의 커밋 A 로
# 심은 사본 레포 — 감사자 하나의 특화 · README 를 다시 쓴 꼴 · 레포 고유 파일) · remote.git(svc 의 bare 원격, 기본 가지 main).
# HOME=F 라 대장 줄은 `~/svc/.claude/agents` 다. 거절 꼴은 V1(0 아닌 종료 · 그 이유 코드 · 그대로), 성공 꼴은 V2 를 본다.
# 떨어진 꼴은 모아 절 끝에 한 번에 떨어뜨린다 — 변조본 하나가 어느 꼴을 떨어뜨리는지 다 보이게(V4).
M=$(mktemp -d)
mg() { git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c push.negotiate=false "$@"; }
mt="$M/tpl"; mkdir -p "$mt/svc"; git clone -q "$R" "$mt/src"
HOME="$mt" "$mt/src/scripts/sync-agents.sh" "$mt/svc" >/dev/null 2>&1
cp -a "$mt/svc/.claude" "$mt/base-snap"   # A 의 스크립트가 빈 자리에 심은 모양 — 기대본의 밑
# 그 줄의 synced_at 을 옛 날로 — 성공 꼴이 「그날」로 바뀌었는지 볼 수 있게
python3 - "$mt/src/copies.json" <<'L'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1]); d = json.loads(p.read_text(encoding="utf-8"))
for c in d["copies"]:
    if c["repo"] == "svc": c["synced_at"] = "2000-01-01"
p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
L
MA=$(git -C "$mt/src" rev-parse HEAD)
git -C "$mt/src" update-ref refs/remotes/origin/main "$MA"
# 감사자 하나의 체크 항목 표 첫 줄(공통 절 밖)에 꼬리를 단다 — 원본 커밋 B 와 충돌 꼴(T3)이 같은 자리를 쓴다
mrow() { awk -v t="$2" '/^## 체크 항목/ { h = 1 } h && !d && /^\| [0-9]/ { $0 = $0 t; d = 1 } { print }' "$1" > "$1.t" && mv "$1.t" "$1"; }
echo "- svc 특화: 이 레포의 마이그레이션은 Alembic 이다" >> "$mt/svc/.claude/agents/audit-data.md"
sed -i '1s/.*/# 감사자 — svc/' "$mt/svc/.claude/agents/README.md"
echo "레포 고유" > "$mt/svc/.claude/agents/svc-local.md"
git -C "$mt/svc" init -q -b main; git -C "$mt/svc" add -A; mg -C "$mt/svc" commit -qm init
git init -q --bare -b main "$mt/remote.git"
git -C "$mt/svc" remote add origin "$mt/remote.git"; mg -C "$mt/svc" push -q origin main 2>/dev/null
MNAMES=$(cd "$mt/base-snap" && for f in agents/*.md commands/*.md scripts/*.py; do echo "$f"; done | LC_ALL=C sort)
MFAILS=""; mpass=0
mfix() {  # $1=꼴 이름 — 앞 꼴의 고정물을 지우고(꼴마다 7MB 남짓이라 쌓으면 수백 MB) 새로 베껴 F · S · V 를 세운다
  if [ -n "${MPREV:-}" ]; then rm -rf "$MPREV"; fi
  F="$M/$1"; MPREV="$F"; cp -a "$mt" "$F"; S="$F/src"; V="$F/svc"; MSCRIPT="$S/scripts/sync-agents.sh"; MTMP="$F/tmp"
  git -C "$V" remote set-url origin "$F/remote.git"
}
msrc() {  # 원본 커밋 — $1=메시지. origin/main 을 따라 옮겨 「기본 브랜치에 없다」 경고가 없게 둔다(경고 꼴은 T13)
  git -C "$S" add -A vibe-audit scripts; mg -C "$S" commit -qm "$1" -- vibe-audit scripts
  git -C "$S" update-ref refs/remotes/origin/main HEAD
}
mB() { mrow "$S/vibe-audit/agents/audit-data.md" " (B)"; msrc B; }
msvc() { git -C "$V" add -A; mg -C "$V" commit -qm "${1:-svc}"; }
mledger() {  # $1=d 를 고치는 파이썬 — 이 스크립트가 쓰는 꼴로 다시 쓴다
  python3 - "$S/copies.json" "$1" <<'L'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1]); d = json.loads(p.read_text(encoding="utf-8"))
exec(sys.argv[2])
p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
L
}
msubst() {  # $1=파일 $2=옛 글자 $3=새 글자 — 옛 글자가 정확히 한 자리
  python3 - "$@" <<'P'
import pathlib, sys
p, old, new = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
s = p.read_text(encoding="utf-8")
if s.count(old) != 1:
    sys.exit(f"시험의 고정물을 못 세운다 — {p} 에 {old!r} 가 {s.count(old)} 자리다")
p.write_text(s.replace(old, new), encoding="utf-8")
P
}
mfail() { MFAILS="$MFAILS  $1"$'\n'; echo "::error::sync-agents.sh --merge $1"; if [ -f "$F/out" ]; then sed 's/^/    | /' "$F/out" | tail -8; fi; }
msnap() {  # 「그대로」의 전 — 사본 레포의 .claude/ · 대장 · 사본 레포의 status · 사본 밖에서 링크가 가리키는 파일
  rm -rf "$F/before"; mkdir -p "$F/before" "$MTMP"
  if [ -e "$V/.claude" ]; then cp -a "$V/.claude" "$F/before/claude"; fi
  cp -p "$S/copies.json" "$F/before/ledger"
  git -C "$V" status --porcelain >"$F/before/status" 2>&1 || true
  if [ -d "$F/outside" ]; then cp -a "$F/outside" "$F/before/outside"; fi
}
msame() {
  if [ -e "$F/before/claude" ]; then diff -r --no-dereference "$F/before/claude" "$V/.claude" >/dev/null 2>&1 || return 1
  elif [ -e "$V/.claude" ]; then return 1; fi
  cmp -s "$F/before/ledger" "$S/copies.json" || return 1
  [ "$(git -C "$V" status --porcelain 2>&1 || true)" = "$(cat "$F/before/status")" ] || return 1
  if [ -d "$F/before/outside" ]; then diff -r "$F/before/outside" "$F/outside" >/dev/null 2>&1 || return 1; fi
}
mrun() {  # sync-agents.sh 를 V 에(V 가 비면 대상 없이) — 인자가 없으면 --merge. 결과는 $F/out · mrc
  if [ $# -eq 0 ]; then set -- --merge; fi
  mrc=0; HOME="$F" TMPDIR="$MTMP" "$MSCRIPT" ${V:+"$V"} "$@" >"$F/out" 2>&1 || mrc=$?
}
mtidy() {  # $1=꼴 $2=코드 — 작업트리 · 임시 폴더(M8). 충돌로 멈춘 것만 임시 폴더를 남긴다
  if [ "$(git -C "$S" worktree list --porcelain | grep -c '^worktree ')" != 1 ]; then mfail "$1: src 에 임시 작업트리가 남았다"; return 1; fi
  if [ "$2" != merge:conflict ] && [ -n "$(ls -A "$MTMP")" ]; then mfail "$1: TMPDIR 에 임시 폴더가 남았다"; return 1; fi
}
mcode() {  # $1=꼴 $2=코드 — 이유 코드 줄이 그것 하나
  if [ "$(grep -c '^merge:' "$F/out")" != 1 ] || ! grep -qx "$2" "$F/out"; then mfail "$1: $2 로 멈추지 않았다"; return 1; fi
}
mrefuse() {  # $1=기대 코드 $2=꼴 [$3…=인자] — V1
  local code=$1 name=$2; shift 2
  msnap; mrun "$@"
  if [ "$mrc" -eq 0 ]; then mfail "$name: 종료 0 — 멈춰야 한다"; return; fi
  if [ "$code" = merge:force-and-merge ] && [ "$mrc" -ne 2 ]; then mfail "$name: 종료 $mrc — 2 여야 한다"; return; fi
  mcode "$name" "$code" || return 0
  msame || { mfail "$name: 사본 · 대장 · 사본 레포 상태가 그대로가 아니다"; return; }
  mtidy "$name" "$code" || return 0
  mpass=$((mpass + 1))
}
mkeep() {  # $1=기대 코드 $2=꼴 — 종료 0 인데 아무것도 안 쓰는 꼴(P4)
  msnap; mrun
  if [ "$mrc" -ne 0 ]; then mfail "$2: 종료 $mrc — 0 이어야 한다"; return; fi
  mcode "$2" "$1" || return 0
  msame || { mfail "$2: 아무것도 쓰지 않아야 한다"; return; }
  mtidy "$2" "$1" || return 0
  mpass=$((mpass + 1))
}
mexpect() {  # 기대본 — 밑은 A 로 심은 모양, 새 원본은 HEAD 의 스크립트가 빈 자리에 심은 모양(심은 뒤 대장을 되돌린다), 사본은 지금 V
  rm -rf "$F/exp" "$F/newsnap"; mkdir -p "$F/newsnap"
  cp -p "$S/copies.json" "$F/ledger.keep"
  HOME="$F" "$S/scripts/sync-agents.sh" "$F/newsnap" >/dev/null 2>&1 || true
  cp -p "$F/ledger.keep" "$S/copies.json"
  local as hs n
  as=$(git -C "$S" rev-parse --short "$MA"); hs=$(git -C "$S" rev-parse --short HEAD)
  while IFS= read -r n; do
    mkdir -p "$F/exp/$(dirname "$n")"
    if [ "$n" = agents/README.md ]; then
      sed "s|pdw96/claude-kit@$as|pdw96/claude-kit@$hs|" "$V/.claude/$n" > "$F/exp/$n"
    else
      git merge-file -p -L "사본" -L "밑 $as" -L "새 원본 $hs" \
        "$V/.claude/$n" "$F/base-snap/$n" "$F/newsnap/.claude/$n" > "$F/exp/$n" || true
    fi
  done <<<"$MNAMES"
}
maccept() {  # $1=꼴 $2=경고(있음|없음) — V2: 종료 0 · 아홉이 기대본 · 대장 전체가 기대본 · 표 · 작업트리 없음 · 레포 고유 파일 그대로
  local name=$1 warn=${2:-없음} n
  mexpect; msnap
  python3 - "$S/copies.json" "$(git -C "$S" rev-parse HEAD)" "$F/exp.ledger" "$F" <<'L'
import datetime, json, pathlib, sys
d = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
for c in d["copies"]:
    if c["agents_path"] in ("~/svc/.claude/agents", sys.argv[4] + "/svc/.claude/agents"):
        c["synced_commit"] = sys.argv[2]; c["synced_at"] = datetime.date.today().isoformat()
pathlib.Path(sys.argv[3]).write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
L
  mrun
  if [ "$mrc" -ne 0 ]; then mfail "$name: 종료 $mrc — 0 이어야 한다"; return; fi
  while IFS= read -r n; do
    cmp -s "$F/exp/$n" "$V/.claude/$n" || { mfail "$name: $n 이 기대본(git merge-file · README 치환)과 다르다"; return; }
  done <<<"$MNAMES"
  cmp -s "$F/exp.ledger" "$S/copies.json" || { mfail "$name: 대장이 기대본(그 줄의 synced_commit · synced_at 만 바뀜)과 다르다"; return; }
  # 표 — 머리줄이 한 줄씩 바뀌고(README 는 출처 한 자리), 원본 B 가 고친 audit-data.md 는 하나 더, 검사기는 바이트 그대로
  local want got
  want=$(while IFS= read -r n; do
    case "$n" in agents/audit-data.md) echo "$n 0 2" ;; *.py) echo "$n 0 0" ;; *) echo "$n 0 1" ;; esac
  done <<<"$MNAMES")
  got=$(sed -nE 's/^\| ((agents|commands|scripts)\/[^ ]+) \| ([^ ]+) \| ([^ ]+) \|$/\1 \3 \4/p' "$F/out")
  [ "$got" = "$want" ] || { mfail "$name: 파일별 표가 다르다 — 기대: $(echo $want)"; return; }
  cmp -s "$F/before/claude/agents/svc-local.md" "$V/.claude/agents/svc-local.md" || { mfail "$name: 레포 고유 파일을 건드렸다"; return; }
  if [ "$warn" = 있음 ] && ! grep -q '경고: HEAD(' "$F/out"; then mfail "$name: 「기본 브랜치에 없다」 경고가 없다"; return; fi
  if [ "$warn" = 없음 ] && grep -q '경고: HEAD(' "$F/out"; then mfail "$name: 기본 브랜치의 HEAD 에 경고를 찍었다"; return; fi
  mtidy "$name" ok || return 0
  mpass=$((mpass + 1))
}

# P1 · 인자
mfix t7a; mB; mrefuse merge:force-and-merge "T7a --force --merge" --force --merge
mfix t0a; V=""; mrefuse merge:no-target "T0a 대상 없이 --merge"
mfix t0b; V="$F/nope"; mrefuse merge:target-missing "T0b 없는 대상"
# P2
mfix t7b; mB; git clone -q --depth 1 "file://$S" "$F/shallow"; cp -p "$S/copies.json" "$F/shallow/copies.json"
MSCRIPT="$F/shallow/scripts/sync-agents.sh"; S="$F/shallow"; mrefuse merge:shallow "T7b 얕은 복제"
# P3
mfix t7c; mB; mledger 'd["copies"] = [c for c in d["copies"] if c["repo"] != "svc"]'; mrefuse merge:no-ledger-row "T7c 대장에 줄 없음"
mfix t7d; mB; mledger 'for c in d["copies"]: c["synced_commit"] = "0" * 40 if c["repo"] == "svc" else c["synced_commit"]'
mrefuse merge:base-missing "T7d synced_commit 이 저장소에 없음"
mfix t7f; mB; mledger 'd["copies"].append(dict(next(c for c in d["copies"] if c["repo"] == "svc"), repo="svc-twin"))'
mrefuse merge:many-ledger-rows "T7f 대상 자리를 가리키는 줄이 둘"
mfix t7i; mB; python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); open(p,"w").write(json.dumps(d, ensure_ascii=False, indent=4)+"\n")' "$S/copies.json"
mrefuse merge:ledger-not-canonical "T7i 대장이 이 스크립트의 꼴이 아님"
# P5 — 지금 스크립트의 앞 검사를 --merge 로
mfix t11a; mB; echo x >> "$S/vibe-audit/agents/audit-ops.md"; mrefuse merge:src-dirty "T11a 원본에 커밋 안 된 변경"
mfix t11b; mB; echo 'vibe-audit/commands/local.md' >> "$S/.git/info/exclude"; printf -- '---\ndescription: x\n---\n' > "$S/vibe-audit/commands/local.md"
mrefuse merge:src-untracked "T11b HEAD 에 없는 원본 파일"
mfix t11g; mB; echo '#' >> "$S/scripts/verify-copy.py"; mrefuse merge:tool-dirty "T11g 병합을 하는 원본 도구(verify-copy.py)에 커밋 안 된 변경"
mfix t11h; mB; echo '#' >> "$S/scripts/sync-agents.sh"; mrefuse merge:tool-dirty "T11h 병합을 하는 원본 도구(sync-agents.sh)에 커밋 안 된 변경"
mfix t11c; mB; mledger 'd["copies"].append({"repo": "svc", "agents_path": "~/elsewhere/svc/.claude/agents", "synced_commit": d["copies"][0]["synced_commit"], "synced_at": "2026-10-19"})'
mrefuse merge:name-clash "T11c 대장의 같은 이름 다른 자리"
mfix t11d; mB; git -C "$V" rm -rq .claude/scripts; : > "$V/.claude/scripts"; msvc; mrefuse merge:dir-slot-not-dir "T11d 폴더 자리에 파일"
mfix t11e; mB; git -C "$V" rm -q .claude/agents/audit-ops.md; mkdir "$V/.claude/agents/audit-ops.md"; : > "$V/.claude/agents/audit-ops.md/x"; msvc
mrefuse merge:file-slot-dir "T11e 파일 자리에 폴더"
mfix t11f; mB; mkdir -p "$F/outside"; git -C "$V" rm -rq --cached .claude/scripts; mv "$V/.claude/scripts/verify-brief.py" "$F/outside/"
rmdir "$V/.claude/scripts"; ln -s "$F/outside" "$V/.claude/scripts"; msvc; mrefuse merge:dir-slot-link "T11f 폴더 자리가 링크"
# P6 — 사본 레포
mfix t9a; mB; git clone -q "$F/remote.git" "$F/other"; echo x > "$F/other/x"; git -C "$F/other" add x; mg -C "$F/other" commit -qm ahead
mg -C "$F/other" push -q origin main 2>/dev/null; mrefuse merge:copy-behind "T9a 원격이 앞섬"
mfix t9b; mB; echo x >> "$V/.claude/agents/audit-ops.md"; mrefuse merge:copy-dirty "T9b 추적된 파일에 커밋 안 된 고침"
mfix t9h; mB; echo x > "$V/.claude/commands/new.md"; mrefuse merge:copy-dirty "T9h 사본 자리에 추적 안 된 새 파일"
mfix t9c; mB; git -C "$V" rm -q --cached .claude/agents/README.md; echo .claude/agents/README.md >> "$V/.git/info/exclude"; msvc
mrefuse merge:copy-not-tracked "T9c 무시된 README"
mfix t9i; mB; git -C "$V" rm -q --cached .claude/agents/audit-ops.md; echo .claude/agents/audit-ops.md >> "$V/.git/info/exclude"; msvc
mrefuse merge:copy-not-tracked "T9i 무시된 감사자"
mfix t9d; mB; git -C "$V" remote remove origin; mrefuse merge:remote-unknown "T9d 원격 없음"
mfix t9g; mB; rm -f "$V/.git/FETCH_HEAD"; mkdir "$V/.git/FETCH_HEAD"; mrefuse merge:fetch-failed "T9g 기본 가지는 읽히는데 받기가 실패"
mfix t9f; mB; rm -rf "$V/.git"; mrefuse merge:copy-not-git "T9f 대상이 git 저장소 밖"
mfix t9e; git clone -q "$F/remote.git" "$F/other"; echo x > "$F/other/x"; git -C "$F/other" add x; mg -C "$F/other" commit -qm ahead
mg -C "$F/other" push -q origin main 2>/dev/null; mrefuse merge:copy-behind "T9e 같은 커밋인데 원격이 앞섬"
# P4
mfix t10; mkeep merge:up-to-date "T10 같은 커밋 · 깨끗함"
# 성공 꼴 — M1 · M6 · M7 · 받는 쪽 경계
mfix t1; mB; maccept "T1 깨끗한 병합"
mfix t2; msubst "$S/scripts/sync-agents.sh" 'HDR="<!-- pdw96/claude-kit@$SHA 에서 옴.' 'HDR="<!-- pdw96/claude-kit@$SHA 에서 왔다.'; msrc H; mB
maccept "T2 사이에 머리줄 꼴이 바뀜"
mfix t7e; mB; mledger 'd["copies"] += [{"repo": r, "agents_path": f"~/x/{r}/.claude/agents", "synced_commit": d["copies"][0]["synced_commit"], "synced_at": "2026-10-19"} for r in ("base", "new")]; d["copies"].sort(key=lambda c: c["repo"])'
mg -C "$S" commit -qm "대장에 base · new" -- copies.json; git -C "$S" update-ref refs/remotes/origin/main HEAD   # 커밋에 들어야 작업트리의 스크립트가 걸린다
maccept "T7e 커밋된 대장에 base · new 줄이 있음"
mfix t12; mB; echo n > "$V/notes.txt"; msvc ahead; maccept "T12 사본 레포가 원격보다 한 커밋 앞섬"
mfix t13; mB; git -C "$S" update-ref refs/remotes/origin/main "$MA"; maccept "T13 HEAD 가 origin/main 밖" 있음
mfix t14; mB; mledger "for c in d['copies']: c['agents_path'] = '$F/svc/.claude/agents' if c['repo'] == 'svc' else c['agents_path']"
maccept "T14 대장 줄이 절대 경로 — 그 바이트 그대로"
# M1 — 그 커밋의 스크립트가 0 아닌 코드로 끝남
mfix t7g; echo 'exit 3' >> "$S/scripts/sync-agents.sh"; msrc "A′"; h=$(git -C "$S" rev-parse HEAD)
mledger "for c in d['copies']: c['synced_commit'] = '$h' if c['repo'] == 'svc' else c['synced_commit']"
git -C "$S" show "$MA:scripts/sync-agents.sh" > "$S/scripts/sync-agents.sh"; mB; mrefuse merge:base-build-failed "T7g 밑의 스크립트가 실패"
mfix t7h; echo 'exit 3' >> "$S/scripts/sync-agents.sh"; mB; mrefuse merge:new-build-failed "T7h 새 원본의 스크립트가 다 심은 뒤 실패"
# M2 — 묶음
mfix t5a; mB; printf -- '---\ndescription: x\n---\n' > "$S/vibe-audit/commands/extra.md"; msrc add; mrefuse merge:bundle-differs "T5a 원본에 파일을 더함"
mfix t5b; mB; git -C "$S" rm -q vibe-audit/commands/audit-brief.md; msrc rm; mrefuse merge:bundle-differs "T5b 원본에서 파일을 뺌"
while IFS= read -r n; do
  k=${n//\//-}
  mfix "t5c-$k"; mB; mkdir -p "$F/outside"; mv "$V/.claude/$n" "$F/outside/$k"; ln -s "$F/outside/$k" "$V/.claude/$n"; msvc
  mrefuse merge:copy-not-file "T5c $n 이 사본 밖을 가리키는 링크"
  mfix "t5d-$k"; mB; git -C "$V" rm -q ".claude/$n"; msvc; mrefuse merge:copy-not-file "T5d $n 이 없음"
  mfix "t5e-$k"; mB; git -C "$V" rm -q ".claude/$n"; mkdir -p "$V/.claude/$n"; : > "$V/.claude/$n/x"; msvc
  # README 는 지금 스크립트가 심는 파일 목록 밖이라 P5 의 파일 자리 검사가 아니라 M2 가 문다
  if [ "$n" = agents/README.md ]; then mrefuse merge:copy-not-file "T5e $n 이 폴더"; else mrefuse merge:file-slot-dir "T5e $n 이 폴더"; fi
done <<<"$MNAMES"
# M3 · M8 — 충돌과 오류
mfix t3; mB; mrow "$V/.claude/agents/audit-data.md" " (svc)"; msvc; mrefuse merge:conflict "T3 사본과 원본이 같은 줄을 고침"
w=$(sed -n 's/^재료와 충돌 표시 병합본: \(.*\) (base .*/\1/p' "$F/out")
mexpect
as=$(git -C "$S" rev-parse --short "$MA"); hs=$(git -C "$S" rev-parse --short HEAD)
git merge-file -p -L "사본" -L "밑 $as" -L "새 원본 $hs" "$V/.claude/agents/audit-data.md" "$F/base-snap/agents/audit-data.md" \
  "$F/newsnap/.claude/agents/audit-data.md" > "$F/exp/agents/audit-data.md" || true
if [ -z "$w" ] || [ "${w#"$V"}" != "$w" ] || ! diff -r "$w/base/.claude" "$F/base-snap" >/dev/null || ! diff -r "$w/new/.claude" "$F/newsnap/.claude" >/dev/null; then
  mfail "T3 M8: 남긴 폴더($w)가 사본 밖이 아니거나 base · new 가 기대 바이트가 아니다"
else
  while IFS= read -r n; do
    cmp -s "$w/copy/$n" "$V/.claude/$n" || mfail "T3 M8: 사본 베낌 $n 이 다르다"
    [ "$n" = agents/README.md ] || cmp -s "$w/merged/$n" "$F/exp/$n" || mfail "T3 M8: 병합본 $n 이 기대(충돌 표시 포함)와 다르다"
  done <<<"$MNAMES"
  grep -q '^<<<<<<< 사본$' "$w/merged/agents/audit-data.md" || mfail "T3 M8: 병합본에 충돌 표시가 없다"
  grep -qx '| agents/audit-data.md | 1 | .* |' "$F/out" || mfail "T3: 표에 충돌 1 이 없다"
fi
# M8 — 임시 폴더가 사본 레포 · 원본 저장소 안이면 멈춘다. 충돌 꼴 위에서 — 그대로 가면 재료를 그 안에 남긴다
mfix t15a; mB; mrow "$V/.claude/agents/audit-data.md" " (svc)"; msvc; MTMP="$V/.tmp"; mrefuse merge:work-inside-repo "T15a TMPDIR 이 사본 레포 안"
mfix t15b; mB; mrow "$V/.claude/agents/audit-data.md" " (svc)"; msvc; MTMP="$S/.tmp"; mrefuse merge:work-inside-repo "T15b TMPDIR 이 원본 저장소 안"
mfix t3b; mB; python3 -c 'import pathlib,sys; p=pathlib.Path(sys.argv[1]); b=p.read_bytes(); i=b.index(b"\n")+1; p.write_bytes(b[:i]+b"\0\n"+b[i:])' "$V/.claude/agents/audit-data.md"; msvc
mrefuse merge:conflict "T3b 사본 파일에 NUL — git merge-file 이 오류(255)"
grep -qx '| agents/audit-data.md | 오류 | .* |' "$F/out" || mfail "T3b: 표에 오류가 없다"
# M4 — 세 README 하나하나에
TPL='\`pdw96/claude-kit@$SHA\` 의 \`vibe-audit\` 플러그인에서 온 사본이다.'
m4src() {  # $1=README 틀을 바꾼 꼴 — 0 | 2 | hex
  case "$1" in
    0) msubst "$S/scripts/sync-agents.sh" "$TPL" '\`pdw96/claude-kit\` 의 \`vibe-audit\` 플러그인에서 온 사본이다.' ;;
    2) msubst "$S/scripts/sync-agents.sh" "$TPL" "$TPL"$'\n''다시 적은 출처: \`pdw96/claude-kit@$SHA\`.' ;;
    hex) msubst "$S/scripts/sync-agents.sh" "$TPL" '\`pdw96/claude-kit@${SHA}0\` 의 \`vibe-audit\` 플러그인에서 온 사본이다.' ;;
  esac
}
for k in 0 2 hex; do
  # 밑 — 그 틀로 심은 커밋 A2 에 사본을 --force 로 다시 심고, 사본 README 만 출처 한 자리로 고친 뒤 B 가 틀을 되돌린다
  mfix "t4-base-$k"; m4src "$k"; msrc A2; a2=$(git -C "$S" rev-parse --short HEAD)
  HOME="$F" "$S/scripts/sync-agents.sh" "$V" --force >/dev/null 2>&1
  python3 - "$V/.claude/agents/README.md" "$a2" <<'P'
import pathlib, re, sys
p, a2 = pathlib.Path(sys.argv[1]), sys.argv[2]
s = re.sub(r"\n다시 적은 출처: .*\n", "\n", p.read_text(encoding="utf-8"))
s = re.sub(r"`pdw96/claude-kit[^`]*`", f"`pdw96/claude-kit@{a2}`", s)
p.write_text(s, encoding="utf-8")
P
  msvc A2; git -C "$S" show "$MA:scripts/sync-agents.sh" > "$S/scripts/sync-agents.sh"; mB
  if [ "$k" = hex ]; then c=merge:readme-source-mismatch; else c=merge:readme-source-count; fi
  mrefuse "$c" "T4 밑 README 의 출처 꼴 $k"
  mfix "t4-new-$k"; m4src "$k"; mB; mrefuse "$c" "T4 새 원본 README 의 출처 꼴 $k"
done
as=$(git -C "$mt/src" rev-parse --short "$MA")
mfix t4-copy-0; mB; msubst "$V/.claude/agents/README.md" "pdw96/claude-kit@$as" "pdw96/claude-kit"; msvc
mrefuse merge:readme-source-count "T4a 사본 README 에 출처 0"
mfix t4-copy-2; mB; echo "또 적은 출처 pdw96/claude-kit@$as" >> "$V/.claude/agents/README.md"; msvc
mrefuse merge:readme-source-count "T4b 사본 README 에 출처 둘"
mfix t4-copy-hex; mB; msubst "$V/.claude/agents/README.md" "pdw96/claude-kit@$as" "pdw96/claude-kit@${as}0"; msvc
mrefuse merge:readme-source-mismatch "T4d 사본 README 의 출처가 밑 SHA 로 시작하는 더 긴 16진"
mfix t4-copy-other; mB; msubst "$V/.claude/agents/README.md" "pdw96/claude-kit@$as" "pdw96/claude-kit@1234567"; msvc
mrefuse merge:readme-source-mismatch "T4h 사본 README 의 출처가 밑과 다름"
# M5
mfix t6; mB; sed -i 's/^tools: .*/tools: ["Read", "Grep", "Glob", "Edit"]/' "$V/.claude/agents/audit-ops.md"; msvc
mrefuse merge:verify-copy-failed "T6 사본이 감사자 하나의 tools 를 바꿈"
# T8 — 지금 길(요구사항 성공 기준 5). 인자 없는 길 · --force 를 마지막으로 바꾼 커밋 c56e571 의 스크립트와 이 스크립트가 같은
# 자리에 심은 결과 · 출력 · 대장이 같다. 그 길을 일부러 바꾸면 이 핀을 그 커밋으로 옮긴다.
mfix t8; git -C "$S" show c56e571:scripts/sync-agents.sh > "$S/scripts/sync-agents.pin.sh"; chmod +x "$S/scripts/sync-agents.pin.sh"
cp -p "$S/copies.json" "$F/l0"
for v in pin cur; do
  if [ "$v" = pin ]; then sc="$S/scripts/sync-agents.pin.sh"; else sc="$S/scripts/sync-agents.sh"; fi
  rm -rf "$F/t8"; mkdir "$F/t8"; cp -p "$F/l0" "$S/copies.json"; mkdir -p "$F/r.$v"
  { HOME="$F" "$sc" "$F/t8"; echo "rc=$?"; } >"$F/r.$v/o1" 2>&1 || true
  { HOME="$F" "$sc" "$F/t8"; echo "rc=$?"; } >"$F/r.$v/o2" 2>&1 || true   # 있으면 건너뛰는 길
  cp -a "$F/t8/.claude" "$F/r.$v/plain"; cp -p "$S/copies.json" "$F/r.$v/l1"
  echo "- 특화" >> "$F/t8/.claude/agents/audit-ops.md"
  { HOME="$F" "$sc" "$F/t8" --force; echo "rc=$?"; } >"$F/r.$v/o3" 2>&1 || true
  cp -a "$F/t8/.claude" "$F/r.$v/force"; cp -p "$S/copies.json" "$F/r.$v/l2"
done
cp -p "$F/l0" "$S/copies.json"
if diff -r "$F/r.pin" "$F/r.cur" >"$F/out" 2>&1; then mpass=$((mpass + 1)); else mfail "T8 인자 없는 길 · --force 가 c56e571 과 다르다"; fi

# V5 — `merge:` 이유 코드마다 그것을 기대하는 시험(mrefuse · mkeep)이 이 절에 있다. 변조본: 시험 하나를 지운 절은 떨어진다.
mcodes() {  # $1=sync-agents.sh $2=시험 파일 — 시험이 없는 코드를 찍는다
  comm -23 <(grep -oE 'merge:[a-z][a-z-]*' "$1" | sort -u) \
           <(grep -vE '^[[:space:]]*#' "$2" | grep -oE '\bm(refuse|keep) merge:[a-z][a-z-]*' | grep -oE 'merge:[a-z-]+' | sort -u)
}
F="$M/v5"; mkdir -p "$F"
gap=$(mcodes "$mt/src/scripts/sync-agents.sh" "$R/scripts/bite-gates.sh")
if [ -n "$gap" ]; then mfail "V5 시험이 없는 이유 코드: $(echo $gap)"; else mpass=$((mpass + 1)); fi
sed '/mrefuse merge:shallow /d' "$R/scripts/bite-gates.sh" > "$F/cut.sh"
if [ "$(mcodes "$mt/src/scripts/sync-agents.sh" "$F/cut.sh")" != merge:shallow ]; then mfail "V5 변조본: 시험 하나를 지운 절이 떨어지지 않는다"; else mpass=$((mpass + 1)); fi

if [ -n "$MFAILS" ]; then
  echo "::error::sync-agents.sh --merge 의 꼴 $(printf '%s' "$MFAILS" | grep -c .) 이 떨어졌다 (지나간 꼴 $mpass):"; printf '%s' "$MFAILS"; exit 1
fi
echo "sync-agents.sh --merge: 꼴 $mpass 다 지나감 — 거절은 이유 코드 · 그대로, 성공은 기대본 · 대장 · 표, 지금 길은 c56e571 과 같음, 이유 코드마다 시험"

# verify-evals.py — 대조군을 뺀 수트는 실패해야 한다
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
rm "$s"/vibe-audit/evals/*/graders/real-nc-found.md
if python3 scripts/verify-evals.py "$s/vibe-audit/evals" >/dev/null 2>&1; then
  echo "::error::verify-evals.py 가 대조군 없는 수트를 통과시켰다"; exit 1
fi

# verify-evals.py — input_match 가 subagent_type 에 안 걸린 그레이더는 실패해야 한다.
# 이름만 적으면 입력 어디에 적혀 있기만 해도 뜬 것으로 센다. 공백을 넣은 JSON 은
# 하네스가 펴는 모양과 달라 영영 안 맞으므로, 음성 그레이더가 늘 통과한다.
for mut in \
  "s/^input_match: .*/input_match: audit-data/" \
  "s/\"subagent_type\":\"/\"subagent_type\": \"/"; do
  s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
  sed -i "$mut" "$s/vibe-audit/evals/route-contract/graders/route-not-data.md"
  if python3 scripts/verify-evals.py "$s/vibe-audit/evals" >/dev/null 2>&1; then
    echo "::error::verify-evals.py 가 subagent_type 에 안 걸린 input_match 를 통과시켰다 ($mut)"; exit 1
  fi
done

# verify-evals.py — route-quiet 이 감사자 하나만 짚으면 실패해야 한다
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
sed -i 's/"vibe-audit:'"'"'$/"vibe-audit:audit-data"'"'"'/' "$s/vibe-audit/evals/route-quiet/graders/route-quiet.md"
if python3 scripts/verify-evals.py "$s/vibe-audit/evals" >/dev/null 2>&1; then
  echo "::error::verify-evals.py 가 하나만 짚는 route-quiet 을 통과시켰다"; exit 1
fi

# verify-graders.py — 함정을 못 무는 그레이더는 실패해야 한다
g=$(mktemp -d); cp -r vibe-audit "$g/"; rm -rf "$g/vibe-audit/evals/results"
sed -i 's/NC-3\\\\b/NC-9\\\\b/' "$g/vibe-audit/evals/cycle-continuity/graders/trap-no-false-resolved.md"
if python3 scripts/verify-graders.py "$g/vibe-audit/evals" >/dev/null 2>&1; then
  echo "::error::verify-graders.py 가 못 무는 그레이더를 통과시켰다"; exit 1
fi

# verify-graders.py — pass.md 밖의 바른 기록(pass-*.md)에서 떨어지는 그레이더는 실패해야 한다.
# pass.md 만 보던 판은 이것을 지나보냈다. 수트 안의 pass-*.md 에 기대지 않고 pass.md 를
# 베껴 report.py 줄을 뺀다 — gate-escalated-perf 하나만 떨어진다(조각 21, ADR 0031).
g=$(mktemp -d); cp -r vibe-audit "$g/"; rm -rf "$g/vibe-audit/evals/results"
grep -v 'report\.py' "$g/vibe-audit/evals/gap-unowned/samples/pass.md" > "$g/vibe-audit/evals/gap-unowned/samples/pass-bite.md"
if python3 scripts/verify-graders.py "$g/vibe-audit/evals" >/dev/null 2>&1; then
  echo "::error::verify-graders.py 가 pass-*.md 에서 떨어지는 그레이더를 통과시켰다"; exit 1
fi

# verify-budget.py — 문구가 자란 사본은 실패해야 한다
u=$(mktemp -d); tar -c --exclude=.git --exclude=results . | tar -x -C "$u"
python3 -c "
import pathlib
p = pathlib.Path('$u/vibe-audit/agents/audit-secrets.md')
p.write_text(p.read_text() + '\n' + '규칙을 더 붙인다. ' * 200)
"
if python3 "$u/scripts/verify-budget.py" >/dev/null 2>&1; then
  echo "::error::verify-budget.py 가 자란 문구를 통과시켰다"; exit 1
fi

# verify-manifest.py — 선언한 라이선스의 파일이 없으면 실패해야 한다
m=$(mktemp -d); tar -c --exclude=.git --exclude=results . | tar -x -C "$m"
rm "$m/LICENSE"
if python3 "$m/scripts/verify-manifest.py" >/dev/null 2>&1; then
  echo "::error::verify-manifest.py 가 LICENSE 없는 선언을 통과시켰다"; exit 1
fi

# verify-copies.py — 이 저장소에 없는 커밋을 적은 대장은 실패해야 한다.
# 이 검사는 git 이력을 보므로 사본이 아니라 제자리에서 흔들고 되돌린다.
hold copies.json
python3 - <<'PY'
import json, pathlib
p = pathlib.Path("copies.json")
d = json.loads(p.read_text(encoding="utf-8"))
d["copies"].append({"repo": "없는-레포", "agents_path": "/없는/자리",
                    "synced_commit": "0" * 40, "synced_at": "2026-01-01"})
p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
if python3 scripts/verify-copies.py >/dev/null 2>&1; then
  undo copies.json
  echo "::error::verify-copies.py 가 없는 커밋을 적은 대장을 통과시켰다"; exit 1
fi
undo copies.json

# 체크아웃이 얕으면 실패한다. verify-copies.py 는 대장의 synced_commit 을 이
# 저장소에서 찾는데, sync-agents.sh 는 대장을 적는 커밋보다 앞선 HEAD 를 적는다.
if [ "$(git rev-parse --is-shallow-repository)" != false ]; then
  echo "::error::체크아웃이 얕다 — 대장의 synced_commit 을 못 찾는다(fetch-depth: 0)"; exit 1
fi

# verify-copies.py — 그 커밋에서 그대로 심은 사본은 통과하고, 커맨드를 지운
# 사본은 실패해야 한다. 적는 커밋은 머리보다 앞서면서 커맨드 · 사본 검사기 ·
# 브리핑 검사기를 가진 가장 가까운 것 — sync-agents.sh 가 적는 모양이다. 없으면
# (스쿼시 머지 직후 main 처럼 그것들이 한 커밋에서 처음 생긴 역사) 머리로 본다. 얕은지는 위에서
# 따로 물므로, 역사의 모양을 얕은 것으로 오인하지 않는다(Codex 리뷰).
c=$(mktemp -d); mkdir -p "$c/.claude/agents" "$c/.claude/commands"
old=$(git rev-parse HEAD)
for k in $(git rev-list --skip=1 --max-count=200 HEAD); do
  if git cat-file -e "$k:vibe-audit/commands/audit-brief.md" 2>/dev/null \
     && git cat-file -e "$k:scripts/verify-copy.py" 2>/dev/null \
     && git cat-file -e "$k:vibe-audit/scripts/verify-brief.py" 2>/dev/null; then
    old=$k; break
  fi
done
echo "사본을 심은 커밋으로 적는 것: $old"
for f in $(git ls-tree --name-only "$old" vibe-audit/agents/ vibe-audit/commands/ vibe-audit/scripts/); do
  case "$f" in
    vibe-audit/agents/audit-*.md) git show "$old:$f" > "$c/.claude/agents/${f##*/}" ;;
    vibe-audit/commands/*.md)     git show "$old:$f" > "$c/.claude/commands/${f##*/}" ;;
    vibe-audit/scripts/*.py)      mkdir -p "$c/.claude/scripts"; git show "$old:$f" > "$c/.claude/scripts/${f##*/}" ;;
  esac
done
hold copies.json
python3 - "$c/.claude/agents" "$old" <<'PY'
import json, pathlib, sys
p = pathlib.Path("copies.json")
d = json.loads(p.read_text(encoding="utf-8"))
d["copies"].append({"repo": "흔드는-사본", "agents_path": sys.argv[1],
                    "synced_commit": sys.argv[2], "synced_at": "2026-01-01"})
p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
if ! python3 scripts/verify-copies.py; then
  undo copies.json
  echo "::error::verify-copies.py 가 HEAD~1 에서 그대로 심은 사본을 떨어뜨렸다 — 체크아웃이 얕은가"; exit 1
fi
# 감사자의 머리말 name 을 바꾼 사본도 실패해야 한다 — 문서가 적은 이름으로 안 불린다
cp "$c/.claude/agents/audit-secrets.md" "$c/keep.md"
sed -i '0,/^name: .*/s//name: renamed-secrets/' "$c/.claude/agents/audit-secrets.md"
if python3 scripts/verify-copies.py >/dev/null 2>&1; then
  undo copies.json
  echo "::error::verify-copies.py 가 name 을 바꾼 감사자 사본을 통과시켰다"; exit 1
fi
mv "$c/keep.md" "$c/.claude/agents/audit-secrets.md"
rm "$c/.claude/commands/audit-brief.md"
if python3 scripts/verify-copies.py >/dev/null 2>&1; then
  undo copies.json
  echo "::error::verify-copies.py 가 /audit-brief 가 빠진 사본을 통과시켰다"; exit 1
fi
# 검사기가 빠진 사본도 실패해야 한다. 적는 커밋은 검사기를 가진 것으로 골랐다 —
# 없는 커밋을 고르면 이 변조가 늘 건너뛰어져 아무것도 안 본다(Codex 리뷰)
if [ ! -f "$c/.claude/scripts/verify-brief.py" ]; then
  undo copies.json
  echo "::error::적는 커밋 $old 에 브리핑 검사기가 없다 — 검사기 빠진 사본 변조를 못 한다"; exit 1
fi
git show "$old:vibe-audit/commands/audit-brief.md" > "$c/.claude/commands/audit-brief.md"
rm "$c/.claude/scripts/verify-brief.py"
if python3 scripts/verify-copies.py >/dev/null 2>&1; then
  undo copies.json
  echo "::error::verify-copies.py 가 브리핑 검사기가 빠진 사본을 통과시켰다"; exit 1
fi
undo copies.json

# verify-copies.py — 사본 줄이 그 뒤 바뀐 원본 파일의 이름을 찍어야 한다(조각 15 설계 ② V2). 경로가 없는 줄
# (CI 의 꼴)에 커맨드를 마지막으로 고친 커밋의 부모를 적으면, 그 커밋이 고친 커맨드 이름이 그 줄에 나와야 한다.
k=$(git log -1 --no-merges --format=%H -- vibe-audit/commands/)
want=$(git diff --name-only "$k^" "$k" -- vibe-audit/commands/ | sed 's#.*/##')
if [ -z "$k" ] || [ -z "$want" ]; then
  echo "::error::vibe-audit/commands/ 를 고친 커밋을 못 찾았다 — 바뀐 원본 이름 변조를 못 한다"; exit 1
fi
hold copies.json
python3 - "$(git rev-parse "$k^")" <<'PY'
import json, pathlib, sys
p = pathlib.Path("copies.json")
d = json.loads(p.read_text(encoding="utf-8"))
d["copies"].append({"repo": "이름-보는-사본", "agents_path": "/없는/자리/.claude/agents",
                    "synced_commit": sys.argv[1], "synced_at": "2026-01-01"})
p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
line=$(python3 scripts/verify-copies.py 2>&1 | grep '이름-보는-사본:' || true)
undo copies.json
for n in $want; do
  case "$line" in
    *"바뀐 원본: "*"$n"*) ;;
    *) echo "::error::verify-copies.py 가 그 뒤 바뀐 원본 $n 의 이름을 사본 줄에 안 찍었다 — $line"; exit 1 ;;
  esac
done

# verify-feedback.py — 성하지 않은 후보 대장은 실패해야 한다(docs/schema.md 의 규칙).
# 같은 모양의 성한 대장은 통과해야 한다 — 다 떨어뜨리는 검사도 무는 것처럼 보인다.
fb=$(mktemp -d)
python3 - "$fb" "$(git rev-parse HEAD)" <<'PY'
import copy, json, pathlib, sys
d, head = pathlib.Path(sys.argv[1]), sys.argv[2]
case = sorted(pathlib.Path("vibe-audit/evals").glob("*/case.yaml"))[0].parent.name
one = {"id": "FB-1", "hash": "sha256:" + "a" * 64,
       "seen": [{"repo": "erp", "files": ["audit-data.md"], "commit": "b" * 40, "base": head}],
       "status": "fed_back", "reason": "다른 레포에서도 같은 말", "decided_at": "2026-10-05",
       "feedback": {"commit": head, "cases": [case], "budget_delta": 0}}
(d / "ok.json").write_text(json.dumps({"candidates": [one]}))
def bad(name, fn):
    c = copy.deepcopy(one); fn(c)
    (d / f"bad-{name}.json").write_text(json.dumps({"candidates": [c]}))
(d / "bad-dup-hash.json").write_text(json.dumps({"candidates": [one, {**one, "id": "FB-2"}]}))
bad("id-gap", lambda c: c.update(id="FB-2"))
bad("status", lambda c: c.update(status="judged"))
bad("no-reason", lambda c: c.update(reason=" "))
bad("base-missing", lambda c: c["seen"][0].update(base="0" * 40))
bad("fed-no-feedback", lambda c: c.pop("feedback"))
bad("fed-commit-missing", lambda c: c["feedback"].update(commit="0" * 40))
bad("fed-case-missing", lambda c: c["feedback"].update(cases=["없는-케이스"]))
bad("feedback-not-fed", lambda c: c.update(status="defect"))
bad("files-folder", lambda c: c["seen"][0].update(files=["commands/audit-brief.md"]))
bad("files-ext", lambda c: c["seen"][0].update(files=["sync.sh"]))
PY
python3 scripts/verify-feedback.py "$fb/ok.json" >/dev/null || {
  echo "::error::verify-feedback.py 가 성한 대장을 떨어뜨렸다"; python3 scripts/verify-feedback.py "$fb/ok.json"; exit 1; }
for f in "$fb"/bad-*.json; do
  if python3 scripts/verify-feedback.py "$f" >/dev/null 2>&1; then
    echo "::error::verify-feedback.py 가 $(basename "$f" .json) 대장을 통과시켰다"; exit 1
  fi
done

# test-compare-copies.py — 비교기를 한 군데씩 망가뜨리면 자체 시험이 떨어져야 한다.
# 그 시험이 무는지를 따로 묻지 않으면, 시험이 비어도 gates.sh 는 초록이다.
cc=$(mktemp -d)
for m in 'if behind != "0":|if False:' \
         'if dirty:|if False:' \
         'if PROVENANCE.match(ln):|if False:' \
         'rows = [(n, ln, " ".join(ln.split()))|rows = [(n, ln, ln)' \
         'if loose:|if False:' \
         'h = content_hash(o, cl)|h = content_hash(o, cl + [str(at)])' \
         'new = sorted(set(e["seen"]) - judged[2]) if judged else []|new = []' \
         'for src, ext, there in SPOTS:|for src, ext, there in SPOTS[:1]:' \
         '"--untracked-files=all", "--", *dirs)|"--untracked-files=all", "--", rel)'; do
  python3 - "${m%%|*}" "${m##*|}" "$cc/c.py" <<'PY'
import pathlib, sys
s = pathlib.Path("scripts/compare-copies.py").read_text(encoding="utf-8")
a, b, out = sys.argv[1:]
if s.count(a) != 1:
    sys.exit(f"변조할 자리 {a!r} 가 비교기에 {s.count(a)} 번 있다 — 이 단계를 비교기에 맞춰 고쳐라")
pathlib.Path(out).write_text(s.replace(a, b), encoding="utf-8")
PY
  if python3 scripts/test-compare-copies.py "$cc/c.py" >/dev/null 2>&1; then
    echo "::error::test-compare-copies.py 가 '${m%%|*}' 를 망가뜨린 비교기를 통과시켰다"; exit 1
  fi
done

# test-verify-feedback.py — 역사 규칙을 끈 대장 검사기를 자체 시험이 잡아야 한다
for m in 'if past:|if False:' \
         'f"{commit}:vibe-audit/evals/{c}/case.yaml"|f"HEAD:vibe-audit/evals/{c}/case.yaml"'; do
  python3 - "${m%%|*}" "${m##*|}" "$cc/v.py" <<'PY'
import pathlib, sys
s = pathlib.Path("scripts/verify-feedback.py").read_text(encoding="utf-8")
a, b, out = sys.argv[1:]
if s.count(a) != 1:
    sys.exit(f"변조할 자리 {a!r} 가 대장 검사기에 {s.count(a)} 번 있다 — 이 단계를 검사기에 맞춰 고쳐라")
pathlib.Path(out).write_text(s.replace(a, b), encoding="utf-8")
PY
  if python3 scripts/test-verify-feedback.py "$cc/v.py" >/dev/null 2>&1; then
    echo "::error::test-verify-feedback.py 가 '${m%%|*}' 를 망가뜨린 대장 검사기를 통과시켰다"; exit 1
  fi
done

# test-verify-docs.py — 문서 대조 검사를 보장 묶음마다 한 군데씩 망가뜨리면 자체 시험이 떨어져야 한다
# (조각 3 설계 ⑤ 「시험이 문다」). 원천 · 틀 · 의도 · 마스터플랜 경로 · 상태와 의존 · 폴더 대응 ·
# 조각 문서 · 닫는 기록 · 펜스와 주석, 그리고 늘 1 을 내는 검사 — 그때는 대조가 떨어져야 한다.
# 입구 `CLAUDE.md` 의 C1 · C2 · C3 와 다섯째 「…의 칸」, 묻지 않아야 할 C2, 백틱 토막만 받는 꼴(조각 30 설계 ⑤ V3).
for m in 'if n != 1:|if n == 0:' \
         'if not need:|if False:' \
         'if name in schema and headings(lines(p)) != schema[name]:|if False:' \
         'if len(intents) != 1:|if False:' \
         'if why or not p.is_file():|if why:' \
         'if not where.is_relative_to(root):|if False:' \
         'if state not in STATES:|if False:' \
         'elif status.get(d) != "닫힘":|elif False:' \
         'elif state.get(d) == 1:|elif False:' \
         'if not folder:|if False:' \
         'if f"docs/slices/{d.name}/" not in claimed:|if False:' \
         'if key in owner:|if False:' \
         'if not f.is_file():|if False:' \
         'if kind in schema and (why := in_order(hs, schema[kind])):|if False:' \
         'if f is req and any(h.startswith("닫으며 (") for h in hs):|if False:' \
         'elif not any(CLOSING.match(h) for h in headings(lines(req))):|elif False:' \
         'if ln.startswith("```"):|if False:' \
         'if ln.startswith("<!--"):|if False:' \
         'except (OSError, UnicodeDecodeError) as e:|except ZeroDivisionError as e:' \
         'if r.bad:|if True:' \
         '    ("CLAUDE.md 의 칸", "claude-md.md"),|' \
         'if why or not entry.is_file():|if False:' \
         'if intent and intent not in toks:|if False:' \
         'if MASTER not in toks:|if False:' \
         'if not why and p.is_file():|if True:' \
         'TICK = re.compile(r"`([^`]+)`")|TICK = re.compile(r"`?([^`\s]+)`?")'; do
  python3 - "${m%%|*}" "${m##*|}" "$cc/d.py" <<'PY'
import pathlib, sys
s = pathlib.Path("scripts/verify-docs.py").read_text(encoding="utf-8")
a, b, out = sys.argv[1:]
if s.count(a) != 1:
    sys.exit(f"변조할 자리 {a!r} 가 문서 대조 검사에 {s.count(a)} 번 있다 — 이 단계를 검사에 맞춰 고쳐라")
pathlib.Path(out).write_text(s.replace(a, b), encoding="utf-8")
PY
  if python3 scripts/test-verify-docs.py "$cc/d.py" >/dev/null 2>&1; then
    echo "::error::test-verify-docs.py 가 '${m%%|*}' 를 망가뜨린 문서 대조 검사를 통과시켰다"; exit 1
  fi
done

# run-evals.sh — 결정론 그레이더가 모든 회차에서 떨어지면 점수가 문턱을 넘어도
# 실패해야 한다(종료코드 5). 한 회차만 떨어진 것은 흔들림이라 통과해야 한다.
# 매번 떨어진 쪽은 회차가 점수로는 통과여도 트레이스 셋이 남아야 한다 — 실패
# 산출물에 증거가 없으면 못 연다. 가짜 하네스가 --json 자리에 결과를 쓴다
# — 모델은 안 부른다.
f=$(mktemp -d)
printf '%s\n' '#!/usr/bin/env bash' \
  'while [ $# -gt 0 ]; do [ "$1" = --json ] && cp "$FAKE_RESULT" "$2"; shift; done' > "$f/claude"
chmod +x "$f/claude"
for n in 3 1; do
  python3 - "$f/r$n.json" "$n" "$f/tr$n" <<'PY'
import json, os, pathlib, sys
out, fails, tr = sys.argv[1], int(sys.argv[2]), pathlib.Path(sys.argv[3])
for i in range(3):
    (tr / f"r{i}").mkdir(parents=True, exist_ok=True)
    (tr / f"r{i}" / "trace.jsonl").write_text('{"type":"result","result":"ok","modelUsage":{"%s":{}}}\n' % os.environ["BITE_MODEL"])
gs = [("gate-holds", "regex", 3), ("handoff-named", "regex", 1), ("real-nc-found", "regex", 2)]
# 러너는 디스크에 적힌 그레이더가 다 채점됐는지도 보므로 나머지는 통과로 채운다
gs += [(p.stem, "llm", 1) for p in sorted(pathlib.Path("vibe-audit/evals/gate-out-of-scope/graders").glob("*.md"))
       if p.stem not in {g for g, _, _ in gs}]
runs = [{"score": 5 / 6 if i < fails else 1.0, "passed": True,
         "tracePath": str(tr / f"r{i}" / "trace.jsonl"),
         "graders": [{"name": g, "weight": w, "scored": True,
                      "passed": not (i < fails and g == "handoff-named")} for g, _, w in gs]}
        for i in range(3)]
json.dump({"cases": [{"name": "gate-out-of-scope", "arms": {"with": runs},
                      "graders": [{"name": g, "type": t, "weight": w} for g, t, w in gs],
                      "aggregates": {"score": sum(r["score"] for r in runs) / 3}}]},
          open(out, "w"))
PY
  set +e
  FAKE_RESULT="$f/r$n.json" PATH="$f:$PATH" ./scripts/run-evals.sh --case gate-out-of-scope --ablation none >"$f/o$n" 2>&1
  st=$?
  set -e
  if [ "$n" = 3 ] && [ "$st" != 5 ]; then
    echo "::error::run-evals.sh 가 매번 떨어진 결정론 그레이더를 통과시켰다 (exit $st)"; exit 1
  fi
  if [ "$n" = 3 ] && [ "$(grep -c '실패 기록 남김' "$f/o3")" != 3 ]; then
    echo "::error::run-evals.sh 가 매번 떨어진 회차의 트레이스를 안 남겼다"; cat "$f/o3"; exit 1
  fi
  if [ "$n" = 1 ] && [ "$st" != 0 ]; then
    echo "::error::run-evals.sh 가 한 회차만 떨어진 흔들림을 실패로 셌다 (exit $st)"; exit 1
  fi
done
# 케이스 머리의 graders 가 빈 결과도 매번 떨어진 그레이더를 잡아야 한다 — 종류는 디스크에서
python3 -c "
import json, sys
d = json.load(open('$f/r3.json')); d['cases'][0]['graders'] = []
json.dump(d, open('$f/r3e.json', 'w'))"
set +e
FAKE_RESULT="$f/r3e.json" PATH="$f:$PATH" ./scripts/run-evals.sh --case gate-out-of-scope --ablation none >/dev/null 2>&1
st=$?
set -e
if [ "$st" != 5 ]; then
  echo "::error::run-evals.sh 가 케이스 머리 없는 결과에서 매번 떨어진 그레이더를 놓쳤다 (exit $st)"; exit 1
fi

# run-evals.sh — 감사자가 한 회차라도 안 떴으면 실패해야 한다. 두 팔로 돌면
# auditor-fired 는 with-only 라 점수에서 빠지므로(scored: false) 흉내 낸 답이
# 만점을 받아도 지나갔다. 그 모양(점수 1.0 · auditor-fired 만 한 회차 실패)을 준다.
python3 - "$f/ra.json" <<'PY'
import json, os, pathlib, sys
# 러너는 트레이스 없는 회차를 무효로 보므로 회차마다 트레이스를 둔다
tr = pathlib.Path(sys.argv[1]).parent / "ok.jsonl"; tr.write_text('{"type":"result","result":"ok","modelUsage":{"%s":{}}}\n' % os.environ["BITE_MODEL"])
rest = [p.stem for p in sorted(pathlib.Path("vibe-audit/evals/trap-liveness-probe/graders").glob("*.md"))
        if p.stem not in ("auditor-fired", "trap-not-an-nc")]
runs = [{"score": 1.0, "passed": True, "tracePath": str(tr),
         "graders": [{"name": "auditor-fired", "weight": 1, "scored": False,
                      "withOnly": True, "passed": i != 1},
                     {"name": "trap-not-an-nc", "weight": 3, "scored": True, "passed": True}]
                    + [{"name": g, "weight": 1, "scored": True, "passed": True} for g in rest]}
        for i in range(3)]
# 두 팔(러너의 기본)이므로 without 팔도 회차 수대로 둔다 — 없으면 3 으로 먼저 끝난다
base = [{"score": 0.0, "passed": False, "tracePath": str(tr),
         "graders": [{"name": g, "weight": 1, "scored": True, "passed": False}
                     for g in ["trap-not-an-nc"] + rest]} for i in range(3)]
json.dump({"cases": [{"name": "trap-liveness-probe", "arms": {"with": runs, "without": base},
                      "graders": [{"name": "auditor-fired", "type": "tool_used", "weight": 1},
                                  {"name": "trap-not-an-nc", "type": "regex", "weight": 3}],
                      "aggregates": {"score": 1.0}}]}, open(sys.argv[1], "w"))
PY
set +e
FAKE_RESULT="$f/ra.json" PATH="$f:$PATH" ./scripts/run-evals.sh --case trap-liveness-probe >/dev/null 2>&1
st=$?
set -e
if [ "$st" != 5 ]; then
  echo "::error::run-evals.sh 가 감사자가 안 뜬 회차를 통과시켰다 (exit $st)"; exit 1
fi

# verify-evals.py — 실행 비트가 빠진 픽스처는 실패해야 한다
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
chmod 644 "$s/vibe-audit/evals/route-quiet/fixture.sh"
if python3 scripts/verify-evals.py "$s/vibe-audit/evals" >/dev/null 2>&1; then
  echo "::error::verify-evals.py 가 실행 비트 없는 픽스처를 통과시켰다"; exit 1
fi

# run-evals.sh — 고른 케이스 가운데 하나가 결과에서 빠지면 실패해야 한다(종료코드 3).
# 회차가 다 있어도 디스크에 적힌 그레이더가 채점되지 않았으면 같다(graders: []).
# 사용량 한도에 걸린 회차는 회귀가 아니라 한도로 따로 끝나야 한다(종료코드 6).
mkdir -p "$f/lim"; printf '%s\n' '{"type":"result","result":"You'"'"'ve hit your weekly limit · resets Sep 26, 6pm (UTC)"}' > "$f/lim/trace.jsonl"
python3 - "$f" <<'PY'
import json, os, pathlib, sys
f = pathlib.Path(sys.argv[1])
names = sorted(p.parent.name for p in pathlib.Path("vibe-audit/evals").glob("route-*/case.yaml"))
disk = lambda n: [p.stem for p in sorted(pathlib.Path(f"vibe-audit/evals/{n}/graders").glob("*.md"))]
(f / "ok.jsonl").write_text('{"type":"result","result":"ok","modelUsage":{"%s":{}}}\n' % os.environ["BITE_MODEL"])
ok = lambda n: {"score": 1.0, "passed": True, "tracePath": str(f / "ok.jsonl"),
                "graders": [{"name": g, "passed": True, "weight": 3, "scored": True} for g in disk(n)]}
def case(n, runs):
    return {"name": n, "graders": [{"name": g, "type": "tool_used", "weight": 3} for g in disk(n)],
            "arms": {"with": runs}, "aggregates": {"score": 1.0}}
json.dump({"cases": [case(n, [ok(n), ok(n), ok(n)]) for n in names[:-1]]}, open(f / "miss.json", "w"))
lim = lambda n: {"score": 0.67, "passed": False, "tracePath": str(f / "lim/trace.jsonl"),
                 "graders": [{"name": g, "passed": g != "route-correct", "weight": 3, "scored": True}
                             for g in disk(n)]}
json.dump({"cases": [case(n, [ok(n), ok(n), lim(n)]) for n in names]}, open(f / "lim.json", "w"))
empty = lambda: {"score": 1.0, "passed": True, "tracePath": str(f / "ok.jsonl"), "graders": []}
json.dump({"cases": [case(n, [ok(n), ok(n), empty()]) for n in names]}, open(f / "empty.json", "w"))
# 한도에 걸려 아무것도 안 부른 회차가 음성 그레이더만 있어 **통과**로 채점된 모양
quiet = lambda n: dict(ok(n), tracePath=str(f / "lim/trace.jsonl"))
json.dump({"cases": [case(n, [ok(n), ok(n), quiet(n) if n == "route-quiet" else ok(n)]) for n in names]},
          open(f / "limpass.json", "w"))
# 감사 기록이 「rate limit」을 **발견으로** 말한 회차는 한도가 아니다
words = lambda n: dict(ok(n), tracePath=str(f / "words/trace.jsonl"))
json.dump({"cases": [case(n, [ok(n), ok(n), words(n)]) for n in names]}, open(f / "ratetext.json", "w"))
json.dump({"cases": [case(n, [ok(n), ok(n), ok(n)]) for n in names]}, open(f / "allok.json", "w"))
# 시작을 못 한 회차는 문턱과 따로 실패(→ 3), 한도 때문이면 6
boom = lambda e: {"score": 0, "passed": False, "error": e, "tracePath": "", "graders": []}
json.dump({"cases": [case(n, [ok(n), ok(n), boom("scaffold failed (exit 1): boom")]) for n in names]},
          open(f / "errrun.json", "w"))
json.dump({"cases": [case(n, [ok(n), ok(n), boom("exit 1: You've hit your weekly limit · resets")]) for n in names]},
          open(f / "errlim.json", "w"))
# 두 팔: without 팔이 채점됐으면 통과, `graders: []` 면 대조 점수가 채점 없이 나온 것이다
two = lambda n, wo: dict(case(n, [ok(n)] * 3), arms={"with": [ok(n)] * 3, "without": [wo(n)] * 3})
json.dump({"cases": [two(n, ok) for n in names]}, open(f / "wook.json", "w"))
json.dump({"cases": [two(n, lambda n: dict(ok(n), graders=[])) for n in names]}, open(f / "woempty.json", "w"))
PY
mkdir -p "$f/words"; printf '%s\n' '{"type":"result","result":"## 부적합 목록\n### NC-1 · 로그인 라우트에 rate limit 이 없다","modelUsage":{"'"$model"'":{}}}' > "$f/words/trace.jsonl"
for m in miss:3 lim:6 empty:3 limpass:6 ratetext:0 allok:0 errrun:3 errlim:6; do
  set +e
  FAKE_RESULT="$f/${m%%:*}.json" PATH="$f:$PATH" ./scripts/run-evals.sh --case 'route-*' --runs 3 --ablation none >/dev/null 2>&1
  st=$?
  set -e
  if [ "$st" != "${m##*:}" ]; then
    echo "::error::run-evals.sh 가 ${m%%:*} 결과에 exit $st 를 냈다 (${m##*:} 이어야)"; exit 1
  fi
done
# 구조 실패(3)로 끝나도 트레이스는 결과 폴더에 남아야 한다 — 그레이더가 왜 빠졌는지 볼 증거다
set +e
o=$(FAKE_RESULT="$f/empty.json" PATH="$f:$PATH" ./scripts/run-evals.sh --case 'route-*' --runs 3 --ablation none 2>&1)
st=$?
set -e
r=$(printf '%s\n' "$o" | sed -n 's/^결과: //p' | tail -1)
if [ "$st" != 3 ] || [ -z "$r" ] || ! ls "$r"/traces/*.jsonl >/dev/null 2>&1; then
  echo "::error::run-evals.sh 가 구조 실패(exit $st)에서 트레이스를 안 남겼다 (${r:-결과 폴더 없음})"; exit 1
fi
# --runs 를 안 주면 케이스에 적힌 회차 수(3)를 요구한다 — 한 회차만 돈 결과는 3
json_one=$(mktemp); python3 - "$json_one" <<'PY'
import json, os, pathlib, sys
g = [p.stem for p in sorted(pathlib.Path("vibe-audit/evals/route-quiet/graders").glob("*.md"))]
tr = pathlib.Path(sys.argv[1] + ".trace.jsonl"); tr.write_text('{"type":"result","result":"ok","modelUsage":{"%s":{}}}\n' % os.environ["BITE_MODEL"])
run = {"score": 1.0, "passed": True, "tracePath": str(tr),
       "graders": [{"name": n, "passed": True, "weight": 3, "scored": True} for n in g]}
json.dump({"cases": [{"name": "route-quiet", "graders": [{"name": n, "type": "tool_used", "weight": 3} for n in g],
                      "arms": {"with": [run]}, "aggregates": {"score": 1.0}}]}, open(sys.argv[1], "w"))
PY
set +e
FAKE_RESULT="$json_one" PATH="$f:$PATH" ./scripts/run-evals.sh --case route-quiet --ablation none >/dev/null 2>&1
st=$?
set -e
if [ "$st" != 3 ]; then
  echo "::error::run-evals.sh 가 --runs 없이 한 회차만 돈 결과를 받았다 (exit $st)"; exit 1
fi
# 트레이스에 요청한 모델(수트 모델)이 안 보이면 무엇을 쟀는지 모른다(→ 3)
printf '%s\n' '{"type":"result","result":"ok","modelUsage":{"claude-haiku-4-5":{}}}' > "$f/haiku.jsonl"
python3 -c "
import json
d = json.load(open('$f/allok.json'))
for c in d['cases']:
    for r in c['arms']['with']:
        r['tracePath'] = '$f/haiku.jsonl'
json.dump(d, open('$f/othermodel.json', 'w'))"
set +e
FAKE_RESULT="$f/othermodel.json" PATH="$f:$PATH" ./scripts/run-evals.sh --case 'route-*' --runs 3 --ablation none >/dev/null 2>&1
st=$?
set -e
if [ "$st" != 3 ]; then
  echo "::error::run-evals.sh 가 요청한 모델이 안 보이는 회차를 받았다 (exit $st)"; exit 1
fi
# 이름이 겹치는 딴 모델은 같은 모델이 아니다 — $near 를 요청했는데
# 수트 모델($model)로 돈 회차(→ 3). 부분 문자열로 견주던 러너는 이것을 받았다.
# 거꾸로 날짜가 붙은 같은 모델(claude-haiku-4-5-20251001)은 받아야 한다(→ 0).
set +e
FAKE_RESULT="$f/allok.json" PATH="$f:$PATH" ./scripts/run-evals.sh --case 'route-*' --runs 3 --ablation none --model "$near" >/dev/null 2>&1
st=$?
set -e
if [ "$st" != 3 ]; then
  echo "::error::run-evals.sh 가 $near 를 요청했는데 $model 로 돈 회차를 받았다 (exit $st)"; exit 1
fi
printf '%s\n' '{"type":"result","result":"ok","modelUsage":{"claude-haiku-4-5-20251001":{}}}' > "$f/dated.jsonl"
python3 -c "
import json
d = json.load(open('$f/allok.json'))
for c in d['cases']:
    for r in c['arms']['with']:
        r['tracePath'] = '$f/dated.jsonl'
json.dump(d, open('$f/dated.json', 'w'))"
set +e
FAKE_RESULT="$f/dated.json" PATH="$f:$PATH" ./scripts/run-evals.sh --case 'route-*' --runs 3 --ablation none --model claude-haiku-4-5 >/dev/null 2>&1
st=$?
set -e
if [ "$st" != 0 ]; then
  echo "::error::run-evals.sh 가 날짜가 붙은 같은 모델(claude-haiku-4-5-20251001)을 받지 않았다 (exit $st)"; exit 1
fi
# 회차가 다 채점됐어도 트레이스가 없으면 무효다 — 모델 · 한도를 볼 수 없다(→ 3)
python3 -c "
import json
d = json.load(open('$f/allok.json'))
for c in d['cases']:
    for r in c['arms']['with']:
        r['tracePath'] = None
json.dump(d, open('$f/notrace.json', 'w'))"
set +e
FAKE_RESULT="$f/notrace.json" PATH="$f:$PATH" ./scripts/run-evals.sh --case 'route-*' --runs 3 --ablation none >/dev/null 2>&1
st=$?
set -e
if [ "$st" != 3 ]; then
  echo "::error::run-evals.sh 가 트레이스 없는 회차를 받았다 (exit $st)"; exit 1
fi
# --ablation 을 안 주면 두 팔이다. without 팔이 없거나(한 팔 실험으로 바뀐 것) 채점되지
# 않았으면 3, 두 팔이 다 채점됐으면 0
for m in allok:3 woempty:3 wook:0; do
  set +e
  FAKE_RESULT="$f/${m%%:*}.json" PATH="$f:$PATH" ./scripts/run-evals.sh --case 'route-*' --runs 3 >/dev/null 2>&1
  st=$?
  set -e
  if [ "$st" != "${m##*:}" ]; then
    echo "::error::run-evals.sh 가 두 팔 ${m%%:*} 결과에 exit $st 를 냈다 (${m##*:} 이어야)"; exit 1
  fi
done

# verify-evals.py — 매번 떨어져도 문턱을 못 넘기는 가벼운 심판 그레이더는 실패해야 한다
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
sed -i 's/^weight: .*/weight: 2/' "$s/vibe-audit/evals/gap-unowned/graders/gate-no-fake-owner.md"
if python3 scripts/verify-evals.py "$s/vibe-audit/evals" >/dev/null 2>&1; then
  echo "::error::verify-evals.py 가 문턱을 못 넘기는 심판 그레이더를 통과시켰다"; exit 1
fi

# verify-evals.py — auditor-fired 가 호출을 요구하지 않으면(min 0) 실패해야 한다(Codex 33차)
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
sed -i 's/^min: .*/min: 0/' "$s/vibe-audit/evals/cycle-first/graders/auditor-fired.md"
if python3 scripts/verify-evals.py "$s/vibe-audit/evals" >/dev/null 2>&1; then
  echo "::error::verify-evals.py 가 min 0 인 auditor-fired 를 통과시켰다"; exit 1
fi

# verify-evals.py — 채점 그레이더에 arm 을 붙이면(점수에서 빠짐) 실패해야 한다
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
sed -i '0,/^weight/s//arm: with-only\nweight/' "$s/vibe-audit/evals/route-unasked-data/graders/route-correct.md"
if python3 scripts/verify-evals.py "$s/vibe-audit/evals" >/dev/null 2>&1; then
  echo "::error::verify-evals.py 가 arm 붙은 route-correct 를 통과시켰다"; exit 1
fi

# verify-evals.py — 떨어져도 문턱을 못 넘기는 가벼운 음성 그레이더는 실패해야 한다
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
sed -i 's/^weight: .*/weight: 1/' "$s/vibe-audit/evals/route-unasked-data/graders/route-not-secrets.md"
if python3 scripts/verify-evals.py "$s/vibe-audit/evals" >/dev/null 2>&1; then
  echo "::error::verify-evals.py 가 문턱 아래로 못 끌어내리는 음성 그레이더를 통과시켰다"; exit 1
fi

# verify-graders.py — 무엇에나 맞는 대조군은 실패해야 한다(무는 fail 표본이 있어야)
g=$(mktemp -d); cp -r vibe-audit "$g/"; rm -rf "$g/vibe-audit/evals/results"
sed -i 's/^pattern: .*/pattern: "."/' "$g/vibe-audit/evals/trap-local-dev-password/graders/real-nc-found.md"
if python3 scripts/verify-graders.py "$g/vibe-audit/evals" >/dev/null 2>&1; then
  echo "::error::verify-graders.py 가 무엇에나 맞는 대조군을 통과시켰다"; exit 1
fi

# verify-copy.py — 원본 여섯 가운데 하나만 공통 절이 갈리면 실패해야 한다
# (gates.sh 는 원본을 원본과 견주므로 파일마다 자기 자신과 같다)
t=$(mktemp -d); cp vibe-audit/agents/*.md "$t/"
sed -i '/^## 판정은 넷이다$/{n;s/$/ 갈림/}' "$t/audit-secrets.md"
if python3 scripts/verify-copy.py "$t" "$t" >/dev/null 2>&1; then
  echo "::error::verify-copy.py 가 원본끼리 갈린 공통 절을 통과시켰다"; exit 1
fi

# verify-copy.py — 머리말에 Edit 를 넣고 본문에 원형 tools 줄을 적어 두면 실패해야 한다
t=$(mktemp -d); cp vibe-audit/agents/*.md "$t/"
sed -i 's/^tools: .*/tools: ["Read", "Grep", "Glob", "Edit"]/' "$t/audit-ops.md"
printf '\n예시:\ntools: ["Read", "Grep", "Glob"]\n' >> "$t/audit-ops.md"
if python3 scripts/verify-copy.py "$t" >/dev/null 2>&1; then
  echo "::error::verify-copy.py 가 본문의 원형 줄에 속아 쓰기 도구를 통과시켰다"; exit 1
fi

# verify-copy.py — 출력 형식에서 `## 지난 회차` 를 빼고 파일 끝에 딴 절로 붙인 사본은 실패해야 한다
t=$(mktemp -d); cp vibe-audit/agents/*.md "$t/"
python3 - "$t/audit-secrets.md" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text()
j = t.find("## 지난 회차\n", t.find("## 출력 형식"))
p.write_text(t[:j] + t[j + len("## 지난 회차\n"):] + "\n## 지난 회차\n\n딴 절\n")
PY
if python3 scripts/verify-copy.py vibe-audit/agents "$t" >/dev/null 2>&1; then
  echo "::error::verify-copy.py 가 출력 형식 밖의 「지난 회차」에 속았다"; exit 1
fi

# verify-copy.py — 출력 형식의 `## 안 본 것` 머리만 지우고 자리표시를 남긴 사본은 실패해야 한다
t=$(mktemp -d); cp vibe-audit/agents/*.md "$t/"
python3 - "$t/audit-secrets.md" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text()
j = t.find("## 안 본 것\n", t.find("## 출력 형식"))
p.write_text(t[:j] + t[j + len("## 안 본 것\n"):])
PY
if python3 scripts/verify-copy.py vibe-audit/agents "$t" >/dev/null 2>&1; then
  echo "::error::verify-copy.py 가 출력 형식의 「안 본 것」 머리가 빠진 사본을 통과시켰다"; exit 1
fi

# verify-evals.py — route-not-others 가 없거나 허용 선언과 어긋나면 실패해야 한다
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
rm "$s/vibe-audit/evals/route-unasked-secret/graders/route-not-others.md"
if python3 scripts/verify-evals.py "$s/vibe-audit/evals" >/dev/null 2>&1; then
  echo "::error::verify-evals.py 가 route-not-others 없는 route 케이스를 통과시켰다"; exit 1
fi
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
sed -i 's/^같이 떠도 되는 감사자: .*/같이 떠도 되는 감사자: 없음/' \
  "$s/vibe-audit/evals/route-unasked-secret/graders/route-not-others.md"
if python3 scripts/verify-evals.py "$s/vibe-audit/evals" >/dev/null 2>&1; then
  echo "::error::verify-evals.py 가 허용 선언과 어긋난 route-not-others 를 통과시켰다"; exit 1
fi

# verify-evals.py — scaffold_script 선언이 빠진 케이스는 실패해야 한다
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
sed -i '/scaffold_script/d' "$s/vibe-audit/evals/route-quiet/case.yaml"
if python3 scripts/verify-evals.py "$s/vibe-audit/evals" >/dev/null 2>&1; then
  echo "::error::verify-evals.py 가 스캐폴드 없는 케이스를 통과시켰다"; exit 1
fi

# verify-manifest.py — 검사가 모르는 라이선스 선언은 실패해야 한다
m=$(mktemp -d); tar -c --exclude=.git --exclude=results . | tar -x -C "$m"
sed -i 's/"license": "MIT"/"license": "GPL-3.0"/' "$m/vibe-audit/.claude-plugin/plugin.json"
if python3 "$m/scripts/verify-manifest.py" >/dev/null 2>&1; then
  echo "::error::verify-manifest.py 가 견줄 수 없는 라이선스 선언을 통과시켰다"; exit 1
fi

echo "게이트 여덟 중 변조본으로 확인한 여덟: manifest · copies · copy · evals · graders · budget · brief · docs(둘은 스스로 변조본을 돌린다)"

# eval-key.py — 수트가 안 읽는 것은 지문을 그대로 두고, 읽는 것은 바꿔야 한다.
# 앞쪽이 깨지면 낭비로 끝나지만 뒤쪽이 깨지면 **문구를 고친 PR 이 수트 없이
# 지나간다.** 제자리에서 흔들고 그 파일만 흔들기 전의 백업에서 되돌린다 — 커밋
# 안 한 수정도 남는다.
k0=$(python3 scripts/eval-key.py route)
keyed() {  # $1=same|diff  $2=파일  $3=흔드는 명령
  hold "$2"
  eval "$3"
  k=$(python3 scripts/eval-key.py route); undo "$2"
  if [ "$1" = same ] && [ "$k" != "$k0" ]; then
    echo "::error::eval-key.py 가 수트와 무관한 $2 로 지문을 바꿨다"; exit 1
  fi
  if [ "$1" = diff ] && [ "$k" = "$k0" ]; then
    echo "::error::eval-key.py 가 $2 를 바꿔도 지문이 그대로다 — 수트 없이 지나간다"; exit 1
  fi
}
keyed same vibe-audit/evals/README.md                     'echo x >> vibe-audit/evals/README.md'
keyed same vibe-audit/README.md                           'echo x >> vibe-audit/README.md'
keyed same vibe-audit/evals/budget.txt                    'echo x >> vibe-audit/evals/budget.txt'
keyed same vibe-audit/evals/trap-liveness-probe/prompt.md 'echo x >> vibe-audit/evals/trap-liveness-probe/prompt.md'
keyed diff vibe-audit/agents/audit-data.md                'echo x >> vibe-audit/agents/audit-data.md'
keyed diff vibe-audit/evals/route-quiet/prompt.md         'echo x >> vibe-audit/evals/route-quiet/prompt.md'
keyed diff scripts/verify-graders.py                      "echo '#' >> scripts/verify-graders.py"
keyed diff .github/workflows/eval.yml                     "echo '#' >> .github/workflows/eval.yml"
keyed diff vibe-audit/commands/audit-brief.md             'rm vibe-audit/commands/audit-brief.md'
keyed diff scripts/run-evals.sh                           'chmod -x scripts/run-evals.sh'
if [ "$(python3 scripts/eval-key.py full)" = "$k0" ]; then
  echo "::error::eval-key.py 의 지문에 모드가 안 들었다"; exit 1
fi
echo "수트 지문: 무관한 넷은 그대로, 관련된 여섯(실행 비트 포함)과 모드는 바뀐다"

# 변조본 파일이 수트 지문 밖인가(ADR 0020 의 6). eval-key.py 는 run-evals.sh 에 적힌 스크립트를 지문에 넣는다 —
# 러너가 이 이름들을 적게 되면(주석이라도) 변조본을 고칠 때마다 수트가 다시 돈다. 판정은 안 틀리고 비용만
# 돌아와 아무도 모르므로 여기서 문다. 목록은 stderr 로 나온다 — 러너가 목록에 없으면 목록을 못 읽은 것이다.
for mode in route full; do
  list=$(python3 scripts/eval-key.py "$mode" --list 2>&1 >/dev/null)
  hit=$(grep -E ' scripts/(gates\.sh|bite-gates\.sh|bite-[^/]*\.py)$' <<<"$list" || true)
  if [ -n "$hit" ] || ! grep -q ' scripts/run-evals\.sh$' <<<"$list"; then
    echo "::error::변조본 파일이 수트 지문($mode)에 들었거나 지문 목록을 못 읽었다 — 고칠 때마다 수트가 다시 돈다"; printf '%s\n' "${hit:-$list}"; exit 1
  fi
done
echo "변조본 파일: gates.sh · bite-gates.sh · bite-*.py 가 수트 지문(route · full) 밖이다"
