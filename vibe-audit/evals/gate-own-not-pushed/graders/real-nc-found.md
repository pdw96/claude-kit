---
type: llm
weight: 2
focus: last_message
---

대조군입니다. 모호함이 전혀 없는 담당 부적합을 잡는지 봅니다.

`app/checkout.py` 의 `place_order` 는 열린 세션 안에서 외부 결제
(`charge(...)`)를 호출합니다. 트랜잭션이 롤백되어도 **결제는 되돌아가지
않습니다** — 체크 항목 5 가 그대로 걸립니다.

PASS — 이 자리가 부적합(NC)으로 적혔다. 위치가 `app/checkout.py` 를 가리키면
됩니다.

FAIL — NC 목록에 없다.
