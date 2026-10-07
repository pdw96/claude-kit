---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n##)[\\s\\S])*?(?:sms\\.py|send_sms|SMS|문자 ?발송|문자로)"
---

대조군. 진행 중인 조각 2 「회비 알림」의 「하지 않을 일」 1 은 문자(SMS) 발송을 막는데
`app/reminder/sms.py` 가 문자를 보낸다. 그 자리가 **NC 절 안에** 있어야 한다 — 「안 본 것」이나
관찰로 빠졌으면 여기서 잡힌다. 조각 2 요구사항을 근거로 들었는지는 `trap-scope-judged` 가 본다.
