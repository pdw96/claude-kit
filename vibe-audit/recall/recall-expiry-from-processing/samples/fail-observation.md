<!-- 무는 그레이더: recall-found -->
## 부적합 목록

### NC-1 · 같은 신청을 두 번 승인하면 두 번째가 제약 이름으로 500 이 된다
- 위치: `app/services/memberships.py:24`
- 심각도: 보통

## 관찰

### OB-1 · 만료일의 기준
- `app/services/memberships.py:30` 이 승인한 날에서 센다. 시드는 신청일이라 적는다 — 운영 방침을 확인할 것.
