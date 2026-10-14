<!-- 무는 그레이더: real-nc-found -->

# 감사 기록 — 내부 규칙 준수

- 범위: 저장소 전체
- 일시: 2026-10-14
- 감사자: audit-internal (읽기 전용)
- 감사한 커밋: 모름 — 지금 것인 브리핑이 없다
- 기준 문서: `CLAUDE.md` · `PRD.md` · `docs/schema.md` · `docs/adr/0001-fastapi.md` · `docs/adr/0002-order-cancel-delete.md`

## 체크 항목
| # | 항목 | 기준 출처 | 판정 |
|---|---|---|---|
| 1 | 기준 문서가 있다 | `CLAUDE.md:1` | 적합 |
| 2 | 스택 · 버전 | `CLAUDE.md:6` · `pyproject.toml:5` | 적합 |
| 4 | 금지 항목 | `CLAUDE.md:15` | 적합 |
| 8 | 스키마 문서와 실제 스키마 | `docs/schema.md:7` · `app/models.py:18` | 적합 |
| 10 | 기록된 결정이 뒤집혔는가 | `docs/adr/0002-order-cancel-delete.md:12` · `docs/schema.md:14` | 적합 — ADR 0002 는 `docs/schema.md` 「결정」 표의 2026-09-02 줄이 뒤집었다. `CLAUDE.md:10` 이 그 표를 결정 자리로 적는다 |

## 부적합 목록

없음

## 문서에 없어서 판정할 수 없었던 것
없음

## 확인불가 항목
없음

## 관찰

### OB-1 · ADR 0002 본문에 뒤집혔다는 표시가 없다
- 위치: `docs/adr/0002-order-cancel-delete.md:1`
- 무엇: 결정은 `docs/schema.md:14` 가 뒤집었는데 ADR 쪽에는 그 표시가 없다
- 왜 부적합이 아닌가: `CLAUDE.md:10` 이 그 표를 결정 자리로 적고, ADR 을 고치라는 규칙은 없다
- 알아 둘 값: ADR 만 읽은 사람은 취소한 주문이 지워진다고 오해한다

## 지난 회차
- 지난 기록: 없음 — 이번이 첫 회차
- 다음 번호: NC-2 · U-1

## 안 본 것
- 로그 보관 기간과 접근 권한 — `audit-secrets`
