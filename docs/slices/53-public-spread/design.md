# 조각 53 설계 — 공개 확산

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `INTENT.md` | A | Why 에 밖 사용자의 문단 · What 에 「밖 사용자의 입구」 줄 · Not 5(ADR 0072 의 1) |
| `docs/master-plan.md` | A · 닫기 | 조각 나눔 — 「공개 확산」을 순서 53 · `진행` 으로 · 조각 폴더. 「범위 변경」 2026-11-03 줄. 닫기에서 `닫힘` · 다음 조각 |
| `docs/slices/53-public-spread/` · `docs/adr/0072-public-spread.md` | A | 이 요구사항 · 설계 · ADR |
| `README.en.md` | B | 새 파일 — 영어 입구(② A ~ D, ③ A) |
| `README.md` | B | 첫 문단 위 한 줄(`README.en.md` 로) · 「무엇이 다른가」의 「한계」에 사실 둘(ADR 0072 의 6) |
| `scripts/verify-counts.py` | B | `ANCHORS` 에 `README.en.md` 의 닻(② E). 원천 · 명사 목록 · 규칙은 그대로 |
| `docs/procedure.md` | B | 「살아 있는 문서와 기록」의 살아 있는 문서 칸에 `README.en.md` |
| `CHECKLIST.md` | B | 「항상」에 한 줄 — `README.md` 를 고치면 `README.en.md` 를 함께 |
| `docs/audit/` | 닫기 | 닫기 전 감사 회차의 기록 · 브리핑 · 대장 등록 |

앵커볼트 가운데 「의도의 모양」은 절 제목이 그대로다 — `INTENT.md` 는 세 절 안의 글만 더한다. 이름 · 감사자의 `tools` · 공통 절 · 대장 둘의 모양 · 절 제목 · 고정 영역은 건드리지 않는다.
`vibe-audit/` · `vibe-slice/` · `.claude-plugin/` · `scripts/run-evals.sh` 를 고치지 않아 수트 지문 · 글자 예산 · 사본 · 판이 그대로다. `README.md` · `README.en.md` 는 수트 지문에 들지 않는다
(`eval-key.py` 의 `SKIP` 이 이름이 `README.md` 인 파일만 빼지만, `README.en.md` 는 `vibe-audit/` 밖이라 애초에 지문에 들지 않는다). `docs/procedure.md` 를 고쳐도 플러그인의 지도 고정
(`verify-map-pin.py`)은 그대로다 — 그 검사는 `vibe-slice/` 를 마지막으로 고친 커밋의 지도를 보고, 이 조각은 `vibe-slice/` 를 고치지 않는다. `CLAUDE.md` 는 그대로다 — 「가변」의 「README
서술」이 두 벌을 다 든다. 시스템 구조(`docs/architecture.md`)는 그대로다 — 부품 · 경계 · 흐름이 바뀌지 않는다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것**

- **A · 입구** — `README.md` 의 첫 문단 위 한 줄이 `README.en.md` 로 가고, `README.en.md` 맨 위 한 줄이 `README.md` 로 돌아간다. `README.en.md` 는 ③ A 의 절을 그 차례로 든다.
- **B · 주장은 옮김이다** — `README.en.md` 「What's different」의 주장 · 표 · 같았던 축 · 한계는 `README.md` 「무엇이 다른가」의 옮김이다. 숫자가 같고, 원문보다 강한 낱말을 쓰지 않는다 — 특히
  `trap-local-dev-password` 를 「로컬 전용이라 결함이 아니라고 판단했다」로 쓰지 않는다(회차 29 OB-29). `claude-security` 는 같았던 축에서만 든다(ADR 0069 의 2).
- **C · 한계는 두 벌 다** — 사실 둘(ADR 0072 의 6)이 두 README 의 「한계」에 같은 뜻으로 있다. `README.en.md` 는 언어의 한계(도구 · 출력은 한국어, 영어 요청에서 뜨는지 재지 않음)를 설치보다
  앞에 든다.
- **D · 설치 명령은 도는 글이다** — `README.en.md` 의 설치 블록은 ① 마켓플레이스의 명령 셋과 판 받기 두 줄이다. B 가 빈 HOME 에서 글자 그대로 돌려 두 플러그인이 그때의 판으로
  깔리는 것을 본다(⑤ 「설치」).
- **E · 수는 닻에 물린다** — `README.en.md` 가 원천이 있는 수를 아라비아 숫자로 쓰고, 그 수마다 `verify-counts.py` 의 `ANCHORS` 에 줄이 있다 — 원천은 지금 `SOURCES` 의 이름 그대로다
  (③ B). 원천이 측정 · 지난 일인 수(맞힘 · 원값 · 날짜)는 닻에 들지 않는다 — `README.md` 와 같다.
