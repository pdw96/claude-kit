# 조각 9 — 다른 레포의 문서 대조 검사 (2026-10-08 착공)

요구사항이다 — **무엇을 · 왜.** 어떻게 · 경계는 같은 폴더의 `design.md`, 대안이 있던 결정은 ADR 0018.

## 문제

claude-kit 에서는 문서의 모양을 `verify-docs.py` 가, 착공 → 구현의 순서를 `verify-slice-gate.py` 가 `gates.sh` 에서 문다.
다른 레포에 닿는 것은 `vibe-slice` 의 스킬 둘뿐이고(ADR 0016 의 1), 거기에는 무는 검사가 없다.

- **모양 — 검사가 돌 수 없다.** `verify-docs.py` 는 필수 제목을 루트의 `docs/procedure.md` 「…의 칸」 표에서 읽고, 틀을
  루트의 `vibe-slice/skills/slice-docs/templates/` 에서 찾는다. 다른 레포에는 둘 다 없다 — 「틀 배포」는 지도를 보내지 않고
  가리킨다(ADR 0013 의 2). 그 대가를 ADR 0013 결과 2 가 「다른 레포에서 문서 대조 검사가 돌지 않는다」로 적었다.
- **순서 — 판정을 스킬 문구가 든다.** `slice-review` 「1. 기준」은 기본 가지의 마스터플랜에서 그 조각이 `진행` 이고 설계가
  있는지를 세션이 읽어 보게 적는다. 검사의 정의를 문구로 옮긴 자리다. 그 문구를 들인 #34 의 지적 셋이 다 「검사의 보장을 스킬
  문구로 옮기며 뜻이 빠졌다」였다 — 기준 가지 · 착공 + 구현 · 결정 문서 목록(조각 7 「닫으며」). 문구는 고쳤지만 같은 판정을
  두 벌 든다.
- **증거가 난 꼴이 바로 이 자리다.** 강호쟁패 #1 은 착공 문서와 검사 스크립트가 한 PR 이라 리뷰 12회차를 돌았고(`docs/procedure.md`
  「사례」), 강호쟁패 ADR-0005 의 결론은 「사람이 기억하는 검사는 건너뛴다」다.

**틀대로 선 다른 레포는 아직 없다**(2026-10-08 에 봤다). 첫 실물은 단계 5 의 강호쟁패다(ADR 0018 의 4).

| 레포 | 받는 길 | 의도 | 마스터플랜 · 조각 폴더 | 검사 · CI |
|---|---|---|---|---|
| 강호쟁패(792a5d3) | 플러그인 `vibe-slice` · 대화형 세션 · Windows | `PRD.md` | 없다 | `Tools/check.mjs`(Node). CI 없음. `python3` 3.14 가 있다(저자) |
| ERP(3e40b5b) | 사본 `.claude/skills/` · 클라우드 세션 | `PRD.md` · `docs/PRD-<N>단계.md` | 없다 — 「이 레포는 그 스킬이 다루는 조각 문서를 쓰지 않는다」(ERP `docs/리뷰-루프.md`) | GitHub Actions `ci.yml` |

`eval.yml` 「게이트가 무는가」는 `scripts/verify-docs.py` 를 경로로 읽어 스무 자리를 망가뜨린다. 검사를 옮기려고 그 경로를
고치면 `eval.yml` 이 수트 지문에 들어 route 수트가 돈다(조각 3 「닫으며」 — 네 번 돌았다).

## 핵심 사용자와 시나리오

- 사용자: 저자 한 명, 그리고 `vibe-slice` 를 받은 다른 레포에서 조각을 여는 Claude Code 세션.
- 시나리오: 강호쟁패의 세션이 `/vibe-slice:slice-docs` 로 마스터플랜(의도 줄 `PRD.md`)을 쓴다 → 착공 PR 을 내기 전에 스킬이
  스킬 폴더의 `verify-docs.py --repo .` 와 `verify-slice-gate.py` 를 돌린다 → 설계에서 `## ③ 받는 입력` 을 빠뜨렸으면 파일과
  보장 번호를 찍고 1 로 떨어져, 세션이 고치고 다시 돌려 통과를 본 뒤 PR 을 연다 → 착공 PR 에 구현 파일을 실었으면 G1 로 떨어진다 →
  구현 PR 에 리뷰가 오면 `/vibe-slice:slice-review` 가 가르기 전에 `verify-slice-gate.py` 로 착공 머지를 본다 — G2 면 가르지 않고
  단계 3 의 조건이라고 말한다. claude-kit 에서는 같은 두 검사를 `gates.sh` 가 그대로 부르고, 원천은 `docs/procedure.md` 그대로다.

## 성공 기준

1. 검사 둘의 실물이 한 벌이다 — `vibe-slice/skills/slice-docs/scripts/` 에 있고, `scripts/verify-docs.py` · `scripts/verify-slice-gate.py`
   는 그것을 가리키는 링크다. `eval.yml` 은 바뀌지 않고, 「게이트가 무는가」의 `verify-docs.py` 변조 스무 자리가 다 떨어진다(CI).
