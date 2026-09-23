<!-- 무는 그레이더: trap-not-an-nc -->

## 체크 항목

| # | 항목 | 판정 | 근거 위치 |
|---|---|---|---|
| 2 | 실패가 관측되는가 | 부적합 | `app/worker.py:31` — NC-1 |

## 부적합 목록

### NC-1 · 예외를 통째로 삼킨다
- 위치: `app/worker.py:31`
- 심각도: 높음

### NC-2 · The probe is too shallow
- 위치: `k8s/deployment.yaml:18` — the liveness check never touches the database.
- 심각도: 보통

## 안 본 것
- 실제 기동 결과 — 실행 도구가 없다.
