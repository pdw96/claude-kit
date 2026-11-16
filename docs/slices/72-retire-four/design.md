# 조각 72 설계 — 감사자 넷 은퇴

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | 착공 | 「감사자 넷 은퇴」를 순서 72 · `진행` · 조각 폴더로. 「범위 변경」에 의도 What 의 줄 |
| `docs/slices/72-retire-four/` · `docs/adr/0091-retire-four-auditors.md` | 착공 | 이 요구사항 · 설계 · ADR |
| `vibe-audit/agents/audit-{secrets,quality,contract,ops}.md` | A | 지운다 |
| `vibe-audit/agents/audit-{internal,data}.md` | A | 공통 절에서 은퇴 이름을 뺀다 — 「보지 않는 것」의 넘김 목록 · 「빌드 재현성 … `audit-ops` 의」 · 저장 이름의 보기(`audit-secrets-…`). 두 파일이 글자 단위로 같게 |
| `vibe-audit/.claude-plugin/plugin.json` · `.claude-plugin/marketplace.json` | A | 설명의 감사자 수 · 판 |
| `INTENT.md` | A | What 의 「감사자 여섯」 |
| `vibe-audit/evals/` · `vibe-audit/recall/` | A | ③ 대로. `budget.txt` 스냅숏 |
| `scripts/` — `verify-copy.py`(감사자 수) · `verify-counts.py`(닻 · 원천 — 「감사자 tools」의 원천 파일이 `audit-secrets.md` 다) · `bite-gates.sh` · `sync-agents.sh`(심는 목록 · 안내) · `test-gates.py` · `verify-eval-gate.py` 의 고정 목록 · 이름 | A | 있는 규칙이 맞추라는 값과 대상 줄을 지금 파일에 맞춘다. 규칙은 그대로다 |
| `compare/` | A | 지운 케이스 넷(`gate-root-cause-auth` · `trap-local-dev-password` · `recall-blank-boundary` · `recall-nul-boundary`)의 `fixture.sh` 를 `compare/<케이스>/` 로 옮기고 `cases.tsv` 의 출처 칸을 바꾼다. `arms.tsv` 의 `vibe-audit` 줄은 남는 축(internal · data)만. 러너는 `vibe-audit` 팔에서 줄이 없는 축의 케이스를 건너뛴다 |
| `README.md` · `README.en.md` · `vibe-audit/README.md` · `vibe-audit/evals/README.md` | A · B | A 는 수와 목록(게이트가 무는 몫). B 는 넘길 곳 · 배포 전 체크리스트 · 「무엇이 다른가」의 서술 |
| `docs/procedure.md` · `docs/architecture.md` · `CLAUDE.md` | B | 지도 단계 5 의 맡는 도구(`audit-ops` → `vibe-audit` README 의 배포 전 체크리스트), 시스템 구조의 감사자 줄. `CLAUDE.md` 는 은퇴 이름을 들지 않으면 그대로 |

앵커볼트를 건드린다 — 감사자 이름 · 플러그인 구성 · 공통 절 문구(`CLAUDE.md` 「앵커볼트」). 저자가 정했다(ADR 0091 의 1 · 4). 대장의 모양 · 감사자의 `tools` · 문서의 모양은 그대로다.
부품이 바뀌므로 시스템 구조 문서를 PR B 에서 고친다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것**

- **A 남는 둘은 그대로 일한다** — `audit-internal` · `audit-data` 의 체크 항목 · `tools` · 대장 쓰기가 그대로다. 공통 절은 은퇴 이름을 빼는 만큼만 바뀌고, 두 파일이 글자 단위로 같다(`verify-copy.py`).
- **B 케이스는 ③ 의 갈래대로** — 「옮김」 · 「좁힘」은 그레이더의 뜻을 바꾸지 않는다. 지운 케이스 말고는 실패 조건이 그대로다.
- **C 기록은 그대로** — 하지 않을 일 5.
- **D 되돌릴 수 있다** — 태그 `v-archive-2026-11`(`8b6c81e`)에 은퇴 전 모양이 있다.
- **E 절차가 밖 도구에 기대지 않는다** — 지도 단계 5 는 이 저장소의 README 체크리스트를 맡는 도구로 든다. `/security-review` · `pr-review-toolkit` · `code-review` 는 README 의 안내일 뿐이다(`INTENT.md` Not 3).
- **F 맞대기 재료가 남는다** — 지운 케이스 넷의 픽스처가 `compare/` 에서 그대로 돈다.

