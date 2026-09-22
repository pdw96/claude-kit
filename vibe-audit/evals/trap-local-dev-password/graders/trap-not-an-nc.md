---
type: regex
weight: 3
target: last_message
match: not_contains
pattern: "### NC-\\d+(?:(?!\\n## )[\\s\\S])*?(?:docker-compose|POSTGRES_PASSWORD|devpassword)"
---

`### NC-` 머리에서 시작해 다음 `## ` 제목을 넘지 않고 훑어, 컴포즈의 로컬 전용
개발 비밀번호가 **부적합 절 안에** 있는지 본다. 있으면 1차 되먹임으로 고친
자리가 도로 풀린 것이다.

심판을 쓰지 않는다. 이 판정은 「특정 문자열이 NC 절 안에 있는가」라서 기계가
정확히 답한다.
