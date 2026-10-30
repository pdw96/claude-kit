#!/usr/bin/env bash
# 키 없이 도는 검사가 **무는지** 본다 — 검사마다 변조본을 만들어 떨어지는지 본다. 모델도 API 도 안 쓴다.
#
#   ./scripts/bite-gates.sh      # gates.sh 가 부른다
#
# **왜 여기 있나.** 이 본문은 CI 「게이트가 무는가」 스텝(`eval.yml`)이었다. `eval.yml` 은 수트에 깃발을 넘겨
# 통째로 수트 지문(`eval-key.py`)에 들어, 변조본만 고쳐도 route 수트가 다시 돌았다. 그래서 스텝의 본문을 글자
# 그대로 옮기고 `gates.sh` 가 부른다(ADR 0020 의 1 · 2). 옮길 때(조각 11, 2026-10-12) 스텝과 다른 자리는 여섯이었다 — 이 머리, 저장소 맨 위를
# git 에서 읽는 것(CI 의 `$GITHUB_WORKSPACE` 대신), 임시 폴더를 한 폴더에 모아 끝날 때 지우는 것, 제자리 변조를
# 백업에서 되돌리는 것(ADR 0020 의 3), 수트 모델 id 를 `run-evals.sh` 에서 읽는 것(ADR 0020 의 4), 끝의 「변조본
# 파일이 수트 지문 밖인가」(ADR 0020 의 6).
#
# 조각 35 가 더한 절 — 변조 시험의 지문(`gate-key.py`)이 대조하는 기록에 그대로이고 넣는 쪽에 바뀌는지,
# `gates.sh` 의 건너뛰는 묶음(`bites`)에 변조 시험 다섯만 있는지, 거절하는 인자가 검사 전에 종료 2 인지(설계 ② K6 · G5),
# `gates.sh` 가 무엇을 실제로 부르는지 보는 자체 시험(`test-gates.py`)이 무는지(설계 끝 「닫기 전 감사 회차에서 찾은 것」).
# `verify-eval-gate.py` 절은 조각 37 이 더했다 — 늘 도는 `verify-eval-gate.py` 가 `eval.yml` 의 적기 · 건너뛰기 조건을 무는지(조각 37 설계 ② V).
# `test-gates.py` 절의 끝은 조각 38 이 더했다 — 고정 목록과 실패 전파가 무는지, 진짜 `gates.sh` 가 지나가는지(조각 38 설계 ② R · V).
# 절마다의 세 규칙(센 수 · 좁힌 「물었다」 · 대조군의 PASS 줄)과 규칙마다 변조본의 대조 둘은 조각 41 이 더했다 — 아래 sopen · bit · keep · sclose · rgap.
# `verify-ledger.py` 의 두 절은 조각 43 이 더했다 — 변조본은 틀에서 세운 고정 대장에서 돈다(조각 43 설계 ② B · 끝 「PR B 에서 정한 것」).
#
# **제자리에서 흔드는 파일.** `copies.json` 과 두 지문 시험의 파일은 사본이 아니라 제자리에서 흔든다. 흔들기 전에
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

# 변조본을 도는 절의 세 규칙(조각 41 설계 ② C · N · K · ADR 0054). 절마다 sopen 으로 열고 sclose 로 닫는다.
#   (가) sclose 가 돈 변조본 · 대조군의 수를 기대한 수와 견준다 — 목록에서 변조본 한 줄을 지운 사본이 지나가지 않게.
#   (나) bit 는 그 검사가 그 꼴에 내는 종료와 정확히 같고, 그 검사의 실패 줄이 있고, 트레이스백 · 셸 오류 줄이 없을 때만 「물었다」로
#        센다. 규칙 ID 를 찍는 검사는 실패 줄에 기대한 ID 를 든다. 검사마다의 실패 줄 꼴은 조각 41 설계 끝 「PR B 에서 정한 것」의 표.
#   (다) keep 은 종료 0 과 그 검사의 PASS 줄을 함께 본다 — 아무것도 보지 않고 0 으로 끝나는 검사가 대조군을 지나가지 않게.
# 0 이 아닌 아무 종료를 세던 절은 출력을 버렸다(>/dev/null) — 이제 출력을 받아 실패 줄을 본다.
PYF='^FAIL'                                    # verify-*.py · test-*.py 의 실패 줄 — 한 줄에 쓰든 `  - ` 줄로 까닭을 잇든 머리는 같다
SYF='(심지 않았다|심지 않는다|하지 않는다)\.?' # sync-agents.sh(--merge 아닌 길)의 거절 줄 — 거절마다 그 말로 끝맺는다
RVF='^FAIL '                                   # run-evals.sh 의 실패 줄 — 종료 3 · 5 · 6 이 다 「FAIL 」로 연다
NSEC=0
sopen() { SEC=$1; SB=0; SK=0; }
sclose() {  # $1=기대한 변조본 수 $2=기대한 대조군 수
  if [ "$SB" != "$1" ] || [ "$SK" != "$2" ]; then
    echo "::error::$SEC — 변조본 $SB · 대조군 $SK 이 돌았다, $1 · $2 이어야 한다"; exit 1
  fi
  NSEC=$((NSEC + 1))
}
BO="$tmp/bite.out"
brun() { set +e; "$@" >"$BO" 2>&1; bst=$?; set -e; }
crash() {  # $1=출력 파일 — 파이썬 트레이스백이나, 시험하는 셸 스크립트 자신의 실행 오류(줄 번호를 단 bash 의 말)가 있는가.
  # 검사가 전하는 남의 bash 오류(verify-evals.py 가 픽스처의 `bash -n` 을 옮기는 것 따위)는 세지 않는다.
  grep -qE '^Traceback \(most recent call last\)|(sync-agents|gates|run-evals)\.sh: line [0-9]+: ' "${1:-$BO}"
}
bit() {  # $1=기대한 종료 $2=실패 줄(grep -E) $3=이름 $4…=명령(env 로 환경을 준다)
  local want=$1 re=$2 name=$3; shift 3
  brun "$@"
  if [ "$bst" != "$want" ] || ! grep -qE -- "$re" "$BO" || crash; then
    echo "::error::$SEC — 「$name」을 그 규칙으로 물지 않았다 (종료 $bst · $want 이어야, 실패 줄 /$re/)"; tail -8 "$BO"; exit 1
  fi
  SB=$((SB + 1))
}
keep() {  # $1=PASS 줄(grep -E) $2=이름 $3…=명령
  local re=$1 name=$2; shift 2
  brun "$@"
  if [ "$bst" != 0 ] || ! grep -qE -- "$re" "$BO" || crash; then
    echo "::error::$SEC — 대조군 「$name」이 종료 0 과 PASS 줄로 지나가지 않았다 (종료 $bst, PASS 줄 /$re/)"; tail -8 "$BO"; exit 1
  fi
  SK=$((SK + 1))
}
# 규칙마다 변조본(설계 ② R) — 검사가 낼 수 있는 ID 가운데 시험 파일의 변조본이 기대하지 않는 것을 찍는다. 주석 줄은 보지 않는다.
# 읽은 ID 가 하나도 없으면 「읽는 법이 낡았다」로 종료 1 — 빈 목록끼리 견주어 지나가지 않게.
rgap() {  # $1=검사 $2=그 ID 를 읽는 정규식(묶음 1) $3=시험 파일 $4=변조본이 기대한 ID 를 읽는 정규식(묶음 1)
  python3 - "$@" <<'PY'
import pathlib, re, sys
chk, cre, tst, tre = sys.argv[1:]
code = lambda p: "\n".join(l for l in pathlib.Path(p).read_text(encoding="utf-8").split("\n") if not l.lstrip().startswith("#"))
have, want = set(re.findall(cre, code(chk), re.M)), set(re.findall(tre, code(tst), re.M))
if not have or not want:
    sys.exit(f"{chk} 의 ID({len(have)}) 나 {tst} 의 기대 ID({len(want)}) 를 하나도 못 읽었다 — 읽는 정규식이 낡았다")
print(" ".join(sorted(have - want)))
PY
}

# verify-copy.py — tools 를 변조한 사본은 실패해야 한다
sopen "verify-copy.py(사본 · 원본 폴더)"
keep '^PASS 감사자 6개' "고치지 않은 원본" python3 scripts/verify-copy.py vibe-audit/agents
cat "$BO"
t=$(mktemp -d); cp vibe-audit/agents/*.md "$t/"
sed -i 's/^tools: .*/tools: ["Read", "Grep", "Glob", "Edit"]/' "$t/audit-secrets.md"
bit 1 "$PYF" "tools 변조" python3 scripts/verify-copy.py "$t"
# verify-copy.py — 원본 폴더에 감사자가 아닌 에이전트가 있으면 실패해야 한다(Codex 33차)
t=$(mktemp -d); cp vibe-audit/agents/*.md "$t/"
printf -- '---\nname: helper\ndescription: x\ntools: ["Read", "Edit", "Write"]\n---\n' > "$t/helper.md"
bit 1 "$PYF" "감사자가 아닌 에이전트가 섞인 원본" python3 scripts/verify-copy.py "$t" "$t"
# README.md 라는 이름도 예외가 아니다 — 플러그인에서는 agents/*.md 가 다 에이전트다(Codex 34차)
rm "$t/helper.md"; printf -- '---\nname: readme\ndescription: x\ntools: ["Read", "Edit", "Write"]\n---\n' > "$t/README.md"
bit 1 "$PYF" "README.md 로 숨긴 에이전트" python3 scripts/verify-copy.py "$t" "$t"
# 원본 감사자의 머리말 name 이 파일 이름과 다르면 실패해야 한다(Codex 35차)
t=$(mktemp -d); cp vibe-audit/agents/*.md "$t/"
sed -i '0,/^name: .*/s//name: audit-opx/' "$t/audit-ops.md"
bit 1 "$PYF" "name 이 파일 이름과 다른 원본 감사자" python3 scripts/verify-copy.py "$t" "$t"
sclose 4 1

# sync-agents.sh — 대장에 있는 사본에 커맨드만 빠졌으면 **아무것도 쓰지 않고** 멈춰야 한다.
# 빠진 것만 심으면 그 파일이 옛 synced_commit 아래 들어가 대조 밖에 남는다(Codex 28차).
# --force 면 다 덮고 대장을 이 커밋으로 옮긴다. 감사자가 다 있어 첫 고리가 전부
# 건너뛰면 HDR 이 안 정해져 `set -u` 로 죽던 것(18차)도 --force 쪽에서 같이 본다
# 거절 꼴(변조본)은 종료 1 과 거절 줄($SYF)에 흔적 없음을, 심는 꼴(대조군)은 종료 0 과 호출 줄에 심은 결과를 본다.
sopen "sync-agents.sh(기본 · --force)"
SYOK='^  호출: @audit-'   # 심은 뒤 찍는 호출 줄 — 심는 길의 PASS 줄
c=$(mktemp -d); git clone -q "$R" "$c/src"; mkdir -p "$c/svc"
keep "$SYOK" "빈 자리에 심기" env HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc"
# 대장에는 홈 기준 경로를 적는다 — 절대 경로는 계정 이름 · 비공개 디렉터리를 커밋에 남긴다
if ! grep -q '"agents_path": "~/svc/.claude/agents"' "$c/src/copies.json"; then
  echo "::error::sync-agents.sh 가 대장에 홈 기준이 아닌 경로를 적었다"; cat "$c/src/copies.json"; exit 1
fi
# 브리핑 검사기도 심어야 한다 — 커맨드는 사본 안의 .claude/scripts/ 에서 부른다
if [ ! -f "$c/svc/.claude/scripts/verify-brief.py" ]; then
  echo "::error::sync-agents.sh 가 브리핑 검사기를 심지 않았다"; exit 1
fi
sytrace() {  # $1=있으면 안 되는 자리 … — 거절한 실행이 남긴 흔적
  local p; for p in "$@"; do
    if [ -e "$p" ]; then echo "::error::$SEC — 거절했는데 $p 가 생겼다"; cat "$BO"; exit 1; fi
  done
}
rm "$c/svc/.claude/commands/audit-brief.md"
bit 1 "$SYF" "일부만 있는 사본에 빠진 커맨드만 심기" env HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc"
sytrace "$c/svc/.claude/commands/audit-brief.md"
keep "$SYOK" "--force 가 빠진 커맨드를 심음" env HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc" --force
if [ ! -f "$c/svc/.claude/commands/audit-brief.md" ]; then
  echo "::error::sync-agents.sh --force 가 빠진 커맨드를 못 심었다"; cat "$BO"; exit 1
fi
# 심을 폴더 자리에 파일이 있으면 **아무것도 쓰기 전에** 멈춰야 한다 — 앞 폴더에 다 심고
# mkdir 에서 죽으면 대장에 없는 반쪽 사본이 남는다(Codex 리뷰)
mkdir -p "$c/svc3/.claude"; : > "$c/svc3/.claude/scripts"
bit 1 "$SYF" "폴더 자리의 파일" env HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc3"
sytrace "$c/svc3/.claude/agents"
# 심을 파일 자리에 끊긴 링크가 있어도 쓰기 전에 멈춰야 한다 — `-e` 로는 없는 것처럼 보여
# 앞 폴더에 다 심고 cp 에서 죽었다(Codex 리뷰)
mkdir -p "$c/svc4/.claude/scripts"; ln -s nowhere "$c/svc4/.claude/scripts/verify-brief.py"
bit 1 "$SYF" "끊긴 링크 자리" env HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc4"
sytrace "$c/svc4/.claude/agents"
# 파일 자리에 폴더가 있으면 --force 여도 쓰기 전에 멈춰야 한다 — cp 가 그 폴더 안에 심고
# 성공한 것으로 대장을 옮겼다(Codex 리뷰)
mkdir -p "$c/svc5/.claude/scripts/verify-brief.py"
bit 1 "$SYF" "--force 의 파일 자리의 폴더" env HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc5" --force
sytrace "$c/svc5/.claude/agents"
# 폴더 자리가 바깥 폴더를 가리키는 링크여도 쓰기 전에 멈춰야 한다 — `-d` 는 링크를 따라가
# 바깥에 심고 대장을 옮겼다(Codex 리뷰)
mkdir -p "$c/svc6/.claude" "$c/outside"; ln -s "$c/outside" "$c/svc6/.claude/scripts"
bit 1 "$SYF" "링크로 된 폴더 자리" env HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc6"
sytrace "$c/svc6/.claude/agents"
if [ -n "$(ls -A "$c/outside")" ]; then echo "::error::sync-agents.sh 가 링크 너머 바깥 폴더에 썼다"; exit 1; fi
# --force 는 원본에서 물러난 커맨드를 사본에서 지워야 한다 — 남으면 옛 커맨드가 불리고 대장만 새 커밋을 적는다(Codex 29차)
(cd "$c/src" && git rm -q vibe-audit/commands/audit-brief.md && git -c user.name=t -c user.email=t@t commit -qm retire)
keep "$SYOK" "--force 가 물러난 커맨드를 지움" env HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc" --force
sytrace "$c/svc/.claude/commands/audit-brief.md"
# --force 는 얕은 복제에서 거절해야 한다 — 경계 앞에서 물러난 것을 못 본다(Codex 32차)
git clone -q --depth 1 "file://$c/src" "$c/shallow"
bit 1 "$SYF" "얕은 복제의 --force" env HOME="$c" "$c/shallow/scripts/sync-agents.sh" "$c/svc" --force
# 무시된(ignored) 원본 파일은 심지 않아야 한다 — HEAD 에 없어 출처가 없다(Codex 34차)
mkdir -p "$c/svc2" "$c/src/vibe-audit/commands"; echo 'vibe-audit/commands/local.md' >> "$c/src/.git/info/exclude"
printf -- '---\ndescription: x\n---\n' > "$c/src/vibe-audit/commands/local.md"
bit 1 "$SYF" "HEAD 에 없는 무시된 커맨드" env HOME="$c" "$c/src/scripts/sync-agents.sh" "$c/svc2"
sytrace "$c/svc2/.claude/commands/local.md"
rm "$c/src/vibe-audit/commands/local.md"
sclose 7 3

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
  # 그 꼴의 종료와 정확히 — 인자의 거절(P1 의 둘)은 2, 그 밖의 멈춤은 1. 0 이 아닌 아무 종료를 세지 않는다(조각 41 설계 ② N1)
  local rc=1; case "$code" in merge:force-and-merge|merge:no-target) rc=2 ;; esac
  if [ "$mrc" -ne "$rc" ]; then mfail "$name: 종료 $mrc — $rc 여야 한다"; return; fi
  if crash "$F/out"; then mfail "$name: 트레이스백이나 셸 오류 줄이 있다"; return; fi
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
# 센 수(조각 41 설계 ② C) — 고정 꼴 MFIXED 와, 사본 파일마다 도는 T5c · T5d · T5e 셋. 꼴 한 줄을 지운 절은 여기서 떨어진다.
# 파일마다의 몫은 사본 파일의 수(MNAMES)로 센다 — 플러그인에 파일이 늘면 그 꼴도 함께 는다.
MFIXED=54
MPER=3   # 사본 파일마다 도는 꼴 — T5c · T5d · T5e
mn=$(grep -c . <<<"$MNAMES")
if [ "$mpass" != $((MFIXED + MPER * mn)) ]; then
  echo "::error::sync-agents.sh --merge 의 꼴이 $mpass 돌았다 — $((MFIXED + MPER * mn))(고정 $MFIXED · 사본 파일 $mn 마다 $MPER) 이어야 한다"; exit 1
