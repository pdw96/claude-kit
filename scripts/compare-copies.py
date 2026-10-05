#!/usr/bin/env python3
"""대장의 사본을 심을 때의 원본과 견줘, 아직 판정 안 한 차이를 후보로 찍는다.

  python3 scripts/compare-copies.py                 # 대장의 사본 전부
  python3 scripts/compare-copies.py --repo erp      # 하나만
  python3 scripts/compare-copies.py --all           # 판정한 후보도 찍는다
  python3 scripts/compare-copies.py --json          # 기계가 읽을 모양으로

**왜 있나.** 되먹임은 전부 써 보다가 우연히 나왔고, 사본이 원본과 어디서 갈렸는지는
사람이 diff 를 손으로 읽어야 알았다(PRD 조각 1). 판정한 결과도 남는 자리가 없어,
특화로 기각한 차이가 다음에 다시 올라왔다. 이 스크립트는 차이를 뽑아 **내용 해시**로
묶고, 후보 대장(`feedback.json`)에 이미 있는 해시는 빼고 찍는다. 판정은 하지 않는다 —
특화인지 결함인지는 저자가 정한다(PRD 「하지 않을 일」 2).

**무엇과 견주나.** 원본은 대장의 `synced_commit` 의 `vibe-audit/agents/*.md`, 사본은
그 레포 `HEAD` 에 커밋된 파일이다. 원본의 HEAD 와 견주면 원본이 그 뒤 움직인 것이
사본의 차이로 보인다. `sync-agents.sh` 가 넣는 출처 주석 줄과 공백만 다른 덩어리는 거른다.

**견주기 전에 멈춘다**(ADR 0003) — 하나라도 걸리면 아무것도 견주지 않고 1 로 끝난다.
  - 사본 자리가 없다 · git 저장소가 아니다
  - 대장의 synced_commit 이 이 저장소에 없다
  - 사본 레포가 원격(origin)의 기본 가지보다 뒤다 — 받아(fetch) 본다. 못 받으면 멈춘다
  - 사본 자리에 커밋 안 된 변경이나 추적 안 된 파일이 있다
  - 후보 대장이 성하지 않다(`verify-feedback.py`)
낡은 사본으로 판정하면 그 판정이 대장에 남아 다음 비교를 거르므로, 한 번 틀리면 오래 간다.

내용 해시는 덩어리의 원본 쪽 줄과 사본 쪽 줄을 정규화(앞뒤 공백 제거 · 연속 공백 하나로 ·
빈 줄 제거)해 `-` · `+` 를 붙이고 줄바꿈으로 이은 것의 sha256 이다(`docs/schema.md`).
줄 번호는 넣지 않으므로 위에 문단이 생겨도 같은 후보다.

종료코드: 0 견줬다(미판정 후보가 있어도) · 1 멈췄다 · 2 사용법.

표준 라이브러리만 쓴다.
"""
import argparse
import difflib
import hashlib
import importlib.util
import json
import os
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PROVENANCE = re.compile(r"^<!-- pdw96/claude-kit@[0-9a-f]{7,40} 에서 옴\.")
SHOW = 6  # 후보마다 한쪽에서 보여 줄 줄 수


def run(*args, cwd=None):
    env = {**os.environ, "GIT_TERMINAL_PROMPT": "0", "LC_ALL": "C"}
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, env=env)


def git(*args):
    return run("git", "-C", str(ROOT), *args)


def norm(lines):
    out = (" ".join(ln.split()) for ln in lines)
    return [ln for ln in out if ln]


def content_hash(orig, copy):
    body = "\n".join(["-" + ln for ln in norm(orig)] + ["+" + ln for ln in norm(copy)])
    return "sha256:" + hashlib.sha256(body.encode("utf-8")).hexdigest()


def strip_provenance(lines):
    """(파일의 줄 번호, 줄) 목록에서 출처 주석 줄과 그 뒤 빈 줄 하나를 뺀다."""
    numbered = list(enumerate(lines, 1))
    for k, (_, ln) in enumerate(numbered):
        if PROVENANCE.match(ln):
            drop = 2 if k + 1 < len(numbered) and not numbered[k + 1][1].strip() else 1
            return numbered[:k] + numbered[k + drop:]
    return numbered


