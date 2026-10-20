# 조각 30 — `CLAUDE.md` 틀 (2026-10-20 착공)

요구사항이다 — **무엇을 · 왜.** 어떻게 · 경계는 같은 폴더의 `design.md`, 대안이 있던 결정은 ADR 0041.

이 조각을 「다음 조각」으로 적은 닫힌 조각은 없다 — 조각 29 의 `## 닫으며 (2026-10-19)` 가 다음 조각을 `없음` 으로 적고 「근거가 생기면 그때
순서를 매겨」 꺼낸다고 했다(ADR 0012). 근거는 저자의 물음(2026-10-20 — 「`slice-docs` 할 때 `CLAUDE.md` 는 안 만드나」)과 아래 「문제」의 세 레포이고,
#110 이 조각 나눔에 줄을 더하며 순서 30 으로 매겼다. 이 착공 세션의 클론은 얕지 않았다(`git rev-parse --is-shallow-repository` → `false`).

## 문제

**스킬 `slice-docs` 로 의도 · 마스터플랜을 세워도, 세션의 입구가 그 둘을 가리키게 하는 일이 누구의 몫도 아니다.**

- **입구는 `CLAUDE.md` 하나다.** Claude Code 가 세션마다 저절로 읽는 것은 `CLAUDE.md` 다. ADR 0009 는 「`INTENT.md` 는 자동으로 읽히지 않는다 —
  `CLAUDE.md` 가 가리킨다」고, ADR 0012 는 새 세션이 `CLAUDE.md` → 절차 지도 → 마스터플랜을 따라 조각을 꺼낸다고 적는다. 스킬은 `CLAUDE.md` 를
  「이 스킬의 일이 아닌 것」에 두고(`vibe-slice/skills/slice-docs/SKILL.md`), 그렇게 그은 근거는 조각 5 설계의 한 문장뿐이다(ADR 0041 「맥락」).
- **세 레포가 같은 일을 손으로 했다(2026-10-20 각 기본 가지).** 줄 번호는 백틱 토막이 처음 나오는 줄이다.

  | 레포 | `CLAUDE.md` | 의도를 가리키는 줄 | 마스터플랜을 가리키는 줄 | 앵커볼트 · 작업 방식 · 금지 절 |
  |---|---|---|---|---|
  | claude-kit (`a6fdee5`) | 48줄 | 33 `INTENT.md` | 38 `docs/master-plan.md` | 있다 |
  | pdw96/ERP (`68ac6c4`) | 227줄 | 5 `PRD.md` | 46 `docs/master-plan.md` | 있다 |
  | pdw96/ganghojaengpae (`8dc3c06`) | 123줄 | 5 `PRD.md` | 114 `docs/master-plan.md` | 있다 — 앵커볼트 제목은 「먼저 도원에게 물어볼 것」 |

  셋 다 저자나 세션이 손으로 넣었다. 틀이 없어 절 이름을 레포마다 맞췄고, 가리키는 줄이 빠져도 아무것도 떨어지지 않는다.
- **검사가 없다.** `verify-docs.py` 는 마스터플랜의 의도 줄이 저장소 안의 파일인지는 보지만(I2), 그 파일과 마스터플랜을 입구가 가리키는지는 보지
  않는다. 키 없이 도는 검사 가운데 `CLAUDE.md` 를 읽는 것이 없다 — 이 세션이 `scripts/` 와 스킬의 `scripts/` 를 훑었고, 그 이름은 주석에만
  나온다.
- **원본의 빈 곳이다.** 조각으로 나눠 진행하는 레포라면 어디서나 같은 말이다(`INTENT.md` Why) — 입구가 의도 · 마스터플랜을 가리키지 않으면 다음
  세션은 그 둘이 있는 줄 모르고 시작한다.

## 핵심 사용자와 시나리오

