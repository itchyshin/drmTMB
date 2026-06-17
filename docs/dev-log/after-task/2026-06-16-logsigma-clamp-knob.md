# After Task: log(sigma) clamp knob (Phase 4)

## Goal

Make the Gaussian `log(sigma)` overflow guard (#576) auditable instead of a
fixed, hidden constant: expose its band and margin as a `drm_control()` knob,
with a disable option, so a user can widen it for legitimately huge-variance
(unstandardized) data or turn it off to see the raw overflow. Default behavior
is unchanged. This closes the "could the guard silently mask a real fit?" risk
that Gauss and Rose flagged, and it turns the convergence/controls documentation's
"planned knob" into a real control.

## Implemented

- `src/drmTMB.cpp`: two new DATA fields, `DATA_INTEGER(use_logsigma_clamp)` and
  `DATA_VECTOR(logsigma_clamp)` (length 3: lo, hi, margin). The three clamp call
  sites (univariate Gaussian, bivariate `sigma1`/`sigma2`) are guarded by
  `if (use_logsigma_clamp == 1)` and read the band from `logsigma_clamp` instead
  of the hardcoded `(-12, 12, 3)`. Disabling uses a flag (no `Inf` math), so the
  AD tape stays clean.
- `R/control.R`: `drm_control()` gains `logsigma_clamp = c(-12, 12)` and
  `logsigma_clamp_margin = 3`, validated (band is `NULL` or a length-2 numeric
  `c(lo, hi)` with `lo < hi`; margin a single positive number), and recorded in
  the control structure. `logsigma_clamp = NULL` disables the guard. Both names
  are automatically reserved from the plain-list `control =` path.
- `R/drmTMB.R`: the universal `add_covariance_block_tmb_data()` merge point adds
  the default fields (`use_logsigma_clamp = 1L`, `logsigma_clamp = c(-12, 12, 3)`)
  so every model carries them; `drmTMB()` then overrides them from `control`
  (disable when `NULL`; otherwise the band + margin). Mirrors the penalty's
  DATA-default pattern.

## Mathematical contract

No likelihood change at the default band: with `use_logsigma_clamp = 1` and
`logsigma_clamp = c(-12, 12, 3)` the objective is bit-identical to #576 (the
clamp is identity inside `[-12, 12]`). Disabling sets `use_logsigma_clamp = 0`,
which skips the soft-clamp entirely (the raw `log(sigma)` linear predictor is
used). The band is a numerical guard only; it does not change identifiability.

## Files Changed

- `src/drmTMB.cpp`, `R/control.R`, `R/drmTMB.R`,
  `tests/testthat/test-logsigma-clamp.R` (knob tests),
  `tests/testthat/test-phylo-utils.R` (the hand-built `phylo_prior_tmb_data`
  helper gains the two new DATA fields, like the penalty fix),
  `NEWS.md`, this note, `docs/dev-log/check-log.md`.

## Checks Run

```sh
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = 'logsigma-clamp|phylo-utils|covariance-block-registry')"
Rscript -e "devtools::test(reporter = 'summary')"   # full suite (regression guard)
git diff --check
```

Results:

- The C++ compiled cleanly. `logsigma-clamp` tests pass: the default band is
  recorded as `c(-12, 12, 3)` with `use_logsigma_clamp = 1L`; a configured band
  (`c(-20, 20)`, margin 2) is recorded; disabling sets `use_logsigma_clamp = 0L`
  and the unclamped inner solve overshoots (emits the `NA/NaN` function-evaluation
  warnings the clamp otherwise prevents); `drm_control()` rejects a reversed,
  wrong-length, or non-numeric band and a non-positive margin. The two
  pre-existing default-band clamp tests still pass (bit-identity guard).
- `phylo-utils` and `covariance-block-registry` pass: the new required DATA
  fields are supplied for direct-`MakeADFun` tests via the universal
  `add_covariance_block_tmb_data()` default and the `phylo_prior_tmb_data()`
  helper.
- `document()` updated `man/drm_control.Rd` (both new arguments documented); the
  pre-existing `man/rho_latent.Rd` drift was reverted.
- Full suite: run as the regression guard for the universal `tmb_data` + DATA
  change; 3-OS CI re-runs it on the PR.
- `git diff --check`: clean.

## Tests Of The Tests

The knob tests were written first: the default band is recorded as
`c(-12, 12, 3)` with `use_logsigma_clamp = 1L`; a configured band
(`c(-20, 20)`, margin 2) is recorded; disabling (`logsigma_clamp = NULL`) sets
`use_logsigma_clamp = 0L` and lets the pathological per-tip scale-phylo fixture
push `log_sigma` past the `[-15, 15]` band the clamp would otherwise enforce;
and `drm_control()` rejects a reversed band, a wrong-length band, a non-numeric
band, and a non-positive margin. The two pre-existing clamp tests (default
identity for a healthy fit; default boundedness for the pathological fit) are
the bit-identity guard for the default band.

## Scope / Deferred

- An "active at the optimum" warning (reporting that the clamp bound at the
  fitted optimum) is deferred to a follow-up; this slice is the configurable band
  + disable.
- The convergence/controls docs (doc 174, `vignettes/convergence.Rmd`) describe
  the clamp as a fixed guard with a planned knob; a tiny follow-up updates that
  wording to "knob" once both PRs land.

## Team

Gauss owns the TMB band plumbing; Boole the `drm_control()` surface and naming;
Rose the auditability rationale (disable to see the raw overflow); Noether the
default bit-identity; Ada gates. Built during the autonomous block.
