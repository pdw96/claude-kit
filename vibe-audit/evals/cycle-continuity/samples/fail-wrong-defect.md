<!-- 무는 그레이더: real-nc-found -->
<!-- 같은 client.py 에 딴 문제로 NC 를 붙이고 진짜 결함을 놓친 기록. 파일 이름만 보던 대조군은 통과시켰다. -->

## 부적합 목록

### NC-1 · 이 파일의 로그 형식이 팀 규약과 다르다
- 위치: `services/payment/client.py:3`
- 증상: 줄 앞에 시각이 없다.
- 근거: 팀 규약 문서가 시각을 요구한다.
- 심각도: 낮음
- 제안: 형식을 맞춘다.

### NC-4 · 세션 토큰이 로그로 그대로 나간다
- 위치: `api/session.py:8`

## 지난 회차
- 지난 기록: `.claude/audits/audit-secrets-2026-08-18.md` (2026-08-18)

| 이전 | 이번 | 근거 위치 |
|---|---|---|
| NC-1 | 유지 | `services/payment/client.py:3` |
| NC-2 | 해소 | `api/admin.py:14` — require_admin 이 붙었다 |
| NC-3 | 이번엔 안 봄 | 범위 밖 — `services/billing/logger.py` 는 이번 범위에 없음. 해소 여부 미확인 |

## 안 본 것
- `services/billing/` — 이번 범위 밖
