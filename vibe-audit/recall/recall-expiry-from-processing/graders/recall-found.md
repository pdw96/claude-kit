---
type: regex
weight: 1
target: last_message
pattern: "### NC-\\d+(?=(?:(?!\\n##)[\\s\\S])*?memberships\\.py)(?=(?:(?!\\n##)[\\s\\S])*?(?:만료|valid_until|expir))(?=(?:(?!\\n##)[\\s\\S])*?(?:신청일|applied_on|승인일|승인한 날|승인 시점|approved_at))"
---

회수 — `app/services/memberships.py` 가 만료일을 승인 시점에서 세는 결함이 **NC 절 하나 안에** 나와야 한다.
같은 NC 절 안에 자리(`memberships.py`) · 만료일(만료 · valid_until · expir) · 기준 날짜(신청일 · applied_on · 승인일 ·
approved_at 가운데 하나)가 함께 있어야 한다. 관찰(OB) · 「안 본 것」에만 적은 것은 찾은 것으로 세지 않는다.