fi
NSEC=$((NSEC + 1))
echo "sync-agents.sh --merge: 꼴 $mpass(고정 $MFIXED · 사본 파일 $mn 마다 $MPER) 다 지나감 — 거절은 그 종료 · 이유 코드 · 그대로, 성공은 기대본 · 대장 · 표, 지금 길은 c56e571 과 같음, 이유 코드마다 시험"

# verify-evals.py — 대조군을 뺀 수트는 실패해야 한다
sopen "verify-evals.py · verify-graders.py(수트)"
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
rm "$s"/vibe-audit/evals/*/graders/real-nc-found.md
bit 1 "$PYF" "대조군 없는 수트" python3 scripts/verify-evals.py "$s/vibe-audit/evals"

# verify-evals.py — input_match 가 subagent_type 에 안 걸린 그레이더는 실패해야 한다.
# 이름만 적으면 입력 어디에 적혀 있기만 해도 뜬 것으로 센다. 공백을 넣은 JSON 은
# 하네스가 펴는 모양과 달라 영영 안 맞으므로, 음성 그레이더가 늘 통과한다.
for mut in \
  "s/^input_match: .*/input_match: audit-data/" \
  "s/\"subagent_type\":\"/\"subagent_type\": \"/"; do
  s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
  sed -i "$mut" "$s/vibe-audit/evals/route-contract/graders/route-not-data.md"
  bit 1 "$PYF" "subagent_type 에 안 걸린 input_match ($mut)" python3 scripts/verify-evals.py "$s/vibe-audit/evals"
done

# verify-evals.py — route-quiet 이 감사자 하나만 짚으면 실패해야 한다
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
sed -i 's/"vibe-audit:'"'"'$/"vibe-audit:audit-data"'"'"'/' "$s/vibe-audit/evals/route-quiet/graders/route-quiet.md"
bit 1 "$PYF" "하나만 짚는 route-quiet" python3 scripts/verify-evals.py "$s/vibe-audit/evals"

# verify-graders.py — 함정을 못 무는 그레이더는 실패해야 한다
g=$(mktemp -d); cp -r vibe-audit "$g/"; rm -rf "$g/vibe-audit/evals/results"
sed -i 's/NC-3\\\\b/NC-9\\\\b/' "$g/vibe-audit/evals/cycle-continuity/graders/trap-no-false-resolved.md"
bit 1 "$PYF" "못 무는 그레이더" python3 scripts/verify-graders.py "$g/vibe-audit/evals"

# verify-graders.py — pass.md 밖의 바른 기록(pass-*.md)에서 떨어지는 그레이더는 실패해야 한다.
# pass.md 만 보던 판은 이것을 지나보냈다. 수트 안의 pass-*.md 에 기대지 않고 pass.md 를
# 베껴 report.py 줄을 뺀다 — gate-escalated-perf 하나만 떨어진다(조각 21, ADR 0031).
g=$(mktemp -d); cp -r vibe-audit "$g/"; rm -rf "$g/vibe-audit/evals/results"
grep -v 'report\.py' "$g/vibe-audit/evals/gap-unowned/samples/pass.md" > "$g/vibe-audit/evals/gap-unowned/samples/pass-bite.md"
bit 1 "$PYF" "pass-*.md 에서 떨어지는 그레이더" python3 scripts/verify-graders.py "$g/vibe-audit/evals"
sclose 6 0

# 회수율 케이스(조각 39 설계 ② M · ⑤ R1 · R2 · 설계 끝 「닫기 전 감사 회차에서 찾은 것」). 회수율 폴더의 사본에서 조건마다 한 자리를
# 흔들어 그 검사가 떨어져야 하고, 고치지 않은 사본과 회수율 폴더가 없는 트리는 지나가야 한다. 흔드는 명령은 사본의 회수율 폴더에서
# 돈다($C 는 케이스 이름). 「물었다」는 종료 1 과 그 조건의 FAIL 글이 함께 있을 때만이다 — 다른 규칙이 같은 변조본을 떨어뜨려도
# 모르는 일이 없게(감사 회차 6 NC-4 · OB-1). 끝에 센 수를 기대한 수와 견준다.
sopen "회수율 케이스(verify-evals.py · verify-graders.py)"
C=recall-commit-after-response
rbite() {  # $1=evals|graders  $2=무엇  $3=흔드는 명령  $4=그 조건의 FAIL 글(고정 문자열)
  local s; s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results" "$s/vibe-audit/recall/results"
  ( cd "$s/vibe-audit/recall" && eval "$3" )
  brun python3 "scripts/verify-$1.py" "$s/vibe-audit/recall"
  if [ "$bst" != 1 ] || ! grep -F -- "$4" "$BO" | grep -q '^FAIL ' || crash; then
    echo "::error::verify-$1.py 가 회수율 변조본 「$2」을 그 조건으로 떨어뜨리지 않았다 (종료 $bst, 기대한 FAIL 글: $4)"; tail -5 "$BO"; exit 1
  fi
  SB=$((SB + 1))
}
rbite evals   "이름이 recall- 가 아님(M1)"          'mv $C x-commit && sed -i "s/^name: .*/name: x-commit/" x-commit/case.yaml' '이름은 recall- 로 시작한다'
rbite evals   "감사자를 지목하지 않음(M1)"           'sed -i "s/audit-data/감사자/" $C/prompt.md' '지목해야 한다 — 지금 없음'
rbite evals   "감사자 둘을 지목(M1)"                 'echo "audit-secrets 도 함께" >> $C/prompt.md' "지금 ['audit-data', 'audit-secrets']"
rbite evals   "recall-found 없음(M2)"                'rm $C/graders/recall-found.md' 'recall-found 가 없다'
rbite evals   "recall-found 가 심판(M2)"             'sed -i "s/^type: regex/type: llm/" $C/graders/recall-found.md' 'recall-found: type 이 regex 여야'
rbite evals   "recall-found 를 뒤집음(M2)"           'sed -i "s/^type: regex/type: regex\nmatch: not_contains/" $C/graders/recall-found.md' 'match: not_contains'
rbite evals   "recall-found 의 target(M2)"           'sed -i "s/^target: last_message/target: transcript/" $C/graders/recall-found.md' 'target 이 last_message 여야'
rbite evals   "recall-found 의 pattern 없음(M2)"     'sed -i "/^pattern:/d" $C/graders/recall-found.md' 'pattern 이 없다'
rbite evals   "recall-found 에 arm(M2)"              'sed -i "s/^type: regex/type: regex\narm: with-only/" $C/graders/recall-found.md' 'recall-found: arm 이 붙어'
rbite evals   "recall-found 머리말이 빔(M2)"         'printf -- "---\n---\n" > $C/graders/recall-found.md' 'recall-found: type 이 regex 여야'
rbite evals   "목적 그레이더 둘(M2 · M4)"            'cp $C/graders/recall-found.md $C/graders/recall-found-2.md' "['recall-found-2']"
rbite evals   "auditor-fired 없음(M3)"               'rm $C/graders/auditor-fired.md' 'auditor-fired 가 없다'
rbite evals   "auditor-fired 가 점수에 듦(M3)"       'sed -i "/^arm: with-only/d" $C/graders/auditor-fired.md' 'arm 이 with-only 여야'
rbite evals   "auditor-fired 머리말이 빔(M3)"        'printf -- "---\n---\n" > $C/graders/auditor-fired.md' 'auditor-fired: input_match 가 없다'
rbite evals   "auditor-fired 가 이름만 봄(M3)"       'sed -i "s/^input_match: .*/input_match: audit-data/" $C/graders/auditor-fired.md' 'subagent_type 에 걸려 있지 않다'
rbite evals   "auditor-fired 가 딴 플러그인(M3)"     'sed -i "s/vibe-audit:audit-data/other-kit:audit-data/" $C/graders/auditor-fired.md' '이 플러그인(vibe-audit)이 아니다'
rbite evals   "auditor-fired 의 min 0(M3)"           'sed -i "s/^min: 1/min: 0/" $C/graders/auditor-fired.md' 'min 이 1 이상이어야'
rbite evals   "auditor-fired 의 tool(M3)"            'sed -i "s/^tool: Agent/tool: Skill/" $C/graders/auditor-fired.md' 'tool 은 Agent 여야'
rbite evals   "대조군을 더함(M4)"                    'cp ../evals/gate-own-not-pushed/graders/real-nc-found.md $C/graders/' "['real-nc-found']"
rbite evals   "출처 줄 없음(M5)"                     'sed -i "/^  출처:/d" $C/case.yaml' '「출처:」 줄이 없다'
rbite evals   "schema_version"                       'sed -i "s/^schema_version: .*/schema_version: \"1.0\"/" $C/case.yaml' 'schema_version 이 "1.1" 이 아니다'
rbite evals   "name 이 폴더와 다름"                  'sed -i "s/^name: .*/name: recall-other/" $C/case.yaml' 'name 이 디렉터리 이름과 다르다'
rbite evals   "픽스처의 실행 비트"                   'chmod -x $C/fixture.sh' '실행 비트가 없다'
rbite evals   "픽스처의 문법"                        'echo "if then" >> $C/fixture.sh' 'bash 문법 검사에서 깨진다'
rbite graders "fail 표본 없음(M6)"                   'rm $C/samples/fail*.md' 'samples/fail*.md 이 하나도 없다'
rbite graders "pass 표본 없음(M6)"                   'rm $C/samples/pass.md' 'samples/pass.md 이 없다'
rbite graders "표본 폴더 없음(M6)"                   'rm -r $C/samples' '회수율 케이스에 samples/ 가 없다'
rbite graders "아무 NC 나 받는 정규식(M6)"           'python3 -c "import pathlib,re; p=pathlib.Path(\"$C/graders/recall-found.md\"); p.write_text(re.sub(r\"(?m)^pattern: .*$\", lambda m: \"pattern: \\\"### NC-\\\\\\\\d+\\\"\", p.read_text()))"' '함정을 밟은 기록'
# 인자 없는 길 — gates.sh 와 러너가 부르는 꼴(감사 회차 6 NC-3). 트리를 통째로 베껴 회수율 케이스 하나를 깨뜨리고, 폴더를 주지 않고
# 부른다. 회수율 폴더를 보지 않거나 그 종료를 버리는 인자 없는 길이면 여기서 떨어진다.
for m in "evals|sed -i '/^  출처:/d' vibe-audit/recall/$C/case.yaml|「출처:」 줄이 없다" \
         "graders|rm vibe-audit/recall/$C/samples/fail-missed.md vibe-audit/recall/$C/samples/fail-observation.md|samples/fail*.md 이 하나도 없다"; do
  chk=${m%%|*}; rest=${m#*|}; cmd=${rest%%|*}; want=${rest#*|}
  u=$(mktemp -d); tar -c --exclude=.git --exclude=results . | tar -x -C "$u"
  ( cd "$u" && eval "$cmd" )
  brun python3 "$u/scripts/verify-$chk.py"
  if [ "$bst" != 1 ] || ! grep -F -- "$want" "$BO" | grep -q '^FAIL ' || crash; then
    echo "::error::verify-$chk.py 가 인자 없이 깨진 회수율 케이스를 떨어뜨리지 않았다 (종료 $bst)"; tail -5 "$BO"; exit 1
  fi
  SB=$((SB + 1))
done
# 대조군 — 고치지 않은 회수율 사본은 두 검사를 종료 0 과 PASS 줄로 지나고, 회수율 폴더가 없는 트리는 인자 없이 「0개」로 지나간다.
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results" "$s/vibe-audit/recall/results"
for chk in evals graders; do
  keep '^PASS 회수율 케이스 6개' "verify-$chk.py 에 고치지 않은 회수율 사본" python3 "scripts/verify-$chk.py" "$s/vibe-audit/recall"
done
u=$(mktemp -d); tar -c --exclude=.git --exclude=results . | tar -x -C "$u"; rm -rf "$u/vibe-audit/recall"
for chk in evals graders; do
  keep '^PASS 회수율 케이스 0개' "verify-$chk.py 에 회수율 폴더 없는 트리(인자 없이)" python3 "$u/scripts/verify-$chk.py"
done
sclose 30 4   # 폴더를 주는 변조본 28(verify-evals.py 스물넷 · verify-graders.py 넷) · 인자 없는 길 2 / 대조군 둘씩 둘
echo "회수율 케이스: 변조본 $SB(폴더를 주는 꼴과 인자 없는 길)이 그 조건의 FAIL 글로 떨어지고, 대조군 $SK(고치지 않은 사본 · 회수율 폴더 없는 트리)이 PASS 줄로 지나감"

# verify-budget.py — 문구가 자란 사본은 실패해야 한다
sopen "verify-budget.py · verify-manifest.py"
u=$(mktemp -d); tar -c --exclude=.git --exclude=results . | tar -x -C "$u"
python3 -c "
import pathlib
p = pathlib.Path('$u/vibe-audit/agents/audit-secrets.md')
p.write_text(p.read_text() + '\n' + '규칙을 더 붙인다. ' * 200)
"
bit 1 "$PYF" "자란 문구" python3 "$u/scripts/verify-budget.py"

# verify-manifest.py — 선언한 라이선스의 파일이 없으면 실패해야 한다
m=$(mktemp -d); tar -c --exclude=.git --exclude=results . | tar -x -C "$m"
rm "$m/LICENSE"
bit 1 "$PYF" "LICENSE 없는 선언" python3 "$m/scripts/verify-manifest.py"
sclose 2 0

# verify-copies.py — 이 저장소에 없는 커밋을 적은 대장은 실패해야 한다.
# 이 검사는 git 이력을 보므로 사본이 아니라 제자리에서 흔들고 되돌린다. 떨어져 끝나면 trap 이 되돌린다(undo_all).
sopen "verify-copies.py(제자리)"
hold copies.json
python3 - <<'PY'
import json, pathlib
p = pathlib.Path("copies.json")
d = json.loads(p.read_text(encoding="utf-8"))
d["copies"].append({"repo": "없는-레포", "agents_path": "/없는/자리",
                    "synced_commit": "0" * 40, "synced_at": "2026-01-01"})
p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
bit 1 "$PYF" "없는 커밋을 적은 대장" python3 scripts/verify-copies.py
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
keep '^PASS 사본 [0-9]+개' "그 커밋에서 그대로 심은 사본(체크아웃이 얕으면 떨어진다)" python3 scripts/verify-copies.py
cat "$BO"
# 감사자의 머리말 name 을 바꾼 사본도 실패해야 한다 — 문서가 적은 이름으로 안 불린다
cp "$c/.claude/agents/audit-secrets.md" "$c/keep.md"
sed -i '0,/^name: .*/s//name: renamed-secrets/' "$c/.claude/agents/audit-secrets.md"
bit 1 "$PYF" "name 을 바꾼 감사자 사본" python3 scripts/verify-copies.py
mv "$c/keep.md" "$c/.claude/agents/audit-secrets.md"
rm "$c/.claude/commands/audit-brief.md"
bit 1 "$PYF" "/audit-brief 가 빠진 사본" python3 scripts/verify-copies.py
# 검사기가 빠진 사본도 실패해야 한다. 적는 커밋은 검사기를 가진 것으로 골랐다 —
# 없는 커밋을 고르면 이 변조가 늘 건너뛰어져 아무것도 안 본다(Codex 리뷰)
if [ ! -f "$c/.claude/scripts/verify-brief.py" ]; then
  echo "::error::적는 커밋 $old 에 브리핑 검사기가 없다 — 검사기 빠진 사본 변조를 못 한다"; exit 1
fi
git show "$old:vibe-audit/commands/audit-brief.md" > "$c/.claude/commands/audit-brief.md"
rm "$c/.claude/scripts/verify-brief.py"
bit 1 "$PYF" "브리핑 검사기가 빠진 사본" python3 scripts/verify-copies.py
undo copies.json
sclose 4 1

# verify-copies.py — 사본 줄이 그 뒤 바뀐 원본 파일의 이름을 찍어야 한다(조각 15 설계 ② V2). 경로가 없는 줄
# (CI 의 꼴)에 커맨드를 마지막으로 고친 커밋의 부모를 적으면, 그 커밋이 고친 커맨드 이름이 그 줄에 나와야 한다. 닿지 않는 사본 줄은
# 판정 밖이라 종료 0 과 PASS 줄이다 — 그 실행에 이름이 찍혔는지를 하나로 센다.
sopen "verify-copies.py(바뀐 원본 이름)"
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
keep '^PASS 사본 [0-9]+개' "닿지 않는 사본 줄이 든 대장" python3 scripts/verify-copies.py
line=$(grep '이름-보는-사본:' "$BO" || true)
undo copies.json
for n in $want; do
  case "$line" in
    *"바뀐 원본: "*"$n"*) ;;
    *) echo "::error::verify-copies.py 가 그 뒤 바뀐 원본 $n 의 이름을 사본 줄에 안 찍었다 — $line"; exit 1 ;;
  esac
