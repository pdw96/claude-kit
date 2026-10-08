#!/usr/bin/env python3
"""`verify-docs.py` 의 자체 시험이 다른 레포 모드에서 무는지 본다 — 검사의 다른 레포 모드를 한 자리씩 망가뜨린 사본에
자체 시험을 대어 다 떨어지는지. 모델도 네트워크도 안 쓴다.

  python3 scripts/bite-verify-docs.py

**왜 여기 있나.** 원본 모드의 변조 스무 자리는 CI 「게이트가 무는가」(`eval.yml`)에 있지만, `eval.yml` 은 수트 지문에
들어 고치면 route 수트가 돈다. 이 파일은 지문 밖이고 `gates.sh` 가 부른다(ADR 0018 의 6, 조각 9 설계 ② V1).
`bite-slice-gate.py` 와 같은 길이다.

떨어지는 것 둘 — 자체 시험이 망가진 사본 하나라도 지나가면(시험을 비우거나 무르게 했다), 망가뜨릴 자리가
검사에 꼭 한 번 있지 않으면(검사를 고치며 여기를 따라 고치지 않았다).

표준 라이브러리만 쓴다.
"""
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHECK = ROOT / "scripts" / "verify-docs.py"
TEST = ROOT / "scripts" / "test-verify-docs.py"

# (설계 ② 의 번호 — 무엇을 망가뜨리나, 검사의 글자, 바꿀 글자)
MUTANTS = [
    ("A5 — `--repo` 를 무시해 원본 모드로 간다",
     "    tpl = side_templates() if repo else None\n",
     "    tpl = None\n"),
    ("A1 — 틀의 원천을 빈 목록으로 읽는다",
     "        found = headings(lines(p))\n",
     "        found = []\n"),
    ("A2 — 빈 원천의 거절을 지운다",
     "        if not found:\n",
     "        if False:\n"),
    ("A3 — 다른 레포 모드에서도 T1 · T2 를 본다",
     "        schema = check_sources(r, tpl)\n",
     "        schema = check_sources(r, tpl)\n        check_templates(r, root, schema)\n"),
    ("A1 — 원천을 검사 옆이 아니라 루트의 vibe-slice/…/templates/ 에서 찾는다",
     "    tpl = side_templates() if repo else None\n",
     "    tpl = root / TEMPLATES if repo else None\n"),
    ("A7 — `진행` · `닫힘` 줄 조건을 지운다(늘 받는다)",
     '    before_first = repo and not any(len(row) == 6 and row[4] in ("진행", "닫힘") for row in rows)\n',
     "    before_first = repo\n"),
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
            # 준비 실패 같은 다른 까닭의 exit 1 을 「물었다」로 세지 않는다 — 다른 레포 모드의 꼴이 판정으로 떨어졌어야 한다.
            judged = [ln for ln in p.stdout.splitlines() if ln.startswith("  - 다른 레포 ") and "준비 실패" not in ln]
            if p.returncode != 1 or "준비 실패" in p.stdout or not judged:
                bad.append(f"{what} — 자체 시험이 망가진 검사를 다른 레포 모드의 판정으로 떨어뜨리지 않았다(exit {p.returncode})")
            else:
                print(f"  물었다: {what}")
    if bad:
        print(f"FAIL bite-verify-docs.py — {len(bad)}")
        for b in bad:
            print(f"  {b}")
        return 1
    print(f"PASS bite-verify-docs.py — 변조본 {len(MUTANTS)} 다 자체 시험에서 떨어졌다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