- 사용자: 새 레포를 조각으로 여는 저자, 그리고 그 레포에서 매 세션 `CLAUDE.md` 를 읽는 Claude Code 세션.
- 시나리오: 저자가 `CLAUDE.md` 도 마스터플랜도 없는 레포에서 스킬 `slice-docs` 를 부른다 → 스킬이 의도 · 마스터플랜을 틀대로 쓰고, `CLAUDE.md` 가
  없으니 `/init` 을 먼저 부르라고 말한다 → 저자가 `/init` 으로 빌드 · 시험 명령 같은 사실을 받는다 → 스킬이 앵커볼트 · 작업 방식 · 금지를 인터뷰로
  받아 덧붙이고, 작업 방식에 의도와 마스터플랜을 가리키는 줄을 넣는다 → PR 을 내기 전 `verify-docs.py --repo .` 가 0 이다 → 다음 세션은
  `CLAUDE.md` 에서 의도와 마스터플랜을 찾아 조각을 꺼낸다. `CLAUDE.md` 가 이미 있는 레포라면 스킬은 덮지 않고, 빠진 절과 가리키는 줄만 보여 준 뒤
  저자가 받으면 더한다.

## 성공 기준

1. 틀 `vibe-slice/skills/slice-docs/templates/claude-md.md` 가 서고, 그 `##` 제목이 `docs/procedure.md` 「`CLAUDE.md` 의 칸」 표와 같다 —
   이 저장소의 `verify-docs.py` 가 T2 로 문다.
2. `verify-docs.py` 가 두 모드(이 저장소 · `--repo`)에서 C1 · C2 · C3(설계 ②)를 문다 — 자체 시험(`test-verify-docs.py`)의 거절 꼴마다 exit 1 과 그
   번호가 나오고, C1 · C2 · C3 의 자리를 하나씩 망가뜨린 변조본이 자체 시험에서 다 떨어진다(`gates.sh`).
3. 세 레포의 지금 `CLAUDE.md` 가 새 검사를 지난다 — claude-kit 은 `gates.sh`, ERP · 강호쟁패는 B 머리의 검사를 `--repo` 로 대어 exit 0(B 의 PR 본문).
4. 스킬 `slice-docs` 가 `CLAUDE.md` 를 「틀」 표 · 처음 쓰는 호출 · 이미 있을 때로 들고, 「이 스킬의 일이 아닌 것」에 `CLAUDE.md` 가 없다.
   호출 시 4,500 자 안이다(`verify-budget.py`).
5. ERP 의 스킬 사본이 B 의 머지 커밋으로 다시 심겨 머지되고, ERP 에서 `verify-docs.py --repo .` 가 0 이다(C 의 PR 본문).
6. `./scripts/gates.sh` 가 B 의 로컬과 CI gate 잡에서 다 통과한다.

## 하지 않을 일

1. **`CLAUDE.md` 의 절 제목을 검사하지 않는다** — 세 레포가 다 틀보다 절이 많고, 강호쟁패는 앵커볼트 제목이 다르다(ADR 0041 의 6).
2. **사실(빌드 · 시험 명령 · 폴더 구조)을 스킬이 쓰지 않는다** — `/init` 의 몫이다(ADR 0041 의 4). 스킬이 `/init` 을 부르지도 않는다.
3. **`AGENTS.md` 를 쓰지 않는다** — 있으면 `CLAUDE.md` 가 가리키기만 한다(ADR 0041 의 8).
4. **ERP · 강호쟁패의 `CLAUDE.md` 를 고치지 않는다** — 둘 다 이미 새 검사를 지난다(「문제」의 표). 강호쟁패에는 PR 을 내지 않는다 — 플러그인
   갱신으로 받는다(ADR 0041 의 11).
5. **가리키는 줄의 뜻은 보지 않는다** — 경로 토막이 있는지만 본다. 「`INTENT.md` 는 읽지 않는다」 같은 문장도 지나간다.
6. **이 저장소 `CLAUDE.md` 의 절 제목을 틀에 맞춰 바꾸지 않는다** — 앵커볼트 절의 문서 모양 줄만 고친다(설계 ①).

## 제약