**보장하지 않는 것(알려진 한계)**

- **사본 레포의 감사자 여섯은 남는다** — 사본은 심은 커밋(`ddcd21f`) 기준으로 `verify-copies.py` 를 지난다. 다시 심을 때 넷이 남는지 · 지워지는지는 `sync-agents.sh` 가 지우지 않는 한 그 레포의 일이다
  (하지 않을 일 1). 조각 나눔 「걷은 사본의 대장 줄」과 이웃이다.
- **보안 · 계약 · 품질 · 운영의 감사는 이 저장소가 더는 재지 않는다** — 넘길 곳의 도구가 그 일을 하는지는 조각 71 의 측정(데이터 · 계약 축, 보안 축은 재지 않음) 밖이다.
- **「옮김」 케이스가 같은 결함을 찾는지는 CI 수트가 보일 뿐이다** — 태우는 감사자의 담당이 달라 픽스처의 결함을 그 감사자가 보지 않으면 PR A 가 ④ 의 열어 둔 것대로 갈래를 바꾼다.
- **리뷰가 이 밖을 짚으면 범위 밖이다** — 요구사항 하지 않을 일.

## ③ 받는 입력

수트 · 회수율의 케이스 서른셋(`vibe-audit/evals/*/case.yaml` 스물일곱 · `vibe-audit/recall/*/case.yaml` 여섯, `f167a93`)의 닫힌 목록. 태우는 감사자는 `graders/auditor-fired.md` · `route-correct.md` 에서 읽었다.

| 갈래 | 케이스 | 하는 일 |
|---|---|---|
| **지움** (14) | `gate-catches-unproven` · `gate-root-cause-auth` · `route-contract` · `route-ops` · `route-quality` · `route-unasked-auth` · `route-unasked-contract` · `route-unasked-ops` · `route-unasked-secret` · `trap-liveness-probe` · `trap-local-dev-password` · `trap-rollback-unproven` · `recall-blank-boundary` · `recall-nul-boundary` | 은퇴 감사자의 판정 · 뜸을 잰다. 폴더를 지운다(맞대기가 쓰는 넷은 픽스처를 `compare/` 로) |
| **옮김** (7) | `brief-absent` · `brief-audited-commit` · `brief-used` · `cycle-continuity` · `cycle-first` · `gap-unowned` · `gate-out-of-scope` | 공통 절(브리핑 · 회차 · 담당 없음 · 담당 밖 넘김)을 재는데 `audit-secrets` 를 태운다. 태우는 감사자를 남는 둘 가운데 하나로 바꾸고 그레이더의 이름을 맞춘다 |
| **좁힘** (4) | `gate-comment-owned` · `gate-own-not-pushed` · `route-internal` · `route-unasked-data` | 남는 감사자를 태우는데 그레이더가 은퇴 이름을 든다(넘김 목록 · `route-not-quality` · `route-not-contract` · `route-not-secrets`). 은퇴 이름만 빼고, 은퇴 감사자가 뜨지 않음을 보는 그레이더는 지운다 |
| **그대로** (8) | `gate-ddl-lock` · `gate-severity-scale` · `route-quiet` · `trap-slice-scope` · `recall-commit-after-response` · `recall-downgrade-equal-rows` · `recall-expiry-from-processing` · `recall-inactive-code` | 은퇴 이름이 그레이더에 없다. `samples/` 의 글에 은퇴 이름이 있으면 보기 글이라 그대로 둔다 |

