#!/usr/bin/env bash
# 도서 대출 한 건을 받는 쓰기 엔드포인트. 요청마다 트랜잭션 하나를 여는 의존성이 `yield` 뒤에서
# 커밋한다 — 그 자리는 응답이 나간 뒤에 돈다. 직렬화 격리라 커밋은 실제로 실패할 수 있다.
# 실제 저장소에서 옮긴 결함이다 — 출처는 case.yaml. 다른 결함을 일부러 심지 않는다.
set -euo pipefail
mkdir -p app/services migrations docs

cat > requirements.txt <<'EOF'
FastAPI==0.141.1
starlette==1.6.0
SQLAlchemy==2.0.36
psycopg[binary]==3.2.3
alembic==1.14.0
pydantic-settings==2.6.1
EOF

cat > docs/schema.md <<'EOF'
# 데이터 모델

| 표 | 무엇 |
|---|---|
| `members` | 회원. 탈퇴해도 지우지 않고 `is_active` 를 끈다 — 지난 대출이 가리킨다 |
| `books` | 소장 도서. `available_copies` 는 지금 빌려 줄 수 있는 권수 |
| `loans` | 대출 한 건. 반납하면 `returned_on` 이 찬다 |

## 원칙

1. **대출 한 건은 한 번에 선다.** 대출 줄이 생기는 것과 `available_copies` 가 줄어드는 것은 함께 들어가거나
   함께 들어가지 않는다. 둘 중 하나만 선 상태는 없다.
2. **빌려 줄 수 있는 권수는 음수가 되지 않는다** — `CHECK (available_copies >= 0)`.
3. **동시에 같은 책을 빌리면 하나만 선다** — 격리 수준 `SERIALIZABLE`.
EOF

cat > app/__init__.py <<'EOF'
EOF
cat > app/services/__init__.py <<'EOF'
EOF

cat > app/db.py <<'EOF'
"""엔진과 세션 공장."""

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.settings import settings

# 동시에 같은 책을 빌리는 두 요청 가운데 하나만 서야 한다(docs/schema.md 원칙 3).
engine = create_engine(settings.database_url, isolation_level="SERIALIZABLE", pool_pre_ping=True)
SessionFactory = sessionmaker(bind=engine, expire_on_commit=False)
EOF

cat > app/settings.py <<'EOF'
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+psycopg://library@localhost/library"


settings = Settings()
EOF

cat > app/models.py <<'EOF'
import sqlalchemy as sa
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class Member(Base):
    __tablename__ = "members"

    id = sa.Column(sa.Integer, primary_key=True)
    card_number = sa.Column(sa.String(20), nullable=False, unique=True)
    name = sa.Column(sa.String(100), nullable=False)
    is_active = sa.Column(sa.Boolean, nullable=False, server_default=sa.true())


class Book(Base):
    __tablename__ = "books"
    __table_args__ = (sa.CheckConstraint("available_copies >= 0", name="books_available_not_negative"),)

    id = sa.Column(sa.Integer, primary_key=True)
    isbn = sa.Column(sa.String(13), nullable=False, unique=True)
    title = sa.Column(sa.String(300), nullable=False)
    loan_days = sa.Column(sa.Integer, nullable=False, server_default="14")
    available_copies = sa.Column(sa.Integer, nullable=False)


class Loan(Base):
    __tablename__ = "loans"
    __table_args__ = (sa.CheckConstraint("due_on >= loaned_on", name="loans_due_after_loan"),)

    id = sa.Column(sa.Integer, primary_key=True)
    book_id = sa.Column(sa.ForeignKey("books.id"), nullable=False)
    member_id = sa.Column(sa.ForeignKey("members.id"), nullable=False)
    loaned_on = sa.Column(sa.Date, nullable=False)
    due_on = sa.Column(sa.Date, nullable=False)
    returned_on = sa.Column(sa.Date, nullable=True)
EOF

cat > migrations/0001_initial.py <<'EOF'
"""첫 스키마 — 회원 · 도서 · 대출"""

import sqlalchemy as sa
from alembic import op

revision = "0001"
down_revision = None


