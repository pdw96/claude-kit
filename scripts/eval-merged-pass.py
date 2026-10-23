#!/usr/bin/env python3
"""`main` 푸시가 머지된 PR 의 통과를 읽는다 — 이 푸시를 머지 커밋으로 가진 PR 하나의 merge ref 에 같은 지문의 캐시가
있는지 캐시 목록 API 로 본다. 모델은 안 쓰고 GitHub REST API 를 읽기만 한다.

  python3 scripts/eval-merged-pass.py <키>     # main 푸시의 gate 잡 — 키는 `eval-key.py route` 나 `gate-key.py` 의 값
  python3 scripts/eval-merged-pass.py --probe  # PR 실행의 gate 잡 — 같은 API 두 곳을 읽어 꼴만 찍는다

**왜 있나.** 통과한 지문은 실행의 ref 범위에 캐시로 적힌다. PR 실행은 `refs/pull/<N>/merge` 에 적고, `main` 푸시는 `main`
범위만 읽어 PR 에서 같은 지문이 통과했어도 머지 뒤에 route 수트를 한 번 더 돌렸다(조각 12 요구사항 「문제」 · ADR 0021).
변조 시험의 지문(`gate-key.py`)도 같은 판정을 쓴다 — 판정은 키를 가리지 않는다(조각 35 · ADR 0046 의 6).

**무엇을 보장하나.** `docs/slices/12-main-reads-pr-pass/design.md` ② 가 든다 — 출력과 아래 주석의 `P1` 같은 번호가 그 보장의
번호다. 받는 입력(환경 · API 의 꼴)의 닫힌 목록은 같은 설계 ③.

**모르면 돈다.** API 를 못 읽거나 꼴이 뜻밖이면 `::warning::` 한 줄을 찍고 「돈다」로 적는다 — 끝은 늘 0 이라 gate 잡을
떨어뜨리지 않는다(P3). 캐시를 지우거나 적지 않는다 — `main` 범위에 적는 것은 `eval.yml` 이다(P5).

이 판정을 망가뜨린 사본이 자체 시험(`test-eval-merged-pass.py`)에서 떨어지는지는 `bite-eval-merged-pass.py` 가 본다 — 아래
줄 몇을 글자 그대로 찾아 바꾸므로, 그 줄을 고치면 변조본도 따라 고친다. 셋 다 수트 지문 밖이다(ADR 0021 의 3).

표준 라이브러리만 쓴다.
"""
import http.client
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

USAGE = "사용법: eval-merged-pass.py <키>   |   eval-merged-pass.py --probe"
TIMEOUT = 10
PROBE_KEY = "eval-route-"


class Unknown(Exception):
    """근거를 읽지 못했다 — P3. 모르면 돈다."""


def env(*names):
    vals = [os.environ.get(n, "") for n in names]
    missing = [n for n, v in zip(names, vals) if not v]
    if missing:
        raise Unknown(f"환경 {' · '.join(missing)} 이 비었다")
    return vals


def get(api, token, path, query=None):
    """API 하나를 읽어 JSON 을 낸다. HTTP 오류 · 연결 실패 · 시간 넘김 · JSON 이 아님은 다 Unknown(P3)."""
    url = api.rstrip("/") + path + (f"?{urllib.parse.urlencode(query)}" if query else "")
    req = urllib.request.Request(url, headers={
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {token}",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "claude-kit-eval-merged-pass",
    })
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            body = r.read()
    except urllib.error.HTTPError as e:
        raise Unknown(f"{path} — HTTP {e.code}") from None
    except (urllib.error.URLError, http.client.HTTPException, OSError) as e:
        raise Unknown(f"{path} — 읽지 못했다: {e}") from None
    try:
        return json.loads(body.decode("utf-8"))
    except ValueError:  # UnicodeDecodeError · JSONDecodeError 둘 다
        raise Unknown(f"{path} — JSON 이 아니다") from None


def pulls_of(data):
    """`commits/{sha}/pulls` 의 응답에서 (number, merged_at, merge_commit_sha, base.ref) 를 뽑는다 — 꼴은 설계 ③."""
    if not isinstance(data, list):
        raise Unknown("commits/{sha}/pulls — 배열이 아니다")
    out = []
    for p in data:
        try:
            row = (p["number"], p["merged_at"], p["merge_commit_sha"], p["base"]["ref"])
        except (TypeError, KeyError):
            raise Unknown("commits/{sha}/pulls — number · merged_at · merge_commit_sha · base.ref 가운데 없는 칸이 있다") from None
        n, at, mcs, base = row
        if type(n) is not int or not all(isinstance(v, (str, type(None))) for v in (at, mcs)) or not isinstance(base, str):
            raise Unknown(f"commits/{{sha}}/pulls — 칸의 꼴이 다르다: {row!r}")
        out.append(row)
    return out


def caches_of(data):
    """`actions/caches` 의 응답에서 (key, ref, created_at) 를 뽑는다 — 꼴은 설계 ③."""
    entries = data.get("actions_caches") if isinstance(data, dict) else None
    if not isinstance(entries, list):
        raise Unknown("actions/caches — actions_caches 배열이 없다")
    out = []
    for c in entries:
        try:
            row = (c["key"], c["ref"], c["created_at"])
        except (TypeError, KeyError):
            raise Unknown("actions/caches — key · ref · created_at 가운데 없는 칸이 있다") from None
        if not all(isinstance(v, str) for v in row):
            raise Unknown(f"actions/caches — 칸의 꼴이 다르다: {row!r}")
        out.append(row)
    return out


