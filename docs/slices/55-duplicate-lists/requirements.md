# 조각 55 — 같은 목록의 두 벌 셋 (2026-11-05 착공)

요구사항이다 — **무엇을 · 왜.** 어떻게 · 경계는 같은 폴더의 `design.md`, 대안이 있던 결정은 ADR.

이 조각을 「다음 조각」으로 적은 닫힌 조각은 조각 54(감사자가 거듭 청한 절차 물음)다 — 그 `## 닫으며 (2026-11-05)` 를 읽었다. 넘겨받은 것은 원칙(ADR 0073 의 5)을 세우며 고치지 않은 두 벌
셋과, 감사 회차 32 가 새로 올린 물음(스킬 `slice-review` ↔ 새 단계 3)을 조각 나눔 줄로 둔 것이다. 의존한 그 조각은 `닫힘` 이다. 저자가 이 착공 세션에서 갈래 둘을 정했다 — 둘 다 세션이
추천한 쪽이다(ADR 0074 의 1 · 2). 착공은 `main`(`00c2de5`) 위에서 연다. 이 착공 세션의 클론은 얕지 않았다(`git rev-parse --is-shallow-repository` → `false`).

## 문제

**같은 목록이 두 자리에 있고, 한쪽만 고쳐질 수 있다.** ADR 0073 의 5 는 같은 목록을 저장소 전체에서 한 자리에 두게 했다. 감사 회차가 든 두 벌 셋을 지금 트리에 대어 보면 이렇다.

| 쌍 | 자리 | 지금 | 근거 |
|---|---|---|---|
| 스크립트 | `scripts/verify-counts.py:451` `SCAN_SKIP_LOCAL` ↔ `vibe-audit/scripts/verify-brief.py:44` `DEFAULT_EXCLUDE` | 두 벌. 주석은 「같다」인데 꼴이 벌써 다르다(폴더 끝의 `/`). 견주는 검사가 없다 | 회차 20 OB-2 · 회차 21 `docs/audit/records/audit-internal-2026-10-30-101213.md` |
| 프로필 | 틀 머리 주석 `vibe-slice/skills/slice-docs/templates/profile.md:14` ↔ 스킬 `slice-docs` `SKILL.md:42-43` | 두 벌이고 다르다 — 스킬만 `.gitignore` 의 다른 꼴을 고친다 | 회차 25 OB-27 `audit-internal-2026-11-02-105513.md` |
| 정답지 낱말 | 조각 52 설계 ③ B ↔ `scripts/run-compare.sh` `LEAK` ↔ `compare/README.md` | 한 자리다 — 조각 52 PR D(`de48575`)가 README 의 목록을 지우고 러너를 가리키게 했다. 설계는 기록이다 | 회차 29 `audit-internal-2026-11-03-081932.md` |

- **스크립트 쌍이 이 조각의 몫이다** — `/audit-brief` 의 작업본 자리가 바뀌면 `verify-brief.py` 만 고쳐지고 `verify-counts.py` 는 옛 자리를 뺀 채 새 자리의 작업본을 훑는다. 그러면 로컬
  `gates.sh` 만 U1 로 떨어지고 CI 는 지나간다 — 감사 회차 18 NC-18 이 그 꼴이었다.
- **프로필 쌍은 다른 줄과 부딪힌다** — `vibe-slice/` 를 고치면 `verify-map-pin.py` M5 가 두 스킬의 지도 링크를 지금 지도로 다시 박게 한다(링크의 `86d27cc` 뒤 조각 54 `47f46fd` 가 지도를
  고쳤다). 조각 나눔 「`slice-review` 를 새 단계 3 에 맞추기」는 그 다시 박기보다 먼저다 — 저자가 프로필 쌍을 그 줄로 넘겼다(ADR 0074 의 1).
- **넷째를 지나다 봤다** — `/audit-brief` 커맨드 본문(`vibe-audit/commands/audit-brief.md:36-37`)이 같은 세 경로를 pathspec 으로 적는다. 고치면 `vibe-audit/` 판 · 수트 지문이 움직인다 —
  조각 나눔의 새 줄로 둔다(ADR 0074 의 6).

## 핵심 사용자와 시나리오

