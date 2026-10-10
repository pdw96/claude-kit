#!/usr/bin/env python3
"""플러그인의 절차 지도 판 — 원본 스킬이 지도를 커밋으로 박았고, 박은 지도가 `vibe-slice/` 를 마지막으로 고친 커밋의
지도인지 본다. 모델도 네트워크도 안 쓴다.

  python3 scripts/verify-map-pin.py      # 인자 없음 — 부른 자리의 git 맨 위를 본다

**왜 있나.** 플러그인은 심는 단계가 없어, 스킬의 링크가 `blob/main/` 이면 대화형 세션은 설치한 판이 아니라 그때의 `main`
지도를 읽는다. 지도만 고친 커밋은 판을 올리지 않으므로 같은 판을 깐 세션이 읽는 날에 따라 다른 지도를 읽는다
(조각 10 요구사항 「문제」 · ADR 0019).

**무엇을 보장하나.** `docs/slices/10-plugin-map-version/design.md` ② 가 든다. 출력의 `[M5]` 같은 번호가 그 보장의
번호다 — 여기 따로 옮겨 적지 않는다. 받는 입력의 닫힌 목록은 같은 설계 ③.

**고치지 않는다.** 다시 박을 커밋은 M5 의 메시지가 찍는다 — 링크는 사람이 고친다(ADR 0019 의 7).

이 검사를 망가뜨린 사본이 자체 시험에서 떨어지는지는 `bite-map-pin.py` 가 본다 — 아래 줄 몇을 글자 그대로 찾아
바꾸므로, 그 줄을 고치면 변조본도 따라 고친다.

표준 라이브러리만 쓴다.
"""
import os
import re
import subprocess
import sys

USAGE = "사용법: verify-map-pin.py   (인자 없음 — 부른 자리의 git 맨 위를 본다)"
PLUGIN = "vibe-slice"
SKILLS = "vibe-slice/skills"
MAP = "docs/procedure.md"
ANY = re.compile(r"github(?:usercontent)?\.com/pdw96/claude-kit")
PIN = re.compile(r"github\.com/pdw96/claude-kit/blob/([0-9a-f]{40})/([^\s)`>\"']+)")


def git(*args):
    # O2 git 이 내는 것은 UTF-8 로 읽는다 — 로케일 인코딩으로 읽으면 한글 경로가 깨지거나 예외로 끝난다.
    p = subprocess.run(["git", *args], capture_output=True, text=True, encoding="utf-8", errors="replace")
    return p.returncode, p.stdout


def blob(rev, path):
    """`rev:path` 의 바이트. 없거나 파일이 아니면 None."""
    if git("cat-file", "-t", f"{rev}:{path}") != (0, "blob\n"):
        return None
    return subprocess.run(["git", "show", f"{rev}:{path}"], capture_output=True).stdout


def links(files):
    """M1 — 파일마다 claude-kit 링크 자리를 다 뽑는다. (파일, 줄, sha, 경로) 와 꼴이 틀린 자리 둘."""
    good, bad = [], []
    for rel in files:
        try:
            with open(rel, encoding="utf-8", errors="replace") as f:
                lines = f.read().splitlines()
        except (OSError, IsADirectoryError):
            continue
        for no, ln in enumerate(lines, 1):
            for m in ANY.finditer(ln):
                p = PIN.match(ln, m.start())
                if p:
                    good.append((rel, no, p.group(1), p.group(2)))
                else:
                    bad.append(f"[M1] {rel}:{no} — `blob/<40 자 소문자 16진>/<경로>` 꼴이 아니다: {ln[m.start():m.start() + 70]}")
    return good, bad


def baseline():
    """M5 의 기준 — (이름, 경로를 받아 바이트를 내는 함수, 제안을 찾을 시작 rev)."""
    last = git("log", "-1", "--format=%H", "HEAD", "--", f"{PLUGIN}/")[1].strip()
    # 고친 커밋이 없으면(`vibe-slice/` 가 아직 커밋되지 않았다) 작업트리가 기준이다 — 빈 rev 의 `:<경로>` 는 인덱스를 읽는다.
    if git("status", "--porcelain", "--", f"{PLUGIN}/")[1].strip() or not last:
        def read(path):
            try:
                with open(path, "rb") as f:
                    return f.read()
            except OSError:
                return None
        return "작업트리", read, "HEAD"
    return last, (lambda path: blob(last, path)), last


