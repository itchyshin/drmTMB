# After Task: Q-Series q2 bias+t top-up runner contract

## 1. Goal

Make the spatial/animal q2 bias+t top-up campaign executable and visible in the
Q-Series evidence ledger without changing any support-cell tier.

## 2. Implemented

This promotes exactly no support cell under the `default_bias_t_location_wald`
interval channel with retained top-up denominators executed on Rorqual and does
not claim spatial q2, animal q2, correlation targets, q4/q8, REML, AI-REML,
bridge support, `supported`, or public support.

The implemented claim is: the four spatial/animal q2 `mu1:x` and `mu2:x` SD
endpoint top-up shards have an executable local/SLURM runner contract,
one-replicate current-source smoke, completed Rorqual SR525 top-up artifacts,
and a guarded SR1000 endpoint synthesis table.

## 3a. Decisions and Rejected Alternatives

The runner targets location-axis structured random-effect SD endpoints from the
bivariate Gaussian q2 slope cell:

- spatial `mu1:x`
- spatial `mu2:x`
- animal `mu1:x`
- animal `mu2:x`

Each interval is the current default small-sample location-axis correction:
Wald width with t degrees of freedom from the group count plus the
simulation-calibrated centre shift used by `confint()`. The smoke verifies
endpoint extraction and interval finiteness only. The Rorqual top-up adds 525
replicates per SD endpoint and combines with the existing SR475 sidecar into
SR1000 endpoint summaries. The endpoint summaries still do not include
correlation targets and cannot promote the linked rows until retained tail
balance, correlation, and row-level gates pass Fisher/Rose review.

Rejected alternatives:

- Do not promote spatial or animal q2 from the one-rep smoke.
- Do not reuse q2 SD-endpoint evidence for correlation targets.
- Do not run a broad q4/q8 or non-Gaussian campaign in this patch.
- Do not call the installed-namespace smoke authoritative after it revealed
  older-package argument routing; local smoke now uses current source.
- Do not call the first Rorqual shared-source retry authoritative after it
  exposed install races; only the isolated-source retries for shards 2 and 4 are
  used in the result table.

## 4. Files Touched

- `tools/run-structured-re-q2-bias-t-coverage-topup.R`
- `tools/slurm/q2-bias-t-topup-rorqual.sbatch`
- `docs/dev-log/dashboard/structured-re-q2-slope-bias-t-topup-runner-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q2-slope-bias-t-topup-results.tsv`
- `docs/dev-log/dashboard/structured-re-q2-slope-spatial-animal-admission-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/simulation-artifacts/2026-06-29-q2-bias-t-topup-current-source-smoke-local/`
- `docs/dev-log/simulation-artifacts/2026-06-29-q2-bias-t-topup-rorqual/`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q2-bias-t-topup-runner-contract.md`

## 5. Checks Run

```sh
/opt/homebrew/bin/air format tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'
git diff --check
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/version.txt
curl -fsS http://127.0.0.1:8765/structured-re-q2-slope-bias-t-topup-runner-contract.tsv
curl -fsS http://127.0.0.1:8765/structured-re-q2-slope-bias-t-topup-results.tsv
R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q2-bias-t-topup-runner-contract.md')"
```

Results: formatting passed; Python compilation passed; mission control passed
with 4 structured RE q2 slope bias+t top-up runner-contract rows and 4 top-up
result rows. The focused structured-RE conversion contract test passed with
6508 PASS / 0 FAIL / 0 WARN / 0 SKIP after the result table was added.
`git diff --check` passed. The dashboard refresh command reported that
`http://127.0.0.1:8765/` was already listening, `version.txt` served `r96`, the
top-up contract/results TSVs served with the expected headers and first rows,
and this after-task report passed the structure check.

## 6. Tests of the Tests

The validator checks the top-up contract schema, exact four-row endpoint set,
source runner path, smoke artifact path, linked support-cell planned/planned
status, non-`supported` authority status, one-row smoke summaries, planned seed
range, and claim-boundary phrases. It also checks the SR1000 result table,
exact Rorqual job IDs, archived failed first attempts, exact endpoint counts,
MCSEs, one-sided misses, linked planned/planned row status, and no-promotion
claim boundaries. The focused test mirrors those contracts and opens smoke and
result summary files from disk.

## 7a. Issue Ledger

No GitHub issue action was taken. This slice prepares and executes the next
compute gate, but it does not create a public support claim or close a
user-visible issue.

## 8. Consistency Audit

The q2 spatial and animal support cells remain `interval_status = planned` and
`coverage_status = planned`. The admission audit, README, check-log, validator,
and focused test now point to
`structured-re-q2-slope-bias-t-topup-results.tsv` for SR1000 endpoint evidence.
The result table records spatial `mu2:x` 47 upper versus 5 lower misses and
animal `mu2:x` 36 versus 10, and it keeps correlation targets, q4/q8, REML,
AI-REML, bridge support, `supported`, and public support outside the claim.

## 9. What Did Not Go Smoothly

The first installed-namespace local smoke failed the bias+t call with an
argument-routing error, which exposed that the installed package was older than
the current default correction. I removed that failed artifact and changed the
runner to prefer `devtools::load_all()` for local smoke while retaining
`--no-load-all` for installed/temp-install cluster execution. A second naming
issue came from sourcing helper functions from the older q2 runner; the new
runner now uses top-up-specific helper names. The first Rorqual array then
exposed a real shared-source install race: shard 4 failed package install while
returning status 0, and shard 2 loaded a namespace with a missing
`getParameterOrder` symbol. I fixed the runner to exit nonzero on load failure,
changed the wrapper to install from a per-task source copy in `$SLURM_TMPDIR`,
archived failed first attempts, and retried shards 2 and 4.

## 10. Known Residuals

The four top-up shards have now been run for 525 replicates and combined with
SR475 evidence. This still does not solve spatial `mu2:x` right-tail imbalance,
animal `mu2:x` tail imbalance, the animal/spatial row-level correlation gates,
q4/q8 stability, skew-aware intervals, REML research route, or public support.

## 11. Team Learning

Top-up runners should smoke against the current source tree before any cluster
dispatch when the change under test is a new package default. The contract TSV
also needs to sit next to the blocker audit, not only in a run directory, so the
Q-Series widget can show "tried but still planned" rows without turning smoke
evidence into a tier promotion.

Cluster arrays that temp-install an R package from source must not compile from
a shared mutable source tree. Use per-task source copies or preinstall once into
a run library, and make runner load failures exit nonzero even when a diagnostic
summary is written.

## 12. Next Actions

Get Fisher/Rose review on the SR1000 endpoint synthesis, then decide whether the
next q2 work is tail-shape diagnosis, correlation-target coverage, or the g=32
profile/Wald comparison. Do not edit spatial or animal q2 status before that
review.
