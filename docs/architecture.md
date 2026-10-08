# 시스템 구조

**살아 있는 문서**다. 이 저장소의 부품과 그 사이의 흐름만 든다. 왜 이 모양인지는 `docs/adr/`, 대장의 모양은
`docs/schema.md`, 값(모델 · 판 · 잡의 설정)은 각 파일이 든다. 의도는 `INTENT.md`.

## 부품

| 부품 | 사는 곳 | 하는 일 |
|---|---|---|
| 원본 감사자 여섯 | `vibe-audit/agents/` | 목적별로 좁힌 읽기 전용 감사자. 공통 절은 여섯이 글자 그대로 같다 |
| 브리핑 커맨드 · 검사기 | `vibe-audit/commands/audit-brief.md` · `vibe-audit/scripts/verify-brief.py` | 부르는 세션이 diff 를 브리핑으로 싣고, 검사기가 그것을 git 과 대조한 뒤 감사자를 부른다 |
| 조각 문서 스킬 | `vibe-slice/skills/slice-docs/` | 의도 · 마스터플랜 · 요구사항 · 설계 틀 넷(`templates/`)과 쓰는 법, 그리고 검사 둘(`scripts/` — 문서 대조 검사 `verify-docs.py` · 설계 → 구현 관문 `verify-slice-gate.py`). 절차는 `docs/procedure.md` 를 가리키기만 한다 |
| 리뷰 가르기 스킬 | `vibe-slice/skills/slice-review/` | 리뷰 지적을 그 조각의 기준에 비춰 가르는 규칙과 답글 · 회차 표의 꼴. 틀은 옆의 `slice-docs` 에서 읽는다 |
| 매니페스트 셋 | `.claude-plugin/marketplace.json` · `vibe-audit/.claude-plugin/plugin.json` · `vibe-slice/.claude-plugin/plugin.json` | 마켓플레이스와 플러그인 둘. 두 군데 적힌 이름 · 설명과, 플러그인 폴더마다 장터에 줄이 하나인지를 `verify-manifest.py` 가 본다 |
| 사본 | 각 레포의 `.claude/agents/` · `.claude/commands/` · `.claude/scripts/` · `.claude/skills/<스킬>/` | 클라우드 레인에서 뜨는 쪽. 그 레포에 맞게 갈린다 |
| 사본 대장 | `copies.json` | 사본마다 레포 · 경로 · 심을 때의 커밋 · 날짜 |
| 후보 대장 | `feedback.json` | 사본과 원본의 차이를 묶은 후보와 그 판정(특화 · 결함 · 보류 · 되먹임 완료). 되먹임 커밋과 케이스는 되먹임 완료(`fed_back`)가 된 뒤에만 붙는다 |
| 수트 | `vibe-audit/evals/` | 되먹임마다 붙인 케이스. 지금 모양은 그 폴더의 `README.md`, 작업 기록은 `docs/eval-log/` |
| 키 없는 게이트 | `scripts/gates.sh` 가 부르는 것 | 모델 없이 도는 검사 전부. 목록은 그 파일 한 군데에만 있다. 조각 문서 스킬의 검사 둘은 `scripts/` 의 같은 이름 링크로 부른다(ADR 0018 의 3) |
| CI | `.github/workflows/eval.yml` | 키 없는 게이트와 그 변조본(「게이트가 무는가」), 수트, 그리고 판정. 잡의 이름과 설정은 그 파일이 들고, 어느 체크를 필수로 거는지는 저장소 설정(브랜치 보호 · ruleset)이 든다 |

대장 둘의 모양은 앵커볼트다(`CLAUDE.md`). 스크립트는 다 파일 머리에 쓰는 법과 까닭을 적는다.

## 흐름

```
심기 ──→ 견주기 ──→ 판정 ──→ 되먹임 ──→ 케이스 ──→ 수트
sync-     verify-     사람이     원본      evals/     run-evals.sh
agents    copy(-ies)  feedback   감사자     <케이스>/   · CI
          compare-    .json      고침
          copies
```

**심기.** `scripts/sync-agents.sh <레포>` 가 감사자 여섯 · 브리핑 커맨드 · 검사기를 그 레포의 `.claude/` 에 심고,
감사자 · 커맨드 파일 머리에 출처 커밋을 박고, `copies.json` 에 한 줄을 적는다. 검사기(`.py`)는 바이트 그대로 옮기고
그 출처는 대장만 든다. 커밋 안 된 원본은 심지 않는다. 사본이 이미 있으면
덮어쓰지 않는다 — 사본의 특화가 사라진다.

**스킬 심기.** `scripts/sync-slice.sh <레포>` 가 `vibe-slice` 의 스킬 폴더를 다 그 레포의 `.claude/skills/<스킬>/` 에
심고 스킬마다 `SKILL.md` 머리에 출처 커밋을 박는다(ADR 0014 의 7). 스킬의 절차 지도 링크(`blob/main/`)도 출처 커밋(전체 sha)으로
박고, 원격 가지에 없는 원본은 링크가 열리지 않으므로 심지 않는다(ADR 0017). 감사자 사본과 달리 대장에 적지 않고 견주지도 않는다 —
있으면 `--force` 로만 폴더째 덮는다(ADR 0013). 대화형 세션은 `vibe-slice` 플러그인으로 받고, 그 링크는 `blob/main/` 그대로다.

