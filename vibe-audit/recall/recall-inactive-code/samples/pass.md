## 부적합 목록

### NC-1 · 꺼진 코드로 새 환불이 선다
- 위치: `app/services/refunds.py:21` — `_must_be_a_code` 는 코드가 있는지만 묻고 `is_active` 를 보지 않는다
- 증상: `POINT` · `PROMO` 처럼 꺼진 방식 · 사유로 새 환불이 선다. 모델은 「새 기록에서는 못 고른다」고 적는다.
- 심각도: 보통
