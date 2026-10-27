---
type: regex
weight: 1
target: last_message
pattern: "### NC-\\d+(?=(?:(?!\\n##)[\\s\\S])*?0007_shipping_zone\\.py)(?=(?:(?!\\n##)[\\s\\S])*?(?:downgrade|되돌|DELETE|지운|지워))(?=(?:(?!\\n##)[\\s\\S])*?(?:먼저 만든|먼저 만들|이미 있|NOT EXISTS|만들지 않은|값이 같|같은 값|글자까지|IS DISTINCT FROM))"
---

회수 — `0007_shipping_zone.py` 의 downgrade 가 리비전이 만들지 않은 같은 값의 줄을 지우는 결함이 **NC 절 하나
안에** 나와야 한다. 같은 NC 절 안에 셋이 함께 있어야 한다 — 자리(`0007_shipping_zone.py`), 지움(downgrade ·
되돌 · DELETE · 지운 · 지워), 그리고 그 줄이 남의 것인데 검사를 지나는 까닭(먼저 만든 · 이미 있 · NOT EXISTS ·
만들지 않은 · 값이 같 · 같은 값 · 글자까지 · IS DISTINCT FROM 가운데 하나). 관찰(OB) · 「안 본 것」에만 적은 것은
찾은 것으로 세지 않는다.
