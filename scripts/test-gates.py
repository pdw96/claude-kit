#!/usr/bin/env python3
"""`gates.sh` 가 **무엇을 실제로 부르는지** 본다 — 부르는 것이 고정 목록 그대로이고, 인자 없이는 변조 시험 다섯까지 다 돌고,
`--skip-bite` 는 그 다섯만 빼고, 어느 하나가 떨어져도 `gates.sh` 가 떨어진다.

  python3 scripts/test-gates.py                # 이 저장소의 gates.sh
  python3 scripts/test-gates.py <gates.sh>     # 다른 판 — bite-gates.sh 가 변조본으로 쓴다

**왜 있나.** CI 는 인자 없이 돈 `gates.sh` 가 통과하면 그 지문을 「변조 시험이 물었다」로 적고, 같은 지문의 다음 실행은
변조 시험을 건너뛴다(`eval.yml` · ADR 0046). 그 전제 — 인자 없이 부르면 변조 시험 다섯이 돈다 — 를 무는 검사가 없어서,
`bites` 호출을 지우거나 건너뛰는 분기의 조건을 뒤집은 `gates.sh` 가 변조 시험 없이 초록으로 지나가고 거짓 근거를 적을 수
있었다(조각 35 닫기 전 감사 회차 `audit-quality` NC-1). 그 자리의 시험(`bite-gates.sh` 의 묶음 · 인자 절)은 변조 시험 안에
있어 변조 시험이 안 돌면 같이 안 돌았다. 그래서 이것은 늘 도는 `checks` 묶음에 둔다.

**고정 목록.** 기대는 시험 대상인 `gates.sh` 에서 읽지 않고 이 파일의 `CHECKS` · `FIVE` 가 든다 — 읽으면 검사 줄을 지운
`gates.sh` 가 기대에서도 그 줄을 지워 지나간다(감사 OB-2, 조각 38 · ADR 0049). 검사를 더하거나 빼는 PR 은 `gates.sh` 와 이
목록을 함께 고친다. 갈리면 여기서 떨어지므로 「목록은 `gates.sh` 한 군데에만」(`CLAUDE.md`)의 예외다.

**어떻게.** 임시 git 저장소에 `gates.sh` 를 베끼고, 그 파일이 부르는 것을 다 셸 가짜로 세운다 — `python3` · `claude` 는 PATH
맨 앞의 가짜이고, `./scripts/…sh` 는 그 자리의 가짜 파일이다. 가짜는 제 이름(스크립트는 파일 이름, claude 는 `claude:<폴더>`)을
기록에 적고 0 으로 끝난다 — `GATES_FAIL` 이 제 이름이면 1 로 끝난다(조각 38 설계 ② S4). 그리고 이렇게 본다(조각 35 설계 끝
「닫기 전 감사 회차에서 찾은 것」 T1 ~ T3, 조각 36 설계 ② N1 · N2, 조각 38 설계 ② L · S).
  - L2 `gates.sh` 가 부르는 것이 `CHECKS` · `FIVE` 와 이름마다 횟수가 같다(다 한 번). 차례는 보지 않는다
  - T1 인자 없이(`GITHUB_ACTIONS` 없음) — 종료 0, 목록의 것이 다 한 번씩 돌고, 변조 시험 다섯은 다른 것이 다 돈 뒤에 돈다
  - T1′ 인자 없이 `GITHUB_ACTIONS=true` — T1 과 같다. CI 가 지문을 「물었다」로 적는 실행이 쓰는 꼴이다
  - T2 `GITHUB_ACTIONS=true --skip-bite 근거` — 종료 0, `CHECKS` 가 다 돌고, 다섯은 하나도 안 돈다
  - T3 변조 시험 다섯은 이 파일이 이름으로 든다 — `gates.sh` 에서 하나라도 안 불리면 떨어진다
  - S1 목록의 서른마다 그 하나만 1 로 끝나게 하고 T1 · T1′ 의 꼴로 부른다 — `gates.sh` 가 0 이 아닌 종료여야 한다
  - S2 `CHECKS` 의 스물다섯마다 같은 것을 T2 의 꼴로 — 건너뛰는 실행에서만 삼키는 꼴을 문다

「부르는 것」은 `gates.sh` 의 주석 아닌 줄에서 `python3 scripts/…` · `./scripts/…` · `claude plugin validate …` 를 읽는다.
그 줄이 어느 묶음에 있는지는 보지 않고 실제로 돌았는지만 본다 — 검사 줄을 지우거나 겹치거나 목록에 없는 것을 더하면 L2 에서,
검사를 `bites` 로 옮기면 T2 에서, 변조 시험을 `checks` 로 옮기면 T2 에서, `bites` 호출을 지우거나 분기를 뒤집으면 T1 에서,
CI 에서만 건너뛰게 하면 T1′ 에서, 어느 줄의 실패를 삼키면(`|| true` · `set +e` · CI 에서만 · `--skip-bite` 에서만) S1 · S2 에서
떨어진다. 검사의 인자는 보지 않는다(조각 38 설계 ② 「보장하지 않는 것」). 이것이 무는지는 `bite-gates.sh` 가 본다 — 이 줄이
`checks` 에서 빠지는 것도 그 절이 진짜 `gates.sh` 에 이것을 불러 문다(설계 ② R).
**세 규칙**(조각 41 설계 ② C · N · K · ADR 0054) — S 의 꼴이 변조본, T1 · T1′ · T2 가 대조군이다.
  - (가) S 가 돈 수를 `2 × 목록 + CHECKS` 와 견주고, 대조군 셋이 다 돌았는지 본다 — 고리가 일찍 끝나거나 꼴을 거르면 S1 에서 떨어진다.
    목록 자체는 L2 가 `gates.sh` 와 견준다
  - (나) S 는 `gates.sh` 가 가짜의 종료(1)를 그대로 내고, 그 검사가 실제로 불렸고, `gates.sh` 자신의 셸 오류 줄이 없을 때만 「물었다」다
    — 0 이 아닌 아무 종료(셸 오류 · 시간 넘김)를 세지 않는다
  - (다) 대조군은 종료 0 과 돈 목록 · 차례에 더해 `gates.sh` 의 끝 줄(「… 다 통과」 · 「… 건너뛰었다 — <근거>」)을 본다
새 실패 줄도 다 위의 태그로 연다 — 태그마다 변조본은 `bite-gates.sh` 가 본다(설계 ② R).
수트 지문 밖이다(`run-evals.sh` 가 부르지 않는다). 표준 라이브러리만 쓴다.
"""
import collections
import os
import pathlib
import re
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
USAGE = "사용법: test-gates.py [<gates.sh>]"
TIMEOUT = 60
KEPT = 3  # 대조군 — 인자 없이 부르는 꼴(T1 · T1′)과 --skip-bite(T2)

