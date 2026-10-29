# 조각 44 설계 — 감사자 README 의 모호한 수

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A · 닫기 | 조각 나눔 — 「감사자 README 의 모호한 수」를 순서 44 · `진행` 으로 · 조각 폴더. 닫기에서 `닫힘` |
| `docs/slices/44-audit-readme-count/` · `docs/adr/0057-audit-readme-count.md` | A | 이 요구사항 · 설계 · ADR |
| `vibe-audit/README.md` | B | 「이 감사자들은 감사받는가」의 「케이스 스물여섯이 셋을 잽니다.」 → 「케이스 스물여섯이 재는 것은 아래 표입니다.」 |
| `scripts/verify-counts.py` | B | `ANCHORS` 의 닻 하나 — 꼴 `케이스 {N}이 셋을` → `케이스 {N}이 재는 것은`. 파일 · 횟수(1) · 원천(`케이스`)은 그대로 |
| `vibe-audit/.claude-plugin/plugin.json` | B | `vibe-audit` 판 0.4.5 → 0.4.6 — 고친 파일이 문서 하나라 끝자리(조각 40 의 닫는 PR 이 README 고침으로 0.4.4 → 0.4.5 를 올린 것과 같다) |
| `docs/audit/` | 닫기 | 닫기 전 감사 회차의 기록 · 브리핑 · 대장 등록 |

부품 · 경계 · 흐름은 그대로다 — `docs/architecture.md` 를 고치지 않는다. 앵커볼트는 건드리지 않는다 — 이름 · 감사자의 `tools` · 공통 절 · 대장 둘의 모양 · 「…의 칸」
여섯 절 · 고정 영역이 그대로다. `INTENT.md` 는 그대로다. `vibe-slice` 판은 그대로다. `.claude-plugin/marketplace.json` 에는 판 칸이 없다.

**지문.** `vibe-audit/README.md` 는 수트 지문 밖이다(`eval-key.py` 의 빼는 목록 — `bite-gates.sh` 의 `keyed same vibe-audit/README.md`). `plugin.json` 은 수트 지문 안이라
B 에서 route 수트가 한 번 돈다. `verify-counts.py` · `plugin.json` 은 변조 시험 지문(`gate-key.py`) 안이라 B 의 CI 는 변조 시험까지 돈다.

**고치지 않는 것.** `bite-gates.sh` 의 「verify-counts.py」 절 — 대조군 「원천과 문장을 함께 바꾼 사본」은 README 의 `케이스 스물여섯이` 토막을 `케이스 서른하나이` 로
바꾼다. 새 문장에도 그 토막이 그대로 남아 대조군은 고치지 않고 지나간다. 변조본 가운데 이 닻을 쓰는 것은 없다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 다 B 가 싣는다.

- **W 문장** — README 「이 감사자들은 감사받는가」의 표 앞 문장이 케이스 수 하나만 들고, 표가 무엇을 재는지는 표가 든다. 그 문장에 표의 줄을 센 수가 없다.
- **A 닻** — `verify-counts.py` 의 닻 하나가 새 문장의 「스물여섯」을 원천 `케이스`(`vibe-audit/evals/*/case.yaml` 의 폴더 수)와 견준다. 닻의 횟수는 1 이다 — 문장을 옛 꼴로
  되돌리거나 지우면 D2, 수만 틀리면 D1 로 떨어진다. 닻의 수 · 원천의 수는 그대로다.
- **V 판** — `vibe-audit` 0.4.6. 두 플러그인이 `claude plugin validate` 를 지난다(`gates.sh` 의 `checks` 첫 두 줄).
- **G 게이트** — 인자 없는 `gates.sh` 가 「스물여덟 다 통과」. 검사를 더하거나 빼지 않아 `gates.sh` · `test-gates.py` 의 목록과 수 낱말은 그대로다(ADR 0049).

**보장하지 않는 것(알려진 한계)**

