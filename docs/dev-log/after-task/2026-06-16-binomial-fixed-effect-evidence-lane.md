# After Task: Binomial Fixed-Effect Evidence Lane

## Goal

Stage the first Phase 18 evidence and comparator lane for the native
`stats::binomial(link = "logit")` fixed-effect response family from #569/#585.

## Implemented

This branch adds a standalone `binomial_fixed_effect` Phase 18 task for the two
supported response encodings: 0/1 Bernoulli rows and
`cbind(success, failure)` binomial counts. It writes replicate, aggregate,
manifest, failure-ledger, Wald-interval, Wald-coverage, and `stats::glm()`
parity CSV artifacts. The lane is wired into the Actions matrix as a manual
task and into the structured workflow registry as a ready-grid family-surface
row.

## Mathematical Contract

The DGP is

```text
Y_i ~ Binomial(n_i, mu_i)
logit(mu_i) = beta_0 + beta_1 x_i
x_i ~ Normal(0, 1)
```

The binary encoding fixes `n_i = 1`. The `cbind` encoding samples integer
trial totals and stores successes and failures explicitly. The estimands are
only `mu:(Intercept)` and `mu:x` on the logit scale. There is no `sigma`,
`rho12`, shape, zero-inflation, random-effect, structured-effect, bivariate, or
Julia bridge claim.

## Files Changed

- `inst/sim/dgp/sim_dgp_binomial_fixed_effect.R`
- `inst/sim/run/sim_run_binomial_fixed_effect_smoke.R`
- `inst/sim/fit/sim_summarise_binomial_fixed_effect.R`
- `inst/sim/run/sim_summary_binomial_fixed_effect_smoke.R`
- `inst/sim/run/sim_write_binomial_fixed_effect_grid.R`
- `tests/testthat/test-phase18-binomial-fixed-effect.R`
- `inst/sim/run/sim_run_actions_cell.R`
- `.github/workflows/phase18-simulation-grid.yaml`
- `inst/sim/registry/phase18_structured_workflow_registry.csv`
- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `docs/design/175-phase-18-binomial-fixed-effect-artifacts.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/158-phase-19-comparator-matrix.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`

## Checks Run

```sh
air format inst/sim/dgp/sim_dgp_binomial_fixed_effect.R inst/sim/fit/sim_summarise_binomial_fixed_effect.R inst/sim/run/sim_run_binomial_fixed_effect_smoke.R inst/sim/run/sim_summary_binomial_fixed_effect_smoke.R inst/sim/run/sim_write_binomial_fixed_effect_grid.R inst/sim/run/sim_run_actions_cell.R inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-phase18-binomial-fixed-effect.R tests/testthat/test-phase18-actions-runner.R tests/testthat/test-phase18-structured-workflow-registry.R
python3 -m json.tool docs/dev-log/dashboard/status.json
python3 -m json.tool docs/dev-log/dashboard/sweep.json
python3 tools/validate-mission-control.py
Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-phase18-binomial-fixed-effect.R", reporter = "summary")'
Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-phase18-actions-runner.R", reporter = "summary")'
Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-phase18-structured-workflow-registry.R", reporter = "summary")'
Rscript --vanilla -e 'devtools::test()'
Rscript --vanilla -e 'devtools::check(error_on = "never", document = FALSE)'
Rscript --vanilla -e 'pkgdown::check_pkgdown()'
git diff --check
rg -n '^(<<<<<<<|=======|>>>>>>>)' . --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/after-task/**'
rg -n 'non-identified|nonidentified|impossible|flat/unbounded|Bayesian only reads back the prior|REML on scale|REML.*scale' README.md ROADMAP.md NEWS.md docs vignettes R tests --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/check-log.md'
```

Results:

- Focused binomial evidence tests passed.
- Focused Actions-runner and structured-workflow-registry tests passed.
- Mission-control validator passed with
  `19/68 banked_or_verified, 4 active, 17 matrix rows, 10 finish rows, 15 Julia gate rows, 9 Julia capability rows`.
