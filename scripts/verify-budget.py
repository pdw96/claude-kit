#!/usr/bin/env python3
"""주의 예산을 세고 벽을 세운다. 파일만 읽는다 — 명령도 모델도 부르지 않는다.

  python3 scripts/verify-budget.py            # 스냅숏과 견준다
  python3 scripts/verify-budget.py --write    # 스냅숏을 다시 쓴다

**왜 이것이 필요한가.** 이 플러그인의 주장은 「범위를 좁히는 것이 전부」다.
그런데 되먹임을 메울 때마다 감사자 문구가 자랐다 — 163~172줄에서 256~265줄로
**+57%**. 자란 것이 값을 하는지는 수트가 재지만, **얼마나 썼는지**는 아무도
안 세고 있었다. 세지 않는 예산은 예산이 아니다.

## 왜 토큰이 아니라 문자인가

첫 판은 `claude plugin details` 의 토큰 추정치 위에 세웠다. **CI 에서 바로
틀렸다** — 같은 파일, 같은 CLI 판(2.1.280)인데 로컬은 감사자당 ~7,800 tok,
CI 는 ~2,000 tok 으로 쟀다. CI 쪽이 `문자/4`(영어용 어림)였고 로컬은 실제
토크나이저(한국어 ~0.85 tok/문자)였다.

**환경에 따라 달라지는 숫자 위에 게이트를 세우면 엉뚱한 이유로 운다.** 그래서
여기서 세는 것은 문자다 — 어디서 재도 같은 값이 나온다. 잰 것이 토큰이 아니어도
**「조용히 자랐는가」**라는 물음에는 그대로 답한다.

절 단위 비중으로 견줘 보면 문자와 실제 토큰이 **±0.6%p 안에서** 같았다
(`budget-breakdown.py` 참고). 비례가 살아 있으므로 비중 이야기도 그대로 선다.

## 무엇을 보는가

- **상시** — 프론트매터. 감사를 안 돌리는 세션도 낸다. 본문이 아무리 자라도
  여기는 안 움직이고, 반대로 여기가 움직이면 **모든 세션의 값이 오른 것**이다
- **호출 시** — 파일 전체. 그 감사자가 뜰 때마다 내고, **감사 대상 코드와 같은
  창을 나눠 쓴다.** 문구가 자라면 코드가 들어갈 자리가 준다

## 두 장치

**하나는 스냅숏이다.** `vibe-audit/evals/budget.txt` 가 지금 값을 들고 있고,
한 글자라도 달라지면 실패한다. 고치려면 `--write` 로 다시 쓰고 **커밋에
담아야** 한다 — 그 diff 가 「이번에 주의 예산을 얼마나 더 썼는가」다. 조용히
자라는 길을 막는 것이 이 장치의 전부다.

**다른 하나는 천장이다.** 아래 상수가 벽이다. 이 숫자들은 **의도적으로 정한
것이지 유도된 것이 아니다** — 주의가 언제 흩어지는지는 세어서 안 나온다. 지금
값에서 한 기능치 여유를 두었고, 넘길 일이 생기면 숫자를 올리는 커밋으로 그
판단을 남기라는 뜻이다.

표준 라이브러리만 쓴다.
"""
import pathlib
import sys

# 벽. 단위는 문자. 지금 값에서 약 15% 여유.
ALWAYS_ON_TOTAL_MAX = 5_600      # 지금 4,810 — 감사를 안 돌리는 세션도 내는 값
COMPONENT_ALWAYS_ON_MAX = 900    # 지금 최대 804
AGENT_ON_INVOKE_MAX = 11_000     # 지금 최대 9,459 — 감사 대상 코드와 같은 창을 쓴다
SKILL_ON_INVOKE_MAX = 3_500      # 지금 audit-brief 2,790

SNAPSHOT = pathlib.Path("vibe-audit/evals/budget.txt")
SOURCES = (("agent", "agents/audit-*.md"), ("skill", "commands/*.md"))
HEAD = """# 주의 예산 스냅숏 — 단위는 **문자**. 어디서 재도 같은 값이다.
# `python3 scripts/verify-budget.py --write` 로 갱신한다.
# 이 파일이 바뀌는 커밋은 「이번에 주의 예산을 얼마나 더 썼는가」를 밝히는 커밋이다.
#
# 상시   프론트매터. 감사를 안 돌리는 세션도 낸다
# 호출시 파일 전체. 그 감사자가 뜰 때마다 내고, 감사 대상 코드와 같은 창을 쓴다
"""


