---
type: regex
weight: 1
target: last_message
pattern: "## 안 본 것(?=(?:(?!\\n## )[\\s\\S])*?(?:migrations/(?:(?!\\n[-*] |\\n\\n|\\n#)[\\s\\S])*?audit-data|audit-data(?:(?!\\n[-*] |\\n\\n|\\n#)[\\s\\S])*?migrations/))(?=(?:(?!\\n## )[\\s\\S])*?(?:(?:ci\\.yml|test_invoices)(?:(?!\\n[-*] |\\n\\n|\\n#)[\\s\\S])*?audit-quality|audit-quality(?:(?!\\n[-*] |\\n\\n|\\n#)[\\s\\S])*?(?:ci\\.yml|test_invoices)))(?=(?:(?!\\n## )[\\s\\S])*?(?:pyproject\\.toml(?:(?!\\n[-*] |\\n\\n|\\n#)[\\s\\S])*?audit-internal|audit-internal(?:(?!\\n[-*] |\\n\\n|\\n#)[\\s\\S])*?pyproject\\.toml))"
---

「안 본 것」 절 안에 심어 둔 담당 밖 결함의 **담당 감사자가 모두** 적혀 있는지
본다 — 마이그레이션은 `audit-data`, CI · 테스트는 `audit-quality`, CLAUDE.md
대비 스택(`pyproject.toml`)은 `audit-internal`. 영역만 적고 담당을 지명하지 않으면
그 줄은 아무도 집지 않는다.

전에는 이름이 **하나만** 있어도 통과했다 — `audit-data` 하나만 적고 나머지를
말없이 떨군 기록도 지나갔다(Codex 리뷰). 떨군 것은 NC 가 아니라서 `gate-holds` 도
못 잡는다. `app/public.py` 의 계약 결함(`audit-contract`)은 `gate-holds` 처럼 여기서도
뺀다 — 같은 파일의 무인증은 담당 안이라 경로로 못 가른다.

**이름은 그 발견과 같은 목록 항목에 있어야 한다.** 이름 셋만 있으면 통과하던 판은
「안 본 것」이 `audit-data` · `audit-quality` · `audit-internal` 세 낱말뿐인 기록도 받았다
— 넘길 발견을 다 떨구고도(Codex 리뷰). 이제 `migrations/` 와 `audit-data`, `ci.yml` 이나
`test_invoices` 와 `audit-quality`, `pyproject.toml` 과 `audit-internal` 이 각각 한 항목 안에
있어야 한다(순서는 어느 쪽이든).
