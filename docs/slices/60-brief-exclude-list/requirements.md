# 조각 60 — `/audit-brief` 커맨드의 제외 목록 (2026-11-09 착공)

요구사항이다 — **무엇을 · 왜.** 어떻게 · 경계는 같은 폴더의 `design.md`, 대안이 있던 결정은 ADR 0079.

이 조각을 「다음 조각」으로 적은 닫힌 조각은 조각 59(같은 목록의 경계)다 — 그 `## 닫으며 (2026-11-09)` 를 읽었다. 넘겨받은 것은 설계 ③ A 의 가름(이 쌍은 「안」 — 무엇을 diff 에서
빼는지 정하는 설정)과 회차 40 의 NC-43 · NC-44 · NC-45(고침 — 다음 `audit-internal` 회차의 재감사를 기다린다)다. 의존은 `—` 다. 저자가 이 착공 세션에서 갈래 셋을 정했다 — 셋 다
세션이 추천한 쪽이다(ADR 0079 의 1 ~ 3). 착공은 `main`(`7a15be0`) 위에서 연다. 이 착공 세션의 클론은 얕지 않았다(`git rev-parse --is-shallow-repository` → `false`).

## 문제

**`/audit-brief` 가 diff 에서 뺄 경로가 두 자리에 있고, 한쪽만 고쳐질 수 있다.** 커맨드 본문(`vibe-audit/commands/audit-brief.md:36-37`)이 브리핑 · 기록 작업본의 세 경로를 pathspec 으로
적고, 검사기 `vibe-audit/scripts/verify-brief.py:44` 의 `DEFAULT_EXCLUDE` 가 같은 세 경로를 든다. 규칙 「같은 목록은 한 자리에 둔다」(`CLAUDE.md` 「작업 방식」, ADR 0073 의 5)를 어긴 채
남은 쌍이다 — 조각 59 설계 ③ A 가 「안」으로 갈랐다.

- **갈려도 말이 없다** — 커맨드가 덜 빼면 브리핑에 작업본이 담기고, 더 빼면 변경이 빠진다. `verify-brief.py` 가 git 과 견줘 잡는 것은 갈린 경로에 git 이 보는 파일이 있을 때뿐이다. 커맨드는 세
  자리를 `.gitignore` 에 두라고 알리고, 그렇게 둔 레포에서는 갈린 경로의 작업본이 어느 git 출력에도 나오지 않는다.
- **첫 자리는 이미 정해져 있다** — `DEFAULT_EXCLUDE` 는 이미 `scripts/verify-counts.py` 가 읽는 첫 자리다(ADR 0074 의 2). 커맨드만 따로 적는다.
- **pathspec 의 꼴도 다르다** — 검사기는 다 `:(top,literal,exclude)` 로, 커맨드는 기본 셋을 `:(top,exclude)` 로 뺀다. 지금의 세 경로에서는 같은 집합이다.

## 핵심 사용자와 시나리오

- 사용자: 레포에 `vibe-audit` 를 깔고(플러그인이나 사본) PR 범위를 감사하려는 사람과, 그 사람의 세션.
- 시나리오: `/audit-brief origin/main audit-secrets` 를 부른다 → 세션이 기준을 굳히고 검사기(`verify-brief.py`)의 자리를 찾는다 → 그 파일의 `DEFAULT_EXCLUDE` 를 읽어 경로마다
  `':(top,literal,exclude)<경로>'` 를 만들고, 레포가 따로 둔 대장이 있으면 덧붙인다 → 그 pathspec 으로 diff · 추적 안 된 파일을 모아 브리핑을 쓴다 → 같은 검사기로 git 과 견줘 PASS 를 본다
  → 감사자를 부른다. 검사기를 못 찾으면 모으기 전에 멈추고 설치가 깨졌다고 알린다. 나중에 누가 작업본 자리를 바꾸면 `DEFAULT_EXCLUDE` 한 줄만 고치면 된다 — 커맨드 글은 그대로다.

## 성공 기준

1. **결정이 기록된다** — 착공 PR 이 ADR 0079 를 더하고, 그 ADR 이 1 ~ 3 을 이 착공 세션의 저자가 정한 것으로 든다.
2. **두 벌이 없다** — PR A 뒤 `grep -c 'exclude)\.claude' vibe-audit/commands/audit-brief.md` 가 0 이고, 커맨드 둘째 단계가 `DEFAULT_EXCLUDE` 와 `:(top,literal,exclude)` 를 든다.
3. **브리핑이 선다** — PR A 의 세션이 고친 커맨드를 글자대로 따라 이 저장소에서 브리핑을 만들고(기준 `main`, 따로 둔 대장 `docs/audit` 를 `--exclude` 로), `verify-brief.py` 가 PASS 다. 이
   저장소는 `.claude/` 의 작업본을 무시하지 않으므로, 브리핑 자신(`.claude/audit-brief.md`)이 빠지지 않으면 FAIL 이다 — PASS 가 `DEFAULT_EXCLUDE` 를 읽어 뺐다는 증거다. PR A 본문에 만든
   pathspec 과 검사 줄을 든다.
