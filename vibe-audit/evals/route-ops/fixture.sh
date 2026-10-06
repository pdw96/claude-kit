#!/usr/bin/env bash
# 첫 배포를 앞둔 작은 서비스 — 로그는 print 몇 줄, 롤백 절차는 없다.
set -euo pipefail
mkdir -p app .github/workflows
cat > app/main.py <<'SRC'
from fastapi import FastAPI

app = FastAPI()


@app.post("/orders")
def create_order(item: str, qty: int):
    print("order", item, qty)
    return {"ok": True}
SRC
cat > app/worker.py <<'SRC'
import time


def settle_daily():
    while True:
        try:
            run_settlement()
        except Exception:
            pass
        time.sleep(3600)
SRC
cat > .github/workflows/deploy.yml <<'SRC'
name: deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/deploy.sh
SRC
cat > README.md <<'SRC'
# orders

`main` 에 머지하면 배포된다.
SRC
