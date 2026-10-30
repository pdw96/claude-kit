# claude-kit

Claude Code 플러그인 마켓플레이스. **원본과 이력이 사는 곳**이고, 실제로 프로젝트에서 뜨는 것은 여기가 아니라 각 레포의 사본이다.

## 들어 있는 것

| 플러그인 | 무엇 |
|---|---|
| `vibe-audit` | 목적별로 범위를 좁힌 읽기전용 감사자 6종 — 시크릿 · 데이터 · 검사장치 · 운영 · 계약 · 내부규칙 |
| `vibe-slice` | 프로젝트를 조각으로 나눠 진행하는 문서 틀 여섯 — 의도 · 마스터플랜 · 작업 규칙(`CLAUDE.md`) · 프로필(`Profile.md`) · 조각 요구사항 · 설계 — 과 부적합 대장의 틀(스킬 `slice-docs`), 리뷰 지적을 그 조각의 설계에 비춰 가르는 법(스킬 `slice-review`) |

## 설치 — 경로가 셋인 이유

**하나로 안 된다.** 프로젝트 레포가 `.claude/settings.json` 에 마켓플레이스를 선언해서 세션이 자동으로 받게 하는 길(`extraKnownMarketplaces` · `enabledPlugins`)이 열린 버그 셋을 달고 있다 — 클라우드 세션은 이 길을 건너뛴다(`SKIP_PLUGIN_MARKETPLACE=true`).

