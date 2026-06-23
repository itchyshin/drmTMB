# After Task: Q1 Relmat Mu ML Parity

## 1. Goal

Bank SR114 by turning the q1 Gaussian `relmat()` mean-side bridge row from a
finite structured smoke into row-specific ML parity evidence across native
R/TMB, direct DRM.jl, and R-via-Julia.

## 2. Implemented

Added a deterministic K-matrix `relmat(1 | id, K = K)` Gaussian fixture to the
Julia-vs-TMB parity test file. The fixture compares native R/TMB, direct
DRM.jl structured bridge output, and the reconstructed R-via-Julia fit on
convergence, log-likelihood, fixed coefficients, structured SD, coefficient
names, and reconstructed SD label.

The mission-control ledgers now mark SR114, `sr_relmat_q1_gaussian_mu`,
`q1_mu_relmat_gaussian_fixture`, `q1_gaussian_mu_relmat_ml`, and
`q1_relmat_mu_ml_live_parity_tests` as banked or covered experimental evidence
for that one K-matrix ML row.

## 3a. Decisions and Rejected Alternatives

I used a supplied covariance matrix `K` because the current bridge route
marshals `relmat(..., K = K)` into DRM.jl. I did not promote precision-matrix
`Q` marshalling, because the bridge intentionally rejects `relmat(..., Q = Q)`
until a separate payload contract exists.

I kept the acceptance contract at `logLik < 1e-6`, fixed effects `< 1e-5`, and
structured SD `< 1e-5`. I did not add interval, REML, sigma-side, q2, q4, or
non-Gaussian claims, because this fixture only checks one q1 Gaussian mean-side
ML target.

## 4. Files Touched

- `tests/testthat/test-julia-tmb-parity.R`
- `docs/dev-log/dashboard/bridge-parity-smoke-status.tsv`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/structured-re-balance-matrix.tsv`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/dashboard/structured-re-finish-100-slices.tsv`
- `docs/dev-log/dashboard/structured-re-julia-twin-sync.tsv`
- `docs/dev-log/dashboard/structured-re-q1-parity-fixture-contract.tsv`
- `docs/dev-log/dashboard/sweep.json`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/200-ayumi-julia-bridge-balance-readiness.md`
- `docs/design/216-structured-random-effect-finish-100-slices.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-22-q1-relmat-mu-ml-parity.md`

## 5. Checks Run

```sh
DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot \
  DRM_JL_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot \
  Rscript --vanilla -e "devtools::test(filter = 'julia-tmb-parity')"
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh -n tools/start-mission-control.sh
git diff --check
Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R \
  docs/dev-log/after-task/2026-06-22-q1-relmat-mu-ml-parity.md
```

Result: `julia-tmb-parity` passed with 45 assertions, 0 failures, 0 warnings,
and 0 skips in 88.9 seconds. `tools/validate-mission-control.py` passed with
9 bridge parity-smoke rows and 18 executable-evidence rows. `status.json` and
`sweep.json` parsed as JSON, `sh -n tools/start-mission-control.sh` passed,
`git diff --check` was clean in both active worktrees, and the after-task
report validator passed.

## 6. Tests of the Tests

Before adding the assertion, I ran the candidate fixture in a scratch R process
against the active DRM.jl pilot worktree. It showed native R/TMB, direct DRM.jl,
and R-via-Julia all converged and matched on log-likelihood, fixed
coefficients, and structured SD. The test would fail if the bridge returned a
non-converged fit, a direct/R-via-Julia target mismatch, missing `resd_id`, a
missing `relmat(1 | id)` SD label, or deltas above the stated tolerances.

## 7a. Issue Ledger

No GitHub issue, comment, PR, commit, or Ayumi reply was created. SR114 is local
mission-control evidence only. The next local issue-equivalent row is SR115:
q1 animal Gaussian parity with an A-matrix fixture.

## 8. Consistency Audit

The adjacent ledgers now agree that relmat q1 `mu` ML parity is covered only as
an experimental K-matrix fixture. The balance matrix still keeps relmat
sigma-side, q2, q4, count, REML, intervals, and `Q` marshalling separate. The
Ayumi bridge note explicitly states that this relmat row is not a phylogenetic
Ayumi-result change.

## 9. What Did Not Go Smoothly

The main friction was choosing the correct comparison route. The existing
structured bridge had a Poisson relmat live smoke, but that was not enough for
SR114 because it did not compare native R/TMB against direct DRM.jl and
R-via-Julia on the Gaussian q1 mean-side target.

## 10. Known Residuals

This is one deterministic q1 Gaussian `relmat()` mean-side ML parity fixture.
It is not calibrated coverage, not interval reliability, not REML parity, not
precision-matrix bridge marshalling, not sigma-side relmat support, not q2/q4
bridge support, and not public broad structured-bridge support.

## 11. Team Learning

Emmy/Rose: finite bridge smoke should not be treated as parity; the row needs
the same native/direct/R-via-Julia evidence ladder as the phylo fixtures.
Grace: the validator can accept additional parity rows when schema and evidence
paths are complete. Fisher: structured-SD parity is a target in this row, not a
side note.
