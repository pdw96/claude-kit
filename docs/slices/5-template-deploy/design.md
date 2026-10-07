# 조각 5 설계 — 틀 배포

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`, 갈림길은 ADR 0013.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A | 「틀 배포」 상태 `진행` · 조각 폴더. 조각 나눔에 「다른 레포의 문서 대조 검사」 한 줄 |
| `docs/adr/0013-template-plugin.md` | A | 갈림길 여덟 |
| `.claude-plugin/marketplace.json` | B | 둘째 플러그인 `vibe-slice` 줄 |
| `vibe-slice/.claude-plugin/plugin.json` | B | 새 매니페스트 — 이름 · 설명 · 판 `0.1.0` · 라이선스 |
| `vibe-slice/skills/slice-docs/SKILL.md` | B | 스킬 — 언제 쓰나 · 틀 넷이 이 폴더 어디에 있나 · 어디에 베끼나 · 절차 지도의 URL |
| `vibe-slice/skills/slice-docs/templates/` | B | `docs/templates/` 의 넷을 `git mv` — 바이트 그대로 |
| `scripts/sync-slice.sh` | B | 클라우드 레인 사본 — 스킬 폴더를 대상 레포 `.claude/skills/slice-docs/` 에 심는다 |
| `scripts/test-sync-slice.py` | B | 위 스크립트의 자체 시험 — 임시 원본 · 대상 |
| `scripts/verify-docs.py` · `scripts/test-verify-docs.py` | B | 틀을 읽는 자리를 새 폴더로 |
| `scripts/verify-manifest.py` · `scripts/test-verify-manifest.py` | B | 마켓플레이스의 플러그인 이름이 겹치지 않고, 저장소 맨 위의 플러그인 폴더(`*/.claude-plugin/plugin.json`)마다 마켓플레이스에 줄이 꼭 하나다 — 그리고 그 자체 시험 |
| `scripts/verify-budget.py` · `vibe-audit/evals/budget.txt` | B | 마켓플레이스의 플러그인마다, `skills/*/SKILL.md` 도 잰다. 스냅숏에 `[vibe-slice]` 절 |
| `scripts/gates.sh` | B | `claude plugin validate ./vibe-slice` · `test-sync-slice.py` · `test-verify-manifest.py` — 세는 줄(`validate` 는 세지 않는다)이 열둘에서 열넷 |
| `CHECKLIST.md` | B | 「플러그인의 파일을 고쳤다면」 — 그 플러그인의 판을 올렸다(`vibe-audit` · `vibe-slice`) |
| `docs/procedure.md` | B | 틀의 자리 세 군데(일곱 단계 1 · 2 의 맡는 도구 · 「대상과 관계」 · 「살아 있는 문서와 기록」), 「계정 스킬의 일」, 「이 모양을 무는 것」의 다른 레포 줄 |
| `docs/architecture.md` | B | 부품에 `vibe-slice` 와 사본 길 |
| `README.md` | B | 「들어 있는 것」 표 · 두 경로의 설치 · 「새 프로젝트를 열 때」 |
| `INTENT.md` | B | What 의 틀 줄이 `vibe-slice` 로 간다고 — 범위는 그대로 |
| `CLAUDE.md` | B | 앵커볼트 「이름」에 `vibe-slice` · `slice-docs` |
| `vibe-audit/agents/audit-internal.md` | C | 체크 항목 뼈대 1 · 6 · 7, 그리고 그만큼의 압축 |
| `vibe-audit/.claude-plugin/plugin.json` | C | 판을 올린다 — 그대로면 이미 설치한 강호쟁패가 갱신해도 옛 감사자를 쓴다 |
| `vibe-audit/evals/<새 케이스>/` | C | 판정 케이스 하나 |
| `vibe-audit/evals/README.md` · `vibe-audit/evals/budget.txt` · `docs/eval-log/2026-10.md` | C | 케이스 표 한 줄 · 스냅숏 · 작업 기록 |

**앵커볼트.** 이름이 둘 는다 — 플러그인 `vibe-slice` · 스킬 `slice-docs`(저자 결정, ADR 0013 의 3). 감사자의 `tools` ·
공통 절 · 대장의 모양 · 「…의 칸」 네 절은 건드리지 않는다. 틀의 자리는 「…의 칸」 밖이다.

**시스템 구조.** 부품(플러그인 하나 · 사본 길 하나)과 흐름이 바뀌므로 PR B 가 `docs/architecture.md` 를 고친다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 번호는 ⑤ 가 같이 쓴다.

- **플러그인**
  - P1 `marketplace.json` 에 `vibe-audit` · `vibe-slice` 둘이 있고, 이름이 겹치지 않으며, 저장소 맨 위의 플러그인 폴더
    (`*/.claude-plugin/plugin.json`)마다 줄이 꼭 하나다. 줄마다 이름 · 설명이 두 매니페스트에서 글자 그대로 같다 —
    `verify-manifest.py` 가 문다. 줄을 빼거나 겹치거나, 폴더는 있는데 줄이 없으면 떨어진다.
  - P2 `claude plugin validate ./vibe-slice` 가 `gates.sh` 에서 통과한다.
  - P3 `vibe-slice` 에 추적된 파일은 `plugin.json` · `SKILL.md` · 틀 넷, 여섯뿐이다 — 에이전트 · 커맨드 · 훅 · MCP 가 없다.
- **틀**
  - T1 틀의 원천은 `vibe-slice/skills/slice-docs/templates/` 하나다. `docs/templates/` 는 없고, 옮긴 넷은 옮기기 전과
    바이트로 같다.
  - T2 문서 대조 검사의 T1 · T2(조각 3 설계 ②)가 새 자리를 문다.
- **스킬**
  - K1 `SKILL.md` 가 틀 넷을 `${CLAUDE_SKILL_DIR}/templates/<이름>.md` 로 든다 — 부르는 레포의 작업 디렉터리가 아니라
    스킬 폴더에서 읽으므로 플러그인 캐시와 사본(`.claude/skills/`)에서 같은 줄이 풀린다. 베낄 자리를 문서 종류마다 든다 — 의도는
    `INTENT.md`, 마스터플랜은 `docs/master-plan.md`, 요구사항 · 설계는 `docs/slices/<순서>-<이름>/`.
  - K2 단계의 조건은 claude-kit `docs/procedure.md` 를 URL(`https://github.com/pdw96/claude-kit/blob/main/docs/procedure.md`)로
    가리킨다 — 지도의 표를 옮겨 적지 않는다.
  - K3 `verify-budget.py` 가 `vibe-slice` 를 잰다 — `SKILL.md` 의 상시 ≤ 900, 호출 시 ≤ 4,500, `vibe-slice` 상시 합계
    ≤ 5,600. 천장 상수는 그대로다.
