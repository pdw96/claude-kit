# 조각 29 설계 — 관문 검사의 한글 경로

설계다 — **어떻게 · 경계.** 무엇을 · 왜는 같은 폴더의 `requirements.md`.

## ① 바뀌는 것

| 파일 | PR | 무엇 |
|---|---|---|
| `docs/master-plan.md` | A · 닫기 | 조각 나눔에 29 줄(`진행`), 닫기에서 `닫힘` |
| `docs/slices/29-gate-quoted-paths/` · `docs/adr/0040-gate-quoted-paths.md` | A | 이 요구사항 · 설계 · ADR |
| `vibe-slice/skills/slice-docs/scripts/verify-slice-gate.py` | B | 바꾼 파일을 받는 `changed()` 가 경로를 `-z` 로 받아 NUL 로 가른다 — 그 일을 도우미 하나(`names()`)가 맡는다. 판정 · 인자 · 출력의 모양은 그대로 |
| `scripts/test-verify-slice-gate.py` | B | E3 의 꼴 · 시험 환경에 `core.quotepath=true` 를 박음 |
| `scripts/bite-slice-gate.py` | B | E3 의 변조본 하나 · B3 변조본의 찾는 글자(`must` → `names`) |
| `vibe-slice/.claude-plugin/plugin.json` | B | 0.4.4 (`CHECKLIST.md` 「플러그인의 파일을 고쳤다면」) |
| pdw96/ERP `.claude/skills/slice-docs/` · `.claude/skills/slice-review/` | C | B 의 머지 커밋에서 `sync-slice.sh --force` — 머리줄 · 지도 링크는 스크립트가 박는다 |

앵커볼트를 건드리지 않는다 — 이름 · 감사자 · 대장 · 「…의 칸」 · 고정 영역이 그대로다. 부품 · 경계 · 흐름이 그대로라 `docs/architecture.md` 를
고치지 않는다. `scripts/verify-slice-gate.py` 는 실물을 가리키는 링크라 그대로다(ADR 0018 의 3).

## ② 보장하는 것 / 보장하지 않는 것

**보장하는 것** — 번호는 조각 7 설계 ② 와 조각 9 설계 끝 「단계 5 에서 찾은 것」(E1 · E2)에 잇는다. ⑤ 와 B 의 PR 본문이 같이 쓴다.

- E3 **바꾼 파일의 경로를 git 이 가진 글자 그대로 받는다.** `diff --name-only` · `ls-files --others --exclude-standard` 를 `-z` 로 불러 NUL 로
  가른다 — git 의 따옴표 · 이스케이프를 거치지 않으므로 사용자 · 레포의 git 설정(`core.quotepath`)에 기대지 않는다. ASCII 밖의 글자(한글) · 줄바꿈이
  든 경로도 같다. 그 경로로 B3 · D1 · G1 · G2 를 조각 7 설계 ② 그대로 가르고, 실패 줄에 글자 그대로 찍는다.
  - B3 의 두 길이 다 E3 를 지난다 — 머리가 커밋이면 `diff` 하나, 작업트리면 `diff` 와 `ls-files --others`.
  - 기준 쪽은 이미 맞다 — `git show <기준>:<경로>` · `git cat-file -e <기준>:<경로>` 는 경로를 인자로 받는다. 기준 마스터플랜의 한글 조각 폴더에서
    `design.md` 를 찾는다(G2). B 의 시험이 그것도 본다.
- R4 · R5 를 E3 로 넓힌다 — 자체 시험에 E3 의 꼴이 있고(⑤), `bite-slice-gate.py` 의 변조본 하나가 E3 의 자리를 망가뜨려 자체 시험에서 떨어진다.
  자체 시험은 `core.quotepath=true` 를 환경으로 박는다 — 부른 쪽의 git 설정이 그것을 꺼도 E3 의 꼴이 무르지 않는다.
