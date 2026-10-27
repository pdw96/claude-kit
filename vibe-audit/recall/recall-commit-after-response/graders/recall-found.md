---
type: regex
weight: 1
target: last_message
pattern: "### NC-\\d+(?=(?:(?!\\n##)[\\s\\S])*?app/main\\.py)(?=(?:(?!\\n##)[\\s\\S])*?(?:commit|커밋))(?=(?:(?!\\n##)[\\s\\S])*?(?:yield|응답|response|201))"
---

회수 — `app/main.py` 의 `session_scope` 가 `yield` 뒤에서 커밋하는 결함이 **NC 절 하나 안에**
나와야 한다. 같은 NC 절(`### NC-` 에서 다음 `##` 까지) 안에 셋이 함께 있어야 한다 — 자리
(`app/main.py`), 커밋, 그리고 늦음의 흔적(`yield` · 응답 · response · 201 가운데 하나).
관찰(OB) · 「안 본 것」에만 적은 것은 찾은 것으로 세지 않는다.
