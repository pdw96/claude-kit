# 조각 37 설계 — `eval.yml` 적기 조건 검사

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A · 닫기 | 조각 나눔 — 「`eval.yml` 적기 조건 검사」를 순서 37 · `진행` 으로 · 조각 폴더. 닫기에서 `닫힘` |
| `docs/slices/37-eval-gate-shape/` · `docs/adr/0048-eval-gate-shape.md` | A | 이 요구사항 · 설계 · ADR |
| `scripts/verify-eval-gate.py` | B | 새 검사(② A · Y · H · T · F · G) |
| `scripts/gates.sh` | B | `checks` 에 한 줄 · 머리 주석과 끝 줄의 수(스물하나 · 스물여섯) |
| `scripts/bite-gates.sh` | B | 새 절 — `eval.yml` 변조본 · 대조군 · 인자 거절(② V). 머리 주석의 검사 수 · `bunch` 앞 주석의 「스물 통과」 |
| `docs/architecture.md` | B | 「키 없는 게이트」 단락의 수와 새 검사 한 문장 |
| `.github/workflows/eval.yml` | C | **주석만** — 「열아홉」 두 줄을 그때의 수로 · 적기 · 건너뛰기 스텝의 주석에 새 검사를 가리키는 줄 |
| `docs/audit/` | 닫기 | 닫기 전 감사 회차의 기록 · 브리핑 · 대장 등록 |

앵커볼트를 건드리지 않는다 — 이름 · 감사자의 `tools` · 공통 절 · 대장 둘의 모양 · 절 제목 · 고정 영역이 그대로다. 플러그인 폴더(`vibe-audit/` · `vibe-slice/`)를
고치지 않아 판이 그대로다. `eval.yml` 은 C 에서 주석만 바뀌지만 수트 지문(`eval-key.py`)은 파일 전체를 해시해 C 에서 route 수트가 한 번 돈다(요구사항 「제약」).
새 검사는 `run-evals.sh` 가 부르지 않아 수트 지문 밖이고, 변조 시험 지문(`gate-key.py`)에는 저절로 든다(넣는 쪽, 조각 35 설계 ③ S13). `INTENT.md` 도 그대로다 —
What 의 「키 없이 도는 게이트」 안이고 Not 에 걸리지 않는다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 다 B 가 싣는다. 검사는 `python3 scripts/verify-eval-gate.py [<eval.yml 경로>]` 이고, ③ 이 든 닫힌 목록과 견준다. 판정에 드는 칸(조건 · 명령 ·
입력)은 글자 그대로, 알림 글 · 주석 · 스텝 이름 · 액션의 판은 자유다(ADR 0048 의 3).

- A **인자와 출력.**
  - A1 인자 없이는 저장소 맨 위의 `.github/workflows/eval.yml`, 경로 하나면 그 파일을 읽는다. 그 밖(③ A3)은 사용법을 찍고 종료 2.
  - A2 맞으면 `PASS verify-eval-gate.py — …` 한 줄과 종료 0. 어긋나면 어긋난 자리마다 `FAIL [<이 절의 번호>] <스텝> · <칸> — <까닭>` 을 다 찍고 종료 1. 파일을
    읽지 못해도 `FAIL` 과 종료 1.
- Y **읽는 꼴.** 읽는 자리(워크플로 머리의 키 · gate 잡)는 ③ Y1 ~ Y5 의 꼴만 읽는다. Y6 의 꼴이 오면 그 줄을 찍고 떨어진다 — YAML 의 뜻이 이 읽기와 갈릴 수 있는
  꼴이라, 읽은 척하지 않는다(ADR 0048 의 5).
- H **머리.**
  - H1 워크플로 머리의 키는 ③ H1 의 넷뿐이다 — `defaults` · `env` 가 오면 떨어진다(모든 스텝의 셸 · 환경을 바꾼다).
  - H2 gate 잡의 키는 ③ H2 의 넷뿐이다 — `defaults` · `env` · `continue-on-error` · `if` · `container` 같은 것이 오면 떨어진다.
