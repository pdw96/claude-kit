# 시스템 구조

**살아 있는 문서**다. 이 저장소의 부품과 그 사이의 흐름만 든다. 왜 이 모양인지는 `docs/adr/`, 대장의 모양은
`docs/schema.md`, 값(모델 · 판 · 잡의 설정)은 각 파일이 든다. 의도는 `INTENT.md`.

## 부품

| 부품 | 사는 곳 | 하는 일 |
|---|---|---|
| 원본 감사자 여섯 | `vibe-audit/agents/` | 목적별로 좁힌 읽기 전용 감사자. 공통 절은 여섯이 글자 그대로 같다 |
| 브리핑 커맨드 · 검사기 | `vibe-audit/commands/audit-brief.md` · `vibe-audit/scripts/verify-brief.py` | 부르는 세션이 diff 를 브리핑으로 싣고, 검사기가 그것을 git 과 대조한 뒤 감사자를 부른다 |
| 조각 문서 스킬 | `vibe-slice/skills/slice-docs/` | 의도 · 마스터플랜 · 작업 규칙(`CLAUDE.md`) · 프로필(`Profile.md`) · 요구사항 · 설계 틀 여섯(`templates/`)과 쓰는 법, 부적합 대장의 틀 둘(`templates/nc-ledger*.md` — 레포가 처음 한 번 베껴 세운다. 사본 대장에 적지 않고 견주지 않는다), 그리고 검사 둘(`scripts/` — 문서 대조 검사 `verify-docs.py` · 설계 → 구현 관문 `verify-slice-gate.py`). 절차는 `docs/procedure.md` 를 가리키기만 한다 |
| 리뷰 가르기 스킬 | `vibe-slice/skills/slice-review/` | 리뷰 지적을 그 조각의 기준에 비춰 가르는 규칙과 답글 · 회차 표의 꼴. 틀은 옆의 `slice-docs` 에서 읽는다 |
| 매니페스트 셋 | `.claude-plugin/marketplace.json` · `vibe-audit/.claude-plugin/plugin.json` · `vibe-slice/.claude-plugin/plugin.json` | 마켓플레이스와 플러그인 둘. 두 군데 적힌 이름 · 설명과, 플러그인 폴더마다 장터에 줄이 하나인지를 `verify-manifest.py` 가 본다 |
| 사본 | 각 레포의 `.claude/agents/` · `.claude/commands/` · `.claude/scripts/` · `.claude/skills/<스킬>/` | 클라우드 레인에서 뜨는 쪽. 그 레포에 맞게 갈린다 |
| 사본 대장 | `copies.json` | 사본마다 레포 · 경로 · 심을 때의 커밋 · 날짜 |
| 후보 대장 | `feedback.json` | 사본과 원본의 차이를 묶은 후보와 그 판정(특화 · 결함 · 보류 · 되먹임 완료). 되먹임 커밋과 케이스는 되먹임 완료(`fed_back`)가 된 뒤에만 붙는다 |
| 수트 | `vibe-audit/evals/` | 되먹임마다 붙인 케이스. 지금 모양은 그 폴더의 `README.md`, 작업 기록은 `docs/eval-log/` |
| 회수율 | `vibe-audit/recall/` | 담당 감사자가 놓친 실제 결함을 옮긴 케이스. 수트와 따로 `run-evals.sh --eval-dir recall` 로 재기만 한다 — CI 는 돌리지 않고 수트 지문 밖이다(ADR 0050) |
| 키 없는 게이트 | `scripts/gates.sh` 가 부르는 것 | 모델 없이 도는 검사 전부. 목록은 그 파일에 있고, 그 이름을 `scripts/test-gates.py` 가 고정 목록으로 들어 갈리면 떨어진다(ADR 0049) — 늘 도는 검사와 자체 시험 스물하나(`checks`)와 건너뛸 수 있는 변조 시험 다섯(`bites`) 두 묶음이다. `--skip-bite <근거>` 는 `checks` 만 돌리고 CI(`GITHUB_ACTIONS=true`)에서만 받는다. 변조 시험의 지문은 `scripts/gate-key.py` 가 낸다 — 검사가 대조하는 문서와 기록을 뺀 파일 전부와 파이썬 · git 판(ADR 0046). 조각 문서 스킬의 검사 둘은 `scripts/` 의 같은 이름 링크로 부른다(ADR 0018 의 3). `scripts/verify-map-pin.py` 는 원본 스킬의 절차 지도 링크가 커밋으로 박혔고 그 지도가 `vibe-slice/` 를 마지막으로 고친 커밋의 것인지 본다 — claude-kit 의 역사를 읽으므로 플러그인에 싣지 않는다(ADR 0019 의 5) |
| CI | `.github/workflows/eval.yml` | 키 없는 게이트(`gates.sh` 하나 — 변조본도 거기서 돈다. 변조 시험의 지문이 이미 물었으면 `--skip-bite` 로 부른다), 수트, 그리고 판정. 잡의 이름과 설정은 그 파일이 들고, 어느 체크를 필수로 거는지는 저장소 설정(브랜치 보호 · ruleset)이 든다 |

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
덮어쓰지 않는다 — 사본의 특화가 사라진다. 다시 심기는 `--merge` 다 — 대장의 `synced_commit` 을 그 커밋의 스크립트로 빈 자리에
심은 모양을 밑으로, 감사자 · 커맨드 · 검사기를 파일마다 사본 · 새 원본과 `git merge-file` 로 합치고, README 는 출처 SHA 한 자리만
바꾼 뒤 대장의 그 줄을 옮긴다. 충돌 · 사본 레포의 뒤처짐 · 원본의 파일 묶음이 바뀜 같은 걸림이 하나라도 있으면 사본과 대장에
아무것도 쓰지 않는다(ADR 0038). 손 병합이 남는 자리는 원본에 파일이 새로 생기거나 물러난 뒤의 첫 심기(ADR 0038 의 3)와 `--merge` 가
멈춘 심기뿐이다. `--force` 는 사본을 일부러 원본으로 되돌릴 때다.

