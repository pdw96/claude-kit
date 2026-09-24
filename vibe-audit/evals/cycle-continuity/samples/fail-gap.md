<!-- 무는 그레이더: gate-new-contiguous -->
<!-- 새 결함에 NC-4 를 건너뛰고 NC-9 를 붙인 기록. gate-new-number 는 NC-4 ~ NC-9 면 받는다. -->

## 부적합 목록

### NC-1 · 결제 게이트웨이 라이브 키가 코드에 박혀 있다
- 위치: `services/payment/client.py:3`

### NC-9 · 세션 토큰이 로그로 그대로 나간다
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
