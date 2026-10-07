# 조각 4 설계 — README · CLAUDE.md 를 제 역할로 줄이기

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`. 칸의 모양은 `docs/procedure.md` 「설계 문서의 칸」.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/slices/4-doc-roles/requirements.md` · `design.md` | A | 이 조각의 요구사항 · 설계 |
| `docs/adr/0011-entry-docs-and-eval-log.md` | A | 기록의 자리 · 나누는 법 · 시스템 구조 · `AGENTS.md` 의 가리킴과 `route-ops` 줄 · 옛 참조 · 검사 |
| `docs/master-plan.md` | A | 조각 나눔 「README · CLAUDE.md 를 제 역할로 줄이기」 — 상태 `진행` · 조각 폴더 |
| `docs/eval-log/2026-09-16_2026-10-06.md` | B | 지금의 `vibe-audit/evals/README.md` 를 글자 그대로 옮긴 첫 기록 파일(`git mv`) |
| `vibe-audit/evals/README.md` | B | 새로 쓴다 — 살아 있는 문서. 절: 재는 것(오검율 · 트리거) · 케이스 표 · 재는 법(그레이더 · 대조군 · 심판 · 키 없는 게이트 · 러너) · 고정한 것 · 기록. 머리에 「2026-10-06 까지의 절은 `docs/eval-log/2026-09-16_2026-10-06.md` 에 글자 그대로 있다」 한 줄 |
| `AGENTS.md` | B | 「Review guidelines」의 세 가리킴을 살아 있는 README 「고정한 것」으로(ADR 0011 의 4). `route-ops` 공백 줄을 지운다(ADR 0011 의 7). 고정한 대상 · 날짜 · 알려진 한계의 말은 그대로 |
| `docs/procedure.md` | B · C | 「살아 있는 문서와 기록」 — B: `vibe-audit/evals/README.md` 를 살아 있는 문서로, 기록 칸에 `docs/eval-log/` 와 그 이름 규칙(L2), 규칙 「수를 늘리지 않는다」를 「늘리려면 ADR 로 정한다」로(ADR 0011). C: 살아 있는 문서에 `docs/architecture.md` |
| `CHECKLIST.md` | B | 「항상」의 기록 목록에서 `vibe-audit/evals/README.md` → `docs/eval-log/`, 새 기록 파일의 이름이 L2 에 맞는지 사람이 보는 칸 |
| `vibe-audit/README.md` | B | 수트를 가리키는 두 줄(114 · 119)만 — 없는 절 「자기 트리거」를 살아 있는 README 의 있는 절로 |
| `docs/architecture.md` | C | 새로 쓴다 — 부품(플러그인 · 스크립트 · 대장 둘 · CI 잡)과 흐름(심기 → 견주기 → 판정 → 되먹임 → 케이스 → 수트). README 에서 걷은 검사 넷의 설명이 여기로 온다 |
| `README.md` | C | 입구로 줄인다 — 들어 있는 것 · 설치(두 경로) · 새 프로젝트를 열 때 · 가리키는 곳 |
| `CLAUDE.md` | C | 「스택」의 값 셋을 주인 가리킴으로 · 「작업 방식」의 되먹임 출처 `(README)` → `INTENT.md` · 「가변」의 작업 기록 → `docs/eval-log/`. 앵커볼트 · 금지 절의 줄은 그대로 |
| `INTENT.md` | C | 되먹임 원칙의 가르는 질문(「다른 레포에서도 같은 말인가」)을 Why 에 — README 에서 옮긴다. What · Not 은 그대로라 「범위 변경」이 아니다 |
| `docs/master-plan.md` | B · C | 「가리키는 문서」 — B: 「감사자가 왜 지금 모양인가」 줄에 `docs/eval-log/`. C: 「시스템 구조」 줄을 `docs/architecture.md` 로 |

