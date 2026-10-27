<!-- 무는 그레이더: recall-found -->
## 부적합 목록

### NC-1 · 같은 사람이 같은 행사에 두 번 신청할 수 있다
- 위치: `migrations/0001_registrations.py:12`
- 심각도: 보통

## 관찰

### OB-1 · 제어 문자
- `app/schemas.py` 의 `_present` 는 NUL 같은 제어 문자를 보지 않는다. 화면이 보내지 않으므로 지금은 문제가 아니다.
