# After-Task Report: Slices 449-458 Function Reference Prose Audit

## Active Perspectives

Ada ran the audit and integrated the roxygen changes. Pat read the reference
pages as an applied user trying to distinguish residual `rho12`, latent
`corpairs()`, and profile targets. Fisher checked that interval language did
not overclaim profile success. Emmy checked that summary and extractor wording
matched the fitted object structure. Rose searched for stale q4/fallback
phrasing after the update.

## Goal

Audit high-risk reference pages whose prose mentions planned syntax, profile
intervals, or advanced covariance layers.

## Implemented

- Updated `corpairs()` documentation so bivariate phylogenetic rows include
  full q4 derived endpoint correlations and block-diagonal q4 fallback direct
  block correlations, not only the first q2 mean-mean row.
- Updated `confint()` documentation so direct profile targets include the
  block-diagonal bivariate phylogenetic `mu1`/`mu2` and `sigma1`/`sigma2`
  correlations.
- Updated `profile_targets()` documentation to state that full q4
  unstructured-correlation summaries are derived targets, while block-diagonal
  phylogenetic q4 fallback correlations are direct targets that can still fail
  on weak, boundary-limited, or one-sided profiles.
- Updated `summary()` documentation so the covariance component refers to
  fitted bivariate phylogenetic q2 and q4 covariance rows where present.
- Regenerated Rd files and rebuilt the rendered reference pages.

## Checks Run

```sh
air format R/methods.R R/profile.R
Rscript -e "devtools::document()"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_reference()"
rg -n "first fitted bivariate phylogenetic|first bivariate phylogenetic mean-mean correlation|first bivariate phylogenetic mean-mean" R/methods.R R/profile.R man/corpairs.Rd man/confint.drmTMB.Rd man/profile_targets.Rd man/summary.drmTMB.Rd pkgdown-site/reference/corpairs.html pkgdown-site/reference/confint.drmTMB.html pkgdown-site/reference/profile_targets.html pkgdown-site/reference/summary.drmTMB.html --glob '!pkgdown-site/search.json'
rg -n "Full q4 phylogenetic blocks report six derived|block-diagonal q4 fallback fits report|bivariate phylogenetic q=2 mean-mean|fitted bivariate phylogenetic covariance rows|direct target can still fail" R/methods.R R/profile.R man/corpairs.Rd man/confint.drmTMB.Rd man/profile_targets.Rd man/summary.drmTMB.Rd pkgdown-site/reference/corpairs.html pkgdown-site/reference/confint.drmTMB.html pkgdown-site/reference/profile_targets.html pkgdown-site/reference/summary.drmTMB.html --glob '!pkgdown-site/search.json'
git diff --check
```

## Validation Notes

- `devtools::document()` regenerated `man/corpairs.Rd`,
  `man/confint.drmTMB.Rd`, `man/profile_targets.Rd`, and
  `man/summary.drmTMB.Rd`.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_reference()` rebuilt the changed rendered reference pages.
- The stale phrase scan found no remaining `first fitted bivariate
  phylogenetic` shorthand in the audited source, Rd, or rendered pages.
- The positive scan found the corrected full q4, block-diagonal fallback, q2,
  summary covariance, and direct-target caveat wording.
- `git diff --check` reported no whitespace problems.

## Known Limitations

This slice audited the most covariance- and interval-sensitive reference pages.
It did not copy-run every reference example.

## Next Actions

Continue with a copy-run example audit for the reference pages most likely to
drift: `phylo()`, `corpair()`, `corpairs()`, `profile_targets()`, and
`check_drm()`.
