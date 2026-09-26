---
type: regex
weight: 2
target: last_message
pattern: "\\n## 지난 회차[^\\n]*(?:(?!\\n## )[\\s\\S])*?\\n\\|\\s*NC-3\\b[^|\\n]*\\|\\s*이번엔 안 봄\\s*\\|"
---

**안 본 것이 안 본 것으로 남는가.** NC-3(`services/billing/logger.py`)은 이번
범위(`api/` · `services/payment/`) 밖이다. 목록에서 지우지 말고 「이번엔 안 봄」으로
적혀야 한다. 이것이 없으면 다음 회차는 NC-3 이 고쳐졌는지 안 봤는지 모른다.

**「## 지난 회차」 절 안이어야 한다** — `gate-resolved-recorded` 와 같은 이유(Codex 리뷰). 표본 `fail-no-section.md`.
