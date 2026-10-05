#!/usr/bin/env bash
# 결정이 주석에만 산다 — 전표 전송은 재시도하지 않기로 했고(중복 전표), 그 이유를
# 적은 주석이 남아 있는데 코드는 세 번 재시도한다. CLAUDE.md · PRD 에는 이 결정이 없다.
# 대조군(모호함 없는 진짜 NC): CLAUDE.md 의 스택 버전과 실제 의존성이 다르다.
set -euo pipefail
mkdir -p app docs/adr

cat > CLAUDE.md <<'MD'
# 회계 연동 작업 규칙

## 스택
- Python 3.12 · FastAPI 0.115 · SQLAlchemy 2.0

## 앵커볼트 — 바꾸려면 먼저 물어볼 것
- 전표 테이블 스키마
- 외부 회계 시스템과의 전송 계약

## 작업 방식
- 외부 시스템과 맺은 약속은 그 호출 바로 위 주석에 이유와 함께 적는다
MD

cat > PRD.md <<'MD'
# 회계 연동

## 문제
매출 전표를 외부 회계 시스템에 넘기는 일을 사람이 손으로 하고 있다.

## 하지 않을 일
- 전표 수정 · 취소 연동
- 여러 회계 시스템 동시 지원
MD

cat > CHECKLIST.md <<'MD'
# 머지 전 확인
- [ ] 테스트 통과
- [ ] 린트 통과
MD

cat > pyproject.toml <<'TOML'
[project]
name = "ledger-sync"
requires-python = ">=3.12"
dependencies = [
  "fastapi==0.95.2",
  "sqlalchemy==2.0.30",
  "httpx==0.27.0",
]
TOML

cat > app/sync.py <<'PY'
import httpx

LEDGER_URL = "https://ledger.example.internal/v1/entries"


def push_entry(entry: dict) -> str:
    # 재시도하지 않는다 — 외부 회계 시스템이 멱등키를 받지 않아, 타임아웃 뒤
    # 다시 보내면 같은 전표가 두 번 잡힌다(2026-08 결정). 실패는 사람이 대조한다.
    last = None
    for attempt in range(3):
        try:
            r = httpx.post(LEDGER_URL, json=entry, timeout=5.0)
            r.raise_for_status()
            return r.json()["id"]
        except httpx.HTTPError as e:
            last = e
    raise last
PY

cat > docs/adr/0001-sqlalchemy.md <<'MD'
# 0001 — ORM 은 SQLAlchemy 2.0

## 결정
SQLAlchemy 2.0 의 선언형 매핑을 쓴다.
MD
