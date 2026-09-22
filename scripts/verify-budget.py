#!/usr/bin/env python3
"""주의 예산을 숫자로 고정한다. API 키도 모델 호출도 필요 없다.

  python3 scripts/verify-budget.py            # 스냅숏과 견준다
  python3 scripts/verify-budget.py --write    # 스냅숏을 다시 쓴다

**왜 이것이 필요한가.** 이 플러그인의 주장은 「범위를 좁히는 것이 전부」다.
그런데 되먹임을 메울 때마다 감사자 문구가 자랐다 — 163~172줄에서 256~265줄로
**+57%**. 자란 것이 값을 하는지는 수트가 재지만, **얼마나 썼는지**는 아무도
안 세고 있었다. 세지 않는 예산은 예산이 아니다.

무엇을 보는가:

- **상시(always-on)** — 감사를 안 돌리는 세션도 낸다. 프론트매터 `description`
  이 전부이므로, 본문이 아무리 자라도 여기는 안 움직인다. 반대로 여기가
  움직이면 **모든 세션의 값이 오른 것**이다
- **호출 시(on-invoke)** — 그 감사자가 뜰 때마다 낸다. 감사 대상 코드와 **같은
  창을 나눠 쓴다.** 문구가 자라면 코드가 들어갈 자리가 준다

## 두 장치

**하나는 스냅숏이다.** `vibe-audit/evals/budget.txt` 가 지금 값을 들고 있고,
한 토큰이라도 달라지면 이 검사가 실패한다. 고치려면 `--write` 로 다시 쓰고
**커밋에 담아야** 한다 — 그 diff 가 「이번에 주의 예산을 얼마나 더 썼는가」다.
조용히 자라는 길을 막는 것이 이 장치의 전부다.

**다른 하나는 천장이다.** 아래 상수가 벽이고, 넘으면 실패한다. 이 숫자들은
**의도적으로 정한 것이지 유도된 것이 아니다** — 주의가 언제 흩어지는지는
토큰으로 안 나온다. 지금 값에서 한 기능치 여유를 두었고, 넘길 일이 생기면
숫자를 올리는 커밋으로 그 판단을 남기라는 뜻이다.

CLI 판이 바뀌어 추정치가 움직이면 스냅숏이 한 번 실패한다. 그것은 결함이
아니라 **추정 기준이 바뀐 사실**이고, `--write` 로 받아 적으면 된다.

표준 라이브러리만 쓴다.
"""
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

# 벽. 지금 값에서 한 기능치 여유. 넘기려면 이 숫자를 올리는 커밋을 남긴다.
ALWAYS_ON_TOTAL_MAX = 4_000      # 지금 ~3,449 — 감사를 안 돌리는 세션도 내는 값
COMPONENT_ALWAYS_ON_MAX = 700    # 지금 최대 ~590
AGENT_ON_INVOKE_MAX = 10_000     # 지금 최대 ~8.5k — 감사 대상 코드와 같은 창을 쓴다
SKILL_ON_INVOKE_MAX = 3_500      # 지금 audit-brief ~2.4k

SNAPSHOT = pathlib.Path("vibe-audit/evals/budget.txt")
HEAD = """# 주의 예산 스냅숏. `python3 scripts/verify-budget.py --write` 로 갱신한다.
# 이 파일이 바뀌는 커밋은 「이번에 주의 예산을 얼마나 더 썼는가」를 밝히는 커밋이다.
# 단위는 토큰. `claude plugin details` 의 추정치이고 반올림되어 있다.
"""


def num(s):
    """~3,449 · ~530 · ~8.5k 를 정수로."""
    s = s.strip().lstrip("~").replace(",", "")
    if s.lower().endswith("k"):
        return int(round(float(s[:-1]) * 1000))
    return int(s)


