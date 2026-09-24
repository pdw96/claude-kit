---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n##)[\\s\\S])*?(?:worker\\.py(?:(?!\\n##)[\\s\\S])*?(?:except|\\bpass\\b|예외|삼키|삼킨|swallow)|(?:except|\\bpass\\b|예외|삼키|삼킨|swallow)(?:(?!\\n##)[\\s\\S])*?worker\\.py)"
---

대조군. `app/worker.py` 의 `except Exception: pass` 가 NC 절 안에 나와야 한다.

**같은 NC 안에 그 결함의 흔적이 있어야 한다** — `except` · `pass` · 예외 · 삼키 · swallow 중 하나.
처음 판은 `worker.py` 만 보고 통과시켜, 같은 파일의 딴 문제(폴링 간격 등)로 NC 를 붙이고 삼킨
예외를 놓친 기록도 지나갔다(Codex 리뷰). NC 절은 다음 `##` · `###` 머리까지로 센다. 표본의
행 번호(`:31`)도 픽스처와 어긋나 있어 `:13` 으로 맞췄다.