**앵커볼트를 건드린다** — `AGENTS.md` 「Review guidelines」(고정 영역)의 문구다. 가리키는 자리가 바뀌고 사실이 아닌 `route-ops`
공백 줄이 빠진다. 고정한 대상(러너 · 정규식 그레이더 · 브리핑 검사기)과 알려진 한계는 바뀌지 않는다. 저자가 정했다(ADR
0011 의 4 · 7). 감사자 · 대장 ·
러너 · 스크립트는 건드리지 않는다. 부품이 늘지 않지만 시스템 구조 문서가 생긴다 — 그 문서를 세우는 것이 PR C 다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 번호는 ⑤ 와 구현 PR 본문이 같이 쓴다.

- **기록**
  - L1 `docs/eval-log/2026-09-16_2026-10-06.md` 가 PR B 의 기준 커밋의 `vibe-audit/evals/README.md` 와 바이트로 같다.
  - L2 `docs/eval-log/` 의 파일 이름은 첫 파일 말고 `<YYYY-MM>.md` 다. 2026-10-07 부터의 기록은 `2026-10.md` 부터 쌓는다.
    이 규칙은 살아 있는 문서 둘이 든다 — `docs/procedure.md` 「살아 있는 문서와 기록」의 기록 줄과 살아 있는 수트 README
    「기록」 절. PR B 의 머리에서 그 폴더의 이름이 다 이 규칙에 맞는다.
- **살아 있는 수트 문서**(`vibe-audit/evals/README.md`)
  - E1 케이스 표가 `vibe-audit/evals/` 의 케이스 폴더마다 꼭 한 줄이고, 표에 없는 폴더도 폴더 없는 줄도 없다.
  - E2 날짜를 박은 작업 기록 절이 없다 — 제목에 `YYYY-MM-DD` 가 든 절이 0 개(괄호 뒤에 말이 붙은 꼴도).
  - E3 「고정한 것」 절이 셋(러너 · 정규식 그레이더 · 브리핑 검사기)을 들고, 각각의 알려진 한계를 옮기기 전과 같은
    범위로 든다. 처음 고정한 날짜는 기록 파일의 절을 가리킨다. 옛 절이 적은 공백 가운데 지금은 메워진 것은 옮기지
    않는다 — `route-ops` 공백(2026-09-25)은 케이스 `route-ops` 가 생겨 메워졌다(같은 파일 「새 route 케이스 둘」).
  - E4 머리의 한 줄이 첫 기록 파일을 가리킨다 — 옛 참조 `evals/README.md 「…」` 는 그 파일에서 찾는다.
- **입구와 규칙**
  - R1 README 의 `##` 절은 넷 이하이고, 되먹임 이야기와 검사 넷의 설명이 없다. 가리키는 곳이 걷은 값의 주인으로
    잇는다 — `INTENT.md` · `docs/master-plan.md` · `docs/architecture.md` · `vibe-audit/evals/README.md`.
  - R2 README 에서 지운 문단마다 그 값의 주인이 PR C 의 머리에 있다 — PR C 본문의 대응표(문단 → 주인 파일 · 절).
  - R3 CLAUDE.md 에 CLI 버전 숫자 · 모델 id · CI 잡 이름이 없고, 그 자리의 줄이 주인 파일을 가리킨다.
  - R4 목표 · 범위(Why · What · Not)를 `INTENT.md` 만 든다 — README 는 한 줄 소개와 링크뿐이다.
- **가리킴**
  - P1 살아 있는 문서(`AGENTS.md` · `CLAUDE.md` · `CHECKLIST.md` · `docs/procedure.md` · 마스터플랜 · `README.md` ·
    `vibe-audit/README.md` · `docs/architecture.md`)가 「…」로 가리키는 수트 문서의 절이 다 있는 절이다.
  - P2 마스터플랜 「가리키는 문서」의 경로가 다 있다 — `verify-docs.py` M2 가 문다.
  - P3 작업 기록을 말하는 자리가 `docs/eval-log/` 를 가리킨다 — `CLAUDE.md` 「가변」 · `CHECKLIST.md` 「항상」 ·
    `docs/procedure.md` 「살아 있는 문서와 기록」의 기록 줄 · 마스터플랜 「감사자가 왜 지금 모양인가」 줄. 그 표의 살아 있는
    문서 줄에 수트 README(PR B)와 `docs/architecture.md`(PR C)가 든다.
