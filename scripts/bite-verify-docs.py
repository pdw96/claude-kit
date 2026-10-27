#!/usr/bin/env python3
"""`verify-docs.py` 의 자체 시험이 다른 레포 모드에서 무는지 본다 — 검사의 다른 레포 모드를 한 자리씩 망가뜨린 사본에
자체 시험을 대어 다 떨어지는지. 모델도 네트워크도 안 쓴다.

  python3 scripts/bite-verify-docs.py

**왜 여기 있나.** 원본 모드의 변조 자리는 `bite-gates.sh` 에 있다. 둘 다 수트 지문 밖이고 `gates.sh` 가
부른다 — `eval.yml` 은 지문에 들어 고치면 route 수트가 돈다(ADR 0018 의 6, 조각 9 설계 ② V1).
`bite-slice-gate.py` 와 같은 길이다.

떨어지는 것 — 자체 시험이 망가진 사본 하나라도 지나가면(시험을 비우거나 무르게 했다), 망가뜨릴 자리가
검사에 꼭 한 번 있지 않으면(검사를 고치며 여기를 따라 고치지 않았다), 대조군이 어긋나면, 돈 수가 기대한 수와 다르면,
검사가 낼 수 있는 번호에 자체 시험의 변조본이 없으면.

**세 규칙과 번호마다**(조각 41 설계 ② C · N · K · R · ADR 0054).
- (가) 돈 변조본 · 대조군의 수를 WANT 와 견준다 — 목록에서 한 줄을 지운 사본이 지나가지 않게.
- (나) 「물었다」는 자체 시험이 종료 1 로 「FAIL — 」 줄을 찍고, 그 변조본이 처음 깨야 할 꼴(아래 넷째 칸)의 실패 줄
  (「  - <꼴>: 」)이 있고, 「준비 실패」와 자체 시험 자신의 트레이스백이 없을 때만이다. 이 파일의 「ID」는 자체 시험의 꼴 이름이다.
  `--first` 라 처음 어긋난 꼴 하나만 찍힌다 — 넷째 칸은 그 꼴이다(ADR 0047).
- (다) 대조군 — 바꾸지 않은 검사 — 은 종료 0 과 「PASS 문서 대조 검사가 문다(다른 레포 모드만)」 줄을 함께 본다.
- (R) 검사가 찍는 번호(`fail(…, "O1", …)` · `"[A2] …"`)마다 자체 시험의 변조본 목록(`CASES` · `QUIET` · `PROFILE_CASES` ·
  `R_CASES`)에 그 번호를 기대한 것이 있는지 본다. 목록은 자체 시험을 모듈로 읽는다 — 돌리지 않는다. 한 번호(`CUT`)를 기대한
  변조본을 다 뺀 목록이 그 번호를 찍는지도 본다. 원본 모드의 변조 자리는 `bite-gates.sh` 에 있지만 번호는 검사 하나의 것이라
  여기서 함께 본다.

**빠르게** (`docs/slices/36-bite-speedup/design.md` ② P1 · P3 · P4 · ADR 0047) — 변조본은 다른 레포 모드만 망가뜨리므로
자체 시험을 `--repo-only --first` 로 불러 그 모드만, 첫 어긋난 꼴까지만 돌린다. 변조본은 제 사본만 읽어 서로 기대지 않으므로
CPU 수만큼 함께 돌리고, 결과는 변조본의 차례대로 찍는다. 먼저 **대조군** — 바꾸지 않은 검사 — 을 같은 길로 돌려 자체 시험이
`PASS` 로 끝나고 「물지 않았다」로 세는지 본다. 늘 1 을 내는 깃발이나 결과를 잃는 길이면 모든 변조본이 「물었다」가 되기 때문이다.

표준 라이브러리만 쓴다.
"""
import concurrent.futures
import importlib.util
import os
import pathlib
import re
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHECK = ROOT / "scripts" / "verify-docs.py"
TEST = ROOT / "scripts" / "test-verify-docs.py"

