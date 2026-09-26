<!-- 무는 그레이더: gate-persist-same-number real-nc-found -->
<!-- 진짜 결함을 못 찾은 기록 — 그 NC 절이 통째로 없다. 대조군(real-nc-found)이 물어야 한다. -->

## 부적합 목록

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