- **표 자체가 맞는지** — 표의 두 줄의 「케이스」 칸은 닻이 이미 문다(`판정 케이스` · `트리거 케이스`). 「재는 것」 칸의 글이 케이스와 맞는지는 사람이 본다.
- **README 의 다른 수 낱말** — 뜻으로만 가리는 수(「셋은 요청하지 않아도 뜹니다」 · 「부르지 않은 셋」)는 닻이 없다(조각 42 설계 끝 「닻 없이 둔 것」). 요구사항 하지 않을 일 1.
- **이미 설치한 레포의 README** — 판을 올려도 `claude plugin update` 를 해야 새 README 를 받는다. 클라우드 레인의 사본에는 README 가 가지 않는다.
- **회수율이 README 에 없다** — 회수율은 `vibe-audit/evals/README.md` 「회수율」이 든다. README 의 표에 들이지 않는다(ADR 0057 의 1).

## ③ 받는 입력

없음 — 검사 장치를 세우거나 넓히지 않는다. `verify-counts.py` 가 받는 입력(닻 목록 · 원천)의 모양은 조각 42 설계 ② · ③ 그대로이고, 닻 하나의 꼴 글자만 바뀐다.

## ④ 결정

**정한 것**

| 결정 | ADR |
|---|---|
| 「셋」을 지운다 — 수 없이 아래 표를 가리킨다. 「둘」로 고쳐 닻을 단다 · 표에 회수율 줄을 더해 셋으로 · 「셋」이 무엇인지 밝힌다는 고르지 않았다 | 0057 의 1 |
| 다음에 `vibe-audit` 판을 올리는 조각을 기다리지 않고 이 조각으로 낸다 — 조각 43 의 닫는 세션에서 저자가 골랐다 | 0057 의 2 |
| 판은 끝자리 — 0.4.6 | 0057 의 3 |

새 문장의 글 · 닻의 꼴은 ① 에 적은 그대로다 — 한 가지로 정해 열어 두지 않는다.

**열어 둔 것**

없음 — ① 이 고칠 글자를 다 적었다.

## ⑤ 검증 계획

- V1 **성공 기준 1 · ② W · A** — B 본문에 `python3 scripts/verify-counts.py` 의 PASS 줄(닻 · 원천 수가 `main` 과 같다)과 README 의 새 문장. `grep -n '셋을 잽' vibe-audit/README.md`
  가 아무것도 찍지 않는다.
- V2 **성공 기준 2 · ② A** — 손 재현을 B 본문에: 작업트리 사본에서 (가) 그 문장을 옛 꼴로 되돌림 → `FAIL [D2]` · 종료 1, (나) 「스물여섯」만 「스물일곱」으로 → `FAIL [D1]` ·
  종료 1. `bite-gates.sh` 의 「verify-counts.py」 절이 인자 없는 `gates.sh` 에서 고치지 않은 채 닫힌다(대조군 「원천과 문장을 함께 바꾼 사본」 PASS).
- V3 **성공 기준 3 · ② V** — `plugin.json` 의 판 0.4.6, CI 의 `claude plugin validate` 두 줄.
- V4 **성공 기준 4 · ② G** — 작업트리의 인자 없는 `./scripts/gates.sh` 끝 줄 「스물여덟 다 통과」(B 본문), B 머리의 CI gate 잡(변조 시험까지) · route 수트(`route-*` 10 × 3 회)
  · verdict 가 초록.
- V5 **성공 기준 5** — 닫기 전 `audit-internal` 회차의 기록 · 대장 등록 · `verify-ledger.py` PASS(닫는 PR).

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A(착공) | 요구사항 · 설계 · ADR 0057 · 마스터플랜 | 단계 1 · 2 |
| B | README 한 문장 · 닻 한 줄 · `vibe-audit` 0.4.6 | ② W · A · V · G, 성공 기준 1 ~ 4 |
| 닫기 | 감사 회차 · `## 닫으며` · 마스터플랜 `닫힘` | 성공 기준 5 |

B 를 둘로 나누지 않는다 — 문장과 닻은 따로 가면 그 사이의 `main` 이 D2 로 빨갛고, 판은 같은 PR 이어야 고친 README 가 배포된다(`CHECKLIST.md`).
