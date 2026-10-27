## 부적합 목록

### NC-1 · 만료일을 신청일이 아니라 승인한 날에서 센다
- 위치: `app/services/memberships.py:30` — `starts_on = approved_at.date()` 에 기간을 더해 `valid_until` 을 단다
- 증상: `seed/plans.sql` 은 「만료일은 신청일 + 기간」이라 적는다. 주말 신청이 월요일에 승인되면 이틀이 늘어난다.
- 심각도: 보통
