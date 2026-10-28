#!/usr/bin/env python3
"""`compare-copies.py` 가 **무는지** 본다. 모델도 API 도 네트워크도 안 쓴다.

  python3 scripts/test-compare-copies.py                 # 저장소의 비교기
  python3 scripts/test-compare-copies.py <비교기 경로>     # 다른 판 — bite-gates.sh 가 변조본으로 쓴다

임시 원본 저장소 · 맨(bare) 원격 · 그것을 받은 사본 레포를 만들고, PRD 조각 1 의
성공 기준을 그대로 재현한다.

  1. 출처 주석 줄(옛 꼴 · 지금 꼴)과 공백만 다른 사본에서는 후보가 안 나온다
  2. 고친 자리는 후보로 나오고, 감사자 둘에 같은 문구는 후보 하나로 묶인다
  3. 판정한 후보는 위에 문단이 생겨 줄이 옮겨져도 다시 안 나온다
  4. 사본이 원격보다 뒤 · 사본 자리가 더러움 · 추적 안 된 파일 · 없는 커밋 ·
     성하지 않은 후보 대장에서는 멈춘다(종료코드 1)
  5. 같은 고침을 담은 사본 둘(`a` · `b`)에서, 판정한 후보의 `seen` 이 `a` 뿐이면 기본 실행에
     「새 레포 b」로 나오고, `a` · `b` 면 지금처럼 숨는다(조각 13 설계 ② T1)
  6. 커맨드(`vibe-audit/commands/c.md`) · 검사기(`vibe-audit/scripts/v.py`)도 견준다(조각 15 설계 ② T1) —
     (가) 출처 줄만 다른 커맨드 · 바이트 그대로인 검사기에서 후보 0 · (나) 둘의 고친 줄이 후보 둘이고 자리 줄이
     `c.md` · `v.py` 다 · (다) 사본 `commands/` 의 커밋 안 된 변경, `scripts/` 의 추적 안 된 파일에서 멈춘다 ·
     (라) 무시돼 HEAD 에 없는 사본 커맨드에서 멈춘다

비교기를 고치고 이것이 안 돌면, 멈춰야 할 것이 견주고 지나가도 아무도 모른다.

**세 규칙**(조각 41 설계 ② C · N · K · ADR 0054) — 멈춰야 하는 실행이 변조본, 견줘야 하는 실행이 대조군이다.
- (가) 비교기를 돈 수를 `WANT` 와 견준다 — 꼴을 지웠거나 조건(`if both:`) 때문에 건너뛰면 떨어진다.
- (나) 멈춤은 종료 1 · 「STOP 」 줄 · 「아무것도 견주지 않았다.」 줄 · 트레이스백 없음일 때만 센다(`stopped`). 까닭의 글을 아는
  꼴은 그 글이 STOP 줄에 있어야 한다. 비교기는 규칙 ID 를 찍지 않는다.
- (다) 견줌은 종료 0 과 그 길의 끝 — `--json` 은 `compared` 를 든 JSON, 글 출력은 「후보 N — 미판정 」 줄 — 을 함께 본다(`compared`).

표준 라이브러리만 쓴다.
"""
import json
import os
import re
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
WANT = (10, 15)  # (가) 멈춤 · 견줌
TB = "Traceback (most recent call last)"


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
        # 출처 줄은 두 꼴이다 — 옛 사본의 줄(audit-a)과 지금 sync-agents.sh 가 박는 줄(audit-b). 어느 쪽이
        # 후보로 새어도 1 에서 떨어진다(조각 8 설계 ② H4).
        hdrs = {
            "audit-a": f"<!-- pdw96/claude-kit@{base[:7]} 에서 옴. 이 레포에 맞게 고쳐도 된다 — 원본으로 되먹이지 않는다. -->\n\n",
            "audit-b": f"<!-- pdw96/claude-kit@{base[:7]} 에서 옴. 이 레포에서만 참인 고침은 이 사본에만 산다 — "
                       f"다른 레포에서도 같은 말이면 원본으로 넘긴다. -->\n\n",
        }
        for n in ("audit-a", "audit-b"):
            (agents / f"{n}.md").write_text(FRONT.format(n=n) + hdrs[n] + BODY, encoding="utf-8")
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

        def compare(*extra, reg_path=reg, ledger_path=ledger, text=False):
            p = subprocess.run([sys.executable, str(orig / "scripts" / "compare-copies.py"),
                                "--registry", str(reg_path), "--ledger", str(ledger_path),
                                *([] if text else ["--json"]), *extra],
                               capture_output=True, text=True, env=ENV)
            if text:
                return p.returncode, None, p.stdout + p.stderr
            data = json.loads(p.stdout) if p.returncode == 0 and p.stdout.strip().startswith("{") else None
            return p.returncode, data, p.stdout + p.stderr

        ran = [0, 0]

        def stopped(rc, out, why=""):
            """(나) 멈춤 — 종료 1 · 그 까닭을 든 STOP 줄 · 「아무것도 견주지 않았다.」 · 트레이스백 없음."""
            ran[0] += 1
            ls = out.splitlines()
            return (rc == 1 and any(ln.startswith("STOP ") and why in ln for ln in ls)
                    and "아무것도 견주지 않았다." in ls and TB not in out)

        def compared(rc, d, out, text=False):
            """(다) 견줌 — 종료 0 과 끝(JSON 의 compared · 글의 「후보 N — 미판정 」 줄) · 트레이스백 없음."""
            ran[1] += 1
            end = re.search(r"^후보 [0-9]+ — 미판정 ", out, re.M) if text else (d is not None and "compared" in d)
            return rc == 0 and bool(end) and TB not in out

        def expect(name, ok, detail=""):
            nonlocal passes
            if ok:
                passes += 1
            else:
                fails.append(f"{name}{' — ' + detail if detail else ''}")

        # 1. 출처 주석 · 공백만 다르면 후보 0
        rc, d, out = compare()
        expect("출처 주석 · 공백만 다른 사본에서 후보가 나왔다",
               compared(rc, d, out) and d["candidates"] == [], out[-400:])

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
        expect("고친 자리 둘(같은 문구 · 지운 줄)이 후보 둘로 안 나왔다", compared(rc, d, out) and len(cands) == 2, out[-400:])
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
        k = compared(rc, d, out)
        expect("판정한 후보가 줄이 옮겨진 뒤 다시 나왔다",
               k and shared and shared[0]["hash"] not in hashes, out[-400:])
        expect("새 문단이 미판정 후보로 안 나왔다",
               k and any("새 문단 첫 줄." in ln for c in d["candidates"] for ln in c["copy"]), out[-400:])
        expect("미판정 후보의 judged 가 null 이 아니다",
               k and all(c["judged"] is None for c in d["candidates"]), out[-400:])
        rc, d, out = compare("--all")
        expect("--all 이 판정한 후보를 안 찍었다",
               compared(rc, d, out) and any((c.get("judged") or {}).get("id") == "FB-1" for c in d["candidates"]), out[-400:])

        # 4. 멈출 자리들
        # 원격보다 뒤 — 다른 클론에서 하나 올린다
        other = t / "other"
        sh(t, "git", "clone", "-q", str(remote), str(other))
        (other / "README.md").write_text("x\n")
        commit(other, "앞선 커밋")
        sh(other, "git", "push", "-q")
        rc, _, out = compare()
        expect("원격보다 뒤인 사본에서 안 멈췄다", stopped(rc, out, "뒤"), out[-400:])
        sh(copy, "git", "pull", "-q", "--ff-only")
        rc, d, out = compare()
        expect("받은 뒤에도 멈췄다", compared(rc, d, out), out[-400:])

        # 사본 자리에 커밋 안 된 변경
        keep = (agents / "audit-a.md").read_text(encoding="utf-8")
        edit(agents / "audit-a.md", lambda s: s + "고치던 중\n")
        rc, _, out = compare()
        expect("커밋 안 된 변경이 있는 사본에서 안 멈췄다", stopped(rc, out), out[-400:])
        (agents / "audit-a.md").write_text(keep, encoding="utf-8")

        # 추적 안 된 파일
        (agents / "audit-new.md").write_text("x\n")
        rc, _, out = compare()
        expect("추적 안 된 파일이 있는 사본에서 안 멈췄다", stopped(rc, out), out[-400:])
        (agents / "audit-new.md").unlink()

        # 원격이 없다 — 최신인지 모르면 멈춘다
        sh(copy, "git", "remote", "rename", "origin", "away")
        rc, _, out = compare()
        expect("원격 origin 이 없는 사본에서 안 멈췄다", stopped(rc, out), out[-400:])
        sh(copy, "git", "remote", "rename", "away", "origin")

        # 무시된 파일 — 디스크에는 있는데 HEAD 에 없다(Codex 리뷰)
        sh(copy, "git", "rm", "-q", "--cached", ".claude/agents/audit-b.md")
        (copy / ".gitignore").write_text(".claude/agents/audit-b.md\n")
        commit(copy, "감사자 하나를 무시")
        sh(copy, "git", "push", "-q")
        rc, _, out = compare()
        expect("무시돼 HEAD 에 없는 감사자 파일이 있는데 안 멈췄다", stopped(rc, out, "HEAD 에 없다"), out[-400:])
        (copy / ".gitignore").unlink()
        sh(copy, "git", "add", "-A")
        commit(copy, "되돌림")
        sh(copy, "git", "push", "-q")
        rc, d, out = compare()
        expect("무시를 푼 뒤에도 멈췄다", compared(rc, d, out), out[-400:])

        # 원본에 없는 커밋
        bad = t / "bad.json"
        bad.write_text(json.dumps({"copies": [{"repo": "x", "agents_path": str(agents),
                                               "synced_commit": "0" * 40, "synced_at": "2026-01-01"}]}))
        rc, _, out = compare(reg_path=bad)
        expect("원본에 없는 커밋을 적은 대장에서 안 멈췄다", stopped(rc, out), out[-400:])

        # 성하지 않은 후보 대장 — 해시가 겹친다
        good = ledger.read_text(encoding="utf-8")
        j = json.loads(good)
        if j["candidates"]:
            j["candidates"].append({**j["candidates"][0], "id": "FB-2"})
        ledger.write_text(json.dumps(j, ensure_ascii=False))
        rc, _, out = compare()
        expect("해시가 겹친 후보 대장에서 안 멈췄다", stopped(rc, out), out[-400:])
        ledger.write_text(good)

        rc, d, out = compare()
        expect("되돌린 뒤에도 멈췄다", compared(rc, d, out), out[-400:])

        # 5. 새 레포 — 같은 고침을 담은 사본 둘. 레포마다 원격을 따로 둔다
        fix = "두 레포가 따로 쓴 같은 문장입니다.\n"
        two = {}
        for n in ("a", "b"):
            rm = t / f"remote-{n}.git"
            sh(t, "git", "init", "-q", "--bare", "-b", "main", str(rm))
            cl = t / f"copy-{n}"
            sh(t, "git", "clone", "-q", str(rm), str(cl))
            ag = cl / ".claude" / "agents"
            ag.mkdir(parents=True)
            for f in ("audit-a", "audit-b"):
                (ag / f"{f}.md").write_text(FRONT.format(n=f) + hdrs["audit-b"] + BODY, encoding="utf-8")
            edit(ag / "audit-a.md", lambda s: s.replace("원본 문장 9 입니다.\n", "원본 문장 9 입니다.\n" + fix))
            sh(cl, "git", "checkout", "-q", "-b", "main")
            commit(cl, "심고 고침")
            sh(cl, "git", "push", "-q", "-u", "origin", "main")
            two[n] = (ag, sh(cl, "git", "rev-parse", "HEAD"))
        reg2 = t / "copies-two.json"
        reg2.write_text(json.dumps({"copies": [{"repo": n, "agents_path": str(ag), "synced_commit": base,
                                                "synced_at": "2026-01-01"} for n, (ag, _) in two.items()]}))
        led2 = t / "feedback-two.json"
        led2.write_text('{"candidates": []}\n')
        rc, d, out = compare(reg_path=reg2, ledger_path=led2)
        both = d["candidates"] if d else []
        expect("같은 고침을 담은 사본 둘이 후보 하나로 안 묶였다",
               compared(rc, d, out) and len(both) == 1 and sorted(x["repo"] for x in both[0]["seen"]) == ["a", "b"], out[-400:])

        def judge(repos):
            led2.write_text(json.dumps({"candidates": [{
                "id": "FB-1", "hash": both[0]["hash"],
                "seen": [{"repo": n, "files": ["audit-a.md"], "commit": two[n][1], "base": base} for n in repos],
                "status": "specific", "reason": "a 에서 본 특화", "decided_at": "2026-01-01"}]},
                ensure_ascii=False))

        if both:
            # (가) seen 이 a 뿐 — 기본 실행에 「새 레포 b」로 나온다
            judge(["a"])
            rc, d, out = compare(reg_path=reg2, ledger_path=led2)
            got = [x for x in (d["candidates"] if d else []) if x["hash"] == both[0]["hash"]]
            expect("seen 밖의 레포에서 나온 판정된 후보가 기본 실행에 안 나왔다", compared(rc, d, out) and len(got) == 1, out[-400:])
            expect("새 레포에서 나온 후보의 judged.new_repos 가 [\"b\"] 가 아니다",
                   len(got) == 1 and (got[0]["judged"] or {}).get("new_repos") == ["b"], out[-400:])
            rc, _, out = compare(reg_path=reg2, ledger_path=led2, text=True)
            expect("새 레포 꼬리표가 안 찍혔다", compared(rc, None, out, text=True) and "FB-1 특화 · 새 레포 b  sha256:" in out, out[-400:])
            expect("끝 줄의 새 레포 셈이나 seen 안내가 없다",
                   "미판정 0 · 판정됨 1(새 레포 1)" in out and "seen 은 저자가 더한다" in out, out[-400:])

            # (나) seen 이 a · b — 기본 실행에 숨고, --all 에서 new_repos 가 빈 목록이다
            judge(["a", "b"])
            rc, d, out = compare(reg_path=reg2, ledger_path=led2)
            expect("seen 안의 레포에서만 나온 판정된 후보가 기본 실행에 나왔다",
                   compared(rc, d, out) and d["candidates"] == [], out[-400:])
            rc, d, out = compare("--all", reg_path=reg2, ledger_path=led2)
            got = [x for x in (d["candidates"] if d else []) if x["hash"] == both[0]["hash"]]
            expect("--all 에서 seen 안의 후보의 judged.new_repos 가 [] 가 아니다",
                   compared(rc, d, out) and len(got) == 1 and (got[0]["judged"] or {}).get("new_repos") == [], out[-400:])
            rc, _, out = compare("--all", reg_path=reg2, ledger_path=led2, text=True)
            expect("seen 안의 후보에 새 레포 꼬리표가 붙었다",
                   compared(rc, None, out, text=True) and "FB-1 특화  sha256:" in out and "새 레포 b" not in out
                   and "미판정 0 · 판정됨 1(새 레포 0)" in out and "seen 은 저자가 더한다" not in out, out[-400:])

        # 6. 커맨드 · 검사기 — 원본에 둘을 더한 커밋을 심은 사본을 따로 둔다. 1 ~ 5 의 사본은 그 앞 커밋을
        # 심어 커맨드 · 검사기가 없다. sync-agents.sh 처럼 커맨드는 머리말 뒤에 출처 줄, 검사기는 바이트 그대로다
        cmd = "---\nname: c\ndescription: x\n---\n\n" + "".join(f"커맨드 문장 {i} 입니다.\n" for i in range(12))
        chk = "".join(f"x{i} = {i}  # 검사기 줄\n" for i in range(12))
        (orig / "vibe-audit" / "commands").mkdir()
        (orig / "vibe-audit" / "scripts").mkdir()
        (orig / "vibe-audit" / "commands" / "c.md").write_text(cmd, encoding="utf-8")
        (orig / "vibe-audit" / "scripts" / "v.py").write_text(chk, encoding="utf-8")
        commit(orig, "커맨드 · 검사기")
        base6 = sh(orig, "git", "rev-parse", "HEAD")
        rm6 = t / "remote-6.git"
        sh(t, "git", "init", "-q", "--bare", "-b", "main", str(rm6))
        c6 = t / "copy-6"
        sh(t, "git", "clone", "-q", str(rm6), str(c6))
        ag6, cm6, sc6 = (c6 / ".claude" / d for d in ("agents", "commands", "scripts"))
        for d in (ag6, cm6, sc6):
            d.mkdir(parents=True)
        hdr6 = hdrs["audit-b"].replace(base[:7], base6[:7])
        for f in ("audit-a", "audit-b"):
            (ag6 / f"{f}.md").write_text(FRONT.format(n=f) + hdr6 + BODY, encoding="utf-8")
        (cm6 / "c.md").write_text(cmd.replace("---\n\n", "---\n\n" + hdr6, 1), encoding="utf-8")
        (sc6 / "v.py").write_text(chk, encoding="utf-8")
        sh(c6, "git", "checkout", "-q", "-b", "main")
        commit(c6, "심음")
        sh(c6, "git", "push", "-q", "-u", "origin", "main")
        reg6 = t / "copies-6.json"
        reg6.write_text(json.dumps({"copies": [{"repo": "y", "agents_path": str(ag6), "synced_commit": base6,
                                                "synced_at": "2026-01-01"}]}))
        led6 = t / "feedback-6.json"
        led6.write_text('{"candidates": []}\n')

        # (가) 출처 줄만 다른 커맨드 · 바이트 그대로인 검사기
        rc, d, out = compare(reg_path=reg6, ledger_path=led6)
        expect("출처 줄만 다른 커맨드 · 바이트 그대로인 검사기에서 후보가 나왔다",
               compared(rc, d, out) and d["candidates"] == [], out[-400:])

        # (나) 고친 줄 — 커맨드 하나 · 검사기 하나
        edit(cm6 / "c.md", lambda s: s.replace("커맨드 문장 6 입니다.", "이 레포는 커맨드를 고쳤습니다."))
        edit(sc6 / "v.py", lambda s: s.replace("x8 = 8", "x8 = 80"))
        commit(c6, "고침")
        sh(c6, "git", "push", "-q")
        rc, d, out = compare(reg_path=reg6, ledger_path=led6)
        got = d["candidates"] if d else []
        where = sorted(w for c in got for w in c["where"])
        expect("커맨드 · 검사기의 고친 줄이 후보 둘로 안 나왔다", compared(rc, d, out) and len(got) == 2, out[-400:])
        expect("커맨드 · 검사기 후보의 자리 줄이 c.md · v.py 가 아니다",
               len(where) == 2 and where[0].startswith("y · c.md:") and where[1].startswith("y · v.py:"), out[-400:])
        expect("커맨드 · 검사기 후보의 seen.files 가 이름 하나가 아니다",
               sorted(c["seen"][0]["files"][0] for c in got if len(c["seen"][0]["files"]) == 1) == ["c.md", "v.py"],
               out[-400:])

        # (다) commands/ 의 커밋 안 된 변경 · scripts/ 의 추적 안 된 파일
        keep6 = (cm6 / "c.md").read_text(encoding="utf-8")
        edit(cm6 / "c.md", lambda s: s + "고치던 중\n")
        rc, _, out = compare(reg_path=reg6, ledger_path=led6)
        expect("사본 commands/ 에 커밋 안 된 변경이 있는데 안 멈췄다", stopped(rc, out), out[-400:])
        (cm6 / "c.md").write_text(keep6, encoding="utf-8")
        (sc6 / "new.py").write_text("x\n")
        rc, _, out = compare(reg_path=reg6, ledger_path=led6)
        expect("사본 scripts/ 에 추적 안 된 파일이 있는데 안 멈췄다", stopped(rc, out), out[-400:])
        (sc6 / "new.py").unlink()

        # (라) 무시돼 HEAD 에 없는 사본 커맨드
        sh(c6, "git", "rm", "-q", "--cached", ".claude/commands/c.md")
        (c6 / ".gitignore").write_text(".claude/commands/c.md\n")
        commit(c6, "커맨드를 무시")
        sh(c6, "git", "push", "-q")
        rc, _, out = compare(reg_path=reg6, ledger_path=led6)
        expect("무시돼 HEAD 에 없는 사본 커맨드가 있는데 안 멈췄다", stopped(rc, out, "HEAD 에 없다"), out[-400:])

        expect(f"비교기가 멈춤 {ran[0]} · 견줌 {ran[1]} 으로 돌았다 — {WANT[0]} · {WANT[1]} 이어야 한다(꼴을 지웠거나 건너뛰었다)",
               tuple(ran) == WANT)

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
    print(f"PASS compare-copies.py — 멈춤 {WANT[0]} · 견줌 {WANT[1]} 이 돌았다 — 기대 {passes} 개 모두 맞다")
    return 0


if __name__ == "__main__":
    sys.exit(main())
