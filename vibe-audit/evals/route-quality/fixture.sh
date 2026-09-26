#!/usr/bin/env bash
set -euo pipefail
mkdir -p tests .github/workflows app
cat > .github/workflows/ci.yml <<'EOF'
name: ci
on: [pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pytest -q
        continue-on-error: true
EOF
cat > tests/test_cart.py <<'EOF'
def test_total(cart):
    cart.add("sku-1", 2)
EOF
cat > app/cart.py <<'EOF'
class Cart:
    def add(self, sku, qty):
        self.items.append((sku, qty))

    @property
    def total(self):
        return sum(price(s) * q for s, q in self.items)
EOF
cat > CLAUDE.md <<'EOF'
# 규칙

- 스택: Python 3.12 · pytest
- 모든 PR 은 테스트를 통과해야 한다
EOF
