# 조각 23 설계 — 사본을 0.4.1 로 다시 심기

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`, 갈림길은 ADR 0034 · ADR 0027.

## ① 바뀌는 것

| 저장소 · 파일 | PR | 무엇 |
|---|---|---|
| claude-kit `docs/master-plan.md` | A | 「사본을 0.4.1 로 다시 심기」 상태 `진행` · 조각 폴더 |
| claude-kit `docs/adr/0034-recopy-041-merge-line.md` | A | 갈림길 넷 |
| 강호쟁패 `.claude/agents/*.md` 여섯 · `.claude/agents/README.md` · `.claude/commands/audit-brief.md` | B | `ddcd21f` 의 작업트리에서 `sync-agents.sh --force` 가 쓴 그대로(② S1). `verify-brief.py` 는 `018842c` 와 `ddcd21f` 가 바이트로 같아 diff 에 없다 |
| ERP `.claude/agents/*.md` 여섯 · `.claude/commands/audit-brief.md` | C | 세 쪽 병합의 결과 그대로(② M1 ~ M3). `verify-brief.py` 는 그대로다 |
| ERP `.claude/agents/README.md` | C | 출처 SHA 한 자리 — 3 줄의 `pdw96/claude-kit@018842c` 를 `ddcd21f` 로. 그 밖은 그대로(② M5) |
| claude-kit `copies.json` | D | 두 줄의 `synced_commit` · `synced_at`(② L1) |
| claude-kit `feedback.json` | D | 비교기가 새 후보를 낼 때만 — 저자의 판정(② L2) |

**앵커볼트.** 대장의 모양 — `copies.json` · `feedback.json` 의 칸은 그대로 쓴다. 이름 · 감사자의 `tools` · 공통 절 · 「…의 칸」 ·
`AGENTS.md` 는 건드리지 않는다 — 원본을 고치지 않는다(하지 않을 일 2). 공통 절은 `018842c` 와 `ddcd21f` 사이에 바뀌지 않았다
(2026-10-16, ERP 모의본에 `verify-copy.py vibe-audit/agents` → `PASS 감사자 6개`).

**고정 영역 · 수트.** claude-kit PR(A · D)의 파일은 다 수트 지문(`eval-key.py route --list` · `full --list`) 밖이다 — eval 이 돌지 않는다.
`run-evals.sh` · `eval.yml` · `sync-agents.sh` 는 고치지 않는다.

**사실.**
- 심는 법 · 충돌을 푸는 규칙 · 출처 커밋의 규칙은 ADR 0027 의 1 ~ 3 이다 — 강호쟁패는 `sync-agents.sh --force`, ERP 는 손으로 세 쪽 병합,
  두 레포 다 한 커밋(`ddcd21f`)의 작업트리에서 심는다. 출처 커밋은 조각 나눔의 이 줄이 든 커밋이고, `ddcd21f..e90400f` 에 `vibe-audit/` ·
  `scripts/sync-agents.sh` 가 없어 내용은 `main` 머리와 같다. `ddcd21f` 는 `main` 의 첫 부모 줄에 있어 `sync-agents.sh` 의 「기본 브랜치에
  없다」 경고에 걸리지 않는다.
- 두 사본의 머리줄은 이미 지금 꼴(`sync-agents.sh` 의 `HDR`)이고 SHA 만 `018842c` 다 — 조각 17 이 둘 다 지금 꼴로 심었다.
- 강호쟁패는 특화가 없어 세 쪽 병합과 `--force` 의 결과가 같다(모의: 여덟 파일 충돌 0, 병합본 = 새 원본을 심은 모양). README 도 생성본
  그대로라 덮어도 잃는 것이 없다. `.claude/audits/` · `settings.json` 은 스크립트가 건드리지 않는다.
- `vibe-audit/agents` · `commands` · `scripts` 에서 `018842c..ddcd21f` 사이에 물러난 파일이 없다 — `--force` 가 지울 것도, 손 병합이 빠뜨릴
  것도 없다.
- 사본은 예산 밖이다 — `verify-budget.py` 는 원본만 잰다.

**시스템 구조.** 부품 · 경계 · 흐름은 그대로다 — 원본 → 사본의 길에 손 병합이 한 번 더 쓰인다. `docs/architecture.md` 는 고치지 않는다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 번호는 ⑤ 와 PR 본문이 같이 쓴다.

- **강호쟁패** (B)
  - S1 claude-kit `ddcd21f` 의 작업트리(`git worktree add <자리> ddcd21f`)에서 `./scripts/sync-agents.sh <강호쟁패> --force` 를 돌린 그대로다 —
    감사자 · 커맨드의 머리줄이 `pdw96/claude-kit@ddcd21f`, 검사기는 원본과 바이트로 같다. 강호쟁패 PR 의 `git diff --name-only` 가 ① 의 B 줄
    밖을 들지 않는다.
  - S2 B 가 머지된 뒤 클론을 `origin/main` 으로 두고, `ddcd21f` 를 든 스크래치 대장으로 `compare-copies.py --repo ganghojaengpae --all` → 후보 0.
- **ERP** (C)
  - M1 병합 재료 — 파일마다 셋이다. 밑: `git show 018842c:vibe-audit/<자리>/<이름>` 을 `sync-agents.sh` 의 awk 와 `HDR`(SHA `018842c`)로 심은
    모양. 사본: ERP `origin/main` 의 그 파일. 원본: `ddcd21f` 를 같은 awk 와 `HDR`(SHA `ddcd21f`)로 심은 모양. 검사기는 머리줄 없이 바이트
    그대로다. `git merge-file <사본> <밑> <원본>`.
  - M2 결과는 `git merge-file` 이 낸 그대로다 — 모의는 여덟 파일 다 충돌 0 이다. 충돌이 나면 ERP 가 그사이 사본을 고친 것이니 ADR 0027 의 2
    로 풀고, 충돌마다 원본 문구 · 사본 문구 · 푼 모양 · 사본에서 빠지는 것을 PR 본문에 적어 저자가 그 PR 에서 정한다.
  - M3 바뀌는 줄 — 충돌 0 이면 감사자 여섯 · 커맨드의 머리줄 일곱(SHA `018842c` → `ddcd21f`)과 `audit-secrets` 「보지 않는 것」 첫 문단의 한
    줄뿐이다. 그 줄은 `ddcd21f` 원본의 그 줄과 글자가 같다.
  - M4 `verify-copy.py <ddcd21f 의 vibe-audit/agents> <ERP>/.claude/agents` 가 PASS 다.
  - M5 ERP 의 `.claude/agents/README.md` 는 출처 SHA 한 자리만 바뀐다 — `git diff` 가 3 줄의 `018842c` → `ddcd21f` 하나다. 그 밖의 ERP 파일은
    그대로다 — ERP PR 의 `git diff --name-only` 가 ① 의 C 줄 밖을 들지 않는다.
  - M6 재현 — PR 본문에 M1 의 명령과 파일마다 충돌 수 · 바뀐 줄 수를 적는다. 누가 M1 을 다시 돌리면 PR 의 파일과 바이트로 같다. 이 표가
    닫는 기록의 `--merge` 줄의 근거다(ADR 0034 의 1).
- **대장** (D, B · C 가 머지된 뒤)
  - L1 `copies.json` — 두 줄의 `synced_commit` 이 `ddcd21f` 의 전체 SHA, `synced_at` 이 심은 날. 강호쟁패 줄은 S1 의 작업트리 `copies.json` 에
    `sync-agents.sh` 가 적은 줄 그대로, ERP 줄은 M4 의 PASS 뒤 손으로(`CLAUDE.md` 「금지」). `agents_path` 는 그대로다.
  - L2 두 클론을 `origin/main` 으로 두고 `compare-copies.py` 가 끝 0 · `미판정 0` 이다. 모의대로면 `후보 27 — 미판정 0 · 판정됨 27` 이고
    `feedback.json` 은 그대로다. 새 후보가 나오면 저자가 판정해 이어지는 번호로 적는다 — `seen` 은 `erp` · 파일 · ERP 의 머지 커밋 · 밑
    `ddcd21f`.
  - L3 `verify-feedback.py` · `verify-copies.py` 통과 — 클론이 있는 세션에서 두 줄 다 「원본은 그 뒤 0 커밋 움직임」, 「바뀐 원본」 없음.
- **게이트** (A · D)
  - G1 `./scripts/gates.sh` 스물넷 통과 — 새 검사를 세우지 않는다.
  - G2 A 는 결정 문서뿐이다 — `verify-slice-gate.py` 가 본다.
  - G3 A · D 의 `git diff --name-only main...HEAD` 와 수트 지문 목록의 교집합 0.

**보장하지 않는 것(알려진 한계)**

- **새 문장이 실제 회차에서 일하는가** — 두 레포의 다음 `audit-secrets` 회차가 본 성능을 표식 아래로 올리는지는 그 회차가 보인다(하지 않을
  일 5). 원본에서 잰 것은 `gap-unowned` 한 케이스다(조각 22).
- **ERP 의 겹침** — 「감사한 커밋」 줄 두 자리(조각 17 「지켜본 것」)는 그대로 남는다. ERP 의 일이다.
- **B · C 머지와 D 사이** — 대장이 옛 커밋을 드는 동안 클론이 있는 세션의 `compare-copies.py` 는 원본의 고침(그 한 줄)을 사본의 차이로 보고
  미판정을 찍는다. `verify-copies.py` 는 공통 절이 그대로라 PASS 다. CI 는 클론 경로가 닿지 않아 영향이 없다. D 가 그 창을 닫는다.
- **병합 모드** — 다음 심기를 기계로 되풀이하는 길은 세우지 않는다(하지 않을 일 1). 줄은 닫는 기록이 더한다.
- **아직 겪지 않은 가설적 경계 사례** — 예: 조각 중에 ERP · 강호쟁패가 사본을 또 고친다, `ddcd21f` 뒤 원본이 움직인다. 앞의 것은 그 머리에서
  다시 병합하고(M2 의 충돌 길), 뒤의 것은 멈추고 저자에게 올린다. 리뷰가 그 밖을 짚으면 범위 밖이다(조각 6 「닫으며」).

## ③ 받는 입력

닫힌 목록이다. 2026-10-16 의 claude-kit `main`(`e90400f`) · ERP `main`(`1046566`) · 강호쟁패 `main`(`ab2748e`)에서 뽑았다.

**대장 줄** — `copies.json`

| `repo` | `agents_path` | `synced_commit` |
|---|---|---|
| `erp` | `/home/user/erp/.claude/agents` | `018842c` |
| `ganghojaengpae` | `/home/user/ganghojaengpae/.claude/agents` | `018842c` |

**사본 자리** — `sync-agents.sh` 가 심는 셋과 그 옆.

| 레포 | `agents/` | `commands/` | `scripts/` | 이 조각이 건드리지 않는 것 |
|---|---|---|---|---|
| ERP | 감사자 여섯 · `README.md`(ERP 가 다시 씀, 44 줄) | `audit-brief.md` | `verify-brief.py` | `hooks/` · `skills/` · `settings.json` |
| 강호쟁패 | 감사자 여섯 · `README.md`(생성본) | `audit-brief.md` | `verify-brief.py` | `audits/` · `settings.json` |

**머리줄** — 한 꼴. 두 레포 다 `sync-agents.sh` 의 `HDR` 에 SHA `018842c` 다.

**원본** — `ddcd21f` 의 여덟 파일: `vibe-audit/agents/audit-{contract,data,internal,ops,quality,secrets}.md` · `vibe-audit/commands/audit-brief.md` ·
`vibe-audit/scripts/verify-brief.py`. `018842c..ddcd21f` 에서 `audit-secrets.md` 한 줄이 바뀌었고 일곱은 그대로다.

**병합 모의** — 2026-10-16, M1 의 재료.

| 파일 | ERP 충돌 · 바뀐 줄 | 강호쟁패 충돌 · 바뀐 줄 |
|---|---|---|
| `audit-contract.md` · `audit-data.md` · `audit-internal.md` · `audit-ops.md` · `audit-quality.md` · `audit-brief.md` | 0 · 1(머리줄) | 0 · 1(머리줄) |
| `audit-secrets.md` | 0 · 2(머리줄 · 「보지 않는 것」 첫 문단) | 0 · 2 |
| `verify-brief.py` | 0 · 0 | 0 · 0 |

ERP 모의본(위 병합 + README 3 줄의 SHA)에 스크래치 대장(`ddcd21f`)으로 비교기를 대면 `후보 27 — 미판정 0 · 판정됨 27`. 강호쟁패 병합본은
여덟 파일 다 `ddcd21f` 를 심은 모양과 바이트로 같다.

**`feedback.json`** — 비교기에 나오는 ERP 의 판정된 해시 스물일곱. 강호쟁패 0.

## ④ 결정

**정한 것** — ADR 0034. 심는 법 · 충돌을 푸는 규칙 · 출처 커밋의 규칙은 ADR 0027 의 1 ~ 3 을 그대로 따른다.

- 1 `--merge` 줄 — 이 조각을 닫는 기록에서 더한다. C 의 병합 결과를 근거로 — 저자, 2026-10-16 착공 대화, 세션이 추천한 쪽
- 2 PR 나눔 — 조각 17 과 같은 넷(착공 · 강호쟁패 · ERP · 대장) — 저자, 착공 PR #87 을 연 뒤의 인터뷰, 세션이 추천한 쪽
- 3 출처 커밋 — `ddcd21f` — 인터뷰, 세션이 추천한 쪽
- 4 모의와 달리 충돌이 나면 — ADR 0027 의 2 로 풀고 ERP PR 에서 저자가 정한다(② M2) — 인터뷰, 세션이 추천한 쪽

**열어 둔 것**

없음 — 갈림길 넷을 착공에서 정한다. 충돌이 나면 푸는 모양(② M2)은 결정이 아니라 C 의 일이고 저자가 C 에서 가른다. 새 후보의 판정은 D 의
일이다.

## ⑤ 검증 계획

명령은 PR 본문에 결과와 함께 적는다.

**PR A**

- `./scripts/gates.sh` 스물넷 통과 — `verify-docs.py` 가 새 조각 폴더를, `verify-slice-gate.py` 가 착공 PR 에 결정 문서뿐인지를 본다(G2).
- 지문 — `git diff --name-only main...HEAD` 와 `eval-key.py route --list` · `full --list` 의 교집합 0(G3).

**PR B** (A 가 머지된 뒤, 강호쟁패)

- `git diff --stat ddcd21f origin/main -- vibe-audit/ scripts/sync-agents.sh` 가 비었는지 먼저 본다 — 비지 않으면 멈춘다.
- `sync-agents.sh --force` 의 출력과 강호쟁패 PR 의 `git diff --name-only`(S1) · 머리줄 일곱의 SHA. 머지 뒤 S2.

**PR C** (A 가 머지된 뒤, ERP)

- M1 의 명령 — 파일마다 충돌 수 · 바뀐 줄 수가 ③ 의 표와 같은지. 다르면 PR 본문에 적고 M2 의 충돌 길로 간다.
- `grep -F` 로 `audit-secrets` 의 그 줄이 `ddcd21f` 원본의 줄과 같음(M3) · `verify-copy.py`(M4) · ERP PR 의 `git diff --name-only` 와 README
  의 diff(M5).
- 재현 — 새 스크래치에서 M1 을 다시 돌려 PR 의 파일과 `cmp` 로 같다(M6).
- 머지 전 스크래치 대장(`ddcd21f`)으로 그 가지에 비교기 — 새 후보가 몇이고 어디인지 PR 본문에 적는다(D 의 판정 재료).

**PR D** (B · C 가 머지된 뒤, claude-kit)

- 두 클론을 `origin/main` 으로 — `compare-copies.py` 끝 0 · `미판정 0`(L2), `--repo erp --all` 이 판정된 스물일곱을 그대로(성공 기준 3).
  `verify-copies.py` 두 줄 「0 커밋 움직임」(L3). `verify-feedback.py` 통과.
- `./scripts/gates.sh` 스물넷 — 로컬과 CI gate 잡(G1). 지문 교집합 0(G3).

- 어긋내 보기 — 새 검사를 세우지 않아 변조본이 없다. M6 의 재현이 그 자리다 — 병합본 한 줄을 바꾸면 `cmp` 가 떨어지는 것을 PR C 본문에 적는다.
- 측정 — 모델 호출이 없다. eval · 전수를 돌리지 않는다.

**스스로 쓰기** — claude-kit PR(A · D)은 `slice-review` 로 가른다. 사본 레포 PR(B · C)은 그 레포의 리뷰 규칙을 따르고, 갈래를 PR 본문에 적는다.

**단계 5(배포)** — 배포가 곧 B · C 의 머지다. 되돌리는 길은 두 레포에서 그 머지를 되돌리고 D 를 되돌리는 것이다 — 대장이 `018842c` 로
돌아간다.

## ⑥ PR 나눔

| PR | 저장소 | 담는 것 | 닫는 것 |
|---|---|---|---|
| A 착공 | claude-kit | 요구사항 · 설계 · ADR 0034 · 마스터플랜(「사본을 0.4.1 로 다시 심기」 `진행`) | 단계 1 · 2, ② G2 |
| B 강호쟁패 심기 | 강호쟁패 | `sync-agents.sh --force` 의 결과 | ② S1 · S2, 성공 기준 1 |
| C ERP 심기 | ERP | 세 쪽 병합의 결과 · README 의 출처 SHA | ② M1 ~ M6, 성공 기준 2 · 3 |
| D 대장 | claude-kit | `copies.json` · 새 후보가 나오면 `feedback.json` | ② L1 ~ L3 · G1 · G3, 성공 기준 3 ~ 7 |

B 와 C 는 서로 기대지 않는다 — 어느 쪽이 먼저 머지돼도 된다. D 는 둘 다 머지된 뒤다(제약 「순서」). 조각을 닫는 기록은 따로 내고(단계 6),
그 기록이 `--merge` 줄을 더한다(성공 기준 8).
