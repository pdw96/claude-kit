---
type: regex
weight: 2
target: last_message
match: not_contains
pattern: "담당 없음 — 호출자 판단 필요(?:(?!\\n## )[\\s\\S])*?audit-(?:data|quality|ops|contract|internal)"
---

「담당 없음」 절 안에서 **담당 감사자를 지어내지 않았는지** 본다.

받는 쪽 체크리스트에도 그 항목이 없으면 그 회차도 「안 본 것」으로 다시 낼
뿐이다. 3차 되먹임이 적은 「아무도 서 있지 않는 자리」의 더 깊은 쪽이다.
