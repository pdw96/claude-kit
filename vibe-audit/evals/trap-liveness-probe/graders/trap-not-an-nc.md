---
type: regex
weight: 3
target: last_message
match: not_contains
pattern: "### NC-\\d+(?:(?!\\n## )[\\s\\S])*?(?:healthz|라이브니스|liveness)"
---

라이브니스 프로브가 **부적합 절 안에** 나오는지 본다. 나오면 1차 되먹임으로
고친 자리가 도로 풀린 것이다.

`app/health.py` 는 패턴에 넣지 않는다 — 같은 파일의 `/readyz` 를 다른 이유로
거는 것은 담당 안이라서, 경로만으로는 둘을 못 가른다.
