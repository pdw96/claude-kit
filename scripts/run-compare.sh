#!/usr/bin/env bash
# 맞대기 러너 — 같은 재료 열을 팔 하나로 돌리고, 케이스마다 맞힌 회차 · 떴는가 · 모델 · 비용을 찍는다.
#
#   ./scripts/run-compare.sh vibe-audit                              # 이 작업트리의 vibe-audit
#   ./scripts/run-compare.sh none                                    # 플러그인 없음 — 중립 요청 그대로
#   ./scripts/run-compare.sh pr-review-toolkit --from <클론>          # anthropics/claude-plugins-official 클론
#   ./scripts/run-compare.sh claude-security --from <클론> --case 'trap-*' --runs 1
#
# **왜 따로 있나.** 조각 51 · ADR 0066 의 5. `run-evals.sh` 는 고정한 러너이고 수트 지문에 든다 — 고치면
# 재는 대상(감사자)이 그대로인데 route 수트가 돈다. 이 러너는 수트 밖(`compare/`)만 읽어 지문에 들지 않는다.
# 깃발을 기억에 맡기지 않는 까닭은 `run-evals.sh` 머리 주석과 같다 — 수트 모델 · 심판 · 픽스처를 여기서 박는다.
#
# **무엇을 보장하나.** `docs/slices/51-head-to-head/design.md` ② A ~ H. 재료 열은 `compare/cases.tsv`,
# 팔은 같은 설계 ③ B. 하네스 밖 팔(claude-security)은 조각 52 설계 ② A ~ F 가 더한다 — 정답지를 건네지 않고,
# 새는 길을 센다. 이 러너는 측정 도구이고 게이트가 아니다 — **종료는 판정이 아니다.** 하네스는 문턱을 받지
# 않으면 1.0 을 써서 한 회차라도 못 맞히면 1 로 끝나고, 하네스 밖 길도 같은 규칙으로 0 · 1 을 낸다. 러너는 그
# 종료를 그대로 돌려줄 뿐이고, 판정은 끝 표로 사람이 낸다(ADR 0066 의 4).
#
# 표준 라이브러리만 쓴다.
set -euo pipefail

main() {

cd "$(dirname "$0")/.."

PIN=a7ba5b93db0c7c8d17f3f1d25853adca79598a1a   # anthropics/claude-plugins-official, 2026-10-30
USAGE="사용법: run-compare.sh <vibe-audit|none|pr-review-toolkit|claude-security> [--from <클론>] [--case <글롭>] [--runs <n>] [-j <n>]"

arm=${1:-}
case "$arm" in
  vibe-audit) cap=10 ;;
  none) cap=5 ;;
  pr-review-toolkit) cap=12 ;;
  claude-security) cap=8 ;;
  *) echo "$USAGE" >&2; exit 2 ;;
esac
shift

from=""
pass=()
jflag=1
while [ $# -gt 0 ]; do
  case "$1" in
    --from) from=${2:-}; shift 2 || { echo "$USAGE" >&2; exit 2; } ;;
    --from=*) from=${1#--from=}; shift ;;
    --model|--model=*|--ablation|--ablation=*|--eval-dir|--eval-dir=*|--json|--json=*|--max-cost-usd|--max-cost-usd=*|--judge-model|--judge-model=*|--allow-tools|--allow-tools=*|--disallow-tools|--disallow-tools=*)
      echo "${1%%=*} 은 이 러너가 박는다 — 팔 사이에 같아야 한다(설계 ② B ~ F)" >&2; exit 2 ;;
    -j|-j=*|--concurrency|--concurrency=*) jflag=0; pass+=("$1"); shift ;;
    *) pass+=("$1"); shift ;;
  esac
done