- **실행**
  - X1 구현 PR 이 바꾼 파일 가운데 수트 지문에 드는 것이 0 개다.
  - X2 `./scripts/gates.sh` 열둘이 PR 마다 통과한다.

**보장하지 않는 것(알려진 한계)**

- **수트 지문 안 파일과 기록의 옛 참조** — `run-evals.sh` · `eval-key.py` · `sync-agents.sh` · `eval.yml` ·
  `verify-brief.py` · 그레이더 · 조각 폴더 · ADR 의 `evals/README.md 「…」` 는 살아 있는 README 의 E4 줄을 거쳐야
  찾는다(ADR 0011 의 5). 다음에 그 파일을 고치는 PR 이 따라 고친다.
- **첫 기록 파일의 내용** — 뒤섞인 순서, 지금은 낡은 숫자 · 시간에 기댄 문장, 「루트 README」처럼 지금은 없는 자리를
  가리키는 말. 글자 그대로 옮긴 기록이다(L1).
- **README · CLAUDE.md 가 나중에 값을 다시 드는 것 · 나중의 기록 파일 이름** — 검사가 없다. 사람이 본다(ADR 0011 의 6 ·
  `CHECKLIST.md`). ⑤ 의 명령은 구현 PR 의 머리에서 한 번 대어 보는 것이다.
- **`docs/architecture.md` 가 완전한가** — PR C 의 날의 부품과 흐름을 든다. 그 뒤는 절차 3 단계의 나가는 조건이 사람에게
  맡긴다. 그 문서의 모양(필수 절)은 정하지 않는다.
- **문장의 질** — 살아 있는 README · architecture 의 서술이 잘 읽히는가. 리뷰가 이 밖을 짚으면 범위 밖이다.
- **`vibe-audit/README.md` 의 나머지 서술** — 두 줄 말고는 보지 않는다(요구사항 하지 않을 일 4).
- **다른 레포** — 조각 나눔 「틀 배포」.

## ③ 받는 입력

검사 장치가 아니다 — 옮기고 줄일 대상의 닫힌 목록이다. 2026-10-06 의 실제 파일(559685e)에서 뽑았다. 이 밖의 파일은
옮기지도 줄이지도 않는다.

**`README.md`(152줄)** — 절과 그 값의 주인.

| 절 | 남나 | 주인 |
|---|---|---|
| 머리말 · `## 들어 있는 것` | 남는다 | — |
| `## 배포 경로가 둘인 이유` · `### ①` · `### ②` | 남는다 — 설치다 | 버그 표도 설치의 근거라 남는다 |
| `## 사본은 갈려도 된다 — 방향만 정해 둔다` 의 원칙 문단(특화 · 결함 · 가르는 질문) | 걷는다 | `INTENT.md` Why |
| 같은 절의 1 ~ 3차 되먹임 이야기 | 걷는다 | 살아 있는 수트 README 의 케이스 표(되먹임 · 날짜 · 새던 자리) · 각 `case.yaml` 의 `description` · 첫 기록 파일 · git |
| `### 되먹인 자리마다 회귀 검사를 세운다` | 걷는다 | 살아 있는 수트 README 「재는 것」 · 「재는 법」 |
| `### 사본이 원본의 공통 절을 …` · `### 견줄 상대는 대장에서 온다` · `### 갈린 자리를 뽑아 …` | 걷는다 | `docs/architecture.md` · 각 스크립트 머리말 · `docs/schema.md` · ADR 0001 ~ 0003 |
| `## 감사 계획과 부적합 대장` | 걷는다 | `INTENT.md` Not 3 |
| `## 새 프로젝트를 열 때` | 남는다 | — |

