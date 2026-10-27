<!-- 무는 그레이더: recall-found -->
## 부적합 목록

### NC-1 · 권역 칸에 그룹을 묶는 제약이 없다
- 위치: `migrations/versions/0007_shipping_zone.py:20`
- 심각도: 보통

## 관찰

### OB-1 · 되돌리기의 잣대
- `migrations/versions/0007_shipping_zone.py` 의 downgrade 는 값이 같으면 운영자가 먼저 만든 줄도 지운다. 운영 데이터가 없으니 지금은 부적합이 아니다.
