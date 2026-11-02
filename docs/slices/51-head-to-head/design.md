# 조각 51 설계 — 다른 플러그인과 맞대기

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A · 닫기 | 조각 나눔 — 「다른 플러그인과 맞대기」를 순서 51 · `진행` 으로 · 조각 폴더, 그리고 저자가 정한 예정 줄 셋. 닫기에서 `닫힘` |
| `docs/slices/51-head-to-head/` · `docs/adr/0066-head-to-head.md` | A | 이 요구사항 · 설계 · ADR |
| `scripts/run-compare.sh` | B | 맞대기 러너 — 팔 하나를 받아 임시 폴더에 플러그인과 재료를 엮고, 깃발을 박아 하네스를 부르고, 끝에 표를 찍는다(②) |
| `compare/` | B | 재료 열(③ A) · 축마다 프롬프트 하나 · 케이스마다 심판 그레이더 하나 · README 한 장(무엇이고 어떻게 돌리나) |
| `.gitignore` | B | `compare/results/` |
| `CLAUDE.md` | B | 「금지」의 `claude plugin eval` 줄에 맞대기 러너를 더한다(ADR 0066 의 5). 절 제목 · 다른 줄은 그대로 |
| `docs/eval-log/2026-11.md` | C | 세 팔의 측정 · 케이스 × 팔 표 · 축마다 판정 · 비용 |
| `docs/audit/` | 닫기 | 닫기 전 감사 회차의 기록 · 브리핑 · 대장 등록 |

앵커볼트를 건드리지 않는다 — 이름 · 감사자의 `tools` · 공통 절 · 대장 둘의 모양 · 절 제목 · 고정 영역이 그대로다. `vibe-audit/` · `vibe-slice/` · `scripts/run-evals.sh` 를
고치지 않아 수트 지문 · 예산 · 사본이 그대로다 — route 수트가 돌지 않는다(`eval-key.py` 는 `vibe-audit/` 와 러너가 부르는 스크립트만 든다). `INTENT.md` 는 그대로다 — What 의
「eval 수트와 키 없이 도는 게이트」 안이고, Not 3(절차를 다른 플러그인에 기대지 않는다)에 걸리지 않는다 — 다른 플러그인은 재는 대상이지 절차가 맡기는 도구가 아니다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것**

- **A · 같은 재료** — 세 팔이 같은 케이스 열을 같은 픽스처로 돈다. 픽스처는 출처 케이스의 `fixture.sh` 를 러너가 그대로 복사한다 — `compare/` 에 사본을 두지 않는다.
- **B · 같은 요청** — 케이스의 프롬프트는 축(③ A)마다 하나이고 세 팔에 같다. 도구 · 플러그인 · 감사자의 이름을 부르지 않고, 「설치된 리뷰 · 감사 도구가 있으면 써도 된다」만
  든다(ADR 0066 의 2).
- **C · 같은 채점** — 케이스마다 심판 그레이더 하나(`type: llm`)가 최종 응답이 기대 결과의 결함을 「고칠 결함」으로 냈는지만 본다. 꼴(`### NC-` · 표 · 번호)을 묻지 않는다.
  심판 모델은 `run-evals.sh` 와 같다(`sonnet`). 함정 케이스는 「내면 안 되는 것」도 같은 그레이더가 본다(ADR 0066 의 3).
- **D · 같은 세션 모델** — 러너가 `run-evals.sh` 의 수트 모델을 `--model` 로 박는다. 회차가 실제로 돈 모델(세션 · 하위 에이전트)을 트레이스에서 읽어 찍는다.
- **E · 고정한 경쟁 쪽** — 경쟁 팔은 `--from <클론>` 으로 받은 `anthropics/claude-plugins-official` 클론의 `HEAD` 가 `a7ba5b93db0c7c8d17f3f1d25853adca79598a1a` 일
  때만 돈다 — 아니면 하네스를 부르기 전에 종료 2.
