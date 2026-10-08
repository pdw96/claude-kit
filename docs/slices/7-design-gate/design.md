# 조각 7 설계 — 설계 → 구현 관문

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`, 갈림길은 ADR 0016.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A | 「설계 → 구현 관문」 상태 `진행` · 조각 폴더 |
| `docs/adr/0016-design-gate.md` | A | 갈림길 여섯 |
| `scripts/verify-slice-gate.py` | B | 새 검사 — ③ 을 읽고 ② 의 B · G · R 을 판정한다. `python3 scripts/verify-slice-gate.py [--base <rev> --head <rev>]`, 통과 0 · 실패 1 · 잘못 부름 2 |
| `scripts/test-verify-slice-gate.py` | B | 자체 시험 — 임시 git 레포에서 ⑤ 의 꼴마다 |
| `scripts/gates.sh` | B | 두 줄 · 끝의 개수 「열넷」 → 「열여섯」 |
| `docs/procedure.md` | B · C | 「일곱 단계」 3 의 맡는 도구 — B 가 검사를, C 가 스킬 둘을 적는다. 머리의 「떨어지는 검사는 … 「설계 → 구현 관문」이 `닫힘` 이 되기 전까지 없다」와 빈자리 「설계 → 구현 관문」의 줄은 조각을 닫을 때 고친다 |
| `CHECKLIST.md` | B | 「조각을 시작했다면」의 「구현은 그 PR 이 머지된 뒤」 — 순서는 `verify-slice-gate.py` 가 보고, 설계 ④ 의 열어 둔 것을 정했는지는 사람이 본다 |
| `docs/architecture.md` | B | 「문서」 — 착공과 구현의 순서를 무는 검사 |
| `vibe-slice/skills/slice-docs/SKILL.md` | C | 「조각을 꺼낼 때」 — 착공 PR 에 싣는 것(결정 문서) |
| `vibe-slice/skills/slice-review/SKILL.md` | C | 「1. 기준」 — 구현 PR 이면 착공 머지를 먼저 본다. 「2. 가르기」 안 — 착공 PR 이 구현을 싣는다 |
| `vibe-slice/.claude-plugin/plugin.json` | C | 판 `0.3.0`. 설명은 그대로 — `marketplace.json` 은 고치지 않는다 |
| `vibe-audit/evals/budget.txt` | C | 스냅숏의 `[vibe-slice]` 절. 수트 지문 밖이다 |

**앵커볼트.** 건드리지 않는다 — 이름이 늘지 않고(검사 스크립트는 앵커볼트 이름이 아니다), 「…의 칸」 네 절 · 틀 · 대장 ·
감사자 · `AGENTS.md` 는 그대로다. `verify-slice-gate.py` 는 마스터플랜의 「가리키는 문서」 · 「조각 나눔」 표를 읽는데, 그
모양은 이미 「…의 칸」(앵커볼트)과 문서 대조 검사가 문다.

**시스템 구조.** 키 없는 게이트에 검사가 하나 는다 — 부품 표의 「키 없는 게이트」 줄은 목록을 `gates.sh` 에 미루므로 그대로이고,
PR B 가 「문서」 절에 한 줄을 더한다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 번호는 ⑤ 와 검사의 출력이 같이 쓴다.

- **기준과 머리** (`verify-slice-gate.py`)
  - B1 **기준은 늘 기본 가지다.** 고르는 순서는 셋이다.
    1. 인자 `--base <rev> --head <rev>` — 둘 다 준다. 하나만 주면 잘못 부름이다.
    2. 인자가 없고 `GITHUB_EVENT_PATH` 의 JSON 에 `pull_request` 가 있으면 — 기준 가지(`pull_request.base.ref`)가 기본 가지
       (`repository.default_branch`)면 기준은 `pull_request.base.sha`, 아니면(쌓은 PR) `origin/<기본 가지>`. 머리는
       `pull_request.head.sha`.
    3. 그 밖(로컬 · `push` · `workflow_dispatch`) — 기준은 `origin/main` 과 `main` 가운데 앞선 쪽(한쪽이 다른 쪽을 품는다),
       머리는 작업트리. 둘 중 하나만 있으면 그것이고, 둘이 갈라졌으면 `origin/main` 이다. 클라우드 세션의 클론은
       `origin/main` 이 낡은 채 `main` 만 최신일 수 있다 — 이 착공을 쓴 세션이 그랬다(`origin/main` 8c3fb38, `main` 8849e80).
       낡은 기준으로 보면 그 사이 머지된 PR 이 다 이 PR 의 변경으로 잡혀 거짓 G1 이 난다.
    고른 기준 sha · 머리(sha 또는 「작업트리」) · 어디서 골랐나(인자 · 이벤트 · 이벤트의 쌓은 PR · 로컬)를 찍는다.
  - B2 기준을 못 찾으면 떨어진다 — rev 가 없다 · merge-base 가 없다(얕은 클론) · 이벤트 JSON 이 깨졌거나 위의 키가 없다.
    모르면 지나가지 않는다.
  - B3 바꾼 파일은 merge-base(기준, 머리)에서 머리까지 바뀐 경로다 — 더함 · 고침 · 지움, 이름 바꿈은 옛 경로와 새 경로 둘 다.
    머리가 작업트리면 추적된 파일의 커밋 안 된 변경과 무시되지 않은 새 파일까지.
  - B4 기준에 `docs/master-plan.md` 가 없으면 「기준에 마스터플랜이 없다 — 보지 않는다」를 찍고 지나간다 — 프로젝트 층을
    세우는 PR(claude-kit #14)과 절차 전의 역사(#7)다.
  - B5 바꾼 파일이 없으면 지나간다(기본 가지의 `push`).
- **관문**
  - D1 **결정 문서**는 다섯 꼴이다 — 기준 마스터플랜 「가리키는 문서」 의도 줄의 첫 경로 토막 · `docs/master-plan.md` ·
    `docs/procedure.md` · `docs/adr/` 바로 아래의 `*.md` · `docs/slices/<폴더>/requirements.md` · `design.md`(ADR 0016 의 4).
  - G1 **착공 PR 에 구현이 없다.** 바꾼 파일 가운데 기준에 없던 `docs/slices/<폴더>/requirements.md` 나 `design.md` 가 하나라도
    있으면, 바꾼 파일은 다 결정 문서다. 아니면 결정 문서 밖의 파일을 다 찍고 떨어진다.
  - G2 **구현은 머지된 설계 위에 선다.** 바꾼 파일 가운데 결정 문서 밖이 하나라도 있으면, 기준 마스터플랜의 조각 나눔에
    상태가 `진행` 이고 조각 폴더 칸의 폴더에 기준에서 `design.md` 가 있는 줄이 하나 이상 있다. 아니면 결정 문서 밖의 파일과
    기준의 `진행` 조각(없으면 없다고)을 찍고 떨어진다.
  - G1 과 G2 는 둘 다 본다 — 하나가 떨어져도 다른 하나의 판정까지 찍는다.
- **실행**
  - R1 실패는 줄마다 `[<보장 번호>] <무엇>` 이고, 통과 0 · 실패 1 · 잘못 부름 2 다. 잡히지 않은 예외로 끝나지 않는다.
  - R2 모델 · 네트워크를 부르지 않는다. 기준의 파일은 `git show <기준>:<경로>` 로 읽는다 — 작업트리나 머리의 마스터플랜이
    아니다. 머리가 바꾼 마스터플랜(상태를 `진행` 으로 고친 착공 PR)은 G2 의 근거가 되지 않는다.
  - R3 마스터플랜의 표는 문서 대조 검사와 같은 법(조각 3 설계 ③ 「줄을 읽는 법」)으로 읽는다. 기준 마스터플랜에서
    「조각 나눔」 표를 못 읽으면 G2 는 지나가지 않는다.
  - R4 `gates.sh` 가 인자 없이 검사를 부르고, 자체 시험 `test-verify-slice-gate.py` 를 부른다.
- **스킬** (`vibe-slice` — 다른 레포에 닿는 쪽)
  - K1 `slice-docs` 「조각을 꺼낼 때」가 착공 PR 에 싣는 것을 적는다 — 요구사항 · 설계 · ADR · 마스터플랜, 범위를 고쳤으면
    의도. 구현은 착공 PR 이 기준 가지에 머지된 뒤다.
  - K2 `slice-review` 「1. 기준」 — 구현 PR 이면 기준을 모으기 전에 그 조각의 착공이 기준 가지에 머지됐는지 본다(기준
    가지의 마스터플랜에서 그 조각이 `진행` 이고 설계가 있다). 아니면 가르지 않고 「착공이 머지되지 않았다 — 단계 3 의
    들어가는 조건」이라고 말한다.
  - K3 `slice-review` 「2. 가르기」 안 — 착공 PR 이 K1 밖의 파일(구현)을 싣는다.
  - K4 `vibe-slice/.claude-plugin/plugin.json` 의 판이 기준 커밋보다 높고, `claude plugin validate ./vibe-slice` ·
    `verify-manifest.py` 가 통과한다.
  - K5 `verify-budget.py` — `slice-review` · `slice-docs` 호출 시 ≤ 4,500, `vibe-slice` 상시 합계 ≤ 5,600. 천장 상수는
    그대로이고, 스냅숏이 같은 PR 에 있다.
- **비용**
  - X1 PR B · C 가 바꾼 파일 가운데 수트 지문(`eval-key.py route --list` · `full --list`, 기준과 머리 둘 다)에 드는 것이 0 이다.

**보장하지 않는 것(알려진 한계)**

- **어느 조각의 구현인지** — `진행` 조각이 둘 이상이면 다른 조각의 구현을 실어도 G2 를 지나간다(ADR 0016 의 3, 하지 않을 일 3).
- **조각 밖 PR** — `진행` 조각이 있으면 조각과 상관없는 고침도 지나가고, 없으면 떨어진다. 예외 표지는 없다(하지 않을 일 4).
- **결정 문서만 바꾸는 PR** — 조각 밖이어도 지나간다. `docs/procedure.md` 를 고치는 조각 밖 PR 도 그렇다(ADR 0016 의 4).
- **결정 문서의 내용** — 착공 PR 이 설계 문서 안에 코드를 적어도 모른다. 경로만 본다.
- **⑥ 밖의 것 · 단계 3 의 다른 조건** — 하지 않을 일 1 · 2. 구현 PR 이 ⑥ 의 그 줄을 넘었는지는 `slice-review` 가 리뷰에서 본다.
- **로컬 판정의 기준** — 로컬은 `origin/main` · `main` 가운데 앞선 쪽을 쓰므로, 둘 다 받아 오지 않았으면 낡은 기준이다 —
  그 사이 머지된 PR 이 이 PR 의 변경으로 잡힌다. 실패의 출력이 기준 sha 를 찍으니 사람이 알아보고 받아 온다. 머지를 막는
  판정은 CI 의 것이다.
- **머지를 막는지** — gate 잡이 떨어지는 것까지다. 필수 체크는 저장소 설정이다(하지 않을 일 7).
- **다른 레포** — 검사가 돌지 않는다. 스킬은 세션이 부를 때만 문다 — 세션이 스킬대로 하는지는 지침이다(ADR 0016 의 1).
- **스킬이 「기준 가지」를 읽는 길** — 레포마다 다르다(`gh` · GitHub MCP · `git fetch`). 스킬은 무엇을 보는지만 적고 길은
  세션에 맡긴다. 기준 가지를 읽지 못하면 그렇다고 말하고 가르지 않는다.
- **아직 겪지 않은 가설적 경계 사례** — 예: 기본 가지가 아닌 가지 사이의 머지, 머지 큐 · 다른 CI 의 이벤트, 한 PR 이 착공과
  닫기를 함께 하는 꼴. 겪으면 그 PR 에서 정해 날짜 항목으로 적는다. 리뷰가 이것을 짚으면 범위 밖이다(조각 6 「닫으며」 —
  #28 이 이 경계를 채우다 일곱 회차를 돌았다).

## ③ 받는 입력

닫힌 목록이다. 2026-10-08 의 `main`(8849e80)과 GitHub 의 `pull_request` 이벤트 문서에서 뽑았다. 이 밖은 B2 로 떨어진다.

**인자** — 없음, 또는 `--base <rev> --head <rev>`(순서 무관), 또는 `-h` · `--help`. 그 밖은 사용법을 찍고 exit 2.

**환경** — `GITHUB_EVENT_PATH` 가 가리키는 JSON. 읽는 키는 넷 — `pull_request.base.sha` · `pull_request.base.ref` ·
`pull_request.head.sha` · `repository.default_branch`. `pull_request` 가 없으면(`push` · `workflow_dispatch`) 이 길을 쓰지
않는다. 변수가 없거나 파일이 없어도 쓰지 않는다.

**git** — 저장소 역사 전체. 부르는 것은 `rev-parse` · `merge-base` · `diff --name-only --no-renames` · `ls-files --others
--exclude-standard` · `show <rev>:<경로>` · `cat-file -e <rev>:<경로>` · `merge-base --is-ancestor`. 가지는
`origin/<기본 가지>` 와 로컬 `main` 이다.

**기준의 파일**

- `docs/master-plan.md` — `## 가리키는 문서` 표의 의도 줄(무엇 칸이 `의도` 로 시작) 어디 칸의 첫 `` `…` `` 토막과,
  `## 조각 나눔` 표의 여섯 칸(순서 · 조각 · 목표 한 줄 · 의존 · 상태 · 조각 폴더). 상태는 `진행` 만 보고, 조각 폴더 칸은
  `` `docs/slices/<폴더>/` `` 토막만 본다(`—` 로 시작하면 폴더가 없다). 지금 의도 줄은 `INTENT.md`, `진행` 조각은 없다.
