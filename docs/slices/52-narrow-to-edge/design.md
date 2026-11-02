# 조각 52 설계 — 차별점으로 좁히기

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A · 닫기 | 조각 나눔 — 「차별점으로 좁히기」를 순서 52 · `진행` 으로 · 조각 폴더. 닫기에서 `닫힘` · 다음 조각 |
| `docs/slices/52-narrow-to-edge/` · `docs/adr/0069-narrow-to-edge.md` | A | 이 요구사항 · 설계 · ADR |
| `scripts/run-compare.sh` | B | 하네스 밖 팔 — 재료를 플러그인 폴더 밖에 두고(② A), 회차마다 임시 HOME 의 세션 기록을 남겨 정답지 낱말을 세고(② B), 천장을 $8 로(② C). 끝 줄에 결과 폴더가 세션 밖에 남지 않는다는 말(② E). 머리 주석의 종료 문장(④ 열어 둔 것) |
| `compare/README.md` | B | 하네스 밖 팔이 재료를 받지 않는다는 것 · 정답지 낱말 칸 · 결과를 남기는 길 |
| `docs/eval-log/2026-11.md` · `docs/eval-log/compare-<날짜>.tar.xz` | C | `claude-security` 재측정 · secrets 축 판정 · 손 대조 · 재료 견주기 · 결과 압축본 |
| `README.md` | C | 절 하나 — 효력 범위의 주장과 같았던 축 · 한계(ADR 0069 의 2) |
| `docs/audit/` | 닫기 | 닫기 전 감사 회차의 기록 · 브리핑 · 대장 등록 |

앵커볼트를 건드리지 않는다 — 이름 · 감사자의 `tools` · 공통 절 · 대장 둘의 모양 · 절 제목 · 고정 영역이 그대로다. `vibe-audit/` · `vibe-slice/` · `scripts/run-evals.sh` 를
고치지 않아 수트 지문 · 예산 · 사본이 그대로다. `README.md` 는 지문에 들지 않는다(`eval-key.py` 의 `SKIP`). `INTENT.md` 는 그대로다 — README 의 주장은 What 의 `vibe-audit` 줄 안이다.
`CLAUDE.md` 는 그대로다 — 러너의 자리 · 「금지」의 줄이 바뀌지 않는다. 시스템 구조(`docs/architecture.md`)는 그대로다 — 러너는 측정 도구라 부품 표에 없다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것**

- **A · 정답지를 건네지 않는다** — 하네스 밖 팔이 `--plugin-dir` 로 넘기는 폴더는 고정 커밋의 플러그인 사본뿐이다. 재료(`case.yaml` · `graders/` · `prompt.md` · `fixture.sh`)는 그
  밖의 임시 폴더에 두고 러너가 읽는다. 회차의 작업 위치는 픽스처만 든 빈 임시 폴더다(지금과 같다).
- **B · 새는 길을 센다** — 회차마다 그 회차의 임시 HOME 아래 세션 기록(`.claude/projects/` 의 `*.jsonl` 전부 — 하위 에이전트의 것 포함)을 결과 폴더(`sessions/<케이스>.run<n>/`)에
  옮기고, 주 트레이스와 그 기록에서 ③ B 의 낱말이 나온 회차를 센다. 끝 표의 `claude-security` 줄이 「정답지 낱말」 칸에 그 수를 찍는다. 낱말이 나온 회차는 판정에서 빼지
  않고 eval-log 에 그 회차와 자리를 적는다 — 빼는지는 C 가 그 자리를 읽고 저자에게 올린다.
- **C · 천장** — `claude-security` 팔의 비용 천장은 $8 이다. 부르는 쪽이 바꾸지 못한다(지금처럼 `--max-cost-usd` 를 받지 않는다).
- **D · 같은 조건** — 재료 · 요청 · 세션 모델 · 허용 도구 · 심판(같은 그레이더 글 · `sonnet` · 세 표)은 조각 51 의 그 팔과 같다. 바뀌는 것은 재료가 놓인 자리와 기록을 남기는 것뿐이다.
- **E · 결과를 남기는 길** — 러너의 끝 줄이 「결과 폴더는 `.gitignore` 라 세션 밖에 남지 않는다 — `docs/eval-log/compare-<날짜>.tar.xz` 로 싣는다」를 찍는다. C 가 그 길로 싣는다.
- **F · 다른 팔은 그대로** — `vibe-audit` · `none` · `pr-review-toolkit` 팔의 하네스 호출 · 재료 엮기 · 끝 표는 글자 그대로다.

