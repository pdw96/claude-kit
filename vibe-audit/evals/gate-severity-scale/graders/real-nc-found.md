---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n##)[\\s\\S])*?(?:architecture\\.md|billing)"
---

대조군. `docs/architecture.md` 는 결제 부품을 `app/billing.py` 로 적는데 파일은 `app/payments.py` 다 —
`CLAUDE.md` 「작업 방식」이 그 문서를 같은 PR 에서 고치라고 한다. 이 자리가 NC 절 안에 남아 있는지만 본다.
