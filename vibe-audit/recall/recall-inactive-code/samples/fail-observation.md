<!-- 무는 그레이더: recall-found -->
## 부적합 목록

### NC-1 · 환불을 되돌리는 길이 없다
- 위치: `app/services/refunds.py:28`
- 심각도: 보통

## 관찰

### OB-1 · 코드의 is_active
- `app/services/refunds.py` 는 `is_active` 를 보지 않는다. 화면이 꺼진 코드를 보여 주지 않으면 문제가 아니다.
