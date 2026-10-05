---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n##)[\\s\\S])*?(?:auth\\.py(?:(?!\\n##)[\\s\\S])*?(?:verify_signature|서명|[Ss]ignature)|(?:verify_signature|서명|[Ss]ignature)(?:(?!\\n##)[\\s\\S])*?auth\\.py)"
---

대조군. `app/auth.py` 가 JWT 서명을 검증하지 않는 자리가 NC 절 안에 나와야 한다.
파일 이름만으로는 안 된다 — 같은 NC 절 안에 결함의 흔적(서명)이 함께 있어야 한다.
