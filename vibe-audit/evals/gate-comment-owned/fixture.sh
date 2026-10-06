#!/usr/bin/env bash
# 결정이 독스트링에만 산다 — 전표 전송은 한 번만 시도하기로 했고(중복 전표), 그 약속을
# 패키지 독스트링(`app/ledger/__init__.py`)에 적었다. 그런데 같은 패키지의 `sync.py` 는
# 세 번 재시도하고, 그 자리의 주석은 재시도를 정당화한다. CLAUDE.md · PRD · ADR 에는 이 결정도,
# 「결정을 독스트링에 적는다」는 규칙도 없다.
#
# 첫 판은 「재시도하지 않는다(결정)」 주석이 재시도 루프 **바로 위**에 있어, 옛 문구도
# 스스로 잡았다. 이 판은 약속과 어기는 코드가 **다른 파일**에 있고, 볼 문서와 코드가 더 많다.
# 함정 둘째(FB-6 · 7): CLAUDE.md 가 결정 자리를 `decisions/` 로 적고 `docs/adr/` 는 효력이 없다고
# 적었다. ADR 0002(밤 배치)와 코드(즉시 전송)는 다르지만 `decisions/` 가 그것을 대체했다 — 기준
# 문서 목록을 고정해 둔 옛 문구는 ADR 0002 를 근거로 거짓 NC 를 낼 수 있다.
# 대조군(모호함 없는 진짜 NC): CLAUDE.md 의 스택 버전과 실제 의존성이 다르다.
set -euo pipefail
mkdir -p app/ledger docs/adr decisions

cat > CLAUDE.md <<'MD'
# 회계 연동 작업 규칙

## 스택
- Python 3.12 · FastAPI 0.115 · SQLAlchemy 2.0

## 앵커볼트 — 바꾸려면 먼저 물어볼 것
- 전표 테이블 스키마

## 결정 기록
- 결정은 `decisions/` 에 남긴다. `docs/adr/` 는 2026-07 에 멈춘 옛 기록이라 판정 근거가 아니다 —
  둘이 다르면 `decisions/` 가 이긴다.

## 작업 방식
- 새 의존성을 추가할 때는 왜 그것인지 세 줄을 남긴다
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

cat > app/ledger/__init__.py <<'PY'
"""외부 회계 시스템과의 전표 연동.

약속(2026-08 결정): 전표 전송은 **한 번만 시도한다.** 외부 회계 시스템이 멱등키를
받지 않아, 타임아웃 뒤 다시 보내면 같은 전표가 두 번 잡힌다. 실패한 전표는
`failed_entries` 에 남기고 사람이 대조한다.
"""
PY

cat > app/ledger/sync.py <<'PY'
import httpx

from .store import mark_failed

LEDGER_URL = "https://ledger.example.internal/v1/entries"


def push_entry(entry: dict) -> str:
    # 회계 시스템 앞단이 가끔 502 를 낸다 — 세 번까지 보내 본다.
    last = None
    for attempt in range(3):
        try:
            r = httpx.post(LEDGER_URL, json=entry, timeout=5.0)
            r.raise_for_status()
            return r.json()["id"]
        except httpx.HTTPError as e:
            last = e
    mark_failed(entry, reason=str(last))
    raise last
PY

cat > app/ledger/store.py <<'PY'
from ..db import session
from ..models import FailedEntry


def mark_failed(entry: dict, reason: str) -> None:
    session.add(FailedEntry(payload=entry, reason=reason))
    session.commit()
PY

cat > app/models.py <<'PY'
import sqlalchemy as sa
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class FailedEntry(Base):
    __tablename__ = "failed_entries"

    id = sa.Column(sa.Integer, primary_key=True)
    payload = sa.Column(sa.JSON, nullable=False)
    reason = sa.Column(sa.Text, nullable=False)
    resolved = sa.Column(sa.Boolean, nullable=False, default=False)
PY

cat > app/db.py <<'PY'
import os

from sqlalchemy import create_engine
from sqlalchemy.orm import Session

engine = create_engine(os.environ["DATABASE_URL"])
session = Session(engine)
PY

cat > app/api.py <<'PY'
from fastapi import APIRouter

from .db import session
from .ledger.sync import push_entry
from .models import FailedEntry

router = APIRouter()


@router.post("/entries")
def create_entry(entry: dict):
    return {"ledger_id": push_entry(entry)}


@router.get("/failed")
def list_failed():
    return [{"id": f.id, "reason": f.reason} for f in session.query(FailedEntry).filter_by(resolved=False)]
PY

cat > README.md <<'MD'
# ledger-sync

매출 전표를 외부 회계 시스템에 넘긴다.

## 실행

```bash
export DATABASE_URL=postgresql://localhost/ledger
uvicorn app.api:router --port 8040
```

실패한 전표는 `GET /failed` 로 본다.
MD

cat > docs/adr/0002-nightly-batch.md <<'MD'
# 0002 — 전표는 밤마다 한 번에 보낸다

## 결정
매일 02:00 에 그날의 전표를 묶어 한 번에 보낸다. 요청마다 보내지 않는다.
MD

cat > decisions/2026-08-realtime.md <<'MD'
# 전표는 생기는 즉시 하나씩 보낸다 (2026-08)

밤 배치는 마감 대조가 하루 늦었다. 전표가 생기면 `POST /entries` 에서 바로 보낸다.
docs/adr/0002 를 대체한다.
MD

cat > docs/adr/0001-sqlalchemy.md <<'MD'
# 0001 — ORM 은 SQLAlchemy 2.0

## 결정
SQLAlchemy 2.0 의 선언형 매핑을 쓴다.
MD
