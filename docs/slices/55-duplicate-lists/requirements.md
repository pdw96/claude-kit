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
