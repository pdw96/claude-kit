#!/usr/bin/env bash
# 키 없이 도는 게이트를 전부 돌린다. 모델도 API 도 안 쓴다.
#
#   ./scripts/gates.sh
#
# **한 군데에만 적는 이유.** 이 목록이 CI 워크플로와 문서에 각각 있으면
# 갈린다 — 한쪽만 고쳐도 아무도 안 알려 준다. 그 결함을 매니페스트에서
# 막아 두고(`verify-manifest.py` 가 두 군데 적힌 이름과 설명을 견준다)
# 정작 게이트 목록은 두 군데 두고 있었다. CI 가 이 파일을 부른다.
#
# 인자가 있어야 도는 검사가 하나 있다. 그냥 돌리면 사용법만 찍고 exit 2 이므로
# 「게이트가 떨어졌다」로 오해하기 쉽다 — 그래서 여기서 옳게 불러 준다.
#
# 게이트가 **무는지**는 여기서 안 본다. 그건 CI 의 「게이트가 무는가」 단계가
# 변조본을 만들어 떨어뜨려 본다. 물지 않는 검사는 게이트가 아니므로 둘 다 있다.
set -euo pipefail

main() {
  R="$(git rev-parse --show-toplevel)"
  cd "$R"

  claude plugin validate ./vibe-audit

  python3 scripts/verify-manifest.py
  python3 scripts/verify-copies.py
  python3 scripts/verify-feedback.py
  python3 scripts/verify-evals.py
  python3 scripts/verify-graders.py
  python3 scripts/verify-budget.py

  # 브리핑 검사기가 무는지 — 임시 저장소에 통과 · 실패 모양을 만들어 돌린다.
  python3 scripts/test-verify-brief.py

  # 사본 비교기가 무는지 — 임시 원본 · 원격 · 사본으로 PRD 조각 1 의 성공 기준을 재현한다.
  python3 scripts/test-compare-copies.py

  # 후보 대장 검사기의 역사 규칙(번호 · 되먹임 커밋의 케이스)이 무는지 — 임시 저장소.
  python3 scripts/test-verify-feedback.py

  # 원본을 자기 자신과 견준다. 사본 대조는 verify-copies.py 가 대장을 보고 한다.
  python3 scripts/verify-copy.py vibe-audit/agents

  # 문서의 모양 — 절 제목 · 경로 · 조각 나눔 · 닫는 기록(조각 3 설계 ②).
  python3 scripts/verify-docs.py

  # 문서 대조 검사가 무는지 — 베낀 트리에 변조본을 하나씩 만들어 돌린다.
  python3 scripts/test-verify-docs.py

  echo
  echo "열둘 다 통과 — 키 없이 볼 수 있는 것은 여기까지다."
  echo "감사자가 실제로 무엇을 판정하는지는 ./scripts/run-evals.sh 가 본다."
}

main "$@"
