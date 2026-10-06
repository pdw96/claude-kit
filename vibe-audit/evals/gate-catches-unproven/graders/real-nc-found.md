---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n##)[\\s\\S])*?(?:ruff(?:(?!\\n##)[\\s\\S])*?(?:\\|\\|\\s*true|삼킨|무시|막지)|(?:\\|\\|\\s*true|삼킨|무시|막지)(?:(?!\\n##)[\\s\\S])*?ruff)"
---

대조군. CI 의 `ruff check . || true` 는 린트 실패를 삼켜 아무것도 막지 않는다.
같은 NC 절 안에 ruff 와 그것이 막지 못한다는 말이 함께 나와야 한다.