- **사본** (`sync-slice.sh`)
  - C1 심는 것은 `vibe-slice/skills/slice-docs/` 아래 HEAD 에 추적된 파일 전부이고, 대상 `.claude/skills/slice-docs/` 의
    같은 상대 경로에 선다. `SKILL.md` 는 프론트매터 뒤에 출처 줄(`<!-- pdw96/claude-kit@<sha> 에서 옴 … -->`)이 들고,
    나머지는 바이트 그대로다.
  - C2 원본 스킬 폴더에 커밋 안 된 변경이나 HEAD 에 없는 파일이 있으면 아무것도 쓰지 않고 멈춘다.
  - C3 대상에 `.claude/skills/slice-docs` 가 **폴더로** 이미 있으면 `--force` 없이는 아무것도 쓰지 않고 멈춘다. `--force`
    면 그 폴더를 비우고 다시 심는다 — 사본의 특화는 사라진다. 그 자리가 파일이나 링크(끊긴 링크도)면 C4 대로 `--force`
    여도 멈춘다.
  - C4 심을 자리(`.claude` · `.claude/skills` · `.claude/skills/slice-docs`) 가운데 링크이거나 폴더가 아닌 것이 있으면
    아무것도 쓰지 않고 멈춘다 — 대상 레포 밖에 쓰지 않는다.
  - C5 `copies.json` 과 대상 레포의 다른 파일을 건드리지 않고, 대상 레포에 커밋하지 않는다.
