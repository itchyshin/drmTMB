# Q-Series phylo count intercept recovery smoke widget

## 1. Goal

Bank local recovery-smoke evidence for the exact phylo Poisson/NB2 q1
structured `mu` intercept rows and surface that evidence in mission control
without promoting non-Gaussian intervals, coverage, `inference_ready`,
`supported`, REML, AI-REML, bridge, q2/q4 covariance, or public support claims.

The exact cells are:

- `qseries_phylo_poisson_q1_mu_intercept`
- `qseries_phylo_nbinom2_q1_mu_intercept`

## 2. Implemented

Ran the existing Phase 18 formal phylo q1 Actions tasks locally with one
replicate per condition and shard 7 for each formal grid. Shard 7 was selected
after a first dry-run/rerun showed that shard 1 used boundary-zero
`sd_phylo = 0` conditions; shard 7 gives four nonzero-SD conditions
(`sd_phylo = 0.25`) for each family.

The run banked artifacts under
`docs/dev-log/simulation-artifacts/2026-06-28-phylo-count-intercept-recovery-smoke-local/`.
Added
`docs/dev-log/dashboard/structured-re-phylo-count-intercept-recovery-smoke-status.tsv`,
a two-row sidecar that links each exact phylo count q1 intercept support cell
to its formal-runner artifact subset. The widget now includes those rows in
the existing `non_gaussian_intercept_recovery_smoke` state, so the `NG
intercept smoke` card covers eight rows total: six spatial/animal/relmat rows
from the earlier sidecar plus these two phylo rows.

Updated the mission-control validator to parse the new sidecar, verify exact
row membership, cross-check support-cell metadata, read the generated formal
spec, manifest, failure, replicate, and interval-evidence CSVs, and compare
every sidecar count against the artifact rows.

## 3a. Decisions and Rejected Alternatives

I did not include the `phylo_interaction()` count rows. Those are distinct
formula cells and still need their own evidence route.

I did not reuse the spatial/animal/relmat `count_structured_q1` sidecar
because the phylo rows come from different formal runners and artifact table
schemas.

I did not count the first shard-1 run as recovery smoke because it tested
`sd_phylo = 0` boundary cases. It remains overwritten by the shard-7 artifact
set, which is the evidence recorded in the sidecar.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-phylo-count-intercept-recovery-smoke-status.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-28-phylo-count-intercept-recovery-smoke-local/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-q-series-phylo-count-intercept-recovery-smoke-widget.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file inst/sim/run/sim_run_actions_cell.R --task poisson_phylo_q1_formal --output-dir docs/dev-log/simulation-artifacts/2026-06-28-phylo-count-intercept-recovery-smoke-local/poisson --n-reps 1 --master-seed 20260628 --cores 1 --backend none --condition-shard 1 --condition-shards 54 --dry-run true`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file inst/sim/run/sim_run_actions_cell.R --task nbinom2_phylo_q1_formal --output-dir docs/dev-log/simulation-artifacts/2026-06-28-phylo-count-intercept-recovery-smoke-local/nbinom2 --n-reps 1 --master-seed 20260628 --cores 1 --backend none --condition-shard 1 --condition-shards 72 --dry-run true`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file inst/sim/run/sim_run_actions_cell.R --task poisson_phylo_q1_formal --output-dir docs/dev-log/simulation-artifacts/2026-06-28-phylo-count-intercept-recovery-smoke-local/poisson --n-reps 1 --master-seed 20260628 --cores 1 --backend none --condition-shard 7 --condition-shards 54 --overwrite true`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file inst/sim/run/sim_run_actions_cell.R --task nbinom2_phylo_q1_formal --output-dir docs/dev-log/simulation-artifacts/2026-06-28-phylo-count-intercept-recovery-smoke-local/nbinom2 --n-reps 1 --master-seed 20260628 --cores 1 --backend none --condition-shard 7 --condition-shards 72 --overwrite true`: passed.
- Artifact audit: Poisson formal shard 7/54 has four nonzero-SD condition-replicates, zero failures, and 4/4 phylo SD rows with converged fits, `pdHess = TRUE`, and finite estimates.
- Artifact audit: NB2 formal shard 7/72 has four nonzero-SD condition-replicates, zero failures, and 4/4 phylo SD rows with converged fits, `pdHess = TRUE`, and finite estimates.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "phase18-(poisson|nbinom2)-phylo-q1|phase18-actions-runner")'`: passed with 449 passed expectations.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `sed -n '/<script>/,/<\\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -`: passed.
- `python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 2 structured RE phylo count-intercept recovery-smoke rows.

## 6. Tests of the Tests

The validator now fails if the sidecar loses either phylo family row, links to
the wrong support-cell metadata, points at the wrong formal-runner artifact
directory, disagrees with manifest/failure/replicate counts, uses a boundary
`sd_phylo = 0` shard, promotes a row, or loses claim-boundary language for
intervals, coverage, REML, AI-REML, `supported`, and public support.

The focused tests exercise both formal phylo q1 runners and the Actions wrapper
dispatch path used to generate the artifacts.

## 7a. Issue Ledger

- `qseries_phylo_poisson_q1_mu_intercept`: local recovery smoke passed; replicated recovery grid still required.
- `qseries_phylo_nbinom2_q1_mu_intercept`: local recovery smoke passed; replicated recovery grid still required.

No GitHub issue was opened. This is a PR #685 dashboard/status tranche.

## 8. Consistency Audit

Checked the support-cell TSV, non-Gaussian status audit, count intercept smoke
sidecar, new phylo count intercept smoke sidecar, widget overlay ordering,
dashboard README, check-log, validator, and generated artifacts. The two linked
support-cell rows remain at `fit_status = point_fit`,
`interval_status = unsupported`, and `coverage_status = planned`.

This tranche does not alter formula grammar, likelihood parameterization,
examples, pkgdown navigation, README, ROADMAP, NEWS, or known limitations
because it records evidence and dashboard state only.

## 9. What Did Not Go Smoothly

The first natural shard choice (`condition_shard = 1`) exercised boundary-zero
`sd_phylo = 0` conditions. I stopped before surfacing that as recovery smoke,
inspected the formal-grid sharding, and reran shard 7 so the recorded artifact
has nonzero true phylo SDs.

## 10. Known Residuals

The `phylo_interaction()` count rows remain point-only and need their own exact
evidence route. The two rows in this tranche still need replicated recovery
grids with MCSE and boundary ledgers before any recovery claim.

Non-Gaussian intervals and coverage remain unsupported. This tranche does not
address q2/q4 count covariance, count scale-side routes, zero-inflated
structured effects, REML, AI-REML, bridge support, `supported`, or public
support.

## 11. Team Learning

Small formal-grid smokes should inspect the selected condition shard before
claiming recovery signal. A clean fit on a boundary-zero shard is useful, but
it is a different evidence type from nonzero-variance recovery smoke.
