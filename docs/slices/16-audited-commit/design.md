# 조각 16 설계 — 감사한 커밋을 기록에

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`, 갈림길은 ADR 0026.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A | 「감사한 커밋을 기록에」 상태 `진행` · 조각 폴더 |
| `docs/adr/0026-audited-commit-in-record.md` | A | 갈림길 셋 |
| `vibe-audit/evals/brief-audited-commit/` | B | 새 판정 케이스 — `case.yaml` · `prompt.md` · `fixture.sh` · `graders/` · `samples/`(② K1) |
| `vibe-audit/agents/audit-*.md` 여섯 | B | 「출력 형식」 머리에 「감사한 커밋」 줄 하나(② R1 · R2). 천장을 넘는 감사자는 그 감사자의 문구를 줄인다(② R4) |
| `vibe-audit/evals/budget.txt` | B | `verify-budget.py --write` 의 새 값 |
| `vibe-audit/.claude-plugin/plugin.json` | B | 판 0.3.1 → 0.4.0 — 판이 그대로면 설치한 레포가 갱신해도 옛 감사자를 쓴다(ADR 0013) |
| `vibe-audit/evals/README.md` | B | 「케이스」 표에 `brief-audited-commit` 한 줄 |
| `docs/eval-log/2026-10.md` | B | 날짜를 박은 항목 — 왜 · 바꾼 것 · 줄인 문구 · 옛 · 새 측정 · 전수 |
| `feedback.json` | B | FB-24 `defect` → `fed_back` · `feedback`(되먹임 커밋 · 케이스 · `budget_delta`) — 저자가 정한 뒤(② L1) |

**앵커볼트.** 건드리지 않는다 — 이름 · 감사자의 `tools` · 공통 절(`verify-copy.py` 의 `SHARED` 넷) · 대장의 모양 · 「…의 칸」 ·
`AGENTS.md`. 「출력 형식」은 감사자마다 다르고 공통 절이 아니다 — `verify-copy.py` 는 그 안의 표식 둘(「담당 없음 — 호출자 판단 필요」 ·
`## 지난 회차`)만 본다. `feedback.json` 은 칸을 그대로 쓰고 FB-24 의 상태만 바뀐다.

**고정 영역 · 수트.** `run-evals.sh` · `eval.yml` 은 고치지 않는다. 지난 정규식 그레이더도 그대로다 — 새 그레이더는 새 케이스의 것뿐이다.
B 는 수트 지문(`eval-key.py route --list` · `full --list`)의 파일을 고친다 — PR 의 CI 가 route 수트를 돈다.

**사실.**
- 감사자는 이미 브리핑 머리의 「대상」을 읽고 `.git/HEAD` 와 견준다(「세 도구로 할 수 없는 것」) — 새 줄은 그 값을 기록에 옮겨 적는
  것이다. 새 도구도 새 읽기도 없다.
- 커맨드 「남기는 것」은 감사자가 돌려준 기록을 저장하라고 한다 — 기록 머리에 줄이 있으면 저장된 기록이 그 줄을 든다. 커맨드는 그대로다.
- 사본 레포는 원본의 새 줄을 들지 않는다 — `compare-copies.py` 는 사본을 심을 때의 원본과 견주므로 후보가 생기지 않고,
  `verify-copies.py` 의 「바뀐 원본」 알림에 감사자 이름이 붙는다(ADR 0025 의 3). 받는 일은 다음 심기다.

**시스템 구조.** 부품 · 경계 · 흐름은 그대로다 — 감사 기록의 머리 줄이 하나 는다. `docs/architecture.md` 는 고치지 않는다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 번호는 ⑤ 와 PR 본문이 같이 쓴다.

- **기록의 줄** (B)
  - R1 원본 감사자 여섯의 「출력 형식」 코드 울타리 안, 머리의 `- 감사자:` 줄 바로 다음에 `- 감사한 커밋:` 으로 시작하는 줄이 하나 있다.
    여섯의 그 줄은 글자가 같다.
  - R2 그 줄의 자리표시가 말하는 것 — 지금 것인 브리핑(「세 도구로 할 수 없는 것」의 대조를 지난 브리핑)이 있으면 그 「대상」의 SHA 를 백틱으로
    적고, 그 브리핑의 「커밋 안 된 변경」이나 「추적 안 된 파일」이 있음이면 끝에 `· 커밋 안 된 변경 포함` 을 붙인다. 지금 것인 브리핑이 없으면
    SHA 를 짐작하지 않고 「모름」을 적는다(ADR 0026 의 3).
  - R3 공통 절 넷과 프론트매터는 글자가 그대로다 — `git diff main...HEAD` 의 감사자 덩어리가 다 「출력 형식」과 R4 의 줄인 문구 안이다.
    `verify-copy.py vibe-audit/agents` 가 통과하고, 두 사본이 `verify-copies.py` PASS 그대로다.
  - R4 예산 — `verify-budget.py` 의 천장 넷은 그대로다. 줄을 넣어 호출 시 11,000 을 넘는 감사자는 **그 감사자의** 문구를 줄여 넣는다 —
    공통 절 · 프론트매터 · 판정 케이스의 그레이더가 찾는 낱말은 건드리지 않는다. 줄인 자리마다 무엇을 줄였고 왜 뜻이 남는지를 eval-log
    항목에 적는다. 줄여서 못 넣으면 B 를 멈추고 천장을 저자에게 올린다(ADR 0004).
