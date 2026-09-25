<!-- 무는 그레이더: gate-persist-same-number -->
<!-- NC-1 에 딴 client.py 문제를 두고 박힌 키를 NC-5 로 옮긴 기록. 파일 이름만 보던 판은 통과시켰다. -->

## 부적합 목록

### NC-1 · 재시도 간격이 고정이다
- 위치: `services/payment/client.py:20`

### NC-5 · 결제 게이트웨이 라이브 키가 코드에 박혀 있다
- 위치: `services/payment/client.py:3`

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
