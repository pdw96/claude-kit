#!/usr/bin/env python3
"""`vibe-audit/scripts/verify-brief.py` 가 **무는지** 본다. 모델도 API 도 안 쓴다.

  python3 scripts/test-verify-brief.py

임시 저장소를 만들어 커밋된 변경 · 작업트리 변경 · 추적 안 된 파일(빈칸 · 한글 · 탭 이름,
심볼릭 링크 · 끊긴 링크 · `-diff` 속성 · UTF-8 이 아닌 이름 둘) · 바이너리 · 바이너리에서
텍스트로 바뀐 파일 · 이름 바꿈 · `a/` 로 시작하는 폴더 · 대장 파일을 두고, 외부 diff 와
줄 수를 바꾸는 textconv 를 켠 저장소에서, `/audit-brief` 커맨드와 **같은 git 명령**으로
브리핑을 만든다. 그 브리핑은 통과해야 하고, 한 군데씩 흔든 변조본은 떨어져야 한다.
검사기를 고치고 이것이 안 돌면, 떨어져야 할 것이 통과해도 아무도 모른다.

표준 라이브러리만 쓴다.
"""
import importlib.util
import os
import pathlib
import re
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHECK = ROOT / "vibe-audit" / "scripts" / "verify-brief.py"
PIN = ["--no-ext-diff", "--no-textconv", "--submodule=short", "--no-color"]  # 커맨드가 붙이는 것
SPEC = ["--", ":/", ":(top,exclude).claude/audits", ":(top,exclude).claude/briefs",
        ":(top,exclude).claude/audit-brief.md"]


def sh(cwd, *args, ok=(0,)):
    p = subprocess.run(args, cwd=cwd, capture_output=True, text=True, errors="surrogateescape",
                       env={**os.environ, "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t",
                            "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@t"})
    if p.returncode not in ok:
        sys.exit(f"준비 실패: {' '.join(args)}\n{p.stderr}")
    return p.stdout


def make_repo(d, ledger):
    sh(d, "git", "init", "-q", "-b", "main")
    # 커맨드가 `--no-ext-diff --no-textconv` 로 막는 설정 — 막지 않으면 diff 가 비거나 줄 수가 바뀐다
    sh(d, "git", "config", "diff.external", "true")
    sh(d, "git", "config", "diff.drop.textconv", "grep -v line <")
    (d / "app").mkdir()
    (d / "app" / "routes.py").write_text("".join(f"line {i}\n" for i in range(30)))
    (d / "old_name.py").write_text("keep\n" * 5)
    (d / "logo.bin").write_bytes(b"\0\1\2")
    (d / "a").mkdir()  # diff.noprefix 면 `a/util.py` 의 `a/` 는 접두가 아니라 경로다
    (d / "a" / "util.py").write_text("u\n" * 3)
    (d / ".gitattributes").write_text("*.dat -diff\n*.py diff=drop\n")
    (d / "mixed.txt").write_bytes(b"\0\1")  # 커밋 몫은 바이너리, 작업트리 몫은 텍스트
    ledger.parent.mkdir(parents=True, exist_ok=True)
    ledger.write_text("# 대장\n")
    sh(d, "git", "add", "-A")
    sh(d, "git", "commit", "-qm", "base")
    sh(d, "git", "checkout", "-qb", "topic")
    txt = (d / "app" / "routes.py").read_text().replace("line 3\n", "line 3 changed\nextra\n")
    (d / "app" / "routes.py").write_text(txt)
    sh(d, "git", "mv", "old_name.py", "new_name.py")
    (d / "logo.bin").write_bytes(b"\0\1\2\3")
    (d / "a" / "util.py").write_text("u\n" * 4)
    (d / "mixed.txt").write_text("a\nb\n")
    ledger.write_text("# 대장\n| NC-1 | x |\n")
    sh(d, "git", "add", "-A")
    sh(d, "git", "commit", "-qm", "change")
    # 작업트리 몫과 추적 안 된 파일
    (d / "app" / "routes.py").write_text((d / "app" / "routes.py").read_text() + "API_KEY = 'sk-live-abcdef123456'\n")
    (d / "new route.py").write_text("a\nb\n")
    (d / "한글.py").write_text("x = 1\n")
    (d / "탭\t이름.py").write_text("t\n")
    os.symlink("new_name.py", d / "link")  # git 은 링크 대상을 한 줄로 적는다 — 따라가면 5줄
    os.symlink("nowhere", d / "dang")      # 끊긴 링크: 따라가면 읽지도 못한다
    (d / "data.dat").write_text("p\nq\n")    # -diff 속성: git 은 텍스트여도 바이너리로 적는다
    (d / "mixed.txt").write_text("a\nb\nc\n")
    for tail in (b"\xff", b"\xfe"):             # UTF-8 이 아닌 이름 둘 — 풀어서 한 이름이 되면 안 된다
        (pathlib.Path(os.fsdecode(bytes(d) + b"/bin" + tail))).write_bytes(b"\0x")


