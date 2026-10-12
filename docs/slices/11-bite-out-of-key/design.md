# 조각 11 설계 — 게이트 변조본을 수트 지문 밖으로

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`, 갈림길은 ADR 0020.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A | 「게이트 변조본을 수트 지문 밖으로」 상태 `진행` · 조각 폴더 |
| `docs/adr/0020-bite-gates-file.md` | A | 갈림길 여섯 |
| `scripts/bite-gates.sh` | B · C | 새 파일. B — 「게이트가 무는가」 스텝의 본문을 옮기고 ② 의 B2 자리와 K1 만 더한다. C — D1 ~ D3 |
| `.github/workflows/eval.yml` | B | 「게이트가 무는가」 스텝(③ 의 70 ~ 778 줄)을 지운다. 그 밖의 바이트는 그대로다 — 이 조각에서 수트 지문에 드는 파일은 이것 하나다 |
| `scripts/gates.sh` | B | `bite-gates.sh` 를 부르는 줄 · 머리 주석의 「게이트가 무는지는 대개 여기서 안 본다」 · 끝의 개수 「스물하나」 → 「스물둘」 |
| `scripts/bite-slice-gate.py` · `scripts/bite-verify-docs.py` · `scripts/bite-map-pin.py` · `scripts/test-verify-manifest.py` · `scripts/test-verify-feedback.py` | B | 머리 주석에서 CI 「게이트가 무는가」(`eval.yml`)를 가리키는 문장 — `bite-gates.sh` 로. 코드는 그대로다 |
| `docs/architecture.md` | B | 부품 표의 CI 줄 · 「게이트가 무는가」 절 — 변조본이 다 `gates.sh` 가 부르는 파일에 있다 |
| `docs/schema.md` | B | 「이 모양을 무는 것」의 두 문장(CI 「게이트가 무는가」) |
| `vibe-audit/evals/README.md` | B | 「도는 것과 무는 것은 …」 한 문장. 수트 지문 밖이다(`README.md`). 감사자 · 커맨드가 아니라 판을 올리지 않는다 — 조각 4 PR B 가 같은 파일을 판 없이 고쳤다 |
| `CLAUDE.md` | B · C | B — 「작업 방식」의 「CI 「게이트가 무는가」나 `gates.sh` 가 부르는 변조본」을 `gates.sh` 가 부르는 변조본으로, 「스택」의 가짜 트레이스 자리를 `bite-gates.sh` 로. C — 「스택」에서 그 문장을 뺀다 |
| `CHECKLIST.md` | B | 「항상」의 변조본 줄 — CI 「게이트가 무는가」를 뺀다 |

`docs/procedure.md` 는 고치지 않는다 — 지도는 「게이트가 무는가」를 말하지 않는다. 고치면 `vibe-slice/` 의 박은 지도와 갈려 판 검사의
기준이 바뀐다(ADR 0019 의 2).

**앵커볼트.** 건드리지 않는다 — 이름(스크립트는 앵커볼트 이름이 아니다) · 감사자 · 공통 절 · 대장 · 「…의 칸」 · `AGENTS.md` 는
그대로다. 플러그인 파일은 `vibe-audit/evals/README.md` 한 문장뿐이다(위 표).

**원본에 레포별 분기를 두지 않는다**(`CLAUDE.md` 「금지」). `bite-gates.sh` 는 `scripts/` 에만 있고 어느 플러그인에도 실리지 않는다.

**시스템 구조.** 부품 「CI」가 변조본을 들지 않게 되고, 「게이트가 무는가」가 `gates.sh` 가 부르는 파일 넷이 된다 — B.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 번호는 ⑤ 와 PR 본문이 같이 쓴다.

- **옮김** (PR B)
  - B1 `eval.yml` 에 「게이트가 무는가」 스텝이 없다. `main` 과의 diff 는 ③ 의 70 ~ 778 줄을 지운 덩어리 하나뿐이다.
  - B2 `bite-gates.sh` 의 본문은 그 스텝의 `run: |` 본문(③ 의 72 ~ 777 줄)에서 열 칸 들여쓰기를 뗀 것과 같다. 다른 줄은 아래 자리뿐이다 —
    머리(shebang · 머리 주석 · 맨 위로 `cd`) · B3 · B4 · K1. 기준 스텝과 `bite-gates.sh` 의 diff 를 PR 본문에 싣는다.
  - B3 `$GITHUB_WORKSPACE` 를 git 맨 위(`git rev-parse --show-toplevel`)로 바꾼다 — CI 의 환경 변수 없이 돈다.
  - B4 제자리에서 흔드는 파일(③ 의 `copies.json` 과 지문 시험의 열)은 흔들기 전에 실행 비트까지 임시 폴더로 베끼고, `git checkout --` 대신
    거기서 되돌린다. 변조본이 떨어져 끝나도 · INT · TERM 으로 끊겨도 trap 이 되돌린다. 그래서 커밋 안 한 수정이 남는다. 흔들기 전에 베낀
    자리를 한 줄 찍는다 — trap 이 돌지 못하는 꼴(SIGKILL)에서 손으로 되돌릴 자리다.
  - B5 멈춤 자리(`::error::`) 63 이 같은 조건 · 같은 메시지로 그대로 있다. K1 이 하나를 더한다.
  - B6 `gates.sh` 가 `bite-gates.sh` 를 부르고 끝의 개수가 스물둘이다. CI gate 잡은 `gates.sh` 하나를 부른다.
- **지문**
  - K1 `bite-gates.sh` 가 끝에서 `eval-key.py route --list` · `full --list` 를 읽어, `scripts/gates.sh` · `scripts/bite-gates.sh` ·
    `scripts/bite-*.py` 가운데 하나라도 들어 있으면 멈춘다 — 러너가 그 이름을 적게 되면(`eval-key.py` 는 `run-evals.sh` 에 적힌 스크립트를
    지문에 넣는다) 변조본을 고칠 때 다시 수트가 돈다.
  - K2 구현 PR 이 바꾼 파일 가운데 수트 지문(기준과 머리 각각의 `route --list` · `full --list`)에 드는 것은 B 의 `eval.yml` 하나이고, 그
    diff 는 B1 의 지움뿐이다. B 의 다음 머리들은 `eval.yml` 을 다시 고치지 않는다. C 는 0.
- **수트 모델** (PR C)
  - D1 가짜 트레이스 다섯과 「요청한 모델이 안 보인다」의 주석 · 메시지가 쓰는 모델 id 를 `run-evals.sh` 의 `DEFAULT_MODEL=` 줄에서 읽는다.
    그 줄이 꼭 하나가 아니거나 값이 비면 아무 변조본도 돌리기 전에 멈춘다.
  - D2 「이름이 겹치는 딴 모델」 자리는 그 id 의 마지막 `-<조각>` 을 뗀 이름을 요청한다(`claude-sonnet-5-5` → `claude-sonnet-5`). `-` 가
    없으면 멈춘다.
  - D3 「딴 모델」 `claude-haiku-4-5` 와 「날짜가 붙은 같은 모델」 `claude-haiku-4-5-20251001` 은 글자 그대로 둔다. 기본 id 가
    `claude-haiku-4-5` 로 시작하면 멈춘다 — 그때는 「딴 모델」이 딴 모델이 아니다.

**보장하지 않는 것(알려진 한계)**

- **`sync-agents.sh` 변조본의 로컬 실행** — 그 블록은 저장소를 clone 해 심으므로 커밋한 `sync-agents.sh` 를 본다. 커밋 안 한 수정은 로컬에서
  보지 않는다. CI 는 커밋을 돌리므로 같다. 옮기기 전과 같은 한계다.
- **SIGKILL · 전원 끊김** — trap 이 돌지 않는다. B4 가 찍은 자리에서 손으로 되돌린다.
- **같은 작업트리에서 `gates.sh` 둘을 함께 돌리기** — `copies.json` 을 서로 흔든다.
- **변조본이 무는 범위** — 옮김이라 넓히지 않는다. `claude plugin validate` 를 떨어뜨리는 변조본은 없다(ADR 0020 의 4). 변조본 자체를
  망가뜨려 보는 변조본도 없다 — 스텝일 때와 같다.
- **`gates.sh` 의 시간** — 로컬에서 6분 남짓이다(하지 않을 일 6).
- **`::error::` 의 꼴** — 로컬에서는 글자 그대로 찍힌다. CI 에서는 전처럼 주석(annotation)이 된다.
- **K1 밖의 지문** — `eval-key.py` 의 규칙이 맞는지는 지문 시험(③ 의 열)이 그대로 본다. K1 은 변조본 파일이 목록에 없는지만 본다.
- **아직 겪지 않은 가설적 경계 사례** — 예: 경로에 공백이 든 클론, `/tmp` 가 없는 머신. 겪으면 그 PR 에서 정해 날짜 항목으로 적는다. 리뷰가
  이것을 짚으면 범위 밖이다(조각 6 「닫으며」).

## ③ 받는 입력

닫힌 목록이다. 2026-10-12 의 `main`(0202faa)에서 뽑았다. 줄 번호는 `.github/workflows/eval.yml` 의 것이다.

**스텝** — 70 줄 `- name: 게이트가 무는가`, 71 줄 `run: |`, 본문 72 ~ 777 줄(706 줄, 열 칸 들여쓰기, 첫 줄 `set -euo pipefail`),
778 줄 빈 줄. 779 줄부터는 다음 스텝(「키가 있는가」)의 주석이다. 멈춤 자리는 63 이다.

| 변조본이 무는 것 | 멈춤 자리 |
|---|---|
| `verify-copy.py` | 8 |
| `sync-agents.sh` | 11 |
| `verify-evals.py` | 11 |
| `verify-graders.py` | 2 |
| `verify-budget.py` | 1 |
| `verify-manifest.py` | 2 |
| `verify-copies.py` | 5 · 그 준비 2(얕은 체크아웃 · 적는 커밋에 검사기가 없음) |
| `verify-feedback.py` | 2 |
| `test-compare-copies.py` · `test-verify-feedback.py` · `test-verify-docs.py` | 1 · 1 · 1 |
| `run-evals.sh`(가짜 하네스) | 13 |
| `eval-key.py`(지문 시험) | 3 |

**CI 에 기댄 자리** — `$GITHUB_WORKSPACE` 하나(103 줄, `sync-agents.sh` 블록이 저장소를 clone 한다). 스텝 안에 다른 `GITHUB_*` ·
`RUNNER_*` 는 없다.

**제자리에서 흔드는 자리** — 둘. 그 밖의 변조본은 다 `mktemp -d` 의 사본에서 흔든다.

| 자리 | 줄 | 흔드는 파일 | 되돌리는 것 |
|---|---|---|---|
| `verify-copies.py` 블록 둘 | 214 ~ 295 | `copies.json` | `git checkout -- copies.json` 여덟(225 · 228 · 267 · 274 · 280 · 286 · 292 · 295) |
| 지문 시험 `keyed` | 749 ~ 776 | 열 — `vibe-audit/evals/README.md` · `vibe-audit/README.md` · `vibe-audit/evals/budget.txt` · `vibe-audit/evals/trap-liveness-probe/prompt.md` · `vibe-audit/agents/audit-data.md` · `vibe-audit/evals/route-quiet/prompt.md` · `scripts/verify-graders.py` · `.github/workflows/eval.yml` · `vibe-audit/commands/audit-brief.md`(지움) · `scripts/run-evals.sh`(실행 비트를 뺌) | `git checkout -q -- "$2"` 하나(756) |

**수트 모델 id** — `run-evals.sh` 69 줄 `DEFAULT_MODEL=claude-sonnet-5-5` 한 줄. 스텝에서는 `claude-sonnet-5-5` 가 가짜 트레이스 다섯(419 ·
467 · 509 · 541 · 564)과 주석 둘(577 · 594)에, `claude-sonnet-5` 가 요청 하나(597)와 그 메시지(601)에 있다. 딴 모델은
`claude-haiku-4-5`(578 · 612) · `claude-haiku-4-5-20251001`(595 주석 · 603 · 616)이다.

**수트 지문** — `eval-key.py route --list` 72 개 · `full --list` 276 개. `scripts/` 에서 드는 것은 `run-evals.sh` 와 그것이 적은
`verify-evals.py` · `verify-graders.py` 뿐이고, `gates.sh` · `bite-*.py` 는 들지 않는다.

**시간** — 이 세션의 클라우드 컨테이너에서 `gates.sh` 2분 31초, 스텝 본문(B3 만 바꿔) 3분 41초. 스텝 본문은 깨끗한 작업트리에서 통과하고
끝난 뒤 `git status` 가 비었다.

## ④ 결정

**정한 것** — ADR 0020.

- 1 `bite-gates.sh` 를 `gates.sh` 가 부른다(저자)
- 2 bash 한 파일로 글자 그대로 옮긴다(저자)
- 3 제자리 변조는 백업에서 되돌린다(저자)
- 4 넘겨받은 둘 가운데 모델 id 만 — `claude plugin validate` 변조본은 두지 않는다(저자)
- 5 `eval.yml` 은 한 PR 에서 지움으로만 고친다 — B 의 리뷰가 `eval.yml` 을 짚으면 지문 밖으로 돌리고, 안 되면 수트 한 번을 더 감수한다(세션 제안 · 저자)
- 6 변조본 파일이 지문 밖인지 `bite-gates.sh` 가 목록으로 본다(세션 제안 · 저자)

**열어 둔 것**

없음 — 갈림길 여섯을 착공에서 정했다.

## ⑤ 검증 계획

명령은 PR 본문에 결과와 함께 적는다. 「어긋내 보기」는 일부러 망가뜨린 작업트리에 같은 명령을 대어 떨어지는지 본 뒤 되돌린다.

**PR A**

- `./scripts/gates.sh` 스물하나 통과 — `verify-docs.py` 가 새 조각 폴더를, `verify-slice-gate.py` 가 착공 PR 에 결정 문서뿐인지를 본다.

**PR B**

- `./scripts/gates.sh` 스물둘 통과 — 로컬과 CI gate 잡(성공 기준 1).
- B1 · B2 — `git diff main...HEAD -- .github/workflows/eval.yml` 이 지움 덩어리 하나이고, `diff <(git show main:.github/workflows/eval.yml |
  sed -n '72,777p' | sed 's/^          //') scripts/bite-gates.sh` 의 덩어리가 머리 · B3 · B4 · K1 자리뿐이다(성공 기준 2).
- B5 — 기준 스텝과 `bite-gates.sh` 의 `::error::` 줄을 견주면 K1 의 하나만 다르다.
- B4 — 커밋 안 한 수정 둘(`copies.json` 끝의 빈 줄 · `vibe-audit/evals/README.md` 끝의 한 줄)을 두고 `git diff | sha256sum` 을 찍은 뒤:

  | 꼴 | 기대 |
  |---|---|
  | `gates.sh` 를 끝까지 돌림 | 통과 · `git diff` 의 해시가 같다 |
  | `verify-copies.py` 가 없는 커밋을 받게 망가뜨림 — `copies.json` 을 흔든 채 멈춤 자리에서 떨어진다 | `bite-gates.sh` 1 · 해시가 같다 — 이 꼴의 해시는 `git diff -- . ':!scripts/verify-copies.py'` 로 찍는다 |
  | `copies.json` 이 흔들린 사이 TERM | 해시가 같다 |
  | 지문 시험의 `keyed` 가 `run-evals.sh` 의 실행 비트를 뺀 사이 TERM | 실행 비트가 돌아온다 |

- 어긋내 보기 둘 — `verify-feedback.py` 가 늘 0 으로 끝나게 망가뜨리면 `bite-gates.sh` 가 그 멈춤 자리로 1 이다. `run-evals.sh` 의 주석에
  `scripts/bite-gates.sh` 를 적으면 `eval-key.py route --list` 에 그것이 들고 `bite-gates.sh` 가 K1 로 1 이다.
- 성공 기준 3 — `bite-gates.sh` 끝에 주석 한 줄을 더한 작업트리의 `eval-key.py route` 가 더하기 전과 같다.
- K2 · 성공 기준 6 — `git diff --name-only main...HEAD` 와 기준 · 머리 각각의 `eval-key.py route --list` · `full --list` 의 교집합이
  `.github/workflows/eval.yml` 하나다. CI 에서 B 의 첫 머리가 route 수트를 한 번 돌리고, 다음 머리는 eval 잡이 「같은 입력이 이미 통과했다」로
  건너뛴다 — 실행 링크를 PR 본문에 적는다.

**PR C**

- `./scripts/gates.sh` 스물둘 통과.
- D1 ~ D3 — `git worktree` 로 만든 임시 작업트리에서:

  | 꼴 | 기대 |
  |---|---|
  | `DEFAULT_MODEL=claude-opus-5-5` | `bite-gates.sh` 통과 — `bite-gates.sh` 는 고치지 않았다(성공 기준 5) |
  | `DEFAULT_MODEL=` 줄을 지움 · 둘로 늘림 · 값을 비움 | D1 로 1 — 아무 변조본도 돌기 전 |
  | `DEFAULT_MODEL=sonnet` | D2 로 1 |
  | `DEFAULT_MODEL=claude-haiku-4-5` | D3 로 1 |

- 어긋내 보기 — D2 의 이름을 기본 id 그대로 두면 「이름이 겹치는 딴 모델」 멈춤 자리로 1 이다.
- `grep -c 'claude-sonnet-5' scripts/bite-gates.sh` 가 0 이다.
- K2 — 교집합 0. eval 잡이 B 의 지문으로 건너뛴다.

**스스로 쓰기** — PR A · B · C 의 리뷰를 `slice-review` 로 가른다. PR 본문의 `## 리뷰 회차` 와 답글. B · C 는 `verify-slice-gate.py` 를
CI 에서 지나간다(이 착공이 머지된 뒤).

