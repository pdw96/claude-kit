#!/usr/bin/env python3
"""`/audit-brief` 가 쓴 브리핑을 **저장소의 git 출력과 직접** 견준다. 모델도 API 도 안 쓴다.

  python3 verify-brief.py <브리핑 파일> [--exclude <경로>]...

저장소 최상위에서 돌린다(하위 폴더에서 돌려도 최상위를 찾아 거기서 git 을 부른다).
`--exclude` 는 레포가 따로 둔 대장처럼 diff 에서 뺀 경로다 — 커맨드가 뺀 것과 같게 준다.

**왜 모양이 아니라 git 인가.** 예전 검사기는 모델이 쓴 마크다운의 모양을 정규식으로
봤다. 모양을 지키고 내용이 틀린 브리핑은 늘 더 만들 수 있어, 리뷰가 26차까지 가도
지적이 줄지 않았다(evals/README.md 「브리핑 검사기를 떼고, 러너를 고정했다」). 여기서는
브리핑이 **무엇을 담았다고 하는지**만 읽고, 담았어야 할 것은 git 에게 다시 묻는다.

보는 것:

- 「대상」 SHA 가 지금 HEAD 인가 — 지난 회차의 브리핑이면 그 diff 는 이번 근거가 아니다
- 「기준」 SHA 가 커밋이고, 적힌 머지 베이스가 git 이 구한 것과 같은가
- git 이 말하는 변경 파일(커밋된 몫 · 작업트리 · 추적 안 된 파일)이 **하나도 빠짐없이**
  diff 절에 있거나 「담지 않은 것」에 이름이 적혀 있는가
- 담은 파일마다 +/- 줄 수가 git 의 `--numstat` 과 같은가 — 다르면 잘린 것이므로
  「자름: 있음」이고 그 파일이 「담지 않은 것」에 적혀 있어야 한다
- git 에 없는 파일의 diff 가 들어 있지 않은가 — 지난 회차나 다른 기준의 것이 섞인 것이다

키 · 토큰을 앞 네 글자만 남기고 가려도 줄 수는 그대로라 대조는 견딘다. 바이너리
파일은 줄 수가 없어 있는지만 본다.

보지 않는 것: 줄의 **내용**(가림과 부딪힌다), 커밋된 몫과 작업트리 몫을 제 소절에
나눠 담았는지(파일마다 합쳐서 센다), 「변경 파일」 · 「커밋」 절의 내용.

종료 코드: 0 통과, 1 불일치, 2 쓰는 법 · git 오류. 표준 라이브러리만 쓴다.
"""
import os
import pathlib
import re
import subprocess
import sys

DEFAULT_EXCLUDE = (".claude/audits", ".claude/briefs", ".claude/audit-brief.md")
SECTIONS = ("## 변경 파일", "## 커밋", "## diff", "## 이 브리핑이 담지 않은 것")


def git(top, *args):
    p = subprocess.run(["git", "-C", str(top), *args], capture_output=True)
    if p.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} 실패: {p.stderr.decode(errors='replace').strip()}")
    return p.stdout


ESC = {"a": 7, "b": 8, "t": 9, "n": 10, "v": 11, "f": 12, "r": 13, '"': 34, "\\": 92}


def unquote(s):
    """git 이 따옴표로 감싼 경로(`"a/\\355\\225\\234.py"`)를 C 식으로 푼다. 안 감쌌으면 그대로.
    `\\ooo` 는 바이트, `\\t` 따위는 제 글자, 나머지 글자는 UTF-8 로 모아 한 번에 푼다 —
    `core.quotePath=false` 로 한글이 날것으로 남고 탭만 이스케이프된 이름도 풀린다."""
    if not (len(s) >= 2 and s[0] == s[-1] == '"'):
        return s
    body, out, i = s[1:-1], bytearray(), 0
    while i < len(body):
        if body[i] == "\\" and re.fullmatch(r"[0-7]{3}", body[i + 1:i + 4]):
            out.append(int(body[i + 1:i + 4], 8) & 0xFF)
            i += 4
        elif body[i] == "\\" and body[i + 1:i + 2] in ESC:
            out.append(ESC[body[i + 1]])
            i += 2
        else:
            out += body[i].encode("utf-8")
            i += 1
    return out.decode("utf-8", errors="replace")


def unprefix(p):
    """`a/` · `b/` 만이 아니라 `diff.mnemonicPrefix` 의 `c/ w/ i/ o/ 1/ 2/` 도 벗긴다. 한 겹만."""
    return p[2:] if re.match(r"[abciwo12]/", p) else p


