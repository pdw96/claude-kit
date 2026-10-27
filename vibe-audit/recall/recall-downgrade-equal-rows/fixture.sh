#!/usr/bin/env bash
# 공통코드에 「배송 권역」 그룹과 코드 셋을 심는 마이그레이션. 운영자도 화면에서 같은 표에 코드를 만든다.
# 실제 저장소에서 옮긴 결함이다 — 출처는 case.yaml. 다른 결함을 일부러 심지 않는다.
set -euo pipefail
mkdir -p migrations/versions app docs

cat > docs/schema.md <<'EOF'
# 데이터 모델

| 표 | 무엇 |
|---|---|
| `code_groups` | 공통코드 그룹 |
| `common_codes` | 공통코드. **운영자가 관리 화면에서 만들고 고친다** — 리비전이 심은 줄과 운영자가 만든 줄이 한 표에 산다 |
| `orders` | 주문. `shipping_zone` 이 `SHIPPING_ZONE` 그룹의 코드를 가리킨다 |

## 원칙

1. **사람이 만든 데이터는 리비전이 지우지 않는다.** 되돌리기(downgrade)는 그 리비전이 만든 것만 거둔다.
   남의 것이 섞여 있으면 지우지 않고 멈춘다.
EOF

cat > app/__init__.py <<'EOF'
EOF

cat > app/models.py <<'EOF'
import sqlalchemy as sa
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class CodeGroup(Base):
    __tablename__ = "code_groups"

    group_code = sa.Column(sa.String(30), primary_key=True)
    name = sa.Column(sa.String(100), nullable=False)
    description = sa.Column(sa.String(200), nullable=True)


class CommonCode(Base):
    __tablename__ = "common_codes"

    group_code = sa.Column(sa.ForeignKey("code_groups.group_code"), primary_key=True)
    code = sa.Column(sa.String(30), primary_key=True)
    name = sa.Column(sa.String(100), nullable=False)
    sort_order = sa.Column(sa.Integer, nullable=False, server_default="0")
    is_active = sa.Column(sa.Boolean, nullable=False, server_default=sa.true())


class Order(Base):
    __tablename__ = "orders"

    id = sa.Column(sa.Integer, primary_key=True)
    shipping_zone = sa.Column(sa.String(30), nullable=True)
EOF

cat > migrations/versions/0006_orders.py <<'EOF'
"""공통코드 · 주문"""

import sqlalchemy as sa
from alembic import op

revision = "0006"
down_revision = None


def upgrade():
    op.create_table(
        "code_groups",
        sa.Column("group_code", sa.String(30), primary_key=True),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("description", sa.String(200), nullable=True),
    )
    op.create_table(
        "common_codes",
        sa.Column("group_code", sa.ForeignKey("code_groups.group_code"), primary_key=True),
        sa.Column("code", sa.String(30), primary_key=True),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("sort_order", sa.Integer, nullable=False, server_default="0"),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.true()),
    )
    op.create_table(
        "orders",
        sa.Column("id", sa.Integer, primary_key=True),
    )


def downgrade():
    raise RuntimeError("첫 리비전은 되돌리지 않는다")
EOF

cat > migrations/versions/0007_shipping_zone.py <<'EOF'
"""배송 권역 — 주문에 권역 칸을 더하고 공통코드 그룹과 코드 셋을 심는다."""

import sqlalchemy as sa
from alembic import op

revision = "0007"
down_revision = "0006"

GROUP = "SHIPPING_ZONE"
# (코드, 이름, 순서)
ZONES = [("METRO", "수도권", 1), ("REGION", "지방", 2), ("ISLAND", "도서 산간", 3)]


def _values() -> str:
    return ", ".join(f"('{code}', '{name}', {order})" for code, name, order in ZONES)


def upgrade():
    op.add_column("orders", sa.Column("shipping_zone", sa.String(30), nullable=True))
    # 운영자가 먼저 만들어 둔 것이 있으면 넘어간다 — 같은 키로 두 번 넣지 않는다.
    op.execute(
        "INSERT INTO code_groups (group_code, name, description)"
        f" SELECT '{GROUP}', '배송 권역', '배송비를 가르는 축이다.'"
        f" WHERE NOT EXISTS (SELECT 1 FROM code_groups WHERE group_code = '{GROUP}')"
    )
    op.execute(
        "INSERT INTO common_codes (group_code, code, name, sort_order)"
        f" SELECT '{GROUP}', v.code, v.name, v.sort_order FROM (VALUES {_values()}) AS v(code, name, sort_order)"
        f" WHERE NOT EXISTS (SELECT 1 FROM common_codes c WHERE c.group_code = '{GROUP}' AND c.code = v.code)"
    )


def downgrade():
    bind = op.get_bind()
    # 주문이 권역을 가리키고 있으면 멈춘다 — 칸을 떨어뜨리면 그 값이 사라진다.
    used = bind.execute(sa.text("SELECT count(*) FROM orders WHERE shipping_zone IS NOT NULL")).scalar()
    if used:
        raise RuntimeError(f"권역이 적힌 주문이 {used} 건 있어 되돌리지 않는다")

    # 심은 셋 말고 다른 코드가 그룹에 있으면 멈춘다 — 운영자가 더한 코드다.
    extra = bind.execute(
        sa.text(
            f"SELECT count(*) FROM common_codes WHERE group_code = '{GROUP}'"
            f" AND code NOT IN ({', '.join(repr(c) for c, _, _ in ZONES)})"
        )
    ).scalar()
    if extra:
        raise RuntimeError(f"운영자가 더한 권역 코드가 {extra} 개 있어 되돌리지 않는다")

    # 심은 셋이 심은 값 그대로인가. 이름이 같아도 값이 다르면 남이 만든 줄이므로 여기서 멈춘다.
    changed = bind.execute(
        sa.text(
            f"SELECT count(*) FROM common_codes c JOIN (VALUES {_values()}) AS v(code, name, sort_order)"
            f" ON c.code = v.code WHERE c.group_code = '{GROUP}'"
            " AND (c.name, c.sort_order, c.is_active) IS DISTINCT FROM (v.name, v.sort_order, TRUE)"
        )
    ).scalar()
    if changed:
        raise RuntimeError(f"값이 바뀐 권역 코드가 {changed} 개 있어 되돌리지 않는다")

    # 「심은 셋」인지는 위의 멈춤 검사가 지킨다.
    op.execute(f"DELETE FROM common_codes WHERE group_code = '{GROUP}'")
    op.execute(f"DELETE FROM code_groups WHERE group_code = '{GROUP}'")
    op.drop_column("orders", "shipping_zone")
EOF
