#!/usr/bin/env python3
"""감사자 수트의 **입력 지문**을 찍는다. CI 가 이것으로 「이미 통과한 입력」을 알아본다.

  python3 scripts/eval-key.py route    # PR · push 가 돌리는 route-* 만
  python3 scripts/eval-key.py full     # workflow_dispatch 가 돌리는 전수
  python3 scripts/eval-key.py route --list   # 무엇을 넣었는지 찍는다

**왜 있나.** 구독 토큰으로 CI 를 돌리게 되면서 한 번에 24회(route-* 여덟 × 3회)가
사용량에서 나간다. 그런데 이 PR 의 커밋 쉰하나 가운데 열둘은 evals/README.md
**하나만** 고쳤다 — 수트 결과를 바꿀 수 없는 변경에 매번 24회를 썼다.

**경로가 아니라 내용으로 가르는 이유.** 「직전 커밋과의 차이가 README 뿐이면
건너뛴다」로 하면 직전 커밋이 빨갰을 때 README 한 줄로 PR 이 초록(Skipped)이
된다. 여기서는 **통과한 실행만** 지문을 캐시에 적고, 같은 지문을 다시 만났을
때만 건너뛴다. 실패한 입력은 몇 번을 다시 와도 다시 돈다. 강제 푸시에도 같다.

**빼는 쪽을 적는 이유.** 넣는 쪽(agents · evals …)을 적으면 새로 생긴 파일이
조용히 지문에서 빠지고, 그 파일만 바꾼 PR 은 수트 없이 지나간다. 빼는 것은
수트가 읽지 않는다고 확인한 것뿐이다 — README 와 예산 스냅숏.

지문에 드는 것:
  - vibe-audit/ 아래 git 이 아는 파일 전부 (README.md · evals/budget.txt 제외)
  - scripts/run-evals.sh 와, 그 안에 적힌 scripts/*.py|sh 전부 — 러너가 새
    스크립트를 부르게 되면 따로 안 고쳐도 따라 들어온다
  - .github/workflows/eval.yml — 수트에 넘기는 깃발이 여기 있다
  - claude CLI 버전 — 하네스가 바뀌면 같은 문구도 다르게 뜰 수 있다
  - 모드(route · full) — 전수가 통과했다고 route 가 따로 돈 것은 아니다.
    route 모드는 route-* 가 아닌 케이스 폴더를 뺀다. `--case 'route-*'` 로
    도는 수트가 그 폴더를 읽을 길이 없다 — 함정 케이스를 고친 PR 이 트리거
    수트를 다시 돌릴 까닭이 없다.

표준 라이브러리만 쓴다.
"""
import hashlib
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
RUNNER = "scripts/run-evals.sh"
SKIP = re.compile(r"(^|/)README\.md$|^vibe-audit/evals/budget\.txt$")
MODES = ("route", "full")


CASE = re.compile(r"^vibe-audit/evals/([^/]+)/")


def inputs(mode):
    out = subprocess.run(["git", "ls-files", "-z", "vibe-audit"], cwd=ROOT,
                         check=True, capture_output=True, text=True).stdout
    files = {f for f in out.split("\0") if f and not SKIP.search(f)}
    if mode == "route":
        files = {f for f in files
                 if not (m := CASE.match(f)) or m.group(1).startswith("route-")}
    called = re.findall(r"scripts/[\w.-]+\.(?:py|sh)",
                        (ROOT / RUNNER).read_text(encoding="utf-8"))
    files |= {RUNNER, ".github/workflows/eval.yml", *called}
    return sorted(files)


def cli_version():
    # 못 읽으면 지문을 안 낸다. 버전 없이 낸 지문은 하네스가 바뀌어도 같아서,
    # 새 하네스에서 한 번도 안 돈 입력을 「통과했다」고 읽게 된다.
    try:
        v = subprocess.run(["claude", "--version"], check=True,
                           capture_output=True, text=True).stdout.strip()
    except (OSError, subprocess.CalledProcessError) as e:
        sys.exit(f"claude --version 을 못 읽었다 — 지문을 내지 않는다: {e}")
    m = re.match(r"[\w.+-]+", v)
    if not m:
        sys.exit(f"claude --version 이 뜻밖의 모양이다 — 지문을 내지 않는다: {v!r}")
    return m.group(0)


def main():
    args = sys.argv[1:]
    if not args or args[0] not in MODES:
        sys.exit(f"사용법: {sys.argv[0]} {{{'|'.join(MODES)}}} [--list]")
    mode, listing = args[0], "--list" in args[1:]

    h = hashlib.sha256()
    for f in inputs(mode):
        p = ROOT / f
        # 지운 파일도 지문을 바꿔야 한다 — 없다는 것 자체가 입력이다.
        body = p.read_bytes() if p.is_file() else b"\0(missing)"
        # 실행 비트도 입력이다. 바이트만 세면 run-evals.sh 에서 비트를 뺀 PR 이 앞서
        # 통과한 지문을 되찾아 eval 을 건너뛰고, 러너가 안 돌 것을 아무도 못 본다(Codex 리뷰).
        xbit = b"x" if p.is_file() and p.stat().st_mode & 0o100 else b"-"
        h.update(f.encode() + b"\0" + xbit + hashlib.sha256(body).digest())
        if listing:
            print(f"  {hashlib.sha256(body).hexdigest()[:12]}  {f}", file=sys.stderr)

    ver = cli_version()
    print(f"eval-{mode}-cli{ver}-{h.hexdigest()[:24]}")


if __name__ == "__main__":
    main()
