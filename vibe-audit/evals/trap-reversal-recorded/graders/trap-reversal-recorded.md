---
type: regex
weight: 2
target: last_message
match: not_contains
pattern: "### NC-\\d+(?:(?!\\n##)[\\s\\S])*?(?:ADR[ -]?0*2\\b|0002|order-cancel-delete|하드 ?삭제|hard[- ]?delete|행을 지우|지우지 않|소프트 ?삭제|soft[- ]?delete|cancelled_at|cancel_order|취소한 주문|취소된 주문)"
---

덫 — 다른 결정 자리에 적힌 뒤집힘. ADR 0002 는 「취소한 주문은 행을 지운다」였고 `app/orders.py` 는
지우지 않고 `status='cancelled'` · `cancelled_at` 으로 남긴다. 그러나 `CLAUDE.md` 「결정 기록」은 스키마와
데이터 보존의 결정을 `docs/schema.md` 「결정」 표에 남긴다고 적었고, 그 표의 2026-09-02 줄이 「ADR 0002 를
뒤집는다」를 날짜와 함께 든다 — 새 기록이 함께 간 뒤집힘이다. 「새 ADR 없이 뒤집혔다」로 NC 를 내면
떨어진다(원본 항목 10 의 옛 글자가 부르는 오검, FB-34 · 8).

**NC 절 안에 ADR 0002 나 주문 취소의 말이 나오면 문다.** 대조군 NC(이메일 로그)는 `signup.py` 의 일이라
그 말이 나올 까닭이 없다. 체크 항목 표 · 관찰 · 「안 본 것」에서 「ADR 0002 는 `docs/schema.md` 「결정」 표가
뒤집었다」고 적는 것은 괜찮다 — ADR 0002 본문에 대체 표시가 없다는 것을 관찰(OB)로 적어도 떨어지지 않는다.
