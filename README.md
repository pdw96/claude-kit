# claude-kit

Claude Code 플러그인 마켓플레이스. **원본과 이력이 사는 곳**이고, 실제로 프로젝트에서 뜨는 것은 여기가 아니라 각 레포의 사본이다.

## 들어 있는 것

| 플러그인 | 무엇 |
|---|---|
| `vibe-audit` | 목적별로 범위를 좁힌 읽기전용 감사자 6종 — 시크릿 · 데이터 · 검사장치 · 운영 · 계약 · 내부규칙 |
| `vibe-slice` | 프로젝트를 조각으로 나눠 진행하는 문서 틀 넷 — 의도 · 마스터플랜 · 조각 요구사항 · 설계(스킬 `slice-docs`), 리뷰 지적을 그 조각의 설계에 비춰 가르는 법(스킬 `slice-review`) |

## 설치 — 경로가 둘인 이유

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
claude plugin install vibe-slice@pdw96-kit
```

호출 이름이 `@vibe-audit:audit-secrets` · `/vibe-slice:slice-docs` 로 **스코프가 붙는다.**

**새 판은 리로드만으로 오지 않는다** — 이 마켓플레이스는 자동 갱신이 기본으로 꺼져 있다. 받으려면
`claude plugin marketplace update pdw96-kit` 뒤 `claude plugin update <플러그인>@pdw96-kit` 을 돌리고 리로드한다
(`/plugin` 에서 `pdw96-kit` 의 자동 갱신을 켜 둬도 된다). 이미 `pdw96-kit` 을 붙인 계정이 `vibe-slice` 를 처음 깔 때도
`marketplace update` 가 먼저다.

### ② 클라우드 레인 — 레포 사본

`claude/...` 가지에서 도는 세션은 위 경로를 받지 못한다. 그 레포의 `.claude/agents/` 에 파일이 있어야 뜬다.

```bash
./scripts/sync-agents.sh ~/src/ERP    # 감사자 · 브리핑 커맨드 · 검사기 → .claude/agents · commands · scripts
./scripts/sync-slice.sh ~/src/ERP     # vibe-slice 의 스킬 → .claude/skills/slice-docs · slice-review
```

호출 이름은 스코프 없이 `@audit-secrets`. 사본은 그 레포에 맞게 갈려도 된다 — 어느 쪽으로 무엇을 되돌리는지는 [의도](INTENT.md).

## 새 프로젝트를 열 때

1. `scripts/sync-agents.sh <새 레포>` — 감사자 여섯을 심는다(클라우드 레인이면 `scripts/sync-slice.sh` 도)
2. 계정 스킬 `project-kickoff` 으로 착공
3. 스킬 `slice-docs` 로 마스터플랜을 세워 조각을 나눈다 — 의도는 착공의 `PRD.md` 를 가리킨다
4. 첫 조각이 끝나면 `@audit-data` 부터

계정에 붙어 있는 스킬 넷(`project-kickoff` · `build-gate` · `separate-audit` · `ai-native-build`)은 설치가 필요 없다.

무엇을 언제 감사할지와 부적합을 닫힐 때까지 따라가는 일은 계정 스킬 `separate-audit` 이 맡는다 — 이 플러그인의 감사자
여섯은 그 계획이 넘겨주는 개별 감사만 한다.

## 가리키는 곳

| 무엇 | 어디 |
|---|---|
| 왜 있고 무엇을 하고 무엇은 안 하나 | [`INTENT.md`](INTENT.md) |
| 무엇을 어떤 순서로 하나 — 조각 나눔과 가리키는 문서 | [`docs/master-plan.md`](docs/master-plan.md) |
| 부품과 흐름 — 심기 · 견주기 · 판정 · 되먹임 · 수트 | [`docs/architecture.md`](docs/architecture.md) |
| 감사자를 어떻게 재나 — 케이스와 재는 법 | [`vibe-audit/evals/README.md`](vibe-audit/evals/README.md) |
| 작업 규칙 | [`CLAUDE.md`](CLAUDE.md) · [`AGENTS.md`](AGENTS.md) |