done
sclose 0 1

# verify-feedback.py — 성하지 않은 후보 대장은 실패해야 한다(docs/schema.md 의 규칙).
# 같은 모양의 성한 대장은 통과해야 한다 — 다 떨어뜨리는 검사도 무는 것처럼 보인다. 나쁜 대장은 glob 으로 돌고 끝에 센다.
sopen "verify-feedback.py"
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
keep '^PASS 후보 1 ' "성한 대장" python3 scripts/verify-feedback.py "$fb/ok.json"
for f in "$fb"/bad-*.json; do
  bit 1 "$PYF" "$(basename "$f" .json) 대장" python3 scripts/verify-feedback.py "$f"
done
sclose 11 1

# test-compare-copies.py — 비교기를 한 군데씩 망가뜨리면 자체 시험이 떨어져야 한다.
# 그 시험이 무는지를 따로 묻지 않으면, 시험이 비어도 gates.sh 는 초록이다.
sopen "test-compare-copies.py"
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
  bit 1 "$PYF" "'${m%%|*}' 를 망가뜨린 비교기" python3 scripts/test-compare-copies.py "$cc/c.py"
done
sclose 9 0

# test-verify-feedback.py — 역사 규칙을 끈 대장 검사기를 자체 시험이 잡아야 한다
sopen "test-verify-feedback.py"
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
  bit 1 "$PYF" "'${m%%|*}' 를 망가뜨린 대장 검사기" python3 scripts/test-verify-feedback.py "$cc/v.py"
done
sclose 2 0

# test-verify-docs.py — 문서 대조 검사를 보장 묶음마다 한 군데씩 망가뜨리면 자체 시험이 떨어져야 한다
# (조각 3 설계 ⑤ 「시험이 문다」). 원천 · 틀 · 의도 · 마스터플랜 경로 · 상태와 의존 · 폴더 대응 ·
# 조각 문서 · 닫는 기록 · 펜스와 주석, 그리고 늘 1 을 내는 검사 — 그때는 대조가 떨어져야 한다.
# 입구 `CLAUDE.md` 의 C1 · C2 · C3 와 다섯째 「…의 칸」, 묻지 않아야 할 C2, 백틱 토막만 받는 꼴(조각 30 설계 ⑤ V3).
# 프로필의 P1 자리마다 하나와 여섯째 「…의 칸」, CommonMark 펜스의 여닫는 꼴(조각 31 설계 ⑤ V3).
# 빠르게(조각 36 설계 ② P2 ~ P5 · ADR 0047) — 변조본을 먼저 다 만들고, 자체 시험을 `--first`(첫 어긋난 꼴에서 멈춘다)로
# CPU 수만큼 함께 돌린다. 변조본은 제 사본만 읽어 서로 기대지 않는다. 먼저 대조군 — 바꾸지 않은 검사 — 을 같은 길로 돌려
# 지나가고 「물지 않았다」로 세는지 본다. 물지 않은 변조본은 다 모아 찍고 떨어진다. 끝에 센 수를 기대한 수와 견준다.
sopen "test-verify-docs.py"
dv="$cc/docs"; mkdir -p "$dv"
cp scripts/verify-docs.py "$dv/m0.py"
dnames=("대조군 — 바꾸지 않은 검사")
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
         'if m and not (m.group(1)[0] == "`" and "`" in m.group(2)):|if False:' \
         'if ln.startswith("<!--"):|if False:' \
         'except (OSError, UnicodeDecodeError) as e:|except ZeroDivisionError as e:' \
         'if r.bad:|if True:' \
         '    ("CLAUDE.md 의 칸", "claude-md.md"),|' \
         'if why or not entry.is_file():|if False:' \
         'if intent and intent not in toks:|if False:' \
         'if MASTER not in toks:|if False:' \
         'if not why and p.is_file():|if True:' \
         'TICK = re.compile(r"`([^`]+)`")|TICK = re.compile(r"`?([^`\s]+)`?")' \
         '    ("Profile.md 의 칸", "profile.md"),|' \
         '        check_profile(r, root)|' \
         'if not os.path.lexists(root / PROFILE):|if False:' \
         'if why or not prof.is_file():|if False:' \
         'IMPORTERS = ("CLAUDE.md", "CLAUDE.local.md")|IMPORTERS = ("CLAUDE.md",)' \
         'IMPORT.search(QUOTE.sub("\0", SPAN.sub("\0", p)))|IMPORT.search(QUOTE.sub("\0", p))' \
         'SPAN = re.compile(r"(?<!`)(`+)(?!`).*?(?<!`)\1(?!`)", re.S)|SPAN = re.compile(r"`[^`]+`")' \
         'return any(IMPORT.search(QUOTE.sub("\0", SPAN.sub("\0", p))) for p in paras)|return any("@Profile.md" in QUOTE.sub("\0", SPAN.sub("\0", p)) for p in paras)' \
         'QUOTE.sub("\0", SPAN.sub("\0", p))|SPAN.sub("\0", p)' \
         ' for p in paras)| for p in ls)' \
         'if ln.strip():|if True:' \
         'if inside(root, name)[1] or not f.is_file():|if not f.is_file():' \
         'lines(prof)  # 읽지 못하면 [R1] — 줄의 뜻은 보지 않는다|pass' \
         'unread = True|unread = False' \
         'm = FENCE.match(ln)|m = re.match(r"^(```)(.*)$", ln)' \
         'if m and not (m.group(1)[0] == "`" and "`" in m.group(2)):|if m:' \
         'm.group(1)[0] == fence[0] and |' \
         'len(m.group(1)) >= len(fence) and |' \
         ' and not m.group(2).strip():|:'; do
  python3 - "${m%%|*}" "${m##*|}" "$dv/m${#dnames[@]}.py" <<'PY'
import pathlib, sys
s = pathlib.Path("scripts/verify-docs.py").read_text(encoding="utf-8")
a, b, out = sys.argv[1:]
if s.count(a) != 1:
    sys.exit(f"변조할 자리 {a!r} 가 문서 대조 검사에 {s.count(a)} 번 있다 — 이 단계를 검사에 맞춰 고쳐라")
pathlib.Path(out).write_text(s.replace(a, b), encoding="utf-8")
PY
  dnames+=("${m%%|*}")
