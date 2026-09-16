# claude-kit

Claude Code 플러그인 마켓플레이스. **원본과 이력이 사는 곳**이고, 실제로 프로젝트에서 뜨는 것은 여기가 아니라 각 레포의 사본이다.

## 들어 있는 것

| 플러그인 | 무엇 |
|---|---|
| `vibe-audit` | 목적별로 범위를 좁힌 읽기전용 감사자 6종 — 시크릿 · 데이터 · 검사장치 · 운영 · 계약 · 내부규칙 |

## 배포 경로가 둘인 이유

**하나로 안 된다.** 프로젝트 레포가 `.claude/settings.json` 에 마켓플레이스를 선언해서 세션이 자동으로 받게 하는 길(`extraKnownMarketplaces` · `enabledPlugins`)이 열린 버그 셋을 달고 있다.

| 이슈 | 증상 |
|---|---|
| [#78119](https://github.com/anthropics/claude-code/issues/78119) | 클라우드 샌드박스 · CI 에서 통째로 무시된다 |
| [#32606](https://github.com/anthropics/claude-code/issues/32606) | 로컬에서도 자동 설치 안 됨. 오류도 안 뜬다 |
| [#13097](https://github.com/anthropics/claude-code/issues/13097) | 대화형 신뢰 승인을 요구 — 헤드리스 불가 |

그래서 **대화형 세션은 마켓플레이스로, 클라우드 레인은 레포 사본으로** 받는다. 위 버그가 닫히면 사본을 걷을 수 있다.

### ① 대화형 세션 — 마켓플레이스

계정에 한 번만 붙이면 로컬에서 여는 모든 레포에 뜬다.

```bash
claude plugin marketplace add pdw96/claude-kit
claude plugin install vibe-audit@pdw96-kit
```

호출 이름이 `@vibe-audit:audit-secrets` 로 **스코프가 붙는다.**

### ② 클라우드 레인 — 레포 사본

`claude/...` 가지에서 도는 세션은 위 경로를 받지 못한다. 그 레포의 `.claude/agents/` 에 파일이 있어야 뜬다.

```bash
./scripts/sync-agents.sh ~/src/ERP
```

호출 이름은 스코프 없이 `@audit-secrets`.

## 사본은 갈려도 된다 — 방향만 정해 둔다

> **원본은 일반형, 사본은 그 레포에 특화된다. 되먹이지 않는다.**

감사자는 레포를 읽을수록 좋아진다. 체크 항목이 「테스트가 있는가」에서 「골든케이스가 기준일을 고정하는가」로 내려가는 순간 값이 나온다 — 그런 항목은 그 레포에서만 참이므로 **사본에만 산다.**

그래서 사본을 고친 것을 여기로 올리지 않는다. 여기는 아무 레포에도 안 들어가 본 일반형으로 남아 있어야 다음 프로젝트에 부을 수 있다.

`sync-agents.sh` 가 각 파일 머리에 출처 커밋을 박아 두므로, 사본이 얼마나 멀어졌는지는 그 줄로 잰다.

**특화 항목은 첫 감사를 돌린 뒤에 얹는다.** 미리 지어낸 체크 항목은 재지 않고 단정한 것이다.

## 감사 계획과 부적합 대장

무엇을 언제 돌릴지와 부적합 추적은 계정 스킬 `separate-audit` 이 맡는다. 스킬은 계정 경유로 클라우드 레인까지 도달하므로 여기서 배포하지 않는다.

## 새 프로젝트를 열 때

1. `scripts/sync-agents.sh <새 레포>` — 감사자 여섯을 심는다
2. 계정 스킬 `project-kickoff` 으로 착공
3. 첫 조각이 끝나면 `@audit-data` 부터

계정에 붙어 있는 스킬 넷(`project-kickoff` · `build-gate` · `separate-audit` · `ai-native-build`)은 설치가 필요 없다.
