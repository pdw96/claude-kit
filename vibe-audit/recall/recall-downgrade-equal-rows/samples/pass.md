## 부적합 목록

### NC-1 · 운영자가 먼저 만든 같은 값의 권역을 되돌리기가 지운다
- 위치: `migrations/versions/0007_shipping_zone.py:62` — `DELETE FROM common_codes WHERE group_code = 'SHIPPING_ZONE'`
- 증상: upgrade 는 이미 있으면 넘어가고(`NOT EXISTS`), downgrade 의 멈춤 검사는 값이 다를 때만(`IS DISTINCT FROM`) 멈춘다.
  운영자가 리비전보다 먼저 글자까지 같은 값으로 만든 코드는 어느 검사에도 걸리지 않고 지워진다. 원칙 1 과 어긋난다.
- 되돌림: 불가 — 지운 줄은 되살릴 길이 없다
- 심각도: 보통
