#!/usr/bin/env python3
"""`verify-map-pin.py` 의 자체 시험이 무는지 본다 — 검사를 한 자리씩 망가뜨린 사본에 자체 시험을 대어 다 떨어지는지.
모델도 네트워크도 안 쓴다.

  python3 scripts/bite-map-pin.py

**왜 여기 있나.** 다른 검사의 변조본은 CI 「게이트가 무는가」(`eval.yml`)에 있지만, `eval.yml` 은 수트 지문에 들어
고치면 route 수트가 돈다. 이 파일은 지문 밖이고 `gates.sh` 가 부른다(ADR 0019 의 5, 조각 10 설계 ② V1).

떨어지는 것 둘 — 자체 시험이 망가진 사본 하나라도 지나가면(시험을 비우거나 무르게 했다), 망가뜨릴 자리가 검사에
꼭 한 번 있지 않으면(검사를 고치며 여기를 따라 고치지 않았다).

표준 라이브러리만 쓴다.
"""
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHECK = ROOT / "scripts" / "verify-map-pin.py"
TEST = ROOT / "scripts" / "test-verify-map-pin.py"

# (설계 ② 의 번호 — 무엇을 망가뜨리나, 검사의 글자, 바꿀 글자)
MUTANTS = [
    ("M1 — 박은 꼴에 가지 이름도 받는다",
     'blob/([0-9a-f]{40})/',
     'blob/([0-9a-z]+)/'),
    ("M2 — 없는 커밋을 거르지 않는다",
     '        if git("cat-file", "-e", f"{sha}^{{commit}}")[0] != 0:\n',
     "        if False:\n"),
    ("M3 — 조상인지 보지 않는다",
     '        if git("merge-base", "--is-ancestor", sha, "HEAD")[0] != 0:\n',
     "        if False:\n"),
    ("M4 — 그 커밋에 경로가 있는지 보지 않는다",
     "        if got is None:\n",
     "        if False:\n"),
    ("M5 — 박은 지도를 기준과 견주지 않는다",
     "        if got != want:\n",
     "        if False:\n"),
    ("M5 — 작업트리를 기준으로 삼지 않는다",
     '    if git("status", "--porcelain", "--", f"{PLUGIN}/")[1].strip() or not last:\n',
     "    if not last:\n"),
    ("M6 — 다른 스킬의 링크로 지나간다",
     "        if not any(rel == skill and path == MAP for rel, _, _, path in good):\n",
     "        if not any(path == MAP for rel, _, _, path in good):\n"),
    ("M6 — 지도가 아닌 경로를 박아도 지나간다",
     "        if not any(rel == skill and path == MAP for rel, _, _, path in good):\n",
     "        if not any(rel == skill for rel, _, _, path in good):\n"),
    ("M6 — SKILL.md 가 있는 폴더만 고른다",
     "if os.path.isdir(os.path.join(SKILLS, d)))",
     'if os.path.isfile(os.path.join(SKILLS, d, "SKILL.md")))'),
    ("R2 — 얕은 클론을 거르지 않는다",
     '    if git("rev-parse", "--is-shallow-repository")[1].strip() == "true":\n',
     "    if False:\n"),
    ("O2 — 출력을 UTF-8 로 고정하지 않는다",
     '        stream.reconfigure(encoding="utf-8")\n',
     "        pass\n"),
]


def main():
    text = CHECK.read_text(encoding="utf-8")
    bad = []
    with tempfile.TemporaryDirectory() as t:
        for i, (what, old, new) in enumerate(MUTANTS):
            if (n := text.count(old)) != 1:
                bad.append(f"{what} — 망가뜨릴 자리가 검사에 {n} 번 있다(꼭 한 번이어야 한다): {old.strip()}")
                continue
            copy = pathlib.Path(t) / f"mutant-{i}.py"
            copy.write_text(text.replace(old, new), encoding="utf-8")
            p = subprocess.run([sys.executable, str(TEST), str(copy)], capture_output=True, text=True)
            # 준비 실패 같은 다른 까닭의 exit 1 을 「물었다」로 세지 않는다 — 시험이 판정으로 떨어졌어야 한다.
            if p.returncode != 1 or "FAIL verify-map-pin.py" not in p.stdout:
                bad.append(f"{what} — 자체 시험이 망가진 검사를 판정으로 떨어뜨리지 않았다(exit {p.returncode})")
            else:
                print(f"  물었다: {what}")
    if bad:
        print(f"FAIL bite-map-pin.py — {len(bad)}")
        for b in bad:
            print(f"  {b}")
        return 1
    print(f"PASS bite-map-pin.py — 변조본 {len(MUTANTS)} 다 자체 시험에서 떨어졌다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
