# After Task: Spatial Q2 ADEMP Admission

## Goal

Close the Phase 18 documentation gate for the fitted coordinate-spatial q=2
bivariate Gaussian location covariance path, without widening spatial support
beyond the tested coordinate subset.

## Implemented

Added `docs/design/56-phase-18-spatial-q2-ademp.md` for matching
`spatial(1 | p | site, coords = coords)` terms in bivariate `mu1` and `mu2`
formulas. The sheet names the DGP hierarchy, estimands, fitted syntax,
performance measures, and failure-ledger boundaries for a focused Phase 18
spatial q=2 grid.

Updated `docs/design/41-phase-18-simulation-programme.md`,
`docs/design/46-pre-simulation-readiness-matrix.md`, and
`docs/design/16-phylo-spatial-common-math.md` so they no longer say the q=2
spatial lane is waiting for an ADEMP row. The new status admits constant q=2
coordinate-spatial location covariance for a focused grid, while broad reports
still need a dedicated DGP, manifest writer, and interval-status artifacts.

## Mathematical Contract

The admitted q=2 spatial layer is

```text
Cov(u_a[s], u_b[t]) = S[a, b] * K_space[s, t]
```

where `K_space` is the coordinate-derived spatial covariance for sites, and
`S` contains `sd_spatial1`, `sd_spatial2`, and `rho_spatial`. The residual
correlation `rho12` remains an observation-level layer and must not be merged
with `corpairs(level = "spatial")`.

## Files Changed

- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/56-phase-18-spatial-q2-ademp.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-21-spatial-q2-ademp-admission.md`

## Checks Run

```sh
Rscript -e "devtools::test(filter = 'spatial-gaussian')"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
rg -n 'bivariate q=2 spatial needs an explicit ADEMP|fitted but waits for a dedicated ADEMP|waiting for an ADEMP row|keep bivariate q=2 spatial out of broad grids until an ADEMP row|simulation programme has not decided|spatial q=2 now needs the next gallery refresh' docs/design/16-phylo-spatial-common-math.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/56-phase-18-spatial-q2-ademp.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-spatial-q2-ademp-admission.md README.md ROADMAP.md vignettes/phylogenetic-spatial.Rmd
```

Outcomes:

- The focused spatial Gaussian test passed 98 expectations.
- `pkgdown::check_pkgdown()` reported no problems.
- `git diff --check` was clean.
- The stale-status scan returned only the historical "was waiting" wording in
  this report and the still-open ROADMAP note that the correlation-layer figure
  gallery needs a spatial q=2 refresh.

## Tests Of The Tests

The focused spatial Gaussian test already fits the q=2 spatial model with
matching `spatial(1 | p | site, coords = coords)` terms, compares the fitted
objective to an independently assembled dense covariance likelihood, verifies
`corpairs(level = "spatial")`, checks direct profile target names for both
spatial SDs and the spatial correlation, checks `summary(fit)$covariance`, and
exercises `simulate()` and `predict()`. This slice did not add likelihood code,
so the test rerun is a regression check for the evidence being cited.

## Consistency Audit

Ada and Rose checked the status chain across the spatial parity ladder, Phase
18 scenario map, readiness matrix, and new ADEMP sheet. The status now says q=2
coordinate-spatial location covariance is fitted and admitted for a focused
grid, but broad Phase 18 reports still require a DGP/helper/artifact slice.

## GitHub Issue Maintenance

No GitHub issue update was attempted for this documentation-only admission
slice. The local check log and after-task report carry the evidence handoff.

## What Did Not Go Smoothly

The main risk was overclaiming. The implementation evidence is stronger than a
paper note, but there is still no dedicated `inst/sim/` q=2 spatial DGP or
interval-status writer. The final text therefore admits the focused grid while
blocking broad reports until those artifacts exist.

## Team Learning

Pat's question was whether an applied user can tell what to fit now. The answer
is yes for constant coordinate-spatial q=2 location covariance. Fisher's
question was whether this is enough for full coverage claims. The answer is no:
coverage needs the next simulation artifact slice.

## Known Limitations

This slice does not add new code. Mesh/SPDE, multiple spatial slopes, slope
correlations, spatial `sigma`, spatial q=4, spatial direct-SD surfaces,
spatial `corpair()` regression, and broad q=2 coverage reports remain outside
the admitted surface.

## Next Actions

- Add the dedicated Phase 18 q=2 spatial DGP, smoke runner, CSV writer, and
  interval-status artifacts.
- Keep the first example biological, for example paired abundance and growth
  deviations across nearby reef sites.