# L1 — 늘 도는 스물다섯(조각 38 설계 ③ L1-c). 검사를 더하거나 빼면 gates.sh 와 함께 고친다(ADR 0049).
CHECKS = (
    "claude:./vibe-audit", "claude:./vibe-slice",
    "verify-manifest.py", "test-verify-manifest.py",
    "verify-copies.py", "verify-feedback.py", "verify-evals.py", "verify-graders.py", "verify-budget.py",
    "test-verify-brief.py", "test-compare-copies.py", "test-verify-feedback.py",
    "verify-copy.py",
    "verify-docs.py", "test-verify-docs.py", "test-sync-slice.py",
    "verify-slice-gate.py", "test-verify-slice-gate.py", "verify-ledger.py",
    "verify-map-pin.py", "test-verify-map-pin.py",
    "test-eval-merged-pass.py", "verify-eval-gate.py", "verify-counts.py", "test-gates.py",
)
# T3 · L1-b — 건너뛸 수 있는 것은 이 다섯뿐이다(조각 35 설계 ② G4).
FIVE = ("bite-verify-docs.py", "bite-slice-gate.py", "bite-map-pin.py", "bite-eval-merged-pass.py", "bite-gates.sh")
ALL = CHECKS + FIVE

CALL = re.compile(r"^\s*(?:python3 scripts/(?P<py>[\w.-]+\.py)|\./scripts/(?P<sh>[\w.-]+\.sh)|claude plugin validate (?P<cl>\S+))(?:\s|$)")

# 셸 가짜(설계 ② S4) — 가짜 하나에 파이썬 하나를 띄우지 않는다. python3 가짜는 첫 인자(scripts/<이름>)의 파일 이름을 적는다.
PY_FAKE = ('#!/bin/sh\nn=${1##*/}\nprintf "%s\\n" "$n" >> "$GATES_RAN"\n'
           '[ "${GATES_FAIL:-}" = "$n" ] && exit 1\nexit 0\n')
