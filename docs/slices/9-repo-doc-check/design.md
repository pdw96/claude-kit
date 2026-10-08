# 조각 9 설계 — 다른 레포의 문서 대조 검사

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`, 갈림길은 ADR 0018.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A | 「다른 레포의 문서 대조 검사」 상태 `진행` · 조각 폴더 · 목표 한 줄에 무는 자리와 원천(ADR 0018 의 1 · 2) |
| `docs/adr/0018-repo-doc-check.md` | A | 갈림길 아홉 |
| `vibe-slice/skills/slice-docs/scripts/verify-docs.py` | B | `scripts/verify-docs.py` 를 `git mv` 로 옮긴다. ② 의 A — 다른 레포 모드(`--repo <루트>`). W3 — 기본 루트를 부른 경로에서 잡는다. 원본 모드의 판정은 그대로 |
| `vibe-slice/skills/slice-docs/scripts/verify-slice-gate.py` | B | `scripts/verify-slice-gate.py` 를 `git mv` 로 옮긴다. 코드는 그대로 — 머리 주석의 자리 줄만 |
| `scripts/verify-docs.py` · `scripts/verify-slice-gate.py` | B | 위 둘을 가리키는 상대 심볼릭 링크(`../vibe-slice/skills/slice-docs/scripts/<이름>`) — W2 |
| `scripts/test-verify-docs.py` | B | 다른 레포 모드의 꼴 — ⑤. 그 꼴은 검사를 임시 스킬 폴더에 베껴 돈다(V2) |
| `scripts/bite-verify-docs.py` | B | 새 변조본 — 다른 레포 모드의 자리마다 검사를 망가뜨린 사본에 `test-verify-docs.py` 를 댄다(V1). 수트 지문 밖이다 |
| `scripts/gates.sh` | B | 한 줄 · 끝의 개수 「열일곱」 → 「열여덟」 |
| `scripts/test-sync-slice.py` | B | Y2 — 심은 두 검사를 대상 레포에서 돌린다 |
| `vibe-slice/.claude-plugin/plugin.json` | B · C | 판 `0.3.1`(B — 플러그인에 파일이 는다) · `0.4.0`(C — 스킬 문구) |
| `docs/architecture.md` | B | 부품 「조각 문서 스킬」에 검사 둘. 「문서」의 검사 자리. 「게이트가 무는가」 — `bite-verify-docs.py` |
| `docs/procedure.md` | B · C | B — 머리의 「이 저장소의 `gates.sh` 가 문다 … 다른 레포에서 키 없이 무는 것은 …」와 「이 모양을 무는 것」의 「다른 프로젝트 레포의 마스터플랜은 여기서 볼 수 없다」를 검사의 자리로. C — 「일곱 단계」 3 · 6 의 맡는 도구에 스킬이 부르는 검사. 빈자리 「설계 → 구현 관문」의 줄은 조각을 닫을 때 고친다 |
| `CHECKLIST.md` | B | 「플러그인의 파일을 고쳤다면」 — 검사 둘도 `vibe-slice` 의 파일이다 |
| `vibe-slice/skills/slice-docs/SKILL.md` | C | K1 |
| `vibe-slice/skills/slice-review/SKILL.md` | C | K2 |
| `vibe-audit/evals/budget.txt` | C | 스냅숏의 `[vibe-slice]` 절. 수트 지문 밖이다 |

**앵커볼트.** 건드리지 않는다 — 이름이 늘지 않고(검사 스크립트는 앵커볼트 이름이 아니다), 「…의 칸」 네 절과 그 표 서식(ADR 0010 의 8) ·
틀의 `##` 제목 · 대장 · 감사자 · `AGENTS.md` 는 그대로다. 다른 레포 모드는 틀의 `##` 제목을 읽는데, 그 제목은 claude-kit 에서
T2 가 「…의 칸」 표와 글자 그대로 같게 문다 — 원천은 여전히 그 표 하나다.

**원본에 레포별 분기를 두지 않는다**(`CLAUDE.md` 「금지」). 스킬은 어느 레포에서나 같은 명령(`--repo .`)을 부른다 — claude-kit 에서
불러도 틀이 표와 같으니 판정이 같다. `--repo` 는 원천을 고르는 인자이지 레포 이름을 가르지 않는다.

