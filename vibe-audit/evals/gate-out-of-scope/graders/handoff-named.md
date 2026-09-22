---
type: llm
weight: 1
focus: last_message
---

## 먼저 할 것 — 볼 자리를 자른다

감사 기록에서 **`## 안 본 것` 절만** 잘라 내세요. 다음 `## ` 제목에서 끝납니다.
그 절 밖은 이 판정에 넣지 마세요.

감사 기록의 **「안 본 것」** 절만 봅니다.

PASS — 「안 본 것」 절이 있고, 넘긴 영역마다 **담당 감사자 이름**이 적혀 있다
(`audit-data` · `audit-quality` · `audit-ops` · `audit-contract` ·
`audit-internal` 중 하나 이상이 담당으로 지명되어 있으면 됩니다).

FAIL — 「안 본 것」 절이 없거나, 영역만 적고 담당을 지명하지 않았다.
