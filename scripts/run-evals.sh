#!/usr/bin/env bash
# 감사자 수트를 옳은 깃발로 돌리고, 실패한 회차의 기록을 남긴다.
#
#   ./scripts/run-evals.sh                          # 전부
#   ./scripts/run-evals.sh --case 'trap-*' --runs 5 # 골라서
#
# 깃발을 손으로 적지 않는 이유는 하나다. `--judge-model sonnet` 을 빠뜨리면
# **조용히 오검이 난다** — 기본 심판(haiku)은 이 수트의 감사 기록에서 아홉 번
# 어긋나는 동안 한 번도 맞지 않았고, trap-rollback-unproven 이 haiku 0.278 /
# sonnet 1.000 이다. 심판 모델은 케이스 파일에 못 적고 명령줄에만 있으므로,
# 기억에 맡기면 언젠가 빠진다.
#
# --scaffold 도 같다. 없으면 픽스처가 안 만들어져 빈 작업공간에서 돌고,
# 감사자는 볼 것이 없으니 함정도 안 밟는다 — 거짓 통과다.
#
# 실패 기록을 남기는 이유는 따로 있다. 결정론 그레이더는 증거를 안 남기고
# 임시 디렉터리는 지워진다. 그래서 **실패가 났는데 무엇이 샜는지 볼 수 없는**
# 일이 실제로 생겼다(gate-out-of-scope, 12회차 중 1회). 못 여는 발견은 닫을
# 수도 없다. 이 스크립트가 실패한 회차의 트레이스만 골라 결과 폴더에 옮긴다.
#
# **본문이 main() 안에 있는 이유.** bash 는 스크립트를 조금씩 읽어 가며 돈다.
# 돌고 있는 동안 이 파일을 고치면, 이어 읽는 자리가 어긋나 엉뚱한 줄을 명령으로
# 실행한다. 실제로 두 번 났다 — `line 48: -keep-temp: command not found` 와
# `line 52: jflag: unbound variable`. 둘 다 재현이 안 돼 한참 못 찾았다.
# 전체를 함수 하나로 감싸면 bash 가 **끝까지 읽은 뒤** 실행하므로 이 일이 없다.
set -euo pipefail

main() {

cd "$(dirname "$0")/.."

# 부르는 쪽이 -j · --model 을 줬는지 본다. 안 줬으면 아래에서 기본값을 박는다.
jflag=1
mflag=1
for a in "$@"; do
  case "$a" in
    --json|--json=*)
      echo "--json 은 이 스크립트가 쓴다. 결과 경로는 끝에 찍힌다." >&2; exit 2 ;;
    -j|-j=*|--concurrency|--concurrency=*)
      jflag=0 ;;
    --model|--model=*)
      mflag=0 ;;
  esac
done

# `claude plugin eval` 의 기본 동시성은 **1** 이다. 한 회차가 감사 한 번
# 전체(최대 60턴 · 파일 전수 · 250줄짜리 기록)라서, 13 케이스 × 3회를 직렬로
# 돌리면 두 시간이 든다. 실제로 그렇게 돌린 뒤에야 알았다.
#
# 넷으로 두는 이유: 같은 자격을 나눠 쓰므로 한 요금 한도에 걸리고, 여덟은
# 한도에 부딪혀 오히려 느려질 수 있다. 결과와 보고서는 케이스 순서를 지키므로
# 점수에는 영향이 없다. 재고 싶으면 -j 를 직접 줘라 — 그러면 이 기본값은 안 박는다.
CONC=()
if [ "$jflag" = 1 ]; then CONC=(-j 4); fi

# **모델을 박는다.** 안 박으면 회차는 돌리는 사람 계정의 기본 모델로 돈다 —
# 사람마다, 요금제마다, CI 와 로컬이 서로 다른 모델을 재게 된다. 이 수트의
# 트리거 숫자(README 「트리거 정확도」)는 전부 claude-sonnet-5 로 쟀으므로
# 같은 모델로 재야 견줄 수 있다. 다른 모델로 재고 싶으면 --model 을 직접 줘라.
# 실제로 그 모델로 돌았는지는 아래 결과 정리에서 트레이스를 읽어 찍는다.
MODEL=()
if [ "$mflag" = 1 ]; then MODEL=(--model claude-sonnet-5); fi

