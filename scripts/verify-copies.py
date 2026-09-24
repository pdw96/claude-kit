#!/usr/bin/env python3
"""사본이 어디에 있는지 적어 둔 대장을 보고, 닿는 것은 원본과 견준다.

  python3 scripts/verify-copies.py

`verify-copy.py` 는 사본 하나를 원본과 글자 단위로 견준다. 그런데 **견줄
상대를 어디서 얻는지가 없었다.** 사본은 다른 레포에 살고, 심은 사람 말고는
어디에 심었는지 아무도 모른다. 대장이 없으면 그 검사는 아무도 안 돌리는
검사이고, 안 도는 검사는 게이트가 아니다.

`sync-agents.sh` 가 심을 때마다 여기에 한 줄을 적는다. 이 검사는 그 줄이
성한지 보고(빠진 자리 · 중복 · **이 저장소에 없는 커밋**), 그 경로가 이
기계에 있으면 `verify-copy.py` 까지 이어 돌린다. 없으면 **없어서 못 봤다고
찍는다** — 안 본 것을 본 것처럼 두지 않는다.

**갈린 것 자체는 실패가 아니다.** 사본은 그 레포에 맞게 갈리라고 둔 것이다
(루트 README). 몇 커밋만큼 멀어졌는지는 찍어 주되 판정하지 않는다.

표준 라이브러리만 쓴다.
"""
import importlib.util
import json
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
REGISTRY = ROOT / "copies.json"
NEEDED = ("repo", "agents_path", "synced_commit", "synced_at")
WATCHED = ("vibe-audit/agents", "vibe-audit/commands")


def git(*args):
    return subprocess.run(
        ["git", "-C", str(ROOT), *args],
        capture_output=True, text=True,
    )


_spec = importlib.util.spec_from_file_location("verify_copy", ROOT / "scripts" / "verify-copy.py")
CURRENT = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(CURRENT)


def against_commit(sha, copy):
    """sha 의 원본 감사자와 그 커밋의 verify-copy.py 로 사본을 견준다.
    (True/False, 첫 줄) · 그 커밋에 검사기나 원본이 없으면 (None, 까닭)."""
    names = git("ls-tree", "--name-only", sha, "vibe-audit/agents/").stdout.split()
    names = [n for n in names if pathlib.PurePosixPath(n).name.startswith("audit-")]
    checker = git("show", f"{sha}:scripts/verify-copy.py")
    if not names or checker.returncode != 0:
        return None, f"{sha[:7]} 에 원본 감사자나 검사기가 없어 못 봤다"
    with tempfile.TemporaryDirectory() as tmp:
        src = pathlib.Path(tmp) / "agents"
        src.mkdir()
        for n in names:
            (src / pathlib.PurePosixPath(n).name).write_text(
                git("show", f"{sha}:{n}").stdout, encoding="utf-8")
        chk = pathlib.Path(tmp) / "verify-copy.py"
        chk.write_text(checker.stdout, encoding="utf-8")
        p = subprocess.run([sys.executable, str(chk), str(src), str(copy)],
                           capture_output=True, text=True)
    lines = (p.stdout or p.stderr).strip().splitlines()
    return p.returncode == 0, (lines[0] if lines else "(말이 없다)")


def commands_missing(sha, agents_dir):
    """sha 의 원본 커맨드가 사본 쪽 commands/ 에 있고 머리말이 성한지 본다.

    `sync-agents.sh` 는 감사자와 함께 커맨드(`/audit-brief`)도 심는다. 감사자는
    git 을 못 돌려 diff 를 스스로 못 구하므로, 커맨드가 빠진 사본은 PR · 커밋
    범위 항목을 전부 확인불가로 남긴다. 그런데 이 검사가 감사자 폴더만 보고 있어,
    커맨드를 지운 사본도 PASS 였다(Codex 리뷰). 내용은 견주지 않는다 — 커맨드는
    공통 절이 없고, 그 레포에 맞게 갈리는 것은 허용이다. 있는지와 머리말만 본다."""
    names = git("ls-tree", "--name-only", sha, "vibe-audit/commands/").stdout.split()
    cmd_dir = agents_dir.parent / "commands"
    out = []
    for n in names:
        name = pathlib.PurePosixPath(n)
        if name.suffix != ".md":
            continue
        f = cmd_dir / name.name
        if not f.is_file():
            out.append(f"커맨드 {name.name} 가 {cmd_dir} 에 없다")
            continue
        parts = f.read_text(encoding="utf-8").split("---", 2)
        head = parts[1] if len(parts) == 3 and not parts[0].strip() else None
        fields = {}
        for line in (head or "").splitlines():
            k, sep, v = line.partition(":")
            if sep:
                fields[k.strip()] = v.strip()
        if head is None or fields.get("name") != name.stem or not fields.get("description"):
            out.append(f"커맨드 {name.name} 의 머리말이 성하지 않다 (name: {name.stem} · description 이 있어야)")
    return out


