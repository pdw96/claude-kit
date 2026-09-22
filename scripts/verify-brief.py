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

    i = text.find("## diff")
    j = text.find("## 이 브리핑이 담지 않은 것")
    if i >= 0 and j > i and not re.search(r"^[-+]", text[i:j], re.M):
        bad.append("diff 절에 변경 줄(+/-)이 한 줄도 없다 — 빈 브리핑이다")

    if i >= 0 and j > i:
        body = text[i:j]
        lines = body.count("\n")
        omit = text[j:]
        if lines > 2000 and not re.search(r"자르|잘라|생략|truncat", omit):
            bad.append(f"diff 가 {lines}줄인데 「담지 않은 것」에 자른 기록이 없다")

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