- `docs/slices/<폴더>/design.md` · `requirements.md` — 있는지만 본다.

**바꾼 파일의 경로** — 저장소 맨 위 기준의 상대 경로. 결정 문서(D1)는 경로의 글자로만 가른다 — `docs/adr/` 아래 폴더 속의
파일 · `docs/slices/<폴더>/` 의 다른 파일(그림 등)은 결정 문서가 아니다.

## ④ 결정

**정한 것** — ADR 0016.

- 1 무는 자리는 claude-kit 의 키 없는 검사와 `vibe-slice` 의 스킬 둘(저자)
- 2 검사는 G1 · G2 를 문다 — ① 표 대조는 하지 않는다(저자가 맡겼고 세션이 골랐다 · 저자 승인)
- 3 어느 조각인지 가리지 않는다 — `진행` 조각이 하나라도 있으면 통과(저자)
- 4 결정 문서의 집합(세션 제안 · 저자 승인)
- 5 기준과 머리를 고르는 순서 — 인자 · 이벤트 · 로컬, 쌓은 PR 은 기본 가지로(세션 제안 · 저자 승인)
- 6 검사는 `gates.sh` 가 부른다 — `eval.yml` 을 고치지 않는다(세션 제안 · 저자 승인)

**열어 둔 것**

- K2 · K3 의 문구가 `slice-review` 의 호출 시 여유 581 자에 드는지 — PR C 가 열기 전에 이 설계 끝에 날짜를 박은 항목으로
  정한다. 넘으면 압축이 먼저다(ADR 0004). 천장은 올리지 않는다.

