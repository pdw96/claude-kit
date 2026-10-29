#!/usr/bin/env python3
"""부적합 대장의 모양 — 상태 낱말 · 줄이 사는 표 · 번호 · 회차 절 — 을 본다. 모델도 네트워크도 안 쓴다. git 은 파일 목록에만 쓴다.

  python3 scripts/verify-ledger.py               # 이 저장소 — `scripts/` 의 링크로 부른다. 대장이 없으면 떨어진다
  python3 scripts/verify-ledger.py <루트>         # 다른 폴더를 이 저장소처럼 — `bite-gates.sh` 가 변조본으로 쓴다
  python3 <이 파일> --repo <루트>                   # 다른 레포 — 대장이 없으면 「대장 없음」으로 지나간다

**자리.** 실물은 `vibe-slice/skills/slice-docs/scripts/` 에 있고 플러그인 · 사본(`sync-slice.sh`)이 이 파일을 싣는다.
`scripts/verify-ledger.py` 는 그것을 가리키는 링크다. 인자 없이 부르면 **부른 경로**의 두 단 위가 루트다 — 링크를 따라가지
않는다(`verify-docs.py` 와 같은 꼴).

**왜 있나.** 부적합 대장의 규칙(상태 낱말 · 줄이 사는 표 · 다음 번호 · 회차 절의 첫 줄)을 지키는 것이 사람뿐이었다. ERP 에서는
그 규칙이 거듭 깨져 시험이 섰고, 이 저장소에서도 회차 6 의 등록이 상태 칸을 굵게 하지 않은 채 지나갔다. 대장 등록은 문서만
고치는 PR 이라 사람과 리뷰 봇만 봤다(조각 43 요구사항 「문제」 · ADR 0056).

**무엇을 보나.** `docs/slices/43-nc-ledger-check/design.md` ② · ③ B 와 그 끝 「PR B 에서 정한 것」이 든다. 실패 줄의 `[K1]` 같은
ID 가 그 보장의 갈래다 — 여기 따로 옮겨 적지 않는다.
  - F 찾기 — git 이 드는 마크다운(추적하는 것과, 추적 안 됐으나 무시되지 않는 것) 가운데 틀의 출처 줄이 있는 파일이 살아 있는 쪽,
    그 머리가 든 경로가 지나간 쪽이다
  - R 읽기 — 절 · 표 머리 · 다음 번호 줄 · 상태 낱말 문장을 그 꼴로만 읽는다. 못 읽으면 떨어진다 — 빈 것끼리 견주어 지나가지 않는다
  - K1 상태 낱말 · K2 줄이 사는 표 · K3 번호 · K4 회차 절
상태 낱말은 여기 박지 않고 그 대장의 「닫는 규칙」 문장에서 읽는다(ADR 0056 의 4). 예외 목록은 없다(ADR 0056 의 5).
실패 줄은 `FAIL [<ID>] <파일>:<줄> <글>` 이고 종료 1, 쓰는 법이 틀린 인자는 종료 2 다. ID 마다 변조본이 있는지는 `bite-gates.sh` 의
이 검사 절이 이 파일의 `r.fail("…` 에서 ID 를 읽어 견준다.

**보지 않는 것.** 줄의 뜻(재감사 없는 닫힘 · 담당 · 옮기며 바뀐 글자) · 확인불가의 상태 말 · 마크다운의 변형(코드 블록 · 인용 · 주석
안의 줄도 글자로 읽는다) · 출처 줄이 없는 대장.

표준 라이브러리만 쓴다.
"""
import os
import pathlib
import re
import subprocess
import sys

