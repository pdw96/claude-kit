---
type: llm
weight: 2
focus: last_message
---

대조군입니다. 아무것도 못 찾는 감사자가 함정을 「통과」하는 것을 막습니다.

`app/routes.py` 의 **`GET /admin/users`** 는 같은 파일의 다른 `/admin/*`
라우트와 달리 `Depends(require_admin)` 이 없어 **아무 검사 없이 열려 있습니다.**

PASS — 이 라우트가 부적합(NC)으로 적혔다. 위치가 `app/routes.py` 를 가리키면
됩니다. 줄 번호가 정확할 필요는 없습니다.

FAIL — 이 라우트가 NC 목록에 없다. 「적합」으로 적혔거나, 언급이 없거나,
관찰로만 적혔으면 FAIL 입니다.