## ⑤ 검증 계획

명령은 PR 본문에 결과와 함께 적는다. 「어긋내 보기」는 일부러 망가뜨린 작업트리에 같은 명령을 대어 떨어지는지 본 뒤 되돌린다.

**PR B**

- R4 — `./scripts/gates.sh` 열여섯 통과.
- B · D · G · R — `test-verify-slice-gate.py` 가 임시 git 레포(원격 `origin` 과 기본 가지 `main` 을 갖춘)에서 꼴마다 판정과
  보장 번호를 본다.

  | 꼴 | 기대 |
  |---|---|
  | 착공 — 새 조각 폴더의 요구사항 · 설계 · 새 ADR · 마스터플랜 · 의도 | 통과 |
  | 착공 + `scripts/x.py` | G1 |
  | 착공 + `CHECKLIST.md`(결정 문서가 아닌 문서) | G1 |
  | 착공 + `docs/slices/<폴더>/notes.md` | G1 |
  | 기준에 `진행` 조각이 없을 때 구현 | G2 |
  | 기준에 `진행` 조각이 있으나 그 폴더에 `design.md` 가 없을 때 구현 | G2 |
  | 머리만 마스터플랜을 `진행` 으로 고친 구현(R2) | G2 |
  | 기준에 `진행` 조각과 설계가 있을 때 구현 · 설계 끝 날짜 항목 | 통과 |
  | 닫는 PR — 요구사항 「닫으며」 · 마스터플랜 · 절차 지도 · `README.md` | 통과(기준에 `진행`) |
  | 기준에 마스터플랜이 없다 | 「보지 않는다」, exit 0 |
  | 바꾼 파일이 없다 | 통과 |
  | 기준 rev 가 없다 · 얕은 클론 | B2, exit 1 |
  | 로컬 — `origin/main` 이 낡고 `main` 이 앞섰다 | `main` 을 기준으로 — 거짓 G1 이 없다 |
  | 이벤트 — 기준 가지가 기본 가지 | 이벤트의 기준 sha 를 쓴다 |
  | 이벤트 — 착공 가지 위에 쌓은 구현 PR | 기본 가지로 보고 G1 |
  | 이벤트 JSON 이 깨졌다 · 키가 없다 | B2 |
  | 작업트리 — 커밋 안 된 구현 파일 · 무시되지 않은 새 파일 | G2 |
  | 이름 바꿈 `scripts/a.py` → `docs/adr/0099-x.md` | 옛 경로로 G2 |
  | `--base` 만 · 모르는 인자 | exit 2 |

