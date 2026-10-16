# 조각 23 — 사본을 0.4.1 로 다시 심기 (2026-10-16 착공)

요구사항이다 — **무엇을 · 왜.** 어떻게 · 경계는 같은 폴더의 `design.md`, 대안이 있던 결정은 ADR 0034 — 심는 법 · 충돌을 푸는 규칙 ·
출처 커밋의 규칙은 ADR 0027 을 그대로 따른다.

이 조각을 「다음 조각」으로 적은 것은 조각 22 의 `## 닫으며 (2026-10-16)` 이다 — 그 기록의 「넘긴 것」 · 「지켜본 것」을 읽고 착공한다
(ADR 0012). 「넘긴 것」 하나가 이 조각이다 — 성공 기준에서 못 미친 몫이 아니라 배포의 남은 몫이다. 다른 하나(「`gate-catches-unproven` 의
흔들림」)와 「지켜본 것」 넷은 감사자 측정의 일이라 이 조각이 다루지 않는다(하지 않을 일 7).

## 문제

**원본의 고침이 다시 실제 쓰임에 닿지 않는다.** 조각 22 가 `audit-secrets` 「보지 않는 것」 첫 문단의 끝 문장을 새 2 로 바꿨다(`5d7f22e`,
판 0.4.1) — 본 성능을 「담당 없음 — 호출자 판단 필요」 아래 항목으로 올리게 하는 문장이다. 옛 문장으로는 같은 머리에서 열두 회차 가운데 셋이
그 성능을 표식 아래로 올리지 않았다(조각 22 「판정(J4 · J5)」). 감사자를 쓰는 두 레포(ERP · 강호쟁패)는 사본만 쓰고(ADR 0022 의 1) 사본은
0.4.0(`018842c`)이다.

- **얼마나 뒤인가.** 2026-10-16 의 `verify-copies.py` → `PASS 사본 2개` — 두 줄 다 「공통 절이 018842c 의 원본과 같음 (원본은 그 뒤 1 커밋
  움직임 — 바뀐 원본: audit-secrets.md)」. `git diff --stat 018842c ddcd21f -- vibe-audit/agents vibe-audit/commands vibe-audit/scripts` 는
  `audit-secrets.md` 한 줄이다. `ddcd21f` 뒤 `main`(`e90400f`)까지 `vibe-audit/` 와 `scripts/sync-agents.sh` 는 움직이지 않았다.
- **강호쟁패는 막는 것이 없다.** 사본 여덟 파일이 `018842c` 를 `sync-agents.sh` 로 심은 모양과 바이트로 같고, `.claude/agents/README.md` 도
  그 스크립트의 생성본 그대로다(2026-10-16, 강호쟁패 `ab2748e`).
- **ERP 는 덮으면 특화가 사라진다.** 조각 17 과 같다 — `--force` 는 감사자 · 커맨드 · 검사기와 README 를 다 덮고, ERP 사본의 덩어리는
  `feedback.json` 의 후보로 판정돼 있다. `compare-copies.py` 는 2026-10-16 에 `후보 27 — 미판정 0 · 판정됨 27(새 레포 0)` 이다.
- **세 쪽 병합이면 얼마나 남는가.** 2026-10-16 에 스크래치에서 재 봤다 — 밑(`018842c` 를 심은 모양) · 사본(ERP `1046566` · 강호쟁패 `ab2748e`)
  · 새 원본(`ddcd21f` 를 심은 모양)을 파일마다 `git merge-file` 로 견주면 두 레포 다 여덟 파일 충돌 0 이다. ERP 쪽에서 바뀌는 줄은 아홉 —
  감사자 여섯 · 커맨드의 머리줄 일곱(SHA 한 자리)과 `audit-secrets` 의 그 한 줄, 그리고 README 3 줄의 출처 SHA 다. 그 모의본에 `ddcd21f` 를
  든 스크래치 대장으로 비교기를 대면 `후보 27 — 미판정 0 · 판정됨 27` 이고, `verify-copy.py vibe-audit/agents <모의본>` 이 `PASS 감사자 6개` 다.
  조각 17 의 충돌 여덟과 달리 사람이 풀 자리가 없다.

