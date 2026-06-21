# After Task: Capability Freeze, Profile Article, and Skew-Normal First Slice

## Goal

Complete the three agreed pre-CRAN additions for the 0.2.0 release candidate:
freeze the capability surface, add a focused profile-likelihood demonstration
article, and implement only the fixed-effect univariate `skew_normal()` first
slice.

## Implemented

The working tree now admits `skew_normal()` as a one-response fixed-effect
location-scale-shape family with `mu`, `sigma`, and `nu` formulas. Public `mu`
is `E[y]`, public `sigma` is `SD[y]`, and `nu` is the residual slant parameter.
The release-readiness docs freeze every larger capability outside this CRAN
target unless the owner explicitly reopens scope.

The profile-likelihood article now shows a Gaussian residual-`sigma` example
end to end: target inventory, coarse-versus-dense profile metadata, timing, the
likelihood-ratio curve, the fitted estimate, the 95% cutoff, profile endpoints,
and the endpoint-only `confint()` result.

## Mathematical Contract

For the skew-normal branch, the R-facing contract is moment based:

```text
mu = E[y]
sigma = SD[y]
nu = alpha
```

The TMB branch transforms those public parameters to the native Azzalini
parameters:

```text
delta = alpha / sqrt(1 + alpha^2)
mean_shift = delta * sqrt(2 / pi)
omega = sigma / sqrt(1 - mean_shift^2)
xi = mu - omega * mean_shift
z = (y - xi) / omega
log f(y) = log(2) - log(omega) + log phi(z) + log Phi(alpha * z)
```

The implementation uses `log(pnorm(alpha * z) + 1e-300)` rather than a
log-probability `pnorm()` call because the TMB overload available locally did
not support the four-argument `pnorm(..., log.p = TRUE)` form.

## Files Changed

Principal implementation files:

- `R/family.R`, `R/drmTMB.R`, `R/methods.R`, `R/check.R`, `src/drmTMB.cpp`,
  and `NAMESPACE`;
- `tests/testthat/test-skew-normal-location-scale.R`,
  `tests/testthat/test-skew-normal-density-contract.R`, and
  `tests/testthat/test-family-link-contract.R`;
- `man/skew_normal.Rd`, `man/drmTMB.Rd`, `man/sigma.drmTMB.Rd`, and
  `man/check_drm.Rd`.

Principal documentation and release files:

- `vignettes/profile-likelihood.Rmd`, `vignettes/distribution-families.Rmd`,
  `vignettes/formula-grammar.Rmd`, `vignettes/model-map.Rmd`,
  `vignettes/source-map.Rmd`, `_pkgdown.yml`, `README.md`, `ROADMAP.md`,
  `NEWS.md`, and `cran-comments.md`;
- `docs/design/01-formula-grammar.md`, `docs/design/02-family-registry.md`,
  `docs/design/03-likelihoods.md`, `docs/design/19-family-link-contract.md`,
  `docs/design/46-pre-simulation-readiness-matrix.md`,
  `docs/design/157-capability-completion-worklist.md`,
  `docs/design/159-drmtmb-0-2-0-release-readiness.md`, and
  `docs/dev-log/known-limitations.md`;
- superseded skew-normal planning notes
  `docs/design/41-phase-18-simulation-programme.md`,
  `docs/design/125-phase-18-next-two-team-slices-1619-1718.md`,
  `docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md`,
  `docs/design/129-phase-18-semantic-boundary-tests-slices-1629-1630-1687-1688.md`,
  and
  `docs/design/132-phase-18-skew-normal-implementation-gate-slices-1689-1702.md`;
- figure evidence under
  `docs/dev-log/figure-audits/2026-06-08-profile-likelihood-article/`.

## Checks Run

- `Rscript -e 'devtools::document()'`: completed after roxygen updates and
  regenerated the new skew-normal reference topic.
- `Rscript -e 'devtools::test(filter = "skew-normal|family-link-contract|profile-plots", reporter = "summary")'`:
  passed.
- `air format R/check.R R/drmTMB.R R/family.R R/methods.R R/profile.R tests/testthat/test-family-link-contract.R tests/testthat/test-skew-normal-density-contract.R tests/testthat/test-skew-normal-location-scale.R`:
  completed without output.