- **F · 두 벌의 규칙** — `docs/procedure.md` 「살아 있는 문서와 기록」과 `CHECKLIST.md` 「항상」이 `README.en.md` 를 든다.
- **G · 도구는 그대로** — `vibe-audit/` · `vibe-slice/` · `.claude-plugin/` 의 diff 가 빈다.

**보장하지 않는 것(알려진 한계)**

- **번역이 맞는지는 무는 것이 없다** — 숫자는 닻이 물고, 문장의 뜻은 사람이 본다(PR B 본문의 대응표 · 리뷰 · 닫기 전 `audit-internal`).
- **영어 요청에서 감사자가 뜨는지 · 영어 저장소에서 같은 판정이 나오는지** — 재지 않는다. README 가 그렇다고 적는다.
- **두 벌이 갈리지 않는다는 보장** — `CHECKLIST.md` 의 줄과 닻뿐이다. 수가 아닌 문장의 갈림은 키 없이 떨어지지 않는다.
- **설치가 늘 선다는 보장** — ⑤ 「설치」는 그날 · 그 CLI 판에서 한 번 본 것이다. 업스트림의 마켓플레이스 동작이 바뀌면 README 가 말없이 낡는다 — 마스터플랜 「배포 경로 다시 재기」의 일이다.
- **밖에서 찾아오는지** — 저장소 설정 · 디렉터리 제출이 없으니 이 조각은 「찾아온 사람이 읽고 깔 수 있다」까지만 진다.

## ③ 받는 입력

**A · 영어 README 의 절 — 닫힌 목록.** 원천은 `README.md` 의 절이다. 그 밖의 절은 옮기지 않는다.

| 차례 | 절(영어) | 원천 | 옮기는 정도 |
|---|---|---|---|
| 1 | 머리 — 무엇인가 · 한국어 README 로 가는 줄 | 머리 문단 | 밖 사람에게 맞춰 다시 쓴다 — 「원본과 이력이 사는 곳」 대신 무엇을 받는가 |
| 2 | 들어 있는 것 | 「들어 있는 것」 | `vibe-audit` 는 감사자 여섯을 하나씩, `vibe-slice` 는 한국어 절차에 묶인 문서 틀로 한 단락(ADR 0072 의 4) |
| 3 | 언어 | 없음 — 새 절 | 도구 · 출력은 한국어 · 영어 요청의 트리거는 재지 않음(② C) |
| 4 | 무엇이 다른가 | 「무엇이 다른가 — 다른 플러그인과 맞대기」 | 주장 · 표 · 같았던 축 · 한계를 다(② B · C) |
| 5 | 설치 | 「설치 — 경로가 셋인 이유」 ① · ② | ① 의 명령과 판 받기, ② 는 한 문장, ③ · 버그 표는 한국어 README 로 가리킨다(ADR 0072 의 8) |
| 6 | 쓰는 법 | 「① 로컬 대화형 세션」의 호출 이름 · `vibe-audit/README.md` 「대략의 주기」 | 스코프가 붙은 호출 이름과 「무엇을 바꿨을 때 어느 감사자」 표 |
| 7 | 가리키는 곳 | 「가리키는 곳」 | 줄마다 「(Korean)」을 단다 |

**B · 닻이 물 원천 — 지금 `SOURCES` 의 이름에서.** 새 원천을 더하지 않는다.

- `감사자` — 감사자 수(지금 6)
- `틀` — `vibe-slice` 의 문서 틀 수(지금 6), `README.en.md` 가 그 수를 적을 때만

**C · 숫자의 원천 — 측정.** `README.md` 「무엇이 다른가」의 숫자와 그 원문인 `docs/eval-log/2026-11.md` 의 세 항목 — 「다른 플러그인과 맞대기 — 조각 51 PR C」 · 「`claude-security` 다시 재기
— 조각 52 PR C」 · 「`pr-review-toolkit` 의 빈 칸 — 조각 52 PR C」. 사실 둘(ADR 0072 의 6)의 원문은 회차 29 OB-28 · OB-29 가 가리킨 자리다.

## ④ 결정

**정한 것**

- 밖 사용자를 들이는 법 · 영어 범위 · 자리 · 앞세울 것 · 두 벌의 주인과 수 · 감사 기록의 문구 둘 · 설치 확인 · 보일 설치 경로 — ADR 0072 의 1 ~ 8.
- PR 나눔 — ⑥.

