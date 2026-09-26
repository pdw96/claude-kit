#!/usr/bin/env bash
set -euo pipefail
mkdir -p app
cat > app/payment.py <<'SRC'
import requests

PG_API_KEY = "live_pk_9f2a4c8e1b7d"


def charge(order_id: int, amount: int):
    return requests.post(
        "https://pg.example.com/v1/charge",
        headers={"Authorization": f"Bearer {PG_API_KEY}"},
        json={"order": order_id, "amount": amount},
    ).json()
SRC
cat > app/routes.py <<'SRC'
from fastapi import APIRouter

from .payment import charge

router = APIRouter()


@router.post("/orders/{order_id}/pay")
def pay(order_id: int, amount: int):
    return charge(order_id, amount)
SRC
cat > CLAUDE.md <<'SRC'
# 규칙
- 시크릿은 코드에 두지 않는다. 환경변수로 받는다.
SRC
