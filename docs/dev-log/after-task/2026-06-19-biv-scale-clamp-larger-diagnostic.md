# Bivariate `sigma1`/`sigma2` Scale Clamp Larger Diagnostic

## Goal

Bank the first Big 4 implementation block after the post-#633 decision ledger:
a larger native R/TMB fixed-effect bivariate Gaussian `sigma1`/`sigma2`
scale-clamp diagnostic for `drmTMB#59`.

## Implemented

The implemented claim is narrow: the repository now has a reproducible
diagnostic artifact showing how the configurable Gaussian `log(sigma)` clamp
behaves for fixed-effect native R/TMB bivariate Gaussian `sigma1`/`sigma2`
scale fits under ordinary, high-scale, low-scale, and residual-correlation
stress cells.

This is not a package-code change. It is an evidence and status update for the
numerical-guard programme.

## Mathematical Contract

The fitted route is:

```r
bf(
  mu1 = y1 ~ x,
  mu2 = y2 ~ x,
  sigma1 = ~ z1,
  sigma2 = ~ z2,
  rho12 = ~ 1
)
```

with `family = biv_gaussian()`. Location, scale, and residual correlation are
fixed-effect terms only. The artifact varies scale-generating conditions and
residual `rho12`, then compares unclamped, default-clamped, and wide-clamped
native R/TMB fits. It does not add or evaluate random effects in residual
`rho12`, structured correlations, q2/q4/q8 covariance blocks, missing-data
routes, or a Julia bridge path.

## Files Changed

- `docs/dev-log/simulation-artifacts/2026-06-19-biv-scale-clamp-larger-diagnostic/`
- `docs/design/176-numerical-guard-simulation-audit.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/177-big4-finish-plan-2026-06-19.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-19-biv-scale-clamp-larger-diagnostic.md`

## What Changed

The new artifact deepens the earlier 120-fit bivariate scale diagnostic. It
uses fixed-effect native R/TMB `biv_gaussian()` fits with
`bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ z1, sigma2 = ~ z2, rho12 = ~ 1)`.
It runs 10 cells, 50 replicates per cell, and three clamp controls:
unclamped, default, and wide `logsigma_clamp = c(-25, 25)`.

The runner records raw and reported `log_sigma1`/`log_sigma2`, upper and lower
clamp deltas, `check_drm()` rows, convergence, positive-Hessian status,
fixed-gradient warnings, optimizer attempts, automatic preset escalation,
warnings, failures, and replicate-matched differences against the unclamped
reference. It uses one start, no fallback optimizer, no manual retry budget, no
profile intervals, and no bootstrap intervals.

## Results

The artifact ran 1500 requested fits with 0 fit errors, 1492 optimizer-converged
fits, and 1497 fits with `pdHess = TRUE`. The default upper-clamp warning
appeared 150 times, matching the three upper out-of-band cells. Raw-versus-
reported log-scale deltas recorded 150 upper-side clamp-active fits and 100
lower-side clamp-active fits.

The ordinary residual-correlation cells (`rho12 = 0`, `0.8`, and `-0.8`) and
the near-upper in-band cell had no clamp-active fits and matched the unclamped
reference to numerical tolerance. Upper out-of-band default rows visibly
surfaced the guard and produced large default-vs-unclamped differences.

The lower side remains diagnostic-hold. Lower in-band and lower out-of-band
rows retained many fixed-gradient warnings and automatic optimizer preset
escalations; `retry_count` reached 2. The `sigma2_below_default` wide-band row
had one non-converged fit and a maximum log-likelihood difference of
`24.4263376` against the unclamped reference. These rows are not recovery,
interval, or readiness evidence.

## Checks Run

```sh
air format docs/dev-log/simulation-artifacts/2026-06-19-biv-scale-clamp-larger-diagnostic/run-pilot.R
/usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-19-biv-scale-clamp-larger-diagnostic/run-pilot.R
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
git diff --check
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "clamp", reporter = "summary")'
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "check-drm", reporter = "summary")'
RSTUDIO_PANDOC=/opt/homebrew/bin /usr/local/bin/Rscript --vanilla -e "pkgdown::check_pkgdown()"
tools/start-mission-control.sh --background
```

Artifact assertions, claim-boundary scans, and pkgdown validation are recorded
in `docs/dev-log/check-log.md`.

