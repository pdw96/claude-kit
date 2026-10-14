## 체크 항목

| # | 항목 | 판정 | 근거 위치 |
|---|---|---|---|
| 3 | 통과 · 쓰기가 멈추는가 | 적합 — 0002 는 PostgreSQL 16(`docker-compose.yml:3`)에서 CONCURRENTLY 로 트랜잭션 밖에서 인덱스를 만든다. SHARE UPDATE EXCLUSIVE 만 잡아 쓰기를 막지 않는다. 네 눈 어느 것에도 해당하지 않는다 | `migrations/versions/0002_orders_customer_index.py:16` |
| 5 | 외부 호출이 트랜잭션 안인가 | 부적합 | `app/checkout.py:12` — NC-1 |

## 부적합 목록

### NC-1 · 결제 승인이 열린 트랜잭션 안에서 불린다
- 위치: `app/checkout.py:12`
- 증상: `SessionLocal.begin()` 안에서 `payments.charge` 를 부른다. 커밋이 실패하면 주문은 롤백되지만 결제는 남는다.
- 되돌림: 불가
- 심각도: 높음

## 확인불가 항목

없음

## 관찰

### OB-1 · 도중 실패하면 INVALID 인덱스가 남는다
- 위치: `migrations/versions/0002_orders_customer_index.py:7`
- 왜 부적합이 아닌가: 독스트링이 그 경우의 처리를 적었다

## 안 본 것
- 없음
