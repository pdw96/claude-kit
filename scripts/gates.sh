#!/usr/bin/env bash
# 키 없이 도는 게이트를 전부 돌린다. 모델도 API 도 안 쓴다.
#
#   ./scripts/gates.sh                       # 스물여섯 — 로컬은 늘 이것
#   ./scripts/gates.sh --skip-bite <근거>    # CI 만 — 스물하나만 돌리고 변조 시험 다섯은 건너뛴다
#
# **한 군데에만 적는 이유.** 이 목록이 CI 워크플로와 문서에 각각 있으면
# 갈린다 — 한쪽만 고쳐도 아무도 안 알려 준다. 그 결함을 매니페스트에서
# 막아 두고(`verify-manifest.py` 가 두 군데 적힌 이름과 설명을 견준다)
# 정작 게이트 목록은 두 군데 두고 있었다. CI 가 이 파일을 부른다.
#
# 인자가 있어야 도는 검사가 하나 있다. 그냥 돌리면 사용법만 찍고 exit 2 이므로
# 「게이트가 떨어졌다」로 오해하기 쉽다 — 그래서 여기서 옳게 불러 준다.
#
# 게이트가 **무는지**도 여기서 본다 — 변조본을 만들어 떨어뜨려 본다. 물지 않는 검사는 게이트가
# 아니므로 둘 다 있다. 변조본은 다 이 파일이 부르는 다섯에 있다 — 열네 검사의 `bite-gates.sh`, 설계 → 구현 관문의 `bite-slice-gate.py`, 문서 대조 검사의 다른 레포 모드의
# `bite-verify-docs.py`, 절차 지도 판의 `bite-map-pin.py`, `main` 푸시가 머지된 PR 의 통과를 읽는 판정의 `bite-eval-merged-pass.py`.
# 다 수트 지문 밖이라 고쳐도 수트가 다시 돌지 않는다(ADR 0016 의 6 · ADR 0018 의 6 · ADR 0019 의 5 · ADR 0020 의 1 · ADR 0021 의 3).
#
# **두 묶음.** 검사와 자체 시험 스물하나(와 `claude plugin validate` 둘)는 `checks`, 변조 시험 다섯은 `bites` 에 둔다.
# 인자 없이는 `checks` 를 다 돌린 뒤 `bites` 를 돌린다 — 변조 시험은 자체 시험의 결과를 읽지 않고 제 사본에서 따로 돈다.
# `--skip-bite <근거>` 는 `checks` 만 돌린다. 변조 시험이 보는 것 — 검사 코드가 무는지 — 은 검사 코드와 그것이 규칙으로
# 읽는 파일의 지문(`gate-key.py`)이 같으면 같으므로, CI 가 같은 지문이 이미 물었던 근거를 찾았을 때만 이것으로 부른다.
# 무엇을 근거로 줄지는 `eval.yml` 이 들고, 여기서는 근거의 뜻을 보지 않고 찍기만 한다. CI 밖(`GITHUB_ACTIONS` 가 `true` 가
# 아님)에서는 받지 않는다 — 로컬은 늘 다 돈다(ADR 0046 의 3 · 4 · 7). `bites` 에는 `scripts/bite-` 로 시작하는 파일을 부르는
# 줄 말고 아무 명령도 두지 않는다 — 건너뛰는 것이 변조 시험뿐인지 `bite-gates.sh` 가 그 모양으로 문다(조각 35 설계 ② G4 · G5).
set -euo pipefail