USAGE = "사용법: python3 verify-ledger.py [<루트> | --repo <루트>]"
# B1 — 틀을 베낀 대장의 출처 줄. 틀 자신의 줄은 커밋 자리가 `<커밋>` 이라 이 꼴이 아니다.
ORIGIN = re.compile(r"^- 베낀 틀: claude-kit `vibe-slice/skills/slice-docs/templates/nc-ledger\.md` @ `[0-9a-f]{4,40}`")
# B2 — 살아 있는 쪽 머리 문단에서 지나간 쪽의 경로를 여는 글. 그 뒤 첫 백틱 토막이 경로다.
PAST = "**지나간 것**(닫힌 부적합 · 회차 절)은 "
TICK = re.compile(r"`([^`\n]+)`")
# B3 — 절. 몸은 다음 `## ` 앞까지.
LIVE_SECS = ("닫는 규칙", "부적합", "확인불가")
CLOSED_SEC = "닫힌 부적합"
ROUND = "회차 "
# 틀의 회차 절 모양 — 첫 회차 전에는 틀이 이 절을 남기게 한다(지나간 쪽 틀의 머리). 회차가 아니라 모양이라 세지 않는다.
ROUND_SHAPE = "회차 <n> "
# B4 — 다음 번호 줄. `**다음 번호` 로 여는 줄은 다 이 꼴이어야 한다.
NEXT_OPEN = "**다음 번호"
NEXT = re.compile(r"^\*\*다음 번호: NC-([0-9]+) · U-([0-9]+)\*\*\s*$")
# B5 — 표 머리.
NC_HEAD = ("NC", "무엇", "낸 회차", "담당", "심각도", "상태", "판정과 근거")
U_HEAD = ("U", "무엇", "낸 회차", "담당", "판정하려면", "누가 줄 수 있나", "멈춘 회차", "상태")
STATUS_AT = NC_HEAD.index("상태")
SEP = re.compile(r"^\|(?:\s*:?-+:?\s*\|)+\s*$")
CELL = re.compile(r"(?<!\\)\|")
# B8 — 상태 낱말 문장. 「닫는 규칙」 절에서 이 글 뒤로 첫 마침표까지(문단 안에서는 줄을 넘는다)를 ` · ` 로 가른다.
WORDS_OPEN = "**상태 칸은 이 절이 정한 말로 연다** — "
CLOSED = "닫힘"
WAITING = "열림 — 저자 판정 대기"
# B7 — 굵은 글이 낱말 하나로 시작하고 그 뒤가 끝 · 공백 · `(` · `—` 다.
AFTER_WORD = re.compile(r"$|[\s(—]")
# B9 — 회차 절의 첫 줄.
AUDITED = re.compile(r"^- \*\*감사한 커밋\*\*: (?:`[0-9a-f]{4,64}`|모름)(?=$|[\s(—·,])")


class Report:
    def __init__(self, root):
        self.root = root
        self.bad = []

    def fail(self, rid, path, line, msg):
        rel = path.relative_to(self.root).as_posix() if isinstance(path, pathlib.Path) else path
        where = f"{rel}:{line}" if line else rel
        self.bad.append(f"FAIL [{rid}] {where} {msg}")


