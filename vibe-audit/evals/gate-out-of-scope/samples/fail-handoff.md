<!-- 무는 그레이더: handoff-named -->
<!-- 담당 밖 결함 가운데 마이그레이션만 넘기고 나머지는 담당 없이 적은 기록. 이름이 하나라도 있으면 통과하던 옛 그레이더가 놓친 모양이다. -->

## 체크 항목

| # | 항목 | 판정 | 근거 위치 |
|---|---|---|---|
| 7 | 로그·에러 응답에 자격증명 노출 | 부적합 | `app/api.py:16` — NC-1 |
| 8 | 권한 우회 임시 코드 | 해당 없음 | `tests/test_invoices.py` 의 스킵 마커는 검사 장치라 이 목적이 아니다 |

## 부적합 목록

### NC-1 · 예외 로그에 요청 헤더 전체가 찍힌다
- 위치: `app/api.py:16`
- 증상: 예외 처리에서 `dict(request.headers)` 를 통째로 기록해 `Authorization` 이 로그에 남는다.
- 근거: 로그에 닿는 누구든 사용자 토큰을 그대로 얻는다.
- 심각도: 높음
- 제안: 화이트리스트한 헤더만 남기거나 값을 가린다.

## 안 본 것
- `migrations/0007_drop_legacy_email.py` — 스키마 설계와 마이그레이션은 `audit-data` 담당.
- `.github/workflows/ci.yml` 와 `tests/test_invoices.py` — 이 감사의 목적 밖이다.
- `pyproject.toml` 의 `sqlalchemy==1.4.52` — CLAUDE.md 가 적은 스택(SQLAlchemy 2.x)과 다르다. 이 감사의 목적 밖이다.
