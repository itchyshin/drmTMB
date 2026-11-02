# After Task: Julia-engine fits read the bridge `convergence_status` (#1564 with DRModels.jl #1129)

## Goal

Reader: the next drmTMB / DRModels.jl reviewer landing the FX3b pair.

`convergence_status.drmTMB_julia()` passed `mle_nonexistent = FALSE` to the
twin rules, so the DRModels.jl geometry screen (Poisson / NB2 cone, Gaussian
all-sigma collapse) could not reach R except through the bridge `converged`
flag. Two reviewer requests were folded into this pairing:

1. drmTMB #1564 reads the `convergence_status` key that DRModels.jl #1129
   sends through the bridge.
2. DRModels.jl #1129 gates the bridge `converged` key on
   `fit.geometry === :ok`, so a Poisson / NB2 fit whose MLE does not exist
   does not send `true`.

Merge condition (code review): a parity test that runs one boundary fit, one
inflated-SE fit, and one all-zero Poisson fit through both
`drmTMB(engine = "julia")` and DRModels.jl, and asserts the same status string.

## Implemented

- `R/check.R`: new `drm_julia_bridge_degenerate()`. It returns `TRUE` when
  `object$bridge[["convergence_status"]]` is `"degenerate"`, and
  `convergence_status.drmTMB_julia()` passes it as `mle_nonexistent`. A bridge
  without the key leaves the slot `FALSE`, as before.
- `R/julia-bridge.R`: the `drm_julia_opt_slot()` comment now describes the
  gated `converged` key.
- DRModels.jl `src/bridge.jl`: both `DrmFit` emission sites of `"converged"`
  now send `fit.geometry === :ok && _converged_nondegenerate(fit)`. A
  `:boundary` fit still sends `true`.

## Mathematical Contract

No predicate or constant changed. Design note 278 now states how an
`engine = "julia"` fit reaches steps 1 and 2: step 1 reads the gated bridge
`converged` key; step 2 reads the bridge `convergence_status` key, because the
bridge does not ship `fit.geometry` on its own. A Julia `"degenerate"` fills
the step-2 slot. The read can only make R stricter, never looser, and it is
stricter than the geometry screen alone: Julia's steps 3 to 5 run on the full
bridge covariance, which includes variance-component coordinates that the R
object's `vcov` drops. Measured on the binomial phylo fit in
`test-julia-phylo-nongaussian.R`: the phylo SD is 2.5e-4, the bridge
covariance is 3 x 3 with a zero `resd_species` variance and is not positive
definite, Julia says `"degenerate"`, and R's 2 x 2 fixed-effect block is
positive definite. Before this change R said `"converged"`; now both say
`"degenerate"`.

## Files Changed

- `R/check.R`
- `R/julia-bridge.R` (comment only)
- `tests/testthat/test-julia-convergence-status-parity.R` (new)
- `tests/testthat/test-julia-phylo-nongaussian.R` (binomial phylo floor: the
  fit is now `"degenerate"` on both engines; see Mathematical Contract)
- `inst/extdata/env-skip-census.tsv` (three rows for the new test file,
  written by `Rscript tools/write-env-skip-census.R`)
- `docs/design/278-twin-convergence-status.md`
- `docs/dev-log/after-task/2026-10-18-fx3b-bridge-convergence-status.md`
- DRModels.jl #1129: `src/bridge.jl`, `test/test_poisson_mle_existence.jl`,
  `news/1109-fx3b-convergence-status.md`

## Checks Run

drmTMB, `NOT_CRAN=true devtools::test()` on the Mac (live Julia not on
this lane, as in the FX3b run):

- Files 1 to 266: FAIL 5 | WARN 25 | SKIP 93 | PASS 14053. Two of the five
  were `test-env-skip-census.R`, which needed the three census rows for the
  new test file; after `Rscript tools/write-env-skip-census.R` it passes 5/5.
  The other three (`test-associate-pairs-bernoulli-bernoulli.R` 1,
  `test-nbinom2-sigma-structured-recovery.R` 2) fail identically on a
  3fd68189e worktree.
- File 267, `test-numeric-kernel-oracle.R`, hung inside TMB's
  `tweedie_logW` series loop (`tweedie.cpp:46`, sampled stack) for 90
  minutes. It also hangs on 3fd68189e (stopped after 10 minutes).