- **감사자** (`audit-internal`)
  - A1 뼈대 1 이 기준 문서로 의도 문서 · `docs/master-plan.md` · 조각 폴더(`docs/slices/*/`)를 이름으로 든다. **의도 문서는
    하나다** — 마스터플랜 「가리키는 문서」의 의도 줄이 가리키는 문서. 그 줄이 없으면 `INTENT.md`, 그것도 없으면
    `PRD.md` 다. 의도 줄이 다른 문서를 가리키는데 `PRD.md` 가 남아 있으면 그 `PRD.md` 는 기준으로 읽지 않는다.
  - A2 뼈대 6 · 7 이 「하지 않을 일」 · 성공 기준의 자리를 둘로 가른다 — 프로젝트 전체의 것은 A1 의 의도 문서 하나의
    Not(또는 「하지 않을 일」), 조각의 것은 **감사 대상 변경이 속한 조각**의 요구사항뿐이다. 다른 조각의 「하지 않을 일」은 그 조각의 구현
    범위에만 걸려, 뒤의 조각이 그것을 한 것은 부적합이 아니다. 어느 조각인지 못 가르면 확인불가로 적는다.
  - A3 프론트매터와 공통 절이 바이트로 그대로다.
  - A4 호출 시 문자 ≤ 11,000 이고, 스냅숏이 같은 PR 에 있다.
  - A5 새 판정 케이스가 수트에서 통과한다 — 진행 조각의 「하지 않을 일」을 어긴 코드를 부적합으로 내고(진짜 부적합),
    닫힌 조각이 하지 않기로 한 것을 뒤 조각이 한 코드는 부적합으로 내지 않는다(덫 1). 마스터플랜의 의도 줄이
    `INTENT.md` 를 가리키는데 남아 있는 옛 `PRD.md` 의 「하지 않을 일」을 어긴 코드도 부적합으로 내지 않는다(덫 2 — A1).
  - A6 `vibe-audit/.claude-plugin/plugin.json` 의 판이 기준 커밋보다 높다.
- **비용**
  - X1 PR B 가 바꾼 파일 가운데 수트 지문(`eval-key.py route --list` · `full --list`, 기준과 머리 둘 다)에 드는 것이 0 이다.

**보장하지 않는 것(알려진 한계)**

- **세션이 틀을 쓴 뒤 절차를 지키는지** — 다른 레포에서는 문서 대조 검사가 돌지 않는다. 사람이 본다 — 조각 나눔
  「다른 레포의 문서 대조 검사」.
- **절차 지도의 URL 이 닿는지** — 네트워크가 막힌 세션은 지도를 읽지 못한다. 스킬은 URL 만 든다.
- **절차 지도의 판** — `main` 을 가리킨다. 지도가 바뀌면 이미 쓴 문서는 그날의 모양이다(기록은 고치지 않는다).
- **새 틀이 설치된 플러그인에 닿는 것** — 서드파티 마켓플레이스는 자동 갱신이 기본으로 꺼져 있고, 리로드는 새 판을
  받지 않는다. 마켓플레이스 목록은 `claude plugin marketplace update pdw96-kit` 이 새로 받고(그 전에는 이미 등록한
  `pdw96-kit` 에 `vibe-slice` 줄이 없어 install 이 실패한다), 설치한 플러그인은 `claude plugin update <플러그인>@pdw96-kit`
  이 받는다 — 또는 `pdw96-kit` 의 자동 갱신을 켜 둔다. 그리고 `plugin.json` 의 판이 그대로면 갱신도 새 파일을 받지
  않는다 — `vibe-slice` 의 판 올림은 검사가 물지 않고 `CHECKLIST.md` 에서 사람이 본다. 강호쟁패의 첫 install 과 갱신은
  저자가 한다.
