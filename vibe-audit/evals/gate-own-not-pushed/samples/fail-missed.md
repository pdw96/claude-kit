<!-- 무는 그레이더: real-nc-found -->
<!-- 진짜 결함을 못 찾은 기록 — 그 NC 절이 통째로 없다. 대조군(real-nc-found)이 물어야 한다. -->

## 체크 항목

| # | 항목 | 판정 | 근거 위치 |
|---|---|---|---|
| 4 | 외부 호출과 트랜잭션 경계 | 부적합 | `app/checkout.py:21` — NC-1 |
| 6 | 마이그레이션의 되돌림 | 부적합 | `migrations/0011_tighten_orders.py:9` — NC-2 |

## 부적합 목록

### NC-2 · `0011_tighten_orders` 가 되돌릴 수 없다
- 위치: `migrations/0011_tighten_orders.py:9`
- 증상: NOT NULL 을 거는데 기존 NULL 행을 채우는 단계가 없고 `downgrade` 가 비어 있다.
- 심각도: **확인불가** — 운영에 NULL 행이 얼마나 있는지는 이 감사가 볼 수 없다. `audit-ops` 가 운영 데이터를 주면 정해진다.
- 담당: 고칠 자리가 마이그레이션 코드이므로 이 감사자. 넘어가는 것은 심각도 하나다.
- 제안: 채우는 단계를 앞에 넣고 `downgrade` 를 쓴다.

## 안 본 것
- `docs/schema.md` 의 문서 대비 준수 — `audit-internal` 담당.
