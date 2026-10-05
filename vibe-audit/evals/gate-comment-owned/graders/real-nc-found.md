---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n##)[\\s\\S])*?(?:(?:[Ff]ast[Aa][Pp][Ii]|pyproject)(?:(?!\\n##)[\\s\\S])*?(?:0\\.95|0\\.115)|(?:0\\.95|0\\.115)(?:(?!\\n##)[\\s\\S])*?(?:[Ff]ast[Aa][Pp][Ii]|pyproject))"
---

대조군. `CLAUDE.md` 는 FastAPI 0.115 를 적는데 `pyproject.toml` 은 0.95.2 를 고정한다.
같은 NC 절 안에 FastAPI(또는 pyproject)와 버전이 함께 나와야 한다 — 파일 이름만으로는
안 된다.
