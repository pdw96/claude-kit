#!/usr/bin/env python3
"""`sync-slice.sh` 가 조각 5 설계 ② C1 ~ C5 — 조각 6 설계 ② 가 `vibe-slice/skills/` 의 스킬 전부로
넓힌 것 — 와 조각 8 설계 ② P1 · L1 ~ L3 · H1 ~ H3 을 지키는지 본다. 모델도 네트워크도 안 쓴다.

  python3 scripts/test-sync-slice.py

임시 원본(이 저장소의 스크립트와 스킬 폴더만 담은 git 저장소 — 맨 저장소를 원격으로 붙여 푸시한다)과
임시 대상을 만들어 돌린다.

  C1 스킬마다 폴더가 서고, 스킬마다 SKILL.md 는 프론트매터 뒤에 출처 줄, 나머지는 L1 의 바꿈 말고는
     바이트 그대로
  C2 원본이 더럽거나 · 추적 안 된 파일이나 · 무시된 파일이 있으면 아무것도 쓰지 않는다
  C3 심을 스킬 하나라도 폴더로 있으면 --force 없이는 멈추고, --force 면 스킬 폴더를 다 덮되 대상의
     다른 스킬 폴더는 건드리지 않는다
  C4 심을 자리(스킬 폴더마다)가 파일 · 링크 · 끊긴 링크면 --force 여도 멈춘다
  C5 원본의 copies.json 과 대상의 다른 파일을 건드리지 않고, 대상에 커밋하지 않는다
  P1 원본 HEAD 가 원격 추적 가지에 없으면(원격이 없어도) 아무것도 쓰지 않는다
  L1 심는 파일마다 github.com/pdw96/claude-kit/blob/main/ 이 blob/<출처 전체 sha>/ 로 — 한 줄에 둘이어도
  L2 그 밖의 claude-kit 링크 꼴(tree · 다른 가지 · 커밋 · raw)이 원본에 있으면 아무것도 쓰지 않는다
  L3 손으로 blob/<옛 커밋>/ 을 박은 사본도 --force 면 새 출처로
  H1 출처 줄의 글자 · H2 sync-agents.sh 의 HDR 과 같은 글자 · H3 sync-agents.sh 의 사본 README 가 같은 방향

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
LINK = "github.com/pdw96/claude-kit/blob/main/"
HDR = ('HDR="<!-- pdw96/claude-kit@$SHA 에서 옴. 이 레포에서만 참인 고침은 이 사본에만 산다 — '
       '다른 레포에서도 같은 말이면 원본으로 넘긴다. -->"')
ENV = {**os.environ, "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t",
       "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@t", "GIT_CONFIG_GLOBAL": os.devnull}


def sh(cwd, *args):
    p = subprocess.run(args, cwd=cwd, capture_output=True, text=True, env=ENV)
    if p.returncode != 0:
        sys.exit(f"준비 실패: {' '.join(map(str, args))}\n{p.stderr}")
    return p.stdout.strip()


def source(at, remote=True, change=None):
    """스크립트 · 스킬 폴더 · 대장 하나를 담고 커밋한 원본. remote 면 맨 저장소에 푸시해 원격 추적
    가지를 세운다(P1). change 는 커밋 전에 원본 트리를 고치는 함수다."""
    (at / "scripts").mkdir(parents=True)
    shutil.copy(ROOT / "scripts" / "sync-slice.sh", at / "scripts")
    shutil.copytree(ROOT / REL, at / REL)
    (at / "copies.json").write_text('{"copies": []}\n', encoding="utf-8")
    if change:
        change(at)
    sh(at, "git", "init", "-q")
    sh(at, "git", "add", "-A")
    sh(at, "git", "commit", "-q", "-m", "원본")
    if remote:
        bare = at.with_name(at.name + ".git")
        sh(at.parent, "git", "init", "-q", "--bare", str(bare))
        sh(at, "git", "remote", "add", "origin", str(bare))
        sh(at, "git", "push", "-q", "origin", "HEAD:refs/heads/main")
        sh(at, "git", "fetch", "-q", "origin")
    return at


def pinned(data, full):
    """원본 바이트에 L1 의 바꿈을 한 것."""
    return data.replace(LINK.encode(), f"github.com/pdw96/claude-kit/blob/{full}/".encode())


def add_line(rel, line):
    """원본 트리의 파일 끝에 한 줄을 더하는 change."""
    def change(at):
        f = at / REL / rel
        f.write_text(f.read_text(encoding="utf-8") + line + "\n", encoding="utf-8")
    return change


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
        full = sh(src, "git", "rev-parse", "HEAD")
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
        hdr = HDR[len('HDR="'):-1].replace("$SHA", sha)
        links = 0
        for n in want:
            links += (src / REL / n).read_bytes().count(LINK.encode())
            expect(f"[L1] {n} 에 blob/main/ 링크가 남았다", LINK.encode() not in (base / n).read_bytes())
            if n.endswith("/SKILL.md") and n.count("/") == 1:
                skill = (base / n).read_text(encoding="utf-8").splitlines()
                ends = [i for i, ln in enumerate(skill) if ln == "---"][:2]
                expect(f"{n} 이 프론트매터로 시작하지 않는다", ends[:1] == [0], "\n".join(skill[:3]))
                expect(f"[H1] {n} 의 출처 줄이 프론트매터 바로 뒤에 없거나 글자가 다르다",
                       len(ends) == 2 and skill[ends[1] + 2] == hdr, "\n".join(skill[:12]))
                orig = pinned((src / REL / n).read_bytes(), full).decode("utf-8").splitlines()
                expect(f"{n} 이 출처 두 줄 · 링크 고정 말고도 달라졌다", skill[:ends[1] + 1] + skill[ends[1] + 3:] == orig)
            else:
                expect(f"{n} 이 링크 고정 말고는 바이트 그대로가 아니다",
                       (base / n).read_bytes() == pinned((src / REL / n).read_bytes(), full))
        expect(f"시험 준비 — 원본 스킬에 blob/main/ 링크가 없어 L1 을 잴 수 없다", links > 0)
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

        # L1 — 한 줄에 링크 둘, 틀 파일에 링크 하나
        two = f"둘 — https://{LINK}a.md · https://{LINK}b.md"
        srcm = source(tmp / "src-multi", change=lambda at: (add_line("slice-docs/SKILL.md", two)(at),
                                                         add_line("slice-docs/templates/design.md", f"https://{LINK}c.md")(at)))
        fullm = sh(srcm, "git", "rev-parse", "HEAD")
        t = target(tmp / "t-multi")
        rc, out = run(srcm, t)
        got = (t / ".claude/skills/slice-docs/SKILL.md").read_text(encoding="utf-8")
        tpl_got = (t / ".claude/skills/slice-docs/templates/design.md").read_text(encoding="utf-8")
        expect("[L1] 한 줄의 링크 둘 · 틀 파일의 링크를 다 바꾸지 못했다",
               rc == 0 and two.replace(LINK, f"github.com/pdw96/claude-kit/blob/{fullm}/") in got
               and f"blob/{fullm}/c.md" in tpl_got and LINK not in got + tpl_got, out)

        # L3 — 손으로 옛 커밋을 박은 사본도 --force 면 새 출처로
        t = target(tmp / "t-pin")
        rc, out = run(src, t)
        hand = t / ".claude/skills/slice-review/SKILL.md"
        hand.write_text(hand.read_text(encoding="utf-8").replace(f"blob/{full}/", "blob/55a8a79/"), encoding="utf-8")
        expect("시험 준비 — 손으로 박은 링크가 서지 않았다", "blob/55a8a79/" in hand.read_text(encoding="utf-8"))
        rc, out = run(src, t, "--force")
        now = hand.read_text(encoding="utf-8")
        expect("[L3] --force 가 손으로 박은 옛 링크를 새 출처로 바꾸지 못했다",
               rc == 0 and "blob/55a8a79/" not in now and f"blob/{full}/" in now, out)

        # L2 — 받지 않는 claude-kit 링크 꼴은 아무것도 쓰지 않는다
        for i, form in enumerate([
            "https://github.com/pdw96/claude-kit/tree/main/docs",
            "https://github.com/pdw96/claude-kit/blob/dev/docs/procedure.md",
            "https://github.com/pdw96/claude-kit/blob/0123abc/docs/procedure.md",
            "https://raw.githubusercontent.com/pdw96/claude-kit/main/docs/procedure.md",
        ]):
            srcb = source(tmp / f"src-bad-{i}", change=add_line("slice-review/SKILL.md", f"보라 — {form}"))
            t = target(tmp / f"t-bad-{i}")
            before = snapshot(t)
            rc, out = run(srcb, t)
            expect(f"[L2] {form} 이 든 원본을 심었다",
                   rc != 0 and snapshot(t) == before and "slice-review/SKILL.md" in out, out)

        # P1 — 원격 가지에 없는 원본
        srcn = source(tmp / "src-noremote", remote=False)
        t = target(tmp / "t-noremote")
        before = snapshot(t)
        rc, out = run(srcn, t)
        expect("[P1] 원격 없는 원본을 심었다", rc != 0 and snapshot(t) == before and "원격 가지 어디에도 없다" in out, out)
        srcu = source(tmp / "src-unpushed")
        (srcu / "copies.json").write_text('{"copies": [] }\n', encoding="utf-8")
        sh(srcu, "git", "commit", "-q", "-am", "푸시 안 함")
        t = target(tmp / "t-unpushed")
        before = snapshot(t)
        rc, out = run(srcu, t)
        expect("[P1] 푸시하지 않은 커밋이 HEAD 인 원본을 심었다",
               rc != 0 and snapshot(t) == before and "원격 가지 어디에도 없다" in out, out)

        # H2 · H3 — 두 스크립트의 출처 줄과 감사자 사본 README 의 방향
        agents_sh = (ROOT / "scripts" / "sync-agents.sh").read_text(encoding="utf-8")
        hdr_lines = {name: [ln for ln in (ROOT / "scripts" / name).read_text(encoding="utf-8").splitlines()
                            if ln.startswith("HDR=")] for name in ("sync-slice.sh", "sync-agents.sh")}
        expect(f"[H2] 두 스크립트의 HDR= 줄이 H1 의 글자로 하나씩이 아니다: {hdr_lines}",
               all(v == [HDR] for v in hdr_lines.values()))
        readme = agents_sh.split('cat > "$DEST/README.md" <<EOF', 1)[-1].split("\nEOF\n", 1)[0]
        expect("[H3] sync-agents.sh 에 옛 방향의 글자가 남았다",
               "원본으로 되먹이지 않는다" not in agents_sh and "여기서 고친 것을 그쪽으로 올리지 않는다" not in agents_sh)
        expect("[H3] sync-agents.sh 의 사본 README 문단이 「다른 레포에서도 같은 말」을 적지 않는다",
               readme != agents_sh and "다른 레포에서도 같은 말" in readme)

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
    print(f"PASS sync-slice.sh 가 C1 ~ C5 · P1 · L1 ~ L3 · H1 ~ H3 을 스킬마다 지킨다 — 기대 {passes} 개 모두 맞다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
