# After Task: Slice 189 Gaussian DH Boundary

## Goal

Close remaining Gaussian double-hierarchical boundary wording before the
non-Gaussian revisit.

## Implemented

The double-hierarchical endpoint map now reflects the current Gaussian surface
after Slices 177-188. It names q > 2 ordinary Gaussian `mu` blocks, independent
Gaussian `sigma` slopes, one or more univariate mean-scale intercept blocks,
and coordinate-spatial one-slope support as fitted. It keeps bivariate slope
blocks, q=6/q=8 endpoint blocks, spatial q=4 covariance, spatial slope
correlations, and slope-level mean-scale covariance planned.

## Mathematical Contract

This slice did not change the model. It corrected the status map for the
Gaussian double-hierarchical ladder:

```text
fitted now:    intercept-level and selected one-slope/q>2 Gaussian pieces
planned next: slope-level mean-scale, bivariate slopes, q=6/q=8 endpoints
deferred:     spatial q=4, spatial slope correlations, structured slope DH
```

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-189-gaussian-dh-boundary.md`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `rg -n "full double-hierarchical.*implemented|complete double-hierarchical.*implemented|q=6.*implemented|q=8.*implemented|spatial q=4.*implemented|bivariate random-slope.*implemented|slope-level mean-scale.*implemented" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes --glob '!docs/dev-log/check-log.md'`:
  returned no stale implemented-status claims.
- `git diff --check`: passed.

## Tests Of The Tests

This is a documentation/status slice. It relies on the tests and interval
checks from Slices 177-188 and adds no new executable test.

## Consistency Audit

The endpoint map, roadmap, NEWS, and known-limitations page now use the same
boundary: Gaussian random-effect support is broad enough for a pre-simulation
gate, but it is not the full double-hierarchical endpoint.

## What Did Not Go Smoothly

The wording had to distinguish "first slice implemented" from "complete
endpoint implemented." The biggest risk was implying that q=4 intercept blocks
also opened q=6/q=8 random-slope endpoints.

## Team Learning

Ada used the endpoint map as the source of truth before opening the
non-Gaussian gate. Noether separated fitted covariance dimensions from planned
ones. Fisher kept profile/derived-interval status visible. Pat wanted the
reader-facing boundary to be plain. Grace kept validation to pkgdown and stale
wording scans because no code changed. Rose recorded the remaining Gaussian
limits before Slice 190.

## Known Limitations

No new Gaussian or non-Gaussian random-effect likelihoods were added. The
closed surfaces are still closed.

## Next Actions

Slice 190 should decide which fixed-effect non-Gaussian families get the first
ordinary `mu` random-intercept path and which retain explicit unsupported
messages.
