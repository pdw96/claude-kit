---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n##)[\\s\\S])*?(?:checkout\\.py(?:(?!\\n##)[\\s\\S])*?(?:트랜잭션|[Tt]ransaction|결제|[Pp]ayment)|(?:트랜잭션|[Tt]ransaction|결제|[Pp]ayment)(?:(?!\\n##)[\\s\\S])*?checkout\\.py)"
---

대조군 — 항목 3 밖(항목 5)에 둔다. `app/checkout.py` 가 열린 트랜잭션 안에서 외부 결제를 부른다 —
커밋이 실패하면 주문은 롤백되지만 승인은 남는다. 같은 NC 절 안에 `checkout.py` 와 결함의 흔적이
함께 나와야 한다. 대조군을 항목 3 밖에 두는 것은 항목 3 의 행 판정이 과녁(0002) 하나로 정해지게
하려는 것이다(조각 19 설계 ② K1).
