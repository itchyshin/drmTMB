# Q-Series Gaussian q1 mu one-slope smoke widget

## 1. Goal

Bank local smoke evidence for the four Gaussian q1 structured `mu`
one-slope provider rows and surface that evidence in mission control without
promoting any row to `inference_ready`, `supported`, REML, AI-REML, bridge, or
public support status.

The exact cells are:

- `qseries_phylo_q1_mu_one_slope`
- `qseries_spatial_q1_mu_one_slope`
- `qseries_animal_q1_mu_one_slope`
- `qseries_relmat_q1_mu_one_slope`

## 2. Implemented

Ran the four phase-18 local Actions tasks for `phylo_mu_slope`,
`spatial_mu_slope`, `animal_mu_slope`, and `relmat_mu_slope` with one
replicate per condition and two conditions per provider. The artifact audit
found zero failures and, for each provider, 10 summary rows with 10 converged
fits, 10 `pdHess`-true fits, and 10 finite estimates.

Added
`docs/dev-log/dashboard/structured-re-gaussian-mu-slope-smoke-status.tsv`, a
four-row evidence sidecar that records the artifact paths, smoke counts, row
state, non-promotion decision, claim boundary, and next gate for the exact
cells. The mission-control widget now shows these rows as
`gaussian_mu_slope_smoke_passed`, with a separate "Mu-slope smoke" summary
card. This overlay wins over the broader Gaussian low-q gate display state, but
the source support-cell TSV statuses remain unchanged.

Updated the mission-control validator to parse the smoke sidecar, verify exact
cell/provider/task membership, cross-check support-cell metadata, read the
manifest/failure/replicate CSV artifacts, compare artifact counts with the
sidecar counts, and require explicit no-promotion wording.

## 3a. Decisions and Rejected Alternatives

I treated this as a smoke-evidence tranche only. A one-replicate local run is
useful for confirming that the runner, extractor, artifact schema, and widget
join work, but it is not interval or coverage evidence.

I rejected promoting these rows to `inference_ready` because they still need a
replicated denominator grid with convergence, `pdHess`, finite interval
fraction, lower/upper misses, coverage, and MCSE.

I kept the location-axis bias correction out of the claim. These `mu` one-slope
smokes only show local fit/extractor viability; they do not validate an
interval channel.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-smoke-status.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-28-gaussian-mu-slope-smoke-local/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-q-series-gaussian-mu-slope-smoke-widget.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file inst/sim/run/sim_run_actions_cell.R --task phylo_mu_slope --output-dir docs/dev-log/simulation-artifacts/2026-06-28-gaussian-mu-slope-smoke-local/phylo --n-reps 1 --master-seed 20260628 --cores 1 --backend none --dry-run true`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file inst/sim/run/sim_run_actions_cell.R --task spatial_mu_slope --output-dir docs/dev-log/simulation-artifacts/2026-06-28-gaussian-mu-slope-smoke-local/spatial --n-reps 1 --master-seed 20260628 --cores 1 --backend none --dry-run true`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file inst/sim/run/sim_run_actions_cell.R --task phylo_mu_slope --output-dir docs/dev-log/simulation-artifacts/2026-06-28-gaussian-mu-slope-smoke-local/phylo --n-reps 1 --master-seed 20260628 --cores 1 --backend none --overwrite true`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file inst/sim/run/sim_run_actions_cell.R --task spatial_mu_slope --output-dir docs/dev-log/simulation-artifacts/2026-06-28-gaussian-mu-slope-smoke-local/spatial --n-reps 1 --master-seed 20260628 --cores 1 --backend none --overwrite true`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file inst/sim/run/sim_run_actions_cell.R --task animal_mu_slope --output-dir docs/dev-log/simulation-artifacts/2026-06-28-gaussian-mu-slope-smoke-local/animal --n-reps 1 --master-seed 20260628 --cores 1 --backend none --overwrite true`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file inst/sim/run/sim_run_actions_cell.R --task relmat_mu_slope --output-dir docs/dev-log/simulation-artifacts/2026-06-28-gaussian-mu-slope-smoke-local/relmat --n-reps 1 --master-seed 20260628 --cores 1 --backend none --overwrite true`: passed.
- Artifact audit across the four providers: 2 manifest rows per provider, 0 failures per provider, and 10/10 converged, `pdHess`, and finite-estimate rows per provider.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "phase18-(phylo|spatial|animal|relmat)-mu-slope|phase18-structured-dependence-wrapper-readiness")'`: passed with 200 passed expectations.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `sed -n '/<script>/,/<\\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -`: passed.
- `python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 4 structured RE Gaussian mu-slope smoke-status rows.
- `tools/start-mission-control.sh --background`: copied dashboard build `r72` to `/tmp/drm-dashboard`.
- `curl -fsS http://127.0.0.1:8765/version.txt`: returned `r72`.
- `curl -fsS http://127.0.0.1:8765/structured-re-gaussian-mu-slope-smoke-status.tsv | wc -l`: returned 5 lines, meaning header plus four smoke rows.
- System-Chrome Playwright smoke against `http://127.0.0.1:8765/`: verified build `r72`, the "Mu-slope smoke" summary card, all four cell IDs, the smoke-passed pill on the phylo row, the smoke counts, and preservation of 4 `inference_ready` rows only.

