#!/usr/bin/env python3
"""평가 수트가 물 수 있는 모양인지 견준다. API 키도 모델 호출도 필요 없다.

  python3 scripts/verify-evals.py [수트 디렉터리]

인자가 없으면 이 스크립트 옆의 vibe-audit/evals 다.

**이것이 없으면 수트가 조용히 썩는다.** `claude plugin eval` 은 케이스를 안
찾으면 그냥 아무것도 안 돌리고 끝난다 — 그레이더 파일 이름을 잘못 쓰거나
`fixture.sh` 가 실행 권한을 잃어도 초록이 난다. 물지 않는 검사는 게이트가
아니다.

케이스는 두 모양이다. 이름의 앞머리로 가른다.

- `trap-*` · `gate-*` — **판정**을 잰다. 감사자를 이름으로 불러 놓고, 그 기록이
  함정을 밟았는지 본다
- `route-*` — **트리거**를 잰다. 감사자를 지목하지 않은 자연스러운 말에 맞는
  감사자가 뜨는가. 프론트매터 `description` 이 시험 대상이다

판정 케이스에서 특히 보는 것은 **대조군**이다. 함정 그레이더만 있는 케이스는
아무것도 안 내는 망가진 감사자에게 만점을 준다 — 함정을 안 걸었으니까. 그래서
`real-nc-found` 를 요구한다.

트리거 케이스에서 같은 자리에 서는 것은 **음성 그레이더**(`route-not-*`)다.
여섯을 전부 띄우는 세션도 「맞는 감사자가 떴다」로는 통과하기 때문이다.

트리거 케이스의 `prompt.md` 는 감사자를 **지목하면 안 된다.** 지목하면 재는
것이 트리거가 아니라 복종이 된다.

표준 라이브러리만 쓴다.
"""
import pathlib
import re
import sys

GRADER_TYPES = {"regex", "tool_used", "tool_order", "file_exists", "llm", "baseline"}
CONTROL = "real-nc-found"
PURPOSE_PREFIXES = ("trap-", "gate-")
ROUTE_PREFIX = "route-"


def frontmatter(path):
    """--- 로 둘러싼 머리말을 얕게 읽는다. 중첩은 점으로 잇는다."""
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---\n", 3)
    if end == -1:
        return None
    out, stack = {}, []
    for line in text[4:end].splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())
        m = re.match(r"\s*([\w.-]+):\s*(.*)$", line)
        if not m:
            continue
        key, val = m.group(1), m.group(2).strip()
        while stack and stack[-1][0] >= indent:
            stack.pop()
        path_key = ".".join([k for _, k in stack] + [key])
        if val == "":
            stack.append((indent, key))
        else:
            out[path_key] = val.strip("\"'")
    return out


def yaml_shallow(path):
    """case.yaml 을 같은 방식으로 얕게 읽는다. 블록 스칼라는 값 없이 넘긴다."""
    out, stack = {}, []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())
        m = re.match(r"\s*([\w.-]+):\s*(.*)$", line)
        if not m:
            continue
        key, val = m.group(1), m.group(2).strip()
        while stack and stack[-1][0] >= indent:
            stack.pop()
        full = ".".join([k for _, k in stack] + [key])
        if val in ("", "|", ">", "|-", ">-"):
            stack.append((indent, key))
            if val in ("|", ">", "|-", ">-"):
                out[full] = "<block>"
        else:
            out[full] = val.strip("\"'")
    return out


