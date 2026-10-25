#!/usr/bin/env python3
"""`gates.sh` 가 **무엇을 실제로 부르는지** 본다 — 인자 없이는 변조 시험 다섯까지 다 돌고, `--skip-bite` 는 그 다섯만 뺀다.

  python3 scripts/test-gates.py                # 이 저장소의 gates.sh
  python3 scripts/test-gates.py <gates.sh>     # 다른 판 — bite-gates.sh 가 변조본으로 쓴다

**왜 있나.** CI 는 인자 없이 돈 `gates.sh` 가 통과하면 그 지문을 「변조 시험이 물었다」로 적고, 같은 지문의 다음 실행은
변조 시험을 건너뛴다(`eval.yml` · ADR 0046). 그 전제 — 인자 없이 부르면 변조 시험 다섯이 돈다 — 를 무는 검사가 없어서,
`bites` 호출을 지우거나 건너뛰는 분기의 조건을 뒤집은 `gates.sh` 가 변조 시험 없이 초록으로 지나가고 거짓 근거를 적을 수
있었다(조각 35 닫기 전 감사 회차 `audit-quality` NC-1). 그 자리의 시험(`bite-gates.sh` 의 묶음 · 인자 절)은 변조 시험 안에
있어 변조 시험이 안 돌면 같이 안 돌았다. 그래서 이것은 늘 도는 `checks` 묶음에 둔다.

**어떻게.** 임시 git 저장소에 `gates.sh` 를 베끼고, 그 파일이 부르는 스크립트와 `claude` 를 다 가짜로 세운다 — 가짜는 제
이름을 기록에 적고 0 으로 끝난다 — `GATES_FAIL` 이 제 이름이면 1 로 끝난다. 그리고 이렇게 부른다(조각 35 설계 끝 「닫기 전
감사 회차에서 찾은 것」 T1 ~ T3, 조각 36 설계 ② N1 · N2 — 감사 회차 2 의 NC-2).
  - T1 인자 없이(`GITHUB_ACTIONS` 없음) — 종료 0, 부르는 것이 다 한 번씩 돌고, 변조 시험 다섯은 다른 것이 다 돈 뒤에 돈다
  - T1′ 인자 없이 `GITHUB_ACTIONS=true` — T1 과 같다. CI 가 지문을 「물었다」로 적는 실행이 쓰는 꼴이다
  - T2 `GITHUB_ACTIONS=true --skip-bite 근거` — 종료 0, 변조 시험 다섯 말고 다 돌고, 다섯은 하나도 안 돈다
  - T3 변조 시험 다섯은 이 파일이 이름으로 든다 — `gates.sh` 에서 하나라도 안 불리면 떨어진다
  - T5 다섯마다 그 하나만 1 로 끝나게 하고 T1 · T1′ 의 꼴로 부른다 — `gates.sh` 가 0 이 아닌 종료여야 한다. 떨어진 변조 시험을
    삼킨 실행이 지문을 적지 않게 한다

「부르는 것」은 `gates.sh` 의 주석 아닌 줄에서 `python3 scripts/…` · `./scripts/…` · `claude plugin validate …` 를 읽는다.
그 줄이 어느 묶음에 있는지는 보지 않고 실제로 돌았는지만 본다 — 검사를 `bites` 로 옮기면 T2 에서, 변조 시험을 `checks` 로
옮기면 T2 에서, `bites` 호출을 지우거나 분기를 뒤집으면 T1 에서, CI 에서만 건너뛰게 하면 T1′ 에서, 변조 시험의 실패를
`|| true` 로 삼키면 T5 에서 떨어진다. 이것이 무는지는 `bite-gates.sh` 가 본다.
수트 지문 밖이다(`run-evals.sh` 가 부르지 않는다). 표준 라이브러리만 쓴다.
"""
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
USAGE = "사용법: test-gates.py [<gates.sh>]"
TIMEOUT = 60

# T3 — 건너뛸 수 있는 것은 이 다섯뿐이다(조각 35 설계 ② G4).
FIVE = ("bite-verify-docs.py", "bite-slice-gate.py", "bite-map-pin.py", "bite-eval-merged-pass.py", "bite-gates.sh")

CALL = re.compile(r"^\s*(?:python3 scripts/(?P<py>[\w.-]+\.py)|\./scripts/(?P<sh>[\w.-]+\.sh)|claude plugin validate (?P<cl>\S+))(?:\s|$)")

PY_STUB = ('import os, sys\nwith open(os.environ["GATES_RAN"], "a", encoding="utf-8") as f:\n    f.write({name!r} + "\\n")\n'
           'sys.exit(1 if os.environ.get("GATES_FAIL") == {name!r} else 0)\n')
SH_STUB = '#!/bin/sh\nprintf "%s\\n" {name} >> "$GATES_RAN"\n[ "${{GATES_FAIL:-}}" = {name} ] && exit 1\nexit 0\n'
CLAUDE_STUB = '#!/bin/sh\nprintf "claude:%s\\n" "$3" >> "$GATES_RAN"\n'


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


