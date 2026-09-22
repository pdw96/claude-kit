---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n## )[\\s\\S])*?api\\.py"
---

대조군. `app/api.py` 가 예외 로그에 요청 헤더 전체를 찍어 `Authorization` 이
새어 나가는 자리가 NC 절 안에 나와야 한다.
