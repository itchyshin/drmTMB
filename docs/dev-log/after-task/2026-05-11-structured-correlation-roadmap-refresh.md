# After Task: Structured Correlation Roadmap Refresh

## Goal

Record the future modelling requirement that residual `rho12`, phylogenetic
correlation, and non-phylogenetic species or individual correlation must remain
separate layers in structured two-response models.

## Implemented

- Updated `ROADMAP.md` Phase 11 to keep the first individual-difference
  covariance target focused on ordinary grouped personality and plasticity
  terms before adding structured phylogenetic or non-phylogenetic species
  correlation layers.
- Updated `ROADMAP.md` Phase 12 to state that future two-response or two-trait
  structured models should estimate and report phylogenetic correlation,
  non-phylogenetic species correlation, and residual `rho12` separately.
- Updated `docs/design/28-double-hierarchical-endpoint.md` so the endpoint
  order distinguishes ordinary grouped covariance, bivariate phylogenetic and
  non-phylogenetic species covariance, residual `rho12`, and later spatial
  covariance.
- Updated `docs/design/20-coscale-correlation-pairs.md` so the correlation-pair
  namespace keeps those three layers visible at the same time.

## Mathematical Contract

This is a planning and documentation update only. It does not add a new
likelihood. The intended future decomposition is:

```text
residual rho12: within-observation residual response coupling
phylogenetic correlation: covariance induced by shared evolutionary history
non-phylogenetic group correlation: remaining species or individual covariance
```

The roadmap now treats these as different covariance layers, not alternative
names for the same parameter.

## Files Changed

- `ROADMAP.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-11-structured-correlation-roadmap-refresh.md`

## Checks Run

- `air format ROADMAP.md docs/design/20-coscale-correlation-pairs.md docs/design/28-double-hierarchical-endpoint.md`
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `LC_ALL=C rg -n "[^\x00-\x7F]" ROADMAP.md docs/design/20-coscale-correlation-pairs.md docs/design/28-double-hierarchical-endpoint.md`

Pkgdown rebuilt successfully and `pkgdown::check_pkgdown()` found no problems.

## Tests Of The Tests

No model code changed. The relevant check is a documentation consistency check:
the roadmap, endpoint design note, and correlation-pair design note now all
separate residual `rho12` from structured phylogenetic and non-phylogenetic
correlations.

## Consistency Audit

- The update does not claim phylogenetic or non-phylogenetic correlation
  modelling is implemented.
- The wording keeps `rho12` reserved for residual bivariate correlation.
- The implementation order still starts with ordinary grouped
  individual-difference covariance before structured phylogenetic or spatial
  covariance.

## What Did Not Go Smoothly

No code problem occurred. The main process lesson is to record future modelling
requirements in the roadmap as soon as they are clear, so later coding work does
not accidentally optimize the wrong correlation layer.

## Team Learning

Darwin and Pat both matter here: the correlation layers answer different
biological questions, and the user-facing output must make that difference
visible. Rose's role is to keep this distinction from drifting as Phase 11,
Phase 12, and Phase 13 evolve.

## Known Limitations

- No bivariate phylogenetic covariance likelihood is implemented.
- No non-phylogenetic species covariance block is implemented.
- `corpairs()` cannot yet report these structured layers because the
  corresponding fitted covariance blocks do not exist.

## Next Actions

1. Finish the ordinary grouped individual-difference covariance path before
   adding structured phylogenetic correlation layers.
2. When the first bivariate phylogenetic block is designed, add matching
   `corpairs()` rows for phylogenetic, non-phylogenetic species, and residual
   correlation layers.
3. Add simulation recovery before any reader-facing tutorial claims the model
   is available.
