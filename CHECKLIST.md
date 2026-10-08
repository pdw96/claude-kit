# 머지 전 확인

자동으로 볼 수 있는 것은 `scripts/gates.sh` 와 CI 에 있다. 여기는 **사람이 보는 것**만 둔다.

## 항상

- [ ] `./scripts/gates.sh` 통과 — CI gate 잡과 같다
- [ ] 새 검사를 세웠다면 CI 「게이트가 무는가」나 `gates.sh` 가 부르는 변조본(`bite-*.py`)에 그것이 떨어지는 변조본이 있다
- [ ] CI verdict 가 초록이다 — Skipped 가 아니라 통과
- [ ] 살아 있는 문서에 시간에 기댄 문장이 없고, 머지된 기록(조각 폴더 · ADR · `docs/eval-log/`)의
      지난 항목을 고치지 않았다 — 기록에 더한 것은 날짜를 박은 새 항목(요구사항 끝의 `## 닫으며 (<YYYY-MM-DD>)` 포함)뿐이다
- [ ] 감사자 작업 기록을 더했다면 `docs/eval-log/<YYYY-MM>.md` 에 덧붙였다 — 이름이 그 꼴이고(`docs/procedure.md`
      「살아 있는 문서와 기록」), `vibe-audit/evals/README.md` 에는 날짜를 박은 절을 쌓지 않았다

## 플러그인의 파일을 고쳤다면

- [ ] 그 플러그인의 `plugin.json` 판을 올렸다(`vibe-audit` · `vibe-slice`) — 판이 그대로면 이미 설치한 레포가
      `claude plugin update` 를 해도 새 파일을 받지 않는다(ADR 0013). 틀 넷도, 검사 둘(`scripts/verify-docs.py` ·
      `scripts/verify-slice-gate.py` — 링크의 실물은 `vibe-slice/skills/slice-docs/scripts/`)도 `vibe-slice` 의 파일이다

## 감사자 문구를 고쳤다면

- [ ] 판정 케이스에 닿는 변경이면 전수(workflow_dispatch)를 돌렸다 — 월 한도 $20 안에서
- [ ] 공통 절을 고쳤다면 사본이 갈리는 것을 알고 있다(`verify-copies.py` 가 찍는다)

## 되먹임이라면

- [ ] 옮긴 문구에 사본 레포의 이름 · 경로 · 표 이름 · NC 번호가 없다
- [ ] `feedback.json` 의 후보가 `fed_back` 이고 원본 커밋 · 케이스가 적혀 있다
- [ ] 예산 천장을 올렸다면 저자 승인과 그 되먹임의 eval 근거가 PR 에 있다

## 조각을 시작했다면

- [ ] 조각이 `docs/master-plan.md` 조각 나눔에 있고 상태가 맞다 — 조각을 닫았다면 `닫힘`, 요구사항 끝에 `## 닫으며 (<YYYY-MM-DD>)`
- [ ] 조각 폴더의 요구사항과 설계가 한 PR 이다 — 구현은 그 PR 이 머지된 뒤(순서는 `verify-slice-gate.py` 가 본다), 설계 ④ 의 열어 둔 것을 정한 뒤(사람이 본다)
- [ ] 설계의 해당 없는 칸은 지우지 않고 「없음 — 이유」다 — 필수 제목 · 경로 · 조각 나눔 · 닫는 기록은
      `verify-docs.py` 가 본다(조각 3 설계 ②). 그 밖은 여기서 사람이 본다
- [ ] 의도를 `INTENT.md` 가 아닌 문서가 들면 그 문서에 Why · What · Not 이 있다 — 검사는 경로만 본다(ADR 0010)
- [ ] PR 본문에 설계 ② 와 `## 리뷰 회차` 표가 있고, 지적마다 답글에 갈래와 근거 줄(반박됨 · 확인 못 함이면 확인한 시도)이 있다 —
      가르는 법은 스킬 `slice-review`. 머지 직전에 표 끝의 「머지할 머리」 줄이 있다

## 대장을 건드렸다면

- [ ] `copies.json` 은 `sync-agents.sh` 를 거쳤다
- [ ] `feedback.json` 의 판정은 저자가 했다 — 스크립트나 세션이 채운 판정이 아니다
