#!/usr/bin/env python3
"""`verify-slice-gate.py` 의 자체 시험이 무는지 본다 — 검사를 한 자리씩 망가뜨린 사본에 자체 시험을 대어 다
떨어지는지. 모델도 네트워크도 안 쓴다.

  python3 scripts/bite-slice-gate.py

**왜 여기 있나.** 다른 검사의 변조본은 CI 「게이트가 무는가」(`eval.yml`)에 있지만, `eval.yml` 은 수트 지문에
들어 고치면 route 수트가 돈다. 이 파일은 지문 밖이고 `gates.sh` 가 부른다(ADR 0016 의 6, 조각 7 설계 ② R5).

떨어지는 것 둘 — 자체 시험이 망가진 사본 하나라도 지나가면(시험을 비우거나 무르게 했다), 망가뜨릴 자리가
검사에 꼭 한 번 있지 않으면(검사를 고치며 여기를 따라 고치지 않았다).

표준 라이브러리만 쓴다.
"""
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHECK = ROOT / "scripts" / "verify-slice-gate.py"
TEST = ROOT / "scripts" / "test-verify-slice-gate.py"

# (설계 ② 의 번호 — 무엇을 망가뜨리나, 검사의 글자, 바꿀 글자)
MUTANTS = [
    ("G1 — 착공 PR 의 판정을 지운다",
     "    g1 = outside if founding else []\n",
     "    g1 = []\n"),
    ("G2 — `진행` 조각의 design.md 확인을 지운다",
     'if folder and at_base(base, folder + "design.md")]',
     "if folder]"),
    ("B1 — 쌓은 PR 을 기본 가지로 바꾸지 않는다",
     '    base = base_sha if ref == default else f"origin/{default}"\n',
     "    base = base_sha\n"),
    ("B1 — 로컬 기준을 origin/main 으로 박는다",
     '        return "main"\n',
     '        return "origin/main"\n'),
    ("B3 — 무시되지 않은 새 파일을 뺀다",
     '        out += must("ls-files", "--others", "--exclude-standard")\n',
     "        out += \"\"\n"),
    ("E1 — 출력을 UTF-8 로 고정하지 않는다",
     '        stream.reconfigure(encoding="utf-8")\n',
     "        pass\n"),
    ("E2 — git 출력을 로케일 인코딩으로 읽는다",
     ', text=True, encoding="utf-8", errors="replace")\n',
     ", text=True)\n"),
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
            if p.returncode != 1 or "FAIL verify-slice-gate.py" not in p.stdout:
                bad.append(f"{what} — 자체 시험이 망가진 검사를 판정으로 떨어뜨리지 않았다(exit {p.returncode})")
            else:
                print(f"  물었다: {what}")
    if bad:
        print(f"FAIL bite-slice-gate.py — {len(bad)}")
        for b in bad:
            print(f"  {b}")
        return 1
    print(f"PASS bite-slice-gate.py — 변조본 {len(MUTANTS)} 다 자체 시험에서 떨어졌다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