- **케이스** (B)
  - K1 `brief-audited-commit` — 감사자 `audit-secrets`, 커맨드를 부르지 않는다(ADR 0026 의 2). 픽스처는 저자 · 커미터 시각을 박아 SHA 가
    늘 같은 저장소를 만든다 — 기준 커밋 · HEAD 커밋, 그리고 **커밋하지 않은** 작업트리 변경. 진짜 부적합 하나는 그 커밋 안 된 변경 안에
    있다. 픽스처가 놓는 브리핑은 커맨드 「셋」의 모양이고 「대상」은 HEAD(지금 것), 「커밋 안 된 변경」은 있음, diff 절의 `### 작업트리`
    아래에 그 변경이 있다. 그레이더 —
    - `real-nc-found`(정규식) 대조군 — 그 부적합이 NC 절에 결함의 흔적과 함께 있다
    - `gate-commit-recorded`(정규식) — 「감사한 커밋」 줄에 HEAD 의 SHA 가 있다. 기준의 SHA 만 적은 줄은 떨어진다
    - `gate-dirty-marked`(정규식) — 같은 줄에 `커밋 안 된 변경 포함` 이 있다
    - `auditor-fired`(`tool_used`, `arm: with-only`)
    - 표본 — `pass.md` 한 벌, 그리고 `fail*.md` 넷: 줄이 없는 옛 모양(두 목적 그레이더) · 꼬리가 없는 줄(`gate-dirty-marked`) · 기준
      SHA 를 적은 줄(`gate-commit-recorded`) · 대조군 결함을 놓친 기록(`real-nc-found`). `verify-evals.py` · `verify-graders.py` 통과.
  - K2 측정 — `run-evals.sh --case brief-audited-commit`(3 회차)을 고치기 전의 감사자(케이스만 더한 커밋)에서 돌리면 세 회차 다 목적
    그레이더 둘이 떨어지고, 고친 감사자에서 돌리면 세 회차 다 지나가 점수가 문턱(0.8) 이상이다.
  - K3 전수 — 고친 감사자의 머리에서 `workflow_dispatch` 전수의 verdict 가 초록이다. R4 의 줄인 문구가 닿는 판정 케이스(`audit-internal` ·
    `audit-data` 의 것)가 이 안에서 문턱을 넘는다.
- **대장** (B)
  - L1 FB-24 — `status` `fed_back`, `feedback.commit` 은 감사자를 고친 커밋, `cases` 는 `["brief-audited-commit"]`, `budget_delta` 는 그
    커밋에서 `verify-budget.py` 가 잰 호출 시 문자 증감. `seen` · `hash` · `reason` · `decided_at` 은 그대로다. 저자가 K2 · K3 를 본 뒤 정한다.
    `verify-feedback.py` 통과.
- **게이트** (A · B)
  - G1 `./scripts/gates.sh` 의 검사 수는 그대로다 — 새 검사를 세우지 않는다. 새 그레이더가 무는지는 표본(`verify-graders.py`)이 본다.
  - G2 A 는 결정 문서뿐이다 — `verify-slice-gate.py` 가 본다. B 는 이 착공이 머지된 뒤에 선다.

**보장하지 않는 것(알려진 한계)**

- **호출자가 기록을 저장하는가** — 줄은 감사자가 돌려준 기록에 있다. 저장 · 대장 등록은 호출자의 몫이고(「회차를 잇습니다」), 대장에 NC 줄만
  옮기는 레포에서는 그 줄이 남지 않을 수 있다. 커맨드를 고치지 않는다(하지 않을 일 2).
- **여섯 중 다섯** — 케이스는 `audit-secrets` 하나로 잰다. 다른 다섯은 같은 글자의 줄을 들 뿐 그 줄을 쓰는지는 재지 않는다.
- **브리핑이 없거나 지난 회차 것일 때** — 「모름」을 적는지는 재지 않는다(하지 않을 일 6).
- **줄의 이름에 기댄다** — 정규식은 「감사한 커밋」이라는 이름의 줄을 찾는다. 같은 사실을 다른 이름의 줄이나 본문에 적은 기록은 떨어진다 —
  출력 형식을 따르는가를 재는 것이다.
