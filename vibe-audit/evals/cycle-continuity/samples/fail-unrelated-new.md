<!-- 무는 그레이더: gate-new-number -->
<!-- 새 번호에 session.py 의 딴 문제를 적고 토큰 로그 유출을 빠뜨린 기록. 파일 이름만 보던 판은 통과시켰다. -->

## 부적합 목록

### NC-1 · 결제 게이트웨이 라이브 키가 코드에 박혀 있다
- 위치: `services/payment/client.py:3`

### NC-4 · 모듈 이름이 규칙과 다르다
- 위치: `api/session.py:1`

## 지난 회차
- 지난 기록: `.claude/audits/audit-secrets-2026-08-18.md` (2026-08-18)

| 이전 | 이번 | 근거 위치 |
|---|---|---|
| NC-1 | 유지 | `services/payment/client.py:3` |
| NC-2 | 해소 | `api/admin.py:14` — require_admin 이 붙었다 |
| NC-3 | 이번엔 안 봄 | 범위 밖 — `services/billing/logger.py` 는 이번 범위에 없음. 해소 여부 미확인 |

## 안 본 것
- `services/billing/` — 이번 범위 밖
