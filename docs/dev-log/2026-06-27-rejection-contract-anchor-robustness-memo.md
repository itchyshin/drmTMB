# Decision memo: make structured-rejection contracts anchor on a condition class, not a message substring

Reader: the drmTMB maintainer (Shinichi). Author: Claude, 2026-06-27. Status:
**advisory — engine change NOT made** (handover item 5 is explicitly "do not
self-fix"; this memo gives you the decision, the evidence, and an exact change to
approve or decline).

## Purpose

The q-series rejection contracts (#676 count-sigma, #678 non-Gaussian family, and
the new #683 count-`mu`) document engine boundaries by matching the **text of the
engine's error message**. That coupling is fragile: a cosmetic reword of a
`cli::cli_abort` line silently breaks the contracts, the tests, and the validator,
with no compile-time signal. This memo recommends anchoring on a **custom
condition class** instead. It became more pressing with #683, which added six more
message-anchored cells.

## Evidence — the current coupling

`grep` over the repo (2026-06-27) shows the rejection boundary text is load-bearing
in four layers at once:

- **Engine**: the structured-rejection `cli::cli_abort` calls in `R/drmTMB.R`
  (`validate_poisson_mu_random_terms` ~6772, `select_count_mu_structured_term`
  ~6810, `validate_count_structured_mu_term` ~6828, plus the count-gate hint at
  6631) carry **no `class =`**. They are plain message conditions.
- **Tests** anchor on substrings via `expect_error(..., "<phrase>")`:
  `test-count-structured-mu.R`, `test-nongaussian-structured-boundary.R`,
  `test-nbinom2-location-scale.R`, `test-structured-re-conversion-contracts.R`.
- **Dashboard sidecars** record an `expected_error_pattern` column:
  `structured-re-count-slope-sigma-one-slope-rejection-contract.tsv`,
  `structured-re-nongaussian-structured-family-rejection-contract.tsv`,
  `structured-re-q2-plus-q2-sigma-rejection-contract.tsv`,
  `structured-re-count-structured-mu-rejection-contract.tsv`.
- **Validator** (`tools/validate-mission-control.py`) hard-checks those patterns
  (e.g. lines 11319, 11502, 11545-11580).

### The worst offender

`"Structured non-Gaussian paths"` is a **hint line** (`"i" =`) at
`R/drmTMB.R:6631`, *not* an abort headline. Rewording that single cosmetic hint
silently breaks **~8 anchor sites** (2 sidecars + 4 test files + validator ×2 +
`README.md`). This is exactly the fragility flagged in the handover.

### The new contracts are less fragile (but still coupled)

The #683 count-`mu` patterns anchor on **headline / `x`-line** substrings
(`"cannot be combined"` 6859, `"Only one structured"` 6817, `"unlabelled q=1"`
6866, `"intercept-only or one-slope"` 6875, `"Zero-inflated Poisson/NB2 structured
random effects"` 6853) — more stable than a hint line, but still a text match.

### Precedent already in the codebase

drmTMB **already** classes its *warning* conditions:
`drmTMB_convergence_warning`, `drmTMB_nonfinite_objective_warning`,
`drmTMB_clamp_active_warning` (`R/drmTMB.R`), `drmTMB_wald_boundary_warning`
(`R/profile.R`), `drmTMB_ic_map_warning`/`drmTMB_ic_reml_warning` (`R/methods.R`).
The rejection *errors* simply have not adopted the same pattern yet.

## Options

**A. Move the phrase to the abort headline (narrow).** Promote
`"Structured non-Gaussian paths"` from the 6631 hint to the abort headline so the
anchor sits on a more deliberate line. Cheap, but still a message-substring anchor;
it only de-risks the one phrase and leaves the general fragility in place.

**B. Anchor on a custom condition class (recommended).** Add
`class = "drmTMB_structured_rejection"` (optionally a per-gate subclass, e.g.
`drmTMB_structured_rejection_zi`) to the structured-rejection `cli_abort` calls,
mirroring the existing warning-class precedent. Then:
- tests use `expect_error(..., class = "drmTMB_structured_rejection")` instead of a
  substring;
- the sidecars keep `expected_error_pattern` for human documentation but add a
  stable `rejection_class` column that the validator checks;
- the validator anchors on the class, not the message.

Message text is then free to be reworded for users without breaking any contract.

## Recommendation

**Option B.** It removes the fragility class entirely rather than relocating one
instance of it, it reuses an established in-repo pattern, and it lets the
user-facing error prose evolve freely. Option A is a stop-gap.

### Concrete change sketch (for your approval — not applied)

1. In `R/drmTMB.R`, add `class = "drmTMB_structured_rejection"` to each
   structured-rejection `cli::cli_abort(c(...))` (the calls in
   `validate_poisson_mu_random_terms`, `select_count_mu_structured_term`,
   `validate_count_structured_mu_term`, and the non-Gaussian / count-sigma /
   q2-plus-q2 gates). cli passes `class` through to `rlang::abort`.
2. In the four `test-*` files, change the substring `expect_error(..., "<phrase>")`
   to `expect_error(..., class = "drmTMB_structured_rejection")` (keep one
   message-substring assertion per gate if you want a human-readable check).
3. Add a `rejection_class` column to the four rejection-contract sidecars and have
   `tools/validate-mission-control.py` check it; downgrade `expected_error_pattern`
   to documentation-only (no longer the contract anchor).

This is a coordinated engine + test + dashboard + validator change touching guarded
prose, so it is yours to approve. Until then, the contracts remain correct (the
messages are accurate today) but coupled — keep rewordings of the listed
`cli_abort` lines in lockstep with the tests, sidecars, and validator.

## What this does NOT change

No model behaviour, no support status, no `coverage_status`. Every rejection cell
stays `unsupported`. This is purely about how the contracts are *anchored*.
