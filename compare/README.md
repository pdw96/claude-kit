# 맞대기 재료

`vibe-audit` 가 맨 Claude 나 널리 쓰는 리뷰 플러그인보다 무엇을 더 잡는지 재는 재료다. 수트(`vibe-audit/evals/` · `recall/`)와 갈려 있다 —
수트 지문 · `gates.sh` · 모양 검사가 이 폴더를 보지 않는다. 왜 · 무엇을 보장하나는 조각 51(`docs/slices/51-head-to-head/`) · ADR 0066.

## 들어 있는 것

| 자리 | 무엇 |
|---|---|
| `cases.tsv` | 재료 열 — 케이스 · 출처 케이스 폴더 · 축 · 경쟁 팔. 조각 51 설계 ③ A 의 닫힌 목록 |
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

`<클론>` 은 `anthropics/claude-plugins-official` 을 `a7ba5b93db0c7c8d17f3f1d25853adca79598a1a` 로 둔 것이다 — 다른 커밋이면 러너가 종료 2 다.
팔마다 깃발(수트 모델 · 심판 · 도구 허용 · 비용 천장)을 러너가 박고, 부르는 쪽이 바꾸지 못한다. 결과는 `compare/results/<시각>-<팔>/` 에 남고 저장소에 싣지 않는다 — `result.json` 과 회차마다의 최종 응답(`messages/`).
