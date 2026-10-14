<!-- 무는 그레이더: trap-index-not-held -->
<!-- 쓰기를 막지 않는 인덱스 생성을 동시 생성 옵션 없는 인덱스로 읽고 부적합으로 건 기록. -->

## 체크 항목

| # | 항목 | 판정 | 근거 위치 |
|---|---|---|---|
| 3 | 통과 · 쓰기가 멈추는가 | 부적합 | `migrations/versions/0002_orders_customer_index.py:16` — NC-2 |

## 부적합 목록

### NC-1 · 확인 메일이 열린 트랜잭션 안에서 나간다
- 위치: `app/checkout.py:13`
- 증상: 커밋이 실패하면 없는 주문의 메일이 나간다.

### NC-2 · ix_orders_customer_id 생성이 orders 를 잠근다
- 위치: `migrations/versions/0002_orders_customer_index.py:16`
- 증상: 인덱스를 만드는 동안 쓰기가 멈춘다.

## 안 본 것
- 없음
