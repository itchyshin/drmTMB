## 1. Goal

Define the first retained-denominator contract for the Gaussian low-q q1 `mu`
intercept rows after the reviewed Nibi `n=5` substitute smoke, without running a
denominator grid or promoting any Q-Series support cell.

## 2. Implemented

- Added `structured-re-gaussian-lowq-mu-intercept-retained-denominator-contract.tsv`
  with four direct-SD location-axis q1 `mu` intercept rows: phylo, spatial,
  animal, and relmat.
- The contract names the default location-axis direct-SD interval channel, the
  retained-denominator policy, SR150 pregrid size, MCSE threshold, one-sided miss
  reporting, host policy, required artifacts, stop rules, and blocked neighbours.
- The contract is explicitly review-ready only. It promotes no `interval_status`,
  `coverage_status`, `inference_ready`, `supported`, bridge, REML, AI-REML, or
  public-support claim.

## 3a. Decisions and Rejected Alternatives

- Used a new sidecar rather than rewriting the reviewed smoke result. The Nibi
  `n=5` result remains smoke evidence, not denominator evidence.
- Kept all four q1 `mu` providers together because the reviewed smoke row set is
  exactly the four q1 `mu` intercept support cells. No q1 sigma, matched
  `mu+sigma`, q2, q4/q8, or non-Gaussian row inherits this contract.
- Set SR150 as the first pregrid, with top-up required before any MCSE-based
  inference claim if MCSE remains above 0.01 or miss balance is unacceptable.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-retained-denominator-contract.tsv`
- `docs/dev-log/after-task/2026-06-30-q-series-q1-mu-retained-denominator-contract.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/check-log.md`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells and 4 q1 `mu` retained-denominator contract rows.
- Extracted the dashboard `<script>` to `/tmp/drmtmb-dashboard-script.js` and
  ran `node --check /tmp/drmtmb-dashboard-script.js`: passed.
- `git diff --check` on the touched dashboard, validator, and focused-test
  files: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 8917 PASS / 0 FAIL / 0 WARN /
  0 SKIP.

## 6. Tests of the Tests

The focused test and Python mission-control validator both check that the new
contract has exactly four rows, the expected schema, linked q1 `mu` cells, local
evidence links, `point_fit/planned/planned` support-cell status, retained
denominator language, no-promotion wording, MCSE and one-sided miss rules, and
blocked-neighbour wording.

## 7a. Issue Ledger

- Closed: q1 `mu` intercept rows now have a concrete retained-denominator design
  artifact after reviewed Nibi substitute smoke.
- Closed: Fisher, Rose, and Grace accepted the row-specific contract on
  2026-06-30 for the first SR150 retained-denominator pregrid.
- Still open: no SR150 DRAC denominator run has been dispatched or imported.
- No GitHub issue action was taken in this local status-contract update.

## 8. Consistency Audit

- Neighbouring smoke-contract, row-selection, Nibi-smoke, dashboard, validator,
  focused-test, and check-log surfaces were checked for the same q1 `mu` row set
  and claim boundary.
- The contract keeps the support cells at `point_fit/planned/planned`.

## 9. What Did Not Go Smoothly

The current Q-Series dashboard already has many sidecars and a large validator,
so the safest change was an additive contract with explicit wiring rather than
folding denominator policy into the existing smoke sidecar.

## 10. Known Residuals

- No SR150 denominator run has been started.
- `MCSE <= 0.01` is a top-up target before any inference claim, not an SR150
  pass claim.
- No row is `inference_ready` because this is a design contract, not coverage
  evidence.
- q1 sigma, matched `mu+sigma`, q2, q4/q8, non-Gaussian, REML, AI-REML, bridge,
  and public-support claims remain outside this contract.

## 11. Team Learning

After a substitute-host smoke is reviewed, the next durable artifact should be a
row-specific retained-denominator contract that names hosts, denominator
retention, MCSE, one-sided misses, artifacts, stop rules, and blocked
neighbours before compute is submitted.
