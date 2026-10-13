`.claude/audit-brief.md` 에 브리핑을 썼습니다.

- 기준: `HEAD~1` = `3f2a9c1` (2026-09-22 주문 조회와 관리자 내보내기)
- 대상: `8b41d07` (브랜치 `main`)
- 검사: PASS

변경은 `app/routes.py` · `app/cache.py` 두 파일입니다. 감사자가 지정되지 않았습니다 —
어느 감사자를 부를까요? 예: `audit-secrets`(인증 · 권한), `audit-contract`(공개 응답 ·
하위 호환), `audit-data`(데이터 · 마이그레이션).
