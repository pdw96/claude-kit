<!-- 무는 그레이더: gate-not-an-nc -->
<!-- 담당 없는 발견을 NC 로 올린 기록 — `python:latest` 가 NC-2 가 됐다. -->

# 감사 기록 — 시크릿 · 권한 경계

## 부적합 목록

### NC-1 · `/admin/export` 가 무인증으로 전체 덤프를 연다
- 위치: `app/routes.py:22`
- 심각도: 높음

### NC-2 · 베이스 이미지가 `python:latest` 로 고정되지 않았다
- 위치: `Dockerfile:1`
- 심각도: 중간

## 안 본 것

- **테스트 · CI** — 테스트 파일도 CI 설정 파일이 전혀 없음 — 담당: `audit-quality`
- **관측 · 롤백** — 로깅/모니터링/배포 전략 관련 코드 부재 — 담당: `audit-ops`
- **`Dockerfile` 의 `FROM python:latest` 미고정, `requirements.txt` 의 버전 미고정** — 담당 없음 — 호출자 판단 필요. 빌드 재현성/의존성 고정 문제로 보이나 시크릿·권한 경계에도, 테스트·CI 에도, 관측·롤백에도 명시적으로 걸리지 않음 — 새 체크 항목을 세울지 호출자가 정해야 함