# 늘 도는 것 — 검사와 자체 시험 스물하나, `claude plugin validate` 둘. 건너뛰는 실행에서도 다 돈다(ADR 0046 의 4).
checks() {
  claude plugin validate ./vibe-audit
  claude plugin validate ./vibe-slice

  python3 scripts/verify-manifest.py

  # 장터의 줄과 플러그인 폴더를 맞대는지 — 베낀 트리에 줄 빼기 · 겹치기 · 줄 없는 폴더 · 설명 한 글자.
  python3 scripts/test-verify-manifest.py

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

  # 문서 대조 검사가 무는지 — 베낀 트리에 변조본을 하나씩 만들어 돌린다. 다른 레포 모드(--repo)는 틀로 세운 임시 레포에서.
  python3 scripts/test-verify-docs.py

  # 조각 문서 스킬의 사본 길 — 임시 원본 · 대상으로 조각 5 설계 ② C1 ~ C5, 심은 두 검사가 대상에서 도는지(조각 9 설계 ② Y).
  python3 scripts/test-sync-slice.py

  # 설계 → 구현 관문 — 착공 PR 에 구현이 없고, 구현은 기준 가지에 머지된 설계 위에 선다(조각 7 설계 ②).
  python3 scripts/verify-slice-gate.py

  # 관문 검사가 무는지 — 임시 git 레포에 착공 · 구현 · 쌓은 PR · 작업트리 꼴을 만들어 돌린다.
  python3 scripts/test-verify-slice-gate.py

  # 플러그인의 절차 지도 판 — 원본 스킬이 지도를 커밋으로 박았고, 그 지도가 vibe-slice/ 를 마지막으로 고친 커밋의 것이다(조각 10 설계 ②).
  python3 scripts/verify-map-pin.py

  # 판 검사가 무는지 — 임시 git 레포에 박기 · 지도만 고침 · 머지 · 작업트리 · 틀린 꼴을 만들어 돌린다.
  python3 scripts/test-verify-map-pin.py

  # main 푸시가 머지된 PR 의 통과를 읽는 판정 — 로컬 가짜 API 에 꼴 열둘과 읽어 보기(--probe)를 세워 돌린다(조각 12 설계 ② T1).
  python3 scripts/test-eval-merged-pass.py

  # eval.yml gate 잡이 변조 시험의 지문을 「물었다」로 적는 조건과 건너뛰는 조건 — 첫 열한 스텝의 판정에 드는 칸이 닫힌 목록 그대로다.
  # 건너뛰는 실행에서도 돌아야 건너뛰는 조건까지 물므로 여기 둔다(조각 37 · ADR 0048 의 2).
  python3 scripts/verify-eval-gate.py

  # 이 파일이 무엇을 실제로 부르는지 — 인자 없이는 변조 시험 다섯까지 다, --skip-bite 는 다섯만 빼고. 변조 시험이 안 돌아도
  # 돌아야 하므로 여기 둔다(조각 35 닫기 전 감사 회차 NC-1 · 설계 끝 「닫기 전 감사 회차에서 찾은 것」).
  python3 scripts/test-gates.py
}

# 건너뛸 수 있는 것 — 변조 시험 다섯. `scripts/bite-` 로 시작하는 파일을 부르는 줄만 둔다(조각 35 설계 ② G4).
bites() {
  # 문서 대조 검사의 자체 시험이 다른 레포 모드에서 무는지 — 검사의 다른 레포 모드를 한 자리씩 망가뜨린 사본에 test-verify-docs.py 를 댄다.
  python3 scripts/bite-verify-docs.py

  # 관문 검사의 자체 시험이 무는지 — 관문 검사를 한 자리씩 망가뜨린 사본에 test-verify-slice-gate.py 를 댄다.
  python3 scripts/bite-slice-gate.py

  # 판 검사의 자체 시험이 무는지 — 판 검사를 한 자리씩 망가뜨린 사본에 test-verify-map-pin.py 를 댄다.
  python3 scripts/bite-map-pin.py

  # main 푸시 판정의 자체 시험이 무는지 — 판정을 한 자리씩 망가뜨린 사본에 test-eval-merged-pass.py 를 댄다(조각 12 설계 ② T2).
  python3 scripts/bite-eval-merged-pass.py

  # 검사들이 무는지 — 검사마다 변조본을 만들어 떨어뜨린다. 두 지문 · 이 파일의 묶음과 인자도 본다. 제자리에서 흔드는 파일은
  # 백업에서 되돌린다(ADR 0020). 맨 끝이라 다른 검사가 다 통과한 뒤에 돈다.
  ./scripts/bite-gates.sh
}

usage() {  # $1=까닭 — 아무 검사도 돌리기 전에 찍고 종료 2(조각 35 설계 ② G3)
  echo "사용법: $0 [--skip-bite <근거>]" >&2
  echo "  거절: $1" >&2
  exit 2
}

main() {
  skip=""
  case $# in
    0) ;;
    2)
      [ "$1" = --skip-bite ] || usage "모르는 인자 — $1"
      [ "${GITHUB_ACTIONS:-}" = true ] || usage "--skip-bite 는 CI(GITHUB_ACTIONS=true)에서만 받는다 — 로컬은 늘 다 돈다"
      [ -n "${2//[[:space:]]/}" ] || usage "--skip-bite 의 근거가 비었다"
      skip=$2 ;;
    1)
      if [ "$1" = --skip-bite ]; then usage "--skip-bite 의 근거가 없다"; fi
      usage "모르는 인자 — $1" ;;
    *) usage "인자가 $# 개다 — 없거나 --skip-bite <근거> 둘이어야 한다" ;;
  esac

  R="$(git rev-parse --show-toplevel)"
  cd "$R"

  if [ -n "$skip" ]; then
    echo "변조 시험 다섯을 건너뛴다 — $skip"
    echo
  fi

  checks

  if [ -n "$skip" ]; then
    echo
    echo "스물하나 통과 · 변조 시험 다섯은 건너뛰었다 — $skip"
    echo "변조 시험까지 보려면 로컬에서 인자 없이 부르거나 CI 의 workflow_dispatch 를 부른다."
    return 0
  fi

  bites

  echo
  echo "스물여섯 다 통과 — 키 없이 볼 수 있는 것은 여기까지다."
  echo "감사자가 실제로 무엇을 판정하는지는 ./scripts/run-evals.sh 가 본다."
}

main "$@"