**보장하지 않는 것(알려진 한계)**

- **디스크를 뒤지면 막지 못한다** — 그 팔은 격리 없는 Bash 를 가진다. 이 저장소의 클론(`compare/`)과 러너의 임시 재료 폴더는 같은 기계에 있다. 막지 않고 ② B 로 센다.
- **모든 하위 실행이 기록에 남는다는 보장은 없다** — ② B 는 CLI 가 임시 HOME 에 쓰는 것만 본다. 주 트레이스가 `Agent` · `Workflow` 를 불렀는데 하위 기록이 없으면 C 가 그 회차
  수를 적는다 — 그만큼은 여전히 배제하지 못한다.
- **표본이 작다** — 칸마다 3 회차. secrets 축은 `vibe-audit` 5/6 · 플러그인 없음 3/6 이라, 이 팔이 4/6 이상이면 「같다」, 3/6 이하면 「앞선다」(+2)다. 「뒤진다」는 나올 수 없다.
- **조건이 다 같지는 않다** — 이 팔은 여전히 하네스 밖이다(ADR 0068). 하네스 팔의 Bash 는 읽기 전용 오류를 받고 이 팔은 받지 않는다(회차 26 OB-1) — 다시 재지 않는 쪽의 일이다.
- **README 의 주장은 이 재료 · 이 수트 모델 · 이 커밋에서만 맞다** — 함정 두 케이스 · 6 회차가 근거다. 절이 그 크기를 함께 든다.
- **자격 · 권한** — 하네스 밖 팔은 제3자 플러그인에 측정 자격을 넘기고 `dontAsk` 로 Bash · Write 를 준다. 받아들이고 적는다(ADR 0069 의 5).

## ③ 받는 입력

**A · 재는 칸 — 닫힌 목록.** 그 밖은 돌리지 않는다.

| 팔 | 케이스 | 회차 |
|---|---|---|
| `claude-security` (하네스 밖) | `gate-root-cause-auth` · `trap-local-dev-password` | 3 · 3 |

재료는 `compare/cases.tsv` 의 두 줄 그대로다 — 출처 `vibe-audit/evals/gate-root-cause-auth` · `vibe-audit/evals/trap-local-dev-password`, 축 `secrets`. 클론의 `HEAD` 가
`a7ba5b93db0c7c8d17f3f1d25853adca79598a1a` 가 아니면 러너가 종료 2(지금과 같다).

**B · 정답지 낱말 — 닫힌 목록.** 재료 폴더에만 있고 픽스처 · 요청 본문에는 없는 글이다(2026-11-02 두 출처 `fixture.sh` · `compare/prompts/secrets.md` 에서 0 건).

- `case.yaml`
- `found.md`
- `expected_outcome`
- 러너가 그 실행에 만든 재료 임시 폴더의 경로

**C · 세션 기록** — 회차의 임시 HOME 아래 `.claude/projects/**/*.jsonl`. 그 밖의 파일은 옮기지 않는다.

## ④ 결정

**정한 것**

- 「같다」 축의 감사자 · README 의 주장 · 다시 재는 팔과 천장 · 정답지를 가리는 법 · 자격과 `dontAsk` · 결과를 남기는 길 — ADR 0069 의 1 ~ 6.
- PR 나눔 — ⑥.

**열어 둔 것**

- **러너 머리 주석의 종료 문장** — 「점수로 종료가 바뀌지 않는다」(`run-compare.sh:14`)는 하네스 밖 길이 다 맞히지 못하면 1 로 끝나는 것(`:259` → `:380`)과 어긋난다(회차 26 「안 본
  것」의 `audit-internal` 몫). 주석을 사실에 맞출지, 하네스 밖 길의 종료를 하네스 길에 맞출지 — PR B 가 하네스 길의 종료를 보고 정해 설계 끝 날짜 항목에 남긴다.
