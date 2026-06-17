# After Task: Bivariate q8 recovery audit

## Goal

Run the newly merged q8 endpoint recovery artifact lane at a small local audit
scale and record whether it is ready for coverage or power use.

## Implemented

No likelihood or API code changed. The work ran the opt-in
`biv_gaussian_q8_endpoint_recovery` Actions task locally with two default cells
and 20 replicates per cell, then added a design-note audit and synchronized the
public status ledgers.

The local artifact path is
`inst/sim/results/actions/biv_gaussian_q8_endpoint_recovery_audit_20260607/`.
Those generated RDS and CSV files remain ignored local evidence; the committed
artifact is the audit note
`docs/design/161-phase-18-bivariate-q8-recovery-audit.md`.

## Mathematical Contract

The fitted model is the first ordinary Gaussian q8 all-endpoint slice:

```r
bf(
  mu1 = y1 ~ x + (1 + x | p | id),
  mu2 = y2 ~ x + (1 + x | p | id),
  sigma1 = ~ x + (1 + x | p | id),
  sigma2 = ~ x + (1 + x | p | id),
  rho12 = ~ 1
)
```

The eight group-level endpoints are the response-specific location intercepts,
location slopes, log-scale intercepts, and log-scale slopes. The eight endpoint
SDs are direct fitted targets; the 28 endpoint correlations are derived
group-level summaries. Residual `rho12` remains a separate row-level residual
coscale parameter.

## Files Changed

- `docs/design/161-phase-18-bivariate-q8-recovery-audit.md`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/67-sdstar-p8-poisson-q1.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/151-phase6c-random-slope-tutorial-ledger.md`
- `inst/sim/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-07-biv-q8-recovery-audit.md`

## Checks Run

- `/usr/bin/time -p Rscript -e 'devtools::load_all(".", quiet = TRUE); source("inst/sim/run/sim_run_actions_cell.R"); phase18_actions_main(c("--task=biv_gaussian_q8_endpoint_recovery", "--output-dir=inst/sim/results/actions/biv_gaussian_q8_endpoint_recovery_audit_20260607", "--n-reps=20", "--master-seed=20260635", "--cores=4", "--backend=multicore", "--overwrite=true"))'`
  completed in 106.57 seconds and wrote all expected artifact tables.
- `git diff --check` passed.
- `Rscript -e "devtools::test(filter = 'phase18-biv-gaussian-q8-endpoint')"`:
  75 passes, no failures, warnings, or skips in 49.4 seconds.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: completed
  successfully and rebuilt `pkgdown-site/`. During article rendering it emitted
  the known local TMB/glmmTMB version-mismatch warning:
  `glmmTMB was built with TMB package version 1.9.17; current TMB package
  version is 1.9.21`.
- Overclaim scan:
  `rg -n "q8.*(ready for coverage|ready for power|supports coverage|supports power|coverage-ready|power-ready|coverage result.*0\\.[0-9]|power result)" README.md NEWS.md ROADMAP.md docs inst/sim vignettes pkgdown-site --glob '!docs/dev-log/recovery-checkpoints/**' --glob '!pkgdown-site/deps/**' --glob '!pkgdown-site/search.json'`
  returned no matches.
- Rendered-site audit scan found the intended q8 audit wording in source docs
  and rendered home, NEWS, and ROADMAP pages.

## Tests Of The Tests

The run exercised the same source path used by the manual Actions task:
`sim_run_actions_cell.R` dispatch, q8 DGP, q8 fit wrapper, q8 fit summariser,
recovery summariser, and recovery grid writer. The manifest table records all
40 requested replicate slots, including the two failed optimization replicates,
so failures did not silently disappear from the audit.

## Consistency Audit

The audit decision is `hold_diagnostic`.

The evidence is useful but not promotable: 38/40 requested fits completed, but
only 8/38 completed fit objects reported optimizer convergence, no completed
fit had `pdHess = TRUE`, two fits failed with non-positive leading minors, and
all Wald interval rows were unusable because the q8 runner uses `se = FALSE`.

The public wording now says q8 is fitted and diagnostic-artifact ready, while
q8 coverage, q8 power, predictor-dependent q8 `corpair()` regression, random
`rho12`, structured q8, and non-Gaussian q8 remain closed.

## GitHub Issue Maintenance

Issue #5 is the relevant endpoint-covariance issue. The audit does not close
#5 because q8 coverage and power remain unavailable. Posted the audit summary
and PR pointer to #5:
<https://github.com/itchyshin/drmTMB/issues/5#issuecomment-4644265017>.

## What Did Not Go Smoothly

The q8 audit exposed weak optimization diagnostics rather than a clean
promotion path. That is valuable evidence, but it means the next q8 work should
be hardening or design narrowing, not a larger power grid.

## Team Learning

For q8 and similar high-dimensional covariance blocks, a successful artifact
writer is not enough. The first audit should always report manifest status,
optimizer convergence, positive-Hessian rate, interval availability, and the
exact failure messages before anyone discusses power.

## Known Limitations

This was a 40-fit local diagnostic audit over two default cells, not a formal
coverage grid. It did not request profile intervals, bootstrap intervals,
alternative starts, robust refits, constrained covariance, or larger sample
sizes.

## Next Actions

Keep q8 outside coverage and power grids until convergence/Hessian diagnostics
improve. If q8 is revisited, test a smaller or constrained endpoint covariance
design, stronger starts, or a larger group/repeat grid before expanding
replicate count.