# 돌기 전에 수트가 물 수 있는 모양인지, 그레이더가 가르기는 하는지부터 본다.
python3 scripts/verify-evals.py
python3 scripts/verify-graders.py

OUT="vibe-audit/evals/results/$(date -u +%Y-%m-%dT%H-%M-%SZ)"
mkdir -p "$OUT"

set +e
claude plugin eval ./vibe-audit \
  --scaffold \
  --trust-plugin \
  --judge-model sonnet \
  --no-publish \
  --keep-temp \
  --output-dir "$OUT" \
  --json "$OUT/result.json" \
  "${CONC[@]}" \
  "${MODEL[@]}" \
  "$@"
status=$?
set -e

# 실패한 회차의 트레이스만 남기고 임시 디렉터리는 지운다.
python3 - "$OUT" "$@" <<'PY'
import json, pathlib, re, shutil, sys

out = pathlib.Path(sys.argv[1])
argv = sys.argv[2:]
res = out / "result.json"
# 결과 파일이 없으면 실패다. 하네스가 exit 0 으로 끝나고 파일을 안 쓰면 아래
# 「한 케이스도 안 돌았다」 검사까지 닿지도 않고, 러너는 하네스의 0 을 그대로
# 돌려준다 — 점수 하나 없이 초록이 난다(Codex 리뷰가 짚었고, 가짜 하네스로 재현했다).
if not res.exists():
    print(f"\nFAIL 결과 파일이 없다: {res}")
    print("     하네스가 무엇을 돌렸는지 알 수 없다. 안 돌린 것을 통과로 세지 않는다.")
    raise SystemExit(4)

d = json.loads(res.read_text(encoding="utf-8"))

# 한 케이스도 안 돌았으면 실패다. `--case` 가 아무것도 못 맞히면 하네스는
# 조용히 exit 0 으로 끝난다 — 이 저장소가 막으려는 바로 그 모양이다.
# 실제로 `--case '{a,b}'` 로 났다. 중괄호는 글롭이 아니다.
if not d.get("cases"):
    print("\nFAIL 한 케이스도 안 돌았다 — --case 가 아무것도 못 맞혔을 수 있다.")
    print("     안 돌린 것을 통과로 세지 않는다.")
    raise SystemExit(3)

# **고른 케이스가 전부, 회차 수대로 돌았는지 본다.** 위는 「하나도 안 돌았다」만
# 잡는다. 하네스가 고른 것 가운데 하나를 조용히 빠뜨리거나 with 팔 회차를 안 내면,
# 남은 케이스만으로 통과하고 그 입력이 캐시에 「통과」로 남는다(Codex 리뷰).
import fnmatch
# `--ablation` 을 안 주면 하네스는 대상 경로에서 플러그인을 찾아 **두 팔**(with-without)로
# 돈다. 그때는 without 팔도 회차 수대로 있어야 한다 — 없으면 대조 실험이 말없이 한 팔
# 실험이 된다(Codex 리뷰).
pats, want, ablation = [], None, "with-without"
for i, a in enumerate(argv):
    if a == "--case" and i + 1 < len(argv):
        pats.append(argv[i + 1])
    elif a.startswith("--case="):
        pats.append(a.split("=", 1)[1])
    elif a == "--runs" and i + 1 < len(argv):
        want = int(argv[i + 1])
    elif a.startswith("--runs="):
        want = int(a.split("=", 1)[1])
    elif a == "--ablation" and i + 1 < len(argv):
        ablation = argv[i + 1]
    elif a.startswith("--ablation="):
        ablation = a.split("=", 1)[1]
suite = pathlib.Path("vibe-audit/evals")
chosen = sorted(c.parent.name for c in suite.glob("*/case.yaml")
                if not pats or any(fnmatch.fnmatchcase(c.parent.name, p) for p in pats))
got = {c.get("name"): len(((c.get("arms") or {}).get("with") or [])) for c in d.get("cases", [])}
short = [f"{n} (결과에 없음)" for n in chosen if n not in got]
short += [f"{n} (with 회차 {got[n]}{'' if want is None else f' / {want}'})"
          for n in chosen if n in got and (got[n] == 0 or (want is not None and got[n] != want))]
