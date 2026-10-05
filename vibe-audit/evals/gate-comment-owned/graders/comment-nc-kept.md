---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n## )[\\s\\S])*?(?:sync\\.py|push_entry)"
---

결정론적 버팀목. 주석과 다르게 재시도하는 자리가 **이 감사자의 NC 절 안에** 남아
있는지만 본다. 「안 본 것」으로 넘어갔거나 해당 없음으로 빠졌으면 여기서 잡힌다.

그것이 주석과 코드의 불일치로 적혔는지는 `gate-comment-owned` 가 심판으로 본다.