2. 다른 레포 모드 — `test-verify-docs.py` 가 틀로 세운 임시 레포(`docs/procedure.md` · `vibe-slice/` 없음)에서 꼴마다 본다.
   대조(의도 줄 `PRD.md` · 날짜 항목을 더한 설계 · 닫은 조각)는 통과하고, 변조본(필수 제목 빠짐 · 의존이 닫히지 않음 · 「닫으며」
   빠짐 · 고아 폴더 · 마스터플랜 없음)은 기대한 보장 번호로 떨어진다. 원천이 틀이다 — 검사 옆 틀에 `##` 제목 한 줄을 더하면 그
   틀로 쓴 `진행` 조각 문서가 떨어진다. 변조본 `bite-verify-docs.py` 가 다른 레포 모드의 자리마다 검사를 망가뜨려 자체 시험이
   다 떨어지는지 본다.
3. 사본 길 — `test-sync-slice.py` 가 `sync-slice.sh` 로 심은 `.claude/skills/slice-docs/scripts/` 의 두 검사를 대상 레포에서
   돌린다. 틀로 세운 대상에서 `verify-docs.py --repo` 가 통과하고 한 자리를 망가뜨리면 떨어지며, 착공 + 구현을 한 diff 로 둔
   대상에서 `verify-slice-gate.py` 가 G1 로 떨어진다.
4. 스킬 — `slice-docs` 가 착공 PR · 닫는 PR 을 내기 전에 두 검사를 돌리고, `slice-review` 가 구현 PR 의 착공 머지를
   `verify-slice-gate.py` 로 본다(grep). `vibe-slice` 판이 오르고, `claude plugin validate ./vibe-slice` · `verify-manifest.py` 가
   통과하고, `verify-budget.py` 가 천장 안이다 — 호출 시 ≤ 4,500, `vibe-slice` 상시 합계 ≤ 5,600.
5. 강호쟁패에서 — 저자가 단계 5 에서 `vibe-slice` 를 새 판으로 갱신하고 `slice-docs` 로 마스터플랜을 세운 뒤, 스킬이 부른 두
   검사가 통과하고 한 자리를 어긋내면(`## 범위 변경` 을 지운다) `verify-docs.py` 가 M1 로 떨어지는 것을 본다.
6. `./scripts/gates.sh` 가 구현 PR 마다 통과하고(검사가 들어온 뒤로 열여덟), 구현 PR 이 바꾼 파일 가운데 수트 지문
   (`eval-key.py route --list` · `full --list`)에 드는 것이 0 이다.

## 하지 않을 일

1. **다른 레포의 CI · 훅에 걸지 않는다** — 검사는 스킬이 부를 때 돈다. 그 레포의 CI 에 거는 법도 적지 않는다(ADR 0018 의 1).
2. **절차 지도를 보내지 않는다** — 다른 레포 모드의 원천은 스킬 폴더의 틀이다. 지도 「…의 칸」을 스킬 폴더에 한 벌 더 두지도,
   네트워크로 읽지도 않는다(ADR 0013 의 2 · ADR 0018 의 2).
3. **`eval.yml` 을 고치지 않는다** — 수트 지문에 든다. 다른 레포 모드의 변조본은 `gates.sh` 가 부른다(ADR 0018 의 3 · 6). 「게이트가
   무는가」의 변조를 지문 밖으로 모으는 일은 조각 나눔 「게이트 변조본을 수트 지문 밖으로」.
4. **검사의 보장을 넓히지 않는다** — 다른 레포 모드는 원천(O)과 틀(T)을 빼고 조각 3 설계 ② 의 규칙을 그대로 쓴다.
   `verify-slice-gate.py` 는 조각 7 설계 ② 그대로 옮기기만 한다. 어느 조각의 구현인지 가리는 일(ADR 0016 의 3)도 그대로다.
5. **「…의 칸」 네 절과 틀의 `##` 제목을 바꾸지 않는다** — 틀은 원천이 될 뿐 모양은 그대로다.
6. **다른 레포 저장소를 이 조각의 PR 에서 고치지 않는다** — 강호쟁패의 플러그인 갱신 · 마스터플랜은 저자가 단계 5 에서 한다.
   ERP 의 사본도 다시 심지 않는다 — ERP 는 조각 문서를 쓰지 않으니 검사는 ERP 가 다음에 심을 때 따라간다.
7. **`vibe-audit` 와 감사자 사본 길(`sync-agents.sh`)을 건드리지 않는다.**

## 제약

- 스택: bash · python3 표준 라이브러리, git. 부르는 레포에 `python3` ≥ 3.9 가 있어야 한다(`pathlib.Path.is_relative_to`) —
  강호쟁패는 3.14(저자, 2026-10-08), 이 착공을 쓴 클라우드 컨테이너는 3.13. 스킬의 모양은 `claude plugin validate` 가 받는 것.
- 모델 비용: 이 조각의 파일로는 route 수트가 돌지 않는다 — **수트 지문에 드는 파일**(`eval-key.py route --list` · `full --list`)을
  건드리지 않는다. 예산 스냅숏 `vibe-audit/evals/budget.txt` 는 지문 밖이고 스킬을 고치는 PR 이 고친다.
- 글자 예산: `slice-review` 호출 시 4,248 / 4,500(여유 252), `slice-docs` 1,599, `vibe-slice` 상시 합계 348 / 5,600. 천장은
  올리지 않는다(ADR 0004).
- 기간 **이틀**.
- `./scripts/gates.sh` 는 지금 열일곱이 그대로 통과해야 하고, 다른 레포 모드의 변조본이 들어온 뒤로는 열여덟이다.
- 리뷰: PR 본문에 설계 ② 를 적고, 착공 PR 도 구현 PR 도 스킬 `slice-review` 로 가른다. **3라운드**를 넘기면 소유자가 판정한다.
