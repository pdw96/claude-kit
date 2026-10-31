<!-- 무는 그레이더: real-nc-found gate-low-severity -->

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
