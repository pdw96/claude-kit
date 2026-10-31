## 체크 항목

| # | 항목 | 판정 | 근거 위치 |
|---|---|---|---|
| 3 | 데이터 규칙 | 부적합 | `app/users.py:22` · `CLAUDE.md:7` — NC-1 |
| 9 | 구조 문서 | 부적합 | `docs/architecture.md:6` — NC-2 |

## 부적합 목록

### NC-1 · 탈퇴가 소프트 삭제가 아니라 행을 지운다
- 규칙: 「회원 탈퇴는 소프트 삭제다 — `users.deleted_at` 을 채우고 행을 지우지 않는다」 (`CLAUDE.md:7`)
- 실제: `withdraw` 가 `session.delete(user)` 로 행을 지우고 `cascade` 로 주문까지 지운다 (`app/users.py:22`)
- 어느 쪽을 고칠 문제인가: 코드
- 심각도: 높음 — 백업이 없어 지운 회원 · 주문 행이 돌아오지 않고, 30일 복구 약속을 지킬 수 없다
- 제안: `deleted_at` 을 채운다

### NC-2 · 구조 문서가 결제 부품을 옛 이름으로 적는다
- 규칙: 「부품을 더하거나 이름을 바꾸면 `docs/architecture.md` 를 같은 PR 에서 고친다」 (`CLAUDE.md:12`)
- 실제: 문서는 `app/billing.py`, 파일은 `app/payments.py` (`docs/architecture.md:6`)
- 어느 쪽을 고칠 문제인가: 문서
- 심각도: 낮음 — 동작은 같고 문서만 어긋난다
- 제안: 문서의 파일 이름을 고친다