**스킬 심기.** `scripts/sync-slice.sh <레포>` 가 `vibe-slice` 의 스킬 폴더를 다 그 레포의 `.claude/skills/<스킬>/` 에
심고 스킬마다 `SKILL.md` 머리에 출처 커밋을 박는다(ADR 0014 의 7). 스킬의 절차 지도 링크도 — `blob/main/` 이든 원본이 박은
`blob/<전체 sha>/` 든 — 출처 커밋(전체 sha)으로 다시 박고(ADR 0019 의 3), 그 밖의 claude-kit 링크 꼴이 있으면 심지 않는다.
원격 가지에 없는 원본은 링크가 열리지 않으므로 심지 않는다(ADR 0017). 감사자 사본과 달리 대장에 적지 않고 견주지도 않는다 —
있으면 `--force` 로만 폴더째 덮는다(ADR 0013). 대화형 세션은 `vibe-slice` 플러그인으로 받고, 그 링크는 원본이 박은 커밋 그대로다 — 원본 스킬의 링크는 `vibe-slice/` 를
마지막으로 고친 커밋과 같은 지도를 가진 커밋을 박는다(ADR 0019 의 1 · 2).

**견주기.** 셋이 층을 나눈다.

- `scripts/verify-copy.py` — 사본이 원본의 공통 절과 `tools` 를 **글자 단위로** 들고 있는가. 절이 있는지만 보면
  손으로 다시 쓰거나 한 줄 빠뜨려도 통과하기 때문이다. 사본 고유의 특화는 보지 않는다.
- `scripts/verify-copies.py` — 대장이 성한가(빠진 자리 · 같은 레포 두 번 · 이 저장소에 없는 커밋)를 보고, 경로가
  이 기계에 있으면 `verify-copy.py` 까지 이어 돌린다. 없으면 못 봤다고 찍는다. **갈린 것 자체는 실패가 아니다** —
  원본이 그 뒤 몇 커밋 움직였는지와 그 사이 바뀐 원본 파일의 이름은 찍되 판정하지 않는다(ADR 0025 의 3). 이름은
  대장의 커밋과 이 저장소의 역사로 나오므로 경로가 없는 CI 에서도 찍힌다. 대장의 커밋을 찾으므로 git 역사 전체가
  있어야 한다.
- `scripts/compare-copies.py` — 감사자 · 커맨드 · 검사기 사본을 **심을 때의 원본**과 견줘 차이를 내용 해시로 묶은
  후보를 찍는다. 커맨드 · 검사기 사본의 자리는 `agents_path` 의 부모에서 끌어낸다(ADR 0025 의 1). 이미
  판정한 후보는 그 후보의 `seen` 밖의 새 레포에서 나올 때만 다시 나온다(ADR 0022 의 4). 사본이 원격보다 뒤거나
  더러우면 견주지 않고 멈춘다(ADR 0001 ~ 0003).

**판정.** 후보가 특화인지 결함인지는 사람이 정해 `feedback.json` 에 적는다 — 스크립트나 세션이 채우지 않는다.
가르는 질문은 `INTENT.md` Why 에 있다. `scripts/verify-feedback.py` 가 대장의 모양과 역사 규칙(번호 · 되먹임
커밋에 케이스가 있는가)을 본다.

**되먹임.** 결함으로 판정된 후보만 원본 감사자를 고친다. 문구가 글자 예산(`vibe-audit/evals/budget.txt` ·
`scripts/verify-budget.py`)을 넘으면 압축이 먼저다(ADR 0004). 특화 항목은 원본에 올리지 않는다 — 미리 지어낸 특화
항목은 재지 않고 단정한 것이기도 하다.

