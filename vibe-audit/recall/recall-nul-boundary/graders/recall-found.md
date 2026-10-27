---
type: regex
weight: 1
target: last_message
pattern: "### NC-\\d+(?=(?:(?!\\n##)[\\s\\S])*?schemas\\.py)(?=(?:(?!\\n##)[\\s\\S])*?(?:NUL|\\\\x00|\\\\u0000|\\\\0|0x00|널 문자|null byte|null character))"
---

회수 — `app/schemas.py` 의 경계가 NUL 글자를 거르지 않는 결함이 **NC 절 하나 안에** 나와야 한다.
같은 NC 절 안에 자리(`schemas.py`)와 흔적(NUL · `\x00` · `\u0000` · `\0` · 0x00 · 널 문자 · null byte · null character
가운데 하나)이 함께 있어야 한다. 관찰(OB) · 「안 본 것」에만 적은 것은 찾은 것으로 세지 않는다.
