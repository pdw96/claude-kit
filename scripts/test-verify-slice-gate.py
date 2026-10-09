#!/usr/bin/env python3
"""`verify-slice-gate.py` 가 조각 7 설계 ② 의 B · D · G · R 을 지키는지 본다. 모델도 네트워크도 안 쓴다.

  python3 scripts/test-verify-slice-gate.py [<검사 경로>]   # 없으면 scripts/verify-slice-gate.py

임시 git 레포(기본 가지 `main` 과 원격 가지 `origin/main` 을 갖춘)에 설계 ⑤ 표의 꼴을 하나씩 만들어 검사를
대고, 종료 코드와 보장 번호를 본다. 검사의 경로를 받는 까닭 — `bite-slice-gate.py` 가 망가뜨린 사본에 이
시험을 대어 떨어지는지 본다(R5).

표준 라이브러리만 쓴다.
"""
import json
import os
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHECK = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / "scripts" / "verify-slice-gate.py"
# CI 의 gate 잡은 GITHUB_EVENT_PATH 를 갖고 이 시험을 부른다 — 진짜 이벤트가 임시 레포의 판정에 끼지 않게 뺀다.
ENV = {k: v for k, v in os.environ.items() if k != "GITHUB_EVENT_PATH"}
ENV.update({"GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t",
            "GIT_COMMITTER_EMAIL": "t@t", "GIT_CONFIG_GLOBAL": os.devnull, "GIT_CONFIG_NOSYSTEM": "1"})

MASTER = """# 마스터플랜

## 가리키는 문서

| 무엇 | 어디 |
|---|---|
| 의도 — 목표 · 범위 · 하지 않을 일 | `INTENT.md` |
| 절차와 문서의 모양 | `docs/procedure.md` |

## 조각 나눔

| 순서 | 조각 | 목표 한 줄 | 의존 | 상태 | 조각 폴더 |
|---|---|---|---|---|---|
| 1 | 하나 | 첫 조각 | — | 닫힘 | `docs/slices/1-one/` |
{extra}"""
DOING = "| 2 | 둘 | 둘째 조각 | 하나 | 진행 | `docs/slices/2-two/` |\n"
PLANNED = "| 2 | 둘 | 둘째 조각 | 하나 | 예정 | — |\n"


def sh(cwd, *args):
    p = subprocess.run(args, cwd=cwd, capture_output=True, text=True, env=ENV)
    if p.returncode != 0:
        sys.exit(f"준비 실패: {' '.join(map(str, args))}\n{p.stderr}")
    return p.stdout.strip()


def put(repo, files):
    for rel, text in files.items():
        p = repo / rel
        if text is None:
            p.unlink()
            continue
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text, encoding="utf-8")


def commit(repo, files, msg="x"):
    put(repo, files)
    sh(repo, "git", "add", "-A")
    sh(repo, "git", "commit", "-q", "--allow-empty", "-m", msg)
    return sh(repo, "git", "rev-parse", "HEAD")


def base_files(doing=True, design=True):
    files = {"INTENT.md": "의도\n", "docs/procedure.md": "절차\n", "README.md": "입구\n",
             "scripts/a.py": "print(1)\n", "docs/slices/1-one/requirements.md": "요구\n",
             "docs/slices/1-one/design.md": "설계\n",
             "docs/master-plan.md": MASTER.format(extra=DOING if doing else PLANNED)}
    if doing:
        files["docs/slices/2-two/requirements.md"] = "요구\n"
        if design:
            files["docs/slices/2-two/design.md"] = "설계\n"
    return files


def repo(at, base, master=True):
    """`main` 과 `origin/main` 이 기준 커밋에 있고, 가지 `work` 가 체크아웃된 레포."""
    at.mkdir(parents=True)
    sh(at, "git", "init", "-q", "-b", "main")
    if not master:
        base = {k: v for k, v in base.items() if k != "docs/master-plan.md"}
    s = commit(at, base, "기준")
    sh(at, "git", "update-ref", "refs/remotes/origin/main", s)
    sh(at, "git", "checkout", "-q", "-b", "work")
    return at


