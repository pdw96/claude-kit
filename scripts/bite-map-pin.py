#!/usr/bin/env python3
"""`verify-map-pin.py` 의 자체 시험이 무는지 본다 — 검사를 한 자리씩 망가뜨린 사본에 자체 시험을 대어 다 떨어지는지.
모델도 네트워크도 안 쓴다.

  python3 scripts/bite-map-pin.py

**왜 여기 있나.** `eval.yml` 은 수트 지문에 들어 고치면 route 수트가 돈다 — 변조본은 다 지문 밖에서 `gates.sh` 가
부른다. 이 파일은 판 검사의 몫이다(ADR 0019 의 5, 조각 10 설계 ② V1). 다른 검사의 변조본은 `bite-gates.sh` 에 있다.

떨어지는 것 — 자체 시험이 망가진 사본 하나라도 지나가면(시험을 비우거나 무르게 했다), 망가뜨릴 자리가
검사에 꼭 한 번 있지 않으면(검사를 고치며 여기를 따라 고치지 않았다), 대조군이 어긋나면, 돈 수가 기대한 수와 다르면,
검사가 낼 수 있는 번호에 자체 시험의 꼴이 없으면.

**세 규칙과 번호마다**(조각 41 설계 ② C · N · K · R · ADR 0054).
- (가) 돈 변조본 · 대조군의 수를 WANT 와 견준다 — 목록에서 한 줄을 지운 사본이 지나가지 않게.
- (나) 「물었다」는 자체 시험이 종료 1 로 「FAIL verify-map-pin.py — 」 줄을 찍고, 그 변조본이 깨야 할 꼴(아래 넷째 칸)로 여는
  실패 줄이 있고, 자체 시험 자신의 트레이스백이 없을 때만이다. 이 파일의 「ID」는 자체 시험의 꼴 이름이다.
- (다) 대조군 — 바꾸지 않은 검사의 사본 — 은 종료 0 과 「PASS verify-map-pin.py」 줄을 함께 본다.
- (R) 검사가 찍는 번호(`[M1]` · `[R1]` 꼴)마다 자체 시험에 그 번호를 기대한 종료 1 의 꼴이 있는지 두 파일의 글자에서 읽어 견준다. 읽는 법이
  낡지 않았는지는 대조군의 PASS 줄이 찍은 번호와 견주어 보고, 한 번호의 꼴을 다 지운 시험 글이 그 번호를 찍는지도 본다.

표준 라이브러리만 쓴다.
"""
import pathlib
import re
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHECK = ROOT / "scripts" / "verify-map-pin.py"
TEST = ROOT / "scripts" / "test-verify-map-pin.py"

# (설계 ② 의 번호 — 무엇을 망가뜨리나, 검사의 글자, 바꿀 글자, 자체 시험에서 떨어져야 하는 꼴 — 그 꼴의 실패 줄이 이 글로 연다)
MUTANTS = [
    ("M1 — 박은 꼴에 가지 이름도 받는다",
     'blob/([0-9a-f]{40})/',
     'blob/([0-9a-z]+)/',
     "M1 — https://github.com/pdw96/claude-kit/blob/main/docs/procedure.md"),
    ("M2 — 없는 커밋을 거르지 않는다",
     '        if git("cat-file", "-e", f"{sha}^{{commit}}")[0] != 0:\n',
     "        if False:\n",
     "M2 — 없는 40 자 커밋"),
    ("M3 — 조상인지 보지 않는다",
     '        if git("merge-base", "--is-ancestor", sha, "HEAD")[0] != 0:\n',
     "        if False:\n",
     "M3 — 조상이 아닌 커밋"),
    ("M4 — 그 커밋에 경로가 있는지 보지 않는다",
     "        if got is None:\n",
     "        if False:\n",
     "M4 — 그 커밋에 없는 경로"),
    ("M5 — 박은 지도를 기준과 견주지 않는다",
     "        if got != want:\n",
     "        if False:\n",
     "M5 — 지도가 다른 옛 커밋"),
    ("M5 — 작업트리를 기준으로 삼지 않는다",
     '    if git("status", "--porcelain", "--", f"{PLUGIN}/")[1].strip() or not last:\n',
     "    if not last:\n",
     "작업트리 — vibe-slice/ 만 고쳐 C 를 박음"),
    ("M6 — 다른 스킬의 링크로 지나간다",
     "        if not any(rel == skill and path == MAP for rel, _, _, path in good):\n",
     "        if not any(path == MAP for rel, _, _, path in good):\n",
     "M6 — 한 SKILL.md 의 링크만 지움"),
    ("M6 — 지도가 아닌 경로를 박아도 지나간다",
     "        if not any(rel == skill and path == MAP for rel, _, _, path in good):\n",
     "        if not any(rel == skill for rel, _, _, path in good):\n",
     "M6 — 한 스킬의 링크가 docs/README.md 를 박음"),
    ("M6 — SKILL.md 가 있는 폴더만 고른다",
     "if os.path.isdir(os.path.join(SKILLS, d)))",
     'if os.path.isfile(os.path.join(SKILLS, d, "SKILL.md")))',
     "M6 — 스킬 폴더를 더함 — SKILL.md 없음(틀만)"),
    ("R2 — 얕은 클론을 거르지 않는다",
     '    if git("rev-parse", "--is-shallow-repository")[1].strip() == "true":\n',
     "    if False:\n",
     "R2 — 얕은 클론"),
    ("O2 — 출력을 UTF-8 로 고정하지 않는다",
     '        stream.reconfigure(encoding="utf-8")\n',
     "        pass\n",
     "O2 — LC_ALL=C · PYTHONIOENCODING=cp949 의 실패 꼴"),
]


