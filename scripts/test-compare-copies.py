#!/usr/bin/env python3
"""`compare-copies.py` 가 **무는지** 본다. 모델도 API 도 네트워크도 안 쓴다.

  python3 scripts/test-compare-copies.py                 # 저장소의 비교기
  python3 scripts/test-compare-copies.py <비교기 경로>     # 다른 판 — CI 가 변조본으로 쓴다

임시 원본 저장소 · 맨(bare) 원격 · 그것을 받은 사본 레포를 만들고, PRD 조각 1 의
성공 기준을 그대로 재현한다.

  1. 출처 주석 줄과 공백만 다른 사본에서는 후보가 안 나온다
  2. 고친 자리는 후보로 나오고, 감사자 둘에 같은 문구는 후보 하나로 묶인다
  3. 판정한 후보는 위에 문단이 생겨 줄이 옮겨져도 다시 안 나온다
  4. 사본이 원격보다 뒤 · 사본 자리가 더러움 · 추적 안 된 파일 · 없는 커밋 ·
     성하지 않은 후보 대장에서는 멈춘다(종료코드 1)

비교기를 고치고 이것이 안 돌면, 멈춰야 할 것이 견주고 지나가도 아무도 모른다.

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
FRONT = "---\nname: {n}\ndescription: x\ntools: [\"Read\", \"Grep\", \"Glob\"]\n---\n"
BODY = "".join(f"원본 문장 {i} 입니다.\n" for i in range(20))


def sh(cwd, *args):
    p = subprocess.run(args, cwd=cwd, capture_output=True, text=True, env=ENV)
    if p.returncode != 0:
        sys.exit(f"준비 실패: {' '.join(map(str, args))}\n{p.stderr}")
    return p.stdout.strip()


def commit(repo, msg):
    sh(repo, "git", "add", "-A")
    sh(repo, "git", "commit", "-q", "-m", msg)


def edit(path, fn):
    path.write_text(fn(path.read_text(encoding="utf-8")), encoding="utf-8")


def main():
    script = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / "scripts" / "compare-copies.py"
    fails, passes = [], 0

    with tempfile.TemporaryDirectory() as t:
        t = pathlib.Path(t)
        # 원본 — 비교기가 자기 저장소를 원본으로 보므로 스크립트를 그 안에 둔다
        orig = t / "orig"
        (orig / "scripts").mkdir(parents=True)
        (orig / "vibe-audit" / "agents").mkdir(parents=True)
        shutil.copy(script, orig / "scripts" / "compare-copies.py")
        shutil.copy(ROOT / "scripts" / "verify-feedback.py", orig / "scripts" / "verify-feedback.py")
        for n in ("audit-a", "audit-b"):
            (orig / "vibe-audit" / "agents" / f"{n}.md").write_text(FRONT.format(n=n) + BODY, encoding="utf-8")
        sh(orig, "git", "init", "-q", "-b", "main")
        commit(orig, "원본")
        base = sh(orig, "git", "rev-parse", "HEAD")

        # 원격과 사본 — sync-agents.sh 처럼 프론트매터 뒤에 출처 주석 줄과 빈 줄을 넣는다
        remote = t / "remote.git"
        sh(t, "git", "init", "-q", "--bare", "-b", "main", str(remote))
        copy = t / "copy"
        sh(t, "git", "clone", "-q", str(remote), str(copy))
        agents = copy / ".claude" / "agents"
        agents.mkdir(parents=True)
        hdr = f"<!-- pdw96/claude-kit@{base[:7]} 에서 옴. 이 레포에 맞게 고쳐도 된다 — 원본으로 되먹이지 않는다. -->\n\n"
        for n in ("audit-a", "audit-b"):
            (agents / f"{n}.md").write_text(FRONT.format(n=n) + hdr + BODY, encoding="utf-8")
        # 공백만 다른 자리 둘 — 빈 줄 하나, 줄 끝 공백
        edit(agents / "audit-a.md", lambda s: s.replace("원본 문장 5 입니다.\n", "원본 문장 5 입니다.\n\n"))
        edit(agents / "audit-b.md", lambda s: s.replace("원본 문장 7 입니다.", "원본 문장  7 입니다.   "))
        sh(copy, "git", "checkout", "-q", "-b", "main")
        commit(copy, "심음")
        sh(copy, "git", "push", "-q", "-u", "origin", "main")

        reg = t / "copies.json"
        reg.write_text(json.dumps({"copies": [{"repo": "x", "agents_path": str(agents),
                                               "synced_commit": base, "synced_at": "2026-01-01"}]}))
        ledger = t / "feedback.json"
        ledger.write_text('{"candidates": []}\n')

        def compare(*extra, reg_path=reg):
            p = subprocess.run([sys.executable, str(orig / "scripts" / "compare-copies.py"),
                                "--registry", str(reg_path), "--ledger", str(ledger), "--json", *extra],
                               capture_output=True, text=True, env=ENV)
            data = json.loads(p.stdout) if p.returncode == 0 and p.stdout.strip().startswith("{") else None
            return p.returncode, data, p.stdout + p.stderr

        def expect(name, ok, detail=""):
            nonlocal passes
            if ok:
                passes += 1
            else:
                fails.append(f"{name}{' — ' + detail if detail else ''}")

        # 1. 출처 주석 · 공백만 다르면 후보 0
        rc, d, out = compare()
        expect("출처 주석 · 공백만 다른 사본에서 후보가 나왔다",
               rc == 0 and d is not None and d["candidates"] == [], out[-400:])

        # 2. 고친 자리는 후보, 같은 문구는 둘에 걸쳐 하나
        same = "이 레포가 따로 둔 대장은 docs/audit/ 입니다.\n"
        edit(agents / "audit-a.md", lambda s: s.replace("원본 문장 12 입니다.\n", "원본 문장 12 입니다.\n" + same))
        edit(agents / "audit-b.md", lambda s: s.replace("원본 문장 12 입니다.\n", "원본 문장 12 입니다.\n" + same))
        edit(agents / "audit-b.md", lambda s: s.replace("원본 문장 3 입니다.\n", ""))  # 지운 자리도 후보다
        commit(copy, "고침")
        sh(copy, "git", "push", "-q")
        rc, d, out = compare()
        cands = d["candidates"] if d else []
        shared = [c for c in cands if any(same.strip() in ln for ln in c["copy"])]
        expect("고친 자리 둘(같은 문구 · 지운 줄)이 후보 둘로 안 나왔다", rc == 0 and len(cands) == 2, out[-400:])
        expect("감사자 둘에 같은 문구가 후보 하나로 안 묶였다",
               len(shared) == 1 and sorted(shared[0]["seen"][0]["files"]) == ["audit-a.md", "audit-b.md"], out[-400:])
        expect("지운 줄이 후보로 안 나왔다",
               any(c["copy"] == [] and "원본 문장 3 입니다." in c["orig"] for c in cands), out[-400:])

        # 3. 판정한 후보는 줄이 옮겨져도 다시 안 나온다
        if shared:
            s0 = shared[0]["seen"][0]
            ledger.write_text(json.dumps({"candidates": [{
                "id": "FB-1", "hash": shared[0]["hash"],
                "seen": [{"repo": "x", "files": s0["files"], "commit": s0["commit"], "base": base}],
                "status": "specific", "reason": "이 레포의 대장 경로", "decided_at": "2026-01-01"}]},
                ensure_ascii=False))
        # 판정 대장은 원본 저장소의 커밋으로 base 를 확인하므로 원본 쪽에서 돌린다 — 위에서 그렇게 했다
        edit(agents / "audit-a.md", lambda s: s.replace("원본 문장 0 입니다.\n", "새 문단 첫 줄.\n새 문단 둘째 줄.\n원본 문장 0 입니다.\n"))
        commit(copy, "위에 문단")
        sh(copy, "git", "push", "-q")
        rc, d, out = compare()
        hashes = [c["hash"] for c in (d["candidates"] if d else [])]
        expect("판정한 후보가 줄이 옮겨진 뒤 다시 나왔다",
               rc == 0 and shared and shared[0]["hash"] not in hashes, out[-400:])
        expect("새 문단이 미판정 후보로 안 나왔다",
               rc == 0 and any("새 문단 첫 줄." in ln for c in d["candidates"] for ln in c["copy"]), out[-400:])
        rc, d, out = compare("--all")
        expect("--all 이 판정한 후보를 안 찍었다",
               rc == 0 and any((c.get("judged") or {}).get("id") == "FB-1" for c in d["candidates"]), out[-400:])

        # 4. 멈출 자리들
        # 원격보다 뒤 — 다른 클론에서 하나 올린다
        other = t / "other"
        sh(t, "git", "clone", "-q", str(remote), str(other))
        (other / "README.md").write_text("x\n")
        commit(other, "앞선 커밋")
        sh(other, "git", "push", "-q")
        rc, _, out = compare()
        expect("원격보다 뒤인 사본에서 안 멈췄다", rc == 1 and "뒤" in out, out[-400:])
        sh(copy, "git", "pull", "-q", "--ff-only")
        rc, _, out = compare()
        expect("받은 뒤에도 멈췄다", rc == 0, out[-400:])

        # 사본 자리에 커밋 안 된 변경
        keep = (agents / "audit-a.md").read_text(encoding="utf-8")
        edit(agents / "audit-a.md", lambda s: s + "고치던 중\n")
        rc, _, out = compare()
        expect("커밋 안 된 변경이 있는 사본에서 안 멈췄다", rc == 1, out[-400:])
        (agents / "audit-a.md").write_text(keep, encoding="utf-8")

        # 추적 안 된 파일
        (agents / "audit-new.md").write_text("x\n")
        rc, _, out = compare()
        expect("추적 안 된 파일이 있는 사본에서 안 멈췄다", rc == 1, out[-400:])
        (agents / "audit-new.md").unlink()

        # 원격이 없다 — 최신인지 모르면 멈춘다
        sh(copy, "git", "remote", "rename", "origin", "away")
        rc, _, out = compare()
        expect("원격 origin 이 없는 사본에서 안 멈췄다", rc == 1, out[-400:])
        sh(copy, "git", "remote", "rename", "away", "origin")

        # 무시된 파일 — 디스크에는 있는데 HEAD 에 없다(Codex 리뷰)
        sh(copy, "git", "rm", "-q", "--cached", ".claude/agents/audit-b.md")
        (copy / ".gitignore").write_text(".claude/agents/audit-b.md\n")
        commit(copy, "감사자 하나를 무시")
        sh(copy, "git", "push", "-q")
        rc, _, out = compare()
        expect("무시돼 HEAD 에 없는 감사자 파일이 있는데 안 멈췄다", rc == 1 and "HEAD 에 없다" in out, out[-400:])
        (copy / ".gitignore").unlink()
        sh(copy, "git", "add", "-A")
        commit(copy, "되돌림")
        sh(copy, "git", "push", "-q")
        rc, _, out = compare()
        expect("무시를 푼 뒤에도 멈췄다", rc == 0, out[-400:])

        # 원본에 없는 커밋
        bad = t / "bad.json"
        bad.write_text(json.dumps({"copies": [{"repo": "x", "agents_path": str(agents),
                                               "synced_commit": "0" * 40, "synced_at": "2026-01-01"}]}))
        rc, _, out = compare(reg_path=bad)
        expect("원본에 없는 커밋을 적은 대장에서 안 멈췄다", rc == 1, out[-400:])

        # 성하지 않은 후보 대장 — 해시가 겹친다
        good = ledger.read_text(encoding="utf-8")
        j = json.loads(good)
        if j["candidates"]:
            j["candidates"].append({**j["candidates"][0], "id": "FB-2"})
        ledger.write_text(json.dumps(j, ensure_ascii=False))
        rc, _, out = compare()
        expect("해시가 겹친 후보 대장에서 안 멈췄다", rc == 1, out[-400:])
        ledger.write_text(good)

        rc, _, out = compare()
        expect("되돌린 뒤에도 멈췄다", rc == 0, out[-400:])

    # 뜻이 바뀐 줄 옆에 공백만 바뀐 줄이 붙어도 같은 후보다(Codex 리뷰) — 함수로 직접 본다
    import importlib.util
    spec = importlib.util.spec_from_file_location("cc", script)
    cc = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(cc)
    one = {cc.content_hash(o, c) for _, o, c in cc.hunks("A\nB\n", "A\nC\n")}
    two = {cc.content_hash(o, c) for _, o, c in cc.hunks("A\nB\n", "A  \nC\n")}
    if one == two and len(one) == 1:
        passes += 1
    else:
        fails.append(f"이웃 줄의 공백만 다른 두 고침이 다른 후보가 됐다 — {one} / {two}")

    if fails:
        for f in fails:
            print(f"FAIL {f}")
        return 1
    print(f"PASS compare-copies.py — 기대 {passes} 개 모두 맞다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