- **`audit-internal` 이 감사 대상의 조각을 늘 맞게 고르는지** — 브리핑 · 부른 말 · 마스터플랜의 `진행` 줄에서 읽는다.
- **ERP 사본이 원본보다 뒤인지** — 대장이 없어 아무도 찍지 않는다. 따라잡으려면 `--force` 로 다시 심는다.
- **ERP 의 `audit-internal` 사본** — PR C 의 뼈대는 원본에만 간다. 사본은 그 레포의 것이고(`INTENT.md` Not 4),
  따라잡는 것은 `sync-agents.sh` 와 대장의 일이다.
- **스킬이 스스로 뜨는 정확도** — 트리거 수트를 세우지 않는다. 단계 5 에서 저자가 부를 수 있는지만 본다.
- **같은 이름의 스킬이 레포나 계정에 따로 있을 때** — Claude Code 가 가른다.
- **두 플러그인을 다 깐 세션의 상시 합** — 예산은 플러그인마다 잰다(ADR 0013 의 8).
- **`audit-internal` 이 모든 꼴의 범위 문서를 찾는지** — 뼈대가 이름으로 드는 자리와, 저장소가 스스로 적은 목록(본문 첫
  문단 「그 목록을 … 먼저 읽고 따르세요」)뿐이다.
- **`sync-slice.sh` 의 대상이 git 레포인지 · 원격보다 뒤인지** — 있는 디렉터리면 심는다.

## ③ 받는 입력

**`sync-slice.sh`** — 닫힌 목록이다. 그 밖은 거절한다.

- 인자: 대상 경로 하나(있는 디렉터리)와 `--force`. 그 밖의 `-` 로 시작하는 인자 · 경로 둘 이상 · 경로 없음은 사용법을
  찍고 exit 2. 없는 디렉터리는 exit 1.
- 원본: 이 스크립트 옆 `../vibe-slice/skills/slice-docs/` 에서 HEAD 에 추적된 파일. 원본에 git 이 없거나 HEAD 를 못
  읽으면 멈춘다.
- 대상의 자리: `.claude` · `.claude/skills` · `.claude/skills/slice-docs` 셋만 본다. 대상의 그 밖 파일은 읽지 않는다.

**`verify-docs.py`** — 틀을 읽는 자리만 `vibe-slice/skills/slice-docs/templates/` 의 `intent.md` · `master-plan.md` ·
`requirements.md` · `design.md` 넷으로 바뀐다. 나머지는 조각 3 설계 ③ 그대로다.

**`verify-budget.py`** — `marketplace.json` 의 `plugins` 줄마다 `source` 폴더에서 `agents/audit-*.md` · `commands/*.md` ·
`skills/*/SKILL.md`. 틀 파일은 재지 않는다 — 스킬이 부를 때만 읽는다.

**`slice-docs` 스킬** — 부르는 세션의 요청. 받는 문서 종류는 넷(의도 · 마스터플랜 · 요구사항 · 설계)뿐이고, 그 밖(ADR ·
`CLAUDE.md` · README)은 이 스킬의 일이 아니라고 적는다.

- 마스터플랜(`docs/master-plan.md`)은 있으면 읽는다(조각의 순서 · 이름). **없으면 처음 쓰는 호출이다** — 의도와
  마스터플랜을 틀에서 시작한다. 의도를 이미 든 문서(`PRD.md` 등)가 있으면 `INTENT.md` 를 새로 쓰지 않고 마스터플랜
  「가리키는 문서」의 의도 줄이 그 문서를 가리킨다(절차 「의도 문서의 칸」).
