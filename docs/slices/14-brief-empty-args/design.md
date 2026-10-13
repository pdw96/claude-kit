# 조각 14 설계 — 브리핑 커맨드의 빈 인자

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`, 갈림길은 ADR 0023.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A | 「브리핑 커맨드의 빈 인자」 상태 `진행` · 조각 폴더 |
| `docs/adr/0023-brief-named-args.md` | A | 갈림길 넷 |
| `vibe-audit/commands/audit-brief.md` | B | 프런트매터 `arguments: [base, auditor]`. 본문의 `$0` 여섯 → `$base`, `$1` 셋 → `$auditor`. 「`$0` 은 기준, `$1` 은 감사자」 괄호 줄을 지우고, 빈 인자를 가리키는 두 문장을 빈 문자열로 읽히게 고친다(② C1 · C2). 늘어난 글자는 커맨드 안에서 압축한다 |
| `vibe-audit/.claude-plugin/plugin.json` | B | 판 0.3.0 → 0.3.1 |
| `vibe-audit/evals/budget.txt` | B | `verify-budget.py --write` 가 쓴 그대로 |
| `vibe-audit/evals/command-base-only/` | B | 새 케이스 — `case.yaml` · `prompt.md` · `fixture.sh` · `graders/` · `samples/`(② K1 ~ K4) |
| `scripts/verify-evals.py` | B | 셋째 모양 「커맨드 케이스」(`command-*`)를 안다(② V1 ~ V3). 머리 독스트링 · 끝의 PASS 줄의 셈 |
| `scripts/bite-gates.sh` | B | `verify-evals.py` 변조 — 커맨드 케이스의 대조군을 뺀 수트 · 없는 커맨드를 부르는 수트가 떨어진다(② V4) |
| `vibe-audit/evals/README.md` | B | 「케이스」 표에 한 줄 · 「오검율」의 판정 케이스 앞머리 목록에 `command-*` · 「키 없이도 무는 게이트」의 `verify-evals.py` 줄 |
| `docs/eval-log/2026-10.md` | B | 날짜 항목 — 왜 · 바꾼 것 · 예산 · 판 · 새 케이스 · 옛 · 새 커맨드의 점수 |

**앵커볼트.** 이름(`audit-brief` · `vibe-audit`)은 그대로다 — 부르는 이름 `/audit-brief` · `/vibe-audit:audit-brief` 가 같다. 감사자 파일 ·
감사자의 `tools` · 공통 절 · 대장의 모양 · 「…의 칸」 · `AGENTS.md` 는 건드리지 않는다. **글자 예산의 천장**도 그대로다(하지 않을 일 3).

**고정 영역.** `run-evals.sh` · `eval.yml` 의 러너 부분 · 정규식 그레이더의 규칙은 고치지 않는다. 새 케이스의 정규식 그레이더는 새 파일이고,
지금의 종류(`regex` · `tool_used` · `file_exists`)만 쓴다.

**사실.**
- 후보 대장에 줄이 없다 — 사본 덩어리에서 온 후보가 아니다(하지 않을 일 2).
- `verify-copies.py` 는 사본 커맨드의 있음과 머리말(`name` · `description`)만 본다. 프런트매터에 `arguments` 한 줄이 늘어도 사본 둘은
  옛 커맨드라 그대로 통과한다.
- 수트 지문 — 커맨드 · `plugin.json` · `verify-evals.py` 가 `route --list` 에, 새 케이스가 `full --list` 에 든다. `bite-gates.sh` ·
  `README.md` · `docs/` 는 밖이다.

**시스템 구조.** 부품 · 경계 · 흐름은 그대로다 — `docs/architecture.md` 의 「브리핑 커맨드 · 검사기」 줄은 바뀌지 않는다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 번호는 ⑤ 와 PR 본문이 같이 쓴다.

- **커맨드** (`audit-brief.md`)
  - C1 본문에 번호 자리표시(`$0` ~ `$9` · `$ARGUMENTS[N]`)와 `$ARGUMENTS` 가 없다. 기준은 `$base`, 감사자는 `$auditor` 로만 받는다 —
    `grep -nE '\$([0-9]|ARGUMENTS)'` 가 빈 출력.
  - C2 빈 인자를 가리키는 두 문장이 빈 문자열에서 뜻이 선다 — 기준이 비면 git 을 돌리기 전에 묻고 멈추고, 감사자가 비면 감사자를
    부르기 전에 묻는다. 펼친 글이 `` `` 가 비어 있으면 `` 처럼 빈 백틱만 남아도 읽히게 쓴다(예: 「기준(`$base`)이 비어 있으면」).
  - C3 인자를 다 준 부름(`/audit-brief origin/main audit-secrets`)은 지금과 같은 글이 된다 — 바뀐 자리의 펼친 글이 옛 커맨드의 그것과 같은
    값을 든다. 「사람이 없는 자리」의 예시 줄은 그대로다.
  - C4 모으는 명령 · 브리핑의 모양 · 검사기 · 남기는 것의 문장은 바뀌지 않는다 — 압축은 그 밖의 자리에서 한다. `git diff` 가 그 자리를 담지
    않는다(압축이 그 자리에 닿아야 하면 저자에게 올린다 — 하지 않을 일 3).
  - C5 `claude plugin validate ./vibe-audit` 통과 · `verify-budget.py` 통과(천장 4,500 그대로) · `verify-copies.py` 통과.
- **케이스** (`command-base-only`)
  - K1 픽스처는 커밋 둘인 git 저장소다(`brief-used` 의 두 커밋과 같은 꼴, 브리핑은 두지 않는다). `prompt.md` 는
    `/vibe-audit:audit-brief HEAD~1` 한 줄 — 감사자를 주지 않는다.
  - K2 대조군 `command-ran` — `file_exists` 로 `.claude/audit-brief.md` 를 요구한다. 커맨드가 펴지지 않았거나 아무것도 안 한 세션은 여기서
    떨어진다. 덫만 있으면 아무것도 안 하는 세션이 만점이다.
  - K3 덫 `trap-no-guessed-auditor` — `tool_used` Agent, `input_match` `"subagent_type":"vibe-audit:` 가 `min: 0 · max: 0`. 감사자를 짐작해
    부르거나 `vibe-audit:$1` 을 글자 그대로 부르면 떨어진다. 무게는 이것 하나만 매번 떨어져도 문턱 0.8 아래로 가게 둔다.
  - K4 목적 `gate-asks-auditor` — 정규식, 마지막 응답이 감사자를 고르라고 묻는다. 표본 `samples/pass.md` 와 `fail*.md`(감사자를 묻지 않고
    끝낸 응답 하나 이상)를 `verify-graders.py` 가 가른다.
  - K5 `allowed_tools` 는 커맨드가 쓰는 도구를 담는다 — `Bash` · `Read` · `Write` · `Glob` · `Grep` · `Agent`(덫이 볼 자리) · `TodoWrite`.