# 경쟁 팔은 고정한 커밋의 클론만 받는다(② E). vibe-audit 팔은 이 작업트리의 것, none 팔은 빈 플러그인이다.
# 팔마다 따로 돈다 — 하네스의 기준 팔(with-without)은 플러그인 팔과 같은 요청을 받으므로 쓰지 않는다(ADR 0067).
ablation=none
if [ "$arm" = vibe-audit ] || [ "$arm" = none ]; then
  [ -z "$from" ] || { echo "$arm 팔은 --from 을 받지 않는다" >&2; exit 2; }
  src=vibe-audit
else
  [ -n "$from" ] || { echo "$arm 팔은 --from <anthropics/claude-plugins-official 클론> 이 있어야 한다" >&2; exit 2; }
  head=$(git -C "$from" rev-parse HEAD 2>/dev/null || true)
  [ "$head" = "$PIN" ] || { echo "클론의 HEAD 가 $PIN 이 아니다 (받은 것: '${head:-읽지 못함}')" >&2; exit 2; }
  src="$from/plugins/$arm"
  [ -f "$src/.claude-plugin/plugin.json" ] || { echo "플러그인이 없다: $src" >&2; exit 2; }
fi

# 수트 모델은 run-evals.sh 한 곳이 든다(② D).
MODEL=$(sed -n 's/^DEFAULT_MODEL=//p' scripts/run-evals.sh)
[ -n "$MODEL" ] || { echo "scripts/run-evals.sh 에서 DEFAULT_MODEL 을 읽지 못했다" >&2; exit 2; }

# 임시 폴더에 플러그인과 재료를 엮는다(② A · B). 픽스처는 출처 케이스의 것, 프롬프트는 축의 것을 그대로 복사한다.
TMP=$(mktemp -d)
# 재료(정답지 · 요청 · 픽스처)가 놓이는 자리. 하네스 팔은 하네스가 대상 플러그인 안의 `compare/` 를 읽으므로
# 플러그인 안이다. 하네스 밖 팔은 `--plugin-dir` 로 플러그인만 넘기므로 따로 둔 폴더다 — 정답지를 건네지
# 않는다(조각 52 설계 ② A · NC-29). 플러그인과 같은 부모에도 두지 않는다.
MAT=$(mktemp -d)
trap 'rm -rf "$TMP" "$MAT"' EXIT
plug="$TMP/$arm"
if [ "$arm" = claude-security ]; then mat="$MAT"; else mat="$plug"; fi
if [ "$arm" = none ]; then
  # 플러그인 없음 — 하네스가 대상으로 받을 빈 플러그인. 에이전트 · 스킬 · 훅이 없다.
  mkdir -p "$plug/.claude-plugin"
  printf '{"name": "none", "version": "0.0.0", "description": "맞대기의 플러그인 없음 팔"}\n' > "$plug/.claude-plugin/plugin.json"
else
  cp -R "$src" "$plug"
fi
rm -rf "$plug/evals" "$plug/recall" "$plug/compare"
mkdir -p "$mat/compare"
n=0
while IFS=$'\t' read -r name source axis rival; do
  case "$name" in ''|'#'*) continue ;; esac
  # 경쟁 팔 칸은 쉼표로 여럿을 들 수 있다 — 한 케이스를 두 경쟁 팔이 돈다(조각 52 · ADR 0070).
  [ "$arm" = vibe-audit ] || [ "$arm" = none ] || case ",$rival," in *",$arm,"*) ;; *) continue ;; esac
  for f in "compare/$name/case.yaml" "compare/$name/graders/found.md" "compare/prompts/$axis.md" "$source/fixture.sh"; do
    [ -f "$f" ] || { echo "재료가 없다: $f" >&2; exit 2; }
  done
  mkdir -p "$mat/compare/$name"
  cp "compare/$name/case.yaml" "$mat/compare/$name/"
  cp -R "compare/$name/graders" "$mat/compare/$name/"
  # 요청 본문은 축의 것 그대로(② B). 플러그인 팔은 그 도구를 부르는 한 줄을 머리에 붙인다(compare/arms.tsv · ADR 0067).
  call=$(awk -F'\t' -v a="$arm" -v x="$axis" '$1 == a && ($2 == x || $2 == "*") { print $3; exit }' compare/arms.tsv)
  if [ "$arm" != none ] && [ -z "$call" ]; then echo "compare/arms.tsv 에 $arm · $axis 줄이 없다" >&2; exit 2; fi
  awk -v call="$call" '{ print } /^---$/ && ++n == 2 && call != "" { print ""; print call }' \
    "compare/prompts/$axis.md" > "$mat/compare/$name/prompt.md"
  cp "$source/fixture.sh" "$mat/compare/$name/fixture.sh"
  n=$((n + 1))