def hunks(orig_text, copy_text):
    """(사본 줄 번호, 원본 쪽 줄, 사본 쪽 줄) — 공백만 다른 자리는 덩어리를 만들지 않는다.

    **정규화한 줄로 견준다.** 날 줄로 견주고 나서 정규화하면, 뜻이 바뀐 줄 옆에 공백만
    바뀐 줄이 붙어 있을 때 둘이 한 덩어리로 묶여 해시가 달라진다 — 같은 고침이 사본마다
    다른 후보가 되고, 판정한 후보가 이웃 공백 하나로 다시 올라온다(Codex 리뷰). 빈 줄은
    견줄 목록에서 빼고, 보여 줄 때만 날 줄과 줄 번호를 쓴다."""
    def keyed(numbered):
        rows = [(n, ln, " ".join(ln.split())) for n, ln in numbered]
        return [r for r in rows if r[2]]
    a = keyed(enumerate(orig_text.splitlines(), 1))
    b = keyed(strip_provenance(copy_text.splitlines()))
    sm = difflib.SequenceMatcher(None, [r[2] for r in a], [r[2] for r in b], autojunk=False)
    for op, i1, i2, j1, j2 in sm.get_opcodes():
        if op == "equal":
            continue
        at = b[j1][0] if j1 < len(b) else (b[-1][0] + 1 if b else 1)
        yield at, [r[1] for r in a[i1:i2]], [r[1] for r in b[j1:j2]]


def preflight(c):
    """멈출 까닭 목록과, 견줄 준비(사본 레포 루트 · 사본 자리 상대 경로 · 사본 HEAD)."""
    who = c.get("repo") or "?"
    path = pathlib.Path(str(c.get("agents_path", ""))).expanduser()
    sha = str(c.get("synced_commit", ""))
    if not path.is_dir():
        return [f"{who}: 사본 자리 {path} 가 이 기계에 없다"], None
    top = run("git", "-C", str(path), "rev-parse", "--show-toplevel")
    if top.returncode != 0:
        return [f"{who}: {path} 가 git 저장소 안이 아니다"], None
    root = pathlib.Path(top.stdout.strip())
    rel = path.resolve().relative_to(root.resolve()).as_posix()
    stop = []
    if git("cat-file", "-e", f"{sha}^{{commit}}").returncode != 0:
        stop.append(f"{who}: 심었다는 커밋 {sha or '(빔)'} 가 이 저장소에 없다")

    rg = lambda *a: run("git", "-C", str(root), *a)
    sym = rg("ls-remote", "--symref", "origin", "HEAD")
    m = re.search(r"^ref: refs/heads/(\S+)\tHEAD$", sym.stdout, re.M)
    if sym.returncode != 0 or not m:
        said = (sym.stderr.strip().splitlines() or ["말 없음"])[-1]
        stop.append(f"{who}: 원격 origin 의 기본 가지를 못 읽었다 — 사본이 최신인지 모른다 ({said})")
    else:
        branch = m.group(1)
        f = rg("fetch", "--quiet", "origin", f"refs/heads/{branch}")
        if f.returncode != 0:
            stop.append(f"{who}: origin/{branch} 를 못 받았다 — 사본이 최신인지 모른다")
        else:
            behind = rg("rev-list", "--count", "HEAD..FETCH_HEAD").stdout.strip()
            if behind != "0":
                stop.append(f"{who}: 사본 레포 HEAD 가 origin/{branch} 보다 {behind} 커밋 뒤다 — 받은 뒤 다시 돌려라")
    dirty = rg("status", "--porcelain", "--untracked-files=all", "--", rel).stdout.strip()
    if dirty:
        stop.append(f"{who}: 사본 자리에 커밋 안 된 것이 있다 — {len(dirty.splitlines())} 개")
    # **견줄 감사자 파일은 HEAD 에 추적돼 있어야 한다.** 사본 레포가 `.claude/` 를 무시하면
    # status 는 그 파일을 안 보여 주고, 아래 `git show HEAD:` 는 감사자를 다 지운 것으로 읽어
    # 거짓 「삭제」 후보를 낸다(Codex 리뷰). 디스크에 있는데 HEAD 에 없으면 멈춘다.
    if not stop:
        names = git("ls-tree", "--name-only", sha, "vibe-audit/agents/").stdout.split()
        loose = [pathlib.PurePosixPath(n).name for n in names
                 if (path / pathlib.PurePosixPath(n).name).exists()
                 and rg("cat-file", "-e", f"HEAD:{rel}/{pathlib.PurePosixPath(n).name}" if rel != "." else
                        f"HEAD:{pathlib.PurePosixPath(n).name}").returncode != 0]
        if loose:
            stop.append(f"{who}: 사본 자리의 감사자가 HEAD 에 없다(무시됐거나 추적 안 됨) — {', '.join(loose)}")
    if stop:
        return stop, None
    head = rg("rev-parse", "HEAD").stdout.strip()
    return [], (root, rel, head)