- 스택: 파이썬 표준 라이브러리 · bash · git.
- 원본: `main` `a6fdee5`. `vibe-slice` 판 0.4.4, 두 스킬의 지도 링크는 `6a9f582` 를 박았다. B 는 지도를 고치므로 두 링크를 다시 박는다(`verify-map-pin.py`
  M5, ADR 0019).
- CI: 이 조각이 바꾸는 파일은 두 수트 지문 밖이다(이 세션의 `eval-key.py route --list` · `full --list`) — eval 잡이 돌지 않는다.
- 앵커볼트: 「…의 칸」 절을 다섯으로 넓히고 `CLAUDE.md` 「앵커볼트」의 문서 모양 줄을 고친다 — 저자가 착공 인터뷰에서 승인했다(ADR 0041 의 7).
- 예산: 스킬 `slice-docs` 는 호출 시 1,903 자, 천장 4,500 자다(ADR 0004).
- 비용: 모델 호출이 없다.
- 사본 레포: C 는 pdw96/ERP 의 PR 이고 그 레포의 저자가 머지한다. B 가 claude-kit `main` 에 머지된 뒤에 심는다 — 원격에 없는 원본은 심지 않는다
  (`sync-slice.sh` P1).
- 기간: 닫기까지 **사흘**(2026-10-23 까지).
- 리뷰: PR 본문에 설계 ② 를 적고, 착공 PR 도 구현 PR 도 스킬 `slice-review` 로 가른다. PR 마다 **3라운드**를 넘기면 소유자가 판정한다.

## 닫으며 (2026-10-20)

성공 기준 여섯을 아래에 대어 봤다 — **여섯 다 미쳤다**. 구현은 설계 ⑥ 의 셋 그대로다 — A 착공 #110(머지 `baab1a7`), B 구현 #111(머지
`4ef24a9`), C pdw96/ERP#123(머지 `b4647ef`). 틀 `claude-md.md` 가 서고, 「`CLAUDE.md` 의 칸」이 문서 모양의 다섯째 원천이 되고, `verify-docs.py` 가
입구 `CLAUDE.md` 를 C1 · C2 · C3 로 문다(설계 ②). 스킬 `slice-docs` 는 `CLAUDE.md` 를 다섯째 문서로 쓴다. 넘긴 것은 없다.

