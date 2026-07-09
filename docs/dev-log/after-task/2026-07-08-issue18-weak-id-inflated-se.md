# After Task: point-6 weak-ID diagnosis (#18) + inflated-SE check (#19) + boundary-message sharpening

Meta: 2026-07-08 · Claude (Opus 4.8) · repo `drmTMB` · branch
`drmtmb/fix-16-phylo-mu-diagnostics` (continues from #16) off `main` `bed29701`.

## 1. Goal

Investigate A. Mizuno's point 6: two bivariate M2 fits with inflated SE on the second
trait despite `conv=0` / `pdHess=TRUE` and `rho12≈0.02`. Decide between better default
starts, a `check_drm` warning, or a documented boundary (#18). Then, per the user's
scope choice: sharpen the existing boundary warning, build the #19
inflated-SE-despite-clean-Hessian diagnostic, and draft an Ayumi reply.

## 2. Implemented

- **Diagnosis (#18).** Reproduced the pattern (`scratchpad/repro_18*.R`): a bivariate
  phylo cross-correlation model (`phylo(1|p|species)` + constant
  `corpair(...phylogenetic...)~1`) with weak second-trait phylo variance. The inflated
  SE is the **phylo cross-correlation coefficient** (Wald SE ≈ 2000 on the atanh scale),
  not the trait means (their SEs are normal). Root cause: weak trait-2 phylo signal pulls
  `sd_phylo2 → 0`, so the cross-correlation is non-identified and runs to ±1 along a flat
  likelihood ridge. Evidence: (a) multi-start gives an identical `nll` (not a local
  optimum); (b) the profile likelihood is flat with no extractable CI. `pdHess` stays TRUE
  because the ridge is only numerically near-flat.
- **Sharpened boundary warning.** `bivariate_phylo_mu_diagnostic_message()` (the two
  `near_rho_boundary` branches) now states that a large SE on the correlation despite a
  clean Hessian is the *expected symptom* of the weak identification, not evidence
  against it.
- **New check (#19) `standard_errors_inflated`.** Fires (as a **note**) when a fixed-effect
  Wald SE is finite but both absolutely large (≥ 50 on the link scale) AND ≥ 1000× the
  median finite SE, on a fit TMB reports as converged with `pdHess = TRUE`. Names the
  offending parameter; defers (returns `NULL`) when there is no sdreport / no
  positive-definite Hessian (those are `check_hessian` / `check_standard_errors_finite`'s
  job). Registered in the `check_drm()` dispatch after `check_standard_errors_finite`.
- **check_drm roxygen** updated to enumerate the new check.
- **Ayumi reply** drafted at `scratchpad/ayumi-point6-followup-DRAFT.md` (not posted;
  Shinichi posts).

## 3a. Decisions and Rejected Alternatives

- **Better default starts: rejected.** Multi-start returns the identical optimum — it is
  structural non-identification, not a local optimum, so more starts cannot help.
- **Warning vs note for #19: chose note.** The phylo boundary case is already a *warning*
  via `biv_phylo_mu_covariance`; a second warning would be redundant and would flip
  `attr(chk,"ok")` on a heuristic threshold. A note is visible, non-disruptive, and
  complements the structural check for non-phylo cases. (A note never changes `attr ok`,
  which is set only by warning/error.)
- **Threshold: absolute floor AND ratio-to-median, not either alone.** Two conditions make
  false positives on well-identified fits extremely unlikely while still catching the
  boundary runaway (SE in the thousands). A pure ratio would false-positive when all SEs
  are tiny; a pure floor would false-positive on unstandardised data.
- **SD source for #16 (carried context): `object$sdpars[[dpar]]`, not `report()$sd_phylo_group`.**

## 4. Files Touched

- `R/check.R` — `check_standard_errors_inflated()` + registration; sharpened
  `bivariate_phylo_mu_diagnostic_message()`; roxygen enumeration.
- `tests/testthat/test-check-drm.R` — new #19 test (real weak-ID fit → note naming the
  cross-correlation); `clean Hessian` assertion on the existing near-boundary test.
- `man/check_drm.Rd` — regenerated from roxygen.
- `docs/dev-log/after-task/2026-07-08-issue18-weak-id-inflated-se.md` — this note.

## 5. Checks Run

- `test-check-drm.R` → FAIL 0 | PASS 270 (+8 from the #19 test).
- Manual: #19 fires (`note`, `n_inflated=1`, names `corpair`) on the weak-ID fit; a
  healthy strong-both-traits control gives `n_inflated=0` (no false positive); the
  sharpened warning contains "clean Hessian".
- Full `devtools::test()` — see §5a (running / result recorded below).

## 5a. Full-suite result

- `devtools::test()` over `tests/testthat` → **TOTAL FAIL 0 | PASS 36656** (was 36648
  before #19; +8 from the new test). The globally-dispatched `standard_errors_inflated`
  note appears on every converged pdHess fit and regressed nothing.

## 6. Tests of the Tests

- The #19 test asserts `n_inflated=1` (exactly one), which doubles as the false-positive
  guard: the other seven coefficients in the same fit are NOT flagged.
- The premise `expect_true(isTRUE(fit$sdr$pdHess))` makes the test fail loudly if the
  fixture ever stops exhibiting the "clean Hessian" condition it is meant to probe.

## 7a. Issue Ledger

- #18 — resolved (diagnosis + decision recorded). #19 — implemented. No new issues.
  Point-6 reply to Ayumi drafted, pending Shinichi's post.

## 8. Consistency Audit

- The new check reuses the exact vcov→diag→sqrt path of `check_standard_errors_finite`,
  keeping the two SE checks consistent. Rose sweep: no other `*_mu_diagnostics` sibling
  needed the boundary-message sharpening (only the phylo mean-mean correlation exposes a
  boundary-runaway cross-correlation in current grammar).

## 9. What Did Not Go Smoothly

- `stree(n, "balanced")` requires a power-of-two `n` (40 failed; used 32).
- `summary(fit)$coefficients` has only `estimate`/`std_error` columns (no `dpar`/`term`),
  so the first sweep returned NA SEs until the extractor was corrected.

## 10. Known Residuals

- The #19 thresholds (50, 1000×) are heuristic. They are deliberately conservative; if a
  real fit is found where a genuinely identified parameter trips them, revisit. Not
  exposed as user-tunable arguments yet (kept internal to avoid API surface creep).
- #19 is a **note**; if Shinichi wants boundary runaways to hard-stop interpretation, it
  could be promoted to a warning — a one-line change.

## 11. Team Learning

- `pdHess = TRUE` + huge Wald SE + flat profile + multi-start-invariant `nll` = genuine
  non-identification along a boundary ridge. The four together are the signature; any one
  alone is ambiguous. Banked to LEARNINGS.
- For a bounded-transform parameter (correlation via atanh), a link-scale SE in the tens
  or higher already means the back-transformed CI covers the whole feasible range —
  a cheap, scale-aware non-ID signal.

## 12. Cross-Product Coverage

- **covers ✓**: the bivariate phylo mean–mean cross-correlation boundary-runaway
  (reproduced, diagnosed, flagged by two check rows); a generic finite-but-inflated Wald
  SE on any converged pdHess fit (new #19 note); sharpened wording on both
  `near_rho_boundary` message branches.
- **does NOT cover ✗**: no change to the optimizer, the likelihood, or default starts (the
  problem is structural, not numeric); #19 does not profile parameters (it is a cheap Wald
  heuristic, not a full identifiability proof) and is not promoted to a warning; no change
  to Ayumi's real fits (mechanism reproduced on synthetic data, not read off her data);
  the #20 ML/REML guidance note and #17 fixture test are separate, still open.