- `Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `Rscript -e 'pkgdown::build_article("profile-likelihood")'`: passed and
  rebuilt the article figure.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with `No problems found`.
- `Rscript -e 'pkgdown::build_site(preview = FALSE)'`: passed; the build
  emitted the known local warning that `glmmTMB` was built with TMB 1.9.17
  while the current TMB package is 1.9.21.
- `Rscript -e 'urlchecker::url_check()'`: passed with `All URLs are correct!`.
- `tools::checkRd()` loop over all `man/*.Rd`: produced no output.
- `devtools::check(manual = TRUE, cran = TRUE, remote = TRUE, incoming = TRUE, force_suggests = TRUE, args = c("--timings", "--as-cran"), error_on = "never")`:
  completed in 10m 51.6s with 0 errors, 0 warnings, and 3 notes. The notes
  were first submission/tarball size 5,357,670 bytes, local current-time
  verification, and local old-HTML-Tidy manual-validation skip.
- `git diff --check`: passed after the final stale-design-note edits.

## Tests Of The Tests

The new skew-normal tests compare the TMB objective to an independent R density
calculation, verify density normalization and the `nu = 0` Gaussian limit, check
the sign orientation of residual skew, exercise `simulate()`, `residuals()`,
`sigma()`, `predict(dpar = "nu")`, and `check_drm()`, and assert early failure
for unsupported random effects, `sd(group)`, `meta_V(V = V)`, `mvbind()`,
`rho12`, `skew ~`, and latent `` `skew(id)` `` syntax.

The profile-plot test checks that the sampled profile curve extends beyond the
likelihood-ratio cutoff on both sides. The figure audit then rendered and
inspected the actual pkgdown PNG rather than relying on source inspection.

## Consistency Audit

The status inventory was updated in README, ROADMAP, NEWS, known limitations,
formula grammar, family registry, likelihood design, link contract, model map,
source map, distribution-family article, `_pkgdown.yml`, and the
release-readiness checklist.

Stale-wording searches included:

```sh
rg -n "skew_normal.*(not fitted yet|not implemented|planned only|future work|does not currently fit)|does not currently fit skew-normal|skew-normal.*not fitted|skew_normal constructor absent|skew_normal.*absent|requiring skew_normal" README.md NEWS.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes R tests man _pkgdown.yml --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/recovery-checkpoints/**'
rg -n "skew_normal|skew-normal|profile-likelihood|profile likelihood|capability freeze|fixed-effect skew" README.md NEWS.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/03-likelihoods.md docs/design/19-family-link-contract.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/157-capability-completion-worklist.md docs/design/159-drmtmb-0-2-0-release-readiness.md docs/dev-log/known-limitations.md vignettes/distribution-families.Rmd vignettes/formula-grammar.Rmd vignettes/model-map.Rmd vignettes/profile-likelihood.Rmd vignettes/source-map.Rmd _pkgdown.yml R/family.R R/drmTMB.R R/methods.R R/check.R src/drmTMB.cpp tests/testthat/test-skew-normal-location-scale.R tests/testthat/test-skew-normal-density-contract.R tests/testthat/test-family-link-contract.R
rg -n "profile-likelihood|profile likelihood|likelihood-ratio|Residual SD profile|cutoff|endpoint|timing|sigma" vignettes/profile-likelihood.Rmd docs/dev-log/figure-audits/2026-06-08-profile-likelihood-article/figure-audit.md pkgdown-site/articles/profile-likelihood.html _pkgdown.yml NEWS.md docs/design/159-drmtmb-0-2-0-release-readiness.md
```

The first stale scan now returns only the intentional error-message boundary in
`R/drmTMB.R` for unsupported skew-normal random effects.

## GitHub Issue Maintenance

Inspected overlapping open issues #3, #342, #61, and #491. Posted focused
updates to:

- #3, skew-normal first slice:
  <https://github.com/itchyshin/drmTMB/issues/3#issuecomment-4650841034>;
- #342, 0.2.0 release gate:
  <https://github.com/itchyshin/drmTMB/issues/342#issuecomment-4650841039>;
- #61, Phase 20 CRAN/paper gate:
  <https://github.com/itchyshin/drmTMB/issues/61#issuecomment-4650841031>.

Issue #491 was inspected but not updated because the narrower issues now carry
the relevant evidence.

## What Did Not Go Smoothly

The first TMB implementation attempt could not use the expected
four-argument `pnorm(..., log.p = TRUE)` overload, so the density uses a guarded
CDF log. Some older design notes still stated that `skew_normal()` must remain
unimplemented; those notes were superseded in place so generated and source
status no longer contradict the package. Two initial Rd-check commands were
wrong for this R version before the file-by-file `tools::checkRd()` loop was
used. A first issue-comment attempt also hit shell quoting on Markdown
backticks; stdin bodies fixed it without posting duplicate comments.

## Team Learning

When a planned-only family crosses into a first fitted slice, supersede the old
boundary notes immediately. The useful line is not "implemented everywhere";
it is "implemented here, still closed there." For CRAN, update
`cran-comments.md` after the last package-code check; docs and dev logs are
build-ignored here, so their final closeout edits do not change the checked
tarball.

## Known Limitations

`skew_normal()` is fixed-effect-only. It does not support random effects,
`sd(group)`, structured effects, known sampling covariance, bivariate
skew-normal responses, residual `rho12`, `skew ~`, latent `skew(id)` syntax,
formal recovery grids, interval-status grids, or runtime/false-positive audits.

The 0.2.0 CRAN path still needs external Windows/devel checking, actual CRAN
submission, CRAN email approval, and post-acceptance release/version steps.

## Next Actions

1. Decide whether to submit this working tree as the CRAN candidate or first
   push it through a review PR.
2. Run `devtools::check_win_devel()` before actual CRAN submission.
3. Keep issue #3 open for skew-normal recovery grids and broader syntax only
   after the CRAN candidate is settled.
