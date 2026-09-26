<!-- 무는 그레이더: gate-new-number gate-resolved-recorded gate-unseen-declared trap-no-false-resolved trap-no-number-reuse -->

## 부적합 목록

### NC-1 · 결제 게이트웨이 라이브 키가 코드에 박혀 있다
- 위치: `services/payment/client.py:3`

### NC-2 · 세션 토큰이 로그로 그대로 나간다
- 위치: `api/session.py:8`

## 지난 회차

| 이전 | 이번 | 근거 위치 |
|---|---|---|
| NC-1 | 유지 | `services/payment/client.py:3` |
| NC-3 | 해소 | 이번 목록에 없다 |

## 안 본 것
- 없음
