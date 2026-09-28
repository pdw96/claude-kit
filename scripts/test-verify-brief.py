#!/usr/bin/env python3
"""`vibe-audit/scripts/verify-brief.py` 가 **무는지** 본다. 모델도 API 도 안 쓴다.

  python3 scripts/test-verify-brief.py

임시 저장소를 만들어 커밋된 변경 · 작업트리 변경 · 추적 안 된 파일(빈칸 · 한글 · 탭 이름,
심볼릭 링크 · 끊긴 링크 · `-diff` 속성 · UTF-8 이 아닌 이름 둘) · 바이너리 · 바이너리에서
텍스트로(또 그 반대로) 바뀐 파일 · 이름 바꿈 · 복사 · 서브모듈(gitlink, 작업트리만 더러운 것 포함) · 줄바꿈 든 이름 ·
안에 든 저장소 · 이름 바꾼 뒤 고친 파일 · 종류가 바뀐 파일(파일→링크) · `a/` 로 시작하는 폴더 ·
대장 파일을 두고(저장소 폴더 이름도 UTF-8 이 아니다), 외부 diff · 줄 수를 바꾸는 textconv ·
복사 찾기 · 서브모듈 무시를 켠 저장소에서(SHA-256 저장소 하나 더), `/audit-brief` 커맨드와 **같은 git 명령**으로
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
PIN = ["--no-ext-diff", "--no-textconv", "--submodule=short", "--ignore-submodules=none", "--no-color"]  # 커맨드가 붙이는 것
SPEC = ["--", ":/", ":(top,exclude).claude/audits", ":(top,exclude).claude/briefs",
        ":(top,exclude).claude/audit-brief.md"]


def sh(cwd, *args, ok=(0,)):
    p = subprocess.run(args, cwd=cwd, capture_output=True,
                       env={**os.environ, "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t",
                            "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@t"})
    if p.returncode not in ok:
        sys.exit(f"준비 실패: {' '.join(map(str, args))}\n{p.stderr.decode(errors='replace')}")
    return p.stdout.decode("utf-8", "surrogateescape")  # 줄 끝을 바꾸지 않는다 — 맨 `\r` 을 지킨다


def make_repo(d, ledger, fmt="sha1"):
    sh(d, "git", "init", "-q", "-b", "main", f"--object-format={fmt}")
    oid = 40 if fmt == "sha1" else 64
    # 커맨드가 `--no-ext-diff --no-textconv` 로 막는 설정 — 막지 않으면 diff 가 비거나 줄 수가 바뀐다
    sh(d, "git", "config", "diff.external", "true")
    sh(d, "git", "config", "diff.drop.textconv", "grep -v line <")
    sh(d, "git", "config", "diff.renames", "copies")        # 복사 블록은 `copy to` 만 있고 `+++` 가 없다
    sh(d, "git", "config", "diff.ignoreSubmodules", "all")  # 막지 않으면 서브모듈 변경이 양쪽에서 사라진다
    (d / "app").mkdir()
    (d / "app" / "routes.py").write_text("".join(f"line {i}\n" for i in range(30)))
    (d / "old_name.py").write_text("keep\n" * 5)
    (d / "logo.bin").write_bytes(b"\0\1\2")
    (d / "a").mkdir()  # diff.noprefix 면 `a/util.py` 의 `a/` 는 접두가 아니라 경로다
    (d / "a" / "util.py").write_text("u\n" * 3)
    (d / ".gitattributes").write_text("*.dat -diff\n*.py diff=drop\n")
    (d / "mixed.txt").write_bytes(b"\0\1")  # 커밋 몫은 바이너리, 작업트리 몫은 텍스트
    (d / "flip.txt").write_text("a\nb\n")     # 커밋 몫은 텍스트, 작업트리 몫은 바이너리
    (d / "tmpl.py").write_text("t\n" * 5)
    (d / "cr.txt").write_bytes(b"a\rb\nold\n")  # 헝크 안의 맨 `\r` — 줄로 읽으면 헝크 수가 어긋난다
    (d / "staged.py").write_text("s\n")      # 작업트리에서 스테이지 몫을 되돌린다
    (d / "conf.txt").write_text("x\n")       # 풀지 않은 머지 — 작업트리 몫은 `diff --cc` 블록
    (d / "gone.txt").write_text("g\n")       # 수정/삭제 충돌 — 블록 없이 `* Unmerged path` 줄만
    (d / '"gone.txt"').write_text("g\n")     # 그 줄은 경로를 날것으로 적는다 — 풀면 gone.txt 와 겹친다
    (d / "gone.txt\nx").write_text("g\n")   # 줄바꿈 든 이름 — 그 줄이 두 줄에 걸치고 앞머리가 gone.txt 다
    (d / "del\nme.txt").write_text("g\n")   # 줄바꿈 든 이름 — 첫 줄 `del` 은 충돌 경로가 아니다
    (d / "x\ndiff --git foo foo").write_text("g\n")  # 그 줄의 둘째 줄이 diff 블록 머리 모양이다
    (d / "cr\r").write_text("g\n")          # 맨 `\r` 로 끝나는 이름 — 그 줄 끝이 `\r\n` 이 된다
    (d / "kind.txt").write_text("k\n")         # 작업트리에서 링크로 바뀐다 — 패치 블록 둘, numstat 한 줄
    (d / "sub").mkdir()                       # 빈 폴더 = 꺼내지 않은 서브모듈
    sh(d, "git", "init", "-q", f"--object-format={fmt}", "dsub")  # 꺼낸 서브모듈 — 작업트리만 더럽힌다
    (d / "dsub" / "f").write_text("f\n")
    sh(d / "dsub", "git", "add", "f")
    sh(d / "dsub", "git", "commit", "-qm", "f")
    ledger.parent.mkdir(parents=True, exist_ok=True)
    ledger.write_text("# 대장\n")
    sh(d, "git", "add", "-A")
    sh(d, "git", "update-index", "--add", "--cacheinfo", f"160000,{'1' * oid},sub")
    sh(d, "git", "commit", "-qm", "base")
    sh(d, "git", "checkout", "-qb", "topic")
    txt = (d / "app" / "routes.py").read_text().replace("line 3\n", "line 3 changed\nextra\n")
    (d / "app" / "routes.py").write_text(txt)
    sh(d, "git", "mv", "old_name.py", "new_name.py")
    (d / "logo.bin").write_bytes(b"\0\1\2\3")
    (d / "a" / "util.py").write_text("u\n" * 4)
    (d / "mixed.txt").write_text("a\nb\n")
    (d / "conf.txt").write_text("y\n")
    (d / "gone.txt").unlink()
    (d / '"gone.txt"').unlink()
    (d / "gone.txt\nx").unlink()
    (d / "del\nme.txt").unlink()
    (d / "x\ndiff --git foo foo").unlink()
    (d / "cr\r").unlink()
    (d / "cr.txt").write_bytes(b"a\rb\nnew\n")
    (d / "flip.txt").write_text("a\nbb\n")
    (d / "tmpl_copy.py").write_text((d / "tmpl.py").read_text())
    (d / "tmpl.py").write_text("t\n" * 6)
    ledger.write_text("# 대장\n| NC-1 | x |\n")
    sh(d, "git", "add", "-A")
    sh(d, "git", "update-index", "--cacheinfo", f"160000,{'2' * oid},sub")
    sh(d, "git", "commit", "-qm", "change")
    # 딴 가지에서 conf.txt 를 달리 고쳐 머지하다 멈춘다(충돌)
    sh(d, "git", "checkout", "-q", "-b", "other", "main")
    (d / "conf.txt").write_text("z\n")
    (d / "gone.txt").write_text("g\nmore\n")
    (d / '"gone.txt"').write_text("g\nmore\n")
    (d / "gone.txt\nx").write_text("g\nmore\n")
    (d / "del\nme.txt").write_text("g\nmore\n")
    (d / "x\ndiff --git foo foo").write_text("g\nmore\n")
    (d / "cr\r").write_text("g\nmore\n")
    sh(d, "git", "commit", "-qam", "other")
    sh(d, "git", "checkout", "-q", "topic")
    sh(d, "git", "merge", "-q", "other", ok=(1,))
    # 작업트리 몫과 추적 안 된 파일
    (d / "app" / "routes.py").write_text((d / "app" / "routes.py").read_text() + "API_KEY = 'sk-live-abcdef123456'\n")
    (d / "new route.py").write_text("a\nb\n")
    (d / "한글.py").write_text("x = 1\n")
    (d / "탭\t이름.py").write_text("t\n")
    os.symlink("new_name.py", d / "link")  # git 은 링크 대상을 한 줄로 적는다 — 따라가면 5줄
    os.symlink("nowhere", d / "dang")      # 끊긴 링크: 따라가면 읽지도 못한다
    (d / "data.dat").write_text("p\nq\n")    # -diff 속성: git 은 텍스트여도 바이너리로 적는다
    (d / "mixed.txt").write_text("a\nb\nc\n")
    (d / "flip.txt").write_bytes(b"\0\0")
    (d / "staged.py").write_text("SECRET = 1\n")  # 스테이지하고 작업트리만 되돌린다 — `git diff HEAD` 는 비고
    sh(d, "git", "add", "staged.py")               # 다음 커밋에는 SECRET 이 들어간다
    (d / "staged.py").write_text("s\n")
    (d / "new_name.py").write_text("keep\n" * 5 + "more\n")  # 커밋 몫은 이름만 바꿈(줄 없음), 작업트리 몫은 줄
    (d / "kind.txt").unlink()
    os.symlink("tmpl.py", d / "kind.txt")
    (d / "줄\n바꿈.py").write_text("n\n")
    (d / "dsub" / "f").write_text("dirty\n")  # 기록된 커밋은 그대로 — numstat 0/0, 패치는 `-dirty` 두 줄
    if os.geteuid() != 0:                    # 못 읽는 파일 — 커맨드도 diff 를 못 떠 「담지 않은 것」에(root 는 다 읽는다)
        (d / "locked.py").write_text("l\n")
        (d / "locked.py").chmod(0)
    (d / "q").write_text("q\n")          # `"q"` 스팬은 그대로는 `"q"`, 풀면 `q` — 어느 쪽인지 모른다
    (d / '"q"').write_text("q\n")
    sh(d / "app", "git", "init", "-q", str(d / "inner"))  # 안에 든 저장소: `inner/` 로 나오고 diff 는 못 뜬다
    (d / "inner" / "z").write_text("z\n")
    for tail in (b"\xff", b"\xfe"):             # UTF-8 이 아닌 이름 둘 — 풀어서 한 이름이 되면 안 된다
        (pathlib.Path(os.fsdecode(bytes(d) + b"/bin" + tail))).write_bytes(b"\0x")


def brief(d, ledger_rel, cfg=(), pin=True, name_skipped=True, head_only=False, base="main"):
    """`cfg` 는 사용자 git 설정 흉내 — `diff.mnemonicPrefix` 면 접두가 `c/ w/ 1/ 2/` 가 된다."""
    g = ["git", *(x for c in cfg for x in ("-c", c))]
    spec = SPEC + [f":(top,literal,exclude){ledger_rel}"]  # 커맨드가 대장을 빼는 모양
    fix = PIN if pin else []
    b = sh(d, *g, "rev-parse", "--verify", f"{base}^{{commit}}").strip()
    mb = sh(d, *g, "merge-base", b, "HEAD").strip()
    head = sh(d, *g, "rev-parse", "--short", "HEAD").strip()
    committed = sh(d, *g, "diff", *fix, f"{b}...HEAD", *spec)
    if head_only:  # 옛 커맨드 모양 — 스테이지 몫이 작업트리 되돌림과 상쇄된다
        work = sh(d, *g, "diff", *fix, "HEAD", *spec)
    else:          # 커맨드: 인덱스 몫과 작업트리 몫을 따로
        work = sh(d, *g, "diff", *fix, "--cached", *spec) + sh(d, *g, "diff", *fix, *spec)
    untracked, skipped = "", []
    for f in sh(d, *g, "ls-files", "-z", "--others", "--exclude-standard", *spec).split("\0"):
        if f and (not ((d / f).is_file() or (d / f).is_symlink())  # 커맨드의 `[ -f ] || [ -L ] || continue`
                  or not ((d / f).is_symlink() or os.access(d / f, os.R_OK))):  # 못 읽으면 못 넣는다
            skipped.append(f)
        elif f:
            untracked += sh(d, *g, "diff", *fix, "--no-index", "--", "/dev/null", f, ok=(0, 1))
    return (f"# 감사 브리핑\n\n- 만든 시각: 지금\n"
            f"- 기준: `main` = `{b[:7]}` (날짜 base), 머지 베이스 `{mb}`\n"
            f"- 대상: `{head}` (브랜치 `topic`)\n- 커밋 안 된 변경: 있음 — `app/routes.py`, 포함\n"
            f"- 추적 안 된 파일: `new route.py` · `한글.py` — 포함\n- 자름: 없음\n\n"
            f"## 변경 파일\n\n(stat)\n\n## 커밋\n\n(log)\n\n"
            f"## diff\n\n```diff\n{committed}\n### 작업트리\n\n{work}{untracked}```\n\n"
            f"## 이 브리핑이 담지 않은 것\n\n- 실행 결과 · 테스트 통과 여부\n"
            + "".join(f"- `{f}` — 파일이 아니라 건너뜀\n" for f in skipped if name_skipped))


def _find_block(text, path):
    """diff 절을 블록으로 가르고, 그 경로의 첫 블록 번호를 준다. git 은 한글 이름을 따옴표 · 8진수로
    적으므로 검사기의 `unquote` · `header_pair` 로 `+++ b/` 줄이나 머리 줄을 풀어 맞춘다."""
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
            return parts, k
    sys.exit(f"시험 준비 실패: {path} 블록을 못 찾았다")


def drop_block(text, path):
    """diff 절에서 그 경로의 블록 하나를 지운다."""
    parts, k = _find_block(text, path)
    return "".join(parts[:k] + parts[k + 1:])


def _block(text, path):
    """diff 절에서 그 경로의 첫 블록을 그대로 꺼낸다(블록을 두 번 넣는 변조용)."""
    parts, k = _find_block(text, path)
    return parts[k]


def run(top, cwd, text, *extra):
    f = pathlib.Path(top) / ".claude" / "audit-brief.md"
    f.parent.mkdir(exist_ok=True)
    f.write_text(text, encoding="utf-8", errors="surrogateescape")
    p = subprocess.run([sys.executable, str(CHECK), str(f), *extra], cwd=cwd, capture_output=True, text=True)
    return p.returncode, p.stdout


def main():
    bad = []
    with tempfile.TemporaryDirectory() as t, tempfile.TemporaryDirectory() as t256:
        # 폴더 이름도 UTF-8 이 아니고 빈칸으로 끝난다
        d, d256 = pathlib.Path(t) / os.fsdecode(b"repo\xff "), pathlib.Path(t256)
        d.mkdir()
        ledger_rel = "*"  # 대장 이름이 와일드카드 글자여도 커맨드 · 검사기가 이름 그대로 뺀다
        make_repo(d, d / ledger_rel)
        good = brief(d, ledger_rel)
        good_head = brief(d, ledger_rel, base="HEAD")
        make_repo(d256, d256 / ledger_rel, "sha256")
        good256 = brief(d256, ledger_rel)
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
            ("줄바꿈이 든 이름을 git 의 따옴표 모양으로 「담지 않은 것」에 적고 뺐으면",
             drop_block(good, "줄\n바꿈.py").replace("통과 여부\n", '통과 여부\n- `"줄\\n바꿈.py"`\n'), d, ex),
            ("SHA-256 저장소 — 머지 베이스가 64자", good256, d256, ex),
            ("CRLF 로 저장한 브리핑 — 맨 `\\r` 은 그대로", good.replace("\n", "\r\n"), d, ex),
            ("기준이 HEAD 라 커밋된 몫이 없는데 충돌의 cc 블록을 잘라 「담지 않은 것」에 적었으면",
             re.sub(r"^diff --cc conf\.txt\n(?:(?!diff --|### |```|\* Unmerged path ).*\n)*", "", good_head, count=1, flags=re.M)
                 .replace("- 자름: 없음", "- 자름: 있음 — conf.txt 블록").replace("통과 여부\n", "통과 여부\n- `conf.txt`\n"),
             d, ex),
            ("기준이 HEAD 라 커밋된 몫이 없는 수정/삭제 충돌의 표시를 통째로 빼고 「담지 않은 것」에 적었으면 — 자름이 아니다",
             re.sub(r"^\* Unmerged path gone\.txt\n(?!x\n)", "", good_head, flags=re.M)
                 .replace("통과 여부\n", "통과 여부\n- `gone.txt`\n"), d, ex),
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
            ("건너뛴 안의 저장소를 「담지 않은 것」에 안 적었다", brief(d, ledger_rel, name_skipped=False), d, ex),
            ("텍스트 → 바이너리로 바뀐 파일의 작업트리 몫(바이너리 블록)을 뺐다",
             good.split("### 작업트리")[0] + "### 작업트리" +
             drop_block(good.split("### 작업트리")[1], "flip.txt"), d, ex),
            ("서브모듈 변경을 뺐다", drop_block(good, "sub"), d, ex),
            ("작업트리만 더러운 서브모듈의 블록을 뺐다",
             good.split("### 작업트리")[0] + "### 작업트리" +
             drop_block(good.split("### 작업트리")[1], "dsub"), d, ex),
            ("수정/삭제 충돌의 `* Unmerged path` 줄을 뺐다",
             re.sub(r"^\* Unmerged path gone\.txt\n(?!x\n)", "", good, flags=re.M), d, ex),
            ('`* Unmerged path "gone.txt"` 줄을 `gone.txt` 로 바꿨다 — 날것 경로가 겹치면 안 된다',
             good.replace('* Unmerged path "gone.txt"\n', "* Unmerged path gone.txt\n"), d, ex),
            ("`* Unmerged path` 줄을 더 넣고 「담지 않은 것」으로 덮었다 — 면제는 모자란 것만",
             good.replace("* Unmerged path gone.txt\n", "* Unmerged path gone.txt\n" * 2, 1)
                 .replace("통과 여부\n", "통과 여부\n- `gone.txt`\n"), d, ex),
            ("수정/삭제 충돌의 `* Unmerged path` 줄 둘 중 하나만 빼고 「담지 않은 것」에 적었다 — 「자름: 없음」",
             good.replace("* Unmerged path gone.txt\n", "", 1).replace("통과 여부\n", "통과 여부\n- `gone.txt`\n"), d, ex),
            ("충돌 경로의 커밋된 몫은 담고 표시만 통째로 빼 「담지 않은 것」에 적었다 — 「자름: 없음」",
             re.sub(r"^\* Unmerged path gone\.txt\n(?!x\n)", "", good, flags=re.M)
                 .replace("통과 여부\n", "통과 여부\n- `gone.txt`\n"), d, ex),
            ("줄바꿈 든 이름의 `* Unmerged path` 줄을 앞머리 이름(gone.txt)의 줄로 바꿨다",
             good.replace("* Unmerged path gone.txt\nx\n", "* Unmerged path gone.txt\n"), d, ex),
            ("풀지 않은 머지의 `diff --cc` 블록을 뺐다",
             re.sub(r"^diff --cc conf\.txt\n(?:(?!diff --|### |```|\* Unmerged path ).*\n)*", "", good, count=1, flags=re.M), d, ex),
            ("이름 바꿈 블록(줄 없음)을 뺐다 — 작업트리 몫이 줄 수를 채운다",
             drop_block(good.split("### 작업트리")[0], "new_name.py") + "### 작업트리" +
             good.split("### 작업트리")[1], d, ex),
            ("`## diff` 가 두 번 — 뒤의 것에 git 에 없는 블록",
             good.replace("## 이 브리핑이 담지 않은 것", "## diff\n\n```diff\ndiff --git a/ghost.py b/ghost.py\n"
                          "--- a/ghost.py\n+++ b/ghost.py\n@@ -1 +1 @@\n-a\n+b\n```\n\n## 이 브리핑이 담지 않은 것"),
             d, ex),
            ("같은 블록을 두 번 넣고 「자름: 있음」 · 「담지 않은 것」으로 덮었다 — 자름은 많은 것을 못 푼다",
             good.replace("### 작업트리", _block(good, "app/routes.py") + "### 작업트리", 1)
                 .replace("- 자름: 없음", "- 자름: 있음 — 0줄")
                 .replace("통과 여부\n", "통과 여부\n- `app/routes.py`\n"), d, ex),
            ("`git diff HEAD` 하나로 작업트리 몫을 뽑았다 — 되돌린 작업트리가 스테이지한 SECRET 을 가린다",
             brief(d, ledger_rel, head_only=True), d, ex),
            ("머리의 「자름」 줄이 둘 — 뒤의 것은 검사되지 않는다",
             good.replace("- 자름: 없음\n", "- 자름: 없음\n- 자름: 있음\n"), d, ex),
            ("`## diff` 가 파일 끝에 빈 채로 — 줄바꿈 없이",
             good.split("## diff\n")[0] + "## 이 브리핑이 담지 않은 것\n\n- 없음\n\n## diff", d, ex),
            ('`q` 와 `"q"` 를 다 빼고 `"q"` 스팬 하나로 덮었다 — 한 스팬이 두 경로에 맞는다',
             drop_block(drop_block(good, "q"), '"q"').replace("통과 여부\n", '통과 여부\n- `"q"`\n'), d, ex),
            ("「자름」을 머리에서 빼고 본문에만 적었다",
             good.replace("+extra\n", "", 1).replace("- 자름: 없음\n", "")
                 .replace("통과 여부\n", "통과 여부\n- 자름: 있음\n- `app/routes.py` 뒷부분\n"), d, ex),
            ("「대상」이 지난 HEAD", re.sub(r"(- 대상: `)[0-9a-f]+", r"\g<1>0000000", good), d, ex),
            ("머지 베이스가 틀렸다", re.sub(r"(머지 베이스 `)[0-9a-f]+", r"\g<1>deadbeef", good), d, ex),
            ("git 에 없는 파일의 diff 가 섞였다",
             good.replace("### 작업트리", "diff --git a/ghost.py b/ghost.py\n--- a/ghost.py\n+++ b/ghost.py\n"
                                         "@@ -1 +1 @@\n-a\n+b\n### 작업트리"), d, ex),
            ("「담지 않은 것」 절이 없다", good.split("## 이 브리핑이 담지 않은 것")[0], d, ex),
            ("대장을 빼라는 말 없이 돌렸다 — 대장의 변경이 빠진 것으로 보여야", good, d, ()),
        ]
        for name, text, cwd, extra in ok:
            rc, out = run(d256 if cwd == d256 else d, cwd, text, *extra)
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
