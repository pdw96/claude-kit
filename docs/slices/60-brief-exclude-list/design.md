# 조각 60 설계 — `/audit-brief` 커맨드의 제외 목록

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | 착공 · 닫기 | 조각 나눔 — 「`/audit-brief` 커맨드의 제외 목록」을 순서 60 · `진행` 으로 · 조각 폴더. 닫기에서 `닫힘` · 다음 조각 |
| `docs/slices/60-brief-exclude-list/` · `docs/adr/0079-brief-exclude-list.md` | 착공 | 이 요구사항 · 설계 · ADR |
| `vibe-audit/commands/audit-brief.md` | A | (가) 검사기를 찾는 일을 둘째 단계 앞에 둔다 — 사본 `.claude/scripts/verify-brief.py`, 플러그인이면 플러그인 폴더의 `scripts/verify-brief.py`. 못 찾으면 멈추고 알린다. (나) 둘째 단계의 세 pathspec 을 지우고 「`-- ':/'` 뒤에 그 파일의 `DEFAULT_EXCLUDE` 경로마다 `':(top,literal,exclude)<경로>'`」를 적는다 — 레포가 따로 둔 대장의 줄은 그대로. (다) 셋째 단계 끝의 검사기 자리 안내를 (가)를 가리키게 줄이고, 「검사기를 못 찾으면 `검사:` 에 적고 감사자에게 알린다」를 「돌리지 못하면(파이썬이 없는 따위) `검사:` 에 까닭을 적고 감사자에게 알린다」로 |
| `vibe-audit/.claude-plugin/plugin.json` | A | 판 0.4.8 → 0.4.9 |
| `vibe-audit/evals/budget.txt` | A | 예산 스냅숏의 `audit-brief` 줄 — 커맨드 본문의 글자 수가 바뀐 만큼(`scripts/verify-budget.py` 가 맞추라고 하는 대로) |
| `docs/audit/` | 닫기 | 닫기 전 감사 회차의 기록 · 브리핑 · 대장 등록 |

앵커볼트는 건드리지 않는다 — 커맨드 이름(`audit-brief`) · 설명 · 인자, 감사자 파일과 공통 절, 대장의 모양이 그대로다. 「가변」의 「검사가 읽는 글」은 닿지 않는다 — `scripts/verify-counts.py` 는
`DEFAULT_EXCLUDE` 를 읽고 커맨드 본문을 읽지 않는다. 커맨드 본문은 호출 시 글자 예산에 든다(`scripts/verify-budget.py` 의 `commands/*.md`). 스크립트 · CI · `vibe-slice` 는 그대로다. 시스템
구조(`docs/architecture.md`)는 그대로다 — 부품 · 경계 · 흐름이 바뀌지 않는다. 커맨드가 검사기를 읽는 화살표는 이미 있다(셋째 단계의 대조).

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것**

- **A 한 자리** — `/audit-brief` 가 기본으로 빼는 경로는 `vibe-audit/scripts/verify-brief.py` 의 `DEFAULT_EXCLUDE` 하나가 든다. 커맨드 본문은 그 경로를 글자로 들지 않고 그 상수를 가리킨다.
  `verify-counts.py` 가 같은 상수를 읽는다(ADR 0074 의 2) — 셋이 한 자리를 쓴다.
- **B 같은 꼴** — 커맨드와 검사기가 같은 pathspec 마법(`:(top,literal,exclude)`)으로 뺀다. 상수에 어떤 경로가 와도 두 쪽이 같은 집합을 뺀다.
- **C 못 찾으면 모으지 않는다** — 검사기를 못 찾으면 커맨드는 diff 를 모으기 전에 멈추고 알린다. 제외 목록 없이 모은 브리핑은 나오지 않는다.
- **D 커맨드의 다른 일은 그대로** — 인자 · 기준 굳히기 · 모으는 명령과 깃발 · 따로 둔 대장을 빼는 줄 · 브리핑 모양 · 자르기 · 대조 · 남기는 것이 착공 `7a15be0` 과 같은 말을 한다.
- **E 장치가 늘지 않는다** — 요구사항 성공 기준 5.

