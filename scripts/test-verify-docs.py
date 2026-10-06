#!/usr/bin/env python3
"""`verify-docs.py` 가 무는지 본다 — 변조본마다 떨어지고, 대조는 통과하는가. 모델도 네트워크도 git 도 안 쓴다.

  python3 scripts/test-verify-docs.py                 # 저장소의 검사
  python3 scripts/test-verify-docs.py <검사 경로>       # 다른 판 — CI 가 망가뜨린 사본으로 쓴다

**시험의 틀** (`docs/slices/3-doc-check/design.md` ⑤)

- 작업트리를 `.git` 없이 임시 폴더로 한 번 베끼고, 조각 나눔에 **과녁 줄 둘**을 더한다 — 시험 진행 조각
  (`docs/slices/99-test/`, 틀을 베낀 두 파일)과 시험 예정 조각. 저장소의 `예정` · `진행` 줄은 조각을 꺼내고
  닫을 때마다 바뀌므로 과녁으로 쓰지 않는다. `닫힘` 쪽 과녁은 바뀌지 않는 닫힌 줄 둘이다.
- 변조본마다 그 바탕을 하드 링크로 떠서 쓴다 — 파일을 베끼는 것보다 일곱 배쯤 빠르다. 그래서 변조는 파일을
  제자리에서 고치지 않고 **새 파일로 바꿔 끼운다**(`write`). 제자리에서 고치면 바탕과 다른 변조본까지 바뀐다.
  끝에 바탕을 다시 돌려 그대로인지 본다.
- 변조본마다 바꿀 자리는 글자 그대로 **한 번만** 나와야 한다 — 아니면 시험이 떨어진다.
- 변조본마다 종료코드 1 · `Traceback` 없음 · 출력에 기대한 파일과 **보장 번호**가 다 있어야 한다. 다른
  규칙이나 예외로 떨어진 것은 통과로 세지 않는다.

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
MP = "docs/master-plan.md"
PROC = "docs/procedure.md"
GO = "| — | 시험 진행 조각 | 시험 | — | 진행 | `docs/slices/99-test/` |"
PLAN = "| — | 시험 예정 조각 | 시험 | — | 예정 | — |"
TEST = "docs/slices/99-test"
SLICE1 = "| 1 | 사본 비교 · 되먹임 |"
SLICE2 = "| 2 | 절차 지도 |"


class Setup(Exception):
    """변조할 자리가 없거나 겹친다 — 저장소가 바뀌었으니 시험을 맞춰 고쳐야 한다."""


def write(p, text):
    """새 파일로 바꿔 끼운다 — 하드 링크로 나눈 바탕을 건드리지 않는다."""
    tmp = p.with_name(p.name + ".new")
    tmp.write_text(text, encoding="utf-8")
    os.replace(tmp, p)


def sub(t, rel, old, new):
    p = t / rel
    s = p.read_text(encoding="utf-8")
    if s.count(old) != 1:
        raise Setup(f"{rel} 에 바꿀 자리 {old!r} 가 {s.count(old)} 번 있다")
    write(p, s.replace(old, new))


def row_of(t, head):
    """조각 나눔에서 `head` 로 시작하는 줄 — 칸을 바꾸는 변조본이 그 줄 전체를 바꿔 쓴다."""
    hits = [ln for ln in (t / MP).read_text(encoding="utf-8").splitlines() if ln.startswith(head)]
    if len(hits) != 1:
        raise Setup(f"{MP} 에 `{head}` 로 시작하는 줄이 {len(hits)} 개다")
    return hits[0]


def set_cell(t, head, i, value):
    ln = row_of(t, head)
    cells = ln.strip().strip("|").split("|")
    cells[i] = f" {value} "
    sub(t, MP, ln, "|" + "|".join(cells) + "|")


def append(t, rel, text):
    p = t / rel
    write(p, p.read_text(encoding="utf-8") + text)


def swap(t, rel, a, b):
    sub(t, rel, a, "\0")
    sub(t, rel, b, a)
    sub(t, rel, "\0", b)


def add_rows(t, *rows):
    sub(t, MP, PLAN, PLAN + "".join("\n" + r for r in rows))


def base(dst):
    shutil.copytree(ROOT, dst, symlinks=True, ignore=shutil.ignore_patterns(".git", "results", "__pycache__"))
    p = dst / MP
    ls = p.read_text(encoding="utf-8").splitlines()
    i = ls.index("## 조각 나눔")
    while not ls[i].startswith("|"):
        i += 1
    while i < len(ls) and ls[i].startswith("|"):
        i += 1
    ls[i:i] = [GO, PLAN]
    write(p, "\n".join(ls) + "\n")
    (dst / TEST).mkdir()
    for f in ("requirements.md", "design.md"):
        shutil.copy(dst / "docs/templates" / f, dst / TEST / f)


def outside_link(t, rel):
    """`rel` 을 루트 밖 파일을 가리키는 링크로 바꾼다."""
    far = t.parent / f"outside-{rel.replace('/', '-')}"
    write(far, (t / rel).read_text(encoding="utf-8"))
    (t / rel).unlink()
    os.symlink(far, t / rel)


# (이름, 기대 번호, 기대 파일, 변조) — 번호는 설계 ② 의 보장. 이름은 설계 ⑤ 의 표를 따른다.
CASES = [
    ("O1 절 이름이 바뀌고 그 틀도 없다", "O1", PROC, lambda t: (
        sub(t, PROC, "### 요구사항 문서의 칸\n", "### 요구사항 문서의 칸들\n"),
        (t / "docs/templates/requirements.md").unlink())),
    ("O1 절이 두 번", "O1", PROC, lambda t: append(
        t, PROC, "\n### 요구사항 문서의 칸\n\n| 제목 | 담는 것 |\n|---|---|\n| `## 다른` | x |\n")),
    ("O2 표가 빈다", "O2", PROC, lambda t: [
        sub(t, PROC, f"| `## {h}` |", f"| ## {h} |")
        for h in ("① 바뀌는 것", "② 보장하는 것 / 보장하지 않는 것", "③ 받는 입력",
                  "④ 결정", "⑤ 검증 계획", "⑥ PR 나눔")]),
    ("O3 절차 지도가 없다", "O3", PROC, lambda t: (t / PROC).unlink()),
    ("O3 마스터플랜이 없다", "O3", MP, lambda t: (t / MP).unlink()),
    ("O3 빈 루트", "O3", PROC, lambda t: [
        shutil.rmtree(x) if x.is_dir() and not x.is_symlink() else x.unlink() for x in list(t.iterdir())]),
    *[(f"T1 틀 {f} 이 없다", "T1", f"docs/templates/{f}",
       (lambda f: lambda t: (t / "docs/templates" / f).unlink())(f))
      for f in ("intent.md", "master-plan.md", "requirements.md", "design.md")],
    ("T2 틀 제목 한 글자", "T2", "docs/templates/intent.md",
     lambda t: sub(t, "docs/templates/intent.md", "\n## Why\n", "\n## Whi\n")),
    ("T2 틀에 제목 더함", "T2", "docs/templates/design.md",
     lambda t: append(t, "docs/templates/design.md", "\n## 덤\n")),
    ("T2 틀의 제목 순서", "T2", "docs/templates/master-plan.md",
     lambda t: swap(t, "docs/templates/master-plan.md", "\n## 조각 나눔\n", "\n## 범위 변경\n")),
    ("T2 원천 표에 제목 더함", "T2", "docs/templates/design.md", lambda t: sub(
        t, PROC, "| `## ⑥ PR 나눔` |", "| `## ⑦ 덤` | x |\n| `## ⑥ PR 나눔` |")),
    ("I1 의도 줄이 없다", "I1", MP,
     lambda t: sub(t, MP, "| 의도 — 목표 · 범위 · 하지 않을 일 | `INTENT.md` |\n", "")),
    ("I1 의도 줄이 둘", "I1", MP, lambda t: sub(
        t, MP, "| 의도 — 목표 · 범위 · 하지 않을 일 | `INTENT.md` |\n",
        "| 의도 — 목표 · 범위 · 하지 않을 일 | `INTENT.md` |\n| 의도의 근거 | `INTENT.md` |\n")),
    ("I2 의도 줄이 없음", "I2", MP, lambda t: sub(
        t, MP, "| 의도 — 목표 · 범위 · 하지 않을 일 | `INTENT.md` |", "| 의도 — 목표 · 범위 · 하지 않을 일 | 없음 — 의도 문서 없음 |")),
    ("I2 의도 줄이 폴더", "I2", MP, lambda t: sub(
        t, MP, "| 의도 — 목표 · 범위 · 하지 않을 일 | `INTENT.md` |", "| 의도 — 목표 · 범위 · 하지 않을 일 | `docs/` |")),
    ("I2 의도 줄이 없는 파일", "I2", MP, lambda t: sub(
        t, MP, "| 의도 — 목표 · 범위 · 하지 않을 일 | `INTENT.md` |", "| 의도 — 목표 · 범위 · 하지 않을 일 | `NOPE.md` |")),
    ("I2 의도 파일이 밖을 가리키는 링크", "I2", MP, lambda t: outside_link(t, "INTENT.md")),
    ("I3 제목 한 글자", "I3", "INTENT.md", lambda t: sub(t, "INTENT.md", "\n## Not\n", "\n## Non\n")),
    ("I3 제목이 펜스 안", "I3", "INTENT.md", lambda t: sub(t, "INTENT.md", "\n## Why\n", "\n```\n## Why\n```\n")),
    ("I3 제목이 주석 안", "I3", "INTENT.md", lambda t: sub(t, "INTENT.md", "\n## Why\n", "\n<!--\n## Why\n-->\n")),
    ("I3 제목 순서", "I3", "INTENT.md", lambda t: swap(t, "INTENT.md", "\n## Why\n", "\n## What\n")),
    ("M1 범위 변경이 없다", "M1", MP, lambda t: sub(t, MP, "\n## 범위 변경\n", "\n")),
    ("M1 제목 순서", "M1", MP, lambda t: swap(t, MP, "\n## 조각 나눔\n", "\n## 범위 변경\n")),
    ("M2 없는 파일", "M2", MP, lambda t: sub(t, MP, "| 설치와 배포 경로 | `README.md`", "| 설치와 배포 경로 | `NOPE.md`")),
    ("M2 `—` 없는 없음", "M2", MP, lambda t: sub(t, MP, "| 데이터 모델 | `docs/schema.md`", "| 데이터 모델 | `없음`")),
    ("M2 저장소 밖", "M2", MP, lambda t: sub(t, MP, "| 데이터 모델 | `docs/schema.md`", "| 데이터 모델 | `../INTENT.md`")),
    ("M2 밖을 가리키는 링크", "M2", MP, lambda t: outside_link(t, "AGENTS.md")),
    ("S1 칸 하나 더", "S1", MP, lambda t: sub(t, MP, GO, GO + " 덤 |")),
    ("S2 순서 3a", "S2", MP, lambda t: set_cell(t, PLAN, 0, "3a")),
    ("S3 이름이 빈다", "S3", MP, lambda t: set_cell(t, PLAN, 1, "")),
    ("S3 이름이 —", "S3", MP, lambda t: set_cell(t, PLAN, 1, "—")),
    ("S3 이름이 겹친다", "S3", MP, lambda t: set_cell(t, PLAN, 1, "시험 진행 조각")),
    ("S4 상태 완료", "S4", MP, lambda t: set_cell(t, PLAN, 4, "완료")),
    ("S5 없는 이름", "S5", MP, lambda t: set_cell(t, PLAN, 3, "없는 조각")),
    ("S5 읽는 길이 둘", "S5", MP, lambda t: (
        add_rows(t, "| — | A | x | — | 예정 | — |", "| — | B | x | — | 예정 | — |", "| — | A · B | x | — | 예정 | — |"),
        set_cell(t, PLAN, 3, "A · B"))),
    ("S6 진행 조각이 예정을 의존", "S6", MP, lambda t: set_cell(t, GO, 3, "시험 예정 조각")),
    ("S6 닫힌 조각이 예정을 의존", "S6", MP, lambda t: set_cell(t, SLICE2, 3, "시험 예정 조각")),
    ("S6 자기 의존", "S6", MP, lambda t: set_cell(t, SLICE2, 3, "절차 지도")),
    ("S7 끝 / 없음", "S7", MP, lambda t: set_cell(t, GO, 5, "`docs/slices/99-test`")),
    ("S7 숫자 없음", "S7", MP, lambda t: set_cell(t, GO, 5, "`docs/slices/test/`")),
    ("S7 토막 둘", "S7", MP, lambda t: set_cell(t, GO, 5, "`docs/slices/99-test/` `docs/slices/98-x/`")),
    ("S8 예정 조각에 폴더", "S8", MP, lambda t: set_cell(t, PLAN, 5, "`docs/slices/98-plan/`")),
    ("S8 진행 조각의 폴더 칸이 —", "S8", MP, lambda t: set_cell(t, GO, 5, "—")),
    ("S8 진행 조각의 폴더가 없다", "S8", MP, lambda t: shutil.rmtree(t / TEST)),
    ("S8 폴더가 고리 링크", "S8", MP, lambda t: (
        os.symlink("98-loop", t / "docs/slices/98-loop"),
        add_rows(t, "| — | 고리 링크 | x | — | 닫힘 | `docs/slices/98-loop/` |"))),
    ("S9 두 줄이 한 폴더", "S9", MP, lambda t: add_rows(
        t, "| — | 겹친 조각 | x | — | 닫힘 | `docs/slices/1-copy-comparison/` |")),
    ("S9 링크로 같은 폴더", "S9", MP, lambda t: (
        os.symlink("1-copy-comparison", t / "docs/slices/98-alias"),
        add_rows(t, "| — | 별칭 조각 | x | — | 닫힘 | `docs/slices/98-alias/` |"))),
    ("S10 닫힌 두 조각의 고리", "S10", MP, lambda t: (
        set_cell(t, SLICE2, 3, "사본 비교 · 되먹임"), set_cell(t, SLICE1, 3, "절차 지도"))),
    ("S10 예정 두 조각의 고리", "S10", MP, lambda t: (
        add_rows(t, "| — | 고리 예정 | x | 시험 예정 조각 | 예정 | — |"), set_cell(t, PLAN, 3, "고리 예정"))),
    ("F1 주인 없는 폴더", "F1", "docs/slices/9-x", lambda t: (t / "docs/slices/9-x").mkdir()),
    ("F2 설계가 없다", "F2", f"{TEST}/design.md", lambda t: (t / TEST / "design.md").unlink()),
    ("F2 요구사항이 없다", "F2", f"{TEST}/requirements.md", lambda t: (t / TEST / "requirements.md").unlink()),
    ("F3 설계 제목이 빠진다", "F3", f"{TEST}/design.md",
     lambda t: sub(t, f"{TEST}/design.md", "\n## ③ 받는 입력\n", "\n")),
    ("F3 요구사항 제목 순서", "F3", f"{TEST}/requirements.md",
     lambda t: swap(t, f"{TEST}/requirements.md", "\n## 문제\n", "\n## 제약\n")),
    ("F4 진행 조각에 닫으며", "F4", f"{TEST}/requirements.md",
     lambda t: append(t, f"{TEST}/requirements.md", "\n## 닫으며 (2026-10-06)\n")),
    ("F5 닫으며에 날짜가 없다", "F5", "docs/slices/1-copy-comparison/requirements.md",
     lambda t: sub(t, "docs/slices/1-copy-comparison/requirements.md", "\n## 닫으며 (2026-10-06)\n", "\n## 닫으며\n")),
    ("F5 닫힌 조각의 요구사항이 없다", "F5", "docs/slices/1-copy-comparison/requirements.md",
     lambda t: (t / "docs/slices/1-copy-comparison/requirements.md").unlink()),
]

# (이름, 변조) — 통과해야 한다. 다 떨어뜨리는 검사도 무는 것처럼 보이므로.
CONTROLS = [
    ("의도를 다른 문서가 든다(ADR 0010)", lambda t: (
        sub(t, MP, "| 의도 — 목표 · 범위 · 하지 않을 일 | `INTENT.md` |", "| 의도 — 목표 · 범위 · 하지 않을 일 | `PRD.md` |"),
        write(t / "PRD.md", "# PRD\n\n## 문제\n\n## 범위\n"))),
    ("요구사항 사이 · 뒤의 절과 설계 끝의 덧붙임", lambda t: (
        sub(t, f"{TEST}/requirements.md", "\n## 성공 기준\n", "\n## 덧붙인 절\n\n## 성공 기준\n"),
        append(t, f"{TEST}/requirements.md", "\n## 로드맵의 근거\n"),
        append(t, f"{TEST}/design.md", "\n## 2026-10-07 — 열어 둔 것을 정한다\n"))),
    ("감싼 `없음 — <이유>` 와 이유 안의 토막", lambda t: sub(
        t, MP, "| 데이터 모델 | `docs/schema.md`", "| 데이터 모델 | `없음 — 구조는 `README.md` 가 대신 든다`")),
    ("감싸지 않은 `없음 — <이유>`", lambda t: sub(
        t, MP, "| 데이터 모델 | `docs/schema.md`", "| 데이터 모델 | 없음 — 대장 둘은 `NOPE.md` 가 든다")),
    ("진행 조각에 「닫으며」로 시작하는 다른 절", lambda t: append(
        t, f"{TEST}/requirements.md", "\n## 닫으며 생각할 것\n")),
    ("긴 의존 사슬(1,100 줄) — 깊이 한도에 걸리지 않는다", lambda t: add_rows(
        t, *(f"| — | 사슬 {k} | x | {f'사슬 {k + 1}' if k < 1099 else '—'} | 예정 | — |" for k in range(1100)))),
    ("닫힌 조각의 지난 모양", lambda t: (
        sub(t, "docs/slices/2-procedure-map/design.md", "\n## ③ 받는 입력\n", "\n"),
        sub(t, "docs/slices/2-procedure-map/requirements.md", "\n## 제약\n", "\n"))),
    ("시험 진행 조각을 닫는다", lambda t: (
        set_cell(t, GO, 4, "닫힘"),
        append(t, f"{TEST}/requirements.md", "\n## 닫으며 (2026-10-07)\n"))),
]


def run(checker, root):
    p = subprocess.run([sys.executable, str(checker), str(root)], capture_output=True, text=True)
    return p.returncode, p.stdout + p.stderr


def main():
    checker = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / "scripts" / "verify-docs.py"
    fails, passes = [], 0

    rc, out = run(checker, ROOT)
    if rc == 0:
        passes += 1
    else:
        fails.append(f"C0 저장소 그대로가 떨어졌다 — {out[-400:]}")

    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        bed = tmp / "base" / "root"
        base(bed)
        n = 0

        def fresh():
            nonlocal n
            n += 1
            box = tmp / f"case{n}"
            box.mkdir()
            t = box / "root"
            shutil.copytree(bed, t, symlinks=True, copy_function=os.link)
            return t

        rc, out = run(checker, bed)
        if rc == 0:
            passes += 1
        else:
            fails.append(f"C0 과녁 줄 둘을 더한 트리가 떨어졌다 — {out[-400:]}")

        for name, gid, rel, mutate in CASES:
            t = fresh()
            try:
                mutate(t)
            except Setup as e:
                fails.append(f"{name}: 준비 실패 — {e}")
                continue
            rc, out = run(checker, t)
            if rc == 1 and "Traceback" not in out and f"{rel}: [{gid}]" in out:
                passes += 1
            else:
                fails.append(f"{name}: `{rel}: [{gid}]` 로 떨어지지 않았다 (종료코드 {rc}) — {out[-300:]}")

        t = fresh()
        sub(t, PROC, "| `## ⑥ PR 나눔` |", "| `## ⑦ 덤` | x |\n| `## ⑥ PR 나눔` |")
        rc, out = run(checker, t)
        want = f"{TEST}/design.md: [F3]"
        if want in out and "docs/slices/2-procedure-map/design.md" not in out:
            passes += 1
        else:
            fails.append(f"원천 표에 제목을 더하면 진행 조각의 설계만 떨어져야 한다 — {out[-300:]}")

        for name, mutate in CONTROLS:
            t = fresh()
            try:
                mutate(t)
            except Setup as e:
                fails.append(f"대조 {name}: 준비 실패 — {e}")
                continue
            rc, out = run(checker, t)
            if rc == 0:
                passes += 1
            else:
                fails.append(f"대조 {name}: 통과해야 하는데 떨어졌다 — {out[-300:]}")

        rc, out = run(checker, bed)
        if rc == 0:
            passes += 1
        else:
            fails.append(f"바탕이 변조본에 물들었다 — 어느 변조가 파일을 제자리에서 고쳤다 — {out[-300:]}")

    if fails:
        print(f"FAIL — 문서 대조 검사의 자체 시험 {len(fails)} 개가 어긋났다")
        for f in fails:
            print(f"  - {f}")
        return 1
    print(f"PASS 문서 대조 검사가 문다 — 변조본 {len(CASES)} · 대조 {len(CONTROLS)} · 원천 1 · 지금 모양 3, 모두 {passes}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
