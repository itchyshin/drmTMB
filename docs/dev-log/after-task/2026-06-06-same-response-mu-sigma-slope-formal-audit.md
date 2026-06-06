# After Task: Same-Response Mu/Sigma Slope Formal Audit

## Goal

Run the new Phase 18 `biv_gaussian_mu_sigma_slope_recovery` lane at formal
replicate count and decide whether the same-response q2 `mu`/`sigma` slope
covariance route is strong enough for power-grid use.

## Implemented

The audit ran the existing recovery writer without adding a new fitted model
surface. It used the default two-cell condition grid, 500 replicates per cell,
master seed `20260630`, eight multicore replicate workers, and
`require_complete = TRUE`.

The generated artifact directory is local and git-ignored:

```text
inst/sim/results/actions/biv_gaussian_mu_sigma_slope_recovery
```

## Mathematical Contract

The audited route fits a same-response location-scale slope block:

```r
mu1 = y1 ~ x + (0 + x | p | id)
sigma1 = ~ x + (0 + x | p | id)
mu2 = y2 ~ x
sigma2 = ~ x
rho12 = ~ 1
```

The group-level `cor(mu1:x,sigma1:x | p | id)` row is distinct from residual
`rho12`. The two slope SD rows and the derived same-response correlation remain
without Wald interval endpoints.

## Files Changed

This audit updated current status prose in `NEWS.md`, `README.md`,
`ROADMAP.md`, `docs/design/46-pre-simulation-readiness-matrix.md`,
`docs/design/67-sdstar-p8-poisson-q1.md`,
`docs/design/157-capability-completion-worklist.md`,
`docs/dev-log/known-limitations.md`, and `docs/dev-log/check-log.md`.

## Checks Run

- `Rscript -e 'devtools::load_all(quiet = TRUE); source("inst/sim/run/sim_run_actions_cell.R"); phase18_actions_main(...)'`
  ran `biv_gaussian_mu_sigma_slope_recovery` with `n_reps = 500`,
  `cores = 8`, `backend = "multicore"`, `master_seed = 20260630`,
  `overwrite = TRUE`, and `require_complete = TRUE`.
- The runner printed the expected Phase 18 task summary and exited with status
  0.
- Artifact audit of the generated CSVs found 1,000 manifest rows, all with
  `status = "ok"`, and 12,000 replicate-parameter rows.
- Unique fit diagnostics showed 428/500 converged positive-Hessian fits in
  `biv_gaussian_mu_sigma_slope_001` and 442/500 in
  `biv_gaussian_mu_sigma_slope_002`.
- Failure-ledger rows were warnings, not skipped or error rows: 92
  `NA/NaN function evaluation` warnings and 78 `NaNs produced` warnings.
- Fixed-effect Wald coverage among interval-available fits ranged from 0.796
  to 0.850 across the two cells.
- `Rscript -e "devtools::test(filter = 'phase18-biv-gaussian-mu-sigma-slope-recovery')"`
  returned 27 passes, no failures, warnings, or skips.
- `Rscript -e "pkgdown::build_site()"` completed and wrote `pkgdown-site`;
  it emitted the known local `glmmTMB`/`TMB` version mismatch warning.
- `Rscript -e "pkgdown::check_pkgdown()"` returned "No problems found."
- Current-source stale scan:
  `rg -n "completed formal artifact audit still needed|still needs a completed formal artifact audit|still needs larger-grid evidence before power|same-response q2.*not a completed|same-response q2.*still needs|same-response.*power-grid use" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md docs/dev-log/check-log.md --glob '!docs/dev-log/after-task/2026-06-05-same-response-mu-sigma-slope-recovery-lane.md'`
  returned only the historical check-log command and the new task sentence that
  says the audit tested whether power-grid use is supported.
- Rendered-site stale scan:
  `rg -n "same-response.*(source-tested only|source-tested and still|no formal Actions|formal Actions artifacts still needed|formal artifacts still needed|source-test level|source tests but no formal)|same-response location-scale slope covariance.*(planned|closed|blocked|unsupported)|same-response q2.*source-test|same-response q2.*source recovery|same-response slope covariance.*still needs formal|mu/sigma.*formal Actions artifacts still needed|completed formal artifact audit still needed|still needs a completed formal artifact audit|still needs larger-grid evidence before power" pkgdown-site --glob '!search.json' --glob '!deps/**'`
  returned one intended NEWS match where cross-response and all-four p8/q8
  neighbours remain closed.
- Rendered-site evidence scan:
  `rg -n "same-response q2.*(diagnostic audit|formal audit|500-replicate)|0\\.856|0\\.884|0\\.796-0\\.850|power-grid support" pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html pkgdown-site/articles/implementation-map.html pkgdown-site/articles/model-map.html pkgdown-site/articles/formula-grammar.html --glob '!search.json'`
  found the new diagnostic wording on the homepage, NEWS, and ROADMAP.
- `git diff --check` passed.

## Tests Of The Tests

The formal artifact audit exercised the same writer and dispatcher path that
the focused tests cover at small replicate count. The audit also checked that
non-interval rows stayed unavailable: the derived same-response correlation,
the two slope SDs, and residual `rho12` had zero finite Wald endpoints.

## Consistency Audit

The result does not support promoting same-response q2 `mu`/`sigma` slope
covariance into a power grid. The fitted route remains available as a first
slice with smoke/recovery artifacts, but the formal audit is diagnostic because
convergence/positive-Hessian rates were 0.856 and 0.884 and fixed-effect Wald
coverage was below the nominal 0.95 target.

## GitHub Issue Maintenance

Issue #491 should stay open. The audit resolves the "run the formal artifact"
step but leaves a follow-up decision: improve convergence/interval evidence or
keep this route as a diagnostic neighbour rather than power-ready evidence. A
follow-up comment records the audit result and hold decision:
<https://github.com/itchyshin/drmTMB/issues/491#issuecomment-4638089487>.

## What Did Not Go Smoothly

The first run command intended to write under `/tmp`, but the shell variable
was not exported, so the runner used its default output path under
`inst/sim/results/actions/`. That directory is ignored by the local
`inst/sim/results/.gitignore`, so the source patch stayed clean.

## Team Learning

For future local formal audits, pass `--output-dir` as a literal path or export
the shell variable before invoking `Rscript`. Treat `status = "ok"` manifests
as necessary but not sufficient: convergence, positive-Hessian status,
warnings, and interval availability need their own table audit before
promotion.

## Known Limitations

This was a local formal audit, not a pushed GitHub Actions artifact. It used the
default two-cell recovery grid only. It did not add profile or bootstrap
intervals for the slope SDs, residual `rho12`, or the derived same-response
correlation.

## Next Actions

Keep same-response q2 power claims gated. The next useful slice is an
interval/convergence hardening pass: inspect the warning replicates, test
whether stronger starts or optimizer controls reduce non-positive-Hessian fits,
and add profile or bootstrap evidence before considering power-grid admission.
