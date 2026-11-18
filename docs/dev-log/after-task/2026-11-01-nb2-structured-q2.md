# After-task: NB2 animal intercept-plus-slope (q2) with coefficient SDs

Date: 2026-11-01. Lane: codex/general-sd-regression (base ea2e2aed7).

## Inconsistency

Gamma, Beta and Binomial admit `animal(1 + x | id)` (unlabelled, independent
fields) and `animal(1 + x | p | id)` (labelled, one cross-coefficient
correlation) with one `sd(id, level = "animal", coef = ...)` formula per
coefficient. NB2 refused both: the R guard allowed one SD formula, and the C++
nbinom2 block raised an error whenever the structured SD model met a q2 block.

## What was done

Native engine only. No Julia route was touched or run.

- `src/drmTMB.cpp`, nbinom2 block: the structured SD branch now accepts q = 2
  with per-coefficient SD rows (`phylo_mu_sd_row_coef`, the same data the Gamma
  block reads). The correlated branch gains a unit-scale prior for the case
  where SD formulas are present: N(0, R kron A) with
  rho = 0.999999 tanh(eta_cor_phylo), the Gamma form. The earlier branch that
  estimates two constant SDs (labelled, no SD formulas) is unchanged.
- `R/drmTMB.R`, `drm_build_nbinom2_spec`: for an animal term with an intercept
  and one slope, the guard asks for exactly two SD formulas, the coefficient
  selectors are checked (one per coefficient), duplicate dpar names are
  relabelled per coefficient, and the shared identifiability check used by
  Gamma runs. Labelled animal q2 is admitted only when SD formulas are present.
  The guard message now names the q2 form. `make_tmb_data` sets the
  per-coefficient SD flag for nbinom2 animal terms.
- The shared parser (`parse_sd_phylo_entries`) already supported multiple
  coefficients, so it was not edited.
- New file `tests/testthat/test-nbinom2-structured-q2-sd-regression.R`.

## Oracle and checks

The test oracle shares no code with the C++ objective. It uses dense A, name
based alignment, `stats::dnbinom`, and an analytic dense Hessian for the
Laplace objective. The kernel has a non-unit diagonal and the factor levels of
`id` are shuffled relative to A. Tolerances were fixed before the first run:
joint objective 1e-6, Laplace objective 1e-5, bug sensitivity 1e-3,
constant-SD equivalence logLik 1e-3 and coefficients 1e-2.

- Joint and Laplace objectives agree with the oracle on three fixed seeds
  (labelled) and one unlabelled fit.
- Six emulated bugs (log determinant counted once, cross term sign, dropped
  correlation, swapped SD formulas, swapped fields, misaligned levels) each
  move both oracle quantities by more than 1e-3.
- Constant SD formulas on both coefficients reproduce the formula-free
  unlabelled animal q2 fit.
- Refusals still closed, with message patterns: labelled animal q2 without SD
  formulas, one SD formula on a q2 block, two formulas on one coefficient,
  relmat q2 with SD formulas, an ordinary random effect beside the animal q2
  block, zero-inflated NB2, and a three-coefficient block.
- No existing test pinned the old refusal, so no test was swapped.

Results on Totoro (4 cores or fewer, `NOT_CRAN=true`). The new file first ran
with one error caused by my own refusal patterns (two refusals come from the
parser or an earlier guard with different, equally designed messages, and one
case used a family constructor that does not exist). Patterns were corrected,
no numeric tolerance was touched. Final run: 75 passed, 0 failed, 0 errors,
0 skipped.

Neighbouring files, same Totoro session (passed / failed / error / skipped):
nbinom2-animal-sd-regression 16/0/0/0; nbinom2-animal-slope-sd-regression
9/0/0/0; nbinom2-correlated-q2-sd 12/0/0/0; nbinom2-ordinary-correlated-q2
25/0/0/0; nbinom2-phylo-sd-regression 4/0/0/0;
nbinom2-phylo-relmat-slope-sd-regression 38/0/0/0;
nbinom2-relmat-spatial-intercept-sd-regression 34/0/0/0;
nbinom2-spatial-slope-sd-regression 23/0/0/0; nbinom2-batch3-sd-regression
0/0/0/3 (skips); nbinom2-batch5-sd-regression 150/0/0/0;
nbinom2-structured-slope-marginal-simulate 42/0/0/0;
nbinom2-sigma-structured-recovery 6/0/0/0; structured-sd-nonunit-k-and-missing
53/0/0/0; zi-nbinom2-sd-regression 43/0/0/0; phase18-nbinom2-phylo-q1 91/0/0/0;
gamma-animal-q2-correlated-sd 46/0/0/0 (shared C++ and tmb-data plumbing);
count-structured-mu 532 passed, 1 failed.

The one failure, `count structured mu keeps planned neighboring routes closed`,
expects `nbinom2` with `spatial(0 + x | site)` and no `sd()` formula to be
refused ("intercept-only or one-slope"). That route is already admitted at the
base commit (the slope-only type list includes spatial for NB2, and
`test-nbinom2-spatial-slope-sd-regression.R` fits it). The failure is therefore
not caused by this change, but I did not run the base commit to prove it, and I
did not edit that stale assertion.

## Not covered

- phylo, relmat and spatial q2 with coefficient SDs stay refused for NB2. The
  C++ change is provider-generic, so admission is an R guard change plus the
  same oracle test per provider; it was not done here.
- Labelled constant-SD equivalence against a formula-free fit: NB2 refuses a
  labelled animal q2 term without SD formulas, so only the unlabelled form has
  that comparison. The labelled form is checked by the oracle and by nesting.
- One synthetic design (48 animals, 20 records each). Recovery bands are fixed
  seed checks, not calibration, coverage or parity claims.
- Zero-inflated NB2, sigma-endpoint structured SDs, mixed ordinary plus
  structured q2, missing-response integration and the mesh route.
- Julia: no DRM.jl route exists for NB2 animal q2 and none was added.
