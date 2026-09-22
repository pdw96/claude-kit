---
type: regex
weight: 1
target: last_message
pattern: "## 안 본 것(?:(?!\\n## )[\\s\\S])*?audit-(?:data|quality|ops|contract|internal)"
---

「안 본 것」 절 안에 담당 감사자 이름이 적혀 있는지 본다. 영역만 적고 담당을
지명하지 않으면 그 줄은 아무도 집지 않는다.
