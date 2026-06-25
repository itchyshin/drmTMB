# After Task: Sigma Slope Coverage Runner Contract

## 1. Goal

Add a fail-closed dry-run runner contract for the sigma-only one-slope coverage
pre-grid targets so later Totoro or reviewed DRAC execution has selected target
manifests, shard-specific filenames, run logs, and a recovery boundary before
any compute job is submitted.

## 2. Implemented

The slice adds
`tools/plan-structured-re-sigma-slope-coverage-runner-contract.R`. The planner
reads `structured-re-sigma-slope-coverage-dispatch-review.tsv`, refuses modes
other than `--mode=dry-run`, and writes:

- `docs/dev-log/dashboard/structured-re-sigma-slope-coverage-runner-contract.tsv`;
- `docs/dev-log/simulation-artifacts/2026-06-25-sigma-slope-coverage-runner-contract/structured-re-sigma-slope-coverage-runner-target-manifest.tsv`;
- `docs/dev-log/simulation-artifacts/2026-06-25-sigma-slope-coverage-runner-contract/structured-re-sigma-slope-coverage-runner-run-log.tsv`;
- provider-filtered target manifests and run logs for `phylo`, `spatial`,
  `animal`, and `relmat`.

The all-target contract contains seven rows: `sigma:(Intercept)` for
`phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix
`relmat()`, plus `sigma:x` for `phylo()`, fixed-covariance `spatial()`, and
K-matrix `relmat()`. Animal `sigma:x` remains excluded as the visible holdout
from the first endpoint-profile smoke.

## 3a. Decisions and Rejected Alternatives

This is not a new likelihood, estimator, or interval method. It is a
manifest-level contract for existing sigma-only one-slope Gaussian structured
random-effect cells. Each selected row links back to the exact support cell,
direct SD target, endpoint-profile target, seed range 740001-740150, and
retention policy from the dispatch-review ledger.

Rejected alternatives:

- submitting a Totoro or DRAC job in this slice;
- treating SR150 as coverage-ready despite the MCSE threshold;
- adding animal `sigma:x` back into the executable target manifest before the
  profile-failure holdout is reconciled.

## 4. Files Touched

- `tools/plan-structured-re-sigma-slope-coverage-runner-contract.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-sigma-slope-coverage-runner-contract.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-sigma-slope-coverage-runner-contract/`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `Rscript --vanilla tools/plan-structured-re-sigma-slope-coverage-runner-contract.R`
  wrote seven runner-contract rows, the all-target manifest, the all-target run
  log, and provider-specific dry-run shard files.
- `Rscript --vanilla tools/plan-structured-re-sigma-slope-coverage-runner-contract.R --mode=execute`
  failed with `Only --mode=dry-run is supported by this runner-contract
  planner.`
- `air format tools/plan-structured-re-sigma-slope-coverage-runner-contract.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported seven
  structured RE sigma-slope coverage-runner contract rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with 4,463 assertions.
- `git diff --check` passed.
- The stale-wording scan found only explicit not-submitted, not-executed, or
  boundary language for sigma coverage, Totoro/DRAC, SR150, and support claims.

## 6. Tests of the Tests

The new test verifies that the runner rows match the dispatch-review rows, that
the all-target manifest equals the dashboard contract, that provider shard
manifests use shard-specific filenames, and that animal `sigma:x` remains
excluded. The mission-control validator repeats those checks outside testthat
and rejects executed, submitted, coverage-evaluable, REML, AI-REML, q4/q8, or
public-support wording.

## 7a. Issue Ledger

`gh issue list --repo itchyshin/drmTMB --search "sigma slope coverage runner contract q-series" --limit 20 --json number,title,state,url,labels`
returned no matching issues, so this slice did not update or open an issue.

## 8. Consistency Audit

Dashboard README and the q-series design map now describe the runner contract
as race-safety and recovery evidence only. They do not describe it as executed
coverage evidence.

## 9. What Did Not Go Smoothly

The first local generator run exposed an argument-parser bug: a missing
`--mode` flag produced `NA` instead of the intended `dry-run` default. The
planner now defaults to dry-run with no arguments and still refuses any
non-dry-run mode.

## 10. Known Residuals

No Totoro or DRAC jobs were submitted. No pre-grid cells were executed. No
coverage-evaluable denominator evidence, MCSE-calibrated coverage, interval
reliability, matched `mu+sigma` support, q4/q8 support, REML, AI-REML, broad
bridge support, public support, or SR150 readiness is promoted.

After stack review and explicit execution approval, run one provider shard on
Totoro or through reviewed DRAC submission, retain all fit/profile/bootstrap
and scheduler outcomes, and only then start denominator accounting.

## 11. Team Learning

Runner contracts should leave a rerunnable generator in `tools/`, not only
dashboard artifacts. The q4 runner-contract artifacts provided the pattern,
but this sigma slice makes the generator explicit so the next agent can
rebuild the sidecar before execution.