# (설계 ② 의 번호 — 무엇을 망가뜨리나, 검사의 글자, 바꿀 글자, 자체 시험이 `--first` 로 처음 떨어뜨려야 하는 꼴 — 그 실패 줄이 「  - <꼴>:」로 연다)
MUTANTS = [
    ("A5 — `--repo` 를 무시해 원본 모드로 간다",
     "    tpl = side_templates() if repo else None\n",
     "    tpl = None\n",
     "다른 레포 A4 진행 조각 설계에서 ③ 이 빠진다"),
    ("A1 — 틀의 원천을 빈 목록으로 읽는다",
     "        found = headings(lines(p))\n",
     "        found = []\n",
     "다른 레포 A4 진행 조각 설계에서 ③ 이 빠진다"),
    ("A2 — 빈 원천의 거절을 지운다",
     "        if not found:\n",
     "        if False:\n",
     "다른 레포 A2 검사 옆 틀 requirements.md 의 ## 제목을 다 지운다"),
    ("A3 — 다른 레포 모드에서도 T1 · T2 를 본다",
     "        schema = check_sources(r, tpl)\n",
     "        schema = check_sources(r, tpl)\n        check_templates(r, root, schema)\n",
     "다른 레포 대조 A4 · A6 의도 줄 PRD.md · 닫힌 조각 · 진행 조각"),
    ("A1 — 원천을 검사 옆이 아니라 루트의 vibe-slice/…/templates/ 에서 찾는다",
     "    tpl = side_templates() if repo else None\n",
     "    tpl = root / TEMPLATES if repo else None\n",
     "다른 레포 A4 진행 조각 설계에서 ③ 이 빠진다"),
    ("A7 — `진행` · `닫힘` 줄 조건을 지운다(늘 받는다)",
     '    before_first = repo and not any(len(row) == 6 and row[4] in ("진행", "닫힘") for row in rows)\n',
     "    before_first = repo\n",
     "다른 레포 A7 첫 마스터플랜에 진행 줄 하나 — 폴더가 없다"),
    ("A2 — 다섯째 틀(claude-md.md)을 원천에서 뺀다",
     '    ("CLAUDE.md 의 칸", "claude-md.md"),\n',
     "",
     "다른 레포 A2 검사 옆 틀 claude-md.md 가 없다"),
    ("C1 — 입구가 없어도 지나간다",
     "    if why or not entry.is_file():\n",
     "    if False:\n",
     "다른 레포 C1 입구가 없다"),
    ("C2 — 의도를 가리키는지 보지 않는다",
     "    if intent and intent not in toks:\n",
     "    if False:\n",
     "다른 레포 C2 의도가 마크다운 링크"),
    ("C3 — 마스터플랜을 가리키는지 보지 않는다",
     "    if MASTER not in toks:\n",
     "    if False:\n",
     "다른 레포 C3 마스터플랜이 마크다운 링크"),
    ("A2 — 여섯째 틀(profile.md)을 원천에서 뺀다",
     '    ("Profile.md 의 칸", "profile.md"),\n',
     "",
     "다른 레포 A2 검사 옆 틀 profile.md 가 없다"),
    ("P1 — 프로필을 묻지 않는다",
     "        check_profile(r, root)\n",
     "",
     "다른 레포 P1 가져오는 줄이 백틱 하나"),
    ("P1 — 이름 검사를 걷는다",
     "    if why or not prof.is_file():\n",
     "    if False:\n",
     "다른 레포 P1 프로필이 폴더"),
    ("P1 — CLAUDE.local.md 를 읽지 않는다",
     'IMPORTERS = ("CLAUDE.md", "CLAUDE.local.md")\n',
     'IMPORTERS = ("CLAUDE.md",)\n',
     "다른 레포 R1 CLAUDE.local.md 가 UTF-8 이 아니면 P1 은 묻지 않는다"),
    ("P1 — 백틱 토막을 빼지 않는다",
     'IMPORT.search(QUOTE.sub("\\0", SPAN.sub("\\0", p)))',
     'IMPORT.search(QUOTE.sub("\\0", p))',
     "다른 레포 P1 가져오는 줄이 백틱 하나가 든 백틱 둘"),
    ("P1 — 백틱 토막을 백틱 하나로만 뺀다",
     'SPAN = re.compile(r"(?<!`)(`+)(?!`).*?(?<!`)\\1(?!`)", re.S)\n',
     'SPAN = re.compile(r"`[^`]+`")\n',
     "다른 레포 P1 가져오는 줄이 백틱 하나가 든 백틱 둘"),
    ("P1 — 앞뒤 경계를 보지 않는다",
     'return any(IMPORT.search(QUOTE.sub("\\0", SPAN.sub("\\0", p))) for p in paras)\n',
     'return any("@Profile.md" in QUOTE.sub("\\0", SPAN.sub("\\0", p)) for p in paras)\n',
     "다른 레포 P1 가져오는 줄이 붙은 마침표"),
    ("P1 — 따옴표 구간을 빼지 않는다",
     'QUOTE.sub("\\0", SPAN.sub("\\0", p))',
     'SPAN.sub("\\0", p)',
     "다른 레포 P1 가져오는 줄이 공백을 둔 큰따옴표"),
    ("P1 — 백틱 토막을 줄마다 뺀다",
     " for p in paras)",
     " for p in ls)",
     "다른 레포 P1 가져오는 줄이 줄을 넘는 백틱 토막"),
    ("P1 — 빈 줄에서 문단을 나누지 않는다",
     "        if ln.strip():\n",
     "        if True:\n",
     "다른 레포 대조 백틱 토막은 빈 줄을 넘지 못한다"),
    ("P1 — 가져오는 파일의 자리를 보지 않는다",
     "        if inside(root, name)[1] or not f.is_file():\n",
     "        if not f.is_file():\n",
     "다른 레포 P1 CLAUDE.local.md 가 밖을 가리키는 링크 — 그 밖 파일이 가져온다"),
    ("P1 — Profile.md 를 읽지 않는다",
     "    lines(prof)  # 읽지 못하면 [R1] — 줄의 뜻은 보지 않는다\n",
     "    pass\n",
     "다른 레포 R1 프로필이 UTF-8 이 아니다"),
    ("P1 — 읽지 못한 가져오는 파일을 없는 것으로 친다",
     "            unread = True\n",
     "            unread = False\n",
     "다른 레포 R1 CLAUDE.local.md 가 UTF-8 이 아니면 P1 은 묻지 않는다"),
    ("P1 — lines() 가 ``` 줄 머리만 안다",
     "        m = FENCE.match(ln)\n",
     '        m = re.match(r"^(```)(.*)$", ln)\n',
     "다른 레포 P1 가져오는 줄이 펜스 ~~~"),
    ("P1 — 백틱 펜스의 정보 문자열을 보지 않는다",
     '        if m and not (m.group(1)[0] == "`" and "`" in m.group(2)):\n',
     "        if m:\n",
     "다른 레포 대조 정보 문자열에 백틱이 든 ``` 줄은 펜스를 열지 않는다"),
    ("E1 — 출력을 UTF-8 로 고정하지 않는다",
     '        stream.reconfigure(encoding="utf-8")\n',
     "        pass\n",
     "다른 레포 E1 대조"),
]