def check(suite, agents_dir):
    known = {p.stem for p in agents_dir.glob("audit-*.md")}
    if not known:
        return [f"감사자를 못 찾았다: {agents_dir}"]

    cases = sorted(
        d for d in suite.iterdir()
        if d.is_dir() and d.name != "results" and not d.name.startswith(".")
    )
    if not cases:
        return [f"{suite} 에 케이스가 없다 — 수트가 비어 있으면 eval 은 조용히 통과한다"]

    bad = []
    for case in cases:
        name = case.name
        cy, pm, gd = case / "case.yaml", case / "prompt.md", case / "graders"

        if not cy.exists():
            bad.append(f"{name}: case.yaml 이 없다")
            continue
        if not pm.exists():
            bad.append(f"{name}: prompt.md 가 없다")
            continue
        if not gd.is_dir():
            bad.append(f"{name}: graders/ 가 없다 — 그레이더 없는 케이스는 아무것도 재지 않는다")
            continue

        meta = yaml_shallow(cy)
        if meta.get("schema_version") != "1.1":
            bad.append(f"{name}: case.yaml 의 schema_version 이 \"1.1\" 이 아니다")
        if meta.get("name") != name:
            bad.append(f"{name}: case.yaml 의 name 이 디렉터리 이름과 다르다 ({meta.get('name')!r})")

        script = meta.get("context.scaffold_script")
        if script:
            f = case / script
            if not f.exists():
                bad.append(f"{name}: scaffold_script 가 가리키는 {script} 가 없다")
            else:
                import subprocess
                if subprocess.run(["bash", "-n", str(f)]).returncode != 0:
                    bad.append(f"{name}: {script} 가 bash 문법 검사에서 깨진다")

        route = name.startswith(ROUTE_PREFIX)

        # 부르는 감사자가 실재하는가
        body = pm.read_text(encoding="utf-8")
        called = set(re.findall(r"audit-[a-z]+", body))
        for a in sorted(called - known):
            bad.append(f"{name}: prompt.md 가 없는 감사자 {a} 를 부른다")
        if route and called:
            bad.append(
                f"{name}: 트리거 케이스인데 prompt.md 가 {sorted(called)} 를 지목한다 — "
                "재는 것이 트리거가 아니라 복종이 된다"
            )
        if not route and not called:
            bad.append(f"{name}: prompt.md 가 어떤 감사자도 지목하지 않는다")

        graders = sorted(gd.glob("*.md"))
        if not graders:
            bad.append(f"{name}: graders/ 에 그레이더가 없다")
            continue

        names, purpose_weight, has_control = set(), 0, False
        route_target, route_negatives = None, []
        for g in graders:
            fm = frontmatter(g)
            if fm is None:
                bad.append(f"{name}/{g.stem}: 프론트매터가 --- 로 닫히지 않았다")
                continue
            t = fm.get("type")
            if t not in GRADER_TYPES:
                bad.append(f"{name}/{g.stem}: type 이 {t!r} — {sorted(GRADER_TYPES)} 중 하나여야 한다")
            names.add(g.stem)
            if g.stem.startswith(PURPOSE_PREFIXES):
                purpose_weight += float(fm.get("weight", 1))
            if g.stem == CONTROL:
                has_control = True
                if fm.get("arm"):
                    bad.append(f"{name}/{CONTROL}: arm 이 붙어 점수에서 빠진다 — 대조군은 점수에 들어가야 한다")
            if route and g.stem.startswith(("route-correct", "route-not-")):
                if t_ := fm.get("type"):
                    if t_ != "tool_used":
                        bad.append(f"{name}/{g.stem}: type 이 tool_used 여야 한다 — 트리거는 심판이 필요 없다")
                if fm.get("tool") != "Agent":
                    bad.append(f"{name}/{g.stem}: tool 이 Agent 여야 한다")
                im = fm.get("input_match", "")
                if im not in known:
                    bad.append(f"{name}/{g.stem}: input_match {im!r} 가 실재하는 감사자가 아니다")
                elif g.stem == "route-correct":
                    route_target = im
                    if fm.get("min", "1") in ("0",):
                        bad.append(f"{name}/route-correct: min 이 0 이다 — 아무것도 요구하지 않는다")
                else:
                    route_negatives.append(im)
                    if not (fm.get("min") == "0" and fm.get("max") == "0"):
                        bad.append(f"{name}/{g.stem}: 음성 그레이더는 min 0 · max 0 이어야 한다")
            if g.stem == "auditor-fired":
                if fm.get("arm") != "with-only":
                    bad.append(f"{name}/auditor-fired: arm 이 with-only 여야 한다 (점수가 아니라 표시)")
                im = fm.get("input_match", "")
                if im not in known:
                    bad.append(f"{name}/auditor-fired: input_match {im!r} 가 실재하는 감사자가 아니다")
                elif im not in called:
                    bad.append(f"{name}/auditor-fired: {im} 를 요구하는데 prompt.md 는 {sorted(called)} 를 부른다")

        if route:
            if not route_target:
                bad.append(f"{name}: route-correct 그레이더가 없다 — 어느 감사자가 떠야 하는지 없다")
            if not route_negatives:
                bad.append(
                    f"{name}: route-not-* 음성 그레이더가 없다 — "
                    "여섯을 전부 띄우는 세션도 통과한다"
                )
            for neg in route_negatives:
                if neg == route_target:
                    bad.append(f"{name}: route-not-{neg} 가 route-correct 와 같은 감사자다")
            if CONTROL in names:
                bad.append(f"{name}: 트리거 케이스에 {CONTROL} 이 있다 — 판정은 여기서 재지 않는다")
        else:
            if purpose_weight == 0:
                bad.append(f"{name}: trap-* · gate-* 그레이더가 없다 — 이 케이스의 목적이 없다")
            if not has_control:
                bad.append(
                    f"{name}: {CONTROL} 대조군이 없다 — "
                    "아무것도 안 내는 감사자가 함정을 안 걸었다는 이유로 만점을 받는다"
                )
            if "auditor-fired" not in names:
                bad.append(f"{name}: auditor-fired 가 없다 — 감사자가 실제로 떴는지 알 수 없다")

    return bad


def main(argv):
    here = pathlib.Path(__file__).resolve().parent.parent
    suite = pathlib.Path(argv[1]) if len(argv) == 2 else here / "vibe-audit" / "evals"
    if len(argv) > 2:
        print(__doc__)
        return 2
    if not suite.is_dir():
        print(f"FAIL 수트 디렉터리가 없다: {suite}")
        return 1

    agents = suite.parent / "agents"
    bad = check(suite, agents)
    if bad:
        for line in bad:
            print("FAIL " + line)
        print(f"\n{len(bad)}건. 수트: {suite}")
        return 1
    cases = [d for d in suite.iterdir() if d.is_dir() and d.name != "results"]
    routes = [d for d in cases if d.name.startswith(ROUTE_PREFIX)]
    print(
        f"PASS 케이스 {len(cases)}개 — "
        f"판정 {len(cases) - len(routes)}(목적 그레이더 · 대조군 · 감사자 지목), "
        f"트리거 {len(routes)}(route-correct · 음성 그레이더 · 지목 없음)"
    )
    print(f"     수트 {suite}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
