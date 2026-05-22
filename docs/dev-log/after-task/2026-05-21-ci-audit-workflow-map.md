# After Task: CI Audit Workflow Map

## Goal

Close the follow-up slices after the fast CI implementation: inspect the local
`gllvmTMB` profile/CI source, make the fast `drmTMB` interval workflow visible
to users, and start the comprehensive function/page/figure audit.

## Implemented

The local `gllvmTMB` audit is recorded in
`docs/design/68-gllvmtmb-profile-ci-audit.md`. It found that `gllvmTMB`'s
profile speed comes mainly from `TMB::tmbprofile()` with coarser defaults
(`ystep = 0.5`, `ytol = 2`) and from targeted profile paths, not from a
separate package-specific C++ profile engine. It also records the
`gllvmTMB` Sigma bootstrap helper and Fisher-z correlation extractor so future
work can reuse ideas without copying source.

The model-workflow article now shows the practical interval order for long
models: use `confint(fit)` for the fast direct Wald table, narrow to
`confint(fit, parm = "variance_components")`, profile selected SD or
correlation targets with `profile_precision = "fast"`, and use
`confint(..., method = "bootstrap")` only when refit-based uncertainty is worth
the runtime.

The roadmap and validation-debt register now separate the implemented
direct-target `confint()` bootstrap route from unsupported bootstrap routes in
`summary()`, `corpairs()`, prediction tables, q4 derived covariance summaries,
repeatability, and phylogenetic signal.

The comprehensive audit map is recorded in
`docs/design/69-comprehensive-function-page-figure-audit.md`, with an initial
ledger at `docs/dev-log/audits/2026-05-21-function-page-figure-audit.md`.

## Mathematical Contract

No likelihood parameterization changed in this slice. The inference wording now
matches the implemented contract:

- SD Wald intervals use the optimized log-SD scale and are exponentiated.
- Direct correlation Wald intervals use the fitted guarded atanh scale and are
  transformed back to the correlation scale.
- `profile_precision = "fast"` changes only the `TMB::tmbprofile()` controls.
- Bootstrap intervals are percentile intervals from simulate/refit point
  estimates for selected direct `confint()` targets.

The audit explicitly rejects using a sample-correlation Fisher-z `n_eff`
heuristic as the default for fitted model-parameter correlations.

## Files Changed

- `R/methods.R`
- `man/summary.drmTMB.Rd`
- `ROADMAP.md`
- `vignettes/model-workflow.Rmd`
- `docs/design/34-validation-debt-register.md`
- `docs/design/68-gllvmtmb-profile-ci-audit.md`
- `docs/design/69-comprehensive-function-page-figure-audit.md`
- `docs/dev-log/audits/2026-05-21-function-page-figure-audit.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-21-ci-audit-workflow-map.md`

## Checks Run

```sh
air format ROADMAP.md vignettes/model-workflow.Rmd docs/design/68-gllvmtmb-profile-ci-audit.md docs/design/69-comprehensive-function-page-figure-audit.md docs/dev-log/audits/2026-05-21-function-page-figure-audit.md
air format docs/design/34-validation-debt-register.md
air format R/methods.R
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('model-workflow', new_process = FALSE, quiet = FALSE)"
Rscript -e "devtools::document()"
rg -n 'bootstrap intervals are not implemented|method = "bootstrap"\).*stop|not a public `method` value|unsupported bootstrap requests now report that bootstrap intervals are not implemented|public `confint\(method = "bootstrap"\)` promise|not a public `confint\(\)` default' README.md ROADMAP.md docs/design vignettes R man tests/testthat -S
Rscript -e "devtools::test(filter = 'profile-targets|summary|control', reporter = 'summary')"
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
```

## Tests Of The Tests

This slice did not add new executable behavior after the preceding fast-CI
tests. It re-ran the focused profile-target, summary, and control tests to
confirm the documented interval contracts still pass after the workflow and
roxygen wording updates.

## Consistency Audit

The stale-wording scan no longer finds current public text saying that public
`confint(..., method = "bootstrap")` is unavailable. Remaining matches are
intentional current-boundary statements: `summary()` and `corpairs()` do not
run bootstrap intervals yet, and the audit map stores the scan pattern for the
next pass.

`pkgdown::build_article('model-workflow')` first failed in a clean process
because it picked up an older installed `drmTMB` without `profile_targets()`.
The article rendered successfully after loading the local package with
`devtools::load_all()` and running `pkgdown::build_article(..., new_process =
FALSE)`.

## GitHub Issue Maintenance

No GitHub issue was updated in this local slice. The source audit points to
Ayumi's Bergmann report as the motivation, but this branch is still carrying
multiple local CI/C++ changes and should be packaged before issue comments are
posted.

## What Did Not Go Smoothly

The pkgdown article-render command exposed an installed-package mismatch. That
is useful evidence for future local documentation checks: when the working tree
contains uninstalled roxygen/export changes, render the focused article with
the local package loaded, or install the package before using a fresh
pkgdown process.

## Team Learning

The sister-package comparison should stay source-grounded. `gllvmTMB` teaches
useful profile controls, bootstrap ledgers, and boundary conventions, but
`drmTMB` should adapt those ideas to its one- and two-response contract rather
than copying many-response covariance machinery.

## Known Limitations

The comprehensive function/page/figure audit has only been launched. No
rendered figure was inspected one by one in this slice. The next audit slice
must produce the function/reference table, page/status table, and rendered
figure table before calling the broad audit complete.

## Next Actions

1. Package the current fast-CI and audit-map changes into a clean reviewable
   commit or PR.
2. Fill the function/reference inventory from `NAMESPACE`, `R/`, `man/`,
   `_pkgdown.yml`, and focused tests.
3. Render and inspect the figure-heavy pages, then write the per-figure audit
   table under `docs/dev-log/figure-audits/`.