- 사용자: `/audit-brief` 의 작업본 자리를 바꾸는 세션 — 이 저장소에서 `vibe-audit` 를 고친다.
- 시나리오: 세션이 `verify-brief.py` 의 `DEFAULT_EXCLUDE` 에 새 작업본 자리를 더하고 커맨드를 함께 고친다 → 그 자리에 브리핑 작업본을 둔 채 `./scripts/gates.sh` 를 돌린다 →
  `verify-counts.py` 가 같은 상수를 읽어 그 자리를 훑지 않는다 — `verify-counts.py` 를 고치지 않아도 로컬과 CI 가 같다. 상수 이름을 바꾸거나 지우면 `verify-counts.py` 가 새 ID 로 떨어져
  세션이 그 자리에서 안다.

## 성공 기준

1. **결정이 기록된다** — 착공 PR 이 ADR 0074 를 더하고, 그 ADR 이 1 · 2 를 저자가 정한 것으로 든다.
2. **스크립트 쌍이 한 자리다** — PR A 뒤 `git grep -nE '\.claude/(audits|briefs|audit-brief)' -- scripts/verify-counts.py` 가 빈다. `verify-counts.py` 가 훑는 트리의
   `vibe-audit/scripts/verify-brief.py` 에서 `DEFAULT_EXCLUDE` 를 읽는다.
3. **고리가 문다** — PR A 뒤 `bite-gates.sh` 의 `verify-counts.py` 절에서 (가) 사본의 `verify-brief.py` 에서 `DEFAULT_EXCLUDE` 대입을 지우면 새 ID 로 떨어지고, (나) 사본의 그 상수에서
   `.claude/audit-brief.md` 를 빼고 그 자리에 같은 원천 문장을 둔 작업본을 심으면 `FAIL [U1] .claude/audit-brief.md` 로 떨어지고, (다) 대조군 셋이 그대로 PASS 줄로 지나간다. 그 절의 끝
   줄이 합 29 · 대조군 3 을 찍는다(착공 전 27 · 3).
4. **프로필 쌍이 넘어간다** — 착공 PR 뒤 조각 나눔 「`slice-review` 를 새 단계 3 에 맞추기」 줄이 프로필 쌍(두 자리와 OB-27)을 든다.
5. **정답지 낱말 쌍이 한 자리다** — 착공 때 `grep -c expected_outcome compare/README.md` → `0`, `grep -c 'LEAK' compare/README.md` → `1`. 닫으며가 같은 명령을 닫는 머리에서 다시 든다.
6. **넷째 쌍이 넘어간다** — 착공 PR 뒤 조각 나눔에 「`/audit-brief` 커맨드의 제외 목록」 줄이 있다.
7. **플러그인 · 수트는 그대로다** — `git diff --stat 00c2de5 <각 머지> -- vibe-audit vibe-slice .claude-plugin` 이 비고, 이 조각의 PR 마다 `eval-key.py route` · `full` 이 `main` 과 같다.
8. **게이트** — `./scripts/gates.sh` 가 이 조각의 PR 마다 작업트리와 CI gate 잡에서 통과한다.
9. **감사 회차** — 닫기 전 감사 회차를 돌려 `docs/audit/` 의 대장에 등록했다.

## 하지 않을 일

1. **프로필 쌍을 고치지 않는다** — `vibe-slice/` 의 틀 · 스킬 · 지도 링크 · 판이 그대로다. 조각 나눔 「`slice-review` 를 새 단계 3 에 맞추기」가 맡는다(ADR 0074 의 1).
2. **`vibe-audit/` 를 고치지 않는다** — `verify-brief.py` · 커맨드 `/audit-brief` · 감사자 · 판 · 수트 지문이 그대로다. 넷째 쌍은 조각 나눔 「`/audit-brief` 커맨드의 제외 목록」이 맡는다
   (ADR 0074 의 6).