# UTF-8 이 아닌 로케일과 cp949 콘솔 — 한국어 Windows 를 이 기계에서 흉내 낸다(E1 · E2, 조각 9 설계 끝 「단계 5 에서 찾은 것」).
NON_UTF8 = {"LC_ALL": "C", "PYTHONCOERCECLOCALE": "0", "PYTHONUTF8": "0", "PYTHONIOENCODING": "cp949"}


def run(cwd, *args, event=None, extra=None):
    env = dict(ENV, **(extra or {}))
    if event is not None:
        env["GITHUB_EVENT_PATH"] = str(event)
    p = subprocess.run([sys.executable, str(CHECK), *args], cwd=cwd, capture_output=True, text=True,
                       encoding="utf-8", errors="replace", env=env)
    return p.returncode, p.stdout + p.stderr


bad = []


def expect(what, ok, out=""):
    if not ok:
        bad.append(f"{what}\n    {out.strip().replace(chr(10), chr(10) + '    ')}")


def verdict(what, got, rc, gids=(), absent=()):
    code, out = got
    expect(f"{what} — exit {code}, 기대 {rc}", code == rc, out)
    for g in gids:
        expect(f"{what} — [{g}] 가 없다", f"[{g}]" in out, out)
    for g in absent:
        expect(f"{what} — [{g}] 가 있다", f"[{g}]" not in out, out)


FOUND = {"docs/slices/3-three/requirements.md": "요구\n", "docs/slices/3-three/design.md": "설계\n",
         "docs/adr/0009-three.md": "결정\n", "INTENT.md": "의도 고침\n",
         "docs/master-plan.md": MASTER.format(extra=DOING + "| 3 | 셋 | 셋째 | 하나 | 진행 | `docs/slices/3-three/` |\n")}