def suggest(path, want, start):
    """기준과 같은 내용을 가진 가장 가까운 조상 커밋 — 없으면 None."""
    for c in git("log", "--format=%H", start, "--", path)[1].split():
        if blob(c, path) == want:
            return c
    return None


def judge(files):
    good, bad = links(files)
    name, read, start = baseline()
    for rel, no, sha, path in good:
        where = f"{rel}:{no}"
        if git("cat-file", "-e", f"{sha}^{{commit}}")[0] != 0:
            bad.append(f"[M2] {where} — 박은 커밋 {sha[:7]} 이 레포에 없다")
            continue
        if git("merge-base", "--is-ancestor", sha, "HEAD")[0] != 0:
            bad.append(f"[M3] {where} — 박은 커밋 {sha[:7]} 이 HEAD 이거나 그 조상이 아니다")
            continue
        got = blob(sha, path)
        if got is None:
            bad.append(f"[M4] {where} — 박은 커밋 {sha[:7]} 에 `{path}` 가 파일로 없다")
            continue
        want = read(path)
        if got != want:
            label = "작업트리" if name == "작업트리" else name[:7]
            hint = suggest(path, want, start) if want is not None else None
            if hint:
                fix = f"`{hint}` 를 박아라"
            elif name == "작업트리":
                fix = f"작업트리의 `{path}` 를 먼저 커밋하고 그 커밋을 박아라"
            elif want is None:
                fix = f"기준 {label} 에 `{path}` 가 없다"
            else:
                fix = f"기준 {label} 의 `{path}` 와 같은 내용의 커밋을 찾지 못했다"
            bad.append(f"[M5] {where} — 박은 커밋 {sha[:7]} 의 `{path}` 가 기준({label})과 다르다 — {fix}")

    # M6 스킬 폴더마다 SKILL.md 에 지도를 박은 링크가 하나 이상 — 꼴을 못 읽어 아무것도 안 보고 지나가지 않게
    skills = sorted(d for d in os.listdir(SKILLS) if os.path.isdir(os.path.join(SKILLS, d))) if os.path.isdir(SKILLS) else []
    if not skills:
        bad.append(f"[M6] {SKILLS}/ — 스킬 폴더가 없다")
    for d in skills:
        skill = f"{SKILLS}/{d}/SKILL.md"
        if not any(rel == skill and path == MAP for rel, _, _, path in good):
            bad.append(f"[M6] {skill} — `{MAP}` 를 M1 의 꼴로 박은 링크가 없다")
    return good, bad, name


def main(argv):
    if argv:
        print(USAGE, file=sys.stderr)
        return 2
    rc, top = git("rev-parse", "--show-toplevel")
    if rc != 0 or git("rev-parse", "--verify", "--quiet", "HEAD")[0] != 0:
        print("FAIL [R1] . — git 레포가 아니거나 HEAD 가 없다")
        return 1
    os.chdir(top.strip())
    if git("rev-parse", "--is-shallow-repository")[1].strip() == "true":
        print("FAIL [R2] . — 얕은 클론이다 — 역사가 없으면 조상을 가리지 못한다")
        return 1
    if not os.path.isdir(PLUGIN):
        print(f"FAIL [R3] {PLUGIN}/ — 맨 위에 없다")
        return 1

    files = [p for p in git("ls-files", "-co", "--exclude-standard", "--", f"{PLUGIN}/")[1].splitlines() if p]
    good, bad, name = judge(sorted(set(files)))
    if bad:
        for b in bad:
            print(f"FAIL {b}")
        return 1
    pins = ", ".join(sorted({sha[:7] for _, _, sha, _ in good}))
    print(f"PASS 절차 지도 판 — 링크 {len(good)} · 박은 커밋 {pins} · 기준 {name if name == '작업트리' else name[:7]}")
    return 0


if __name__ == "__main__":
    # O2 출력은 콘솔 인코딩과 상관없이 UTF-8 이다 — cp949 콘솔에서 `—` 를 찍다 예외로 끝나지 않게.
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv[1:]))
