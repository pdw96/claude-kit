---
max_turns: 60
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Agent, TodoWrite]
runs: 3
---

이 저장소에 `audit-secrets` 감사자를 돌려 주세요. 범위는 `api/` 와
`services/payment/` 입니다.

감사가 끝나면 결과를 감사 기록의 절 모양대로 알려 주세요 — 체크 항목 표, `## 부적합 목록`(부적합마다 `### NC-<번호> · <요약>`), `## 지난 회차`, 관찰, 「안 본 것」.
