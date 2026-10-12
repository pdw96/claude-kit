#!/usr/bin/env python3
"""`eval-merged-pass.py` 가 조각 12 설계 ② 의 P1 ~ P4 · R1 을 지키는지 본다. 모델도 바깥 네트워크도 안 쓴다.

  python3 scripts/test-eval-merged-pass.py [<판정 경로>]   # 없으면 scripts/eval-merged-pass.py

로컬 가짜 API(`http.server`, 127.0.0.1)에 설계 ③ 「시험의 꼴」 열둘을 하나씩 세우고 판정을 대어, 끝 코드 · `$GITHUB_OUTPUT`
· 경고를 본다. `--probe` 는 정상 · 403 둘. 판정의 경로를 받는 까닭 — `bite-eval-merged-pass.py` 가 망가뜨린 사본에 이 시험을
대어 떨어지는지 본다(T2).

**가짜 API 는 거르지 않는다.** 꼴이 든 항목을 질의와 상관없이 그대로 낸다 — 캐시 API 의 `key` 는 앞부분 일치이고, 판정은
서버의 거름에 기대지 않고 key · ref 를 다시 견줘야 한다(P2). 질의가 옳은지는 H1 이 따로 본다.

표준 라이브러리만 쓴다.
"""
import http.server
import json
import os
import pathlib
import subprocess
import sys
import tempfile
import threading
import urllib.parse

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHECK = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / "scripts" / "eval-merged-pass.py"
REPO = "o/r"
SHA = "a" * 40
OTHER = "b" * 40
HEAD = "c" * 40
KEY = "eval-route-cli2.1.296-0123456789abcdef01234567"
TOKEN = "t0k"
WHEN = "2026-10-12T09:00:00Z"
PROXY = {"HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "http_proxy", "https_proxy", "all_proxy", "NO_PROXY", "no_proxy"}


def pr(n, merged=True, mcs=SHA, base="main"):
    return {"number": n, "state": "closed" if merged else "open", "merged_at": WHEN if merged else None,
            "merge_commit_sha": mcs, "base": {"ref": base, "sha": OTHER}, "head": {"ref": f"b{n}", "sha": HEAD}}


def cache(key=KEY, n=7):
    return {"id": 1, "ref": f"refs/pull/{n}/merge", "key": key, "version": "v", "last_accessed_at": WHEN,
            "created_at": WHEN, "size_in_bytes": 1}


def caches(*entries):
    return {"total_count": len(entries), "actions_caches": list(entries)}


# 꼴 — 이름: (pulls 의 (코드, 몸), caches 의 (코드, 몸)). 몸이 bytes 면 그대로, 아니면 JSON.
STATE = {"pulls": (200, []), "caches": (200, caches()), "seen": []}


class Fake(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        u = urllib.parse.urlsplit(self.path)
        STATE["seen"].append((u.path, urllib.parse.parse_qs(u.query), self.headers.get("Authorization")))
        if u.path.startswith(f"/repos/{REPO}/commits/") and u.path.endswith("/pulls"):
            code, body = STATE["pulls"]
        elif u.path == f"/repos/{REPO}/actions/caches":
            code, body = STATE["caches"]
        else:
            code, body = 404, {"message": "Not Found"}
        raw = body if isinstance(body, bytes) else json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def log_message(self, *a):
        pass


bad = []


def run(api, out, *args, extra=None):
    env = {k: v for k, v in os.environ.items() if k not in PROXY and not k.startswith("GITHUB_") and not k.startswith("PR_")}
    env.update({"GITHUB_API_URL": api, "GITHUB_REPOSITORY": REPO, "GITHUB_SHA": SHA, "GITHUB_REF_NAME": "main",
                "GITHUB_TOKEN": TOKEN, "GITHUB_OUTPUT": str(out), "NO_PROXY": "*"})
    env.update(extra or {})
    out.write_text("", encoding="utf-8")
    STATE["seen"] = []
    p = subprocess.run([sys.executable, str(CHECK), *args], capture_output=True, text=True,
                       encoding="utf-8", errors="replace", env=env, timeout=60)
    got = dict(ln.split("=", 1) for ln in out.read_text(encoding="utf-8").splitlines() if "=" in ln)
    return p.returncode, p.stdout + p.stderr, got


def expect(what, ok, log=""):
    if not ok:
        bad.append(f"{what}\n    {log.strip().replace(chr(10), chr(10) + '    ')}")


def case(api, out, name, pulls, cached, skip=False, warn=False):
    STATE["pulls"], STATE["caches"] = pulls, cached
    code, log, got = run(api, out, KEY)
    expect(f"{name} — exit {code}, 기대 0", code == 0, log)
    expect(f"{name} — hit={got.get('hit')}, 기대 {'true' if skip else 'false'}",
           got.get("hit") == ("true" if skip else "false"), log)
    expect(f"{name} — 경고 {'있음' if '::warning::' in log else '없음'}, 기대 {'있음' if warn else '없음'}",
           ("::warning::" in log) == warn, log)
    if not skip:
        expect(f"{name} — 돈다인데 까닭이 없다", bool(got.get("reason")), log)
    return got, log


def main():
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Fake)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    api = f"http://127.0.0.1:{srv.server_address[1]}"
    try:
        with tempfile.TemporaryDirectory() as t:
            out = pathlib.Path(t) / "output"

            # H1 — 머지된 PR 하나 · 그 merge ref 에 같은 키 → 건너뛴다. 질의 · 토큰도 본다.
            got, log = case(api, out, "H1 머지된 PR 하나 · 그 merge ref 에 같은 키", (200, [pr(7)]), (200, caches(cache())),
                            skip=True)
            expect(f"H1 — pr={got.get('pr')} · created={got.get('created')}", got.get("pr") == "7" and got.get("created") == WHEN, log)
            seen = STATE["seen"]
            want = [(f"/repos/{REPO}/commits/{SHA}/pulls", None),
                    (f"/repos/{REPO}/actions/caches", {"key": [KEY], "ref": ["refs/pull/7/merge"], "per_page": ["100"]})]
            expect(f"H1 — 읽은 곳 {[(p, q) for p, q, _ in seen]}",
                   len(seen) == 2 and all(p == w and (q == wq if wq else True) for (p, q, _), (w, wq) in zip(seen, want)), log)
            expect("H1 — 토큰을 Bearer 로 넘기지 않았다", all(a == f"Bearer {TOKEN}" for _, _, a in seen), log)

            case(api, out, "M1 같은 키가 다른 PR 의 merge ref 에만", (200, [pr(7)]), (200, caches(cache(n=8))))
            case(api, out, "M2 그 merge ref 에 키가 앞부분만 같은 항목", (200, [pr(7)]), (200, caches(cache(key=KEY + "0"))))
            case(api, out, "M3 PR 이 머지되지 않았다", (200, [pr(7, merged=False)]), (200, caches(cache())))
            case(api, out, "M4 merge_commit_sha 가 푸시 sha 와 다르다", (200, [pr(7, mcs=OTHER)]), (200, caches(cache())))
            case(api, out, "M5 base.ref 가 푸시한 가지가 아니다", (200, [pr(7, base="dev")]), (200, caches(cache())))
            case(api, out, "M6 PR 이 없다", (200, []), (200, caches(cache())))
            case(api, out, "M7 머지된 PR 이 둘", (200, [pr(7), pr(8)]), (200, caches(cache(n=7), cache(n=8))))
            case(api, out, "M8 PR API 403", (403, {"message": "Resource not accessible by integration"}),
                 (200, caches(cache())), warn=True)
            case(api, out, "M9 캐시 API 500", (200, [pr(7)]), (500, {"message": "boom"}), warn=True)
            case(api, out, "M10 JSON 이 아님", (200, b"<html>not json</html>"), (200, caches(cache())), warn=True)
            case(api, out, "M11 actions_caches 없음", (200, [pr(7)]), (200, {"total_count": 1}), warn=True)

            # 인자 — 틀린 부름은 사용법과 2.
            code, log, _ = run(api, out)
            expect(f"인자 없음 — exit {code}, 기대 2", code == 2, log)

            # R1 --probe — 판정에 쓰지 않는다: 끝은 0, $GITHUB_OUTPUT 에 아무것도 안 적는다.
            probe_env = {"PR_NUMBER": "7", "PR_HEAD_SHA": HEAD}
            STATE["pulls"], STATE["caches"] = (200, [pr(7, merged=False, mcs=OTHER)]), (200, caches(cache()))
            code, log, got = run(api, out, "--probe", extra=probe_env)
            expect(f"probe 정상 — exit {code}, 기대 0", code == 0, log)
            expect("probe 정상 — 경고가 났다", "::warning::" not in log, log)
            expect("probe 정상 — PR 번호와 캐시 개수를 찍지 않았다", "#7" in log and "ref=refs/pull/7/merge — 1 개" in log, log)
            expect(f"probe 정상 — $GITHUB_OUTPUT 에 적었다: {got}", not got, log)
            expect(f"probe 정상 — 읽은 곳 {[p for p, _, _ in STATE['seen']]}",
                   [p for p, _, _ in STATE["seen"]] == [f"/repos/{REPO}/commits/{HEAD}/pulls", f"/repos/{REPO}/actions/caches"], log)

            STATE["pulls"] = (403, {"message": "Resource not accessible by integration"})
            code, log, got = run(api, out, "--probe", extra=probe_env)
            expect(f"probe 403 — exit {code}, 기대 0", code == 0, log)
            expect("probe 403 — 경고가 없다", "::warning::" in log, log)
            expect(f"probe 403 — $GITHUB_OUTPUT 에 적었다: {got}", not got, log)
    finally:
        srv.shutdown()

    if bad:
        print(f"FAIL eval-merged-pass.py — {len(bad)}")
        for b in bad:
            print(f"  {b}")
        return 1
    print("PASS eval-merged-pass.py — H1 · M1 ~ M11 · 인자 · probe 정상 · 403")
    return 0


if __name__ == "__main__":
    sys.exit(main())