- **다음 회차가 그 줄을 쓰는가** — 기준을 그 SHA 로 고르는 규칙은 세우지 않는다(하지 않을 일 5).
- **커맨드 케이스** — ADR 0024 의 세 제약은 그대로다. 커맨드의 동작은 대화형 세션에서 저자가 본다(`vibe-audit/evals/README.md` 「재지 않는 것」).
- **아직 겪지 않은 가설적 경계 사례** — 예: 브리핑 「대상」이 HEAD 와 같은데 커밋 안 된 변경이 브리핑 뒤에 더 생긴 작업트리, 떨어진 HEAD,
  「대상」에 긴 SHA. 겪으면 그 PR 에서 정해 날짜 항목으로 적는다. 리뷰가 이것을 짚으면 범위 밖이다(조각 6 「닫으며」).

## ③ 받는 입력

닫힌 목록이다. 2026-10-13 의 claude-kit `main`(88b4a0a), ERP `main`(248317a)에서 뽑았다.

**브리핑 머리** — 커맨드 「셋」의 모양. 새 줄이 읽는 것은 셋뿐이다.

| 브리핑 줄 | 모양 | 새 줄이 쓰는 것 |
|---|---|---|
| `- 대상:` | `` `<HEAD 짧은 SHA>` (브랜치 `<이름>`) `` | 백틱 안의 SHA |
| `- 커밋 안 된 변경:` | `없음` / `있음 — <경로 목록, diff 포함 여부>` | 있음이면 꼬리 |
| `- 추적 안 된 파일:` | `없음` / `<경로 목록 — diff 포함 여부>` | 없음이 아니면 꼬리 |

그 밖의 줄(만든 시각 · 기준 · 자름 · 검사)은 이 줄에 쓰지 않는다. 브리핑이 지금 것인지는 감사자의 지금 규칙(「대상」 SHA 와 `.git/HEAD`)이
가르고, 그 규칙은 바뀌지 않는다.

**원본 「출력 형식」의 머리** — 2026-10-13 `main`. 새 줄은 `- 감사자:` 다음에 선다.

| 감사자 | `- 범위` · `- 일시` · `- 감사자` 다음 줄 | 호출 시(천장 11,000) |
|---|---|---|
| `audit-contract` | `- 소비자 가정:` | 10,186 |
| `audit-data` | `- 운영 데이터 존재:` | 10,951 |
| `audit-internal` | `- 기준 문서:` | 10,991 |
| `audit-ops` | 없음 — 빈 줄 뒤 `## 체크 항목` | 10,405 |
| `audit-quality` | 없음 — 빈 줄 뒤 `## 체크 항목` | 10,899 |
| `audit-secrets` | 없음 — 빈 줄 뒤 `## 체크 항목` | 10,409 |

**ERP 의 실물** — 사본 커맨드 `audit-brief.md:124 ~ 127`(회차 절 첫 줄 「감사한 커밋」 · 「· 커밋 안 된 변경 포함」 꼬리), 대장
`docs/audit/README.md` 「회차 절이 여는 줄 — 감사한 커밋」(줄의 모양 `` - **감사한 커밋**: `7d592b2` · **감사자**: `audit-quality` ``, 꼬리의
뜻 「덜 보지 않고 더 본다」), `docs/audit/회차-기록.md` 의 회차 절들. ERP 사본 감사자의 「출력 형식」에는 그 줄이 없다 — 커맨드 쪽에만 세웠다.

**사본** — 두 레포의 사본 감사자는 각자 심은 원본(ERP 3d6964a · 강호쟁패 b8d9243)의 「출력 형식」을 든다 — 「감사한 커밋」 줄이 없다.
`compare-copies.py` 는 `후보 23 — 미판정 0 · 판정됨 23(새 레포 0)` 이다(조각 15 「닫으며」).

