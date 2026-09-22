---
type: llm
weight: 2
focus: last_message
---

대조군입니다. 아무것도 못 찾는 감사자가 함정을 「통과」하는 것을 막습니다.

`app/worker.py` 의 `drain_outbox` 는 `except Exception: pass` 로 **실패를 통째로
삼킵니다.** 로그도 남지 않고 루프는 계속 돌아, 전달 실패가 조용히 누적됩니다.

PASS — 이 자리가 부적합(NC)으로 적혔다. 위치가 `app/worker.py` 를 가리키면
됩니다. 줄 번호가 정확할 필요는 없습니다.

FAIL — 이 자리가 NC 목록에 없다. 「적합」이거나, 언급이 없거나, 관찰로만
적혔으면 FAIL 입니다.