done < compare/cases.tsv
[ "$n" -gt 0 ] || { echo "$arm 팔의 케이스가 없다" >&2; exit 2; }

OUT="compare/results/$(date -u +%Y-%m-%dT%H-%M-%SZ)-$arm"
mkdir -p "$OUT"
# 동시성도 run-evals.sh 한 곳이 든다 — 같은 자격 · 같은 요금 한도를 나눠 쓰는 까닭이 같다.
CONC=()
if [ "$jflag" = 1 ]; then
  read -r -a CONC <<< "$(sed -n 's/^if \[ "\$jflag" = 1 \]; then CONC=(\(.*\)); fi$/\1/p' scripts/run-evals.sh)"
  [ "${#CONC[@]}" -gt 0 ] || { echo "scripts/run-evals.sh 에서 동시성을 읽지 못했다" >&2; exit 2; }
fi

echo "팔 $arm · 케이스 $n · 모델 $MODEL · ablation $ablation · 천장 \$$cap"
set +e
if [ "$arm" = claude-security ]; then
  # **claude-security 는 하네스 밖에서 돈다(ADR 0068).** 하네스의 격리 안에서는 스킬의 셸 전처리(`!` 명령)가
  # 읽기 전용 임시 경로에 작업 위치 파일을 쓰지 못해 스킬이 서지 않는다(설계 끝 「PR B 에서 정한 것」).
  # 같은 재료 · 같은 요청 · 같은 모델 · 같은 도구로 `claude -p` 를 부르고, 같은 그레이더 글을 같은 심판 모델에
  # 세 번 물어 다수로 가른다. 결과는 하네스와 같은 꼴의 result.json 이라 아래 정리가 그대로 읽는다.
  python3 - "$OUT" "$plug" "$mat" "$MODEL" "$cap" "${pass[@]}" <<'OUTSIDE'
import json, os, pathlib, re, shutil, subprocess, sys, tempfile

out, plug, mat = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), pathlib.Path(sys.argv[3])
model, cap = sys.argv[4], float(sys.argv[5])
pats, want, rest = [], None, sys.argv[6:]
it = iter(rest)
for a in it:
    if a == "--case":
        pats.append(next(it, ""))
    elif a.startswith("--case="):
        pats.append(a.split("=", 1)[1])
    elif a == "--runs":
        want = int(next(it, "0"))
    elif a.startswith("--runs="):
        want = int(a.split("=", 1)[1])
    elif a in ("-j", "--concurrency"):
        next(it, None)
    elif a.startswith(("-j=", "--concurrency=")):
        pass
    else:
        print(f"하네스 밖 팔은 --case · --runs 만 받는다 (받은 것: {a})", file=sys.stderr)
        raise SystemExit(2)

import fnmatch
cases = sorted(d for d in (mat / "compare").iterdir() if d.is_dir()
               and (not pats or any(fnmatch.fnmatchcase(d.name, p) for p in pats)))
if not cases:
    print("한 케이스도 고르지 못했다", file=sys.stderr)
    raise SystemExit(3)

# 이 세션의 설정 · 플러그인이 섞이지 않게 빈 HOME 과 필요한 변수만 넘긴다.
KEEP = ("PATH", "TERM", "HTTPS_PROXY", "https_proxy", "NO_PROXY", "no_proxy", "NODE_EXTRA_CA_CERTS",
        "SSL_CERT_FILE", "CLAUDE_CODE_OAUTH_TOKEN", "ANTHROPIC_API_KEY")