이 목록 밖의 케이스는 없다. PR A 를 열 때 케이스가 이 서른셋과 다르면 PR A 를 멈추고 이 표에 날짜 항목을 더한다.

## ④ 결정

**정한 것**

- 은퇴 대상 넷 · 의도 What 을 고친다 — ADR 0091 의 1
- 파일을 지우고 되돌릴 자리는 태그 — ADR 0091 의 2
- 케이스를 지움 · 옮김 · 좁힘 · 그대로로 가른다 — ADR 0091 의 3
- 공통 절 문구를 고친다 — ADR 0091 의 4
- 넘길 곳은 README 의 안내, 운영은 `vibe-audit` README 의 배포 전 체크리스트 — ADR 0091 의 5
- 맞대기 — 지운 케이스의 픽스처를 옮기고 `vibe-audit` 팔은 남는 축만 — ADR 0091 의 6
- 착공을 #257 위에 쌓아 연다 — ADR 0091 의 7
- 의도 고침은 PR A 와 함께 — ADR 0091 의 8

**열어 둔 것**

- 「옮김」 일곱의 태울 감사자(`audit-internal` · `audit-data`)와, 픽스처의 결함이 그 감사자의 담당 밖이면 「지움」으로 바꿀지 — PR A 가 열기 전에 케이스마다 정해 이 설계 끝에 날짜 항목으로 남긴다.
- 배포 전 체크리스트의 항목 — PR B 가 열기 전에 `audit-ops` 의 체크 항목에서 고른다(옮겨 적는 수는 PR B 가 정한다).

## ⑤ 검증 계획

- **PR A** — `./scripts/gates.sh` 가 작업트리와 CI 에서 통과(성공 기준 5). `verify-copy.py` 가 원본 둘의 공통 절이 같다고 PASS. `verify-counts.py` 가 새 닻 · 원천으로 PASS.
  CI 수트(route · full) 통과. `ls vibe-audit/agents/`(성공 기준 2). 케이스 목록과 ③ 의 대조를 PR 본문에 한 줄씩(성공 기준 4). `run-compare.sh none --case 'trap-*' --runs 1` 이 재료로 멈추지
  않는지는 비용이 드니 재료를 엮는 앞부분만 본다 — 인자 · 재료 검사를 지나 「팔 none · 케이스 n」 줄이 찍히는가(성공 기준 6).
- **PR B** — 게이트. 성공 기준 3 의 `git grep` 출력을 PR 본문에.
- 새 검사 · 변조본이 없다 — 지운 케이스 · 그레이더는 떨어지는 장치를 빼는 일이다. 남는 검사가 여전히 무는지는 `gates.sh` 의 변조 시험이 본다.

## ⑥ PR 나눔

| PR | 닫는 것 |
|---|---|
| A — 감사자 · 수트 | 감사자 넷 지움 · 공통 절 · 「여섯」을 박은 스크립트 · 의도 What · ③ · 맞대기 재료 · README 의 수. 게이트가 원자로 맞아야 해 한 PR 이다 — 성공 기준 2 · 4 · 5 · 6 |
| B — 넘길 곳 · 지도 | README 의 넘길 곳과 배포 전 체크리스트 · 「무엇이 다른가」 · 지도 단계 5 · 시스템 구조 — 성공 기준 3 |

## 2026-11-16 · PR A 를 열기 전에 정한 것

④ 의 열어 둔 것(「옮김」 일곱의 태울 감사자와 갈래)과 조각 71 회차 52 의 「담당 없음」 둘(저자 판정 — 이 조각이 받는다)을 정한다.