if ablation != "none":
    wo = {c.get("name"): len(((c.get("arms") or {}).get("without") or [])) for c in d.get("cases", [])}
    short += [f"{n} (without 회차 {wo[n]} / {want if want is not None else got[n]} — --ablation {ablation})"
              for n in chosen if n in got and wo[n] != (want if want is not None else got[n])]
# **디스크에 적힌 그레이더가 회차마다 다 채점됐는지도 본다.** 아래의 필수 그레이더
# 판정은 결과가 적은 이름에서 출발하므로, 하네스가 그레이더를 조용히 빠뜨리면
# `graders: []` 인 만점 회차가 아무것도 안 재고 통과해 캐시에 남는다(Codex 리뷰).
byname = {c.get("name"): c for c in d.get("cases", [])}
for n in chosen:
    if n not in got:
        continue
    need = {p.stem for p in (suite / n / "graders").glob("*.md")}
    for i, run in enumerate((byname[n].get("arms") or {}).get("with") or [], 1):
        # 시작을 못 한 회차(픽스처 실패 · 실행 불가)는 하네스가 `error` 와 점수 0 ·
        # `graders: []` 로 낸다. 점수로 이미 떨어지니 여기서 3 으로 덮지 않는다 —
        # 덮으면 아래의 한도(6) 판정을 가린다.
        if run.get("error") and not run.get("score"):
            continue
        miss = sorted(need - {g.get("name") for g in run.get("graders", [])})
        if miss:
            short.append(f"{n} run{i} (채점 안 된 그레이더: {', '.join(miss)})")
if short:
    print("\nFAIL 고른 케이스가 다 돌지 않았다 — 안 돌린 것을 통과로 세지 않는다.")
    for s in short:
        print(f"     {s}")
    raise SystemExit(3)

kept, temps = 0, set()
limited = []
# 한도 문구는 **답의 머리에 온 것만** 센다. 「rate limit」 같은 말은 감사 기록이 정상으로
# 쓰는 낱말이다 — 로그인 라우트에 rate limit 이 없다는 발견이 한도로 읽혀 멀쩡한 실행이
# 6 으로 끝난다(Codex 리뷰). 한도에 걸린 세션은 그 문구 한 줄만 답한다.
LIMIT = re.compile(r"\s*(?:You['’]ve hit your (?:\w+ )?limit|You have hit your (?:\w+ )?limit"
                   r"|Claude AI usage limit reached)", re.I)

# 회차가 **실제로** 어느 모델로 돌았는지 트레이스에서 읽는다. result.json 에는
# 모델이 없고, 통과한 회차의 트레이스는 아래에서 지워지므로 지금 읽어 둔다.
# 감사자(`model: inherit`)가 부른 모델도 같은 modelUsage 에 잡힌다.
import collections
models = collections.Counter()
for case in d.get("cases", []):
    for runs in (case.get("arms") or {}).values():
        for run in runs:
            tp = run.get("tracePath")
            seen = set()
            try:
                for line in open(tp, encoding="utf-8"):
                    if '"modelUsage"' not in line:
                        continue
                    try:
                        seen |= set((json.loads(line).get("modelUsage") or {}).keys())
                    except ValueError:
                        pass
            except (OSError, TypeError):
                seen = {"(트레이스 없음)"}
            for m in (seen or {"(기록 없음)"}):
                models[m] += 1
print("모델: " + " · ".join(f"{m} {n}회" for m, n in models.most_common()))

# 케이스별 점수부터 찍는다. 이게 없으면 result.json 을 매번 손으로 파야 한다.
# 팔이 둘일 때 with 만 보지 않는 이유: without(플러그인 없는 팔)이 함께 떨어져야
# 이 케이스가 재는 것이 모델의 기본값이 아니라 **플러그인의 문구**임이 선다.
for case in d.get("cases", []):
    ag = case.get("aggregates") or {}
    line = f"=== {case.get('name')} → {ag.get('score', 0):.3f}"
    if ag.get("scoreWithout") is not None:
        line += f"   (플러그인 없이 {ag['scoreWithout']:.3f} · Δ {ag.get('delta', 0):+.3f})"
    print(line)
    for arm, runs in (case.get("arms") or {}).items():
        if arm != "with":
            continue
        for i, run in enumerate(runs, 1):
            bad = [g["name"] for g in run.get("graders", []) if not g.get("passed")]
            mark = "전부 통과" if not bad else "FAIL " + ", ".join(bad)
            print(f"  run{i} score={run.get('score', 0):.2f}  {mark}")
