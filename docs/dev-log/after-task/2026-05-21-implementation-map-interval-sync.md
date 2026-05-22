# After Task: Implementation Map Interval Sync

## Goal

Continue the comprehensive page audit by checking `model-map` and
`implementation-map` against the current CI contract, then fixing stale
implementation-map wording about Wald and bootstrap intervals.

## Implemented

- Confirmed that `model-map` already describes the current fast CI route.
- Updated `implementation-map` so it no longer says Wald intervals are
  fixed-effect-only.
- Updated the bootstrap boundary: public `confint(method = "bootstrap")` now
  exists for selected direct targets, while `summary()`, `corpairs()`,
  prediction tables, derived q4 rows, repeatability, and phylogenetic signal
  remain outside that route.
- Recorded that the rendered `model-map` and `implementation-map` pages have no
  active article figures beyond the pkgdown logo.

## Mathematical Contract

No model code changed. The documentation now matches the fitted inference
contract: direct SD Wald intervals use the fitted log-SD scale, direct
correlation Wald intervals use the guarded atanh correlation-link scale, and
derived or weak-Hessian targets still require profile/bootstrap diagnostics or
an explicit unavailable status.

## Files Changed

- `vignettes/implementation-map.Rmd`
- `docs/dev-log/audits/2026-05-21-function-page-figure-audit.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-21-implementation-map-interval-sync.md`

## Checks Run

```sh
air format vignettes/implementation-map.Rmd docs/dev-log/audits/2026-05-21-function-page-figure-audit.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-implementation-map-interval-sync.md
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('model-map', new_process = FALSE, quiet = TRUE); pkgdown::build_article('implementation-map', new_process = FALSE, quiet = TRUE)"
rg -n 'model-map_files/figure-html|implementation-map_files/figure-html|<img' pkgdown-site/articles/model-map.html pkgdown-site/articles/implementation-map.html
rg -n 'Use Wald intervals only|not a public `confint\(method = "bootstrap"\)` route|private simulation infrastructure, not a public|fixed-effect-only|Wald intervals are fixed-effect-only' vignettes/implementation-map.Rmd pkgdown-site/articles/implementation-map.html vignettes/model-map.Rmd pkgdown-site/articles/model-map.html README.md ROADMAP.md docs/design/34-validation-debt-register.md -S
rg -n 'direct bootstrap only through selected `confint\(\)` targets|narrow public simulate/refit route|Use fast Wald intervals for routine fixed-effect coefficients and selected direct fitted targets' vignettes/implementation-map.Rmd pkgdown-site/articles/implementation-map.html -S
Rscript -e "devtools::test(filter = 'profile-targets|summary', reporter = 'summary')"
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
gh issue list --search "implementation map interval OR bootstrap intervals OR confidence interval" --limit 20
```

## Tests Of The Tests

This was a page-consistency slice. The focused `profile-targets` and `summary`
tests cover the interval target inventory and summary-side Wald/profile
boundary that the page describes.

## Consistency Audit

The implementation map now agrees with `model-map`, `README.md`,
`NEWS.md`, and `docs/design/12-profile-likelihood-cis.md` on the fast
CI order: default Wald for direct routine targets, targeted profile when
likelihood shape matters, `profile_precision = "fast"` for long first-pass
profiles, and direct-target bootstrap only through `confint()`.

## GitHub Issue Maintenance

The issue search found #265, the public bootstrap interval design issue, along
with broader visualization and simulation artifact issues (#58 and #255). This
slice documents the current direct-target bootstrap boundary but does not close
#265 because non-direct bootstrap surfaces and broader hard-fit ergonomics
remain open.

## What Did Not Go Smoothly

An `rg` pattern containing backticks triggered shell command substitution when
quoted with double quotes. The logged stale-wording scans now use single-quoted
patterns when they include backticks.

## Team Learning

Rose's map-authority rule caught a real drift: `model-map` had been corrected,
but `implementation-map` still carried the old fixed-effect-only interval
boundary. Future interval changes should scan both maps in the same slice.

## Known Limitations

This pass did not audit every historical NEWS item or after-task report. Older
records that were true at the time stay historical. Current reader-facing
surfaces must match the live package.

## Next Actions

1. Continue the rendered page audit with `phylogenetic-spatial`.
2. Continue the simulation figure/status audit with `simulation-plot-grammar`.
3. Return to the function/reference inventory after the high-risk public maps
   are synchronized.
