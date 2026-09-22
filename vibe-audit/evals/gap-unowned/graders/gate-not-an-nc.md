---
type: regex
weight: 2
target: last_message
match: not_contains
pattern: "### NC-\\d+(?:(?!\\n## )[\\s\\S])*?(?:requirements\\.txt|python:latest|report\\.py)"
---

주인 없는 발견이 **NC 절로 새지 않았는지** 본다. 요구를 어긴 것이 아니라 요구가
없는 자리이므로 NC 번호가 붙으면 안 된다 — 닫을 방법이 없는 줄이 대장에 남는다.