3. **정답지 낱말 쌍을 고치지 않는다** — 조각 52 설계 ③ B 는 기록이라 그대로이고, 러너 · `compare/README.md` 는 이미 한 자리다(ADR 0074 의 5).
4. **두 벌을 더 찾지 않는다** — 저장소를 훑어 같은 목록의 다른 두 벌을 찾는 일은 하지 않는다. 넷째는 스크립트 쌍을 보다 지나며 본 것이다.
5. **두 벌을 견주는 검사를 세우지 않는다** — 이 조각은 두 벌을 없앤다. 다른 자리에 두 벌이 생기는지 무는 장치는 두지 않는다.
6. **`verify-counts.py` 의 훑는 길을 바꾸지 않는다** — git 길 · 폴더 길 · git 이 실패할 때 넘어가는 동작(감사 회차 21 NC-23 · 회차 20 OB-1) · `SCAN_SKIP` · 원천 · 닻 · 예외가 그대로다.
   바뀌는 것은 작업본 자리를 어디서 읽나와 그 경로를 맞추는 법뿐이다.
7. **조각 나눔의 다른 줄을 다루지 않는다** — 「새 장치는 새어 나간 결함에만」 · 「걷은 사본의 대장 줄」 · 「배포 경로 다시 재기」 · 「맞대기 다시 재기」.

## 제약

- 스택: python3 표준 라이브러리 · bash. `vibe-audit/` · `vibe-slice/` 를 고치지 않는다.
- 원본: `main` `00c2de5`.
- 비용: **$0** — 측정이 없다. `verify-counts.py` 는 `run-evals.sh` 가 부르지 않아 수트 지문 밖이다(그 파일 머리). 게이트 지문은 바뀌어 CI 가 변조 시험을 다시 돈다.
- 기간: 닫기까지 **사흘**(2026-11-08 까지).
- 리뷰: 착공 PR 도 구현 PR 도 스킬 `slice-review` 로 가른다. PR 마다 **3라운드**를 넘기면 소유자가 판정한다.
- 감사 회차: 닫기 전 — `audit-quality`(바뀌는 것 — 검사 `verify-counts.py` 와 그 변조본. 대장이 이 조각에 기대는 것 — NC-30 이 고침으로 다음 `audit-quality` 회차를 기다린다) ·
  `audit-internal`(바뀌는 것 — 조각 나눔과 ADR 0073 의 5 의 첫 적용. 대장이 이 조각에 기대는 것 — NC-37 이 고침으로 다음 `audit-internal` 회차를 기다린다).

## 닫으며 (2026-11-05)

성공 기준 아홉을 아래에 대어 봤다 — **다 미쳤다.** 3 은 닫기 전 감사가 찾은 변조본의 빈 절반(NC-38)을 이 닫는 PR 이 고친 뒤에 미친다. 구현은 설계 ⑥ 의 A 하나다 — 착공 #206(머지
`dfedd06`) · A #207(머지 `7fb0237`). 측정 비용 0, 기간(2026-11-08) 안. 근거는 `docs/procedure.md` 단계 6 대로 명령과 결과의 핵심 줄을 여기 든다.

- **저자가 정한 것(착공 세션):** ADR 0074 의 1 · 2 — 둘 다 세션이 추천한 쪽. 3 ~ 7 은 세션이 정했고 #206 본문 「세션이 정한 것」에 든 채 저자가 머지하라고 했다(2026-11-05)
- **저자가 정한 것(이 닫는 세션):** 넷 다 세션이 추천한 쪽 — NC-38 은 「고침」으로 이 닫는 PR 이 감사 제안 한 줄을 싣는다(ADR 0073 의 2). U-43 은 「측정 뒤에 박혔다」로 확정해
  닫는다. 회차 34 의 「문서에 없어서」(규칙 5 의 「목록」의 경계 · 감사 회차로 넘긴 일을 무엇이 잡는가)는 조각 나눔 새 줄 「같은 목록의 경계」로 둔다. 다음 조각은
  「`slice-review` 를 새 단계 3 에 맞추기」
- **착공 뒤 기록:** `git diff --stat dfedd06 7fb0237 -- docs/slices/55-duplicate-lists docs/adr/0074-duplicate-lists.md` 빈 출력 — #207 은 요구사항 · 설계 · ADR 을 고치지 않았다

