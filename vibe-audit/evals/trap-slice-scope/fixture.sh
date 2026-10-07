#!/usr/bin/env bash
# 범위가 조각 폴더에 있는 레포 — 틀(`vibe-slice`)대로 섰다. 의도는 `INTENT.md`, 마스터플랜이 조각을
# 나누고, 조각마다 `docs/slices/<n>-<이름>/requirements.md` 가 「하지 않을 일」을 든다. 착공 때 쓴
# `PRD.md` 는 남아 있지만 마스터플랜의 의도 줄은 `INTENT.md` 를 가리킨다.
#
# 진짜 부적합: 진행 중인 조각 2 「회비 알림」의 「하지 않을 일」 1 이 문자(SMS) 발송을 막는데
# `app/reminder/sms.py` 가 문자를 보낸다.
# 덫 1(닫힌 조각): 조각 1 「회원 명부」는 「CSV 내보내기를 만들지 않는다」였다. 조각 2 는 미납자 CSV 를
# 성공 기준으로 들고 만들었다 — 조각 1 의 제외는 조각 1 의 구현에만 걸린다.
# 덫 2(옛 PRD): `PRD.md` 는 「이메일 발송」을 하지 않을 일로 적었지만 의도 문서는 `INTENT.md` 다.
# 조각 2 의 이메일 알림은 부적합이 아니다.
set -euo pipefail
mkdir -p app/reminder docs/slices/1-members docs/slices/2-dues-reminder

cat > CLAUDE.md <<'MD'
# 동아리 회비 작업 규칙

의도는 `INTENT.md`, 조각 나눔은 `docs/master-plan.md`, 조각의 요구사항 · 설계는 `docs/slices/` 에 있다.

## 스택
- Python 3.12 · FastAPI 0.115 · SQLAlchemy 2.0

## 앵커볼트 — 바꾸려면 먼저 물어볼 것
- 회원 · 납부 테이블 스키마

## 작업 방식
- 조각 하나씩. 요구사항과 설계를 한 PR 로 낸 뒤 구현한다
MD

cat > INTENT.md <<'MD'
# 동아리 회비 — 의도

## Why
총무가 회비 납부를 엑셀로 맞추느라 매달 이틀을 쓴다.

## What
- 회원 명부와 월 회비 납부 기록
- 미납자 알림

## Not
1. 결제 대행(PG) 연동은 하지 않는다 — 회비는 계좌 이체로 받고 총무가 확인한다.
2. 회원이 스스로 가입하는 화면은 만들지 않는다.
MD

cat > PRD.md <<'MD'
# 동아리 회비 (2026-06 착공)

## 문제
총무가 회비 납부를 엑셀로 맞춘다.

## 성공 기준
- 미납자가 화면 배너로 보인다

## 하지 않을 일
- 이메일 발송 — 알림은 화면 배너로만
- 결제 대행 연동
MD

cat > docs/master-plan.md <<'MD'
# 동아리 회비 마스터플랜

## 가리키는 문서

| 무엇 | 어디 |
|---|---|
| 의도 — Why · What · Not | `INTENT.md` |
| 작업 규칙 | `CLAUDE.md` |
| 조각의 요구사항 · 설계 | `docs/slices/` |

## 조각 나눔

| 순서 | 조각 | 목표 한 줄 | 의존 | 상태 | 조각 폴더 |
|---|---|---|---|---|---|
| 1 | 회원 명부 | 회원을 등록하고 화면에서 본다 | — | 닫힘 | `docs/slices/1-members/` |
| 2 | 회비 알림 | 미납자에게 이메일로 알리고 총무가 미납자 목록을 내려받는다 | 회원 명부 | 진행 | `docs/slices/2-dues-reminder/` |

## 범위 변경

| 날짜 | 무엇을 | 왜 | 어느 조각에서 |
|---|---|---|---|
| 2026-08-03 | 알림을 화면 배너에서 이메일로 | 회원이 사이트에 잘 안 들어온다 | 회비 알림 — `INTENT.md` What 을 고쳤다 |
MD

cat > docs/slices/1-members/requirements.md <<'MD'
# 조각 1 — 회원 명부 (2026-07-01 착공)

## 문제
회원 명단이 총무의 엑셀에만 있다.

## 핵심 사용자와 시나리오
- 사용자: 총무
- 시나리오: 신입을 등록하고 명단을 화면에서 본다.

## 성공 기준
- 회원 등록 · 조회가 된다

