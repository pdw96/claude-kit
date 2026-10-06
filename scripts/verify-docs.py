#!/usr/bin/env python3
"""문서의 모양 — 절 제목 · 경로 · 조각 나눔 · 닫는 기록 — 을 대조한다. 모델도 네트워크도 git 도 안 쓴다.

  python3 scripts/verify-docs.py            # 이 저장소
  python3 scripts/verify-docs.py <루트>      # 다른 폴더 — 자체 시험이 베낀 트리로 쓴다

**왜 있나.** 절차 지도(`docs/procedure.md`)는 문서의 모양을 앵커볼트로 정했는데, 어겨도 떨어지는
검사가 없었다. 조각 2 착공 PR 안에서 문서 자리가 두 번 옮겨졌고, 가리키는 줄은 사람이 손으로
따라 고쳤다. 사람이 기억하는 검사는 건너뛴다.

**무엇을 보장하나.** `docs/slices/3-doc-check/design.md` ② 가 든다. 실패 줄의 `[O1]` 같은 번호가
그 보장의 번호다 — 여기 따로 옮겨 적지 않는다.

**모양의 원천은 `docs/procedure.md` 다.** 필수 제목은 그 파일의 「…의 칸」 표에서 읽는다. 여기에
있는 것은 그 표를 찾는 네 절 이름뿐이고, 그 자리는 앵커볼트다(`CLAUDE.md`, ADR 0010 의 8).

표준 라이브러리만 쓴다.
"""
import pathlib
import re
import sys

# 「…의 칸」 절 이름 → 그 모양을 따르는 틀. 절 이름은 앵커볼트다.
KINDS = [
    ("의도 문서의 칸", "intent.md"),
    ("마스터플랜의 칸", "master-plan.md"),
    ("요구사항 문서의 칸", "requirements.md"),
    ("설계 문서의 칸", "design.md"),
]
STATES = ("예정", "진행", "닫힘")
CLOSING = re.compile(r"^닫으며 \(\d{4}-\d{2}-\d{2}\)$")
FOLDER = re.compile(r"^`(docs/slices/\d+-[^/`\s]+/)`$")
NONE_MARK = re.compile(r"^`?없음 — ")
HEADING = re.compile(r"^(#+) (.*)$")


class Report:
    def __init__(self, root):
        self.root = root
        self.bad = []

    def fail(self, path, gid, msg):
        rel = path.relative_to(self.root).as_posix() if isinstance(path, pathlib.Path) else path
        self.bad.append(f"{rel}: [{gid}] {msg}")


def lines(path):
    """코드 펜스와 줄 머리에서 연 주석을 뺀 줄."""
    out, fence, comment = [], False, False
    for ln in path.read_text(encoding="utf-8").splitlines():
        if comment:
            if "-->" in ln:
                comment = False
            continue
        if ln.startswith("```"):
            fence = not fence
            continue
        if fence:
            continue
        if ln.startswith("<!--"):
            comment = "-->" not in ln
            continue
        out.append(ln)
    return out


def headings(ls, depth=2):
    found = []
    for ln in ls:
        m = HEADING.match(ln)
        if m and len(m.group(1)) == depth:
            found.append(m.group(2).rstrip())
    return found


def section(ls, depth, title):
    """깊이 `depth` 의 제목 `title` 아래 줄들. 같은 제목이 몇 번 나왔는지도 돌려준다."""
    starts = [i for i, ln in enumerate(ls)
              if (m := HEADING.match(ln)) and len(m.group(1)) == depth and m.group(2).rstrip() == title]
    if not starts:
        return None, 0
    body = []
    for ln in ls[starts[0] + 1:]:
        m = HEADING.match(ln)
        if m and len(m.group(1)) <= depth:
            break
        body.append(ln)
    return body, len(starts)


def table(body):
    """절 안에서 처음 나오는 표의 칸 줄 — 머리와 가름줄은 뺀다."""
    block, started = [], False
    for ln in body:
        if ln.startswith("|"):
            block.append(ln)
            started = True
        elif started:
            break
    return [[c.strip() for c in ln.strip().strip("|").split("|")] for ln in block[2:]]


def in_order(have, need):
    """`need` 가 `have` 안에 그 순서로 다 있나. 없는 것과 순서가 어긋난 것을 가른다."""
    missing = [t for t in need if t not in have]
    if missing:
        return f"필수 제목이 없다 — {', '.join(missing)}"
    it = iter(have)
    if not all(t in it for t in need):
        return f"필수 제목의 순서가 다르다 — {' → '.join(need)}"
    return None


