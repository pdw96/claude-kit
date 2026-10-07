#!/usr/bin/env python3
"""`sync-slice.sh` 가 조각 5 설계 ② C1 ~ C5 — 조각 6 설계 ② 가 `vibe-slice/skills/` 의 스킬 전부로
넓힌 것 — 를 지키는지 본다. 모델도 네트워크도 안 쓴다.

  python3 scripts/test-sync-slice.py

임시 원본(이 저장소의 스크립트와 스킬 폴더만 담은 git 저장소)과 임시 대상을 만들어 돌린다.

  C1 스킬마다 폴더가 서고, 스킬마다 SKILL.md 는 프론트매터 뒤에 출처 줄, 나머지는 바이트 그대로
  C2 원본이 더럽거나 · 추적 안 된 파일이나 · 무시된 파일이 있으면 아무것도 쓰지 않는다
  C3 심을 스킬 하나라도 폴더로 있으면 --force 없이는 멈추고, --force 면 스킬 폴더를 다 덮되 대상의
     다른 스킬 폴더는 건드리지 않는다
  C4 심을 자리(스킬 폴더마다)가 파일 · 링크 · 끊긴 링크면 --force 여도 멈춘다
  C5 원본의 copies.json 과 대상의 다른 파일을 건드리지 않고, 대상에 커밋하지 않는다

표준 라이브러리만 쓴다.
"""
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
REL = "vibe-slice/skills"
ENV = {**os.environ, "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t",
       "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@t", "GIT_CONFIG_GLOBAL": os.devnull}


def sh(cwd, *args):
    p = subprocess.run(args, cwd=cwd, capture_output=True, text=True, env=ENV)
    if p.returncode != 0:
        sys.exit(f"준비 실패: {' '.join(map(str, args))}\n{p.stderr}")
    return p.stdout.strip()


def source(at):
    """스크립트 · 스킬 폴더 · 대장 하나를 담고 커밋한 원본."""
    (at / "scripts").mkdir(parents=True)
    shutil.copy(ROOT / "scripts" / "sync-slice.sh", at / "scripts")
    shutil.copytree(ROOT / REL, at / REL)
    (at / "copies.json").write_text('{"copies": []}\n', encoding="utf-8")
    sh(at, "git", "init", "-q")
    sh(at, "git", "add", "-A")
    sh(at, "git", "commit", "-q", "-m", "원본")
    return at


def target(at):
    at.mkdir(parents=True)
    (at / "README.md").write_text("대상\n", encoding="utf-8")
    sh(at, "git", "init", "-q")
    sh(at, "git", "add", "-A")
    sh(at, "git", "commit", "-q", "-m", "대상")
    return at


def run(src, *args):
    p = subprocess.run(["bash", str(src / "scripts" / "sync-slice.sh"), *map(str, args)],
                       capture_output=True, text=True, env=ENV)
    return p.returncode, p.stdout + p.stderr


def snapshot(d):
    """폴더 안 모든 항목(링크 포함)의 경로와 내용 — 「아무것도 쓰지 않았다」를 견준다."""
    out = {}
    for p in sorted(d.rglob("*")):
        if ".git" in p.relative_to(d).parts:
            continue
        rel = p.relative_to(d).as_posix()
        if p.is_symlink():
            out[rel] = ("link", os.readlink(p))
        elif p.is_file():
            out[rel] = ("file", p.read_bytes())
        else:
            out[rel] = ("dir", None)
    return out


