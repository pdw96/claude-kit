# 조각 38 설계 — `gates.sh` 검사 목록의 고정

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A · 닫기 | 조각 나눔 — 「`gates.sh` 검사 목록의 고정」을 순서 38 · `진행` 으로 · 조각 폴더. 닫기에서 `닫힘` |
| `docs/slices/38-gates-list-pin/` · `docs/adr/0049-gates-list-pin.md` | A | 이 요구사항 · 설계 · ADR |
| `scripts/test-gates.py` | B | 고정 목록(② L) · 실패 전파를 스물여덟 다로(② S) · 가짜를 셸로(② S4) · 머리 주석 |
| `scripts/bite-gates.sh` | B | `test-gates.py` 절에 변조본 · 대조군 · 진짜 `gates.sh` 부르기(② R · V). 머리 주석 |
| `scripts/gates.sh` | B | **머리 주석만** — 「한 군데에만 적는 이유」에 고정 목록의 예외 한 문장 |
| `CLAUDE.md` | B | 「작업 방식」의 「키 없이 도는 검사의 목록은 `gates.sh` 한 군데에만 둔다」에 예외 한 마디(ADR 0049 의 6) |
| `docs/architecture.md` | B | 「키 없는 게이트」의 「목록은 그 파일 한 군데에만 있다」에 예외 한 마디 |
| `CHECKLIST.md` | B | 「새 검사를 세웠다면」 줄에 `test-gates.py` 의 목록 |
| `docs/audit/` | 닫기 | 닫기 전 감사 회차의 기록 · 브리핑 · 대장 등록 |

앵커볼트를 건드리지 않는다 — 이름 · 감사자의 `tools` · 공통 절 · 대장 둘의 모양 · 절 제목 · 고정 영역이 그대로다. `CLAUDE.md` 는 「작업 방식」 한 줄의 글만
바뀌고 절 제목은 그대로다. 플러그인 폴더(`vibe-audit/` · `vibe-slice/`)를 고치지 않아 판이 그대로다. 수트 지문(`eval-key.py`)에 드는 파일을 고치지 않아
route 수트는 돌지 않는다. B 의 세 스크립트는 변조 시험 지문(`gate-key.py`)에 들어 B 의 CI 는 변조 시험까지 다 돈다. `INTENT.md` 도 그대로다 — What 의 「키
없이 도는 게이트」 안이고 Not 에 걸리지 않는다. `gates.sh` 의 판정은 바뀌지 않아 부품 · 경계 · 흐름이 그대로고, `docs/architecture.md` 는 목록의 자리를 적은
한 마디만 고친다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 다 B 가 싣는다. 인자와 출력은 지금 그대로다 — `python3 scripts/test-gates.py [<gates.sh>]`, 맞으면 `PASS test-gates.py — …` 와 종료 0,
어긋나면 어긋난 자리마다 `FAIL <번호> …` 를 다 찍고 종료 1, ③ A3 의 꼴은 사용법과 종료 2.

- L **고정 목록.**
  - L1 `test-gates.py` 가 `gates.sh` 가 부르는 것의 이름을 제 안의 닫힌 목록으로 든다 — 늘 도는 스물셋과 변조 시험 다섯(지금의 `FIVE`), ③ L 그대로.
  - L2 `gates.sh` 의 부르는 것(주석 아닌 줄의 `python3 scripts/…` · `./scripts/…` · `claude plugin validate …` — 지금 읽는 법 그대로)이 L1 과 이름마다 횟수가
    같다. 목록에 있는데 없거나(지움 · 주석 처리) · 목록에 없는 이름이 있거나(새 검사) · 한 번이 아니면(겹침) 이름마다 `FAIL L2 …`. 차례는 보지 않는다.
  - L3 T1 · T1′ · T2 의 기대는 L1 에서 나온다 — `gates.sh` 에서 읽지 않는다. 그래서 L2 가 떨어진 `gates.sh` 도 T1 · T2 가 따로 찍는다.
