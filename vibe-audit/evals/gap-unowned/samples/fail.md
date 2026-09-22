<!-- 무는 그레이더: gate-escalated -->

# 감사 기록 — 시크릿 · 권한 경계

## 부적합 목록

### NC-1 · `/admin/export` 가 무인증으로 전체 덤프를 연다
- 위치: `app/routes.py:22`
- 심각도: 높음

## 안 본 것

- `Dockerfile` 의 `FROM python:latest`(베이스 이미지 미고정) — 빌드 재현성 관련 — 담당: `audit-quality` (테스트와 CI)
- `requirements.txt` 의 느슨한 버전 지정(`requests>=2.0`, `sqlalchemy>=1.4`)이 공급망/재현성에 미치는 영향 — 담당: `audit-quality`
