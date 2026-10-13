# 조각 15 설계 — 커맨드 · 검사기 사본 비교

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`, 갈림길은 ADR 0025.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A | 「커맨드 · 검사기 사본 비교」 상태 `진행` · 조각 폴더 |
| `docs/adr/0025-command-copy-comparison.md` | A | 갈림길 넷 |
| `scripts/compare-copies.py` | B | 견줄 자리를 셋으로 — 감사자(`vibe-audit/agents/*.md` ↔ `agents_path`), 커맨드(`vibe-audit/commands/*.md` ↔ 그 부모의 `commands/`), 검사기(`vibe-audit/scripts/*.py` ↔ 그 부모의 `scripts/`). 멈추는 규칙의 더러움 · HEAD 에 없는 파일을 세 자리에 다 댄다(② C1 ~ C5). 머리 독스트링 |
| `scripts/test-compare-copies.py` | B | 임시 원본에 커맨드 · 검사기를 하나씩 두고 ② T1 의 꼴을 본다 |
| `scripts/verify-feedback.py` | B | `seen[].files` 가 `*.md` · `*.py` 이름(폴더 없음)을 받는다(② F1) |
| `scripts/test-verify-feedback.py` | B | `verify-brief.py` 를 든 성한 대장이 통과하는 꼴 하나(② F2) |
| `scripts/verify-copies.py` | B | 사본 줄의 「원본은 그 뒤 N 커밋 움직임」에 그 사이 바뀐 원본 파일 이름을 붙인다(② V1) |
| `scripts/bite-gates.sh` | B | 비교기 변조 둘 · 대장 변조 둘 · 사본 검사의 이름 자리 하나(② T2 · F2 · V2) |
| `docs/schema.md` | B | 「차이」의 정의 · 「차이를 뽑는 법」의 원본 쪽 · 사본 쪽 · 멈추는 경우 · 견주는 파일 · `files` 칸의 규칙 · 「이 모양을 무는 것」의 변조 수 |
| `docs/architecture.md` | B | 「견주기」의 `verify-copies.py` · `compare-copies.py` 줄 |
| `feedback.json` | C | 저자가 가른 후보 — `FB-19` 부터(② J1 · J2) |

**앵커볼트.** `feedback.json` 의 `seen[].files` 가 받는 이름이 넓어진다 — 대장의 모양이라 저자가 정한다(ADR 0025 의 2). 칸 · 내용 해시의
공식 · `copies.json` 은 그대로다. 이름 · 감사자의 `tools` · 공통 절 · 「…의 칸」 · `AGENTS.md` 는 건드리지 않는다.

**고정 영역 · 수트.** `run-evals.sh` · `eval.yml` · 정규식 그레이더 · `vibe-audit/` · `vibe-slice/` 를 고치지 않는다. ① 의 파일은 다 수트
지문(`eval-key.py route --list` · `full --list`) 밖이다.

**사실.**
- 커맨드 · 검사기 사본의 자리는 `agents_path` 의 부모에서 끌어낸다 — `sync-agents.sh` 가 그 자리에 심고(`$TARGET/.claude/commands` ·
  `.../scripts`), `verify-copies.py` 의 `commands_missing` · `scripts_missing` 이 같은 꼴로 읽는다.
- 출처 주석 줄은 커맨드에도 있고(옛 꼴 · 지금 꼴 둘 다 `PROVENANCE` 가 잡는다), 검사기에는 없다(`sync-agents.sh` 가 바이트 그대로 옮긴다).
  `strip_provenance` 는 그 줄이 없으면 아무것도 빼지 않는다.

**시스템 구조.** 부품은 그대로다 — 「견주기」의 두 줄이 견주는 파일 · 찍는 것을 더 든다. `docs/architecture.md` 를 B 에서 고친다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 번호는 ⑤ 와 PR 본문이 같이 쓴다.

- **비교기** (`compare-copies.py`, B)
  - C1 사본마다 견주는 파일은 그 `synced_commit` 의 `vibe-audit/agents/*.md` · `vibe-audit/commands/*.md` · `vibe-audit/scripts/*.py` 다.
    원본 쪽은 그 커밋의 파일, 사본 쪽은 사본 레포 `HEAD` 의 `<agents_path>` · `<agents_path>/../commands` · `<agents_path>/../scripts` 아래 같은
    이름이다. 그 밖의 파일(사본에만 있는 이름 · 원본의 다른 확장자)은 견주지 않는다.
  - C2 덩어리 · 내용 해시 · 출처 줄 거르기 · 정규화는 감사자와 같다(`hunks` · `content_hash` 그대로). 같은 덩어리가 감사자와 커맨드에 다
    있으면 후보 하나다(`docs/schema.md` 「대상과 관계」).
  - C3 후보의 자리 줄은 `<레포> · <파일 이름>:<줄>` 그대로다 — `audit-brief.md` · `verify-brief.py` 는 감사자 이름과 겹치지 않는다. `--json` 의
    `seen[].files` 에 그 이름이 든다. 사본에 없는 파일은 지금처럼 「(사본에 없는 파일)」로 찍는다.
  - C4 멈추는 규칙(ADR 0003)의 둘이 세 자리에 다 든다 — 커밋 안 된 변경 · 추적 안 된 파일(`status --porcelain --untracked-files=all`)과,
    디스크에 있는데 HEAD 에 없는 견줄 파일. 하나라도 걸리면 아무것도 견주지 않고 1 이다. 자리 폴더가 없으면 멈추지 않는다 — 그 파일은 C3
    의 「사본에 없는 파일」이고, 빠진 것 자체는 `verify-copies.py` 가 떨어뜨린다.
  - C5 쓰지 않는다 — `feedback.json` · `copies.json` 은 읽기만 한다. 종료코드는 그대로다(0 견줬다 · 1 멈췄다 · 2 사용법).
- **비교기 시험** (B)
  - T1 `test-compare-copies.py` 가 임시 원본에 `vibe-audit/commands/c.md`(머리말 있음) · `vibe-audit/scripts/v.py` 를 두고 사본에 심어 꼴
    넷을 본다 — (가) 출처 줄만 다른 커맨드 · 바이트 그대로인 검사기에서 후보 0 · (나) 커맨드의 고친 줄과 검사기의 고친 줄이 후보 둘로 나오고
    자리 줄이 `c.md` · `v.py` 다 · (다) 사본 `commands/` 에 커밋 안 된 변경, `scripts/` 에 추적 안 된 파일이 있으면 각각 1 로 멈춘다 · (라)
    `.gitignore` 로 무시돼 HEAD 에 없는 사본 커맨드가 있으면 1 로 멈춘다. 지금의 시험 다섯은 그대로 지나간다.
  - T2 `bite-gates.sh` 의 비교기 변조에 둘을 더한다 — 커맨드 · 검사기를 견줄 목록에서 뺀 비교기(T1 (나)에서 떨어진다), 더러움을 감사자
    자리만 보는 비교기(T1 (다)에서 떨어진다). 변조할 자리가 비교기에 꼭 한 번 있지 않으면 떨어진다(지금의 꼴 그대로).
- **대장 검사기** (`verify-feedback.py`, B)
  - F1 `seen[].files` 는 비지 않은 목록이고, 이름마다 `/` 가 없고 `.md` 나 `.py` 로 끝난다. 그 밖의 규칙은 그대로다.
  - F2 `test-verify-feedback.py` 가 `files: ["verify-brief.py"]` 를 든 성한 대장이 통과하는 것을 보고, `bite-gates.sh` 의 대장 변조에 둘을
    더한다 — `files: ["commands/audit-brief.md"]`(폴더) · `files: ["sync.sh"]`(다른 확장자). 둘 다 떨어져야 한다.
- **사본 검사** (`verify-copies.py`, B)
  - V1 사본 줄의 「원본은 그 뒤 N 커밋 움직임」 뒤에 `— 바뀐 원본: <이름>, …` 를 붙인다. 이름은 `git diff --name-only <synced_commit> HEAD --
    vibe-audit/agents vibe-audit/commands vibe-audit/scripts` 의 파일 이름이고, 없으면 붙이지 않는다. 사본 경로가 없는 줄(CI)에도 붙는다.
    알림이다 — PASS · FAIL 은 바뀌지 않는다.
  - V2 `bite-gates.sh` 가 경로가 없는 임시 대장 줄(`synced_commit` = `vibe-audit/commands/` 를 마지막으로 고친 커밋의 부모)로
    `verify-copies.py` 를 불러, 출력에 그 커맨드 이름이 없으면 떨어진다. 이름 자리를 지운 변조본을 손으로 대어 떨어지는 것을 PR 본문에 적는다.
- **판정** (C)
  - J1 C 는 `feedback.json` 에 저자가 가른 후보만 더한다 — `seen` 은 B 의 비교기가 `--json` 으로 찍은 `repo` · `files` · `commit` · `base`
    그대로, `status` · `reason` · `decided_at` 은 저자가 정한 것. 세션은 근거 초안을 PR 본문에 낼 수 있지만 칸을 채우는 결정은 저자다.
  - J2 C 의 머리에서 `verify-feedback.py` 통과 · 두 클론으로 다시 부른 `compare-copies.py` 의 미판정 0.
  - J3 이 조각의 PR 셋은 수트 지문의 파일을 고치지 않는다 — 셋 다 eval 잡이 건너뛴다.

**보장하지 않는 것(알려진 한계)**

- **커맨드 · 검사기를 원본 커밋 사이에서 견주기** — 사본은 심을 때의 원본과만 견준다. 원본이 그 뒤 고친 것(조각 14 의 이름 자리표시)이
  사본에 없는 것은 후보가 아니다 — V1 이 이름만 알린다. 받는 일은 다시 심기다(하지 않을 일 2).
- **원본 커밋이 다른 두 사본의 같은 고침** — 해시에 원본 쪽 줄이 들어 갈릴 수 있다(조각 13 설계 ② · ADR 0022 의 3). 커맨드도 같다.
- **검사기의 뜻** — `.py` 도 줄 단위 덩어리로 견준다. 들여쓰기만 다른 줄은 정규화로 같아진다 — 파이썬에서는 뜻이 다를 수 있는데 후보가
  나오지 않는다. 사본 검사기가 바이트 그대로 심기고 지금 두 사본 다 같아(③), 겪으면 그 PR 에서 정해 날짜 항목으로 적는다.
- **파일 이름이 겹치는 원본** — 감사자 · 커맨드 · 검사기의 이름이 겹치면 `seen[].files` 와 자리 줄이 어느 쪽인지 가르지 못한다. 지금 원본에
  겹치는 이름이 없다(③).
- **판정의 옳음** — 갈래는 저자가 정하고 `verify-feedback.py` 는 모양만 본다(지금 그대로).
- **아직 겪지 않은 가설적 경계 사례** — 예: 사본 `commands/` 가 링크 · 서브모듈, 원본에 커맨드가 둘 이상. 겪으면 그 PR 에서 정해 날짜 항목으로
  적는다. 리뷰가 이것을 짚으면 범위 밖이다(조각 6 「닫으며」).

## ③ 받는 입력

닫힌 목록이다. 2026-10-13 의 claude-kit `main`(d69b8c8), ERP `main`(248317a), 강호쟁패 `main`(53524d9)에서 뽑았다. 이 밖은 비교기가
지금처럼 다룬다 — 자리가 git 저장소 밖이거나 대장 · 후보 대장이 성하지 않으면 멈춘다.

**`copies.json`** — 줄 둘. `erp`(`/home/user/erp/.claude/agents`, 3d6964a, 2026-09-28) · `ganghojaengpae`
(`/home/user/ganghojaengpae/.claude/agents`, b8d9243, 2026-10-13).

**원본의 견줄 파일** — 두 `synced_commit` 과 `main` 이 같은 이름을 든다.

| 자리 | 3d6964a · b8d9243 · d69b8c8 |
|---|---|
| `vibe-audit/agents/` | `audit-*.md` 여섯 |
| `vibe-audit/commands/` | `audit-brief.md` 하나 |
| `vibe-audit/scripts/` | `verify-brief.py` 하나 |

**사본 레포의 `.claude/`**

| 레포 | 폴더 | 커맨드 사본 | 검사기 사본 |
|---|---|---|---|
| ERP | `agents` · `commands` · `hooks` · `scripts` · `skills` · `settings.json` | `commands/` 에 `audit-brief.md` 하나 · 출처 줄은 옛 꼴(「이 레포에 맞게 고쳐도 된다 — 원본으로 되먹이지 않는다.」) | `scripts/` 에 `verify-brief.py` 하나 · 3d6964a 와 바이트 같음 |
| 강호쟁패 | `agents` · `audits` · `commands` · `scripts` · `settings.json` | `audit-brief.md` 하나 · 출처 줄은 지금 꼴 · 그 줄 말고 b8d9243 과 같음 | `verify-brief.py` 하나 · b8d9243 과 바이트 같음 |

**ERP 사본 커맨드의 덩어리** — 이 세션이 2026-10-13 에 지금의 `hunks` · `content_hash` 를 ERP 사본과 3d6964a 의 원본에 대어 뽑았다. 일곱
다 `feedback.json` 에 없는 해시다.

| 사본 줄 | 원본 · 사본 줄 수 | 요지 |
|---|---|---|
| 40 | 1 · 1 | 대장 두 파일(`docs/audit/README.md` · `회차-기록.md`)을 diff 에서 뺀다 — 원본은 「레포가 대장을 따로 두었으면」 |
| 51 | 0 · 1 | 모으는 표에 「열린 낮음 이슈」 — `gh issue list --label audit-low` · 상한에서 잘리면 적는다 |
| 75 | 0 · 2 | 브리핑에 `## 열린 낮음 이슈` 절 |
| 104 | 3 · 2 | 검사기를 `--exclude` 대장 둘로 부른다 · 플러그인 폴더 경로 문장이 빠짐 |
| 120 | 5 · 3 | 감사 기록을 `.claude/audits/` 대신 대장에 등록 · 낮음은 이슈 · 회차 절은 `회차-기록.md` |
| 124 | 1 · 5 | 회차 절의 첫 줄 「감사한 커밋」 · 「커밋 안 된 변경 포함」 꼬리 · 브리핑 보관 이름 |
| 132 | 1 · 1 | 「`.claude/audits/` 에 두면 감사자가 지난 기록으로 집습니다」 문장이 빠짐 |

**지금의 출력** — 두 클론을 원격 기본 가지의 머리로 둔 세션에서(2026-10-13).
- `compare-copies.py` — `후보 16 — 미판정 0 · 판정됨 16(새 레포 0)`, 끝 0.
- `verify-copies.py` — PASS. `erp: … (원본은 그 뒤 12 커밋 움직임)` · `ganghojaengpae: … (원본은 그 뒤 1 커밋 움직임)`. 그 사이 바뀐 원본은
  `git diff --name-only` 로 ERP 가 감사자 여섯과 `audit-brief.md`, 강호쟁패가 `audit-brief.md` 하나다.

**`feedback.json`** — 후보 열여덟(FB-1 ~ FB-18), `seen[].files` 는 다 `audit-*.md`. `verify-feedback.py` 의 규칙은 「`*.md` · `/` 없음」.

**수트 지문** — `eval-key.py route --list` · `full --list` 의 파일 가운데 이 조각이 고치는 것은 없다(`scripts/` 에서는 `run-evals.sh` ·
`verify-evals.py` · `verify-graders.py` 만 든다).

## ④ 결정

**정한 것** — ADR 0025. 넷 다 저자가 착공 PR(#62)을 연 뒤 정했다(2026-10-13) — 세션이 추천한 쪽이다.

- 1 커맨드 · 검사기 사본의 자리 — `agents_path` 의 부모에서 끌어낸다. 대장의 칸은 그대로
- 2 후보 대장의 `seen[].files` — `*.py` 이름도 받는다(폴더 없음)
- 3 원본 쪽의 움직임 — `verify-copies.py` 가 그 사이 바뀐 원본 파일 이름을 알린다
- 4 닫는 때 — 저자가 ERP 커맨드의 후보를 판정해 대장에 적으면 닫는다. 되먹임은 조각 나눔의 새 줄

**열어 둔 것**

없음 — 갈림길 넷을 착공에서 정한다.

## ⑤ 검증 계획

명령은 PR 본문에 결과와 함께 적는다. 「어긋내 보기」는 일부러 망가뜨린 작업트리에 같은 명령을 대어 떨어지는지 본 뒤 되돌린다.

**PR A**

- `./scripts/gates.sh` 스물넷 통과 — `verify-docs.py` 가 새 조각 폴더를, `verify-slice-gate.py` 가 착공 PR 에 결정 문서뿐인지를 본다.
- 지문 — `git diff --name-only main...HEAD` 와 `eval-key.py route --list` · `full --list` 의 교집합 0.

**PR B**

- `./scripts/gates.sh` 스물넷 통과 — 로컬과 CI gate 잡(성공 기준 5 · 7).
- T1 — `python3 scripts/test-compare-copies.py` 가 지금의 다섯과 (가) ~ (라)를 지나간다(성공 기준 2).
- T2 · F2 · V2 — `bash scripts/bite-gates.sh` 통과. 어긋내 보기 — 비교기에서 커맨드 · 검사기 자리를 뺀 작업트리에 T1 을 대면 (나)에서,
  `verify-feedback.py` 를 `.md` 만 받게 되돌린 작업트리에 `test-verify-feedback.py` 를 대면 `.py` 꼴에서, `verify-copies.py` 의 이름 자리를
  지운 작업트리에 V2 를 대면 떨어진다.
- C1 ~ C3 · 성공 기준 1 — 두 클론을 원격 기본 가지의 머리로 옮긴 뒤(`git -C <클론> rev-parse HEAD` 가 `origin/main` 과 같다)
  `python3 scripts/compare-copies.py` 의 출력과 끝값. ERP 커맨드의 덩어리 수와 ③ 의 표를 견준다.
- V1 · 성공 기준 4 — 같은 세션의 `python3 scripts/verify-copies.py` 출력, 그리고 클론 경로를 치운 대장 사본(CI 와 같은 꼴)의 출력.
- C5 — `git diff main...HEAD -- scripts/compare-copies.py` 에 대장을 쓰는 줄이 없다.
- 지문 — 교집합 0(J3).

**PR C** (B 가 머지된 뒤)

- J1 — `git diff main...HEAD -- feedback.json` 이 새 후보만 더하고 지난 열여덟을 바꾸지 않는다. `seen` 이 B 의 `compare-copies.py --json`
  출력과 같다. 판정은 PR 본문에 저자의 말로 적는다.
- J2 · 성공 기준 6 — `python3 scripts/verify-feedback.py` · 두 클론으로 다시 부른 `python3 scripts/compare-copies.py` 의 끝 줄(미판정 0).
- 지문 — 교집합 0.

**스스로 쓰기** — PR A · B · C 의 리뷰를 `slice-review` 로 가른다. PR 본문의 `## 리뷰 회차` 와 답글. B · C 는 `verify-slice-gate.py` 를
CI 에서 지나간다(이 착공이 머지된 뒤).

**단계 5(배포)** — 없음 — 배포처가 없다. 바뀌는 것은 claude-kit 의 스크립트와 대장이고, 플러그인 · 사본 레포에 가지 않는다. 되돌리는 길은
B · C 의 되돌림이다 — 둘 다 수트 지문 밖이다.

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A 착공 | 요구사항 · 설계 · ADR 0025 · 마스터플랜(「커맨드 · 검사기 사본 비교」 `진행`) | 단계 1 · 2 |
| B 견주기 | `compare-copies.py` · `test-compare-copies.py` · `verify-feedback.py` · `test-verify-feedback.py` · `verify-copies.py` · `bite-gates.sh` · `docs/schema.md` · `docs/architecture.md` | ② 의 C1 ~ C5 · T1 · T2 · F1 · F2 · V1 · V2, 성공 기준 1 ~ 5 · 7 |
| C 판정 | `feedback.json` — 저자가 가른 후보 | ② 의 J1 ~ J3, 성공 기준 6 |

B 를 C 앞에 둔다 — 대장이 `.py` 이름을 받고 비교기가 커맨드 후보를 내야 C 가 그것을 적는다. 결함으로 가른 후보의 되먹임은 C 에서 조각
나눔에 줄을 더하고(하지 않을 일 1), 조각을 닫는 기록은 따로 낸다(단계 6).
