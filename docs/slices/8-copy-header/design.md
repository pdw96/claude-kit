# 조각 8 설계 — 사본 머리줄

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`, 갈림길은 ADR 0017.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A | 「사본 머리줄」 상태 `진행` · 조각 폴더 · 목표 한 줄에 감사자 사본의 머리줄(ADR 0017 의 3). 후보 줄 「플러그인의 절차 지도 판」(ADR 0017 의 7) |
| `docs/adr/0017-copy-header.md` | A | 갈림길 여덟 |
| `scripts/sync-slice.sh` | B | ② 의 P1 · L1 · L2 · H1. 쓰기 전에 다 보고, 하나라도 걸리면 아무것도 쓰지 않는다 |
| `scripts/sync-agents.sh` | B | `HDR=` 한 줄 — H1 의 문장. 사본 `README.md` 를 쓰는 문단 — H3. 그 밖은 그대로 |
| `scripts/test-sync-slice.py` | B | 임시 원본에 원격(맨 저장소)을 붙이고, ⑤ 의 꼴을 더한다. H2 — 두 스크립트의 `HDR=` 줄을 견준다. H3 — `sync-agents.sh` 의 README 문단을 본다 |
| `scripts/test-compare-copies.py` | B | 가짜 사본 둘의 머리줄을 하나는 옛 문장, 하나는 H1 의 문장으로 — H4. 옛 꼴을 지우지 않는다 |
| `docs/architecture.md` | B | 「흐름」의 「스킬 심기」 — 링크를 출처 커밋으로 박고, 원격 가지에 없는 원본은 심지 않는다 |

링크의 커밋과 출처 줄의 커밋은 같은 HEAD 다 — 링크는 `git rev-parse HEAD`(전체), 출처 줄은 `git rev-parse --short HEAD`(ADR 0017 의 6).

**앵커볼트.** 건드리지 않는다 — 이름 · 감사자의 `tools` · 공통 절 · 대장의 모양 · 「…의 칸」 · 고정 영역 그대로다. 머리줄은
감사자 공통 절 밖이고(`verify-copy.py` 가 견주지 않는다), `compare-copies.py` 는 그것을 「… 에서 옴.」 접두로만 알아본다.

**시스템 구조.** 부품 · 경계는 그대로다. 「스킬 심기」 흐름의 한 문장이 는다 — PR B.

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 번호는 ⑤ 와 시험의 출력이 같이 쓴다. 조각 5 · 6 의 C1 ~ C5 는 그대로이고, C1 의 「나머지는 바이트 그대로」를
L1 의 바꿈만큼 좁힌다.

- **원격** (`sync-slice.sh`)
  - P1 원본 HEAD 가 원격 추적 가지(`git branch -r --contains HEAD`) 어느 것에도 들지 않으면 아무것도 쓰지 않고 멈춘다 — 원격이
    없어도 그렇다. 메시지는 출처 커밋과 「푸시했으면 받아 와라(`git fetch`)」를 찍는다.
- **링크** (`sync-slice.sh`)
  - L1 심는 파일마다(스킬 폴더의 모든 파일 — `SKILL.md` 와 틀) `github.com/pdw96/claude-kit/blob/main/` 을
    `github.com/pdw96/claude-kit/blob/<출처 전체 sha>/` 로 바꾼다. 줄마다 몇 번이든 다 바꾼다. 그 밖의 바이트는 그대로다.
  - L2 원본 HEAD 의 심을 파일에 ③ 밖의 claude-kit 링크 꼴이 있으면 아무것도 쓰지 않고 멈추며, 파일과 줄을 찍는다 — 새 꼴이
    고정 없이 사본에 새지 않게.
  - L3 다시 심어도 같다 — 그 레포가 손으로 `blob/<옛 커밋>/` 을 박은 사본을 `--force` 로 덮으면 링크는 새 출처다. C3 의 폴더째
    덮기와 L1 의 결과이고, 시험이 따로 본다.
- **머리줄**
  - H1 두 스크립트가 박는 출처 줄은 이 글자다 —
    `<!-- pdw96/claude-kit@<출처> 에서 옴. 이 레포에서만 참인 고침은 이 사본에만 산다 — 다른 레포에서도 같은 말이면 원본으로 넘긴다. -->`
  - H2 `sync-slice.sh` 와 `sync-agents.sh` 의 `HDR=` 줄이 글자 그대로 같다 — `test-sync-slice.py` 가 견준다(ADR 0017 의 5).
  - H3 `sync-agents.sh` 가 쓰는 감사자 사본 `README.md` 도 같은 방향이다. 옛 첫 문단(「**이 사본이 이 레포의 진실이다.** … 여기서
    고친 것을 그쪽으로 올리지 않는다. 갈리는 것이 정상인 관계다.」)을 이 글자로 바꾼다 —
    「**이 레포에서만 참인 고침은 이 사본에만 산다.** 원본은 아무 레포에도 안 들어가 본 일반형으로 남아 있어야 하므로, 이 레포의
    특화는 그쪽으로 올리지 않는다 — 갈리는 것이 정상인 관계다. 다른 레포에서도 같은 말인 고침(감사자 자체의 결함)은 원본으로
    넘긴다.」 `test-sync-slice.py` 가 `sync-agents.sh` 에 옛 두 글자(「원본으로 되먹이지 않는다」 · 「여기서 고친 것을 그쪽으로
    올리지 않는다」)가 없고, 「다른 레포에서도 같은 말」이 `HDR=` 줄과 README 문단에 다 있는지 본다(PR #36 Codex 1회차).
  - H4 `compare-copies.py` 는 옛 출처 줄과 H1 의 출처 줄을 다 출처 줄로 거른다 — 이미 심긴 사본은 옛 줄이다(하지 않을 일 4 · 5).
    `test-compare-copies.py` 의 가짜 사본 둘이 하나씩 들어, 어느 쪽이 후보로 새어도 떨어진다(PR #36 Codex 1회차).
- **비용**
  - X1 PR B 가 바꾼 파일 가운데 수트 지문(`eval-key.py route --list` · `full --list`, 기준과 머리 둘 다)에 드는 것이 0 이다.

**보장하지 않는 것(알려진 한계)**

- **플러그인 경로** — 원본 스킬의 링크는 `blob/main/` 이다. 강호쟁패의 세션은 설치한 판이 아니라 `main` 의 지도를 읽는다(하지
  않을 일 1) — 조각 나눔 「플러그인의 절차 지도 판」.
- **원격이 `pdw96/claude-kit` 인지** — P1 은 원격 추적 가지만 본다. 포크에만 푸시한 커밋이면 링크가 열리지 않는다.
- **로컬의 원격 추적이 맞는지** — 네트워크를 쓰지 않는다. 받아 온 뒤 원격에서 지워진 가지에만 든 커밋은 지나간다. 링크가
  열리는지는 보지 않는다(하지 않을 일 6).
- **URL 이 아닌 글자** — 「claude-kit `docs/procedure.md`」 같은 글자는 바꾸지 않는다(하지 않을 일 2).
- **이미 심긴 사본** — 다시 심기 전까지 옛 머리줄 · 옛 링크다(하지 않을 일 4).
- **감사자 사본의 원격 확인** — `sync-agents.sh` 는 P1 을 하지 않는다(하지 않을 일 3).
- **사본 레포가 머리줄대로 하는지** — 머리줄은 지침이다. 그 레포의 세션이 사본 지적을 원본으로 넘기는지는 보지 않는다.
- **아직 겪지 않은 가설적 경계 사례** — 예: 원본이 링크를 코드 블록 · 각주로 적는 꼴, 출처 커밋이 다른 가지로만 머지된 꼴.
  겪으면 그 PR 에서 정해 날짜 항목으로 적는다. 리뷰가 이것을 짚으면 범위 밖이다(조각 6 「닫으며」).

## ③ 받는 입력

닫힌 목록이다. 2026-10-08 의 `main`(01e0e60)에서 뽑았다.

**원본의 claude-kit 링크** — `vibe-slice/skills/` 아래 추적된 파일에서 `pdw96/claude-kit` 가 나오는 자리는 둘이고, 둘 다 같은 꼴이다.

| 파일 | 줄 | 링크 |
|---|---|---|
| `vibe-slice/skills/slice-docs/SKILL.md` | 8 | `https://github.com/pdw96/claude-kit/blob/main/docs/procedure.md` |
| `vibe-slice/skills/slice-review/SKILL.md` | 9 | `https://github.com/pdw96/claude-kit/blob/main/docs/procedure.md` |

