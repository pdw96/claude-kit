#!/usr/bin/env python3
"""`eval.yml` gate 잡이 **변조 시험의 지문을 「물었다」로 적는 조건과 건너뛰는 조건**을 지금 모양 그대로 드는지 본다.

  python3 scripts/verify-eval-gate.py              # 이 저장소의 .github/workflows/eval.yml
  python3 scripts/verify-eval-gate.py <eval.yml>   # 다른 판 — bite-gates.sh 가 변조본으로 쓴다

**왜 있나.** gate 잡은 변조 시험 다섯까지 다 돌아 통과한 실행만 지문을 캐시에 적고, 같은 지문의 다음 실행은 그 근거로 변조 시험을
건너뛴다(ADR 0046). 그 조건은 `eval.yml` 의 글 몇 줄뿐인데 무는 것이 리뷰뿐이었다 — `./scripts/gates.sh || true` 나 건너뛰는 갈래의
`full=true` 가 들어가도 CI 는 초록이고 거짓 근거가 적힌다(`audit-quality` 세 회차의 OB-1, 조각 37). 건너뛰는 실행에서도 돌아야
건너뛰는 조건까지 물으므로 늘 도는 `checks` 묶음에 둔다(ADR 0048 의 2).

**무엇을 보나(조각 37 설계 ② · ③).** 판정에 드는 칸은 아래 SPEC 의 닫힌 목록과 글자 그대로 같아야 하고, 알림 글 · 주석 · 스텝 이름 ·
액션의 판은 자유다(ADR 0048 의 3).
  - Y 읽는 꼴 — 워크플로 머리의 키와 gate 잡은 지금 쓰는 꼴(두 칸 들여쓰기 · `키: 값` · `run: |` 블록 · `- ` 스텝 목록)만 읽는다.
    탭 · 앵커 · 별칭 · 태그 · 흐름 꼴 · 같은 키 둘 · `|` 밖의 블록 꼴 · 따옴표 키 · 값 뒤의 주석 · 알 수 없는 들여쓰기는 거절한다
  - H1 워크플로 머리의 키는 `name` · `on` · `concurrency` · `jobs` 뿐 · H2 gate 잡의 키는 `runs-on` · `permissions` · `outputs` · `steps` 뿐
  - T1 gate 잡의 스텝이 SPEC 의 열한으로 시작해 그 차례대로 이어진다 · T2 스텝마다 SPEC 의 칸만(`name` 은 자유) ·
    T3 `id` · `if` · `env` · `with` 의 값과 `run` 의 명령 줄이 SPEC 과 같다 — `uses` 는 `@` 앞만, 판은 `v<숫자>`
  - F 자유 — `run` 의 알림 줄(줄 전체가 `echo "<글>"`, 글에 `$(` · 역따옴표 · `\\` · 따옴표가 없고 `$이름` · `${이름}` 만 펼친다)은 명령 줄에서
    뺀다. 주석 줄 · 빈 줄 · 줄 앞뒤 공백도 보지 않는다
  - G 주석 밖에서 `.gate-pass` · `gfp` 를 든 줄은 파일 전체에서 열한 스텝 안에만 있다

판정에 드는 칸을 고치는 PR 은 SPEC 도 함께 고친다 — 그 PR 은 변조 시험 지문이 바뀌어 다 돌고, 리뷰가 두 쪽을 함께 본다. 이것이 무는지는
`bite-gates.sh` 의 「eval.yml 적기 조건」 절이 변조본과 대조군으로 본다. `run-evals.sh` 가 부르지 않아 수트 지문 밖이다. 표준 라이브러리만 쓴다.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
WORKFLOW = ROOT / ".github" / "workflows" / "eval.yml"
USAGE = "사용법: verify-eval-gate.py [<eval.yml>]"

HEAD_KEYS = ["name", "on", "concurrency", "jobs"]           # H1
GATE_KEYS = ["runs-on", "permissions", "outputs", "steps"]  # H2

# T — gate 잡의 첫 열한 스텝(main 7df49c4 의 eval.yml). 칸은 그 스텝이 갖는 것의 닫힌 목록이고 `name` 은 늘 자유다.
# `run` 은 알림 줄 · 주석 · 빈 줄을 뺀 명령 줄을 줄 앞뒤 공백 없이 든다.
SPEC = [
    ("T1", {"uses": "actions/checkout", "with": {"fetch-depth": "0"}}),
    ("T2", {"uses": "actions/setup-node", "with": {"node-version": '"22"', "package-manager-cache": "false"}}),
    ("T3", {"run": ["npm install -g @anthropic-ai/claude-code"]}),
    ("T4", {"id": "gfp", "run": [
        "if key=$(python3 scripts/gate-key.py) && [[ $key =~ ^gate-bite-py[^[:space:]]+-git[^[:space:]]+-[0-9a-f]{24}$ ]]; then",
        'echo "key=$key" >> "$GITHUB_OUTPUT"',
        "else",
        "fi",
    ]}),
    ("T5", {"id": "gseen",
            "if": "steps.gfp.outputs.key != '' && github.event_name != 'workflow_dispatch'",
            "uses": "actions/cache/restore",
            "with": {"path": ".gate-pass", "key": "${{ steps.gfp.outputs.key }}"}}),
    ("T6", {"id": "gmerged",
            "if": "github.event_name == 'push' && steps.gfp.outputs.key != '' && steps.gseen.outputs.cache-hit != 'true'",
            "env": {"GITHUB_TOKEN": "${{ github.token }}", "KEY": "${{ steps.gfp.outputs.key }}"},
            "run": ['python3 scripts/eval-merged-pass.py "$KEY"']}),
    ("T7", {"if": "steps.gmerged.outputs.hit == 'true'",
            "env": {"PR": "${{ steps.gmerged.outputs.pr }}", "CREATED": "${{ steps.gmerged.outputs.created }}"},
            "run": [
                "mkdir -p .gate-pass",
                'echo "PR #$PR 의 refs/pull/$PR/merge 캐시($CREATED 에 적힘) — 그것을 읽은 main 실행 '
                '$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID ($GITHUB_SHA)" > .gate-pass/run.txt',
            ]}),
    ("T8", {"uses": "actions/cache/save", "if": "steps.gmerged.outputs.hit == 'true'",
            "with": {"path": ".gate-pass", "key": "${{ steps.gfp.outputs.key }}"}}),
    ("T9", {"id": "gates",
            "env": {"KEY": "${{ steps.gfp.outputs.key }}",
                    "HIT": "${{ steps.gseen.outputs.cache-hit == 'true' || steps.gmerged.outputs.hit == 'true' }}"},
            "run": [
                'if [ "$HIT" = true ] && [ -s .gate-pass/run.txt ]; then',
                'why="같은 지문($KEY)이 이미 물었다 — $(head -n 1 .gate-pass/run.txt)"',
                './scripts/gates.sh --skip-bite "$why"',
                "else",
                'if [ "$HIT" = true ]; then',
                "fi",
                'echo "full=true" >> "$GITHUB_OUTPUT"',
                "./scripts/gates.sh",
                "fi",
            ]}),
    ("T10", {"id": "gpass", "if": "steps.gates.outputs.full == 'true' && steps.gfp.outputs.key != ''",
             "run": [
                 "mkdir -p .gate-pass",
                 'echo "$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID ($GITHUB_SHA)" > .gate-pass/run.txt',
             ]}),
    ("T11", {"uses": "actions/cache/save", "if": "steps.gpass.outcome == 'success'",
             "with": {"path": ".gate-pass", "key": "${{ steps.gfp.outputs.key }}"}}),
]

KEY = re.compile(r"([A-Za-z_][A-Za-z0-9_-]*):(?: (.*))?")
BAD_HEAD = re.compile(r"[&*!{\[>|%@`]")   # Y6 — 앵커 · 별칭 · 태그 · 흐름 꼴 · 블록 꼴 · 예약 글자로 여는 값
FREE_ECHO = re.compile(r'echo "(?:[^"`\\$]|\$[A-Za-z_][A-Za-z0-9_]*|\$\{[A-Za-z_][A-Za-z0-9_]*\})*"')  # F2
VERSION = re.compile(r"v[0-9]+")  # F3
GUARDED = (".gate-pass", "gfp")   # G


class Unread(Exception):
    """Y — 읽는 꼴 밖의 줄. (줄 번호, 까닭)"""


def indent(line):
    return len(line) - len(line.lstrip(" "))


def skip(line):
    s = line.strip()
    return not s or s.startswith("#")


class Reader:
    """gate 잡의 줄을 읽는다 — 키 · 값 · 블록 · 스텝 목록만. lines 는 (줄 번호, 글)이고 그 밖의 꼴은 Unread."""

    def __init__(self, lines):
        self.lines = lines
        self.i = 0

    def peek(self):
        while self.i < len(self.lines) and skip(self.lines[self.i][1]):
            self.i += 1
        return self.lines[self.i] if self.i < len(self.lines) else None

    def mapping(self, ind):
        out = {}
        while (cur := self.peek()) is not None:
            no, line = cur
            if indent(line) < ind:
                break
            if indent(line) != ind:
                raise Unread(no, "알 수 없는 들여쓰기")
            m = KEY.fullmatch(line[ind:].rstrip())
            if not m:
                raise Unread(no, "`키: 값` 꼴이 아니다(따옴표 키 · `<<:` · 흐름 꼴 따위)")
            key, val = m[1], m[2]
            if key in out:
                raise Unread(no, f"같은 키 `{key}` 가 둘이다")
            self.i += 1
            if val is None or val == "":
                nxt = self.peek()
                if nxt is not None and indent(nxt[1]) > ind:
                    if indent(nxt[1]) != ind + 2:
                        raise Unread(nxt[0], "알 수 없는 들여쓰기")
                    out[key] = self.steps(ind + 2) if nxt[1].lstrip().startswith("- ") else self.mapping(ind + 2)
                else:
                    out[key] = None
            elif val == "|":
                out[key] = self.block(no, ind)
            elif BAD_HEAD.match(val):
                raise Unread(no, f"`{key}` 의 값이 읽지 않는 꼴로 연다 — {val[:1]!r}")
            elif " #" in val:
                raise Unread(no, f"`{key}` 의 값 뒤에 주석이 있다")
            else:
                out[key] = val
        return out

    def block(self, at, ind):
        """`run: |` 아래 줄들 — 첫 줄의 들여쓰기보다 얕은 줄이 오면 끝난다(YAML 의 블록 꼴). 빈 줄은 블록에 든다."""
        body, deep = [], None
        while self.i < len(self.lines):
            no, line = self.lines[self.i]
            if not line.strip():
                body.append("")
                self.i += 1
                continue
            if deep is None:
                deep = indent(line)
                if deep <= ind:
                    raise Unread(at, "`|` 블록이 비었다")
            if indent(line) < deep:
                break
            body.append(line[deep:])
            self.i += 1
        if deep is None:
            raise Unread(at, "`|` 블록이 비었다")
        return body

    def steps(self, ind):
        out = []
        while (cur := self.peek()) is not None:
            no, line = cur
            if indent(line) < ind:
                break
            if indent(line) != ind or not line[ind:].startswith("- "):
                raise Unread(no, "스텝 목록에서 `- ` 로 열지 않는 줄")
            # 「- 키: 값」 줄을 두 칸 깊은 매핑의 첫 줄로 읽는다
            self.lines[self.i] = (no, " " * (ind + 2) + line[ind + 2:])
            start = no
            step = self.mapping(ind + 2)
            end = self.lines[self.i - 1][0] if self.i else start
            step["_lines"] = (start, end)
            out.append(step)
        return out


def commands(run):
    """`run` 의 명령 줄 — 알림 줄(F2) · 주석 · 빈 줄을 빼고 줄 앞뒤 공백 없이."""
    lines = run if isinstance(run, list) else [run]
    return [s for s in (l.strip() for l in lines) if s and not s.startswith("#") and not FREE_ECHO.fullmatch(s)]


def sig(step):
    """차례(T1)를 가르는 얼굴 — id, 없으면 액션 이름, 그도 없으면 run 스텝."""
    if step.get("id"):
        return ("id", step["id"])
    if step.get("uses"):
        return ("uses", str(step["uses"]).split("@")[0])
    return ("run",)


def check_steps(steps, fail):
    for n, (tag, spec) in enumerate(SPEC):
        if n >= len(steps):
            fail("T1", f"{tag}", f"gate 잡의 스텝이 {len(steps)} 개뿐이다 — 열한으로 시작해야 한다")
            return
        step = steps[n]
        where = f"{tag}({step.get('name') or step.get('id') or step.get('uses') or 'run'} · {step['_lines'][0]}행)"
        if sig(step) != sig(spec):
            fail("T1", where, f"{n + 1} 째 스텝이 {sig(spec)} 여야 하는데 {sig(step)} 다 — 스텝이 끼었거나 빠졌거나 차례가 바뀌었다")
            return
        have = set(step) - {"name", "_lines"}
        if have != set(spec):
            extra, miss = sorted(have - set(spec)), sorted(set(spec) - have)
            fail("T2", where, f"칸이 다르다 — 더한 칸 {extra} · 없는 칸 {miss}")
        for k in sorted(set(spec) & have):
            got, want = step[k], spec[k]
            if k == "uses":
                name, _, ver = str(got).partition("@")
                if name != want:
                    fail("T3", f"{where} · uses", f"`{want}` 여야 하는데 `{name}` 다")
                elif not VERSION.fullmatch(ver):
                    fail("T3", f"{where} · uses", f"판이 `v<숫자>` 가 아니다 — `{ver}`")
            elif k == "run":
                g = commands(got)
                if g != want:
                    at = next((i for i, (a, b) in enumerate(zip(g, want)) if a != b), min(len(g), len(want)))
                    a = g[at] if at < len(g) else "(없음)"
                    b = want[at] if at < len(want) else "(없음)"
                    fail("T3", f"{where} · run", f"명령 줄 {at + 1} 이 다르다 — 지금 `{a}` · 목록 `{b}`")
            elif isinstance(want, dict):
                if not isinstance(got, dict) or got != want:
                    fail("T3", f"{where} · {k}", f"값이 다르다 — 지금 {got!r} · 목록 {want!r}")
            elif got != want:
                fail("T3", f"{where} · {k}", f"값이 다르다 — 지금 `{got}` · 목록 `{want}`")


def judge(text):
    """실패 (번호, 자리, 까닭) 의 목록과 알림 줄의 수. 목록이 비었으면 통과."""
    bad = []
    fail = lambda code, where, why: bad.append((code, where, why))
    lines = text.split("\n")

    # H1 · Y — 워크플로 머리의 키
    head = []
    for no, line in enumerate(lines, 1):
        if skip(line) or indent(line):
            continue
        m = KEY.fullmatch(line.rstrip())
        if not m:
            return [("Y", f"{no}행", "워크플로 머리의 줄이 `키:` 꼴이 아니다")], 0
        if "\t" in line:
            return [("Y", f"{no}행", "탭이 있다")], 0
        if m[1] in head:
            return [("Y", f"{no}행", f"머리의 키 `{m[1]}` 가 둘이다")], 0
        head.append(m[1])
    if sorted(head) != sorted(HEAD_KEYS):
        fail("H1", "워크플로 머리", f"키가 {HEAD_KEYS} 여야 하는데 {head} 다")

    # gate 잡의 자리 — jobs: 아래 「  gate:」 한 줄부터 다음 잡이나 머리의 키까지
    starts = [no for no, line in enumerate(lines, 1) if line.rstrip() == "  gate:"]
    jobs = [no for no, line in enumerate(lines, 1) if line.rstrip() == "jobs:"]
    if len(starts) != 1 or len(jobs) != 1 or starts[0] < jobs[0]:
        return bad + [("Y", "jobs", "jobs: 아래 「  gate:」 한 줄을 찾지 못했다")], 0
    a = starts[0]
    b = next((no for no in range(a + 1, len(lines) + 1)
              if not skip(lines[no - 1]) and indent(lines[no - 1]) <= 2), len(lines) + 1)
    body = [(no, lines[no - 1]) for no in range(a + 1, b)]
    for no, line in body:
        if "\t" in line:
            return bad + [("Y", f"{no}행", "gate 잡에 탭이 있다")], 0
    try:
        job = Reader(body).mapping(4)
    except Unread as e:
        no, why = e.args
        return bad + [("Y", f"{no}행", why)], 0

    # H2
    if sorted(job) != sorted(GATE_KEYS):
        fail("H2", "gate 잡", f"키가 {GATE_KEYS} 여야 하는데 {list(job)} 다")
    steps = job.get("steps")
    if not isinstance(steps, list):
        fail("T1", "gate 잡", "steps 가 스텝 목록이 아니다")
        return bad, 0

    check_steps(steps, fail)

    # G — 열한 스텝 밖에서 근거 파일이나 지문을 쓰는 줄
    lo = steps[0]["_lines"][0]
    hi = steps[min(len(steps), len(SPEC)) - 1]["_lines"][1]
    for no, line in enumerate(lines, 1):
        if lo <= no <= hi or skip(line):
            continue
        for g in GUARDED:
            if g in line:
                fail("G", f"{no}행", f"열한 스텝 밖에서 `{g}` 를 쓴다 — {line.strip()[:80]}")

    free = sum(1 for s in steps[:len(SPEC)] if "run" in s
               for l in (s["run"] if isinstance(s["run"], list) else [s["run"]]) if FREE_ECHO.fullmatch(l.strip()))
    return bad, free


def main(argv):
    if len(argv) > 1 or (argv and argv[0].startswith("-")):
        print(USAGE, file=sys.stderr)
        return 2
    path = pathlib.Path(argv[0]) if argv else WORKFLOW
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as e:
        print(f"FAIL [A2] {path} — 읽지 못했다: {e}")
        return 1
    bad, free = judge(text)
    if bad:
        for code, where, why in bad:
            print(f"FAIL [{code}] {where} — {why}")
        return 1
    print(f"PASS verify-eval-gate.py — 머리의 키 넷 · gate 잡의 키 넷 · 첫 열한 스텝의 차례 · 칸 · 글이 닫힌 목록과 같고, "
          f"`.gate-pass` · `gfp` 는 그 안에만 있다(알림 줄 {free} 은 자유)")
    return 0


if __name__ == "__main__":
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv[1:]))
