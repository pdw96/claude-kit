# 조각 10 설계 — 플러그인의 절차 지도 판

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`, 갈림길은 ADR 0019.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A | 「플러그인의 절차 지도 판」 상태 `진행` · 조각 폴더 · 목표 한 줄에 박는 길과 견주는 지도(ADR 0019 의 1 · 2) |
| `docs/adr/0019-plugin-map-pin.md` | A | 갈림길 여덟 |
| `scripts/sync-slice.sh` | B | ② 의 L1 · L2 를 넓힌다 — 받고 바꾸는 꼴에 `blob/<전체 sha>/`. 그 밖은 그대로 |
| `scripts/test-sync-slice.py` | B | ⑤ 의 꼴 — 원본이 `blob/<전체 sha>/` 를 박은 꼴, 섞인 꼴, 짧은 sha 는 그대로 멈춤 |
| `docs/architecture.md` | B · C | B — 「흐름」의 「스킬 심기」에 박은 링크도 출처로. C — 「대화형 세션은 … 그 링크는 `blob/main/` 그대로다」를 박은 커밋으로, 부품 「키 없는 게이트」에 새 검사 · 「게이트가 무는가」에 `bite-map-pin.py` |
| `scripts/verify-map-pin.py` | C | 새 검사 — ② 의 R · M · O |
| `scripts/test-verify-map-pin.py` | C | 자체 시험 — 임시 git 레포에 ⑤ 의 꼴을 만들어 검사를 돌린다 |
| `scripts/bite-map-pin.py` | C | 변조본 — 검사를 자리마다 망가뜨린 사본에 자체 시험을 댄다(V1). 수트 지문 밖이다 |
| `scripts/gates.sh` | C | 세 줄 · 끝의 개수 「열여덟」 → 「스물하나」 |
| `vibe-slice/skills/slice-docs/SKILL.md` · `vibe-slice/skills/slice-review/SKILL.md` | C | 지도 링크 한 줄씩 — `blob/main/` → `blob/<전체 sha>/`. 박는 커밋은 C 를 열 때의 `main` 머리(그 지도가 C 의 지도와 같다). 그 밖의 글자는 그대로 |
| `vibe-slice/.claude-plugin/plugin.json` | C | 판 `0.4.1` → `0.4.2` — 링크 두 줄만 바뀐다 |
| `vibe-audit/evals/budget.txt` | C | 스냅숏의 `[vibe-slice]` 절. 수트 지문 밖이다 |

`docs/procedure.md` 는 이 조각의 구현 PR 에서 고치지 않는다 — 고치면 C 의 지도와 박는 커밋의 지도가 갈려 C 안에서 커밋이 둘 든다(ADR 0019
결과 2). 빈자리 표에 고칠 줄이 생기면 조각을 닫을 때 고친다 — 지도만 고친 PR 은 링크를 건드리지 않는다.

**앵커볼트.** 건드리지 않는다 — 이름이 늘지 않고(검사 스크립트는 앵커볼트 이름이 아니다), 감사자 · 공통 절 · 대장 · 「…의 칸」 · 틀의
`##` 제목 · `AGENTS.md` 는 그대로다. 스킬 문구는 링크의 커밋 글자만 바뀐다.

**원본에 레포별 분기를 두지 않는다**(`CLAUDE.md` 「금지」). 새 검사는 `scripts/` 에만 있고 플러그인에 실리지 않는다 — claude-kit 의
역사를 읽는 판정이다.

**시스템 구조.** 부품 「키 없는 게이트」에 검사 하나가 는다. 「스킬 심기」 흐름의 한 문장과 대화형 세션의 링크 한 문장이 바뀐다 — B · C.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 번호는 ⑤ 와 검사 · 시험의 출력이 같이 쓴다. 조각 5 · 6 · 8 · 9 의 C1 ~ C5 · P1 · L3 · H1 ~ H4 · Y 는 그대로이고, 조각 8 의
L1 · L2 를 아래로 넓힌다.

