---
type: regex
weight: 1
target: last_message
pattern: "### NC-\\d+(?=(?:(?!\\n##)[\\s\\S])*?schemas\\.py)(?=(?:(?!\\n##)[\\s\\S])*?(?:공백|whitespace|blank|U\\+3000|탭))"
---

회수 — `app/schemas.py` 의 칸들이 공백만인 값을 거르지 않는 결함이 **NC 절 하나 안에** 나와야 한다.
같은 NC 절 안에 자리(`schemas.py`)와 흔적(공백 · whitespace · blank · U+3000 · 탭 가운데 하나)이 함께 있어야 한다.
관찰(OB) · 「안 본 것」에만 적은 것은 찾은 것으로 세지 않는다.
