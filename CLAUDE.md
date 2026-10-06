# claude-kit 작업 규칙

매 세션 읽는 입력물이다. 리뷰 지침과 고정 영역은 `AGENTS.md` 에 있다 — 여기 옮겨 적지 않는다.
같은 목록을 두 군데 두면 갈린다.

## 스택

- bash · python3 **표준 라이브러리만**. 외부 패키지를 들이지 않는다.
- git — **역사 전체**가 있어야 한다. 얕은 클론에서는 `verify-copies.py` 가 대장의 커밋을 못 찾는다.
- Claude Code CLI 2.1.28x — `claude plugin validate` · `claude plugin eval`. CLI 버전은 수트
  지문(`eval-key.py`)에 들어간다.
- CI: GitHub Actions `eval.yml` — gate(키 없음) · eval(키 필요) · verdict(필수 체크).
- 수트 모델 `claude-sonnet-5-5`(2026-10-05 부터) · 심판 sonnet — `run-evals.sh` 가 박는다.

## 앵커볼트 — 바꾸려면 먼저 물어볼 것

- **이름** — 감사자(`audit-*`) · 플러그인(`vibe-audit`) · 마켓플레이스(`pdw96-kit`). 호출 이름이고
  사본 레포에 퍼져 있다.
- **감사자의 `tools`** — 읽기 전용 셋. 고칠 도구가 없다는 것이 이 플러그인의 주장이다.
- **감사자 공통 절의 문구** — 사본이 글자 단위로 견준다(`verify-copy.py`). 바꾸면 모든 사본이 갈린다.
- **대장의 모양** — `copies.json` · `feedback.json`. `docs/schema.md`.
- **기준 문서 · 설계 문서의 모양** — 절 제목. `docs/schema.md`. 다음 조각들이 읽는다.
- **고정 영역** — `AGENTS.md` 「Review guidelines」.

## 가변 — 자유롭게 바꿔도 되는 것

- README 서술, `vibe-audit/evals/README.md` 의 작업 기록
- 감사자 체크 항목의 문구 — 예산과 수트 안에서
- 스크립트의 내부 구조

## 작업 방식

- **되먹임은 사본 → 원본 한 방향**이고, 가르는 질문은 「다른 레포에서도 같은 말인가」다(README).
- **되먹임 한 건에 eval 케이스 하나** — 진짜 부적합 하나 · 대조군 · `samples/fail*.md`.
- **새 검사를 세우면 CI 「게이트가 무는가」에 변조본으로 떨어지는 것을 함께 넣는다.** 물지 않는
  검사는 게이트가 아니다. 키 없이 도는 검사의 목록은 `gates.sh` 한 군데에만 둔다.
- 대안이 있던 결정은 `docs/adr/` 에 남긴다. 고치지 않고 새 ADR 로 대체한다.
- 조각을 시작하면 `PRD.md` 에 절을 더하고 설계 문서(`docs/design/<조각>.md`)를 쓴다 — 둘은 한 PR(ADR 0006).
  구현 PR 은 그것이 머지된 뒤, 설계 ⑥ 의 나눔대로. 절차 전체는 `docs/procedure.md`(조각 2 구현 PR 에서 선다).

## 금지

- 사본의 특화를 원본에 올리지 않는다. 레포별 분기를 원본에 두지 않는다.
- 커밋 안 된 원본을 심지 않는다 — `sync-agents.sh` 가 막는다. 대장의 `synced_commit` 을 손으로
  옮겼다면 `verify-copy.py` PASS 를 본 뒤다.
- `claude plugin eval` 을 직접 부르지 않는다 — `run-evals.sh` 로.
- 글자 예산 천장을 저자 승인 없이 올리지 않는다(ADR 0004).
- 토큰 · 키를 저장소에 쓰지 않는다. CI 자격은 저장소 시크릿에만 있다.
