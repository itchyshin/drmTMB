# After Task: Post-Phase-8 Roadmap Extension

## Goal

Answer the planning gap after Phase 8 by adding a clear roadmap sequence for the
work that follows implemented counts, proportions, and the planned ordinal
family seed.

## Implemented

- Added Phase 9 through Phase 17 to `ROADMAP.md`.
- Kept Phase 9 focused on ordinal and denominator-aware models.
- Moved spatial implementation into its own Phase 10 rather than mixing it with
  the count/proportion family work.
- Put bivariate random effects and correlation-pair reporting before complex
  bivariate phylogenetic or spatial covariance blocks.
- Kept profile-likelihood inference, large-data engineering, mixed-response
  bivariate families, shape/asymmetry models, and release/paper work as separate
  phases.

## Consistency Audit

The added phases preserve the existing project boundaries:

- one- and two-response scope only;
- `rho12` remains residual bivariate correlation;
- phylogenetic, spatial, ordinary group-level, and residual correlations remain
  separate reporting levels;
- `sigma` remains the public scale name unless an explicit family-specific
  design decision says otherwise;
- higher-dimensional multivariate models remain assigned to `gllvmTMB`.

## Checks Run

- The roadmap patch was reviewed against `docs/design/06-distribution-roadmap.md`
  and the current Phase 0-8 roadmap structure.
- `Rscript -e "pkgdown::build_site()"`: passed after rerunning with normal
  cache/network access.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `rg -n "Phase 9: Ordinal|Phase 17: Release|residual covariance component after known sampling covariance|rho12_i = tanh" ROADMAP.md README.md vignettes/drmTMB.Rmd vignettes/testing-likelihoods.Rmd docs/design/03-likelihoods.md docs/design/09-phylogenetic-and-spatial-speed.md pkgdown-site/ROADMAP.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/testing-likelihoods.html`:
  confirmed the new roadmap headings and generated-site equation wording.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 1 local macOS temp-directory note for `xcrun_db`.

## Tests Of The Tests

This was a roadmap-only change. The meaningful verification is that the planned
phases do not claim implementation and do not contradict the implemented Phase
0-8 status. The pkgdown scan also checked that the ROADMAP page actually rendered
the new Phase 9 and Phase 17 headings.

## Known Limitations

- This task did not implement any new family, likelihood, inference method, or
  spatial model.
- Each new phase still needs issue-level design documents before code starts.

## Next Actions

1. Link future issues to the new Phase 9-17 headings.
2. Keep Phase 9 ordinal design separate from Phase 10 spatial design so neither
   becomes under-specified.
