# 부적합 대장 — 지나간 것

**지나간 것**을 든다 — 닫힌 부적합과 회차 절. 닫는 규칙 · 열린 부적합 · 다음 번호는 `docs/audit/nc-ledger.md` 가 든다. 이 파일은
소급해 고치지 않는다 — 뒤 회차가 앞 회차를 뒤집었으면 뒤 절이 그렇게 적는다.

- 베낀 틀: claude-kit `vibe-slice/skills/slice-docs/templates/nc-ledger-history.md` @ `d022edd` (2026-10-23)

## 닫힌 부적합

살아 있는 쪽에서 닫힘이 된 줄을 옮겨 온다. 글자는 바꾸지 않는다. 번호는 두 표를 가로질러 하나다.

| NC | 무엇 | 낸 회차 | 담당 | 심각도 | 상태 | 판정과 근거 |
|---|---|---|---|---|---|---|
| 1 | 「인자 없이 돈 `gates.sh` = 변조 시험 다섯이 돌았다」를 무는 검사가 없는데, CI 는 그 전제로 지문을 「물었다」로 적는다 — `bites` 의 `bite-gates.sh` 줄 지우기 · `main` 의 `bites` 호출 지우기 · 건너뛰는 분기 `-n` → `-z` 가 초록으로 지나가고, 변조 시험을 돌지 않은 실행이 지문을 적는다(`scripts/gates.sh:132-139` · `.github/workflows/eval.yml:150-166` · `scripts/bite-gates.sh:1273-1344`) | 회차 1 | `audit-quality` | 보통 | **닫힘** | 고침 — 저자가 조각 35 안에서 고치기로 정했다(2026-10-23). 조각 35 PR D #128(머지 `a99a533`): 늘 도는 `checks` 에 `scripts/test-gates.py`(가짜 스크립트를 세운 임시 저장소에서 `gates.sh` 를 인자 없이 · `--skip-bite` 로 불러 실제로 돈 것을 본다), `bite-gates.sh` 끝 절에 감사가 든 셋과 묶음을 넘나드는 둘의 변조본. 감사 제안 (2)(`eval.yml` 의 양성 근거)는 route 수트 비용 때문에 하지 않았다 — 설계 끝 「닫기 전 감사 회차에서 찾은 것」. 재감사가 닫는다. 회차 2(`audit-quality`, `4c8b33e`): 해소 — 감사가 든 세 어긋냄을 늘 도는 `checks` 의 `test-gates.py` 가 문다. 잔여(CI 의 인자 없는 꼴 · 변조 시험 실패의 전파)를 NC-2 로 냈다 → 부분 닫힘. NC-2 가 닫히고 `audit-quality` 회차가 잔여 없음을 볼 때 닫힌다 회차 3(`audit-quality`, `0f4115a` — 조각 36 닫기 전): 해소 — 「부분 닫힘」의 두 조건을 봤다. 잇는 NC-2 가 같은 회차에서 해소됐고 새 잔여는 없다. 남은 자리(`eval.yml` 의 적기 · 검사 줄 지우기)는 설계가 받아들인 관찰 OB-1 · OB-2 다 → 닫힘 |
| 2 | `test-gates.py` 는 CI 가 지문을 적는 전제의 두 자리를 무지 않는다 — (가) T1 은 `GITHUB_ACTIONS` 를 지운 채로만 인자 없이 부르고 CI 가 실제로 쓰는 꼴(`GITHUB_ACTIONS=true` 에 인자 없음)은 어디서도 불리지 않는다 (나) 가짜는 다 0 으로 끝나 「다섯 중 하나가 떨어지면 `gates.sh` 가 0 이 아니다」 쪽으로 빨개질 수 없다. `gates.sh:136` 에 `\|\| [ "${GITHUB_ACTIONS:-}" = true ]` 를 더하거나 `:143` 을 `bites \|\| true` 로, `:102` 를 `./scripts/bite-gates.sh \|\| true` 로 바꾼 것이 다 지나가고, 변조 시험 없이 · 떨어진 변조 시험을 삼킨 채 지문을 적는다(`scripts/test-gates.py:41-43` · `:60` · `:94-104` · `scripts/gates.sh:136` · `:143` · `.github/workflows/eval.yml:150-166` · `scripts/bite-gates.sh:1276-1316` · `:1350-1373`). NC-1 의 잔여 | 회차 2 | `audit-quality` | 보통 | **닫힘** | 등록 — 저자가 정했다(2026-10-23). 기한: 조각 「변조 시험 빠르게」의 `audit-quality` 회차 — 그 조각이 `gates.sh` 의 `bites` 와 변조 시험을 다시 짜므로 거기서 고치고 재감사한다(감사 제안 (1) T1′ · (2) T5 · (3) 변조본 셋, 다 `scripts/` 안이라 route 수트는 돌지 않는다). 조각 나눔의 그 줄에 적었다 고침 — 조각 36 PR C #133(머지 `0f4115a`): `test-gates.py` 에 T1′(`GITHUB_ACTIONS=true` 에 인자 없이)과 T5(다섯마다 하나가 1 이면 두 꼴 다 0 이 아니어야 한다), `bite-gates.sh` 끝 절에 감사가 든 어긋냄 넷의 변조본. 회차 3(`audit-quality`, `0f4115a`): 해소 — 넷 다 늘 도는 `checks` 의 `test-gates.py` 가 문다 → 닫힘 |

