#!/usr/bin/env python3
"""살아 있는 문서와 스크립트에 **적힌 수**가 그 수의 원천과 같은지 본다.

  python3 scripts/verify-counts.py            # 이 저장소
  python3 scripts/verify-counts.py <루트>     # 다른 트리 — bite-gates.sh 가 변조본으로 쓴다

**왜 있나.** `audit-internal` 이 「적힌 것과 있는 것이 같다」를 세 회차 연달아 깨진 것으로 냈다 — README 의 「케이스
스물다섯」은 폴더가 스물여섯이 된 뒤에도 남았고, 주석의 「지금 4,810」은 스냅숏이 바뀐 뒤에도 남았고, 끝 줄의 「변조본 둘」은
견준 수를 찍게 한 뒤에도 남았다(조각 42 · ADR 0055). 세션과 감사자는 적힌 수를 사실로 읽는다.

**무엇을 보나(조각 42 설계 ② · 끝 「PR C 에서 정한 것」).**
  - D 닻 — 아래 `ANCHORS` 의 닫힌 목록. 닻 하나는 (파일 · 수 하나를 잡는 꼴 · 그 꼴이 그 파일에 나오는 횟수 · 원천 이름)이다.
    꼴의 `{N}` 이 수 낱말 하나를 잡고, 그 바로 뒤에 적은 토씨는 짝(이/가 · 을/를 …)도 받는다. 나온 횟수가 적은 횟수와
    다르면 D2(닻이 낡았다), 잡은 수가 원천의 값과 다르면 D1
  - S 원천 — 아래 `SOURCES` 의 닫힌 이름 목록. 셈 종류는 셋 — 파일 수(`files`) · 코드의 목록 길이와 상수(`items` · `const`) ·
    표의 줄 수(`rows`). 셈마다 값을 그 트리의 파일에서 다시 센다 — 닻은 수를 들지 않는다. 0 이거나 읽을 자리를 못 찾으면 S1
  - L 수 낱말 — 고유어 수(하나 ~ 아홉 · 열 · 스물 · … 과 그 합성, 매김꼴 한 · 두 · 세 · 네 · 스무)와 아라비아 수를 읽는다.
    읽지 못하면 L1 — 0 으로 읽어 지나가지 않는다
  - E 끝 줄 — `bite-gates.sh` · `bite-*.py` · `test-*.py` 의 끝 줄(조각 42 설계 끝 「PR B 에서 정한 것」의 꼴)에 견준 값 밖의 수
    낱말이 있으면 E1. 닻이 잡은 한글 수 낱말은 뺀다 — 아라비아 수는 닻이 잡아도 E1 이다(끝 줄의 수는 견준 값으로 찍는다).
    훑을 파일이 없거나 끝 줄을 하나도 못 찾은 파일이 있으면 E2(읽는 법이 낡았다)
  - U 같은 원천 훑기(조각 46 · ADR 0059) — 아래 `NOUNS` 가 원천마다 그 원천을 가리키는 명사를 든다. 살아 있는 파일(`SCAN_*` —
    `.git` 이 있으면 git 이 드는 파일, 없으면 폴더를 걸어서. 브리핑 · 감사 기록의 작업본 `.claude/` 셋은 뺀다)에서
    명사 바로 앞이나 뒤의 수 낱말이 그 원천의 지금 값과 같고, 닻이 잡은 자리도 원천을 읽는 자리(`const`)도 `EXEMPT` 의 예외도
    아니면 U1(닻 없는 같은 원천 문장). 예외의 꼴이 적은 횟수만큼 나오지 않거나 예외의 파일을 못 읽으면 U2, 원천 목록과 명사
    목록(`NOUNS` · `NO_NOUN`)의 이름이 갈리거나 겹치거나 명사 목록이 비면 U3, 훑을 파일이 없으면 U4
실패 줄은 `FAIL [<ID>] <파일>:<줄> …` 이다(ID 는 실패의 갈래마다 — 닻마다가 아니다). 원천 · 파일 하나에 걸린 실패는 줄 없이
`<파일>` 만 든다. ID 마다 변조본이 있는지는 `bite-gates.sh` 의 이 검사 절이 이 파일의 `r.fail("…` 에서 ID 를 읽어 견준다.

**보지 않는 것.** 닻 없는 수 가운데 원천의 지금 값과 다른 수와 명사 옆이 아닌 수(`CHECKLIST.md` 와 리뷰가 본다) · 기록 넷(`docs/slices/` · `docs/adr/` ·
`docs/eval-log/` · `docs/audit/`) · 측정과 지난 일의 수 · 문장의 뜻(닻은 「이 문장의 이 수는 이 원천」이라는 판단을 고정할 뿐이다).
수를 새로 적거나 원천을 바꾸는 PR 은 이 목록을 함께 고친다 — 문장을 지우거나 고쳐 꼴이 안 맞으면 D2 로 떨어진다. 원천을
더하면 그 명사도(U3).

`run-evals.sh` 가 부르지 않아 수트 지문 밖이다. 표준 라이브러리만 쓴다.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
USAGE = "사용법: verify-counts.py [<루트>]"

# ── L 수 낱말 ───────────────────────────────────────────────────────────────────────────────────────────
UNITS = {"하나": 1, "둘": 2, "셋": 3, "넷": 4, "다섯": 5, "여섯": 6, "일곱": 7, "여덟": 8, "아홉": 9,
         "한": 1, "두": 2, "세": 3, "네": 4}
TENS = {"열": 10, "스물": 20, "서른": 30, "마흔": 40, "쉰": 50, "예순": 60, "일흔": 70, "여든": 80, "아흔": 90}
ALONE = {"스무": 20}  # 매김꼴 — 뒤에 하나치가 붙지 않는다
SYL = "".join(sorted(set("".join([*UNITS, *TENS, *ALONE]))))
# 꼴의 {N} — 한글 · 숫자에 붙지 않은 아라비아 수, 또는 수 낱말에 쓰이는 글자로만 된 한 덩이(길게 잡고 꼴의 뒤 글자에 맞춰
# 물린다). 읽을 수 있는지는 word() 가 가른다(L1)
NUM = rf"(?<![가-힣A-Za-z0-9.,_′-])([0-9][0-9,]*(?:\.[0-9]+)?|[{SYL}]+)"
PARTICLES = ("", "이", "가", "을", "를", "은", "는", "의", "과", "와", "만", "도", "로", "으로", "까지", "뿐", "씩", "째",
             "에", "에서", "이다", "다", "이고", "이며", "이면", "이나", "쯤", "보다", "이라", "에도", "뿐이다", "만큼")


# 받침에 따라 갈리는 토씨 — 꼴에서 {N} 바로 뒤에 적은 토씨는 짝도 받는다(수를 고치면 토씨도 바뀌므로)
PAIRED = (("으로", "(?:으로|로)"), ("이", "[이가]"), ("가", "[이가]"), ("을", "[을를]"), ("를", "[을를]"),
          ("은", "[은는]"), ("는", "[은는]"), ("과", "[과와]"), ("와", "[과와]"))


def compile_anchor(pat):
    """닻의 꼴을 정규식으로 — {N} 을 수 낱말 하나로, 그 바로 뒤의 토씨를 짝까지로."""
    out, rest = [], pat
    while "{N}" in rest:
        head, rest = rest.split("{N}", 1)
        out += [head, NUM]
        for k, v in PAIRED:
            if rest.startswith(k):
                out.append(v)
                rest = rest[len(k):]
                break
    return "".join(out) + rest


def word(s):
    """수 낱말 하나의 값. 못 읽으면 None."""
    if re.fullmatch(r"[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+", s):
        return int(s.replace(",", ""))
    if re.fullmatch(r"[0-9]+\.[0-9]+", s):
        return float(s)
    if s in ALONE:
        return ALONE[s]
    for t, tv in [("", 0), *TENS.items()]:
        if s.startswith(t):
            rest = s[len(t):]
            if rest == "" and tv:
                return tv
            if rest in UNITS:
                return tv + UNITS[rest]
    return None


def number_token(tok):
    """한글 덩이가 수 낱말(과 토씨)인가 — 그 값, 아니면 None. 끝 줄 훑기(E)가 쓴다."""
    for p in sorted(PARTICLES, key=len, reverse=True):
        if tok.endswith(p) and len(tok) > len(p):
            v = word(tok[:len(tok) - len(p)] if p else tok)
            if v is not None:
                return v
    return None


# ── S 원천 ─────────────────────────────────────────────────────────────────────────────────────────────
class Uncountable(Exception):
    pass


def read(root, rel):
    p = root / rel
    try:
        return p.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as e:
        raise Uncountable(f"{rel} 을 못 읽었다 — {e.__class__.__name__}") from None


def between(text, rel, start, end):
    """start 줄 다음부터 end 줄 앞까지. 둘 다 정규식이고 꼭 한 번 나와야 한다."""
    s = [m.end() for m in re.finditer(start, text, re.M)]
    if len(s) != 1:
        raise Uncountable(f"{rel} 에서 여는 자리 /{start}/ 가 {len(s)} 번이다 — 한 번이어야 한다")
    m = re.compile(end, re.M).search(text, s[0])
    if not m:
        raise Uncountable(f"{rel} 에서 닫는 자리 /{end}/ 를 못 찾았다")
    return text[s[0]:m.start()]


def count(root, src):
    kind, rel = src[0], src[1]
    if kind == "files":  # ("files", 글롭, 빼는 정규식 | None)
        out = [p for p in root.glob(rel) if p.is_file() and not (src[2] and re.search(src[2], p.name))]
        return len(out)
    text = read(root, rel)
    if kind == "items":  # ("items", 파일, 여는 자리, 닫는 자리, 셀 꼴) — 그 사이에서 셀 꼴이 나온 수(목록의 길이)
        return len(re.findall(src[4], between(text, rel, src[2], src[3]), re.M))
    if kind == "const":  # ("const", 파일, 수 하나를 잡는 정규식) — 꼭 한 번
        found = re.findall(src[2], text, re.M)
        if len(found) != 1:
            raise Uncountable(f"{rel} 에서 /{src[2]}/ 가 {len(found)} 번이다 — 한 번이어야 한다")
        v = word(found[0])
        if v is None:
            raise Uncountable(f"{rel} 의 {found[0]!r} 를 수로 못 읽었다")
        return v
    if kind == "rows":  # ("rows", 파일, 머리 줄) — 그 머리 뒤 첫 표의 몸 줄 수(머리 줄 · 구분 줄을 뺀다)
        body = between(text, rel, src[2], r"^#{1,6} |\Z")
        lines = body.split("\n")
        i = next((k for k, l in enumerate(lines) if l.startswith("|")), None)
        if i is None or i + 1 >= len(lines) or not re.match(r"^\|[\s:|-]+\|$", lines[i + 1]):
            raise Uncountable(f"{rel} 의 /{src[2]}/ 아래에 표가 없다")
        n = 0
        for l in lines[i + 2:]:
            if not l.startswith("|"):
                break
            n += 1
        return n
    raise Uncountable(f"모르는 셈 종류 {kind}")


# 원천의 닫힌 이름 목록(설계 ② S). 셈 종류는 셋 — 파일 수 · 코드의 목록 길이와 상수 · 표의 줄 수.
SOURCES = {
    # 파일 수
    "감사자": ("files", "vibe-audit/agents/audit-*.md", None),
    "틀": ("files", "vibe-slice/skills/slice-docs/templates/*.md", r"^nc-ledger"),
    "대장 틀": ("files", "vibe-slice/skills/slice-docs/templates/nc-ledger*.md", None),
    "케이스": ("files", "vibe-audit/evals/*/case.yaml", None),
    "트리거 케이스": ("files", "vibe-audit/evals/route-*/case.yaml", None),
    "판정 케이스": ("files", "vibe-audit/evals/[!r]*/case.yaml", None),
    "cycle-continuity 그레이더": ("files", "vibe-audit/evals/cycle-continuity/graders/*.md", None),
    "플러그인": ("files", "*/.claude-plugin/plugin.json", None),
    "매니페스트": ("files", "**/.claude-plugin/*.json", None),
    "조각 문서 검사": ("files", "vibe-slice/skills/slice-docs/scripts/*.py", None),
    "변조 시험 py": ("files", "scripts/bite-*.py", None),
    # 코드의 목록 길이와 상수
    "늘 도는 검사": ("items", "scripts/gates.sh", r"^checks\(\) \{$", r"^\}$", r"^\s*python3 scripts/"),
    "validate 줄": ("items", "scripts/gates.sh", r"^checks\(\) \{$", r"^\}$", r"^\s*claude plugin validate "),
    "변조 시험": ("items", "scripts/gates.sh", r"^bites\(\) \{$", r"^\}$", r"^\s*(?:python3 scripts/bite-|\./scripts/bite-)"),
    "게이트": ("items", "scripts/gates.sh", r"^checks\(\) \{$", r"^usage\(\)", r"^\s*(?:python3 scripts/|\./scripts/)"),
    "고정 목록 CHECKS": ("items", "scripts/test-gates.py", r"^CHECKS = \($", r"^\)$", r'"[^"]+"'),
    "고정 목록": ("items", "scripts/test-gates.py", r"^CHECKS = \($", r"^ALL = ", r'"[^"]+"'),
    "대조군 KEPT": ("const", "scripts/test-gates.py", r"^KEPT = ([0-9]+)"),
    "감사자 tools": ("items", "vibe-audit/agents/audit-secrets.md", r"^tools: \[", r"\]$", r'"[A-Za-z]+"'),
    "적기 조건 스텝": ("items", "scripts/verify-eval-gate.py", r"^SPEC = \[$", r"^\]$", r'^    \("T[0-9]+", '),
    "머리의 키": ("items", "scripts/verify-eval-gate.py", r"^HEAD_KEYS = \[", r"\]", r'"[a-z-]+"'),
    "gate 잡의 키": ("items", "scripts/verify-eval-gate.py", r"^GATE_KEYS = \[", r"\]", r'"[a-z-]+"'),
    "route 문턱": ("const", ".github/workflows/eval.yml", r"--case 'route-\*' .*--threshold ([0-9.]+) "),
    "전수 문턱": ("const", ".github/workflows/eval.yml", r"run-evals\.sh --ablation none --runs [0-9]+ --threshold ([0-9.]+) "),
    "CI 회차": ("const", ".github/workflows/eval.yml", r"--case 'route-\*' --ablation none --runs ([0-9]+) "),
    "러너 동시성": ("const", "scripts/run-evals.sh", r"CONC=\(-j ([0-9]+)\)"),
    "후보 대장 변조": ("const", "scripts/bite-gates.sh", r'^sopen "verify-feedback\.py"\n(?:.*\n)*?sclose ([0-9]+) '),
    "비교기 변조": ("const", "scripts/bite-gates.sh", r'^sopen "test-compare-copies\.py"\n(?:.*\n)*?sclose ([0-9]+) '),
    "칸의 절": ("items", "docs/procedure.md", r"^## 문서의 모양$", r"^## 사례$", r"^### .+의 칸$"),
    "감사자 고르는 원천": ("items", "docs/procedure.md", r"^- \*\*어느 감사자\*\*", r"^- \*\*돌리는 법\*\*", r"^  - \*\*"),
    # 표의 줄 수
    "단계": ("rows", "docs/procedure.md", r"^## 일곱 단계$"),
    "만나는 자리": ("rows", "docs/procedure.md", r"^## 두 층$"),
    "문서 종류": ("rows", "docs/procedure.md", r"^### 살아 있는 문서와 기록$"),
    "의도 칸": ("rows", "docs/procedure.md", r"^### 의도 문서의 칸$"),
    "마스터플랜 칸": ("rows", "docs/procedure.md", r"^### 마스터플랜의 칸$"),
    "CLAUDE.md 칸": ("rows", "docs/procedure.md", r"^### CLAUDE\.md 의 칸$"),
    "Profile 칸": ("rows", "docs/procedure.md", r"^### Profile\.md 의 칸$"),
    "요구사항 칸": ("rows", "docs/procedure.md", r"^### 요구사항 문서의 칸$"),
    "설계 칸": ("rows", "docs/procedure.md", r"^### 설계 문서의 칸$"),
    "열린 버그": ("rows", "README.md", r"^## 설치 — 경로가 둘인 이유$"),
}


# ── D 닻 ───────────────────────────────────────────────────────────────────────────────────────────────
# (파일, 꼴, 횟수, 원천). 꼴의 {N} 이 수 하나를 잡는다 — 꼴은 정규식이고 re.M 으로 파일 전체에서 찾는다.
ANCHORS = [
    # README.md
    ('README.md', r'감사자 {N}(?=종|을|은)', 3, '감사자'),
    ('README.md', r'문서 틀 {N} —', 1, '틀'),
    ('README.md', r'열린 버그 {N}을', 1, '열린 버그'),
    # .claude-plugin/marketplace.json
    ('.claude-plugin/marketplace.json', r'감사자 {N}종', 1, '감사자'),
    ('.claude-plugin/marketplace.json', r'문서 틀 {N}\(', 1, '틀'),
    # vibe-audit/.claude-plugin/plugin.json · vibe-slice/.claude-plugin/plugin.json
    ('vibe-audit/.claude-plugin/plugin.json', r'감사자 {N}종', 1, '감사자'),
    ('vibe-slice/.claude-plugin/plugin.json', r'문서 틀 {N}\(', 1, '틀'),
    # INTENT.md
    ('INTENT.md', r'감사자 {N} ·', 1, '감사자'),
    # CLAUDE.md
    ('CLAUDE.md', r'읽기 전용 {N}\.', 1, '감사자 tools'),
    ('CLAUDE.md', r'「…의 칸」 {N} 절', 1, '칸의 절'),
    # CHECKLIST.md
    ('CHECKLIST.md', r'틀 {N}도', 1, '틀'),
    ('CHECKLIST.md', r'검사 {N}\(`scripts/verify-docs.py`', 1, '조각 문서 검사'),
    # docs/architecture.md
    ('docs/architecture.md', r'감사자 {N} \|', 1, '감사자'),
    ('docs/architecture.md', r'공통 절은 {N}이', 1, '감사자'),
    ('docs/architecture.md', r'설계 틀 {N}\(', 1, '틀'),
    ('docs/architecture.md', r'대장의 틀 {N}\(', 1, '대장 틀'),
    ('docs/architecture.md', r'그리고 검사 {N}\(`scripts/`', 1, '조각 문서 검사'),
    ('docs/architecture.md', r'매니페스트 {N} \|', 1, '매니페스트'),
    ('docs/architecture.md', r'마켓플레이스와 플러그인 {N}\.', 1, '플러그인'),
    ('docs/architecture.md', r'자체 시험 {N}\(`checks`\)', 2, '늘 도는 검사'),
    ('docs/architecture.md', r'변조 시험 {N}(?=\(`bites`\)|은 건너뛰었다|이 실제로)', 4, '변조 시험'),
    ('docs/architecture.md', r'스킬의 검사 {N}은', 1, '조각 문서 검사'),
    ('docs/architecture.md', r'감사자 {N} · 브리핑', 1, '감사자'),
    ('docs/architecture.md', r'파일 {N}에 있다', 1, '변조 시험'),
    ('docs/architecture.md', r'{N} 다 수트 지문 밖', 1, '변조 시험'),
    ('docs/architecture.md', r'「{N} 통과 ·', 1, '늘 도는 검사'),
    ('docs/architecture.md', r'늘 {N}이고', 1, '게이트'),
    ('docs/architecture.md', r'그 {N}만 빼는지', 1, '변조 시험'),
    ('docs/architecture.md', r'^{N}을 돌리고', 1, '게이트'),
    ('docs/architecture.md', r'첫 {N}\n스텝', 1, '적기 조건 스텝'),
    ('docs/architecture.md', r'{N} 검사의 실물', 1, '조각 문서 검사'),
    ('docs/architecture.md', r'틀 {N}을 원천으로', 1, '틀'),
    # docs/procedure.md
    ('docs/procedure.md', r'틀 {N}을 원천으로', 1, '틀'),
    ('docs/procedure.md', r'틀 {N}이고', 1, '틀'),
    ('docs/procedure.md', r'{N} 단계(?=」|를 지난다|$)', 4, '단계'),
    ('docs/procedure.md', r'두 층은 {N} 자리에서', 1, '만나는 자리'),
    ('docs/procedure.md', r'\| {N} 칸이 다 있고', 1, '요구사항 칸'),
    ('docs/procedure.md', r'원천 {N}에서 고르고', 1, '감사자 고르는 원천'),
    ('docs/procedure.md', r'문서는 {N} 중 하나다', 1, '문서 종류'),
    ('docs/procedure.md', r'주인이 아니다\. {N} 절 다 필수이고', 1, '의도 칸'),
    ('docs/procedure.md', r'\(ADR 0007\)\.\n{N} 절 다 필수이고', 1, '마스터플랜 칸'),
    ('docs/procedure.md', r'저자의 결정만 든다\. {N} 절 다 필수이고', 1, 'CLAUDE.md 칸'),
    ('docs/procedure.md', r'ADR\. {N} 절은 필수이고', 1, '요구사항 칸'),
    ('docs/procedure.md', r'^{N} 다 \*\*필수\*\*다', 1, '설계 칸'),
    ('docs/procedure.md', r'{N} 검사는 `vibe-slice`', 1, '조각 문서 검사'),
    # docs/schema.md
    ('docs/schema.md', r'감사자 {N}에 다 있으면', 1, '감사자'),
    ('docs/schema.md', r'변조한 대장 {N}와', 1, '후보 대장 변조'),
    ('docs/schema.md', r'비교기 변조 {N}이', 1, '비교기 변조'),
    # scripts/gates.sh
    ('scripts/gates.sh', r'# {N} — 로컬은 늘 이것', 1, '게이트'),
    ('scripts/gates.sh', r'(?<=CI 만 — ){N}만 돌리고', 1, '늘 도는 검사'),
    ('scripts/gates.sh', r'자체 시험 {N}(?=\(와|, `claude)', 2, '늘 도는 검사'),
    ('scripts/gates.sh', r'`claude plugin validate` {N}(?=\)|\.)', 2, 'validate 줄'),
    ('scripts/gates.sh', r'변조 시험 {N}(?=은|까지|\.|을)', 6, '변조 시험'),
    ('scripts/gates.sh', r'이 파일이 부르는 {N}에', 1, '변조 시험'),
    ('scripts/gates.sh', r'--skip-bite 는 {N}만 빼고', 1, '변조 시험'),
    ('scripts/gates.sh', r'첫 {N} 스텝', 1, '적기 조건 스텝'),
    ('scripts/gates.sh', r'echo "{N} 통과', 1, '늘 도는 검사'),
    ('scripts/gates.sh', r'echo "{N} 다 통과', 1, '게이트'),
    ('scripts/gates.sh', r'심은 {N} 검사가 대상에서', 1, '조각 문서 검사'),
    # scripts/test-gates.py
    ('scripts/test-gates.py', r'변조 시험 {N}(?=까지|이 돈다|은 다른|은 이 파일|은 건너뛰었다)', 5, '변조 시험'),
    ('scripts/test-gates.py', r'그 {N}만 빼고', 1, '변조 시험'),
    ('scripts/test-gates.py', r'`CHECKS` 가 다 돌고, {N}은', 1, '변조 시험'),
    ('scripts/test-gates.py', r'목록의 {N}마다', 1, '고정 목록'),
    ('scripts/test-gates.py', r'`CHECKS` 의 {N}마다', 1, '고정 목록 CHECKS'),
    ('scripts/test-gates.py', r'대조군 {N}이 다 돌았는지', 1, '대조군 KEPT'),
    ('scripts/test-gates.py', r'늘 도는 {N}\(조각 38', 1, '고정 목록 CHECKS'),
    ('scripts/test-gates.py', r'이 {N}뿐이다', 1, '변조 시험'),
    ('scripts/test-gates.py', r'--skip-bite — {N}만 빠진다', 1, '변조 시험'),
    ('scripts/test-gates.py', r'{N}(?=이 맨 뒤|을 이름으로 든다)', 2, '변조 시험'),
    # scripts/bite-gates.sh
    ('scripts/bite-gates.sh', r'변조 시험 {N}(?=만 있|뿐|을 건너뛴다)', 6, '변조 시험'),
    ('scripts/bite-gates.sh', r'변조 시험 {N}만 든다', 1, '변조 시험'),
    ('scripts/bite-gates.sh', r"keep '\^PASS 감사자 {N}개'", 1, '감사자'),
    ('scripts/bite-gates.sh', r'「{N} 통과」', 1, '늘 도는 검사'),
    ('scripts/bite-gates.sh', r'원본 {N} 가운데', 1, '감사자'),
    ('scripts/bite-gates.sh', r'# G — {N} 스텝 밖', 1, '적기 조건 스텝'),
    ('scripts/bite-gates.sh', r'"G {N} 뒤 스텝', 1, '적기 조건 스텝'),
    # scripts/gate-key.py
    ('scripts/gate-key.py', r'변조 시험 {N}\(`bite-\*\.py` ', 1, '변조 시험'),
    ('scripts/gate-key.py', r'`bite-\*\.py` {N} ·', 1, '변조 시험 py'),
    # scripts/verify-eval-gate.py
    ('scripts/verify-eval-gate.py', r'변조 시험 {N}까지', 1, '변조 시험'),
    ('scripts/verify-eval-gate.py', r'{N}(?=으로 시작| 스텝)', 7, '적기 조건 스텝'),
    ('scripts/verify-eval-gate.py', r'머리의 키 {N} ·', 1, '머리의 키'),
    ('scripts/verify-eval-gate.py', r'gate 잡의 키 {N} ·', 1, 'gate 잡의 키'),
    # .github/workflows/eval.yml
    ('.github/workflows/eval.yml', r'변조 시험 {N}(?=을 건너뛴다)', 2, '변조 시험'),
    ('.github/workflows/eval.yml', r'# {N}(?=은 건너뛰는 실행에서도)', 1, '늘 도는 검사'),
    ('.github/workflows/eval.yml', r'남기고 {N}만 돌린다', 1, '늘 도는 검사'),
    ('.github/workflows/eval.yml', r'{N} 스텝의 판정', 1, '적기 조건 스텝'),
    ('.github/workflows/eval.yml', r'`route-\*` {N} ×', 2, '트리거 케이스'),
    ('.github/workflows/eval.yml', r'`route-\*` 열 × {N}회', 2, 'CI 회차'),
    ('.github/workflows/eval.yml', r'러너 기본 -j {N}', 2, '러너 동시성'),
    ('.github/workflows/eval.yml', r'케이스 {N}이다', 1, '케이스'),
    ('.github/workflows/eval.yml', r'route 는 문턱 {N} —', 1, 'route 문턱'),
    ('.github/workflows/eval.yml', r'— {N} 회차 \*\*전부', 1, 'CI 회차'),
    ('.github/workflows/eval.yml', r'심판이\n.*갈리므로 {N} 을 둔다', 1, '전수 문턱'),
    # scripts/run-evals.sh
    ('scripts/run-evals.sh', r'그레이더가\n# {N}이라', 1, 'cycle-continuity 그레이더'),
    ('scripts/run-evals.sh', r'^# {N}으로 두는 이유', 1, '러너 동시성'),
    ('scripts/run-evals.sh', r'전수 문턱 {N} 을', 1, '전수 문턱'),
    ('scripts/run-evals.sh', r'전수의 {N} 이 봐주려는', 1, '전수 문턱'),
    # vibe-audit/agents/audit-contract.md
    ('vibe-audit/agents/audit-contract.md', r'\*\*{N} 중 누구의', 2, '감사자'),
    # vibe-audit/agents/audit-data.md
    ('vibe-audit/agents/audit-data.md', r'\*\*{N} 중 누구의', 2, '감사자'),
    # vibe-audit/agents/audit-internal.md
    ('vibe-audit/agents/audit-internal.md', r'\*\*{N} 중 누구의', 2, '감사자'),
    # vibe-audit/agents/audit-ops.md
    ('vibe-audit/agents/audit-ops.md', r'\*\*{N} 중 누구의', 2, '감사자'),
    # vibe-audit/agents/audit-quality.md
    ('vibe-audit/agents/audit-quality.md', r'\*\*{N} 중 누구의', 2, '감사자'),
    # vibe-audit/agents/audit-secrets.md
    ('vibe-audit/agents/audit-secrets.md', r'\*\*{N} 중 누구의', 2, '감사자'),
    # vibe-audit/README.md
    ('vibe-audit/README.md', r'^{N}이 보는 범위', 1, '감사자'),
    ('vibe-audit/README.md', r'{N}을 한꺼번에', 1, '감사자'),
    ('vibe-audit/README.md', r'케이스 {N}이 재는 것은', 1, '케이스'),
    ('vibe-audit/README.md', r'\| 판정 \| {N} \|', 1, '판정 케이스'),
    ('vibe-audit/README.md', r'\| 트리거 \| {N} \|', 1, '트리거 케이스'),
    ('vibe-audit/README.md', r'인자 없이 {N}을 다', 1, '케이스'),
    ('vibe-audit/README.md', r'^{N}만 문턱', 1, '트리거 케이스'),
    ('vibe-audit/README.md', r'^열만 문턱 {N} 으로', 1, 'route 문턱'),
    ('vibe-audit/README.md', r'로 문턱 {N} 에서', 1, '전수 문턱'),
    ('vibe-audit/README.md', r'감사자 {N}종', 2, '감사자'),
    # vibe-audit/evals/README.md
    ('vibe-audit/evals/README.md', r'없으면 {N}을 전부', 1, '감사자'),
    # vibe-slice/skills/slice-docs/templates/claude-md.md
    ('vibe-slice/skills/slice-docs/templates/claude-md.md', r'{N} 제목은 글자 그대로', 1, 'CLAUDE.md 칸'),
    # vibe-slice/skills/slice-docs/templates/intent.md
    ('vibe-slice/skills/slice-docs/templates/intent.md', r'{N} 제목은 글자 그대로', 1, '의도 칸'),
    # vibe-slice/skills/slice-docs/templates/master-plan.md
    ('vibe-slice/skills/slice-docs/templates/master-plan.md', r'{N} 제목은 글자 그대로', 1, '마스터플랜 칸'),
    # vibe-slice/skills/slice-docs/templates/profile.md
    ('vibe-slice/skills/slice-docs/templates/profile.md', r'{N} 제목은 글자 그대로', 1, 'Profile 칸'),
    # vibe-slice/skills/slice-docs/templates/design.md
    ('vibe-slice/skills/slice-docs/templates/design.md', r'{N} 제목은 글자 그대로', 1, '설계 칸'),
    # vibe-slice/skills/slice-docs/templates/requirements.md
    ('vibe-slice/skills/slice-docs/templates/requirements.md', r'{N} 제목은 글자 그대로', 1, '요구사항 칸'),
    # vibe-slice/skills/slice-docs/SKILL.md
    ('vibe-slice/skills/slice-docs/SKILL.md', r'틀의 {N} 절을', 1, 'CLAUDE.md 칸'),
    # vibe-slice/skills/slice-docs/scripts/verify-docs.py
    ('vibe-slice/skills/slice-docs/scripts/verify-docs.py', r'틀 {N}(?=$|이다)', 2, '틀'),
    ('vibe-slice/skills/slice-docs/scripts/verify-docs.py', r'찾는 {N} 절 이름', 1, '칸의 절'),
    # scripts/test-verify-docs.py
    ('scripts/test-verify-docs.py', r'틀 {N}을 둔다', 1, '틀'),
    ('scripts/test-verify-docs.py', r'틀 {N}으로 세운', 1, '틀'),
    # scripts/sync-agents.sh
    ('scripts/sync-agents.sh', r'감사자 {N}과 브리핑', 1, '감사자'),
    ('scripts/sync-agents.sh', r'README 의 이슈 {N}\)', 1, '열린 버그'),
    ('scripts/sync-agents.sh', r'^{N} 다 \\`tools: \[', 1, '감사자'),
    # scripts/sync-slice.sh
    ('scripts/sync-slice.sh', r'README 의 이슈 {N}\)', 1, '열린 버그'),
    # scripts/test-sync-slice.py
    ('scripts/test-sync-slice.py', r'slice-docs/scripts/ 의 {N} 검사가 원본과', 1, '조각 문서 검사'),
    ('scripts/test-sync-slice.py', r'심은 {N} 검사가 대상 레포에서', 1, '조각 문서 검사'),
    ('scripts/test-sync-slice.py', r'심은 틀 {N}을', 1, '대장 틀'),
    # scripts/verify-copy.py
    ('scripts/verify-copy.py', r'감사자 {N}만 둔다', 1, '감사자'),
    ('scripts/verify-copy.py', r'들어가 {N}이 다르므로', 1, '감사자'),
    ('scripts/verify-copy.py', r'PASS 감사자 {N}개', 1, '감사자'),
    # scripts/verify-evals.py
    ('scripts/verify-evals.py', r'{N}을 전부 띄우는', 2, '감사자'),
    # scripts/budget-breakdown.py
    ('scripts/budget-breakdown.py', r'안 주면 {N} 전부', 1, '감사자'),
]


# ── U 같은 원천 훑기 ───────────────────────────────────────────────────────────────────────────────────
# 원천마다 그 원천을 가리키는 명사(조각 46 설계 ② U · ADR 0059). 명사는 정규식이다 — `{N}` 이 없으면 명사 바로 앞이나 바로
# 뒤(빈칸 하나)의 수 낱말을, `{N}` 이 있으면 그 꼴만 본다. 그 수가 그 원천의 지금 값과 같고 닻이 잡은 자리가 아니면 U1 이다.
# 명사를 둘 수 없는 원천은 NO_NOUN 에 까닭과 함께 둔다 — 이름이 없어서 빠지는 원천은 없다(U3).
NOUNS = {
    # 파일 수
    "감사자": [r"감사자"],
    "틀": [r"틀"],
    "대장 틀": [r"틀"],
    "케이스": [r"케이스"],
    "트리거 케이스": [r"트리거"],
    "판정 케이스": [r"판정"],
    "cycle-continuity 그레이더": [r"그레이더"],
    "플러그인": [r"플러그인"],
    "매니페스트": [r"매니페스트"],
    "조각 문서 검사": [r"검사"],
    "변조 시험 py": [r"`bite-\*\.py`"],
    # 코드의 목록 길이와 상수
    "늘 도는 검사": [r"검사", r"자체 시험"],
    "validate 줄": [r"`claude plugin validate`"],
    "변조 시험": [r"변조 시험"],
    "게이트": [r"검사"],
    "고정 목록 CHECKS": [r"`CHECKS` 의"],
    "고정 목록": [r"목록의"],
    "대조군 KEPT": [r"대조군"],
    "감사자 tools": [r"읽기 전용"],
    "적기 조건 스텝": [r"스텝"],
    "머리의 키": [r"머리의 키"],
    "gate 잡의 키": [r"gate 잡의 키"],
    "route 문턱": [r"문턱"],
    "전수 문턱": [r"문턱"],
    "러너 동시성": [r"-j"],
    "후보 대장 변조": [r"변조한 대장"],
    "비교기 변조": [r"비교기 변조"],
    "칸의 절": [r"{N} 절"],
    "감사자 고르는 원천": [r"원천"],
    # 표의 줄 수
    "단계": [r"단계"],
    "만나는 자리": [r"{N} 자리에서"],
    "문서 종류": [r"문서는 {N}"],
    "의도 칸": [r"{N} 절", r"{N} 제목은"],
    "마스터플랜 칸": [r"{N} 절", r"{N} 제목은"],
    "CLAUDE.md 칸": [r"{N} 절", r"{N} 제목은"],
    "Profile 칸": [r"{N} 절", r"{N} 제목은"],
    "요구사항 칸": [r"{N} 절", r"{N} 제목은", r"{N} 칸이"],
    "설계 칸": [r"{N} 절", r"{N} 제목은"],
    "열린 버그": [r"버그", r"이슈"],
}
NO_NOUN = {
    "CI 회차": "그 수를 드는 낱말 「회차」 · 「회」는 감사 회차 · 측정 회차 · 리뷰 회차와 같은 낱말이라 오검이 닻보다 많다 — 닻 둘(eval.yml)이 든다",
}

# 훑을 파일 — 저장소 맨 위에서 고른 살아 있는 파일. `.git` 이 있으면 git 이 드는 파일(추적한 것과 무시되지 않은 새 파일 —
# `bite-gates.sh` 가 사본에 베끼는 집합과 같다)에서, 없으면(사본 트리) 폴더를 걸어 고른다. 무시된 파일은 CI 체크아웃에 없어 훑지
# 않는다. `/audit-brief` 의 브리핑 · 기록 자리(`SCAN_SKIP_LOCAL`)는 커밋하지 않는 작업본이라 어느 길에서도 뺀다(감사 회차 18 NC-18).
SCAN_EXT = (".md", ".py", ".sh", ".yml", ".yaml", ".json")
SCAN_SKIP = ("docs/slices/", "docs/adr/", "docs/eval-log/", "docs/audit/", "vibe-audit/recall/")  # 기록 넷과 회수율 픽스처
SCAN_SKIP_RE = re.compile(r"^vibe-audit/evals/[^/]+/")  # 평가 픽스처 — evals/README.md 는 훑는다
SCAN_SKIP_LOCAL = (".claude/audits/", ".claude/briefs/", ".claude/audit-brief.md")  # verify-brief.py 의 DEFAULT_EXCLUDE 와 같다
SELF = "scripts/verify-counts.py"  # 원천 목록 · 명사 · 예외를 든 이 파일 자신은 훑지 않는다

# 예외 — 원천의 명사 옆에 지금 값과 같은 수가 있지만 그 원천을 든 문장이 아닌 자리. (파일, 꼴, 횟수, 까닭) — 꼴과 횟수는 닻과 같다.
# 꼴이 적은 횟수만큼 나오지 않으면 U2 다(문장을 지우거나 고쳤으면 예외도 고친다).
EXEMPT = [
    # 지난 기록 — 그때의 값을 적었다. 원천이 바뀌어도 고치지 않는다
    ('feedback.json', r'{N} 감사자', 2, '대장의 판정 까닭 — 판정한 때의 감사자 수'),
    ('docs/master-plan.md', r'케이스 {N}이 셋을 잽니다', 1, '닫힌 조각 44 의 줄이 그때의 README 문장을 옮겨 적었다'),
    ('docs/master-plan.md', r'로 문턱 {N} 을 넘었', 1, '닫힌 조각 24 의 줄 — 그때의 전수 결과'),
    ('scripts/run-evals.sh', r'문턱 {N} 에서 네 만점', 1, '지난 리뷰(Codex)가 든 보기 — 그때의 문턱'),
    ('scripts/verify-evals.py', r'전수 문턱 {N} 을\n', 1, '지난 리뷰(Codex)가 든 보기 — 그때의 문턱'),
    # 다른 것을 센 같은 값
    ('scripts/bite-gates.sh', r'문턱 {N} 하네스', 1, '--threshold 가 없을 때 하네스가 쓰는 1.0 — route 문턱이 아니다'),
    # 변조본의 바꿀 글 — 닻이 잡는 문장을 일부러 베꼈다. 그 문장이 바뀌면 vedit 이 「한 번이 아니다」로 먼저 떨어진다
    ('scripts/bite-gates.sh', r"'문서 틀 {N}' ", 2, '변조본의 바꿀 글'),
    ('scripts/bite-gates.sh', r"'변조 시험 {N}이 맨 뒤'", 2, '변조본의 바꿀 글'),
    ('scripts/bite-gates.sh', r"'감사자 {N} · '", 1, '변조본의 바꿀 글'),
    ('scripts/bite-gates.sh', r'읽기 전용 {N}\.', 3, '변조본의 바꿀 글'),
    ('scripts/bite-gates.sh', r"'대조군 {N} 이 돌았다'", 1, '변조본의 바꿀 글'),
    ('scripts/bite-gates.sh', r"'케이스 {N}이'", 2, '변조본의 바꿀 글'),
    ('scripts/bite-gates.sh', r"'케이스 {N}이다'", 2, '변조본의 바꿀 글'),
    ('scripts/bite-gates.sh', r"'문턱 {N} 에서 네 만점'", 1, '변조본의 바꿀 글'),
    ('scripts/bite-gates.sh', r"'감사자 {N}이 다 읽기 전용이다", 1, '대조군이 브리핑 작업본에 심는 글'),
]

RUN = r"([0-9][0-9,]*(?:\.[0-9]+)?(?![0-9])|[가-힣]+)"
LEFT = r"(?<![가-힣A-Za-z0-9.,_′-])"


def noun_patterns(pat):
    """명사 하나의 정규식 — (정규식, 수를 읽는 법). 앞: 명사 뒤의 덩이(토씨 붙음), 뒤: 명사 앞의 덩이(매김꼴)."""
    if "{N}" in pat:
        return [(re.compile(compile_anchor(pat), re.M), word)]
    return [(re.compile(rf"(?<![가-힣A-Za-z0-9_]){pat} {RUN}", re.M), lambda s: word(s) if s[0].isdigit() else number_token(s)),
            (re.compile(rf"{LEFT}{RUN} {pat}", re.M), word)]


def scan_files(root):
    import os
    import subprocess

    def keep(rel, full):
        return (rel != SELF and rel.endswith(SCAN_EXT) and not rel.startswith(SCAN_SKIP + SCAN_SKIP_LOCAL)
                and not SCAN_SKIP_RE.match(rel) and not os.path.islink(full) and os.path.isfile(full))

    if (root / ".git").exists():
        got = subprocess.run(["git", "-C", str(root), "ls-files", "-z", "-co", "--exclude-standard"],
                             capture_output=True)
        if got.returncode == 0:
            rels = sorted({r for r in got.stdout.decode("utf-8", "surrogateescape").split("\0") if r})
            return [r for r in rels if keep(r, os.path.join(root, r))]
    out = []
    for d, dirs, files in os.walk(root):
        rd = pathlib.Path(d).relative_to(root).as_posix()
        rd = "" if rd == "." else rd + "/"
        dirs[:] = sorted(x for x in dirs if x != ".git" and not os.path.islink(os.path.join(d, x))
                         and not (rd + x + "/").startswith(SCAN_SKIP) and not SCAN_SKIP_RE.match(rd + x + "/"))
        out += [rd + f for f in sorted(files) if keep(rd + f, os.path.join(d, f))]
    return out


# ── E 끝 줄 ────────────────────────────────────────────────────────────────────────────────────────────
END_GLOBS = ("scripts/bite-gates.sh", "scripts/bite-*.py", "scripts/test-*.py")
SH_END = re.compile(r'^echo "(?!.*::error::)(?!.*" >)')
SH_VALUE = re.compile(r"\$\(\([^)]*\)\)|\$\{[^}]*\}|\$[A-Za-z_][A-Za-z_0-9]*|\$[0-9#?@*$]")
PY_VALUE = re.compile(r"\{[^{}]*\}")
EXIT = re.compile(r"종료 [0-9]+")
ARABIC = re.compile(r"(?<![\w./′-])[0-9]+(?![\w./′-])")
HANGUL = re.compile(r"[가-힣]+")


def end_lines(rel, text):
    """끝 줄 — (줄 번호, 그 줄 앞의 글자 수, 글). 파이썬은 PASS 로 여는 print( 호출을 닫는 괄호까지 한 덩이로."""
    out = []
    if rel.endswith(".sh"):
        pos = 0
        for i, line in enumerate(text.split("\n"), 1):
            if SH_END.match(line):
                out.append((i, pos, line))
            pos += len(line) + 1
        return out
    for m in re.finditer(r'print\(\s*f?"PASS', text):
        depth, j = 0, m.start() + len("print")
        while j < len(text):
            c = text[j]
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        out.append((text.count("\n", 0, m.start()) + 1, m.start(), text[m.start():j + 1]))
    return out


def blank(s, pat):
    return pat.sub(lambda m: " " * len(m.group()), s)


class Report:
    def __init__(self):
        self.bad = []

    def fail(self, rid, where, msg):
        self.bad.append(f"FAIL [{rid}] {where} {msg}")


def judge(root):
    r = Report()
    values, failed = {}, set()
    for name, src in SOURCES.items():
        try:
            v = count(root, src)
        except Uncountable as e:
            r.fail("S1", src[1], f"원천 「{name}」을 못 셌다 — {e}")
            failed.add(name)
            continue
        if not v:
            r.fail("S1", src[1], f"원천 「{name}」이 0 이다 — 읽는 자리가 낡았거나 비었다")
            failed.add(name)
            continue
        values[name] = v

    spans = {}  # 파일 → 닻이 잡은 수 낱말의 (시작, 끝)
    texts = {}
    for rel, pat, times, name in ANCHORS:
        if name not in SOURCES:
            r.fail("S1", rel, f"닻의 원천 「{name}」이 원천 목록에 없다")
            continue
        if rel not in texts:
            try:
                texts[rel] = read(root, rel)
            except Uncountable as e:
                texts[rel] = None
                r.fail("D2", rel, f"닻의 파일을 못 읽었다 — {e}")
        text = texts[rel]
        if text is None:
            continue
        found = list(re.finditer(compile_anchor(pat), text, re.M))
        if len(found) != times:
            at = ", ".join(str(text.count("\n", 0, m.start()) + 1) for m in found) or "없음"
            r.fail("D2", rel, f"닻 /{pat}/ 이 {len(found)} 번 나온다(줄 {at}) — {times} 번이어야 한다. 문장을 고쳤으면 닻도 고친다")
            continue
        for m in found:
            line = text.count("\n", 0, m.start(1)) + 1
            spans.setdefault(rel, []).append((m.start(1), m.end(1)))
            got = word(m.group(1))
            if got is None:
                r.fail("L1", f"{rel}:{line}", f"수 낱말 {m.group(1)!r} 을 못 읽었다 — 닻 /{pat}/")
                continue
            if name in failed:
                continue
            if got != values[name]:
                r.fail("D1", f"{rel}:{line}", f"적힌 수 {m.group(1)}({got:g}) 이 원천 「{name}」의 {values[name]:g} 와 다르다 — 닻 /{pat}/")

    files = sorted({p for g in END_GLOBS for p in root.glob(g) if p.is_file()})
    if not files:
        r.fail("E2", "scripts/", f"끝 줄을 훑을 파일이 없다 — {' · '.join(END_GLOBS)}")
    n_end = 0
    for p in files:
        rel = p.relative_to(root).as_posix()
        try:
            text = read(root, rel)
        except Uncountable as e:
            r.fail("E2", rel, f"끝 줄을 훑을 파일을 못 읽었다 — {e}")
            continue
        ends = end_lines(rel, text)
        if not ends:
            r.fail("E2", rel, "끝 줄을 하나도 못 찾았다 — 끝 줄의 꼴이 바뀌었으면 이 검사의 읽는 법도 고친다")
            continue
        n_end += len(ends)
        held = spans.get(rel, [])
        for line, pos, body in ends:
            s = blank(body, SH_VALUE if rel.endswith(".sh") else PY_VALUE)
            s = blank(s, EXIT)
            hits = []
            for m in HANGUL.finditer(s):
                at = pos + m.start()
                if any(a <= at < b for a, b in held):
                    continue
                if number_token(m.group()) is not None:
                    hits.append(m.group())
            hits += ARABIC.findall(s)
            if hits:
                r.fail("E1", f"{rel}:{line}",
                       f"끝 줄에 견준 값이 아닌 수 낱말 {' · '.join(hits)} — 지우거나 견준 값(변수)으로 찍는다")
    # U — 같은 원천 훑기
    named = set(NOUNS) | set(NO_NOUN)
    for name in sorted(set(SOURCES) - named):
        r.fail("U3", SELF, f"원천 「{name}」에 명사가 없다 — NOUNS 에 명사를 두거나 NO_NOUN 에 까닭을 적는다")
    for name in sorted(named - set(SOURCES)):
        r.fail("U3", SELF, f"명사 목록의 「{name}」이 원천 목록에 없다 — 지운 원천의 명사를 지운다")
    for name in sorted(set(NOUNS) & set(NO_NOUN)):
        r.fail("U3", SELF, f"원천 「{name}」이 NOUNS 와 NO_NOUN 에 다 있다 — 한 곳에만 둔다")
    for name, pats in NOUNS.items():
        if not pats:
            r.fail("U3", SELF, f"원천 「{name}」의 명사 목록이 비었다 — 둘 수 없으면 NO_NOUN 에 까닭을 적는다")
    skip = {}  # 파일 → 훑지 않는 수 낱말의 시작 자리(닻 · 예외 · 원천을 읽는 자리)
    for rel, held in spans.items():
        skip.setdefault(rel, set()).update(a for a, _ in held)
    for name, src in SOURCES.items():
        if src[0] == "const":
            try:
                text = read(root, src[1])
            except Uncountable:
                continue
            skip.setdefault(src[1], set()).update(m.start(1) for m in re.finditer(src[2], text, re.M))
    for rel, pat, times, why in EXEMPT:
        try:
            text = read(root, rel)
        except Uncountable as e:
            r.fail("U2", rel, f"예외의 파일을 못 읽었다 — {e}")
            continue
        found = list(re.finditer(compile_anchor(pat), text, re.M))
        if len(found) != times:
            at = ", ".join(str(text.count("\n", 0, m.start()) + 1) for m in found) or "없음"
            r.fail("U2", rel, f"예외 /{pat}/ 이 {len(found)} 번 나온다(줄 {at}) — {times} 번이어야 한다. 문장을 고쳤으면 예외도 고친다")
            continue
        skip.setdefault(rel, set()).update(m.start(1) for m in found)
    scanned = scan_files(root)
    if not scanned:
        r.fail("U4", ".", f"같은 원천을 훑을 파일이 없다 — {' · '.join(SCAN_EXT)}")
    rules = [(name, rx, how) for name, pats in NOUNS.items() if name in values for pat in pats for rx, how in noun_patterns(pat)]
    for rel in scanned:
        try:
            text = read(root, rel)
        except Uncountable:
            continue
        held, hits = skip.get(rel, set()), {}
        for name, rx, how in rules:
            for m in rx.finditer(text):
                at = m.start(1)
                if at in held:
                    continue
                got = how(m.group(1))
                if got is None or got != values[name]:
                    continue
                hits.setdefault(at, (m.group(1), []))[1].append(name)
        for at in sorted(hits):
            tok, names = hits[at]
            line = text.count("\n", 0, at) + 1
            r.fail("U1", f"{rel}:{line}", f"닻 없는 수 {tok} 이 원천 「{' · '.join(sorted(set(names)))}」의 지금 값과 같다 — "
                   "같은 원천이면 ANCHORS 에 닻을, 아니면 EXEMPT 에 까닭과 함께 예외를 더한다")
    return r.bad, len(ANCHORS), len(values), n_end, len(scanned), len(EXEMPT)


def main(argv):
    if len(argv) > 1 or (argv and argv[0].startswith("-")):
        print(USAGE, file=sys.stderr)
        return 2
    root = pathlib.Path(argv[0]).resolve() if argv else ROOT
    if not root.is_dir():
        print(USAGE, file=sys.stderr)
        return 2
    bad, n_anchor, n_source, n_end, n_scan, n_exempt = judge(root)
    if bad:
        for b in bad:
            print(b)
        return 1
    print(f"PASS verify-counts.py — 닻 {n_anchor} 이 원천 {n_source} 과 맞고, 끝 줄 {n_end} 에 견준 값 밖의 수 낱말이 없고, "
          f"훑은 파일 {n_scan} 에 닻 없는 같은 원천 문장이 없다(예외 {n_exempt})")
    return 0


if __name__ == "__main__":
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv[1:]))
