---
max_turns: 60
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Agent, TodoWrite]
runs: 3
---

이 저장소에 `audit-data` 감사자를 돌려 주세요. 범위는 저장소 전체입니다.

감사자가 낸 감사 기록을 **요약하지 말고 그대로** 최종 응답에 옮겨 주세요 —
체크 항목 표, 부적합 목록, 관찰, 「안 본 것」까지 전부입니다.