def upgrade():
    op.create_table(
        "members",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("card_number", sa.String(20), nullable=False, unique=True),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.true()),
    )
    op.create_table(
        "books",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("isbn", sa.String(13), nullable=False, unique=True),
        sa.Column("title", sa.String(300), nullable=False),
        sa.Column("loan_days", sa.Integer, nullable=False, server_default="14"),
        sa.Column("available_copies", sa.Integer, nullable=False),
        sa.CheckConstraint("available_copies >= 0", name="books_available_not_negative"),
    )
    op.create_table(
        "loans",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("book_id", sa.ForeignKey("books.id"), nullable=False),
        sa.Column("member_id", sa.ForeignKey("members.id"), nullable=False),
        sa.Column("loaned_on", sa.Date, nullable=False),
        sa.Column("due_on", sa.Date, nullable=False),
        sa.Column("returned_on", sa.Date, nullable=True),
        sa.CheckConstraint("due_on >= loaned_on", name="loans_due_after_loan"),
    )


def downgrade():
    # 대출 기록이 있으면 되돌리지 않는다 — 지우면 되살릴 길이 없다.
    bind = op.get_bind()
    if bind.execute(sa.text("SELECT EXISTS (SELECT 1 FROM loans)")).scalar():
        raise RuntimeError("대출 기록이 있어 되돌리지 않는다")
    op.drop_table("loans")
    op.drop_table("books")
    op.drop_table("members")
EOF

cat > app/services/loans.py <<'EOF'
"""대출 한 건을 세운다."""

from dataclasses import dataclass
from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Book, Loan, Member


class RefusedLoan(Exception):
    """빌려 줄 수 없는 요청 — 부르는 쪽에 이름으로 말한다."""


@dataclass(frozen=True)
class LoanRequest:
    isbn: str
    card_number: str
    loaned_on: date


@dataclass(frozen=True)
class LoanResult:
    loan_id: int
    due_on: date
    available_copies: int


def lend(session: Session, request: LoanRequest) -> LoanResult:
    book = session.scalars(select(Book).where(Book.isbn == request.isbn)).one_or_none()
    if book is None:
        raise RefusedLoan(f"없는 도서다: {request.isbn}")
    member = session.scalars(select(Member).where(Member.card_number == request.card_number)).one_or_none()
    if member is None or not member.is_active:
        raise RefusedLoan(f"빌릴 수 없는 회원이다: {request.card_number}")
    if book.available_copies <= 0:
        raise RefusedLoan(f"남은 권수가 없다: {request.isbn}")

    book.available_copies -= 1
    loan = Loan(
        book_id=book.id,
        member_id=member.id,
        loaned_on=request.loaned_on,
        due_on=request.loaned_on + timedelta(days=book.loan_days),
    )
    session.add(loan)
    session.flush()
    return LoanResult(loan_id=loan.id, due_on=loan.due_on, available_copies=book.available_copies)
EOF

cat > app/schemas.py <<'EOF'
from datetime import date

from pydantic import BaseModel, Field


class LoanIn(BaseModel):
    isbn: str = Field(min_length=10, max_length=13)
    card_number: str = Field(min_length=1, max_length=20)
    loaned_on: date


class LoanOut(BaseModel):
    loan_id: int
    due_on: date
    available_copies: int
EOF

cat > app/main.py <<'EOF'
"""쓰기 엔드포인트 — 대출 한 건."""

from collections.abc import Iterator
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, status
from sqlalchemy.orm import Session

from app.db import SessionFactory
from app.schemas import LoanIn, LoanOut
from app.services.loans import LoanRequest, RefusedLoan, lend

app = FastAPI(title="도서관 — 대출")


def session_scope() -> Iterator[Session]:
    """요청 하나가 트랜잭션 하나다.

    대출 줄과 남은 권수가 한 번에 들어가거나 하나도 들어가지 않는다(docs/schema.md 원칙 1).
    """
    session = SessionFactory()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


@app.post("/loans", response_model=LoanOut, status_code=status.HTTP_201_CREATED)
def post_loan(payload: LoanIn, session: Annotated[Session, Depends(session_scope)]) -> LoanOut:
    """대출 한 건을 받는다. 빌려 줄 수 없으면 422 로 이름을 말한다."""
    try:
        result = lend(
            session,
            LoanRequest(isbn=payload.isbn, card_number=payload.card_number, loaned_on=payload.loaned_on),
        )
    except RefusedLoan as refused:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=str(refused)) from refused
    return LoanOut(loan_id=result.loan_id, due_on=result.due_on, available_copies=result.available_copies)
EOF