| 이슈 | 증상 |
|---|---|
| [#78119](https://github.com/anthropics/claude-code/issues/78119) | 클라우드 샌드박스 · CI 에서 통째로 무시된다 |
| [#32606](https://github.com/anthropics/claude-code/issues/32606) | 로컬에서도 자동 설치 안 됨. 오류도 안 뜬다 |
| [#13097](https://github.com/anthropics/claude-code/issues/13097) | 대화형 신뢰 승인을 요구 — 헤드리스 불가 |

그래서 세션을 연 자리마다 받는 길이 다르다.

| 세션 | 받는 길 | 부르는 이름 |
|---|---|---|
| 로컬 대화형 세션 | ① 마켓플레이스 | `@vibe-audit:audit-secrets` · `/vibe-slice:slice-docs` |
| 앱에서 연 클라우드 세션 | ② 계정 동기화 | ① 과 같다 |
| 그 밖에서 잰 것 — 세션이 도구(`create_session`)로 연 클라우드 세션 | ③ 레포 사본 | `@audit-secrets` · `/slice-docs`(스코프 없음) |

클라우드 쪽은 2026-10-30(CLI 2.1.314)에 같은 계정 · 같은 환경으로 쟀다 — 앱에서 연 세션에는 동기화본이 왔고, 도구로 연 세션에는 오지 않았다. 웹에서 연 세션 ·
예약 작업 · Slack · CI 는 재지 않았다. 레포 사본은 그 밖에 **특화가 있는 레포**의 자리다(③).

### ① 로컬 대화형 세션 — 마켓플레이스

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

### ② 앱에서 연 클라우드 세션 — 계정 동기화

claude.ai 계정에 이 저장소를 마켓플레이스로 붙이고 `vibe-audit` · `vibe-slice` 를 켜 두면, 앱에서 여는 클라우드 세션이 열릴 때 그 둘을 받는다
(`CLAUDE_CODE_SYNC_PLUGINS=1` · `~/.claude/plugins/synced/`). 레포에 아무것도 심지 않아도 된다. 호출 이름은 ① 처럼 스코프가 붙는다. 세션 중간에 레포를 붙여
등록해도 그 레포의 사본은 곧바로 실리지 않았고, 세션이 다시 시작된 뒤에 실렸다(2026-10-30).

### ③ 레포 사본 — 특화가 있는 레포

사본은 그 레포에 맞게 고친 감사자 · 스킬을 두는 자리다. **특화가 있는 레포** — 후보 대장(`feedback.json`)에 그 레포의 특화(`specific`) 판정이 있는 레포 — 와
동기화가 닿지 않는 세션에서 쓰는 레포만 심는다. 특화가 없으면 ② 로 원본을 받는다. 그 레포의 `.claude/agents/` 에 파일이 있어야 뜬다.

```bash
./scripts/sync-agents.sh ~/src/ERP            # 처음 심기 — 감사자 · 브리핑 커맨드 · 검사기 → .claude/agents · commands · scripts
./scripts/sync-agents.sh ~/src/ERP --merge    # 다시 심기 — 늘 이것. 사본의 특화를 지키며 세 쪽 병합, 걸리면 아무것도 안 쓴다
./scripts/sync-slice.sh ~/src/ERP             # vibe-slice 의 스킬 → .claude/skills/slice-docs · slice-review
```

`--force` 는 사본을 일부러 원본으로 되돌릴 때만 쓴다 — 특화가 사라진다. `--merge` 가 멈추면(충돌 · 원본의 파일 묶음이 바뀜 등)
그 심기는 손으로 세 쪽 병합한다 — 충돌이면 스크립트가 찍은 임시 폴더에 재료와 충돌 표시 병합본이 있다.

호출 이름은 스코프 없이 `@audit-secrets`. 사본은 그 레포에 맞게 갈려도 된다 — 어느 쪽으로 무엇을 되돌리는지는 [의도](INTENT.md).

**사본 레포의 앱 세션에는 두 벌이 뜬다.** 앱에서 연 클라우드 세션은 ② 의 원본도 받으므로, 감사자 여섯 · `audit-brief` · `slice-docs` · `slice-review` 가 다
둘씩 뜬다(2026-10-30 ERP). 스코프 없는 이름(`@audit-data` · `/slice-docs`)은 그 레포의 사본을, `vibe-audit:` · `vibe-slice:` 를 붙인 이름은 원본을 부른다.
**특화로 감사하려면 스코프 없는 이름으로 부른다** — 세션이 설명만 보고 고를 때 어느 쪽이 잡히는지는 재지 않았다. 레포 설정으로는 원본을 끌 수 없었다 —
`.claude/settings.json` 의 `enabledPlugins` 에 `vibe-audit` · `vibe-slice` 를 `@claude-kit` 꼴로도 `@pdw96-kit` 꼴로도 `false` 로 둬도 다 떴다(2026-10-30). 계정에서 끄면
모든 레포에서 꺼진다.

## 새 프로젝트를 열 때

1. 설치를 고른다 — 로컬은 ①, 앱에서 여는 클라우드 세션은 ② 로 이미 받는다. 그 레포에 특화가 생기거나 동기화가 닿지 않는 세션에서 쓰면 `scripts/sync-agents.sh <레포>` 로 감사자 여섯을 심는다(스킬도 그렇다면 `scripts/sync-slice.sh`) — ③
2. 스킬 `slice-docs` 로 의도 · 마스터플랜 · 작업 규칙(`CLAUDE.md`)을 세워 조각을 나눈다
3. 조각마다 요구사항 「제약」에 감사 회차를 적고 닫기 전에 돌린다

감사자 여섯은 개별 감사만 한다. 부적합을 닫힐 때까지 따라가는 대장은 `vibe-slice` 의 틀을
베껴 세운다(자리는 [시스템 구조](docs/architecture.md)). 무엇을 언제 감사할지는 조각 요구사항의 감사 회차가 든다 — 고르는 법은 [절차 지도](docs/procedure.md) 「감사 회차」,
바뀐 것에 맞는 감사자는 [`vibe-audit/README.md`](vibe-audit/README.md) 「대략의 주기」.

## 가리키는 곳

| 무엇 | 어디 |
|---|---|
| 왜 있고 무엇을 하고 무엇은 안 하나 | [`INTENT.md`](INTENT.md) |
| 무엇을 어떤 순서로 하나 — 조각 나눔과 가리키는 문서 | [`docs/master-plan.md`](docs/master-plan.md) |
| 부품과 흐름 — 심기 · 견주기 · 판정 · 되먹임 · 수트 | [`docs/architecture.md`](docs/architecture.md) |
| 감사자를 어떻게 재나 — 케이스와 재는 법 | [`vibe-audit/evals/README.md`](vibe-audit/evals/README.md) |
| 작업 규칙 | [`CLAUDE.md`](CLAUDE.md) · [`AGENTS.md`](AGENTS.md) |
