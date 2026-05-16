# After Phase: Phase 6d Stable-Core Validation And Engine-Hardening Closure

Date: 2026-05-15

## Goal

Close the Phase 6d audit-response lane locally. The goal was not to add a broad
new modelling surface. It was to make the current stable core easier to trust:
clearer status tables, explicit validation debt, safer uncertainty controls,
guardrails for large-data and covariance claims, count-kernel hardening, and a
bounded C++ modularization plan.

## Implemented

- Slice 77 added the README and model-map stable-core feature matrix.
- Slice 78 added `docs/design/34-validation-debt-register.md`.
- Slice 79 added `drm_control(se = FALSE)` and explicit skipped or failed
  `sdreport()` uncertainty states.
- Slice 80 added the optimizer/start/map/multi-start contract in
  `docs/design/35-optimizer-start-map-multistart.md` and re-pinned profile
  callbacks to the selected optimizer state.
- Slice 81 added dense known-covariance diagnostics and large-data claim
  guardrails.
- Slice 82 replaced NB2 observed-count likelihood loops with a shared helper
  using a closed-form `lgamma` ratio and a small-overdispersion series guard.
- Slice 83 added `docs/design/36-cpp-modularization-source-map.md`.
- Slice 84 closes the local Phase 6d gate with this after-phase report, ROADMAP
  and NEWS updates, local checks, pkgdown evidence, and check-log evidence.

## Scope Boundary

Phase 6d did not implement sparse or block-sparse known sampling covariance,
public starts or maps, fallback optimizers, multi-start fitting, broad C++
header extraction, new approximation methods for sparse binary latent-variable
models, or new fitted families. Those remain future work until they have code,
tests, diagnostics, docs, and their own after-task evidence.

## Standing Review Closure

- Ada: Phase 6d is locally closed as a hardening and evidence lane, not a
  feature-expansion lane.
- Boole: no formula grammar changed during the closure gate.
- Gauss: the only likelihood change in Phase 6d was the NB2 helper
  implementation, and it has objective-level comparisons against independent R
  calculations.
- Noether: public `sigma`, `rho12`, `sd(group)`, `meta_known_V(V = V)`, and
  hidden `model_type` wording now stay aligned across the source map and design
  docs.
- Darwin: applied users now see which model surfaces are stable, first-slice,
  opt-in, planned, or rejected before interpreting biological effects.
- Fisher: validation debt is explicit rather than buried in prose.
- Pat: the README/model-map stable-core matrix gives a practical first stop for
  users deciding whether a model surface is ready.
- Jason: the C++ source-map plan separates current implementation from future
  file movement.
- Curie: new tests target uncertainty states, dense covariance diagnostics,
  count kernels, and mapped hidden branches without adding slow stochastic
  burdens.
- Emmy: the R-to-TMB ABI and report names are protected before any future C++
  split.
- Grace: local full tests, pkgdown build/check, and `R CMD check` are green;
  GitHub Actions remains the PR-side gate.
- Rose: stale-claim scans found no local claim that the remaining Phase 6d debt
  is implemented.

## Files Changed In Gate Slice

- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-phase/2026-05-15-phase-6d-stable-core-hardening-closure.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-phase/2026-05-15-phase-6d-stable-core-hardening-closure.md`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "check-drm|control|optimizer-contract|count-kernels|covariance-block-registry|phylo-utils|biv-gaussian|gaussian-random-intercepts|spatial-gaussian|package-skeleton", reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`
- `git diff --check`
- Source and rendered scans for Phase 6d local closure wording and stale
  overclaims about unresolved debt.

All tests and checks passed. `pkgdown::check_pkgdown()` found no problems.
`devtools::check()` passed with 0 errors, 0 warnings, and 0 notes in 2m 29.6s.

## Tests Of The Tests

The closure gate combined focused tests for the changed Phase 6d surfaces with
the full package test suite. The focused gate included diagnostic, control,
optimizer, NB2 count-kernel, covariance-block, phylogenetic probe, bivariate,
ordinary random-effect, spatial, and package-skeleton tests. The full suite and
package check then verified that no neighbouring model path was broken by the
hardening work.

## Consistency Audit

The source and rendered ROADMAP now mark Slices 77 to 84 as locally complete.
NEWS records the user-facing and developer-facing changes from Phase 6d. The
source-map article points to the validation-debt and C++ modularization design
notes. The validation-debt register continues to list sparse known covariance,
large-data compatibility breadth, broader structured effects, and future
interval methods as debt rather than complete support.

## What Did Not Go Smoothly

Phase 6d sat across many parts of the package, so the main risk was
overclaiming. Rose's repeated stale-wording scans were necessary because some
changes were diagnostic or documentary rather than fitted model support.

## Known Limitations

- GitHub Actions remains the PR-side gate.
- One open pull request remains in the repository queue:
  [#45](https://github.com/itchyshin/drmTMB/pull/45). No new PR was opened
  during this local closure.
- Sparse and block-sparse known covariance remain planned.
- Public start, map/fixed-parameter, fallback optimizer, and multi-start
  controls remain planned.
- The C++ modularization source map is a plan; no helper headers were created
  yet.
- Adaptive Gauss-Hermite or other alternatives to Laplace approximation are not
  part of `drmTMB` Phase 6d.

## Next Actions

1. Decide whether to move this branch behind the remaining open PR or wait for
   that queue to clear.
2. If Phase 6d is pushed, let GitHub Actions serve as the final remote gate.
3. Continue with Phase 10+ or the first mechanical C++ helper extraction only
   as separate focused slices.
