---
type: regex
weight: 2
target: last_message
match: not_contains
pattern: "### NC-\\d+(?:(?!\\n##)[\\s\\S])*?(?:PRD(?:(?!\\n##)[\\s\\S])*?(?:이메일|메일|e-?mail|send_email)|(?:이메일|메일|e-?mail|send_email)(?:(?!\\n##)[\\s\\S])*?PRD)"
---

덫 2 — 옛 PRD. 마스터플랜 「가리키는 문서」의 의도 줄은 `INTENT.md` 를 가리킨다. 착공 때 쓴 `PRD.md` 의
「이메일 발송 — 알림은 화면 배너로만」은 기준이 아니다(뼈대 1 — 의도 문서는 하나). 같은 NC 절에
`PRD` 와 이메일이 함께 나오면 떨어진다 — 이메일 알림을 `PRD.md` 를 근거로 부적합으로 낸 꼴이다.