def section(text, head):
    m = re.search(rf"^{re.escape(head)}[ \t]*\n([\s\S]*?)(?=^## |\Z)", text, re.M)
    return m.group(1) if m else None


HUNK = re.compile(r"^@@ -\d+(?:,(\d+))? \+\d+(?:,(\d+))? @@")


def parse_diff(body):
    """diff 절에서 파일마다 (+, -) 줄 수를 모은다. 같은 경로가 두 번(커밋 몫 · 작업트리 몫)
    나오면 더한다. 헝크 안의 줄은 `@@ -a,b +c,d @@` 가 적은 수만큼만 먹는다 — 줄 모양으로
    짐작하지 않으므로 헝크 뒤에 붙은 글 · 헝크 안의 `--- a/` 모양 줄에 흔들리지 않는다.
    경로는 `+++ b/` · `rename to` · `--- a/` · 머리 줄 순서로 잡는다."""
    counts = {}
    for blk in re.split(r"^(?=diff --git )", body, flags=re.M):
        if not blk.startswith("diff --git "):
            continue
        lines = [ln for ln in blk.split("\n") if not ln.startswith("```")]
        head, path, minus_path = lines[0], None, None
        add = rem = old_left = new_left = 0
        for ln in lines[1:]:
            if old_left > 0 or new_left > 0:
                if ln.startswith("\\"):
                    continue
                if ln.startswith("+"):
                    add, new_left = add + 1, new_left - 1
                elif ln.startswith("-"):
                    rem, old_left = rem + 1, old_left - 1
                else:
                    old_left, new_left = old_left - 1, new_left - 1
                continue
            h = HUNK.match(ln)
            if h:
                old_left = int(h.group(1)) if h.group(1) is not None else 1
                new_left = int(h.group(2)) if h.group(2) is not None else 1
            elif ln.startswith("+++ "):
                p = unquote(ln[4:].rstrip("\t"))
                if p != "/dev/null":
                    path = unprefix(p)
            elif ln.startswith("--- "):
                p = unquote(ln[4:].rstrip("\t"))
                if p != "/dev/null":
                    minus_path = unprefix(p)
            elif ln.startswith("rename to ") and path is None:
                path = unquote(ln[len("rename to "):])
        if path is None:
            path = minus_path
        if path is None:  # 모드만 바뀐 파일 · 내용 없는 새 파일: 머리 줄 `a/P b/P` 에서 가른다
            s = head[len("diff --git "):]
            m = re.fullmatch(r'("(?:[^"\\]|\\.)*") ("(?:[^"\\]|\\.)*")', s)
            if m:
                path = unprefix(unquote(m.group(2)))
            elif (len(s) - 5) % 2 == 0:
                n = (len(s) - 5) // 2
                if re.match(r"[abciwo12]/", s) and re.match(r" [abciwo12]/", s[2 + n:]) \
                        and s[5 + n:] == s[2:2 + n]:
                    path = s[2:2 + n]
        if path is None:
            continue
        a, r = counts.get(path, (0, 0))
        counts[path] = (a + add, r + rem)
    return counts


def named(text, path):
    """「담지 않은 것」에 그 경로가 **따로** 적혀 있는가 — `a.py` 가 `data.py` 에도,
    `app/routes.py@backup` 에도 걸리지 않게. 앞뒤는 줄 끝 · 빈칸 · 따옴표 · 괄호 · 쉼표 따위만
    받고, 마침표는 뒤에 빈칸 · 줄 끝이 올 때(문장 끝)만 받는다."""
    before = r"(?:^|(?<=[\s`'\"(\[{<,;:·]))"
    after = r"(?=$|[\s`'\")\]}>,;:·—]|\.(?:\s|$))"
    return re.search(before + re.escape(path) + after, text, re.M) is not None


def numstat(top, *args):
    """`git diff --numstat -z` → {경로: (+, -) 또는 None(바이너리)}. 이름 바꿈은 새 이름으로."""
    out = git(top, "diff", "--numstat", "-z", *args).decode("utf-8", errors="replace")
    res, parts, i = {}, out.split("\0"), 0
    while i < len(parts):
        rec = parts[i]
        if not rec:
            i += 1
            continue
        a, d, path = rec.split("\t", 2)
        if path == "":  # 이름 바꿈: 다음 둘이 옛 이름 · 새 이름
            path = parts[i + 2]
            i += 3
        else:
            i += 1
        res[path] = None if a == "-" else (int(a), int(d))
    return res


