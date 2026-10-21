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

**다른 레포 모드의 꼴** (`docs/slices/9-repo-doc-check/design.md` ② A · ⑤)

- 틀 여섯으로 세운 임시 레포(지도도 `vibe-slice/` 도 없다)에 `--repo` 로 댄다. 의도 줄은 `PRD.md`, 조각은 닫힌 것 ·
  진행 · 예정 하나씩이고, 맨 위에 그 둘을 가리키는 입구 `CLAUDE.md` 가 있다(조각 30 설계 ② C1 ~ C3).
- 받은 검사(인자로 받은 사본도)를 꼴마다 임시 스킬 폴더 `<임시>/slice-docs/scripts/` 에 베끼고 `templates/` 에 이
  저장소의 틀 여섯을 둔다(V2) — 검사가 제 옆의 틀을 찾으므로, 망가뜨린 사본이 틀을 못 찾아 엉뚱한 까닭으로 떨어지지 않는다.

**프로필의 꼴** (`docs/slices/31-profile/design.md` ② P1 · ⑤ V1 · V2)

- 두 모드가 같은 꼴 목록(`PROFILE_CASES` · `PROFILE_CONTROLS`)을 쓴다 — 이 저장소 모드는 베낀 트리, 다른 레포 모드는 임시
  레포에 `Profile.md` 를 두고 `CLAUDE.md` · `CLAUDE.local.md` 를 바꾼다.
- 거절 꼴은 exit 1 · 기대한 줄이 다 있고 · 출력의 번호가 기대한 번호뿐임을 본다 — 서지 않아야 할 번호(읽지 못한 가져오는
  파일의 P1 따위)가 서면 떨어진다. 성공 꼴은 exit 0 이다.

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
TPL = "vibe-slice/skills/slice-docs/templates"
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
        shutil.copy(dst / TPL / f, dst / TEST / f)


ENTRY = "CLAUDE.md"


def retoken(t, tok, form, tail=""):
    """입구의 백틱 토막 `tok` 을 모두 `form` 으로 바꾸고 끝에 `tail` 을 붙인다 — ③ 의 거절 꼴(조각 30 설계 ⑤ V1)."""
    p = t / ENTRY
    s = p.read_text(encoding="utf-8")
    if f"`{tok}`" not in s:
        raise Setup(f"{ENTRY} 에 `{tok}` 토막이 없다")
    write(p, s.replace(f"`{tok}`", form) + tail)


# ③ 의 거절 꼴 — (이름, 토막을 바꿀 꼴, 끝에 붙일 것). `{t}` 는 그 경로다.
REFUSED = [
    ("마크다운 링크", "[가리킴]({t})", ""),
    ("맨 글자", "{t}", ""),
    ("다른 글자가 섞인 토막", "`{t} 를 본다`", ""),
    ("./ 이 붙은 토막", "`./{t}`", ""),
    ("펜스 안의 토막", "{t}", "\n```\n`{t}`\n```\n"),
    ("주석 안의 토막", "{t}", "\n<!--\n`{t}`\n-->\n"),
]