받는 꼴은 글자 `github.com/pdw96/claude-kit/blob/main/` 하나다. 그 밖에 `github.com/pdw96/claude-kit` 나
`githubusercontent.com/pdw96/claude-kit` 가 나오면(`tree/main` · 다른 가지 · 커밋 · `raw`) L2 로 멈춘다. 「claude-kit」 글자만
있고 그 둘이 아닌 자리(틀 머리의 주석 · 본문의 「claude-kit 의 절차 지도」)는 링크가 아니다.

**git** — 원본에서 부르는 것은 `rev-parse HEAD` · `rev-parse --short HEAD` · `branch -r --contains HEAD` · `status --porcelain` · `cat-file -e` ·
`ls-tree` · `show HEAD:<경로>` 이다. 원격 추적 가지는 로컬에 받아 온 그대로다.

**대상** — 조각 5 · 6 의 C3 · C4 그대로다(`.claude` · `.claude/skills` · 스킬 폴더마다).

## ④ 결정

**정한 것** — ADR 0017.

- 1 바꾸는 링크는 `blob/main/` 접두 전부, 그 밖의 claude-kit 링크 꼴은 멈춘다(저자)
- 2 머리줄의 문장(저자)
- 3 감사자 사본의 머리줄도 같은 문장으로(저자)
- 4 원본 HEAD 가 원격 가지에 없으면 멈춘다 — `sync-slice.sh` 만(저자)
- 5 두 스크립트의 문장은 각자 들고 시험이 견준다(세션 제안 · 저자)
- 6 링크는 전체 sha, 출처 줄은 짧은 sha(저자)
- 7 플러그인 경로는 조각 나눔의 후보 줄로(저자)
- 8 단계 5 에서 ERP 감사자 사본을 다시 심지 않는다(저자)