## Tests Of The Tests

The artifact assertions check the denominator and main status counts: 1500
requested fits, 0 fit errors, 1492 optimizer-converged fits, 1497
positive-Hessian fits, 150 default upper-clamp warnings, 150 upper-side
raw-versus-reported clamp-delta detections, 100 lower-side clamp-delta
detections, and a maximum automatic optimizer escalation count of 2.

The table assertions check that lower-side clamp deltas are detected only in
the lower-tail default rows, that non-converged and non-positive-Hessian rows
stay visible by condition and clamp configuration, and that 322 rows record
automatic optimizer preset escalation. Those checks matter because the main
risk in this block was not a missing fit object; it was accidentally turning a
guarded or escalated fit into ordinary-looking evidence.

The focused package checks exercise the neighbouring diagnostics rather than
the artifact alone: `devtools::test(filter = "clamp")` covers clamp warning
paths, and `devtools::test(filter = "check-drm")` covers the diagnostic surface
that users and simulation summaries read.

## Consistency Audit

This is a native R/TMB diagnostic artifact only. It does not change package
code, formula grammar, likelihood parameterization, tests, or user-facing
functions. It does not test direct DRM.jl or the R-side Julia bridge.

The stale-claim scan used this pattern:

```sh
rg -n 'bivariate scale.*(coverage|power|release|CRAN|Julia bridge|AI-REML|REML|recovery accuracy|random effects in `rho12`)|sigma1.*sigma2.*(coverage|power|release|CRAN|Julia bridge|AI-REML|REML|recovery accuracy)|engine_control' README.md ROADMAP.md NEWS.md docs vignettes R tests
```

The hits were historical, planned, registry, or negative-boundary wording, not
new promotion claims from this block. Old after-task notes and historical
design sections were left intact where they were true when written.

## GitHub Issue Maintenance

The active issue is still `drmTMB#59`, "Phase 18: comprehensive simulation
framework and reporting". It was open when checked after the artifact pass, and
the post-block breadcrumb was posted here:
https://github.com/itchyshin/drmTMB/issues/59#issuecomment-4751579119.

The breadcrumb records the artifact path, 1500-fit denominator, convergence and
`pdHess` counts, upper- and lower-side clamp evidence, validation commands,
and the boundary that this is native R/TMB diagnostic evidence only.

## What Did Not Go Smoothly

The first full runner exposed an optimizer-metadata representation problem:
the optimizer attempts needed to be carried as structured artifact fields
rather than flattened away. The final artifact keeps `optimizer_attempts`,
`optimizer_used`, `n_optimizer_attempts`, and `retry_count` visible.

The lower-tail cells were rougher than a simple guard-visibility story would
suggest. Lower in-band and lower out-of-band rows retained fixed-gradient
warnings and automatic optimizer preset escalation, and the
`sigma2_below_default` wide-band row had a non-converged fit plus a maximum
log-likelihood difference of `24.4263376` against the unclamped reference. The
artifact therefore supports lower-tail diagnostic visibility, not lower-tail
recovery or interval readiness.

The `check_drm()` warning path directly exposes upper clamp activation. Lower
activation needed raw-versus-reported log-scale deltas, so future lower-tail
guard audits should include those deltas from the start rather than relying on
warning rows alone.

## Team Learning

For scale guards, the review standard should ask for three separate quantities:
whether a warning is visible, whether raw-versus-reported parameters changed,
and whether optimizer intervention occurred. Any one of those can make a fit
diagnostic even when convergence and `pdHess` look acceptable.

The next q2 block should not inherit the bivariate scale artifact as a recovery
claim. It can inherit the audit discipline: route-specific conditions,
replicate-matched reference comparisons, intervention fields, warning/status
tables, and explicit native R/TMB versus Julia boundary wording.

## Known Limitations

The artifact does not estimate recovery accuracy, interval coverage, power,
q2/q4/q8 covariance readiness, random effects in `rho12`, structured
correlation readiness, missing-data behavior, release readiness, CRAN
readiness, direct Julia behavior, Julia-via-R behavior, or non-Gaussian
REML/AI-REML.

## Next Actions

Before moving to ordinary q2 hardening, decide whether the lower-tail
bivariate scale roughness needs a focused method audit or whether it should
remain a documented diagnostic boundary for the q2 block.