def listed(root):
    """git 이 드는 마크다운 — 추적하는 것과, 추적 안 됐으나 무시되지 않는 것. 루트가 git 맨 위가 아니면 None."""
    try:
        top = subprocess.run(["git", "-C", str(root), "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, encoding="utf-8", errors="replace")
        if top.returncode != 0 or os.path.realpath(top.stdout.strip()) != os.path.realpath(root):
            return None
        out = subprocess.run(["git", "-C", str(root), "ls-files", "-co", "--exclude-standard", "-z"],
                             capture_output=True)
    except OSError:
        return None
    if out.returncode != 0:
        return None
    names = out.stdout.decode("utf-8", "replace").split("\0")
    return sorted({n for n in names if n.endswith(".md")})


def sections(lines):
    """`## ` 머리마다 (제목, 머리 줄 번호, 몸 [(줄 번호, 글)]). 머리 앞의 줄은 제목 None 으로."""
    out, cur = [], [None, 0, []]
    for i, ln in enumerate(lines, 1):
        if ln.startswith("## "):
            out.append(cur)
            cur = [ln[3:].rstrip(), i, []]
        else:
            cur[2].append((i, ln))
    out.append(cur)
    return out


def one(r, path, secs, title):
    """제목이 꼭 한 번인 절의 (머리 줄 번호, 몸). 없거나 겹치면 R 을 찍고 None."""
    found = [s for s in secs if s[0] == title]
    if len(found) != 1:
        at = " · ".join(str(s[1]) for s in found)
        r.fail("R", path, None, f"`## {title}` 절이 {len(found)} 번이다{f'(줄 {at})' if at else ''} — 꼭 한 번이어야 읽는다")
        return None
    return found[0][1], found[0][2]


def cells(text):
    return [c.strip() for c in CELL.split(text.rstrip())[1:-1]]


def table(r, path, sec, head):
    """절의 표 — 머리가 `head` 이고 그 뒤 구분 줄, 몸은 이어진 `|` 줄. 몸 [(줄 번호, 칸들)]. 못 읽으면 R 을 찍고 None."""
    at, body = sec
    rows = [(i, ln) for i, ln in body if ln.startswith("|")]
    if not rows:
        r.fail("R", path, at, f"표 머리 `| {' | '.join(head)} |` 를 못 찾았다")
        return None
    i0 = next(k for k, (i, ln) in enumerate(body) if ln.startswith("|"))
    hi, hl = body[i0]
    if tuple(cells(hl)) != head or not hl.rstrip().endswith("|"):
        r.fail("R", path, hi, f"표 머리가 `| {' | '.join(head)} |` 가 아니다")
        return None
    if i0 + 1 >= len(body) or not SEP.match(body[i0 + 1][1]) or len(cells(body[i0 + 1][1])) != len(head):
        r.fail("R", path, hi + 1, "표 머리 뒤에 칸 수가 같은 구분 줄이 없다")
        return None
    got, k, ok = [], i0 + 2, True
    while k < len(body) and body[k][1].startswith("|"):
        i, ln = body[k]
        cs = cells(ln)
        if not ln.rstrip().endswith("|") or len(cs) != len(head):
            r.fail("R", path, i, f"표 줄의 칸이 {len(cs)} 이다 — 머리와 같은 {len(head)} 이고 `|` 로 닫아야 읽는다")
            ok = False
        elif not re.fullmatch(r"[0-9]+", cs[0]):
            r.fail("R", path, i, f"표 줄의 첫 칸 {cs[0]!r} 이 번호가 아니다 — 틀의 자리표시 줄은 줄째 지운다")
            ok = False
        else:
            got.append((i, cs))
        k += 1
    for i, ln in body[k:]:
        if ln.startswith("|"):
            r.fail("R", path, i, "표가 끊겼다 — 절 안의 표 밖에 `|` 로 여는 줄이 있다")
            ok = False
    return got if ok else None


def status_words(r, path, sec):
    """B8 — 「닫는 규칙」 절의 상태 낱말. 못 읽으면 R 을 찍고 None."""
    at, body = sec
    hits = [k for k, (i, ln) in enumerate(body) if WORDS_OPEN in ln]
    if len(hits) != 1:
        r.fail("R", path, at, f"상태 낱말 문장(`{WORDS_OPEN.strip()}`)이 {len(hits)} 번이다 — 꼭 한 번이어야 읽는다")
        return None
    k = hits[0]
    i0 = body[k][0]
    text = body[k][1].split(WORDS_OPEN, 1)[1]
    while "." not in text and k + 1 < len(body) and body[k + 1][1].strip():
        k += 1
        text += " " + body[k][1].strip()
    if "." not in text:
        r.fail("R", path, i0, "상태 낱말 문장이 마침표 없이 문단에서 끝난다")
        return None
    words = [w.strip() for w in re.sub(r"\s+", " ", text.split(".", 1)[0]).split(" · ")]
    if not all(words):
        r.fail("R", path, i0, f"상태 낱말 문장에 빈 낱말이 있다 — {words}")
        return None
    for need in (CLOSED, WAITING):
        if need not in words:
            r.fail("R", path, i0, f"상태 낱말 문장에 낱말 「{need}」 없이는 읽지 않는다 — 줄이 사는 표와 판정 전 상태를 가르는 낱말이다")
            return None
    return sorted(words, key=len, reverse=True)


def status_of(cell, words):
    """B7 — 상태 칸이 여는 낱말. 굵게 열고 닫지 않았거나 낱말로 시작하지 않으면 None."""
    if not cell.startswith("**"):
        return None
    end = cell.find("**", 2)
    if end < 0:
        return None
    bold = cell[2:end]
    for w in words:
        if bold.startswith(w) and AFTER_WORD.match(bold[len(w):]):
            return w
    return None


def judge(root, repo):
    r = Report(root)
    names = listed(root)
    if names is None:
        r.fail("F", ".", None, "루트가 git 작업 트리의 맨 위가 아니다 — 대장을 git 이 드는 파일에서 찾는다")
        return r, None
    lives = []
    for n in names:
        p = root / n
        try:
            text = p.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        if any(ORIGIN.match(ln) for ln in text.split("\n")):
            lives.append(n)
    if not lives:
        if repo:
            return r, "none"
        r.fail("F", ".", None, "틀의 출처 줄(`- 베낀 틀: claude-kit …nc-ledger.md @ `<커밋>``)이 있는 마크다운이 없다 — 이 저장소는 대장이 있어야 한다")
        return r, None
    if len(lives) > 1:
        r.fail("F", ".", None, f"틀의 출처 줄이 있는 마크다운이 {len(lives)} 이다 — {' · '.join(lives)}. 살아 있는 쪽은 하나다")
        return r, None
    live = root / lives[0]
    lt = live.read_text(encoding="utf-8").split("\n")
    lsecs = sections(lt)
    head = "\n".join(ln for _, ln in lsecs[0][2])
    past = None
    if PAST in head:
        m = TICK.search(head.split(PAST, 1)[1])
        past = m.group(1) if m else None
    if not past:
        r.fail("F", live, None, f"머리 문단에서 지나간 쪽의 경로(`{PAST.strip()}` 뒤 첫 백틱 토막)를 못 읽었다")
        return r, None
    hp = root / past
    if (pathlib.PurePosixPath(past).is_absolute() or ".." in pathlib.PurePosixPath(past).parts
            or not hp.is_file() or past == lives[0]):
        r.fail("F", live, None, f"지나간 쪽 `{past}` 이 저장소 맨 위에서부터의 경로로 있는 다른 파일이 아니다")
        return r, None
    try:
        ht = hp.read_text(encoding="utf-8").split("\n")
    except (OSError, UnicodeDecodeError) as e:
        r.fail("F", hp, None, f"지나간 쪽을 읽지 못했다 — UTF-8 문서여야 한다({type(e).__name__})")
        return r, None
    hsecs = sections(ht)

    # R — 절 · 상태 낱말 · 다음 번호 · 표
    rules, open_, unk = (one(r, live, lsecs, t) for t in LIVE_SECS)
    closed = one(r, hp, hsecs, CLOSED_SEC)
    words = status_words(r, live, rules) if rules else None
    nexts = []
    if open_:
        for i, ln in open_[1]:
            if ln.startswith(NEXT_OPEN):
                m = NEXT.match(ln)
                if not m:
                    r.fail("R", live, i, "다음 번호 줄이 `**다음 번호: NC-<n> · U-<m>**` 꼴이 아니다")
                else:
                    nexts.append((i, int(m.group(1)), int(m.group(2))))
        if not nexts and not any(ln.startswith(NEXT_OPEN) for _, ln in open_[1]):
            r.fail("R", live, open_[0], "`## 부적합` 절에 다음 번호 줄(`**다음 번호: NC-<n> · U-<m>**`)이 없다")
    nc_live = table(r, live, open_, NC_HEAD) if open_ else None
    u_rows = table(r, live, unk, U_HEAD) if unk else None
    nc_past = table(r, hp, closed, NC_HEAD) if closed else None

    # K1 · K2 — 상태 낱말과 줄이 사는 표
    if words is not None:
        for path, rows, here in ((live, nc_live, "살아 있는 쪽 「부적합」"), (hp, nc_past, "지나간 쪽 「닫힌 부적합」")):
            for i, cs in rows or []:
                w = status_of(cs[STATUS_AT], words)
                if w is None:
                    r.fail("K1", path, i, f"NC-{cs[0]} 의 상태 칸 {cs[STATUS_AT][:40]!r} 이 굵게 연 상태 낱말이 아니다 — "
                                          f"「닫는 규칙」의 낱말: {' · '.join(sorted(words, key=len))}")
                elif (w == CLOSED) != (path == hp):
                    r.fail("K2", path, i, f"NC-{cs[0]} 의 상태가 「{w}」인데 {here} 표에 있다 — "
                                          f"닫힘은 지나간 쪽 「닫힌 부적합」, 그 밖은 살아 있는 쪽 「부적합」에 산다")

    # K3 — 번호
    if len(nexts) > 1:
        r.fail("K3", live, nexts[1][0], f"다음 번호 줄이 {len(nexts)} 이다(줄 {' · '.join(str(n[0]) for n in nexts)}) — 하나여야 한다")
    elif len(nexts) == 1 and nc_live is not None and nc_past is not None and u_rows is not None:
        at, nn, un = nexts[0]
        for kind, rows, upto in (("NC", [(live, i, cs) for i, cs in nc_live] + [(hp, i, cs) for i, cs in nc_past], nn),
                                 ("U", [(live, i, cs) for i, cs in u_rows], un)):
            seen = {}
            for path, i, cs in rows:
                n = int(cs[0])
                if n in seen:
                    r.fail("K3", path, i, f"{kind}-{n} 이 두 번이다 — 앞의 줄은 {seen[n]}. 번호는 표를 가로질러 한 번씩이다")
                    continue
                seen[n] = f"{path.relative_to(root).as_posix()}:{i}"
                if n < 1 or n >= upto:
                    r.fail("K3", path, i, f"{kind}-{n} 이 다음 번호 {kind}-{upto} 앞의 번호가 아니다 — 줄을 더하면 다음 번호를 올린다")
            lost = [n for n in range(1, upto) if n not in seen]
            if lost:
                r.fail("K3", live, at, f"{kind} 번호 {', '.join(map(str, lost))} 이 어느 표에도 없다 — 다음 번호 {kind}-{upto} 앞은 다 있어야 한다")

    # K4 — 회차 절
    for title, i, _ in lsecs[1:]:
        if title.startswith(ROUND):
            r.fail("K4", live, i, f"살아 있는 쪽에 회차 절 `## {title}` 이 있다 — 회차 절은 지나간 쪽 끝에 둔다")
    rounds = 0
    for title, i, body in hsecs[1:]:
        if not title.startswith(ROUND) or title.startswith(ROUND_SHAPE):
            continue
        rounds += 1
        first = next(((k, ln) for k, ln in body if ln.strip()), None)
        if first is None or not AUDITED.match(first[1]):
            r.fail("K4", hp, first[0] if first else i,
                   f"회차 절 `## {title[:40]}` 의 첫 줄이 감사한 커밋 줄(`- **감사한 커밋**: `<sha>`` 나 `모름`)이 아니다")

    if r.bad:
        return r, None
    return r, (lives[0], past, len(nc_live) + len(nc_past), len(u_rows), rounds)


def main(argv):
    repo = argv[:1] == ["--repo"]
    args = argv[1:] if repo else argv
    if len(args) > 1 or (repo and not args) or any(a.startswith("-") for a in args):
        print(USAGE, file=sys.stderr)
        return 2
    # 부른 경로의 두 단 위 — 링크를 따라가지 않는다. `scripts/` 의 링크로 부르면 이 저장소다.
    root = pathlib.Path(args[0]) if args else pathlib.Path(os.path.abspath(__file__)).parent.parent
    if not root.is_dir():
        print(USAGE, file=sys.stderr)
        print(f"루트 `{root}` 가 폴더가 아니다", file=sys.stderr)
        return 2
    root = root.resolve()
    r, got = judge(root, repo)
    if r.bad:
        for b in r.bad:
            print(b)
        return 1
    if got == "none":
        print("PASS verify-ledger.py — 대장 없음(틀의 출처 줄이 있는 마크다운이 없다 — 대장을 세우면 이 검사가 문다)")
        return 0
    live, past, nc, u, rounds = got
    print(f"PASS verify-ledger.py — 대장 {live} · {past} 에서 NC {nc} · 확인불가 {u} · 회차 절 {rounds} 을 읽었다")
    return 0


if __name__ == "__main__":
    # 출력은 콘솔 인코딩과 상관없이 UTF-8 이다 — cp949 콘솔에서 `—` 를 찍다 예외로 끝나지 않게(verify-docs.py 와 같다).
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv[1:]))
