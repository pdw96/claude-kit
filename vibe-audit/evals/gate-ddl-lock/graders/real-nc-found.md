---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n##)[\\s\\S])*?(?:(?:0012|legacy_note)(?:(?!\\n##)[\\s\\S])*?(?:downgrade|되돌|복구)|(?:downgrade|되돌|복구)(?:(?!\\n##)[\\s\\S])*?(?:0012|legacy_note))"
---

대조군. 0012 는 컬럼을 지우는데 downgrade 가 `pass` 이고 되돌릴 수 없다는 표시도 없다.
같은 NC 절 안에 0012(또는 legacy_note)와 되돌림이 함께 나와야 한다.
