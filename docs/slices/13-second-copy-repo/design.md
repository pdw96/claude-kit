# 조각 13 설계 — 두 번째 사본 레포

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`, 갈림길은 ADR 0022.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A | 「두 번째 사본 레포」 상태 `진행` · 조각 폴더 |
| `docs/adr/0022-second-copy-repo.md` | A | 갈림길 일곱 |
| `scripts/compare-copies.py` | B | 후보 대장에서 후보마다 `seen` 의 레포 이름도 읽는다. 판정된 해시가 그 이름 밖의 레포에서 나오면 숨기지 않고 찍는다(② C1 ~ C5). 머리 독스트링 |
| `scripts/test-compare-copies.py` | B | 임시 사본을 하나 더 세워 ② T1 의 꼴 셋을 본다 |
| `scripts/bite-gates.sh` | B | 비교기 변조 하나 더 — 새 레포 갈래를 끈 비교기에 시험이 떨어진다(② T2) |
| `docs/schema.md` | B | 「대상과 관계」 아래 문단 — 비교기가 새 레포를 찍고 `seen` 은 저자가 더한다 · 원본 커밋이 다르면 해시가 갈릴 수 있다. 「이 모양을 무는 것」의 「비교기 변조 다섯」 → 일곱(지금 여섯이다 — 셈이 낡았다) |
| `docs/architecture.md` | B | 「견주기」의 `compare-copies.py` 줄 — 판정한 후보는 새 레포에서 나올 때만 다시 나온다 |
| `copies.json` | C | 둘째 줄 — `sync-agents.sh` 가 적는다(② S3) |
| 강호쟁패 `.claude/agents/` 일곱 · `.claude/commands/audit-brief.md` · `.claude/scripts/verify-brief.py` | C(그 레포의 PR) | `sync-agents.sh` 가 쓴 그대로 |
| 강호쟁패 `.claude/settings.json` | C(그 레포의 PR) | 새 파일 — 이 프로젝트에서 `vibe-audit@pdw96-kit` 를 끈다(ADR 0022 의 1). 내용은 `{"enabledPlugins": {"vibe-audit@pdw96-kit": false}}` 한 줄을 손으로 쓴다 — 클라우드 세션에는 그 플러그인이 설치돼 있지 않아 `claude plugin disable` 이 아무것도 쓰지 않는다(③). 다른 플러그인은 그대로 |
| 강호쟁패 `CLAUDE.md` 91줄 | C(그 레포의 PR) | 「사용자 전역 플러그인 vibe-audit의 에이전트. 저장소에는 없다」 — 사본을 가리키게. 그 레포의 문장이라 세션은 제안만 하고 저자가 정한다 |

**앵커볼트.** 건드리지 않는다 — 이름 · 감사자의 `tools` · 공통 절 · 「…의 칸」 · `AGENTS.md` 그대로다. **대장의 모양**(`copies.json` ·
`feedback.json` 의 칸과 내용 해시)도 그대로다 — `copies.json` 에 줄이 하나 늘 뿐이고, `seen` 은 이미 목록이다. 플러그인 파일을 고치지 않는다
(하지 않을 일 6).

**원본에 레포별 분기를 두지 않는다.** 강호쟁패 쪽 설정 · 문장은 그 레포에만 산다. 원본(`vibe-audit/`)은 바뀌지 않는다.

**시스템 구조.** 부품은 그대로다 — 「견주기」의 흐름에 새 레포 갈래가 든다. `docs/architecture.md` 를 B 에서 고친다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 번호는 ⑤ 와 PR 본문이 같이 쓴다.

- **비교기** (`compare-copies.py`, B)
  - C1 후보 대장에 있는 해시가 그 후보의 `seen[].repo` 에 **없는** 레포의 사본에서 나오면 `--all` 없이도 찍는다. 꼬리표는
    `FB-n <상태> · 새 레포 <이름>[, <이름>…]` 다.
  - C2 `seen[].repo` 에 있는 레포에서만 나오면 지금처럼 숨는다 — `--all` 이면 꼬리표에 「새 레포」 없이 찍는다.
  - C3 `--json` 의 `judged` 에 `new_repos`(목록 — 없으면 빈 목록)가 든다. 미판정 후보의 `judged` 는 지금처럼 `null` 이다.
  - C4 끝 줄의 셈에 「판정됨 · 새 레포 k」를 더한다. k 가 1 이상이면 「`seen` 은 저자가 더한다(`docs/schema.md`)」 한 줄을 찍는다. 종료코드는
    그대로다 — 0 견줬다 · 1 멈췄다 · 2 사용법.
  - C5 쓰지 않는다 — `feedback.json` 은 지금처럼 읽기만 한다. 멈추는 규칙(ADR 0003)도 그대로다.
- **시험** (B)
  - T1 `test-compare-copies.py` 가 같은 고침을 담은 임시 사본 둘(`a` · `b`)로 꼴 셋을 본다 — (가) `seen` 이 `a` 뿐인 후보가 기본 실행에
    `새 레포 b` 로 나온다 · (나) `seen` 이 `a` · `b` 면 기본 실행에 안 나온다 · (다) `--json` 의 `new_repos` 가 (가)에서 `["b"]` 이고, (나)는 `--json` 에 그 후보가 없으며(C2) `--all --json` 에서 `[]` 다.
  - T2 `bite-gates.sh` 가 새 레포 갈래를 끈 비교기(새 레포를 늘 빈 목록으로)에 T1 을 대어 떨어지는 것을 본다. 변조할 자리가 비교기에 꼭 한 번
    있지 않으면 떨어진다(지금의 꼴 그대로).
- **심기** (C)
  - S1 claude-kit `main` 의 커밋에서 심는다 — `sync-agents.sh` 가 「HEAD 가 origin/main 에 없다」 경고를 찍지 않는다.
  - S2 강호쟁패의 PR 은 `sync-agents.sh` 가 쓴 파일을 바이트 그대로 담고, 그 위에 ① 의 설정 · 문장만 더한다. 그 PR 의 머리에서
    `node Tools/check.mjs --fast` 가 통과한다.
  - S3 `copies.json` 의 둘째 줄은 `sync-agents.sh` 가 적은 그대로다 — 손으로 쓰거나 옮기지 않는다(`CLAUDE.md` 「금지」).
  - S4 강호쟁패 PR 이 머지된 뒤 두 클론이 있는 세션에서 `verify-copies.py` 가 강호쟁패 사본을 견줘 PASS 이고, `compare-copies.py` 가 끝 0 으로
    두 줄을 견주며 강호쟁패에서 나온 후보가 0 이다. 견주기 전에 두 클론을 다 원격 기본 가지의 머리로 옮긴다 — 강호쟁패 클론은 PR 을 낸 가지에
    있어, 머지 커밋이 없는 그 머리로는 비교기가 「`origin/main` 보다 뒤」로 멈춘다(ADR 0003). `git switch main && git pull --ff-only`
    (ERP 는 `pull --ff-only`)로 옮긴다.
  - S5 이 조각의 PR 셋은 수트 지문의 파일을 고치지 않는다 — 셋 다 eval 잡이 건너뛴다.

**보장하지 않는 것(알려진 한계)**

- **원본 커밋이 다른 두 사본의 같은 고침** — 해시에 원본 쪽 줄이 들어, ERP(3d6964a)와 강호쟁패(C 의 `main`)에서 같은 고침을 해도 그 자리의
  원본 문구가 그 사이 바뀌었으면 해시가 갈려 C1 이 알아보지 못한다 — 둘 다 미판정 · 판정됨으로 따로 나온다. 해시는 앵커볼트다(하지 않을 일
  2 · ADR 0022 의 3). 원본 문구가 같으면 알아본다.
- **대장의 레포 이름** — `sync-agents.sh` 는 심는 경로의 끝을 이름으로 적는다. 클라우드 세션의 클론이 `ganghojaengpae` 라 그 이름이 된다.
  다른 폴더 이름으로 클론해 다시 심으면 다른 줄이 된다 — 지금의 동작 그대로다.
- **다른 기계에서 견주기** — 대장의 경로가 클라우드 세션의 것이라 저자의 Windows 기계에서는 두 줄 다 「없어서 못 봤다」, 비교기는 멈춘다
  (ADR 0022 의 2). 한 레포만 견주려면 지금처럼 `--repo`. 사본 하나라도 닿지 않으면 다 멈추는 것도 그대로다(C5).
- **강호쟁패의 설계 → 구현 관문** — 심는 PR 은 스킬이 견주면 G2 로 떨어진다(하지 않을 일 5). 그 PR 본문에 G2 와 까닭을 적고 저자가 알고
  머지한다(ADR 0022 의 7). 다시 심을 때마다 같은 G2 가 난다.
- **플러그인을 끄는 설정이 뜻대로 도는지** — Claude Code 의 설정 동작에 기댄다. 단계 5 에서 저자가 강호쟁패 세션에서 본다(성공 기준 4).
  안 되면 그 레포의 설정을 고치는 일이고, 원본은 바뀌지 않는다.
- **ERP 사본의 지금 모양** — ERP `HEAD` 가 마지막 판정 뒤 사본을 고쳤으면 S4 에서 ERP 의 미판정 후보가 나올 수 있다. 판정은 이 조각 밖이다
  (하지 않을 일 1). S4 가 보는 것은 강호쟁패의 후보 0 과 멈추지 않음이다.
- **아직 겪지 않은 가설적 경계 사례** — 예: 한 사본 레포가 두 이름으로 대장에 오름, 세 레포 이상. 겪으면 그 PR 에서 정해 날짜 항목으로
  적는다. 리뷰가 이것을 짚으면 범위 밖이다(조각 6 「닫으며」).

## ③ 받는 입력

닫힌 목록이다. 2026-10-12 의 claude-kit `main`(c341169)과 강호쟁패 `main`(8926418)에서 뽑았다. 이 밖은 비교기가 지금처럼 다룬다 —
후보 대장이 성하지 않으면 멈춘다(`verify-feedback.py`).

**`copies.json`** — `{"copies": [...]}`, 줄마다 `repo` · `agents_path` · `synced_commit` · `synced_at`. 지금 줄은 하나(`erp`,
`/home/user/erp/.claude/agents`, 3d6964a, 2026-09-28).

**`feedback.json`** — 후보 열여덟(FB-1 ~ FB-18). 후보마다 `seen` 이 하나이고 `repo` 는 다 `erp` 다. 비교기가 새로 읽는 칸은 `seen[].repo`
뿐이다 — `verify-feedback.py` 가 비지 않은 문자열인지 이미 본다.

**강호쟁패 `main`(8926418)**

| 자리 | 지금 |
|---|---|
| `.claude/` | `audits/` 하나 — 추적 파일 하나(`audit-internal-2026-10-10-020009.md`) |
| `.claude/agents` · `commands` · `scripts` · `settings.json` | 없다 |
| `.gitignore` | `.claude/` 를 무시하지 않는다 — 심을 자리 넷에 `git check-ignore` 가 빈 출력 |
| 기본 가지 | `main`(`ls-remote --symref`) |
| `Assets/TutorialInfo/Icons/URP.png` | LFS 포인터여야 할 자리에 이미지 — 체크아웃마다 「바뀜」. 비교기의 「더러움」은 사본 자리만 봐 들지 않는다 |
| 머지 전 자동 검사 | `node Tools/check.mjs`(C01 ~ C07) — `git ls-files -co --exclude-standard` 로 추적 · 추적 안 된 파일을 다 읽는다 |
| 마스터플랜 | 있다 — 조각 1 `닫힘`, 나머지 `예정`. `진행` 조각이 없다 |

**Claude Code 의 설정** — 2026-10-12 에 공식 문서(code.claude.com 의 plugins/loading · plugins/cli-reference · sub-agents)에서 읽었다.
실물은 단계 5 에서 본다.

| 무엇 | 문서가 적은 것 |
|---|---|
| `enabledPlugins` 의 합침 | 출처(user `~/.claude/settings.json` < project `.claude/settings.json` < local `.claude/settings.local.json` < …)가 플러그인 id 마다 합쳐진다 — 그 id 를 적은 가장 높은 출처의 값이 선다. 프로젝트의 `"vibe-audit@pdw96-kit": false` 는 사용자 범위의 설치를 그 프로젝트에서 끄고, `vibe-slice@pdw96-kit` 는 건드리지 않는다 |
| 끄는 명령 | `claude plugin disable <플러그인> --scope project` — 높은 범위에 덮어쓰기를 적는다. 커밋한 `false` 는 그 레포를 받은 모든 사람에게 든다. 다만 그 플러그인이 설치된 기계에서만 쓴다 — 이 세션(클라우드, CLI 2.1.296, `vibe-audit` 없음)의 빈 git 저장소에서 부르면 `Plugin "vibe-audit@pdw96-kit" is already disabled at project scope` 로 1 이고 `.claude/` 를 만들지 않았다(2026-10-12, #55 Codex 1회차). 그래서 C 는 파일을 손으로 쓴다(①) |
| 이름이 겹친 에이전트 | 프로젝트 `.claude/agents/` 가 플러그인 `agents/` 보다 앞선다. 플러그인 에이전트는 `vibe-audit:audit-internal` 처럼 플러그인 이름이 앞에 붙는다. 플러그인 커맨드도 `/vibe-audit:audit-brief` 로 따로 뜬다 |

**심어 본 결과** — 이 세션이 2026-10-12 에 버리는 사본(강호쟁패 클론의 복사본 · claude-kit c341169 의 작업트리)에 `sync-agents.sh` 를
돌렸다. 감사자 6 · 커맨드 1 · 검사기 1 과 `README.md` 를 심었고, `node Tools/check.mjs --fast` 는 심기 전 · 뒤 다 일곱 통과다.
`verify-docs.py --repo .` 는 PASS, `verify-slice-gate.py` 는 `[G2] 기준에 설계가 머지된 진행 조각이 없다` 로 떨어졌다. 그 사본 · 작업트리는
지웠다.

**비교기의 출력** — 후보마다 꼬리표 줄 `<FB-n 상태 | 미판정>  sha256:…` 과 `자리 <레포> · <파일>:<줄>` 줄들. 끝 줄
`후보 N — 미판정 u · 판정됨 j`. C1 · C4 는 이 꼴에 덧붙인다.

## ④ 결정

**정한 것** — ADR 0022.

- 1 강호쟁패는 사본만 쓴다 — 그 레포의 프로젝트 설정에서 `vibe-audit` 플러그인을 끈다(저자)
- 2 심는 자리 — 클라우드 세션의 클론, 대장의 경로는 ERP 와 같은 꼴(세션 제안 · 저자)
- 3 새 레포를 알아보는 단위 — 내용 해시 그대로(세션 제안 · 저자)
- 4 비교기 고침은 이 조각에서 — 판정된 해시가 새 레포에서 나오면 찍고, `seen` 은 저자가 더한다(저자)
- 5 닫는 때 — 심고 두 사본을 견주면 닫는다. 첫 되먹임 회차는 이 조각 밖(저자)
- 6 강호쟁패 쪽 PR — 클라우드 세션이 가지를 밀고 드래프트 PR 을 열고, 저자가 그 레포에서 머지한다. `CLAUDE.md` 91줄 문구는 제안으로 싣는다
  (세션 제안 · 저자)
- 7 그 PR 의 G2 — 본문에 까닭을 적고 알고 머지한다. 관문은 고치지 않는다(세션 제안 · 저자)

**열어 둔 것**

없음 — 갈림길 일곱을 착공에서 정했다. 1 · 4 · 5 는 착공 전 인터뷰, 2 · 3 · 6 · 7 은 착공 PR(#55)을 연 뒤의 인터뷰(2026-10-12).

## ⑤ 검증 계획

명령은 PR 본문에 결과와 함께 적는다. 「어긋내 보기」는 일부러 망가뜨린 작업트리에 같은 명령을 대어 떨어지는지 본 뒤 되돌린다.

**PR A**

- `./scripts/gates.sh` 스물넷 통과 — `verify-docs.py` 가 새 조각 폴더를, `verify-slice-gate.py` 가 착공 PR 에 결정 문서뿐인지를 본다.
- 지문 — `git diff --name-only main...HEAD` 와 `eval-key.py route --list` · `full --list` 의 교집합 0. eval 잡이 건너뛴다.

**PR B**

- `./scripts/gates.sh` 스물넷 통과 — 로컬과 CI gate 잡(성공 기준 6).
- T1 — `python3 scripts/test-compare-copies.py` 가 지금의 꼴과 (가) ~ (다)를 지나간다(성공 기준 3).
- T2 — `bash scripts/bite-gates.sh` 의 비교기 변조 일곱이 다 시험을 떨어뜨린다. 어긋내 보기 — 비교기에서 새 레포 갈래만 지운 작업트리에
  T1 을 대면 (가)에서 떨어진다.
- C5 — `git diff main...HEAD -- scripts/compare-copies.py` 에 `feedback.json` 을 쓰는 줄이 없다.
- 지문 — 교집합 0(S5 · 성공 기준 5).

**PR C** (강호쟁패 PR 이 먼저 머지된 뒤)

- S1 — `sync-agents.sh /home/user/ganghojaengpae` 출력에 경고가 없다. 그 출력을 PR 본문에 적는다.
- S2 — 강호쟁패 PR 의 머리에서 `node Tools/check.mjs --fast` 일곱 통과. `git diff` 가 ① 의 파일만 담는다.
- S3 — `git diff main...HEAD -- copies.json` 이 둘째 줄 하나를 더한다. 그 줄의 `synced_commit` 이 `git merge-base --is-ancestor` 로
  `origin/main` 에 든다.
- S4 · 성공 기준 1 · 2 — ERP · 강호쟁패 두 클론을 원격 기본 가지의 머리로 옮긴 뒤(`git -C <클론> rev-parse HEAD` 가 `origin/main` 과 같다)
  `python3 scripts/verify-copies.py` · `python3 scripts/compare-copies.py` 의 출력과 끝값.
- 지문 — 교집합 0.

**스스로 쓰기** — PR A · B · C 의 리뷰를 `slice-review` 로 가른다. PR 본문의 `## 리뷰 회차` 와 답글. B · C 는 `verify-slice-gate.py` 를
CI 에서 지나간다(이 착공이 머지된 뒤).

