# After Task: Q-Series q1 Mu Nibi Substitute Smoke

## Goal

Run and import the exact Nibi `n=5` substitute-host smoke for the four Gaussian
low-q q1 `mu` intercept rows, under
`structured-re-q-series-smoke-substitution-contract.tsv`, without promoting any
support cell.

## Implemented

- Ran the smoke on Nibi host `l5.nibi.sharcnet` from campaign root
  `/project/def-snakagaw/snakagaw/drmtmb-qseries/20260630-q1-mu-nibi-smoke-77b634eda91b`.
- Installed the synced source snapshot into the run-local library before
  running `tools/run-structured-re-gaussian-lowq-mu-intercept-smoke.R`.
- Fetched the smoke artifacts into
  `docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-smoke-nibi/`.
- Added
  `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-nibi-smoke-results.tsv`
  as a validator-owned dashboard import with local artifact paths.
- Added a `Low-q mu Nibi n5` Q-Series widget card/table and linked the Nibi
  artifact from the four q1 `mu` intercept support rows.
- Extended the validator and focused conversion-contract test so this sidecar
  must stay exact substitute-host smoke evidence.

## Evidence

- Summary rows: 4/4 providers (`phylo`, `spatial`, `animal`, `relmat`).
- Replicate rows: 20 total, 5 per provider.
- Fit evidence: 5/5 fit, convergence, `pdHess`, `confint()`, usable finite
  Wald intervals, and zero warning replicates for each provider.
- Seed manifest: 20 rows with
  `source_substitution_contract =
  docs/dev-log/dashboard/structured-re-q-series-smoke-substitution-contract.tsv`
  and `source_substitution_contract_id =
  qseries_smoke_substitution_q1_mu_intercept`.
- Reproducibility artifacts include `sessionInfo.txt`, `git-sha.txt`, module
  list, exact command, install logs, and smoke stdout/stderr.

## Claim Boundary

This promotes exactly no Q-Series row under substitute-host `n=5` smoke with
all attempted rows retained and does not claim denominator evidence, interval
coverage, `inference_ready`, `supported`, sigma, matched `mu+sigma`, q2,
q4/q8, non-Gaussian, REML, AI-REML, bridge, or public support.

The four linked support cells remain `point_fit/planned/planned`. Fisher/Rose
review of this substitute-host artifact is still required before any
Nibi/Rorqual/DRAC denominator work.

## Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells and 4 Gaussian low-q q1 `mu` Nibi smoke-result
  rows.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'devtools::test(filter = "structured-re-conversion-contracts")'`: 8710 PASS /
  0 FAIL / 0 WARN / 0 SKIP.

## Known Limitations

- This is a smoke import, not coverage or denominator evidence.
- The artifact came from a synced source snapshot rather than a Git checkout on
  Nibi; metadata records the source SHA and exact command.
- No q1 `mu` slope, q1 `sigma`, matched `mu+sigma`, q2, q4/q8,
  non-Gaussian, REML, AI-REML, bridge, or public-support claim changes.

## Next Actions

Fisher/Rose should review the Nibi substitute-host artifact. If accepted, Ada
and Grace can decide whether to open a denominator-admission contract for the
exact four q1 `mu` intercept rows; until then, all Nibi/Rorqual/DRAC denominator
work stays blocked.
