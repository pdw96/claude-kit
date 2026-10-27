#!/usr/bin/env python3
"""`verify-slice-gate.py` 의 자체 시험이 무는지 본다 — 검사를 한 자리씩 망가뜨린 사본에 자체 시험을 대어 다
떨어지는지. 모델도 네트워크도 안 쓴다.

  python3 scripts/bite-slice-gate.py

**왜 여기 있나.** `eval.yml` 은 수트 지문에 들어 고치면 route 수트가 돈다 — 변조본은 다 지문 밖에서 `gates.sh` 가
부른다. 이 파일은 관문 검사의 몫이다(ADR 0016 의 6, 조각 7 설계 ② R5). 다른 검사의 변조본은 `bite-gates.sh` 에 있다.

떨어지는 것 — 자체 시험이 망가진 사본 하나라도 지나가면(시험을 비우거나 무르게 했다), 망가뜨릴 자리가
검사에 꼭 한 번 있지 않으면(검사를 고치며 여기를 따라 고치지 않았다), 대조군이 어긋나면, 돈 수가 기대한 수와 다르면,
검사가 낼 수 있는 번호에 자체 시험의 꼴이 없으면.

**세 규칙과 번호마다**(조각 41 설계 ② C · N · K · R · ADR 0054).
- (가) 돈 변조본 · 대조군의 수를 WANT 와 견준다 — 목록에서 한 줄을 지운 사본이 지나가지 않게.
- (나) 「물었다」는 자체 시험이 종료 1 로 「FAIL verify-slice-gate.py — 」 줄을 찍고, 그 변조본이 깨야 할 꼴(아래 넷째 칸)로 여는
  실패 줄이 있고, 자체 시험 자신의 트레이스백이 없을 때만이다. 이 파일의 「ID」는 자체 시험의 꼴 이름이다.
- (다) 대조군 — 바꾸지 않은 검사의 사본 — 은 종료 0 과 「PASS verify-slice-gate.py」 줄을 함께 본다.
- (R) 검사가 찍는 번호(`[G1]` 꼴)마다 자체 시험에 그 번호를 기대한 종료 1 의 꼴이 있는지 두 파일의 글자에서 읽어 견준다. 읽는 법이
  낡지 않았는지는 대조군의 PASS 줄이 찍은 번호와 견주어 보고, 한 번호의 꼴을 다 지운 시험 글이 그 번호를 찍는지도 본다.

표준 라이브러리만 쓴다.
"""
import pathlib
import re
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHECK = ROOT / "scripts" / "verify-slice-gate.py"
TEST = ROOT / "scripts" / "test-verify-slice-gate.py"