**옮김 일곱 — 태울 감사자는 `audit-internal`.** 일곱 다 보안 쪽 결함(무인증 `/admin/*` · 박힌 키 · 토큰 로그)을 정답으로 든다. `audit-internal` 은 그 결함을 작업 규칙의 「권한 우회 · 박힌
시크릿 금지」 위반으로 담당한다 — 회차 둘의 픽스처는 그 규칙을 이미 들고, 브리핑 셋은 픽스처 끝에서 같은 규칙을 커밋하지 않은 `CLAUDE.md`(`.git/info/exclude`)로 둔다 — 박아 둔 커밋 SHA
와 브리핑의 「추적 안 된 파일: 없음」을 지키려는 것이다. 그레이더의 뜻은 바꾸지 않았다. 저자가 「옮기고 재 본다」를 골랐다(2026-11-16).

| 케이스 | 갈래 | 근거 |
|---|---|---|
| `brief-absent` · `brief-audited-commit` · `brief-used` | 옮김 | 로컬 수트(`--ablation none --threshold 0.8`, 케이스마다 3 회) 0.917 · 1.000 · 1.000 |
| `cycle-continuity` · `cycle-first` | 옮김 | 같은 수트 1.000 · 1.000 |
| `gap-unowned` | **지움** | 같은 수트 0.487 — 세 회차 다 `gate-escalated-perf` 를 놓쳤다. 성능을 「누구의 담당도 아니다」로 든 줄은 `audit-data` 의 「보지 않는 것」에만 있어 `audit-internal` 을 태우면 근거가 없다 |
| `gate-out-of-scope` | **지움**(재지 않음) | 담당 밖 발견 셋을 `audit-data` · `audit-quality` · `audit-internal` 에 넘기는지 본다 — 남는 둘 가운데 무엇을 태워도 셋 중 하나가 자기 담당이 되어 케이스의 뜻(관문의 왼쪽)이 뒤집힌다. 옮기려면 케이스를 새로 짜야 하고 그것은 새 장치다 |

수트 원값 약 $3.11(`aggregate-result.json` 의 `costUsd` — 브리핑 셋 $1.5543 · 회차 둘 $0.9614 · `gap-unowned` $0.5978), 수트 모델 `claude-sonnet-5-5`, 이 세션의 자격. 그래서 ③ 의 갈래는
지움 16 · 옮김 5 · 좁힘 4 · 그대로 8 이 된다. 수트는 판정 열 · 트리거 셋의 열셋, 회수율은 넷이다.

**좁힘의 음성 그레이더.** `scripts/verify-evals.py` 는 route 케이스마다 `route-not-*` 를 요구한다. 은퇴 감사자를 막던 그레이더를 지운 자리에 남는 감사자를 막는 것을 둔다 —
`route-internal` 의 `route-not-data`, `route-unasked-data` 의 `route-not-internal`. 있는 규칙이 요구하는 대상 줄이다(`CLAUDE.md` 「새 장치는 새어 나간 결함에만」).

**변조 시험의 대상.** `scripts/bite-gates.sh` 가 지운 감사자 · 케이스를 변조하던 자리를 남는 것으로 옮겼다 — 같은 규칙을 계속 물게 하는 고침이다. `sync-agents.sh` 의 T8 핀은 안내 문구의
감사자 수를 고친 커밋 `577810a` 로 옮겼다(시험 주석이 정한 대로).

**회차 52 「담당 없음」 둘(조각 71).**
- (1) 평가셋 항목의 담당이 사라진다 — 이 조각의 감사 회차에 **PR A 머지 전 `audit-quality`**(은퇴 전 마지막 회차 — 지운 케이스 · 그레이더로 무엇을 잃는가)를 더한다. 그 뒤로 평가셋을
  보는 감사자는 없다 — ADR 0091 의 1 의 대가에 이것이 든다.
- (2) NC-39(반박)의 담당을 `audit-internal` 로 옮겼다(대장, PR A).

**PR B 로 넘긴 것.** 감사자 글은 「배포 전 체크리스트(`vibe-audit` README)」를 가리키는데, 그 절은 PR B 가 쓴다 — A 와 B 사이에 그 자리가 빈다.