- **수트 검사** (`verify-evals.py`)
  - V1 앞머리 `command-` 인 케이스를 셋째 모양으로 본다. `prompt.md` 의 첫 줄이 `/<플러그인>:<커맨드>` 로 시작하고 그 커맨드가
    `commands/<커맨드>.md` 로 실재해야 한다.
  - V2 대조군 `command-ran` 과 목적 그레이더(`trap-*` · `gate-*`) 하나 이상을 요구한다. 판정 케이스의 `real-nc-found` · `auditor-fired` ·
    감사자 지목은 요구하지 않는다 — 감사자를 부르지 않는 것이 이 모양의 정상이다.
  - V3 판정 케이스와 같은 규칙은 그대로 든다 — `arm` 은 붙이지 않는다 · 스캐폴드 선언과 실행 비트 · 심판 무게.
  - V4 `bite-gates.sh` 가 변조본 둘로 V1 · V2 가 무는 것을 본다 — `command-ran` 을 지운 수트, `prompt.md` 의 커맨드 이름을 없는 이름으로
    바꾼 수트. 둘 다 `verify-evals.py` 가 떨어뜨려야 한다.
- **측정**
  - M1 새 케이스를 옛 커맨드(케이스만 담은 커밋)와 새 커맨드로 각각 세 회차 잰다. 두 점수와 그레이더별 통과를 PR 본문과
    `docs/eval-log/2026-10.md` 에 적는다.
  - M2 구현 PR 의 route 수트가 CI 에서 통과한다(문턱 1.0).