- **README 절의 자리와 문장** — 「들어 있는 것」 아래 새 절로 둘지, 그 표의 `vibe-audit` 줄 곁에 둘지 — PR C 가 측정 뒤 정한다. 내용은 성공 기준 6 이 묶는다. `verify-counts.py` 의
  README 닻(「감사자 {N}」 셋 따위)을 건드리지 않는다.

## ⑤ 검증 계획

- **러너(PR B, 비용 0)** — 경로 맨 앞에 가짜 `claude` 를 두고 PR B 본문에 보인다: (가) 하네스 밖 팔이 받은 `--plugin-dir` 폴더의 파일 목록에 `compare/` · `case.yaml` · `found.md`
  가 없다, (나) 가짜가 임시 HOME 의 `.claude/projects/` 에 ③ B 의 낱말 하나를 쓴 기록을 남기면 끝 표의 「정답지 낱말」이 1 이고 그 기록이 `sessions/` 에 옮겨졌다, 쓰지 않으면 0 이다,
  (다) 끝 줄에 ② E 의 문장이 있다, (라) 조각 51 닫기의 거절 길 아홉(`docs/eval-log/2026-11.md` 「조각 51 닫기」의 표)이 그대로 종료 2 이고 가짜가 불린 수가 0 이다, (마) 다른 세
  팔의 하네스 호출 줄이 `main` 과 글자 그대로다(`git diff` 의 덩이가 하네스 밖 길과 끝 줄 · 머리 주석에만 있다). 새 검사 · 변조본은 세우지 않는다(요구사항 하지 않을 일 5).
- **측정(PR C)** — `./scripts/run-compare.sh claude-security --from <클론>` 한 번. 끝 표 · 정답지 낱말 수 · 회차마다 하위 기록이 있는지(주 트레이스의 `Agent` · `Workflow` 호출 수와
  견준다)를 eval-log 에 싣는다. 여섯 회차의 최종 응답을 사람이 다 읽어 심판과 갈린 회차를 적는다 — 갈린 회차가 하나라도 있으면 판정을 내기 전에 저자에게 올린다.
- **재료 견주기(PR C)** — `git diff --stat ba1f955 <측정 커밋> -- compare/ vibe-audit/evals/gate-root-cause-auth/fixture.sh vibe-audit/evals/trap-local-dev-password/fixture.sh`
  가 비어 있음을 eval-log 에 싣는다(회차 26 OB-3).
- **README(PR C)** — 절의 숫자마다 eval-log 의 칸을 대어 PR 본문에 대응을 보인다.
- **수트와 갈림** — 각 PR 에서 `python3 scripts/eval-key.py route` · `full` 이 `main` 과 같은 값을 찍는 것을 PR 본문에 보인다.
- **게이트** — 각 PR 의 작업트리와 CI gate 잡에서 `./scripts/gates.sh` 가 통과한다.

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A | 마스터플랜 줄 · 이 요구사항 · 설계 · ADR 0069 | 착공 |
| B | `scripts/run-compare.sh` 의 하네스 밖 길 · 끝 줄 · 머리 주석, `compare/README.md`, 「열어 둔 것」의 종료 문장을 설계 끝 날짜 항목에 | ② A ~ F, 성공 기준 1 · 2 · 7 |
| C | `claude-security` 재측정 · eval-log 의 표와 판정 · 손 대조 · 재료 견주기 · 결과 압축본 · `README.md` 의 절 | 성공 기준 3 · 4 · 5 · 6 |
| 닫기 | 닫기 전 감사 회차의 등록 · NC-29 판정 · 요구사항 끝의 `## 닫으며` · 마스터플랜 52 를 `닫힘` · 다음 조각 | 성공 기준 9 |

B 와 C 를 나누는 까닭 — B 는 러너라 리뷰가 있고 비용이 0 이다. C 는 돈을 쓰는 측정이라 B 가 머지된 러너 위에서 한 번 돈다. README 의 절은 secrets 의 새 판정이 그 절의 「같았던
축」 문장에 들어 C 에 싣는다.
