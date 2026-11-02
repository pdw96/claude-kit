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
# 팔은 같은 설계 ③ B. 이 러너는 측정 도구이고 게이트가 아니다 — 점수로 종료가 바뀌지 않는다.
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
  claude-security) cap=15 ;;
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
trap 'rm -rf "$TMP"' EXIT
plug="$TMP/$arm"
if [ "$arm" = none ]; then
  # 플러그인 없음 — 하네스가 대상으로 받을 빈 플러그인. 에이전트 · 스킬 · 훅이 없다.
  mkdir -p "$plug/.claude-plugin"
  printf '{"name": "none", "version": "0.0.0", "description": "맞대기의 플러그인 없음 팔"}\n' > "$plug/.claude-plugin/plugin.json"
else
  cp -R "$src" "$plug"
fi
rm -rf "$plug/evals" "$plug/recall" "$plug/compare"
mkdir -p "$plug/compare"
n=0
while IFS=$'\t' read -r name source axis rival; do
  case "$name" in ''|'#'*) continue ;; esac
  [ "$arm" = vibe-audit ] || [ "$arm" = none ] || [ "$rival" = "$arm" ] || continue
  for f in "compare/$name/case.yaml" "compare/$name/graders/found.md" "compare/prompts/$axis.md" "$source/fixture.sh"; do
    [ -f "$f" ] || { echo "재료가 없다: $f" >&2; exit 2; }
  done
  mkdir -p "$plug/compare/$name"
  cp "compare/$name/case.yaml" "$plug/compare/$name/"
  cp -R "compare/$name/graders" "$plug/compare/$name/"
  # 요청 본문은 축의 것 그대로(② B). 플러그인 팔은 그 도구를 부르는 한 줄을 머리에 붙인다(compare/arms.tsv · ADR 0067).
  call=$(awk -F'\t' -v a="$arm" -v x="$axis" '$1 == a && ($2 == x || $2 == "*") { print $3; exit }' compare/arms.tsv)
  if [ "$arm" != none ] && [ -z "$call" ]; then echo "compare/arms.tsv 에 $arm · $axis 줄이 없다" >&2; exit 2; fi
  awk -v call="$call" '{ print } /^---$/ && ++n == 2 && call != "" { print ""; print call }' \
    "compare/prompts/$axis.md" > "$plug/compare/$name/prompt.md"
  cp "$source/fixture.sh" "$plug/compare/$name/fixture.sh"
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
        hits, fired_n, costs, models = 0, 0, [], set()
        for i, run in enumerate(runs, 1):
            tp = run.get("tracePath")
            if tp:
                temps.add(pathlib.Path(tp).parent.parent)
            m, c, final, fired = read_trace(tp)
            models |= m
            if c is not None:
                costs.append(c)
            hit = any(g.get("name") == "found" and g.get("passed") for g in run.get("graders", []))
            # 못 맞힌 회차는 트레이스를 남긴다 — 왜 못 맞혔는지(도구 거절 · 오류)는 트레이스에만 있다.
            # 임시 폴더는 아래에서 지워진다. run-evals.sh 가 실패 회차를 남기는 까닭과 같다.
            if not hit and tp and pathlib.Path(tp).is_file():
                (out / "traces").mkdir(exist_ok=True)
                shutil.copyfile(tp, out / "traces" / f"{case.get('name')}.{side}.run{i}.jsonl")
            hits += hit
            fired_n += fired
            if run.get("error"):
                final = f"(회차 오류: {run.get('error')})\n\n" + final
            (msgs / f"{case.get('name')}.{'with' if side == 'with' else 'without'}.run{i}.md").write_text(
                f"<!-- {label} · {'맞힘' if hit else '못 맞힘'} · 떴는가 {fired} · 비용 {c} -->\n\n{final}\n", encoding="utf-8")
        total += sum(costs)
        rows.append((case.get("name"), label, hits, len(runs), fired_n if (side == "with" and arm != "none") else None,
                     sum(costs), " · ".join(sorted(models)) or "기록 없음"))

print("\n| 케이스 | 팔 | 맞힘 | 떴는가 | 비용($) | 모델 |\n|---|---|---|---|---|---|")
for name, label, hits, nruns, fired_n, cost, models in rows:
    f = "—" if fired_n is None else f"{fired_n}/{nruns}"
    print(f"| {name} | {label} | {hits}/{nruns} | {f} | {cost:.4f} | {models} |")
print(f"\n합 비용 ${total:.4f} · 최종 응답은 {msgs}/")

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
exit "$status"

}

main "$@"
