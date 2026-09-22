---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n## )[\\s\\S])*?checkout\\.py"
---

대조군. `app/checkout.py` 가 열린 트랜잭션 안에서 외부 결제를 호출하는 자리가
NC 절 안에 나와야 한다.
