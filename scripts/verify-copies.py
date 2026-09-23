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
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
REGISTRY = ROOT / "copies.json"
NEEDED = ("repo", "agents_path", "synced_commit", "synced_at")
WATCHED = ("vibe-audit/agents", "vibe-audit/commands")


def git(*args):
    return subprocess.run(
        ["git", "-C", str(ROOT), *args],
        capture_output=True, text=True,
    )


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
        p = subprocess.run(
            [sys.executable, str(ROOT / "scripts" / "verify-copy.py"), str(path)],
            capture_output=True, text=True,
        )
        head = (p.stdout or p.stderr).strip().splitlines()
        head = head[0] if head else "(말이 없다)"
        if p.returncode != 0:
            bad.append(f"{who}: 공통 절이 원본과 다르다 — {head}")
        else:
            notes.append(f"{who}: 공통 절 같음 (원본은 그 뒤 {drift} 커밋 움직임)")

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
