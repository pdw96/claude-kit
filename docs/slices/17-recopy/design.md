# 조각 17 설계 — 사본 다시 심기

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`, 갈림길은 ADR 0027.

## ① 바뀌는 것

| 저장소 · 파일 | PR | 무엇 |
|---|---|---|
| claude-kit `docs/master-plan.md` | A | 「사본 다시 심기」 상태 `진행` · 조각 폴더 |
| claude-kit `docs/adr/0027-recopy-three-way-merge.md` | A | 갈림길 셋 |
| 강호쟁패 `.claude/agents/*.md` 여섯 · `.claude/agents/README.md` · `.claude/commands/audit-brief.md` · `.claude/scripts/verify-brief.py` | B | `018842c` 의 작업트리에서 `sync-agents.sh --force` 가 쓴 그대로(② S1) |
| ERP `.claude/agents/*.md` 여섯 · `.claude/commands/audit-brief.md` | C | 세 쪽 병합과 충돌 여덟을 푼 모양 · 머리줄(② M1 ~ M5). `verify-brief.py` 는 `3d6964a` 와 `018842c` 가 바이트로 같아 그대로다 |
| ERP `.claude/agents/README.md` | C | 저자가 정하면 출처 SHA 한 자리(`3d6964a`)만. 그 밖은 그대로(② M6) |
| claude-kit `copies.json` | D | 두 줄의 `synced_commit` · `synced_at`(② L1) |
| claude-kit `feedback.json` | D | 비교기가 내는 새 후보와 저자의 판정 — `FB-26` 부터(② L2) |

**앵커볼트.** 대장의 모양 — `copies.json` · `feedback.json` 의 칸은 그대로 쓴다. 이름 · 감사자의 `tools` · 공통 절 · 「…의 칸」 ·
`AGENTS.md` 는 건드리지 않는다 — 원본을 고치지 않는다(하지 않을 일 2). 사본의 공통 절은 `3d6964a` 와 `018842c` 사이에 바뀌지 않았다
(2026-10-14, 모의 병합본에 `verify-copy.py` 를 두 원본으로 대 둘 다 PASS).

**고정 영역 · 수트.** claude-kit PR(A · D)의 파일은 다 수트 지문(`eval-key.py route --list` · `full --list`) 밖이다 — eval 이 돌지 않는다.
`run-evals.sh` · `eval.yml` · `sync-agents.sh` 는 고치지 않는다.

**사실.**
- 강호쟁패는 특화가 없어 세 쪽 병합과 `--force` 의 결과가 같다(모의: 여덟 파일 충돌 0). 그래서 `sync-agents.sh` 의 길로 심는다 — 대장 줄도
  그 스크립트가 적는다. 사본 README 도 생성본 그대로라 덮어도 잃는 것이 없다. `.claude/audits/` 는 스크립트가 건드리지 않는다.
- `vibe-audit/agents` · `commands` · `scripts` 에서 물러난 파일은 원본 역사에 없다 — `--force` 가 지울 것도, 손 병합이 빠뜨릴 것도 없다.
- ERP 사본의 머리줄은 옛 꼴(「이 레포에 맞게 고쳐도 된다 — 원본으로 되먹이지 않는다」)이다. `compare-copies.py` 의 출처 주석 거르기는 두 꼴을
  다 잡는다(조각 15).
- 사본은 예산 밖이다 — `verify-budget.py` 는 원본만 잰다.

**시스템 구조.** 부품 · 경계 · 흐름은 그대로다 — 원본 → 사본의 길에 손 병합이 한 번 쓰인다. `docs/architecture.md` 는 고치지 않는다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 번호는 ⑤ 와 PR 본문이 같이 쓴다.

- **강호쟁패** (B)
  - S1 claude-kit `018842c` 의 작업트리(`git worktree add <자리> 018842c`)에서 `./scripts/sync-agents.sh <강호쟁패> --force` 를 돌린 그대로다 —
    감사자 · 커맨드의 머리줄이 `pdw96/claude-kit@018842c`, 검사기는 원본과 바이트로 같다. 강호쟁패 PR 의 `git diff --name-only` 가 ① 의 B 줄
    밖을 들지 않는다.
  - S2 B 가 머지된 뒤 클론을 `origin/main` 으로 두고, `018842c` 를 든 스크래치 대장으로 `compare-copies.py --repo ganghojaengpae --all` → 후보 0.
- **ERP** (C)
  - M1 병합 재료 — 파일마다 셋이다. 밑: `git show 3d6964a:vibe-audit/<자리>/<이름>` 을 `sync-agents.sh` 의 awk 로 심은 모양, 머리줄은 ERP 사본의
    옛 꼴 글자 그대로(ERP 가 그 줄을 고치지 않았다 — 모의에서 머리줄 충돌 0). 사본: ERP `origin/main` 의 그 파일. 원본: `018842c` 를 지금 꼴
    머리줄(`sync-agents.sh` 의 `HDR`)로 심은 모양. 검사기는 머리줄 없이 바이트 그대로다. `git merge-file <사본> <밑> <원본>`.
  - M2 깨끗한 덩어리는 `git merge-file` 의 결과 그대로다.
  - M3 충돌은 줄마다 푼다(ADR 0027 의 2) — 한쪽만 바꾼 줄은 바꾼 쪽, 둘 다 바꾼 줄은 원본 문구를 받고, 그 자리에 있던 사본 문구 가운데 특화
    몫(대장 `reason` 이 특화 · 「뺄 것」이라 부른 것, ERP 가 사본 특화로 적은 것)만 다시 붙인다. 붙일 문장과 자리는 저자가 C 에서 정하고,
    붙이지 않은 것은 PR 본문의 「사본에서 빠지는 것」에 적는다. 충돌 여덟 — 2026-10-14 모의 —

    | # | 파일 · 자리 | 대장 | 원본이 바꾼 커밋 | 다시 붙일 후보 몫 |
    |---|---|---|---|---|
    | 1 | `audit-data` 「통과해도 쓰기가 멈추는가」 | FB-3 · 4 되먹임 완료 | `910132c` | FB-4 의 「뺄 것」 — 「적으면 적합」 판정 표 · Alembic API 열 · PG11+ `relfilenode` 실측 · NC-21 의 예. ERP 대장 W-1 이 이 항목을 사본 특화로 적는다 |
    | 2 | `audit-internal` 서두 | FB-6 결함 | `c7cc318` · `b1a172c` | FB-6 의 특화 — ERP 의 기준 문서 목록 · `CLAUDE.md` 인용 · `docs/adr/` 의 내력 |
    | 3 | `audit-internal` 항목 1 | FB-7 결함 | `c7cc318` · `2177869` | FB-7 의 특화 — ERP 의 목록 |
    | 4 | `audit-internal` 항목 10 · 11 | FB-8 결함 | `8f4f3a2`(11 만) | 10 은 ERP 만, 11 은 원본만 바꿨다 — 줄 규칙으로 ERP 의 10 · 원본의 11 |
    | 5 | `audit-internal` 「기준점과 diff 를 못 받았으면」 | FB-9 특화 | `8f4f3a2` | FB-9 의 문구(「무엇이 · 누구에게서 필요한지」) |
    | 6 | `audit-quality` 설명 | FB-10 특화 | `a3b97f0` | FB-10 — 평가셋을 뺀 LLM 없는 제품의 설명 |
    | 7 | `audit-quality` 「무엇을 잡는가」 · 「자동 게이트」 문단 | FB-13 · 14 · 18 되먹임 완료, FB-15 · 16 특화 | `e315a39` | ERP 가 「기준점과 diff 를 못 받았으면」 문단과 「자동 게이트」 문단의 순서를 바꿨다(FB-15 · 16) — 원본 쪽을 받으면 「자동 게이트」 문단이 원본 자리와 ERP 가 옮긴 자리에 두 번 선다. 어느 쪽을 지우느냐가 그 순서를 지키는가다 |
    | 8 | `audit-secrets` 「넘기는 것은 원인이지 실패가 아닙니다」 | FB-17 결함 | `c7cc318` | FB-17 의 특화 — 「특채」 예 · `nonconformity_stage_rules` |

  - M4 머리줄 — 감사자 여섯 · 커맨드의 출처 줄이 `sync-agents.sh` 의 `HDR` 과 글자가 같고 SHA 는 `018842c` 다.
  - M5 `verify-copy.py <ERP>/.claude/agents` 가 PASS 다(원본 = claude-kit `018842c` 의 `vibe-audit/agents`). 감사자 여섯의 「출력 형식」에
    `- 감사한 커밋:` 줄이 원본과 같은 글자로 있고, 커맨드가 `$base` · `$auditor` 로 받는다.
  - M6 그 밖의 ERP 파일은 그대로다 — ERP PR 의 `git diff --name-only` 가 ① 의 C 줄 밖을 들지 않는다.
  - M7 재현 — PR 본문에 M1 의 명령과 충돌마다 원본 문구 · 사본 문구 · 푼 모양 · 사본에서 빠지는 것을 적는다. 누가 M1 을 다시 돌리고 충돌을
    그 푼 모양으로 바꾸면 PR 의 파일과 바이트로 같다.
- **대장** (D, B · C 가 머지된 뒤)
  - L1 `copies.json` — 두 줄의 `synced_commit` 이 `018842c` 의 전체 SHA, `synced_at` 이 심은 날. 강호쟁패 줄은 S1 의 작업트리 `copies.json` 에
    `sync-agents.sh` 가 적은 줄 그대로, ERP 줄은 M5 의 PASS 뒤 손으로(`CLAUDE.md` 「금지」). `agents_path` 는 그대로다.
  - L2 두 클론을 `origin/main` 으로 두고 `compare-copies.py` 가 끝 0 · `미판정 0` 이다. 새 후보는 저자가 판정해 `FB-26` 부터 적는다 — `seen` 은
    `erp` · 파일 · ERP 의 머지 커밋 · 밑 `018842c`. 깨끗한 자리의 특화 열하나는 같은 해시로 「판정됨」이다(성공 기준 3).
  - L3 `verify-feedback.py` · `verify-copies.py` 통과 — 클론이 있는 세션에서 두 줄 다 「원본은 그 뒤 0 커밋 움직임」, 「바뀐 원본」 없음.
- **게이트** (A · D)
  - G1 `./scripts/gates.sh` 스물넷 통과 — 새 검사를 세우지 않는다.
  - G2 A 는 결정 문서뿐이다 — `verify-slice-gate.py` 가 본다.
  - G3 A · D 의 `git diff --name-only main...HEAD` 와 수트 지문 목록의 교집합 0.

**보장하지 않는 것(알려진 한계)**

- **ERP 의 푼 모양이 ERP 에 맞는가** — 특화 몫을 어떤 문장으로 붙일지는 그 레포의 판단이다. 이 조각은 빠진 것을 보이는 데까지다(M3 · M7).
- **새 사본이 실제 회차에서 쓰이는가** — 빈 인자 질문 · 「감사한 커밋」 줄이 실제 기록에 찍히는지는 두 레포의 다음 회차가 보인다(하지 않을
  일 6).
- **ERP 의 겹침** — ERP 사본 커맨드 「남기는 것」의 「감사한 커밋」 줄(FB-24 의 사본 덩어리)은 깨끗하게 남고, 감사자 「출력 형식」의 원본 줄도
  들어온다. 둘을 하나로 줄일지는 ERP 의 일이다.
- **B · C 머지와 D 사이** — 대장이 옛 커밋을 드는 동안 클론이 있는 세션의 `compare-copies.py` 는 원본의 고침을 사본의 차이로 보고 미판정을
  찍는다. `verify-copies.py` 는 공통 절이 그대로라 PASS 다. CI 는 클론 경로가 닿지 않아 영향이 없다. D 가 그 창을 닫는다.
- **병합 모드** — 다음 심기를 기계로 되풀이하는 길은 세우지 않는다(하지 않을 일 1).
- **아직 겪지 않은 가설적 경계 사례** — 예: 조각 중에 ERP 가 사본을 또 고친다, `018842c` 뒤 원본이 움직인다. 앞의 것은 C 를 그 머리에서 다시
  병합하고, 뒤의 것은 멈추고 저자에게 올린다. 리뷰가 그 밖을 짚으면 범위 밖이다(조각 6 「닫으며」).

## ③ 받는 입력

닫힌 목록이다. 2026-10-14 의 claude-kit `main`(`9aaf460`) · ERP `main`(`248317a`) · 강호쟁패 `main`(`53524d9`)에서 뽑았다.

**대장 줄** — `copies.json`

| `repo` | `agents_path` | `synced_commit` |
|---|---|---|
| `erp` | `/home/user/erp/.claude/agents` | `3d6964a` |
| `ganghojaengpae` | `/home/user/ganghojaengpae/.claude/agents` | `b8d9243` |

**사본 자리** — `sync-agents.sh` 가 심는 셋과 그 옆.

| 레포 | `agents/` | `commands/` | `scripts/` | 이 조각이 건드리지 않는 것 |
|---|---|---|---|---|
| ERP | 감사자 여섯 · `README.md`(ERP 가 다시 씀) | `audit-brief.md` | `verify-brief.py` | `hooks/` · `skills/` · `settings.json` |
| 강호쟁패 | 감사자 여섯 · `README.md`(생성본) | `audit-brief.md` | `verify-brief.py` | `audits/` · `settings.json` |

**머리줄** — 두 꼴. 옛 꼴 `<!-- pdw96/claude-kit@3d6964a 에서 옴. 이 레포에 맞게 고쳐도 된다 — 원본으로 되먹이지 않는다. -->`(ERP), 지금 꼴은
`sync-agents.sh` 의 `HDR`(강호쟁패 · 이 조각이 쓰는 꼴).

**원본** — `018842c` 의 여덟 파일: `vibe-audit/agents/audit-{contract,data,internal,ops,quality,secrets}.md` · `vibe-audit/commands/audit-brief.md` ·
`vibe-audit/scripts/verify-brief.py`. `3d6964a..018842c` 에서 일곱이 바뀌었고 `verify-brief.py` 는 그대로다.

**병합 모의** — 2026-10-14, M1 의 재료.

| 파일 | ERP 충돌 | 강호쟁패 충돌 |
|---|---|---|
| `audit-contract.md` · `audit-ops.md` · `audit-brief.md` · `verify-brief.py` | 0 | 0 |
| `audit-data.md` | 1 | 0 |
| `audit-internal.md` | 4 | 0 |
| `audit-quality.md` | 2 | 0 |
| `audit-secrets.md` | 1 | 0 |

충돌을 다 원본 쪽으로 둔 ERP 모의본에 스크래치 대장(`018842c`)으로 비교기를 대면 `후보 14 — 미판정 1 · 판정됨 13`.

**`feedback.json`** — ERP 의 후보 25: 특화 15 · 결함 4 · 되먹임 완료 6. 지금 비교기에 나오는 해시는 23 이다 — FB-13 · 14 는 FB-18 한 덩어리로
나온다. 강호쟁패 0.

## ④ 결정

**정한 것** — ADR 0027.

- 1 ERP 를 심는 법 — 손으로 세 쪽 병합. `sync-agents.sh` 는 그대로(저자, 2026-10-14 착공 대화)
- 2 충돌을 푸는 규칙 — 줄마다. 둘 다 바꾼 줄은 원본 문구 + 특화 몫(세션 추천 — 저자가 이 PR 에서 정한다)
- 3 출처 커밋 — 두 레포 다 `018842c`, 그 작업트리에서 심는다(세션 추천 — 저자가 이 PR 에서 정한다)

**열어 둔 것**

없음 — 갈림길 셋을 착공에서 정한다. 충돌마다 붙일 문장(② M3)은 결정이 아니라 C 의 일이고 저자가 C 에서 가른다. 새 후보의 판정은 D 의
일이다.

## ⑤ 검증 계획

명령은 PR 본문에 결과와 함께 적는다.

**PR A**

- `./scripts/gates.sh` 스물넷 통과 — `verify-docs.py` 가 새 조각 폴더를, `verify-slice-gate.py` 가 착공 PR 에 결정 문서뿐인지를 본다(G2).
- 지문 — `git diff --name-only main...HEAD` 와 `eval-key.py route --list` · `full --list` 의 교집합 0(G3).

**PR B** (A 가 머지된 뒤, 강호쟁패)

- `git diff --stat 018842c origin/main -- vibe-audit/` 가 비었는지 먼저 본다 — 비지 않으면 멈춘다.
- `sync-agents.sh --force` 의 출력과 강호쟁패 PR 의 `git diff --name-only`(S1). 머지 뒤 S2.

**PR C** (A 가 머지된 뒤, ERP)

- M1 의 명령 — 파일마다 충돌 수가 ③ 의 표와 같은지. 다르면 ERP 가 그사이 사본을 고친 것이니 PR 본문에 적는다.
- 충돌마다 원본 · 사본 · 푼 모양 · 빠지는 것(M3 · M7). `verify-copy.py`(M5) · `grep -c '^- 감사한 커밋:'` 여섯 · 커맨드의 `$base` ·
  `$auditor`. ERP PR 의 `git diff --name-only`(M6).
- 재현 — 새 스크래치에서 M1 을 다시 돌리고 PR 본문의 푼 모양을 대어 PR 의 파일과 `cmp` 로 같다(M7).
- 머지 전 스크래치 대장(`018842c`)으로 그 가지에 비교기 — 새 후보가 몇이고 어디인지 PR 본문에 적는다(D 의 판정 재료).

**PR D** (B · C 가 머지된 뒤, claude-kit)

- 두 클론을 `origin/main` 으로 — `compare-copies.py` 끝 0 · `미판정 0`(L2), `--repo erp --all` 에 FB-1 · 2 · 5 · 11 · 12 · 19 ~ 23 · 25 가 「판정됨」
  (성공 기준 3). `verify-copies.py` 두 줄 「0 커밋 움직임」(L3). `verify-feedback.py` 통과.
- `./scripts/gates.sh` 스물넷 — 로컬과 CI gate 잡(G1). 지문 교집합 0(G3).

- 어긋내 보기 — 새 검사를 세우지 않아 변조본이 없다. M7 의 재현이 그 자리다 — 푼 모양 한 줄을 바꾸면 `cmp` 가 떨어지는 것을 PR C 본문에 적는다.
- 측정 — 모델 호출이 없다. eval · 전수를 돌리지 않는다.

**스스로 쓰기** — claude-kit PR(A · D)은 `slice-review` 로 가른다. 사본 레포 PR(B · C)은 그 레포의 리뷰 규칙을 따르고, 갈래를 PR 본문에 적는다.

**단계 5(배포)** — 배포가 곧 B · C 의 머지다. 되돌리는 길은 두 레포에서 그 머지를 되돌리고 D 를 되돌리는 것이다 — 대장이 옛 커밋으로
돌아간다.

## ⑥ PR 나눔

| PR | 저장소 | 담는 것 | 닫는 것 |
|---|---|---|---|
| A 착공 | claude-kit | 요구사항 · 설계 · ADR 0027 · 마스터플랜(「사본 다시 심기」 `진행`) | 단계 1 · 2, ② G2 |
| B 강호쟁패 심기 | 강호쟁패 | `sync-agents.sh --force` 의 결과 | ② S1 · S2, 성공 기준 1 |
| C ERP 심기 | ERP | 세 쪽 병합과 충돌 여덟을 푼 모양 · 머리줄 | ② M1 ~ M7, 성공 기준 2 · 3 |
| D 대장 | claude-kit | `copies.json` · `feedback.json` | ② L1 ~ L3 · G1 · G3, 성공 기준 3 ~ 7 |

B 와 C 는 서로 기대지 않는다 — 어느 쪽이 먼저 머지돼도 된다. D 는 둘 다 머지된 뒤다(제약 「순서」). 조각을 닫는 기록은 따로 낸다(단계 6).