def refused(t, tok, form, tail):
    retoken(t, tok, form.format(t=tok), tail.format(t=tok))


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
        (t / TPL / "requirements.md").unlink())),
    ("O1 절이 두 번", "O1", PROC, lambda t: append(
        t, PROC, "\n### 요구사항 문서의 칸\n\n| 제목 | 담는 것 |\n|---|---|\n| `## 다른` | x |\n")),
    ("O2 표가 빈다", "O2", PROC, lambda t: [
        sub(t, PROC, f"| `## {h}` |", f"| ## {h} |")
        for h in ("① 바뀌는 것", "② 보장하는 것 / 보장하지 않는 것", "③ 받는 입력",
                  "④ 결정", "⑤ 검증 계획", "⑥ PR 나눔")]),
    ("O1 「CLAUDE.md 의 칸」 절 이름이 바뀐다", "O1", PROC,
     lambda t: sub(t, PROC, "### CLAUDE.md 의 칸\n", "### CLAUDE.md 칸\n")),
    ("O1 「Profile.md 의 칸」 절이 없다", "O1", PROC,
     lambda t: sub(t, PROC, "### Profile.md 의 칸\n", "### 프로필의 칸\n")),
    ("O2 「Profile.md 의 칸」 표에 제목 줄이 없다", "O2", PROC, lambda t: [
        sub(t, PROC, f"| `## {h}` |", f"| ## {h} |") for h in ("수준", "결정을 가르는 법", "설명하는 법")]),
    ("O3 절차 지도가 없다", "O3", PROC, lambda t: (t / PROC).unlink()),
    ("O3 마스터플랜이 없다", "O3", MP, lambda t: (t / MP).unlink()),
    ("O3 빈 루트", "O3", PROC, lambda t: [
        shutil.rmtree(x) if x.is_dir() and not x.is_symlink() else x.unlink() for x in list(t.iterdir())]),
    *[(f"T1 틀 {f} 이 없다", "T1", f"{TPL}/{f}",
       (lambda f: lambda t: (t / TPL / f).unlink())(f))
      for f in ("intent.md", "master-plan.md", "claude-md.md", "profile.md", "requirements.md", "design.md")],
    ("T2 틀 제목 한 글자", "T2", TPL + "/intent.md",
     lambda t: sub(t, TPL + "/intent.md", "\n## Why\n", "\n## Whi\n")),
    ("T2 틀에 제목 더함", "T2", TPL + "/design.md",
     lambda t: append(t, TPL + "/design.md", "\n## 덤\n")),
    ("T2 틀의 제목 순서", "T2", TPL + "/master-plan.md",
     lambda t: swap(t, TPL + "/master-plan.md", "\n## 조각 나눔\n", "\n## 범위 변경\n")),
    ("T2 틀 claude-md.md 의 제목 한 글자", "T2", TPL + "/claude-md.md",
     lambda t: sub(t, TPL + "/claude-md.md", "\n## 금지\n", "\n## 금기\n")),
    ("T2 틀 profile.md 의 제목 한 글자", "T2", TPL + "/profile.md",
     lambda t: sub(t, TPL + "/profile.md", "\n## 수준\n", "\n## 수줌\n")),
    ("M1 ~~~ 펜스 안의 제목은 제목이 아니다", "M1", MP,
     lambda t: sub(t, MP, "\n## 조각 나눔\n", "\n~~~\n## 조각 나눔\n~~~\n")),
    ("T2 원천 표에 제목 더함", "T2", TPL + "/design.md", lambda t: sub(
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
    ("R1 의도 문서가 UTF-8 이 아니다", "R1", "INTENT.md", lambda t: (
        (t / "INTENT.md").unlink(), (t / "INTENT.md").write_bytes(b"\xff\xfe## Why\n"))),
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
    ("C1 입구가 없다", "C1", ENTRY, lambda t: (t / ENTRY).unlink()),
    ("C1 입구가 폴더", "C1", ENTRY, lambda t: ((t / ENTRY).unlink(), (t / ENTRY).mkdir())),
    ("C1 입구가 밖을 가리키는 링크", "C1", ENTRY, lambda t: outside_link(t, ENTRY)),
    *[(f"C2 의도가 {name}", "C2", ENTRY, (lambda f, a: lambda t: refused(t, "INTENT.md", f, a))(form, tail))
      for name, form, tail in REFUSED],
    *[(f"C3 마스터플랜이 {name}", "C3", ENTRY, (lambda f, a: lambda t: refused(t, "docs/master-plan.md", f, a))(form, tail))
      for name, form, tail in REFUSED],
]

# (이름, 변조, 있어야 할 줄 머리, 없어야 할 번호) — 묻지 않아야 할 자리(조각 30 설계 ⑤ V1).
QUIET = [
    ("의도 줄이 I2 로 떨어지면 C2 를 묻지 않는다", lambda t: sub(
        t, MP, "| 의도 — 목표 · 범위 · 하지 않을 일 | `INTENT.md` |", "| 의도 — 목표 · 범위 · 하지 않을 일 | `NOPE.md` |"),
     f"{MP}: [I2]", ["[C2]"]),
    ("입구가 없으면 C2 · C3 를 묻지 않는다", lambda t: (t / ENTRY).unlink(), f"{ENTRY}: [C1]", ["[C2]", "[C3]"]),
    ("의도 문서가 I3 로 떨어져도 C2 는 묻는다", lambda t: (
        sub(t, "INTENT.md", "\n## Not\n", "\n## Non\n"), retoken(t, "INTENT.md", "INTENT.md")),
     f"{ENTRY}: [C2]", []),
]

# ── 프로필(조각 31 설계 ② P1 · ③) — 두 모드가 같이 쓴다 ──────────────────────────

PROFILE = "Profile.md"
LOCAL = "CLAUDE.local.md"
# 실물의 꼴 — pdw96/ERP#125(`fb160d9`) `CLAUDE.md` 「작업 방식」의 한 줄(조각 31 설계 ③).
IMPORTS = "\n- **설명하고 결정을 묻는 법은 소유자 프로필을 따른다** — @Profile.md\n"


def add(t, rel, text):
    """`rel` 끝에 붙인다 — 없으면 새로 쓴다."""
    p = t / rel
    write(p, (p.read_text(encoding="utf-8") if p.is_file() else "") + text)


def profile(t, where=ENTRY, line=IMPORTS):
    """맨 위에 틀 모양의 프로필을 두고 `where` 에 `line` 을 붙인다(`where` 가 None 이면 붙이지 않는다)."""
    write(t / PROFILE, (ROOT / TPL / "profile.md").read_text(encoding="utf-8"))
    if where:
        add(t, where, line)


def outside(t, rel, text):
    """`rel` 을 루트 밖의 `text` 파일을 가리키는 링크로 둔다."""
    far = t.parent / f"outside-{rel.replace('/', '-')}"
    write(far, text)
    if os.path.lexists(t / rel):
        (t / rel).unlink()
    os.symlink(far, t / rel)


def not_utf8(t, rel, head=b"## x\n"):
    if os.path.lexists(t / rel):
        (t / rel).unlink()
    (t / rel).write_bytes(b"\xff\xfe" + head)


# ③ 의 거절 꼴 — (이름, `CLAUDE.md` 끝에 붙일 것). 하나도 가져오는 줄로 읽히지 않아야 한다.
NOT_IMPORTS = [
    ("백틱 하나", "\n- 프로필은 `@Profile.md`\n"),
    ("백틱 둘", "\n- 프로필은 ``@Profile.md``\n"),
    ("백틱 하나가 든 백틱 둘", "\n- 프로필은 ``x` @Profile.md ``\n"),
    ("백틱 셋 — 줄 머리에서도 펜스가 아니다", "\n```@Profile.md```\n"),
    ("따옴표", '\n- 프로필은 "@Profile.md"\n'),
    ("줄을 넘는 백틱 토막", "\n- 프로필은 `시작\n@Profile.md\n끝` 이다\n"),
    ("공백을 둔 큰따옴표", '\n- 프로필은 " @Profile.md " 이다\n'),
    ("공백을 둔 작은따옴표", "\n- 프로필은 ' @Profile.md ' 이다\n"),
    ("펜스 ```", "\n```\n@Profile.md\n```\n"),
    ("펜스 ~~~", "\n~~~\n@Profile.md\n~~~\n"),
    ("들여 쓴 펜스 ```", "\n   ```\n@Profile.md\n   ```\n"),
    ("```` 안의 ``` 줄", "\n````\n```\n@Profile.md\n```\n````\n"),
    ("``` 안의 ~~~ 줄", "\n```\n~~~\n@Profile.md\n~~~\n```\n"),
    ("정보 문자열이 붙은 ``` 줄로는 닫히지 않는 펜스", "\n```\n``` 덤\n@Profile.md\n```\n"),
    ("주석", "\n<!--\n@Profile.md\n-->\n"),
    ("마크다운 링크", "\n- 프로필은 [프로필](Profile.md)\n"),
    ("경로 변형", "\n- 프로필은 @./Profile.md\n"),
    ("붙은 마침표", "\n- 프로필은 @Profile.md.\n"),
    ("괄호", "\n- 프로필은 (@Profile.md)\n"),
    ("대소문자", "\n- 프로필은 @profile.md\n"),
]

P1 = f"{PROFILE}: [P1]"
C1 = f"{ENTRY}: [C1]"
# 이 저장소의 마스터플랜 「가리키는 문서」는 `CLAUDE.md` 를 든다 — 입구가 없거나 밖을 가리키면 그 줄도 [M2] 로 선다.
# 임시 레포의 마스터플랜은 입구를 들지 않으므로 다른 레포 모드에서는 이 표시를 뺀다.
ENTRY_ROW = "<이 저장소만: 마스터플랜의 입구 줄>"

# (이름, 변조(트리), 출력에 다 있어야 할 줄 머리) — 출력의 번호는 이 줄들의 번호뿐이어야 한다(V2).
PROFILE_CASES = [
    *[(f"P1 가져오는 줄이 {name}", (lambda x: lambda t: profile(t, line=x))(text), [P1]) for name, text in NOT_IMPORTS],
    ("P1 가져오는 줄이 없다", lambda t: profile(t, where=None), [P1]),
    ("P1 프로필이 폴더", lambda t: (profile(t), (t / PROFILE).unlink(), (t / PROFILE).mkdir()), [P1]),
    ("P1 프로필이 밖을 가리키는 링크", lambda t: (profile(t), outside_link(t, PROFILE)), [P1]),
    ("P1 프로필이 고리 링크", lambda t: (add(t, ENTRY, IMPORTS), os.symlink(PROFILE, t / PROFILE)), [P1]),
    ("P1 프로필이 끊긴 링크", lambda t: (add(t, ENTRY, IMPORTS), os.symlink("NOPE.md", t / PROFILE)), [P1]),
    ("P1 CLAUDE.local.md 가 폴더", lambda t: (profile(t, where=None), (t / LOCAL).mkdir()), [P1]),
    ("P1 CLAUDE.local.md 가 밖을 가리키는 링크 — 그 밖 파일이 가져온다", lambda t: (
        profile(t, where=None), outside(t, LOCAL, IMPORTS)), [P1]),
    ("P1 CLAUDE.local.md 가 끊긴 링크", lambda t: (profile(t, where=None), os.symlink("NOPE.md", t / LOCAL)), [P1]),
    ("P1 CLAUDE.md 가 밖을 가리키는 링크 — 그 밖 파일이 가져온다", lambda t: (
        profile(t, where=None), outside(t, ENTRY, (t / ENTRY).read_text(encoding="utf-8") + IMPORTS)), [C1, P1, ENTRY_ROW]),
    ("P1 CLAUDE.md 가 폴더", lambda t: (profile(t, where=None), (t / ENTRY).unlink(), (t / ENTRY).mkdir()), [C1, P1]),
    ("R1 프로필이 UTF-8 이 아니다", lambda t: (profile(t), not_utf8(t, PROFILE)), [f"{PROFILE}: [R1]"]),
    ("R1 CLAUDE.local.md 가 UTF-8 이 아니면 P1 은 묻지 않는다", lambda t: (
        profile(t, where=None), not_utf8(t, LOCAL, IMPORTS.encode())), [f"{LOCAL}: [R1]"]),
    ("R1 CLAUDE.md 가 UTF-8 이 아니면 P1 은 묻지 않는다", lambda t: (
        profile(t, where=None), not_utf8(t, ENTRY, IMPORTS.encode())),
     [f"{ENTRY}: [R1]", f"{ENTRY}: [C2]", f"{ENTRY}: [C3]"]),
    ("프로필이 없으면 P1 을 묻지 않는다", lambda t: (t / ENTRY).unlink(), [C1, ENTRY_ROW]),
    ("마스터플랜이 없으면 P1 을 묻지 않는다", lambda t: (profile(t, where=None), (t / MP).unlink()), [f"{MP}: [O3]"]),
    ("CLAUDE.md 가 C1 로 떨어져도 CLAUDE.local.md 가 가져오면 P1 은 서지 않는다", lambda t: (
        profile(t, where=LOCAL), (t / ENTRY).unlink()), [C1, ENTRY_ROW]),
]

# (이름, 변조(트리)) — 통과해야 한다.
PROFILE_CONTROLS = [
    ("CLAUDE.md 가 가져온다 — 실물의 꼴", lambda t: profile(t)),
    ("CLAUDE.local.md 가 가져온다", lambda t: profile(t, where=LOCAL)),
    ("줄 머리 · 뒤에 글이 이어진다 · 앞뒤의 백틱 토막", lambda t: profile(
        t, line="\n@Profile.md\n- `프로필` @Profile.md 를 따른다 `끝`\n")),
    ("정보 문자열에 백틱이 든 ``` 줄은 펜스를 열지 않는다", lambda t: profile(
        t, line="\n```설명 `x`\n- 프로필 — @Profile.md\n")),
    ("백틱 토막은 빈 줄을 넘지 못한다", lambda t: profile(
        t, line="\n- 짝 없는 ` 하나\n\n- @Profile.md 와 ` 하나\n")),
    ("따옴표 구간 밖이면 가져온다", lambda t: profile(t, line='\n- "따옴표" 뒤의 @Profile.md\n')),
]

ID = re.compile(r"\[([A-Z]\d+)\]")


def judged(rc, out, need):
    """거절 꼴의 판정 — exit 1 · 예외 없음 · 기대한 줄이 다 있고 · 번호는 그 줄들의 번호뿐(조각 31 설계 ⑤ V2)."""
    seen = {m for ln in out.splitlines() if ln.startswith("  - ") for m in ID.findall(ln)}
    want = {m for w in need for m in ID.findall(w)}
    return rc == 1 and "Traceback" not in out and all(w in out for w in need) and seen == want, seen


# ── 다른 레포 모드(설계 ② A) ─────────────────────────────────────────

R_DONE = "| 1 | 닫힌 조각 | 시험 | — | 닫힘 | `docs/slices/1-done/` |"
R_GO = "| 2 | 진행 조각 | 시험 | 닫힌 조각 | 진행 | `docs/slices/2-go/` |"
R_PLAN = "| — | 예정 조각 | 시험 | — | 예정 | — |"
R_INTENT = "| 의도 — Why · What · Not | `PRD.md` |"
GO_DIR = "docs/slices/2-go"
DONE_DIR = "docs/slices/1-done"
CLOSE = "\n## 닫으며 (2026-10-08)\n"
R_ENTRY = "# 시험 레포 작업 규칙\n\n## 작업 방식\n\n- 의도는 `PRD.md`, 조각은 `docs/master-plan.md` 에서 꺼낸다.\n"


def fill(text, old, new):
    """틀의 자리표시자를 채운다 — 없으면 틀이 바뀌었으니 시험을 맞춰 고친다."""
    if old not in text:
        raise Setup(f"틀에 채울 자리 {old!r} 가 없다")
    return text.replace(old, new)


def repo_bed(box, checker):
    """(베낀 검사, 그 옆의 틀 폴더, 틀로 세운 임시 레포). 레포에는 지도도 `vibe-slice/` 도 없다(V2)."""
    skill = box / "slice-docs"
    (skill / "scripts").mkdir(parents=True)
    shutil.copy(checker, skill / "scripts" / "verify-docs.py")
    shutil.copytree(ROOT / TPL, skill / "templates")
    t = box / "repo"
    (t / "docs").mkdir(parents=True)
    write(t / "PRD.md", "# PRD\n\n## 문제\n\n## 범위\n")
    write(t / ENTRY, R_ENTRY)
    mp = (ROOT / TPL / "master-plan.md").read_text(encoding="utf-8")
    intent = [ln for ln in mp.splitlines() if ln.startswith("| 의도")]
    if len(intent) != 1:
        raise Setup(f"틀 master-plan.md 에 의도 줄이 {len(intent)} 개다")
    mp = fill(mp, intent[0], R_INTENT)
    mp = fill(mp, "<경로, 또는 `없음 — <이유>`>", "없음 — 시험 레포")
    mp = fill(mp, "| 1 | <이름> | <목표 한 줄> | — | 예정 | — |", "\n".join((R_DONE, R_GO, R_PLAN)))
    write(t / MP, mp)
    for d in (DONE_DIR, GO_DIR):
        (t / d).mkdir(parents=True)
        for f in ("requirements.md", "design.md"):
            shutil.copy(ROOT / TPL / f, t / d / f)
    append(t, f"{DONE_DIR}/requirements.md", CLOSE)
    return skill / "scripts" / "verify-docs.py", (skill / "templates").resolve(), t


def first_plan(t):
    """첫 마스터플랜 — 조각 나눔이 다 `예정` 이고 `docs/slices/` 가 아직 없다(A7)."""
    sub(t, MP, R_DONE + "\n", "")
    sub(t, MP, R_GO + "\n", "")
    shutil.rmtree(t / "docs/slices")


def no_headings(p):
    write(p, "".join(ln for ln in p.read_text(encoding="utf-8").splitlines(True) if not ln.startswith("## ")))


# (이름, 출력에 다 있어야 할 줄 머리, 변조(레포, 틀 폴더)) — `{tpl}` 은 그 꼴의 틀 폴더다.
R_CASES = [
    ("A4 마스터플랜이 없다", ["docs/master-plan.md: [O3]"], lambda t, tpl: (t / MP).unlink()),
    ("A7 첫 마스터플랜에 진행 줄 하나 — 폴더가 없다", ["docs/master-plan.md: [M2]", "docs/master-plan.md: [S8]"],
     lambda t, tpl: (first_plan(t), sub(t, MP, R_PLAN, R_PLAN + "\n| 1 | 첫 조각 | 시험 | — | 진행 | `docs/slices/1-x/` |"))),
    ("A7 첫 마스터플랜이 docs/plans/ 를 가리킨다", ["docs/master-plan.md: [M2]"],
     lambda t, tpl: (first_plan(t), sub(t, MP, "| `docs/slices/` |", "| `docs/plans/` |"))),
    ("A4 진행 조각 설계에서 ③ 이 빠진다", [f"{GO_DIR}/design.md: [F3]"],
     lambda t, tpl: sub(t, f"{GO_DIR}/design.md", "\n## ③ 받는 입력\n", "\n")),
    ("A4 진행 조각이 예정 조각을 의존", ["docs/master-plan.md: [S6]"],
     lambda t, tpl: sub(t, MP, R_GO, R_GO.replace("| 닫힌 조각 |", "| 예정 조각 |"))),
    ("A4 닫힌 조각의 「닫으며」가 없다", [f"{DONE_DIR}/requirements.md: [F5]"],
     lambda t, tpl: sub(t, f"{DONE_DIR}/requirements.md", CLOSE, "\n")),
    ("A4 고아 폴더", ["docs/slices/9-x: [F1]"], lambda t, tpl: (t / "docs/slices/9-x").mkdir()),
    ("A4 INTENT.md 의 Not → Non", ["INTENT.md: [I3]"], lambda t, tpl: (
        write(t / "INTENT.md", (tpl / "intent.md").read_text(encoding="utf-8")),
        sub(t, "INTENT.md", "\n## Not\n", "\n## Non\n"),
        sub(t, MP, R_INTENT, R_INTENT.replace("`PRD.md`", "`INTENT.md`")))),
    ("A1 검사 옆 틀 design.md 에 제목을 더한다", [f"{GO_DIR}/design.md: [F3]"],
     lambda t, tpl: append(tpl.parent, "templates/design.md", "\n## ⑦ 덤\n")),
    ("A2 검사 옆 틀 requirements.md 가 없다", ["[A2] {tpl}/requirements.md:"],
     lambda t, tpl: (tpl / "requirements.md").unlink()),
    ("A2 검사 옆 틀 requirements.md 의 ## 제목을 다 지운다", ["[A2] {tpl}/requirements.md:"],
     lambda t, tpl: no_headings(tpl / "requirements.md")),
    ("A2 검사 옆 틀 intent.md 가 UTF-8 이 아니다", ["[A2] {tpl}/intent.md:"], lambda t, tpl: (
        (tpl / "intent.md").unlink(), (tpl / "intent.md").write_bytes(b"\xff\xfe## Why\n"))),
    ("A2 검사 옆 틀 claude-md.md 가 없다", ["[A2] {tpl}/claude-md.md:"],
     lambda t, tpl: (tpl / "claude-md.md").unlink()),
    ("A2 검사 옆 틀 profile.md 가 없다", ["[A2] {tpl}/profile.md:"],
     lambda t, tpl: (tpl / "profile.md").unlink()),
    ("C1 입구가 없다", ["CLAUDE.md: [C1]"], lambda t, tpl: (t / ENTRY).unlink()),
    ("C1 첫 마스터플랜이어도 입구가 없으면 떨어진다", ["CLAUDE.md: [C1]"],
     lambda t, tpl: (first_plan(t), (t / ENTRY).unlink())),
    *[(f"C2 의도가 {name}", ["CLAUDE.md: [C2]"], (lambda f, a: lambda t, tpl: refused(t, "PRD.md", f, a))(form, tail))
      for name, form, tail in REFUSED],
    *[(f"C3 마스터플랜이 {name}", ["CLAUDE.md: [C3]"],
       (lambda f, a: lambda t, tpl: refused(t, "docs/master-plan.md", f, a))(form, tail))
      for name, form, tail in REFUSED],
]

# (이름, 변조(레포, 틀 폴더)) — 통과해야 한다.
R_CONTROLS = [
    ("A4 · A6 의도 줄 PRD.md · 닫힌 조각 · 진행 조각", lambda t, tpl: None),
    ("A3 진행 조각 설계 끝의 날짜 항목 · 루트의 엉뚱한 docs/procedure.md", lambda t, tpl: (
        append(t, f"{GO_DIR}/design.md", "\n## 2026-10-08 — 열어 둔 것을 정한다\n"),
        write(t / PROC, "# 절차\n\n### 설계 문서의 칸\n\n| 제목 | 담는 것 |\n|---|---|\n| `## ⑦ 덤` | x |\n"
                        "\n### 설계 문서의 칸\n\n| 제목 | 담는 것 |\n|---|---|\n| `## ⑧ 덤` | x |\n"))),
    ("A7 첫 마스터플랜 — 다 예정 · docs/slices/ 없음", lambda t, tpl: first_plan(t)),
]

# 사용법 — exit 2. `{root}` 는 그 꼴의 임시 레포다.
R_USAGE = [["--repo"], ["--repo", "{root}", "--force"], ["--repo", "-x"], ["{root}", "--repo"], ["-x"]]


# UTF-8 이 아닌 로케일과 cp949 콘솔 — 한국어 Windows 를 이 기계에서 흉내 낸다(E1, 조각 9 설계 끝 「단계 5 에서 찾은 것」).
NON_UTF8 = {**os.environ, "LC_ALL": "C", "PYTHONCOERCECLOCALE": "0", "PYTHONUTF8": "0", "PYTHONIOENCODING": "cp949"}


def run_repo(checker, *args, env=None):
    p = subprocess.run([sys.executable, str(checker), *map(str, args)], capture_output=True, text=True,
                       encoding="utf-8", errors="replace", env=env)
    return p.returncode, p.stdout + p.stderr


def repo_mode(checker, tmp):
    """다른 레포 모드의 꼴 — (통과 수, 실패 줄)."""
    fails, passes, n = [], 0, 0

    def bed():
        nonlocal n
        n += 1
        return repo_bed(tmp / f"repo{n}", checker)

    for name, want, mutate in R_CASES:
        try:
            c, tpl, t = bed()
            mutate(t, tpl)
        except Setup as e:
            fails.append(f"다른 레포 {name}: 준비 실패 — {e}")
            continue
        rc, out = run_repo(c, "--repo", t)
        need = [w.format(tpl=tpl.as_posix()) for w in want]
        if rc == 1 and "Traceback" not in out and all(w in out for w in need):
            passes += 1
        else:
            fails.append(f"다른 레포 {name}: {' · '.join(need)} 로 떨어지지 않았다 (종료코드 {rc}) — {out[-300:]}")

    for name, mutate in R_CONTROLS:
        try:
            c, tpl, t = bed()
            mutate(t, tpl)
        except Setup as e:
            fails.append(f"다른 레포 대조 {name}: 준비 실패 — {e}")
            continue
        rc, out = run_repo(c, "--repo", t)
        if rc == 0 and f"(다른 레포 — 원천 {tpl.as_posix()})" in out:
            passes += 1
        else:
            fails.append(f"다른 레포 대조 {name}: 원천을 찍고 통과해야 하는데 아니다 (종료코드 {rc}) — {out[-300:]}")

    for name, mutate, need in PROFILE_CASES:
        try:
            c, tpl, t = bed()
            mutate(t)
        except Setup as e:
            fails.append(f"다른 레포 {name}: 준비 실패 — {e}")
            continue
        need = [w for w in need if w != ENTRY_ROW]
        rc, out = run_repo(c, "--repo", t)
        ok, seen = judged(rc, out, need)
        if ok:
            passes += 1
        else:
            fails.append(f"다른 레포 {name}: {' · '.join(need)} 만 서야 한다 (종료코드 {rc}, 선 번호 {sorted(seen)}) — {out[-300:]}")

    for name, mutate in PROFILE_CONTROLS:
        try:
            c, tpl, t = bed()
            mutate(t)
        except Setup as e:
            fails.append(f"다른 레포 대조 {name}: 준비 실패 — {e}")
            continue
        rc, out = run_repo(c, "--repo", t)
        if rc == 0:
            passes += 1
        else:
            fails.append(f"다른 레포 대조 {name}: 통과해야 하는데 떨어졌다 — {out[-300:]}")

    # E1 UTF-8 이 아닌 로케일 · cp949 콘솔 — 대조는 통과 줄을, 변조는 판정 줄을 예외 없이 찍는다.
    for name, mutate, want_rc, want in (
            ("대조", lambda t, tpl: None, 0, "PASS 문서의 모양(다른 레포"),
            ("F3", lambda t, tpl: sub(t, f"{GO_DIR}/design.md", "\n## ③ 받는 입력\n", "\n"), 1, f"{GO_DIR}/design.md: [F3]")):
        try:
            c, tpl, t = bed()
            mutate(t, tpl)
        except Setup as e:
            fails.append(f"다른 레포 E1 {name}: 준비 실패 — {e}")
            continue
        rc, out = run_repo(c, "--repo", t, env=NON_UTF8)
        if rc == want_rc and "Traceback" not in out and want in out:
            passes += 1
        else:
            fails.append(f"다른 레포 E1 {name}: UTF-8 이 아닌 로케일에서 {want} 를 예외 없이 찍어야 한다 (종료코드 {rc}) — {out[-300:]}")

    try:
        c, tpl, t = bed()
    except Setup as e:
        return passes, fails + [f"다른 레포 사용법: 준비 실패 — {e}"]
    for args in R_USAGE:
        rc, out = run_repo(c, *(a.format(root=t) for a in args))
        if rc == 2 and "사용법" in out:
            passes += 1
        else:
            fails.append(f"다른 레포 사용법 {args}: exit 2 여야 한다 (종료코드 {rc}) — {out[-200:]}")
    return passes, fails


# (이름, 변조) — 통과해야 한다. 다 떨어뜨리는 검사도 무는 것처럼 보이므로.
CONTROLS = [
    ("의도를 다른 문서가 든다(ADR 0010) — 입구도 그 문서를 가리킨다", lambda t: (
        sub(t, MP, "| 의도 — 목표 · 범위 · 하지 않을 일 | `INTENT.md` |", "| 의도 — 목표 · 범위 · 하지 않을 일 | `PRD.md` |"),
        write(t / "PRD.md", "# PRD\n\n## 문제\n\n## 범위\n"),
        append(t, ENTRY, "\n- 의도는 `PRD.md` 가 든다.\n"))),
    ("입구의 절 제목은 묻지 않는다(조각 30 설계 ② · 하지 않을 일 1)", lambda t: write(
        t / ENTRY, "# 다른 모양\n\n## 아무 절\n\n의도는 `INTENT.md`, 조각은 `docs/master-plan.md`.\n")),
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
    ("넓은 의존 칸(이름 1,100 개) — 깊이 한도에 걸리지 않는다", lambda t: (
        add_rows(t, *(f"| — | 넓이 {k} | x | — | 예정 | — |" for k in range(1100))),
        set_cell(t, PLAN, 3, " · ".join(f"넓이 {k}" for k in range(1100))))),
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

        for name, mutate, need, never in QUIET:
            t = fresh()
            try:
                mutate(t)
            except Setup as e:
                fails.append(f"{name}: 준비 실패 — {e}")
                continue
            rc, out = run(checker, t)
            seen = [x for x in never if x in out]
            if rc == 1 and "Traceback" not in out and need in out and not seen:
                passes += 1
            else:
                fails.append(f"{name}: `{need}` 만 서고 {' · '.join(never) or '—'} 는 서지 않아야 한다 "
                             f"(종료코드 {rc}, 선 것 {seen}) — {out[-300:]}")

        for name, mutate, need in PROFILE_CASES:
            t = fresh()
            try:
                mutate(t)
            except Setup as e:
                fails.append(f"{name}: 준비 실패 — {e}")
                continue
            need = [f"{MP}: [M2]" if w == ENTRY_ROW else w for w in need]
            rc, out = run(checker, t)
            ok, seen = judged(rc, out, need)
            if ok:
                passes += 1
            else:
                fails.append(f"{name}: {' · '.join(need)} 만 서야 한다 (종료코드 {rc}, 선 번호 {sorted(seen)}) — {out[-300:]}")

        for name, mutate in [*CONTROLS, *PROFILE_CONTROLS]:
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

        # W3 인자 없이 부르면 부른 경로의 두 단 위가 루트다 — `scripts/` 의 링크는 그 트리, 실물 경로는 O3.
        t = fresh()
        write(t / "vibe-slice/skills/slice-docs/scripts/verify-docs.py", checker.read_text(encoding="utf-8"))
        rc, out = run_repo(t / "scripts" / "verify-docs.py")
        if rc == 0:
            passes += 1
        else:
            fails.append(f"W3 링크로 인자 없이 부르면 그 트리에서 통과해야 한다 (종료코드 {rc}) — {out[-300:]}")
        rc, out = run_repo(t / "vibe-slice/skills/slice-docs/scripts/verify-docs.py")
        if rc == 1 and "docs/procedure.md: [O3]" in out:
            passes += 1
        else:
            fails.append(f"W3 실물 경로로 인자 없이 부르면 O3 이어야 한다 (종료코드 {rc}) — {out[-300:]}")

        rc, out = run(checker, bed)
        if rc == 0:
            passes += 1
        else:
            fails.append(f"바탕이 변조본에 물들었다 — 어느 변조가 파일을 제자리에서 고쳤다 — {out[-300:]}")

        got, bad = repo_mode(checker, tmp)
        passes += got
        fails += bad

    if fails:
        print(f"FAIL — 문서 대조 검사의 자체 시험 {len(fails)} 개가 어긋났다")
        for f in fails:
            print(f"  - {f}")
        return 1
    print(f"PASS 문서 대조 검사가 문다 — 변조본 {len(CASES)} · 묻지 않음 {len(QUIET)} · 대조 {len(CONTROLS)} · 원천 1 · 지금 모양 3 · 링크 2, "
          f"다른 레포 변조본 {len(R_CASES)} · 대조 {len(R_CONTROLS)} · 사용법 {len(R_USAGE)} · 로케일 2, "
          f"프로필 거절 {len(PROFILE_CASES)} · 대조 {len(PROFILE_CONTROLS)} 두 모드, 모두 {passes}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
