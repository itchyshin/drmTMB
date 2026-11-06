# Native Gamma sigma-endpoint SD regression

Date: 2026-10-21

## Scope

Implemented a predictor-dependent SD for one ordinary random intercept in the
Gamma `sigma` formula. Here `sigma` is the coefficient of variation, and the
SD formula governs the latent random intercept on `log(sigma)`. The route is
complete-data, univariate, fixed-effect `mu`, one unlabelled ordinary
`sigma` intercept, and fixed predictors constant within group. This does not
combine with Gamma `mu` random effects.

## Checks

Passed:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "gamma-sigma-sd-regression", reporter = "summary")'
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "gamma-(location-scale|sigma-sd-regression)|lognormal-sigma-sd-regression", reporter = "summary")'
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/predictor-dependent-random-sd.Rmd", output_file = "/private/tmp/predictor-dependent-random-sd-gamma-sigma-current.html", envir = globalenv(), quiet = TRUE)'
```

The new seeded recovery test and adjacent Gamma/LogNormal filter exited 0.
The test covers recovery of the log-SD intercept and predictor slope, finite
coefficient covariance, group-SD prediction, fitted-data conditional `sigma`
link and response outputs, save/reload prediction, constant-SD equivalence to
the existing Gamma sigma-intercept fit, and rejection of an SD predictor that
varies within group. The vignette rendered from the current source. Its only
reported warning was Pandoc's deprecated `--mathjax` option.
`pkgdown::check_pkgdown()` passed with no problems; its output contained only
the existing deprecated `--mathml` warnings.

The live Julia engine was not exercised. No profile or bootstrap refit was
run, and no coverage claim is made.

## Documentation and status inventory

Updated the Gamma formula grammar row, likelihood design, random-effect-scale
design, predictor-SD vignette, NEWS, known limitations, internal roadmap, and
the programme's partial G3/G4/G6 evidence. The exact inventory scan was:

```sh
rg -n 'Gamma.*sigma.*SD|sigma-endpoint' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

README, the formula-grammar vignette, and pkgdown navigation had no target-
specific wording to update. The existing formula-grammar table already states
that Gamma admits an ordinary sigma random intercept; this slice adds
predictor-dependent SD for that intercept and does not imply Gamma random
slopes in sigma.

## Issue maintenance

Read open issue #1551, which reports a separate Julia bridge failure for
ordinary Gamma and Poisson mean random intercepts. It does not cover this
Gamma sigma-endpoint SD route, so no issue was changed and no duplicate was
opened.

## What did not go smoothly

An early broad patch matched the Gaussian builder instead of the Gamma builder
and temporarily disrupted structured-SD parsing. The full-source vignette
render caught the error. The unintended Gaussian and sparse-design hunks were
restored, the existing animal selector was preserved, and the current-source
render then passed. Future repeated-builder edits should anchor patches on the
family function name and inspect the full diff immediately.

## Naturalness assessment

Style: 3/10, medium confidence. Genre/coverage: technical after-task report,
whole report. Evidence: the scope paragraph names the exact Gamma parameter
and tested restriction; the checks paragraph distinguishes test evidence from
coverage; the failure paragraph gives a concrete cause and repair. No repair
was needed after review. Gates: science pass against the written likelihood
contract and synthetic test; facts pass against the focused test outputs and
render result; references not applicable because the report uses local
evidence and contains no external citations. Provenance: self-review, draft
2026-10-21, related LogNormal endpoint report had been seen.

## Remaining limitations

This is one native TMB endpoint/effect-shape cell. Julia parity, other Gamma
sigma effect types, combining sigma- and mu-endpoint random effects, profile
and bootstrap-refit workflows, and interval calibration remain open. The
programme-wide target universe and gates remain open.

## Next action

Continue with the next uncovered family/effect/backend row after checking its
source ownership; keep the overall general-SD goal active.