- Files 268 to 448: FAIL 0 | ERR 0 | WARN 39 | SKIP 14 | PASS 34354
  (83.3 min).
- `devtools::document()`: no change from this work. It rewrites 38
  unrelated `man/` pages (the #1400 drift); those were not committed.

Live Julia from R (Julia 1.12.6, `DRMODELS_JL_PATH` = DRModels.jl 493c639),
the 81 files that reach the live engine:

- `test-julia-convergence-status-parity.R`: 3 tests, 21 expectations, all
  pass.
- 3849 pass with 16 failures and 16 errors over 75 files, plus 7 failures and
  1 error in `test-reml-biv-animal.R` / `test-xfam-bridge.R`. Every failing
  file was re-run on a 3fd68189e worktree against the same Julia checkout and
  fails identically, except one: `test-julia-phylo-nongaussian.R` (binomial
  phylo floor), which this change moves from `"converged"` to
  `"degenerate"`. That assertion is updated; the file passes 35/35.

DRModels.jl 493c639, full `Pkg.test()` on Totoro, 16 shards per version:

- Julia 1.12.6: 15 of 16 shards pass, 15,884 passed, 1 failed. The failure
  is the known `test_reml_q4_missing_response.jl:210` (`fit_reml.converged`,
  same line on 7348cf3). The five shard-12 files after it ran separately:
  83 passed, 0 failed.
- Julia 1.10.10: 16 of 16 shards pass, 15,949 passed, 0 failed.

## Tests Of The Tests

- The unit test (bridge stub reporting `"degenerate"` with every R-visible
  signal clean) failed on 3fd68189e: `convergence_status()` returned
  `"converged"` and `is_converged()` returned `TRUE`. It passes after the fix.
- The new Julia testset failed on 7348cf3 at both families
  (`b["converged"] === false` evaluated `true === false`) and passes on
  493c639.
- The inflated-SE fixture was chosen so that the route is step 5: at
  `x2 = x1 + 1e-4 * noise` Julia warned that the Hessian was numerically
  singular and used a pseudo-inverse; at `5e-4` there is no warning, the
  covariance is positive definite, the bridge `converged` key is `TRUE`, and
  the SEs (0.115, 265, 265, 0.0707) clear both cuts. The test asserts that
  route, not only the final string.

## Consistency Audit

- `check_drm()` on Julia fits reads `convergence_status(object)`, so its
  `convergence_status` row follows the change with no edit.
- `devtools::document()` rewrote 38 `man/*.Rd` pages that this change does
  not touch: #1400 edited help text in `man/` without the roxygen sources,
  and the fix (#1571) is not on `main`. Those regenerated pages were not
  committed.

## GitHub Issue Maintenance

No issue opened or closed. DRModels.jl #1129 body gained one line: the
binomial-separation screen is not ported (it warns but does not set
`DrmFit.geometry`).

## What Did Not Go Smoothly

- The brief placed the Julia `converged` key "around line 175" of
  `src/bridge.jl`; it is at lines 1648 and 2421 on 7348cf3.
- The bridge has no separate `count_mle_nonexistent` key. R therefore takes
  any Julia `"degenerate"` as the step-2 signal.

## Team Learning

When a parity test asserts only the final status string, a fixture can reach
the expected string by the wrong rule. Assert the rule too.

## Known Limitations

- Step 2 for Julia fits cannot tell the count cone from the Gaussian collapse.
  A dedicated geometry key on the bridge would.
- `drm_twin_convergence_status_from_parts()` does not skip steps 3 to 5 for a
  Julia fit whose bridge covariance is withheld. Measured on the q4 phylo
  route (`test-coevolution-accessors.R`, both live fixtures): the bridge
  sends an all-`NaN` covariance and `convergence_status = "converged"`, and R
  returns `"degenerate"` with or without this change. That twin disagreement
  predates this change and fails `res$julia_converged` in that file.
- DRModels.jl #1129 body and drmTMB #1564 body still quote their earlier
  heads in the local-check sections.
- DRModels.jl #1129 conflicts with `main` in ten `src/` files. A local test
  merge shows the same ten on 7348cf3, so the conflict predates 493c639.
  GitHub starts no `pull_request` run on a conflicting PR, so CI on 493c639
  was started by `workflow_dispatch` on the branch. Resolving the conflict
  needs a merge or rebase of `main`, which was out of scope here.

## Next Actions

Land #1564 and DRModels.jl #1129 together, after both CI runs are green.
