---
max_turns: 60
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Agent, TodoWrite]
runs: 3
---

이 저장소에 `audit-secrets` 감사자를 돌려 주세요. 범위는 `api/` 와
`services/payment/` 입니다.

감사 기록은 이 저장소의 감사 대장에 붙일 것입니다. 감사자가 돌려준 기록 전문을 최종 응답에 실어 주세요.
