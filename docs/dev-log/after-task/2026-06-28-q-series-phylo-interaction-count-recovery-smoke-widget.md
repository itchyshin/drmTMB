# Q-Series phylo_interaction count recovery smoke widget

## 1. Goal

Bank local recovery-smoke evidence for the exact `phylo_interaction()` Poisson
and NB2 q1 structured `mu` rows and surface that evidence in mission control
without promoting non-Gaussian intervals, coverage, `inference_ready`,
`supported`, REML, AI-REML, bridge, q2/q4 covariance, additive partner-main,
structured-sigma, or public support claims.

The exact cells are:

- `qseries_phylo_interaction_poisson_q1_mu`
- `qseries_phylo_interaction_nbinom2_q1_mu`

## 2. Implemented

Added and ran a reproducible local smoke script under
`docs/dev-log/simulation-artifacts/2026-06-28-phylo-interaction-count-recovery-smoke-local/`.
The script fits Poisson and NB2 models with four replicate seeds, true pair SD
0.45, and the exact
`phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)`
formula in `mu`.

Added
`docs/dev-log/dashboard/structured-re-phylo-interaction-count-recovery-smoke-status.tsv`,
a two-row sidecar that links each exact pair-level count q1 support cell to
the smoke artifact. The widget now shows these two rows as
`non_gaussian_intercept_recovery_smoke`, so the `NG intercept smoke` card covers
ten rows total: six spatial/animal/relmat rows, two ordinary phylo rows, and
these two `phylo_interaction()` rows.

Updated the mission-control validator to parse the new sidecar, verify exact
row membership, cross-check support-cell metadata, read the generated manifest,
failure, aggregate, and replicate CSVs, and compare every sidecar count against
the artifact rows.

## 3a. Decisions and Rejected Alternatives

I did not treat `tests/testthat/test-phylo-interaction.R` as recovery evidence.
It is useful point-fit and extractor evidence, but it is not a durable
simulation artifact with manifest, failures, seeds, and aggregate counts.

I reused the existing `non_gaussian_intercept_recovery_smoke` display state
because the formula is still q1 `mu` intercept-only count structure. The
sidecar name and evidence text keep the pair-level `phylo_interaction()` route
separate from ordinary `phylo()`.

I did not update the support-cell TSV statuses. This is smoke evidence only;
the linked rows remain `fit_status = point_fit`, `interval_status =
unsupported`, and `coverage_status = planned`.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-28-phylo-interaction-count-recovery-smoke-local/`
- `docs/dev-log/dashboard/structured-re-phylo-interaction-count-recovery-smoke-status.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-q-series-phylo-interaction-count-recovery-smoke-widget.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file docs/dev-log/simulation-artifacts/2026-06-28-phylo-interaction-count-recovery-smoke-local/run-phylo-interaction-count-smoke.R docs/dev-log/simulation-artifacts/2026-06-28-phylo-interaction-count-recovery-smoke-local`: passed.
- Artifact audit: Poisson `phylo_interaction()` has four replicate seeds, zero failures, and 4/4 pair-level SD rows with converged fits, `pdHess = TRUE`, finite estimates, profile target ready, and no boundary warnings.
- Artifact audit: NB2 `phylo_interaction()` has four replicate seeds, zero failures, and 4/4 pair-level SD rows with converged fits, `pdHess = TRUE`, finite estimates, profile target ready, and no boundary warnings.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `sed -n '/<script>/,/<\\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -`: passed.
- `python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 2 structured RE phylo-interaction count recovery-smoke rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "phylo-interaction|structured-re-conversion-contracts")'`: passed with 6,280 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.
- `tools/start-mission-control.sh --background`: passed; dashboard already served at `http://127.0.0.1:8765/`.
- `curl -fsS http://127.0.0.1:8765/version.txt`: returned `r75`.
- `curl -fsS http://127.0.0.1:8765/structured-re-phylo-interaction-count-recovery-smoke-status.tsv | wc -l`: returned 3 lines, meaning one header plus two evidence rows.
- Browser-level Playwright check: passed for `#q-series-board`, `Q-Series Support Cells`, `NG intercept smoke = 10`, and both `qseries_phylo_interaction_poisson_q1_mu` and `qseries_phylo_interaction_nbinom2_q1_mu`.
- Effective dashboard-state recount: 104 total rows, 4 `inference_ready`, 10 `non_gaussian_intercept_recovery_smoke`, and 0 `non_gaussian_point_only` rows.

## 6. Tests of the Tests

The validator now fails if the sidecar loses either `phylo_interaction()`
family row, links to the wrong support-cell metadata, points at the wrong
artifact directory, lacks the run script/session/git/run-log artifacts,
disagrees with manifest/failure/aggregate/replicate counts, promotes a row, or
loses claim-boundary language for intervals, coverage, REML, AI-REML,
`supported`, and public support.

The existing `test-phylo-interaction.R` remains the focused point-fit/extractor
test. This tranche adds artifact validation around the same exact formula
shape.

## 7a. Issue Ledger

- `qseries_phylo_interaction_poisson_q1_mu`: local recovery smoke passed; replicated recovery grid still required.
- `qseries_phylo_interaction_nbinom2_q1_mu`: local recovery smoke passed; replicated recovery grid still required.

No GitHub issue was opened. This is a PR #685 dashboard/status tranche.

## 8. Consistency Audit

Checked the support-cell TSV, non-Gaussian status audit, new
`phylo_interaction()` count smoke sidecar, widget overlay ordering, dashboard
README, check-log, validator, and generated artifacts. The two linked
support-cell rows remain at `fit_status = point_fit`, `interval_status =
unsupported`, and `coverage_status = planned`.

This tranche does not alter formula grammar, likelihood parameterization,
examples, pkgdown navigation, README, ROADMAP, NEWS, or known limitations
because it records evidence and dashboard state only.

## 9. What Did Not Go Smoothly

The main design choice was whether to create a new display state. I kept the
existing count-intercept smoke state to avoid inventing a new tier, while the
sidecar and validator preserve the pair-level route boundary.

## 10. Known Residuals

The two rows in this tranche still need replicated recovery grids with MCSE and
boundary ledgers before any recovery claim.

Non-Gaussian intervals and coverage remain unsupported. This tranche does not
address q2/q4 count covariance, additive partner-main effects,
structured-sigma routes, zero-inflated structured effects, REML, AI-REML,
bridge support, `supported`, or public support.

## 11. Team Learning

Point-fit tests and recovery-smoke artifacts should stay separate. The tests
prove that the API/extractor path works; the artifact adds seeds, failures,
counts, and a dashboard contract that future reviewers can audit.