**케이스.** 되먹임 한 건에 케이스 하나 — 진짜 부적합 하나(대조군)와 그 되먹임이 막는 거짓 판정. 정규식 그레이더가
있으면 바른 기록 여러 벌(`samples/pass.md` · `pass-*.md`)과 `samples/fail*.md` 로 그레이더가 가르는지도 본다
(`verify-graders.py`).

**수트.** `scripts/run-evals.sh` 가 깃발을 박아 `claude plugin eval` 을 돌린다. CI 는 같은 러너를 부른다. PR · `main` push 는
`route-*` 만 돌리고, 그 수트 입력의 지문(`scripts/eval-key.py`)이 이미 통과했으면 다시 돌지 않는다. 통과한 지문은 실행의
ref 범위에 캐시로 적혀, PR 은 제 merge ref 와 `main` 범위를 읽는다. `main` push 는 `main` 범위에서 못 찾으면 그 푸시를 머지
커밋으로 가진 PR 하나의 merge ref 를 캐시 목록 API 로 읽고(`scripts/eval-merged-pass.py`), 같은 키가 있으면 건너뛰며 그 키를
`main` 범위에도 적는다 — 지문을 바꾼 PR 의 수트가 머지 뒤 한 번 더 돌지 않는다(ADR 0021). 그래서 `main` 에서 다시 돌리려면
`refs/heads/main` 과 그 PR 의 `eval-route-` 항목을 둘 다 지우거나 전수를 부른다. 사람이 부르는 전수(`workflow_dispatch`)는
지문을 찾아보지 않고 늘 돈다. 재는 법과 케이스 표는 `vibe-audit/evals/README.md`. 회수율 케이스는 이 흐름 밖이다 — 같은 러너가 `--eval-dir recall` 로 같은 결과 정리를
그 폴더에 대고, 끝에 찾은 회차 수를 찍을 뿐 종료를 바꾸지 않는다(ADR 0050 의 2 · 4).

## 게이트가 무는가

키 없는 게이트는 도는 것과 무는 것을 따로 본다. 변조본은 다 `gates.sh` 가 부르는 파일 다섯에 있다 — `scripts/bite-gates.sh`
가 이 저장소의 검사기마다 변조본(사본 감사자의 `tools` 변조 · 대장의 없는 커밋 · 성하지 않은 후보 대장 · 파일 없는 라이선스
선언 · 가짜 하네스 · 수트 지문 …)을 만들어 떨어지는지 보고, 설계 → 구현 관문(`scripts/bite-slice-gate.py`) · 문서 대조 검사의
다른 레포 모드(`scripts/bite-verify-docs.py`) · 절차 지도 판(`scripts/bite-map-pin.py`) · `main` 푸시가 머지된 PR 의 통과를
읽는 판정(`scripts/bite-eval-merged-pass.py`)은 제 파일에 둔다. 검사기 몇은 자기 시험 스크립트(`scripts/test-*.py`)를
`gates.sh` 에 둔다. 다섯 다 수트 지문 밖이다 — `eval.yml` 은 지문에 들어 고치면 route 수트가 돈다(ADR 0016 의 6 · ADR 0018 의
6 · ADR 0019 의 5 · ADR 0020 의 1 · ADR 0021 의 3). `bite-gates.sh` 는 그 파일들이 지문에 들면 떨어지고(ADR
0020 의 6), 제자리에서 흔드는 파일(`copies.json` · 지문 시험의 파일)은 흔들기 전의 백업에서 되돌려 로컬의 커밋 안 한 수정을
남긴다(ADR 0020 의 3). `gates.sh` 의 `claude plugin validate` 는 정상 트리에서만 돈다 — 그것을 떨어뜨리는 변조본은 없다(ADR
0020 의 4). 새 검사를 세우면 그 변조본을 함께 넣는다(`CLAUDE.md` 「작업 방식」). 문서 대조 검사의 변조본(`bite-verify-docs.py` · `bite-gates.sh` 의 그 절)은 자체 시험을
`--first`(첫 어긋난 꼴에서 멈춘다)로 부르고 CPU 수만큼 함께 돌린다 — 바꾸지 않은 검사를 같은 길로 돌린 대조군이 먼저 지나가야 한다(ADR 0047).

