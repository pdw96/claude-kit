# claude-kit

[한국어](README.md) · English

A Claude Code plugin marketplace with 2 plugins. The main one, `vibe-audit`, gives you 6 read-only auditors, each narrowed to one purpose.
They report nonconformities and cannot fix anything — they have no tool that writes.

## What's inside

| Plugin | What |
|---|---|
| `vibe-audit` | 6 read-only auditors and the `audit-brief` command |
| `vibe-slice` | Document templates and a procedure for running a project in slices — written in Korean (below) |

**`vibe-audit`.** Each auditor's frontmatter is `tools: ["Read", "Grep", "Glob"]` — no `Edit`, `Write` or `Bash`. Asking it to fix something does not work, by
construction: code an auditor fixed would be code nobody audited. Each auditor looks at one area only and hands anything outside it to the auditor that owns it.

| Auditor | Looks only at |
|---|---|
| `audit-secrets` | Secrets · credentials · environment separation · permission boundaries |
| `audit-data` | Schema · migrations · transaction boundaries · whether a change can be rolled back |
| `audit-quality` | The checking machinery itself — tests · CI gates · eval sets |
| `audit-ops` | Logging · observability · alerting · rollback · incident paths |
| `audit-contract` | Promises visible from outside — public API · response shape · error conventions · backward compatibility |
| `audit-internal` | Rules the project wrote down for itself (`CLAUDE.md` · PRD · ADRs) against the actual code |

Each run returns numbered nonconformities (`NC-1`, `NC-2`, …) and a **"not looked at"** list — what the auditor did not check is part of the result.

**`vibe-slice`.** 6 document templates — intent · master plan · working rules (`CLAUDE.md`) · profile (`Profile.md`) · slice requirements · slice design — plus a
nonconformity ledger template (skill `slice-docs`), and a way to sort review comments against the slice's design (skill `slice-review`). The templates, the
procedure map they follow and the checks' output are Korean. This README does not explain the procedure in English.

## Language

**The tools speak Korean.** The auditors' descriptions (the text a session reads to pick an auditor), their instructions and their reports are Korean, and so are
`vibe-slice`'s skills and templates. You can call an auditor by name from an English session. Whether a session picks an auditor on its own from an English
request has not been measured — the trigger suite and the comparison below used Korean requests only.

## What's different — head-to-head with other plugins

`vibe-audit` **tells which of a repository's own rules are still in force** — it does not report as a defect to fix something the repository has scoped out: a
closed slice's "won't do", a superseded old document, a value used only for local development. Below are the passing runs on two trap cases, with the same
material, the same request body and the same judge for every arm. A run passes when it reports the defect it should find and does not report the trap as a defect.

| Trap case | Reporting this as a defect is wrong | `vibe-audit` | No plugin | `pr-review-toolkit` |
|---|---|---|---|---|
| `trap-slice-scope` | A closed slice's "don't build CSV export" · an old `PRD.md`'s "email sending" | 3/3 | 0/3 | 0/3 |
| `trap-local-dev-password` | A development DB password in a `docker-compose.yml` bound only to `127.0.0.1` | 2/3 | 0/3 | 1/3 |

**Where it was even.** On six cases built from defects the owning auditor had missed before (data · contract), `vibe-audit` scored 17/18, no plugin 18/18 and
`pr-review-toolkit` 18/18 — that set showed nothing only this plugin catches. On the security axis `claude-security` also got both cases (6/6, trap included —
re-measured without handing it the answer key).

**Limits.**

- The evidence is two trap cases · 6 runs.
- In `trap-local-dev-password`, `vibe-audit` reported the password in all three runs as **unverifiable** — "looks local-only, but the repository alone cannot
  tell whether it matches the deployed environment". It did not report it as a defect, and it did not close it as "local-only, so not a defect" either. The failing
  run is the one that also wrote the auditors' rule that unverifiable items count like nonconformities for pass/fail.
- In the same case, `pr-review-toolkit`'s 1/3 includes one borderline run (it put the password under a "note" heading as advice). In those three runs the plugin's
  review skill was called but did not launch its review agents — the main session read the files itself — at $0.145 per run.
- These numbers hold only for this material (`ba1f955`), this suite model (`claude-sonnet-5-5`) and this competitor commit (`anthropics/claude-plugins-official`
  `a7ba5b9`). Other material, models or versions need a new measurement.
- The plugin arms were called by name at the top of the request. Whether the auditor is picked when it is only installed is measured separately by the trigger
  suite; whether an installed-only auditor also tells the trap apart was not measured in one run.
- Raw cost per run: `vibe-audit` $0.21 · no plugin $0.13 · `pr-review-toolkit` $0.48 (the earlier 24-run measurement) · `claude-security` $0.65.

Tables, judging rules and raw output (Korean): `docs/eval-log/2026-11.md` — "다른 플러그인과 맞대기 — 조각 51 PR C" · "`claude-security` 다시 재기 — 조각 52 PR C" ·
"`pr-review-toolkit` 의 빈 칸 — 조각 52 PR C" — and ADR 0066 · 0069 · 0070.

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
@vibe-audit:audit-secrets only under backend/app
@vibe-audit:audit-data the migrations in this PR
```

If you wrote the code in this same session, run the audit in a new session — otherwise it checks with the assumptions it just made. To compare against a base
(a PR, a branch, a commit range), build a brief first with `/vibe-audit:audit-brief <base> [auditor]`; auditors cannot run git themselves.

| When | Run |
|---|---|
| A PR touching layers that are costly to undo (schema, credentials, permissions) | `audit-data`, `audit-secrets` |
| A PR touching the public API | `audit-contract` |
| Right before the first deploy | `audit-ops`, `audit-quality` |
| After merging three or four slices | `audit-internal` |
| After an incident | `audit-ops` → again `audit-ops` after the fix |

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