**보장하지 않는 것(알려진 한계)**

- **모델이 상수를 읽는 걸음** — 커맨드는 모델이 따르는 글이다. 상수를 잘못 읽은 브리핑을 잡는 것은 지금과 같은 `verify-brief.py` 대조뿐이고, 갈린 경로에 git 이 보는 파일이 있을 때만 잡힌다.
  커맨드 본문을 쓰는 평가 케이스가 없어 재지 않는다(ADR 0079 의 2 · 대가).
- **커맨드가 만드는 자리와 상수** — 커맨드는 브리핑을 `.claude/audit-brief.md` 에 쓰고 기록 · 옮긴 브리핑을 `.claude/audits/` · `.claude/briefs/` 에 둔다. 그 자리를 옮기는 PR 은
  `DEFAULT_EXCLUDE` 를 함께 고쳐야 하고, 그것을 무는 검사는 없다 — 리뷰가 본다(ADR 0079 의 6).
- **시험의 `SPEC`** — `scripts/test-verify-brief.py:34` 는 커맨드를 흉내 내는 기대값으로 세 경로를 `:(top,exclude)` 로 든다. ADR 0049 의 예외로 적힌 자리이고(ADR 0074 의 맥락), 세 경로에
  와일드카드 글자가 없어 B 의 꼴과 같은 집합이다. 이 조각은 고치지 않는다(하지 않을 일 1).
- **사본 레포** — 다음 다시 심기까지 옛 커맨드(세 pathspec 을 적은 꼴)를 읽는다(하지 않을 일 3). 옛 커맨드도 같은 세 경로를 빼서 지금은 결과가 같다.
- **검사기만 없는 설치** — 플러그인과 사본 심기는 만들지 않는 꼴이다. 손으로 커맨드만 옮긴 레포는 C 로 멈춘다 — 대가로 받았다(ADR 0079 의 3).
- **리뷰가 이 밖을 짚으면 범위 밖이다** — 요구사항 하지 않을 일.

## ③ 받는 입력

검사 장치가 아니다 — 커맨드가 읽는 입력과 고칠 자리를 착공 `7a15be0` 에서 뽑아 든다.

**A 커맨드가 읽는 것**

| 입력 | 자리 | 꼴 |
|---|---|---|
| 검사기 | 사본 `.claude/scripts/verify-brief.py` · 플러그인 폴더의 `scripts/verify-brief.py`(커맨드 `:97-99` 가 이미 드는 두 자리) | 파이썬 파일. 맨 위의 대입 한 줄 `DEFAULT_EXCLUDE = (".claude/audits", ".claude/briefs", ".claude/audit-brief.md")`(`:44`) — 빈 경로 없는 문자열의 튜플(`verify-counts.py` 가 같은 꼴을 받는다, ADR 0074 의 3) |
| 따로 둔 대장 | 레포의 `CLAUDE.md` 등이 가리키는 곳(커맨드 `:38`) | 경로 하나 이상. 지금처럼 `':(top,literal,exclude)<경로>'` 로 덧붙이고, 대조할 때 `--exclude <경로>` 로 준다 |

**B 고칠 자리(착공 `7a15be0` 의 `vibe-audit/commands/audit-brief.md`)**

| 줄 | 지금 | PR A 뒤 |
|---|---|---|
| `:24-33` 하나 | 기준을 확인하고 굳힌다 | 그대로. 그 끝이나 둘째 단계 머리에 검사기를 찾는 일 — 못 찾으면 멈춘다 |
| `:35-38` 둘 | 세 pathspec 을 글자로 · 대장은 literal | 상수를 가리키는 한 문장 · 대장 줄 그대로 |
| `:97-100` 셋 끝 | 검사기 자리 두 곳 · 「못 찾으면 `검사:` 에 적고」 | 찾은 검사기로 돌린다 · 「돌리지 못하면 까닭을 적고」 |

