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


def diff_lines(text):
    """diff 절 본문의 줄 수 — 절 머리 · 코드 울타리 · 앞뒤 빈 줄을 뺀다. 절이 없으면 None."""
    m = re.search(r"^## diff[ \t]*\n([\s\S]*?)(?=^## |\Z)", text, re.M)
    if not m:
        return None
    body = [ln for ln in m.group(1).split("\n") if not ln.startswith("```")]
    while body and not body[0].strip():
        body.pop(0)
    while body and not body[-1].strip():
        body.pop()
    return len(body)


def short_hunks(body):
    """줄 수가 모자란 헝크의 (머리, 마지막 헝크인가) 목록."""
    out, lines, k = [], body.split("\n"), 0
    heads = [n for n, ln in enumerate(lines) if re.match(r"@@ -\d", ln)]
    for h in heads:
        m = re.match(r"@@ -\d+(?:,(\d+))? \+\d+(?:,(\d+))? @@", lines[h])
        if not m:
            continue
        old, new = int(m.group(1) or 1), int(m.group(2) or 1)
        k = h + 1
        while k < len(lines) and (old > 0 or new > 0):
            ln = lines[k]
            if ln.startswith("\\"):
                pass
            elif ln.startswith("-") and not ln.startswith("--- a/"):
                old -= 1
            elif ln.startswith("+") and not ln.startswith("+++ b/"):
                new -= 1
            elif ln.startswith(" ") or (ln == "" and old > 0 and new > 0):
                # 빈 줄은 공백이 지워진 문맥 줄일 수 있다 — 양쪽이 다 남았을 때만 문맥으로 센다
                old, new = old - 1, new - 1
            else:
                break
            k += 1
        if old > 0 or new > 0:
            out.append((lines[h].split(" @@")[0] + " @@", h == heads[-1]))
    return out


