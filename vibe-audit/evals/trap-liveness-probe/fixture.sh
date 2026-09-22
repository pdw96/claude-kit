#!/usr/bin/env bash
# 함정: 라이브니스는 의존성을 보지 않는 것이 옳다. 레디니스는 본다.
# 대조군(진짜 NC): 백그라운드 워커가 예외를 통째로 삼킨다.
set -euo pipefail
mkdir -p app k8s

cat > k8s/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  template:
    spec:
      containers:
        - name: api
          image: registry.internal/api:1.4.2
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8000
            periodSeconds: 10
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /readyz
              port: 8000
            periodSeconds: 5
EOF

cat > app/health.py <<'EOF'
from fastapi import APIRouter, Response

from .db import pool
from .queue import broker

router = APIRouter()


@router.get("/healthz")
def liveness():
    """프로세스가 살아 있는지만 본다.

    의존성(DB · 브로커)은 일부러 보지 않는다. 여기서 의존성 장애를 실패로
    돌려주면 kubelet 이 컨테이너를 재시작하고, 의존성이 돌아올 때까지
    재시작 루프가 돌아 장애가 커진다. 의존성은 /readyz 가 본다.
    """
    return Response(status_code=200)


@router.get("/readyz")
async def readiness():
    await pool.execute("SELECT 1")
    await broker.ping()
    return {"db": "ok", "broker": "ok"}
EOF

cat > app/worker.py <<'EOF'
import asyncio
import logging

log = logging.getLogger(__name__)


async def drain_outbox():
    while True:
        for row in await fetch_pending():
            try:
                await deliver(row)
                await mark_sent(row.id)
            except Exception:
                pass
        await asyncio.sleep(5)
EOF

mkdir -p docs
cat > docs/runbook.md <<'EOF'
# 운영

- 배포: `kubectl set image deploy/api api=registry.internal/api:<tag>`
- 로그: Loki 대시보드 `api-errors`
- 알림: Slack `#api-alerts` 로 5xx 비율 1% 초과 시 발송
EOF