**보장하지 않는 것(알려진 한계)**

- **옛 커맨드가 덫을 밟는지** — 결함은 문서가 적은 치환 규칙이라 고치지만, 모델이 글자 그대로의 `$1` 을 「없음」으로 읽고 물어 옛 커맨드도
  통과할 수 있다. 그러면 케이스는 결함을 재현하지 못한 회귀 검사로 남고, 그 사실을 기록에 적는다(성공 기준 2).
- **eval 이 플러그인 커맨드를 펴는지** — 헤드리스 문서(code.claude.com/docs/en/headless)는 `-p` 프롬프트의 `/skill-name` 을 편다고
  적고, `claude plugin eval` 의 공식 문서는 열리지 않았다(2026-10-13, 404). 첫 측정에서 본다 — 펴지 않으면 대조군 K2 가 떨어져 드러나고,
  그때의 길은 ④ 의 열어 둔 것이다.
- **인자 없는 부름** — 수트로 재지 않는다(하지 않을 일 6). 단계 5 에서 저자가 한 번 본다.
- **셋째 인자 이상** — `arguments` 에 이름이 둘이라 셋째부터는 받지 않는다. 이름 자리표시가 있으면 Claude Code 가 `ARGUMENTS:` 를 덧붙이지
  않으므로(문서) 남는 인자는 말없이 버려진다. 옛 커맨드에서도 셋째 인자는 쓰이지 않았다.
- **사본 레포의 커맨드** — ERP · 강호쟁패의 사본은 옛 글자다(하지 않을 일 1). 다음 심기 전까지 그 레포에서는 결함이 남는다.
- **헤드리스의 묻기** — eval 세션은 사람이 없어 「묻는다」는 마지막 응답의 글로만 잰다. `AskUserQuestion` 을 쓰는지는 보지 않는다.
- **아직 겪지 않은 가설적 경계 사례** — 예: 기준에 따옴표 · 공백을 담은 인자, 이름 자리표시와 같은 글자의 다른 낱말. 겪으면 그 PR 에서 정해
  날짜 항목으로 적는다. 리뷰가 이것을 짚으면 범위 밖이다(조각 6 「닫으며」).

## ③ 받는 입력

닫힌 목록이다. 2026-10-13 의 claude-kit `main`(83ac86d)과 Claude Code 문서에서 뽑았다.

**커맨드의 자리표시** — `vibe-audit/commands/audit-brief.md`(호출 시 4,458자 · 상시 285자).

| 자리 | 줄 | 뜻 |
|---|---|---|
| `$0` | 본문 여섯 — 머리 문장 · 괄호 줄 · 「비어 있으면」 · 「하나」의 글자 검사 · `rev-parse` · 「`$0` 대신 `<B>`」 | 기준 |
| `$1` | 본문 셋 — 괄호 줄 · 「넷」의 「주어졌으면」 · `@vibe-audit:$1` | 감사자 |
| `$ARGUMENTS` · `$ARGUMENTS[N]` | 없다 | — |
| `$base` · `$auditor` | 없다 — 이름이 지금 본문의 다른 글자와 겹치지 않는다 | — |
| `$f` · `$(…)` | 「추적 안 된 파일」의 셸 줄 · 「하나」의 `cd "$(git rev-parse …)"` | 셸 — 자리표시가 아니다(이름 · 숫자에 걸리지 않는다) |

