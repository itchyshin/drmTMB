# After Task: Reference CI Fast Examples

## Goal

Continue the comprehensive function/reference audit by making the high-risk
`confint()` and `summary()` reference pages show the fast confidence-interval
workflow directly.

## Implemented

- Added `confint(fit, parm = "variance_components")` to the `confint()`
  examples so users see the direct Wald variance-component shortcut.
- Added a fast-profile `confint()` example using
  `profile_precision = "fast"`.
- Added a commented direct-target bootstrap example to show that bootstrap is a
  current `confint()` route when refit cost is worth it.
- Updated the `summary()` profile example to include
  `profile_precision = "fast"`.
- Regenerated `man/confint.drmTMB.Rd` and `man/summary.drmTMB.Rd`.

## Mathematical Contract

No interval implementation changed. The examples expose the current contract:
Wald intervals are the fast default for direct targets where the
`TMB::sdreport()` covariance is available; SD intervals use the optimized
log-SD scale before returning response-scale bounds; direct correlation Wald
intervals use the guarded TMB correlation-link, equivalent to a guarded
Fisher z/atanh scale; profile remains targeted and slower; bootstrap uses
simulate/refit point estimates for direct `confint()` targets.

## Files Changed

- `R/profile.R`
- `R/methods.R`
- `man/confint.drmTMB.Rd`
- `man/summary.drmTMB.Rd`
- `docs/dev-log/audits/2026-05-21-function-reference-inventory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-21-reference-ci-fast-examples.md`

## Checks Run

```sh
air format R/profile.R R/methods.R docs/dev-log/audits/2026-05-21-function-reference-inventory.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-reference-ci-fast-examples.md
Rscript -e "devtools::document()"
Rscript -e "pkgdown::build_reference()"
Rscript -e "devtools::load_all(quiet = TRUE); dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2)); fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat); print(confint(fit)); print(confint(fit, parm = 'variance_components')); print(confint(fit, parm = 'sigma', method = 'profile', profile_precision = 'fast')); print(summary(fit, conf.int = TRUE, method = 'profile', ci_parm = 'sigma', profile_precision = 'fast'))"
rg -n 'confint\(fit|variance_components|profile_precision = "fast"|method = "bootstrap"|bootstrap intervals are not implemented|not implemented yet' R/profile.R R/methods.R man/confint.drmTMB.Rd man/summary.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html pkgdown-site/reference/summary.drmTMB.html -S
Rscript -e "devtools::test(filter = 'profile-targets|summary', reporter = 'summary')"
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
gh issue list --search "bootstrap intervals OR confidence interval OR profile" --limit 20
```

## Tests Of The Tests

The new example calls were run exactly on the documented toy model. That smoke
check verified the variance-component shortcut, the fast profile call, and the
summary fast-profile example before commit.

## Consistency Audit

`pkgdown::build_reference()` rewrote the local reference HTML for `confint()`
and `summary()`. Before rebuilding, the local generated HTML still said
bootstrap intervals were not implemented; after rebuilding, the reference page
shows `method = c("wald", "profile", "bootstrap")`, `profile_precision =
c("default", "fast")`, the variance-component example, and the commented
bootstrap example.

## Sister-Package Learning

The local `gllvmTMB` source keeps `confint.gllvmTMB_multi()` as a fixed-effect
Wald helper, while its simulation path documents unconditional redraws as the
parametric-bootstrap route. The lesson for `drmTMB` is not to port code, but to
keep the public fast path obvious and reserve refit-based bootstrap for cases
where its extra cost answers a real uncertainty question.

## GitHub Issue Maintenance

Issue search found #265 for public bootstrap intervals, #58 for visualization,
#4 for large-data readiness, #255 for simulation artifacts, and several
structured-effect follow-ups. This slice contributes to #265, but no issue was
closed because bootstrap policy and heavier validation remain open.

## What Did Not Go Smoothly

The generated pkgdown reference pages were stale after the Rd update. The audit
now treats `pkgdown::build_reference()` or a full site build as required
evidence before calling reference-page wording current.

## Known Limitations

This pass only improves examples and generated-reference evidence. It does not
change bootstrap internals, add `summary()` bootstrap intervals, or validate
long phylogenetic profiles beyond the toy-model example.

## Next Actions

1. Continue the function/reference audit with `corpairs()`, `predict_parameters()`,
   and the plot helpers.
2. Keep #265 open as the policy ledger for broader bootstrap interval design.
3. Decide before release whether `gr()` should remain exported or move farther
   out of the main public surface.
