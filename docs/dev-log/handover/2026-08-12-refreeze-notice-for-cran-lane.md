# Re-freeze notice for the 0.7 CRAN lane — the candidate and `main` now differ in compiled code

**2026-08-12 · from the MSPL non-logit lane (Claude) → the 0.7 CRAN lane (Codex)**
**Docs only. This notice changes no code, no ledger, no rung, and makes no release claim.**

You already record that the 0.7.0 candidate no longer matches `main` and that a re-freeze is
required. **This notice is not that reminder.** It is a change in the *kind* of re-freeze needed, and
one specific hazard that is worth naming before a submission.

## The hazard, stated once

`DESCRIPTION` on `main` still reads **`Version: 0.7.0`** — the same string the frozen candidate
carries — while **17 shipped files have changed**. A tarball cut from `main` today would therefore be
**a different 0.7.0**: same version, different bytes, no version-string signal that anything moved.

That is the state in which a package gets submitted having been tested as something else.

## What changed, by kind

Candidate `a75c3c901` (tarball `2176e4b8…cda9`) against `main` `98057133d`:

| kind | count | files |
|---|---|---|
| **`src/`** | **1** | `src/drmTMB.cpp` |
| `R/` | 4 | `drmTMB.R`, `mspl-estimator.R`, `mspl.R`, `profile.R` |
| `man/` | 2 | `confint.drmTMB.Rd`, `drmTMB.Rd` |
| `tests/` | 5 | four MSPL/link files, one missing-response |
| `vignettes/` | 3 | three capability-ledger includes |
| `inst/` | 1 | `sim/R/sim_missing_response_g4g5.R` |
| `NEWS.md` | 1 | shipped — **not** in `.Rbuildignore` (checked) |

Reproduce with:

```sh
git diff --name-only a75c3c901 origin/main -- \
  R/ src/ tests/ man/ vignettes/ NAMESPACE DESCRIPTION inst/ data/ NEWS.md
```

## Why the `src/` row is the one that matters

Until 2026-08-11 the drift was **R-level only** — `R/`, `man/`, `tests/`. The compiled object was
byte-identical to the frozen tarball's, so platform evidence keyed to `2176e4b8…` still described the
same binary, and a re-cut alone would have sufficed.

`src/drmTMB.cpp` has since changed (PR #1012, the MSPL Jeffreys weight made link-dispatching).
**Platform evidence keys on bytes, and the bytes have moved.** So:

- **sanitizer, valgrind, 3-OS and win-builder results against `2176e4b8…` no longer describe what
  would ship.** They are predecessor evidence. Do not carry them forward.
- A re-cut is necessary but **not sufficient** — the platform matrix has to be re-run against the new
  artifact.

win-builder had not run against `2176e4b8…` in any case, so nothing is lost there; the point is that
the other three classes cannot be reused either.

## What is NOT being claimed

This notice does not advance or retract any rung, does not touch `status_claim`, and does not assert
the candidate is unfit — only that it is **stale in a way that now includes compiled code**. Whether
to re-freeze now, or defer the MSPL work to 0.7.1/0.8.0 and re-cut from an earlier point, is entirely
the CRAN lane's call. Both are reasonable; only carrying old platform evidence onto new bytes is not.

## Where the changes came from, if you need to unwind any of them

| PR | what | shipped paths |
|---|---|---|
| #1006 | estimator round-trip + documented limits | `R/`, `man/`, `tests/` |
| **#1012** | **MSPL Jeffreys weight dispatches on link** | **`src/`**, `R/`, `tests/` |
| #1020 | MSPL admits probit and cloglog | `R/`, `man/`, `tests/`, `NEWS.md` |
| others | capability-ledger vignette includes, missing-response sim | `vignettes/`, `inst/`, `tests/` |

#1012 and #1020 are one arc and unwind together. Their evidence is on `main` under
`docs/dev-log/simulation-artifacts/2026-08-11-mspl-nonlogit-links/`, and neither is on the 0.7
critical path — deferring them costs the release nothing.

## Lane boundary

Written from a lane that does **not** own the CRAN ladder. The `AGENTS.md` `▶ Latest` pointer is
yours and was not touched; `active-lane-split.md` was not touched either, since several live refs
carry unmerged edits to it. Full context for the MSPL arc, if wanted:
[`2026-08-11-codex-handover-mspl-nonlogit.md`](2026-08-11-codex-handover-mspl-nonlogit.md).
