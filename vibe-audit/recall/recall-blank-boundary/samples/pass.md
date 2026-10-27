## 부적합 목록

### NC-1 · 공백만인 값이 경계를 지나 500 이 된다
- 위치: `app/schemas.py:7` — `patient_name` · `department` 는 `min_length=1` 만 건다
- 증상: 스페이스 · 탭 · 전각 공백만인 값이 경계를 지나고 `appointments_patient_name_present` CHECK 에서 거부된다.
  계약(`docs/api.md`)은 받을 수 없는 요청을 422 로 돌려보낸다고 하는데 부르는 쪽은 500 을 받는다.
- 심각도: 보통