- T **열한 스텝 — 적기와 건너뛰기의 사슬.**
  - T1 **차례** — gate 잡의 스텝이 ③ T 의 열한으로 시작해 그 차례대로 이어진다. 사이에 다른 스텝이 끼거나 · 빠지거나 · 차례가 바뀌면 떨어진다. 열한 뒤의
    스텝(수트 쪽)은 보지 않는다 — 변조 시험의 지문은 열한째에서 이미 캐시에 적혔다.
  - T2 **칸** — 스텝마다 ③ T 의 칸만 갖는다. `continue-on-error` · `shell` · `working-directory` · `timeout-minutes` 같은 다른 칸이 오면 떨어진다. `name` 은 어느
    스텝이든 있어도 없어도 된다.
  - T3 **글** — `id` · `if` · `env` · `with` 의 값과 `run` 의 명령 줄이 ③ T 의 글과 글자 그대로 같다. `uses` 는 `@` 앞이 같다. 줄 앞뒤의 공백 · 빈 줄 · 주석 줄은
    보지 않는다. `run` 의 알림 줄(F2)은 명령 줄에서 빼고 견준다.
  - T3 이 닫는 것 — **적기**: `full=true` 를 적는 줄은 건너뛰지 않는 갈래에 한 번, 인자 없는 `./scripts/gates.sh` 바로 앞이다 · `./scripts/gates.sh` 의 두 줄은 그
    줄 전체다(`||` · `|` · `;` · `&` 가 붙지 않는다) · 적는 스텝의 `if` 에 상태 함수가 없어 앞 스텝이 다 성공했을 때만 돈다 · 그 캐시 저장은 그 스텝의 성공에 걸린다 ·
    `main` 범위에 다시 적는 길은 머지된 PR 판정의 적중에 걸린다. **건너뛰기**: 지문은 `gate-key.py` 가 낸 모양 맞는 것뿐이다 · 찾아보기는 지문이 있고
    `workflow_dispatch` 가 아닐 때, `restore-keys` 없이 그 지문 하나로 · 건너뛰는 갈래는 두 적중 가운데 하나이고 근거 파일이 비지 않았을 때 · 건너뛸 때 근거를
    `--skip-bite` 로 넘긴다.