- S **실패 전파** — 지금의 T5 를 넓힌다. 가짜 하나만 1 로 끝나게 하고 `gates.sh` 를 부르면 `gates.sh` 가 0 이 아닌 종료여야 한다. 아니면 `FAIL S<번호> …`.
  - S1 L1 의 스물여덟마다, T1 의 꼴(`GITHUB_ACTIONS` 없음)과 T1′ 의 꼴(`GITHUB_ACTIONS=true`).
  - S2 늘 도는 스물셋마다, T2 의 꼴(`GITHUB_ACTIONS=true --skip-bite 근거`).
  - S3 `claude` 가짜도 1 로 끝날 수 있다 — `claude:<폴더>` 이름으로.
  - S4 가짜는 셸이다 — `python3` 와 `claude` 를 가짜로 PATH 맨 앞에 두고, 가짜는 부른 스크립트의 파일 이름을 기록에 적는다. S 는 `gates.sh` 를 일흔아홉 번 더
    부르는데(S1 쉰여섯 · S2 스물셋), 그때마다 가짜 스크립트 하나에 파이썬 하나를 띄우지 않으려는 것이다(성공 기준 5).
  - S 가 닫는 것 — 실패를 삼키는 꼴이 무엇이든(`|| true` · `|| :` · `set +e` · `if` 로 감싸기 · CI 에서만 · `--skip-bite` 에서만) 그 가짜의 실패가 올라오지
    않으면 떨어진다. 꼴의 목록이 아니라 동작으로 문다(ADR 0049 의 4).
- R **자기 줄.** `bite-gates.sh` 의 `test-gates.py` 절이 진짜 `scripts/gates.sh` 에 `test-gates.py` 를 한 번 부른다 — `checks` 에서 `test-gates.py` 줄을 지우면
  그 실행이 L2 로 떨어진다. `gates.sh` 를 고친 PR 은 변조 시험 지문이 바뀌어 CI 에서도 변조 시험이 돈다.
- V **문다 — `bite-gates.sh` 의 `test-gates.py` 절.**
  - V1 **변조본** — `gates.sh` 사본의 한 자리를 바꿔 `test-gates.py <사본>` 을 부른다. 새 변조본은 종료 1 이고 기대한 번호의 `FAIL` 줄(예: `FAIL L2`)을 찍었을
    때만 「물었다」로 센다(조각 37 감사 OB-4 의 가 — 다른 까닭으로 떨어진 것을 세지 않는다). 바꿀 글이 `gates.sh` 에 꼭 한 번이 아니면 변조본을 돌리기 전에
    종료 1(지금의 `gmut` 그대로).
  - V2 **대조군** — 자유로운 것만 바꾼 사본이 `PASS` · 종료 0 이다. 하나라도 떨어지면 시험이 차례나 주석까지 잡는 것이라 종료 1.
  - V3 **앞 변조본 아홉** — 지금의 아홉이 그대로 떨어진다.

**보장하지 않는 것(알려진 한계)**

- **두 파일을 함께 고친 PR** — `gates.sh` 의 줄과 `test-gates.py` 의 목록을 함께 지우거나 더한 PR 은 리뷰가 본다. 그것이 이 조각의 뜻이다 — 조용히 갈리지 않고,
  갈리려면 두 diff 가 같이 나간다(ADR 0049 의 2).
- **`test-gates.py` 줄과 `bite-gates.sh` 줄을 함께 지운 `gates.sh`** — R 은 `bite-gates.sh` 가 돌 때만 문다. 둘을 함께 지운 PR 은 리뷰가 본다.
- **검사의 인자 · 묶음 안의 자리** — 이름과 횟수만 본다(요구사항 하지 않을 일 2). 묶음은 T2 가 보고(늘 도는 것이 `bites` 로 가면 떨어진다), 차례는 T1 의
  「변조 시험은 맨 뒤」만 본다.
- **부르는 스크립트의 속** — 가짜로 바꿔 세우므로 진짜 검사가 무는지는 각자의 변조 시험이 든다. `GATES_FAIL` 로 띄운 실패가 아닌 꼴(진짜 검사가 늘 0 으로
  끝나게 바뀌기)은 그 검사의 변조 시험 몫이다.