def load_ledger(path):
    spec = importlib.util.spec_from_file_location("verify_feedback", ROOT / "scripts" / "verify-feedback.py")
    vf = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(vf)
    p = subprocess.run([sys.executable, str(ROOT / "scripts" / "verify-feedback.py"), str(path)],
                       capture_output=True, text=True)
    if p.returncode != 0:
        return None, p.stdout.strip() or p.stderr.strip()
    if not path.is_file():
        return {}, None
    data = json.loads(path.read_text(encoding="utf-8"))
    return {c["hash"]: (c["id"], vf.STATUS[c["status"]]) for c in data["candidates"]}, None


def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--repo")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--registry", type=pathlib.Path, default=ROOT / "copies.json")
    ap.add_argument("--ledger", type=pathlib.Path, default=ROOT / "feedback.json")
    a = ap.parse_args()

    try:
        copies = json.loads(a.registry.read_text(encoding="utf-8"))["copies"]
    except (OSError, ValueError, KeyError, TypeError) as e:
        print(f"STOP 대장 {a.registry} 를 못 읽었다 — {e}")
        return 1
    if a.repo:
        copies = [c for c in copies if c.get("repo") == a.repo]
        if not copies:
            print(f"STOP 대장에 {a.repo!r} 가 없다")
            return 1

    known, why = load_ledger(a.ledger)
    stops = [] if why is None else [f"후보 대장이 성하지 않다 — {why.splitlines()[0]}"]
    ready = []
    for c in copies:
        s, r = preflight(c)
        stops += s
        if r:
            ready.append((c, *r))
    if stops:
        for s in stops:
            print(f"STOP {s}")
        print("아무것도 견주지 않았다.")
        return 1

    cands, heads = {}, []
    for c, root, rel, head in ready:
        sha = c["synced_commit"]
        heads.append((c["repo"], sha, head))
        names = git("ls-tree", "--name-only", sha, "vibe-audit/agents/").stdout.split()
        for n in sorted(x for x in names if x.endswith(".md")):
            name = pathlib.PurePosixPath(n).name
            orig = git("show", f"{sha}:{n}").stdout
            cp = run("git", "-C", str(root), "show", f"HEAD:{rel}/{name}" if rel != "." else f"HEAD:{name}")
            copy = cp.stdout if cp.returncode == 0 else ""
            for at, o, cl in hunks(orig, copy):
                h = content_hash(o, cl)
                e = cands.setdefault(h, {"hash": h, "orig": o, "copy": cl, "where": [], "seen": {}})
                e["where"].append(f"{c['repo']} · {name}:{at}" + ("" if cp.returncode == 0 else " (사본에 없는 파일)"))
                sn = e["seen"].setdefault(c["repo"], {"repo": c["repo"], "files": [], "commit": head, "base": sha})
                if name not in sn["files"]:
                    sn["files"].append(name)

    rows = []
    for h, e in cands.items():
        judged = known.get(h)
        if judged and not a.all:
            continue
        rows.append({**e, "seen": list(e["seen"].values()),
                     "judged": None if not judged else {"id": judged[0], "status": judged[1]}})

    if a.json:
        print(json.dumps({"compared": [{"repo": r, "base": b, "commit": h} for r, b, h in heads],
                          "candidates": rows}, ensure_ascii=False, indent=2))
        return 0

    for r, b, h in heads:
        print(f"     {r}: 원본 {b[:7]} ↔ 사본 {h[:7]} (원격 기본 가지와 같거나 앞섬)")
    for e in rows:
        tag = f"{e['judged']['id']} {e['judged']['status']}" if e["judged"] else "미판정"
        print(f"\n{tag}  {e['hash']}")
        for w in e["where"]:
            print(f"  자리 {w}")
        for sign, side in (("-", e["orig"]), ("+", e["copy"])):
            body = [ln for ln in side if ln.strip()]
            for ln in body[:SHOW]:
                print(f"  {sign} {ln[:160]}{'…' if len(ln) > 160 else ''}")
            if len(body) > SHOW:
                print(f"  {sign} … {len(body) - SHOW} 줄 더")
    unjudged = sum(1 for h in cands if h not in known)
    print(f"\n후보 {len(cands)} — 미판정 {unjudged} · 판정됨 {len(cands) - unjudged}")
    if unjudged:
        print("판정은 feedback.json 에 적는다(docs/schema.md). 미판정은 대장에 안 적는다.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
