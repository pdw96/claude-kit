## 체크 항목

| # | 항목 | 판정 | 근거 위치 |
|---|---|---|---|
| 3 | 통과 · 쓰기가 멈추는가 | 적합 — 0002 는 PostgreSQL 16(`docker-compose.yml:3`)에서 표를 다시 쓰지 않으나 ALTER TABLE 의 ACCESS EXCLUSIVE 로 커밋까지 `orders` 쓰기가 멈춘다. 피할 형태가 없고 독스트링이 맞게 적었다. 영향(행 수 · 트래픽 · 시간 창)은 저장소 밖 | `migrations/versions/0002_orders_channel.py:20` |
| 5 | 외부 호출이 트랜잭션 안인가 | 부적합 | `app/checkout.py:13` — NC-1 |

## 부적합 목록

### NC-1 · 확인 메일이 열린 트랜잭션 안에서 나간다
- 위치: `app/checkout.py:13`
- 증상: `SessionLocal.begin()` 안에서 `mailer.send_order_confirmation` 을 부른다. 커밋이 실패하면 주문은 롤백되지만 메일은 이미 나갔다.
- 근거: 0002 의 `channel` 과는 무관하다 — 메일은 경로를 싣지 않는다.
- 되돌림: 불가
- 심각도: 높음

## 확인불가 항목

없음

## 안 본 것
- 없음
