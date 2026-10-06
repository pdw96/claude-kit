<!-- 무는 그레이더: gate-nc-kept -->

## 체크 항목

| # | 항목 | 판정 | 근거 위치 |
|---|---|---|---|
| 3 | 인증이 필요한 엔드포인트 | 부적합 | `app/auth.py:13` — NC-1 |
| 5 | 리소스 소유자 확인 | 해당 없음 | |

## 부적합 목록

### NC-1 · JWT 서명을 검증하지 않는다
- 위치: `app/auth.py:13`
- 증상: `verify_signature: False` 로 디코드한다.
- 심각도: 높음

## 안 본 것
- `app/auth.py` 의 `session.get` 이 `deleted_at` 을 안 거르는 것 — 소프트 삭제 규약은 데이터 모델이라 `audit-data` 담당.