**열어 둔 것**

없음 — 갈림길 여덟을 착공에서 정했다.

## ⑤ 검증 계획

명령은 PR 본문에 결과와 함께 적는다. 「어긋내 보기」는 일부러 망가뜨린 작업트리에 같은 명령을 대어 떨어지는지 본 뒤 되돌린다.

**PR B**

- `./scripts/gates.sh` 열일곱 통과.
- `test-sync-slice.py` — 임시 원본에 맨 저장소를 원격으로 붙이고 푸시한 뒤 꼴마다 본다.

  | 꼴 | 기대 |
  |---|---|
  | 빈 대상에 심는다 | 심은 파일마다 원본에서 `blob/main/` → `blob/<출처 전체 sha>/` 만 다르다 · 사본에 `blob/main/` 이 없다(L1) · 출처 줄이 H1 의 글자(H1) |
  | 한 줄에 `blob/main/` 링크 둘, 틀 파일에 링크 하나를 더한 원본 | 다 바뀐다(L1) |
  | 손으로 `blob/<옛 커밋>/` 을 박은 사본 + `--force` | 링크가 새 출처(L3) |
  | 원본에 `tree/main/` · `blob/<다른 가지>/` · `raw.githubusercontent.com` 의 claude-kit 링크 | 꼴마다 멈춤 · 대상 그대로(L2) |
  | 원격 없는 원본 · 푸시하지 않은 커밋이 HEAD 인 원본 | 멈춤 · 대상 그대로(P1) |
  | `sync-agents.sh` 와 `sync-slice.sh` 의 `HDR=` 줄 | 같다(H2) |
  | `sync-agents.sh` 의 README 문단 | 옛 두 글자가 없고 「다른 레포에서도 같은 말」이 있다(H3) |
  | 조각 5 · 6 의 C1 ~ C5 꼴 | 그대로 지나간다 |

- 어긋내 보기 다섯 — 다 `test-sync-slice.py` 가 떨어진다: L1 의 바꿈을 지운다, L2 의 꼴 거절을 지운다, P1 의 원격 확인을 지운다,
  `sync-agents.sh` 의 `HDR=` 한 글자를 바꾼다, `sync-agents.sh` 의 README 문단을 옛 글자로 되돌린다.
- 어긋내 보기 하나 — `compare-copies.py` 의 `PROVENANCE` 를 H1 의 문장 전체로 좁히면 `test-compare-copies.py` 가 떨어진다(H4).
- 실물(성공 기준 2) — PR B 머리에서 빈 임시 git 레포에 `sync-slice.sh` 로 심고, `diff -r` 를 원본 스킬 폴더와 견준 출력.
  `sync-agents.sh` 로 다른 임시 레포에 심고 `grep -rn '에서 옴'` 과 `.claude/agents/README.md` 첫 문단의 출력.
- `test-compare-copies.py` — 옛 머리줄 · 새 머리줄의 가짜 사본에서 그대로 지나간다(`gates.sh`, H4).
- X1 — `git diff --name-only main...HEAD` 와 기준 · 머리 각각의 `eval-key.py route --list` · `full --list` 의 교집합이 0.

**스스로 쓰기** — PR A · B 의 리뷰를 `slice-review` 로 가른다. PR 본문의 `## 리뷰 회차` 와 답글. PR B 는 `verify-slice-gate.py`
를 CI 에서 지나간다(이 착공이 머지된 뒤).

**단계 5(배포)** — PR B 뒤: 저자가 ERP 에서 `sync-slice.sh --force` 로 다시 심고, 그 PR diff 에서 링크가 `blob/55a8a79/` →
`blob/<새 출처 전체 sha>/` 로 바뀌었고 ERP 세션이 링크를 손으로 고친 커밋이 없는지 본다. 감사자 사본은 다음 `sync-agents.sh` 때
바뀐다 — 이 조각에서 부르지 않는다(ADR 0017 의 8).

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A 착공 | 요구사항 · 설계 · ADR 0017 · 마스터플랜(「사본 머리줄」 `진행` · 후보 줄 「플러그인의 절차 지도 판」) | 단계 1 · 2 |
| B 심기 | `sync-slice.sh` · `sync-agents.sh` 의 `HDR=` 과 README 문단 · `test-sync-slice.py` · `test-compare-copies.py` · `docs/architecture.md` | ② 의 P1 · L1 ~ L3 · H1 ~ H4 · X1, 성공 기준 1 · 2 · 3 · 5 |

성공 기준 4 는 단계 5 에서 저자가 본다. 조각을 닫는 기록은 그 뒤 따로 낸다(단계 6).