- 요구사항 · 설계는 마스터플랜에 그 조각의 줄이 있어야 쓴다. 없으면 줄을 먼저 더하라고 한다.

**`audit-internal`** — 기준 문서의 이름: `CLAUDE.md` · 의도 문서 하나(「가리키는 문서」의 의도 줄 → 없으면 `INTENT.md` →
없으면 `PRD.md`) · `docs/master-plan.md` · `docs/slices/*/requirements.md` · `docs/slices/*/design.md` · `docs/adr/` · 스키마 문서. 그 밖의 문서는
저장소가 스스로 적은 목록이 있을 때만 읽는다. 감사 대상의 조각은 브리핑(`.claude/audit-brief.md`) · 부른 말 · 마스터플랜의
`진행` 줄에서 읽는다.

## ④ 결정

**정한 것** — ADR 0013.

- 1 틀이 가는 길은 두 경로 — 대화형은 플러그인, 클라우드 레인은 사본(저자)
- 2 절차 지도는 보내지 않고 가리킨다(저자)
- 3 새 플러그인 `vibe-slice`, 스킬 `slice-docs`(저자)
- 4 `audit-internal` 은 뼈대 문구와 판정 케이스 하나, 설명은 그대로(저자)
- 5 대장에 적지 않는다(저자)
- 6 틀의 원천은 스킬 폴더 하나 — `docs/templates/` 를 옮긴다(세션 제안)
- 7 사본은 새 스크립트 `sync-slice.sh` — `sync-agents.sh` 에 붙이지 않는다(세션 제안)
- 8 예산은 플러그인마다 같은 천장으로 잰다(세션 제안)

**열어 둔 것**

- 판정 케이스의 이름 · 픽스처 · 그레이더 — PR C 가 열기 전에 이 설계 끝에 날짜를 박은 항목으로 정한다.
- `audit-internal` 에서 압축할 자리 — PR C 가 열기 전에 같은 항목에서 정한다.

## ⑤ 검증 계획

명령은 PR 본문에 결과와 함께 적는다. 「어긋내 보기」는 기준 커밋이나 일부러 망가뜨린 작업트리에 같은 명령을 대어
떨어지는지 본 뒤 되돌린다.

**PR B**

- P1 — `python3 scripts/verify-manifest.py` 통과, 그리고 `test-verify-manifest.py` 가 베낀 트리에서 변조본을 하나씩 문다 —
  `vibe-audit` 줄을 뺀다 · `vibe-slice` 줄을 겹친다 · 줄 없는 플러그인 폴더를 둔다 · `vibe-slice` 설명 한 글자를 바꾼다.
  넷 다 떨어지고 정상 트리는 통과한다.
- P2 · T2 · K3 · C1 ~ C5 — `./scripts/gates.sh` 열넷 통과. `test-verify-docs.py` 의 T1 · T2 변조본이 새 자리의 틀을
  지우고 · 고친다. `test-sync-slice.py` 가 C1 ~ C5 를 임시 원본 · 대상으로 하나씩 문다 — 다시 심기 거절, `--force`,
  더러운 원본, 추적 안 된 파일, **무시된 파일**(`.git/info/exclude` 에 넣고 만든 것 — `status --porcelain` 이 못 본다),
  링크 · 파일로 선 자리(`--force` 로도), 끊긴 링크, `copies.json` 바이트 그대로.
- C2 · C3 · C4 어긋내 보기 — `sync-slice.sh` 의 그 검사 줄을 하나씩 지운 작업트리에서 `test-sync-slice.py` 가 떨어진다.
- K3 어긋내 보기 — `SKILL.md` 끝에 4,500 자를 붙이면 `verify-budget.py` 가 떨어진다.
- P3 — `git ls-files vibe-slice` 가 여섯 줄.
- T1 — `git diff -M --summary main...HEAD` 에 `docs/templates/` 넷의 `rename … (100%)` 가 있고, `test ! -e docs/templates`.
- K1 — `SKILL.md` 의 틀 경로가 다 `${CLAUDE_SKILL_DIR}/templates/` 로 시작하고, 그 꼴의 네 경로를 스킬 폴더로 풀면
  다 있는 파일이다(파이썬 몇 줄). 어긋내 보기: 경로 하나를 `templates/…` 나 `docs/templates/…` 로 바꾸면 그 대조가
  떨어진다. 부를 때 실제로 그 바이트를 읽는지는 단계 5 에서 본다.