**Claude Code 의 치환** — code.claude.com/docs/en/skills(2026-10-13). 커맨드 파일은 스킬과 같은 프런트매터를 받는다(plugins/components).

| 무엇 | 문서가 적은 것 |
|---|---|
| 번호 자리표시 | 「`$N` 은 `$ARGUMENTS[N]` 의 줄임」 · 「짝이 없는 번호 자리표시는 바뀌지 않고 남는다」 |
| 이름 자리표시 | 「프런트매터 `arguments` 목록에 적은 이름 — 차례대로 자리에 맞는다」 · 「짝이 없으면 빈 문자열」 · `arguments` 는 공백으로 가른 문자열이나 YAML 목록 |
| 나누기 | 셸식 따옴표 — `"hello world" second` 는 둘 |
| `ARGUMENTS:` 덧붙임 | 인자를 줬는데 받는 자리표시가 없으면 본문 끝에 `ARGUMENTS: <입력>` 을 덧붙인다. 이름 자리표시는 짝이 없어도 받은 것으로 센다 |
| 글자 그대로의 `$` | 숫자 · `ARGUMENTS` · 선언한 이름 앞의 `$` 는 `\$` 로 막는다 |

**미리 본 것** — 이 세션이 2026-10-13 에 버리는 사본(`vibe-audit/` 를 복사)의 커맨드 프런트매터에 `arguments: [base, auditor]` 를 넣고
`claude plugin validate`(CLI 2.1.296)를 돌려 통과했다. 사본은 지웠다.

**수트 검사가 지금 아는 모양** — `verify-evals.py` 는 케이스를 둘로 가른다. 앞머리 `route-` 는 트리거, 그 밖은 다 판정이다 — 판정은
`prompt.md` 가 감사자를 지목하고 · `trap-*`/`gate-*` · `real-nc-found` · `auditor-fired` 를 요구한다. 커맨드를 부르는 케이스는 없다.
`run-evals.sh` 는 `auditor-fired` 가 **있는** 케이스에서만 그것을 따로 문다 — 없는 케이스는 지금 규칙 그대로 돈다.

**eval 세션** — 케이스마다 새 `claude -p` 세션, `case.yaml` 의 `allowed_tools` 밖의 도구는 막힌다. 지금 케이스 스물다섯의
`allowed_tools` 는 다 `[Read, Glob, Grep, Agent, TodoWrite]` 다 — `Bash` · `Write` 를 여는 케이스는 이것이 처음이다.

## ④ 결정

**정한 것** — ADR 0023. 넷 다 세션 제안 · 저자 확인 대기.

- 1 빈 인자를 받는 꼴 — 프런트매터 `arguments` 의 이름 자리표시
- 2 케이스 — 기준만 준 부름 하나(`command-base-only`), 대조군은 브리핑을 쓴 것
- 3 수트 검사 — `verify-evals.py` 가 셋째 모양 「커맨드 케이스」를 안다
- 4 사본 — 이 조각에서 다시 심지 않는다

**열어 둔 것**

- **eval 이 플러그인 커맨드를 펴지 않을 때의 길** — B 의 첫 측정(옛 커맨드)에서 K2 가 커맨드가 안 펴진 까닭으로 떨어지면, B 가 새
  커맨드를 담기 전에 저자가 정한다. 후보: `prompt.md` 를 커맨드 이름 없이 「`vibe-audit` 의 `audit-brief` 커맨드를 `HEAD~1` 로」처럼
  풀어 쓴다 / 케이스를 세우지 않고 단계 5 로만 본다(되먹임 한 건에 케이스 하나를 어긴다 — 저자 판정).

## ⑤ 검증 계획

명령은 PR 본문에 결과와 함께 적는다. 「어긋내 보기」는 일부러 망가뜨린 작업트리에 같은 명령을 대어 떨어지는지 본 뒤 되돌린다.

