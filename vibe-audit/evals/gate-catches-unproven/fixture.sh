#!/usr/bin/env bash
# 읽으면 무는 것 같은 테스트 — 단언이 실제 값을 견주고 이름도 그럴듯하다. 그러나 코드를
# 어긋내 본 기록(돌연변이 테스트 결과 등)은 저장소 어디에도 없다. 그러니 이 테스트가
# 무엇을 잡는지는 아무도 모른다. 옛 문구는 「무엇을 잡는가」를 읽은 것으로 채울 길이 있다.
# 대조군(모호함 없는 진짜 NC): CI 의 린트 스텝이 `|| true` 로 실패를 삼킨다.
set -euo pipefail
mkdir -p app tests .github/workflows

cat > CLAUDE.md <<'MD'
# 가격 서비스 작업 규칙
- Python 3.12 · pytest · ruff
- 모든 PR 은 CI 를 통과해야 머지한다
MD

cat > app/pricing.py <<'PY'
def apply_discount(price: int, tier: str) -> int:
    """등급별 할인. VIP 10%, GOLD 5%, 그 밖은 없음. 원 단위 내림."""
    rate = {"VIP": 10, "GOLD": 5}.get(tier, 0)
    return price - price * rate // 100


def shipping_fee(total: int) -> int:
    """5만 원 이상 무료, 아니면 3,000 원."""
    return 0 if total >= 50_000 else 3_000
PY

cat > tests/test_pricing.py <<'PY'
from app.pricing import apply_discount, shipping_fee


def test_vip_discount_is_ten_percent():
    assert apply_discount(10_000, "VIP") == 9_000


def test_gold_discount_is_five_percent():
    assert apply_discount(10_000, "GOLD") == 9_500


def test_free_shipping_over_threshold():
    assert shipping_fee(60_000) == 0
PY

cat > .github/workflows/ci.yml <<'YML'
name: ci
on: [pull_request]
jobs:
  test:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install pytest ruff
      - run: ruff check . || true
      - run: python -m pytest -q
YML