def main():
    if not CHECK.is_file():
        sys.exit(f"검사가 없다 — {CHECK}")
    with tempfile.TemporaryDirectory() as t:
        tmp = pathlib.Path(t)
        n = iter(range(1000))

        def committed(what, base, files, rc, gids=(), absent=(), master=True):
            r = repo(tmp / f"r{next(n)}", base, master)
            commit(r, files)
            verdict(what, run(r), rc, gids, absent)
            return r

        # 착공 — 결정 문서만
        committed("착공 — 요구사항 · 설계 · 새 ADR · 마스터플랜 · 의도", base_files(doing=False), FOUND, 0)
        # G1 — 착공 PR 에 결정 문서 밖
        for extra in ({"scripts/x.py": "x\n"}, {"CHECKLIST.md": "목록\n"},
                      {"docs/slices/3-three/notes.md": "메모\n"}):
            committed(f"착공 + {next(iter(extra))}", base_files(), {**FOUND, **extra}, 1, ["G1"])
        # G2
        committed("기준에 `진행` 조각이 없을 때 구현", base_files(doing=False), {"scripts/a.py": "print(2)\n"}, 1, ["G2"])
        committed("기준의 `진행` 조각에 design.md 가 없을 때 구현", base_files(design=False),
                  {"scripts/a.py": "print(2)\n"}, 1, ["G2"])
        committed("머리만 마스터플랜을 `진행` 으로 고친 구현(R2)", base_files(doing=False),
                  {"scripts/a.py": "print(2)\n", "docs/master-plan.md": MASTER.format(extra=DOING),
                   "docs/slices/2-two/design.md": "설계\n"}, 1, ["G2"])
        committed("기준에 `진행` 조각과 설계 — 구현 · 설계 끝 날짜 항목", base_files(),
                  {"scripts/a.py": "print(2)\n", "docs/slices/2-two/design.md": "설계\n\n2026-10-08 정함\n"}, 0)
        committed("닫는 PR — 요구사항 「닫으며」 · 마스터플랜 · 절차 지도 · README", base_files(),
                  {"docs/slices/2-two/requirements.md": "요구\n\n## 닫으며 (2026-10-08)\n",
                   "docs/master-plan.md": MASTER.format(extra=DOING.replace("진행", "닫힘")),
                   "docs/procedure.md": "절차 고침\n", "README.md": "입구 고침\n"}, 0)
        r = committed("기준에 마스터플랜이 없다", base_files(doing=False), {"scripts/x.py": "x\n"}, 0, master=False)
        expect("기준에 마스터플랜이 없다 — 「보지 않는다」를 찍지 않았다", "보지 않는다" in run(r)[1], run(r)[1])
        committed("바꾼 파일이 없다", base_files(doing=False), {}, 0)
        committed("표를 읽지 못하는 기준 마스터플랜(R3)",
                  {**base_files(), "docs/master-plan.md": "# 마스터플랜\n\n## 조각 나눔\n\n없다\n"},
                  {"scripts/a.py": "print(2)\n"}, 1, ["G2"])

        # G1 과 G2 를 둘 다 찍는다
        committed("착공 + 구현, 기준에 `진행` 없음 — G1 · G2 둘 다", base_files(doing=False),
                  {**FOUND, "scripts/x.py": "x\n"}, 1, ["G1", "G2"])

        # B2 — 기준을 못 찾는다
        r = repo(tmp / f"r{next(n)}", base_files())
        commit(r, {"scripts/a.py": "print(2)\n"})
        verdict("기준 rev 가 없다", run(r, "--base", "nope", "--head", "HEAD"), 1, ["B2"])
        orphan = sh(r, "git", "commit-tree", "-m", "고아", sh(r, "git", "rev-parse", "HEAD^{tree}"))
        verdict("merge-base 가 없다", run(r, "--base", orphan, "--head", "main"), 1, ["B2"])
        shallow = tmp / f"r{next(n)}"
        sh(tmp, "git", "clone", "-q", "--depth", "1", "--no-single-branch", f"file://{r}", str(shallow))
        sh(shallow, "git", "checkout", "-q", "work")
        verdict("얕은 클론", run(shallow), 1, ["B2"])

        # B1 로컬 — origin/main 이 낡고 main 이 앞섰다
        r = repo(tmp / f"r{next(n)}", base_files(doing=False))
        sh(r, "git", "checkout", "-q", "main")
        commit(r, {"docs/master-plan.md": MASTER.format(extra=DOING), "docs/slices/2-two/requirements.md": "요구\n",
                   "docs/slices/2-two/design.md": "설계\n", "scripts/b.py": "b\n"}, "그 사이 머지된 착공과 구현")
        sh(r, "git", "checkout", "-q", "-b", "work2")
        commit(r, {"scripts/a.py": "print(2)\n"})
        verdict("로컬 — origin/main 이 낡고 main 이 앞섰다", run(r), 0, absent=["G1", "G2"])

        # B1 이벤트
        r = repo(tmp / f"r{next(n)}", base_files(doing=False))
        sh(r, "git", "checkout", "-q", "main")
        merged = commit(r, FOUND, "착공 머지")
        sh(r, "git", "update-ref", "refs/remotes/origin/main", merged)
        sh(r, "git", "checkout", "-q", "-b", "impl")
        head = commit(r, {"scripts/a.py": "print(2)\n"})
        ev = tmp / "event.json"

        def event(base_sha, ref, head_sha, default="main"):
            ev.write_text(json.dumps({"pull_request": {"base": {"sha": base_sha, "ref": ref},
                                                       "head": {"sha": head_sha}},
                                      "repository": {"default_branch": default}}), encoding="utf-8")
            return ev

        # 작업트리에 떨어지는 것을 두어, 이벤트가 아니라 작업트리를 보면 떨어지게 한다.
        sh(r, "git", "checkout", "-q", "main")
        put(r, {"scripts/stray.py": "x\n", "docs/slices/9-stray/design.md": "설계\n"})
        got = run(r, event=event(merged, "main", head))
        verdict("이벤트 — 기준 가지가 기본 가지", got, 0, absent=["G1", "G2", "B2"])
        expect("이벤트 — 출처를 「이벤트」로 찍지 않았다", "· 이벤트" in got[1], got[1])

        # 쌓은 PR — 머지되지 않은 착공 가지 위의 구현
        r = repo(tmp / f"r{next(n)}", base_files(doing=False))
        start = commit(r, FOUND, "착공 — 머지 안 됨")
        sh(r, "git", "checkout", "-q", "-b", "stacked")
        head = commit(r, {"scripts/a.py": "print(2)\n"})
        verdict("이벤트 — 착공 가지 위에 쌓은 구현 PR", run(r, event=event(start, "work", head)), 1, ["G1"])

        for what, text in [("깨진 이벤트 JSON", "{"),
                           ("이벤트에 base.sha 가 없다", json.dumps({"pull_request": {"base": {"ref": "main"},
                                                                                "head": {"sha": head}},
                                                                 "repository": {"default_branch": "main"}}))]:
            ev.write_text(text, encoding="utf-8")
            verdict(what, run(r, event=ev), 1, ["B2"])

        # B3 작업트리
        r = repo(tmp / f"r{next(n)}", base_files(doing=False))
        put(r, {"scripts/a.py": "print(2)\n"})
        verdict("작업트리 — 커밋 안 된 구현 파일", run(r), 1, ["G2"])
        r = repo(tmp / f"r{next(n)}", base_files(doing=False))
        put(r, {"scripts/new.py": "x\n"})
        verdict("작업트리 — 무시되지 않은 새 파일", run(r), 1, ["G2"])
        r = repo(tmp / f"r{next(n)}", base_files(doing=False))
        (r / "docs/adr").mkdir()
        sh(r, "git", "mv", "scripts/a.py", "docs/adr/0099-x.md")
        sh(r, "git", "commit", "-q", "-m", "이름 바꿈")
        got = run(r)
        verdict("이름 바꿈 scripts/a.py → docs/adr/0099-x.md", got, 1, ["G2"])
        expect("이름 바꿈 — 옛 경로를 찍지 않았다", "scripts/a.py" in got[1], got[1])

        # E1 · E2 UTF-8 이 아닌 로케일 · cp949 콘솔 — 한글 마스터플랜을 git 으로 읽고, 판정 줄을 예외 없이 찍는다.
        r = repo(tmp / f"r{next(n)}", base_files())
        commit(r, {"scripts/x.py": "x\n"})
        got = run(r, extra=NON_UTF8)
        verdict("UTF-8 이 아닌 로케일 — 기준에 설계가 있는 구현", got, 0)
        expect("UTF-8 이 아닌 로케일 — 구현이 예외로 끝났다", "Traceback" not in got[1], got[1])
        r = repo(tmp / f"r{next(n)}", base_files(doing=False))
        commit(r, {"scripts/x.py": "x\n"})
        got = run(r, extra=NON_UTF8)
        verdict("UTF-8 이 아닌 로케일 — 기준에 진행 조각이 없는 구현", got, 1, ["G2"])
        expect("UTF-8 이 아닌 로케일 — G2 가 예외로 끝났다", "Traceback" not in got[1], got[1])

        # 잘못 부름
        for what, args in [("--base 만", ["--base", "main"]), ("모르는 인자", ["--bse", "main"]),
                           ("--head 값 없음", ["--base", "main", "--head"])]:
            verdict(what, run(r, *args), 2)

    if bad:
        print(f"FAIL verify-slice-gate.py — {len(bad)}")
        for b in bad:
            print(f"  {b}")
        return 1
    print("PASS verify-slice-gate.py — 착공 · 구현 · 닫는 PR · 기준과 머리 · 작업트리 · 로케일 · 잘못 부름")
    return 0


if __name__ == "__main__":
    sys.exit(main())
