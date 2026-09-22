#!/usr/bin/env python3
"""어느 절이 얼마를 쓰는지 절 단위로 잰다. API 키도 모델 호출도 필요 없다.

  python3 scripts/budget-breakdown.py [감사자 이름 ...]

이름을 안 주면 여섯 전부. 게이트가 아니라 **보는 도구**다 — 실패하지 않는다.

`verify-budget.py` 는 총액에 벽을 세운다. 이것은 그 총액이 **어디로 갔는지**를
연다. 방법은 하나뿐이다 — 절을 하나씩 뺀 사본을 만들어 `claude plugin details`
로 다시 재고, 줄어든 만큼이 그 절의 값이다. 추정이 100 단위로 반올림되므로
소계는 통짜와 몇 퍼센트 어긋난다. **그 어긋남을 그대로 찍는다.**

왜 절 단위인가. 되먹임을 메울 때마다 문구가 자랐는데, 자란 것은 언제나
**공통 규율**(담당 경계 · 판정 구분 · 회차)이었고 그 감사자를 그 감사자이게
하는 **체크 항목**은 그대로였다. 총액만 보면 그 치우침이 안 보인다.

표준 라이브러리만 쓴다.
"""
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
ROW = re.compile(r"^\s{2,}([a-z][\w-]*)\s+~([\d.,]+k?)\s+~([\d.,]+k?)\s*$", re.MULTILINE)


def num(s):
    s = s.strip().lstrip("~").replace(",", "")
    return int(round(float(s[:-1]) * 1000)) if s.lower().endswith("k") else int(s)


def details(root, market, plugin):
    """격리된 설정에 설치해 호출 시 토큰을 읽는다. 실설정은 건드리지 않는다."""
    cfg = tempfile.mkdtemp(prefix="breakdown-cfg-")
    env = {**os.environ, "CLAUDE_CONFIG_DIR": cfg}
    try:
        for args in (("marketplace", "add", str(root) + os.sep),
                     ("install", f"{plugin}@{market}")):
            subprocess.run(["claude", "plugin", *args], env=env, capture_output=True, text=True)
        r = subprocess.run(["claude", "plugin", "details", plugin],
                           env=env, capture_output=True, text=True)
        return {n: num(b) for n, _, b in ROW.findall(r.stdout)}
    finally:
        shutil.rmtree(cfg, ignore_errors=True)


def copy_repo(dst):
    subprocess.run(
        f"tar -c --exclude=.git --exclude=results -C {ROOT} . | tar -x -C {dst}",
        shell=True, check=True)


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
    import json
    market = json.loads((ROOT / ".claude-plugin" / "marketplace.json").read_text(encoding="utf-8"))
    mname, plugin = market["name"], market["plugins"][0]["name"]
    agents = argv[1:] or sorted(p.stem for p in (ROOT / plugin / "agents").glob("audit-*.md"))

    base_dir = tempfile.mkdtemp(prefix="breakdown-base-")
    copy_repo(base_dir)
    whole = details(pathlib.Path(base_dir), mname, plugin)
    shutil.rmtree(base_dir, ignore_errors=True)

    for agent in agents:
        src = ROOT / plugin / "agents" / f"{agent}.md"
        if not src.exists():
            print(f"없는 감사자: {agent}")
            continue
        lines = src.read_text(encoding="utf-8").splitlines(keepends=True)
        idx = tops(lines)
        base = whole.get(agent)
        if base is None:
            print(f"{agent}: 재고에 없다")
            continue

        rows = []
        for k, i in enumerate(idx):
            j = idx[k + 1] if k + 1 < len(idx) else len(lines)
            d = tempfile.mkdtemp(prefix="breakdown-")
            copy_repo(d)
            (pathlib.Path(d) / plugin / "agents" / f"{agent}.md").write_text(
                "".join(lines[:i] + lines[j:]), encoding="utf-8")
            cut = details(pathlib.Path(d), mname, plugin).get(agent, base)
            shutil.rmtree(d, ignore_errors=True)
            rows.append((lines[i].rstrip("\n")[3:], base - cut, j - i))

        rows.sort(key=lambda r: -r[1])
        total = sum(r[1] for r in rows)
        print(f"\n{agent} — 호출 시 {base} tok · 절 {len(rows)}개")
        print(f"  {'절':<26} {'토큰':>7} {'줄':>5} {'비중':>7}")
        for name, tok, ln in rows:
            print(f"  {name:<26} {tok:>7} {ln:>5} {tok / base * 100:>6.1f}%")
        print(f"  {'— 소계':<26} {total:>7} {sum(r[2] for r in rows):>5} "
              f"{'':>6} (통짜와 {total - base:+d}, 반올림 탓)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