**견주기.** 셋이 층을 나눈다.

- `scripts/verify-copy.py` — 사본이 원본의 공통 절과 `tools` 를 **글자 단위로** 들고 있는가. 절이 있는지만 보면
  손으로 다시 쓰거나 한 줄 빠뜨려도 통과하기 때문이다. 사본 고유의 특화는 보지 않는다.
- `scripts/verify-copies.py` — 대장이 성한가(빠진 자리 · 같은 레포 두 번 · 이 저장소에 없는 커밋)를 보고, 경로가
  이 기계에 있으면 `verify-copy.py` 까지 이어 돌린다. 없으면 못 봤다고 찍는다. **갈린 것 자체는 실패가 아니다** —
  원본이 그 뒤 몇 커밋 움직였는지는 찍되 판정하지 않는다. 대장의 커밋을 찾으므로 git 역사 전체가 있어야 한다.
- `scripts/compare-copies.py` — 사본을 **심을 때의 원본**과 견줘 차이를 내용 해시로 묶은 후보를 찍는다. 이미
  판정한 후보는 다시 안 나온다. 사본이 원격보다 뒤거나 더러우면 견주지 않고 멈춘다(ADR 0001 ~ 0003).

**판정.** 후보가 특화인지 결함인지는 사람이 정해 `feedback.json` 에 적는다 — 스크립트나 세션이 채우지 않는다.
가르는 질문은 `INTENT.md` Why 에 있다. `scripts/verify-feedback.py` 가 대장의 모양과 역사 규칙(번호 · 되먹임
커밋에 케이스가 있는가)을 본다.

**되먹임.** 결함으로 판정된 후보만 원본 감사자를 고친다. 문구가 글자 예산(`vibe-audit/evals/budget.txt` ·
`scripts/verify-budget.py`)을 넘으면 압축이 먼저다(ADR 0004). 특화 항목은 원본에 올리지 않는다 — 미리 지어낸 특화
항목은 재지 않고 단정한 것이기도 하다.

**케이스.** 되먹임 한 건에 케이스 하나 — 진짜 부적합 하나(대조군)와 그 되먹임이 막는 거짓 판정. 정규식 그레이더가
있으면 `samples/pass.md` · `samples/fail*.md` 로 그레이더가 가르는지도 본다(`verify-graders.py`).

**수트.** `scripts/run-evals.sh` 가 깃발을 박아 `claude plugin eval` 을 돌린다. CI 는 같은 러너를 부른다. PR · `main` push 는
`route-*` 만 돌리고, 그 수트 입력의 지문(`scripts/eval-key.py`)이 이미 통과했으면 다시 돌지 않는다. 사람이 부르는 전수
(`workflow_dispatch`)는 지문을 찾아보지 않고 늘 돈다. 재는 법과 케이스 표는 `vibe-audit/evals/README.md`.

## 게이트가 무는가

키 없는 게이트는 도는 것과 무는 것을 따로 본다. CI 「게이트가 무는가」 단계가 이 저장소의 검사기마다 변조본(사본 감사자의
`tools` 변조 · 대장의 없는 커밋 · 성하지 않은 후보 대장 · 파일 없는 라이선스 선언 …)을 만들어 떨어지는지 보고, 검사기 몇은
자기 시험 스크립트(`scripts/test-*.py`)를 `gates.sh` 에 둔다. `gates.sh` 의 `claude plugin validate` 는 정상 트리에서만
돈다 — 그것을 떨어뜨리는 변조본은 없다. 설계 → 구현 관문의 변조본(`scripts/bite-slice-gate.py`)과 문서 대조 검사의 다른 레포
모드 변조본(`scripts/bite-verify-docs.py`)은 「게이트가 무는가」가 아니라 `gates.sh` 에 있다 — `eval.yml` 은 수트 지문에 들어
고치면 route 수트가 돈다(ADR 0016 의 6 · ADR 0018 의 6). 새 검사를 세우면 그 변조본을 함께 넣는다(`CLAUDE.md` 「작업 방식」).

## 문서

의도(`INTENT.md`) · 마스터플랜(`docs/master-plan.md`) · 절차와 문서의 모양(`docs/procedure.md`) · 틀
(`vibe-slice/skills/slice-docs/templates/`) · 조각(`docs/slices/`) · 결정(`docs/adr/`). 문서의 모양은
`scripts/verify-docs.py` 가, 착공 PR 에 구현이 없고 구현이 기준 가지에 머지된 설계 위에 서는지는
`scripts/verify-slice-gate.py` 가 본다(ADR 0016). 두 검사의 실물은 조각 문서 스킬의 `scripts/` 에 있어 플러그인 · 사본과 함께
다른 레포에 가고, 다른 레포에서는 `verify-docs.py --repo <루트>` 가 지도 대신 검사 옆의 틀 넷을 원천으로 읽는다(ADR 0018 의 2).
살아 있는 문서와 기록의 구분은 `docs/procedure.md` 「살아 있는 문서와 기록」.
