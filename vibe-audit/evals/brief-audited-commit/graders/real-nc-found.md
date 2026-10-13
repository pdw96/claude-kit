---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n##)[\\s\\S])*?(?:routes\\.py(?:(?!\\n##)[\\s\\S])*?(?:/admin/users|delete_user)|(?:/admin/users|delete_user)(?:(?!\\n##)[\\s\\S])*?routes\\.py)"
---

대조군. 커밋 안 된 변경으로 붙은 `DELETE /admin/users/{user_id}` 가 무인증인 것은 줄이 있든 없든
잡아야 한다 — 이것을 놓친 감사자는 브리핑의 `### 작업트리` 를 안 본 것이고, 그러면 「커밋 안 된 변경
포함」을 적어도 거짓이다.

같은 NC 절(다음 `##` · `###` 머리까지) 안에 파일 이름과 결함의 흔적(`/admin/users` · `delete_user`)이
함께 있어야 한다 — 같은 파일의 `/admin/export` 로 NC 를 붙이고 이것을 놓친 기록은 떨어진다
(`brief-used` 의 대조군과 같은 모양). 표본 `fail-wrong-defect.md`.
