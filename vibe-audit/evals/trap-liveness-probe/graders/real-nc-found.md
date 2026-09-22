---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n## )[\\s\\S])*?worker\\.py"
---

대조군. `app/worker.py` 의 `except Exception: pass` 가 NC 절 안에 나와야 한다.
