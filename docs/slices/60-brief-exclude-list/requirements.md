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

## 닫으며 (2026-11-09)

성공 기준 일곱을 아래에 대어 봤다 — **다 미쳤다.** 구현은 설계 ⑥ 의 A 하나다 — 착공 #222(머지 `d660ab6`) · A #223(머지 `00b4b73`). 측정 비용 0, 기간(2026-11-12) 안.
근거는 `docs/procedure.md` 단계 6 대로 명령과 결과의 핵심 줄을 여기 든다.

- **저자가 정한 것(착공 세션):** ADR 0079 의 1 ~ 3 — 셋 다 세션이 추천한 쪽. 4 ~ 7 은 세션이 정했고 #222 에 실린 채 저자가 머지했다
- **저자가 정한 것(이 닫는 세션):** 넷 다 세션이 추천한 쪽 — 회차 41 의 NC-46 · NC-47 · NC-48 은 「고침」(셋 다 감사 제안)이다. NC-47 은 이 닫는 PR 이 `vibe-audit/evals/README.md` 를 고치고
  `vibe-audit` 판을 0.4.10 으로 올렸다(ADR 0073 의 2). NC-46 · NC-48 은 아래 「바로잡는 것」이 고친다. 「문서에 없어서」 A · B 는 새 줄. 다음 조각은 「ADR 을 좁힐 때의 대체 문턱」
- **착공 뒤 기록:** `git diff --stat d660ab6 00b4b73 -- docs/slices docs/adr docs/master-plan.md` 빈 출력 — #223 은 요구사항 · 설계 · ADR · 마스터플랜을 고치지 않았다. 이 닫는 PR 은 이 절을
  덧붙이고 설계 · ADR 은 고치지 않는다
- **바로잡는 것(착공 기록의 틀림, 회차 41):**
  - NC-48 — 「제약」의 「글자 예산 … 천장 11100」은 틀렸다. 커맨드는 스킬 몫으로 재고 호출 시 천장은 **4500**(`scripts/verify-budget.py:56` `SKILL_ON_INVOKE_MAX`)이다 — 11100 은 감사자 몫
    (`:55`)이다. PR A 의 첫 글은 4600 으로 넘었고, 천장을 올리지 않고(`CLAUDE.md` 「금지」) 새 문장을 줄여 **4499** 로 맞췄다. 여유는 1 자다(회차 41 OB-46)
  - NC-46 — 「문제」와 ADR 0079 맥락의 「커맨드는 세 자리를 `.gitignore` 에 두라고 알린다」는 틀렸다. 알림은 **두 자리**(브리핑 · `.claude/briefs/`, `vibe-audit/commands/audit-brief.md:126-127`)다.
    「갈려도 말이 없다」는 그 둘에만 서고, `.claude/audits` 쪽 갈림은 `verify-brief.py` 대조가 잡는다. 결정(ADR 0079 의 1)은 그대로다 — 둘째 자리가 없어져 갈림 자체가 없다

