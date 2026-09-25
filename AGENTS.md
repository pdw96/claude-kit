# AGENTS.md

## Review guidelines

- `scripts/run-evals.sh` 와 `.github/workflows/eval.yml` 의 러너 부분은 **고정**했다(2026-09-25).
  여기서는 두 가지만 짚어 달라 — 실제 CI 실행에서 나는 결함, 그리고 회귀를 통과(exit 0)로
  내는 결함. 하네스가 이상한 `result.json` · 트레이스를 쓰는 가설적 모양은 알려진 한계다
  (`vibe-audit/evals/README.md` 「브리핑 검사기를 떼고, 러너를 고정했다」의 표).
- 브리핑 형식 검사기(`verify-brief.py`)는 이 브랜치에 없다. 후속 PR 에서 git 출력과 직접
  대조하는 방식으로 다시 세운다.
- 그 밖의 파일(감사자 · 커맨드 · 그레이더 · 게이트 · 사본 대장)은 평소대로 봐 달라.