이 밖의 줄은 고치지 않는다(② D). 커맨드가 만드는 자리를 적은 줄(`:8` · `:59` · `:109` · `:114` · `:121` · `:124`)은 B 에 들지 않는다(하지 않을 일 4). `:97` 의 대조 명령은 B 의 셋째
자리에 들지만, 그 안의 브리핑 경로는 그대로 둔다.

## ④ 결정

**정한 것**

- 커맨드가 `DEFAULT_EXCLUDE` 를 가리킨다 — 예외 · 견주는 시험이 아니다 — ADR 0079 의 1(저자)
- 커맨드 글이 검사기 파일의 상수를 읽게 한다 — 옵션을 더하지 않는다 — ADR 0079 의 2(저자)
- 검사기를 못 찾으면 멈추고 알린다 — ADR 0079 의 3(저자)
- 기본 셋도 `:(top,literal,exclude)` — ADR 0079 의 4
- 커맨드 본문과 판만 — 검사기 · 시험 · 사본은 그대로 — ADR 0079 의 5
- 커맨드가 만드는 자리의 이름은 그대로 — ADR 0079 의 6
- 감사 회차 `audit-internal` 하나 — ADR 0079 의 7

**열어 둔 것**

없음 — 커맨드의 문장은 PR A 가 쓰고 리뷰가 본다. 문장이 들 것은 ① · ② A ~ D · ③ B 가 닫는다.

## ⑤ 검증 계획

시험을 세우지 않는다 — 커맨드의 글이다. 있는 검사와 손으로 따른 한 번에 대어 본다.

| 보장 | 무엇으로 보이나 |
|---|---|
| A 한 자리 | `grep -c 'exclude)\.claude' vibe-audit/commands/audit-brief.md` → 0, `grep -n DEFAULT_EXCLUDE` 의 줄을 PR A 본문에 |
| B 같은 꼴 | 같은 `grep` 의 `:(top,literal,exclude)` 줄. 손으로 따른 한 번(아래)의 pathspec 이 `verify-brief.py` 의 `pathspec()` 이 내는 것과 같다 |
| C 못 찾으면 모으지 않는다 | 고친 커맨드에서 검사기를 찾는 문장이 둘째 단계 앞에 있고 「멈춘다」를 든다. 「검사기를 못 찾으면 `검사:` 에」 줄이 셋째 단계에 남지 않는다 |
| D 다른 일은 그대로 | `git diff 7a15be0 <A> -- vibe-audit/commands/audit-brief.md` 의 헝크가 ③ B 의 세 자리 안에만 있다 |
| E 늘지 않는다 | 요구사항 성공 기준 5 의 명령 |

- **손으로 따른 한 번(PR A)** — PR A 의 세션이 고친 커맨드를 글자대로 따라 이 저장소에서 브리핑을 만든다 — 기준 `main` · 따로 둔 대장 `docs/audit`. `python3 vibe-audit/scripts/verify-brief.py
  .claude/audit-brief.md --exclude docs/audit` 가 PASS 다. 이 저장소는 `.claude/` 의 작업본을 무시하지 않아, 브리핑 자신이 빠지지 않으면 FAIL 이다. 만든 pathspec 과 PASS 줄을 PR A 본문에
  든다. 브리핑은 커밋하지 않는다(`CLAUDE.md` 「감사 기록은 `docs/audit/` 에 둔다」).
- **예산** — `python3 scripts/verify-budget.py` PASS(호출 시 `audit-brief` 가 천장 안). 스냅숏 `vibe-audit/evals/budget.txt` 를 그 검사대로 맞춘다.
- **게이트** — `./scripts/gates.sh` 를 PR 마다 돌리고 끝 줄을 PR 본문에 든다. PR A 의 CI 는 수트 지문 · 변조 시험 지문이 움직여 route 수트와 변조 시험을 돈다 — 둘 다 초록이어야 한다.

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A | `vibe-audit/commands/audit-brief.md` 의 ③ B 세 자리 · `vibe-audit/.claude-plugin/plugin.json` 판 0.4.9 · 예산 스냅숏이 움직이면 `vibe-audit/evals/budget.txt` | 성공 기준 2 · 3 · 4 · 5 · 6 의 A 몫 |