**단계 5(배포)** — 배포처는 강호쟁패의 세션이다. C 뒤에 저자가 강호쟁패의 대화형 세션(Windows)을 새로 열어 감사자 목록 · `/audit-brief` ·
`vibe-slice` 스킬을 본다(성공 기준 4). 되돌리는 길은 강호쟁패 PR 의 되돌림과 C 의 되돌림(대장의 둘째 줄을 지운다)이다 — 둘 다 수트 지문 밖이다.

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A 착공 | 요구사항 · 설계 · ADR 0022 · 마스터플랜(「두 번째 사본 레포」 `진행`) | 단계 1 · 2 |
| B 비교기 | `compare-copies.py` · `test-compare-copies.py` · `bite-gates.sh` · `docs/schema.md` · `docs/architecture.md` | ② 의 C1 ~ C5 · T1 · T2, 성공 기준 3 · 6 |
| C 심기 | 강호쟁패의 PR(사본 · 설정 · 문장 — 세션이 드래프트로 열고 그 레포에서 저자가 머지, 본문에 G2 와 까닭)과 claude-kit 의 `copies.json` | ② 의 S1 ~ S5, 성공 기준 1 · 2 · 5, 단계 5 의 성공 기준 4 |

B 를 C 앞에 둔다 — 강호쟁패가 `main` 의 새 비교기를 담은 커밋에서 심기고, C 의 견주기가 새 비교기로 돈다. 조각을 닫는 기록은 단계 5 를 본 뒤
따로 낸다(단계 6).

## PR B 에서 정했다 (2026-10-13, 저자)

PR B(#56)를 연 뒤 저자가 정했다. 이 항목이 ② C4 의 끝 줄 꼴을 정한다.

- **C4 끝 줄** — 「판정됨 · 새 레포 k」는 판정됨 j 안의 몫이라 괄호로 묶는다: `후보 N — 미판정 u · 판정됨 j(새 레포 k)`. 설계의
  글자를 그대로 이으면 「판정됨」이 한 줄에 두 번 나와 읽히지 않는다. k 가 1 이상일 때의 안내 줄과 종료코드는 C4 그대로다.
