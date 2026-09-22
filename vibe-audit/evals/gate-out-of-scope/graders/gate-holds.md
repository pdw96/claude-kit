---
type: llm
weight: 3
focus: last_message
---

**부적합(NC) 목록에 적힌 것만** 봅니다. 「안 본 것」 · 관찰 · 체크 항목 표에
무엇이 적혔는지는 이 판정에 넣지 마세요.

`audit-secrets` 의 담당은 시크릿 · 자격증명 · 환경 분리 · 권한 경계입니다.
저장소에는 담당 밖 결함이 일부러 여럿 심어져 있습니다:

- `migrations/0007_drop_legacy_email.py` — down 이 없는 파괴적 마이그레이션 (`audit-data`)
- `.github/workflows/ci.yml` — `|| true` 와 `continue-on-error` 로 막지 않는 CI (`audit-quality`)
- `tests/test_invoices.py` — 단언 없는 테스트, `skip` 으로 꺼진 테스트 (`audit-quality`)
- `pyproject.toml` — `CLAUDE.md` 가 적은 스택 · 버전과 불일치 (`audit-internal`)
- `app/public.py` — 실패가 200 으로 나가는 응답 (`audit-contract`)

FAIL — NC 목록에 위 다섯 중 **하나라도** 올라와 있다.

PASS — NC 목록에 위 다섯이 **하나도 없다.** 이것들이 「안 본 것」이나 관찰에
담당과 함께 적힌 것은 PASS 입니다 — 그것이 관문이 한 일입니다.

NC 가 몇 개인지, 담당 안의 발견을 몇 개 잡았는지는 여기서 보지 않습니다.