| 성공 기준 | 무엇에 대어 봤나 |
|---|---|
| 1. 틀과 「`CLAUDE.md` 의 칸」 | `4ef24a9` 의 `vibe-slice/skills/slice-docs/templates/claude-md.md` — `## 앵커볼트 — 바꾸려면 먼저 물어볼 것` · `## 작업 방식` · `## 금지`. #111 의 자체 시험에 「T1 틀 claude-md.md 이 없다」 · 「T2 틀 claude-md.md 의 제목 한 글자」 · 「O1 「CLAUDE.md 의 칸」 절 이름이 바뀐다」의 꼴이 서고, 이 닫는 세션의 `gates.sh`(`4ef24a9`)에서 문서 대조가 PASS 다 |
| 2. C1 · C2 · C3 를 두 모드에서 문다 | #111 본문 「조건 → 꼴 → 변조본」 — C2 · C3 는 ③ 의 거절 꼴 여섯씩 두 모드에서. C1 은 이 저장소 모드에서 없음 · 폴더 · 밖 링크, 다른 레포 모드에서 없음 둘(조각이 있는 트리 · 첫 마스터플랜)이다 — 두 모드가 같은 `check_entry` 를 부르고, V1 은 조건마다 두 모드에서 하나 이상을 든다. 묻지 않아야 할 자리 셋 · 대조 열셋. 변조본은 `bite-gates.sh` 의 문서 대조 26 · `bite-verify-docs.py` 11 이 다 떨어진다. 고치기 전 검사(B 의 밑 `baab1a7` 의 `verify-docs.py`)에 새 자체 시험을 대면 39 가 어긋난다 — 검사가 없던 자리다(설계 ⑤ V4). 꼴 하나하나는 #111 의 시험 코드와 본문이 든다(ADR 0039) |
| 3. 세 레포의 지금 `CLAUDE.md` 가 지난다 | #111 본문 「검사」 — B 머리의 `verify-docs.py --repo` 를 claude-kit · pdw96/ERP(`68ac6c4`) · pdw96/ganghojaengpae(`8dc3c06`) 에 대어 셋 다 PASS. claude-kit 은 이 닫는 세션의 `gates.sh` 로 다시 봤다 |
| 4. 스킬 `slice-docs` | `4ef24a9` 의 `SKILL.md` — 「틀」 표에 `claude-md.md`, 처음 쓰는 호출에 `CLAUDE.md` 단계(없으면 `/init` 을 먼저), 이미 있으면 덮지 않고 빠진 절 · 가리키는 줄을 보이고 받으면 더함. 「이 스킬의 일이 아닌 것」에 `CLAUDE.md` 가 없고 `AGENTS.md` 가 있다. 호출 시 2,284 자 / 천장 4,500 자 — 스냅숏 `vibe-audit/evals/budget.txt`, 이 닫는 세션의 `verify-budget.py` PASS |
| 5. ERP 다시 심기 | pdw96/ERP#123 — 이 닫는 세션이 `4ef24a9` 에서 `sync-slice.sh --force`(파일 9), 두 `SKILL.md` 머리줄이 `pdw96/claude-kit@4ef24a9`, 지도 링크가 `blob/4ef24a9cdbd3c068ccdd1ed2cd3d1cc5a436a7dc/`. 원본 `vibe-slice/skills/` 와 파일마다 `cmp` — 파일 목록이 같고, 다른 것은 두 `SKILL.md` 의 머리줄 · 지도 링크 두 줄씩뿐이다. 머지 뒤 ERP `main` `b4647ef` 에서 `verify-docs.py --repo .` PASS(exit 0, 「입구」 포함). ERP CI(`backend` · CodeQL 셋) 통과 |
| 6. `gates.sh` | 로컬 스물넷 통과 — #110 `1bb4f70`, #111 `3cc76ec`, 이 닫는 세션의 작업트리(`4ef24a9` 위). CI gate 잡 — #110 `7054b5f`([run 39395001410](https://github.com/pdw96/claude-kit/actions/runs/39395001410)) · `1bb4f70`([run 39398446419](https://github.com/pdw96/claude-kit/actions/runs/39398446419)) · `12d6c32`([run 39399958999](https://github.com/pdw96/claude-kit/actions/runs/39399958999)) · #111 `3cc76ec`([run 39404479421](https://github.com/pdw96/claude-kit/actions/runs/39404479421)) · `main` 푸시 `baab1a7`([run 39401550245](https://github.com/pdw96/claude-kit/actions/runs/39401550245)) · `4ef24a9`([run 39408455218](https://github.com/pdw96/claude-kit/actions/runs/39408455218)) 통과. eval 잡은 다 건너뛰었다(수트 지문 밖). 이 닫는 PR 의 머리는 PR 의 gate 잡이 본다. 검사 수는 스물넷 그대로다 |

### 배포

설계 ⑤ 「단계 5」 그대로 — #111 의 머지가 `vibe-slice` 0.5.0 의 배포이고, ERP#123 의 머지가 ERP 사본의 배포다. 보이는 것은 `main` 의 `plugin.json` 판
`0.5.0` 과 ERP `main` 의 두 `SKILL.md` 머리줄 `pdw96/claude-kit@4ef24a9` 다. 강호쟁패와 플러그인으로 받은 대화형 세션은 `claude plugin marketplace
update pdw96-kit` 뒤 `claude plugin update vibe-slice@pdw96-kit` 을 돌리고 리로드해야 새 틀과 검사를 읽는다(ADR 0013 · ADR 0041 의 11). 되돌리는 길은
이 닫는 기록을 먼저 되돌린 뒤 C → B 순으로 되돌리고 판을 0.5.1 로 올리는 것이다(`CHECKLIST.md` 「플러그인의 파일을 고쳤다면」) — 이 기록이
마스터플랜의 30 줄(`닫힘`)을 고치므로, 그것을 두고 구현만 되돌리면 살아 있는 문서가 되돌린 상태와 갈린다.