- **일부러 감춘 우회** — 가짜를 알아보는 `gates.sh`(예: `GATES_RAN` 이 있으면 다르게 돈다) 같은 것. 모양 · 동작 시험이다 — 실수로 흔든 줄을 문다.
- **`eval.yml` 이 `gates.sh` 를 부르는 모양** — 조각 37 의 `verify-eval-gate.py` 가 든다(요구사항 하지 않을 일 3).

## ③ 받는 입력

검사 장치다 — 받는 모양을 실제 파일에서 뽑은 닫힌 목록으로 든다(`main` `b05c20a` 의 `scripts/gates.sh`). B 의 `test-gates.py` 가 이 목록을 코드로 들고, 그
뒤에 검사를 더하거나 빼는 PR 은 그 목록을 함께 고친다.

**A — 인자.** 지금 그대로다.

| # | 꼴 | 받는가 |
|---|---|---|
| A1 | 없음 | 받는다 — 저장소의 `scripts/gates.sh` |
| A2 | `-` 로 시작하지 않는 경로 하나 | 받는다 — 그 파일 |
| A3 | 인자 둘 이상 · `-` 로 시작하는 인자 | 거절 — 종료 2 |

**L — 고정 목록.** 이름은 `test-gates.py` 의 `calls` 가 내는 것 — 스크립트는 파일 이름, `claude plugin validate` 는 `claude:<폴더>`. 다 한 번씩이다.

| # | 묶음 | 이름 |
|---|---|---|
| L1-c | `checks` — 늘 도는 스물셋 | `claude:./vibe-audit` · `claude:./vibe-slice` · `verify-manifest.py` · `test-verify-manifest.py` · `verify-copies.py` · `verify-feedback.py` · `verify-evals.py` · `verify-graders.py` · `verify-budget.py` · `test-verify-brief.py` · `test-compare-copies.py` · `test-verify-feedback.py` · `verify-copy.py` · `verify-docs.py` · `test-verify-docs.py` · `test-sync-slice.py` · `verify-slice-gate.py` · `test-verify-slice-gate.py` · `verify-map-pin.py` · `test-verify-map-pin.py` · `test-eval-merged-pass.py` · `verify-eval-gate.py` · `test-gates.py` |
| L1-b | `bites` — 변조 시험 다섯(지금의 `FIVE`) | `bite-verify-docs.py` · `bite-slice-gate.py` · `bite-map-pin.py` · `bite-eval-merged-pass.py` · `bite-gates.sh` |

**자유로운 것** — 검사 줄의 차례(변조 시험 다섯이 맨 뒤라는 T1 안에서) · 주석 줄 · 빈 줄 · 인자.

## ④ 결정

**정한 것**

- 이 관찰을 고정 목록 시험으로 닫는다 — 두지 않는다는 ADR 대신. ADR 0049 의 1.
- 목록의 자리는 `test-gates.py` 안이다 — 따로 둔 목록 파일이나 `bite-gates.sh` 의 한 절 대신. ADR 0049 의 2.
- 고정하는 것은 이름과 횟수다 — 차례 · 인자 · 줄 글자 그대로 대신. ADR 0049 의 3.
- 실패를 삼키는 꼴은 동작으로 문다(스물여덟마다 가짜 하나를 떨어뜨린다) — 금지하는 꼴의 목록 대신. ADR 0049 의 4.
- `test-gates.py` 자기 줄은 `bite-gates.sh` 가 진짜 `gates.sh` 에 한 번 불러 문다. ADR 0049 의 5.
- `CLAUDE.md` 의 그 줄에 예외를 적는다. ADR 0049 의 6.
- PR 나눔 — 구현은 B 하나. ADR 0049 의 7.

**열어 둔 것**

없음 — 1 과 6 은 저자가 이 착공 세션에서 정했고(2026-10-26), 2 ~ 5 와 7 은 세션이 제안해 착공 PR 에서 저자가 본다.

## ⑤ 검증 계획

시험을 세우는 조각이다(늘 도는 자체 시험을 넓히고 그 변조본 · 대조군을 더한다). 꼴 하나하나와 변조본의 대응은 B 의 PR 본문이 든다.

