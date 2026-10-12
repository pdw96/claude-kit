# 조각 12 설계 — main 푸시가 통과한 수트 지문을 읽게

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`, 갈림길은 ADR 0021.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A | 「main 푸시가 통과한 수트 지문을 읽게」 상태 `진행` · 조각 폴더 |
| `docs/adr/0021-main-reads-pr-pass.md` | A | 갈림길 일곱 |
| `scripts/eval-merged-pass.py` | B | 새 파일. 판정 — `main` 푸시 커밋을 머지 커밋으로 가진 PR 하나의 merge ref 에 같은 키의 캐시가 있는가(② P1 ~ P6). `--probe` 는 PR 실행에서 같은 API 두 곳을 읽어 보기만 한다(② R1) |
| `scripts/test-eval-merged-pass.py` | B | 새 파일. 자체 시험 — 로컬 가짜 API(`http.server`)에 ③ 의 꼴을 세워 판정을 본다 |
| `scripts/bite-eval-merged-pass.py` | B | 새 파일. 변조본 — 판정을 한 자리씩 망가뜨린 사본에 자체 시험을 대어 다 떨어지는지 본다(`bite-map-pin.py` 와 같은 꼴) |
| `scripts/gates.sh` | B | 위 둘을 부르는 줄 · 머리 주석의 변조본 목록 · 끝의 개수 「스물둘」 → 「스물넷」 |
| `.github/workflows/eval.yml` | B | gate 잡에 `permissions`(③) · 스텝 셋(「API 를 읽어 본다」 · 「머지된 PR 이 통과했는가」 · 「`main` 에도 적는다」) · `fresh` 의 식 · 「건너뛰는 근거」의 조건 · 85 ~ 94 줄 주석(다시 돌리는 길). 그 밖의 바이트는 그대로다 — 이 조각에서 수트 지문에 드는 파일은 이것 하나다 |
| `docs/architecture.md` | B | 「수트」 문단 — `main` 푸시는 머지된 PR 의 통과도 읽는다 · `main` 에서 다시 돌리는 길 |

**앵커볼트.** 건드리지 않는다 — 이름 · 감사자 · 공통 절 · 대장 · 「…의 칸」 · `AGENTS.md` 그대로다. 플러그인 파일을 고치지 않는다
(하지 않을 일 5).

**원본에 레포별 분기를 두지 않는다.** 새 스크립트는 `scripts/` 에만 있고 어느 플러그인에도 실리지 않는다.

**시스템 구조.** 부품 「CI」의 흐름이 바뀐다 — `main` 푸시의 gate 잡이 캐시 목록 API 를 읽는다. `docs/architecture.md` 를 B 에서 고친다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 번호는 ⑤ 와 PR 본문이 같이 쓴다.

- **판정** (`eval-merged-pass.py <키>`, `main` 푸시에서만)
  - P1 `GET /repos/{저장소}/commits/{푸시 sha}/pulls` 에서 `merged_at` 이 비지 않고, `merge_commit_sha` 가 푸시 sha 와 글자 그대로 같고,
    `base.ref` 가 푸시한 가지(`GITHUB_REF_NAME`)인 PR 이 **꼭 하나**일 때만 다음으로 간다. 없거나 둘 이상이면 「돈다」.
  - P2 `GET /repos/{저장소}/actions/caches?key=<키>&ref=refs/pull/<N>/merge` 의 `actions_caches` 가운데 `key` 가 키와 **글자 그대로** 같고
    `ref` 가 `refs/pull/<N>/merge` 와 글자 그대로 같은 항목이 있을 때만 「건너뛴다」. API 의 `key` 는 앞부분 일치라 서버의 거름에 기대지
    않고 다시 견준다.
  - P3 그 밖은 다 「돈다」 — HTTP 오류 · 연결 실패 · 10초 넘김 · JSON 이 아님 · 칸이 없거나 꼴이 다름. `::warning::` 한 줄을 찍고 끝은 0 이다.
    gate 잡을 떨어뜨리지 않는다(「모르면 돈다」 — `eval.yml` 49 ~ 50 줄의 원칙 그대로).
  - P4 「건너뛴다」면 `$GITHUB_OUTPUT` 에 `hit=true` · `pr=<N>` · `created=<캐시의 created_at>` 를, 아니면 `hit=false` 와 까닭 한 줄을 적는다.
  - P5 판정은 캐시를 읽기만 한다 — 지우거나 적지 않는다. 적는 것은 워크플로의 「`main` 에도 적는다」다(W3).
  - P6 키는 gate 잡이 이미 낸 `eval-key.py route` 의 값을 인자로 받는다 — 판정이 지문을 다시 내지 않는다.
- **읽어 보기** (`eval-merged-pass.py --probe`, PR 실행에서)
  - R1 그 PR 의 head sha 로 P1 의 API 를, 그 PR 의 merge ref 로 P2 의 API(`key=eval-route-`)를 읽고 응답의 꼴과 개수를 찍는다. 판정에
    쓰지 않는다 — `fresh` 에 들지 않는다. 실패는 `::warning::` 이고 끝은 0 이다. 머지 전에 권한 · 응답의 꼴을 PR 의 로그에서 본다.
- **워크플로** (`eval.yml`)
  - W1 gate 잡의 `permissions` 가 `contents: read` · `actions: read` · `pull-requests: read` 다. 다른 잡은 그대로다.
  - W2 「머지된 PR 이 통과했는가」는 `push` 이고 자격이 있고 `main` 범위 캐시에서 못 찾았을 때만 돈다. `pull_request` · `workflow_dispatch`
    에서는 돌지 않는다.
  - W3 「건너뛴다」면 `.eval-pass/run.txt` 에 근거(PR 번호 · 그 merge ref · 캐시가 적힌 때 · 이 실행)를 쓰고 `actions/cache/save` 로 같은
    키를 `main` 범위에 적는다. 다음 PR 들은 `main` 범위에서 읽는다.
  - W4 `fresh` 는 `main` 범위에서 찾았거나 W2 가 「건너뛴다」일 때 false 다. 「건너뛰는 근거」는 둘 다에서 `run.txt` 를 찍는다.
  - W5 이 조각의 `eval.yml` 고침은 B 의 첫 머리 하나다. B 의 다음 머리 · 닫는 PR 은 `eval.yml` 을 고치지 않는다.
- **시험**
  - T1 `test-eval-merged-pass.py` 가 가짜 API 로 ③ 의 꼴 열둘을 세운다 — 「건너뛴다」는 H1 하나, 나머지는 「돈다」. `--probe` 는 정상 ·
    403 둘 다 끝이 0 이다.
  - T2 `bite-eval-merged-pass.py` 가 판정을 한 자리씩 망가뜨린 사본 여섯(⑤)에 자체 시험을 대어 다 떨어진다. 망가뜨릴 자리가 판정에 꼭 한 번
    있지 않으면 떨어진다.
  - T3 새 파일 셋이 `eval-key.py route --list` · `full --list` 에 없다.

**보장하지 않는 것(알려진 한계)**

- **CLI 판이 PR 과 머지 사이에 오르면** — 키에 CLI 판이 들어 `main` 의 키가 다르다. 지금처럼 `main` 에서 돈다(하지 않을 일 3).
- **PR 이 아닌 `main` 푸시** — 직접 푸시 · PR 여럿을 한 번에 담은 푸시 · 푸시 sha 가 PR 의 `merge_commit_sha` 가 아닌 머지 방식은 P1 에서
  「돈다」. 이 저장소는 merge commit 으로 머지한다.
- **머지 사이에 `main` 이 움직였을 때** — PR 의 merge ref 는 그때의 `main` 과 합친 것이다. 키는 내용이라 `main` 의 내용이 다르면 키가 달라
  돈다 — 틀리게 건너뛰지 않는다. 같으면 건너뛴다.
- **PR 범위 캐시가 지워졌을 때** — 7일 안 쓰임 · 저장소 용량 초과로 지워지면 「돈다」. 머지 뒤 몇 분 안이라 겪지 않았다.
- **merge ref 에 적힌 키가 정말 통과했는지** — 그 PR 의 eval 잡이 통과한 실행만 적는다는 것(`eval.yml` 「통과한 입력을 적는다」)에 기댄다.
  그 PR 이 제 워크플로를 고쳐 거짓 키를 적었으면 믿는다 — 그 워크플로는 머지 전 리뷰가 본다(ADR 0021 의 2).
- **API 의 꼴이 바뀌면** — P3 로 「돈다」. 판정이 틀려 건너뛰지는 않는다.
- **`main` 에서 다시 돌리기** — `main` 범위 항목만 지우면 머지된 PR 의 항목으로 다시 건너뛴다. 둘 다 지우거나 `workflow_dispatch`(전수)를
  부른다. `vibe-audit/evals/README.md` 의 문장은 PR 만 말한다(하지 않을 일 5).
- **아직 겪지 않은 가설적 경계 사례** — 예: API 의 페이지가 둘 이상인 응답, 같은 키가 한 ref 에 둘. 겪으면 그 PR 에서 정해 날짜 항목으로
  적는다. 리뷰가 이것을 짚으면 범위 밖이다(조각 6 「닫으며」).

## ③ 받는 입력

닫힌 목록이다. 워크플로 쪽은 2026-10-12 의 `main`(a341e25)에서 뽑았다. API 의 꼴은 착공 세션이 문서를 열지 못해(이 컨테이너에서
`docs.github.com` 이 풀리지 않았다) 알던 대로 적었다 — B 의 R1 이 실물 응답으로 확인하고, 다르면 B 에서 정해 날짜 항목으로 적는다. 이 꼴
밖은 다 「돈다」(P3).

**환경** — `GITHUB_API_URL` · `GITHUB_REPOSITORY` · `GITHUB_SHA` · `GITHUB_REF_NAME` · `GITHUB_OUTPUT`(러너가 준다), `GITHUB_TOKEN`
(스텝의 `env` 가 `${{ github.token }}` 으로 준다). `--probe` 는 `PR_NUMBER` · `PR_HEAD_SHA` 를 스텝의 `env` 에서 받는다. 하나라도
비면 「돈다」(probe 는 경고).

**`GET /repos/{o}/{r}/commits/{sha}/pulls`** — 배열. 읽는 칸: `number`(정수) · `merged_at`(문자열 또는 `null`) · `merge_commit_sha`
(문자열 또는 `null`) · `base.ref`(문자열). 머지 커밋에는 머지된 그 PR 이, 가지의 커밋에는 열린 PR 이 든다.

**`GET /repos/{o}/{r}/actions/caches?key=…&ref=…&per_page=100`** — 객체. 읽는 칸: `actions_caches`(배열) 의 `key` · `ref` ·
`created_at`(문자열). `key` 거름은 앞부분 일치다.

**토큰 권한** — 지금 `eval.yml` 에 `permissions` 가 없어 저장소 기본값을 받는다. W1 이 gate 잡에 셋을 박는다. 캐시 액션은 `GITHUB_TOKEN`
이 아니라 러너의 캐시 토큰을 써 W1 에 기대지 않는다.

**시험의 꼴** — T1 이 세우는 열둘.

| 꼴 | 판정 |
|---|---|
| H1 머지된 PR 하나 · 그 merge ref 에 같은 키 | 건너뛴다 |
| M1 같은 키가 **다른 PR** 의 merge ref 에만 | 돈다 |
| M2 그 merge ref 에 키가 **앞부분만** 같은 항목(`<키>0`) | 돈다 |
| M3 PR 이 머지되지 않았다(`merged_at` null) | 돈다 |
| M4 `merge_commit_sha` 가 푸시 sha 와 다르다 | 돈다 |
| M5 `base.ref` 가 푸시한 가지가 아니다 | 돈다 |
| M6 PR 이 없다(빈 배열) | 돈다 |
| M7 머지된 PR 이 둘 | 돈다 |
| M8 PR API 403 | 돈다 · 경고 |
| M9 캐시 API 500 | 돈다 · 경고 |
| M10 JSON 이 아님 | 돈다 · 경고 |
| M11 칸이 없음(`actions_caches` 없음) | 돈다 · 경고 |

**지금의 셈** — `main` 푸시 51 가운데 eval 잡이 돈 것 19(요구사항 「문제」). route 케이스 열 · 회차 3 — 한 번에 30회.

## ④ 결정

**정한 것** — ADR 0021.

- 1 근거를 찾는 길 — 캐시 목록 API(저자)
- 2 믿는 범위 — 그 푸시를 머지 커밋으로 가진 PR 하나의 merge ref(저자)
- 3 판정의 자리 — 수트 지문 밖 스크립트와 자체 시험 · 변조본, `eval.yml` 은 부르는 줄과 권한만(저자)
- 4 머지 전에 PR 실행에서 API 를 읽어 보기만 한다(세션 제안 · 저자)
- 5 B 의 리뷰가 `eval.yml` 로만 고칠 지적을 내면 수트 한 번을 더 감수하고 「닫으며」에 적는다 — ADR 0020 의 5 와 같다(세션 제안 · 저자)
- 6 `bite-gates.sh` 의 K1 은 넓히지 않는다 — T3 이 한 번 본다(세션 제안 · 저자)
- 7 `vibe-audit/evals/README.md` 의 재실행 문장은 그대로 둔다 — 하지 않을 일 5(세션 제안 · 저자)

**열어 둔 것**

없음 — 갈림길 일곱을 착공에서 정했다.

## ⑤ 검증 계획

명령은 PR 본문에 결과와 함께 적는다. 「어긋내 보기」는 일부러 망가뜨린 작업트리에 같은 명령을 대어 떨어지는지 본 뒤 되돌린다.

**PR A**

- `./scripts/gates.sh` 스물둘 통과 — `verify-docs.py` 가 새 조각 폴더를, `verify-slice-gate.py` 가 착공 PR 에 결정 문서뿐인지를 본다.
- 지문 — `git diff --name-only main...HEAD` 와 `eval-key.py route --list` · `full --list` 의 교집합 0. eval 잡이 건너뛴다.

**PR B**

- `./scripts/gates.sh` 스물넷 통과 — 로컬과 CI gate 잡(성공 기준 6).
- T1 — `python3 scripts/test-eval-merged-pass.py` 가 열두 꼴과 `--probe` 둘을 지나간다(성공 기준 2 · 3).
- T2 — `python3 scripts/bite-eval-merged-pass.py` 가 아래 여섯 사본에서 다 자체 시험을 떨어뜨린다.

  | 망가뜨림 | 지나가 버리는 꼴 |
  |---|---|
  | ref 를 견주지 않는다 | M1 |
  | 키를 앞부분으로 견준다 | M2 |
  | `merged_at` 을 보지 않는다 | M3 |
  | `merge_commit_sha` 를 견주지 않는다 | M4 |
  | PR 이 둘이어도 첫 것을 쓴다 | M7 |
  | API 오류를 「건너뛴다」로 돌린다 | M8 |

- T3 · 성공 기준 4 — 새 파일 셋이 `eval-key.py route --list` · `full --list` 에 없다.
- R1 · W1 — B 의 CI gate 잡 「API 를 읽어 본다」의 로그에 PR 번호와 캐시 항목 개수가 찍히고 경고가 없다(권한 · 응답의 꼴).
- W5 · 지문 — `git diff --name-only main...HEAD` 와 기준 · 머리 각각의 `route --list` ∪ `full --list` 의 교집합이 `.github/workflows/eval.yml`
  하나다. B 의 첫 머리가 route 수트를 한 번 돌리고, 다음 머리는 「같은 입력이 이미 통과했다」로 건너뛴다 — 실행 링크를 PR 본문에 적는다.
- **머지 뒤** — B 의 머지 커밋의 `main` 푸시에서 eval 잡이 Skipped 이고, 「건너뛰는 근거」가 B 의 PR 번호를 찍고, Actions → Caches 의
  `refs/heads/main` 에 그 키가 생긴다(성공 기준 1 · 5). 닫는 기록이 run 번호를 적는다.

**스스로 쓰기** — PR A · B 의 리뷰를 `slice-review` 로 가른다. PR 본문의 `## 리뷰 회차` 와 답글. B 는 `verify-slice-gate.py` 를 CI 에서
지나간다(이 착공이 머지된 뒤).

