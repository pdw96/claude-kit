# claude-kit

[한국어](README.md) · English

A Claude Code plugin marketplace with 2 plugins. The main one, `vibe-audit`, gives you 2 read-only auditors, each narrowed to one purpose.
They report nonconformities and cannot fix anything — they have no tool that writes.

## What's inside

| Plugin | What |
|---|---|
| `vibe-audit` | 2 read-only auditors and the `audit-brief` command |
| `vibe-slice` | Document templates and a procedure for running a project in slices — written in Korean (below) |

**`vibe-audit`.** Each auditor's frontmatter is `tools: ["Read", "Grep", "Glob"]` — no `Edit`, `Write` or `Bash`. Asking it to fix something does not work, by
construction: code an auditor fixed would be code nobody audited. Each auditor looks at one area only and hands anything outside it to the auditor that owns it.

| Auditor | Looks only at |
|---|---|
| `audit-data` | Schema · migrations · transaction boundaries · whether a change can be rolled back |
| `audit-internal` | Rules the project wrote down for itself (`CLAUDE.md` · PRD · ADRs) against the actual code |

Four more auditors (secrets · checking machinery · operations · public contract) were retired in 2026-11; their last form is tagged `v-archive-2026-11`.

Each run returns numbered nonconformities (`NC-1`, `NC-2`, …) and a **"not looked at"** list — what the auditor did not check is part of the result.

**`vibe-slice`.** 6 document templates — intent · master plan · working rules (`CLAUDE.md`) · profile (`Profile.md`) · slice requirements · slice design — plus a
nonconformity ledger template (skill `slice-docs`), and a way to sort review comments against the slice's design (skill `slice-review`). The templates, the
procedure map they follow and the checks' output are Korean. This README does not explain the procedure in English.

## Language

**The tools speak Korean.** The auditors' descriptions (the text a session reads to pick an auditor), their instructions and their reports are Korean, and so are
`vibe-slice`'s skills and templates. You can call an auditor by name from an English session. Whether a session picks an auditor on its own from an English
request has not been measured — the trigger suite and the comparison below used Korean requests only.

## What's different — head-to-head with other plugins

`vibe-audit`'s `audit-internal` **tells which of a repository's own rules are still in force** — it does not report as a defect something the repository has
scoped out: a closed slice's "won't do", a superseded old document. Below are the passing runs on a trap case, with the same material, the same request body and
the same judge for every arm (2026-11-15, CLI 2.1.325, suite model `claude-sonnet-5-5`). A run passes when it reports the defect it should find and does not
report the trap as a defect.

| Trap case | Reporting this as a defect is wrong | `vibe-audit` | `pr-review-toolkit` | `pr-review-toolkit` + context | No plugin + context |
|---|---|---|---|---|---|
| `trap-slice-scope` | A closed slice's "don't build CSV export" · an old `PRD.md`'s "email sending" | 3/3 | 1/3 | 2/3 | 2/3 |

**One line of context closes most of the gap.** The "+ context" arms put two lines in the repository's `CLAUDE.md`: read `INTENT.md`'s Not and closed slices'
"won't do" before a review, and do not report what they list or local-only values as defects. On the local-dev-password trap (`trap-local-dev-password`) both
context arms scored 3/3. So the four auditors for security · contract · quality · operations were retired; `audit-internal` (this difference) and `audit-data`
(where most feedback came from) remain — ADR 0090 · 0091 (Korean).

**Where it was even.** On six cases built from defects the owning auditor had missed before (four data · two contract), `vibe-audit` scored 17/18 (earlier
measurement), no plugin 18/18, `pr-review-toolkit` 18/18 and both context arms 18/18. That set is at the ceiling even without context, so it shows only that the
context lines did not hide real defects.

**Limits.** One trap case · 3 runs — one run can flip a verdict. These numbers hold only for this material, this suite model and this competitor commit
(`anthropics/claude-plugins-official` `a7ba5b9`). The security and checking-machinery auditors were retired without a missed-defect set for their areas. The
plugin arms were called by name at the top of the request; whether an installed-only plugin also tells the trap apart was not measured. Raw cost per run on the
trap: `vibe-audit` $0.198 · `pr-review-toolkit` $0.271 · no plugin + context $0.126.

Tables, judging rules and raw output (Korean): `docs/eval-log/2026-11.md` — "2026-11-15 · 맥락 한 줄 팔 — 조각 71" · "다른 플러그인과 맞대기 — 조각 51 PR C".

## Install

In a local interactive session, add the marketplace once and every repository you open locally gets the plugins.

```bash
claude plugin marketplace add pdw96/claude-kit
claude plugin install vibe-audit@pdw96-kit
claude plugin install vibe-slice@pdw96-kit
```

**A new version does not arrive by reloading** — auto-update is off by default for this marketplace. To get one:

```bash
claude plugin marketplace update pdw96-kit
claude plugin update vibe-audit@pdw96-kit
claude plugin update vibe-slice@pdw96-kit
```

then reload (or turn on auto-update for `pdw96-kit` in `/plugin`).

Cloud sessions opened from the Claude app received the plugins when this repository was added as a marketplace on the claude.ai account and both plugins were
enabled — measured once, on 2026-10-30. The author's own repositories also use per-repository copies; that path and the upstream bugs behind it are in the
Korean README, section "설치 — 경로가 셋인 이유".

## Use

Call an auditor by its scoped name, one at a time — running all of them at once makes each one shallow.

```
@vibe-audit:audit-data the migrations in this PR
@vibe-audit:audit-internal the whole repository
```

If you wrote the code in this same session, run the audit in a new session — otherwise it checks with the assumptions it just made. To compare against a base
(a PR, a branch, a commit range), build a brief first with `/vibe-audit:audit-brief <base> [auditor]`; auditors cannot run git themselves.

| When | Run |
|---|---|
| A PR touching schema · migrations · transactions | `audit-data` |
| After merging three or four slices | `audit-internal` |

Close a nonconformity only when the same auditor, run again, no longer finds it — "fixed" is not the same as "verified".

## Where to read more (Korean)

| What | Where |
|---|---|
| Why this exists, what it does and does not do | [`INTENT.md`](INTENT.md) |
| What happens in which order — slices and pointers | [`docs/master-plan.md`](docs/master-plan.md) |
| Parts and flows | [`docs/architecture.md`](docs/architecture.md) |
| How the auditors are measured — cases and method | [`vibe-audit/evals/README.md`](vibe-audit/evals/README.md) |
| `vibe-audit` in detail | [`vibe-audit/README.md`](vibe-audit/README.md) |

License: MIT.