def judge(key):
    """(건너뛰나, 적을 것). 근거를 못 읽으면 Unknown."""
    api, repo, sha, branch, token = env("GITHUB_API_URL", "GITHUB_REPOSITORY", "GITHUB_SHA", "GITHUB_REF_NAME", "GITHUB_TOKEN")
    if not key:
        raise Unknown("키가 비었다")  # P6 — 지문은 gate 잡이 낸 것을 받는다. 여기서 다시 내지 않는다.

    # P1 머지된 PR 하나 — 그 PR 의 머지 커밋이 이 푸시이고, 이 가지로 머지됐다. 없거나 둘 이상이면 돈다.
    pulls = pulls_of(get(api, token, f"/repos/{repo}/commits/{sha}/pulls"))
    merged = [n for n, at, mcs, base in pulls
              if at and mcs == sha and base == branch]
    if len(merged) != 1:
        return False, {"reason": f"이 푸시({sha[:12]})를 머지 커밋으로 가진 {branch} 의 PR 이 {len(merged)} 개다 — 꼭 하나일 때만 건너뛴다"}
    n = merged[0]
    ref = f"refs/pull/{n}/merge"

    # P2 그 merge ref 에 같은 키 — API 의 key 는 앞부분 일치라 서버의 거름에 기대지 않고 key · ref 를 글자 그대로 다시 견준다.
    caches = caches_of(get(api, token, f"/repos/{repo}/actions/caches", {"key": key, "ref": ref, "per_page": 100}))
    hits = [t for k, r, t in caches
            if k == key and r == ref]
    if not hits:
        return False, {"reason": f"PR #{n} 의 {ref} 에 같은 키가 없다(앞부분이 같은 항목 {len(caches)})"}
    return True, {"pr": n, "created": hits[0]}


def emit(**kv):
    """P4 — `$GITHUB_OUTPUT` 에 한 줄씩. 값의 줄바꿈은 빈칸으로 접는다."""
    lines = "".join(f"{k}={' '.join(str(v).split())}\n" for k, v in kv.items())
    path = os.environ.get("GITHUB_OUTPUT")
    if not path:
        print("::warning::GITHUB_OUTPUT 이 비어 판정을 적지 못했다 — hit 이 비어 돈다")
        return
    with open(path, "a", encoding="utf-8") as f:
        f.write(lines)


def main_push(key):
    try:
        hit, facts = judge(key)
    except Unknown as e:
        print(f"::warning::머지된 PR 의 통과를 읽지 못해 돈다 — {e}")
        hit, facts = False, {"reason": f"읽지 못했다 — {e}"}
    if hit:
        print(f"건너뛴다 — PR #{facts['pr']} 의 refs/pull/{facts['pr']}/merge 에 같은 키({key})가 있다({facts['created']} 에 적힘)")
        emit(hit="true", **facts)
    else:
        print(f"돈다 — {facts['reason']}")
        emit(hit="false", **facts)
    return 0


def probe():
    """R1 — PR 실행에서 판정이 쓸 API 두 곳을 읽어 꼴과 개수를 찍는다. 판정에 쓰지 않고 아무것도 적지 않는다."""
    try:
        api, repo, token, n, head = env("GITHUB_API_URL", "GITHUB_REPOSITORY", "GITHUB_TOKEN", "PR_NUMBER", "PR_HEAD_SHA")
        if not n.isdigit():
            raise Unknown(f"PR_NUMBER 가 수가 아니다: {n}")

        data = get(api, token, f"/repos/{repo}/commits/{head}/pulls")
        pulls = pulls_of(data)
        print(f"commits/{head[:12]}/pulls — {len(pulls)} 개 · 첫 항목의 칸: {sorted(data[0]) if data else '없음'}")
        for num, at, mcs, base in pulls:
            print(f"  #{num} · merged_at={at} · merge_commit_sha={mcs} · base.ref={base}")
        if not any(num == int(n) for num, *_ in pulls):
            print(f"::warning::이 PR(#{n})이 commits/{head[:12]}/pulls 에 없다 — 판정의 P1 이 기대는 짝이다")

        ref = f"refs/pull/{n}/merge"
        data = get(api, token, f"/repos/{repo}/actions/caches", {"key": PROBE_KEY, "ref": ref, "per_page": 100})
        caches = caches_of(data)
        first = sorted(data["actions_caches"][0]) if caches else "없음"
        print(f"actions/caches?key={PROBE_KEY}&ref={ref} — {len(caches)} 개 · 맨 위 칸: {sorted(data)} · 첫 항목의 칸: {first}")
        for k, r, t in caches:
            print(f"  {k} · {r} · {t}")
    except Unknown as e:
        print(f"::warning::판정이 쓸 API 를 읽어 보지 못했다 — {e}")
    return 0


def main(argv):
    if argv == ["--probe"]:
        return probe()
    if len(argv) != 1 or argv[0].startswith("-"):
        print(USAGE, file=sys.stderr)
        return 2
    return main_push(argv[0])


if __name__ == "__main__":
    # 출력은 콘솔 인코딩과 상관없이 UTF-8 이다 — cp949 콘솔에서 `—` 를 찍다 예외로 끝나지 않게.
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv[1:]))