## 6. Tests of the Tests

The validator now fails if the smoke sidecar loses a provider, changes a
provider/task pairing, links to the wrong support-cell metadata, drops an
artifact directory, disagrees with the manifest/failure/replicate CSV counts,
changes the exact smoke status fields, promotes a row, or loses claim-boundary
language for `inference_ready`, `supported`, REML, AI-REML, and public support.

The targeted phase-18 tests exercise the source runners and wrapper readiness
for the four provider tasks. The local smoke artifacts then test the live path
from runner to artifact tables to validator to widget.

## 7a. Issue Ledger

- `qseries_phylo_q1_mu_one_slope`: local smoke passed; replicated interval and coverage denominator grid still required.
- `qseries_spatial_q1_mu_one_slope`: local smoke passed; replicated interval and coverage denominator grid still required.
- `qseries_animal_q1_mu_one_slope`: local smoke passed; replicated interval and coverage denominator grid still required.
- `qseries_relmat_q1_mu_one_slope`: local smoke passed; replicated interval and coverage denominator grid still required.

No GitHub issue was opened. This is a PR #685 dashboard/status tranche.

## 8. Consistency Audit

Checked the support-cell TSV, the Gaussian low-q sidecar, the new Gaussian
mu-slope smoke sidecar, widget overlay ordering, dashboard README, check-log,
validator, live dashboard build, and browser-rendered Q-Series board. The four
rows now have a more specific evidence state in the widget, while the source
support-cell rows remain at `fit_status = point_fit`,
`interval_status = planned`, and `coverage_status = planned`.

This tranche does not alter examples, formula grammar, likelihood
parameterization, pkgdown navigation, README, ROADMAP, NEWS, or known
limitations because it records evidence and dashboard state only.

## 9. What Did Not Go Smoothly

The first live curl was issued while `tools/start-mission-control.sh` was still
copying build `r72` into `/tmp/drm-dashboard`, so the server briefly returned
the previous `r71` build and missed the new sidecar. I reran the live checks
after the copy finished and confirmed `r72`, the 5-line sidecar, and the
browser-rendered smoke rows.

## 10. Known Residuals

These rows are not `inference_ready`. They still need replicated denominator
work with convergence, `pdHess`, finite interval fraction, one-sided misses,
coverage, MCSE, and Fisher/Rose review before any status-table promotion.

The tranche does not address sigma, q2 `supported`, q4, q8, non-Gaussian,
bridge, REML, AI-REML, or public support claims.

## 11. Team Learning

Smoke evidence is useful only when it is visibly fenced. The widget now has a
separate rung for local Gaussian `mu` one-slope smoke evidence, so the team can
see progress without letting a green-looking row drift into an inference claim.
