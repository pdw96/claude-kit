#!/usr/bin/env python3
"""매니페스트가 선언한 것이 실제로 있는지, 두 군데 적힌 것이 서로 맞는지 본다.

  python3 scripts/verify-manifest.py

이 검사가 있는 이유는 이 저장소에서 실제로 난 일 때문이다. `plugin.json` 이
`"license": "MIT"` 라고 적고 있었는데 **LICENSE 파일이 없었다.** 받아 가는
쪽은 선언만 보고 조건을 알 수 없고, 사본이 여섯 레포로 퍼진 뒤에는 고쳐도
늦는다. 감사자에게 「문서 대비 준수」를 시키면서 자기 매니페스트가 그 부적합을
갖고 있었다.

두 번째로 보는 것은 **같은 말이 두 군데 적힌 자리**다. 플러그인 설명이
`plugin.json` 과 `marketplace.json` 에 각각 있다. 한쪽만 고치면 장터에 뜨는
말과 설치된 것의 말이 갈리는데, 갈린 것을 알려 주는 것이 아무것도 없었다.

표준 라이브러리만 쓴다.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MARKET = ROOT / ".claude-plugin" / "marketplace.json"

# 선언한 라이선스가 파일 안에서 어떤 말로 나타나야 하는가.
LICENSE_MARK = {
    "MIT": "MIT License",
    "Apache-2.0": "Apache License",
    "BSD-3-Clause": "BSD 3-Clause",
    "ISC": "ISC License",
}


def load(path, bad):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        bad.append(f"{path.relative_to(ROOT)} 가 없다")
    except json.JSONDecodeError as e:
        bad.append(f"{path.relative_to(ROOT)} 가 JSON 이 아니다 — {e}")
    return None


def main():
    bad = []
    market = load(MARKET, bad)
    if market is None:
        print("FAIL\n  - " + "\n  - ".join(bad))
        return 1

    entries = market.get("plugins") or []
    if not entries:
        bad.append("marketplace.json 에 plugins 가 비어 있다 — 장터에 아무것도 안 뜬다")

    checked = 0
    for entry in entries:
        name = entry.get("name", "<이름 없음>")
        src = entry.get("source")
        if not src:
            bad.append(f"{name}: marketplace.json 에 source 가 없다")
            continue
        pdir = (ROOT / src).resolve()
        if not pdir.is_dir():
            bad.append(f"{name}: source 가 가리키는 {src} 가 없다")
            continue

        manifest = pdir / ".claude-plugin" / "plugin.json"
        plugin = load(manifest, bad)
        if plugin is None:
            continue
        checked += 1
        rel = manifest.relative_to(ROOT)

        if plugin.get("name") != name:
            bad.append(
                f"{name}: 이름이 갈렸다 — marketplace.json 은 {name!r}, "
                f"{rel} 은 {plugin.get('name')!r}"
            )

        # 같은 말이 두 군데 적힌 자리는 글자 단위로 견준다.
        if entry.get("description") != plugin.get("description"):
            bad.append(
                f"{name}: 설명이 갈렸다 — 장터에 뜨는 말과 설치된 것의 말이 다르다"
            )

        ver = plugin.get("version")
        if not (isinstance(ver, str) and re.fullmatch(r"\d+\.\d+\.\d+", ver)):
            bad.append(f"{name}: version 이 {ver!r} 다 — 세 자리 판 번호여야 한다")

        # 선언한 라이선스는 파일로 서 있어야 한다.
        lic = plugin.get("license")
        if not lic:
            bad.append(f"{name}: license 선언이 없다")
        else:
            files = [p for p in (pdir / "LICENSE", ROOT / "LICENSE") if p.is_file()]
            if not files:
                bad.append(
                    f"{name}: license 를 {lic!r} 로 선언했는데 LICENSE 파일이 없다 "
                    f"— 받아 가는 쪽이 조건을 알 수 없다"
                )
            else:
                mark = LICENSE_MARK.get(lic)
                text = files[0].read_text(encoding="utf-8")
                if mark and mark not in text:
                    bad.append(
                        f"{name}: {files[0].relative_to(ROOT)} 안에 {mark!r} 가 없다 "
                        f"— 선언({lic})과 파일이 다른 것을 말한다"
                    )

        owner = (market.get("owner") or {}).get("name")
        author = (plugin.get("author") or {}).get("name")
        if owner and author and owner != author:
            bad.append(f"{name}: 장터 주인({owner!r})과 플러그인 저자({author!r})가 다르다")

    if bad:
        print("FAIL\n  - " + "\n  - ".join(bad))
        return 1
    print(f"PASS 플러그인 {checked}개 — 선언한 라이선스가 파일로 서 있고, "
          f"두 군데 적힌 이름·설명이 같다")
    print(f"     매니페스트 {MARKET.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
