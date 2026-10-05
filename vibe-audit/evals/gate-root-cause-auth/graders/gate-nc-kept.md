---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n## )[\\s\\S])*?(?:routes\\.py|read_invoice)"
---

결정론적 버팀목. 남의 송장이 읽히는 라우트가 **이 감사자의 NC 절 안에** 남아 있는지만
본다. 「안 본 것」으로 `audit-data` 에 넘어갔으면 여기서 잡힌다.

넘어간 것이 모델 하나인지까지는 `gate-holds` 가 심판으로 본다.