- **시험 규칙**
  - R1 ② 의 조건마다 변조본 하나 이상 — L2(지우기 · 주석 처리 · 겹치기 · 목록에 없는 이름 더하기 · `claude plugin validate` 줄 지우기) · S1(T1 의 꼴에서
    삼키기 · T1′ 의 꼴에서만 삼키기 · `claude plugin validate` 줄 삼키기 · `checks` 머리의 `set +e`) · S2(`--skip-bite` 에서만 삼키기) · R(`test-gates.py` 줄
    지우기 — 사본에서 L2 로). 감사가 든 둘(늘 도는 검사 줄 지우기 · 그 줄 뒤의 `|| true`)은 꼭 든다 — 감사가 예로 든 `verify-eval-gate.py` 줄로.
  - R2 자유로운 것마다 대조군 하나 — 늘 도는 두 검사 줄의 차례 바꾸기 · 주석 줄 바꾸기(V2).
  - R3 새 변조본 · 대조군이 바꿀 글은 `gates.sh` 에 꼭 한 번. 새 변조본의 「물었다」는 종료 1 · 기대한 번호의 `FAIL` 줄(V1).
  - R4 앞 변조본 아홉은 그대로 둔다(V3) — 「물었다」의 좁히기는 새 변조본에만 건다.
- V1 **성공 기준 1** — B 의 로컬과 CI 의 gate 잡 로그에서 `PASS test-gates.py — …`(고정 목록 스물여덟) · 「스물여섯 다 통과」.
- V2 **성공 기준 2 · 3** — B 의 CI 로그에서 `test-gates.py` 절의 끝 줄(변조본 수 · 대조군 수 · 진짜 `gates.sh`). 감사가 든 둘을 손으로 재현해 B 의 PR 본문에
  싣는다 — B 앞의 `test-gates.py` 는 통과시키고 B 의 것은 떨어뜨리는 것을 보인다.
- V3 **성공 기준 4** — B 의 diff 에서 네 문서의 그 줄.
- V4 **성공 기준 5** — B 의 CI gate 잡 로그에서 `test-gates.py` 앞뒤 줄의 시각. 로컬 시간도 PR 본문에 싣는다.
- V5 **성공 기준 6** — 각 PR 의 CI gate 잡 · eval 잡(다 skipped). B 의 작업트리에서 인자 없는 `./scripts/gates.sh` 를 끝까지 돌려 시간과 끝 줄을 PR 본문에
  싣는다(백그라운드).
- V6 **성공 기준 7** — B 가 머지된 뒤 `main` 에서 기준 `b05c20a` 로 `audit-quality` 를 돌리고 닫는 PR 의 대장에 등록한다.
- 단계 5 — 배포처는 이 저장소의 CI 다. 보이는 것은 V1 의 실행이다. 되돌리는 길은 B 를 되돌리는 것이다 — 수트는 돌지 않는다.

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A | 착공 — 마스터플랜 · 이 요구사항 · 설계 · ADR 0049 | 단계 0 ~ 2 |
| B | `test-gates.py` 의 고정 목록 · 실패 전파 · 셸 가짜, `bite-gates.sh` 의 변조본 · 대조군 · 진짜 `gates.sh` 부르기, `gates.sh` 머리 주석 · `CLAUDE.md` · `docs/architecture.md` · `CHECKLIST.md` 의 예외 | ② L · S · R · V · 성공 기준 1 ~ 6 |
| 닫기 | 닫기 전 감사 회차의 등록 · 요구사항 끝의 `## 닫으며` · 마스터플랜 38 을 `닫힘` · 다음 조각 | 단계 6 · 성공 기준 7 |

B 하나로 두는 까닭 — 목록 · 그 시험 · 예외를 적은 규칙이 한 묶음이다. 규칙만 먼저 고치면 그 사이 `CLAUDE.md` 가 없는 시험을 가리키고, 시험만 먼저 넣으면 그
사이 `CLAUDE.md` 가 그 시험과 어긋난다. 수트가 돌지 않아 PR 을 나눠 아낄 비용도 없다.
