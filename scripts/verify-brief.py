#!/usr/bin/env python3
"""브리핑 파일이 감사자가 쓸 수 있는 모양인지 견준다. API 도 모델도 안 쓴다.

  python3 scripts/verify-brief.py <브리핑 파일>

`/audit-brief` 커맨드가 내는 `.claude/audit-brief.md` 를 받는다.

**가장 중요한 것은 「담지 않은 것」 절이다.** 브리핑이 무엇을 안 담았는지 적지
않으면 감사자는 전부 본 줄 알고, 안 본 자리가 통과한 자리처럼 보인다 — 이
플러그인이 「안 본 것」을 결과의 일부로 요구하는 것과 같은 이유다.

그리고 **기준이 적혀 있어야 한다.** 무엇과 견준 diff 인지 모르면 그 diff 는
근거가 아니다.

표준 라이브러리만 쓴다.
"""
import pathlib
import re
import sys

NEED = [
    ("## 변경 파일", "무엇이 바뀌었는지 목록이 없다"),
    ("## 커밋", "어떤 커밋들이 들어 있는지 없다"),
    ("## diff", "본문 diff 가 없다"),
    ("## 이 브리핑이 담지 않은 것", "담지 않은 것을 안 적으면 감사자가 전부 본 줄 안다"),
]


def check(text):
    bad = []

    if not text.lstrip().startswith("# 감사 브리핑"):
        bad.append("첫 줄이 `# 감사 브리핑` 이 아니다")

    for head, why in NEED:
        n = len(re.findall(r"^" + re.escape(head) + r"\s*$", text, re.M))
        if n != 1:
            bad.append(f"「{head[3:]}」 절이 {n}번 — 정확히 1번이어야 한다. {why}")

    if not re.search(r"^- 기준: .*`[0-9a-f]{7,40}`", text, re.M):
        bad.append("머리에 기준 커밋 SHA 가 없다 — 무엇과 견준 diff 인지 모르면 근거가 아니다")
    if not re.search(r"^- 대상: .*`[0-9a-f]{7,40}`", text, re.M):
        bad.append("머리에 대상 커밋 SHA 가 없다")
    if not re.search(r"^- 커밋 안 된 변경:", text, re.M):
        bad.append("커밋 안 된 변경이 있는지 안 적혀 있다 — diff 가 작업트리를 담았는지 모른다")
    # 추적 안 된 파일은 어느 diff 에도 안 나온다. 머리에 적지 않으면 새 파일이 통째로
    # 빠져도 이 검사는 모른다 — 고친 파일 하나가 아래 +/- 검사를 채우기 때문이다(Codex 리뷰).
    ut = re.search(r"^- 추적 안 된 파일:(.*)$", text, re.M)
    if not ut:
        bad.append("추적 안 된 파일이 있는지 안 적혀 있다 — 새로 만든 파일은 어느 diff 에도 안 나온다")
    else:
        # 줄만 있고 적힌 파일이 본문에 없으면 머리가 거짓말을 한다. 「app/new.py — 아래
        # diff 포함」이라 적고 빼도, 다른 파일의 +/- 가 diff 검사를 채웠다(Codex 리뷰).
        # 적힌 경로(백틱 안)는 diff 절이나 「담지 않은 것」 절에 다시 나와야 한다.
        rest = text[:ut.start()] + text[ut.end():]
        k = rest.find("## diff")
        where = rest[k:] if k >= 0 else ""
        for path in re.findall(r"`([^`]+)`", ut.group(1)):
            if path not in where:
                bad.append(f"추적 안 된 파일 `{path}` 가 diff 에도 「담지 않은 것」에도 없다 — 머리만 적었다")
    # 자른 여부는 **명시로** 받는다. 줄 수로 짐작하면 못 잡는다 — 5,000줄을 2,000줄로
    # 자른 브리핑은 이미 2,000줄이라 「길다」가 안 걸린다(Codex 리뷰).
    cut = re.search(r"^- 자름:\s*(없음|있음)(.*)$", text, re.M)
    if not cut:
        bad.append("머리에 `자름: 없음` / `자름: 있음 — N줄 중 M줄` 이 없다 — 자른 브리핑을 전부로 읽는다")
    elif cut.group(1) == "있음" and not re.search(r"\d", cut.group(2)):
        bad.append("`자름: 있음` 인데 몇 줄 중 몇 줄을 담았는지가 없다")

    i = text.find("## diff")
    j = text.find("## 이 브리핑이 담지 않은 것")
    if i >= 0 and j > i and not re.search(r"^[-+]", text[i:j], re.M):
        bad.append("diff 절에 변경 줄(+/-)이 한 줄도 없다 — 빈 브리핑이다")

    # 「담지 않은 것」은 제목만으로는 공개가 아니다. 제목 아래가 비면 감사자는 여전히
    # 전부 본 줄 안다 — 이 검사가 지키려는 바로 그것이다(Codex 리뷰). 항목 하나는 있어야 한다.
    if j >= 0 and not re.search(r"^\s*[-*] \S", text[j:].split("\n", 1)[-1], re.M):
        bad.append("「담지 않은 것」 제목 아래에 항목이 하나도 없다 — 제목은 공개가 아니다")

    if i >= 0 and j > i:
        body = text[i:j]
        lines = body.count("\n")
        omit = text[j:]
        if lines > 2000 and not re.search(r"자르|잘라|생략|truncat", omit):
            bad.append(f"diff 가 {lines}줄인데 「담지 않은 것」에 자른 기록이 없다")
        if cut and cut.group(1) == "있음" and not re.search(r"자르|잘라|잘랐|생략|truncat", omit):
            bad.append("`자름: 있음` 인데 「담지 않은 것」에 무엇을 잘랐는지가 없다")

    return bad


def main(argv):
    if len(argv) != 2:
        print(__doc__)
        return 2
    p = pathlib.Path(argv[1])
    if not p.is_file():
        print(f"FAIL 브리핑 파일이 없다: {p}")
        return 1
    bad = check(p.read_text(encoding="utf-8"))
    if bad:
        for line in bad:
            print("FAIL " + line)
        print(f"\n{len(bad)}건. 파일: {p}")
        return 1
    print(f"PASS 브리핑에 기준 · 변경 파일 · 커밋 · diff · 담지 않은 것이 다 있다")
    print(f"     {p}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