def measure(root):
    """격리된 설정 디렉터리에 설치해 재고를 읽는다. 실설정은 건드리지 않는다."""
    if not shutil.which("claude"):
        return None, "claude 명령이 없다 — 이 검사는 재지 못하면 통과시키지 않는다"
    cfg = tempfile.mkdtemp(prefix="budget-cfg-")
    env = {**os.environ, "CLAUDE_CONFIG_DIR": cfg}
    try:
        market = (root / ".claude-plugin" / "marketplace.json")
        if not market.exists():
            return None, f"마켓플레이스 선언이 없다: {market}"
        import json
        m = json.loads(market.read_text(encoding="utf-8"))
        mname = m["name"]
        plugins = [p["name"] for p in m.get("plugins", [])]
        if not plugins:
            return None, "마켓플레이스에 플러그인이 없다"

        def run(*args):
            return subprocess.run(["claude", "plugin", *args], env=env,
                                  capture_output=True, text=True)

        r = run("marketplace", "add", str(root) + os.sep)
        if r.returncode != 0:
            return None, f"마켓플레이스를 못 걸었다: {r.stdout.strip()} {r.stderr.strip()}"
        out = {}
        for name in plugins:
            r = run("install", f"{name}@{mname}")
            if r.returncode != 0:
                return None, f"{name} 설치 실패: {r.stdout.strip()} {r.stderr.strip()}"
            r = run("details", name)
            if r.returncode != 0:
                return None, f"{name} 재고를 못 읽었다: {r.stdout.strip()} {r.stderr.strip()}"
            out[name] = parse(r.stdout)
            if out[name] is None:
                return None, f"{name}: `claude plugin details` 출력이 예상과 다르다"
        return out, None
    finally:
        shutil.rmtree(cfg, ignore_errors=True)


def parse(text):
    """Always-on 총계와 per-component 표를 뽑는다."""
    m = re.search(r"Always-on:\s*~?([\d,]+)\s*tok", text)
    if not m:
        return None
    rows = re.findall(r"^\s{2,}([a-z][\w-]*)\s+~([\d.,]+k?)\s+~([\d.,]+k?)\s*$",
                      text, re.MULTILINE)
    if not rows:
        return None
    kinds = {}
    for label, names in re.findall(r"^\s*(Skills|Agents)\s*\(\d+\)\s+(.+)$", text, re.MULTILINE):
        for n in names.split(","):
            kinds[n.strip()] = "skill" if label == "Skills" else "agent"
    return {
        "always_on_total": num(m.group(1)),
        "components": {n: (num(a), num(b), kinds.get(n, "?")) for n, a, b in rows},
    }


def render(data):
    lines = [HEAD]
    for plug in sorted(data):
        d = data[plug]
        lines.append(f"[{plug}]")
        lines.append(f"always-on-total  {d['always_on_total']}")
        for n in sorted(d["components"]):
            a, b, kind = d["components"][n]
            lines.append(f"{kind:<6} {n:<16} {a:>6} {b:>7}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def ceilings(data):
    bad = []
    for plug, d in sorted(data.items()):
        if d["always_on_total"] > ALWAYS_ON_TOTAL_MAX:
            bad.append(f"{plug}: 상시 {d['always_on_total']} > 천장 {ALWAYS_ON_TOTAL_MAX} "
                       "— 감사를 안 돌리는 세션도 내는 값이다")
        for n, (a, b, kind) in sorted(d["components"].items()):
            if a > COMPONENT_ALWAYS_ON_MAX:
                bad.append(f"{plug}/{n}: 상시 {a} > 천장 {COMPONENT_ALWAYS_ON_MAX}")
            cap = SKILL_ON_INVOKE_MAX if kind == "skill" else AGENT_ON_INVOKE_MAX
            if b > cap:
                bad.append(f"{plug}/{n}: 호출 시 {b} > 천장 {cap} "
                           "— 감사 대상 코드가 들어갈 자리를 줄인다")
    return bad


def main(argv):
    root = pathlib.Path(__file__).resolve().parent.parent
    os.chdir(root)
    write = "--write" in argv[1:]
    if [a for a in argv[1:] if a != "--write"]:
        print(__doc__)
        return 2

    data, err = measure(root)
    if err:
        print("FAIL " + err)
        return 1

    now = render(data)
    if write:
        SNAPSHOT.write_text(now, encoding="utf-8")
        print(f"스냅숏을 다시 썼다: {SNAPSHOT}")
        print(now)
        return 0

    bad = ceilings(data)
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

    for plug, d in sorted(data.items()):
        agents = [b for _, b, k in d["components"].values() if k == "agent"]
        print(f"PASS {plug} — 상시 {d['always_on_total']} tok "
              f"(천장 {ALWAYS_ON_TOTAL_MAX}, 여유 {ALWAYS_ON_TOTAL_MAX - d['always_on_total']}), "
              f"감사자 호출 시 최대 {max(agents)} (천장 {AGENT_ON_INVOKE_MAX}, "
              f"여유 {AGENT_ON_INVOKE_MAX - max(agents)})")
    print(f"     스냅숏 {SNAPSHOT}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