def inside(root, tok):
    """경로 토막이 루트 안의 있는 자리인가. 아니면 까닭을 돌려준다."""
    if tok.startswith("/") or ".." in pathlib.PurePosixPath(tok).parts:
        return None, "저장소 밖을 가리킨다"
    p = root / tok
    if not p.exists():
        return None, "없다"
    if not p.resolve().is_relative_to(root.resolve()):
        return None, "링크가 저장소 밖을 가리킨다"
    if tok.endswith("/") and not p.is_dir():
        return None, "폴더가 아니다"
    return p, None


def readings(cell, names):
    """의존 칸을 조각 이름의 ` · ` 이음으로 읽는 길 — 셋째부터는 세지 않는다."""
    found = []

    def walk(rest, acc):
        if len(found) > 1:
            return
        for n in names:
            if rest == n:
                found.append(acc + [n])
            elif rest.startswith(n + " · "):
                walk(rest[len(n) + 3:], acc + [n])

    walk(cell, [])
    return found


def check_schema(r, root):
    proc = root / "docs" / "procedure.md"
    if not proc.is_file():
        r.fail("docs/procedure.md", "O3", "없다 — 문서의 모양을 읽을 곳이 없다")
        return {}
    ls = lines(proc)
    schema = {}
    for name, _ in KINDS:
        body, n = section(ls, 3, name)
        if n != 1:
            r.fail(proc, "O1", f"`### {name}` 이 {n} 번 있다 — 꼭 한 번이어야 한다")
            continue
        need = [m.group(1) for row in table(body) if (m := re.match(r"^`## (.+)`$", row[0]))]
        if not need:
            r.fail(proc, "O2", f"「{name}」 표에 필수 제목 줄이 없다")
            continue
        schema[name] = need
    return schema


def check_templates(r, root, schema):
    for name, fname in KINDS:
        p = root / "docs" / "templates" / fname
        if not p.is_file():
            r.fail(f"docs/templates/{fname}", "T1", "틀이 없다")
            continue
        if name in schema and headings(lines(p)) != schema[name]:
            r.fail(p, "T2", f"`##` 제목이 「{name}」 표와 다르다 — {' → '.join(schema[name])}")


def check_master(r, root, schema):
    mp = root / "docs" / "master-plan.md"
    if not mp.is_file():
        r.fail("docs/master-plan.md", "O3", "없다 — 마스터플랜이 없다")
        return None
    ls = lines(mp)
    need = schema.get("마스터플랜의 칸")
    if need and (why := in_order(headings(ls), need)):
        r.fail(mp, "M1", why)

    body, _ = section(ls, 2, "가리키는 문서")
    intents = []
    for row in table(body or []):
        if len(row) != 2:
            r.fail(mp, "M2", f"「가리키는 문서」 줄이 두 칸이 아니다 — {' | '.join(row)}")
            continue
        what, where = row
        is_intent = what.startswith("의도")
        if is_intent:
            intents.append(where)
        if NONE_MARK.match(where):
            if is_intent:
                r.fail(mp, "I2", "의도 줄은 `없음 — ` 을 받지 않는다")
            continue
        toks = re.findall(r"`([^`]+)`", where)
        if not toks:
            r.fail(mp, "I2" if is_intent else "M2", f"「{what}」 줄에 경로도 `없음 — <이유>` 도 없다")
            continue
        for tok in toks:
            _, why = inside(root, tok)
            if why:
                r.fail(mp, "M2", f"「{what}」 줄의 `{tok}` 가 {why}")
        if is_intent:
            p, why = inside(root, toks[0])
            if why or not p.is_file():
                r.fail(mp, "I2", f"의도 줄의 `{toks[0]}` 가 저장소 안의 파일이 아니다 — {why or '폴더다'}")
            elif p.name == "INTENT.md" and (need := schema.get("의도 문서의 칸")):
                if why := in_order(headings(lines(p)), need):
                    r.fail(p, "I3", why)
    if len(intents) != 1:
        r.fail(mp, "I1", f"「가리키는 문서」에 의도 줄이 {len(intents)} 개다 — 꼭 하나여야 한다")

    body, _ = section(ls, 2, "조각 나눔")
    return mp, table(body or [])


