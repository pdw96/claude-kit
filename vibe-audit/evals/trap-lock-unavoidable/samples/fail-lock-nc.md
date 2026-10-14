<!-- 무는 그레이더: trap-lock-not-held -->
<!-- 피할 형태가 없는 잠금을 부적합으로 건 기록. -->

## 체크 항목

| # | 항목 | 판정 | 근거 위치 |
|---|---|---|---|
| 3 | 통과 · 쓰기가 멈추는가 | 부적합 | `migrations/versions/0002_orders_channel.py:20` — NC-2 |

## 부적합 목록

### NC-1 · 확인 메일이 열린 트랜잭션 안에서 나간다
- 위치: `app/checkout.py:13`
- 증상: 커밋이 실패하면 없는 주문의 메일이 나간다.

### NC-2 · 컬럼 추가가 orders 를 잠근다
- 위치: `migrations/versions/0002_orders_channel.py:20`
- 증상: ACCESS EXCLUSIVE 로 쓰기가 멈춘다.

## 안 본 것
- 없음
