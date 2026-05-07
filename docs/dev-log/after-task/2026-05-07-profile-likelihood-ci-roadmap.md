# After Task: Profile-Likelihood CI Roadmap

Date: 2026-05-07

## Task

Record profile-likelihood confidence intervals as a planned inference feature,
especially for random-effect variance components, phylogenetic and spatial
components, ICC-like quantities, and group-level correlation summaries.

## Created Or Changed

- Added `docs/design/12-profile-likelihood-cis.md`.
- Added Phase 6 profile-likelihood inference to `ROADMAP.md`.
- Added future profile-likelihood CI tests to
  `docs/design/05-testing-strategy.md`.
- Added a check-log entry for this design task.

## Design Decisions Captured

- A 95% profile-likelihood CI uses the threshold
  `qchisq(0.95, df = 1) / 2`, approximately `1.92`, as the allowed
  log-likelihood drop from the joint MLE.
- The profile must re-optimize nuisance parameters at each candidate value; it
  is not a fixed-parameter slice.
- The first implementation should prefer `TMB::tmbprofile()` plus `uniroot()`
  for direct TMB parameters.
- Linear combinations can use TMB's `lincomb` machinery where the quantity is
  linear in the internal parameterization.
- Nonlinear derived quantities, such as ICCs and cross-trait correlations, need
  fix-and-refit profiling or a more invasive reparameterization.
- Boundary, non-monotone, and failed inner-optimization cases need explicit
  flags and bootstrap/profile-plot fallbacks.

## Checks Performed

- `Rscript -e "devtools::test()"`.
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`.

## Outcomes

- Full test suite: 139 passed, 0 failed.
- pkgdown check: no problems found.
- pkgdown site: built successfully.

## Remaining Limitations

- This task added design documentation only.
- No `confint(..., method = "profile")` API has been implemented.
- No profile-likelihood CI tests exist yet.

## Next Best Task

Do not implement profile CIs immediately. The next modelling work should remain
random slopes or comparator validation. Profile CIs should come after fitted
objects expose variance-component names and update/refit machinery can fix or
map parameters reliably.