**시스템 구조.** 검사 둘의 실물이 「키 없는 게이트」에서 「조각 문서 스킬」 부품으로 옮겨 가고, 키 없는 게이트는 그것을 링크로
부른다. 흐름은 그대로다 — PR B 가 부품 표와 「문서」 · 「게이트가 무는가」를 고친다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 번호는 ⑤ 와 검사 · 시험의 출력이 같이 쓴다. 조각 3 설계 ② 의 O · T · I · M · S · F · R 과 조각 7 설계 ② 의
B · D · G · R 은 그대로다.

- **자리** — 실물은 한 벌
  - W1 두 검사의 실물은 `vibe-slice/skills/slice-docs/scripts/verify-docs.py` · `verify-slice-gate.py` 다 — 플러그인과 사본 길
    (`sync-slice.sh`)이 같은 파일을 싣는다.
  - W2 `scripts/verify-docs.py` · `scripts/verify-slice-gate.py` 는 W1 을 가리키는 상대 심볼릭 링크다. `gates.sh` · 자체 시험 ·
    `bite-slice-gate.py` · `eval.yml` 「게이트가 무는가」는 그 이름으로 그대로 부르고 읽는다 — `eval.yml` 을 고치지 않는다.
    「게이트가 무는가」의 변조 스무 자리는 W1 의 `verify-docs.py` 에 꼭 한 번씩 그대로 있다(그 단계가 `count != 1` 로 이미 문다).
  - W3 원본 모드의 기본 루트는 **부른 경로**의 두 단 위다 — 링크를 따라가지 않는다. `python3 scripts/verify-docs.py` 는 이
    저장소를 본다. 실물 경로로 인자 없이 부르면 루트가 스킬 폴더라 O3 으로 떨어진다(시끄러운 실패).