def judge(gates):
    """실패 줄의 목록. 비었으면 통과."""
    text = gates.read_text(encoding="utf-8")
    want = calls(text)
    bad = [f"T3 변조 시험 {f} 를 부르는 줄이 gates.sh 에 없다" for f in FIVE if f not in want]
    rest = [c for c in want if c not in FIVE]

    with tempfile.TemporaryDirectory() as tmp:
        repo, bindir = pathlib.Path(tmp, "repo"), pathlib.Path(tmp, "bin")
        (repo / "scripts").mkdir(parents=True)
        bindir.mkdir()
        subprocess.run(["git", "init", "-q", str(repo)], check=True)
        shutil.copyfile(gates, repo / "scripts/gates.sh")
        for c in set(want) | set(FIVE):
            if c.endswith(".py"):
                (repo / "scripts" / c).write_text(PY_STUB.format(name=c), encoding="utf-8")
            elif c.endswith(".sh"):
                (repo / "scripts" / c).write_text(SH_STUB.format(name=c), encoding="utf-8")
                (repo / "scripts" / c).chmod(0o755)
        (bindir / "claude").write_text(CLAUDE_STUB, encoding="utf-8")
        (bindir / "claude").chmod(0o755)
        ran = pathlib.Path(tmp, "ran.txt")

        # T1 · T1′ 인자 없이 — 다 한 번씩, 변조 시험은 맨 뒤에. T1′ 은 CI 의 꼴(GITHUB_ACTIONS=true)이다
        for tag, extra in (("T1", {}), ("T1′", {"GITHUB_ACTIONS": "true"})):
            st, out, got = run(repo, bindir, ran, extra, [])
            if st != 0:
                bad.append(f"{tag} 인자 없이 부른 gates.sh 가 종료 {st} 다 — 0 이어야 한다\n{out[-600:]}")
                continue
            missing = [c for c in want if got.count(c) != want.count(c)]
            if missing:
                bad.append(f"{tag} 인자 없이 불렀는데 돌지 않았거나 횟수가 다르다: {missing}")
            five_at = [i for i, c in enumerate(got) if c in FIVE]
            rest_at = [i for i, c in enumerate(got) if c not in FIVE]
            if five_at and rest_at and min(five_at) < max(rest_at):
                bad.append(f"{tag} 변조 시험이 다른 검사보다 먼저 돌았다(설계 ② G1): {got}")

            # T5 다섯 가운데 하나가 떨어지면 gates.sh 도 떨어진다 — 실패를 삼키면 거짓 근거가 적힌다
            for f in FIVE:
                st, out, _ = run(repo, bindir, ran, {**extra, "GATES_FAIL": f}, [])
                if st == 0:
                    bad.append(f"T5 {tag} 의 꼴에서 {f} 가 1 로 끝났는데 gates.sh 가 종료 0 이다 — 변조 시험의 실패를 삼켰다")
                elif st is None:
                    bad.append(f"T5 {tag} 의 꼴에서 {f} 가 1 로 끝났는데 gates.sh 가 {TIMEOUT}초 안에 끝나지 않았다")

        # T2 CI 의 --skip-bite — 다섯만 빠진다
        st, out, got = run(repo, bindir, ran, {"GITHUB_ACTIONS": "true"}, ["--skip-bite", "근거"])
        if st != 0:
            bad.append(f"T2 --skip-bite 로 부른 gates.sh 가 종료 {st} 다 — 0 이어야 한다\n{out[-600:]}")
        else:
            ran_five = [c for c in got if c in FIVE]
            if ran_five:
                bad.append(f"T2 --skip-bite 인데 변조 시험이 돌았다: {ran_five}")
            missing = [c for c in rest if got.count(c) != rest.count(c)]
            if missing:
                bad.append(f"T2 --skip-bite 에서 늘 돌아야 할 것이 돌지 않았다: {missing}")
    return bad, want


def main(argv):
    if len(argv) > 1 or (argv and argv[0].startswith("-")):
        print(USAGE, file=sys.stderr)
        return 2
    gates = pathlib.Path(argv[0]) if argv else ROOT / "scripts/gates.sh"
    if not gates.is_file():
        print(f"FAIL {gates} 가 없다", file=sys.stderr)
        return 1
    bad, want = judge(gates)
    if bad:
        for b in bad:
            print(f"FAIL {b}")
        return 1
    print(f"PASS test-gates.py — 인자 없이 {len(want)} 개가 다 돌고 변조 시험 다섯이 맨 뒤(T1 · CI 의 꼴 T1′), "
          f"--skip-bite 는 {len(want) - len(FIVE)} 개만 돈다(T2), 다섯을 이름으로 든다(T3), "
          f"다섯 가운데 하나가 떨어지면 두 꼴 다 떨어진다(T5)")
    return 0


if __name__ == "__main__":
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv[1:]))