SH_STUB = '#!/bin/sh\nprintf "%s\\n" {name} >> "$GATES_RAN"\n[ "${{GATES_FAIL:-}}" = {name} ] && exit 1\nexit 0\n'
# (다) gates.sh 의 끝 줄 — 인자 없이(T1 · T1′)와 --skip-bite(T2)
DONE = re.compile(r"^\S+ 다 통과 — 키 없이 볼 수 있는 것은 여기까지다\.$", re.M)
SKIPPED = re.compile(r"^\S+ 통과 · 변조 시험 다섯은 건너뛰었다 — 근거$", re.M)
SHELL_ERR = re.compile(r"gates\.sh: line [0-9]+: ")
CLAUDE_FAKE = ('#!/bin/sh\nprintf "claude:%s\\n" "$3" >> "$GATES_RAN"\n'
               '[ "${GATES_FAIL:-}" = "claude:$3" ] && exit 1\nexit 0\n')


def calls(text):
    """`gates.sh` 의 주석 아닌 줄에서 부르는 것의 이름 — 스크립트는 파일 이름, claude 는 `claude:<폴더>`."""
    out = []
    for line in text.split("\n"):
        if line.lstrip().startswith("#"):
            continue
        m = CALL.match(line)
        if m:
            out.append(m["py"] or m["sh"] or f"claude:{m['cl']}")
    return out