def check(text):
    bad = []

    if not text.lstrip().startswith("# 감사 브리핑"):
        bad.append("첫 줄이 `# 감사 브리핑` 이 아니다")

    at = []
    for head, why in NEED:
        found = [m.start() for m in re.finditer(r"^" + re.escape(head) + r"\s*$", text, re.M)]
        if len(found) != 1:
            bad.append(f"「{head[3:]}」 절이 {len(found)}번 — 정확히 1번이어야 한다. {why}")
        at.append(found[0] if len(found) == 1 else None)
    # 절은 적힌 순서대로 와야 한다. 「담지 않은 것」이 diff 앞에 오면 아래의 빈 diff
    # 검사가 통째로 건너뛰어져, 끝에 빈 diff 절을 둔 브리핑이 통과했다(Codex 리뷰).
    got = [a for a in at if a is not None]
    if len(got) == len(NEED) and got != sorted(got):
        bad.append("절의 순서가 변경 파일 → 커밋 → diff → 담지 않은 것 이 아니다")

    if not re.search(r"^- 기준: .*`[0-9a-f]{7,40}`", text, re.M):
        bad.append("머리에 기준 커밋 SHA 가 없다 — 무엇과 견준 diff 인지 모르면 근거가 아니다")
    if not re.search(r"^- 대상: .*`[0-9a-f]{7,40}`", text, re.M):
        bad.append("머리에 대상 커밋 SHA 가 없다")
    wt = re.search(r"^- 커밋 안 된 변경:(.*)$", text, re.M)
    if not wt:
        bad.append("커밋 안 된 변경이 있는지 안 적혀 있다 — diff 가 작업트리를 담았는지 모른다")
    elif not (wt.group(1).strip().startswith("없음")
              or (wt.group(1).strip().startswith("있음") and re.search(r"포함|담지 않|뺐|제외", wt.group(1)))):
        # 줄만 있고 값이 비면 적지 않은 것과 같다. 「있음」이면 diff 에 넣었는지도 적어야
        # 감사자가 작업트리 몫을 본 것인지 안다(Codex 리뷰).
        bad.append("`커밋 안 된 변경:` 값이 `없음` 도, 포함 여부를 적은 `있음` 도 아니다")
    elif wt.group(1).strip().startswith("있음"):
        # 「있음 — 포함」이라 적고 `git diff HEAD` 가 실패해 작업트리 몫이 빠져도 통과했다
        # (Codex 리뷰). 추적 안 된 파일처럼 백틱 경로를 적게 하고, 그 경로가 diff 절이나
        # 「담지 않은 것」에 다시 나와야 한다.
        paths = re.findall(r"`([^`]+)`", wt.group(1))
        if not paths:
            bad.append("`커밋 안 된 변경: 있음` 인데 어느 파일인지 백틱 경로가 없다 — 담겼는지 가릴 수 없다")
        # 커밋된 diff 에 같은 파일이 있으면 그것만으로 채워졌다(Codex 리뷰). 작업트리 몫은
        # diff 절의 `### 작업트리` 아래에 따로 있어야 하고, 경로는 거기나 「담지 않은 것」에.
        sub = re.search(r"^### 작업트리[ \t]*\n([\s\S]*?)(?=^## |^### |\Z)", text, re.M)
        omit = text[text.find("## 이 브리핑이 담지 않은 것"):] if "## 이 브리핑이 담지 않은 것" in text else ""
        for path in paths:
            if path not in (sub.group(1) if sub else "") and path not in omit:
                bad.append(f"커밋 안 된 변경 `{path}` 가 diff 의 「### 작업트리」에도 「담지 않은 것」에도 없다 — 머리만 적었다")
    # 추적 안 된 파일은 어느 diff 에도 안 나온다. 머리에 적지 않으면 새 파일이 통째로
    # 빠져도 이 검사는 모른다 — 고친 파일 하나가 아래 +/- 검사를 채우기 때문이다(Codex 리뷰).
    ut = re.search(r"^- 추적 안 된 파일:(.*)$", text, re.M)
    if not ut:
        bad.append("추적 안 된 파일이 있는지 안 적혀 있다 — 새로 만든 파일은 어느 diff 에도 안 나온다")
    elif not (ut.group(1).strip().startswith("없음") or re.search(r"`[^`]+`", ut.group(1))):
        # 값이 비면 줄만 있는 것과 같다 — 새 파일을 빠뜨렸는지 감사자가 모른다(Codex 리뷰).
        bad.append("`추적 안 된 파일:` 값이 `없음` 도 백틱 경로 목록도 아니다 — 비어 있으면 적지 않은 것과 같다")
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
    elif cut.group(1) == "있음":
        # 두 수가 다 있어야 한다 — 전체만 적으면 몇 줄을 받았는지 모른다(Codex 리뷰).
        # 받은 줄이 전체보다 적어야 자른 것이다.
        nm = re.search(r"([\d,]+)\s*줄\s*중\s*([\d,]+)\s*줄", cut.group(2))
        if not nm:
            bad.append("`자름: 있음` 인데 `전체 N줄 중 M줄` 이 없다 — 몇 줄을 받았는지 모른다")
        elif not 0 < int(nm.group(2).replace(",", "")) < int(nm.group(1).replace(",", "")):
            bad.append(f"`자름: 있음` 의 줄 수가 맞지 않다 — {nm.group(1)}줄 중 {nm.group(2)}줄")
        else:
            # 담았다는 M 이 diff 절의 실제 줄 수와 맞는지도 본다. 65줄짜리 브리핑이 「5,000줄 중
            # 2,000줄」이라 적어도 통과했다 — 감사자가 받은 근거를 부풀린다(Codex 리뷰). 절 머리 ·
            # 코드 울타리 · 앞뒤 빈 줄은 빼고 세고, 작업트리 몫 같은 소제목 줄만큼은 봐준다.
            got = diff_lines(text)
            m = int(nm.group(2).replace(",", ""))
            if got is not None and abs(got - m) > max(10, m // 50):
                bad.append(f"`자름: 있음` 이 {m}줄을 담았다는데 diff 절은 {got}줄이다 — 받은 근거를 잘못 적었다")

    i = text.find("## diff")
    j = text.find("## 이 브리핑이 담지 않은 것")
    # 변경 줄(+/-)이 없어도 git 이 적는 메타데이터 기록(이름 바꿈 · 모드 · 새 파일 ·
    # 지운 파일 · 이진 파일)이 있으면 빈 것이 아니다. 실행 비트만 바뀐 변경도 운영에서는
    # 무겁다 — 그것만 담은 브리핑을 빈 것으로 버리면 안 된다(Codex 리뷰).
    # 파일 머리(`--- a/…` · `+++ b/…` · `/dev/null`)는 변경 줄이 아니다. 그것만 남은 diff —
    # 중간에 끊긴 브리핑 — 를 채워진 것으로 읽으면 안 된다(Codex 리뷰).
    # 변경 줄은 **헝크(`@@ … @@`) 안에서만** 센다. 맨 `-` 로 시작하는 줄은 마크다운 목록이나
    # 「- git diff 실패: …」 같은 실패 기록일 수 있다 — 그것만 있는 diff 절이 통과했다(Codex 리뷰).
    # 메타데이터는 **짝이 맞아야** 증거다. `old mode 100644` 한 줄에서 끊기면 새 모드를 모른다
    # (Codex 리뷰). 짝 없이도 완결인 것은 새 파일 · 지운 파일 · 이진 파일 표시뿐이다.
    def meta_ok(body):
        has = lambda p: re.search(p, body, re.M)
        return bool(has(r"^(?:new|deleted) file mode |^Binary files ")
                    or (has(r"^old mode ") and has(r"^new mode "))
                    or (has(r"^rename from ") and has(r"^rename to "))
                    or (has(r"^copy from ") and has(r"^copy to ")))
    hunk = (r"^@@ -\d[^\n]*@@[^\n]*\n(?:[ \\][^\n]*\n|\n)*"
            r"(?:\+(?!\+\+ (?:b/|/dev/null))|-(?!-- (?:a/|/dev/null)))")
    if i >= 0 and j > i and not (meta_ok(text[i:j]) or re.search(hunk, text[i:j], re.M)):
        bad.append("diff 절에 헝크 안의 변경 줄(+/-)도 git 메타데이터 기록(이름 바꿈 · 모드 등)도 없다 — 빈 브리핑이다")
    # 헝크는 머리(`@@ -a,b +c,d @@`)가 적은 줄 수만큼 와야 한다. 중간에 끊긴 `-old` 한 줄은
    # 바꿈을 지움으로 읽게 한다(Codex 리뷰). 자른 브리핑(`자름: 있음`)은 마지막 헝크만 봐준다.
    if i >= 0 and j > i:
        broken = short_hunks(text[i:j])
        if cut and cut.group(1) == "있음":
            broken = [h for h, last in broken if not last]
        else:
            broken = [h for h, _ in broken]
        if broken:
            bad.append(f"diff 절의 헝크 {broken[0]} 가 머리가 적은 줄 수보다 짧다 — 끊긴 diff 다")

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