4. **못 찾으면 멈춘다** — PR A 뒤 커맨드가 검사기를 찾는 일을 모으기(둘째 단계) 앞에 두고, 못 찾으면 멈추고 알린다고 말한다. 「검사기를 못 찾으면 `검사:` 에 적고 감사자에게 알린다」는 줄이
   없다.
5. **장치가 늘지 않는다** — `git diff --stat 7a15be0 <각 머지> -- scripts .github vibe-slice compare vibe-audit ':!vibe-audit/commands/audit-brief.md' ':!vibe-audit/.claude-plugin/plugin.json'
   ':!vibe-audit/evals/budget.txt'` 가 빈 출력이다 — 예산 스냅숏은 커맨드 본문의 글자 수가 바뀌어 함께 움직인다. `vibe-audit` 판이 0.4.9 다.
6. **게이트** — `./scripts/gates.sh` 가 이 조각의 PR 마다 작업트리와 CI gate 잡에서 통과하고, PR A 의 CI eval 잡(수트 지문이 움직여 route 수트가 돈다)이 초록이다.
7. **감사 회차** — 닫기 전 감사 회차를 돌려 `docs/audit/` 의 대장에 등록했다.

## 하지 않을 일

1. **검사기 · 시험을 고치지 않는다** — `verify-brief.py`(옵션을 더하지 않는다) · `scripts/test-verify-brief.py` 의 `SPEC` · `scripts/verify-counts.py` 가 그대로다(ADR 0079 의 2 · 5).
2. **견주는 시험이나 예외를 세우지 않는다** — 새 실패 조건이 없고, `CLAUDE.md` 의 예외 줄이 그대로다(ADR 0079 의 1).
3. **사본을 다시 심지 않는다** — `copies.json` 과 사본 레포가 그대로다. 사본 레포는 다음 다시 심기까지 옛 커맨드를 읽는다.
4. **커맨드가 만드는 자리의 이름을 돌리지 않는다** — 브리핑(`.claude/audit-brief.md`) · 기록(`.claude/audits/`) · 옮긴 브리핑(`.claude/briefs/`)을 적은 줄은 그대로다(ADR 0079 의 6).
5. **커맨드의 다른 일을 고치지 않는다** — 인자 · 기준 굳히기 · 모으는 명령 · 브리핑 모양 · 자르기 · 남기는 것은 그대로다. 감사자 · 공통 절 · 평가 케이스도 그대로다.
6. **조각 나눔의 다른 줄을 다루지 않는다** — 「넘긴 일이 받지 않는 꼴」 · 「ADR 을 좁힐 때의 대체 문턱」 · 「상시 회차의 문턱」 · 「닫는 PR 의 글을 보는 회차」 등.

## 제약

- 스택: 마크다운(커맨드 본문) · JSON(판 한 자리). 스크립트를 고치지 않는다.
- 원본: `main` `7a15be0`.
- 비용: 측정 **$0**. PR A 가 `vibe-audit/` 를 고쳐 수트 지문(`scripts/eval-key.py`)이 움직이므로 그 CI 가 route 수트를 한 번 돈다(구독 사용량). 변조 시험 지문(`scripts/gate-key.py`)도 움직여
  gate 잡이 변조 시험을 돈다. 커맨드 본문을 쓰는 평가 케이스가 없어 전수(workflow_dispatch)는 돌리지 않는다.
- 글자 예산: 커맨드 본문은 호출 시 예산에 든다(`vibe-audit/evals/budget.txt` 의 `audit-brief` 4491, 천장 11100). 상시 몫(설명)은 고치지 않는다.
- 기간: 닫기까지 **사흘**(2026-11-12 까지).
- 리뷰: 착공 PR 도 구현 PR 도 스킬 `slice-review` 로 가른다. PR 마다 **3라운드**를 넘기면 소유자가 판정한다.
- 감사 회차: 닫기 전 — `audit-internal`(대장이 이 조각에 기대는 것 — NC-43 · NC-44 · NC-45 가 고침으로 다음 `audit-internal` 회차를 기다린다. 바뀌는 것 — 커맨드가 규칙 5 를 지키는가:
  고친 커맨드 본문에 `DEFAULT_EXCLUDE` 와 같은 목록의 둘째 자리가 남지 않았는가, 커맨드 · ADR 0079 · 설계 ③ 이 같은 말을 하는가). `audit-quality` 는 고르지 않는다 — 검사 · 변조본 · 평가셋이
  바뀌지 않는다. `audit-contract` 도 고르지 않는다 — 커맨드의 인자 · 브리핑 모양이 그대로다. 새 장치의 꼴을 더하거나 고치지 않아 상시 회차도 걸리지 않는다(ADR 0079 의 7).
