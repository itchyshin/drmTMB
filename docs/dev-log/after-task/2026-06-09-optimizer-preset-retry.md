# After Task: Optimizer Preset Error Retry

## Goal

Make issue #506 usable for tree-dependent optimizer-call failures without
turning `drmTMB()` into an unrecorded multi-optimizer search.

## Implemented

`drmTMB()` now routes fitting through an internal `nlminb()` retry runner. When
the selected preset is the default and no explicit optimizer controls were
supplied, optimizer-call errors retry the same objective with the existing
`"careful"` and `"robust"` deterministic presets. A successful retry warns and
stores the selected attempt in `fit$optimizer_used`; all attempted presets are
stored in `fit$optimizer_attempts`.

## Mathematical Contract

No likelihood, parameterization, formula grammar, starting-value rule, or TMB
template changed. All reported quantities still come from the selected
`opt$par`, and the TMB object is pinned to that selected optimum before
standard errors, extracted parameters, and profiles use it.

## Files Changed

- `R/drmTMB.R`
- `R/control.R`
- `man/drm_control.Rd`
- `tests/testthat/test-optimizer-contract.R`
- `tests/testthat/_snaps/optimizer-contract.md`
- `vignettes/convergence.Rmd`
- `docs/design/35-optimizer-start-map-multistart.md`
- `docs/dev-log/check-log.md`
- `NEWS.md`
- `ROADMAP.md`

## Checks Run

```sh
Rscript -e 'devtools::test(filter = "optimizer-contract", reporter = "summary")'
Rscript -e 'devtools::test(filter = "control|optimizer-contract", reporter = "summary")'
Rscript -e 'devtools::document()'
RSTUDIO_PANDOC=/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64 Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/convergence.Rmd", output_dir = tempfile("convergence-render-"), quiet = TRUE); cat("convergence_render_ok\n")'
Rscript - <<'EOF'
res <- utils::capture.output(tools::checkRd("man/drm_control.Rd"))
res <- res[nzchar(trimws(res))]
if (length(res)) {
  cat(res, sep = "\n")
  quit(status = 1L)
}
cat("drm_control_checkRd_ok\n")
EOF
rg -n 'fallback optimizer.*automatic|fallback optimizers.*automatic|fallback refits.*automatic|BFGS.*automatic|L-BFGS-B.*automatic|optimizer_attempts|optimizer_used|optimizer preset retry|non-finite gradient|NA/NaN gradient' NEWS.md R/control.R R/drmTMB.R ROADMAP.md docs/design/35-optimizer-start-map-multistart.md vignettes/convergence.Rmd man/drm_control.Rd tests/testthat/test-optimizer-contract.R
git diff --check
Rscript -e 'devtools::test(reporter = "summary")'
Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::check_pkgdown(); cat("pkgdown_check_ok\n")'
```

## Tests Of The Tests

The new optimizer-contract tests use a fake optimizer that throws
`NA/NaN gradient evaluation` on the first call and succeeds on the second. That
test confirms that the second call receives the `"careful"` preset budget, that
the warning is snapshotted, and that `fit$optimizer_attempts` records both the
failed default attempt and the selected careful attempt. A second fake optimizer
test confirms explicit custom optimizer controls are attempted once and do not
enter the preset ladder. A third fake optimizer test makes all preset attempts
fail and confirms the `"robust"` control is attempted before the final error is
reported.

## Consistency Audit

The convergence vignette now explains the automatic preset retry beside the
manual `optimizer_preset` guidance. The optimizer design note separates this
narrow deterministic retry from the future alternative-optimizer fallback
contract. NEWS and ROADMAP mention issue #506 and preserve the distinction
between preset retry, nonzero-convergence diagnostics, and planned BFGS or
L-BFGS-B fallback searches.

## GitHub Issue Maintenance

Issue #506 remains open until the PR with this implementation is merged. The
planned PR should reference and close #506.

## What Did Not Go Smoothly

The first focused test run caught an R syntax error in the fake optimizer result:
`function` must be quoted when used as a vector name. The retry branch was also
started while #511 CI was still running, so it was rebased onto the #511 merge
commit before final verification.

## Team Learning

Ada kept the change narrow enough to avoid reopening the broader fallback
optimizer contract. Grace required full `devtools::test()` because the fitted
object gained optimizer metadata. Fisher kept nonzero convergence-code fits out
of the automatic retry path so weak fits remain diagnostic rather than silently
rescued.

## Known Limitations

This does not implement user starts, warm starts, BFGS, L-BFGS-B, stochastic
multi-start, Hessian rescue, or automatic model simplification. It does not
retry fits that return a nonzero optimizer convergence code. Those fits still
need `check_drm()`, profile or bootstrap routes, and model-specific
interpretation.

## Next Actions

Open the #506 PR, watch CI, and close the issue after the branch merges.