def env(home):
    e = {k: os.environ[k] for k in KEEP if k in os.environ}
    e.update(HOME=home, LANG="C.UTF-8")
    return e

def split(md):
    parts = md.split("---", 2)
    return parts[1], parts[2].lstrip("\n")

def last_result(path):
    res = None
    for line in open(path, encoding="utf-8"):
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "result":
            res = ev
    return res or {}

# 정답지 낱말 — 재료 폴더에만 있고 픽스처 · 요청 본문에는 없는 글(조각 52 설계 ③ B 의 닫힌 목록).
LEAK = ("case.yaml", "found.md", "expected_outcome", str(mat))


def keep_sessions(home, dest):
    """회차의 임시 HOME 에 CLI 가 쓴 세션 기록(`.claude/projects/` 아래 *.jsonl — 하위 에이전트 것 포함)을
    결과 폴더로 옮긴다(설계 ② B · ③ C). 옮긴 파일과, 그 가운데 프로젝트 폴더 바로 아래가 아닌 것(하위 기록)의 수."""
    src = pathlib.Path(home) / ".claude" / "projects"
    kept, sub = [], 0
    for f in sorted(src.rglob("*.jsonl")) if src.is_dir() else []:
        rel = f.relative_to(src)
        to = dest / rel
        to.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(f, to)
        kept.append(to)
        sub += len(rel.parts) > 2
    return kept, sub


def leak_hits(paths):
    """주 트레이스와 세션 기록에서 정답지 낱말이 나온 자리 — 「파일: 낱말」 목록."""
    hits = []
    for pth in paths:
        try:
            text = pth.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        hits += [f"{pth.relative_to(out)}: {w}" for w in LEAK if w in text]
    return hits


def sub_calls(trace):
    """주 트레이스가 하위 실행(Agent · Task · Workflow)을 부른 수 — 하위 기록이 남았는지 견줄 자리."""
    n = 0
    try:
        lines = open(trace, encoding="utf-8")
    except OSError:
        return 0
    for line in lines:
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        msg = ev.get("message")
        for block in (msg.get("content") or []) if isinstance(msg, dict) else []:
            n += isinstance(block, dict) and block.get("type") == "tool_use" and block.get("name") in ("Agent", "Task", "Workflow")
    return n


spent, results, all_passed = 0.0, [], True
(out / "traces").mkdir(parents=True, exist_ok=True)

def dump(extra=None):
    """돈 회차를 그때그때 남긴다 — 뒤의 회차가 어떻게 끝나든 이미 쓴 측정이 버려지지 않는다."""
    cases_out = results + ([extra] if extra else [])
    (out / "result.json").write_text(json.dumps({"cases": cases_out}, ensure_ascii=False, indent=1), encoding="utf-8")

