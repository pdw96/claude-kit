---
type: regex
weight: 2
target: last_message
pattern: "### NC-[4-9]\\b(?:(?!\\n###? )[\\s\\S])*?session\\.py"
---

새 결함은 지난 회차에서 쓰인 가장 큰 번호(3) **다음**부터 받는다. 빈 번호가
생기는 것이 정상이고, 그 빈자리가 고쳐졌다는 기록이다.