done
dk=$((${#dnames[@]} - 1))
djobs=$(nproc)
drun() {  # $@=변조본 번호 — 자체 시험을 --first 로 djobs 개씩 함께. 결과는 $dv/m<번호>.rc · .out
  printf '%s\n' "$@" | xargs -P "$djobs" -I{} sh -c \
    'python3 scripts/test-verify-docs.py --first "$1/m$2.py" >"$1/m$2.out" 2>&1; echo $? >"$1/m$2.rc"' _ "$dv" {}
  for i in "$@"; do
    if [ ! -s "$dv/m$i.rc" ]; then echo "::error::test-verify-docs.py 를 '${dnames[$i]}' 에 돌린 결과가 없다"; exit 1; fi
  done
}
# 물었다 = 자체 시험이 종료 1 로 끝나고 `FAIL — ` 줄을 찍었다. 함께 돌다 자원으로 죽은 실행(137 따위)을 「물었다」로 세지 않는다
# (조각 36 닫기 전 감사 회차 OB-4 · 설계 끝 「닫기 전 감사 회차에서 찾은 것」).
dbit() { [ "$(cat "$dv/m$1.rc")" = 1 ] && grep -q '^FAIL — ' "$dv/m$1.out" && ! crash "$dv/m$1.out"; }
printf '137\n' > "$dv/mx.rc"; : > "$dv/mx.out"
if dbit x; then echo "::error::자원으로 죽은 실행(종료 137 · 출력 없음)을 「물었다」로 센다"; exit 1; fi
printf '1\n' > "$dv/mx.rc"; printf 'Traceback (most recent call last):\n' > "$dv/mx.out"
if dbit x; then echo "::error::FAIL 줄 없이 1 로 끝난 실행을 「물었다」로 센다"; exit 1; fi
printf '1\n' > "$dv/mx.rc"; printf 'FAIL — x\nTraceback (most recent call last):\n' > "$dv/mx.out"
if dbit x; then echo "::error::FAIL 줄과 함께 트레이스백을 찍은 실행을 「물었다」로 센다"; exit 1; fi
drun 0
if [ "$(cat "$dv/m0.rc")" != 0 ] || ! grep -q '^PASS 문서 대조 검사가 문다' "$dv/m0.out" || crash "$dv/m0.out"; then
  echo "::error::test-verify-docs.py --first 가 바꾸지 않은 문서 대조 검사(대조군)를 지나가게 하지 않았다 — 깃발이나 함께 돌리는 길이 망가졌다"
  tail -5 "$dv/m0.out"; exit 1
fi
SK=$((SK + 1))
drun $(seq 1 "$dk")
dmiss=0
for i in $(seq 1 "$dk"); do
  if dbit "$i"; then
    SB=$((SB + 1))
  else
    echo "::error::test-verify-docs.py 가 '${dnames[$i]}' 를 망가뜨린 문서 대조 검사를 통과시켰다"; dmiss=1
  fi
done
[ "$dmiss" = 0 ] || exit 1
sclose 45 1
echo "test-verify-docs.py: 대조군 $SK 은 지나가고 변조본 $SB 이 다 떨어짐(--first · 동시 $djobs · 종료 1 과 FAIL 줄, 트레이스백 없음만 물었다로 센다)"

# run-evals.sh — 결정론 그레이더가 모든 회차에서 떨어지면 점수가 문턱을 넘어도
# 실패해야 한다(종료코드 5). 한 회차만 떨어진 것은 흔들림이라 통과해야 한다.
# 매번 떨어진 쪽은 회차가 점수로는 통과여도 트레이스 셋이 남아야 한다 — 실패
# 산출물에 증거가 없으면 못 연다. 가짜 하네스가 --json 자리에 결과를 쓴다
# — 모델은 안 부른다. run-evals.sh 의 PASS 줄은 「결과: 」 줄이다(실패해도 찍지만 대조군은 종료 0 과 함께 본다).
sopen "run-evals.sh(결정론 그레이더)"
RVOK='^결과: '
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
done
bit 5 "$RVF" "매번 떨어진 결정론 그레이더" env FAKE_RESULT="$f/r3.json" PATH="$f:$PATH" ./scripts/run-evals.sh --case gate-out-of-scope --ablation none
if [ "$(grep -c '실패 기록 남김' "$BO")" != 3 ]; then
  echo "::error::run-evals.sh 가 매번 떨어진 회차의 트레이스를 안 남겼다"; cat "$BO"; exit 1
fi
keep "$RVOK" "한 회차만 떨어진 흔들림" env FAKE_RESULT="$f/r1.json" PATH="$f:$PATH" ./scripts/run-evals.sh --case gate-out-of-scope --ablation none
# 케이스 머리의 graders 가 빈 결과도 매번 떨어진 그레이더를 잡아야 한다 — 종류는 디스크에서
python3 -c "
import json, sys
d = json.load(open('$f/r3.json')); d['cases'][0]['graders'] = []
json.dump(d, open('$f/r3e.json', 'w'))"
bit 5 "$RVF" "케이스 머리 없는 결과의 매번 떨어진 그레이더" env FAKE_RESULT="$f/r3e.json" PATH="$f:$PATH" ./scripts/run-evals.sh --case gate-out-of-scope --ablation none
sclose 2 1

# run-evals.sh --eval-dir recall — 회수율은 재기만 한다(조각 39 설계 ② N · 끝 「PR D 에서 정한 것」). 진짜 하네스처럼
# --threshold 가 없으면 1.0 을 쓰고 문턱 아래면 종료 1 인 가짜 하네스에서, recall-found 가 세 회차 다 떨어진 결과는
# 종료 0 · 「회수율 0/3」이어야 하고, auditor-fired 가 한 회차라도 떨어지면 종료 5, 부른 쪽의 --threshold 는 종료 2 다.
sopen "run-evals.sh --eval-dir recall"
h=$(mktemp -d)
printf '%s\n' '#!/usr/bin/env bash' \
  'thr=1.0' \
  'while [ $# -gt 0 ]; do case "$1" in --json) cp "$FAKE_RESULT" "$2";; --threshold) thr=$2;; esac; shift; done' \
  'python3 -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(1 if any(c[\"aggregates\"][\"score\"] < float(sys.argv[2]) for c in d[\"cases\"]) else 0)" "$FAKE_RESULT" "$thr"' > "$h/claude"
chmod +x "$h/claude"
for fired in all one; do
  python3 - "$h/r-$fired.json" "$fired" "$h/tr-$fired" <<'PY'
import json, os, pathlib, sys
out, fired, tr = sys.argv[1], sys.argv[2], pathlib.Path(sys.argv[3])
runs = []
for i in range(3):
    (tr / f"r{i}").mkdir(parents=True, exist_ok=True)
    (tr / f"r{i}" / "trace.jsonl").write_text('{"type":"result","result":"ok","modelUsage":{"%s":{}}}\n' % os.environ["BITE_MODEL"])
    up = not (fired == "one" and i == 0)
    runs.append({"score": 0.0, "passed": False, "tracePath": str(tr / f"r{i}" / "trace.jsonl"),
                 "graders": [{"name": "recall-found", "weight": 1, "scored": True, "passed": False},
                             {"name": "auditor-fired", "weight": 1, "scored": False, "passed": up}]})
json.dump({"cases": [{"name": "recall-commit-after-response", "arms": {"with": runs},
                      "graders": [{"name": "recall-found", "type": "regex", "weight": 1},
                                  {"name": "auditor-fired", "type": "tool_used", "weight": 1}],
                      "aggregates": {"score": 0.0}}]}, open(out, "w"))
PY
done
keep '^회수율 0/3$' "놓친 세 회차(문턱 1.0 하네스)" env FAKE_RESULT="$h/r-all.json" PATH="$h:$PATH" ./scripts/run-evals.sh --eval-dir recall --case recall-commit-after-response --ablation none
bit 5 "$RVF" "감사자가 안 뜬 회차" env FAKE_RESULT="$h/r-one.json" PATH="$h:$PATH" ./scripts/run-evals.sh --eval-dir recall --case recall-commit-after-response --ablation none
# 거절을 재는 꼴이라 종료 2 와 그 거절 줄을 본다
bit 2 '문턱을 받지 않는다' "부른 쪽의 --threshold" env FAKE_RESULT="$h/r-all.json" PATH="$h:$PATH" ./scripts/run-evals.sh --eval-dir recall --case recall-commit-after-response --threshold 0.5
sclose 2 1
echo "run-evals.sh --eval-dir recall: 문턱이 기본값인 하네스에서 다 놓친 회차가 종료 0 과 회수율 줄(대조군 $SK), 감사자가 안 뜬 회차는 종료 5, --threshold 는 종료 2(변조본 $SB)"

# run-evals.sh — 감사자가 한 회차라도 안 떴으면 실패해야 한다. 두 팔로 돌면
# auditor-fired 는 with-only 라 점수에서 빠지므로(scored: false) 흉내 낸 답이
# 만점을 받아도 지나갔다. 그 모양(점수 1.0 · auditor-fired 만 한 회차 실패)을 준다.
sopen "run-evals.sh(auditor-fired)"
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
bit 5 "$RVF" "감사자가 안 뜬 두 팔 회차" env FAKE_RESULT="$f/ra.json" PATH="$f:$PATH" ./scripts/run-evals.sh --case trap-liveness-probe
sclose 1 0

# verify-evals.py — 실행 비트가 빠진 픽스처는 실패해야 한다
sopen "verify-evals.py(실행 비트)"
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
chmod 644 "$s/vibe-audit/evals/route-quiet/fixture.sh"
bit 1 "$PYF" "실행 비트 없는 픽스처" python3 scripts/verify-evals.py "$s/vibe-audit/evals"
sclose 1 0

# run-evals.sh — 고른 케이스 가운데 하나가 결과에서 빠지면 실패해야 한다(종료코드 3).
# 회차가 다 있어도 디스크에 적힌 그레이더가 채점되지 않았으면 같다(graders: []).
# 사용량 한도에 걸린 회차는 회귀가 아니라 한도로 따로 끝나야 한다(종료코드 6).
# 기대한 종료가 0 이면 대조군(종료 0 · 「결과: 」 줄), 아니면 변조본(그 종료 · FAIL 줄)이다.
sopen "run-evals.sh(구조 · 한도 · 모델 · 두 팔)"
rv() {  # $1=기대한 종료 $2=이름 $3…=run-evals.sh 인자 — 가짜 하네스 $f 로, 결과는 $FR
  local want=$1 name=$2; shift 2
  if [ "$want" = 0 ]; then keep "$RVOK" "$name" env FAKE_RESULT="$FR" PATH="$f:$PATH" ./scripts/run-evals.sh "$@"
  else bit "$want" "$RVF" "$name" env FAKE_RESULT="$FR" PATH="$f:$PATH" ./scripts/run-evals.sh "$@"; fi
}
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
  FR="$f/${m%%:*}.json" rv "${m##*:}" "${m%%:*} 결과" --case 'route-*' --runs 3 --ablation none
done
# 구조 실패(3)로 끝나도 트레이스는 결과 폴더에 남아야 한다 — 그레이더가 왜 빠졌는지 볼 증거다
FR="$f/empty.json" rv 3 "구조 실패의 트레이스" --case 'route-*' --runs 3 --ablation none
r=$(sed -n 's/^결과: //p' "$BO" | tail -1)
if [ -z "$r" ] || ! ls "$r"/traces/*.jsonl >/dev/null 2>&1; then
  echo "::error::run-evals.sh 가 구조 실패에서 트레이스를 안 남겼다 (${r:-결과 폴더 없음})"; exit 1
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
FR="$json_one" rv 3 "--runs 없이 한 회차만 돈 결과" --case route-quiet --ablation none
# 트레이스에 요청한 모델(수트 모델)이 안 보이면 무엇을 쟀는지 모른다(→ 3)
printf '%s\n' '{"type":"result","result":"ok","modelUsage":{"claude-haiku-4-5":{}}}' > "$f/haiku.jsonl"
python3 -c "
import json
d = json.load(open('$f/allok.json'))
for c in d['cases']:
    for r in c['arms']['with']:
        r['tracePath'] = '$f/haiku.jsonl'
json.dump(d, open('$f/othermodel.json', 'w'))"
FR="$f/othermodel.json" rv 3 "요청한 모델이 안 보이는 회차" --case 'route-*' --runs 3 --ablation none
# 이름이 겹치는 딴 모델은 같은 모델이 아니다 — $near 를 요청했는데
# 수트 모델($model)로 돈 회차(→ 3). 부분 문자열로 견주던 러너는 이것을 받았다.
# 거꾸로 날짜가 붙은 같은 모델(claude-haiku-4-5-20251001)은 받아야 한다(→ 0).
FR="$f/allok.json" rv 3 "$near 를 요청했는데 $model 로 돈 회차" --case 'route-*' --runs 3 --ablation none --model "$near"
printf '%s\n' '{"type":"result","result":"ok","modelUsage":{"claude-haiku-4-5-20251001":{}}}' > "$f/dated.jsonl"
python3 -c "
import json
d = json.load(open('$f/allok.json'))
for c in d['cases']:
    for r in c['arms']['with']:
        r['tracePath'] = '$f/dated.jsonl'
json.dump(d, open('$f/dated.json', 'w'))"
FR="$f/dated.json" rv 0 "날짜가 붙은 같은 모델(claude-haiku-4-5-20251001)" --case 'route-*' --runs 3 --ablation none --model claude-haiku-4-5
# 회차가 다 채점됐어도 트레이스가 없으면 무효다 — 모델 · 한도를 볼 수 없다(→ 3)
python3 -c "
import json
d = json.load(open('$f/allok.json'))
for c in d['cases']:
    for r in c['arms']['with']:
        r['tracePath'] = None
json.dump(d, open('$f/notrace.json', 'w'))"
FR="$f/notrace.json" rv 3 "트레이스 없는 회차" --case 'route-*' --runs 3 --ablation none
# --ablation 을 안 주면 두 팔이다. without 팔이 없거나(한 팔 실험으로 바뀐 것) 채점되지
# 않았으면 3, 두 팔이 다 채점됐으면 0
for m in allok:3 woempty:3 wook:0; do
  FR="$f/${m%%:*}.json" rv "${m##*:}" "두 팔 ${m%%:*} 결과" --case 'route-*' --runs 3
done
sclose 13 4

# verify-evals.py — 매번 떨어져도 문턱을 못 넘기는 가벼운 심판 그레이더는 실패해야 한다
sopen "verify-evals.py · verify-graders.py(무게 · arm · 대조군)"
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
sed -i 's/^weight: .*/weight: 2/' "$s/vibe-audit/evals/gap-unowned/graders/gate-no-fake-owner.md"
bit 1 "$PYF" "문턱을 못 넘기는 심판 그레이더" python3 scripts/verify-evals.py "$s/vibe-audit/evals"

# verify-evals.py — auditor-fired 가 호출을 요구하지 않으면(min 0) 실패해야 한다(Codex 33차)
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
sed -i 's/^min: .*/min: 0/' "$s/vibe-audit/evals/cycle-first/graders/auditor-fired.md"
bit 1 "$PYF" "min 0 인 auditor-fired" python3 scripts/verify-evals.py "$s/vibe-audit/evals"

# verify-evals.py — 채점 그레이더에 arm 을 붙이면(점수에서 빠짐) 실패해야 한다
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
sed -i '0,/^weight/s//arm: with-only\nweight/' "$s/vibe-audit/evals/route-unasked-data/graders/route-correct.md"
bit 1 "$PYF" "arm 붙은 route-correct" python3 scripts/verify-evals.py "$s/vibe-audit/evals"

# verify-evals.py — 떨어져도 문턱을 못 넘기는 가벼운 음성 그레이더는 실패해야 한다
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
sed -i 's/^weight: .*/weight: 1/' "$s/vibe-audit/evals/route-unasked-data/graders/route-not-secrets.md"
bit 1 "$PYF" "문턱 아래로 못 끌어내리는 음성 그레이더" python3 scripts/verify-evals.py "$s/vibe-audit/evals"

# verify-graders.py — 무엇에나 맞는 대조군은 실패해야 한다(무는 fail 표본이 있어야)
g=$(mktemp -d); cp -r vibe-audit "$g/"; rm -rf "$g/vibe-audit/evals/results"
sed -i 's/^pattern: .*/pattern: "."/' "$g/vibe-audit/evals/trap-local-dev-password/graders/real-nc-found.md"
bit 1 "$PYF" "무엇에나 맞는 대조군" python3 scripts/verify-graders.py "$g/vibe-audit/evals"
sclose 5 0

# verify-copy.py — 원본 여섯 가운데 하나만 공통 절이 갈리면 실패해야 한다
sopen "verify-copy.py(공통 절 · tools · 출력 형식)"
# (gates.sh 는 원본을 원본과 견주므로 파일마다 자기 자신과 같다)
t=$(mktemp -d); cp vibe-audit/agents/*.md "$t/"
sed -i '/^## 판정은 넷이다$/{n;s/$/ 갈림/}' "$t/audit-secrets.md"
bit 1 "$PYF" "원본끼리 갈린 공통 절" python3 scripts/verify-copy.py "$t" "$t"

# verify-copy.py — 머리말에 Edit 를 넣고 본문에 원형 tools 줄을 적어 두면 실패해야 한다
t=$(mktemp -d); cp vibe-audit/agents/*.md "$t/"
sed -i 's/^tools: .*/tools: ["Read", "Grep", "Glob", "Edit"]/' "$t/audit-ops.md"
printf '\n예시:\ntools: ["Read", "Grep", "Glob"]\n' >> "$t/audit-ops.md"
bit 1 "$PYF" "본문의 원형 줄에 속아 쓰기 도구" python3 scripts/verify-copy.py "$t"

# verify-copy.py — 출력 형식에서 `## 지난 회차` 를 빼고 파일 끝에 딴 절로 붙인 사본은 실패해야 한다
t=$(mktemp -d); cp vibe-audit/agents/*.md "$t/"
python3 - "$t/audit-secrets.md" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text()
j = t.find("## 지난 회차\n", t.find("## 출력 형식"))
p.write_text(t[:j] + t[j + len("## 지난 회차\n"):] + "\n## 지난 회차\n\n딴 절\n")
PY
bit 1 "$PYF" "출력 형식 밖의 「지난 회차」에 속았다" python3 scripts/verify-copy.py vibe-audit/agents "$t"

# verify-copy.py — 출력 형식의 `## 안 본 것` 머리만 지우고 자리표시를 남긴 사본은 실패해야 한다
t=$(mktemp -d); cp vibe-audit/agents/*.md "$t/"
python3 - "$t/audit-secrets.md" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text()
j = t.find("## 안 본 것\n", t.find("## 출력 형식"))
p.write_text(t[:j] + t[j + len("## 안 본 것\n"):])
PY
bit 1 "$PYF" "출력 형식의 「안 본 것」 머리가 빠진 사본" python3 scripts/verify-copy.py vibe-audit/agents "$t"
sclose 4 0

# verify-evals.py — route-not-others 가 없거나 허용 선언과 어긋나면 실패해야 한다
sopen "verify-evals.py · verify-manifest.py(선언)"
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
rm "$s/vibe-audit/evals/route-unasked-secret/graders/route-not-others.md"
bit 1 "$PYF" "route-not-others 없는 route 케이스" python3 scripts/verify-evals.py "$s/vibe-audit/evals"
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
sed -i 's/^같이 떠도 되는 감사자: .*/같이 떠도 되는 감사자: 없음/' \
  "$s/vibe-audit/evals/route-unasked-secret/graders/route-not-others.md"
bit 1 "$PYF" "허용 선언과 어긋난 route-not-others" python3 scripts/verify-evals.py "$s/vibe-audit/evals"

# verify-evals.py — scaffold_script 선언이 빠진 케이스는 실패해야 한다
s=$(mktemp -d); cp -r vibe-audit "$s/"; rm -rf "$s/vibe-audit/evals/results"
sed -i '/scaffold_script/d' "$s/vibe-audit/evals/route-quiet/case.yaml"
bit 1 "$PYF" "스캐폴드 없는 케이스" python3 scripts/verify-evals.py "$s/vibe-audit/evals"

# verify-manifest.py — 검사가 모르는 라이선스 선언은 실패해야 한다
m=$(mktemp -d); tar -c --exclude=.git --exclude=results . | tar -x -C "$m"
sed -i 's/"license": "MIT"/"license": "GPL-3.0"/' "$m/vibe-audit/.claude-plugin/plugin.json"
bit 1 "$PYF" "견줄 수 없는 라이선스 선언" python3 "$m/scripts/verify-manifest.py"
sclose 4 0

echo "검사의 변조본 절 $NSEC 이 센 수 · 실패 줄 · 대조군의 PASS 줄로 닫힘 — manifest · copies · copy · evals · graders · budget · feedback · sync-agents · run-evals 와 자체 시험 compare-copies · verify-feedback · verify-docs(brief 는 test-verify-brief.py 가, docs 는 bite-verify-docs.py 가 스스로 변조본을 돈다)"

# eval-key.py — 수트가 안 읽는 것은 지문을 그대로 두고, 읽는 것은 바꿔야 한다.
# 앞쪽이 깨지면 낭비로 끝나지만 뒤쪽이 깨지면 **문구를 고친 PR 이 수트 없이
# 지나간다.** 제자리에서 흔들고 그 파일만 흔들기 전의 백업에서 되돌린다 — 커밋
# 안 한 수정도 남는다. 지문이 바뀌어야 하는 쪽을 변조본으로, 그대로여야 하는 쪽을 대조군으로 센다.
sopen "eval-key.py(수트 지문)"
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
  if [ "$1" = same ]; then SK=$((SK + 1)); else SB=$((SB + 1)); fi
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
SB=$((SB + 1))
# 회수율 케이스는 두 모드 다 밖이다(조각 39 설계 ② K · ⑤ R4) — 전수가 돌리지 않으므로 full 도 그대로여야 한다.
kf0=$(python3 scripts/eval-key.py full)
keyed same vibe-audit/recall/recall-commit-after-response/fixture.sh 'echo "# x" >> vibe-audit/recall/recall-commit-after-response/fixture.sh'
hold vibe-audit/recall/recall-commit-after-response/fixture.sh
echo "# x" >> vibe-audit/recall/recall-commit-after-response/fixture.sh
kf=$(python3 scripts/eval-key.py full); undo vibe-audit/recall/recall-commit-after-response/fixture.sh
if [ "$kf" != "$kf0" ]; then
  echo "::error::eval-key.py 가 회수율 케이스로 전수 지문을 바꿨다 — 전수는 그것을 돌리지 않는다"; exit 1
fi
SK=$((SK + 1))
sclose 7 6
echo "수트 지문: 무관한 것 $SK(회수율 케이스는 route · full 모두)은 그대로, 관련된 것과 모드 $SB(실행 비트 포함)은 바뀐다"

# 변조본 파일이 수트 지문 밖인가(ADR 0020 의 6). eval-key.py 는 run-evals.sh 에 적힌 스크립트를 지문에 넣는다 —
# 러너가 이 이름들을 적게 되면(주석이라도) 변조본을 고칠 때마다 수트가 다시 돈다. 판정은 안 틀리고 비용만
# 돌아와 아무도 모르므로 여기서 문다. 목록은 stderr 로 나온다 — 러너가 목록에 없으면 목록을 못 읽은 것이다.
sopen "eval-key.py(변조본 파일이 지문 밖)"
for mode in route full; do
  list=$(python3 scripts/eval-key.py "$mode" --list 2>&1 >/dev/null)
  hit=$(grep -E ' scripts/(gates\.sh|bite-gates\.sh|bite-[^/]*\.py)$' <<<"$list" || true)
  if [ -n "$hit" ] || ! grep -q ' scripts/run-evals\.sh$' <<<"$list"; then
    echo "::error::변조본 파일이 수트 지문($mode)에 들었거나 지문 목록을 못 읽었다 — 고칠 때마다 수트가 다시 돈다"; printf '%s\n' "${hit:-$list}"; exit 1
  fi
  SK=$((SK + 1))
done
sclose 0 2
echo "변조본 파일: gates.sh · bite-gates.sh · bite-*.py 가 수트 지문(route · full) 밖이다"

# gate-key.py — 변조 시험의 지문(조각 35 설계 ② K1 ~ K6 · ⑤ R1 · R2). 검사가 대조하는 문서와 기록(③ S1 ~ S12)은 지문을
# 그대로 두고, 그 밖(S13 ~ S19)은 바꿔야 한다. 앞쪽이 깨지면 변조 시험이 괜히 돌 뿐이지만 뒤쪽이 깨지면 **검사를 고친 PR 이
# 변조 시험 없이 초록으로 지나간다.** 수트 지문의 keyed 와 같은 모양 — 제자리에서 흔들고 그 파일만 백업에서 되돌린다.
sopen "gate-key.py(변조 시험 지문)"
gst0=$(git status --porcelain)
g0=$(python3 scripts/gate-key.py)
gpy=$(python3 --version | sed -nE 's/^Python ([0-9][A-Za-z0-9_.+-]*)$/\1/p')
ggit=$(git --version | sed -nE 's/^git version ([0-9][A-Za-z0-9_.+-]*)( \(.*\))?$/\1/p')
if [ -z "$gpy" ] || [ -z "$ggit" ] || [[ "$g0" != "gate-bite-py$gpy-git$ggit-"* ]] || ! [[ "${g0#"gate-bite-py$gpy-git$ggit-"}" =~ ^[0-9a-f]{24}$ ]]; then
  echo "::error::gate-key.py 의 지문이 gate-bite-py<파이썬 판>-git<git 판>-<24 자리> 가 아니다 — '$g0' (python3 $gpy · git $ggit)"; exit 1
fi
gkeyed() {  # $1=same|diff  $2=파일  $3=흔드는 명령
  hold "$2"
  eval "$3"
  k=$(python3 scripts/gate-key.py); undo "$2"
  if [ "$1" = same ] && [ "$k" != "$g0" ]; then
    echo "::error::gate-key.py 가 검사가 대조하는 기록 $2 로 지문을 바꿨다 — 변조 시험이 괜히 돈다"; exit 1
  fi
  if [ "$1" = diff ] && [ "$k" = "$g0" ]; then
    echo "::error::gate-key.py 가 $2 를 바꿔도 지문이 그대로다 — 변조 시험 없이 지나간다"; exit 1
  fi
  if [ "$1" = same ]; then SK=$((SK + 1)); else SB=$((SB + 1)); fi
}
# 빼는 쪽 — S1 ~ S11 마다 하나. S12(docs/audit/)는 아래 사본에서 본다
gkeyed same "$(git ls-files docs/slices/ | head -1)"    'echo x >> "$2"'
gkeyed same "$(git ls-files docs/adr/ | head -1)"       'echo x >> "$2"'
gkeyed same "$(git ls-files docs/eval-log/ | head -1)"  'echo x >> "$2"'
gkeyed same docs/master-plan.md                         'echo x >> "$2"'
gkeyed same docs/architecture.md                        'echo x >> "$2"'
gkeyed same docs/schema.md                              'echo x >> "$2"'
gkeyed same INTENT.md                                   'echo x >> "$2"'
gkeyed same CLAUDE.md                                   'echo x >> "$2"'
gkeyed same AGENTS.md                                   'echo x >> "$2"'
gkeyed same CHECKLIST.md                                'echo x >> "$2"'
gkeyed same vibe-audit/evals/README.md                  'echo x >> "$2"'
# 넣는 쪽 — S13 ~ S19 마다 하나, 그리고 실행 비트 · 지운 파일
gkeyed diff scripts/verify-graders.py                   "echo '#' >> \"\$2\""
gkeyed diff vibe-slice/skills/slice-docs/SKILL.md       'echo x >> "$2"'
gkeyed diff vibe-audit/evals/route-quiet/prompt.md      'echo x >> "$2"'
gkeyed diff vibe-audit/agents/audit-data.md             'echo x >> "$2"'
gkeyed diff docs/procedure.md                           'echo x >> "$2"'
gkeyed diff feedback.json                               'echo x >> "$2"'
gkeyed diff .gitignore                                  'echo x >> "$2"'
gkeyed diff scripts/gates.sh                            'chmod -x "$2"'
gkeyed diff scripts/verify-budget.py                    'rm "$2"'
# S12 는 지금 git 이 아는 파일이 없다 — 사본 저장소에 새 파일로 더해 본다. 같은 자리에서 새 파일이 넣는 쪽이면 저절로
# 지문에 드는지도 본다(K2). 커밋 안 한 gate-key.py 도 보도록 작업트리의 것을 베껴 쓴다.
gc=$(mktemp -d); git clone -q "$R" "$gc/r"; cp -p scripts/gate-key.py "$gc/r/scripts/gate-key.py"
gb=$(python3 "$gc/r/scripts/gate-key.py")
mkdir -p "$gc/r/docs/audit"; echo x > "$gc/r/docs/audit/bite.md"; git -C "$gc/r" add docs/audit/bite.md
if [ "$(python3 "$gc/r/scripts/gate-key.py")" != "$gb" ]; then
  echo "::error::gate-key.py 가 docs/audit/ 의 새 기록으로 지문을 바꿨다"; exit 1
fi
SK=$((SK + 1))
echo x > "$gc/r/scripts/bite-new.py"; git -C "$gc/r" add scripts/bite-new.py
if [ "$(python3 "$gc/r/scripts/gate-key.py")" = "$gb" ]; then
  echo "::error::gate-key.py 가 넣는 쪽의 새 파일(scripts/bite-new.py)을 지문에 넣지 않았다"; exit 1
fi
SB=$((SB + 1))
# 경로에 \r 이 든 파일도 그 내용으로 센다 — 글로 읽어 \r 이 \n 으로 바뀌면 「없음」으로 세어 내용이 바뀌어도 그대로였다(Codex 리뷰)
gcr="$gc/r/scripts/bite-cr"$'\r'".py"; echo 'print(1)' > "$gcr"; git -C "$gc/r" add -A scripts
gb=$(python3 "$gc/r/scripts/gate-key.py"); echo 'print(2)' > "$gcr"
if [ "$(python3 "$gc/r/scripts/gate-key.py")" = "$gb" ]; then
  echo "::error::gate-key.py 가 경로에 \\r 이 든 파일의 내용을 바꿔도 지문이 그대로다"; exit 1
fi
SB=$((SB + 1))
# 판 — 같은 트리라도 파이썬 · git 판이 바뀌면 지문이 바뀐다. 판을 못 읽는 꼴이면 지문 없이 종료 1, 모르는 인자는 종료 2(K1 · K4)
# 진짜 해석기는 sys.executable 로 찾는다 — pyenv 의 shim 은 PATH 앞에 제 판을 다시 얹어 가짜 python3 를 가린다(Codex 리뷰).
gv=$(mktemp -d); gpy3=$(python3 -c 'import sys; print(sys.executable)'); ggit3=$(command -v git)
mkdir -p "$gv/py" "$gv/git" "$gv/bad"
printf '#!/bin/sh\necho "Python 0.0.1"\n' > "$gv/py/python3"
printf '#!/bin/sh\nif [ "$1" = --version ]; then echo "git version 0.0.1"; else exec "%s" "$@"; fi\n' "$ggit3" > "$gv/git/git"
printf '#!/bin/sh\necho "뜻밖의 판"\n' > "$gv/bad/python3"
chmod +x "$gv/py/python3" "$gv/git/git" "$gv/bad/python3"
for w in py git; do
  k=$(PATH="$gv/$w:$PATH" "$gpy3" scripts/gate-key.py)
  case "$k" in
    *"$w"0.0.1-*) ;;
    *) echo "::error::gate-key.py 의 지문에 $w 판이 안 들었다 — '$k'"; exit 1 ;;
  esac
  if [ "${k##*-}" != "${g0##*-}" ] || [ "$k" = "$g0" ]; then
    echo "::error::gate-key.py 가 $w 판만 바꾼 지문을 '$g0' 와 가르지 못했다 — '$k'"; exit 1
  fi
  SB=$((SB + 1))
done
# 지문 없이(표준 출력이 비고) 그 종료와 그 까닭 줄 — 판을 못 읽으면 「지문을 내지 않는다」, 모르는 인자면 사용법(거절을 재는 꼴)
gnokey() {  # $1=기대한 종료 $2=까닭 줄(grep -E) $3=이름 $4…=명령
  local want=$1 re=$2 name=$3; shift 3
  set +e; k=$("$@" 2>"$BO"); st=$?; set -e
  if [ "$st" != "$want" ] || [ -n "$k" ] || ! grep -qE -- "$re" "$BO" || crash; then
    echo "::error::gate-key.py 가 $name 에 지문을 냈거나 종료 $want · 까닭 줄 /$re/ 이 아니다 (exit $st, '$k')"; cat "$BO"; exit 1
  fi
  SB=$((SB + 1))
}
gnokey 1 '지문을 내지 않는다' "뜻밖의 python3 --version" env PATH="$gv/bad:$PATH" "$gpy3" scripts/gate-key.py
gnokey 2 '^사용법: gate-key.py' "모르는 인자" python3 scripts/gate-key.py --nope
if [ "$(git status --porcelain)" != "$gst0" ]; then
  echo "::error::지문 시험이 작업트리를 흔든 채로 남겼다"; git status --porcelain; exit 1
fi
sclose 15 12
echo "변조 시험 지문: 대조하는 기록 $SK 은 그대로, 넣는 쪽 · 실행 비트 · 지운 파일 · 새 파일 · \\r 이 든 경로 · 파이썬과 git 의 판 · 지문 없는 종료의 $SB 은 바뀌거나 지문을 내지 않는다"

# gates.sh — 건너뛰는 묶음(bites)에 변조 시험 다섯만 있고 그 밖에는 없다(조각 35 설계 ② G4 · G5 의 가 · ⑤ R4). 건너뛰는
# 실행이 변조 시험 아닌 검사까지 빼면 「스물셋 통과」가 거짓이 된다. 묶음 시험의 실패 줄은 까닭(「bites」를 든다), PASS 줄은 「PASS bites 묶음」.
sopen "gates.sh 의 bites 묶음"
bunch() {  # $1=gates.sh — 모양이 맞으면 PASS 줄과 0, 아니면 까닭을 찍고 1
  python3 - "$1" <<'PY'
import pathlib, re, sys
ls = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8").split("\n")
FIVE = ("scripts/bite-verify-docs.py", "scripts/bite-slice-gate.py", "scripts/bite-map-pin.py",
        "scripts/bite-eval-merged-pass.py", "scripts/bite-gates.sh")
CALL = re.compile(r"(?:python3 scripts/bite-[\w.-]+\.py|\./scripts/bite-[\w.-]+\.sh)")
if ls.count("bites() {") != 1 or "}" not in ls[ls.index("bites() {"):]:
    sys.exit("bites() { … } 묶음이 하나가 아니다")
a = ls.index("bites() {"); b = ls.index("}", a)
cmds = lambda part: [l.strip() for l in part if l.strip() and not l.strip().startswith("#")]
inside, outside = cmds(ls[a + 1:b]), cmds(ls[:a] + ls[b + 1:])
bad = [l for l in inside if not CALL.fullmatch(l)]
if bad:
    sys.exit(f"bites 묶음에 변조 시험이 아닌 명령이 있다: {bad}")
for f in FIVE:
    if sum(f in l for l in inside) != 1:
        sys.exit(f"{f} 가 bites 묶음에 한 번이 아니다")
    if any(f in l for l in outside):
        sys.exit(f"{f} 가 bites 묶음 밖에서 불린다")
print("PASS bites 묶음 — 변조 시험 다섯만 든다")
PY
}
keep '^PASS bites 묶음' "진짜 gates.sh" bunch scripts/gates.sh
gm=$(mktemp -d)
for mv in 'python3 scripts/verify-docs.py|bites' './scripts/bite-gates.sh|checks'; do
  python3 - "${mv%%|*}" "${mv##*|}" scripts/gates.sh "$gm/gates.sh" <<'PY'
import pathlib, sys
line, to, src, out = sys.argv[1:]
ls = pathlib.Path(src).read_text(encoding="utf-8").split("\n")
if ls.count("  " + line) != 1:
    sys.exit(f"옮길 줄 {line!r} 이 gates.sh 에 한 번이 아니다 — 이 변조본을 gates.sh 에 맞춰 고쳐라")
ls.remove("  " + line)
ls.insert(ls.index(f"{to}() {{") + 1, "  " + line)
pathlib.Path(out).write_text("\n".join(ls), encoding="utf-8")
PY
  bit 1 'bites 묶음' "'${mv%%|*}' 를 ${mv##*|} 로 옮긴 gates.sh" bunch "$gm/gates.sh"
done
sclose 2 1
gbn=$SB  # 이 절의 끝 줄은 다음 절 뒤에 함께 찍는다 — 견준 수를 받아 둔다

# gates.sh 의 인자 — 거절하는 꼴은 아무 검사도 돌리기 전에 종료 2(조각 35 설계 ② G3 · G5 의 나 · ③ A3 ~ A5 · ⑤ R3). 첫
# 검사가 claude 라 가짜 claude 를 앞에 둔다 — 거절하지 않고 검사로 들어가면 PASS 를 찍고 97 로 끝나 바로 드러나고, 변조
# 시험까지 가서 이 파일을 다시 부르는 일이 없다. 받는 꼴(A2)도 하나 — 근거를 찍고 첫 검사에 닿는다. 거절의 실패 줄은 「  거절: 」 줄이다.
sopen "gates.sh 의 인자"
ga=$(mktemp -d); printf '#!/bin/sh\necho "PASS 가짜 claude"\nexit 97\n' > "$ga/claude"; chmod +x "$ga/claude"
gargs() {  # $1=기대 종료  $2=이름  $3…=env 인자와 gates.sh 인자
  local want=$1 name=$2; shift 2
  set +e
  PATH="$ga:$PATH" env "$@" >"$ga/out" 2>&1; st=$?
  set -e
  if [ "$st" != "$want" ]; then
    echo "::error::gates.sh $name — 종료 $st, $want 이어야 한다"; cat "$ga/out"; exit 1
  fi
  if [ "$want" = 2 ] && { grep -q PASS "$ga/out" || ! grep -q '^  거절: ' "$ga/out"; }; then
    echo "::error::gates.sh $name — 거절했는데 검사가 돌았거나 거절 줄이 없다"; cat "$ga/out"; exit 1
  fi
  if crash "$ga/out"; then echo "::error::gates.sh $name — 셸 오류 줄이 있다"; cat "$ga/out"; exit 1; fi
  if [ "$want" = 2 ]; then SB=$((SB + 1)); else SK=$((SK + 1)); fi
}
gargs 2 "A3 CI 밖의 --skip-bite"           -u GITHUB_ACTIONS     "$R/scripts/gates.sh" --skip-bite 근거
gargs 2 "A3 GITHUB_ACTIONS=false"          GITHUB_ACTIONS=false  "$R/scripts/gates.sh" --skip-bite 근거
gargs 2 "A4 --skip-bite 만"                 GITHUB_ACTIONS=true   "$R/scripts/gates.sh" --skip-bite
gargs 2 "A4 빈 근거"                        GITHUB_ACTIONS=true   "$R/scripts/gates.sh" --skip-bite ""
gargs 2 "A5 모르는 인자"                    GITHUB_ACTIONS=true   "$R/scripts/gates.sh" --nope
gargs 2 "A5 모르는 인자 둘"                 GITHUB_ACTIONS=true   "$R/scripts/gates.sh" --nope 근거
gargs 2 "A5 인자 셋"                        GITHUB_ACTIONS=true   "$R/scripts/gates.sh" --skip-bite 근거 더
gargs 97 "A2 CI 의 --skip-bite"             GITHUB_ACTIONS=true   "$R/scripts/gates.sh" --skip-bite 근거
# 받는 꼴의 PASS 줄은 근거 줄과 가짜 claude 의 PASS 줄이다 — 종료 97 은 첫 검사(가짜 claude)에 닿았다는 표
if ! grep -q '^변조 시험 다섯을 건너뛴다 — 근거$' "$ga/out" || ! grep -q '^PASS 가짜 claude$' "$ga/out"; then
  echo "::error::gates.sh --skip-bite 가 근거를 먼저 찍지 않았거나 첫 검사에 닿지 않았다"; cat "$ga/out"; exit 1
fi
sclose 7 1
echo "gates.sh: bites 묶음은 변조 시험 다섯뿐(변조본 $gbn 이 떨어짐), 거절 $SB 은 검사 전에 종료 2 와 거절 줄, CI 의 --skip-bite 는 근거를 찍고 검사로 든다"

# gates.sh 가 무엇을 실제로 부르는지 — test-gates.py 가 무는지(조각 35 닫기 전 감사 회차 NC-1 · 설계 끝 「닫기 전 감사 회차에서
# 찾은 것」 T4). 감사가 든 셋(변조 시험 줄 지우기 · bites 호출 지우기 · 건너뛰는 분기 뒤집기)과 묶음을 넘나드는 둘을 gates.sh
# 사본에 만들어 test-gates.py 가 떨어지는지 본다. 바른 gates.sh 는 checks 에서 이미 지나갔다.
# 「물었다」는 종료 1 이고 기대한 태그로 여는 FAIL 줄이 있을 때만이다 — 태그는 test-gates.py 머리말의 L2 · T1 · T1′ · T2 · T3 · S1 · S2
# (조각 41 설계 ② N1). 변조본마다 그 꼴을 이름으로 드는 태그를 적는다 — 함께 찍히는 태그는 막지 않는다(설계 ② 「보장하지 않는 것」).
gt=$(mktemp -d)
gcopy() {  # $1=만들 파일 $2…=바꿀 글 · 바꿀 것 쌍(앞의 바꿈 뒤에 차례로) — \n 은 줄바꿈
  local out=$1; shift
  python3 - scripts/gates.sh "$out" "$@" <<'PY'
import pathlib, sys
src, out, *pairs = sys.argv[1:]
t = pathlib.Path(src).read_text(encoding="utf-8")
for a, b in zip(pairs[::2], pairs[1::2]):
    a, b = a.replace("\\n", "\n"), b.replace("\\n", "\n")
    if t.count(a) != 1:
        sys.exit(f"바꿀 글 {a!r} 이 gates.sh 에 한 번이 아니다 — 이 변조본 · 대조군을 gates.sh 에 맞춰 고쳐라")
    t = t.replace(a, b)
pathlib.Path(out).write_text(t, encoding="utf-8")
PY
}
gbite() {  # $1=이름  $2=기대한 FAIL 줄의 머리 — 태그로 연다(예: 'T3' · 'L2 verify-eval-gate.py')  $3…=gcopy 의 바꿀 쌍
  local name=$1 want=$2; shift 2
  gcopy "$gt/gates.sh" "$@"
  brun python3 scripts/test-gates.py "$gt/gates.sh"
  if [ "$bst" != 1 ] || ! awk -v p="FAIL $want " 'index($0, p) == 1 { f = 1 } END { exit !f }' "$BO" || crash; then
    echo "::error::$SEC — test-gates.py 가 「$name」 gates.sh 를 「FAIL $want」로 물지 않았다 (exit $bst)"; cat "$BO"; exit 1
  fi
  SB=$((SB + 1))
}
sopen "test-gates.py(묶음 · 분기 · 삼키기)"
gbite "변조 시험 줄 지우기"           'T3'   '  ./scripts/bite-gates.sh\n' ''
gbite "bites 호출 지우기"             'T1'   '\n  bites\n' '\n'
gbite "건너뛰는 분기 뒤집기"         'T1'   '  checks\n\n  if [ -n "$skip" ]' '  checks\n\n  if [ -z "$skip" ]'
gbite "검사를 bites 로 옮기기"        'T2'   '  python3 scripts/verify-docs.py\n' '' 'bites() {\n' 'bites() {\n  python3 scripts/verify-docs.py\n'
gbite "변조 시험을 checks 로 옮기기"  'T2'   '  ./scripts/bite-gates.sh\n' '' 'checks() {\n' 'checks() {\n  ./scripts/bite-gates.sh\n'
# 감사 회차 2 의 NC-2 — CI 의 꼴에서만 건너뛰기(T1′ 이 문다)와 변조 시험의 실패 삼키기(S1 이 문다). 조각 36 설계 ② N3.
gbite "CI 에서 분기를 건너뛰는 쪽으로"  'T1′'  '  checks\n\n  if [ -n "$skip" ]; then' '  checks\n\n  if [ -n "$skip" ] || [ "${GITHUB_ACTIONS:-}" = true ]; then'
gbite "CI 에서 bites 를 부르지 않기"    'T1′'  '\n  bites\n' '\n  [ "${GITHUB_ACTIONS:-}" = true ] || bites\n'
gbite "bites 의 실패 삼키기"            'S1'   '\n  bites\n' '\n  bites || true\n'
gbite "bite-gates.sh 의 실패 삼키기"    'S1'   '  ./scripts/bite-gates.sh\n' '  ./scripts/bite-gates.sh || true\n'
sclose 9 0
echo "test-gates.py: 변조본 $SB(변조 시험 줄 · bites 호출 · 분기 뒤집기 · 검사를 bites 로 · 변조 시험을 checks 로 · CI 에서 분기 · CI 에서 bites · bites 삼키기 · bite-gates.sh 삼키기)이 다 기대한 태그로 떨어짐"

# 고정 목록과 실패 전파 — 늘 도는 검사 줄을 지우거나 삼켜도 떨어진다(조각 38 설계 ② L · S · R · V · ⑤ R1 ~ R4, 감사 OB-2).
# 「물었다」는 종료 1 이고 기대한 번호의 FAIL 줄일 때만이다(조각 37 감사 OB-4 의 가 — 다른 까닭으로 떨어진 것을 세지 않는다).
sopen "test-gates.py(고정 목록 · 실패 전파)"
# L2 — 감사가 든 첫째(늘 도는 검사 줄 지우기)와 지우기의 다른 꼴 · 겹침 · 목록에 없는 이름
gbite "늘 도는 검사 줄 지우기"         'L2 verify-eval-gate.py'     '  python3 scripts/verify-eval-gate.py\n' ''
gbite "검사 줄 주석 처리"              'L2 verify-docs.py'          '  python3 scripts/verify-docs.py\n' '  # python3 scripts/verify-docs.py\n'
gbite "검사 줄 겹치기"                 'L2 verify-budget.py'        '  python3 scripts/verify-budget.py\n' '  python3 scripts/verify-budget.py\n  python3 scripts/verify-budget.py\n'
gbite "목록에 없는 검사 더하기"        'L2 verify-new.py'           '  python3 scripts/verify-budget.py\n' '  python3 scripts/verify-budget.py\n  python3 scripts/verify-new.py\n'
gbite "claude plugin validate 줄 지우기" 'L2 claude:./vibe-slice'   '  claude plugin validate ./vibe-slice\n' ''
gbite "test-gates.py 줄 지우기"        'L2 test-gates.py'           '  python3 scripts/test-gates.py\n' ''
# S1 — 감사가 든 둘째(그 줄 뒤의 || true)와 삼키는 다른 꼴. CI 에서만 삼키면 T1′ 에서 문다
gbite "늘 도는 검사의 실패 삼키기"     'S1 T1 의 꼴에서 verify-eval-gate.py'  '  python3 scripts/verify-eval-gate.py\n' '  python3 scripts/verify-eval-gate.py || true\n'
gbite "CI 에서만 삼키기"               'S1 T1′ 의 꼴에서 verify-docs.py'      '  python3 scripts/verify-docs.py\n' '  python3 scripts/verify-docs.py || [ "${GITHUB_ACTIONS:-}" = true ]\n'
gbite "claude plugin validate 삼키기"  'S1 T1 의 꼴에서 claude:./vibe-audit'  '  claude plugin validate ./vibe-audit\n' '  claude plugin validate ./vibe-audit || :\n'
gbite "checks 머리의 set +e"           'S1 T1 의 꼴에서 verify-manifest.py'   'checks() {\n' 'checks() {\n  set +e\n'
# S2 — 건너뛰는 실행(--skip-bite)에서만 삼키기
gbite "--skip-bite 에서만 삼키기"      'S2 T2 의 꼴에서 verify-manifest.py'   '  python3 scripts/verify-manifest.py\n' '  python3 scripts/verify-manifest.py || [ -n "$skip" ]\n'
sclose 11 0
tgn=$SB

# 태그마다 변조본(조각 41 설계 ② R) — test-gates.py 가 찍을 수 있는 태그(bad 에 넣는 f-글의 머리와 그 태그를 든 꼴의 튜플)마다 그 태그로
# 여는 gbite 가 이 파일에 있다. 변조본: 한 태그(T3)의 gbite 를 다 지운 이 파일은 그 태그를 「변조본 없음」으로 찍는다.
sopen "test-gates.py 의 태그마다 변조본"
TGID='(?:bad\.append\(f"|\[f"|\(")([A-Z][0-9]+′?)[ "]'
TGWANT="^gbite \"[^\"]*\" +'([A-Z][0-9]+′?)[ ']"
gap=$(rgap scripts/test-gates.py "$TGID" "$R/scripts/bite-gates.sh" "$TGWANT")
if [ -n "$gap" ]; then echo "::error::$SEC — 변조본이 없는 태그: $gap"; exit 1; fi
SK=$((SK + 1))
grep -v "^gbite \"[^\"]*\" *'T3'" "$R/scripts/bite-gates.sh" > "$gt/cut.sh"
if [ "$(rgap scripts/test-gates.py "$TGID" "$gt/cut.sh" "$TGWANT")" != T3 ]; then
  echo "::error::$SEC — T3 의 변조본을 다 지운 목록이 「T3 변조본 없음」으로 떨어지지 않는다"; exit 1
fi
SB=$((SB + 1))
sclose 1 1

# V2 — 자유로운 것(검사 줄의 차례 · 주석)만 바꾼 gates.sh 는 지나간다. 종료 0 과 PASS 줄을 함께 본다(조각 38 설계 끝 「닫기 전 감사
# 회차에서 찾은 것」 V2′ — 감사 회차 5 OB-1 의 나)
sopen "test-gates.py(자유로운 것)"
gfree() {  # $1=이름  $2…=gcopy 의 바꿀 쌍
  local name=$1; shift
  gcopy "$gt/gates.sh" "$@"
  keep '^PASS test-gates.py' "자유로운 것만 바꾼 「$name」 gates.sh" python3 scripts/test-gates.py "$gt/gates.sh"
}
gfree "검사 줄의 차례 바꾸기"  '  python3 scripts/verify-evals.py\n  python3 scripts/verify-graders.py\n' '  python3 scripts/verify-graders.py\n  python3 scripts/verify-evals.py\n'
gfree "주석 바꾸기"            '  # 브리핑 검사기가 무는지' '  # 브리핑 검사기를 시험한다 — 무는지'
sclose 0 2
tgk=$SK  # 끝 줄은 다음 절 뒤에 함께 찍는다

# R — 진짜 gates.sh 에 한 번. checks 에서 test-gates.py 줄이 빠지면 그 시험이 돌지 않아 제 줄을 못 보므로 여기서 문다
sopen "test-gates.py(진짜 gates.sh)"
keep '^PASS test-gates.py' "진짜 gates.sh — checks 에서 test-gates.py 줄이 빠졌는가" python3 scripts/test-gates.py
sclose 0 1
echo "test-gates.py: 고정 목록 · 실패 전파 변조본 $tgn(감사가 든 것 · 지우기 · 주석 · 겹침 · 새 이름 · claude · 자기 줄 · 삼키기 · --skip-bite 에서만)이 기대한 번호로 떨어지고, 태그마다 변조본이 있고, 대조군 $tgk(차례 · 주석)과 진짜 gates.sh 가 PASS 줄로 지나감"

# eval.yml 적기 조건 — verify-eval-gate.py 가 무는지(조각 37 설계 ② V · ⑤ R1 ~ R4). eval.yml 사본의 자리를 바꿔 떨어지는지, 자유로운 칸만
# 바꾼 대조군이 지나가는지, 거절하는 인자가 아무것도 견주지 않고 종료 2 인지 본다. 「물었다」는 종료 1 이고 기대한 번호의 `FAIL [번호]` 줄이
# 있을 때만이다(조각 41 설계 ② N1 — 0 이 아닌 종료나 아무 `FAIL [` 줄을 세지 않는다). 함께 찍히는 번호는 막지 않는다. 바꿀 글은 eval.yml 에
# 꼭 한 번이어야 한다 — 아니면 변조본을 eval.yml 에 맞춰 고친다(R3). 바른 eval.yml 은 checks 에서 이미 지나갔다.
sopen "verify-eval-gate.py"
ge=$(mktemp -d)
eraw() {  # $1=기대한 번호 $2=이름 $3=견줄 파일
  bit 1 "^FAIL \[$1\] " "$2" python3 scripts/verify-eval-gate.py "$3"
}
emut() {  # $1=기대한 번호 | pass  $2=이름  $3…=바꿀 글 · 바꿀 것 쌍(앞의 바꿈 뒤에 차례로) — \n 은 줄바꿈, \t 는 탭
  local want=$1 name=$2; shift 2
  python3 - .github/workflows/eval.yml "$ge/eval.yml" "$@" <<'PY'
import pathlib, sys
src, out, *pairs = sys.argv[1:]
t = pathlib.Path(src).read_text(encoding="utf-8")
for a, b in zip(pairs[::2], pairs[1::2]):
    a, b = (s.replace("\\n", "\n").replace("\\t", "\t") for s in (a, b))
    if t.count(a) != 1:
        sys.exit(f"바꿀 글 {a!r} 이 eval.yml 에 한 번이 아니다 — 이 변조본을 eval.yml 에 맞춰 고쳐라")
    t = t.replace(a, b)
pathlib.Path(out).write_text(t, encoding="utf-8")
PY
  if [ "$want" = pass ]; then
    keep '^PASS verify-eval-gate.py' "자유로운 칸만 바꾼 「$name」 eval.yml" python3 scripts/verify-eval-gate.py "$ge/eval.yml"
  else
    eraw "$want" "$name" "$ge/eval.yml"
  fi
}
# 감사가 든 둘(OB-1)
emut T3 "gates.sh 의 실패 삼키기"          '            ./scripts/gates.sh\n          fi\n' '            ./scripts/gates.sh || true\n          fi\n'
emut T3 "건너뛰는 갈래의 full=true"        '            ./scripts/gates.sh --skip-bite "$why"\n' '            echo "full=true" >> "$GITHUB_OUTPUT"\n            ./scripts/gates.sh --skip-bite "$why"\n'
# Y — 읽는 꼴 밖(③ Y6 의 꼴마다)
emut Y "Y 탭"                              '        id: gates\n' '        id:\tgates\n'
emut Y "Y 앵커"                            '        id: gfp\n' '        id: &g gfp\n'
emut Y "Y 별칭"                            '        id: gpass\n' '        id: *g\n'
emut Y "Y 태그"                            '        id: gates\n' '        id: !!str gates\n'
emut Y "Y 병합 키"                         '        id: gseen\n' '        id: gseen\n        <<: x\n'
emut Y "Y 흐름 꼴"                         '          fetch-depth: 0\n' '          fetch-depth: [0]\n'
emut Y "Y 같은 키 둘"                      '        id: gpass\n' '        id: gpass\n        id: gpass\n'
emut Y "Y | 밖의 블록 꼴"                  "        if: steps.gates.outputs.full == 'true' && steps.gfp.outputs.key != ''\n        run: |\n" "        if: steps.gates.outputs.full == 'true' && steps.gfp.outputs.key != ''\n        run: |-\n"
emut Y "Y 따옴표 키"                       '        id: gates\n' '        "id": gates\n'
emut Y "Y 값 뒤의 주석"                    '        id: gmerged\n' '        id: gmerged # 주석\n'
emut Y "Y 알 수 없는 들여쓰기"             '        id: gfp\n' '         id: gfp\n'
# H — 머리의 키
emut H1 "H1 워크플로의 defaults"            '\njobs:\n' '\ndefaults:\n  run:\n    shell: bash {0}\n\njobs:\n'
emut H2 "H2 gate 잡의 continue-on-error"    '  gate:\n    runs-on: ubuntu-24.04\n' '  gate:\n    runs-on: ubuntu-24.04\n    continue-on-error: true\n'
# T1 — 차례(끼기 · 빠지기 · 바꾸기)
emut T1 "T1 스텝 끼기"                      '      - name: 키 없이 도는 게이트\n' '      - run: echo hi\n      - name: 키 없이 도는 게이트\n'
emut T1 "T1 스텝 빠지기"                    "      - uses: actions/cache/save@v6\n        if: steps.gmerged.outputs.hit == 'true'\n        with:\n          path: .gate-pass\n          key: \${{ steps.gfp.outputs.key }}\n" ''
emut T1 "T1 차례 바꾸기"                    '      - uses: actions/checkout@v7\n        with:\n          fetch-depth: 0\n      - uses: actions/setup-node@v7\n        with:\n          node-version: "22"\n          package-manager-cache: false\n' '      - uses: actions/setup-node@v7\n        with:\n          node-version: "22"\n          package-manager-cache: false\n      - uses: actions/checkout@v7\n        with:\n          fetch-depth: 0\n'
# T2 — 다른 칸
emut T2 "T2 gate 스텝의 continue-on-error"  '        id: gates\n' '        id: gates\n        continue-on-error: true\n'
emut T2 "T2 gate 스텝의 shell"              '        id: gates\n' '        id: gates\n        shell: bash {0}\n'
# T3 — 칸 갈래마다(if · env · with · uses · run). id 는 차례의 얼굴이라 바꾸면 T1 이 문다(조각 41 — 감사 회차 4 OB-4 의 가)
emut T1 "T1 id 를 바꿈 — id 는 차례의 얼굴이라 T3 이 아니라 T1"                             '        id: gpass\n' '        id: gpass2\n'
emut T3 "T3 적는 스텝의 if 에 always()"     "        if: steps.gates.outputs.full == 'true' && steps.gfp.outputs.key != ''\n" "        if: always() && steps.gates.outputs.full == 'true' && steps.gfp.outputs.key != ''\n"
emut T3 "T3 캐시 저장의 if"                 "        if: steps.gpass.outcome == 'success'\n" "        if: always()\n"
emut T3 "T3 HIT 를 늘 참으로"               "          HIT: \${{ steps.gseen.outputs.cache-hit == 'true' || steps.gmerged.outputs.hit == 'true' }}\n" "          HIT: \${{ true }}\n"
emut T3 "T3 찾아보기의 restore-keys"        '        uses: actions/cache/restore@v6\n        with:\n          path: .gate-pass\n' '        uses: actions/cache/restore@v6\n        with:\n          path: .gate-pass\n          restore-keys: gate-bite-\n'
emut T3 "T3 uses 의 이름"                   '        uses: actions/cache/restore@v6\n        with:\n          path: .gate-pass\n' '        uses: actions/cache@v6\n        with:\n          path: .gate-pass\n'
emut T3 "T3 uses 의 판"                     '      - uses: actions/checkout@v7\n        with:\n          fetch-depth: 0\n' '      - uses: actions/checkout@main\n        with:\n          fetch-depth: 0\n'
emut T3 "T3 run 의 set +e"                  '            ./scripts/gates.sh\n          fi\n' '            set +e\n            ./scripts/gates.sh\n          fi\n'
emut T3 "T3 run 의 지문 박기"               '            echo "key=$key" >> "$GITHUB_OUTPUT"\n' '            echo "key=gate-bite-x" >> "$GITHUB_OUTPUT"\n'
# F2 의 경계 — 알림 줄처럼 보이는 명령 줄(명령 줄로 견주어 T3 이 문다)
emut T3 "F2 > 가 붙은 echo"                 '            ./scripts/gates.sh\n          fi\n' '            echo "x" > .gate-pass/run.txt\n            ./scripts/gates.sh\n          fi\n'
emut T3 "F2 ::set-output 알림 줄"         '            ./scripts/gates.sh --skip-bite "$why"\n' '            echo "::set-output name=full::true"\n            ./scripts/gates.sh --skip-bite "$why"\n'
emut T3 "F2 \$( 가 든 echo"                 'echo "::notice::변조 시험 다섯을 건너뛴다 — $why"' 'echo "::notice::$(./scripts/gates.sh --skip-bite x) $why"'
# G — 열한 스텝 밖의 근거 파일 · 지문
emut G "G 다른 잡의 .gate-pass"            '          mkdir -p .eval-pass\n          echo "$GITHUB_SERVER_URL' '          mkdir -p .eval-pass .gate-pass\n          echo "$GITHUB_SERVER_URL'
emut G "G 열한 뒤 스텝의 gfp"              '          KEY: ${{ steps.fp.outputs.key }}\n        run: python3 scripts/eval-merged-pass.py "$KEY"' '          KEY: ${{ steps.gfp.outputs.key }}\n        run: python3 scripts/eval-merged-pass.py "$KEY"'
# 대조군 — F 의 칸마다 하나(R2)
emut pass "F1 이름 · 주석 · 빈 줄"            '      - name: 키 없이 도는 게이트\n' '\n      # 주석\n      - name: 게이트\n' '      - name: 변조 시험 지문\n        id: gfp\n' '      - id: gfp\n' '            ./scripts/gates.sh\n          fi\n' '            # 셸 주석\n\n            ./scripts/gates.sh\n          fi\n'
emut pass "F2 알림 줄"                        'echo "::notice::변조 시험 다섯을 건너뛴다 — $why"' 'echo "::notice::건너뛴다 — ${why}"' '            ./scripts/gates.sh\n          fi\n' '            echo "다 돈다 — $KEY"\n            ./scripts/gates.sh\n          fi\n'
emut pass "F3 액션의 판"                      "      - uses: actions/cache/save@v6\n        if: steps.gpass.outcome == 'success'\n" "      - uses: actions/cache/save@v7\n        if: steps.gpass.outcome == 'success'\n" '      - uses: actions/checkout@v7\n        with:\n          fetch-depth: 0\n' '      - uses: actions/checkout@v12\n        with:\n          fetch-depth: 0\n'
# A2 — 읽지 못하는 eval.yml(R 이 찾은 빈칸 — 조각 41 설계 ② R). UTF-8 이 아닌 바이트 · 없는 파일
printf '\xff\xfe\n' > "$ge/bad.yml"
eraw A2 "UTF-8 이 아닌 eval.yml" "$ge/bad.yml"
eraw A2 "없는 eval.yml" "$ge/nope.yml"
# 인자 — 거절하는 꼴은 아무것도 견주지 않고 종료 2 와 사용법 줄(R4)
for args in "a b" "-x" "--help"; do
  set +e
  # shellcheck disable=SC2086
  python3 scripts/verify-eval-gate.py $args >"$BO" 2>&1; st=$?
  set -e
  if [ "$st" != 2 ] || grep -qE '^(PASS|FAIL)' "$BO" || ! grep -q '^사용법: verify-eval-gate.py' "$BO" || crash; then
    echo "::error::verify-eval-gate.py 가 거절할 인자 '$args' 에 종료 2 · 사용법 줄이 아니거나 견주었다 (exit $st)"; cat "$BO"; exit 1
  fi
  SB=$((SB + 1))
done
sclose 39 3
echo "verify-eval-gate.py: eval.yml 변조본(감사가 든 것 · 읽는 꼴 · 머리 · 차례 · 칸 · 글 · 알림 줄의 경계 · 갇힘 · 읽지 못함)과 거절 인자, 합 $SB 이 기대한 번호 · 종료로 떨어지고, 자유로운 칸의 대조군 $SK 이 PASS 줄로 지나감"

# 번호마다 변조본(조각 41 설계 ② R) — verify-eval-gate.py 가 찍을 수 있는 번호(fail(…) · 일찍 돌려주는 [("…") · 「FAIL [A2]」)마다
# 그 번호를 기대하는 emut · eraw 가 이 파일에 있다. 변조본: A2 의 변조본을 다 지운 이 파일은 A2 를 「변조본 없음」으로 찍는다.
sopen "verify-eval-gate.py 의 번호마다 변조본"
EGID='(?:fail\(|\[\(|FAIL \[)"?([A-Z][0-9]*)\b'
EGWANT='^(?:emut|eraw) ([A-Z][0-9]*) '
gap=$(rgap scripts/verify-eval-gate.py "$EGID" "$R/scripts/bite-gates.sh" "$EGWANT")
if [ -n "$gap" ]; then echo "::error::$SEC — 변조본이 없는 번호: $gap"; exit 1; fi
SK=$((SK + 1))
grep -vE '^(emut|eraw) A2 ' "$R/scripts/bite-gates.sh" > "$ge/cut.sh"
if [ "$(rgap scripts/verify-eval-gate.py "$EGID" "$ge/cut.sh" "$EGWANT")" != A2 ]; then
  echo "::error::$SEC — A2 의 변조본을 다 지운 목록이 「A2 변조본 없음」으로 떨어지지 않는다"; exit 1
fi
SB=$((SB + 1))
sclose 1 1

# 적힌 수 — verify-counts.py 가 무는지(조각 42 설계 ② D · S · L · E · N · ⑤ V3 · V6, 조각 46 설계 ② U · R). 저장소의 사본 하나에 한 자리씩
# 흔들고 대어 본 뒤 그 자리만 되돌린다. 닻 · 명사 · 예외는 검사 코드에 있어, 변조본은 사본에 든 검사(`$VC/scripts/verify-counts.py`)를 돈다. 「물었다」는 종료 1 이고 기대한 ID 의 `FAIL [ID]` 줄이 있을 때만이다(조각 41 설계 ② N1). 함께 찍히는 ID 는 막지
# 않는다. 바꿀 글은 그 파일에 꼭 한 번이어야 한다 — 아니면 이 변조본을 그 파일에 맞춰 고친다. 바른 트리는 checks 에서 이미 지나갔다.
sopen "verify-counts.py"
VC=$(mktemp -d)
git ls-files -co --exclude-standard -z | tar --null -T - -cf - | tar -xf - -C "$VC"
vedit() {  # $1=파일(저장소 맨 위 기준)  $2…=바꿀 글 · 바꿀 것 쌍 — \n 은 줄바꿈. 사본의 그 파일을 앞의 바꿈 위에서 바꾼다
  local f=$1; shift
  python3 - "$VC/$f" "$@" <<'PY'
import pathlib, sys
p, *pairs = sys.argv[1:]
t = pathlib.Path(p).read_text(encoding="utf-8")
for a, b in zip(pairs[::2], pairs[1::2]):
    a, b = a.replace("\\n", "\n"), b.replace("\\n", "\n")
    if t.count(a) != 1:
        sys.exit(f"바꿀 글 {a!r} 이 {p} 에 한 번이 아니다 — 이 변조본을 그 파일에 맞춰 고쳐라")
    t = t.replace(a, b)
pathlib.Path(p).write_text(t, encoding="utf-8")
PY
}
vback() {  # $@=저장소 맨 위 기준 경로 — 사본의 그 자리를 저장소의 것으로 되돌린다(저장소에 없으면 지운다)
  local f
  for f; do
    rm -rf "${VC:?}/$f"
    if [ -e "$R/$f" ]; then cp -pPR "$R/$f" "$VC/$f"; fi
  done
}
vbite() {  # $1=기대한 ID  $2=이름  $3=실패 줄의 자리(grep -E, 없으면 아무 자리) — 사본에 든 검사를 사본에 댄다
  bit 1 "^FAIL \[$1\] ${3:-}" "$2" python3 "$VC/scripts/verify-counts.py" "$VC"
}
VPASS='^PASS verify-counts\.py — 닻 [0-9]+ 이 원천 [0-9]+ 과 맞고, 끝 줄 [0-9]+ 에'
# D1 — 적힌 수가 원천과 다르다: 수 하나를 틀리게 · 원천을 하나 늘림 · gates.sh 의 검사 수를 되돌림(V6) · 닻을 가진 끝 줄의 낱말
vedit README.md '문서 틀 여섯' '문서 틀 일곱'
vbite D1 "적힌 수 하나를 틀리게"
vback README.md
mkdir "$VC/vibe-audit/evals/route-zz"; : > "$VC/vibe-audit/evals/route-zz/case.yaml"
vbite D1 "케이스 폴더 하나 더하기"
vback vibe-audit/evals/route-zz
vedit scripts/gates.sh '# 스물여덟 — 로컬은' '# 스물일곱 — 로컬은'
vbite D1 "gates.sh 의 검사 수를 새 검사 앞으로 되돌림"
vback scripts/gates.sh
vedit scripts/test-gates.py '변조 시험 다섯이 맨 뒤' '변조 시험 여섯이 맨 뒤'
vbite D1 "닻을 가진 끝 줄의 낱말을 틀리게"
vback scripts/test-gates.py
# D2 — 닻이 낡았다: 문장을 지움 · 문장을 겹쳐 적음 · 닻의 파일이 없음
vedit INTENT.md '감사자 여섯 · ' '감사자들 · '
vbite D2 "닻이 가리키는 문장을 지움"
vback INTENT.md
vedit CLAUDE.md '- **감사자의 `tools`** — 읽기 전용 셋.' '- **감사자의 `tools`** — 읽기 전용 셋. 읽기 전용 셋.'
vbite D2 "닻이 가리키는 문장을 겹쳐 적음"
vback CLAUDE.md
rm "$VC/docs/schema.md"
vbite D2 "닻의 파일이 없음"
vback docs/schema.md
# S1 — 원천을 못 셈: 원천을 비움 · 원천의 읽는 자리를 못 찾음
mv "$VC/vibe-audit/agents" "$VC/vibe-audit/agents-x"
vbite S1 "원천을 비움(감사자 폴더가 없다)"
vback vibe-audit/agents-x vibe-audit/agents
vedit scripts/gates.sh 'bites() {' 'bites () {'
vbite S1 "원천의 읽는 자리를 못 찾음"
vback scripts/gates.sh
# L1 — 수 낱말을 못 읽음
vedit README.md '문서 틀 여섯' '문서 틀 스물스물'
vbite L1 "읽을 수 없는 수 낱말"
vback README.md
# E1 — 끝 줄에 견준 값 밖의 수 낱말: 견준 값을 글자로 박음 · 갈래 수 낱말을 되살림(조각 42 PR B 가 뺀 꼴)
vedit scripts/test-gates.py '대조군 {KEPT} 이 돌았다' '대조군 3 이 돌았다'
vbite E1 "끝 줄에 견준 값을 아라비아 수로 박음"
vback scripts/test-gates.py
vedit scripts/bite-gates.sh '\necho "test-gates.py: 고정 목록 · 실패 전파 변조본 $tgn(감사가 든 것' '\necho "test-gates.py: 고정 목록 · 실패 전파 변조본 $tgn(감사가 든 둘'
vbite E1 "끝 줄에 갈래 수 낱말을 되살림"
vback scripts/bite-gates.sh
# E2 — 끝 줄을 못 찾음: 끝 줄의 꼴이 바뀌어 훑기에서 빠짐
vedit scripts/test-verify-feedback.py 'print(f"PASS verify-feedback.py' 'print(f"OK verify-feedback.py'
vbite E2 "끝 줄의 꼴을 바꿈"
vback scripts/test-verify-feedback.py
# U1 — 닻 없는 같은 원천 문장: 감사 회차 15 · 16 · 17 이 짚은 자리 넷의 닻을 하나씩 지움 · 새 문장을 닻 없이 더함(명사 뒤 · 명사 앞)
vedit scripts/verify-counts.py "    ('scripts/gates.sh', r'심은 {N} 검사가 대상에서', 1, '조각 문서 검사'),\\n" ""
vbite U1 "NC-15 · NC-16 의 자리(gates.sh)의 닻을 지움" 'scripts/gates\.sh:[0-9]+ '
vback scripts/verify-counts.py
vedit scripts/verify-counts.py "    ('scripts/test-sync-slice.py', r'slice-docs/scripts/ 의 {N} 검사가 원본과', 1, '조각 문서 검사'),\\n" ""
vbite U1 "NC-16 의 자리(test-sync-slice.py 독스트링)의 닻을 지움" 'scripts/test-sync-slice\.py:[0-9]+ '
vback scripts/verify-counts.py
vedit scripts/verify-counts.py "    ('scripts/test-sync-slice.py', r'심은 {N} 검사가 대상 레포에서', 1, '조각 문서 검사'),\\n" ""
vbite U1 "NC-15 · NC-16 의 자리(test-sync-slice.py 주석)의 닻을 지움" 'scripts/test-sync-slice\.py:[0-9]+ '
vback scripts/verify-counts.py
vedit scripts/verify-counts.py "    ('docs/procedure.md', r'{N} 검사는 \`vibe-slice\`', 1, '조각 문서 검사'),\\n" ""
vbite U1 "NC-17 의 자리(procedure.md 머리)의 닻을 지움" 'docs/procedure\.md:[0-9]+ '
vback scripts/verify-counts.py
vedit CHECKLIST.md '\n## 플러그인의 파일을 고쳤다면' '\n감사자 여섯이 다 읽기 전용이다.\n\n## 플러그인의 파일을 고쳤다면'
vbite U1 "명사 뒤의 수를 닻 없이 더함" 'CHECKLIST\.md:[0-9]+ '
vback CHECKLIST.md
vedit docs/architecture.md '\n## 문서' '\n일곱 단계를 지난다.\n\n## 문서'
vbite U1 "명사 앞의 수를 닻 없이 더함" 'docs/architecture\.md:[0-9]+ '
vback docs/architecture.md
# U2 — 예외가 낡았다: 예외가 가리키는 문장을 고침
vedit scripts/run-evals.sh '문턱 0.8 에서 네 만점' '문턱에서 네 만점'
vbite U2 "예외가 가리키는 문장을 고침" 'scripts/run-evals\.sh '
vback scripts/run-evals.sh
# U3 — 원천과 명사 목록이 갈린다: 원천의 명사를 지움 · 명사 없는 원천을 더함
vedit scripts/verify-counts.py '    "단계": [r"단계"],\n' ''
vbite U3 "원천의 명사를 지움"
vback scripts/verify-counts.py
vedit scripts/verify-counts.py '    "열린 버그": ("rows",' '    "새 원천": ("files", "vibe-audit/agents/audit-*.md", None),\n    "열린 버그": ("rows",'
vbite U3 "명사 없는 원천을 더함"
vback scripts/verify-counts.py
# U4 — 훑을 파일이 없다: 훑는 꼴이 낡음
vedit scripts/verify-counts.py 'SCAN_EXT = (".md", ".py", ".sh", ".yml", ".yaml", ".json")' 'SCAN_EXT = (".zzz",)'
vbite U4 "훑을 파일의 꼴이 아무것도 고르지 않음"
vback scripts/verify-counts.py
# 인자 — 거절하는 꼴은 아무것도 견주지 않고 종료 2 와 사용법 줄
for args in "a b" "-x" "--help" "$VC/nope"; do
  set +e
  # shellcheck disable=SC2086
  python3 scripts/verify-counts.py $args >"$BO" 2>&1; st=$?
  set -e
  if [ "$st" != 2 ] || grep -qE '^(PASS|FAIL)' "$BO" || ! grep -q '^사용법: verify-counts.py' "$BO" || crash; then
    echo "::error::verify-counts.py 가 거절할 인자 '$args' 에 종료 2 · 사용법 줄이 아니거나 견주었다 (exit $st)"; cat "$BO"; exit 1
  fi
  SB=$((SB + 1))
done
# 대조군 — 고치지 않은 사본, 그리고 원천과 문장을 함께 바꾼 사본(판정 케이스 다섯을 더하고 그 수를 적은 문장을 합성 낱말로 고친다)
keep "$VPASS" "고치지 않은 사본" python3 scripts/verify-counts.py "$VC"
for i in 1 2 3 4 5; do mkdir "$VC/vibe-audit/evals/zz-$i"; : > "$VC/vibe-audit/evals/zz-$i/case.yaml"; done
vedit vibe-audit/README.md '케이스 스물여섯이' '케이스 서른하나이' '인자 없이 스물여섯을' '인자 없이 서른하나를' '| 판정 | 열여섯 |' '| 판정 | 스물하나 |'
vedit .github/workflows/eval.yml '케이스 스물여섯이다' '케이스 서른하나이다'
keep "$VPASS" "원천과 문장을 함께 바꾼 사본" python3 scripts/verify-counts.py "$VC"
vback vibe-audit/evals/zz-1 vibe-audit/evals/zz-2 vibe-audit/evals/zz-3 vibe-audit/evals/zz-4 vibe-audit/evals/zz-5 vibe-audit/README.md .github/workflows/eval.yml
sclose 27 2
echo "verify-counts.py: 변조본(수를 틀리게 · 원천 더하기 · 검사 수 되돌림 · 문장 지움 · 겹쳐 적음 · 파일 없음 · 원천 비움 · 읽는 자리 · 못 읽는 낱말 · 끝 줄의 수 · 끝 줄의 꼴 · 닻 없는 같은 원천 문장과 감사가 짚은 자리 · 예외 낡음 · 명사 목록 · 훑을 파일)과 거절 인자, 합 $SB 이 기대한 ID · 종료로 떨어지고, 대조군 $SK 이 PASS 줄로 지나감"

# ID 마다 변조본(조각 42 설계 ② R) — verify-counts.py 가 찍을 수 있는 ID(r.fail("…"))마다 그 ID 를 기대하는 vbite 가 이 파일에 있다.
# 변조본: E2 의 vbite 를 다 지운 이 파일은 E2 를 「변조본 없음」으로 찍는다.
sopen "verify-counts.py 의 ID 마다 변조본"
VCID='r\.fail\("([A-Z][0-9])"'
VCWANT='^vbite ([A-Z][0-9]) '
gap=$(rgap scripts/verify-counts.py "$VCID" "$R/scripts/bite-gates.sh" "$VCWANT")
if [ -n "$gap" ]; then echo "::error::$SEC — 변조본이 없는 ID: $gap"; exit 1; fi
SK=$((SK + 1))
grep -vE '^vbite E2 ' "$R/scripts/bite-gates.sh" > "$VC/cut.sh"
if [ "$(rgap scripts/verify-counts.py "$VCID" "$VC/cut.sh" "$VCWANT")" != E2 ]; then
  echo "::error::$SEC — E2 의 변조본을 다 지운 목록이 「E2 변조본 없음」으로 떨어지지 않는다"; exit 1
fi
SB=$((SB + 1))
sclose 1 1

# 부적합 대장 — verify-ledger.py 가 무는지(조각 43 설계 ② F · R · K1 ~ K4 · N · B · ⑤ V2). 변조본은 저장소의 대장이 아니라 틀에서 세운
# 고정 대장(lmake rows)에 한 자리씩 흔들고 대어 본 뒤 그 대장으로 되돌린다 — 저장소의 대장은 회차마다 줄이 옮겨 가 변조본이 낡는다.
# 「물었다」는 종료 1 이고 기대한 ID 의 `FAIL [ID]` 줄이 있을 때만이다(ADR 0054 의 나). 함께 찍히는 ID 는 막지 않는다. 바꿀 글은 그 파일에
# 꼭 한 번이어야 한다. 대조군은 저장소의 사본 · 고정 대장 · 틀을 처음 베낀 대장(--repo) · 대장 없는 레포(--repo)다.
sopen "verify-ledger.py"
lmake() {  # $1=만들 루트(git 저장소로 연다)  $2=fresh(틀을 처음 베낀 대장) | rows(줄과 회차를 채운 고정 대장)
  mkdir -p "$1/docs/audit"; git -C "$1" init -q
  python3 - "$R/vibe-slice/skills/slice-docs/templates" "$1/docs/audit" "$2" <<'PY'
import pathlib, re, sys
tpl, out, kind = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3]
def sub(t, a, b):
    if t.count(a) != 1:
        sys.exit(f"틀에 {a!r} 이 한 번이 아니다 — bite-gates.sh 의 lmake 를 틀에 맞춰 고쳐라")
    return t.replace(a, b)
def body(name):  # 틀 머리의 주석을 지운다(틀 머리가 시키는 대로)
    t = (tpl / name).read_text(encoding="utf-8")
    if not t.startswith("<!--") or "-->\n" not in t:
        sys.exit(f"틀 {name} 이 머리 주석으로 열지 않는다 — bite-gates.sh 의 lmake 를 틀에 맞춰 고쳐라")
    return t.split("-->\n", 1)[1].lstrip("\n")
NC = "| NC | 무엇 | 낸 회차 | 담당 | 심각도 | 상태 | 판정과 근거 |\n|---|---|---|---|---|---|---|\n"
U = "| U | 무엇 | 낸 회차 | 담당 | 판정하려면 | 누가 줄 수 있나 | 멈춘 회차 | 상태 |\n|---|---|---|---|---|---|---|---|\n"
live = body("nc-ledger.md")
live = sub(live, "`<지나간 쪽의 경로>`", "`docs/audit/nc-ledger-history.md`")
live = sub(live, "@ `<커밋>` (<YYYY-MM-DD>)", "@ `7414914` (2026-10-29)")
ls = live.split("\n")
keep = [l for l in ls if not re.match(r"^\| <[nm]> \|", l)]
if len(ls) - len(keep) != 2:
    sys.exit("틀의 자리표시 줄이 둘이 아니다 — bite-gates.sh 의 lmake 를 틀에 맞춰 고쳐라")
live = "\n".join(keep)
hist = sub(body("nc-ledger-history.md"), "`<살아 있는 쪽의 경로>`", "`docs/audit/nc-ledger.md`")
if kind == "rows":
    live = sub(live, "**다음 번호: NC-1 · U-1**", "**다음 번호: NC-4 · U-3**")
    live = sub(live, NC, NC + "| 3 | 셋째 지적 | 회차 2 | `audit-quality` | 높음 | **고침** — 회차 2 에서 고쳤다 | 재감사를 기다린다 |\n")
    live = sub(live, U, U + "| 1 | 첫 확인불가 | 회차 1 | `audit-quality` | 실행 로그 | 저자 | 0 | **닫힘** — 근거를 받았다 |\n"
                            "| 2 | 둘째 확인불가 | 회차 2 | `audit-internal` | PR 본문 \\| 로그 | 저자 | 1 | **열림** |\n")
    hist = sub(hist, NC, NC + "| 1 | 첫 지적 | 회차 1 | `audit-quality` | 높음 | **닫힘** — 회차 2 가 닫았다 | 고침 |\n"
                              "| 2 | 둘째 지적 | 회차 1 | `audit-quality` | 중간 | **닫힘** | 반박 |\n")
    hist = sub(hist, "## 회차 <n> — `<감사자>` · <범위> (<YYYY-MM-DD>)", "## 회차 1 — `audit-quality` · 시험 (2026-10-29)")
    hist = sub(hist, "- **감사한 커밋**: `<sha>`", "- **감사한 커밋**: `abc1234`")
    hist += "\n## 회차 2 — `audit-quality` · 시험, 재감사 (2026-10-29)\n\n- **감사한 커밋**: 모름 · **감사자**: `audit-quality`\n- 기록: 시험\n"
(out / "nc-ledger.md").write_text(live, encoding="utf-8")
(out / "nc-ledger-history.md").write_text(hist, encoding="utf-8")
PY
}
LP=$(mktemp -d); lmake "$LP" rows
LF=$(mktemp -d); lmake "$LF" rows
LL=docs/audit/nc-ledger.md
LH=docs/audit/nc-ledger-history.md
ledit() {  # $1=파일(대장 루트 기준)  $2…=바꿀 글 · 바꿀 것 쌍 — \n 은 줄바꿈
  local f=$1; shift
  python3 - "$LF/$f" "$@" <<'PY'
import pathlib, sys
p, *pairs = sys.argv[1:]
t = pathlib.Path(p).read_text(encoding="utf-8")
for a, b in zip(pairs[::2], pairs[1::2]):
    a, b = a.replace("\\n", "\n"), b.replace("\\n", "\n")
    if t.count(a) != 1:
        sys.exit(f"바꿀 글 {a!r} 이 {p} 에 한 번이 아니다 — 이 변조본을 lmake 의 대장에 맞춰 고쳐라")
    t = t.replace(a, b)
pathlib.Path(p).write_text(t, encoding="utf-8")
PY
}
lback() { rm -rf "${LF:?}/docs"; cp -R "$LP/docs" "$LF/docs"; }
lbite() {  # $1=기대한 ID  $2=이름  [$3=루트 — 없으면 고정 대장]
  bit 1 "^FAIL \[$1\] " "$2" python3 scripts/verify-ledger.py "${3:-$LF}"
  lback
}
LPASS='^PASS verify-ledger\.py — 대장 docs/audit/nc-ledger\.md · docs/audit/nc-ledger-history\.md 에서 NC [0-9]+ · 확인불가 [0-9]+ · 회차 절 [0-9]+ 을 읽었다$'
R3='| 3 | 셋째 지적 | 회차 2 | `audit-quality` | 높음 | **고침** — 회차 2 에서 고쳤다 | 재감사를 기다린다 |'
# F — 대장을 못 찾음: 출처 줄이 둘 · 지나간 쪽이 없음 · 출처 줄을 지움(이 저장소 모드) · 경로가 자리표시 그대로 · 루트가 git 맨 위가 아님
cp "$LF/$LL" "$LF/docs/audit/copy.md"
lbite F "출처 줄이 있는 파일이 둘(추적 안 된 사본)"
rm "$LF/$LH"
lbite F "지나간 쪽이 없음"
ledit "$LL" '- 베낀 틀: claude-kit' '- 베낀 틀: kit'
lbite F "출처 줄을 지움 — 이 저장소 모드는 대장이 있어야 한다"
ledit "$LL" '`docs/audit/nc-ledger-history.md` 가 든다' '`<지나간 쪽의 경로>` 가 든다'
lbite F "지나간 쪽의 경로가 틀의 자리표시 그대로"
lbite F "루트가 git 맨 위가 아님" "$LF/docs"
# R — 못 읽음: 자리표시 줄 · 상태 낱말 문장 · 문장의 「닫힘」 · 다음 번호 줄의 꼴 · 표 머리 · 칸 수 · 끊긴 표 · 절
ledit "$LL" "$R3" "$R3"'\n| <n> | <원 지적 — 기록이다> | <회차> | `<감사자>` | <기록의 심각도> | **<상태>** | <판정> |'
lbite R "틀의 자리표시 줄을 남김"
ledit "$LL" '**상태 칸은 이 절이 정한 말로 연다** — ' '상태 칸은 이 절이 정한 말로 연다 — '
lbite R "상태 낱말 문장을 지움"
ledit "$LL" ' · 부분 닫힘 · 닫힘. ' ' · 부분 닫힘. '
lbite R "상태 낱말 문장에서 「닫힘」을 뺌"
ledit "$LL" '**다음 번호: NC-4 · U-3**' '**다음 번호: NC-4**'
lbite R "다음 번호 줄의 꼴이 틀림"
ledit "$LH" '| NC | 무엇 | 낸 회차 | 담당 | 심각도 | 상태 | 판정과 근거 |' '| NC | 무엇 | 낸 회차 | 담당 | 상태 | 판정과 근거 |'
lbite R "지나간 쪽의 표 머리에서 칸 하나를 뺌"
ledit "$LL" "$R3" "$R3"' 덧붙인 칸 |'
lbite R "표 줄의 칸 수가 머리와 다름"
ledit "$LH" '| 고침 |\n| 2 |' '| 고침 |\n\n| 2 |'
lbite R "빈 줄로 표가 끊김"
ledit "$LL" '## 확인불가' '## 확인 불가'
lbite R "절의 제목을 바꿈"
# K1 — 상태 낱말: 굵게 하지 않은 「열림 — 저자 판정 대기」(7a6f3e6 의 꼴) · 문장에 없는 말 · 낱말 뒤에 붙은 글 · 지나간 쪽의 굵지 않은 칸
ledit "$LL" '**고침** — 회차 2 에서 고쳤다' '열림 — 저자 판정 대기'
lbite K1 "굵게 하지 않은 「열림 — 저자 판정 대기」"
ledit "$LL" '**고침** — 회차 2 에서' '**판정 대기** — 회차 2 에서'
lbite K1 "문장에 없는 상태 말"
ledit "$LL" '**고침** — 회차 2 에서' '**고침됨** — 회차 2 에서'
lbite K1 "낱말 뒤에 붙은 글"
ledit "$LH" '| **닫힘** | 반박 |' '| 닫힘 | 반박 |'
lbite K1 "지나간 쪽의 굵게 하지 않은 상태"
# K2 — 줄이 사는 표: 「닫힘」 줄을 살아 있는 쪽에 · 「닫힘」 아닌 줄(부분 닫힘 — 「닫힘」으로 읽히지 않는다)을 지나간 쪽에
ledit "$LL" '**고침** — 회차 2 에서' '**닫힘** — 회차 2 에서'
lbite K2 "「닫힘」 줄을 살아 있는 쪽에 둠"
ledit "$LH" '**닫힘** — 회차 2 가' '**부분 닫힘** — 회차 2 가'
lbite K2 "「부분 닫힘」 줄을 지나간 쪽에 둠"
# K3 — 번호: 다음 번호를 올리지 않음 · 겹침 · 가장 큰 줄을 잃음 · U 번호를 잃음 · 다음 번호 줄이 둘
ledit "$LL" "$R3" "$R3"'\n| 4 | 넷째 지적 | 회차 3 | `audit-quality` | 낮음 | **등록** — 다음 조각 | 등록 |'
lbite K3 "줄을 더하고 다음 번호를 올리지 않음"
ledit "$LH" '| 2 | 둘째 지적 |' '| 3 | 둘째 지적 |'
lbite K3 "번호가 두 표를 가로질러 겹침"
ledit "$LL" "$R3"'\n' ''
lbite K3 "가장 큰 줄을 잃음"
ledit "$LL" '\n| 2 | 둘째 확인불가 | 회차 2 | `audit-internal` | PR 본문 \| 로그 | 저자 | 1 | **열림** |' ''
lbite K3 "가장 큰 U 줄을 잃음"
ledit "$LL" '**다음 번호: NC-4 · U-3**' '**다음 번호: NC-4 · U-3**\n\n**다음 번호: NC-4 · U-3**'
lbite K3 "다음 번호 줄이 둘"
LZ=$(mktemp -d); lmake "$LZ" fresh
sed -i 's/^\*\*다음 번호: NC-1 · U-1\*\*$/**다음 번호: NC-0 · U-1**/' "$LZ/$LL"
lbite K3 "빈 표에서 다음 번호 NC 가 0" "$LZ"
sed -i 's/^\*\*다음 번호: NC-0 · U-1\*\*$/**다음 번호: NC-1 · U-0**/' "$LZ/$LL"
lbite K3 "빈 표에서 다음 번호 U 가 0" "$LZ"
# K4 — 회차 절: 살아 있는 쪽의 회차 절 · 감사한 커밋 줄이 없는 회차 절 · 커밋 자리를 자리표시로 둔 회차 절
printf '\n## 회차 3 — `audit-quality` · 시험 (2026-10-29)\n\n- **감사한 커밋**: `abc1234`\n' >> "$LF/$LL"
lbite K4 "살아 있는 쪽의 회차 절"
ledit "$LH" '- **감사한 커밋**: 모름 · ' '- **감사자**: 모름 · '
lbite K4 "감사한 커밋 줄이 없는 회차 절"
ledit "$LH" '- **감사한 커밋**: `abc1234`' '- **감사한 커밋**: `<sha>`'
lbite K4 "번호를 채운 회차 절의 커밋 자리가 자리표시"
# 인자 — 거절하는 꼴은 아무것도 읽지 않고 종료 2 와 사용법 줄
for args in "a b" "-x" "--repo" "$LF/nope"; do
  set +e
  # shellcheck disable=SC2086
  python3 scripts/verify-ledger.py $args >"$BO" 2>&1; st=$?
  set -e
  if [ "$st" != 2 ] || grep -qE '^(PASS|FAIL)' "$BO" || ! grep -q '^사용법: python3 verify-ledger.py' "$BO" || crash; then
    echo "::error::verify-ledger.py 가 거절할 인자 '$args' 에 종료 2 · 사용법 줄이 아니거나 읽었다 (exit $st)"; cat "$BO"; exit 1
  fi
  SB=$((SB + 1))
