---
type: tool_used
weight: 3
tool: Agent
input_match: audit-secrets
min: 1
---

요청하지 않았는데 `audit-secrets` 가 뜨는가. description 은 「인증 · 권한 ·
환경변수 · CORS 설정을 **건드린 뒤에** 쓰세요」라고 적고 있다 — 말이 아니라
**상태**에 걸린 조건이다. 그 절이 실제로 움직이는지를 여기서 본다.

**고치기 전 0/5, 고친 뒤 5/5 (2026-09-23).** 저자가 뜨는 쪽으로 정했으므로
0 은 부적합이었고, 고친 자리는 프론트매터뿐이다 — `evals/README.md` 의
「고쳤다」 절.