## 회차 1 — `audit-quality` · 조각 35 닫기 전 (2026-10-23)

- **감사한 커밋**: `ddaae39` — 브리핑의 「대상」 SHA 를 `.git/HEAD` → `refs/heads/ccr-ed755b65-4qed6n` = `ddaae3944bc8…` 와 맞춰 봤다. 브리핑은 이번 회차의 것이다. 「자름: 없음」. · **감사자**: `audit-quality`
- 기록: `docs/audit/records/audit-quality-2026-10-23-043316.md` · 브리핑: `docs/audit/briefs/audit-quality-2026-10-23-043316.md`(기준 `f0dc98e` → 대상 `ddaae39`, 10 파일, `verify-brief.py` PASS)
- 범위: 조각 35 PR A · B · C. 요구사항 「제약」의 감사 회차(닫기 전 — `audit-quality`, 원천 밖에서 저자가 골랐다)
- 돌린 법: 이 세션에 `vibe-audit` 플러그인이 깔려 있지 않아, `vibe-audit/agents/audit-quality.md` 를 시스템 프롬프트로 따르고 읽기 전용
  도구(Read · Grep · Glob)만 쓰는 하위 에이전트로 돌렸다. 브리핑은 `/audit-brief` 의 절차를 손으로 따라 만들었다
- 낸 것: NC-1(보통) · U-1 · U-2 · U-3
- 지난 회차: 없음 — 첫 회차
- 관찰: OB-1(`eval.yml` 의 건너뛰기 · 적기 조건과 K5 는 키 없이 무는 검사 없이 PR 본문과 리뷰로만 섰다) · OB-2(지문 밖 입력이 바뀐 뒤
  변조 시험을 다시 보는 시점이 시간에 묶여 있지 않다 — 예약 실행이 없다) · OB-3(`.claude/` 는 지문 안이다 — 감사 기록을 거기 커밋하면
  닫는 PR 이 변조 시험까지 다 돈다. 이 레포가 기록을 `docs/audit/` 에 두는 까닭)