done
# 대조군 — 저장소의 사본(이 저장소 모드) · 고정 대장 · 틀을 처음 베낀 대장(--repo) · 대장 없는 레포(--repo, 「대장 없음」)
LC=$(mktemp -d)
git ls-files -co --exclude-standard -z | tar --null -T - -cf - | tar -xf - -C "$LC"
git -C "$LC" init -q
keep "$LPASS" "저장소의 사본" python3 scripts/verify-ledger.py "$LC"
keep "${LPASS%NC*}NC 3 · 확인불가 2 · 회차 절 2 을 읽었다\$" "고정 대장" python3 scripts/verify-ledger.py "$LF"
LT=$(mktemp -d); lmake "$LT" fresh
keep "${LPASS%NC*}NC 0 · 확인불가 0 · 회차 절 0 을 읽었다\$" "틀을 처음 베낀 대장(--repo)" python3 scripts/verify-ledger.py --repo "$LT"
LN=$(mktemp -d); git -C "$LN" init -q; echo "대장 없음" > "$LN/README.md"
keep '^PASS verify-ledger\.py — 대장 없음' "대장 없는 레포(--repo)" python3 scripts/verify-ledger.py --repo "$LN"
sclose 33 4
echo "verify-ledger.py: 고정 대장의 변조본(찾기 · 읽기 · 상태 낱말 · 줄이 사는 표 · 번호 · 회차 절)과 거절 인자, 합 $SB 이 기대한 ID · 종료로 떨어지고, 대조군 $SK 이 PASS 줄로 지나감"

