# After-task: q1 sigma phylo/relmat rows to inference_ready

Meta: 2026-06-28 · Codex · branch `codex/qseries-sigma-inference-ready`;
base/consolidation head `77b3730fa563b022f04fff31e29907ba3f4f7e37`.

## 1. Goal

Move only the exact Gaussian q1 sigma one-slope `phylo()` and `relmat()` rows
toward `inference_ready`, using row-level evidence after the Q-Series v1
consolidation. The goal was not structured-RE `supported`, broad sigma support,
spatial/animal promotion, or a REML/AI-REML claim.

## 2. Implemented

- Ran the sigma top-up campaign on Nibi for the two intercept targets:
  `qseries_phylo_q1_sigma_one_slope` and
  `qseries_relmat_q1_sigma_one_slope`. SLURM job `16844251` completed array tasks
  1 and 6 with exit code 0 on node `c542`.
- Preserved the Nibi artifacts under
  `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/`,
  including raw replicate TSVs, summaries, logs, `sessionInfo`, `git-sha`,
  module lists, `sacct`, and `seff`.
- Added
  `docs/dev-log/dashboard/structured-re-sigma-slope-inference-evidence.tsv` as the
  row-level evidence table. It combines the Nibi SR1000 intercept top-up with the
  already banked SR475 sigma:x local grids.
- Promoted exactly two support cells in
  `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`:
  `qseries_phylo_q1_sigma_one_slope` and
  `qseries_relmat_q1_sigma_one_slope` now have `interval_status` and
  `coverage_status` set to `inference_ready`.
- Updated `tools/validate-mission-control.py` so the new evidence table is a
  first-class validator input and the two sigma rows are the only newly admitted
  structured `inference_ready` cells.
- Updated focused tests so the structured conversion/status contract now expects
  exactly four structured `inference_ready` cells total: the two q2 location rows
  from Q-Series v1 plus these two q1 sigma rows.
- Updated public/status prose in README, NEWS, ROADMAP, formula grammar, design
  doc 218, the v1 after-task report, and the 2026-06-28 handover so sigma is
  described as raw uncorrected log-SD Wald-z `inference_ready` with caveats.
- Hardened `tools/run-structured-re-sigma-slope-coverage-grid.R` so a loadable
  installed `drmTMB` namespace can run on the cluster even when the R-version
  built-field check is too strict for the project-library install.

## 3a. Decisions and Rejected Alternatives

Fisher and Rose accepted a narrow promotion only under the raw uncorrected
log-SD Wald-z channel. The location-axis bias+t default correction remains
location-axis only and does not apply to sigma. Profile evidence at g = 8 remains
diagnostic-only because the sigma:x profile finite rates were 0.7579 for phylo
and 0.8042 for relmat.

Rejected alternatives:

- Do not promote `supported`. The intercept targets have clear upper-tail miss
  asymmetry: phylo 56 upper misses vs 5 lower misses, and relmat 53 upper misses
  vs 5 lower misses.
- Do not promote spatial sigma, animal sigma, matched `mu+sigma`, q4/q8, count,
  non-Gaussian, relmat Q bridge, REML, or AI-REML by analogy.
- Do not use the sigma profile channel as the primary sign-off path at g = 8.
- Do not apply the q2 location-axis bias+t correction to sigma.

## 4. Files Touched

- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/after-task/2026-06-28-q-series-v1-consolidation.md`
- `docs/dev-log/after-task/2026-06-28-sigma-q1-inference-ready.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-sigma-slope-inference-evidence.tsv`
- `docs/dev-log/dashboard/structured-re-slope-coverage-results.tsv`
- `docs/dev-log/handover/2026-06-28-codex-handover.md`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/logs/sigtopup-16844251_1.out`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/logs/sigtopup-16844251_6.out`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/metadata/git-sha.txt`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/metadata/module-list-1.txt`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/metadata/module-list-6.txt`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/metadata/run-log-1.txt`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/metadata/run-log-6.txt`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/metadata/sessionInfo-1.txt`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/metadata/sessionInfo-6.txt`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/results/shard_1/01-phylo-sigma_intercept-replicates.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/results/shard_1/01-phylo-sigma_intercept-summary.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/results/shard_6/06-relmat-sigma_intercept-replicates.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/results/shard_6/06-relmat-sigma_intercept-summary.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/sacct-16844251.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/seff-16844251_1.txt`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/seff-16844251_6.txt`
- `docs/dev-log/simulation-artifacts/2026-06-28-sigma-slope-coverage-topup-nibi/sigma-row-evidence-summary.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/run-structured-re-sigma-slope-coverage-grid.R`
- `tools/slurm/sigma-slope-coverage-topup-nibi.sbatch`
- `tools/validate-mission-control.py`

## 5. Checks Run

- Nibi SLURM job `16844251`: tasks `16844251_1` and `16844251_6` completed with
  exit code 0. `sacct` recorded elapsed times of 00:13:55 and 00:13:43.
- Raw artifact line counts: each Nibi intercept replicate file has 1000 data rows
  plus header; each banked sigma:x replicate file has 475 data rows plus header;
  the new evidence table has four data rows plus header.