for case in cases:
    front, body = split((case / "prompt.md").read_text(encoding="utf-8"))
    tools = re.search(r"^allowed_tools:\s*\[(.*)\]\s*$", front, re.M).group(1)
    tools = [x.strip() for x in tools.split(",") if x.strip()] + ["Bash", "Write"]
    timeout = int(re.search(r"^timeout_seconds:\s*(\d+)", front, re.M).group(1))
    n = want or int(re.search(r"^runs:\s*(\d+)", front, re.M).group(1))
    _, rubric = split((case / "graders" / "found.md").read_text(encoding="utf-8"))
    runs = []
    for i in range(1, n + 1):
        trace = out / "traces" / f"{case.name}.with.run{i}.jsonl"
        if spent >= cap:
            runs.append({"score": 0.0, "passed": False, "error": f"비용 천장 ${cap} 에 닿아 돌지 않았다", "graders": []})
            all_passed = False
            continue
        with tempfile.TemporaryDirectory() as ws, tempfile.TemporaryDirectory() as home:
            if subprocess.run(["bash", str(case / "fixture.sh")], cwd=ws, stdout=subprocess.DEVNULL).returncode:
                runs.append({"score": 0.0, "passed": False, "error": "픽스처가 실패했다 — 회차를 돌리지 않았다", "graders": []})
                all_passed = False
                dump({"name": case.name, "arms": {"with": runs}})
                continue
            cmd = ["claude", "-p", body, "--plugin-dir", str(plug), "--model", model, "--permission-mode", "dontAsk",
                   "--allowedTools", *tools, "--output-format", "stream-json", "--verbose",
                   "--max-budget-usd", f"{cap - spent:.2f}"]
            err = None
            try:
                with open(trace, "w", encoding="utf-8") as f:
                    rc = subprocess.run(cmd, cwd=ws, env=env(home), stdout=f, stderr=subprocess.PIPE,
                                        text=True, timeout=timeout).returncode
                if rc:
                    err = f"exit {rc}"
            except subprocess.TimeoutExpired:
                err = f"{timeout}초 안에 끝나지 않았다"
            res = last_result(trace)
            spent += res.get("total_cost_usd") or 0.0
            final = res.get("result") or ""
            # 새는 길 — 심판을 부르기 전에(심판도 같은 HOME 에 기록을 쓴다) 회차의 기록을 옮기고 낱말을 센다.
            kept, sub_records = keep_sessions(home, out / "sessions" / f"{case.name}.run{i}")
            seen = {"leakHits": leak_hits([trace, *kept]), "sessionFiles": len(kept),
                    "subRecords": sub_records, "subCalls": sub_calls(trace)}
            # 심판 — 같은 그레이더 글을 같은 심판 모델(sonnet)에 세 번 묻는다. 도구는 없다.
            # 표마다 남은 천장을 넘기고, 천장에 닿거나 심판이 답하지 않으면 채점 못 함으로 남긴다 —
            # 탐지 실패와 가른다. 회차 실행이 이미 실패했으면 심판을 부르지 않는다.
            ask = (f"{rubric}\n\n## 판정할 최종 응답\n\n<<<\n{final}\n>>>\n\n"
                   "위 질문에 PASS 또는 FAIL 한 낱말로만 답하세요.")
            votes, grade_err, judge_cost = [], None, 0.0
            for _ in range(3 if final and not err else 0):
                if spent >= cap:
                    grade_err = f"비용 천장 ${cap} 에 닿아 채점을 마치지 못했다"
                    break
                try:
                    j = subprocess.run(["claude", "-p", ask, "--model", "sonnet", "--tools", "", "--output-format", "json",
                                        "--max-budget-usd", f"{cap - spent:.2f}"],
                                       cwd=ws, env=env(home), capture_output=True, text=True, timeout=300)
                except subprocess.TimeoutExpired:
                    grade_err = "심판이 300초 안에 답하지 않았다"
                    break
                try:
                    jr = json.loads(j.stdout)
                except ValueError:
                    jr = {}
                c = jr.get("total_cost_usd") or 0.0
                spent += c
                judge_cost += c
                # 읽을 수 있는 판정만 표로 센다 — 심판이 실패했거나(종료 · 자격 · 천장) 답에 PASS · FAIL 이 없으면
                # 그 회차는 채점되지 않은 것이다. FAIL 로 세면 탐지 실패로 둔갑한다.
                m = re.search(r"\b(PASS|FAIL)\b", jr.get("result") or "") if j.returncode == 0 and not jr.get("is_error") else None
                if not m:
                    grade_err = f"심판이 판정을 내지 못했다 (종료 {j.returncode})"
                    break
                votes.append(m.group(1) == "PASS")
        if grade_err:
            err = f"채점 못 함 — {grade_err}" + (f" (그 전 표 {len(votes)})" if votes else "")
        passed = bool(final) and not err and sum(votes) >= 2
        all_passed &= passed
        run = {"score": 1.0 if passed else 0.0, "passed": passed, "tracePath": str(trace), "judgeCostUsd": judge_cost, **seen,
               "graders": [{"name": "found", "passed": passed, "weight": 1, "scored": True, "judgeVotes": votes,
                            "explanation": "하네스 밖 심판(sonnet) votes: " + " ".join("PASS" if v else "FAIL" for v in votes)}]}
        if err:
            run["error"] = err
        runs.append(run)
        dump({"name": case.name, "arms": {"with": runs}})
        print(f"{case.name} run{i} → {'PASS' if passed else 'FAIL'}{' · ' + err if err else ''} · 비용 누계 ${spent:.4f}", flush=True)
    results.append({"name": case.name, "arms": {"with": runs}})

