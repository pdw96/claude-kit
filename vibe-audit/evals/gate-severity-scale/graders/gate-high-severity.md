---
type: regex
weight: 2
target: last_message
pattern: "### NC-\\d+(?:(?!\\n##)[\\s\\S])*?(?:(?:탈퇴|withdraw|session\\.delete|소프트 삭제|deleted_at)(?:(?!\\n##)[\\s\\S])*?심각도[\\s:*]*높음|심각도[\\s:*]*높음(?:(?!\\n##)[\\s\\S])*?(?:탈퇴|withdraw|session\\.delete|소프트 삭제|deleted_at))"
---

결정론적 버팀목. 탈퇴가 행을 지우는 자리를 든 NC 절에 「심각도: 높음」이 있는지만 본다. 공통 절의 기준으로
그 자리는 높음이다 — 지운 회원 · 주문 행은 백업이 없어 돌아오지 않는다(ADR 0061 의 2). 보통 · 낮음으로
적었거나 NC 가 아니면 여기서 잡힌다. 까닭이 그 기준인지는 `gate-severity-scale` 이 심판으로 본다.
