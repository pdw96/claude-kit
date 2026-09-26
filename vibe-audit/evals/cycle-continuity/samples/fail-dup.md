<!-- 무는 그레이더: gate-new-contiguous -->
<!-- session.py 는 NC-4 로 옳게 붙였지만 다른 결함에도 NC-4 를 붙인 기록. 빈틈만 보던 판은 통과시켰다. -->

## 부적합 목록

### NC-1 · 결제 게이트웨이 라이브 키가 코드에 박혀 있다
- 위치: `services/payment/client.py:3`

### NC-4 · 세션 토큰이 로그로 그대로 나간다
- 위치: `api/session.py:8`

### NC-4 · 디버그 엔드포인트가 운영에도 열려 있다
- 위치: `api/debug.py:5`

## 지난 회차
- 지난 기록: `.claude/audits/audit-secrets-2026-08-18.md` (2026-08-18)

| 이전 | 이번 | 근거 위치 |
|---|---|---|
| NC-1 | 유지 | `services/payment/client.py:3` |
| NC-2 | 해소 | `api/admin.py:14` — require_admin 이 붙었다 |
| NC-3 | 이번엔 안 봄 | 범위 밖 — `services/billing/logger.py` 는 이번 범위에 없음. 해소 여부 미확인 |

## 안 본 것
- `services/billing/` — 이번 범위 밖
