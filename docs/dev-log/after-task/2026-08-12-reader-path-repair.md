# After Task: Reader-path P1 documentation repair

## Goal

Repair the highest-priority reader gaps identified by the ten-workflow audit:
remove internal phylogenetic access from the beginner path, complete the
bipartite post-fit endpoint, and give fixed-effect ordinal analysis an honest
interpretation workflow.

## Implemented

Three existing articles now carry public fit → diagnostic → reporting routes.
The phylogenetic tutorial uses `check_drm()`, `coef()`, and
`profile_targets()`. The bipartite tutorial adds public diagnostic/status,
conditional-deviation table, and point-only plot. The distribution guide now
fits an ordinal model, checks it, reports fixed-effect Wald uncertainty, and
builds fitted category probabilities with `fitted_distribution()`.

## Mathematical Contract

No model changed. `phylo()` remains a structured location effect; its SD is
read from a response-scale public target. `phylo_interaction()` deviations are
conditional log-rate deviations, not individual-pair intervals. The ordinal
model retains ordered latent-logistic cutpoints, no free `mu` intercept, and
fixed latent scale; its location Wald interval is distinct from cutpoint or
category-probability uncertainty.

## Files Changed

- `vignettes/phylogenetic-models.Rmd`
- `vignettes/bipartite-phylogenetic-interactions.Rmd`
- `vignettes/distribution-families.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-08-12-reader-path-repair.md`

## Checks Run

- Rendered the three changed articles after `pkgload::load_all()` — passed.
- `test-cumulative-logit.R` — passed.
- `test-phylo-interaction.R` — passed, with four expected On-CRAN skips.
- `pkgdown::check_pkgdown()` — no problems.
- `git diff --check` — passed.

## Tests Of The Tests

The rendered ordinal workflow calls the public `fitted_distribution()$d()`
vectorized over the prediction grid; a prior direct inspection established
that this returns per-category probabilities without reimplementing the
ordinal likelihood. The phylogenetic SD target was checked on a live small fit
before replacing internal fields.

## Consistency Audit

Searched all three articles for `fit$opt`, `fit$sdpars`, and raw ordinal target
wording. The repaired reader-facing paths contain none of the first two. The
only raw ordinal target text now labels it internal and non-reportable. Terms
remain consistent: `sigma` is not a phylogenetic SD, `rho12` is not involved,
and `meta_V()` is untouched.

## GitHub Issue Maintenance

Reviewed open related issues. #967 already records the ordinal-cutpoint
decision, so no duplicate issue or comment was needed. No open issue matched a
new package defect in the phylogenetic or bipartite documentation route.

## What Did Not Go Smoothly

The public ordinal distribution interface is vectorized by prediction row, so
the category table must evaluate each category over the full grid. Confirming
that shape before writing the vignette prevented an attractive but wrong
one-row probability table.

## Team Learning

Public extractors are not merely polish. They make a tutorial resilient to
internal object refactors and show users which outputs are safe to report.

## Known Limitations

This documentation repair does not add ordinal cutpoint intervals, calibration
for structured SDs, individual-pair intervals, or broader structured ordinal
effects. It does not change any capability tier.

## Next Actions

Merge this docs-only repair after CI. The next capability decision remains the
separate #967 ordinal-cutpoint interval implementation; its math and
calibration gate stay independent of this reader documentation work.
