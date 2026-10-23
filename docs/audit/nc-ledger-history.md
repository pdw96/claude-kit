# 부적합 대장 — 지나간 것

**지나간 것**을 든다 — 닫힌 부적합과 회차 절. 닫는 규칙 · 열린 부적합 · 다음 번호는 `docs/audit/nc-ledger.md` 가 든다. 이 파일은
소급해 고치지 않는다 — 뒤 회차가 앞 회차를 뒤집었으면 뒤 절이 그렇게 적는다.

- 베낀 틀: claude-kit `vibe-slice/skills/slice-docs/templates/nc-ledger-history.md` @ `d022edd` (2026-10-23)

## 닫힌 부적합

살아 있는 쪽에서 닫힘이 된 줄을 옮겨 온다. 글자는 바꾸지 않는다. 번호는 두 표를 가로질러 하나다.

| NC | 무엇 | 낸 회차 | 담당 | 심각도 | 상태 | 판정과 근거 |
|---|---|---|---|---|---|---|

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
