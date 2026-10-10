#!/usr/bin/env python3
"""`verify-map-pin.py` 가 조각 10 설계 ② 의 R · M · O 를 지키는지 본다. 모델도 네트워크도 안 쓴다.

  python3 scripts/test-verify-map-pin.py [<검사 경로>]   # 없으면 scripts/verify-map-pin.py

임시 git 레포(`docs/procedure.md` · `vibe-slice/skills/a/SKILL.md`)에 설계 ⑤ PR C 표의 꼴을 하나씩 만들어 검사를 대고,
종료 코드와 보장 번호를 본다. 검사의 경로를 받는 까닭 — `bite-map-pin.py` 가 망가뜨린 사본에 이 시험을 대어
떨어지는지 본다(V1).

표준 라이브러리만 쓴다.
"""
import os
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHECK = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / "scripts" / "verify-map-pin.py"
ENV = {k: v for k, v in os.environ.items() if k != "GITHUB_EVENT_PATH"}
ENV.update({"GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t",
            "GIT_COMMITTER_EMAIL": "t@t", "GIT_CONFIG_GLOBAL": os.devnull, "GIT_CONFIG_NOSYSTEM": "1"})
# UTF-8 이 아닌 로케일과 cp949 콘솔 — 한국어 Windows 를 이 기계에서 흉내 낸다(O2).
NON_UTF8 = {"LC_ALL": "C", "PYTHONCOERCECLOCALE": "0", "PYTHONUTF8": "0", "PYTHONIOENCODING": "cp949"}
MAP = "docs/procedure.md"
SKILL_A = "vibe-slice/skills/a/SKILL.md"
SKILL_B = "vibe-slice/skills/b/SKILL.md"


def url(sha, path=MAP, form=None):
    return form or f"https://github.com/pdw96/claude-kit/blob/{sha}/{path}"


def skill(name, *links):
    """프론트매터와 링크 줄을 든 SKILL.md — 실제 두 스킬처럼 링크 뒤가 ` .` 와 `)` 다."""
    body = "".join(f"지도({u}) 를 읽는다.\n" if i % 2 else f"절차 지도 {u} .\n" for i, u in enumerate(links))
    return f"---\nname: {name}\ndescription: 시험\n---\n\n# {name}\n\n{body}"


def sh(cwd, *args):
    p = subprocess.run(args, cwd=cwd, capture_output=True, text=True, env=ENV)
    if p.returncode != 0:
        sys.exit(f"준비 실패: {' '.join(map(str, args))}\n{p.stderr}")
    return p.stdout.strip()


def put(repo, files):
    for rel, text in files.items():
        p = repo / rel
        if text is None:
            p.unlink()
            continue
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text, encoding="utf-8")


def commit(repo, files, msg="x"):
    put(repo, files)
    sh(repo, "git", "add", "-A")
    sh(repo, "git", "commit", "-q", "--allow-empty", "-m", msg)
    return sh(repo, "git", "rev-parse", "HEAD")


def run(cwd, *args, extra=None):
    p = subprocess.run([sys.executable, str(CHECK), *args], cwd=cwd, capture_output=True, text=True,
                       encoding="utf-8", errors="replace", env=dict(ENV, **(extra or {})))
    return p.returncode, p.stdout + p.stderr


bad = []


def expect(what, ok, out=""):
    if not ok:
        bad.append(f"{what}\n    {out.strip().replace(chr(10), chr(10) + '    ')}")


def verdict(what, got, rc, ids=(), absent=(), has=()):
    code, out = got
    expect(f"{what} — exit {code}, 기대 {rc}", code == rc, out)
    for g in ids:
        expect(f"{what} — [{g}] 가 없다", f"[{g}]" in out, out)
    for g in absent:
        expect(f"{what} — {g} 가 있다", g not in out, out)
    for g in has:
        expect(f"{what} — 「{g}」 를 찍지 않았다", g in out, out)
    expect(f"{what} — 예외로 끝났다", "Traceback" not in out, out)