# (설계 ② 의 번호 — 무엇을 망가뜨리나, 검사의 글자, 바꿀 글자, 자체 시험에서 떨어져야 하는 꼴 — 그 꼴의 실패 줄이 이 글로 연다)
MUTANTS = [
    ("G1 — 착공 PR 의 판정을 지운다",
     "    g1 = outside if founding else []\n",
     "    g1 = []\n",
     "착공 + scripts/x.py"),
    ("G2 — `진행` 조각의 design.md 확인을 지운다",
     'if folder and at_base(base, folder + "design.md")]',
     "if folder]",
     "기준의 `진행` 조각에 design.md 가 없을 때 구현"),
    ("B1 — 쌓은 PR 을 기본 가지로 바꾸지 않는다",
     '    base = base_sha if ref == default else f"origin/{default}"\n',
     "    base = base_sha\n",
     "이벤트 — 착공 가지 위에 쌓은 구현 PR"),
    ("B1 — 로컬 기준을 origin/main 으로 박는다",
     '        return "main"\n',
     '        return "origin/main"\n',
     "로컬 — origin/main 이 낡고 main 이 앞섰다"),
    ("B3 — 무시되지 않은 새 파일을 뺀다",
     '        out += names("ls-files", "--others", "--exclude-standard")\n',
     "        out += []\n",
     "작업트리 — 무시되지 않은 새 파일"),
    ("E3 — git 이 내는 경로를 줄로 받는다(한글 경로가 따옴표로 감싸여 온다)",
     '["git", args[0], "-z", *args[1:]]',
     '["git", *args]',
     "한글 착공 — 결정 문서만"),
    ("E3 — 텍스트 모드처럼 `\\r` 을 `\\n` 으로 바꾼다",
     'b.decode("utf-8", "surrogateescape") for b',
     'b.decode("utf-8", "surrogateescape").replace("\\r", "\\n") for b',
     "이름에 `\\r` 이 든 기준의 조각 문서를 고친 구현"),
    ("E3 — UTF-8 이 아닌 바이트를 바꿔 읽는다",
     '"utf-8", "surrogateescape") for b', '"utf-8", "replace") for b',
     "이름에 UTF-8 이 아닌 바이트가 든 기준의 조각 문서를 고친 구현"),
    ("E3 — 실패 줄에서 줄바꿈만 이스케이프한다",
     "c if c.isprintable() else", 'c if c != "\\n" else',
     "이름에 탭 · ESC 가 든 구현 파일 — 제어 문자를 그대로 찍었다"),
    ("E3 — 실패 줄의 경로에서 제어 문자를 이스케이프하지 않는다",
     'c if c.isprintable() else c.encode("unicode_escape").decode("ascii")',
     "c",
     "이름에 줄바꿈이 든 구현 파일 — 실패 줄이 줄바꿈을 그대로 찍었다"),
    ("E3 — G1 의 새 조각 문서 목록을 이스케이프하지 않는다",
     "{shown(founding)}", "{', '.join(founding)}",
     "이름에 줄바꿈이 든 새 조각 문서와 구현 — G1 의 두 목록"),
    ("E3 — G1 의 결정 문서 밖 목록을 이스케이프하지 않는다",
     "{shown(g1)}", "{', '.join(g1)}",
     "이름에 줄바꿈이 든 새 조각 문서와 구현 — G1 의 두 목록"),
    ("E3 — G2 「표를 읽지 못했다」의 목록을 이스케이프하지 않는다",
     "읽지 못했다 — 결정 문서 밖: {shown(outside)}", "읽지 못했다 — 결정 문서 밖: {', '.join(outside)}",
     "표를 읽지 못하는 기준 마스터플랜과 이름에 줄바꿈이 든 구현"),
    ("E3 — G2 「`진행` 조각이 없다」의 목록을 이스케이프하지 않는다",
     'f"결정 문서 밖: {shown(outside)}"', "f\"결정 문서 밖: {', '.join(outside)}\"",
     "이름에 줄바꿈이 든 구현 파일 — 실패 줄이 줄바꿈을 그대로 찍었다"),
    ("E3 — 조각 문서 정규식의 끝을 `$` 로 되돌린다",
     '(requirements|design)\\.md\\Z")', '(requirements|design)\\.md$")',
     "끝에 줄바꿈이 붙은 조각 문서 이름 — 착공이 아니다"),
    ("E3 — ADR 정규식의 끝을 `$` 로 되돌린다",
     'ADR = re.compile(r"^docs/adr/[^/]+\\.md\\Z")', 'ADR = re.compile(r"^docs/adr/[^/]+\\.md$")',
     "끝에 줄바꿈이 붙은 ADR 이름의 구현"),
    ("E1 — 출력을 UTF-8 로 고정하지 않는다",
     '        stream.reconfigure(encoding="utf-8")\n',
     "        pass\n",
     "UTF-8 이 아닌 로케일 — 구현이 예외로 끝났다"),
    ("E2 — git 출력을 로케일 인코딩으로 읽는다",
     ', text=True, encoding="utf-8", errors="replace")\n',
     ", text=True)\n",
     "UTF-8 이 아닌 로케일 — 구현이 예외로 끝났다"),
]


WANT = (18, 1)  # (가) 변조본 · 대조군
NAME = "verify-slice-gate.py"
# (R) 검사가 찍는 번호 — 실패 줄을 여는 `"[G1] ` · `FAIL [G1] ` 꼴. 자체 시험이 기대한 번호 — 종료 1 꼴의 번호 목록(`, 1, ["G1"]`).
CHECK_ID = re.compile(r'(?:"|FAIL )\[([A-Z][0-9]+)\] ')
TEST_WANT = re.compile(r"\b1, \[([^\]]*)\]")
CUT = "B2"  # 이 번호의 꼴을 다 지운 시험 글이 이 번호를 찍어야 한다


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
            print(f"FAIL bite-slice-gate.py — 대조군(바꾸지 않은 검사)이 종료 0 과 PASS 줄로 지나가지 않았다(exit {rc})")
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
        print(f"FAIL bite-slice-gate.py — {len(bad)}")
        for b in bad:
            print(f"  {b}")
        return 1
    print(f"PASS bite-slice-gate.py — 변조본 {ran[0]} 다 그 꼴로 떨어지고 대조군 {ran[1]} 은 지나갔다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
