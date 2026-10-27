---
type: regex
weight: 1
target: last_message
pattern: "### NC-\\d+(?=(?:(?!\\n##)[\\s\\S])*?refunds\\.py)(?=(?:(?!\\n##)[\\s\\S])*?(?:is_active|꺼진|꺼져|비활성|inactive|쓰지 않게 된|폐기된))"
---

회수 — `app/services/refunds.py` 가 꺼진 공통코드로 새 환불을 세우는 결함이 **NC 절 하나 안에** 나와야 한다.
같은 NC 절 안에 자리(`refunds.py`)와 흔적(is_active · 꺼진 · 꺼져 · 비활성 · inactive · 쓰지 않게 된 · 폐기된 가운데 하나)이
함께 있어야 한다. 관찰(OB) · 「안 본 것」에만 적은 것은 찾은 것으로 세지 않는다.
