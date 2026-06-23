# After Task: Q1 Animal Mu ML Parity

## 1. Goal

Bank SR115 by turning the q1 Gaussian `animal()` mean-side bridge row into
row-specific ML parity evidence across native R/TMB, direct DRM.jl, and
R-via-Julia.

## 2. Implemented

Added a deterministic A-matrix `animal(1 | id, A = A)` Gaussian fixture to the
Julia-vs-TMB parity test file. The fixture checks convergence, log-likelihood,
fixed coefficients, structured SD, direct bridge coefficient names, and the
R-via-Julia reconstructed `animal(1 | id)` SD label.

The mission-control ledgers now mark SR115, `sr_animal_q1_gaussian_mu`,
`q1_mu_animal_gaussian_fixture`, `q1_gaussian_mu_animal_ml`, and
`q1_animal_mu_ml_live_parity_tests` as banked or covered experimental evidence
for that one A-matrix ML row.

## 3a. Decisions and Rejected Alternatives

I used `animal(..., A = A)` because the current Julia bridge routes the
supplied relationship matrix to DRM.jl's `A` keyword. I did not promote
pedigree or `Ainv` bridge marshalling; those remain separate payload-design
work.

I reused the q1 known-matrix acceptance thresholds from SR114:
`logLik < 1e-6`, fixed effects `< 1e-5`, and structured SD `< 1e-5`. I did
not add REML, interval, sigma-side, q2, q4, or non-Gaussian support claims.

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
- `docs/dev-log/after-task/2026-06-22-q1-animal-mu-ml-parity.md`

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
  docs/dev-log/after-task/2026-06-22-q1-animal-mu-ml-parity.md
```

Result: `julia-tmb-parity` passed with 57 assertions, 0 failures, 0 warnings,
and 0 skips in 104.4 seconds. `tools/validate-mission-control.py` passed with
10 bridge parity-smoke rows and 19 executable-evidence rows. `status.json` and
`sweep.json` parsed as JSON, `sh -n tools/start-mission-control.sh` passed,
`git diff --check` was clean in both active worktrees, and the after-task
report validator passed.

## 6. Tests of the Tests

Before adding the assertion, I ran the candidate animal fixture in a scratch R
process against the active DRM.jl pilot worktree. It showed convergence and
agreement across native R/TMB, direct DRM.jl, and R-via-Julia. The new test
would fail on a missing `A` route, non-converged direct bridge, missing
`resd_id`, missing `animal(1 | id)` SD reconstruction, or deltas above the
stated tolerances.

## 7a. Issue Ledger

No GitHub issue, comment, PR, commit, or Ayumi reply was created. SR115 is
local mission-control evidence only. The next local row is SR116: q1 spatial
Gaussian parity with a coordinate fixture.

## 8. Consistency Audit

The adjacent ledgers now agree that animal q1 `mu` ML parity is covered only
as an experimental A-matrix fixture. The balance matrix still keeps pedigree,
`Ainv`, sigma-side, q2, q4, REML, intervals, and non-Gaussian rows separate.

## 9. What Did Not Go Smoothly

The route itself was straightforward once SR114 had established the
native/direct/R-via-Julia comparison pattern. The main risk was wording drift:
native drmTMB accepts richer animal inputs than the current bridge, so the
banked row had to say A-matrix explicitly.

## 10. Known Residuals

This is one deterministic q1 Gaussian `animal()` mean-side ML parity fixture.
It is not calibrated coverage, not interval reliability, not REML parity, not
pedigree or `Ainv` bridge marshalling, not sigma-side animal support, not q2/q4
bridge support, and not broad public structured-bridge support.

## 11. Team Learning

Boole/Emmy: use the syntax the bridge actually marshals in the row name and
claim boundary. Fisher: known-matrix SD parity is the minimum useful target for
these q1 bridge rows. Rose: sibling structured rows need the same evidence
ladder so "finite smoke" never masquerades as parity.
