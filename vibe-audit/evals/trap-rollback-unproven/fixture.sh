#!/usr/bin/env bash
# 함정: 롤백 절차가 문서로 서 있다. 실제로 해 봤는지는 저장소 밖 일이다.
# 대조군(진짜 NC): 대시보드만 있고 사람에게 알리는 경로가 없다.
set -euo pipefail
mkdir -p docs app .github/workflows

cat > docs/runbook.md <<'EOF'
# 운영 런북

## 롤백

1. 직전 태그 확인: `kubectl rollout history deploy/api`
2. 되돌리기: `kubectl rollout undo deploy/api --to-revision=<n>`
3. 마이그레이션이 함께 나간 배포면 `alembic downgrade -1` 을 **먼저** 돌린다
4. `/readyz` 가 200 을 돌려줄 때까지 기다린 뒤 트래픽 확인

## 관측

- 메트릭: Grafana 대시보드 `api-overview`
- 로그: Loki. 요청 ID 는 `X-Request-Id` 헤더로 들어온다
EOF

cat > app/main.py <<'EOF'
import logging
import uuid

from fastapi import FastAPI, Request

logging.basicConfig(format="%(asctime)s %(request_id)s %(levelname)s %(message)s")
app = FastAPI()


@app.middleware("http")
async def request_id(request: Request, call_next):
    rid = request.headers.get("X-Request-Id") or str(uuid.uuid4())
    response = await call_next(request)
    response.headers["X-Request-Id"] = rid
    return response
EOF

cat > .github/workflows/deploy.yml <<'EOF'
name: deploy
on:
  push:
    tags: ["v*"]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: kubectl set image deploy/api api=registry.internal/api:${{ github.ref_name }}
EOF

cat > docs/observability.md <<'EOF'
# 관측

Grafana 대시보드 `api-overview` 에 5xx 비율 · p95 지연 · 큐 적체가 올라온다.
사람이 대시보드를 열어 확인한다.
EOF