**`CLAUDE.md`(49줄)** — 값을 든 줄 넷.

| 줄 | 값 | 주인 |
|---|---|---|
| 「스택」 Claude Code CLI | `2.1.28x` | 고정하지 않는다 — 수트 지문(`eval-key.py`)이 실행마다 기록 |
| 「스택」 CI | 잡 이름 셋 | `.github/workflows/eval.yml` |
| 「스택」 수트 모델 · 심판 | `claude-sonnet-5-5` · `sonnet` | `scripts/run-evals.sh` |
| 「작업 방식」 되먹임 | 출처 `(README)` | `INTENT.md` |

**`vibe-audit/evals/README.md`(2157줄)** — 살아 있는 문서로 가져갈 것.

- 케이스 폴더 스물넷 — `brief-*` 둘 · `cycle-*` 둘 · `gap-unowned` · `gate-*` 여섯 · `route-*` 열 · `trap-*` 셋. 지금 표는
  다섯 줄이다.
- 날짜 없는 절 — 「이 수트가 재는 것 — 오검율」 · 「트리거 정확도 — 재는 대상이 다르다」 · 「대조군이 왜 붙어 있나」 ·
  「그레이더 읽는 법」 · 「키 없이도 무는 게이트」 · 「심판을 쓸 때의 모양」 · 「아직 안 재는 것」 · 「얼마나 걸리나」 ·
  「변동성」. 지금 상태로 맞는 말만 다시 쓴다 — 글자 그대로 옮기지 않는다(옛 글자는 첫 기록 파일에 있다).
- 고정한 것의 원천 — 「브리핑 검사기를 떼고, 러너를 고정했다 (2026-09-25)」의 표 · 「브리핑 검사기를 git 과 대조하는
  방식으로 다시 세웠다 (2026-09-28)」 · 「정규식 그레이더를 고정했다 · route-ops 는 공백으로 둔다 (2026-09-25)」. 뒤의
  기록이 앞의 것을 바꾼 자리는 뒤의 것을 따른다 — 「plugin-dev 리뷰 (2026-10-06)」의 「새 route 케이스 둘」이
  `route-ops` 공백을 메웠다. 그래서 `AGENTS.md` 의 「`audit-ops` 에 route 케이스가 없는 것은 알려진 공백이다」 줄은 지금도
  사실이 아니다 — PR B 에서 지운다(ADR 0011 의 7).

**가리킴** — `evals/README` 를 이름으로 부르는 자리(`grep -rn "evals/README"`, 2026-10-06).

| 자리 | 지문 안 | PR B 에서 |
|---|---|---|
| `AGENTS.md` 세 줄 | 아니다 | 「고정한 것」으로 |
| `CLAUDE.md` 「가변」 · `CHECKLIST.md` 「항상」 · `docs/procedure.md` 「살아 있는 문서와 기록」 · 마스터플랜 「가리키는 문서」 | 아니다 | 기록은 `docs/eval-log/` 로 |
| `vibe-audit/README.md` 114 · 119 | 아니다(`README.md`) | 있는 절로 |
| `scripts/run-evals.sh` · `eval-key.py` · `sync-agents.sh` · `.github/workflows/eval.yml` · `vibe-audit/scripts/verify-brief.py` · `route-unasked-*` 그레이더 넷 | 그렇다 | 고치지 않는다(E4) |
| 조각 1 · 2 · 3 폴더 · ADR | 아니다 — 기록 | 고치지 않는다 |

## ④ 결정

**정한 것** — 다 ADR 0011.

