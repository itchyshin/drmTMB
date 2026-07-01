# Q-Series count intercept recovery smoke widget

## 1. Goal

Bank local recovery-smoke evidence for the exact spatial, animal, and relmat
Poisson/NB2 q1 structured `mu` intercept rows and surface that evidence in
mission control without promoting non-Gaussian intervals, coverage,
`inference_ready`, `supported`, REML, AI-REML, bridge, q2/q4 covariance, or
public support claims.

The exact cells are:

- `qseries_spatial_poisson_q1_mu_intercept`
- `qseries_spatial_nbinom2_q1_mu_intercept`
- `qseries_animal_poisson_q1_mu_intercept`
- `qseries_animal_nbinom2_q1_mu_intercept`
- `qseries_relmat_poisson_q1_mu_intercept`
- `qseries_relmat_nbinom2_q1_mu_intercept`

## 2. Implemented

Ran the existing Phase 18 `count_structured_q1` Actions task locally with all
follow-up conditions, one replicate per condition, and no interval/profile
request. The run banked 24 condition-replicates, zero failures, and 96
replicate-summary rows under
`docs/dev-log/simulation-artifacts/2026-06-28-count-intercept-recovery-smoke-local/`.

Added
`docs/dev-log/dashboard/structured-re-count-intercept-recovery-smoke-status.tsv`,
a six-row sidecar that links each exact count q1 intercept support cell to the
artifact subset for its family/provider pair. The widget now shows these rows
as `non_gaussian_intercept_recovery_smoke` and adds an `NG intercept smoke`
summary card.

Updated the mission-control validator to parse the new sidecar, verify exact
row membership, cross-check support-cell metadata, read the generated manifest,
failure, replicate, and interval-evidence CSVs, and compare every sidecar count
against the artifact rows.

## 3a. Decisions and Rejected Alternatives

I did not use the count one-slope 80-rep recovery sidecar for these rows
because the intercept cells need exact structured-intercept formulas, not
neighbouring slope evidence.

I did not include the phylo count intercept rows. The `count_structured_q1`
runner covers spatial, animal, and relmat structured intercepts; phylo count
intercepts need their own exact evidence route.

I kept the spatial NB2 row in the smoke rung but marked it as
`local_recovery_smoke_boundary_warning` because 3/4 structured-SD rows had
lower-boundary warnings despite convergence, `pdHess = TRUE`, and finite
estimates.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-count-intercept-recovery-smoke-status.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-28-count-intercept-recovery-smoke-local/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-q-series-count-intercept-recovery-smoke-widget.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file inst/sim/run/sim_run_actions_cell.R --task count_structured_q1 --output-dir docs/dev-log/simulation-artifacts/2026-06-28-count-intercept-recovery-smoke-local --n-reps 1 --master-seed 20260628 --cores 1 --backend none --condition-set all --dry-run true`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file inst/sim/run/sim_run_actions_cell.R --task count_structured_q1 --output-dir docs/dev-log/simulation-artifacts/2026-06-28-count-intercept-recovery-smoke-local --n-reps 1 --master-seed 20260628 --cores 1 --backend none --condition-set all --overwrite true`: passed.
- Artifact audit: 24/24 manifest rows OK, 0 failures, 96 replicate-summary rows, and for each of the six linked family/provider subsets, 4/4 structured-SD rows converged, 4/4 had `pdHess = TRUE`, and 4/4 had finite estimates.
- Artifact caveat: spatial NB2 had 3/4 structured-SD rows with lower-boundary warnings.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "phase18-count-structured-q1|phase18-actions-runner")'`: passed with 490 passed expectations.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `sed -n '/<script>/,/<\\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -`: passed.
- `python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 6 structured RE count-intercept recovery-smoke rows.

## 6. Tests of the Tests

The validator now fails if the sidecar loses a family/provider pair, includes
phylo or any non-intercept row, links to the wrong support-cell metadata,
points at the wrong artifact directory, disagrees with manifest/failure/
replicate counts, drops the spatial NB2 boundary warning, promotes a row, or
loses claim-boundary language for intervals, coverage, REML, AI-REML,
`supported`, and public support.

The focused tests exercise both the `count_structured_q1` runner and the
Actions wrapper dispatch path used to generate the artifact.

## 7a. Issue Ledger

- `qseries_spatial_poisson_q1_mu_intercept`: local recovery smoke passed; replicated recovery grid still required.
- `qseries_spatial_nbinom2_q1_mu_intercept`: local recovery smoke with lower-boundary warnings; boundary diagnostics and replicated recovery grid still required.
- `qseries_animal_poisson_q1_mu_intercept`: local recovery smoke passed; replicated recovery grid still required.
- `qseries_animal_nbinom2_q1_mu_intercept`: local recovery smoke passed; replicated recovery grid still required.
- `qseries_relmat_poisson_q1_mu_intercept`: local recovery smoke passed; replicated recovery grid still required.
- `qseries_relmat_nbinom2_q1_mu_intercept`: local recovery smoke passed; replicated recovery grid still required.

No GitHub issue was opened. This is a PR #685 dashboard/status tranche.

## 8. Consistency Audit

Checked the support-cell TSV, non-Gaussian status audit, count one-slope
recovery sidecar, new count intercept smoke sidecar, widget overlay ordering,
dashboard README, check-log, validator, and generated artifacts. The six linked
support-cell rows remain at `fit_status = point_fit`,
`interval_status = unsupported`, and `coverage_status = planned`.

This tranche does not alter examples, formula grammar, likelihood
parameterization, pkgdown navigation, README, ROADMAP, NEWS, or known
limitations because it records evidence and dashboard state only.

## 9. What Did Not Go Smoothly

The useful snag was scientific rather than mechanical: spatial NB2 converged
and had `pdHess = TRUE`, but 3/4 structured-SD rows were near the lower
boundary. The sidecar records that row as a warning state instead of a clean
pass.

## 10. Known Residuals

The two phylo count intercept rows still do not have an exact recovery-smoke
sidecar. The six rows in this tranche still need replicated recovery grids with
MCSE and boundary ledgers before any recovery claim.

Non-Gaussian intervals and coverage remain unsupported. This tranche does not
address q2/q4 count covariance, count scale-side routes, zero-inflated
structured effects, REML, AI-REML, bridge support, `supported`, or public
support.

## 11. Team Learning

Do not flatten "converged" into "clean." The lower-boundary warning is exactly
the kind of stability signal the widget should keep visible before the team
spends cluster time on larger non-Gaussian grids.