def check_slices(r, root, schema, mp, rows):
    good = []
    for row in rows:
        if len(row) != 6:
            r.fail(mp, "S1", f"조각 나눔 줄이 여섯 칸이 아니다({len(row)}) — {' | '.join(row)}")
        else:
            good.append(row)

    names = [row[1] for row in good]
    seen = set()
    for order, name, _, _, state, _ in good:
        if not re.fullmatch(r"\d+|—", order):
            r.fail(mp, "S2", f"「{name}」의 순서 `{order}` 가 숫자도 `—` 도 아니다")
        if not name or name == "—":
            r.fail(mp, "S3", f"조각 이름 `{name}` 은 쓸 수 없다")
        elif name in seen:
            r.fail(mp, "S3", f"조각 이름 「{name}」이 겹친다")
        seen.add(name)
        if state not in STATES:
            r.fail(mp, "S4", f"「{name}」의 상태 `{state}` 가 {' · '.join(STATES)} 가운데 하나가 아니다")
    status = {row[1]: row[4] for row in good}
    usable = [n for n in dict.fromkeys(names) if n and n != "—"]

    deps = {}
    for _, name, _, cell, state, _ in good:
        if cell == "—":
            deps[name] = []
            continue
        ways = readings(cell, usable)
        if len(ways) != 1:
            why = "조각 이름으로 읽히지 않는다" if not ways else "조각 이름으로 읽는 길이 둘 이상이다"
            r.fail(mp, "S5", f"「{name}」의 의존 `{cell}` 가 {why}")
            continue
        deps[name] = ways[0]
        if state in ("진행", "닫힘"):
            for d in ways[0]:
                if d == name:
                    r.fail(mp, "S6", f"「{name}」이 자기 자신을 의존한다")
                elif status.get(d) != "닫힘":
                    r.fail(mp, "S6", f"{state} 조각 「{name}」의 의존 「{d}」가 `닫힘` 이 아니다")

    color = {}

    def visit(n, path):
        color[n] = 1
        for d in deps.get(n, []):
            if color.get(d) == 1:
                cyc = path[path.index(d):] + [d] if d in path else [n, d]
                r.fail(mp, "S10", f"의존에 고리가 있다 — {' → '.join(cyc)}")
            elif d in deps and not color.get(d):
                visit(d, path + [d])
        color[n] = 2

    for n in deps:
        if not color.get(n):
            visit(n, [n])

    claimed = {}
    for _, name, _, _, state, cell in good:
        m = FOLDER.match(cell)
        if not m and not cell.startswith("—"):
            r.fail(mp, "S7", f"「{name}」의 폴더 칸 `{cell}` 가 `docs/slices/<숫자>-<이름>/` 하나도 `—` 도 아니다")
        folder = m.group(1) if m else None
        if folder:
            if folder in claimed:
                r.fail(mp, "S9", f"「{claimed[folder]}」와 「{name}」이 같은 폴더 `{folder}` 를 가리킨다")
            claimed.setdefault(folder, name)
        if state == "예정":
            if not cell.startswith("—"):
                r.fail(mp, "S8", f"예정 조각 「{name}」에 폴더가 있다 — `—` 여야 한다")
            continue
        if state not in ("진행", "닫힘"):
            continue
        if not folder:
            r.fail(mp, "S8", f"{state} 조각 「{name}」에 폴더 경로가 없다")
            continue
        p, why = inside(root, folder)
        if why:
            r.fail(mp, "S8", f"{state} 조각 「{name}」의 폴더 `{folder}` 가 {why}")
            continue
        req, des = p / "requirements.md", p / "design.md"
        if state == "진행":
            for f, kind in ((req, "요구사항 문서의 칸"), (des, "설계 문서의 칸")):
                if not f.is_file():
                    r.fail(f, "F2", f"진행 조각 「{name}」에 이 파일이 없다")
                    continue
                hs = headings(lines(f))
                if kind in schema and (why := in_order(hs, schema[kind])):
                    r.fail(f, "F3", why)
                if f is req and any(h.startswith("닫으며") for h in hs):
                    r.fail(f, "F4", f"진행 조각 「{name}」에 「닫으며」가 있다 — 닫았다면 상태를 `닫힘` 으로")
        else:
            if not req.is_file():
                r.fail(req, "F5", f"닫힌 조각 「{name}」에 요구사항이 없다")
            elif not any(CLOSING.match(h) for h in headings(lines(req))):
                r.fail(req, "F5", f"닫힌 조각 「{name}」에 `## 닫으며 (<YYYY-MM-DD>)` 가 없다")

    slices = root / "docs" / "slices"
    if slices.is_dir():
        for d in sorted(x for x in slices.iterdir() if x.is_dir()):
            if f"docs/slices/{d.name}/" not in claimed:
                r.fail(d, "F1", "조각 나눔의 어느 줄도 이 폴더를 가리키지 않는다")


def main(argv):
    if len(argv) > 1:
        print("사용법: python3 scripts/verify-docs.py [<루트>]", file=sys.stderr)
        return 2
    root = pathlib.Path(argv[0]) if argv else pathlib.Path(__file__).resolve().parent.parent
    if not root.is_dir():
        print(f"루트 `{root}` 가 폴더가 아니다", file=sys.stderr)
        return 2
    root = root.resolve()
    r = Report(root)
    schema = check_schema(r, root)
    check_templates(r, root, schema)
    got = check_master(r, root, schema)
    if got:
        check_slices(r, root, schema, *got)

    if r.bad:
        print("FAIL")
        for b in r.bad:
            print(f"  - {b}")
        return 1
    print("PASS 문서의 모양 — 원천 · 틀 · 의도 · 마스터플랜 · 조각 나눔 · 조각 폴더")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