- **F · 비용 천장** — 러너가 팔마다 `--max-cost-usd` 를 건다(값은 PR B 가 요구사항 「제약」의 $45 안에서 나눈다). 하네스가 천장에서 멈추면 러너는 그 사실과 돈 회차 수를 찍는다.
- **G · 떴는가** — 팔마다 그 플러그인의 도구가 떴는지를 점수 밖(`arm: with-only` 나 러너의 트레이스 읽기)으로 센다. 판정 표는 「다 센 것」과 「뜬 회차만」을 함께 든다.
- **H · 수트와 갈림** — 러너는 `vibe-audit/evals/` · `vibe-audit/recall/` 의 결과 폴더에 쓰지 않는다. 결과는 `compare/results/<시각>-<팔>/` 에만 남는다.

**보장하지 않는 것 — 알려진 한계**

- **표본이 작다** — 칸마다 3 회차, 축마다 6 ~ 18 회차다. ADR 0066 의 4 의 문턱(2 회차)은 흔들림을 다 거르지 못한다.
- **팔의 모델이 다 같지는 않다** — `pr-review-toolkit` 의 `code-reviewer` · `code-simplifier` 는 `model: opus`, `claude-security` 의 보조 넷은 `model: sonnet` 을 박았다.
  고치지 않는다 — 그 플러그인을 설치한 사람이 받는 그대로다. 표가 돈 모델을 든다.
- **경쟁 쪽이 머리 없이 다 돈다는 보장은 없다** — `claude-security` 는 `AskUserQuestion` · `Workflow` 를 쓰고 비용을 한 번 묻는다. 프롬프트가 비용을 미리 받는다고 적어도
  하네스에서 멈출 수 있다. 그러면 그 칸은 「돌지 않음 — <까닭>」으로 남고 그 축은 두 팔로 가른다.
- **재료가 우리 쪽에 기운다** — 열 가운데 넷은 감사자의 되먹임 케이스(`vibe-audit/evals/`)라 감사자 문구가 이미 그 자리를 겨냥한다. 회수율 여섯은 감사자가 **놓친** 결함이라
  반대로 기운다. 판정 표는 두 묶음을 따로 든다.
- **편집 · PR 에 붙는 도구는 재지 않는다** — ③ C.
- **정밀도** — 함정 하나만큼만 본다(요구사항 하지 않을 일 6).

## ③ 받는 입력

**A · 재료 열 — 닫힌 목록.** 그 밖의 케이스는 받지 않는다.

| 묶음 | 케이스(출처) | 축 | 경쟁 팔 |
|---|---|---|---|
| 놓친 결함 | `recall-commit-after-response` · `recall-downgrade-equal-rows` · `recall-expiry-from-processing` · `recall-inactive-code` (`vibe-audit/recall/`) | 데이터 | `pr-review-toolkit` |
| 놓친 결함 | `recall-blank-boundary` · `recall-nul-boundary` (`vibe-audit/recall/`) | 계약 | `pr-review-toolkit` |
| 되먹임 | `gate-root-cause-auth` · `trap-local-dev-password` (`vibe-audit/evals/`) | 보안 | `claude-security` |
| 되먹임 | `gate-comment-owned` · `trap-slice-scope` (`vibe-audit/evals/`) | 내부 규칙 | `pr-review-toolkit` |

기대 결과는 출처 `case.yaml` 의 `expected_outcome` 에서 감사자 이름 · NC 꼴을 뺀 말로 옮긴다 — 결함의 자리 · 까닭은 바꾸지 않는다.

**B · 팔 — 닫힌 목록.**

| 팔 | 러너 인자 | 하네스의 대상 | `--ablation` | 케이스 |
|---|---|---|---|---|
| `vibe-audit` | `vibe-audit` | 이 작업트리의 `vibe-audit/` 를 엮은 임시 폴더 | `with-without` — 「플러그인 없음」 팔이 여기서 함께 돈다 | 열 다 |
| 플러그인 없음 | (위에서 함께) | — | — | 열 다 |
| `pr-review-toolkit` | `pr-review-toolkit --from <클론>` | 클론의 `plugins/pr-review-toolkit/` 를 엮은 임시 폴더 | `none` | ③ A 에서 그 팔인 여덟 |
| `claude-security` | `claude-security --from <클론>` | 클론의 `plugins/claude-security/` 를 엮은 임시 폴더 | `none` | ③ A 에서 그 팔인 둘 |