## 핵심 사용자와 시나리오

- 사용자: claude-kit 의 저자(ERP · 강호쟁패의 소유자이기도 하다), 그리고 두 레포에서 감사를 돌리는 세션.
- 시나리오: 세션이 claude-kit `ddcd21f` 의 작업트리에서 강호쟁패에 `sync-agents.sh --force` 를 돌려 강호쟁패 PR 을 연다 → ERP 는 세 쪽
  병합을 하고, 충돌이 0 인지와 바뀐 줄 아홉을 ERP PR 본문에 적는다 → 저자가 두 PR 을 가르고 머지한다 → claude-kit 대장 PR 에서
  `copies.json` 두 줄을 `ddcd21f` 로 옮긴다 → 두 레포의 다음 `audit-secrets` 회차가 본 성능을 「담당 없음 — 호출자 판단 필요」 아래 항목으로
  올린다 → 조각을 닫는 기록이 조각 나눔에 `sync-agents.sh --merge` 줄을 더한다.

## 성공 기준

1. 강호쟁패 사본이 `ddcd21f` 원본 그대로다 — 덮기 전에 사본이 `018842c` 를 심은 모양 그대로인지 본 결과(설계 ② S0)가 강호쟁패 PR 본문에
   있고, 그대로였으면 감사자 · 커맨드의 머리줄 일곱이 `pdw96/claude-kit@ddcd21f`, 검사기는 원본과 `cmp` 같고, 클론을 원격 기본 가지 머리로
   두고 `copies.json` 이 `ddcd21f` 를 든 뒤 `compare-copies.py --repo ganghojaengpae --all` 이 후보 0 이다. 그대로가 아니었으면 강호쟁패도
   성공 기준 2 · 3 의 ERP 와 같은 기준이다.
2. ERP 사본이 원본의 고침을 받았다 — ERP PR 의 감사자 · 커맨드 · 검사기가 「설계 ② M1 의 세 재료로 `git merge-file` 을 돌린 결과」와
   바이트로 같다. 그 결과로 `audit-secrets` 「보지 않는 것」 첫 문단의 끝 문장이 `ddcd21f` 원본과 같은 글자로 있다.
3. ERP 특화가 산다 — ERP 머지 뒤 `compare-copies.py --repo erp --all` 이 지금의 판정된 해시 스물일곱을 그대로 내고 새 후보가 없다.
   `git diff --name-only` 는 `.claude/agents/` 일곱(감사자 여섯 · `README.md`)과 `.claude/commands/audit-brief.md` 뿐이고, README 는 3 줄의
   출처 SHA 한 자리(`018842c` → `ddcd21f`)만 바뀐다.
4. 대장 — `copies.json` 두 줄의 `synced_commit` 이 `ddcd21f` 의 전체 SHA 다. 강호쟁패 줄은 `sync-agents.sh` 가 적은 줄이고(설계 ② S0 이
   세 쪽 병합으로 돌렸으면 ERP 와 같이), ERP 줄은 `verify-copy.py` PASS 를 본 뒤 손으로 옮긴다(`CLAUDE.md` 「금지」). 두 클론이 있는 세션에서 `verify-copies.py` → `PASS 사본 2개`, 두 줄 다
   「원본은 그 뒤 0 커밋 움직임」이고 「바뀐 원본」이 없다.
5. 미판정 0 — 두 클론을 원격 기본 가지 머리로 두고 `compare-copies.py` 가 끝 0 · `미판정 0` 이다. 새 후보가 나오면 저자가 판정해
   `feedback.json` 에 이어지는 번호로 적고, `verify-feedback.py` 가 통과한다. 안 나오면 `feedback.json` 은 그대로다.
6. 원본은 그대로다 — 이 조각의 claude-kit PR 은 `vibe-audit/` · `vibe-slice/` · `scripts/` 를 고치지 않는다. 수트 지문(`eval-key.py route --list`
   · `full --list`)과 각 PR 의 `git diff --name-only` 의 교집합이 0 이다.
