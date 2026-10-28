#!/usr/bin/env python3
"""`verify-manifest.py` 가 **장터의 줄과 플러그인 폴더**를 맞대는지 본다. 모델도 네트워크도 안 쓴다.

  python3 scripts/test-verify-manifest.py

플러그인이 둘이 되면서 줄마다 이름 · 설명을 보는 것만으로는 모자랐다 — 한 줄을 빼거나 겹쳐도
남은 줄이 맞으니 통과한다(#24 Codex, 조각 5 설계 ② P1). 베낀 트리에 변조본을 하나씩 만들어
검사기가 떨어지는지, 손대지 않은 트리는 통과하는지 본다.

  - `vibe-audit` 줄을 뺀다            → 떨어진다(폴더는 있는데 줄이 없다)
  - `vibe-slice` 줄을 겹친다          → 떨어진다(이름이 두 번)
  - 줄 없는 플러그인 폴더를 둔다       → 떨어진다
  - `vibe-slice` 설명 한 글자를 바꾼다 → 떨어진다(두 군데 적힌 설명이 갈렸다)

라이선스 쪽 변조본은 `bite-gates.sh` 에 있다. 표준 라이브러리만 쓴다.
"""
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
MARKET = ".claude-plugin/marketplace.json"
# 세 규칙(조각 41 설계 ② C · N · K · ADR 0054) — (가) 돈 변조본 · 대조군의 수를 WANT 와 견준다. (나) 변조본은 종료 1 · 「FAIL」 줄 ·
# 기대한 글로 여는 까닭 줄(「  - 」) · 트레이스백 없음일 때만 센다. (다) 대조군은 종료 0 과 「PASS 플러그인 」 줄을 함께 본다.
WANT = (4, 1)
TB = "Traceback (most recent call last)"


def copy(dst):
    """검사기가 읽는 것만 베낀다 — 장터 매니페스트 · 플러그인 매니페스트 · 라이선스 · 검사기."""
    (dst / "scripts").mkdir(parents=True)
    shutil.copy(ROOT / "scripts" / "verify-manifest.py", dst / "scripts")
    shutil.copy(ROOT / "LICENSE", dst / "LICENSE")
    shutil.copytree(ROOT / ".claude-plugin", dst / ".claude-plugin")
    for pj in ROOT.glob("*/.claude-plugin/plugin.json"):
        shutil.copytree(pj.parent, dst / pj.parent.relative_to(ROOT))


def edit_market(t, fn):
    p = t / MARKET
    d = json.loads(p.read_text(encoding="utf-8"))
    fn(d["plugins"])
    p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def drop(name):
    return lambda t: edit_market(t, lambda ps: ps.remove(next(e for e in ps if e["name"] == name)))


def dup(name):
    return lambda t: edit_market(t, lambda ps: ps.append(dict(next(e for e in ps if e["name"] == name))))


def stray(t):
    d = t / "extra-plugin" / ".claude-plugin"
    d.mkdir(parents=True)
    (d / "plugin.json").write_text(json.dumps(
        {"name": "extra-plugin", "version": "0.1.0", "description": "x", "license": "MIT"}) + "\n", encoding="utf-8")


def one_char(t):
    p = t / "vibe-slice" / ".claude-plugin" / "plugin.json"
    d = json.loads(p.read_text(encoding="utf-8"))
    d["description"] = d["description"][:-1] + "!"
    p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


CASES = [
    ("vibe-audit 줄을 뺐다", drop("vibe-audit"), "vibe-audit/.claude-plugin/plugin.json: 플러그인 폴더인데"),
    ("vibe-slice 줄을 겹쳤다", dup("vibe-slice"), "vibe-slice: marketplace.json 에 이름이 2 번"),
    ("줄 없는 플러그인 폴더", stray, "extra-plugin/.claude-plugin/plugin.json: 플러그인 폴더인데"),
    ("vibe-slice 설명 한 글자", one_char, "vibe-slice: 설명이 갈렸다"),
]


def run(t):
    p = subprocess.run([sys.executable, str(t / "scripts" / "verify-manifest.py")], capture_output=True, text=True)
    return p.returncode, p.stdout + p.stderr


def main():
    fails, passes = [], 0
    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        t = tmp / "base"
        copy(t)
        rc, out = run(t)
        ran = [0, 1]
        if rc != 0 or TB in out or not any(ln.startswith("PASS 플러그인 ") for ln in out.splitlines()):
            fails.append(f"손대지 않은 트리가 종료 0 과 PASS 줄로 지나가지 않았다(종료 {rc})\n{out}")
        else:
            passes += 1
        for i, (name, mutate, want) in enumerate(CASES):
            t = tmp / f"case{i}"
            copy(t)
            mutate(t)
            rc, out = run(t)
            ran[0] += 1
            ls = out.splitlines()
            if rc == 1 and "FAIL" in ls and TB not in out and any(ln.startswith(f"  - {want}") for ln in ls):
                passes += 1
            else:
                fails.append(f"{name} — 종료 {rc}, 기대한 줄 {want!r} 이 없다\n{out}")
        if tuple(ran) != WANT:
            fails.append(f"변조본 {ran[0]} · 대조군 {ran[1]} 이 돌았다, {WANT[0]} · {WANT[1]} 이어야 한다")
    if fails:
        for f in fails:
            print(f"FAIL {f}")
        return 1
    print(f"PASS verify-manifest.py 가 문다 — 변조본 {WANT[0]} · 대조군 {WANT[1]} 이 돌았다, 기대 {passes} 개 모두 맞다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
