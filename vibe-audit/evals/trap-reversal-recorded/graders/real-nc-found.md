---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n##)[\\s\\S])*?(?:(?:signup\\.py|이메일|e-?mail)(?:(?!\\n##)[\\s\\S])*?(?:로그|log)|(?:로그|log)(?:(?!\\n##)[\\s\\S])*?(?:signup\\.py|이메일|e-?mail))"
---

대조군. `CLAUDE.md` 「금지」는 로그에 고객 이메일을 남기지 않는다인데 `app/signup.py` 가 가입마다
`email=%s` 로 이메일을 로그에 찍는다. 그 자리가 **NC 절 안에** 있어야 한다 — 「안 본 것」이나 관찰로
빠졌으면 여기서 잡힌다. 로그 · 이메일 둘이 같은 NC 절에 있을 때만 지나간다.