- **스킬** — `slice-docs` · `slice-review` 는 같은 파일(`slice-docs/scripts/verify-slice-gate.py`)을 부르므로 고침이 두 호출에 다 미친다. 스킬 문구는
  그대로다.
- **사본** — C 뒤 ERP 의 두 사본 머리줄 출처가 B 의 머지 커밋이고, 사본의 검사가 요구사항 성공 기준 4 를 지난다.

**보장하지 않는 것(알려진 한계)**

- **UTF-8 이 아닌 POSIX 로케일에서 한글 경로를 git 인자로 넘기기** — `LC_ALL=C PYTHONUTF8=0 PYTHONCOERCECLOCALE=0` 처럼 파이썬의 UTF-8 모드와 로케일
  강제를 다 끈 꼴이면 파일 시스템 인코딩이 `ascii` 라, `cat-file -e <기준>:<한글 경로>` 의 인자를 만들다 `UnicodeEncodeError` 로 끝난다(이 세션에서
  확인). 기준 마스터플랜의 `진행` 조각 폴더가 한글이면 고치기 전에도 같다. 한국어 Windows(E1 · E2 가 흉내 낸 것)는 인자를 유니코드로 넘겨 나지 않고,
  파이썬 3.7 뒤로 C 로케일은 UTF-8 모드 · 로케일 강제가 저절로 켜진다. 겪지 않은 꼴이다.
- **유니코드 정규화** — 마스터플랜의 조각 폴더 글자와 커밋된 경로가 다른 정규형(NFC · NFD)이면 G2 가 설계를 못 찾는다. 겪지 않은 꼴이다.
- **다른 사본 레포 · 이미 설치한 플러그인** — C 가 심는 것은 ERP 하나다. 플러그인으로 받은 세션은 `claude plugin update vibe-slice@pdw96-kit` 뒤에
  고친 검사를 읽는다(ADR 0013).
- **아직 겪지 않은 가설적 경계 사례** — 조각 7 설계 ② 의 같은 줄 그대로다.

## ③ 받는 입력

조각 7 설계 ③ 의 닫힌 목록 그대로다 — 인자 · 이벤트 JSON · 기준 마스터플랜. 바뀌는 것은 git 출력의 모양 하나다.

**바꾼 파일 목록** — `git diff --name-only --no-renames -z <merge-base> [<머리>]` · `git ls-files --others --exclude-standard -z`. 이 세션의 git 2.43
에서 뽑았다 — 경로마다 NUL 로 끝나고, 따옴표 · 이스케이프가 없는 바이트다(`docs/slices/3-\354\235\264…/design.md\0` 을 `od -c` 로 봤다). UTF-8 로
읽는다(E2). 경로 글자의 닫힌 목록 — ASCII 만 · ASCII 밖(한글) · 줄바꿈이나 따옴표가 든 것. 셋 다 받는다. 빈 출력은 바꾼 파일이 없는 것이다(B5).

**같은 결함이 있는 자리를 훑었다** — git 의 경로 출력을 줄로 받는 곳.

| 자리 | 무엇을 읽나 | 이 조각 |
|---|---|---|
| `verify-slice-gate.py` `changed()` | 다른 레포의 바꾼 파일 — 한글일 수 있다 | 고친다(E3) |
| `verify-docs.py` | git 을 쓰지 않는다 — 파일 시스템에서 읽어 경로를 견준다 | 그대로(하지 않을 일 2) |
| `verify-map-pin.py` · `verify-copies.py` · `compare-copies.py` · `sync-agents.sh` · `sync-slice.sh` | 이 저장소의 `vibe-slice/` · `vibe-audit/` 와 사본 레포의 `.claude/` 아래 — 원본이 이름을 정하고 다 ASCII 다 | 그대로(하지 않을 일 5) |

## ④ 결정

**정한 것**