**PR A**

- `./scripts/gates.sh` 통과 — `verify-docs.py` 가 새 조각 폴더를, `verify-slice-gate.py` 가 착공 PR 에 결정 문서뿐인지를 본다.
- 지문 — `git diff --name-only main...HEAD` 와 `eval-key.py route --list` · `full --list` 의 교집합 0. eval 잡이 건너뛴다.

**PR B** — 커밋 둘로 낸다. 첫 커밋은 케이스 · `verify-evals.py` · `bite-gates.sh` 만, 둘째가 커맨드 · 판 · 예산 · 문서.

- M1 옛 — 첫 커밋에서 `./scripts/run-evals.sh --case command-base-only` 세 회차(돌릴 수 없는 자리면 그 커밋의 가지에서 `workflow_dispatch`
  전수). 점수와 그레이더별 통과.
- M1 새 — 둘째 커밋에서 같은 명령. 성공 기준 2.
- C1 — `grep -nE '\$([0-9]|ARGUMENTS)' vibe-audit/commands/audit-brief.md` 빈 출력. 어긋내 보기 — `$base` 하나를 `$0` 으로 되돌리면 한 줄.
- C3 — 인자 둘을 준 펼친 글을 옛 · 새 커맨드에서 손으로 펼쳐(`$0`·`$base` → `origin/main`, `$1`·`$auditor` → `audit-secrets`) 바뀐 자리를
  견준다. 견준 diff 를 PR 본문에.
- C4 — `git diff main...HEAD -- vibe-audit/commands/audit-brief.md` 가 「둘」의 명령 표 · 브리핑 틀 · 「남기는 것」을 담지 않는다.
- C5 · V1 ~ V4 · K4 — `./scripts/gates.sh` 통과(로컬과 CI gate 잡). 어긋내 보기 — V4 의 변조 둘을 `bite-gates.sh` 밖에서 손으로 한 번씩
  만들어 `verify-evals.py` 가 FAIL 인 것을 본다.
- M2 — CI eval 잡(route)이 PR 머리에서 통과.
- 예산 — `budget.txt` 의 diff 를 PR 본문에.

**스스로 쓰기** — PR A · B 의 리뷰를 `slice-review` 로 가른다. PR 본문의 `## 리뷰 회차` 와 답글. B 는 `verify-slice-gate.py` 를 CI 에서
지나간다(이 착공이 머지된 뒤).

**단계 5(배포)** — 배포처는 마켓플레이스다. B 가 머지된 뒤 저자가 대화형 세션에서 `claude plugin update` 로 0.3.1 을 받고 새 세션에서
`/vibe-audit:audit-brief` 를 인자 없이 부른다 — git 을 돌리기 전에 기준을 묻는지 본다(성공 기준 6). 되돌리는 길은 B 의 되돌림과 판을 한 번 더
올리는 것이다.

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A 착공 | 요구사항 · 설계 · ADR 0023 · 마스터플랜(「브리핑 커맨드의 빈 인자」 `진행`) | 단계 1 · 2 |
| B 커맨드 · 케이스 | 커맨드 · `plugin.json` · `budget.txt` · 새 케이스 · `verify-evals.py` · `bite-gates.sh` · `vibe-audit/evals/README.md` · `docs/eval-log/2026-10.md` | ② 의 C1 ~ C5 · K1 ~ K5 · V1 ~ V4 · M1 · M2, 성공 기준 1 ~ 5 · 7, 단계 5 의 성공 기준 6 |

케이스와 커맨드를 한 PR 에 둔다 — route 수트는 지문을 바꾼 PR 머리마다 돌아, 둘로 나누면 적어도 두 번 돈다. 옛 · 새 점수는 B 의 커밋 둘로
가른다. 조각을 닫는 기록은 단계 5 를 본 뒤 따로 낸다(단계 6).