- K2 — `SKILL.md` 에 절차 지도 URL 이 있다(grep). 어긋내 보기: 기준 커밋에는 `SKILL.md` 가 없다.
- X1 — `git diff --name-only main...HEAD` 와 기준 · 머리 각각의 `eval-key.py route --list` · `full --list` 의 교집합이 0.
  머리에서 CI eval 잡이 「같은 지문」으로 건너뛴다.

**PR C**

- A1 · A2 — 동작은 A5 의 두 덫이 문다. 문구는 뼈대 1 · 6 · 7 의 줄에 `INTENT.md` · `docs/master-plan.md` ·
  `docs/slices/` 가 있고, 6 · 7 이 「감사 대상
  변경이 속한 조각」으로 범위를 좁힌다(grep). 어긋내 보기: 기준
  커밋의 같은 줄에는 없다.
- A3 — `python3 scripts/verify-copy.py vibe-audit/agents` 통과, 그리고 기준과 머리의 `audit-internal.md` 프론트매터(첫
  `---` 부터 둘째 `---` 까지)가 바이트로 같다.
- A4 — `python3 scripts/verify-budget.py` 통과, 스냅숏의 `audit-internal` 호출 시 ≤ 11,000.
- A5 — 머리에서 CI route 잡 통과, 그리고 전수(`workflow_dispatch`)에서 새 케이스 통과. 그레이더는 진짜 부적합과 두 덫을
  따로 문다 — 덫 하나라도 부적합으로 낸 표본(`samples/fail*.md`, 덫마다 하나)을 그레이더가 떨어뜨린다
  (`verify-graders.py`).

- A6 — `git show main:vibe-audit/.claude-plugin/plugin.json` 과 머리의 `version` 을 견줘 머리가 높다.

**단계 5(배포)** — PR B 뒤: 저자가 강호쟁패에서 `claude plugin marketplace update pdw96-kit` →
`claude plugin install vibe-slice@pdw96-kit` 뒤 `/vibe-slice:slice-docs` 가 뜨고
부르면 틀의 내용(예: 설계 틀의 여섯 `##` 제목)을 그대로 읽는지,
ERP 에 `./scripts/sync-slice.sh <ERP>` 를 돌려 커밋한 뒤 클라우드 세션에서 `/slice-docs` 가 뜨는지 본다. PR C 뒤:
강호쟁패에서 `claude plugin marketplace update pdw96-kit` → `claude plugin update vibe-audit@pdw96-kit` → 리로드 뒤,
`audit-internal` 의 뼈대 6 이 「감사 대상 변경이 속한 조각」을 드는지(예: 감사자에게 뼈대 6 을 그대로 옮겨 보라고 한다) 본다.

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A 착공 | 요구사항 · 설계 · ADR 0013 · 마스터플랜 | 단계 0 · 1 · 2 |
| B 플러그인과 사본 길 | `vibe-slice` · 틀 옮기기 · `sync-slice.sh` 와 시험 · 검사 넷의 자리 · 살아 있는 문서 | 성공 기준 1 · 2 · 3 · 7 · 8 |
| C 감사자 | `audit-internal` 뼈대 · 압축 · `vibe-audit` 판 · 판정 케이스 · 수트 README · 기록 | 성공 기준 5 · 6 · 8 |

성공 기준 4 는 PR B · C 가 머지된 뒤 단계 5 에서 저자가 닫는다.