**단계 5(배포)** — 없음 — 플러그인 파일 가운데 바뀌는 것은 수트 문서 한 문장이고 판이 오르지 않는다. 바뀌는 것은 이 저장소의 CI 와
로컬 스크립트뿐이고, 되돌리는 길은 B · C 의 머지 커밋을 되돌리는 것이다(B 를 되돌리면 스텝이 `eval.yml` 로 돌아와 수트가 한 번 돈다).

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A 착공 | 요구사항 · 설계 · ADR 0020 · 마스터플랜(「게이트 변조본을 수트 지문 밖으로」 `진행`) | 단계 1 · 2 |
| B 옮김 | `bite-gates.sh`(머리 · B3 · B4 · K1) · `eval.yml` 스텝 지움 · `gates.sh` · 머리 주석 다섯 · `docs/architecture.md` · `docs/schema.md` · `vibe-audit/evals/README.md` · `CLAUDE.md` · `CHECKLIST.md` | ② 의 B1 ~ B6 · K1 · K2, 성공 기준 1 ~ 4 · 6 |
| C 모델 id | `bite-gates.sh` 의 D1 ~ D3 · `CLAUDE.md` 「스택」 | ② 의 D1 ~ D3 · K2, 성공 기준 5 |

B 가 C 보다 먼저다 — C 는 B 가 세운 파일을 고친다. B 를 글자 그대로의 옮김으로 두려고 D 를 C 로 뗐다 — B 의 diff 를 기준 스텝에 대어
읽을 수 있다. 조각을 닫는 기록은 C 뒤 따로 낸다(단계 6).