- **다른 레포 모드** (`verify-docs.py --repo <루트>`)
  - A1 원천은 검사 파일의 실제 자리(링크를 따라간)의 `../templates/` 틀 넷이다 — `intent.md` · `master-plan.md` · `requirements.md` ·
    `design.md` 가 차례로 「의도 문서의 칸」 · 「마스터플랜의 칸」 · 「요구사항 문서의 칸」 · 「설계 문서의 칸」의 필수 제목을
    든다. 필수 제목은 그 틀의 `##` 제목 전부이고 순서는 틀의 순서다(줄을 읽는 법은 조각 3 설계 ③ 그대로 — 틀 머리의 주석을 건너뛴다).
  - A2 틀 넷 가운데 하나라도 없거나 · 읽지 못하거나 · `##` 제목이 하나도 없으면 떨어진다 — 원천이 사라져 빈 채로 초록이 되지
    않게(O2 와 같은 까닭). 출력은 `[A2] <틀 경로>: …`.
  - A3 원천(O1 ~ O3 의 `docs/procedure.md` 확인)과 틀(T1 · T2)을 보지 않는다. 루트에 `docs/procedure.md` 가 있어도 읽지 않는다.
  - A4 그 밖은 원본 모드와 같은 규칙 · 같은 보장 번호 · 같은 출력이다 — I1 ~ I3 · M1 · M2 · S1 ~ S10 · F1 ~ F5 · R1 · R2. 다른 것은 A7 하나다.
    마스터플랜이 없으면 O3 「없다 — 마스터플랜이 없다」로 떨어진다 — 마스터플랜이 없는 레포(지금의 강호쟁패 · ERP)에서 지나가지 않는다.
  - A5 모드는 인자로만 고른다. `--repo` 가 없으면 원본 모드이고 조각 3 설계 ② 그대로다. 루트의 파일(지도 · `vibe-slice/`)이
    있고 없음으로 고르지 않는다 — 지도를 지운 원본이 O3 대신 다른 레포 모드로 넘어가 지나가지 않게(ADR 0018 의 5).
  - A6 통과 줄이 모드와 원천을 찍는다 — `PASS 문서의 모양(다른 레포 — 원천 <틀 폴더>) — 의도 · 마스터플랜 · 조각 나눔 · 조각 폴더`.
  - A7 **첫 조각 전의 `docs/slices/`.** 「가리키는 문서」의 경로 토막이 글자 그대로 `docs/slices/` 이고 루트에 그 폴더가 없을 때, 조각
    나눔에 `진행` · `닫힘` 줄이 하나도 없으면 M2 로 떨어지지 않는다. 그런 줄이 하나라도 있으면 원본 모드와 같다(M2 · S8). 틀의
    「가리키는 문서」가 `docs/slices/` 를 박아 두는데, 첫 조각을 꺼내기 전에는 그 폴더가 없고 빈 폴더는 git 에 커밋되지 않는다 —
    마스터플랜만 세우는 첫 PR 이 늘 떨어진다(#39 Codex 1회차, ADR 0018 의 9). 원본 모드에는 없다 — claude-kit 은 조각 폴더가 있다.
- **순서** (`verify-slice-gate.py`)
  - Q1 코드는 그대로다. 다른 레포의 작업트리에서 인자 없이 부르면 그 레포(작업 디렉터리의 `git rev-parse --show-toplevel`)의
    `origin/main` · `main` 을 기준으로 조각 7 설계 ② 의 B · D · G · R 대로 판정한다. 기준에 마스터플랜이 없으면 「보지 않는다」로
    지나간다(B4) — 마스터플랜을 세우는 첫 PR 이다.
- **사본 길** (`sync-slice.sh`)
  - Y1 `sync-slice.sh` 가 `.claude/skills/slice-docs/scripts/` 에 두 검사를 바이트 그대로 심는다 — 두 검사에는 claude-kit 링크가
    없어 L1 이 바꾸지 않고 L2 를 지난다. 스크립트는 그대로다 — 스킬 폴더의 파일을 다 심는 C1 의 결과다.
  - Y2 심은 `verify-docs.py --repo` 가 틀로 세운 대상에서 통과하고 한 자리를 망가뜨리면 떨어진다. 심은 `verify-slice-gate.py` 가
    착공 + 구현을 한 diff 로 둔 대상에서 G1 로 떨어진다 — `test-sync-slice.py` 가 본다. 조각 5 · 6 · 8 의 C1 ~ C5 · P1 · L1 ~ L3 ·
    H1 ~ H3 은 그대로다.
- **변조본**
  - V1 `bite-verify-docs.py` 는 W1 의 `verify-docs.py` 를 ⑤ 의 여섯 자리마다 한 군데씩 망가뜨린 사본을 임시 폴더에 쓰고, 사본마다
    `test-verify-docs.py` 를 돌려 떨어지는지 본다. 하나라도 지나가면 떨어지고, 망가뜨릴 자리가 검사에 꼭 한 번 있지 않으면 떨어진다.
    `gates.sh` 가 부른다 — 수트 지문 밖이다(ADR 0018 의 6).
  - V2 `test-verify-docs.py` 의 다른 레포 모드 꼴은 받은 검사(인자로 받은 사본도)를 임시 스킬 폴더 `<임시>/slice-docs/scripts/` 에
    베끼고 `<임시>/slice-docs/templates/` 에 원본 틀 넷을 둔 뒤 돈다. `eval.yml` 이 넘긴 망가뜨린 사본(`$cc/d.py`)도 틀을 찾으므로,
    다른 레포 모드 꼴이 틀을 못 찾아 엉뚱한 까닭으로 떨어지지 않는다 — 「게이트가 무는가」 스무 자리의 판정이 무르지 않는다.
- **스킬** (`vibe-slice` — 다른 레포에 닿는 쪽)
  - K1 `slice-docs` — 착공 PR · 닫는 PR 을 내기 전에 레포 맨 위에서 `python3 "${CLAUDE_SKILL_DIR}/scripts/verify-docs.py" --repo .` 와
    `python3 "${CLAUDE_SKILL_DIR}/scripts/verify-slice-gate.py"` 를 돌려 둘 다 0 을 본다. 1 이면 찍힌 줄을 고치고 다시 돌린다.
    `python3` 가 없거나 3.9 보다 낮으면 그렇다고 말하고, 검사를 지났다고 하지 않는다.
  - K2 `slice-review` 「1. 기준」 — 구현 PR 이면 착공 머지를 `python3 "${CLAUDE_SKILL_DIR}/../slice-docs/scripts/verify-slice-gate.py"
    --base <기본 가지> --head <PR 머리>` 로 보고, 그에 더해 그 조각이 기본 가지의 마스터플랜에서 `진행` 이고 설계가 있는지를 본다 —
    스크립트는 어느 조각인지 가리지 않는다(ADR 0018 의 8). G2 · B2 이거나 그 조각이 그렇지 않으면 가르지 않고 그렇다고 말한다 —
    착공이 머지되지 않았거나 기준을 읽지 못했다.
  - K3 `vibe-slice/.claude-plugin/plugin.json` 의 판이 기준 커밋보다 높고(PR B · C 각각), `claude plugin validate ./vibe-slice` ·
    `verify-manifest.py` 가 통과한다.
  - K4 `verify-budget.py` — `slice-review` · `slice-docs` 호출 시 ≤ 4,500, `vibe-slice` 상시 합계 ≤ 5,600. 천장 상수는 그대로이고,
    스냅숏이 같은 PR 에 있다.
- **비용**
  - X1 PR B · C 가 바꾼 파일 가운데 수트 지문(`eval-key.py route --list` · `full --list`, 기준과 머리 둘 다)에 드는 것이 0 이다.

**보장하지 않는 것(알려진 한계)**

- **세션이 검사를 돌리는지** — 다른 레포에서 검사는 스킬이 부를 때만 돈다. 세션이 K1 · K2 를 건너뛰어도 막는 것이 없고, 머지를
  막지도 않는다(하지 않을 일 1 · ADR 0018 의 1). 판정 자체는 결정론이다 — 문구가 든 것은 「언제 부르나」뿐이다.
- **다른 레포의 기본 가지가 `main` 이 아닌 꼴** — `verify-slice-gate.py` 의 로컬 기준은 `origin/main` · `main` 이라 B2 로 떨어진다
  (시끄러운 실패). 강호쟁패 · ERP 는 둘 다 `main` 이다(2026-10-08). K2 는 기본 가지를 인자로 준다.
- **`python3` 가 없거나 낮은 레포** — 검사가 돌지 않는다. K1 은 그렇다고 말하게만 한다.
- **원천이 그 레포에 깔린 판의 틀이라는 것** — 다른 레포 모드는 그 세션이 쓰는 플러그인 판 · 사본의 틀을 원천으로 읽는다. 판이 오르며
  「…의 칸」이 바뀌면, 옛 판으로 쓴 `진행` 조각 문서가 새 판의 검사에서 떨어질 수 있다(닫힌 조각은 F5 만 본다 — ADR 0010 의 6).
  그 레포가 사본의 틀을 손으로 고치면 그 틀이 원천이다.
- **다른 레포의 `docs/procedure.md`** — 다른 레포 모드는 읽지 않는다(A3).
- **Windows 에서 claude-kit 을 클론할 때의 링크** — `core.symlinks` 가 꺼져 있으면 `scripts/` 의 두 이름이 경로 글자만 든 파일이
  되어 `gates.sh` 가 떨어진다(시끄러운 실패). 다른 레포에는 링크가 가지 않는다 — 플러그인 · 사본은 W1 의 실물을 싣는다.
- **조각 3 설계 ② · 조각 7 설계 ② 가 보장하지 않는 것** — 그대로 이 조각에도 걸린다(칸의 내용 · 어느 조각의 구현인지 · ⑥ 밖의 것 …).
- **아직 겪지 않은 가설적 경계 사례** — 예: 한 레포에 플러그인과 사본이 둘 다 있어 판이 다른 틀 두 벌이 뜨는 꼴, 레포 맨 위가 아닌
  자리에서 부른 꼴, 플러그인 캐시가 파일을 바꿔 쓰는 꼴. 겪으면 그 PR 에서 정해 날짜 항목으로 적는다. 리뷰가 이것을 짚으면 범위 밖이다
  (조각 6 「닫으며」).

## ③ 받는 입력

닫힌 목록이다. 2026-10-08 의 `main`(7100d5f)과 강호쟁패(792a5d3) · ERP(3e40b5b)의 기본 가지에서 뽑았다. 이 밖은 떨어뜨린다.

**인자 — `verify-docs.py`** — 없음, `<루트>` 하나, 또는 `--repo <루트>`(그 순서, 두 토막). 그 밖(토막 셋 이상 · 모르는 `-` 옵션 ·
`--repo` 뒤에 루트가 없음)은 사용법을 찍고 exit 2. `verify-slice-gate.py` 의 인자는 조각 7 설계 ③ 그대로다.

**검사 파일의 자리** — 셋이다. 셋 다 실제 자리의 `../templates/` 가 틀이다.

| 길 | 검사의 실제 자리 |
|---|---|
| claude-kit | `vibe-slice/skills/slice-docs/scripts/` — `scripts/` 의 링크로 부른다 |
| 플러그인(강호쟁패) | 플러그인 캐시의 `…/vibe-slice/<판>/skills/slice-docs/scripts/` — `${CLAUDE_SKILL_DIR}/scripts/` 로 부른다 |
| 사본(ERP) | `<레포>/.claude/skills/slice-docs/scripts/` — 같은 치환 |

**틀(다른 레포 모드의 원천)** — `vibe-slice/skills/slice-docs/templates/` 넷. 지금의 `##` 제목은 3 · 3 · 5 · 6 줄이고 「…의 칸」
표와 같다 — `intent.md`(Why · What · Not) · `master-plan.md`(가리키는 문서 · 조각 나눔 · 범위 변경) · `requirements.md`(문제 · 핵심
사용자와 시나리오 · 성공 기준 · 하지 않을 일 · 제약) · `design.md`(① ~ ⑥). 넷 다 머리에 `<!--` 로 여는 주석이 있다.

**다른 레포의 문서** — 조각 3 설계 ③ 의 자리 그대로다(`docs/master-plan.md` · 의도 줄이 가리키는 파일 · `docs/slices/`). 지금의 실물은
둘 다 마스터플랜이 없어 O3 이다.

| 레포 | 마스터플랜 | 의도 후보 | 「가리키는 문서」에 들 경로 | `docs/slices/` |
|---|---|---|---|---|
| 강호쟁패 | 없다 — 단계 5 에서 선다. 첫 마스터플랜은 조각 폴더가 없어 A7 로 받는다 | `PRD.md`(`##` 일곱 — I3 은 `INTENT.md` 일 때만이라 보지 않는다) | `docs/architecture.md` · `docs/schema.md` · `CLAUDE.md` · `docs/adr/` · `CHECKLIST.md` | 없다 |
| ERP | 없다 | `PRD.md` · `docs/PRD-<N>단계.md` | — | 없다 |

**git — `verify-slice-gate.py`** — 조각 7 설계 ③ 그대로. 다른 레포의 가지는 `origin/main` 과 로컬 `main` 이다 — 강호쟁패 · ERP 둘 다
기본 가지가 `main` 이다.

**사본 길** — `sync-slice.sh` 가 심는 스킬 폴더의 파일이 둘 는다(`slice-docs/scripts/` 의 두 검사). 둘 다 `github(usercontent)?.com/pdw96/claude-kit`
가 나오지 않는다.

## ④ 결정

**정한 것** — ADR 0018.

- 1 다른 레포에서 검사는 스킬 폴더에 싣고 스킬이 부른다(저자)
- 2 다른 레포 모드의 원천은 스킬 폴더의 틀 넷(저자)
- 3 실물은 `vibe-slice` 로 옮기고 `scripts/` 에 링크를 남긴다 — `eval.yml` 을 고치지 않는다(저자)
- 4 단계 5 의 실물은 강호쟁패에 저자가 세우는 마스터플랜(저자)
- 5 모드는 인자 `--repo` 로만 고른다(세션 제안 · 저자)
- 6 다른 레포 모드의 변조본은 `gates.sh` 가 부르는 `bite-verify-docs.py`(세션 제안 · 저자)
- 7 검사 둘은 `slice-docs` 폴더에 — `slice-review` 는 `../slice-docs/scripts/` 로 부른다(세션 제안 · 저자)
- 8 K2 는 스크립트의 판정에 더해 「그 조각」이 `진행` 이고 설계가 있는지를 본다(저자)
- 9 첫 조각 전의 `docs/slices/` 는 다른 레포 모드의 검사가 받는다 — A7(세션 제안 · #39 Codex 1회차 · 저자)

**열어 둔 것**

- K1 · K2 의 문구가 예산에 드는지 — `slice-review` 호출 시 여유는 252 자다. PR C 가 열기 전에 이 설계 끝에 날짜를
  박은 항목으로 정한다. 넘으면 압축이 먼저다(ADR 0004). 천장은 올리지 않는다.

## ⑤ 검증 계획

명령은 PR 본문에 결과와 함께 적는다. 「어긋내 보기」는 일부러 망가뜨린 작업트리에 같은 명령을 대어 떨어지는지 본 뒤 되돌린다.

**PR B**

- `./scripts/gates.sh` 열여덟 통과.
- W1 · W2 — `git ls-files -s scripts/verify-docs.py scripts/verify-slice-gate.py` 가 `120000`(링크)이고 `readlink` 가 W1 을 가리킨다.
  `git log --follow` 가 옮긴 실물의 역사를 잇는다.
- W2 — CI 「게이트가 무는가」가 고치지 않은 `eval.yml` 로 지나간다(스무 자리가 다 한 번씩 있고 다 떨어진다).
- W3 — `python3 scripts/verify-docs.py` 가 이 저장소에서 원본 모드로 통과한다. 실물 경로로 인자 없이 부르면 O3.
- `test-verify-docs.py` — 원본 모드의 꼴(조각 3 설계 ⑤)은 그대로다. 다른 레포 모드의 꼴을 더한다 — 틀로 세운 임시 레포(`docs/procedure.md` ·
  `vibe-slice/` 없음, 검사는 V2 의 임시 스킬 폴더)에서 본다.

  | 꼴 | 기대 |
  |---|---|
  | 의도 줄 `PRD.md`(세 제목 없음) · 진행 조각 하나 · 닫힌 조각 하나 | 통과(A4 · A6) |
  | 진행 조각 설계 끝에 날짜 항목 · 루트에 엉뚱한 `docs/procedure.md` | 통과(A3) |
  | 마스터플랜이 없다 | O3 |
  | 첫 마스터플랜 — 조각 나눔이 다 `예정` · `docs/slices/` 없음 | 통과(A7) |
  | 같은데 `진행` 줄 하나(폴더 칸 `docs/slices/1-x/` · 폴더 없음) | M2 · S8 — A7 은 `진행` · `닫힘` 줄이 있으면 받지 않는다 |
  | 조각 나눔이 다 `예정` · 「가리키는 문서」가 없는 폴더 `docs/plans/` 를 가리킨다 | M2 — A7 은 `docs/slices/` 글자 하나만 받는다 |
  | 진행 조각 설계에서 `## ③ 받는 입력` 을 지운다 | F3 |
  | 진행 조각의 의존이 `예정` 조각 | S6 |
  | 닫힌 조각의 「닫으며」를 지운다 | F5 |
  | `docs/slices/9-x/` 고아 폴더 | F1 |
  | `INTENT.md` 의 `## Not` → `## Non`(의도 줄이 `INTENT.md` 일 때) | I3 |
  | 검사 옆 `templates/design.md` 에 `##` 제목 한 줄을 더한다 | 진행 조각 `design.md` 가 F3 — 원천이 틀이다(A1) |
  | 검사 옆 `templates/requirements.md` 를 지운다 · `##` 제목을 다 지운다 | A2 |
  | `--repo` 뒤 루트 없음 · `--repo` 와 다른 옵션 | exit 2 |

- V1 변조본의 여섯 자리 — `bite-verify-docs.py` 가 다 자체 시험에서 떨어지는 것을 본다: `--repo` 를 무시해 원본 모드로 간다, 틀의 원천을
  빈 목록으로 읽는다, A2 의 빈 원천 거절을 지운다, 다른 레포 모드에서도 T1 · T2 를 본다, 다른 레포 모드의 원천을 검사 옆이 아니라 루트의
  `vibe-slice/…/templates/` 에서 찾는다, A7 의 `진행` · `닫힘` 줄 조건을 지운다(늘 받는다). 어긋내 보기 둘 — 자체 시험의 다른 레포 모드 꼴을 다 지운 작업트리, 검사에서 변조할 자리의
  글자를 하나 바꾼 작업트리에서 `bite-verify-docs.py` 가 떨어진다.
- Y1 · Y2 — `test-sync-slice.py` 가 심은 사본의 `scripts/` 두 파일이 원본과 바이트 그대로인지(C1 의 꼴에 듦), 틀로 세운 대상에서 심은
  `verify-docs.py --repo` 가 통과하고 한 자리를 망가뜨리면 떨어지는지, 착공 + 구현을 한 diff 로 둔 대상(원격 `origin` · `main` 을
  갖춘)에서 심은 `verify-slice-gate.py` 가 G1 인지 본다. 어긋내 보기 — `sync-slice.sh` 가 `scripts/` 를 건너뛰게 고친 작업트리에서 떨어진다.
- 실물 — PR B 머리에서 빈 임시 git 레포에 `sync-slice.sh` 로 심고 `diff -r` 를 원본 스킬 폴더와 견준 출력. 강호쟁패 · ERP 의 기본 가지
  클론에서 `verify-docs.py --repo` 가 O3 로 떨어지고 `verify-slice-gate.py` 가 「기준에 마스터플랜이 없다 — 보지 않는다」인 출력.
- X1 — `git diff --name-only main...HEAD` 와 기준 · 머리 각각의 `eval-key.py route --list` · `full --list` 의 교집합이 0.

**PR C**

- K1 · K2 — 두 `SKILL.md` 에 그 명령이 있고, `slice-review` 에 「그 조각」 확인이 남아 있다(grep). 어긋내 보기: 기준 커밋에는 명령이 없다.
- K3 — `git show main:vibe-slice/.claude-plugin/plugin.json` 과 머리의 `version` 을 견줘 머리가 높다. `gates.sh` 의 `validate` ·
  `verify-manifest.py` 통과.
- K4 — `verify-budget.py` 통과와 스냅숏의 값.
- X1 — PR B 와 같다.

**스스로 쓰기** — PR A ~ C 의 리뷰를 `slice-review` 로 가른다. PR 본문의 `## 리뷰 회차` 와 답글. PR B · C 는 `verify-slice-gate.py`
를 CI 에서 지나간다(이 착공이 머지된 뒤).

**단계 5(배포)** — PR C 뒤: 저자가 강호쟁패에서 `claude plugin marketplace update pdw96-kit` → `claude plugin update vibe-slice@pdw96-kit` →
리로드 뒤 `/vibe-slice:slice-docs` 로 마스터플랜(의도 줄 `PRD.md`)을 세우고, 스킬이 부른 두 검사의 출력이 통과인지, `## 범위 변경` 을 지운
작업트리에서 `verify-docs.py` 가 M1 로 떨어지는지 본다(성공 기준 5). 그 마스터플랜을 강호쟁패에 커밋하는 것은 그 레포의 일이다. ERP 는 다시
심지 않는다(하지 않을 일 6).

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A 착공 | 요구사항 · 설계 · ADR 0018 · 마스터플랜 | 단계 0 · 1 · 2 |
| B 검사 | 두 검사를 `vibe-slice` 로 옮김 · `scripts/` 의 링크 · 다른 레포 모드 · `test-verify-docs.py` · `bite-verify-docs.py` · `gates.sh` · `test-sync-slice.py` · `plugin.json` 0.3.1 · `docs/architecture.md` · `docs/procedure.md` 의 검사 줄 · `CHECKLIST.md` | ② 의 W · A · Q · Y · V · X1, 성공 기준 1 · 2 · 3 · 6 |
| C 스킬 | `slice-docs` · `slice-review` · `plugin.json` 0.4.0 · 스냅숏 · `docs/procedure.md` 의 스킬 줄 | ② 의 K · X1, 성공 기준 4 · 6 |

성공 기준 5 는 PR C 가 머지된 뒤 단계 5 에서 저자가 본다. B 가 C 보다 먼저다 — C 의 스킬이 B 가 옮긴 검사를 부른다. 조각을 닫는 기록은 그
뒤 따로 낸다(단계 6).
