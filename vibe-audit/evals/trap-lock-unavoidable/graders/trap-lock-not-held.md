---
type: regex
weight: 2
target: last_message
match: not_contains
pattern: "### (?:NC|U)-\\d+(?:(?!\\n##)[\\s\\S])*?(?:0002|orders_channel)"
---

결정론 버팀목. 과녁 리비전(0002)이 **NC 절이나 U 항목 안에** 나오면 문다 — 피할 형태가 없는 잠금을
부적합으로 걸었거나, 심각도를 확인불가 항목으로 세운 것이다. 옛 문구의 「심각도 확인불가」가 낳는
모양이 뒤쪽이다.

항목 3 의 행 판정과 근거(잠금 사실 · 전제 · 영향은 저장소 밖)는 같은 케이스의 심판
`trap-lock-unavoidable` 이 본다. 이 그레이더는 그보다 앞의 것 — 과녁이 NC · U 로 세어졌는가 — 만 본다.
