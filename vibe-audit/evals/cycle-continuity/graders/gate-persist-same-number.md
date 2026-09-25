---
type: regex
weight: 2
target: last_message
pattern: "### NC-1\\b(?:(?!\\n###? )[\\s\\S])*?(?:client\\.py(?:(?!\\n###? )[\\s\\S])*?(?:PG_API_KEY|live_sk|키|[Kk]ey)|(?:PG_API_KEY|live_sk|키|[Kk]ey)(?:(?!\\n###? )[\\s\\S])*?client\\.py)"
---

**번호가 자리가 아니라 결함에 붙는가.** 박힌 키는 지난 회차에서 NC-1 이었고
그대로 있으므로 이번에도 NC-1 이어야 한다. 목록을 새로 1부터 매기면 이 발견이
NC-1 을 유지할 이유가 없어진다 — 두 기록을 나란히 놓고 비교할 수 없게 된다.

`### NC-1` 에서 다음 `##` · `###` 제목 전까지만 훑는다. 심판을 쓰지 않는다.

**NC-1 에 박힌 키가 있어야 한다.** 처음 판은 NC-1 이 `client.py` 만 적으면 통과해, 딴 `client.py` 문제를 NC-1 에 두고 키를 NC-5 로 옮겨도 통과했다(Codex 리뷰). 같은 NC-1 절 안에 키 흔적(`PG_API_KEY` · `live_sk` · 키)도 있어야 한다. 표본 `fail-key-moved.md`.