- **사본 길** (`sync-slice.sh`)
  - L1 심는 파일마다 `github.com/pdw96/claude-kit/blob/main/` 과 `github.com/pdw96/claude-kit/blob/<40 자 소문자 16진>/` 을 다
    `github.com/pdw96/claude-kit/blob/<출처 전체 sha>/` 로 바꾼다. 한 파일 · 한 줄에 두 꼴이 섞여도 다 바꾼다. 그 밖의 바이트는 그대로다.
  - L2 원본 HEAD 의 심을 파일에 위 두 꼴 밖의 claude-kit 링크 꼴(`tree/` · 가지 · 짧은 sha · 대문자 sha · `raw`)이 있으면 아무것도
    쓰지 않고 멈추며 파일과 줄을 찍는다.
- **검사** (`verify-map-pin.py` — 인자 없음, 부른 자리의 git 맨 위를 본다)
  - R1 git 레포가 아니거나 HEAD 가 없으면 떨어진다.
  - R2 얕은 클론(`git rev-parse --is-shallow-repository` 가 `true`)이면 떨어진다 — 역사가 없으면 조상을 가리지 못한다.
  - R3 맨 위에 `vibe-slice/` 가 없으면 떨어진다.
  - M1 `vibe-slice/` 아래 파일(③)에서 `github.com/pdw96/claude-kit` 나 `githubusercontent.com/pdw96/claude-kit` 가 나오는 자리마다,
    `github.com/pdw96/claude-kit/blob/<40 자 소문자 16진>/<경로>` 꼴이 아니면 떨어진다 — `blob/main/` · 짧은 sha · 가지 · `tree/` · `raw`.
  - M2 박은 커밋이 레포에 없으면 떨어진다.
  - M3 박은 커밋이 HEAD 이거나 그 조상이 아니면 떨어진다(`git merge-base --is-ancestor`).
  - M4 박은 커밋에 그 경로가 파일로 없으면 떨어진다.
  - M5 박은 커밋의 그 경로 파일이 **기준**과 바이트로 다르면 떨어진다. 기준은 — `vibe-slice/` 가 작업트리에서 HEAD 와 다르면(추적 파일의
    변경 · 무시되지 않은 새 파일) 작업트리의 그 경로 파일, 아니면 HEAD 에서 `vibe-slice/` 를 마지막으로 고친 커밋
    (`git log -1 --format=%H HEAD -- vibe-slice/`)의 그 경로 파일. 메시지는 기준과 같은 내용을 가진 가장 가까운 조상 커밋을 박으라고 찍고,
    기준이 작업트리에만 있으면 「그 파일을 먼저 커밋하고 그 커밋을 박아라」를 찍는다.
  - M6 `vibe-slice/skills/` 아래 스킬 폴더마다 그 `SKILL.md` 에 M1 의 꼴로 `docs/procedure.md` 를 박은 링크가 하나 이상 없으면, 그 스킬마다
    떨어진다 — 스킬은 절차를 지도에서 읽게 한다. 한 스킬의 링크가 빠지거나 다른 경로를 박아도 다른 스킬의 링크로 지나가지 않고, 링크가 틀에만
    있어도 지나가지 않으며, 꼴을 못 읽어 아무것도 보지 않고 지나가는 일도 막는다. 지도 밖의 경로를 박은 링크는 그 밖에 더 있어도 되고 M2 ~ M5 가
    본다(PR #44 Codex 1회차).
  - O1 다 지나면 `PASS 절차 지도 판` 한 줄과 링크 수 · 박은 커밋(짧은 sha) · 기준(커밋의 짧은 sha 또는 `작업트리`)을 찍고 0. 떨어지면
    `FAIL [<번호>] <파일>:<줄> — <까닭>` 을 자리마다 찍고 1. 인자를 주면 사용법을 찍고 2.
  - O2 출력과 git 읽기는 UTF-8 이다 — 로케일이 `C` 거나 `PYTHONIOENCODING` 이 다른 인코딩이어도 예외로 끝나지 않는다(조각 9 E1 · E2 와 같은 길).
- **원본**
  - S1 두 `SKILL.md` 의 지도 링크가 `blob/<전체 sha>/docs/procedure.md` 이고, PR C 의 머리에서 `verify-map-pin.py` 가 통과한다.
- **변조본**
  - V1 `bite-map-pin.py` 가 검사의 자리마다(M1 의 꼴 · M2 · M3 · M4 · M5 의 비교 · M5 의 작업트리 기준 · M6 의 스킬마다 · M6 의 경로 · R2) 한 자리씩 망가뜨린 사본에
    `test-verify-map-pin.py` 를 대어 다 떨어지는지 보고, 하나라도 지나가면 1 이다.
- **비용**
  - X1 PR B · C 가 바꾼 파일 가운데 수트 지문(`eval-key.py route --list` · `full --list`, 기준과 머리 둘 다)에 드는 것이 0 이다.

**보장하지 않는 것(알려진 한계)**

- **판이 올랐는지** — 검사는 `plugin.json` 의 판을 보지 않는다. 판 없이 플러그인을 고치면 검사가 지나가도 설치한 판과 지도가 갈린다 —
  `CHECKLIST.md` 「플러그인의 파일을 고쳤다면」(하지 않을 일 4).
- **링크가 열리는지 · 박은 커밋이 원격에 있는지** — 네트워크를 쓰지 않는다. PR 가지의 커밋은 머지 커밋으로 `main` 에 든다(하지 않을 일 5).
- **스쿼시 · 리베이스 머지** — 박은 커밋이 `main` 의 역사에서 사라지면 다음 `gates.sh` 가 M3 로 떨어진다(시끄러운 실패). 이 저장소의
  PR 머지는 다 머지 커밋이다.
- **이미 설치한 판 · 이미 심긴 사본** — 0.4.1 이하는 `blob/main/` 이다. ERP 의 사본은 다시 심을 때까지 그때의 출처다(하지 않을 일 6).
- **`vibe-slice/` 밖의 claude-kit 링크** — README · 문서의 링크는 보지 않는다. 플러그인으로 가는 것은 `vibe-slice/` 뿐이다.
- **URL 이 아닌 글자** — 「claude-kit `docs/procedure.md`」 같은 글자는 보지 않는다(하지 않을 일 8).
- **박은 지도의 뜻** — 같은 바이트인지만 본다. 지도가 스킬 문구와 맞는지는 사람이 본다.
- **아직 겪지 않은 가설적 경계 사례** — 예: 링크를 코드 블록 · 각주 · 줄바꿈으로 나눠 적는 꼴, `vibe-slice/` 를 고친 커밋이 머지 커밋뿐인
  꼴(충돌 해소). 겪으면 그 PR 에서 정해 날짜 항목으로 적는다. 리뷰가 이것을 짚으면 범위 밖이다(조각 6 「닫으며」).

## ③ 받는 입력

닫힌 목록이다. 2026-10-10 의 `main`(2e25c48)에서 뽑았다.

**원본의 claude-kit 링크** — `vibe-slice/` 아래 추적된 파일에서 `pdw96/claude-kit` 가 나오는 자리는 둘이고, 둘 다 같은 꼴이다. 「claude-kit」
글자만 있는 자리(`plugin.json` 설명 · 틀 머리의 주석 · 본문의 「claude-kit 의 절차 지도」)는 링크가 아니다.

| 파일 | 줄 | 링크 |
|---|---|---|
| `vibe-slice/skills/slice-docs/SKILL.md` | 8 | `https://github.com/pdw96/claude-kit/blob/main/docs/procedure.md` |
| `vibe-slice/skills/slice-review/SKILL.md` | 9 | `https://github.com/pdw96/claude-kit/blob/main/docs/procedure.md` |

검사가 받는 꼴은 `github.com/pdw96/claude-kit/blob/<40 자 소문자 16진>/<경로>` 하나다. 경로는 `/` 뒤로 공백 · `)` · `` ` `` · `>` · `"` ·
`'` 가 나오기 전까지다 — 위 두 줄은 경로 뒤가 공백(` .`)과 `)` 다. `sync-slice.sh` 는 그 꼴과 `blob/main/` 둘을 받는다(L1 · L2).

**검사가 읽는 파일** — 작업트리의 `vibe-slice/` 아래 가운데 git 이 추적하거나 무시하지 않는 것(`git ls-files -co --exclude-standard -- vibe-slice/`).
UTF-8 로 읽는다. 링크는 `vibe-slice/skills/slice-docs/scripts/` 의 두 검사 안에는 없다(2026-10-10 grep).

**스킬 폴더** — `vibe-slice/skills/` 바로 아래 폴더 둘(`slice-docs` · `slice-review`)이고, 둘 다 `SKILL.md` 에 지도 링크가 하나씩 있다(위 표).
M6 은 폴더를 이름으로 적지 않고 그 아래 폴더마다 본다 — 스킬이 늘면 그 `SKILL.md` 도 지도를 박아야 지나간다.

**git** — 검사가 부르는 것은 `rev-parse --show-toplevel` · `rev-parse --verify HEAD` · `rev-parse --is-shallow-repository` · `ls-files` ·
`status --porcelain -- vibe-slice/` · `cat-file -e <커밋>^{commit}` · `merge-base --is-ancestor` · `log -1 --format=%H HEAD -- vibe-slice/` ·
`log --format=%H HEAD -- <경로>` · `show <커밋>:<경로>` 이다. 역사는 이 저장소의 꼴 — 머지된 PR 은 다 머지 커밋으로 `main` 에 든다(2026-10-10, `git log --merges` 의 「Merge pull request」 42).

**작업트리** — 세 꼴. `vibe-slice/` 도 지도도 깨끗하다(CI) · `vibe-slice/` 만 고쳤다 · 둘 다 고쳤다. 지도만 고친 작업트리는 기준이 커밋이라
첫 꼴과 같다.

## ④ 결정

**정한 것** — ADR 0019.

- 1 원본 스킬의 링크를 커밋으로 박고 키 없는 검사가 문다(저자)
- 2 박은 지도를 `vibe-slice/` 를 마지막으로 고친 커밋의 지도에 견준다(저자)
- 3 사본의 링크는 원본이 박은 것도 출처 커밋으로 다시 박는다(저자)
- 4 단계 5 의 실물은 강호쟁패에서 저자가(저자)
- 5 검사 · 자체 시험 · 변조본을 `gates.sh` 가 부른다(세션 제안 · 저자)
- 6 박는 꼴은 전체 sha 하나(세션 제안 · 저자)
- 7 다시 박는 일은 검사의 메시지만 돕는다 — `--fix` 를 두지 않는다(저자)
- 8 단계 5 에서 ERP 사본을 다시 심지 않는다(저자)

**열어 둔 것**

없음 — 갈림길 여덟을 착공에서 정했다.

## ⑤ 검증 계획

명령은 PR 본문에 결과와 함께 적는다. 「어긋내 보기」는 일부러 망가뜨린 작업트리에 같은 명령을 대어 떨어지는지 본 뒤 되돌린다.

**PR B**

- `./scripts/gates.sh` 열여덟 통과.
- `test-sync-slice.py` — 조각 8 의 꼴은 그대로 두고 더한다.

  | 꼴 | 기대 |
  |---|---|
  | 원본 `SKILL.md` 가 `blob/<전체 sha>/` 를 박았다 | 사본의 링크가 `blob/<출처 전체 sha>/` · 그 밖의 바이트는 원본 그대로(L1) |
  | 한 줄에 `blob/main/` 과 `blob/<전체 sha>/` 가 섞였다 · 틀 파일에 `blob/<전체 sha>/` | 다 출처로(L1) |
  | 원본에 `blob/0123abc/`(짧은 sha) · `blob/<대문자 40 자>/` | 꼴마다 멈춤 · 대상 그대로(L2) |

- 어긋내 보기 둘 — 다 `test-sync-slice.py` 가 떨어진다: L1 의 바꿈을 `blob/main/` 만으로 되돌린다, L2 가 짧은 sha 를 받게 넓힌다.
- X1 — `git diff --name-only main...HEAD` 와 기준 · 머리 각각의 `eval-key.py route --list` · `full --list` 의 교집합이 0.

**PR C**

- `./scripts/gates.sh` 스물하나 통과 — `verify-map-pin.py` 가 claude-kit 에서 지나간다(S1).
- `test-verify-map-pin.py` — 임시 git 레포(`docs/procedure.md` · `vibe-slice/skills/a/SKILL.md`)에 꼴마다 만든다.

  | 꼴 | 기대 |
  |---|---|
  | 지도 커밋 A, 플러그인 커밋 B 가 A 를 박음 | 통과 |
  | 그 뒤 지도만 고친 커밋 C | 통과 — 기준은 B |
  | 그 뒤 틀만 고친 커밋 D(링크는 A) | M5 · 박을 커밋으로 C 를 찍는다 |
  | D 뒤 링크를 C 로 다시 박은 커밋 E | 통과 |
  | 옆 가지에서 박은 커밋을 머지 커밋으로 들인 꼴 | 통과 |
  | 작업트리 — `vibe-slice/` 만 고쳐 C 를 박음 | 통과 · 기준 `작업트리` |
  | 작업트리 — 지도도 고치고 `vibe-slice/` 도 고침 | M5 · 「먼저 커밋」 |
  | `blob/main/` · `blob/0123abc/` · `tree/main/` · `raw.githubusercontent.com` | M1 |
  | 없는 40 자 커밋 | M2 |
  | 조상이 아닌 커밋(다른 가지) | M3 |
  | 그 커밋에 없는 경로(`docs/nope.md`) | M4 |
  | 지도가 다른 옛 커밋 | M5 |
  | 링크가 없다 | M6 |
  | 스킬 둘 가운데 한 `SKILL.md` 의 링크만 지움 | M6 · 그 스킬 |
  | 한 스킬의 링크가 `docs/README.md` 를 박음(그 커밋에 있는 경로) | M6 · 그 스킬 |
  | 한 스킬의 링크를 그 스킬의 틀 파일로 옮김 | M6 · 그 스킬 |
  | 지도 링크에 더해 다른 경로를 박은 링크 하나(그 경로가 기준과 같음) | 통과 |
  | 얕은 클론 · `vibe-slice/` 없음 · git 아님 | R2 · R3 · R1 |
  | 인자를 줌 | 2 |
  | `LC_ALL=C` · `PYTHONIOENCODING=cp949` 로 실패 꼴 | 예외 없이 1(O2) |

- `bite-map-pin.py` — V1 의 자리 아홉을 하나씩 망가뜨린 사본마다 자체 시험이 떨어진다.
- 어긋내 보기 둘 — 자체 시험의 표에서 M3 꼴을 지우면 `bite-map-pin.py` 가 1 이다. 두 `SKILL.md` 가운데 하나를 `blob/main/` 으로 되돌리면
  `gates.sh` 가 M1 로 떨어진다.
- 원본 — `claude plugin validate ./vibe-slice` · `verify-manifest.py` 통과, `verify-budget.py` 의 `slice-review` 호출 시 ≤ 4,500.
- 실물(성공 기준 3) — C 머리에서 빈 임시 git 레포에 `sync-slice.sh` 로 심고, `diff -r` 를 원본 스킬 폴더와 견준 출력.
- X1 — B 와 같다.

**스스로 쓰기** — PR A · B · C 의 리뷰를 `slice-review` 로 가른다. PR 본문의 `## 리뷰 회차` 와 답글. B · C 는 `verify-slice-gate.py` 를
CI 에서 지나간다(이 착공이 머지된 뒤).

**단계 5(배포)** — PR C 뒤: 저자가 강호쟁패에서 `claude plugin marketplace update pdw96-kit` · `claude plugin update vibe-slice@pdw96-kit` 로
0.4.2 를 받고, 세션을 다시 연 뒤 `/vibe-slice:slice-docs` 가 읽은 `${CLAUDE_SKILL_DIR}/SKILL.md` 의 링크가 박은 커밋인지, claude-kit 에서
`git show <박은 커밋>:docs/procedure.md` 가 C 머지의 `docs/procedure.md` 와 같은지 본다(성공 기준 4).

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A 착공 | 요구사항 · 설계 · ADR 0019 · 마스터플랜(「플러그인의 절차 지도 판」 `진행`) | 단계 1 · 2 |
| B 사본 길 | `sync-slice.sh` 의 L1 · L2 · `test-sync-slice.py` · `docs/architecture.md` 「스킬 심기」 | ② 의 L1 · L2 · X1, 성공 기준 3 의 시험 몫 |
| C 박기 | `verify-map-pin.py` · `test-verify-map-pin.py` · `bite-map-pin.py` · `gates.sh` · 두 `SKILL.md` 의 링크 · `plugin.json` 0.4.2 · `budget.txt` · `docs/architecture.md` | ② 의 R1 ~ R3 · M1 ~ M6 · O1 · O2 · S1 · V1 · X1, 성공 기준 1 · 2 · 3 의 실물 · 5 |

B 가 C 보다 먼저다 — C 가 원본 링크를 박으면 B 전의 `sync-slice.sh` 는 L2 로 멈춘다. 성공 기준 4 는 단계 5 에서 저자가 본다. 조각을 닫는
기록은 그 뒤 따로 낸다(단계 6).
