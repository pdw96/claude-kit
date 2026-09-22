#!/usr/bin/env python3
"""어느 절이 예산을 얼마나 쓰는지 절 단위로 연다. 파일만 읽는다.

  python3 scripts/budget-breakdown.py [감사자 이름 ...]

이름을 안 주면 여섯 전부. **게이트가 아니라 보는 도구다** — 실패하지 않는다.

`verify-budget.py` 는 총액에 벽을 세운다. 이것은 그 총액이 **어디로 갔는지**를
연다. 왜 절 단위인가 — 되먹임을 메울 때마다 자란 것은 언제나 **공통 규율**
(담당 경계 · 판정 구분 · 회차)이었고, 그 감사자를 그 감사자이게 하는 **체크
항목**은 그대로였다. 총액만 보면 그 치우침이 안 보인다.

## 문자로 세는 것이 왜 충분한가

절을 하나씩 뺀 사본을 `claude plugin details` 로 다시 재서 실제 토큰 값을 구해
본 적이 있다. **문자 비중과 토큰 비중이 ±0.6%p 안에서 같았다.**

| 절 | 문자 비중 | 토큰 비중 |
|---|---|---|
| 보지 않는 것 | 26.2% | 25.9% |
| 판정은 넷이다 | 20.4% | 19.8% |
| 회차를 잇습니다 | 14.8% | 14.8% |
| 체크 항목 | 12.1% | 12.3% |

그 토큰 추정치는 **환경에 따라 달라진다** — 같은 파일 · 같은 CLI 판인데 로컬은
감사자당 ~7,800 tok, CI 는 ~2,000 tok 이었다(CI 는 `문자/4` 라는 영어용 어림).
비례는 살아 있으니 **비중 이야기는 서고, 절대값은 못 믿는다.** 그래서 여기서는
어디서 재도 같은 문자를 센다.

표준 라이브러리만 쓴다.
"""
import pathlib
import sys


def tops(lines):
    """펜스 밖의 '## ' 만 절이다 — 출력 형식 예시가 '## 안 본 것' 을 품고 있다."""
    out, fenced = [], False
    for k, l in enumerate(lines):
        if l.startswith("```"):
            fenced = not fenced
        elif not fenced and l.startswith("## ") and not l.startswith("### "):
            out.append(k)
    return out


def main(argv):
    root = pathlib.Path(__file__).resolve().parent.parent
    import json
    market = json.loads((root / ".claude-plugin" / "marketplace.json").read_text(encoding="utf-8"))
    agents_dir = root / market["plugins"][0]["name"] / "agents"
    names = argv[1:] or sorted(p.stem for p in agents_dir.glob("audit-*.md"))

    shares = {}
    for name in names:
        src = agents_dir / f"{name}.md"
        if not src.exists():
            print(f"없는 감사자: {name}")
            continue
        text = src.read_text(encoding="utf-8")
        lines = text.splitlines(keepends=True)
        idx = tops(lines)
        head = sum(len(l) for l in lines[:idx[0]]) if idx else len(text)

        rows = []
        for k, i in enumerate(idx):
            j = idx[k + 1] if k + 1 < len(idx) else len(lines)
            rows.append((lines[i].rstrip("\n")[3:], sum(len(l) for l in lines[i:j])))
        rows.sort(key=lambda r: -r[1])
        whole = len(text)

        print(f"\n{name} — 호출 시 {whole} 문자 · 절 {len(rows)}개")
        print(f"  {'절':<26} {'문자':>6} {'줄':>5} {'비중':>7}")
        for label, ch in rows:
            shares.setdefault(label, []).append(ch / whole * 100)
            print(f"  {label:<26} {ch:>6} {'':>5} {ch / whole * 100:>6.1f}%")
        print(f"  {'— 머리말(상시)':<26} {head:>6} {'':>5} {head / whole * 100:>6.1f}%")

    if len(names) > 1 and shares:
        print(f"\n여섯의 폭\n  {'절':<26} {'최소':>7} {'최대':>7}")
        for label, vs in sorted(shares.items(), key=lambda kv: -sum(kv[1]) / len(kv[1])):
            if len(vs) == len(names):
                print(f"  {label:<26} {min(vs):>6.1f}% {max(vs):>6.1f}%")
            else:
                print(f"  {label:<26} {min(vs):>6.1f}% {max(vs):>6.1f}%  ({len(vs)}/{len(names)})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
