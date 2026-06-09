# After Task: Gaussian REML Known-V Slice

## Goal

Make the first Gaussian REML implementation useful for ordinary meta-analysis
models by allowing diagonal and dense known sampling covariance through
`meta_V(V = V)`.

## Implemented

`drmTMB(..., REML = TRUE)` now accepts univariate Gaussian known-`V` fits inside
the existing REML boundary: dense ordinary `mu` fixed effects, optional ordinary
`mu` random effects, intercept-only `sigma`, complete responses, and unit
likelihood weights.

## Mathematical Contract

For known-`V` models, the fitted observation covariance is
`Sigma = V + sigma^2 I` for the constant residual-heterogeneity route. The
reported restricted log likelihood is the full Gaussian REML quantity

```text
-0.5 * ((n - p) log(2 pi) + log|Sigma| +
        log|X' Sigma^{-1} X| + r' Sigma^{-1} r).
```

Comparator tests check this value against an independent R calculation.
`metafor` optimizes to the same fixed effects and heterogeneity variance, but
uses a log-likelihood convention shifted by `0.5 * log|X'X|`; the tests record
that expected fixed-design determinant shift.

## Files Changed

- `R/drmTMB.R` removes the REML guard against known sampling covariance and
  updates the public `REML` parameter boundary.
- `tests/testthat/test-comparators.R` adds diagonal and dense known-`V` REML
  comparator tests against manual REML likelihood calculations and `metafor`.
- `vignettes/meta-analysis.Rmd` adds a reader-facing REML example for constant
  residual heterogeneity.
- `README.md`, `NEWS.md`, `docs/design/03-likelihoods.md`,
  `docs/design/05-testing-strategy.md`,
  `docs/design/168-gaussian-reml-first-slice.md`,
  `docs/dev-log/known-limitations.md`, and `man/drmTMB.Rd` synchronize the
  implemented and unsupported boundaries.

## Checks Run

```sh
/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::test(filter = "comparators")'
/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::test(filter = "meta-known-v")'
air format .
/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::document()'
RSTUDIO_PANDOC=/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64 /Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/meta-analysis.Rmd", output_dir = tempdir(), quiet = TRUE); cat("meta_analysis_render_ok\n")'
/Library/Frameworks/R.framework/Resources/bin/Rscript - <<'EOF'
files <- list.files("man", pattern = "\\.Rd$", full.names = TRUE)
problems <- list()
for (f in files) {
  res <- tryCatch(
    utils::capture.output(tools::checkRd(f)),
    error = function(e) paste("ERROR:", conditionMessage(e))
  )
  res <- res[nzchar(trimws(res))]
  if (length(res) > 0L) problems[[f]] <- res
}
if (length(problems) > 0L) {
  print(problems)
  quit(status = 1L)
}
cat("checkRd_ok", length(files), "files\n")
EOF
RSTUDIO_PANDOC=/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64 /Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::check_pkgdown(); pkgdown::build_article("meta-analysis", new_process = FALSE, quiet = TRUE); cat("pkgdown_meta_article_ok\n")'
rg -n "REML.*known sampling covariance.*planned|known sampling covariance.*REML.*planned|REML.*meta_V.*planned|meta_V\\(V = V\\).*REML.*planned|no known sampling covariance|known Gaussian sampling covariance" README.md NEWS.md R/drmTMB.R docs/design docs/dev-log/known-limitations.md vignettes man tests/testthat/test-comparators.R --glob '!docs/dev-log/check-log.md'
git diff --check
gh issue list --repo itchyshin/drmTMB --state open --search 'REML meta_V OR known sampling covariance OR restricted maximum likelihood metafor' --limit 20 --json number,title,state,url,labels
```

Results:

- `devtools::test(filter = "comparators")` passed with 101 expectations, no
  failures, warnings, or skips.
- `devtools::test(filter = "meta-known-v")` passed with 75 expectations, no
  failures, warnings, or skips.
- `devtools::document()` regenerated `man/drmTMB.Rd`.
- Direct rendering of `vignettes/meta-analysis.Rmd` completed with
  `meta_analysis_render_ok`.
- `tools::checkRd()` passed for 54 Rd files.
- `pkgdown::check_pkgdown()` reported no problems, and
  `pkgdown::build_article("meta-analysis", new_process = FALSE)` wrote
  `pkgdown-site/articles/meta-analysis.html` with `pkgdown_meta_article_ok`.
- The stale-wording scan left implemented known-`V` REML wording and the
  separate missing-data REML limitation only.
- `git diff --check` reported no whitespace problems.
- GitHub issue search found only broad open issues, not a dedicated overlapping
  known-`V` REML issue; no issue comment was added.

## Tests Of The Tests

The known-`V` REML tests compare the restricted log likelihood against an
independent Cholesky-based R calculation rather than another `drmTMB` path. They
also compare fixed effects and heterogeneity variance against `metafor` for
both diagonal and dense known covariance.

## Consistency Audit

The docs now say that known sampling covariance is fitted under REML only for
univariate Gaussian models inside the intercept-only `sigma` boundary. They do
not advertise REML for predictor-dependent `sigma`, explicit missing-data
routes, row aggregation, structured effects, non-unit dense-`V` weights, or
direct `sd()` scale formulae.

## GitHub Issue Maintenance

`gh issue list` with REML, `meta_V`, known sampling covariance, and `metafor`
terms returned broad roadmap issues only. No dedicated issue needed updating.

## What Did Not Go Smoothly

`air format .` reformatted unrelated simulation and test files. Those unrelated
format-only edits were removed with a reverse patch before closing the slice.

## Team Learning

The known-`V` REML route was already mostly a validation-boundary problem: once
the guard was removed, TMB's integrated Gaussian likelihood matched the full
restricted likelihood. Future adjacent REML slices should start with an
independent likelihood probe before changing public support claims.

## Known Limitations

Known-`V` REML still requires the current first-slice Gaussian REML boundary:
complete responses, unit likelihood weights, dense full-rank `mu` design, and
intercept-only `sigma`. Predictor-dependent heterogeneity should stay on ML
until it has a separate Hessian/profile/bootstrap and comparator gate.

## Next Actions

The next REML capability slice should be chosen from the still-planned
neighbours: predictor-dependent `sigma`, explicit missing-data routes, row
aggregation, structured effects, or direct random-effect scale formulae.