- 작업 기록은 `docs/eval-log/` 에 · 지금 파일을 글자 그대로 첫 기록 파일로 옮기고 그 뒤는 달마다(1 · 2) — 저자.
- 시스템 구조는 `docs/architecture.md` 를 새로 둔다(3) — 저자.
- `AGENTS.md` 는 살아 있는 README 「고정한 것」을 가리킨다(4) · 사실이 아닌 `route-ops` 공백 줄을 지운다(7) — 저자.
- 수트 지문 안 파일의 옛 참조는 고치지 않고 E4 한 줄로 잇는다 · 새 검사를 세우지 않는다(5 · 6) — 세션이 제안, 이 PR 의
  머지가 저자의 결정.

**열어 둔 것**

없음 — 갈림길 일곱은 ADR 0011 이 정했고, 나머지는 ③ 의 실제 파일에서 따라 나온다.

## ⑤ 검증 계획

모델을 부르지 않는다. 검사를 세우지 않는다 — 각 보장을 한 번 도는 명령으로 대어 보고 결과를 PR 본문에 붙인다. 명령이
무는지는 그 PR 의 기준 커밋에 같은 명령을 대어 본다(「어긋내 보기」) — 기준 커밋은 고치기 전의 모양이라 걸려야 한다.

**PR B**

- L1 — `git show <기준>:vibe-audit/evals/README.md | cmp - docs/eval-log/2026-09-16_2026-10-06.md`, 출력 없음.
- L2 — `ls -A docs/eval-log | grep -vxE '2026-09-16_2026-10-06\.md|[0-9]{4}-[0-9]{2}\.md'`, 0 줄. 규칙이 든 자리 —
  `grep -cF '<YYYY-MM>.md'` 를 `docs/procedure.md` 와 `vibe-audit/evals/README.md` 에 **따로** 대어 각각 1 이상 — 한 번에
  두 파일을 주면 한쪽만 있어도 통과한다.
- E1 — 케이스 폴더 이름 목록과 표 첫 칸의 목록을 `sort | diff`, 출력 없음.
- E2 — `grep -nE '^#+ .*20[0-9]{2}-[0-9]{2}-[0-9]{2}' vibe-audit/evals/README.md`, 0 줄. 어긋내 보기: 기준 커밋에서 53 줄
  (`## 5.5 전수 기준 (2026-10-05, 로컬)` 포함, 2026-10-06).
- E3 — 옮기기 전 세 절의 알려진 한계 항목을 「고정한 것」과 하나씩 대어 본 표(PR 본문). 메워진 공백이 남지 않았는지 —
  `grep -n 'route 케이스가 없는' AGENTS.md vibe-audit/evals/README.md`, 0 줄. 어긋내 보기: 기준 커밋에서 `AGENTS.md` 16 줄.
  처음 고정한 날짜가 기록 파일의 절을 가리키는지 — 셋 각각 한 줄에 경로와 절 이름이 같이 있다:
  `grep -cE 'docs/eval-log/2026-09-16_2026-10-06\.md.*「<절>' vibe-audit/evals/README.md` 가 `<절>` =
  `브리핑 검사기를 떼고, 러너를 고정했다` · `브리핑 검사기를 git 과 대조하는 방식으로 다시 세웠다` · `정규식 그레이더를 고정했다`
  마다 1 이상. 어긋내 보기: 기준 커밋에서 셋 다 0.
- E4 — `head -n 15 vibe-audit/evals/README.md | grep -cF 'docs/eval-log/2026-09-16_2026-10-06.md'`, 1 이상. 어긋내 보기: 기준
  커밋에서 0.
