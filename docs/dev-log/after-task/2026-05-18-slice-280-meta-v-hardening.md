# After Task: Slice 280 Meta-V Hardening

## Goal

Harden the preferred `meta_V(V = V)` route before broader simulation claims:
vector and full-matrix known covariance should be covered by the preferred
spelling, `scale = "exact"` should not look like a missing implementation, and
current user-facing prose should point to `meta_V()` while keeping
`meta_known_V()` as a compatibility alias.

## Standing Perspectives

- Ada kept this as an API and evidence-hardening slice, not a new
  meta-analysis likelihood.
- Fisher checked that Wald fixed-effect intervals remain attached to estimated
  coefficients and not to known `V`.
- Curie kept the tests focused on alias equivalence, matrix `V`, and the exact
  default boundary.
- Pat checked that users see `meta_V(V = V)` as the next thing to type.
- Grace checked regenerated Rd files, pkgdown, and whitespace.
- Rose used stale-wording scans to catch current docs that still framed
  `meta_known_V()` as the primary spelling.

No spawned subagents were used.

## Implemented

The `meta_V()` parser now gives a targeted error for
`meta_V(V = V, scale = "exact")`: additive exact known covariance is already
the default when the user supplies `V`, so the user should remove `scale`.
`tests/testthat/test-meta-known-v.R` now checks that full-matrix
`meta_V(V = V)` routes to the same likelihood as `meta_known_V(V = V)`, stores
`V_known_type = "matrix"`, and returns finite Wald intervals for fixed `mu`
coefficients. The `drmTMB()`, `meta_vcov_bivariate()`, `relmat()`, README,
known-limitations, likelihood-weights, NEWS, and roadmap prose now lead with
`meta_V(V = V)` where the text describes the current preferred known-covariance
surface.

## Mathematical Contract

No likelihood parameterization changed. `V` remains known sampling covariance
added to the Gaussian covariance model. It is not an estimated parameter, not a
profile or Wald interval target, and not a row likelihood weight. The fitted
`sigma`, random-effect SDs, and bivariate `rho12` remain estimated residual or
latent quantities after known sampling covariance is accounted for.

## Files Changed

- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `R/drmTMB.R`
- `R/formula-markers.R`
- `R/meta-vcov.R`
- `docs/design/22-likelihood-weights.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-204217-codex-checkpoint.md`
- `man/drmTMB.Rd`
- `man/meta_vcov_bivariate.Rd`
- `man/relmat.Rd`
- `tests/testthat/test-meta-known-v.R`

## Checks Run

- `air format R/drmTMB.R R/meta-vcov.R tests/testthat/test-meta-known-v.R`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'meta-known-v', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'meta-known-v|profile-targets|phase18-meta-v', reporter = 'summary')"`
- `air format NEWS.md README.md ROADMAP.md R/drmTMB.R R/formula-markers.R R/meta-vcov.R docs/design/22-likelihood-weights.md docs/dev-log/known-limitations.md tests/testthat/test-meta-known-v.R`
- `Rscript -e "devtools::document()"`
- `rg -n 'preferred.*meta_known_V|use \\[meta_known_V\\]|use `meta_known_V|known `V` matrix used by \\[meta_known_V\\]|Known sampling variance or covariance remains separate and should use `meta_known_V|covariance remains `meta_known_V|meta-analysis should use `meta_known_V|meta_V\\(V = V, scale = "exact"\\).*implemented|scale = "exact".*implemented|weights = 1 / vi.*same model|tau ~|meta_gaussian' README.md NEWS.md ROADMAP.md docs/design vignettes R man tests/testthat --glob '!docs/dev-log/**'`
- `rg -n 'Slice 280|meta_V\\(V = V\\).*hardening|scale = "exact"|without.*scale|exact additive|preferred known-covariance|full-matrix alias|Wald fixed-effect interval|meta_vcov_bivariate\\(\\).*meta_V|compatibility alias' NEWS.md README.md ROADMAP.md docs/design/22-likelihood-weights.md docs/dev-log/known-limitations.md R/drmTMB.R R/formula-markers.R R/meta-vcov.R man/drmTMB.Rd man/meta_vcov_bivariate.Rd man/relmat.Rd tests/testthat/test-meta-known-v.R`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript tools/codex-checkpoint.R --goal "Slice 280 meta_V hardening" --next "stage, commit, push, and open draft PR"`

The focused and broader meta-analysis tests passed. `pkgdown::check_pkgdown()`
reported no problems, and `git diff --check` reported no whitespace errors.

## Tests Of The Tests

The updated alias test fits both vector and full-matrix known covariance through
`meta_V(V = V)` and compares the full-matrix fit against the compatibility
alias on coefficients and log-likelihood. It also asks `confint()` for fixed
`mu` rows and checks that the interval status is Wald with finite endpoints.
The malformed-call test now checks the exact-scale default boundary rather than
the generic proportional-variance reservation.

## Consistency Audit

The stale-wording scan found current-facing README, known-limitation,
likelihood-weight, and roxygen text still pointing users to `meta_known_V()` as
the main spelling. Those were updated to lead with `meta_V()`. Remaining
matches are compatibility-alias explanations, older NEWS/history entries,
intentional design boundaries that forbid `meta_gaussian()` or `tau ~`, and
the tutorial sentence explaining that `weights = 1 / vi` is not the same model
as `meta_V(V = vi)`.

## What Did Not Go Smoothly

The first implementation patch passed tests, but the prose scan showed the
naming cleanup was incomplete. This was useful friction: the code path and
tests were already right, but the user-facing status table and limitations file
would still have taught the old spelling as the main route.

## Team Learning

For alias migrations, Rose should scan current docs separately from historical
NEWS. A compatibility alias can remain visible, but README, help pages, and
known limitations should all agree on the preferred spelling before the slice
is called done.

## Known Limitations

`meta_known_V(V = V)` remains supported as a compatibility alias. This slice
does not add proportional sampling-variance likelihoods, sparse known
covariance storage, full-matrix known `V` with non-unit weights, missing
single-outcome bivariate meta-analysis, or new interval targets for known `V`.

## Next Actions

Stage, commit, push, and open the Slice 280 draft PR against Slice 279, then
move to Slice 281 for structural-dependence user-surface work unless the 5 AM
report cutoff arrives first.