WANT = (26, 1)  # (가) 변조본 · 대조군
CONTROL = "PASS 문서 대조 검사가 문다(다른 레포 모드만)"
# (R) 검사가 찍는 번호 — `.fail(<경로>, "<번호>"` 와 원천의 `"[A2] …"`.
CHECK_ID = re.compile(r'\.fail\([^,\n]+, "([A-Z][0-9]+)"|"\[([A-Z][0-9]+)\] ')
ID = re.compile(r"\[([A-Z][0-9]+)\]")
CUT = "A2"  # 이 번호를 기대한 변조본을 다 뺀 목록이 이 번호를 찍어야 한다


def check_ids(text):
    code = "\n".join(ln for ln in text.split("\n") if not ln.lstrip().startswith("#"))
    return {a or b for a, b in CHECK_ID.findall(code)}


def test_ids(t, drop=None):
    """자체 시험의 변조본 목록이 기대한 번호 — `drop` 을 기대한 변조본은 뺀다."""
    keep = lambda ids: drop not in ids
    out = set()
    for _, gid, _, _ in t.CASES:
        out |= {gid} if keep({gid}) else set()
    for need in [[n] for _, _, n, _ in t.QUIET] + [n for _, _, n in t.PROFILE_CASES] + [w for _, w, _ in t.R_CASES]:
        ids = {i for x in need for i in ID.findall(x)}
        out |= ids if keep(ids) else set()
    return out