- 어긋내 보기 — 다섯 다 자체 시험이 떨어진다: G1 의 판정을 지운 작업트리, G2 의 `design.md` 확인을 지운 작업트리, B1 의
  쌓은 PR 대체를 지운 작업트리, B1 의 앞선 쪽 고르기를 `origin/main` 고정으로 바꾼 작업트리, B3 의 무시되지 않은 새 파일을
  뺀 작업트리.
- **역사 재연(성공 기준 2)** — 머지 커밋 `m` 마다 `--base m^1 --head m^2` 로 #14 ~ #31 과 #7 을 돌린 표, 그리고 `--base 69f0008
  --head 5eff890`(착공 #28 과 구현 #29 를 한 PR 로 붙인 꼴). 기대 — #15 ~ #31 통과, #14 · #7 보지 않음, 붙인 꼴 G1.
  PR A 의 머지(이 착공)도 표에 더한다 — 통과.
- **CI(성공 기준 3)** — PR B 의 gate 잡 로그에서 `verify-slice-gate.py` 의 기준 · 머리 sha 와 「이벤트」를 찍은 줄.
- X1 — `git diff --name-only main...HEAD` 와 기준 · 머리 각각의 `eval-key.py route --list` · `full --list` 의 교집합이 0.

**PR C**

- K1 ~ K3 — 두 `SKILL.md` 에 그 문구가 있다(grep). 어긋내 보기: 기준 커밋에는 없다.
- K4 — `git show main:vibe-slice/.claude-plugin/plugin.json` 과 머리의 `version` 을 견줘 머리가 높다. `gates.sh` 의 `validate`
  · `verify-manifest.py` 통과.
- K5 — `verify-budget.py` 통과와 스냅숏의 값.
- X1 — PR B 와 같다.

**스스로 쓰기** — PR A ~ C 의 리뷰를 `slice-review` 로 가른다. PR 본문의 `## 리뷰 회차` 와 답글. PR C 는 머지된 PR B 의
검사를 CI 에서 지나간다.