- P1 — 살아 있는 문서에서 `evals/README.md` 「…」 를 뽑아 살아 있는 README 의 제목과 대조, 빠진 것 0. 가리킴이 지워져
  대조할 것이 줄어든 채로 통과하지 않게 — `AGENTS.md` 의 고정한 셋(러너 · 브리핑 검사기 · 정규식 그레이더)은 각 줄이
  경로와 절을 한 줄에 든다: `grep -cE 'vibe-audit/evals/README\.md.*「고정한 것」' AGENTS.md` 가 3. 어긋내 보기: 기준
  커밋에서 0(지금은 옛 절 이름을 가리킨다).
  플러그인 입구도 같다 — `vibe-audit/README.md` 의 두 줄(114 · 119)은 각 줄이 `evals/README.md` 와 살아 있는 README 의
  절을 한 줄에 든다: `grep -cE 'evals/README\.md` 「' vibe-audit/README.md` 가 2 이상이고, 그 절은 위 대조로 다 있는 절이다.
  어긋내 보기: 기준 커밋에서 1(114 줄은 절 없이 파일만, 119 줄의 「자기 트리거」는 없는 절).
- P3 (B 몫) — 파일마다 따로: `grep -cF 'docs/eval-log/'` 가 `CLAUDE.md` · `CHECKLIST.md` 에서 각각 1 이상 ·
  `grep -cE '^\| 감사자가 왜 지금 모양인가 \|.*docs/eval-log/' docs/master-plan.md` 1 · `docs/procedure.md` 에서
  `grep -cE '^\| \*\*기록\*\*.*docs/eval-log/'` 1 과 `grep -cE '^\| \*\*살아 있는 문서\*\*.*vibe-audit/evals/README\.md'` 1.
  옛 자리가 남지 않았는지 — `grep -nE '`vibe-audit/evals/README\.md` 의 작업 기록' CLAUDE.md` ·
  `grep -n '머지된 기록.*evals/README' CHECKLIST.md` · `grep -nE '^\| \*\*기록\*\*.*vibe-audit/evals/README' docs/procedure.md` 0 줄.
  어긋내 보기: 기준 커밋에서 앞의 다섯은 다 0, 뒤의 셋은 각각 한 줄(CLAUDE.md 28 · CHECKLIST.md 10 · procedure.md 108).
- X1 — `git diff --no-renames --name-only <기준>..HEAD`(지우거나 옮긴 옛 경로도 나온다)와, 기준 커밋과 HEAD 의
  `eval-key.py route --list` · `full --list` 의 **합집합**의 교집합 0. HEAD 의 목록만 보면 지문 안 파일을 지우거나 옮긴
  것이 빠진다. `claude` 가 있는 곳에서는 기준 커밋의 worktree 와 HEAD 에서 `eval-key.py route` · `full` 의 지문이 같은지도
  본다. CI eval 잡이 「같은 지문」으로 건너뛰는지도 본다.
- X2 — `./scripts/gates.sh`.

**PR C**

- R1 — `grep -c '^## ' README.md` 넷 이하. 그리고 걷을 내용이 없는지 —
  `grep -nE '^#+ (사본은 갈려도|되먹인 자리마다|사본이 원본의 공통 절|견줄 상대는 대장|갈린 자리를 뽑아|감사 계획과 부적합)|첫 되먹임에서|둘째 되먹임|셋째는 관문|verify-copy|compare-copies|run-evals' README.md`,
  0 줄. 어긋내 보기: 기준 커밋에서 13 줄(2026-10-06). 남아야 할 것이 남았는지 —
  `grep -cE '^## (들어 있는 것|새 프로젝트를 열 때)$' README.md` 가 2, `claude plugin install vibe-audit@pdw96-kit` ·
  `./scripts/sync-agents.sh` 가 `grep -cF` 로 각각 1 이상(설치 두 경로). 기준 커밋에서도 2 · 1 · 1 이다 — 지우는 쪽으로
  잘못 가는 것을 막는 단언이라 어긋내 보기는 그 줄을 지운 사본에서 0 이 나오는 것으로 대신한다.
