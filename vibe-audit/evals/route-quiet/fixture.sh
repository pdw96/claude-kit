#!/usr/bin/env bash
set -euo pipefail
mkdir -p app
cat > app/report.py <<'SRC'
def calc(rows):
    total = 0
    for r in rows:
        total += r["amount"] * r["qty"]
    return total
SRC
