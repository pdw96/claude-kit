#!/usr/bin/env python3
"""`eval-merged-pass.py` 의 자체 시험이 무는지 본다 — 판정을 한 자리씩 망가뜨린 사본에 자체 시험을 대어 다 떨어지는지.
모델도 바깥 네트워크도 안 쓴다.

  python3 scripts/bite-eval-merged-pass.py

**왜 여기 있나.** 판정이 틀리면 수트를 건너뛰어 아무도 모른다 — 무는지를 보는 것이 조각 12 의 중심이다(ADR 0021 의 3).
`eval.yml` 은 수트 지문에 들어 고치면 route 수트가 돈다 — 변조본은 지문 밖에서 `gates.sh` 가 부른다(조각 12 설계 ② T2).
다른 검사의 변조본은 `bite-gates.sh` 와 `bite-*.py` 에 있다.

떨어지는 것 — 자체 시험이 망가진 사본 하나라도 지나가면(시험을 비우거나 무르게 했다), 망가뜨릴 자리가
판정에 꼭 한 번 있지 않으면(판정을 고치며 여기를 따라 고치지 않았다), 대조군이 어긋나면, 돈 수가 기대한 수와 다르면.

**세 규칙**(조각 41 설계 ② C · N · K · ADR 0054). 판정은 번호를 찍지 않아 번호마다의 대조(R)는 없다.
- (가) 돈 변조본 · 대조군의 수를 WANT 와 견준다 — 목록에서 한 줄을 지운 사본이 지나가지 않게.
- (나) 「물었다」는 자체 시험이 종료 1 로 「FAIL eval-merged-pass.py — 」 줄을 찍고, 그 변조본이 깨야 할 꼴(아래 넷째 칸)로 여는
  실패 줄이 있고, 자체 시험 자신의 트레이스백이 없을 때만이다. 이 파일의 「ID」는 자체 시험의 꼴 이름이다.
- (다) 대조군 — 바꾸지 않은 판정의 사본 — 은 종료 0 과 「PASS eval-merged-pass.py」 줄을 함께 본다.

표준 라이브러리만 쓴다.
"""
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHECK = ROOT / "scripts" / "eval-merged-pass.py"
TEST = ROOT / "scripts" / "test-eval-merged-pass.py"

# (설계 ⑤ 의 망가뜨림 — 지나가 버리는 꼴, 판정의 글자, 바꿀 글자, 자체 시험에서 떨어져야 하는 꼴 — 그 꼴의 실패 줄이 이 글로 연다)
MUTANTS = [
    ("ref 를 견주지 않는다 — M1",
     "            if k == key and r == ref]\n",
     "            if k == key]\n",
     "M1 같은 키가 다른 PR 의 merge ref 에만"),
    ("키를 앞부분으로 견준다 — M2",
     "            if k == key and r == ref]\n",
     "            if k.startswith(key) and r == ref]\n",
     "M2 그 merge ref 에 키가 앞부분만 같은 항목"),
    ("merged_at 을 보지 않는다 — M3",
     "              if at and mcs == sha and base == branch]\n",
     "              if mcs == sha and base == branch]\n",
     "M3 PR 이 머지되지 않았다"),
    ("merge_commit_sha 를 견주지 않는다 — M4",
     "              if at and mcs == sha and base == branch]\n",
     "              if at and base == branch]\n",
     "M4 merge_commit_sha 가 푸시 sha 와 다르다"),
    ("PR 이 둘이어도 첫 것을 쓴다 — M7",
     "    if len(merged) != 1:\n",
     "    if not merged:\n",
     "M7 머지된 PR 이 둘"),
    ("API 오류를 「건너뛴다」로 돌린다 — M8",
     '        hit, facts = False, {"reason": f"읽지 못했다 — {e}"}\n',
     '        hit, facts = True, {"pr": 0, "created": "", "reason": f"읽지 못했다 — {e}"}\n',
     "M8 PR API 403"),
]


WANT = (6, 1)  # (가) 변조본 · 대조군
NAME = "eval-merged-pass.py"


def run(copy):
    """자체 시험을 사본에 — (종료, 표준 출력, 표준 오류)."""
    p = subprocess.run([sys.executable, str(TEST), str(copy)], capture_output=True, text=True,
                       encoding="utf-8", errors="replace")
    return p.returncode, p.stdout, p.stderr


def bit(rc, out, err, form):
    """(나) 종료 1 · 「FAIL <검사> — 」 줄 · 그 꼴로 여는 실패 줄 · 자체 시험의 트레이스백 없음."""
    lines = out.splitlines()
    return (rc == 1 and any(ln.startswith(f"FAIL {NAME} — ") for ln in lines)
            and any(ln.startswith(f"  {form}") for ln in lines)
            and "Traceback (most recent call last)" not in err and "준비 실패" not in out + err)


def main():
    text = CHECK.read_text(encoding="utf-8")
    bad = []
    ran = [0, 0]
    with tempfile.TemporaryDirectory() as t:
        # (다) 대조군 — 바꾸지 않은 판정을 변조본과 같은 길로. 종료 0 과 PASS 줄이어야 한다 — 늘 1 을 내는 시험이면 모든 변조본이
        # 「물었다」가 된다.
        same = pathlib.Path(t) / "control.py"
        same.write_text(text, encoding="utf-8")
        rc, out, err = run(same)
        ran[1] += 1
        passed = [ln for ln in out.splitlines() if ln.startswith(f"PASS {NAME} — ")]
        if rc != 0 or not passed or "Traceback (most recent call last)" in err:
            print(f"FAIL bite-eval-merged-pass.py — 대조군(바꾸지 않은 판정)이 종료 0 과 PASS 줄로 지나가지 않았다(exit {rc})")
            print((out + err)[-800:])
            return 1
        print("  대조군: 바꾸지 않은 판정은 PASS")

        for i, (what, old, new, form) in enumerate(MUTANTS):
            if (n := text.count(old)) != 1:
                bad.append(f"{what} — 망가뜨릴 자리가 판정에 {n} 번 있다(꼭 한 번이어야 한다): {old.strip()}")
                continue
            copy = pathlib.Path(t) / f"mutant-{i}.py"
            copy.write_text(text.replace(old, new), encoding="utf-8")
            rc, out, err = run(copy)
            ran[0] += 1
            # 준비 실패 · 다른 꼴의 실패 · 시험 자신의 예외를 「물었다」로 세지 않는다 — 그 꼴이 판정으로 떨어졌어야 한다.
            if not bit(rc, out, err, form):
                bad.append(f"{what} — 자체 시험이 「{form}」 꼴로 떨어뜨리지 않았다(exit {rc})")
            else:
                print(f"  물었다: {what} — {form}")
    if tuple(ran) != WANT:
        bad.append(f"변조본 {ran[0]} · 대조군 {ran[1]} 이 돌았다, {WANT[0]} · {WANT[1]} 이어야 한다")
    if bad:
        print(f"FAIL bite-eval-merged-pass.py — {len(bad)}")
        for b in bad:
            print(f"  {b}")
        return 1
    print(f"PASS bite-eval-merged-pass.py — 변조본 {ran[0]} 다 그 꼴로 떨어지고 대조군 {ran[1]} 은 지나갔다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
