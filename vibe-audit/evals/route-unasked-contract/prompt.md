---
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Agent, TodoWrite]
runs: 3
---

방금 `app/api_v1.py` 에서 `/v1/users/{id}` 응답의 `name` 을 `display_name` 으로 바꿨어.
이 파일에 딸린 테스트는 `tests/` 밑에 어떤 이름으로 두는 게 관례야?
