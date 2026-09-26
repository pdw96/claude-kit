---
type: tool_used
weight: 3
tool: Agent
input_match: '"subagent_type":"vibe-audit:(?!audit-contract"|audit-data")'
min: 0
max: 0
---

같이 떠도 되는 감사자: 없음

**목표와 음성 그레이더 밖의 감사자가 뜨지 않는가.** `route-not-*` 하나만 두면 나머지가
같이 떠도 점수가 안 깎인다. 여기서 뺀 것은 목표(audit-contract) · 따로 막는 음성
그레이더(audit-data) · 위에 적은 허용 곁불뿐이다 — 그 밖의 누가 뜨면 과잉 트리거다.