WANT = (11, 1)  # (가) 변조본 · 대조군
NAME = "verify-map-pin.py"
# (R) 검사가 찍는 번호 — 실패 줄을 여는 `"[M1] ` · `FAIL [R1] ` 꼴. 자체 시험이 기대한 번호 — 종료 1 꼴의 번호 목록(`, 1, ["M1"]`).
CHECK_ID = re.compile(r'(?:"|FAIL )\[([A-Z][0-9]+)\] ')
TEST_WANT = re.compile(r"\b1, \[([^\]]*)\]")
CUT = "R3"  # 이 번호의 꼴을 다 지운 시험 글이 이 번호를 찍어야 한다


def code(text):
    return "\n".join(ln for ln in text.split("\n") if not ln.lstrip().startswith("#"))


def expected(text):
    return {i for m in TEST_WANT.finditer(code(text)) for i in re.findall(r'"([A-Z][0-9]+)"', m.group(1))}


def gap(check_text, test_text):
    have, want = set(CHECK_ID.findall(code(check_text))), expected(test_text)
    if not have or not want:
        return None
    return have - want


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
    test_text = TEST.read_text(encoding="utf-8")
    bad = []
    ran = [0, 0]
    with tempfile.TemporaryDirectory() as t:
        # (다) 대조군 — 바꾸지 않은 검사를 변조본과 같은 길로. 종료 0 과 PASS 줄이어야 한다 — 늘 1 을 내는 시험이면 모든 변조본이
        # 「물었다」가 된다.
        same = pathlib.Path(t) / "control.py"
        same.write_text(text, encoding="utf-8")
        rc, out, err = run(same)
        ran[1] += 1
        passed = [ln for ln in out.splitlines() if ln.startswith(f"PASS {NAME} — ")]
        if rc != 0 or not passed or "Traceback (most recent call last)" in err:
            print(f"FAIL bite-map-pin.py — 대조군(바꾸지 않은 검사)이 종료 0 과 PASS 줄로 지나가지 않았다(exit {rc})")
            print((out + err)[-800:])
            return 1
        print("  대조군: 바꾸지 않은 검사는 PASS")

        # (R) 번호마다 자체 시험의 꼴
        g = gap(text, test_text)
        if g is None:
            bad.append(f"{NAME} 의 번호나 자체 시험이 기대한 번호를 하나도 못 읽었다 — 읽는 정규식이 낡았다")
        else:
            if g:
                bad.append(f"검사가 찍는 번호 {' '.join(sorted(g))} 를 기대한 종료 1 의 꼴이 자체 시험에 없다")
            shown = re.search(r"· 번호 ([A-Z0-9 ]+) — ", passed[0])
            if not shown or set(shown.group(1).split()) != expected(test_text):
                bad.append(f"자체 시험의 글자에서 읽은 번호 {sorted(expected(test_text))} 가 대조군이 찍은 번호와 다르다 — 읽는 정규식이 낡았다: {passed[0]}")
            cut = "\n".join(ln for ln in test_text.split("\n")
                             if not (m := TEST_WANT.search(ln)) or f'"{CUT}"' not in m.group(1))
            cut_gap = (gap(text, cut) or set()) - g  # 이미 빈 번호는 위에서 찍었다
            if CUT not in g and cut_gap != {CUT}:
                bad.append(f"{CUT} 의 꼴을 다 지운 자체 시험 글에서 번호 대조가 {CUT} 하나를 찍지 않았다: {sorted(cut_gap)}")
            elif not g:
                print(f"  번호마다: {' '.join(sorted(set(CHECK_ID.findall(code(text)))))} — 다 꼴이 있다 · {CUT} 를 지운 글은 {CUT} 를 찍는다")

        for i, (what, old, new, form) in enumerate(MUTANTS):
            if (n := text.count(old)) != 1:
                bad.append(f"{what} — 망가뜨릴 자리가 검사에 {n} 번 있다(꼭 한 번이어야 한다): {old.strip()}")
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
        print(f"FAIL bite-map-pin.py — {len(bad)}")
        for b in bad:
            print(f"  {b}")
        return 1
    print(f"PASS bite-map-pin.py — 변조본 {ran[0]} 다 그 꼴로 떨어지고 대조군 {ran[1]} 은 지나갔다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