def run(repo, bindir, ran, env_extra, args):
    ran.write_text("", encoding="utf-8")
    env = {k: v for k, v in os.environ.items() if k not in ("GITHUB_ACTIONS", "GATES_FAIL")}
    env.update(env_extra, PATH=f"{bindir}{os.pathsep}{os.environ.get('PATH', '')}", GATES_RAN=str(ran))
    try:
        p = subprocess.run(["bash", "scripts/gates.sh", *args], cwd=repo, env=env,
                           capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        return None, "", []
    return p.returncode, p.stdout + p.stderr, ran.read_text(encoding="utf-8").split()


def fake(path, body):
    path.write_text(body, encoding="utf-8")
    path.chmod(0o755)


def judge(gates):
    """실패 줄의 목록. 비었으면 통과."""
    text = gates.read_text(encoding="utf-8")
    got_calls = collections.Counter(calls(text))
    bad = [f"T3 변조 시험 {f} 를 부르는 줄이 gates.sh 에 없다" for f in FIVE if f not in got_calls]

    # L2 — 이름마다 꼭 한 번. 목록에 없는 이름도 떨어진다(새 검사는 이 파일의 목록을 함께 고친다)
    for name in ALL:
        if got_calls[name] != 1:
            bad.append(f"L2 {name} 을 부르는 줄이 gates.sh 에 {got_calls[name]} 번이다 — 고정 목록은 한 번이다")
    for name in sorted(set(got_calls) - set(ALL)):
        bad.append(f"L2 {name} 을 gates.sh 가 부르는데 고정 목록에 없다 — 검사를 더했으면 test-gates.py 의 목록도 고친다")

    with tempfile.TemporaryDirectory() as tmp:
        repo, bindir = pathlib.Path(tmp, "repo"), pathlib.Path(tmp, "bin")
        (repo / "scripts").mkdir(parents=True)
        bindir.mkdir()
        subprocess.run(["git", "init", "-q", str(repo)], check=True)
        (repo / "scripts/gates.sh").write_text(text, encoding="utf-8")
        for c in set(got_calls) | set(ALL):
            if c.endswith(".sh"):
                fake(repo / "scripts" / c, SH_STUB.format(name=c))
        fake(bindir / "python3", PY_FAKE)
        fake(bindir / "claude", CLAUDE_FAKE)
        ran = pathlib.Path(tmp, "ran.txt")

        forms = (("T1", {}, []), ("T1′", {"GITHUB_ACTIONS": "true"}, []))
        kept = 0
        # T1 · T1′ 인자 없이 — 목록의 것이 다 한 번씩, 변조 시험은 맨 뒤에. T1′ 은 CI 의 꼴(GITHUB_ACTIONS=true)이다
        for tag, extra, args in forms:
            st, out, got = run(repo, bindir, ran, extra, args)
            kept += 1
            if st != 0:
                bad.append(f"{tag} 인자 없이 부른 gates.sh 가 종료 {st} 다 — 0 이어야 한다\n{out[-600:]}")
                continue
            if not DONE.search(out):
                bad.append(f"{tag} 인자 없이 부른 gates.sh 가 「… 다 통과」 끝 줄을 찍지 않았다\n{out[-600:]}")
            missing = [c for c in ALL if got.count(c) != 1]
            if missing:
                bad.append(f"{tag} 인자 없이 불렀는데 돌지 않았거나 한 번이 아니다: {missing}")
            five_at = [i for i, c in enumerate(got) if c in FIVE]
            rest_at = [i for i, c in enumerate(got) if c not in FIVE]
            if five_at and rest_at and min(five_at) < max(rest_at):
                bad.append(f"{tag} 변조 시험이 다른 검사보다 먼저 돌았다(설계 ② G1): {got}")

        # T2 CI 의 --skip-bite — 다섯만 빠진다
        skip = ({"GITHUB_ACTIONS": "true"}, ["--skip-bite", "근거"])
        st, out, got = run(repo, bindir, ran, *skip)
        kept += 1
        if st != 0:
            bad.append(f"T2 --skip-bite 로 부른 gates.sh 가 종료 {st} 다 — 0 이어야 한다\n{out[-600:]}")
        else:
            if not SKIPPED.search(out):
                bad.append(f"T2 --skip-bite 로 부른 gates.sh 가 「… 건너뛰었다 — 근거」 끝 줄을 찍지 않았다\n{out[-600:]}")
            ran_five = [c for c in got if c in FIVE]
            if ran_five:
                bad.append(f"T2 --skip-bite 인데 변조 시험이 돌았다: {ran_five}")
            missing = [c for c in CHECKS if got.count(c) != 1]
            if missing:
                bad.append(f"T2 --skip-bite 에서 늘 돌아야 할 것이 돌지 않았거나 한 번이 아니다: {missing}")

        # S1 · S2 하나가 떨어지면 gates.sh 도 떨어진다 — 실패를 삼키면 그 검사는 게이트가 아니고, 변조 시험이면 거짓 근거가 적힌다
        cases = [("S1", tag, extra, args, name) for tag, extra, args in forms for name in ALL]
        cases += [("S2", "T2", skip[0], skip[1], name) for name in CHECKS]
        bitten = 0
        for s, tag, extra, args, name in cases:
            st, out, got = run(repo, bindir, ran, {**extra, "GATES_FAIL": name}, args)
            bitten += 1
            if st == 0:
                bad.append(f"{s} {tag} 의 꼴에서 {name} 이 1 로 끝났는데 gates.sh 가 종료 0 이다 — 실패를 삼켰다")
            elif st is None:
                bad.append(f"{s} {tag} 의 꼴에서 {name} 이 1 로 끝났는데 gates.sh 가 {TIMEOUT}초 안에 끝나지 않았다")
            elif st != 1 or name not in got or SHELL_ERR.search(out):
                # (나) 다른 까닭의 실패 — 셸 오류 · 그 검사를 부르지도 않고 떨어짐 · 가짜의 종료가 아닌 종료
                bad.append(f"{s} {tag} 의 꼴에서 {name} 이 1 로 끝났는데 gates.sh 가 그 실패로 떨어지지 않았다 "
                           f"(종료 {st} · 불림 {name in got}){chr(10)}{out[-600:]}")
        want = 2 * len(ALL) + len(CHECKS)
        if (bitten, kept) != (want, KEPT):
            bad.append(f"S1 꼴이 {bitten} · 대조군이 {kept} 돌았다 — {want} · {KEPT} 이어야 한다(고리가 일찍 끝났거나 꼴을 걸렀다)")
    return bad


def main(argv):
    if len(argv) > 1 or (argv and argv[0].startswith("-")):
        print(USAGE, file=sys.stderr)
        return 2
    gates = pathlib.Path(argv[0]) if argv else ROOT / "scripts/gates.sh"
    if not gates.is_file():
        print(f"FAIL {gates} 가 없다", file=sys.stderr)
        return 1
    bad = judge(gates)
    if bad:
        for b in bad:
            print(f"FAIL {b}")
        return 1
    print(f"PASS test-gates.py — 변조본(S) {2 * len(ALL) + len(CHECKS)} · 대조군 {KEPT} 이 돌았다, 부르는 것이 고정 목록 {len(ALL)} 그대로(L2), 인자 없이 다 돌고 변조 시험 다섯이 맨 뒤"
          f"(T1 · CI 의 꼴 T1′), --skip-bite 는 {len(CHECKS)} 만 돈다(T2), 다섯을 이름으로 든다(T3), "
          f"어느 것이 떨어져도 꼴마다 떨어진다(S1 · S2)")
    return 0


if __name__ == "__main__":
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv[1:]))
