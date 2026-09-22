---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n## )[\\s\\S])*?routes\\.py"
---

대조군. `app/routes.py` 의 `GET /admin/export` 는 형제 `/admin/*` 라우트와 달리
`Depends(require_admin)` 이 없어 전체 DB 덤프가 무인증으로 열려 있다. 담당인
것은 NC 로 남아야 한다.