print()
# **결정론 그레이더가 모든 회차에서 떨어졌으면 실패다 — 문턱과 따로.**
# 문턱은 케이스 점수(회차 평균)에 걸린다. 그래서 무게가 가벼운 그레이더는 매번
# 떨어져도 문턱을 넘는다 — gate-out-of-scope 의 handoff-named(무게 1/6)는 세 회차
# 전부 떨어져도 0.833 으로 전수 문턱 0.8 을 넘었고, cycle-continuity 는 그레이더가
# 일곱이라 어느 하나를 무겁게 해도 셈이 안 맞는다(Codex 리뷰). 전수의 0.8 이 봐주려는
# 것은 **흔들림**(심판의 갈림 · 감사자의 한 회차)이지 매번 나는 회귀가 아니다.
# 정규식 · tool_used 는 같은 기록에 늘 같은 답을 내므로, 모든 회차에서 떨어졌다면
# 그것은 감사자가 매번 그렇게 했다는 뜻이다. 심판(llm)은 넣지 않는다 — 심판이
# 틀린 일이 이 수트에 실제로 있었다(README 「심판이 못 믿을 자리였다」).
steady, steady_cases = [], set()
for case in d.get("cases", []):
    kinds = {g.get("name"): g.get("type") for g in case.get("graders", [])}
    runs = (case.get("arms") or {}).get("with") or []
    if not runs:
        continue
    for name, kind in kinds.items():
        if kind not in ("regex", "tool_used"):
            continue
        marks = [g for run in runs for g in run.get("graders", []) if g.get("name") == name]
        # auditor-fired 는 **한 회차라도** 떨어지면 실패다. 이것은 품질이 아니라 그 회차가
        # 플러그인을 쟀는지의 전제다 — 감사자가 안 뜬 회차는 본 세션이 흉내 낸 답을 채점한
        # 것이고, 그 점수가 평균에 섞인다. 게다가 두 팔로 돌면(--ablation 기본) 이
        # 그레이더는 with-only 라 점수에서 빠져(scored: false) 아무도 안 물었다(Codex 리뷰).
        # 그래서 이것만은 scored 를 보지 않는다.
        if name == "auditor-fired":
            missed = sum(1 for g in marks if not g.get("passed"))
            if missed:
                steady.append(f"{case.get('name')}/{name} ({missed}/{len(runs)} 회차 — 감사자가 안 떴다)")
                steady_cases.add(case.get("name"))
            continue
        if len(marks) == len(runs) and all(g.get("scored", True) and not g.get("passed") for g in marks):
            steady.append(f"{case.get('name')}/{name} ({len(runs)}/{len(runs)} 회차)")
            steady_cases.add(case.get("name"))
# 이 판정은 트레이스를 치우기 **전에** 내린다. 그런 회차는 점수로는 통과(passed)라
# 아래 보존 고리가 건너뛰고 임시 디렉터리째 지워져, 실패 산출물에 증거가 없었다
# (Codex 리뷰). 그 케이스의 회차는 실패한 회차로 보고 트레이스를 남긴다.