**C · 견주지 않는 것.** `security-guidance` — 편집 · 턴 끝 · `git commit` 의 훅으로만 돈다. 픽스처를 읽기만 하는 회차에는 걸 자리가 없다. `code-review` — `gh pr` 명령으로
GitHub PR 을 읽는다. 픽스처는 PR 이 없다. 내장 `/security-review` — 브랜치의 바뀐 것을 본다. 픽스처는 한 커밋이다.

## ④ 결정

**정한 것**

- 경쟁 팔의 선정 · 프롬프트 · 채점 · 판정 규칙 · 러너의 자리 — ADR 0066 의 1 ~ 5.
- PR 나눔 — ⑥.

**열어 둔 것**

- **팔마다 허용 도구** — `claude-security` 는 `Write` · `Bash` · `Workflow` 를 든다. 하네스의 `--allow-tools` 로 그 플러그인이 든 만큼 줄지, 케이스의 `allowed_tools` 를
  팔마다 둘지 — PR B 가 시험 회차 하나로 보고 정한다. `vibe-audit` 팔은 지금 케이스 그대로(`Read` · `Glob` · `Grep` · `Agent` · `TodoWrite`)다.
- **케이스 폴더의 꼴** — `compare/<케이스>/` 에 `case.yaml` · `graders/` 만 두고 픽스처를 러너가 복사할지, 출처 경로를 한 파일(`compare/cases.tsv` 같은)에 적고 러너가
  케이스를 엮을지 — PR B.
- **팔마다 비용 천장의 값** — PR B. 합이 $45 를 넘지 않는다.

## ⑤ 검증 계획

- **러너** — PR B 본문에 보인다: 인자 없음 · 모르는 팔 · `--from` 없는 경쟁 팔 · `HEAD` 가 다른 클론이 하네스를 부르기 전에 종료 2 인 것, 그리고 `vibe-audit` 팔을 한 케이스
  `--runs 1` 로 돌려 임시 폴더 · 결과 폴더 · 끝의 표가 서는 것. 새 검사 · 변조본은 세우지 않는다(요구사항 하지 않을 일 2) — 러너는 측정 도구이고 게이트에 들지 않는다.
- **심판** — PR C 가 측정 뒤 팔마다 무작위 두 회차(합 여덟)의 최종 응답을 사람이 기대 결과에 대어 읽고, 심판과 갈린 회차를 표에 적는다. 갈린 회차가 둘을 넘으면 판정을 내지 않고
  저자에게 올린다.
- **수트와 갈림** — 각 PR 에서 `python3 scripts/eval-key.py route` · `full` 이 `main` 과 같은 값을 찍는 것을 PR 본문에 보인다.
- **게이트** — 각 PR 의 작업트리와 CI gate 잡에서 `./scripts/gates.sh` 가 통과한다.

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A | 마스터플랜 줄 · 이 요구사항 · 설계 · ADR 0066 | 착공 |
| B | `scripts/run-compare.sh` · `compare/` 재료 열 · `.gitignore` · `CLAUDE.md` 「금지」 한 줄 · 「열어 둔 것」을 설계 끝 날짜 항목에 | ② A ~ H, 성공 기준 1 · 2 · 3 · 6 |
| C | 세 팔 측정 · `docs/eval-log/2026-11.md` 의 표와 판정 · 심판 손 대조 | 성공 기준 4 · 5 |
| 닫기 | 닫기 전 감사 회차의 등록 · 요구사항 끝의 `## 닫으며` · 마스터플랜 51 을 `닫힘` · 다음 조각 | 성공 기준 8 |

B 와 C 를 나누는 까닭 — B 는 러너 · 재료라 리뷰가 있고, C 는 돈을 쓰는 측정이라 B 가 머지된 재료 위에서 한 번 돈다. 측정 뒤 재료를 고치면 세 팔을 다시 돌려야 한다.