7. `./scripts/gates.sh` 가 claude-kit PR 마다 로컬과 CI gate 잡에서 통과하고 검사 수는 스물넷 그대로다.
8. `--merge` 줄 — 조각을 닫는 기록이 조각 나눔에 `sync-agents.sh --merge` 의 순서 없는 줄을 더하고, 그 줄이 이 조각 C 의 병합 결과(파일마다
   충돌 수 · 바뀐 줄 수)와 조각 17 C 의 충돌 여덟을 근거로 든다(ADR 0034 의 1).

## 하지 않을 일

1. **`sync-agents.sh` 에 병합 모드를 세우지 않는다** — ERP 는 ADR 0027 의 1 대로 손으로 세 쪽 병합을 한다. 줄을 더하는 것은 닫는 기록이고,
   세우는 것은 그 줄의 조각이다(ADR 0034 의 1).
2. **원본을 고치지 않는다** — 감사자 · 커맨드 · 검사기 · 판 · `sync-agents.sh`.
3. **ERP 의 특화를 새로 쓰지 않고 겹침을 정리하지 않는다** — 「감사한 커밋」 줄 두 자리(조각 17 「지켜본 것」)는 ERP 의 일이다
   (`INTENT.md` Not 4).
4. **판정된 후보를 고치지 않는다** — 후보 스물일곱의 상태 · `seen` · `reason` 은 그대로다. 대장에는 새 후보만 더한다.
5. **두 레포의 감사를 돌리지 않고 eval 도 돌리지 않는다** — 원본이 바뀌지 않는다. 새 문장이 실제 기록에서 일하는지는 그 레포의 다음 회차다.
6. **플러그인 설치 쪽과 사본 밖의 파일을 건드리지 않는다** — 두 레포가 사본만 쓰는 설정(ADR 0022 의 1), 강호쟁패 `.gitignore`(조각 17
   「지켜본 것」)는 그대로다.
7. **조각 나눔의 다른 줄을 다루지 않는다** — 「`gate-catches-unproven` 의 흔들림」 · 「`brief-absent` 의 떨어짐」 · 회수율 측정 · 가르지 못한
   결함 다섯 · 항목 10 과 머리의 어긋남 · 가르지 못한 빈 갈래 둘. 조각 22 「지켜본 것」 넷도.

## 제약

- 스택: bash · python3 표준 라이브러리 · git(`git merge-file` · `git worktree`) · `sync-agents.sh` · `verify-copy.py` · `verify-copies.py` ·
  `compare-copies.py` · `verify-feedback.py`.
