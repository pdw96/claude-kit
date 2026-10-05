#!/usr/bin/env python3
"""`verify-feedback.py` 의 **역사를 보는 규칙**이 무는지 본다. 모델도 네트워크도 안 쓴다.

  python3 scripts/test-verify-feedback.py                 # 저장소의 검사기
  python3 scripts/test-verify-feedback.py <검사기 경로>     # 다른 판 — CI 가 변조본으로 쓴다

한 판만 보고 가를 수 있는 규칙(빈 칸 · 겹친 해시 · 없는 상태)은 CI 「게이트가 무는가」가
변조한 대장으로 본다. 여기는 **git 역사가 있어야** 가를 수 있는 둘을 임시 저장소로 본다.

  1. 한 번 매긴 번호는 사라지지 않고 주인(hash)도 안 바뀐다 — 끝 후보 지우기 · 가운데 지우고
     당기기 · 두 번호의 hash 바꾸기는 떨어지고, 상태만 바꾼 것은 통과한다
  2. 되먹임 완료의 케이스는 `feedback.commit` 에 있어야 한다 — 케이스보다 앞선 커밋을 적으면
     떨어지고, 케이스가 든 커밋을 적으면 통과한다

표준 라이브러리만 쓴다.
"""
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
ENV = {**os.environ, "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t",
       "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@t", "GIT_CONFIG_GLOBAL": os.devnull}


def sh(cwd, *args):
    p = subprocess.run(args, cwd=cwd, capture_output=True, text=True, env=ENV)
    if p.returncode != 0:
        sys.exit(f"준비 실패: {' '.join(map(str, args))}\n{p.stderr}")
    return p.stdout.strip()


def main():
    script = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / "scripts" / "verify-feedback.py"
    fails, passes = [], 0

    with tempfile.TemporaryDirectory() as t:
        repo = pathlib.Path(t)
        (repo / "scripts").mkdir()
        shutil.copy(script, repo / "scripts" / "verify-feedback.py")
        sh(repo, "git", "init", "-q", "-b", "main")
        sh(repo, "git", "add", "-A")
        sh(repo, "git", "commit", "-q", "-m", "검사기")
        base = sh(repo, "git", "rev-parse", "HEAD")

        def row(n, h, **kw):
            return {"id": f"FB-{n}", "hash": "sha256:" + h * 64,
                    "seen": [{"repo": "x", "files": ["audit-a.md"], "commit": "c" * 40, "base": base}],
                    "status": "defect", "reason": "근거", "decided_at": "2026-10-05", **kw}

        ledger = repo / "feedback.json"

        def write(rows):
            ledger.write_text(json.dumps({"candidates": rows}, ensure_ascii=False))

        def check():
            p = subprocess.run([sys.executable, str(repo / "scripts" / "verify-feedback.py")],
                               capture_output=True, text=True, env=ENV)
            return p.returncode, p.stdout + p.stderr

        def expect(name, ok, detail=""):
            nonlocal passes
            if ok:
                passes += 1
            else:
                fails.append(f"{name}{' — ' + detail[-300:] if detail else ''}")

        three = [row(1, "a"), row(2, "b"), row(3, "c")]
        write(three)
        sh(repo, "git", "add", "-A")
        sh(repo, "git", "commit", "-q", "-m", "대장")
        rc, out = check()
        expect("커밋한 성한 대장이 떨어졌다", rc == 0, out)

        # 1. 번호가 사라지거나 주인이 바뀐다
        write(three[:2])
        rc, out = check()
        expect("끝 후보를 지운 대장이 통과했다", rc == 1, out)
        write([three[0], {**three[2], "id": "FB-2"}])
        rc, out = check()
        expect("가운데를 지우고 당긴 대장이 통과했다", rc == 1, out)
        write([three[0], {**three[1], "hash": three[2]["hash"]}, {**three[2], "hash": three[1]["hash"]}])
        rc, out = check()
        expect("두 번호의 hash 를 바꾼 대장이 통과했다", rc == 1, out)
        write([three[0], {**three[1], "status": "specific"}, three[2], row(4, "d")])
        rc, out = check()
        expect("상태를 바꾸고 새 후보를 더한 대장이 떨어졌다", rc == 0, out)

        # 2. 되먹임 완료의 케이스는 그 커밋에 있어야 한다
        before = sh(repo, "git", "rev-parse", "HEAD")
        case = repo / "vibe-audit" / "evals" / "gate-x"
        case.mkdir(parents=True)
        (case / "case.yaml").write_text("name: gate-x\n")
        write(three)
        sh(repo, "git", "add", "-A")
        sh(repo, "git", "commit", "-q", "-m", "케이스")
        after = sh(repo, "git", "rev-parse", "HEAD")
        fed = lambda commit: {**three[1], "status": "fed_back",
                              "feedback": {"commit": commit, "cases": ["gate-x"], "budget_delta": 0}}
        write([three[0], fed(before), three[2]])
        rc, out = check()
        expect("케이스보다 앞선 커밋을 적은 되먹임이 통과했다", rc == 1, out)
        write([three[0], fed(after), three[2]])
        rc, out = check()
        expect("케이스가 든 커밋을 적은 되먹임이 떨어졌다", rc == 0, out)

    if fails:
        for f in fails:
            print(f"FAIL {f}")
        return 1
    print(f"PASS verify-feedback.py 역사 규칙 — 기대 {passes} 개 모두 맞다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