dump()
raise SystemExit(0 if all_passed else 1)
OUTSIDE
  status=$?
else
claude plugin eval "$plug" \
  --eval-dir compare \
  --scaffold \
  --trust-plugin \
  --judge-model sonnet \
  --no-publish \
  --keep-temp \
  --output-dir "$OUT" \
  --json "$OUT/result.json" \
  --model "$MODEL" \
  --ablation "$ablation" \
  --max-cost-usd "$cap" \
  --allow-tools Bash Write \
  "${CONC[@]}" \
  "${pass[@]}" 2>&1 | grep --line-buffered -v '^⚠ kept /tmp/claude-eval-'
status=${PIPESTATUS[0]}
fi
set -e

# 회차마다 맞힘 · 떴는가 · 모델 · 비용을 트레이스에서 읽고, 최종 응답을 손 대조용으로 남긴다(② G · ⑤ 「심판」).
ARM="$arm" python3 - "$OUT" <<'PY'
import json, os, pathlib, shutil, stat, sys

out = pathlib.Path(sys.argv[1])
arm = os.environ["ARM"]
res = out / "result.json"
if not res.exists():
    print(f"\n결과 파일이 없다: {res} — 하네스가 무엇을 돌렸는지 알 수 없다.")
    raise SystemExit(4)
d = json.loads(res.read_text(encoding="utf-8"))
msgs = out / "messages"
msgs.mkdir(exist_ok=True)


def read_trace(tp):
    """(모델 집합, 비용, 최종 응답, 플러그인이 떴는가)"""
    models, cost, final, fired = set(), None, "", False
    try:
        lines = open(tp, encoding="utf-8")
    except (OSError, TypeError):
        return {"(트레이스 없음)"}, None, "", False
    for line in lines:
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        models |= set((ev.get("modelUsage") or {}).keys())
        if ev.get("type") == "result":
            cost = ev.get("total_cost_usd", cost)
            final = ev.get("result") or final
        for block in ((ev.get("message") or {}).get("content") or []) if isinstance(ev.get("message"), dict) else []:
            if not isinstance(block, dict) or block.get("type") != "tool_use":
                continue
            inp = json.dumps(block.get("input") or {}, ensure_ascii=False)
            if block.get("name") in ("Agent", "Task", "Skill") and f'"{arm}:' in inp:
                fired = True
    return models, cost, final, fired