- 원본 커밋: `ddcd21f`(`vibe-audit` 0.4.1 — 조각 22 의 구현 PR #85 의 머지). 2026-10-16 의 `main`(`e90400f`)까지 `vibe-audit/` 와
  `scripts/sync-agents.sh` 는 그 뒤 움직이지 않았다. 조각 중에 움직이면 멈추고 저자에게 올린다.
- 사본 레포 쓰기: 두 레포에 브랜치를 밀고 PR 을 연다 — 머지는 저자다. 강호쟁패는 「커밋/푸시는 도원이 요청할 때만」(그 레포 `CLAUDE.md`)
  이라 저자가 이 조각의 세션에 요청하면 그 세션이 민다(저자, 2026-10-16 착공 PR #87 의 인터뷰). ERP 는 공개 저장소라 익명 클론으로
  읽고, 밀 때 `add_repo`(push)로 붙인다. 두 PR 은 그 레포의 리뷰 규칙(ERP `docs/리뷰-루프.md`, 강호쟁패 ADR-0005 · `CLAUDE.md` 「PR · 리뷰」)도 따른다.
- 순서: 대장 PR 은 두 사본 PR 이 머지된 뒤다 — 비교기는 사본 레포가 원격 기본 가지보다 뒤면 멈추고(ADR 0003), 대장이 머지되지 않은 사본
  커밋을 출처로 들면 안 된다.
- 클론: claude-kit 은 역사 전체(`git fetch --unshallow`) — `--force` 가 물러난 파일을 역사에서 찾는다. ERP 는 익명 클론(`GIT_LFS_SKIP_SMUDGE=1`),
  강호쟁패는 `add_repo` 뒤 `Assets/TutorialInfo/Icons/URP.png` 를 `assume-unchanged` 로 재운다. 두 클론은 대장의 `agents_path` 자리
  (`/home/user/erp` · `/home/user/ganghojaengpae`)에 둔다.
- 비용: 모델 호출이 없다 — eval · 전수를 돌리지 않는다.
- 판정: 새 후보가 나오면 그 판정은 저자다(`CHECKLIST.md` 「대장을 건드렸다면」).
- 기간: **이틀**(2026-10-17 까지).
- 리뷰: PR 본문에 설계 ② 를 적고, 착공 PR 도 대장 PR 도 스킬 `slice-review` 로 가른다. **3라운드**를 넘기면 소유자가 판정한다.

## 닫으며 (2026-10-16)

저자가 닫았다. 성공 기준 여덟을 아래에 대어 봤다 — 다 미쳤다. 구현은 설계 ⑥ 의 넷 그대로다 — A 착공 #87(머지 dde13f1), B 강호쟁패
pdw96/ganghojaengpae#13(머지 82af872), C ERP pdw96/ERP#113(머지 6dda439), D 대장 #88(머지 1d720eb). 단계 5 는 B · C 의 머지였다 —
아래 「배포」. ADR 0034 의 4(충돌이 나면)는 쓰이지 않았다 — 두 레포 다 충돌 0 이다.

| 성공 기준 | 무엇에 대어 봤나 |
|---|---|
| 1. 강호쟁패 사본이 `ddcd21f` 원본 그대로다 | #13 — S0: `git fetch` 뒤 `origin/main`(ab2748e)의 사본 여덟 · `.claude/agents/README.md` 가 `018842c` 작업트리의 `sync-agents.sh` 로 빈 자리에 심은 모양과 아홉 다 `cmp` 같음 → `--force` 로 갔다. S1: `ddcd21f` 작업트리의 `sync-agents.sh --force`(감사자 심음 6 · 커맨드 1 · 검사기 1 · 지움 0, 「기본 브랜치에 없다」 경고 없음), 머리줄 일곱이 `pdw96/claude-kit@ddcd21f`, `verify-brief.py` 는 원본과 `cmp` 같음, `git diff --name-only` 여덟이 설계 ① B 줄 안, `verify-copy.py` → `PASS 감사자 6개`. S2: 클론을 `origin/main`(82af872)에 두고 `copies.json` 이 `ddcd21f` 를 든 #88 머리에서 `compare-copies.py --repo ganghojaengpae --all` → `후보 0 — 미판정 0 · 판정됨 0` |
| 2. ERP 사본이 원본의 고침을 받았다 | #113 — M1 의 세 재료로 파일마다 `git merge-file`, 여덟 다 충돌 0 이고 바뀐 줄이 설계 ③ 의 표와 같다(감사자 다섯 · 커맨드 1 · `audit-secrets` 2 · `verify-brief.py` 0). 그 PR 본문의 `m1.sh` 를 새 스크래치에서 다시 돌려 여덟 파일이 PR 과 `cmp` 같음(M6), 병합본 한 줄을 바꾸면 `cmp` 가 떨어짐. `audit-secrets` 「보지 않는 것」 첫 문단의 끝 문장이 `ddcd21f` 원본의 그 줄과 `grep -cxF` 1(M3). `verify-copy.py <ddcd21f 의 vibe-audit/agents> .claude/agents` → `PASS 감사자 6개`(M4) — #88 의 세션에서 머지 머리 6dda439 에 다시 봤다 |
| 3. ERP 특화가 산다 | #88 머리에서 `compare-copies.py --repo erp --all` 이 판정된 스물일곱을 그대로 낸다(특화 스물 · 결함 셋 FB-30 · 31 · 34 · 되먹임 둘 FB-18 · 24). `--json` 의 후보 해시 스물일곱이 C 의 머지 전(ERP `main` · 대장 `018842c`)과 같은 집합이다. `git diff --name-only c75c215 6dda439` 는 `.claude/agents/` 일곱 · `.claude/commands/audit-brief.md` 뿐이고, README 의 diff 는 3 줄의 `018842c` → `ddcd21f` 하나다(M5) |
| 4. 대장 | #88 — `copies.json` 두 줄 `ddcd21f7d359…` · `2026-10-16`. 강호쟁패 줄은 S1 의 작업트리 `copies.json` 에 `sync-agents.sh` 가 적은 줄과 JSON 으로 같고, ERP 줄은 위 2 의 `verify-copy.py` PASS 뒤 손으로 옮겼다. `verify-copies.py` → `PASS 사본 2개`, 두 줄 다 「원본은 그 뒤 0 커밋 움직임」, 「바뀐 원본」 없음 |
| 5. 미판정 0 | #88 머리에서 `compare-copies.py` → `후보 27 — 미판정 0 · 판정됨 27(새 레포 0)`, 끝 0. 새 후보가 없어 `feedback.json` 은 그대로다. `verify-feedback.py` → `PASS 후보 37 — 특화 24 · 결함 7 · 보류 0 · 되먹임 완료 6` |
| 6. 원본은 그대로다 | claude-kit PR 의 바꾼 파일 — #87 `docs/` 넷, #88 `copies.json`, 이 닫는 기록 `docs/` 둘 — 에 `vibe-audit/` · `vibe-slice/` · `scripts/` 가 없다. 셋 다 `eval-key.py route --list` ∪ `full --list` 와의 교집합 0, CI eval 잡이 건너뛰었다. `git diff --stat ddcd21f 1d720eb -- vibe-audit/ vibe-slice/ scripts/` 는 비었다 |
| 7. `gates.sh` | 로컬 스물넷 통과 — #87 의 세 커밋 머리, #88 `46e15bd`, 이 닫는 기록의 커밋 전 작업트리. CI gate 잡 — #87 `0199796`([run 38891309270](https://github.com/pdw96/claude-kit/actions/runs/38891309270)) · #88 `46e15bd`([run 38896166327](https://github.com/pdw96/claude-kit/actions/runs/38896166327)) · `main` 푸시 dde13f1([run 38892447983](https://github.com/pdw96/claude-kit/actions/runs/38892447983)) · 1d720eb([run 38898852262](https://github.com/pdw96/claude-kit/actions/runs/38898852262)) 통과. 검사 수는 스물넷 그대로다 |
| 8. `--merge` 줄 | 이 기록의 「넘긴 것」이 조각 나눔에 `sync-agents.sh --merge` 의 순서 없는 줄을 더한다. 근거는 #113 의 파일별 표(여덟 파일 충돌 0 · 바뀐 줄 1 · 1 · 1 · 1 · 1 · 2 · 1 · 0)와 조각 「사본 다시 심기」 C(pdw96/ERP#111)의 충돌 여덟이다(ADR 0034 의 1) |

### 배포

배포가 곧 B · C 의 머지다(설계 ⑤ 「단계 5」) — 두 레포는 사본만 쓴다(ADR 0022 의 1). 2026-10-16 에 둘 다 머지됐다. 새 문장이 실제
회차에서 일하는지(본 성능을 「담당 없음 — 호출자 판단 필요」 아래 항목으로 올리는가)는 두 레포의 다음 `audit-secrets` 회차가 보인다(하지
않을 일 5). 되돌리는 길은 두 레포에서 그 머지를 되돌리고 #88 을 되돌리는 것이다 — 대장이 `018842c` 로 돌아간다.

### 제약에서 어긋난 것

- **ERP `main` 이 그사이 움직였다** — 설계 ③ 은 ERP `main` 을 `1046566` 으로 적었는데, C 를 낼 때는 dependabot 머지(pdw96/ERP#112)로
  `c75c215` 였다. `git diff --stat 1046566 c75c215 -- .claude` 가 비어 병합 재료는 같고, C 의 가지는 `c75c215` 위에 섰다(#113 본문 「검증」).
  설계 ② 「보장하지 않는 것」의 「사본을 또 고친다」는 아니다 — 사본은 그대로였다.
- **강호쟁패의 자체 리뷰** — 그 레포 `CLAUDE.md` 는 PR 전에 `/code-review` 를 든다. B 는 그것 대신 diff 가 `ddcd21f` 생성본과 바이트로
  같음을 `cmp` 로 보고 PR 본문 「자체 리뷰」에 적었다 — 조각 「사본 다시 심기」 B(#12)와 같은 갈래다.
- **머지한 손** — #13 · #113 · #88 은 저자가 대화에서 「머지해」라고 시킨 뒤 세션이 머지 커밋으로 머지했다. 머지를 정한 것은 저자다.
- 그 밖은 없다. 착공부터 이 기록까지 하루(2026-10-16)로 이틀 안이다. 리뷰는 PR 마다 3라운드 안이다. 원본 · 앵커볼트 · `sync-agents.sh` ·
  `eval.yml` · `run-evals.sh` 는 고치지 않았다. eval · 전수는 돌리지 않았다(모델 호출 없음).

### 리뷰가 찾은 갈래

- #87 1회차 — 안 하나(B 의 사전 검사가 원본만 봐 강호쟁패 사본이 그사이 움직이면 `--force` 가 말없이 덮는다). 0199796 에서 ② S0 을
  세우고 같은 갈래를 함께 고쳤다. 2회차 지적 0.
- pdw96/ganghojaengpae#13 1회차 — Codex 지적 0. CodeRabbit 은 리뷰 한도에 걸려 요약만 남겼다(지적 아님).
- pdw96/ERP#113 1회차 — Codex 지적 0. 그 레포 `docs/리뷰-루프.md` 의 점수 추이 `0`.
- #88 1회차 — 지적 0.

말하지 않음은 없다.

### 지켜본 것 — 줄을 더하지 않는다

증거가 해를 보이지 않거나 그 레포의 일이라 조각 나눔에 줄을 더하지 않는다.

- **ERP 의 「감사한 커밋」 줄 두 자리 · 강호쟁패 `.gitignore`** — 조각 「사본 다시 심기」 「지켜본 것」 그대로 남았다. 그 레포의 일이다.
- **대장에 적히는 `agents_path` 의 꼴** — `sync-agents.sh` 는 대상이 `$HOME` 아래면 `~/…` 로 적는다. 이 세션은 `HOME=/root` 라 대장의 절대
  경로 그대로였고, 그래서 강호쟁패 줄이 「스크립트가 적은 줄 그대로」와 「`agents_path` 는 그대로」(L1)를 함께 지켰다. `HOME=/home/user` 인
  세션이면 둘이 갈린다 — 다음 심기도 같은 자리에 클론을 둔다면 그 세션의 `HOME` 을 먼저 본다.
- **사본 레포 붙이기** — 강호쟁패를 `add_repo` 의 push 로 붙이는 것은 거절됐고, read 로 붙인 뒤에도 `git push` 는 지났다. ERP 는 push 로
  붙었다. 세션 환경의 일이라 줄을 더하지 않는다.
- **얕은 클론** — 이 세션의 claude-kit 클론도 얕아 `git fetch --unshallow` 뒤에 돌렸다(조각 「사본 다시 심기」 「닫으며」와 같다).

### 넘긴 것

- **`sync-agents.sh --merge`** — 조각 나눔에 순서 없는 새 줄. 손 병합을 두 번 겪었다 — 조각 「사본 다시 심기」 C 는 사람이 풀 충돌이
  여덟이었고, 이 조각 C 는 같은 명령을 되풀이해 여덟 파일 다 충돌 0 이었다. 뒤의 것이 `--merge` 가 할 일의 모양이다 — 충돌이 없으면 쓰고
  대장을 옮기며, 있으면 아무것도 쓰지 않고 멈춘다(ADR 0034 「결정」 1). 다음 심기 전에 꺼낼지는 그때 정한다.

이미 열려 있던 순서 없는 줄 — 「`brief-absent` 의 떨어짐」 · 「회수율 측정」 · 「가르지 못한 결함 다섯」 · 「항목 10 과 머리의 어긋남」 ·
「가르지 못한 빈 갈래 둘」 — 은 그대로 둔다.

다음 조각은 조각 나눔 「`gate-catches-unproven` 의 흔들림」(순서 24)(저자, 2026-10-16).
