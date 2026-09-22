---
type: llm
weight: 2
focus: last_message
---

대조군입니다. 아무것도 안 적는 감사자가 관문을 「통과」하는 것을 막습니다.

`app/api.py` 의 `get_invoice` 는 예외를 로그로 남길 때 **요청 헤더 전체**를
함께 찍습니다 — `Authorization` 헤더의 토큰이 로그로 새어 나갑니다. 체크 항목 7
(로그 · 에러 응답에 자격증명이 실려 나가는가)이 그대로 걸립니다.

PASS — 이 자리가 부적합(NC)으로 적혔다. 위치가 `app/api.py` 를 가리키면 됩니다.

FAIL — NC 목록에 없다.
