# After Task: Q-Series Tranche 97 q1 mu one-slope spatial DRAC dependency-install staging contract

## Goal

Bank the T97 review layer after the T96 missing-dependency proof without spending
new remote compute. The tranche decides the minimal dependency-install route
for the q1 `mu` one-slope spatial DRAC lane and keeps the next action honest.

## Implemented

- Added
  `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche97-spatial-drac-dependency-install-staging-contract.tsv`
  with 8 reviewed decision rows.
- Added
  `docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche97-spatial-drac-dependency-install-staging-contract/t97-dependency-install-staging-contract.txt`
  as the compact route-contract artifact.
- Appended SC437 member-board rows to
  `docs/dev-log/dashboard/member-discussions.tsv`.
- Updated Mission Control build `r291`, the q1 `mu` one-slope queue, the
  validator, the focused conversion-contract test, the dashboard README, the
  Q-Series completion map, and the check log.

## Mathematical Contract

No model was fitted in T97, so no mathematical inference contract changes. The
target identity remains exactly `sd_mu_intercept` and `sd_mu_x` for the spatial
q1 `mu` one-slope cell. T97 records only a dependency-install staging decision:
T98 must probe default/project libraries first, then install exactly `cli`,
`RcppEigen`, and `TMB` into `Rlib-tranche98` only if the host policy is
login-node safe.

## Files Changed

- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche97-spatial-drac-dependency-install-staging-contract.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche97-spatial-drac-dependency-install-staging-contract/t97-dependency-install-staging-contract.txt`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`

## Checks Run

- TSV width checks for the T97 sidecar, member discussions, and q1 `mu`
  one-slope queue passed.
- `node --check /tmp/drmtmb-mission-control-index-r291.js` passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`
  passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`
  passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py` passed and reported 8 T97 rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'Sys.setenv(OMP_NUM_THREADS = "1", OPENBLAS_NUM_THREADS = "1",
  MKL_NUM_THREADS = "1"); devtools::test(filter =
  "structured-re-conversion-contracts", reporter = "summary")'` passed with
  `DONE`.
- The corrected support-cell invariant scan reported `104 96 8 0 0 0 0`.
- The served Mission Control copy at `http://127.0.0.1:8765/` reports build
  `r291`, includes the `Mu T97 dep contract` card, and serves the T97 sidecar
  with 9 lines including the header and 41 columns.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/codex-checkpoint.R
  --goal "Q-Series T97 q1 mu one-slope spatial DRAC dependency-install staging
  contract" --next "T98 no-model/no-sbatch dependency-install proof for cli
  TMB RcppEigen before any repeat Rorqual sbatch"` wrote
  `docs/dev-log/recovery-checkpoints/2026-07-02-221158-codex-checkpoint.md`.

## Tests Of The Tests

The focused conversion-contract test now reads the T97 sidecar, checks all 41
fields, requires the 8 expected decision IDs, verifies evidence links, checks
the no-fit/no-denominator/no-coverage boundaries, confirms the q1 `mu`
one-slope spatial support cell remains `point_fit/planned/planned`, and checks
that SC437 includes the blocking reviewers.

## Consistency Audit

Rose/Fisher/Grace boundaries are explicit in the sidecar, queue, member-board
rows, Mission Control, validator, focused tests, README, completion map, and
check log. T97 makes no public API, formula grammar, `R/`, `src/`, pkgdown,
README, NEWS, or support-cell status change. The prose pass used the
project-local `prose-style-review` checklist for the new report and dashboard
wording.

Searches used:

```sh
rg -n "Tranche 97|Tranche 98|dependency-install/staging|dependency-install proof" docs/dev-log/dashboard/README.md docs/design/218-structured-q-series-completion-map.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-03-q-series-tranche97-q1-mu-one-slope-spatial-drac-dependency-install-staging-contract.md tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R
rg -n "inference_ready|supported|coverage_authorized|REML|AI-REML" docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche97-spatial-drac-dependency-install-staging-contract.tsv docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche97-spatial-drac-dependency-install-staging-contract/t97-dependency-install-staging-contract.txt
```

## GitHub Issue Maintenance

No issue action was taken. This tranche is an internal Q-Series dashboard and
validator checkpoint; it does not close or alter a user-facing issue.

## What Did Not Go Smoothly

The first local invariant scan used `family_class == "structured_re"` for the
96-cell count, but the support-cell table records `family_class` as `gaussian`
or `non_gaussian`. I reran the scan with `structure_provider != "ordinary"`,
which produced the expected `104 96 8 0 0 0 0`.

## Team Learning

For dependency-heavy DRAC work, the next proof should explicitly separate
library probing, package installation, package loading, and model execution.
T97 keeps those as separate gates so the team cannot accidentally convert a
route decision into a fit or coverage claim.

## Known Limitations

T97 proves no package install, no package load, no model fit, no `pdHess`, no
Wald interval, no profile interval, no retained denominator, and no coverage.
The q1 `mu` one-slope spatial support cell remains `point_fit/planned/planned`.

## Next Actions

Checkpoint before any repeat compute. T98 may only be a no-model/no-sbatch
dependency-install proof: probe default/project libraries and modules for
`cli`, `TMB`, and `RcppEigen`; if absent and host policy is safe, install only
`cli`, `RcppEigen`, and `TMB` into `Rlib-tranche98`, then run `R CMD INSTALL
drmTMB` and `library(drmTMB)` for the exact T83 DRAC source path. Stop and write
an allocation contract if compilation is not login-node safe.
