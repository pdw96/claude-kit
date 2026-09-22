#!/usr/bin/env bash
# 감사자 수트를 옳은 깃발로 돌린다.
#
#   ./scripts/run-evals.sh                    # 전부
#   ./scripts/run-evals.sh --case 'trap-*'    # 골라서
#
# 깃발을 손으로 적지 않는 이유는 하나다. `--judge-model sonnet` 을 빠뜨리면
# **조용히 오검이 난다** — 기본 심판(haiku)은 이 수트의 감사 기록에서 아홉 번
# 어긋나는 동안 한 번도 맞지 않았고, trap-rollback-unproven 이 haiku 0.278 /
# sonnet 1.000 이다. 심판 모델은 케이스 파일에 못 적고 명령줄에만 있으므로,
# 기억에 맡기면 언젠가 빠진다.
#
# --scaffold 도 같다. 없으면 픽스처가 안 만들어져 빈 작업공간에서 돌고,
# 감사자는 볼 것이 없으니 함정도 안 밟는다 — 거짓 통과다.
set -euo pipefail

cd "$(dirname "$0")/.."

# 돌기 전에 수트가 물 수 있는 모양인지부터 본다.
python3 scripts/verify-evals.py

exec claude plugin eval ./vibe-audit \
  --scaffold \
  --trust-plugin \
  --judge-model sonnet \
  --no-publish \
  "$@"