- `python3 tools/validate-mission-control.py`: `mission_control_ok`, including
  104 structured RE Q-Series cells and 4 structured RE sigma-slope
  inference-evidence rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'devtools::test(filter = "structured-re-conversion-contracts")'`: FAIL 0 /
  WARN 0 / SKIP 0 / PASS 6225.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'devtools::test()'`: FAIL 0 / WARN 17 / SKIP 43 / PASS 19604; duration
  492.9 s.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'devtools::check()'`: Status OK, 0 errors / 0 warnings / 0 notes; duration
  10m 39.7s.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'pkgdown::check_pkgdown()'`: no problems found.
- `git diff --check`: no whitespace errors.
- Forbidden-claim scan over the edited status surfaces: remaining hits are guard
  text or historical q2 handover context, not sigma `supported`, all-provider
  promotion, REML/AI-REML, or bias+t-for-sigma claims.

## 6. Tests of the Tests

The validator now reads the sigma evidence table and rejects a broad status drift:
it requires exactly four sigma evidence rows, exact linked support-cell IDs, Wald
MCSE <= 0.01, high finite-Wald fractions, resolvable source artifacts, and claim
boundaries that say Wald/raw sigma evidence rather than `supported` or bias+t.

The focused structured conversion contract test independently checks the support
cell table and the evidence table. It asserts the total structured
`inference_ready` set, the two promoted sigma cell IDs, Wald-primary/profile-
diagnostic wording, conservative sigma:x coverage, low sigma:x profile finite
rates, intercept upper-tail asymmetry, and explicit "not supported" wording.

No deliberate mutation was left in the tree. The tests are direct table-contract
guards, so a spatial/animal sigma promotion, `supported` relabel, removed caveat,
or broken evidence path would fail the validator or focused test before a PR.

## 7a. Issue Ledger

- Fixed a cluster install/load guard that was too strict for the Nibi project
  library. The runner now records `installed_namespace_loaded_version_unchecked`
  instead of failing before simulations when `requireNamespace("drmTMB")` works.
- Resolved the main Rose audit concern by syncing raw Nibi artifacts into the
  repository before claiming the evidence table.
- Converted the prior sigma SR475 slope grid from a non-promotion record into a
  superseded input for this row-level evidence table, without changing the spatial
  or animal sigma rows.
- Corrected stale handover text that still described sigma promotion as an
  unexecuted future/profile-channel choice.

## 8. Consistency Audit

The source of truth is still
`docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`. It now has
104 rows and exactly four structured `inference_ready` rows: q2 phylo/relmat
from the small-sample location-axis arc, plus q1 sigma phylo/relmat from this
raw-Wald sigma arc. No structured row is `supported`.

README, NEWS, ROADMAP, formula grammar, design doc 218, the v1 after-task report,
the 2026-06-28 handover, validator, and focused tests were checked against the
same boundary. The narrative now says the two q1 sigma rows are
`inference_ready`, while spatial q2, animal q2, spatial/animal sigma, matched
`mu+sigma`, q4/q8, count, non-Gaussian, relmat Q bridge, REML, and AI-REML remain
future arcs.

Fisher signed off on the narrow statistical claim with caveats. Rose signed off
on the status-table edit only after the raw artifact sync, validator guard, test
update, check-log entry, after-task report, and forbidden-claim scan were part of
the closeout path.

## 9. What Did Not Go Smoothly

FIIA was not reachable by name and Totoro denied SSH, so the campaign used Nibi
as the primary SLURM host. The first Nibi job failed fast because the runner's
R-version guard did not accept the otherwise loadable installed package. After
the guard was narrowed, job `16844251` completed the two intended shards.

The profile channel looked tempting from earlier g-sweep language, but the
g = 8 sigma:x finite rates were too low for a primary inference claim. Keeping
raw Wald-z as the sign-off channel avoided laundering a diagnostic profile result
into status language.

## 10. Known Residuals

- The sigma intercept rows are near-nominal but asymmetric: phylo Wald coverage
  is 0.9388 with 5 lower and 56 upper misses; relmat Wald coverage is 0.9416
  with 5 lower and 53 upper misses.
- The sigma:x rows are conservative under Wald-z: phylo coverage 0.9935 and
  relmat coverage 0.9957.
- The profile channel is diagnostic-only at g = 8 for sigma:x because finite
  rates are 0.7579 and 0.8042.
- `supported` would need a separate support-grade arc with g stress, near-boundary
  conditions, miss-balance control, and a skew-aware or otherwise sigma-specific
  interval plan.
- Spatial sigma, animal sigma, matched `mu+sigma`, q4/q8, count, non-Gaussian,
  relmat Q bridge, REML, and AI-REML remain unpromoted.

## 11. Team Learning

The sigma arc needed a different sign-off channel from q2. A status row can be
ready for inference under one explicit interval channel while another channel is
only diagnostic. Future promotion reports should name the channel, denominator,
one-sided misses, and non-claims in the first evidence table, then let Rose block
the table edit until raw artifacts are present locally.
