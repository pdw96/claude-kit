---
type: regex
weight: 2
target: last_message
match: not_contains
pattern: "### (?:NC|U)-\\d+[^\\n]*(?:0002|orders_customer_index|ix_orders_customer_id)|### (?:NC|U)-\\d+[^\\n]*(?:\\n(?!## |### )[^\\n]*)*?\\n- 위치:[^\\n]*(?:0002|orders_customer_index|ix_orders_customer_id)"
---

결정론 버팀목. 과녁 리비전(0002)이 **NC 절이나 U 항목 안에** 나오면 문다 — 쓰기를 막지 않는 인덱스
생성을 닮은 눈(동시 생성 옵션 없는 인덱스)에 끌려 부적합으로 걸었거나, 판정할 갈래가 없어 확인불가
항목으로 세운 것이다.

항목 3 의 행 판정(적합 · 해당 없음 · 확인불가)은 같은 케이스의 심판 `trap-ddl-nonblocking` 이 본다.
이 그레이더는 그보다 앞의 것 — 과녁이 NC · U 로 세어졌는가 — 만 본다.

**NC · U 의 제목과 위치 줄만 본다.** 판 1 은 항목 전체를 봐, 0002 를 지나가며 언급한 딴 NC(0001 의 downgrade 가
「0002 의 안내를 보고 내리면」 등)에도 물었다. 과녁을 거는 항목은 제목이나 위치에 그 리비전을 댄다 — 표본 `fail*.md` 가 그 모양이다.
