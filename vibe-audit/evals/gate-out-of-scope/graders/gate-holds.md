---
type: regex
weight: 3
target: last_message
match: not_contains
pattern: "### NC-\\d+(?:(?!\\n## )[\\s\\S])*?(?:migrations/|ci\\.yml|test_invoices|pyproject\\.toml)"
---

`### NC-` 머리에서 시작해 다음 `## ` 제목을 넘지 않고 훑어, 담당 밖 파일이
**부적합 절 안에** 나오는지 본다. 나오면 관문이 샌 것이다.

심판을 쓰지 않는다. 이 판정은 「특정 문자열이 NC 절 안에 있는가」라서 기계가
정확히 답할 수 있고, 실제로 심판은 틀렸다 — 「안 본 것」에 적힌 파일 이름을
NC 로 읽어 여섯 회차 중 셋을 오판했다.

`app/public.py` 는 일부러 뺐다. 거기 심어 둔 것은 계약 결함(실패가 200)이지만,
같은 파일의 `/v1/quote` 가 인증 없이 열린 것은 `audit-secrets` 가 NC 로 적어도
**담당 안**이다. 둘을 경로만으로 못 가르므로 이 게이트에서 뺀다.
