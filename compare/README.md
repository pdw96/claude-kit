# 맞대기 재료

`vibe-audit` 가 맨 Claude 나 널리 쓰는 리뷰 플러그인보다 무엇을 더 잡는지 재는 재료다. 수트(`vibe-audit/evals/` · `recall/`)와 갈려 있다 —
수트 지문 · `gates.sh` · 모양 검사가 이 폴더를 보지 않는다. 왜 · 무엇을 보장하나는 조각 51(`docs/slices/51-head-to-head/`) · ADR 0066.

## 들어 있는 것

| 자리 | 무엇 |
|---|---|
| `cases.tsv` | 재료 열 — 케이스 · 출처 케이스 폴더 · 축 · 경쟁 팔. 조각 51 설계 ③ A 의 닫힌 목록 |
| `prompts/<축>.md` | 축마다 요청 하나 — 세 팔에 같다. 도구 이름을 부르지 않는다 |
| `<케이스>/case.yaml` · `graders/found.md` | 기대 결과와 심판 그레이더 하나 — 꼴을 묻지 않고 그 결함을 냈는지만 본다 |

픽스처는 여기 없다. 러너가 출처 케이스의 `fixture.sh` 를 그대로 복사한다.

## 돌리는 법

```bash
./scripts/run-compare.sh vibe-audit                         # vibe-audit 팔과 플러그인 없음 팔
./scripts/run-compare.sh pr-review-toolkit --from <클론>
./scripts/run-compare.sh claude-security --from <클론>
```

`<클론>` 은 `anthropics/claude-plugins-official` 을 `a7ba5b93db0c7c8d17f3f1d25853adca79598a1a` 로 둔 것이다 — 다른 커밋이면 러너가 종료 2 다.
결과는 `compare/results/<시각>-<팔>/` 에 남고 저장소에 싣지 않는다 — `result.json` 과 회차마다의 최종 응답(`messages/`).
