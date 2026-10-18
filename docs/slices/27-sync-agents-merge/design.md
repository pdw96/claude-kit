# 조각 27 설계 — `sync-agents.sh --merge`

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`, 갈림길은 ADR 0038 — 충돌을 푸는 규칙은 ADR 0027 의 2.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A | 「`sync-agents.sh --merge`」 상태 `진행` · 조각 폴더 |
| `docs/adr/0038-sync-agents-merge.md` | A | 갈림길 열 |
| `scripts/sync-agents.sh` | B | `--merge` 길 — ② P · M. 머리의 쓰는 법에 한 줄. `--merge` 없는 길과 `--force` 는 바이트가 그대로다(요구사항 성공 기준 5) |
| `scripts/bite-gates.sh` | B | `sync-agents.sh` 절 끝에 ② T 의 시험. 지난 시험은 글자가 그대로 |
| `docs/architecture.md` | B | 「심기」 문단에 `--merge` 한 문장 |
| `README.md` | B | 「② 클라우드 레인 — 레포 사본」의 명령 블록에 `--merge` 한 줄 — 다시 심기는 늘 `--merge`, `--force` 는 일부러 되돌릴 때(ADR 0038 의 10) |
| `CHECKLIST.md` | B | 「대장을 건드렸다면」 첫 줄 — `sync-agents.sh`(`--merge` 포함)를 거쳤다, 손 병합이면 `verify-copy.py` PASS 와 PR 본문의 병합 재현 |

**앵커볼트.** 대장의 모양 — `copies.json` 의 칸은 그대로 쓴다(`--merge` 는 그 줄의 `synced_commit` · `synced_at` 만 바꾼다). 이름 · 감사자의
`tools` · 공통 절 · 「…의 칸」 · `AGENTS.md` 는 건드리지 않는다.

**고정 영역 · 수트.** `scripts/sync-agents.sh` · `scripts/bite-gates.sh` · `docs/` · `README.md` · `CHECKLIST.md` 는 수트 지문(`eval-key.py route --list` ·
`full --list`) 밖이다 — B 의 CI 는 eval 잡을 건너뛴다. `gates.sh` · `eval.yml` · `run-evals.sh` · `verify-copy.py` · `verify-copies.py` ·
`compare-copies.py` 는 그대로다.

**사실.**
- 지금 `sync-agents.sh`(`c56e571`)는 인자 하나(대상 레포)와 `--force` 를 받는다. 쓰기 전에 보는 것 — 원본의 커밋 안 된 변경 · HEAD 에 없는 파일 ·
  `--force` 의 얕은 복제 · 대장의 같은 이름 다른 자리 · (`--force` 없을 때) 대장에 없는 자리의 사본과 일부만 있는 사본 · 폴더 자리 · 파일 자리 — 를
  다 본 뒤 감사자 · 커맨드 · 검사기 · README 를 쓰고 대장 줄을 다시 쓴다. 감사자 · 커맨드는 awk 가 프론트매터 뒤에 `HDR` 을 넣고, 검사기는 바이트
  그대로다.
- 대장 줄을 쓰는 python 은 `agents_path` 를 그 실행의 `$HOME` 으로 다시 만든다 — 조각 23 「지켜본 것」의 갈림이 여기서 난다.
- 손 병합 두 번의 `synced_commit`(`3d6964a` · `018842c`)과 그 뒤 커밋(`ddcd21f`)의 `sync-agents.sh` 는 다 빈 자리에 감사자 여섯 · `audit-brief.md` ·
  `verify-brief.py` · README 를 심는다(2026-10-18 재현). `HDR` 꼴은 `c56e571` 에서 지금 꼴이 됐다 — `3d6964a` 는 옛 꼴이다.
- `git merge-file -p <사본> <밑> <원본>` 은 병합본을 표준 출력에 내고, 종료 코드가 충돌 수(127 에서 자른다)이고, 음수면 오류다.
- `verify-copy.py <원본 agents> <사본 agents>` 는 공통 절과 `tools` 를 글자 단위로 견준다.
- 원본 감사자 · 커맨드 · 검사기는 `ddcd21f` 뒤 움직이지 않았다(`git diff --stat ddcd21f 30bc0e2` 가 그 세 폴더에서 비었다).

**시스템 구조.** 부품은 그대로이고 「심기」의 흐름에 길이 하나 는다 — 특화가 있는 사본을 다시 심는 길이 손에서 스크립트로 온다. B 가
`docs/architecture.md` 「심기」를 고친다.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 번호는 ⑤ 와 PR 본문이 같이 쓴다.

- **전제 — 쓰기 전에 다 본다** (B)
  - P1 `--merge` 와 `--force` 를 함께 주면 아무것도 보기 전에 종료 코드 2.
  - P2 원본이 얕은 복제면 멈춘다 — 밑이 `synced_commit` 의 작업트리다(`--force` 의 멈춤과 같은 문구 꼴).
  - P3 대장에 대상의 `.claude/agents` 와 `agents_path` 가 같은 줄이 정확히 하나 있고, 그 `synced_commit` 이 이 저장소에 있다. 없으면 멈춘다 — 「사본을
    처음 심는 것은 `--merge` 없이」.
  - P4 `synced_commit` 이 HEAD 와 같으면 쓸 것이 없다고 찍고 아무것도 쓰지 않고 종료 코드 0. P4 는 P5 · P6 을 다 지난 뒤에 본다 — 뒤처지거나 더러운 사본은
    같은 커밋이어도 0 이 아니다(요구사항 성공 기준 2).
  - P5 지금 스크립트의 앞 검사 가운데 원본의 커밋 안 된 변경 · HEAD 에 없는 파일 · 같은 이름 다른 자리 · 폴더 자리 · 파일 자리는 `--merge` 에도 그대로
    진다. 「대장에 없는 자리 · 일부만 있는 사본」 검사는 `--force` 없을 때의 것이라 `--merge` 에는 M2 가 대신한다.
  - P6 사본 레포 — `compare-copies.py` 와 같은 기준(ADR 0003 · ADR 0038 의 8). 대상이 git 저장소 안이고, 원격 `origin` 의 기본 가지를 읽어 받은 뒤 HEAD 가
    그보다 뒤가 아니며, 사본 자리(감사자 · 커맨드 · 검사기)에 커밋 안 된 것이 없고(`status --porcelain --untracked-files=all`), M2 의 파일과 README 가 HEAD 에
    추적돼 있다 — `status` 는 무시된(ignored) 파일을 보이지 않으므로, 무시된 README 는 추적 검사가 잡는다. 못 읽거나 못 받으면 멈춘다 — 「모른다」를 「최신」으로 두지 않는다.
- **병합** (B) — 다 사본 밖 임시 폴더 하나에서 한다.
  - M1 재료 — 밑: `git worktree add --detach <임시>/wt-base <synced_commit>` 에서 그 커밋의 `scripts/sync-agents.sh` 를 빈 자리 `<임시>/base` 에 돌린
    모양(ADR 0038 의 2). 새 원본: 같은 식으로 HEAD 의 작업트리에서 `<임시>/new` 에. 돌리기 전에 두 작업트리의 `copies.json` 을 빈 대장(`{"copies": []}`)으로 비운다 —
    그 커밋의 스크립트는 대상 이름(`basename`)이 대장의 다른 자리 줄과 같으면 멈추므로, 대장에 `base` · `new` 라는 레포가 있어도 걸리지 않게. 두 대장은
    그 작업트리에만 쓰이고 버린다.
    사본: 대상의 `.claude/` 그 파일. 그 스크립트가 0 이 아닌 코드로 끝나면 멈춘다.
  - M2 파일 집합 — `base` 와 `new` 의 `agents/*.md`(README 밖) · `commands/*.md` · `scripts/*.py` 이름 목록이 같고, 사본에 그 이름이 다 일반 파일로 있다
    (링크 · 없음이면 멈춘다). 다르면 멈추고 다른 이름을 찍는다(ADR 0038 의 3). 사본에만 있는 레포 고유 파일은 보지도 쓰지도 않는다.
  - M3 파일마다 `git merge-file -p <사본> <밑> <새 원본>` 을 `<임시>/merged/` 에. 충돌 수가 하나라도 0 이 아니면(오류 포함) 멈춘다.
  - M4 README — `base` 와 `new` 의 README 에서 `pdw96/claude-kit@<짧은 SHA>` 를 하나씩 읽고, 사본 README 에 밑의 그것이 뒤에 16진 글자 없이 **정확히
    하나** 있으면 새 짧은 SHA 로 바꾼 것을 `merged/` 에. 0 이거나 둘 이상이거나 사본 README 가 없으면 멈춘다(ADR 0038 의 1). README 의 다른 바이트는
    그대로다.
  - M5 `verify-copy.py <원본 vibe-audit/agents> <임시>/merged/agents` 가 PASS 다. FAIL 이면 멈춘다 — 대장을 옮기는 근거가 이것이다(`CLAUDE.md` 「금지」).
  - M6 쓰기 — M2 ~ M5 를 다 지나야 쓴다. `merged/` 의 아홉을 사본의 제자리에 쓰고, 대장의 그 줄에서 `synced_commit` 을 HEAD 의 전체 SHA 로, `synced_at`
    을 그날로 바꾼다 — `repo` · `agents_path` · 다른 줄 · 줄 순서는 바이트가 그대로다(`$HOME` 으로 다시 만들지 않는다).
  - M7 표 — 파일마다 충돌 수 · 바뀐 줄 수(사본 대비 병합본의 `diff` 에서 더한 줄)를 찍는다. 다 쓰면 끝에 대장 줄과 「기본 브랜치에 없다」 경고(지금과
    같은 조건)를 찍는다. 이 표가 사본 레포 PR 본문의 파일별 표다(조각 23 설계 ② M6 의 꼴).
  - M8 멈출 때 — 사본 레포와 대장의 바이트가 그대로이고 종료 코드가 0 이 아니다(P4 만 0). M3 에서 멈추면 `<임시>` 의 `base` · `new` · 사본 베낌 ·
    `merged`(충돌 표시)를 남기고 그 경로를 찍는다(ADR 0038 의 5). 그 밖의 멈춤은 임시 폴더를 지운다. 두 작업트리는 어느 쪽이든 `git worktree remove --force`
    로 치운다 — 비운 대장과 스크립트가 적은 줄로 작업트리가 더러워, `--force` 없이는 지우지 못한다(2026-10-18 재현: rc 128).
- **시험** (B) — `bite-gates.sh` 의 `sync-agents.sh` 절 끝. 지금 절처럼 저장소를 clone 한 `src` 에서 커밋을 만들고 `HOME` · `TMPDIR` 을 임시로 둔다.
  사본은 임시 bare 원격에 밀고 그 클론으로 둔다(P6). 시험은 아래 규칙 넷을 따르고, 보장마다의 꼴은 대응표가 든다 — 착공 PR #101 2회차에서 쏠림 신호가
  선 뒤 저자가 「규칙으로 전수」로 정했다(2026-10-18).
  - V1 **거절 꼴** — 둘 다 본다: 종료 코드가 0 이 아니고(P1 은 2), 「그대로」다 — 사본 레포의 `.claude/` 를 돌리기 전후 `diff -r`, `src/copies.json` 을
    `cmp`, 사본 레포의 `git status --porcelain` 이 전후 같다. 하나만 보는 거절 시험은 두지 않는다.
  - V2 **성공 꼴** — 다섯을 다 본다: 종료 0 · 아홉 파일이 시험이 따로 만든 기대본(`git merge-file` 과 README 치환)과 `cmp` 같음 · `src/copies.json` 전체가
    기대본(대상 줄의 `synced_commit` · `synced_at` 만 다르다)과 `cmp` 같음 — 대장에는 다른 줄을 하나 이상 둔다 · M7 표가 아홉 줄이고 파일마다 충돌 수 ·
    바뀐 줄 수가 기대값과 같음(검사기의 0 포함) · `src` 의 `git worktree list` 에 임시 작업트리가 없음.
  - V3 **보장마다 시험** — P1 ~ P6 · M1 ~ M8 과 요구사항 성공 기준 5 마다, 그것을 어기면 떨어지는 꼴이 대응표에 하나 이상 있다. P5 는 `--merge` 길에서
    다시 본다 — 지금 시험이 인자 없이 · `--force` 로 보는 검사를 `--merge` 로.
  - V4 **변조본** — T 마다(T8 포함) 그 T 의 꼴만 떨어지게 망가뜨린 `sync-agents.sh` 사본이 하나 이상 있다. 커밋하지 않고, 결과 표를 PR 본문에 싣는다
    (`CLAUDE.md` 「작업 방식」 — 물지 않는 검사는 게이트가 아니다).

  | 보장 | 시험 꼴(V1 · V2) | 변조본(V4) |
  |---|---|---|
  | P1 | T7a `--force --merge` → 2 | P1 을 뺀다 |
  | P2 | T7b 얕은 복제 | P2 를 뺀다 |
  | P3 | T7c 대장에 줄 없음 · T7d 줄의 `synced_commit` 이 저장소에 없음 | P3 을 뺀다 |
  | P4 | T9e 같은 커밋 · 원격이 앞섬 → 0 아님 · T10 같은 커밋 · 깨끗함 → 0 이고 「그대로」 | P4 를 P6 앞에 둔다 · P4 가 대장을 다시 쓴다 |
  | P5 | T11 `--merge` 로 원본의 커밋 안 된 변경 · HEAD 에 없는 원본 파일 · 대장의 같은 이름 다른 자리 · 폴더 자리의 파일 · 파일 자리의 폴더, 다섯 꼴 | `--merge` 길에서 P5 를 건너뛴다 |
  | P6 | T9a 원격이 앞섬 · T9b 사본 자리에 커밋 안 된 고침 · T9c 무시된 README · T9d 원격 없음 | 그 검사를 하나씩 뺀다 |
  | M1 | T2 머리줄 꼴이 바뀐 사이(V2) · T7e 대장에 `base` · `new` 줄이 있어도 T1 이 V2 로 지나감 | 밑을 지금 스크립트의 awk · `HDR` 로 세운다 · 작업트리 대장을 비우지 않는다 |
  | M2 | T5a 원본에 파일을 더함 · T5b 원본에서 파일을 뺌 · T5c 사본의 그 파일이 링크 | M2 를 뺀다 · 한 쪽(더함)만 본다 |
  | M3 | T3 사본과 원본이 같은 줄을 고침 | 충돌 검사를 뺀다 |
  | M4 | T4a 출처 자리 0 · T4b 둘 · T4c README 없음 | 「정확히 하나」를 「하나 이상」으로 |
  | M5 | T6 사본이 감사자 하나의 `tools` 를 바꿈 — 병합은 깨끗하다 | M5 를 뺀다 |
  | M6 | T1 의 V2 대장 비교 | `agents_path` 를 `$HOME` 으로 다시 만든다 · 다른 줄을 떨군다 · `synced_at` 을 두고 간다 |
  | M7 | T1 의 V2 표 비교 | 표를 찍지 않는다 · 바뀐 줄 수를 지운 줄까지 센다 |
  | M8 | T3 — 찍은 경로가 사본 레포 밖이고 `base` · `new` · 사본 베낌 · `merged` 넷이 기대 바이트(병합본은 충돌 표시) · T4 ~ T6 — `TMPDIR` 에 임시 폴더가 남지 않음 · T1 — V2 의 작업트리 목록 | 남길 넷 가운데 하나를 지운다 · 다른 멈춤에서 임시 폴더를 남긴다 · `--force` 없이 작업트리를 지운다 |
  | 성공 기준 5 | T8 지난 시험이 글자 그대로 지나가고, `main` 의 `sync-agents.sh` 와 B 의 것으로 빈 자리에 심은 결과 · `--force` 로 덮은 결과가 `diff -r` 같음 | 인자 없는 길이나 `--force` 의 출력(머리줄 · README · 대장 줄)을 한 바이트 바꾼다 |

  T1 **깨끗한 병합** — `src` 커밋 A 로 심은 사본에 특화 한 줄(감사자 하나의 원본이 안 고치는 자리)과 README 를 다시 쓴 꼴(출처 자리 하나 · 다른 줄
  바꿈)을 넣고, `src` 커밋 B 가 같은 감사자의 다른 자리를 고친다. `--merge` → V2. T2 는 A 와 B 사이에 `HDR` 꼴을 바꾼 커밋을 둔 T1 이다.
- **재현** (B) — 손 병합 두 번. ERP 익명 클론과 claude-kit 의 스크래치 클론에서 하고 저장소에 싣지 않는다.
  - 두 재현 다 ERP 클론의 원격을 그 사본 커밋을 기본 가지 `main` 으로 든 로컬 bare 로 둔다 — P6 이 원격 머리와 견주기 때문이다(ADR 0038 의 8).
  - R1 #113 — 스크래치 claude-kit 에 `ddcd21f` 위로 B 의 `sync-agents.sh` 만 얹은 커밋 X 를 만들고(`git diff --quiet ddcd21f X -- vibe-audit` 로
    원본이 같은지 본다), 그 `copies.json` 의 `erp` 줄을 ERP 클론 자리 · `018842c` 로 둔다. ERP 클론을 `c75c215` 에 두고 `--merge` → 종료 0, 파일마다 충돌
    0 · 바뀐 줄 1 · 1 · 1 · 1 · 1 · 2 · 1 · 0, README 1. 아홉 파일을 출처 SHA 자리(X 의 짧은 SHA → `ddcd21f`)만 읽어 바꾸면 ERP `c9331a3` 과 `cmp`
    같다.
  - R2 #111 — 같은 식으로 `018842c` 위의 커밋 X′, 대장 줄 `3d6964a`, ERP 클론 `edab087^`. `--merge` → 종료 코드 0 이 아니고 충돌 `audit-data` 1 ·
    `audit-internal` 4 · `audit-quality` 2 · `audit-secrets` 1 을 찍으며, ERP 클론의 `git status --porcelain` 이 비고 스크래치 `copies.json` 이 그대로다.
  - 명령과 결과를 PR 본문에 싣는다.
- **게이트** (A · B)
  - G1 `./scripts/gates.sh` 의 검사 수는 스물넷 그대로다 — `bite-gates.sh` 는 그 하나다(ADR 0038 의 4).
  - G2 A 는 결정 문서뿐이다 — `verify-slice-gate.py` 가 본다. B 는 이 착공이 머지된 뒤에 선다.
  - G3 A · B 의 `git diff --name-only main...HEAD` 와 수트 지문 목록의 교집합 0.

**보장하지 않는 것(알려진 한계)**

- **쓰는 도중의 끊김** — M6 은 파일 아홉과 대장을 차례로 쓴다. 그 사이 죽으면 반쯤 쓴 사본이 남는다. 사본 레포는 git 이라 `git checkout -- .claude`
  로 되돌린다 — `--force` 와 같은 한계다.
- **원격보다 앞선 사본** — P6 은 뒤처짐만 본다. 사본 레포가 원격에 없는 커밋 위(심기용 가지)에 있으면 그 커밋까지 재료다 — `compare-copies.py` 와 같다.
- **대장 커밋의 순서** — M6 은 claude-kit 작업트리의 `copies.json` 을 곧바로 고친다. 사본 레포 PR 이 머지된 뒤에 대장을 커밋하는 것, 그 PR 이 닫히면
  고침을 되돌리는 것은 사람이 지킨다(ADR 0038 의 9).
- **짧은 SHA 의 길이** — 밑의 머리줄 · README 의 짧은 SHA 는 그 커밋의 스크립트가 지금 저장소에서 `rev-parse --short` 로 낸 것이다. 객체가 늘어 길이가
  바뀌면 사본의 머리줄과 달라 M3 에서 충돌로 멈춘다 — 쓰지 않는 쪽으로 틀린다.
- **옛 스크립트가 다른 꼴로 심는 커밋** — 그 커밋의 스크립트가 커맨드 · 검사기를 심지 않거나 다른 자리에 심으면 M2 에서 멈춘다. 손 병합 두 번의 커밋은
  다 지금 자리에 심는다.
- **충돌이 없는데 틀린 병합** — `git merge-file` 이 깨끗이 합친 두 고침이 뜻으로 부딪는 것(같은 규칙을 다른 줄에서 고침)은 보지 않는다. 공통 절 ·
  `tools` 는 M5 가 보고, 그 밖은 사본 레포의 PR 리뷰와 그 뒤 `compare-copies.py` 의 새 후보가 본다.
- **특화 없는 사본(강호쟁패)** — 그 사본에도 `--merge` 는 돌고, 생성본 README 도 출처 자리가 하나라 같은 규칙으로 옮겨진다. 결과가 `--force` 와 같은지는
  이 조각에서 실물로 재지 않는다 — 시험의 README 는 다시 쓴 꼴(T1)과 자리가 하나가 아닌 꼴(T4)이다.
- **아직 겪지 않은 가설적 경계 사례** — 예: 같은 레포가 대장에 두 자리, 사본의 `.claude/agents` 가 링크. 앞의 것은 P3, 뒤의 것은 P5 의 폴더 자리 검사가
  멈춘다. 리뷰가 그 밖을 짚으면 범위 밖이다(조각 6 「닫으며」).

## ③ 받는 입력

닫힌 목록이다. 2026-10-18 의 claude-kit `main`(`30bc0e2`)과 ERP `main`(`6dda439`)에서 뽑았다.

**인자** — `<대상 레포 경로>` 하나와 `--force` · `--merge` 가운데 0 개나 하나. 둘 다면 P1. 그 밖의 `-` 인자는 지금처럼 「모르는 옵션」.

**대장 줄** — `copies.json` 의 `copies[]` 원소 `{repo, agents_path, synced_commit, synced_at}`. 지금 두 줄 다 `ddcd21f7d359…` 이고 `agents_path` 는 절대
경로(`/home/user/erp/.claude/agents` · `/home/user/ganghojaengpae/.claude/agents`)다. `agents_path` 는 `~` 를 풀어 대상의 `.claude/agents` 와 견준다 — 지금
스크립트의 같은 이름 검사와 같은 식.

**사본 자리** — 대상의 `.claude/` 아래 셋과 README.

| 자리 | 파일 | 머리줄 |
|---|---|---|
| `agents/` | 감사자 여섯 · `README.md` | 감사자: 프론트매터 뒤 빈 줄 다음 `HDR` 한 줄. README: 머리줄 없음, 출처 `pdw96/claude-kit@<짧은 SHA>` 하나(생성본 3 줄 · ERP 3 줄) |
| `commands/` | `audit-brief.md` | 감사자와 같다 |
| `scripts/` | `verify-brief.py` | 없음 — 바이트 그대로 |

그 밖의 `.claude/` 파일(ERP `hooks/` · `skills/` · `settings.json`, 강호쟁패 `audits/` · `settings.json`)은 보지 않는다.

**밑 · 새 원본을 심는 스크립트** — 지금까지의 `synced_commit` 셋(`b8d9243` · `3d6964a` · `018842c`)과 `ddcd21f` 의 `sync-agents.sh`. 다 위 표의 자리에
심는다. `HDR` 꼴은 `c56e571` 앞뒤로 둘이다.

| 커밋 | `HDR` 의 꼬리 |
|---|---|
| `c56e571` 앞(`3d6964a` 가 여기) | 「이 레포에 맞게 고쳐도 된다 — 원본으로 되먹이지 않는다.」 |
| `c56e571` 부터(`b8d9243` · `018842c` · `ddcd21f` 가 여기) | 「이 레포에서만 참인 고침은 이 사본에만 산다 — 다른 레포에서도 같은 말이면 원본으로 넘긴다.」 |

**재현의 재료**

| 재현 | claude-kit 원본 | 대장 줄 | ERP 사본 | 견줄 것 |
|---|---|---|---|---|
| R1 #113 | `ddcd21f` 의 `vibe-audit/` + B 의 스크립트 | `018842c` | `c75c215` | `c9331a3` 의 아홉 |
| R2 #111 | `018842c` 의 `vibe-audit/` + B 의 스크립트 | `3d6964a` | `edab087^` | 충돌 1 · 4 · 2 · 1 |

## ④ 결정

**정한 것** — ADR 0038. 열 다 저자가 정했다(2026-10-18) — 1 ~ 7 은 착공 대화, 8 ~ 10 은 착공 PR #101 을 연 뒤의 인터뷰. 열 다 세션이 추천한 쪽.

- 1 README — 출처 SHA 치환, 자리가 하나가 아니면 멈춤
- 2 밑 — `synced_commit` 의 작업트리에서 그 커밋의 `sync-agents.sh` 로
- 3 파일 집합이 다르면 — 멈춤
- 4 시험의 자리 — `bite-gates.sh` 의 `sync-agents.sh` 절, 검사 수 스물넷 그대로
- 5 충돌로 멈출 때 — 사본 밖 임시 폴더에 재료와 충돌 표시 병합본을 남기고 경로를 찍음
- 6 맞음 — 시험 + 손 병합 두 번의 재현, ERP 에는 쓰지 않음
- 7 PR 나눔 — 착공 A 뒤 구현 B 하나
- 8 사본 레포의 상태 — ADR 0003 대로 뒤처짐 · 커밋 안 된 것 · 못 받음이면 멈춤(② P6)
- 9 대장 — 성공하면 곧바로 `copies.json` 을 고침, 커밋은 사본 레포 PR 머지 뒤
- 10 안내 — 다시 심기는 늘 `--merge`, `--force` 는 일부러 되돌릴 때

**열어 둔 것**

없음 — 열 다 정했다. 스크립트 안의 함수 · 변수 이름과 찍는 문구는 결정이 아니라 B 의 일이다 — ② 의 범위 안에서 무엇을 썼는지를 PR 본문에 적는다.

## ⑤ 검증 계획

명령은 PR 본문에 결과와 함께 적는다.

**PR A**

- `./scripts/gates.sh` 스물넷 통과 — `verify-docs.py` 가 새 조각 폴더를, `verify-slice-gate.py` 가 착공 PR 에 결정 문서뿐인지를 본다(G2).
- 지문 — `git diff --name-only main...HEAD` 와 `eval-key.py route --list` · `full --list` 의 교집합 0(G3).

**PR B** (A 가 머지된 뒤)

1. 스크립트 · 시험 — `./scripts/bite-gates.sh` 가 ② 「시험」 대응표의 꼴을 다 지나간다. `./scripts/gates.sh` 스물넷 통과(G1).
2. 어긋내 보기 — 대응표의 변조본 열마다 그 사본을 커밋한 스크래치 clone 에서 그 줄의 꼴만 떨어진다(V4). 결과 표(변조본 · 떨어진 꼴 · 지나간 꼴)를
   PR 본문에 적는다 — 스크래치는 싣지 않는다.
3. 재현 — R1 · R2 의 명령 · 파일별 표 · `cmp` 결과를 PR 본문에.
4. 지금 길 — T8 의 `diff -r` 결과. `git diff main...HEAD -- scripts/sync-agents.sh` 에서 `--merge` 밖의 줄이 바뀐 것은 인자 풀이 · 쓰는 법 줄뿐인지
   PR 본문에 적는다.
5. 지문 — G3. B 의 CI 는 gate 잡 초록이고 eval 잡은 건너뛴다.

**비용** — 없음(모델 호출이 없다).

**스스로 쓰기** — 각 PR 의 리뷰를 `slice-review` 로 가른다. PR 본문의 `## 리뷰 회차` 와 답글. B 는 `verify-slice-gate.py` 를 CI 에서 지나간다(이
착공이 머지된 뒤).

**단계 5(배포)** — B 의 머지가 배포다. `sync-agents.sh` 는 claude-kit 저장소 안의 스크립트라 플러그인 판이 오르지 않고 사본 레포가 받을 것이 없다.
첫 실물은 다음 심기의 사본 레포 PR 이다(요구사항 하지 않을 일 1). 되돌리는 길은 B 의 되돌림이다.

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A 착공 | 요구사항 · 설계 · ADR 0038 · 마스터플랜(「`sync-agents.sh --merge`」 `진행`) | 단계 1 · 2, ② G2 · G3 |
| B 구현 | `scripts/sync-agents.sh` 의 `--merge` · `scripts/bite-gates.sh` 의 ② 「시험」 대응표 · `docs/architecture.md` · `README.md` · `CHECKLIST.md` | ② P · M · T · R · G1 · G3, 성공 기준 1 ~ 7 |

조각을 닫는 기록(단계 6)은 따로 낸다 — 못 미친 기준이나 재현에서 난 다른 갈래를 조각 나눔의 줄로 올리는 것도 그 PR 이다.