- 담당 없음: 없음
- 저자 판정(2026-10-23): NC-1 고침 — 조각 35 안에서(PR D #128). U-1 은 저자가 답해 닫았다. U-2 · U-3 의 근거는 이 세션이 Actions 로그로 댔다

## 회차 2 — `audit-quality` · 조각 35 닫기 전, NC-1 재감사 (2026-10-23)

- **감사한 커밋**: `4c8b33e` — 브리핑의 「대상」 SHA 를 지금 HEAD 와 맞춰 봤다: `.git/HEAD` → `refs/heads/ccr-ed755b65-4qed6n` = `4c8b33e635b6…`. 브리핑은 이번 회차의 것이다. 브리핑에는 「커밋 안 된 변경: 없음 · 추적 안 된 파일: 없음 · 자름: 없음」이라고 적혀 있다. · **감사자**: `audit-quality`
- 기록: `docs/audit/records/audit-quality-2026-10-23-053727.md` · 브리핑: `docs/audit/briefs/audit-quality-2026-10-23-053727.md`(기준 `ddaae39` → 대상 `4c8b33e`, 6 파일, `docs/audit/` 를 뺐다, `verify-brief.py --exclude docs/audit` PASS)
- 범위: 조각 35 PR D #128(머지 `a99a533`)과 닫는 PR 의 첫 커밋(대장 세우기 · `CLAUDE.md` 의 한 줄). 돌린 법은 회차 1 과 같다
- 낸 것: NC-2(보통 — NC-1 의 잔여) · U-4
- 지난 회차: NC-1 해소 → 부분 닫힘(잔여 NC-2). U-3 유지(2회차째 — W1 근거 없음). U-1 · U-2 는 대장에서 닫혀 있었다
- 관찰: OB-1(`eval.yml` 의 적기는 여전히 분기를 믿는다 — 2회째) · OB-2(`test-gates.py` 는 「부르는 것」을 시험 대상에서 읽는다 — 검사 줄을 통째로 지우면 지나간다) · OB-3(「`.claude/` 아래에는 커밋하지 않는다」는 규칙 글뿐이다 — 2회째. 한 번 더 나오면 `.gitignore` 에 두 경로를 둘지 정하자는 제안)
- 담당 없음: 없음
- 저자 판정(2026-10-23): NC-2 등록 — 기한은 조각 「변조 시험 빠르게」의 `audit-quality` 회차. U-4 의 근거는 이 세션이 Actions 로그로 댔다

## 회차 3 — `audit-quality` · 조각 36 닫기 전 (2026-10-25)

- **감사한 커밋**: `0f4115a` — 브리핑의 「대상」 SHA 를 지금 HEAD 와 맞춰 봤다: `.git/HEAD` → `refs/heads/ccr-95fc4682-hd2r9f` = `0f4115ad9fb1…`(`origin/main` 도 같다). 브리핑은 이번 회차의 것이다. 브리핑에는 「커밋 안 된 변경: 없음 · 추적 안 된 파일: 없음 · 자름: 없음」이라고 적혀 있다. · **감사자**: `audit-quality`
- 기록: `docs/audit/records/audit-quality-2026-10-25-105619.md` · 브리핑: `docs/audit/briefs/audit-quality-2026-10-25-105619.md`(기준 `a959096` → 대상 `0f4115a`, 10 파일, `docs/audit/` 를 뺐다, `verify-brief.py --exclude docs/audit` PASS)
- 범위: 조각 36 착공 #131 · PR B #132 · PR C #133. 요구사항 「제약」의 감사 회차(닫기 전 — `audit-quality`, 대장이 이 조각에 기댄다 — NC-2 의 기한). 돌린 법은 회차 1 과 같다
- 낸 것: 부적합 없음 · U-5
- 지난 회차: NC-2 해소 → 닫힘. NC-1 해소 — 「부분 닫힘」의 두 조건을 봤다 → 닫힘. U-1 ~ U-4 는 대장에서 닫혀 있었다
- 관찰: OB-1(`eval.yml` 의 적기는 여전히 분기를 믿는다 — 3회째. 조각 나눔에 줄을 세우거나 두지 않는 결정을 ADR 로 남기자는 제안) · OB-2(`test-gates.py` 의 기대 목록은 시험 대상에서 나온다 — 검사 줄 지우기와 `checks` 쪽 `|| true` 가 지나간다, 2회째) · OB-3(새 깃발의 거절과 `.gitignore` 한 줄은 PR 본문의 손 확인뿐이다) · OB-4(`bite-gates.sh` 의 문서 대조 절은 0 이 아닌 종료를 다 「물었다」로 센다 — 함께 돌게 된 뒤로 자원으로 죽은 실행이 숨을 수 있다)
- 담당 없음: 없음
- 저자 판정(2026-10-25): OB-1 은 조각 나눔에 「`eval.yml` 적기 조건 검사」 줄로 넘긴다. OB-4 는 이 조각에서 고친다 — 조각 36 PR D #134(머지 `156326a`). U-5 의 근거는 이 세션이 Actions 로그로 댔다

## 회차 4 — `audit-quality` · 조각 37 닫기 전 (2026-10-26)

- **감사한 커밋**: `06d0205` — 브리핑의 「대상」 SHA 를 지금 HEAD 와 맞춰 봤다: `.git/HEAD` → `refs/heads/ccr-5e3be11c-yj2ahc` = `06d0205d2450…`(`origin/main` 도 같다). 브리핑은 이번 회차의 것이다. 브리핑에는 「커밋 안 된 변경: 없음 · 추적 안 된 파일: 없음 · 자름: 없음」이라고 적혀 있다. · **감사자**: `audit-quality`
- 기록: `docs/audit/records/audit-quality-2026-10-26-032802.md` · 브리핑: `docs/audit/briefs/audit-quality-2026-10-26-032802.md`(기준 `7df49c4` → 대상 `06d0205`, 9 파일, `docs/audit/` 를 뺐다, `verify-brief.py --exclude docs/audit` PASS)
- 범위: 조각 37 착공 #136 · PR B #137 · PR C #138. 요구사항 「제약」의 감사 회차(닫기 전 — `audit-quality`, 이 조각이 그 감사자의 관찰 OB-1 의 제안이다). 돌린 법은 회차 1 과 같다
- 낸 것: 부적합 없음 · U-6
- 지난 회차: 회차 1 · 2 · 3 의 OB-1(적기 · 건너뛰기 조건은 리뷰뿐이다) — 제안이 받아들여져 요구가 섰다, 이 자리의 관찰은 닫힌다. OB-2 유지(3회째). U-1 ~ U-5 는 대장에서 닫혀 있었다
- 관찰: OB-1(새 검사는 자기가 지키는 스텝 안에서 돈다 — T9 가 `gates.sh` 에 닿지 않는 `eval.yml` 의 그 CI 실행에서는 물지 않는다) · OB-2(`gates.sh` 에서 새 검사 줄을 지우거나 삼켜도 아무것도 떨어지지 않는다 — 3회째, 규칙을 세우거나 두지 않는 결정을 ADR 로 남기자는 제안) · OB-3(자유로운 알림 줄도 GitHub 이 읽는 워크플로 명령이고, G 는 `eval.yml` 한 파일만 본다) · OB-4(변조본의 「물었다」는 어느 규칙이 물었는지 보지 않고 개수를 단언하지 않는다)
- 담당 없음: 없음
- 저자 판정(2026-10-26): OB-3 의 알림 줄 몫은 이 조각에서 고친다 — 조각 37 PR D #139(머지 `2e038e7`). OB-2 는 조각 나눔에 「`gates.sh` 검사 목록의 고정」 줄로 넘긴다. OB-1 · OB-4 와 OB-3 의 다른 워크플로 파일 몫은 설계가 받아들인 한계로 둔다(조각 37 설계 끝 「닫기 전 감사 회차에서 찾은 것」). U-6 의 근거는 이 세션이 Actions 로그로 댔다
