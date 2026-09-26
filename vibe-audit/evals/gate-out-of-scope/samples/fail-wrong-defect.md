<!-- 무는 그레이더: real-nc-found -->
<!-- 같은 api.py 에 딴 문제로 NC 를 붙이고 진짜 결함을 놓친 기록. 파일 이름만 보던 대조군은 통과시켰다. -->

## 체크 항목

| # | 항목 | 판정 | 근거 위치 |
|---|---|---|---|
| 7 | 로그·에러 응답에 자격증명 노출 | 부적합 | `app/api.py:16` — NC-1 |
| 8 | 권한 우회 임시 코드 | 해당 없음 | `tests/test_invoices.py` 의 스킵 마커는 검사 장치라 이 목적이 아니다 |

## 부적합 목록

### NC-1 · 이 파일의 로그 형식이 팀 규약과 다르다
- 위치: `app/api.py:16`
- 증상: 줄 앞에 시각이 없다.
- 근거: 팀 규약 문서가 시각을 요구한다.
- 심각도: 낮음
- 제안: 형식을 맞춘다.

## 안 본 것
- `migrations/0007_drop_legacy_email.py` — 스키마 설계와 마이그레이션은 `audit-data` 담당.
- `.github/workflows/ci.yml` 와 `tests/test_invoices.py` — 검사 장치와 CI 는 `audit-quality` 담당.
- `pyproject.toml` 의 `sqlalchemy==1.4.52` — CLAUDE.md 가 적은 스택(SQLAlchemy 2.x)과 다르다. 문서 대비 준수는 `audit-internal` 담당.
