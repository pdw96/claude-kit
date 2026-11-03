# 맞대기 재료

`vibe-audit` 가 맨 Claude 나 널리 쓰는 리뷰 플러그인보다 무엇을 더 잡는지 재는 재료다. 수트(`vibe-audit/evals/` · `recall/`)와 갈려 있다 —
수트 지문 · `gates.sh` · 모양 검사가 이 폴더를 보지 않는다. 왜 · 무엇을 보장하나는 조각 51(`docs/slices/51-head-to-head/`) · ADR 0066.

## 들어 있는 것

| 자리 | 무엇 |
|---|---|
| `cases.tsv` | 재료 열 — 케이스 · 출처 케이스 폴더 · 축 · 경쟁 팔. 조각 51 설계 ③ A 의 닫힌 목록. 경쟁 팔 칸은 쉼표로 여럿을 들 수 있다 — `trap-local-dev-password` 는 `claude-security` · `pr-review-toolkit` 둘이 돈다(ADR 0070) |
| `prompts/<축>.md` | 축마다 요청 본문 하나 — 모든 팔에 같다. 도구 이름을 부르지 않는다 |
| `arms.tsv` | 플러그인 팔이 요청 머리에 붙이는 그 도구를 부르는 한 줄(ADR 0067). 「플러그인 없음」 팔은 줄이 없다 |
| `<케이스>/case.yaml` · `graders/found.md` | 기대 결과와 심판 그레이더 하나 — 꼴을 묻지 않고 그 결함을 냈는지만 본다 |

픽스처는 여기 없다. 러너가 출처 케이스의 `fixture.sh` 를 그대로 복사한다.

## 돌리는 법

```bash
./scripts/run-compare.sh vibe-audit                         # 이 작업트리의 vibe-audit
./scripts/run-compare.sh none                               # 플러그인 없음 — 빈 플러그인 · 중립 요청
./scripts/run-compare.sh pr-review-toolkit --from <클론>
./scripts/run-compare.sh claude-security --from <클론>
```

`claude-security` 팔은 하네스 밖에서 `claude -p` 로 돈다 — 하네스의 격리 안에서는 그 스킬이 서지 않는다(ADR 0068). 채점은 같은 그레이더 글을 같은 심판 모델에 세 번 물어 가른다.
이 팔은 `--plugin-dir` 로 플러그인만 받는다 — 재료(`case.yaml` · `graders/` · 요청 · 픽스처)는 러너가 따로 둔 임시 폴더에서 읽는다(조각 52 · ADR 0069 의 4).
격리 없는 Bash 를 가져 디스크를 뒤지는 것은 막지 못하므로, 회차마다 그 회차의 세션 기록(하위 에이전트 것 포함)을 결과 폴더의 `sessions/` 에 남기고
정답지 낱말(`case.yaml` · `found.md` · `expected_outcome` · 재료 폴더의 경로)이 나온 회차를 끝 표 아래에 따로 센다.

`<클론>` 은 `anthropics/claude-plugins-official` 을 `a7ba5b93db0c7c8d17f3f1d25853adca79598a1a` 로 둔 것이다 — 다른 커밋이면 러너가 종료 2 다.
팔마다 깃발(수트 모델 · 심판 · 도구 허용 · 비용 천장)을 러너가 박고, 부르는 쪽이 바꾸지 못한다. 결과는 `compare/results/<시각>-<팔>/` 에 남는다 — `result.json` 과 회차마다의 최종 응답(`messages/`). 이 폴더는 `.gitignore` 라 측정한 세션과 함께 사라진다.
근거로 남길 측정은 `docs/eval-log/compare-<날짜>.tar.xz` 로 싣는다 — 첫 압축본과 푸는 법은 `docs/eval-log/2026-11.md` 「조각 51 닫기」(NC-28).
