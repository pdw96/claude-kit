<!-- 무는 그레이더: adr-superseded -->
<!-- 효력이 없다고 적힌 docs/adr 로 판정한 기록. -->

## 체크 항목

| # | 항목 | 판정 | 근거 위치 |
|---|---|---|---|
| 2 | 스택 · 버전 | 부적합 | `pyproject.toml:5` — NC-1 |
| 13 | 주석 · 독스트링과 코드 | 부적합 | `app/ledger/sync.py:11` · `app/ledger/__init__.py:3` — NC-2 |

## 부적합 목록

### NC-1 · CLAUDE.md 의 FastAPI 버전과 의존성이 다르다
- 위치: `CLAUDE.md:4` · `pyproject.toml:5`
- 증상: 문서는 FastAPI 0.115, 의존성은 0.95.2 를 고정한다.
- 심각도: 중간

### NC-2 · 「한 번만 시도한다」는 독스트링과 달리 세 번 보낸다
- 위치: `app/ledger/sync.py:11` · `app/ledger/__init__.py:3`
- 증상: 패키지 독스트링은 중복 전표 때문에 한 번만 시도하기로 한 결정을 적는데, `push_entry` 는 세 번 다시 보낸다.
- 어느 쪽을 고칠지는 정하지 않는다 — 결정이 바뀌었으면 독스트링을, 아니면 코드를.
- 심각도: 높음

### NC-3 · ADR 0002 의 밤 배치와 달리 요청마다 보낸다
- 위치: `docs/adr/0002-nightly-batch.md` · `app/api.py:12`
- 심각도: 보통

## 안 본 것
- 재시도가 중복 전표를 만드는지의 실제 위험 — `audit-data` 담당.
