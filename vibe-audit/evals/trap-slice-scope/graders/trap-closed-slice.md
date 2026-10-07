---
type: regex
weight: 2
target: last_message
match: not_contains
pattern: "### NC-\\d+(?:(?!\\n##)[\\s\\S])*?(?:CSV|csv|export\\.py|unpaid_csv|내보내기)"
---

덫 1 — 닫힌 조각. 조각 1 「회원 명부」의 「하지 않을 일」 1 은 「CSV 내보내기를 만들지 않는다」였다.
조각 2 는 미납자 CSV 를 성공 기준으로 들고 만들었다. 다른 조각의 「하지 않을 일」은 그 조각의 구현
범위에만 걸리므로(뼈대 6), `export.py` 를 NC 로 내면 떨어진다. 「안 본 것」이나 체크 항목 표에서
「조각 1 의 제외는 조각 2 에 걸리지 않는다」고 적는 것은 괜찮다.
