#!/usr/bin/env python3
"""레포 사본이 원본 감사자의 공통 절을 정확히 들고 있는지 견준다.

  python3 scripts/verify-copy.py <사본 agents 디렉터리>
  python3 scripts/verify-copy.py <원본 agents 디렉터리> <사본 agents 디렉터리>

인자가 하나면 원본은 이 스크립트 옆의 vibe-audit/agents 다.

**표식이 아니라 문구를 글자 단위로 견준다.** 절이 있는지만 보면 세션이 문구를
손으로 다시 쓰거나 한 줄 빠뜨려도 통과한다. 두 벌이 생겼으면 견주는 검사를
붙인다 — 물지 않는 검사는 게이트가 아니다.

사본 고유의 특화(체크 항목 추가 · 감사 원칙 보강)는 보지 않는다. 그건 사본에
있으라고 둔 것이다. 여기서 보는 것은 **모든 레포에서 같아야 하는 절**뿐이다.

표준 라이브러리만 쓴다.
"""
import pathlib
import sys

# 모든 사본에서 원본과 같아야 하는 절
SHARED = ["## 판정은 넷이다", "## 부적합과 관찰을 가릅니다"]

# 이 순서로 서 있어야 한다
ORDER = ["## 감사 원칙", "## 판정은 넷이다", "## 부적합과 관찰을 가릅니다", "## 출력 형식"]

TOOLS = '\ntools: ["Read", "Grep", "Glob"]\n'


def section(text, head):
    """head 절을 다음 '## ' 직전까지 자른다.

    '### ' 는 절 안이고, 펜스(```) 안의 '## ' 도 절 경계가 아니다 —
    출력 형식 예시가 '## 관찰' 을 품고 있다.
    """
    lines = text.splitlines()
    try:
        i = lines.index(head)
    except ValueError:
        return None
    out = [lines[i]]
    fenced = False
    for line in lines[i + 1:]:
        if line.startswith("```"):
            fenced = not fenced
        elif not fenced and line.startswith("## ") and not line.startswith("### "):
            break
        out.append(line)
    return "\n".join(out).rstrip()


def check(src, dst):
    names = sorted(p.name for p in src.glob("audit-*.md"))
    if len(names) != 6:
        return [f"원본 {src} 에 감사자가 {len(names)}개다 — 6이어야 한다"]

    bad = []
    for name in names:
        d = dst / name
        if not d.exists():
            bad.append(f"{name}: 사본이 없다")
            continue
        st = (src / name).read_text(encoding="utf-8")
        dt = d.read_text(encoding="utf-8")

        if not dt.startswith("---\n"):
            bad.append(f"{name}: 첫 줄이 --- 가 아니다 — 프론트매터가 안 읽힌다")
        if TOOLS not in dt:
            bad.append(f"{name}: tools 줄이 원형이 아니다 — 이것이 바뀌면 감사자가 아니다")
        if "적합 / 부적합 / 해당 없음" in dt:
            bad.append(f"{name}: 판정값이 아직 셋이다 — 확인불가가 빠졌다")

        for head in SHARED:
            n = dt.count("\n" + head + "\n")
            if n != 1:
                bad.append(f"{name}: 「{head[3:]}」 절이 {n}번 — 정확히 1번이어야 한다")
                continue
            if section(st, head) != section(dt, head):
                bad.append(f"{name}: 「{head[3:]}」 절이 원본과 다르다")

        pos = []
        for head in ORDER:
            try:
                pos.append(dt.index("\n" + head + "\n"))
            except ValueError:
                bad.append(f"{name}: 「{head[3:]}」 절이 없다")
                pos = None
                break
        if pos and pos != sorted(pos):
            bad.append(f"{name}: 절 순서가 틀렸다 — " + " → ".join(h[3:] for h in ORDER))

    return bad


def main(argv):
    here = pathlib.Path(__file__).resolve().parent.parent
    if len(argv) == 2:
        src, dst = here / "vibe-audit" / "agents", pathlib.Path(argv[1])
    elif len(argv) == 3:
        src, dst = pathlib.Path(argv[1]), pathlib.Path(argv[2])
    else:
        print(__doc__)
        return 2

    for p, what in ((src, "원본"), (dst, "사본")):
        if not p.is_dir():
            print(f"FAIL {what} 디렉터리가 없다: {p}")
            return 1

    bad = check(src, dst)
    if bad:
        for line in bad:
            print("FAIL " + line)
        print(f"\n{len(bad)}건. 원본: {src}")
        return 1
    print(f"PASS 감사자 6개 — 공통 절이 원본과 글자 단위로 같고 순서도 맞다")
    print(f"     원본 {src}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
