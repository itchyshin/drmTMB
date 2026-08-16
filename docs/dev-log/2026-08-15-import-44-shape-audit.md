# The 44-cell 2026-07-11 import, audited against the shape contract

**Date:** 2026-08-15 (overnight) · **Lane:** `claude/lane-overnight-0815`
**Status:** FACTS ONLY. The disposition is Shinichi's — this document does not change a single tier.

## Why this exists

`docs/design/255` decided that `interval_feasible` claims **shape**: a finite, ordered, unclamped
interval from a converged, pdHess-positive fit. It claims nothing about location. That decision made
a previously-unanswerable question answerable: **do the 44 cells of the 2026-07-11 migration import
meet the tier's own standard?** Their only ledger evidence is a `legacy_model_evidence` row citing
source code and tests, so the question is simply whether the cited test computes and checks an
interval.

Four independent agents audited 11 cells each, searching campaigns (simulation-artifacts, all
dashboard TSVs, campaign bindings, `check-log.md`, after-task, and `git log --all -S<cell>`) before
reading the cited tests.

## The result

| verdict | cells | meaning |
| --- | ---: | --- |
| **B — shape-justified** | **19** | the cited test computes an interval and asserts finite, ordered endpoints. **Correctly tiered.** |
| **C — not even shape** | **22** | no campaign, and the cited evidence never computes an interval at all. **The tier is unearned under its own definition.** |
| **A — unwired campaign** | **3** | a real coverage campaign exists but is not wired — see the warning below |

### The 22 (C) — what their evidence actually is

Not "weak evidence for an interval" but **no interval**. Representative findings:

- `mc-0029`, `mc-0031`, `mc-0240`, `mc-0244`, `mc-0488` — the cited test only checks that a
  `profile_targets()` row *exists* (a `profile_ready` flag, or membership), never calling `confint()`.
- `mc-0177`–`mc-0181` (biv_gaussian fixed) — neither cited range contains a `confint()` call; the
  file's only `confint()` (line 1419) belongs to an unrelated test.
- `mc-0210`, `mc-0211` — assert a finite **standard error**, not an interval; the test's own comment
  says so.
- `mc-0236`, `mc-0238` — three cited files, zero `confint()` calls; an *uncited* test fits the
  identical route and does check intervals, but is wired to the lognormal siblings instead.
- `mc-0559`–`mc-0562` — **citation drift**: the cited lines now point at DGP helper code; the real
  test moved to 1794-1853 and asserts only `conf.status == "wald"`.
- `mc-0487`, `mc-0510`, `mc-0378` — a recurring pattern worth its own note: phase18 smoke tests
  assert `interval_status == "ok"` for the fixed-effect rows but only *row counts* for the paired
  random-effect SD row. The fixed-effect half is checked; the RE half is not.

### The 3 (A) — and why this is a WARNING, not a promotion

`mc-0484`, `mc-0485`, `mc-0486` (student mu / sigma / nu) have a genuine unwired campaign:
`docs/dev-log/simulation-artifacts/2026-06-19-student-nu-wald-calibration-diagnostic/` (200 fits),
referenced nowhere in the ledger.

**Its measured Wald coverage is 0.81–0.86 against a nominal 0.95.** Wiring it would not upgrade these
cells; on the evidence it would justify `location_checked = failed`. This is the mirror image of the
16-cell re-wire earlier today — there, unwiring hid *good* evidence; here it hides *bad* evidence.
**Do not wire it as a promotion.** It needs its own review.

## What follows, and what does not

**Follows from the shape contract, mechanically:** the 22 (C) cells do not meet `interval_feasible`
as defined. Two dispositions are available and both are defensible:

1. **Demote to `point_fit_recovery` or `diagnostic_only`** — matching what today's tier decision
   implies, and consistent with how the four `supported` legacy cells were re-tiered.
2. **Close the gap instead** — add the missing endpoint assertions to their cited tests, exactly as
   the 14 label-only sites were closed today, and keep the tier. For several of the 22 this is a
   two-line change; for those whose cited test never calls `confint()` at all it is more.

**Does NOT follow:** that these routes are broken, that the models do not fit, or that any user-facing
claim is currently false. The reader surface grants `interval_feasible` cells **no calibrated
interval-reporting permission**, so nothing is over-promised to a reader today. What is wrong is the
ledger's internal accounting of why the tier was granted.

**Recommendation, for the record:** option 2 for the subset whose test already calls `confint()`
(cheap, and it makes the claim true rather than removing it), option 1 for the rest. I have not acted
on either — a 22-cell tier change is a claims decision, and it is yours.

> ### ⚠ Option 2 is NOT free — measured overnight, not assumed
>
> I attempted the cheap half on `mc-0559`–`mc-0562` (zero_one_beta): their test at
> `test-zero-one-beta.R:1794-1856` *does* call `confint()`, so three assertions should have closed
> them. The assertions worked — file green at 1521 passes, and the deliberate-red mutation failed
> correctly (`FAIL=1`).
>
> **But the C14/C17 source-bound guard rejected it:** `test-zero-one-beta.R` is pinned as the source
> blob behind **`mc-0568`'s retained receipt** — one of the five 5-seed cells whose location check
> passed tonight. Any edit to that file, however additive, breaks a real provenance binding
> (`SystemExit: mc-0568: current source blob differs`).
>
> **Reverted.** A convenience fix is not worth invalidating a receipt binding. The lesson generalises:
> **for any cell whose cited test is also source-bound evidence for another cell's receipt, option 2
> is blocked** — the test file cannot be touched without re-pinning that receipt, which is a
> provenance decision, not a test improvement. Whoever takes this on should first partition the 22 by
> whether their cited test is blob-pinned. The citation-drift repair for those four (pointing at the
> real test block instead of DGP helper code) is metadata only and was kept.

## Provenance

Per-cell evidence, queries run, and negative results: `scratchpad/overnight-import-batch{1,2,3,4}.md`.
Every verdict cites a file and line; every negative lists the queries behind it. Two citation errors
of my own were found by this audit and repaired in commit `2706b42e1`.
