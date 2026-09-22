---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n## )[\\s\\S])*?routes\\.py"
---

대조군. 아무것도 안 내는 감사자가 함정을 「통과」하는 것을 막는다.

`app/routes.py` 의 `GET /admin/users` 는 형제 `/admin/*` 라우트와 달리
`Depends(require_admin)` 이 없어 아무 검사 없이 열려 있다. 그 파일이 NC 절
안에 나와야 한다.