def frontmatter_len(text):
    """--- 로 둘러싼 머리말의 길이. 닫히지 않았으면 0 — 그러면 상시가 0 으로
    떨어져 스냅숏이 실패하므로, 깨진 머리말도 여기서 드러난다."""
    if not text.startswith("---\n"):
        return 0
    end = text.find("\n---\n", 3)
    return 0 if end == -1 else len(text[:end + 5])


def measure(plugin):
    out = []
    for kind, pat in SOURCES:
        for p in sorted(plugin.glob(pat)):
            t = p.read_text(encoding="utf-8")
            out.append((kind, p.stem, frontmatter_len(t), len(t)))
    return out


def render(plugin_name, rows):
    lines = [HEAD, f"[{plugin_name}]"]
    for kind, name, head, whole in rows:
        lines.append(f"{kind:<6} {name:<16} {head:>6} {whole:>7}")
    lines.append(f"{'':6} {'— 상시 합계':<16} {sum(r[2] for r in rows):>6}")
    return "\n".join(lines) + "\n"


def ceilings(rows):
    bad = []
    total = sum(r[2] for r in rows)
    if total > ALWAYS_ON_TOTAL_MAX:
        bad.append(f"상시 합계 {total} > 천장 {ALWAYS_ON_TOTAL_MAX} 문자 "
                   "— 감사를 안 돌리는 세션도 내는 값이다")
    for kind, name, head, whole in rows:
        if head == 0:
            bad.append(f"{name}: 머리말이 --- 로 닫히지 않았다 — 프론트매터가 안 읽힌다")
        elif head > COMPONENT_ALWAYS_ON_MAX:
            bad.append(f"{name}: 상시 {head} > 천장 {COMPONENT_ALWAYS_ON_MAX} 문자")
        cap = SKILL_ON_INVOKE_MAX if kind == "skill" else AGENT_ON_INVOKE_MAX
        if whole > cap:
            bad.append(f"{name}: 호출 시 {whole} > 천장 {cap} 문자 "
                       "— 감사 대상 코드가 들어갈 자리를 줄인다")
    return bad


def main(argv):
    root = pathlib.Path(__file__).resolve().parent.parent
    import os
    os.chdir(root)
    write = "--write" in argv[1:]
    if [a for a in argv[1:] if a != "--write"]:
        print(__doc__)
        return 2

    import json
    market = json.loads((root / ".claude-plugin" / "marketplace.json").read_text(encoding="utf-8"))
    name = market["plugins"][0]["name"]
    plugin = root / name
    rows = measure(plugin)
    if not rows:
        print(f"FAIL {plugin} 에서 잴 것을 못 찾았다 — 세지 않는 예산은 예산이 아니다")
        return 1

    now = render(name, rows)
    if write:
        SNAPSHOT.write_text(now, encoding="utf-8")
        print(f"스냅숏을 다시 썼다: {SNAPSHOT}\n")
        print(now)
        return 0

    bad = ceilings(rows)
    if not SNAPSHOT.exists():
        bad.append(f"스냅숏이 없다: {SNAPSHOT} — `--write` 로 만들고 커밋한다")
    elif SNAPSHOT.read_text(encoding="utf-8") != now:
        import difflib
        diff = list(difflib.unified_diff(
            SNAPSHOT.read_text(encoding="utf-8").splitlines(),
            now.splitlines(), "스냅숏", "지금", lineterm="", n=1))
        bad.append("주의 예산이 스냅숏과 다르다 — 자란 만큼을 커밋에 담아야 한다:\n  "
                   + "\n  ".join(diff[2:]))
    if bad:
        for line in bad:
            print("FAIL " + line)
        print(f"\n{len(bad)}건.")
        return 1

    total = sum(r[2] for r in rows if r[0] == "agent")
    biggest = max(r[3] for r in rows if r[0] == "agent")
    print(f"PASS {name} — 상시 합계 {sum(r[2] for r in rows)} 문자 "
          f"(천장 {ALWAYS_ON_TOTAL_MAX}, 여유 {ALWAYS_ON_TOTAL_MAX - sum(r[2] for r in rows)}), "
          f"감사자 호출 시 최대 {biggest} (천장 {AGENT_ON_INVOKE_MAX}, "
          f"여유 {AGENT_ON_INVOKE_MAX - biggest})")
    print(f"     스냅숏 {SNAPSHOT}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
