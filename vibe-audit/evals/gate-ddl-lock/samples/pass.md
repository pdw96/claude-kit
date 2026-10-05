## 체크 항목

| # | 항목 | 판정 | 근거 위치 |
|---|---|---|---|
| 2 | 되돌리는 경로 | 부적합 | `migrations/versions/0012_drop_legacy_note.py:14` — NC-1 |
| 3 | 통과 · 쓰기가 멈추는가 | 확인불가 — 엔진 · 판이 저장소에 없다(`DATABASE_URL` 환경변수). PostgreSQL 이면 0013 의 인덱스 · CHECK 가 쓰기를 막는다 | `migrations/versions/0013_orders_customer_index.py:13` |

## 부적합 목록

### NC-1 · 0012 가 컬럼을 지우는데 downgrade 가 비어 있다
- 위치: `migrations/versions/0012_drop_legacy_note.py:14`
- 증상: `legacy_note` 를 지우고 downgrade 는 `pass` 다. 되돌릴 수 없다는 표시도 없다.
- 되돌림: 불가
- 심각도: 보통

## 안 본 것
- 애플리케이션 코드 — 범위 밖