def main():
    bad, notes = [], []
    try:
        data = json.loads(REGISTRY.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"FAIL 대장이 없다: {REGISTRY.relative_to(ROOT)}")
        return 1
    except json.JSONDecodeError as e:
        print(f"FAIL 대장이 JSON 이 아니다 — {e}")
        return 1

    copies = data.get("copies")
    if not isinstance(copies, list):
        print("FAIL 대장에 copies 배열이 없다")
        return 1

    seen = set()
    reachable = 0
    for i, c in enumerate(copies, 1):
        if not isinstance(c, dict):
            bad.append(f"{i}번 줄이 객체가 아니다")
            continue
        who = c.get("repo") or f"{i}번"
        missing = [k for k in NEEDED if not c.get(k)]
        if missing:
            bad.append(f"{who}: 빠진 자리 — {', '.join(missing)}")
            continue
        if c["repo"] in seen:
            bad.append(f"{who}: 같은 레포가 두 번 적혀 있다 — 어느 쪽이 참인지 알 수 없다")
        seen.add(c["repo"])

        sha = c["synced_commit"]
        if git("cat-file", "-e", f"{sha}^{{commit}}").returncode != 0:
            bad.append(
                f"{who}: 심었다는 커밋 {sha} 가 이 저장소에 없다 "
                f"— 대장이 가리키는 원본이 없으면 견줄 수가 없다"
            )
            continue

        r = git("rev-list", "--count", f"{sha}..HEAD", "--", *WATCHED)
        drift = r.stdout.strip() if r.returncode == 0 else "?"

        path = pathlib.Path(c["agents_path"]).expanduser()
        if not path.is_dir():
            notes.append(f"{who}: 이 기계에 {path} 가 없어 못 봤다 (원본은 그 뒤 {drift} 커밋 움직임)")
            continue

        reachable += 1

        # **읽기 전용은 지금 규칙으로 본다.** 이것은 판이 달라도 변하지 않는 불변식이다.
        for f in sorted(path.glob("audit-*.md")):
            if CURRENT.frontmatter_tools(f.read_text(encoding="utf-8")) != [CURRENT.TOOLS]:
                bad.append(f"{who}: {f.name} 의 프론트매터 tools 가 원형이 아니다 — 감사자가 아니다")

        # **공통 절은 적힌 커밋의 원본과, 그 커밋의 검사기로 견준다.** 지금 HEAD 와
        # 견주면 원본이 앞서 나간 것만으로 손대지 않은 사본이 실패한다 — 갈림은
        # 실패가 아니라고 적어 놓고(루트 README) 게이트는 그것을 실패로 셌다(Codex
        # 리뷰). 규칙도 판마다 자랐으므로 그 판의 규칙으로 잰다. 앞선 만큼은 drift 로 찍는다.
        bad += [f"{who}: {m}" for m in commands_missing(sha, path)]

        # **예전 원본에 있던 감사자가 사본에 남아 있으면 실패다.** 이름을 바꾸거나 뺀
        # 감사자는 `--force` 로 다시 심어도 지워지지 않고, 위 대조는 원본 이름만 돌아
        # 그 파일을 못 본다 — 옛 description 으로 여전히 불리는데 PASS 였다(Codex 리뷰).
        # 레포가 직접 만든 감사자(원본 역사에 한 번도 없던 이름)는 허용한다 — 사본은
        # 그 레포에 맞게 갈리라고 둔 것이다.
        now = {pathlib.PurePosixPath(n).name for n in
               git("ls-tree", "--name-only", sha, "vibe-audit/agents/").stdout.split()}
        for f in sorted(path.glob("audit-*.md")):
            if f.name in now:
                continue
            ever = git("log", "--format=%h", "-1", sha, "--", f"vibe-audit/agents/{f.name}").stdout.strip()
            if ever:
                bad.append(f"{who}: {f.name} 는 원본에서 빠진 감사자다(마지막으로 건드린 커밋 {ever}) — 사본에 남아 옛 설명으로 불린다")

        ok, head = against_commit(sha, path)
        if ok is None:
            notes.append(f"{who}: {head} (원본은 그 뒤 {drift} 커밋 움직임)")
        elif not ok:
            bad.append(f"{who}: 공통 절이 {sha[:7]} 의 원본과 다르다 — {head}")
        else:
            notes.append(f"{who}: 공통 절이 {sha[:7]} 의 원본과 같음 (원본은 그 뒤 {drift} 커밋 움직임)")

    if bad:
        print("FAIL\n  - " + "\n  - ".join(bad))
        for n in notes:
            print(f"     {n}")
        return 1

    if not copies:
        print("PASS 대장에 적힌 사본 0개 — 아직 아무 데도 안 심었거나, "
              "심고 적지 않았다(이 검사가 안 본 것)")
    else:
        print(f"PASS 사본 {len(copies)}개 — 대장이 성하고, 닿는 {reachable}개는 공통 절이 원본과 같다")
    for n in notes:
        print(f"     {n}")
    print(f"     대장 {REGISTRY.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
