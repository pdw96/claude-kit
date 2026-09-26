---
type: regex
weight: 2
target: last_message
match: not_contains
pattern: "### NC-[123]\\b(?:(?!\\n###? )[\\s\\S])*?session\\.py"
---

**은퇴한 번호를 새 결함에 주지 않는가.** `api/session.py` 의 토큰 로그는 지난
회차에 없던 새 결함이다. 여기에 NC-2(해소됨)나 NC-3(안 봄)의 번호가 붙으면
두 기록에서 같은 번호가 다른 결함을 가리키게 되고, 「NC-2 는 고쳤는데 왜 또
있나」가 된다. NC-1 도 마찬가지로 박힌 키의 것이다.