**열어 둔 것**

- **닻의 꼴** — `README.en.md` 의 문장이 서야 `ANCHORS` 의 꼴(`{N}` 앞뒤 글)이 정해진다. PR B 가 정해 설계 끝 날짜 항목에 남긴다. 영어 수 낱말을 쓰게 되면 그 자리는 아라비아 숫자로
  고쳐 쓴다 — 검사의 L 을 넓히지 않는다(요구사항 하지 않을 일 7).

## ⑤ 검증 계획

- **설치(PR B, 비용 0)** — 새 빈 HOME(`env -i` · 프록시와 CA 변수만)에서 `README.en.md` 의 설치 블록을 글자 그대로 돌리고 `claude plugin list` 의 출력을 PR B 본문에 싣는다 — 두 플러그인이
  `enabled` 이고 판이 그때 `plugin.json` 의 판이다. CLI 판을 함께 적는다.
- **주장의 대응(PR B)** — `README.en.md` 「What's different」의 숫자마다 `README.md` 의 자리 · `docs/eval-log/2026-11.md` 의 칸을 대는 표를 PR B 본문에 싣는다. 사실 둘은 회차 29 기록의 자리를
  댄다.
- **닻이 무는가(PR B)** — 인자 없는 `python3 scripts/verify-counts.py` 가 PASS 이고, `README.en.md` 의 닻 수를 하나 바꾼 사본 트리에서 `verify-counts.py <루트>` 가 D1 로, 그 문장을 지운
  사본에서 D2 로 떨어지는 것을 PR B 본문에 보인다. 새 변조본은 더하지 않는다 — D1 · D2 의 변조본은 `bite-gates.sh` 의 그 검사 절에 이미 있다.
- **도구 · 수트** — 각 PR 에서 `git diff --stat 737448c HEAD -- vibe-audit vibe-slice .claude-plugin scripts/run-evals.sh` 가 비고 `python3 scripts/eval-key.py route` · `full` 이 `main` 과 같은
  값을 찍는 것을 PR 본문에 보인다.
- **문서 검사** — 각 PR 에서 `verify-docs.py` · `verify-slice-gate.py` · `verify-ledger.py` · `verify-map-pin.py` 가 PASS 다(`gates.sh` 가 부른다).
- **게이트** — 각 PR 의 작업트리와 CI gate 잡에서 `./scripts/gates.sh` 가 통과한다.

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A | `INTENT.md` · 마스터플랜 줄과 「범위 변경」 · 이 요구사항 · 설계 · ADR 0072 | 착공 · 성공 기준 1 |
| B | `README.en.md` · `README.md` 의 한 줄과 사실 둘 · `verify-counts.py` 의 닻 · `docs/procedure.md` 의 목록 · `CHECKLIST.md` 의 줄, 「열어 둔 것」의 닻 꼴을 설계 끝 날짜 항목에 | ② A ~ G, 성공 기준 2 ~ 9 |
| 닫기 | 닫기 전 감사 회차의 등록 · 요구사항 끝의 `## 닫으며` · 마스터플랜 53 을 `닫힘` · 다음 조각 | 성공 기준 10 |

구현을 한 PR 로 두는 까닭 — 영어 README · 한국어 README 의 사실 둘 · 닻 · 두 벌의 규칙이 한 덩이라, 나누면 한 PR 에 닻 없는 수나 한 벌만 고친 한계가 머지된다. 측정이 없어 돈을
쓰는 PR 과 리뷰하는 PR 을 가를 까닭도 없다.

## PR B 에서 정한 것 (2026-11-03)

④ 의 열어 둔 것 하나(닻의 꼴)를 정했다.

- **닻의 꼴 둘** — `README.en.md` 의 원천이 있는 수는 둘이다. `('README.en.md', r'{N} read-only auditors', 2, '감사자')` — 머리 문단과 「What's inside」 표의 두 자리,
  `('README.en.md', r'{N} document templates', 1, '틀')` — `vibe-slice` 단락. 영어 수 낱말을 쓴 자리는 없다. 원천 · 명사 목록 · 규칙은 그대로다.
- **원천이 있는 수로 세지 않은 것** — 함정 표의 맞힘 · 같았던 축의 17/18 · 「two trap cases · 6 runs」 · 회차당 원값 · 날짜 · 커밋은 측정 · 지난 일이라 닻에 들지 않는다(② E). 「three or four
  slices」(「대략의 주기」의 옮김)는 원천이 없는 서술이다.