| 성공 기준 | 무엇에 대어 봤나 |
|---|---|
| 1. 결정이 기록된다 | `git diff --stat 7a15be0 d660ab6` → ADR 0079 · 마스터플랜 · 이 폴더의 `design.md` · `requirements.md` 넷(+227 −1). ADR 0079 머리가 「1 ~ 3 은 저자가 조각 60 의 착공 세션에서 정했다」를 든다 |
| 2. 두 벌이 없다 | `grep -c 'exclude)\.claude' vibe-audit/commands/audit-brief.md` → 0. 둘째 단계 `:39-40` 「`-- ':/'` 와 검사기 `DEFAULT_EXCLUDE` 의 경로마다 `':(top,literal,exclude)<경로>'` 를 붙입니다」. 회차 41 항목 17 적합 |
| 3. 브리핑이 선다 | #223 의 세션이 고친 커맨드를 글자대로 따라 기준 `origin/main`(`d660ab6`) · `--exclude docs/audit` 로 브리핑을 만들었다 — pathspec `-- :/ :(top,literal,exclude).claude/audits :(top,literal,exclude).claude/briefs :(top,literal,exclude).claude/audit-brief.md :(top,literal,exclude)docs/audit`, 그 목록이 `verify-brief.py` 의 `pathspec(DEFAULT_EXCLUDE + ["docs/audit"])` 와 같다. `PASS .claude/audit-brief.md — git 과 파일 · 줄 수가 맞다 (HEAD e25797b55490, 머지 베이스 d660ab6ecf29)`. 대조군 — 빼지 않은 `git ls-files --others --exclude-standard -- ':/'` 는 `.claude/audit-brief.md` 를 냈다. 회차 41 의 브리핑도 같은 커맨드로 만들어 `PASS … (HEAD 00b4b73f8433, 머지 베이스 7a15be0b5e6c)` |
| 4. 못 찾으면 멈춘다 | `audit-brief.md:35-36` 「검사기 `verify-brief.py` 도 찾습니다 — 사본은 `.claude/scripts/`, 플러그인은 그 폴더의 `scripts/` 에 있습니다. **못 찾으면 모으지 말고 멈추고 알리세요** — 뺄 경로가 거기 있습니다」 — 둘째 단계 앞이다. 셋째 단계 끝은 「못 돌리면 `검사:` 에 까닭을 적고」(`:102`)뿐이고 「검사기를 못 찾으면 `검사:` 에」는 없다 |
| 5. 장치가 늘지 않는다 | `git diff --stat 7a15be0 <c> -- scripts .github vibe-slice compare vibe-audit ':!…/audit-brief.md' ':!…/plugin.json' ':!…/budget.txt'` — `d660ab6` · `00b4b73` 에서 빈 출력. A 뒤 판 0.4.9. 이 닫는 PR 은 NC-47 의 판정 고침으로 `vibe-audit/evals/README.md` 와 판(0.4.10)을 고친다 — 판정 고침은 성공 기준에 묶이지 않는다(`docs/procedure.md` 단계 6 위, ADR 0073 의 2). 검사 · 시험 · `gates.sh` · CI 는 이 머리에서도 그대로다 |
| 6. 게이트 | 인자 없는 `./scripts/gates.sh` 「변조 시험: 절 36 이 다 닫힘」 · 「스물여덟 다 통과」 종료 0 — `5e169ba`(#222) · `e25797b`(#223). CI — run 42582601986(#222: gate · verdict 초록, eval 은 수트 지문이 같아 건너뜀) · run 42585169161(#223: gate · eval · verdict 초록 — 수트 지문이 움직여 route 수트가 돌았다). Codex 리뷰 두 PR 다 지적 없음 |
| 7. 감사 회차 | 회차 41 `audit-internal`(`docs/audit/records/audit-internal-2026-11-09-095509.md` — NC-46 · NC-47 · NC-48 낮음, NC-43 · NC-44 · NC-45 해소 → 닫힘, 등록 `cdaee48`) |

- **돌린 감사 회차:** 회차 41(`audit-internal`) — 요구사항 「제약」의 줄 그대로
- **넘긴 것:** 조각 나눔 「목표 한 줄」이 꺼낼 때의 사실이라는 관행이 적힌 데가 없다(회차 41 A) → 새 줄 「조각 나눔 목표 칸의 시점」. 규칙 5 의 경계가 4 회째 판단으로 남는다(회차 41 B) → 새 줄
  「규칙 5 경계의 닫힌 표」 — 조각 59 `## 닫으며` 의 「다음 회차가 같은 꼴을 다시 들면 그때 줄을 둔다」대로
- **다음 조각:** 「ADR 을 좁힐 때의 대체 문턱」 — 의존이 없어 꺼낼 수 있다. 저자가 골랐다(2026-11-09)