| 성공 기준 | 무엇에 대어 봤나 |
|---|---|
| 1. 결정이 기록된다 | `git diff --stat 00c2de5 dfedd06` → `docs/adr/0074-duplicate-lists.md` · `docs/master-plan.md` · 이 폴더의 `design.md` · `requirements.md` 넷(+224 −2). ADR 0074 머리가 「1 · 2 는 저자가 조각 55 의 착공 세션에서 정했다」를 든다 |
| 2. 스크립트 쌍이 한 자리다 | `git grep -nE '\.claude/(audits\|briefs\|audit-brief)' 7fb0237 -- scripts/verify-counts.py` → 빈 출력(종료 1). `git diff --stat dfedd06 7fb0237` → `scripts/bite-gates.sh` · `scripts/verify-counts.py` 둘(+59 −11). 회차 34 항목 17 이 같은 경로 목록이 남은 살아 있는 자리를 커맨드 본문(조각 나눔 줄) · `test-verify-brief.py:34`(ADR 0049 꼴) 둘로 댔다 |
| 3. 고리가 문다 | run 42018377873 gate 잡(`57f546f`) 「verify-counts.py: … 합 29 이 기대한 ID · 종료로 떨어지고, 대조군 3 이 PASS 줄로 지나감」 · 「변조 시험: 절 36 이 다 닫힘」(대장 U-51). 변조본 (나)는 사본의 검사를 사본에 대어 「검사 파일 옆에서 읽기」를 놓쳤고(NC-38), 이 닫는 PR 이 저장소의 검사로 사본을 보게 고쳤다 — 저장소의 검사를 `ROOT / BRIEF` 로 바꾼 작업트리에서 고친 명령은 PASS(그 변조본이 떨어진다), 옛 명령은 `FAIL [U1] .claude/audit-brief.md:1`(놓친다). 고친 머리 `b1c8333` 의 로컬 `gates.sh` 「합 29 … 대조군 3」 |
| 4. 프로필 쌍이 넘어간다 | `docs/master-plan.md:90` 「같은 조각이 프로필 쌍도 맡는다 — 프로필 틀 머리 주석(…`profile.md:14`)과 스킬 `slice-docs` 의 … 줄(`SKILL.md:42-43`)」 |
| 5. 정답지 낱말 쌍이 한 자리다 | 닫는 머리에서 `grep -c expected_outcome compare/README.md` → `0`, `grep -c LEAK compare/README.md` → `1` — 착공 때와 같다 |
| 6. 넷째 쌍이 넘어간다 | `docs/master-plan.md:91` 「`/audit-brief` 커맨드의 제외 목록」 |
| 7. 플러그인 · 수트는 그대로다 | `git diff --stat 00c2de5 7fb0237 -- vibe-audit vibe-slice .claude-plugin` 빈 출력. `eval-key.py route` → `eval-route-cli2.1.318-8fbc43c6e316871042214dd1`, `full` → `eval-full-cli2.1.318-6f595da5b221fee85e0c1d28` — `00c2de5` · `777f6bd` · `57f546f` 에서 같고, CI eval 잡은 두 PR 다 건너뛰었다 |
| 8. 게이트 | 인자 없는 `./scripts/gates.sh` 「스물여덟 다 통과」 종료 0 — `777f6bd`(12분 37초) · `57f546f`(12분 10초) · `b1c8333`(12분 52초). CI gate · verdict 초록 — run 42016514957(#206) · 42018377873(#207) |
| 9. 감사 회차 | 회차 33 `audit-quality`(`docs/audit/records/audit-quality-2026-11-05-114638.md` — NC-38 · U-51, NC-29 · NC-30 닫힘, 등록 `740cce7`) · 회차 34 `audit-internal`(`…/audit-internal-2026-11-05-115617.md` — 통과, NC-37 닫힘, 등록 `6678f32`) |

- **돌린 감사 회차:** 회차 33(`audit-quality`) · 34(`audit-internal`) — 요구사항 「제약」의 줄 그대로
- **넘긴 것:** 프로필 쌍 → 조각 나눔 「`slice-review` 를 새 단계 3 에 맞추기」. 넷째 쌍 → 「`/audit-brief` 커맨드의 제외 목록」. 규칙 5 의 「목록」의 경계와 감사 회차로 넘긴 일 →
  새 줄 「같은 목록의 경계」. 회차 33 OB-1(설계 ⑤ 가 손으로 둔 D 와 ADR 0074 의 4 의 경계를 무는 것이 없다)은 관찰로 남는다
- **다음 조각:** 「`slice-review` 를 새 단계 3 에 맞추기」 — 의존한 「감사자가 거듭 청한 절차 물음」이 닫혀 꺼낼 수 있다. 저자가 골랐다(2026-11-05)