**`feedback.json`** — FB-24 `defect`, `seen` 은 `erp · audit-brief.md` · 248317a · 3d6964a(조각 15 #64).

## ④ 결정

**정한 것** — ADR 0026. 셋 다 세션 제안 · 저자 확인 대기.

- 1 되먹임 자리 — 감사자 여섯의 「출력 형식」 머리에 줄 하나. 공통 절 · 커맨드는 그대로
- 2 재는 케이스 — 감사자 케이스 `brief-audited-commit`. 커맨드를 부르지 않고 ADR 0024 의 세 제약을 비켜 간다
- 3 지금 것인 브리핑이 없을 때 — 「모름」. SHA 를 짐작하지 않는다

**열어 둔 것**

없음 — 갈림길 셋을 착공에서 정한다. 줄일 문구(② R4)는 결정이 아니라 B 의 일이다 — 무엇을 줄였는지를 eval-log 항목과 PR 본문에 적는다.

## ⑤ 검증 계획

명령은 PR 본문에 결과와 함께 적는다. 「어긋내 보기」는 일부러 망가뜨린 작업트리에 같은 명령을 대어 떨어지는지 본 뒤 되돌린다.

**PR A**

- `./scripts/gates.sh` 스물넷 통과 — `verify-docs.py` 가 새 조각 폴더를, `verify-slice-gate.py` 가 착공 PR 에 결정 문서뿐인지를 본다(G2).
- 지문 — `git diff --name-only main...HEAD` 와 `eval-key.py route --list` · `full --list` 의 교집합 0.

**PR B** (A 가 머지된 뒤) — 커밋 순서가 측정의 순서다.

1. 케이스만 더한 커밋 — `verify-evals.py` · `verify-graders.py` 통과(K1). 픽스처를 두 번 돌려 HEAD SHA 가 같고 그레이더의 SHA 와 같은지 본다.
   `run-evals.sh --case brief-audited-commit` → 목적 그레이더 둘이 세 회차 다 떨어진다(K2 의 옛 쪽, 성공 기준 4).
2. 감사자 여섯 · `budget.txt` · 판 — `run-evals.sh --case brief-audited-commit` → 세 회차 다 지나간다(K2 의 새 쪽).
   `python3 scripts/verify-budget.py` 통과 · `budget.txt` diff(R4). `verify-copy.py vibe-audit/agents` 통과 ·
   `git diff main...HEAD -- vibe-audit/agents` 가 R3 의 자리 안(R3). 두 클론이 있으면 `verify-copies.py` PASS 와 「바뀐 원본」 이름 —
   없으면 CI gate 잡의 같은 출력(성공 기준 2).
3. 전수 — 2 의 머리에서 `workflow_dispatch` → verdict 초록(K3, 성공 기준 6). PR 의 CI 는 route 수트 · gate · verdict 초록.
4. 기록 · 대장 — eval-log 항목 · README 표 · FB-24(L1). `verify-feedback.py` 통과. 이 커밋은 수트 지문 밖이다 — 전수를 다시 돌리지 않는다.

- 어긋내 보기 — 표본: 새 정규식 그레이더를 한 글자씩 무르게 한 작업트리(예: SHA 자리를 아무 SHA 로)에 `verify-graders.py` 를 대면 그
  그레이더를 지목한 표본에서 떨어진다.
- 측정에는 자격(구독 토큰이나 API 키)이 있는 세션이 필요하다. 없으면 1 · 2 를 각각 `workflow_dispatch` 전수로 잰다 — 전수 두 번이
  월 한도 안인지 저자가 정한다.
- `./scripts/gates.sh` 스물넷 통과 — 로컬과 CI gate 잡(성공 기준 8).

**스스로 쓰기** — PR A · B 의 리뷰를 `slice-review` 로 가른다. PR 본문의 `## 리뷰 회차` 와 답글. B 는 `verify-slice-gate.py` 를 CI 에서
지나간다(이 착공이 머지된 뒤).

**단계 5(배포)** — 플러그인 판이 오른다(0.4.0). 마켓플레이스로 설치한 레포는 `claude plugin update` 로 받는다. 사본 레포는 다음 심기에서
받는다(하지 않을 일 7). 되돌리는 길은 B 의 되돌림과 판을 다시 올리는 것이다 — 대장의 FB-24 는 되돌림과 함께 `defect` 로 돌아간다.

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A 착공 | 요구사항 · 설계 · ADR 0026 · 마스터플랜(「감사한 커밋을 기록에」 `진행`) | 단계 1 · 2, ② G2 |
| B 되먹임 | 케이스 `brief-audited-commit` · 감사자 여섯 · `budget.txt` · `plugin.json` · `vibe-audit/evals/README.md` · `docs/eval-log/2026-10.md` · `feedback.json` | ② R1 ~ R4 · K1 ~ K3 · L1 · G1, 성공 기준 1 ~ 8 |

케이스와 감사자를 한 PR 에 둔다 — 케이스만 머지하면 `main` 의 전수가 그 케이스에서 떨어진다. 그 안에서 케이스 커밋을 감사자 커밋 앞에
두어 옛 감사자를 잰다(⑤ B 1). 조각을 닫는 기록은 따로 낸다(단계 6).
