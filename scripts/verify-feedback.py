#!/usr/bin/env python3
"""후보 대장(`feedback.json`)이 성한지 본다. 모델도 네트워크도 안 쓴다.

  python3 scripts/verify-feedback.py            # 저장소의 feedback.json
  python3 scripts/verify-feedback.py <대장>      # 다른 대장 — CI 가 변조본으로 쓴다

**왜 있나.** 사본과 원본을 견줘 나온 후보를 저자가 판정하면 이 대장에 남고,
`compare-copies.py` 는 여기 있는 해시를 빼고 미판정만 찍는다. 대장이 틀리면
조용히 샌다 — 해시가 겹치면 어느 판정이 참인지 모르고, 「되먹임 완료」인데
원본 커밋이나 케이스가 없으면 되먹였다는 말을 아무것도 받쳐 주지 않는다.

규칙은 `docs/schema.md` 의 `feedback.json` 표 그대로다. 그 표를 고치면 여기도 고친다.

대장이 없으면 「후보 0」으로 통과한다 — 아직 아무것도 판정하지 않은 상태다.

표준 라이브러리만 쓴다.
"""
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LEDGER = ROOT / "feedback.json"
STATUS = {"specific": "특화", "defect": "결함", "hold": "보류", "fed_back": "되먹임 완료"}
SHA = re.compile(r"^[0-9a-f]{40}$")
HASH = re.compile(r"^sha256:[0-9a-f]{64}$")
DAY = re.compile(r"^\d{4}-\d{2}-\d{2}$")
ID = re.compile(r"^FB-([1-9]\d*)$")


def has_commit(sha):
    return subprocess.run(["git", "-C", str(ROOT), "cat-file", "-e", f"{sha}^{{commit}}"],
                          capture_output=True).returncode == 0


def check_seen(who, seen):
    bad = []
    if not isinstance(seen, list) or not seen:
        return [f"{who}: seen 이 비었다 — 어느 사본에서 본 것인지 없다"]
    for k, s in enumerate(seen, 1):
        at = f"{who} seen[{k}]"
        if not isinstance(s, dict):
            bad.append(f"{at}: 객체가 아니다")
            continue
        if not isinstance(s.get("repo"), str) or not s["repo"]:
            bad.append(f"{at}: repo 가 없다")
        files = s.get("files")
        if (not isinstance(files, list) or not files
                or not all(isinstance(f, str) and f.endswith(".md") and "/" not in f for f in files)):
            bad.append(f"{at}: files 는 감사자 파일 이름(*.md)의 목록이어야 한다")
        if not SHA.match(str(s.get("commit", ""))):
            bad.append(f"{at}: commit 이 40자 SHA 가 아니다 — 판정할 때 견준 사본 커밋")
        base = str(s.get("base", ""))
        if not SHA.match(base):
            bad.append(f"{at}: base 가 40자 SHA 가 아니다 — 판정할 때 견준 원본 커밋")
        elif not has_commit(base):
            bad.append(f"{at}: base {base[:7]} 가 이 저장소에 없다 — 무엇과 견준 판정인지 되짚을 수 없다")
    return bad


def check_feedback(who, fb):
    if not isinstance(fb, dict):
        return [f"{who}: 되먹임 완료인데 feedback 이 없다 — 원본 커밋과 케이스를 적는다"]
    bad = []
    commit = str(fb.get("commit", ""))
    if not SHA.match(commit):
        bad.append(f"{who}: feedback.commit 이 40자 SHA 가 아니다")
    elif not has_commit(commit):
        bad.append(f"{who}: feedback.commit {commit[:7]} 가 이 저장소에 없다 — 스쿼시 머지로 사라졌는가")
    cases = fb.get("cases")
    if not isinstance(cases, list) or not cases:
        bad.append(f"{who}: feedback.cases 가 비었다 — 되먹임 한 건에 케이스 하나")
    else:
        for c in cases:
            if not isinstance(c, str) or not re.fullmatch(r"[\w.-]+", c) \
                    or not (ROOT / "vibe-audit" / "evals" / c / "case.yaml").is_file():
                bad.append(f"{who}: 케이스 {c!r} 가 vibe-audit/evals/ 에 없다")
    if not isinstance(fb.get("budget_delta"), int) or isinstance(fb.get("budget_delta"), bool):
        bad.append(f"{who}: feedback.budget_delta 가 정수가 아니다 — 호출 시 문자 증감")
    return bad


def main():
    path = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else LEDGER
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"PASS 후보 0 — 대장이 아직 없다 ({path.name})")
        return 0
    except json.JSONDecodeError as e:
        print(f"FAIL 대장이 JSON 이 아니다 — {e}")
        return 1

    cands = data.get("candidates") if isinstance(data, dict) else None
    if not isinstance(cands, list):
        print("FAIL 대장에 candidates 배열이 없다")
        return 1

    bad, ids, hashes, count = [], [], {}, {k: 0 for k in STATUS}
    for i, c in enumerate(cands, 1):
        if not isinstance(c, dict):
            bad.append(f"{i}번 줄이 객체가 아니다")
            continue
        who = str(c.get("id") or f"{i}번")
        m = ID.match(str(c.get("id", "")))
        if not m:
            bad.append(f"{who}: id 가 FB-n 꼴이 아니다")
        else:
            ids.append(int(m.group(1)))
        h = str(c.get("hash", ""))
        if not HASH.match(h):
            bad.append(f"{who}: hash 가 sha256:<64 hex> 꼴이 아니다")
        elif h in hashes:
            bad.append(f"{who}: hash 가 {hashes[h]} 와 같다 — 같은 후보를 두 번 판정했다")
        else:
            hashes[h] = who
        bad += check_seen(who, c.get("seen"))
        st = c.get("status")
        if st not in STATUS:
            bad.append(f"{who}: status {st!r} — {' · '.join(STATUS)} 중 하나다. 미판정은 대장에 안 적는다")
        else:
            count[st] += 1
        if not isinstance(c.get("reason"), str) or not c["reason"].strip():
            bad.append(f"{who}: reason 이 비었다 — 판정 근거 없이는 다음 사람이 되짚지 못한다")
        if not DAY.match(str(c.get("decided_at", ""))):
            bad.append(f"{who}: decided_at 이 YYYY-MM-DD 가 아니다")
        if st == "fed_back":
            bad += check_feedback(who, c.get("feedback"))
        elif "feedback" in c:
            bad.append(f"{who}: 되먹임 완료가 아닌데 feedback 이 있다 — 상태와 기록이 어긋난다")

    if sorted(ids) != list(range(1, len(ids) + 1)):
        bad.append(f"id 가 FB-1 부터 이어지지 않거나 겹친다: {sorted(ids)}")

    if bad:
        for b in bad:
            print(f"FAIL {b}")
        return 1
    print(f"PASS 후보 {len(cands)} — " + " · ".join(f"{STATUS[k]} {v}" for k, v in count.items()))
    print(f"     대장 {path.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
