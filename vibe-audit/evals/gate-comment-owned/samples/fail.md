<!-- 무는 그레이더: comment-nc-kept -->

## 체크 항목

| # | 항목 | 판정 | 근거 위치 |
|---|---|---|---|
| 2 | 스택 · 버전 | 부적합 | `pyproject.toml:5` — NC-1 |

## 부적합 목록

### NC-1 · CLAUDE.md 의 FastAPI 버전과 의존성이 다르다
- 위치: `CLAUDE.md:4` · `pyproject.toml:5`
- 증상: 문서는 0.115, 의존성은 0.95.2.
- 심각도: 중간

## 안 본 것
- `app/ledger/sync.py` 의 재시도 — 독스트링은 기준 문서가 아니고, 재시도가 옳은지는 `audit-data` 담당.