for case in d.get("cases", []):
    for arm, runs in (case.get("arms") or {}).items():
        for i, run in enumerate(runs, 1):
            tp = run.get("tracePath")
            if tp:
                temps.add(pathlib.Path(tp).parent.parent)
            if not tp or not pathlib.Path(tp).exists():
                continue
            src = pathlib.Path(tp)
            # **한도는 통과한 회차에서도 찾는다.** 한도에 걸린 세션은 아무 도구도 안
            # 부르므로, 음성 그레이더만 가진 케이스(route-quiet)는 그 회차가 통과로
            # 채점된다. 실패한 회차에서만 찾으면 한도에 걸린 실행이 0 으로 끝나 캐시에
            # 통과로 남는다(Codex 리뷰). 걸린 회차는 증거로 트레이스도 남긴다.
            hit = False
            try:
                for line in open(src, encoding="utf-8"):
                    if '"result"' not in line:
                        continue
                    try:
                        e = json.loads(line)
                    except ValueError:
                        continue
                    if e.get("type") == "result":
                        hit = bool(LIMIT.match(str(e.get("result") or "")))
            except OSError:
                pass
            if hit:
                limited.append(f"{case['name']}.{arm}.run{i}")
            held = (arm == "with" and case.get("name") in steady_cases) or hit
            if run.get("passed") and not held:
                continue
            dst = out / "traces" / f"{case['name']}.{arm}.run{i}.jsonl"
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            kept += 1
            bad = [g["name"] for g in run.get("graders", []) if not g.get("passed")]
            print(f"  실패 기록 남김 {dst}  ({', '.join(bad)})")
            # **무엇을 했는지 로그에도 찍는다.** 트레이스는 산출물로 올라가지만, 산출물을
            # 못 받는 자리(네트워크가 막힌 세션)에서는 CI 로그가 전부다. route-contract 가
            # CI 에서 한 번 안 떴을 때 실제로 그랬다 — 무엇을 대신 했는지 볼 길이 없었다.
            # 부른 도구(최상위만, 감사자 안의 호출은 빼고)와 마지막 답의 머리를 찍는다.
            calls, last = [], ""
            try:
                for line in open(src, encoding="utf-8"):
                    try:
                        e = json.loads(line)
                    except ValueError:
                        continue
                    if e.get("type") == "result":
                        last = str(e.get("result") or "")
                    if e.get("type") != "assistant" or e.get("parent_tool_use_id"):
                        continue
                    for b in (e.get("message") or {}).get("content") or []:
                        if b.get("type") != "tool_use":
                            continue
                        inp = b.get("input") or {}
                        what = inp.get("subagent_type") or inp.get("skill") or ""
                        calls.append(f"{b.get('name')}({what})" if what else str(b.get("name")))
            except OSError:
                pass
            print(f"     부른 도구: {' → '.join(calls) or '(없음)'}")
            print(f"     마지막 답: {' '.join(last.split())[:300] or '(없음)'}")

# --keep-temp 로 남는 작업공간을 치운다. 모드가 닫혀 있어 그냥 지우면 조용히
# 실패하므로(하네스가 경고하는 자리) 먼저 열고 지운다. 남기는 것은 위에서 이미
# 결과 폴더로 복사한 실패 트레이스뿐이다.
import os, stat
for t in temps:
    if not (t.name.startswith("claude-eval-") and t.parent == pathlib.Path("/tmp")):
        continue
    # 남긴 디렉터리 **자체**부터 연다. 하네스는 그것을 읽기 전용으로 남기므로
    # 안의 항목만 열면 목록은 읽혀도 지울 수가 없다. root 로 돌면 권한이 안
    # 걸려 드러나지 않았고, CI(root 아님)에서 회차마다 「치우지 못했다」로 났다.
    try:
        os.chmod(t, stat.S_IRWXU)
    except OSError:
        pass
    for root, dirs, files in os.walk(t):
        for n in dirs + files:
            try:
                os.chmod(os.path.join(root, n), stat.S_IRWXU)
            except OSError:
                pass
    shutil.rmtree(t, ignore_errors=True)
    if t.exists():
        print(f"  치우지 못했다: {t}")

print(f"\n결과: {out}")
print(f"  result.json · report.html" + (f" · traces/ ({kept}건)" if kept else "  (실패 없음)"))

# **사용량 한도에 걸린 회차는 판정이 아니다.** 한도에 걸리면 세션은 아무 도구도 안
# 부르고 「한도에 걸렸다」만 답한다 — 채점은 그것을 「감사자가 안 떴다」로 센다.
# 실제로 CI 에서 route 여섯이 3/3 「회귀」로 떨어졌는데 원인은 주간 한도였다.
# 회귀로 읽히지 않도록 따로 찍고 따로 끝낸다(종료코드 6).
if limited:
    print(f"\nFAIL 사용량 한도에 걸린 회차가 {len(limited)}개 — 이 실행의 점수는 판정이 아니다.")
    for s in limited[:5]:
        print(f"     {s}")
    print("     한도가 풀린 뒤 다시 돌려라.")
    raise SystemExit(6)

if steady:
    print("\nFAIL 결정론 그레이더가 모든 회차에서 떨어졌거나, 감사자가 뜨지 않은 회차가 있다.")
    for s in steady:
        print(f"     {s}")
    print("     케이스 점수가 문턱을 넘었어도 통과로 세지 않는다.")
    raise SystemExit(5)
PY

  exit $status
}

main "$@"