- Tiny writer smoke wrote seven artifacts under
  `/private/tmp/drmtmb-binomial-fe-grid-smoke`: aggregate 4 rows, replicates 4,
  manifest 2, failures 0, Wald intervals 4, Wald coverage 4, and `glm` parity
  4.
- The tiny smoke's largest absolute `drmTMB` versus `stats::glm()` coefficient
  difference was `5.742073e-13`; largest standard-error difference was
  `4.357602e-09`; largest absolute `logLik` difference was `4.774847e-12`;
  largest absolute AIC/BIC difference was `9.549694e-12`.
- Full `devtools::test()` passed with `0` failures, `8` warnings, `5` skips,
  and `11174` passes. The warnings are from the existing log-sigma clamp test;
  the skips are existing Julia bridge or DRM.jl-support gates.
- `devtools::check(error_on = "never", document = FALSE)` finished with
  `0 errors | 0 warnings | 0 notes`.
- `pkgdown::check_pkgdown()` remains blocked by the Claude-owned penalty/MAP
  docs seam: `_pkgdown.yml` is missing the exported `drm_phylo_penalty` topic.
- `devtools::document()` was run, but it generated unrelated roxygen drift in
  `DESCRIPTION` and `man/*.Rd`; that drift was reverted because no roxygen
  surface changed in this slice.

## Tests Of The Tests

The new tests exercise both response encodings, compare `drmTMB` coefficients
and likelihood criteria against an independent `stats::glm()` fit, verify all
seven output artifacts, check overwrite protection, and reject malformed
encoding, trial-range, and output-directory inputs.

## Consistency Audit

The design note, Phase 18 programme, Phase 19 comparator matrix, dashboard
evidence row, Actions runner, workflow matrix, structured workflow registry,
and tests all describe the same fixed-effect binomial logit lane. The dashboard
continues to mark binomial interval calibration as partial rather than
verified, and the Julia bridge remains unsupported/planned. Stale-wording
scans found only existing Ayumi/REML context outside this binomial slice.

## GitHub Issue Maintenance

Draft PR #588 opened:
<https://github.com/itchyshin/drmTMB/pull/588>.

Issue-ledger comments posted:

- #59 Phase 18 simulation programme:
  <https://github.com/itchyshin/drmTMB/issues/59#issuecomment-4723306223>
- #60 comparator programme:
  <https://github.com/itchyshin/drmTMB/issues/60#issuecomment-4723306281>
- #491 local-R queue:
  <https://github.com/itchyshin/drmTMB/issues/491#issuecomment-4723306294>

## What Did Not Go Smoothly

The new design note first used number 172, which collided with the existing
phylo penalty design note. It was renumbered to 175 and references were
updated. A one-off smoke-reporting command initially selected `nrow` instead of
the manifest column `n_row`; the implementation was already writing the
artifacts, and the reporting command was corrected. Full package tests and
`R CMD check` are slow because this repo now carries many Phase 18 and Julia
bridge checks.

## Team Learning

Rose's duplicate-ledger-number check belongs before finalizing any design note.
Grace's reproducibility boundary also helped here: `devtools::document()` can
create unrelated generated drift, so run it, inspect it, and revert it when no
roxygen surface changed.

## Known Limitations

This branch does not add random-effect binomial models, structured binomial
models, bivariate or mixed-response binomial models, non-logit links, weights as
trial totals, a `bernoulli()` alias, `engine = "julia"` support, speed claims,
or calibrated interval claims. The Phase 18 lane can produce pilot artifacts,
but promotion language needs larger replicate counts with MCSE-backed coverage
and failure-rate summaries.

## Next Actions

Open a draft PR, post the issue-ledger comments with the PR URL, watch the
3-OS R-CMD-check matrix, and only then decide whether to mark the PR ready or
merge.
