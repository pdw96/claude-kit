#!/usr/bin/env python3
"""`gates.sh` 가 부르는 **변조 시험의 지문**을 찍는다. CI 가 이것으로 「변조 시험이 이미 물었던 입력」을 알아본다.

  python3 scripts/gate-key.py          # 한 줄 — gate-bite-py<파이썬 판>-git<git 판>-<24 자리 16진>
  python3 scripts/gate-key.py --list   # 같은 한 줄과, 든 파일마다 「<12 자리>  <경로>」를 stderr 에

**왜 있나.** 변조 시험 다섯(`bite-*.py` 넷 · `bite-gates.sh`)이 gate 잡의 거의 전부인데, 그것이 보는 것 — 검사 코드가
무는지 — 은 검사 코드와 그것이 규칙으로 읽는 파일이 그대로면 같다. 지문이 이미 통과했으면 CI 가 변조 시험만 건너뛴다
(조각 35 · ADR 0046). 수트의 `eval-key.py` 와 같은 원리이고, 넣고 빼는 규칙이 달라 파일을 따로 둔다(ADR 0046 의 5).

**빼는 쪽만 적는 이유.** 넣는 쪽을 적으면 새 파일이 조용히 지문에서 빠지고, 그 파일만 바꾼 PR 은 변조 시험 없이 지나간다.
빼는 것은 검사가 **대조하는** 문서와 기록뿐이다(조각 35 설계 ③ S1 ~ S12) — 그 문서가 바뀌면 늘 도는 검사와 자체 시험이
다시 대조한다. 빼는 쪽에 새 꼴을 더하려면 ADR 0046 을 대체한다.

지문에 드는 것(설계 ② K1 ~ K4):
  - `git ls-files` 가 아는 파일 가운데 SKIP 밖의 전부 — 경로 · 실행 비트 · 내용의 해시. 지운 파일도 지문을 바꾼다
  - `python3 --version` · `git --version` 의 판 — 키의 머리에. 못 읽거나 뜻밖의 모양이면 지문을 내지 않고 종료 1

`run-evals.sh` 가 부르지 않아 수트 지문 밖이다(K5). 이것이 무는지는 `bite-gates.sh` 의 변조 시험 지문 절이 본다(K6).
표준 라이브러리만 쓴다.
"""
import hashlib
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
USAGE = "사용법: gate-key.py [--list]"

# 설계 ③ S1 ~ S12 — 검사가 대조하는 문서와 기록. 이 밖은 다 넣는다(S13 ~ S19).
SKIP = re.compile(
    r"^docs/slices/"            # S1 조각 문서
    r"|^docs/adr/"              # S2 결정 기록
    r"|^docs/eval-log/"         # S3 감사자 작업 기록
    r"|^docs/master-plan\.md$"  # S4
    r"|^docs/architecture\.md$" # S5
    r"|^docs/schema\.md$"       # S6
    r"|^INTENT\.md$"            # S7
    r"|^CLAUDE\.md$"            # S8
    r"|^AGENTS\.md$"            # S9
    r"|^CHECKLIST\.md$"         # S10
    r"|(^|/)README\.md$"        # S11 어느 폴더든
    r"|^docs/audit/"            # S12 부적합 대장 · 감사 기록
)

# 판의 모양 — 「Python 3.13.1」 · 「git version 2.43.0」(맥의 「(Apple Git-146)」 같은 꼬리는 뗀다)
VERSIONS = (
    ("py", ["python3", "--version"], re.compile(r"^Python ([0-9][\w.+-]*)$")),
    ("git", ["git", "--version"], re.compile(r"^git version ([0-9][\w.+-]*)(?: \(.*\))?$")),
)


def inputs():
    out = subprocess.run(["git", "ls-files", "-z"], cwd=ROOT,
                         check=True, capture_output=True, text=True).stdout
    return sorted({f for f in out.split("\0") if f and not SKIP.search(f)})


def version(cmd, shape):
    # 못 읽으면 지문을 안 낸다. 판 없이 낸 지문은 도구가 바뀌어도 같아서, 새 도구에서 한 번도 안 문 입력을
    # 「물었다」고 읽게 된다.
    try:
        v = subprocess.run(cmd, check=True, capture_output=True, text=True).stdout.strip()
    except (OSError, subprocess.CalledProcessError) as e:
        sys.exit(f"{' '.join(cmd)} 을 못 읽었다 — 지문을 내지 않는다: {e}")
    m = shape.match(v)
    if not m:
        sys.exit(f"{' '.join(cmd)} 이 뜻밖의 모양이다 — 지문을 내지 않는다: {v!r}")
    return m.group(1)


def main():
    args = sys.argv[1:]
    if args not in ([], ["--list"]):
        print(USAGE, file=sys.stderr)
        sys.exit(2)
    listing = bool(args)

    head = "-".join(f"{name}{version(cmd, shape)}" for name, cmd, shape in VERSIONS)

    h = hashlib.sha256()
    for f in inputs():
        p = ROOT / f
        # 지운 파일도 지문을 바꿔야 한다 — 없다는 것 자체가 입력이다.
        body = p.read_bytes() if p.is_file() else b"\0(missing)"
        # 실행 비트도 입력이다 — 비트를 뺀 스크립트는 gates.sh 에서 안 돈다.
        xbit = b"x" if p.is_file() and p.stat().st_mode & 0o100 else b"-"
        h.update(f.encode() + b"\0" + xbit + hashlib.sha256(body).digest())
        if listing:
            print(f"  {hashlib.sha256(body).hexdigest()[:12]}  {f}", file=sys.stderr)

    print(f"gate-bite-{head}-{h.hexdigest()[:24]}")


if __name__ == "__main__":
    main()