def main():
    if not CHECK.is_file():
        sys.exit(f"검사가 없다 — {CHECK}")
    with tempfile.TemporaryDirectory() as t:
        tmp = pathlib.Path(t)
        n = iter(range(1000))

        def repo(**files):
            """지도 커밋 A 하나가 있는 레포 — (레포, A)."""
            r = tmp / f"r{next(n)}"
            r.mkdir()
            sh(r, "git", "init", "-q", "-b", "main")
            a = commit(r, {MAP: "지도 1\n", "docs/README.md": "읽어라\n", **files}, "지도 A")
            return r, a

        # 지도 커밋 A · 플러그인 커밋 B 가 A 를 박음 → 그 뒤 지도만 C → 틀만 D(링크 A) → 다시 박은 E
        r, a = repo()
        b = commit(r, {SKILL_A: skill("a", url(a))}, "플러그인 B")
        verdict("A 를 박은 B", run(r), 0, has=[f"기준 {b[:7]}", f"박은 커밋 {a[:7]}"])
        c = commit(r, {MAP: "지도 2\n"}, "지도만 C")
        verdict("그 뒤 지도만 고친 C", run(r), 0, has=[f"기준 {b[:7]}"])

        # 작업트리 — `vibe-slice/` 만 고쳐 C 를 박음(이 레포의 C 위에서)
        put(r, {SKILL_A: skill("a", url(c))})
        verdict("작업트리 — vibe-slice/ 만 고쳐 C 를 박음", run(r), 0, has=["기준 작업트리"])
        put(r, {MAP: "지도 3\n"})
        verdict("작업트리 — 지도도 고치고 vibe-slice/ 도 고침", run(r), 1, ["M5"], has=["먼저 커밋"])
        sh(r, "git", "checkout", "-q", "--", ".")

        d = commit(r, {"vibe-slice/skills/a/templates/t.md": "틀\n"}, "틀만 D")
        verdict("틀만 고친 D(링크는 A)", run(r), 1, ["M5"], has=[c])
        commit(r, {SKILL_A: skill("a", url(c))}, "다시 박은 E")
        verdict("D 뒤 C 로 다시 박은 E", run(r), 0, has=[f"박은 커밋 {c[:7]}"])

        # 옆 가지에서 박은 커밋을 머지 커밋으로 들인 꼴
        r, a = repo()
        sh(r, "git", "checkout", "-q", "-b", "side")
        commit(r, {SKILL_A: skill("a", url(a))}, "옆 가지에서 박음")
        sh(r, "git", "checkout", "-q", "main")
        commit(r, {"README.md": "입구\n"}, "그 사이 main")
        sh(r, "git", "merge", "-q", "--no-ff", "-m", "머지", "side")
        verdict("옆 가지에서 박은 커밋을 머지 커밋으로", run(r), 0)

        # 지도 커밋 뒤 플러그인 커밋 B, 그 뒤 옆 가지가 지도만 고쳐 머지 커밋으로 들어옴 — 머지에서
        r, a = repo()
        b = commit(r, {SKILL_A: skill("a", url(a))}, "플러그인 B")
        sh(r, "git", "checkout", "-q", "-b", "close")
        commit(r, {MAP: "지도 닫으며\n"}, "지도만 — 닫는 PR")
        sh(r, "git", "checkout", "-q", "main")
        commit(r, {"README.md": "입구\n"}, "그 사이 main")
        sh(r, "git", "merge", "-q", "--no-ff", "-m", "머지", "close")
        verdict("지도만 고친 옆 가지를 머지한 뒤", run(r), 0, has=[f"기준 {b[:7]}"])

        # M1 — 받지 않는 꼴
        for form in ["https://github.com/pdw96/claude-kit/blob/main/docs/procedure.md",
                     "https://github.com/pdw96/claude-kit/blob/0123abc/docs/procedure.md",
                     "https://github.com/pdw96/claude-kit/tree/main/docs",
                     "https://raw.githubusercontent.com/pdw96/claude-kit/main/docs/procedure.md"]:
            r, a = repo()
            commit(r, {SKILL_A: skill("a", url(a), form)})
            verdict(f"M1 — {form}", run(r), 1, ["M1"])

        # M2 — 없는 40 자 커밋 · M3 — 조상이 아닌 커밋 · M4 — 그 커밋에 없는 경로 · M5 — 지도가 다른 옛 커밋
        r, a = repo()
        commit(r, {SKILL_A: skill("a", url(a), url("0" * 40))})
        verdict("M2 — 없는 40 자 커밋", run(r), 1, ["M2"])
        r, a = repo()
        sh(r, "git", "checkout", "-q", "-b", "other")
        o = commit(r, {"docs/other.md": "옆\n"}, "다른 가지")
        sh(r, "git", "checkout", "-q", "main")
        commit(r, {SKILL_A: skill("a", url(a), url(o, "docs/other.md"))})
        verdict("M3 — 조상이 아닌 커밋", run(r), 1, ["M3"])
        r, a = repo()
        commit(r, {SKILL_A: skill("a", url(a), url(a, "docs/nope.md"))})
        verdict("M4 — 그 커밋에 없는 경로", run(r), 1, ["M4"])
        r, a = repo()
        commit(r, {MAP: "지도 2\n"}, "지도 A2")
        commit(r, {SKILL_A: skill("a", url(a))})
        verdict("M5 — 지도가 다른 옛 커밋", run(r), 1, ["M5"])

        # M6 — 스킬마다
        r, a = repo()
        commit(r, {SKILL_A: skill("a")})
        verdict("M6 — 링크가 없다", run(r), 1, ["M6"])
        for what, files, who in [
            ("한 SKILL.md 의 링크만 지움", {SKILL_A: skill("a", url("{a}")), SKILL_B: skill("b")}, "b"),
            ("한 스킬의 링크가 docs/README.md 를 박음", {SKILL_A: skill("a", url("{a}")),
                                                  SKILL_B: skill("b", url("{a}", "docs/README.md"))}, "b"),
            ("한 스킬의 링크를 그 스킬의 틀로 옮김", {SKILL_A: skill("a", url("{a}")), SKILL_B: skill("b"),
                                               "vibe-slice/skills/b/templates/t.md": f"틀 {url('{a}')}\n"}, "b"),
            ("스킬 폴더를 더함 — SKILL.md 에 지도 링크 없음", {SKILL_A: skill("a", url("{a}")),
                                                     "vibe-slice/skills/c/SKILL.md": skill("c")}, "c"),
            ("스킬 폴더를 더함 — SKILL.md 없음(틀만)", {SKILL_A: skill("a", url("{a}")),
                                                "vibe-slice/skills/c/templates/t.md": "틀\n"}, "c"),
        ]:
            r, a = repo()
            commit(r, {k: v.replace("{a}", a) for k, v in files.items()})
            got = run(r)
            verdict(f"M6 — {what}", got, 1, ["M6"], has=[f"vibe-slice/skills/{who}/SKILL.md"],
                    absent=[f"[M6] {SKILL_A}"])
        r, a = repo()
        commit(r, {SKILL_A: skill("a", url(a), url(a, "docs/README.md"))})
        verdict("지도 링크에 더해 다른 경로를 박은 링크(그 경로가 기준과 같음)", run(r), 0, has=["링크 2"])

        # R — 얕은 클론 · vibe-slice/ 없음 · git 아님
        r, a = repo()
        commit(r, {SKILL_A: skill("a", url(a))})
        shallow = tmp / f"r{next(n)}"
        sh(tmp, "git", "clone", "-q", "--depth", "1", f"file://{r}", str(shallow))
        verdict("R2 — 얕은 클론", run(shallow), 1, ["R2"])
        r, a = repo()
        verdict("R3 — vibe-slice/ 없음", run(r), 1, ["R3"])
        plain = tmp / f"plain{next(n)}"
        plain.mkdir()
        verdict("R1 — git 아님", run(plain, extra={"GIT_CEILING_DIRECTORIES": str(tmp)}), 1, ["R1"])

        # 인자 · O2
        verdict("인자를 줌", run(r, "--fix"), 2)
        r, a = repo()
        commit(r, {MAP: "지도 2\n"}, "지도 A2")
        commit(r, {SKILL_A: skill("a", url(a))})
        verdict("O2 — LC_ALL=C · PYTHONIOENCODING=cp949 의 실패 꼴", run(r, extra=NON_UTF8), 1, ["M5"])

    if bad:
        print(f"FAIL verify-map-pin.py — {len(bad)}")
        for b in bad:
            print(f"  {b}")
        return 1
    print("PASS verify-map-pin.py — 박기 · 지도만 · 다시 박기 · 머지 · 작업트리 · M1 ~ M6 · R1 ~ R3 · 인자 · 로케일")
    return 0


if __name__ == "__main__":
    sys.exit(main())
