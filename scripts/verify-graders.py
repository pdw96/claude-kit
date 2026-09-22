#!/usr/bin/env python3
"""그레이더가 바른 기록과 틀린 기록을 실제로 가르는지 견준다. API 키가 필요 없다.

  python3 scripts/verify-graders.py [수트 디렉터리]

`verify-evals.py` 는 수트의 **모양**만 본다 — 그레이더가 있는가, 대조군이
있는가. 그 검사를 통과하면서도 **아무것도 가르지 못하는 정규식**은 얼마든지
쓸 수 있다. 이 작업에서 실제로 세 번 나왔다.

- `report.py` 를 잡는 분류기가 감사 데이터 NC 를 성능 발견으로 오인했다
- 라우팅 음성 대조군이 안 물었다 — 맞는 감사자가 여전히 이겼기 때문이다
- `gate-no-fake-owner` 정규식이 **진짜 가짜 담당을 놓쳤다** — 그것이 표식
  *앞*에 앉아 있었고, 정규식은 표식 뒤만 봤다

셋 다 같은 가정을 깔고 있었다 — 「문자열이 거기 있으면 그런 뜻이다」.

그래서 케이스가 표본 두 벌을 함께 두게 한다.

  <케이스>/samples/pass.md   — 바르게 쓴 기록. 모든 정규식 그레이더가 통과해야 한다
  <케이스>/samples/fail.md   — 함정을 밟은 기록. 첫 줄에 물어야 할 그레이더를 적는다

`fail.md` 첫 줄:

  <!-- 무는 그레이더: trap-no-false-resolved gate-unseen-declared -->

**표본은 선택이다.** 다만 없는 케이스는 여기서 세어 찍는다 — 덮이지 않은 자리를
덮인 것처럼 두지 않는다.

심판 그레이더(`llm` · `baseline`)는 여기서 보지 않는다. 모델이 필요하고, 이
스크립트는 필요 없어야 한다.

표준 라이브러리만 쓴다.
"""
import pathlib
import re
import sys

DECL = re.compile(r"<!--\s*무는 그레이더:\s*(.+?)\s*-->")


def grader(path):
    """정규식 그레이더의 pattern 과 match 를 꺼낸다. 아니면 None."""
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---\n", 3)
    if end == -1:
        return None
    out = {}
    for line in text[4:end].splitlines():
        m = re.match(r"([\w.-]+):\s*(.*)$", line)
        if not m:
            continue
        key, raw = m.group(1), m.group(2).strip()
        if key == "pattern" and raw.startswith('"') and raw.endswith('"'):
            # YAML 큰따옴표는 \\ 를 \ 로 푼다. 그 뒤는 정규식의 것이다.
            out[key] = raw[1:-1].replace('\\\\', '\\').replace('\\"', '"')
        else:
            out[key] = raw.strip("\"'")
    return out if out.get("type") == "regex" and "pattern" in out else None


def hits(g, text):
    """그레이더가 이 기록을 통과시키는가."""
    found = re.search(g["pattern"], text) is not None
    return found if g.get("match") != "not_contains" else not found


def check(suite):
    cases = sorted(
        d for d in suite.iterdir()
        if d.is_dir() and d.name != "results" and not d.name.startswith(".")
    )
    bad, covered, uncovered = [], [], []

    for case in cases:
        samples = case / "samples"
        if not samples.is_dir():
            uncovered.append(case.name)
            continue

        graders = {}
        for g in sorted((case / "graders").glob("*.md")):
            got = grader(g)
            if got:
                graders[g.stem] = got
        if not graders:
            bad.append(f"{case.name}: samples/ 가 있는데 정규식 그레이더가 없다")
            continue

        ok_file, ng_file = samples / "pass.md", samples / "fail.md"
        for f in (ok_file, ng_file):
            if not f.exists():
                bad.append(f"{case.name}: samples/{f.name} 이 없다 — 한 벌로는 가르는지 알 수 없다")
        if not (ok_file.exists() and ng_file.exists()):
            continue

        ok_text = ok_file.read_text(encoding="utf-8")
        for name, g in sorted(graders.items()):
            if not hits(g, ok_text):
                bad.append(
                    f"{case.name}/{name}: 바르게 쓴 기록(samples/pass.md)에서 실패한다 — "
                    "정규식이 좁거나 출력 형식과 어긋난다"
                )

        ng_text = ng_file.read_text(encoding="utf-8")
        m = DECL.search(ng_text.split("\n", 1)[0])
        if not m:
            bad.append(
                f"{case.name}: samples/fail.md 첫 줄에 "
                "<!-- 무는 그레이더: ... --> 가 없다 — 무엇이 물어야 하는지 없으면 검사가 아니다"
            )
            continue
        want = m.group(1).split()
        unknown = [w for w in want if w not in graders]
        if unknown:
            bad.append(f"{case.name}: samples/fail.md 가 없는 그레이더 {unknown} 를 적었다")
        if not any(w.startswith(("trap-", "gate-")) for w in want):
            bad.append(f"{case.name}: samples/fail.md 가 목적 그레이더를 하나도 안 적었다")
        for name in want:
            if name in graders and hits(graders[name], ng_text):
                bad.append(
                    f"{case.name}/{name}: 함정을 밟은 기록(samples/fail.md)에서 통과한다 — "
                    "물지 않는 그레이더는 게이트가 아니다"
                )
        covered.append(f"{case.name}({len(graders)})")

    return bad, covered, uncovered


def main(argv):
    here = pathlib.Path(__file__).resolve().parent.parent
    suite = pathlib.Path(argv[1]) if len(argv) == 2 else here / "vibe-audit" / "evals"
    if len(argv) > 2:
        print(__doc__)
        return 2
    if not suite.is_dir():
        print(f"FAIL 수트 디렉터리가 없다: {suite}")
        return 1

    bad, covered, uncovered = check(suite)
    for line in bad:
        print("FAIL " + line)
    if bad:
        print(f"\n{len(bad)}건. 수트: {suite}")
        return 1
    if not covered:
        print(f"FAIL 표본을 둔 케이스가 하나도 없다 — 이 검사가 아무것도 안 본다: {suite}")
        return 1
    print(f"PASS 표본으로 견딘 케이스 {len(covered)}개 — {' · '.join(covered)}")
    if uncovered:
        print(f"     표본 없음 {len(uncovered)}개(이 검사가 안 본 것) — {' · '.join(uncovered)}")
    print(f"     수트 {suite}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
