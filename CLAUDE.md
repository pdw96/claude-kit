# claude-kit 작업 규칙

매 세션 읽는 입력물이다. 리뷰 지침과 고정 영역은 `AGENTS.md` 에 있다 — 여기 옮겨 적지 않는다.
같은 목록을 두 군데 두면 갈린다.

## 스택

- bash · python3 **표준 라이브러리만**. 외부 패키지를 들이지 않는다.
- git — **역사 전체**가 있어야 한다. 얕은 클론에서는 `verify-copies.py` 가 대장의 커밋을 못 찾는다. 클라우드 세션의 얕은 클론은 `.claude/settings.json` 의 SessionStart 훅이 시작할 때 받아 온다. 저장소 여럿을 붙인 세션은 저장소 훅을 읽지 않으니 `git fetch --unshallow origin` 을 손으로 한다.
- Claude Code CLI — `claude plugin validate` · `claude plugin eval`. 판은 고정하지 않는다 — CLI 판은 수트 지문(`eval-key.py`)이 든다.
- CI: GitHub Actions — 잡과 그 역할은 `.github/workflows/eval.yml` 이 든다. 어느 체크를 필수로 거는지는 저장소 설정(브랜치 보호 · ruleset)이다.
- 수트 모델 · 심판 모델 — `run-evals.sh` 가 박는다.

## 앵커볼트 — 바꾸려면 먼저 물어볼 것

- **이름** — 감사자(`audit-*`) · 플러그인(`vibe-audit` · `vibe-slice`) · 스킬(`slice-docs` · `slice-review`) · 마켓플레이스(`pdw96-kit`).
  호출 이름이고 사본 레포에 퍼져 있다.
- **감사자의 `tools`** — 읽기 전용 셋. 고칠 도구가 없다는 것이 이 플러그인의 주장이다.
- **감사자 공통 절의 문구** — 사본이 글자 단위로 견준다(`verify-copy.py`). 바꾸면 모든 사본이 갈린다.
- **대장의 모양** — `copies.json` · `feedback.json`. `docs/schema.md`.
- **의도 · 마스터플랜 · 작업 규칙(`CLAUDE.md`) · 프로필(`Profile.md`) · 요구사항 · 설계 문서의 모양** — 절 제목. `docs/procedure.md`. 그 파일
  「…의 칸」 여섯 절의 제목과 표 서식도 — 문서 대조 검사(`verify-docs.py`)가 그것으로 원천을 찾는다(ADR 0010 · 0041 · 0042).
- **고정 영역** — `AGENTS.md` 「Review guidelines」.

## 가변 — 자유롭게 바꿔도 되는 것

- README 서술, 감사자 작업 기록(`docs/eval-log/` — 덧붙이기만 한다)
- 감사자 체크 항목의 문구 — 예산과 수트 안에서
- 스크립트의 내부 구조

## 작업 방식

- **되먹임은 사본 → 원본 한 방향**이고, 가르는 질문은 「다른 레포에서도 같은 말인가」다(`INTENT.md` Why).
- **되먹임 한 건에 eval 케이스 하나** — 진짜 부적합 하나 · 대조군 · `samples/fail*.md`.
- **새 검사를 세우면 `gates.sh` 가 부르는 변조본으로 떨어지는 것을 함께 넣는다.** 물지 않는
  검사는 게이트가 아니다. 키 없이 도는 검사의 목록은 `gates.sh` 한 군데에만 둔다 — `test-gates.py` 의 고정 목록은
  갈리면 떨어지는 두 벌이라 예외다. 검사를 더하거나 빼면 둘을 함께 고친다(ADR 0049).
- 대안이 있던 결정은 `docs/adr/` 에 남긴다. 고치지 않고 새 ADR 로 대체한다.
- **감사 기록은 `docs/audit/` 에 둔다** — 부적합 대장 `docs/audit/nc-ledger.md`(살아 있는 쪽) · `nc-ledger-history.md`(지나간 쪽), 회차의
  기록 `records/` · 브리핑 `briefs/`. 감사자는 이 대장을 지난 기록으로 읽고, `/audit-brief` 는 이 폴더를 diff 에서 뺀다. `.claude/` 아래에는
  커밋하지 않는다 — 변조 시험 지문에 든다.
- **프로젝트의 의도는 `INTENT.md` 가 든다. 조각은 `docs/master-plan.md` 의 조각 나눔에서 꺼내 `docs/procedure.md` 대로 간다.** 살아 있는 문서와 기록의
  규칙도 거기.

## 금지

- 사본의 특화를 원본에 올리지 않는다. 레포별 분기를 원본에 두지 않는다.
- 커밋 안 된 원본을 심지 않는다 — `sync-agents.sh` 가 막는다. 대장의 `synced_commit` 을 손으로
  옮겼다면 `verify-copy.py` PASS 를 본 뒤다.
- `claude plugin eval` 을 직접 부르지 않는다 — `run-evals.sh` 로.
- 글자 예산 천장을 저자 승인 없이 올리지 않는다(ADR 0004).
- 토큰 · 키를 저장소에 쓰지 않는다. CI 자격은 저장소 시크릿에만 있다.