def rules(text):
    """(R) — 실패 줄의 목록."""
    spec = importlib.util.spec_from_file_location("test_verify_docs", TEST)
    t = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(t)
    have, want = check_ids(text), test_ids(t)
    if not have or not want:
        return [f"검사의 번호({len(have)})나 자체 시험이 기대한 번호({len(want)})를 하나도 못 읽었다 — 읽는 법이 낡았다"]
    bad = []
    if have - want:
        bad.append(f"검사가 찍는 번호 {' '.join(sorted(have - want))} 를 기대한 변조본이 자체 시험에 없다")
    cut_gap = have - test_ids(t, CUT) - (have - want)  # 이미 빈 번호는 위에서 찍었다
    if CUT not in have - want and cut_gap != {CUT}:
        bad.append(f"{CUT} 를 기대한 변조본을 다 뺀 목록에서 번호 대조가 {CUT} 하나를 찍지 않았다: {sorted(cut_gap)}")
    if not bad:
        print(f"  번호마다: {len(have)} 개 다 변조본이 있다 · {CUT} 의 변조본을 뺀 목록은 {CUT} 를 찍는다")
    return bad


def run(copy, form=None):
    """자체 시험을 사본에 — (물었나, 종료 코드, 출력). `form` 이 없으면 대조군이다."""
    p = subprocess.run([sys.executable, str(TEST), "--repo-only", "--first", str(copy)], capture_output=True, text=True,
                       encoding="utf-8", errors="replace")
    lines = p.stdout.splitlines()
    clean = "Traceback (most recent call last)" not in p.stderr and "준비 실패" not in p.stdout
    if form is None:
        return p.returncode == 0 and clean and any(ln.startswith(CONTROL) for ln in lines), p.returncode, p.stdout + p.stderr
    # (나) 준비 실패 · 다른 꼴 · 시험 자신의 예외를 「물었다」로 세지 않는다 — 그 꼴이 다른 레포 모드의 판정으로 떨어졌어야 한다.
    hit = (p.returncode == 1 and clean and any(ln.startswith("FAIL — ") for ln in lines)
           and any(ln.startswith(f"  - {form}: ") for ln in lines))
    return hit, p.returncode, p.stdout + p.stderr


def main():
    text = CHECK.read_text(encoding="utf-8")
    bad = []
    ran = [0, 0]
    with tempfile.TemporaryDirectory() as t, concurrent.futures.ThreadPoolExecutor(os.cpu_count() or 1) as pool:
        # 대조군 — 바꾸지 않은 검사를 변조본과 같은 길로. 끝까지 돌아 종료 0 과 PASS 줄이어야 한다(② P4 · 조각 41 ② K).
        same = pathlib.Path(t) / "control.py"
        same.write_text(text, encoding="utf-8")
        ok, rc, out = pool.submit(run, same).result()
        ran[1] += 1
        if not ok:
            print(f"FAIL bite-verify-docs.py — 대조군(바꾸지 않은 검사)이 종료 0 과 「{CONTROL}」 줄로 지나가지 않았다(exit {rc}) — 깃발이나 함께 돌리는 길이 망가졌다")
            print(out[-600:])
            return 1
        print("  대조군: 바꾸지 않은 검사는 PASS · 물지 않았다")

        bad += rules(text)

        jobs = []
        for i, (what, old, new, form) in enumerate(MUTANTS):
            if (n := text.count(old)) != 1:
                bad.append(f"{what} — 망가뜨릴 자리가 검사에 {n} 번 있다(꼭 한 번이어야 한다): {old.strip()}")
                continue
            copy = pathlib.Path(t) / f"mutant-{i}.py"
            copy.write_text(text.replace(old, new), encoding="utf-8")
            jobs.append((what, form, pool.submit(run, copy, form)))
        for what, form, job in jobs:
            hit, rc, _ = job.result()
            ran[0] += 1
            if hit:
                print(f"  물었다: {what} — {form}")
            else:
                bad.append(f"{what} — 자체 시험이 「{form}」 꼴로 떨어뜨리지 않았다(exit {rc})")
    if tuple(ran) != WANT:
        bad.append(f"변조본 {ran[0]} · 대조군 {ran[1]} 이 돌았다, {WANT[0]} · {WANT[1]} 이어야 한다")
    if bad:
        print(f"FAIL bite-verify-docs.py — {len(bad)}")
        for b in bad:
            print(f"  {b}")
        return 1
    print(f"PASS bite-verify-docs.py — 변조본 {ran[0]} 다 그 꼴로 떨어지고 대조군 {ran[1]} 은 지나갔다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