- 경로를 `-z` 로 받는다 — `-c core.quotepath=false` · 따옴표를 풀어 읽기가 아니다. ADR 0040 의 1.
- ERP 다시 심기를 이 조각의 C 로 한다 — 그 레포의 다음 심기에 맡기지 않는다. ADR 0040 의 2.

**열어 둔 것**

없음 — B 의 코드는 이 세션이 로컬에서 세워 ⑤ 를 돌려 봤다(B 의 PR 이 싣는다). C 의 길은 pdw96/ERP#114 가 이미 정했다.

## ⑤ 검증 계획

**시험 규칙** — 키 없이 도는 시험을 고치는 조각이다. 꼴 하나하나와 보장의 조건 → 꼴 → 변조본의 대응은 B 의 시험 코드와 PR 본문이 든다(ADR 0039).

- V1 **③ 의 길 둘과 관문 셋을 덮는다** — E3 의 꼴은 바꾼 파일의 길 둘(커밋된 머리 · 작업트리의 새 파일)과 결정 문서의 꼴 둘(한글 조각 문서 · 한글
  ADR)을 쓰고, 관문 셋(결정 문서만인 착공 PASS · 구현이 섞인 착공 G1 · `진행` 조각이 없는 구현 G2)이 다 나온다. 기준 마스터플랜의 `진행` 조각
  폴더가 한글인 구현 PASS 도 하나.
- V2 **성공 시험은 exit 0 과 G1 · G2 가 없음을, 떨어지는 시험은 exit 1 · 선 번호 · 서지 않아야 할 번호가 없음을 본다.** G1 꼴은 기준에 설계가 머지된
  다른 `진행` 조각을 두어 G2 가 서지 않게 한다 — 고치기 전의 조용한 통과를 G1 만이 문다. 실패 줄이 경로를 글자 그대로 찍는지 하나가 본다.
- V3 **시험 환경이 `core.quotepath=true` 다** — `GIT_CONFIG_COUNT` 로 박고 `GIT_CONFIG_PARAMETERS` 를 뺀다.
- V4 **고침을 걷어 낸 검사에서 빨갛다** — `987df53` 의 검사에 자체 시험을 대어 E3 의 꼴이 떨어지는 것을 B 의 PR 본문에 싣는다. `-c core.quotepath=false`
  만 붙인 검사(ADR 0040 의 1 의 대안)에도 대어 줄바꿈 꼴이 떨어지는 것을 싣는다.
- V5 **변조본** — E3 의 자리를 줄로 받기로 되돌린 사본이 자체 시험에서 떨어진다(`bite-slice-gate.py`). B3 변조본은 찾는 글자만 따라 고친다.

**그 밖**

- `./scripts/gates.sh` 스물넷 — B 의 로컬과 CI gate 잡. A 는 결정 문서만이라 관문을 지난다.
- C — ERP 에서 요구사항 성공 기준 4 를 돌린 결과를 그 PR 본문에 싣는다. 사본 여섯 파일 밖의 차이(머리줄 · 지도 링크 말고)가 없는지 원본과 견준다
  (#114 와 같은 확인).
- 단계 5 — B 의 머지가 `vibe-slice` 0.4.4 의 배포이고, C 의 머지가 ERP 사본의 배포다. 되돌리는 길은 C → B 순으로 되돌리고 판을 올리는 것이다.

## ⑥ PR 나눔

| PR | 담는 것 | 닫는 것 |
|---|---|---|
| A 착공 | 마스터플랜 29 줄 · 요구사항 · 설계 · ADR 0040 | — |
| B 구현 | 검사 · 자체 시험 · 변조본 · `plugin.json` 0.4.4 | E3 · R4 · R5 의 넓힘. 성공 기준 1 · 2 · 3 · 5 |
| C ERP 다시 심기 | pdw96/ERP 의 PR — B 의 머지 커밋에서 `sync-slice.sh --force` | 성공 기준 4 |

C 가 머지되면 닫는 PR 을 낸다.