temps, total = set(), 0.0
rows = []
for case in d.get("cases", []):
    for side, runs in (case.get("arms") or {}).items():
        label = "플러그인 없음" if (side != "with" or arm == "none") else arm
        hits, fired_n, costs, models, ungraded = 0, 0, [], set(), 0
        for i, run in enumerate(runs, 1):
            tp = run.get("tracePath")
            if tp:
                temps.add(pathlib.Path(tp).parent.parent)
            m, c, final, fired = read_trace(tp)
            models |= m
            if c is not None:
                costs.append(c)
            # 하네스 밖 팔은 심판 비용을 회차에 따로 남긴다 — 천장에 든 돈이라 합에 넣는다(ADR 0068).
            costs.append(run.get("judgeCostUsd") or 0.0)
            hit = any(g.get("name") == "found" and g.get("passed") for g in run.get("graders", []))
            # 못 맞힌 회차는 트레이스를 남긴다 — 왜 못 맞혔는지(도구 거절 · 오류)는 트레이스에만 있다.
            # 임시 폴더는 아래에서 지워진다. run-evals.sh 가 실패 회차를 남기는 까닭과 같다.
            if not hit and tp and pathlib.Path(tp).is_file() and pathlib.Path(tp).parent != out / "traces":
                (out / "traces").mkdir(exist_ok=True)
                shutil.copyfile(tp, out / "traces" / f"{case.get('name')}.{side}.run{i}.jsonl")
            hits += hit
            ungraded += str(run.get("error") or "").startswith("채점 못 함")
            fired_n += fired
            if run.get("error"):
                final = f"(회차 오류: {run.get('error')})\n\n" + final
            (msgs / f"{case.get('name')}.{'with' if side == 'with' else 'without'}.run{i}.md").write_text(
                f"<!-- {label} · {'맞힘' if hit else '못 맞힘'} · 떴는가 {fired} · 비용 {c} -->\n\n{final}\n", encoding="utf-8")
        total += sum(costs)
        rows.append((case.get("name"), label, hits, len(runs), ungraded, fired_n if (side == "with" and arm != "none") else None,
                     sum(costs), " · ".join(sorted(models)) or "기록 없음"))

print("\n| 케이스 | 팔 | 맞힘 | 떴는가 | 비용($) | 모델 |\n|---|---|---|---|---|---|")
for name, label, hits, nruns, ungraded, fired_n, cost, models in rows:
    f = "—" if fired_n is None else f"{fired_n}/{nruns}"
    u = f" (채점 못 함 {ungraded})" if ungraded else ""
    print(f"| {name} | {label} | {hits}/{nruns}{u} | {f} | {cost:.4f} | {models} |")
print(f"\n합 비용 ${total:.4f} · 최종 응답은 {msgs}/")

# 하네스 밖 팔의 새는 길(조각 52 설계 ② B). 위 표의 칸은 네 팔에 같게 두고(② F), 이 팔만 줄을 더한다.
if arm == "claude-security":
    print("\n| 케이스 | 정답지 낱말이 나온 회차 | 세션 기록 | 하위 호출 · 하위 기록이 남은 회차 |\n|---|---|---|---|")
    hits_all = []
    for case in d.get("cases", []):
        runs = (case.get("arms") or {}).get("with", [])
        leaked = [r for r in runs if r.get("leakHits")]
        called = [r for r in runs if r.get("subCalls")]
        print(f"| {case.get('name')} | {len(leaked)}/{len(runs)} | {sum(r.get('sessionFiles') or 0 for r in runs)} |"
              f" {len(called)} · {sum(1 for r in called if r.get('subRecords'))} |")
        hits_all += [h for r in runs for h in r.get("leakHits") or []]
    for h in hits_all:
        print(f"  정답지 낱말: {h}")
    print(f"세션 기록은 {out / 'sessions'}/")

# --keep-temp 로 남은 작업공간을 치운다 — run-evals.sh 와 같은 까닭으로 먼저 열고 지운다.
for t in temps:
    if not (t.name.startswith("claude-eval-") and t.parent == pathlib.Path("/tmp")):
        continue
    try:
        os.chmod(t, stat.S_IRWXU)
    except OSError:
        pass
    for root, dirs, files in os.walk(t):
        for x in dirs + files:
            try:
                os.chmod(os.path.join(root, x), stat.S_IRWXU)
            except OSError:
                pass
    shutil.rmtree(t, ignore_errors=True)
PY

echo "하네스 종료 $status · 결과 $OUT"
# 결과를 세션 밖에 남기는 길(NC-28 · 조각 52 설계 ② E) — 이 폴더는 .gitignore 라 측정한 세션과 함께 사라진다.
echo "결과 폴더는 .gitignore 라 세션 밖에 남지 않는다 — docs/eval-log/compare-<날짜>.tar.xz 로 싣는다(풀고 싣는 법은 docs/eval-log/2026-11.md 「조각 51 닫기」)"
exit "$status"

}

main "$@"