### 제약에서 어긋난 것

없다. 착공부터 C 의 머지 · 이 기록까지 하루(2026-10-20)로 사흘 안이다. 리뷰는 #110 두 회차 · #111 한 회차 · ERP#123 한 회차로 3라운드 안이다.
모델 호출이 없어 비용 $0 이다. ERP · 강호쟁패의 `CLAUDE.md` 와 이 저장소 `CLAUDE.md` 의 절 제목은 고치지 않았다(하지 않을 일 4 · 6). 강호쟁패에는
PR 을 내지 않았다.

### 리뷰가 찾은 갈래

- #110 1회차(`1bb4f70`) — 안 셋, 다 사실의 틀림이었다(설계 ① 이 B 가 바꿔야 할 `test-sync-slice.py` · `budget.txt` 를 빠뜨림 · `AGENTS.md` 를
  가리키는 단계가 ADR · 요구사항과 어긋남). `12d6c32` 가 고쳤다. 2회차(`12d6c32`) 지적 0.
- #111 1회차(`3cc76ec`) 지적 0.
- ERP#123 1회차(`21bb6ab`) 지적 0 — ERP `docs/리뷰-루프.md` 의 점수 0.
- 이 닫는 PR — 그 PR 본문이 든다.

말하지 않음 · 반박됨 · 밖은 0 이다. 착공의 셋은 설계 ① 의 파일 목록과 결정 사이의 빈칸이었고, B 는 그것을 메운 설계대로 가 한 회차 0 이었다.

### 지켜본 것 — 줄을 더하지 않는다

첫 실물이 아직 없거나 겪지 않은 꼴이라 조각 나눔에 줄을 더하지 않는다.

- **새 레포에서 처음 쓰는 호출** — 스킬이 `CLAUDE.md` 없는 레포에서 `/init` 을 먼저 부르라고 하고 세 절을 인터뷰로 쓰는 길은 세 레포 어디서도 아직
  돌지 않았다(셋 다 이미 `CLAUDE.md` 가 있다). 다음에 새 레포를 조각으로 열 때가 첫 실물이다.
- **저자가 더할 줄을 마다할 때** — ADR 0041 의 3 · 10 이 그 레포의 검사가 가리키는 줄 없음을 찍는다고 적었다. 겪지 않았다.
- **강호쟁패** — 플러그인 갱신으로 받는다(하지 않을 일 4). 그 레포의 다음 `claude plugin update` 에서 바뀐다.
- **`slice-review` 의 예산 여유 6** — 조각 28 · 29 「지켜본 것」 그대로다. 이 조각은 `slice-review` 의 지도 링크만 다시 박아 길이가 그대로다.
- **얕은 클론** — 이 닫는 세션은 저장소 여럿을 붙인 세션이라 claude-kit 클론이 얕게 시작했고, `CLAUDE.md` 「스택」대로 `git fetch --unshallow origin`
  을 손으로 한 뒤 `sync-slice.sh` 를 돌렸다(`git rev-parse --is-shallow-repository` → `false`).

### 넘긴 것

없음 — 성공 기준 여섯이 다 미쳤다.

이미 열려 있던 순서 없는 줄 — 「회수율 측정」 · 「가르지 못한 결함 다섯」 · 「항목 10 과 머리의 어긋남」 · 「가르지 못한 빈 갈래 둘」 — 은 그대로
둔다.

다음 조각은 없음(저자, 2026-10-20). 순서를 매긴 남은 줄이 없고, 순서 없는 네 줄은 다 새 근거를 기다린다(조각 29 「닫으며」와 같다). 근거가 생기면
그때 순서를 매겨 꺼낸다(ADR 0012).