**단계 5(배포)** — PR C 뒤: 저자가 강호쟁패에서 `claude plugin marketplace update pdw96-kit` → `claude plugin update
vibe-slice@pdw96-kit` → 리로드 뒤 `/vibe-slice:slice-docs` · `/vibe-slice:slice-review` 가 새 판으로 뜨는지, ERP 에
`./scripts/sync-slice.sh <ERP> --force` 를 돌려 커밋한 뒤 클라우드 세션에서 두 스킬이 뜨는지 본다.

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A 착공 | 요구사항 · 설계 · ADR 0016 · 마스터플랜 | 단계 0 · 1 · 2 |
| B 검사 | `verify-slice-gate.py` · 자체 시험 · `gates.sh` · `docs/procedure.md` 의 검사 줄 · `CHECKLIST.md` · `docs/architecture.md` · 역사 재연 | 성공 기준 1 · 2 · 3 · 6 |
| C 스킬 | `slice-docs` · `slice-review` · `plugin.json` · 스냅숏 · `docs/procedure.md` 의 스킬 줄 | 성공 기준 4 · 6 |

성공 기준 5 는 PR C 가 머지된 뒤 단계 5 에서 저자가 닫는다. B 가 C 보다 먼저다 — C 가 B 의 검사를 CI 에서 지나가는 것을 본다.
