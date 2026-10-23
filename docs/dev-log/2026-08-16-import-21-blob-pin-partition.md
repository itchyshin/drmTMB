# Blob-pin partition of the 21 demoted import cells

**Date:** 2026-08-16 · **Lane:** `cursor/interval-truth-owed` · **Base:** `origin/main` @ `723ed80a0`
**Reader:** whoever next tries to re-earn `interval_feasible` for a cell demoted by PR #1054.
**Status:** FACTS ONLY. This document does not change a tier, a test, or a pin.

## Why this exists

The 2026-08-16 interval-truth handover asked for a mechanical partition: for each import cell
whose cited evidence never computed an interval, is that cited test file also a pinned source
blob? The overnight zero_one_beta attempt showed why the question is load-bearing —
`tests/testthat/test-zero-one-beta.R` is the current-source blob behind `mc-0568` /
`mc-0569` / `mc-0576`, so an additive assertion edit was written, proven, and reverted
(`docs/dev-log/2026-08-15-import-44-shape-audit.md`).

PR #1054 then demoted **21** of those cells (`interval_feasible` → `point_fit_recovery`,
`location_checked` → `not_applicable`). The 44-cell disposition is **DONE**. This partition
is now only about **re-earning** the tier, not about deciding it.

The audit table's "22" was a mis-tally (addendum on
`docs/dev-log/handover/2026-08-16-cursor-handover.md`). The demoted set is the 21 IDs
below.

## How the pins were read

Checked against live `origin/main` at `723ed80a0`:

1. `C17_C14_SOURCE_FILES` in `tools/capability_ledger.py` (the guard that raises
   `current source blob differs` for `mc-0568` / `mc-0569` / `mc-0576`).
2. `git_blob:tests/testthat/…` keys in committed C14/C16/C17 provenance TSVs.
3. Path columns of the B4-CI C1 / C2 / C3 manifests under
   `docs/dev-log/canonical-integration/` (C4 manifest is absent on this tree).
4. C14 candidate-evidence and C16 source-bound manifests.

C1–C3 pin **receipt / trace / interval artifacts**, not test files. The only testthat
file that is a live source blob is `tests/testthat/test-zero-one-beta.R`.

Cited test files were taken from each cell's `legacy_model_evidence` row in
`evidence.tsv` plus the citation column on `cells.tsv`.

## The partition

| class | n | meaning for a cheap assertion fix |
| --- | ---: | --- |
| **PINNED** | **4** | cited test is a live source blob for another cell's receipt. Do not edit the file to re-earn. |
| **UNPINNED** | **17** | cited test is not a C1/C14/C16/C17 source blob. A cheap assertion edit is *possible*; it is not authorised here. |

### PINNED — cheap fix blocked (4)

| cell | cited test | pin that blocks an edit |
| --- | --- | --- |
| `mc-0559` | `tests/testthat/test-zero-one-beta.R` | `C17_C14_SOURCE_FILES` + `git_blob:tests/testthat/test-zero-one-beta.R` on the C17 model-15 compatibility / ZOI-slope / COI-intercept receipts (`mc-0568` / `mc-0569` / `mc-0576`) |
| `mc-0560` | same | same |
| `mc-0561` | same | same |
| `mc-0562` | same | same |

This is the overnight measurement, re-derived: any byte change to that file fails
`capability_ledger.py --check` until those receipts are re-run and re-pointed. Re-pinning
is a provenance decision, not a test improvement.

To re-earn these four without touching the blob: add a **new** test file (or a new
evidence class citing a campaign), then wire that — do not edit `test-zero-one-beta.R`.

### UNPINNED — cheap fix not blob-blocked (17)

| cell | cited test file(s) |
| --- | --- |
| `mc-0029` | `test-beta-binomial.R`; `test-phase18-bounded-response-mu-random-intercept.R` |
| `mc-0031` | `test-nongaussian-mu-random-slopes.R` |
| `mc-0177`–`mc-0181` | `test-biv-gaussian.R`; `test-summary.R` |
| `mc-0210`, `mc-0211` | `test-reml-bivariate.R` |
| `mc-0236` | `test-comparators.R`; `test-emmeans-methods.R`; `test-gamma-location-scale.R` |
| `mc-0238`, `mc-0240` | `test-gamma-location-scale.R` |
| `mc-0244` | `test-nongaussian-mu-random-slopes.R` |
| `mc-0378` | `test-lognormal-location-scale.R`; `test-phase18-positive-continuous-mu-random-intercept.R` |
| `mc-0487` | `test-phase18-student-mu-random-intercept.R`; `test-student-location-scale.R` |
| `mc-0488` | `test-nongaussian-mu-random-slopes.R` |
| `mc-0510` | `test-phase18-truncated-nbinom2-mu-random-intercept.R`; `test-truncated-nbinom2-location-scale.R` |

"Unpinned" means only that an edit would not trip the `mc-0568` family of blob guards.
It does **not** mean the cited test already calls `confint()`, or that adding two
assertions would meet the shape contract. The import audit still stands: several of
these files only check `profile_targets()` row existence, a finite SE, or a
`conf.status` label. Re-earning still needs an interval that is computed and asserted
finite and ordered (`docs/design/255`).

Line-range repairs remain metadata-only and were already kept where the overnight
lane found citation drift.

## What this does not authorise

- No test edit.
- No receipt re-pin.
- No tier change (the 21 stay `point_fit_recovery` / `not_applicable` until new
  interval evidence is cited).
- No claim that the 17 unpinned cells are "easy".

Machine-readable copy: `docs/dev-log/dashboard/2026-08-16-import-21-blob-pin-partition.tsv`.