- F **자유로운 칸.** 다음만 바꾼 `eval.yml` 은 통과한다.
  - F1 스텝 이름(`name`) · 주석 줄 · 빈 줄.
  - F2 `run` 의 알림 줄 — 줄 전체가 `echo "<글>"` 이고, 글에 `$(` · 역따옴표 · `\` · 따옴표가 없으며 펼치는 것은 `$이름` · `${이름}` 뿐인 줄. 따옴표 뒤에 아무것도
    없다 — `>` · `>>` 가 붙은 줄은 알림 줄이 아니라 명령 줄이다.
  - F3 `uses` 의 판 — `@` 뒤가 `v<숫자>` 인 것.
- G **갇힘.** 주석 밖에서 `.gate-pass` 나 `gfp` 를 든 줄은 파일 전체에서 열한 스텝 안에만 있다 — 다른 잡이나 열한 뒤의 스텝이 변조 시험의 근거 파일이나 지문을
  쓰면 떨어진다.
- V **문다 — `bite-gates.sh` 의 새 절.**
  - V1 **변조본** — `eval.yml` 사본의 한 자리를 바꿔 `verify-eval-gate.py <사본>` 을 부른다. 종료 1 이고 `FAIL [` 줄을 찍었을 때만 「물었다」로 센다(조각 36 OB-4 —
    0 이 아닌 종료를 다 세지 않는다). 바꿀 글이 `eval.yml` 에 꼭 한 번이 아니면 변조본을 돌리기 전에 종료 1 — 변조본이 `eval.yml` 을 따라 고쳐지게.
  - V2 **대조군** — F 의 칸만 바꾼 사본이 `PASS` · 종료 0 이다. 하나라도 떨어지면 검사가 자유로운 칸까지 잡는 것이라 종료 1.
  - V3 **인자** — ③ A3 의 꼴이 종료 2 이고 아무것도 견주지 않는다.

**보장하지 않는 것(알려진 한계)**

- **gate 스텝의 실패를 삼킨 `eval.yml` 의 그 CI 실행** — 새 검사는 그 실행의 `gates.sh` 안에서 돌므로, `./scripts/gates.sh || true` 인 `eval.yml` 의 CI 는 검사가
  떨어져도 초록이고 지문을 적는다. 로그에 `FAIL [T3]` 줄은 남는다. 그 꼴은 로컬 `gates.sh` 가 떨어뜨리고(세션은 PR 을 내기 전에 돌린다 — 조각 36 이 15분 안으로
  줄였다) 리뷰가 본다. `eval.yml` 안에 검사를 따로 두면 같은 PR 이 그 스텝도 함께 지울 수 있다(ADR 0048 의 2).
- **열한 스텝이 부르는 것의 속** — `gates.sh`(그 자체 시험 `test-gates.py`) · `gate-key.py` · `eval-merged-pass.py`(각자의 변조 시험)가 든다. 액션의 동작(캐시의
  `cache-hit` 는 키가 꼭 같을 때만 참)과 GitHub 의 기본 셸(`bash -e`)은 사실로 둔다.
- **일부러 감춘 우회** — 열한 밖의 스텝이 변수로 지은 경로로 캐시를 쓰기, 저장소 변수 · 시크릿으로 셸을 바꾸기 같은 것. 모양 검사다 — 실수로 흔든 글을 문다.
- **같은 뜻의 다른 글** — 닫힌 목록과 글자가 다르면 뜻이 같아도 떨어진다(예: `if` 의 따옴표를 바꾸기 · 줄을 둘로 나누기). 거짓 빨강 쪽이고, 그 PR 이 검사의 목록을
  함께 고쳐 리뷰에 내놓는다. 액션의 판을 넘어 `with` 의 값(예: `node-version`)을 바꿀 때도 그렇다.
- **검사를 지우거나 목록을 함께 고친 PR** — `gates.sh` 의 줄을 지우는 것은 조각 35 설계 끝 그대로(감사 OB-2), 목록과 `eval.yml` 을 함께 고친 PR 은 리뷰가 본다.
- **수트 지문의 사슬 · verdict · `eval.yml` 이 GitHub 에서 받아들여지는지** — 요구사항 하지 않을 일 2 · 3.

## ③ 받는 입력

검사 장치다 — 받는 모양을 실제 파일에서 뽑은 닫힌 목록으로 든다(`main` `7df49c4` 의 `.github/workflows/eval.yml`). B 의 검사가 이 목록을 코드로 들고, 그 뒤의
바꿈은 그 PR 들이 검사와 함께 고친다.

**A — 인자.**

| # | 꼴 | 받는가 |
|---|---|---|
| A1 | 없음 | 받는다 — 저장소의 `.github/workflows/eval.yml` |
| A2 | `-` 로 시작하지 않는 경로 하나 | 받는다 — 그 파일 |
| A3 | 인자 둘 이상 · `-` 로 시작하는 인자 | 거절 — 종료 2 |

**Y — 읽는 꼴.** 읽는 자리는 워크플로 머리의 키 이름과 `jobs:` 아래 `gate:` 잡이다. 그 밖(다른 잡 · `on:` 의 값)은 G 의 줄 찾기만 한다.

| # | 꼴 | 받는가 |
|---|---|---|
| Y1 | 공백 두 칸 단위 들여쓰기 · 따옴표 없는 키 `<이름>:` | 받는다 |
| Y2 | 키 뒤의 한 줄 값 | 받는다 — 글 그대로 견준다(따옴표도 글이다) |
| Y3 | 값이 없는 키 아래 한 단계 깊은 매핑(`env` · `with` · `permissions` · `outputs`) · `- ` 로 시작하는 스텝 목록(`steps`) | 받는다 |
| Y4 | `run: \|` 아래 더 깊게 들여 쓴 줄들 | 받는다 — 셸 줄로 |
| Y5 | 주석 줄 · 빈 줄 | 받는다 — 보지 않는다 |
| Y6 | 탭 · 값의 머리의 `&앵커` · `*별칭` · `!태그` · `<<:` · 흐름 꼴(`{` · `[` 로 여는 값) · 한 매핑의 같은 키 둘 · `\|` 밖의 블록 꼴(`\|-` · `\|+` · `>` …) · 따옴표 키 · 값 뒤의 주석 · Y3 · Y4 밖에서 더 깊게 들여 쓴 줄 | 거절 |

**H — 머리.**

| # | 어디 | 받는 키 |
|---|---|---|
| H1 | 워크플로 머리 | `name` · `on` · `concurrency` · `jobs` |
| H2 | gate 잡 | `runs-on` · `permissions` · `outputs` · `steps` — 값은 보지 않는다(`steps` 는 T) |

**T — 열한 스텝.** 칸은 그 스텝이 갖는 것의 닫힌 목록이다(`name` 은 늘 자유라 뺐다). 「판정에 드는 글」은 `run` 이면 알림 줄 · 주석 · 빈 줄을 뺀 명령 줄을 차례대로
든다.

| # | 스텝(지금 이름) | 칸 | 판정에 드는 글 |
|---|---|---|---|
| T1 | (이름 없음) | `uses` · `with` | `actions/checkout` · `fetch-depth: 0` |
| T2 | (이름 없음) | `uses` · `with` | `actions/setup-node` · `node-version: "22"` · `package-manager-cache: false` |
| T3 | (이름 없음) | `run` | `npm install -g @anthropic-ai/claude-code` |
| T4 | 변조 시험 지문 | `id` · `run` | `gfp` · 아래 ① |
| T5 | 같은 지문이 이미 물었는가 | `id` · `if` · `uses` · `with` | `gseen` · `steps.gfp.outputs.key != '' && github.event_name != 'workflow_dispatch'` · `actions/cache/restore` · `path: .gate-pass` · `key: ${{ steps.gfp.outputs.key }}` |
| T6 | 머지된 PR 의 변조 시험이 물었는가 | `id` · `if` · `env` · `run` | `gmerged` · `github.event_name == 'push' && steps.gfp.outputs.key != '' && steps.gseen.outputs.cache-hit != 'true'` · `GITHUB_TOKEN: ${{ github.token }}` · `KEY: ${{ steps.gfp.outputs.key }}` · `python3 scripts/eval-merged-pass.py "$KEY"` |
| T7 | 변조 시험 지문을 main 에도 적는다 | `if` · `env` · `run` | `steps.gmerged.outputs.hit == 'true'` · `PR: ${{ steps.gmerged.outputs.pr }}` · `CREATED: ${{ steps.gmerged.outputs.created }}` · 아래 ② |
| T8 | (이름 없음) | `uses` · `if` · `with` | `actions/cache/save` · `steps.gmerged.outputs.hit == 'true'` · `path: .gate-pass` · `key: ${{ steps.gfp.outputs.key }}` |
| T9 | 키 없이 도는 게이트 | `id` · `env` · `run` | `gates` · `KEY: ${{ steps.gfp.outputs.key }}` · `HIT: ${{ steps.gseen.outputs.cache-hit == 'true' \|\| steps.gmerged.outputs.hit == 'true' }}` · 아래 ③ |
| T10 | 변조 시험까지 통과한 지문을 적는다 | `id` · `if` · `run` | `gpass` · `steps.gates.outputs.full == 'true' && steps.gfp.outputs.key != ''` · 아래 ④ |
| T11 | (이름 없음) | `uses` · `if` · `with` | `actions/cache/save` · `steps.gpass.outcome == 'success'` · `path: .gate-pass` · `key: ${{ steps.gfp.outputs.key }}` |

`run` 의 명령 줄 — 줄 앞의 공백은 뺐다.

```
① T4
if key=$(python3 scripts/gate-key.py) && [[ $key =~ ^gate-bite-py[^[:space:]]+-git[^[:space:]]+-[0-9a-f]{24}$ ]]; then
echo "key=$key" >> "$GITHUB_OUTPUT"
else
fi

② T7
mkdir -p .gate-pass
echo "PR #$PR 의 refs/pull/$PR/merge 캐시($CREATED 에 적힘) — 그것을 읽은 main 실행 $GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID ($GITHUB_SHA)" > .gate-pass/run.txt

③ T9
if [ "$HIT" = true ] && [ -s .gate-pass/run.txt ]; then
why="같은 지문($KEY)이 이미 물었다 — $(head -n 1 .gate-pass/run.txt)"
./scripts/gates.sh --skip-bite "$why"
else
if [ "$HIT" = true ]; then
fi
echo "full=true" >> "$GITHUB_OUTPUT"
./scripts/gates.sh
fi

④ T10
mkdir -p .gate-pass
echo "$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID ($GITHUB_SHA)" > .gate-pass/run.txt
```

빠진 알림 줄은 넷이다 — T4 의 `echo "변조 시험 지문: $key"` · `echo "::warning::…"`, T9 의 `echo "::notice::… $why"` · `echo "::warning::…"`. 다 F2 의 꼴이다.

## ④ 결정

**정한 것**

- 이 관찰을 검사로 닫는다 — 두지 않는다는 ADR 대신. ADR 0048 의 1.
- 검사의 자리는 늘 도는 `checks` 의 새 파일이다 — `bite-gates.sh` 의 한 절이나 `eval.yml` 의 스텝 대신. ADR 0048 의 2.
- 판정에 드는 칸은 닫힌 목록을 글자 그대로, 알림 글 · 주석 · 이름 · 액션의 판은 자유다. ADR 0048 의 3.
- 보는 범위는 gate 잡의 머리와 첫 열한 스텝, 그리고 파일 전체의 `.gate-pass` · `gfp` 줄이다. ADR 0048 의 4.
- 읽는 법은 지금 쓰는 꼴만 읽는 줄 단위 읽기이고 그 밖은 거절한다. ADR 0048 의 5.
- PR 나눔 — B 가 검사, C 가 `eval.yml` 주석(수트 한 번). ADR 0048 의 6.

**열어 둔 것**

없음 — 1 과 6 의 「`eval.yml` 을 고친다」는 저자가 이 착공 세션에서 정했고(2026-10-25), 2 ~ 5 와 6 의 나눔은 세션이 제안해 착공 PR 에서 저자가 본다.

## ⑤ 검증 계획

시험을 세우는 조각이다(새 검사와 그 변조본 · 대조군을 더한다). 꼴 하나하나와 변조본의 대응은 B 의 PR 본문이 든다.

- **시험 규칙**
  - R1 ② 의 조건마다 변조본 하나 이상 — Y(③ Y6 의 꼴마다) · H1 · H2 · T1(끼기 · 빠지기 · 바꾸기) · T2 · T3(칸 갈래마다 — `id` · `if` · `env` · `with` · `uses` ·
    `run`) · F2 의 경계(`>` 가 붙은 알림 줄 · `$(` 가 든 알림 줄) · G. 감사가 든 둘(T9 의 `./scripts/gates.sh || true` · 건너뛰는 갈래의 `full=true`)은 꼭 든다.
  - R2 F 의 칸마다 대조군 하나(V2).
  - R3 변조본 · 대조군이 바꿀 글은 `eval.yml` 에 꼭 한 번(V1). 「물었다」는 종료 1 · `FAIL [` 줄(V1).
  - R4 ③ A3 의 꼴마다 종료 2 하나(V3).
- V1 **성공 기준 1** — B 의 로컬과 CI 의 gate 잡 로그에서 `PASS verify-eval-gate.py` · 「스물여섯 다 통과」, 지문이 같아 건너뛴 실행(닫는 PR)의 「스물하나 통과」.
- V2 **성공 기준 2 · 3** — B 의 CI 로그에서 새 절의 끝 줄(변조본 수 · 대조군 수). 감사가 든 둘을 손으로 재현해 B 의 PR 본문에 싣는다.
- V3 **성공 기준 4** — C 의 diff 에서 `eval.yml` 의 더하고 뺀 줄이 다 주석 줄이고, C 의 gate 잡에서 `PASS verify-eval-gate.py`.
- V4 **성공 기준 5** — 각 PR 의 eval 잡(A · B · 닫기는 skipped, C 는 돌아 통과)과 C 의 머지 `main` 푸시의 「머지된 PR 이 통과했는가」 적중.
- V5 **성공 기준 6** — 각 PR 의 CI gate 잡. B 의 작업트리에서 인자 없는 `./scripts/gates.sh` 를 끝까지 돌려 시간과 끝 줄을 PR 본문에 싣는다(백그라운드).
- V6 **성공 기준 7** — C 가 머지된 뒤 `main` 에서 기준 `7df49c4` 로 `audit-quality` 를 돌리고 닫는 PR 의 대장에 등록한다.
- 단계 5 — 배포처는 이 저장소의 CI 다. 보이는 것은 V1 의 실행이다. 되돌리는 길은 C · B 를 되돌리는 것이다 — C 를 되돌리면 route 수트가 한 번 더 돈다.

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A | 착공 — 마스터플랜 · 이 요구사항 · 설계 · ADR 0048 | 단계 0 ~ 2 |
| B | `verify-eval-gate.py` · `gates.sh` 의 한 줄과 수 · `bite-gates.sh` 의 새 절 · `docs/architecture.md` | ② A · Y · H · T · F · G · V · 성공 기준 1 · 2 · 3 · 6 |
| C | `eval.yml` 의 주석 — 수 두 줄 · 새 검사를 가리키는 줄 | 성공 기준 4 · 5 |
| 닫기 | 닫기 전 감사 회차의 등록 · 요구사항 끝의 `## 닫으며` · 마스터플랜 37 을 `닫힘` · 다음 조각 | 단계 6 · 성공 기준 7 |

B 를 앞에 두는 까닭 — C 의 주석이 가리키는 검사가 먼저 머지되어 있고, C 의 `eval.yml` 이 새 검사를 지나는지가 C 의 CI 에서 보인다. 수트를 부르는 바꿈을 주석뿐인
C 하나에 가두면, B 의 리뷰가 몇 회차를 돌아도 수트는 돌지 않는다. C 에 둘째 푸시가 나면 수트가 그만큼 더 돈다 — 그 수는 닫는 기록이 든다.

## 닫기 전 감사 회차에서 찾은 것 (2026-10-26, PR D 를 열기 전)

C 가 머지된 `main`(`06d0205`)에서 기준 `7df49c4` 로 `audit-quality` 를 돌렸다(요구사항 「제약」의 감사 회차 — 회차 4). 부적합은 없다. 관찰 OB-3 —
② F2 의 알림 줄은 글이 `::` 로 열어도 자유라, 건너뛰는 갈래에 `echo "::set-output name=full::true"` 를 넣은 `eval.yml` 이 `PASS` 였다. GitHub 이
폐기 예고한 그 명령을 아직 처리하면 `>>` 없이도 `full` 이 선다. 저자가 이 조각에서 고치기로 정했다(2026-10-26).

**보장에 넣는다**

- F2′ 알림 줄의 글이 `::` 로 열면 `::notice::` · `::warning::` 으로 열 때만 알림 줄이다. 그 밖의 워크플로 명령(`::set-output` · `::add-mask::` 따위)으로
  여는 `echo` 줄은 명령 줄로 견준다 — ③ T 의 목록에 없으니 `FAIL [T3]` 다. 지금 `eval.yml` 의 알림 줄 넷은 다 `::notice::` · `::warning::` 이거나 `::` 로
  열지 않아 그대로 자유다.
- V1′ `bite-gates.sh` 의 새 절에 그 꼴의 변조본 하나 — T9 의 건너뛰는 갈래에 `echo "::set-output name=full::true"`. 옛 검사(`06d0205`)는 그 사본에
  `PASS`, 새 검사는 `FAIL [T3]` 다(D 의 PR 본문).

**그대로 둔다** — 감사 회차 4 의 나머지 관찰은 설계가 받아들인 한계다(저자 판정은 닫는 기록이 든다).

- OB-1 — 검사는 T9 가 부르는 `gates.sh` 안에서 돈다. T9 가 `gates.sh` 에 닿지 않는 꼴(T9 에 `if:` · 호출 줄 지우기 · 스텝 지우기)은 그 CI 실행의
  로그에 아무 줄도 남기지 않는다 — ② 「보장하지 않는 것」 첫 줄이 든 `|| true` 꼴만 `FAIL [T3]` 줄을 남긴다. 근거는 gate 로그의 `PASS verify-eval-gate.py`
  줄이고, 그 줄이 없는 초록 gate 는 이 검사가 돌지 않은 실행이다.
- OB-4 — 변조본은 어느 번호가 물었는지 보지 않고 개수를 단언하지 않는다. 「T3 id」 변조본은 차례의 얼굴(`id`)이라 `[T1]` 로 문다(B 의 PR 본문).

**⑥ 에 한 줄을 더한다**

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| D | `verify-eval-gate.py` 의 알림 줄 판정 · `bite-gates.sh` 새 절의 변조본 하나 · 이 항목 | OB-3 · F2′ · V1′ |

닫는 PR 은 D 다음이다. D 는 `scripts/` 를 고쳐 변조 시험 지문이 바뀌므로 첫 머리가 변조 시험까지 다 돈다. `eval.yml` 을 고치지 않아 route 수트는
돌지 않는다. 감사 회차는 다시 돌리지 않는다 — OB-3 은 관찰이라 대장에 줄이 없고, 닫는 기록이 D 의 로그로 이 항목을 든다.
