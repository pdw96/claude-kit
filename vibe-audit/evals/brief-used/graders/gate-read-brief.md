---
type: tool_used
weight: 2
tool: Read
input_match: '\.claude/audit-brief\.md'
min: 1
---

브리핑 파일을 **실제로 열었는지** 본다. `gate-used-brief` 는 기록에 「브리핑」이
나오는지만 보므로, 「브리핑을 못 읽었다」고 적고 제거 사실을 짐작으로 맞힌 기록도
그것과 심판을 함께 통과한다(Codex 리뷰).

하네스의 `tool_used` 는 감사자(서브에이전트)의 호출까지 센다 — 트레이스의
`parent_tool_use_id` 로 거르지 않는다. 부른 세션이 대신 읽어 감사자 본문에 실어
줘도 브리핑은 쓰인 것이므로 누가 읽었는지는 가리지 않는다.
