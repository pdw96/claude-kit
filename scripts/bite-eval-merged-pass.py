#!/usr/bin/env python3
"""`eval-merged-pass.py` 의 자체 시험이 무는지 본다 — 판정을 한 자리씩 망가뜨린 사본에 자체 시험을 대어 다 떨어지는지.
모델도 바깥 네트워크도 안 쓴다.

  python3 scripts/bite-eval-merged-pass.py

**왜 여기 있나.** 판정이 틀리면 수트를 건너뛰어 아무도 모른다 — 무는지를 보는 것이 조각 12 의 중심이다(ADR 0021 의 3).
`eval.yml` 은 수트 지문에 들어 고치면 route 수트가 돈다 — 변조본은 지문 밖에서 `gates.sh` 가 부른다(조각 12 설계 ② T2).
다른 검사의 변조본은 `bite-gates.sh` 와 `bite-*.py` 에 있다.

떨어지는 것 둘 — 자체 시험이 망가진 사본 하나라도 지나가면(시험을 비우거나 무르게 했다), 망가뜨릴 자리가 판정에
꼭 한 번 있지 않으면(판정을 고치며 여기를 따라 고치지 않았다).

표준 라이브러리만 쓴다.
"""
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHECK = ROOT / "scripts" / "eval-merged-pass.py"
TEST = ROOT / "scripts" / "test-eval-merged-pass.py"

# (설계 ⑤ 의 망가뜨림 — 지나가 버리는 꼴, 판정의 글자, 바꿀 글자)
MUTANTS = [
    ("ref 를 견주지 않는다 — M1",
     "            if k == key and r == ref]\n",
     "            if k == key]\n"),
    ("키를 앞부분으로 견준다 — M2",
     "            if k == key and r == ref]\n",
     "            if k.startswith(key) and r == ref]\n"),
    ("merged_at 을 보지 않는다 — M3",
     "              if at and mcs == sha and base == branch]\n",
     "              if mcs == sha and base == branch]\n"),
    ("merge_commit_sha 를 견주지 않는다 — M4",
     "              if at and mcs == sha and base == branch]\n",
     "              if at and base == branch]\n"),
    ("PR 이 둘이어도 첫 것을 쓴다 — M7",
     "    if len(merged) != 1:\n",
     "    if not merged:\n"),
    ("API 오류를 「건너뛴다」로 돌린다 — M8",
     '        hit, facts = False, {"reason": f"읽지 못했다 — {e}"}\n',
     '        hit, facts = True, {"pr": 0, "created": "", "reason": f"읽지 못했다 — {e}"}\n'),
]


def main():
    text = CHECK.read_text(encoding="utf-8")
    bad = []
    with tempfile.TemporaryDirectory() as t:
        for i, (what, old, new) in enumerate(MUTANTS):
            if (n := text.count(old)) != 1:
                bad.append(f"{what} — 망가뜨릴 자리가 판정에 {n} 번 있다(꼭 한 번이어야 한다): {old.strip()}")
                continue
            copy = pathlib.Path(t) / f"mutant-{i}.py"
            copy.write_text(text.replace(old, new), encoding="utf-8")
            p = subprocess.run([sys.executable, str(TEST), str(copy)], capture_output=True, text=True,
                               encoding="utf-8", errors="replace")
            # 준비 실패 같은 다른 까닭의 exit 1 을 「물었다」로 세지 않는다 — 시험이 판정으로 떨어졌어야 한다.
            if p.returncode != 1 or "FAIL eval-merged-pass.py" not in p.stdout:
                bad.append(f"{what} — 자체 시험이 망가진 판정을 떨어뜨리지 않았다(exit {p.returncode})")
            else:
                print(f"  물었다: {what}")
    if bad:
        print(f"FAIL bite-eval-merged-pass.py — {len(bad)}")
        for b in bad:
            print(f"  {b}")
        return 1
    print(f"PASS bite-eval-merged-pass.py — 변조본 {len(MUTANTS)} 다 자체 시험에서 떨어졌다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