def brief(d, ledger_rel, cfg=(), pin=True):
    """`cfg` 는 사용자 git 설정 흉내 — `diff.mnemonicPrefix` 면 접두가 `c/ w/ 1/ 2/` 가 된다."""
    g = ["git", *(x for c in cfg for x in ("-c", c))]
    spec = SPEC + [f":(top,exclude){ledger_rel}"]
    fix = PIN if pin else []
    b = sh(d, *g, "rev-parse", "--verify", "main^{commit}").strip()
    mb = sh(d, *g, "merge-base", b, "HEAD").strip()
    head = sh(d, *g, "rev-parse", "--short", "HEAD").strip()
    committed = sh(d, *g, "diff", *fix, f"{b}...HEAD", *spec)
    work = sh(d, *g, "diff", *fix, "HEAD", *spec)
    untracked = ""
    for f in sh(d, *g, "ls-files", "-z", "--others", "--exclude-standard", *spec).split("\0"):
        if f:
            untracked += sh(d, *g, "diff", *fix, "--no-index", "--", "/dev/null", f, ok=(0, 1))
    return (f"# 감사 브리핑\n\n- 만든 시각: 지금\n"
            f"- 기준: `main` = `{b[:7]}` (날짜 base), 머지 베이스 `{mb}`\n"
            f"- 대상: `{head}` (브랜치 `topic`)\n- 커밋 안 된 변경: 있음 — `app/routes.py`, 포함\n"
            f"- 추적 안 된 파일: `new route.py` · `한글.py` — 포함\n- 자름: 없음\n\n"
            f"## 변경 파일\n\n(stat)\n\n## 커밋\n\n(log)\n\n"
            f"## diff\n\n```diff\n{committed}\n### 작업트리\n\n{work}{untracked}```\n\n"
            f"## 이 브리핑이 담지 않은 것\n\n- 실행 결과 · 테스트 통과 여부\n")


def drop_block(text, path):
    """diff 절에서 그 경로의 블록 하나를 지운다. git 은 한글 이름을 따옴표 · 8진수로 적으므로
    검사기의 `unquote` · `header_pair` 로 `+++ b/` 줄이나 머리 줄을 풀어 맞춘다."""
    spec = importlib.util.spec_from_file_location("vb", CHECK)
    vb = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(vb)
    parts = re.split(r"^(?=diff --git |### |```)", text, flags=re.M)
    for k, blk in enumerate(parts):
        if not blk.startswith("diff --git "):
            continue
        m = re.search(r"^\+\+\+ (.*)$", blk, re.M)  # 바이너리 블록에는 없어 머리 줄로도 본다
        pair = vb.header_pair(blk.split("\n", 1)[0])
        if (m and vb.unquote(m.group(1).rstrip("\t")) == f"b/{path}") or (pair and pair[1] == f"b/{path}"):
            return "".join(parts[:k] + parts[k + 1:])
    sys.exit(f"시험 준비 실패: {path} 블록을 못 찾았다")


def run(top, cwd, text, *extra):
    f = pathlib.Path(top) / ".claude" / "audit-brief.md"
    f.parent.mkdir(exist_ok=True)
    f.write_text(text, encoding="utf-8", errors="surrogateescape")
    p = subprocess.run([sys.executable, str(CHECK), str(f), *extra], cwd=cwd, capture_output=True, text=True)
    return p.returncode, p.stdout