**단계 5(배포)** — 배포처는 이 저장소의 CI 다. 「배포된 것이 보인다」는 위 「머지 뒤」다. 되돌리는 길은 B 의 머지 커밋을 되돌리는 것이다 —
`eval.yml` 이 바뀌어 그 되돌림의 PR 과 `main` 에서 수트가 돈다(되돌린 `eval.yml` 은 PR 의 통과를 읽지 못한다).

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A 착공 | 요구사항 · 설계 · ADR 0021 · 마스터플랜(「main 푸시가 통과한 수트 지문을 읽게」 `진행`) | 단계 1 · 2 |
| B 판정 | `eval-merged-pass.py` · `test-eval-merged-pass.py` · `bite-eval-merged-pass.py` · `gates.sh` · `eval.yml` · `docs/architecture.md` | ② 의 P1 ~ P6 · R1 · W1 ~ W5 · T1 ~ T3, 성공 기준 1 ~ 6 |

구현은 한 PR 이다 — `eval.yml` 을 고치는 것과 그것이 부르는 스크립트를 가르면 그 사이 `eval.yml` 이 없는 파일을 부르거나, `eval.yml` 을
두 번 고쳐 수트가 두 번 돈다. 조각을 닫는 기록은 B 의 머지 푸시를 본 뒤 따로 낸다(단계 6).
