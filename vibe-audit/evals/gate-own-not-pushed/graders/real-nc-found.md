---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n##)[\\s\\S])*?(?:checkout\\.py(?:(?!\\n##)[\\s\\S])*?(?:트랜잭션|[Tt]ransaction|결제|[Pp]ayment)|(?:트랜잭션|[Tt]ransaction|결제|[Pp]ayment)(?:(?!\\n##)[\\s\\S])*?checkout\\.py)"
---

대조군. `app/checkout.py` 가 열린 트랜잭션 안에서 외부 결제를 호출하는 자리가
NC 절 안에 나와야 한다.

**파일 이름만으로는 안 된다.** 같은 NC 절(다음 `##` · `###` 머리까지) 안에 결함의 흔적
(`(?:트랜잭션|[Tt]ransaction|결제|[Pp]ayment)`)이 함께 있어야 한다. 파일 이름만 보면 같은 파일의 딴 문제로 NC 를 붙이고
진짜 결함을 놓친 기록도 통과한다 — `trap-local-dev-password` · `trap-liveness-probe` 에서 짚인
모양을 나머지 대조군에도 걸었다(Codex 22차 리뷰 뒤).
