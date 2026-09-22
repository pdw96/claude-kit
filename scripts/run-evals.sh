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
set -euo pipefail

cd "$(dirname "$0")/.."

for a in "$@"; do
  case "$a" in
    --json|--json=*)
      echo "--json 은 이 스크립트가 쓴다. 결과 경로는 끝에 찍힌다." >&2; exit 2 ;;
  esac
done

# 돌기 전에 수트가 물 수 있는 모양인지부터 본다.
python3 scripts/verify-evals.py

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
  "$@"
status=$?
set -e

# 실패한 회차의 트레이스만 남기고 임시 디렉터리는 지운다.
python3 - "$OUT" <<'PY'
import json, pathlib, shutil, sys

out = pathlib.Path(sys.argv[1])
res = out / "result.json"
if not res.exists():
    print(f"\n결과 파일이 없다: {res}"); raise SystemExit(0)

d = json.loads(res.read_text(encoding="utf-8"))
kept, temps = 0, set()
for case in d.get("cases", []):
    for arm, runs in (case.get("arms") or {}).items():
        for i, run in enumerate(runs, 1):
            tp = run.get("tracePath")
            if tp:
                temps.add(pathlib.Path(tp).parent.parent)
            if run.get("passed") or not tp:
                continue
            src = pathlib.Path(tp)
            if not src.exists():
                continue
            dst = out / "traces" / f"{case['name']}.{arm}.run{i}.jsonl"
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            kept += 1
            bad = [g["name"] for g in run.get("graders", []) if not g.get("passed")]
            print(f"  실패 기록 남김 {dst}  ({', '.join(bad)})")

# --keep-temp 로 남는 작업공간을 치운다. 모드가 닫혀 있어 그냥 지우면 조용히
# 실패하므로(하네스가 경고하는 자리) 먼저 열고 지운다. 남기는 것은 위에서 이미
# 결과 폴더로 복사한 실패 트레이스뿐이다.
import os, stat
for t in temps:
    if not (t.name.startswith("claude-eval-") and t.parent == pathlib.Path("/tmp")):
        continue
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
PY

exit $status
