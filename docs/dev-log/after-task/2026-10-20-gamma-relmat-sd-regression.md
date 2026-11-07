# After Task: Gamma relatedness-matrix direct-SD point-fit evidence

## 1. Goal

Record the exact native Gamma q1 `relmat()` location-intercept route that accepts a group-level predictor for the latent SD. The larger random-effect SD-regression programme remains active.

## 2. Implemented

No production likelihood code changed. The existing native structured-effect builder already fits the target. A seeded synthetic test now checks point recovery, group-named SD predictions, and equivalence between an explicit constant-SD formula and the existing scalar-SD fit. The supplied kernel labels are reversed relative to the factor levels. The random-SD vignette now includes a runnable synthetic example, and capability documents record this as one native point-fit row.

## 3a. Decisions and Rejected Alternatives

For group `g`, the tested model uses `tau_g = exp(W_g alpha)` and covariance `D_tau K D_tau`. The matrix is passed in its original scaling and its labels determine group matching. The Gamma response uses fixed `sigma ~ 1`; this does not test an SD effect on Gamma residual `sigma` or combine location and residual random effects.

## 4. Files Touched

- `tests/testthat/test-gamma-relmat-sd-regression.R`
- `vignettes/predictor-dependent-random-sd.Rmd`
- `vignettes/formula-grammar.Rmd`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/design/37-worked-example-inventory.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/internal-roadmap.md`
- `docs/dev-log/check-log.md`
- `NEWS.md`
- `.unlazy/general-sd-regression/GATES.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "gamma-relmat-sd-regression")'`: 11 passed, no failures, warnings, or skips, in 2.9 seconds. No live Julia test ran.
- Loaded this worktree with `devtools::load_all(".", quiet = TRUE)`, checked the loaded namespace path, and rendered `vignettes/predictor-dependent-random-sd.Rmd` to `/tmp/predictor-dependent-random-sd-gamma-relmat.html`. Render succeeded; Pandoc reported the existing deprecated `--mathjax` option.
- Loaded this worktree and ran `pkgdown::check_pkgdown()`: no problems found. Pandoc emitted existing deprecated `--mathml` option notices.
- `git diff --check` on the changed test, documents, NEWS, report, programme gate, and checkpoint: passed.
- `slop_check.py` on this report and the changed user-facing prose: passed with no findings.
- The required after-task report structure check passed. The full programme ledger remains open and was not reverified for this partial slice.

## 6. Tests of the Tests

This test adds an independent synthetic truth with a positive log-SD slope and a kernel whose labels run in the reverse order from the factor levels. The assertions would fail if the route did not fit, if predictions lost group names, if the recovered trend had the wrong direction or was far from the generating value, or if a constant direct-SD formula changed the scalar model likelihood or SD. The focused test passed 11 assertions. It is one seeded point-fit check, not repeated-recovery or interval-calibration evidence.

## 7a. Issue Ledger

No issue was created, changed, or closed for this local test and documentation slice.

## 8. Consistency Audit

The test, formula grammar, family registry, random-effect-scale design note, worked-example inventory, limitations, roadmap, NEWS, and vignette all describe the same narrow native Gamma q1 `relmat()` intercept. The example keeps the predictor constant within group and preserves the supplied kernel scaling. None claims Julia parity, interval calibration, or general Gamma structured-SD support. G3 remains incomplete; G4 and G6 receive partial evidence only.

## 9. What Did Not Go Smoothly

The first patch attempt used a mismatched documentation context and changed no files. I checked the exact surrounding text and then applied the edits to the matching locations. The rendered vignette and pkgdown checks completed afterward.

## 10. Known Residuals

The evidence covers one native q1 location intercept with complete responses, a group-constant predictor, and fixed `sigma ~ 1`. It does not cover save/reload, simulation, profile or bootstrap refits, interval coverage, Julia, other Gamma structured providers, slopes, labelled blocks, or joint `mu` and `sigma` random effects. The package-wide target universe and implementation gates remain open; coverage is deferred under the revised programme scope.

## 11. Team Learning

A structured covariance ordering test is useful even for a small synthetic model: reversed labels make name-based matrix alignment observable in the test rather than assumed from matching row order.

## 12. Cross-Product Coverage

This slice does NOT cover Julia parity, interval calibration, or broad Gamma structured-effect support. Continue with the next unevidenced capability row in the active inventory and coordinate Julia source changes with the DRM.jl owner.