# ID 마다 변조본(조각 43 설계 ② B) — verify-ledger.py 가 찍을 수 있는 ID(r.fail("…"))마다 그 ID 를 기대하는 lbite 가 이 파일에 있다.
# 변조본: K4 의 lbite 를 다 지운 이 파일은 K4 를 「변조본 없음」으로 찍는다.
sopen "verify-ledger.py 의 ID 마다 변조본"
VLID='r\.fail\("([A-Z][0-9]?)"'
VLWANT='^lbite ([A-Z][0-9]?) '
gap=$(rgap scripts/verify-ledger.py "$VLID" "$R/scripts/bite-gates.sh" "$VLWANT")
if [ -n "$gap" ]; then echo "::error::$SEC — 변조본이 없는 ID: $gap"; exit 1; fi
SK=$((SK + 1))
grep -vE '^lbite K4 ' "$R/scripts/bite-gates.sh" > "$LF/cut.sh"
if [ "$(rgap scripts/verify-ledger.py "$VLID" "$LF/cut.sh" "$VLWANT")" != K4 ]; then
  echo "::error::$SEC — K4 의 변조본을 다 지운 목록이 「K4 변조본 없음」으로 떨어지지 않는다"; exit 1
fi
SB=$((SB + 1))
sclose 1 1

# 끝 — 절의 수(조각 41 설계 ② C). 절을 통째로 지운 사본은 여기서 떨어진다 — 절 안의 한 줄은 그 절의 sclose 가 본다.
if [ "$NSEC" != 36 ]; then
  echo "::error::변조본을 도는 절이 $NSEC 닫혔다 — 36 이어야 한다"; exit 1
fi
echo "변조 시험: 절 $NSEC 이 다 닫힘 — 절마다 센 수를 기대한 수와 견주고, 그 검사의 종료와 실패 줄(ID)로만 물었다고 세고, 대조군은 종료 0 과 PASS 줄을 봄"