def expected(top, mb, excludes):
    spec = ["--", ":/"] + [f":(top,exclude){e}" for e in excludes]
    want = {}

    def add(path, c):
        if path in want and want[path] is not None and c is not None:
            want[path] = (want[path][0] + c[0], want[path][1] + c[1])
        else:
            want[path] = c if path not in want else None

    for path, c in numstat(top, f"{mb}..HEAD", *spec).items():
        add(path, c)
    for path, c in numstat(top, "HEAD", *spec).items():
        add(path, c)
    for path in git(top, "ls-files", "-z", "--others", "--exclude-standard", *spec).decode(
            "utf-8", errors="replace").split("\0"):
        if not path:
            continue
        f = top / path
        if f.is_symlink():  # git 은 링크를 따라가지 않고 대상 경로 한 줄을 적는다
            add(path, (1, 0) if os.readlink(f) else (0, 0))
            continue
        if not f.is_file():  # 안에 든 저장소 따위: 있는지만 본다
            add(path, None)
            continue
        data = f.read_bytes()
        lines = data.count(b"\n") + (1 if data and not data.endswith(b"\n") else 0)
        add(path, None if b"\0" in data[:8000] else (lines, 0))
    return want


def main(argv):
    args, excludes = [], list(DEFAULT_EXCLUDE)
    it = iter(argv[1:])
    for a in it:
        if a == "--exclude":
            excludes.append(next(it, "").strip("/"))
        elif a.startswith("-"):
            print(__doc__)
            return 2
        else:
            args.append(a)
    if len(args) != 1:
        print(__doc__)
        return 2
    brief = pathlib.Path(args[0])
    try:
        text = brief.read_text(encoding="utf-8")
        top = pathlib.Path(git(pathlib.Path.cwd(), "rev-parse", "--show-toplevel").decode().strip())
        head = git(top, "rev-parse", "HEAD").decode().strip()
    except (OSError, RuntimeError) as e:
        print(f"ERROR {e}")
        return 2

    bad = []
    for s in SECTIONS:
        if section(text, s) is None:
            bad.append(f"절이 없다: {s}")

    m = re.search(r"^- 대상:\s*`([0-9a-f]{4,40})`", text, re.M)
    if not m:
        bad.append("「대상」 줄에 HEAD 짧은 SHA 가 없다")
    elif not head.startswith(m.group(1)):
        bad.append(f"「대상」 {m.group(1)} 이 지금 HEAD {head[:12]} 가 아니다 — 지난 회차의 브리핑이다")

    mb = None
    base = re.search(r"^- 기준:.*?=\s*`([0-9a-f]{4,40})`", text, re.M)
    mbw = re.search(r"^- 기준:.*머지 베이스\s*`([0-9a-f]{4,40})`", text, re.M)
    if not base or not mbw:
        bad.append("「기준」 줄에 기준 SHA 와 머지 베이스가 없다")
    else:
        try:
            b = git(top, "rev-parse", "--verify", f"{base.group(1)}^{{commit}}").decode().strip()
            mb = git(top, "merge-base", b, "HEAD").decode().strip()
            if not mb.startswith(mbw.group(1)):
                bad.append(f"적힌 머지 베이스 {mbw.group(1)} 가 git 이 구한 {mb[:12]} 가 아니다")
                mb = None
        except RuntimeError as e:
            bad.append(f"기준 {base.group(1)} 을 풀지 못했다 — {e}")

    cut = re.search(r"^- 자름:\s*(없음|있음)", text, re.M)
    if not cut:
        bad.append("「자름」 줄이 없음 · 있음 으로 시작하지 않는다")

    body = section(text, "## diff")
    omitted = section(text, "## 이 브리핑이 담지 않은 것") or ""
    if mb and body is not None:
        got = parse_diff(body)
        want = expected(top, mb, excludes)
        for path in sorted(want):
            if path not in got:
                if not named(omitted, path):
                    bad.append(f"빠졌다: {path} — git 은 바뀌었다고 하는데 diff 에도 「담지 않은 것」에도 없다")
                continue
            if want[path] is not None and got[path] != want[path]:
                if not named(omitted, path) or not cut or cut.group(1) != "있음":
                    bad.append(f"줄 수가 다르다: {path} — 브리핑 +{got[path][0]}/-{got[path][1]}, "
                               f"git +{want[path][0]}/-{want[path][1]}. 잘랐으면 「자름: 있음」과 "
                               f"「담지 않은 것」에 적어야 한다")
        for path in sorted(set(got) - set(want)):
            bad.append(f"git 에 없는 변경이 있다: {path} — 다른 기준 · 지난 회차의 diff 가 섞였다")

    if bad:
        print(f"FAIL {brief} — {len(bad)}건")
        for b in bad:
            print(f"  - {b}")
        return 1
    print(f"PASS {brief} — git 과 파일 · 줄 수가 맞다 (HEAD {head[:12]}, 머지 베이스 {mb[:12]})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