def main():
    bad = []
    with tempfile.TemporaryDirectory() as t:
        d = pathlib.Path(t)
        ledger_rel = "docs/audit/README.md"
        make_repo(d, d / ledger_rel)
        good = brief(d, ledger_rel)
        ex = ("--exclude", ledger_rel)
        ok = [
            ("커맨드와 같은 명령으로 만든 브리핑", good, d, ex),
            ("하위 폴더에서 돌려도", good, d / "app", ex),
            ("키를 앞 네 글자만 남기고 가려도 — 줄 수는 그대로", good.replace("sk-live-abcdef123456", "sk-l****"), d, ex),
            ("추적 안 된 파일을 「담지 않은 것」에 적고 뺐으면",
             drop_block(good, "한글.py").replace("통과 여부\n", "통과 여부\n- `한글.py` — 못 넣었다\n"), d, ex),
            ("사용자 설정이 diff.mnemonicPrefix 여도 — 접두 c/ w/ 1/ 2/",
             brief(d, ledger_rel, ("diff.mnemonicPrefix=true",)), d, ex),
            ("사용자 설정이 core.quotePath=false 여도 — 한글은 날것, 탭만 이스케이프",
             brief(d, ledger_rel, ("core.quotePath=false",)), d, ex),
            ("사용자 설정이 diff.noprefix 여도 — `a/util.py` 의 `a/` 를 벗기면 안 된다",
             brief(d, ledger_rel, ("diff.noprefix=true",)), d, ex),
            ("사용자 설정이 color.ui=always 여도 — 색 코드가 섞인 diff",
             brief(d, ledger_rel, ("color.ui=always",)), d, ex),
            ("자른 파일을 「자름: 있음」과 「담지 않은 것」에 적었으면",
             good.replace("+extra\n", "", 1).replace("- 자름: 없음", "- 자름: 있음 — 1줄")
                 .replace("통과 여부\n", "통과 여부\n- `app/routes.py` 뒷부분\n"), d, ex),
        ]
        fail = [
            ("추적 안 된 파일을 말없이 뺐다", drop_block(good, "한글.py"), d, ex),
            ("작업트리 몫을 뺐다", good.split("### 작업트리")[0] + good[good.index("diff --git a/new route.py"):], d, ex),
            ("말없이 잘랐다 — 「자름: 없음」", good.replace("+extra\n", "", 1), d, ex),
            ("잘랐다고만 하고 어느 파일인지 안 적었다",
             good.replace("+extra\n", "", 1).replace("- 자름: 없음", "- 자름: 있음"), d, ex),
            ("자른 파일 대신 이름이 비슷한 딴 파일을 적었다",
             good.replace("+extra\n", "", 1).replace("- 자름: 없음", "- 자름: 있음 — 1줄")
                 .replace("통과 여부\n", "통과 여부\n- `app/routes.py@backup`\n"), d, ex),
            ("자른 파일 대신 빈칸으로 이어지는 딴 경로를 적었다",
             good.replace("+extra\n", "", 1).replace("- 자름: 없음", "- 자름: 있음 — 1줄")
                 .replace("통과 여부\n", "통과 여부\n- `app/routes.py backup`\n"), d, ex),
            ("자른 파일 대신 백틱 두 개로 감싼 딴 경로를 적었다 — ``app/routes.py`x``",
             good.replace("+extra\n", "", 1).replace("- 자름: 없음", "- 자름: 있음 — 1줄")
                 .replace("통과 여부\n", "통과 여부\n- ``app/routes.py`x``\n"), d, ex),
            ("UTF-8 이 아닌 이름 둘 중 하나를 뺐다", drop_block(good, os.fsdecode(b"bin\xfe")), d, ex),
            ("바이너리에서 텍스트로 바뀐 파일의 작업트리 몫을 뺐다",
             good.split("### 작업트리")[0] + "### 작업트리" +
             drop_block(good.split("### 작업트리")[1], "mixed.txt"), d, ex),
            ("`--exclude '*'` 로 diff 를 통째로 비웠다 — `*` 는 이름이지 와일드카드가 아니다",
             good.split("```diff\n")[0] + "```diff\n```\n\n## 이 브리핑이 담지 않은 것\n\n- 없음\n",
             d, ex + ("--exclude", "*")),
            ("커맨드의 고정 플래그 없이 뽑았다 — 외부 diff · textconv 가 모양 · 줄 수를 바꿨다",
             brief(d, ledger_rel, pin=False), d, ex),
            ("「대상」이 지난 HEAD", re.sub(r"(- 대상: `)[0-9a-f]+", r"\g<1>0000000", good), d, ex),
            ("머지 베이스가 틀렸다", re.sub(r"(머지 베이스 `)[0-9a-f]+", r"\g<1>deadbeef", good), d, ex),
            ("git 에 없는 파일의 diff 가 섞였다",
             good.replace("### 작업트리", "diff --git a/ghost.py b/ghost.py\n--- a/ghost.py\n+++ b/ghost.py\n"
                                         "@@ -1 +1 @@\n-a\n+b\n### 작업트리"), d, ex),
            ("「담지 않은 것」 절이 없다", good.split("## 이 브리핑이 담지 않은 것")[0], d, ex),
            ("대장을 빼라는 말 없이 돌렸다 — 대장의 변경이 빠진 것으로 보여야", good, d, ()),
        ]
        for name, text, cwd, extra in ok:
            rc, out = run(d, cwd, text, *extra)
            if rc != 0:
                bad.append(f"통과해야 했다 — {name}\n{out}")
        for name, text, cwd, extra in fail:
            rc, out = run(d, cwd, text, *extra)
            if rc != 1 or not out.startswith("FAIL"):  # 예외로 죽어도 종료 1 이다 — 판정으로 떨어져야
                bad.append(f"떨어져야 했다 — {name} (종료 {rc})\n{out}")
        # 빈 제외는 `:(top,exclude)` 가 되어 모든 경로를 뺀다 — 쓰는 법 오류로 멈춰야
        for extra in (("--exclude",), ("--exclude", ""), ("--exclude", "/")):
            rc, out = run(d, d, good, *extra)
            if rc != 2:
                bad.append(f"쓰는 법 오류여야 했다 — {extra} (종료 {rc})\n{out}")
    if bad:
        print(f"FAIL verify-brief.py 가 {len(bad)}건에서 틀렸다")
        for b in bad:
            print("  - " + b.replace("\n", "\n    "))
        return 1
    print(f"PASS verify-brief.py — 통과 {len(ok)} · 떨어짐 {len(fail)} 모양 모두 맞다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