변조 시험이 보는 것 — 검사 코드가 무는지 — 은 검사 코드와 그것이 규칙으로 읽는 파일이 그대로면 같다. 그래서 `gates.sh` 는
검사와 자체 시험 스물하나(`checks`)와 변조 시험 다섯(`bites`)을 두 묶음으로 두고, `--skip-bite <근거>` 로 부르면 `checks` 만 돌려
끝 줄에 「스물하나 통과 · 변조 시험 다섯은 건너뛰었다 — <근거>」를 찍는다. 인자 없이는 늘 스물여섯이고, `--skip-bite` 는 CI 에서만
받는다 — 로컬은 늘 다 돈다(ADR 0046 의 3 · 4 · 7). 같은 입력인지는 `scripts/gate-key.py` 의 지문이 가른다 — `git ls-files` 가
아는 파일에서 검사가 대조하는 문서와 기록(조각 폴더 · ADR · 작업 기록 · 마스터플랜 · 이 문서 · 스키마 · 의도 · 입구 문서 ·
README · 부적합 대장)만 빼고, 파이썬 · git 판을 키 머리에 넣는다(ADR 0046 의 2). 빼는 쪽만 적어 새 파일은 저절로 든다.
`bite-gates.sh` 는 빼는 꼴마다 지문이 그대로이고 넣는 꼴마다 바뀌는지, `bites` 묶음에 변조 시험 말고 아무것도 없는지, 거절하는
인자가 검사 전에 종료 2 인지를 문다. 인자 없이 부르면 변조 시험 다섯이 실제로 돌고 `--skip-bite` 는 그 다섯만 빼는지는 늘 도는
`scripts/test-gates.py` 가 가짜 스크립트를 세운 임시 저장소에서 문다 — CI 가 인자 없이 돈 실행을 「물었다」로 적는 전제다. 그 시험은
부르는 것을 제 고정 목록과 견주고, 어느 하나만 떨어뜨려도 `gates.sh` 가 떨어지는지 본다 — 검사 줄을 지우거나 그 실패를 삼키면
떨어진다(ADR 0049). `gate-key.py`
도 수트 지문 밖이다.

CI 의 gate 잡이 이것을 잇는다 — `gates.sh` 앞에서 `gate-key.py` 로 지문을 내고 Actions 캐시(`.gate-pass`, 키 머리 `gate-bite-`)에서
같은 키를 찾는다. PR 은 제 범위와 `main` 범위를, `main` 푸시는 `main` 범위를 읽고, `main` 푸시가 못 찾으면 수트와 같은 판정
(`scripts/eval-merged-pass.py`)으로 그 푸시를 머지 커밋으로 가진 PR 하나의 merge ref 를 보고 찾으면 `main` 범위에도 적는다.
찾았으면 근거(통과한 실행의 URL · 커밋과 지문)를 notice 로 찍고 `gates.sh --skip-bite "<근거>"` 를 부른다. 못 찾았으면 인자 없이
스물여섯을 돌리고, 그 실행이 통과했을 때만 키를 적는다 — 건너뛴 실행은 적지 않는다. 사람이 부른 `workflow_dispatch` 는 찾지 않고
다 돈다. 지문을 못 내거나 근거 파일이 비었으면 경고하고 다 돈다(ADR 0046 · 조각 35 설계 ② E). 이 적기 · 건너뛰기 조건 — gate 잡의 첫 열한
스텝의 판정에 드는 칸(`id` · `if` · `env` · `with` · `run` 의 명령 줄) — 은 늘 도는 `scripts/verify-eval-gate.py` 가 닫힌 목록과 글자 그대로
견준다. 알림 글 · 주석 · 스텝 이름 · 액션의 판은 자유다(ADR 0048). 수트 캐시(`.eval-pass` ·
`eval-route-`)와는 폴더와 키 머리가 달라 서로를 찾지 않는다. 다시 돌리려면 `gate-bite-` 항목을 지우거나 `workflow_dispatch` 를 부른다.

## 문서

의도(`INTENT.md`) · 마스터플랜(`docs/master-plan.md`) · 절차와 문서의 모양(`docs/procedure.md`) · 틀
(`vibe-slice/skills/slice-docs/templates/`) · 조각(`docs/slices/`) · 결정(`docs/adr/`). 문서의 모양은
`scripts/verify-docs.py` 가, 착공 PR 에 구현이 없고 구현이 기준 가지에 머지된 설계 위에 서는지는
`scripts/verify-slice-gate.py` 가 본다(ADR 0016). 두 검사의 실물은 조각 문서 스킬의 `scripts/` 에 있어 플러그인 · 사본과 함께
다른 레포에 가고, 다른 레포에서는 `verify-docs.py --repo <루트>` 가 지도 대신 검사 옆의 틀 여섯을 원천으로 읽는다(ADR 0018 의 2). 입구 `CLAUDE.md` 는
절 제목을 묻지 않고 의도와 마스터플랜을 가리키는지만 본다(ADR 0041 의 6). 프로필 `Profile.md` 도 절 제목을 묻지 않고, 있으면
`CLAUDE.md` 나 `CLAUDE.local.md` 가 가져오는지만 본다(ADR 0042 의 6).
살아 있는 문서와 기록의 구분은 `docs/procedure.md` 「살아 있는 문서와 기록」.