## 하지 않을 일
1. CSV 내보내기를 만들지 않는다 — 명부는 화면에서만 본다.
2. 회비 금액 계산은 하지 않는다.
3. 회원 사진은 받지 않는다.

## 제약
- 리뷰 3라운드

## 닫으며 (2026-07-20)
성공 기준 하나를 등록 · 조회 화면에 대어 봤다. 다음 조각은 조각 나눔 2 「회비 알림」.
MD

cat > docs/slices/2-dues-reminder/requirements.md <<'MD'
# 조각 2 — 회비 알림 (2026-08-04 착공)

## 문제
미납자를 총무가 한 명씩 찾아 연락한다.

## 핵심 사용자와 시나리오
- 사용자: 총무
- 시나리오: 매달 5일 미납자에게 알림이 가고, 총무는 미납자 목록을 CSV 로 내려받아 대조한다.

## 성공 기준
- 매달 5일 미납자 전원에게 이메일이 간다
- 총무가 미납자 CSV 를 내려받는다

## 하지 않을 일
1. 문자(SMS) 발송은 하지 않는다 — 건당 비용이 들고, 전화번호를 알림에 쓰겠다는 동의를 받지 않았다.
2. 알림에 계좌 번호를 넣지 않는다 — 회원은 동아리방 공지로 안다.
3. 납부 확인을 자동으로 하지 않는다 — 총무가 통장과 대조한다.

## 제약
- 리뷰 3라운드
MD

cat > docs/slices/2-dues-reminder/design.md <<'MD'
# 조각 2 설계 — 회비 알림

## ① 바뀌는 것
`app/reminder/` — 이메일 알림 · 미납자 CSV.

## ② 보장하는 것 / 보장하지 않는 것
미납자 한 명에 달마다 이메일 한 통.

## ③ 받는 입력
`members` · `payments` 테이블.

## ④ 결정
없음 — 대안이 없었다.

## ⑤ 검증 계획
미납자 둘 · 납부자 하나로 알림 수를 센다.

## ⑥ PR 나눔
한 PR.
MD

cat > pyproject.toml <<'TOML'
[project]
name = "club-dues"
requires-python = ">=3.12"
dependencies = [
  "fastapi==0.115.0",
  "sqlalchemy==2.0.30",
  "httpx==0.27.0",
]
TOML

cat > app/__init__.py <<'PY'
PY

cat > app/members.py <<'PY'
from dataclasses import dataclass


@dataclass
class Member:
    id: int
    name: str
    email: str
    phone: str


def unpaid(members: list[Member], paid_ids: set[int]) -> list[Member]:
    return [m for m in members if m.id not in paid_ids]
PY

cat > app/reminder/__init__.py <<'PY'
"""회비 알림 — 매달 5일 미납자에게 알린다(조각 2)."""
PY

cat > app/reminder/email.py <<'PY'
import smtplib
from email.message import EmailMessage

from ..members import Member


def send_email(m: Member, month: str) -> None:
    msg = EmailMessage()
    msg["To"] = m.email
    msg["Subject"] = f"{month} 회비 안내"
    msg.set_content(f"{m.name} 님, {month} 회비가 아직 확인되지 않았습니다.")
    with smtplib.SMTP("localhost") as s:
        s.send_message(msg)
PY

cat > app/reminder/sms.py <<'PY'
import os

import httpx

from ..members import Member

SMS_API = "https://sms.example.com/v1/send"


def send_sms(m: Member, month: str) -> None:
    # 이메일을 잘 안 읽는 회원이 있어 문자로도 보낸다.
    httpx.post(SMS_API, json={"to": m.phone, "text": f"{month} 회비 안내"},
               headers={"Authorization": os.environ["SMS_TOKEN"]}, timeout=5.0)
PY

cat > app/reminder/export.py <<'PY'
import csv
import io

from ..members import Member


def unpaid_csv(members: list[Member]) -> str:
    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow(["id", "name", "email"])
    for m in members:
        w.writerow([m.id, m.name, m.email])
    return buf.getvalue()
PY

cat > app/reminder/run.py <<'PY'
from ..members import Member, unpaid
from .email import send_email
from .sms import send_sms


def remind(members: list[Member], paid_ids: set[int], month: str) -> int:
    targets = unpaid(members, paid_ids)
    for m in targets:
        send_email(m, month)
        send_sms(m, month)
    return len(targets)
PY

cat > README.md <<'MD'
# club-dues

동아리 회비 납부 기록과 미납자 알림. 매달 5일 `app.reminder.run.remind` 를 돌린다.
MD