def main():
    fails, passes = [], 0

    def expect(what, ok, out=""):
        nonlocal passes
        if ok:
            passes += 1
        else:
            fails.append(f"{what}\n{out}")

    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        src = source(tmp / "src")
        sha = sh(src, "git", "rev-parse", "--short", "HEAD")
        ledger = (src / "copies.json").read_bytes()

        skills = sorted(d.name for d in (src / REL).iterdir() if d.is_dir())
        expect(f"시험 준비 — 스킬이 둘 이상이어야 C3 · C4 의 「하나라도」를 잰다: {skills}", len(skills) >= 2)
        last = skills[-1]

        # C1 · C5 — 빈 대상에 심는다
        t = target(tmp / "t1")
        head_before = sh(t, "git", "rev-parse", "HEAD")
        rc, out = run(src, t)
        base = t / ".claude/skills"
        expect("빈 대상에 심지 못했다", rc == 0, out)
        names = sorted(p.relative_to(base).as_posix() for p in base.rglob("*") if p.is_file())
        want = sorted(p.relative_to(src / REL).as_posix() for p in (src / REL).rglob("*") if p.is_file())
        expect(f"심은 파일이 원본과 다르다: {names} ≠ {want}", names == want)
        hdr = f"<!-- pdw96/claude-kit@{sha} 에서 옴."
        for n in want:
            if n.endswith("/SKILL.md") and n.count("/") == 1:
                skill = (base / n).read_text(encoding="utf-8").splitlines()
                ends = [i for i, ln in enumerate(skill) if ln == "---"][:2]
                expect(f"{n} 이 프론트매터로 시작하지 않는다", ends[:1] == [0], "\n".join(skill[:3]))
                expect(f"{n} 의 출처 줄이 프론트매터 바로 뒤에 없다",
                       len(ends) == 2 and skill[ends[1] + 2].startswith(hdr), "\n".join(skill[:12]))
                orig = (src / REL / n).read_text(encoding="utf-8").splitlines()
                expect(f"{n} 이 출처 두 줄 말고도 달라졌다", skill[:ends[1] + 1] + skill[ends[1] + 3:] == orig)
            else:
                expect(f"{n} 이 바이트 그대로가 아니다", (base / n).read_bytes() == (src / REL / n).read_bytes())
        expect("원본의 copies.json 이 바뀌었다", (src / "copies.json").read_bytes() == ledger)
        expect("대상의 다른 파일이 바뀌었다", (t / "README.md").read_text(encoding="utf-8") == "대상\n")
        expect("대상에 커밋했다", sh(t, "git", "rev-parse", "HEAD") == head_before)

        # C3 — 스킬 하나만 있어도 다시 심기는 멈추고, --force 는 스킬 폴더를 다 덮되 다른 스킬은 둔다
        t3 = target(tmp / "t3")
        (t3 / ".claude/skills" / last).mkdir(parents=True)
        (t3 / ".claude/skills" / last / "SKILL.md").write_text("특화\n", encoding="utf-8")
        (t3 / ".claude/skills" / last / "레포고유.md").write_text("x\n", encoding="utf-8")
        mine = t3 / ".claude/skills/레포-스킬"
        mine.mkdir()
        (mine / "SKILL.md").write_text("그 레포의 스킬\n", encoding="utf-8")
        before = snapshot(t3)
        rc, out = run(src, t3)
        expect(f"스킬 하나({last})만 있는 사본을 --force 없이 덮었다", rc != 0 and snapshot(t3) == before, out)
        rc, out = run(src, t3, "--force")
        expect("--force 가 덮지 못했다", rc == 0 and all((t3 / ".claude/skills" / k / "SKILL.md").is_file()
                                                         for k in skills)
               and (t3 / ".claude/skills" / last / "SKILL.md").read_text(encoding="utf-8") != "특화\n", out)
        expect("--force 가 폴더째 덮지 않았다 — 사본에만 있던 파일이 남았다",
               not (t3 / ".claude/skills" / last / "레포고유.md").exists())
        expect("--force 가 대상의 다른 스킬 폴더를 건드렸다",
               (mine / "SKILL.md").read_text(encoding="utf-8") == "그 레포의 스킬\n")

        # C4 — 심을 자리가 파일 · 링크 · 끊긴 링크면 --force 여도 멈춘다
        outside = tmp / "outside"
        outside.mkdir()
        (outside / "keep.md").write_text("밖\n", encoding="utf-8")
        spots = [
            ("slice-docs 자리가 파일", lambda t: (t / ".claude/skills").mkdir(parents=True)
             or (t / ".claude/skills/slice-docs").write_text("파일\n", encoding="utf-8")),
            ("slice-docs 자리가 밖을 가리키는 링크", lambda t: (t / ".claude/skills").mkdir(parents=True)
             or os.symlink(outside, t / ".claude/skills/slice-docs")),
            ("slice-docs 자리가 끊긴 링크", lambda t: (t / ".claude/skills").mkdir(parents=True)
             or os.symlink(tmp / "없음", t / ".claude/skills/slice-docs")),
            (".claude 가 밖을 가리키는 링크", lambda t: os.symlink(outside, t / ".claude")),
            (f"{last} 자리가 밖을 가리키는 링크", lambda t: (t / ".claude/skills").mkdir(parents=True)
             or os.symlink(outside, t / ".claude/skills" / last)),
            (f"{last} 자리가 파일", lambda t: (t / ".claude/skills").mkdir(parents=True)
             or (t / ".claude/skills" / last).write_text("파일\n", encoding="utf-8")),
            (f"{last} 자리가 끊긴 링크", lambda t: (t / ".claude/skills").mkdir(parents=True)
             or os.symlink(tmp / "없음", t / ".claude/skills" / last)),
            ("skills 자리가 파일", lambda t: (t / ".claude").mkdir()
             or (t / ".claude/skills").write_text("파일\n", encoding="utf-8")),
        ]
        for i, (what, make) in enumerate(spots):
            t = target(tmp / f"t4-{i}")
            make(t)
            before, outside_before = snapshot(t), snapshot(outside)
            rc, out = run(src, t, "--force")
            expect(f"{what} — --force 로 심었다", rc != 0 and snapshot(t) == before
                   and snapshot(outside) == outside_before, out)

        # C2 — 더러운 원본 · 추적 안 된 파일 · 무시된 파일
        tpl = src / REL / "slice-docs" / "templates" / "design.md"
        keep = tpl.read_bytes()
        stray = src / REL / "slice-docs" / "templates" / "덤.md"
        ignored = src / REL / "slice-docs" / "templates" / "무시.md"
        cases = [
            ("원본에 커밋 안 된 변경", lambda: tpl.write_bytes(keep + b"\n"), lambda: tpl.write_bytes(keep)),
            ("원본에 추적 안 된 파일", lambda: stray.write_text("x\n", encoding="utf-8"), stray.unlink),
            ("원본에 무시된 파일", lambda: ((src / ".git/info/exclude").write_text("무시.md\n", encoding="utf-8"),
                                    ignored.write_text("x\n", encoding="utf-8")), ignored.unlink),
        ]
        for i, (what, spoil, undo) in enumerate(cases):
            t = target(tmp / f"t2-{i}")
            spoil()
            if what == "원본에 무시된 파일":
                expect("시험 준비 — 무시된 파일이 status 에 보인다",
                       sh(src, "git", "status", "--porcelain", "--", REL) == "")
            before = snapshot(t)
            rc, out = run(src, t)
            expect(f"{what} — 심었다", rc != 0 and snapshot(t) == before, out)
            undo()

        # 인자
        for what, args, code in [
            ("인자 없음", [], 2),
            ("모르는 옵션", [tmp / "t1", "--forse"], 2),
            ("경로 둘", [tmp / "t1", tmp / "t2-0"], 2),
            ("없는 경로", [tmp / "없는"], 1),
        ]:
            rc, out = run(src, *args)
            expect(f"{what} — 종료 {rc}, 기대 {code}", rc == code, out)

    if fails:
        for f in fails:
            print(f"FAIL {f}")
        return 1
    print(f"PASS sync-slice.sh 가 C1 ~ C5 를 스킬마다 지킨다 — 기대 {passes} 개 모두 맞다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