- R2 — 지운 문단 → 주인 대응표(PR 본문). 주인마다 PR C 의 머리에서 그 절을 연다.
- R3 — `grep -nE '[0-9]+\.[0-9]+\.[0-9]+|claude-(sonnet|opus|haiku)|\b(sonnet|opus|haiku)\b|\bgate\b|\bverdict\b|\beval\(' CLAUDE.md`,
  0 줄. 잡 이름은 지금 CLAUDE.md 가 쓰는 꼴(`gate(…)` · `eval(…)` · `verdict(…)`)로 건다 — `eval` 만으로 걸면 `eval.yml` ·
  `run-evals.sh` 를 가리키는 줄이 걸린다. 어긋내 보기: PR C 의 기준 커밋 CLAUDE.md 에 같은 명령을 대면 값 넷(CLI 버전 ·
  잡 이름 · 수트 모델 · 심판 모델)이 든 세 줄이 다 걸린다(2026-10-06 에 10 · 12 · 13 줄). 그 자리의 줄이 주인을
  가리키는지 — 값의 이름과 주인이 **한 줄에** 같이 있어야 한다. 다른 줄의 같은 파일 이름(47 줄 「`run-evals.sh` 로」)으로
  통과하지 않게. `grep -cE 'CLI.*eval-key\.py'` · `grep -cE '^- CI.*eval\.yml'` · `grep -cE '수트 모델.*run-evals\.sh'` ·
  `grep -cE '되먹임.*INTENT\.md'` 가 `CLAUDE.md` 에서 각각 1 이상. 어긋내 보기: 기준 커밋에서 첫째(CLI 줄이 두 줄에 걸쳤다)와
  넷째(지금은 `(README)`)가 0.
- R4 — `grep -nE '^\| 시스템 구조 \| `docs/architecture\.md`' docs/master-plan.md` 1 줄이고 그 줄에 `README.md` 가 없다 ·
  `grep -nE '되먹이지 않는다|다른 레포에서도 같은 말' README.md` 0 줄 · `grep -cF '다른 레포에서도 같은 말' INTENT.md` 1 이상.
  어긋내 보기: 기준 커밋에서 첫 것은 0 줄(지금은 `docs/adr/` · `README.md`), 둘째는 2 줄, 셋째는 0.
- P2 — `python3 scripts/verify-docs.py`. M2 는 적힌 경로가 있는지만 보므로 R4 의 첫 명령이 새 경로를 따로 본다.
- R1 (가리키는 곳) — `INTENT.md` · `docs/master-plan.md` · `docs/architecture.md` · `vibe-audit/evals/README.md` 를
  `grep -cF` 로 `README.md` 에 따로 대어 각각 1 이상. 어긋내 보기: 기준 커밋에서 `docs/master-plan.md` 말고 셋이 0.
- P3 (C 몫) — `grep -cE '^\| \*\*살아 있는 문서\*\*.*docs/architecture\.md' docs/procedure.md` 1. 어긋내 보기: 기준 커밋에서 0.
- P1 · X1 · X2 — PR B 와 같다.

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| **A — 착공(요구사항 + 설계)** | 이 폴더 · ADR 0011 · 마스터플랜의 상태와 조각 폴더 | 갈림길 일곱과 옮길 대상의 목록 — 구현보다 먼저 선다 |
| **B — 수트 문서 나누기** | `docs/eval-log/` · 살아 있는 `vibe-audit/evals/README.md` · `AGENTS.md` · `docs/procedure.md` · `CHECKLIST.md` · `vibe-audit/README.md` · 마스터플랜 「가리키는 문서」 | 성공 기준 4 · 5 와 6 · 7 의 B 몫 |
| **C — 입구와 규칙** | `docs/architecture.md` · `README.md` · `CLAUDE.md` · `INTENT.md` · `docs/procedure.md` 살아 있는 문서 목록 · 마스터플랜 「가리키는 문서」 | 성공 기준 1 · 2 · 3 과 6 · 7 의 C 몫 |

B 는 A 가 머지된 뒤에, C 는 B 가 머지된 뒤에 연다 — README 의 되먹임 이야기를 걷기 전에 그 주인(살아 있는 수트
README 의 케이스 표)이 먼저 서야 한다.
