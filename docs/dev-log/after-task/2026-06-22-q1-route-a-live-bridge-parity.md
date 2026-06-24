# q1 Route A Live Bridge Parity

## Task Goal

Retire the stale q1 Gaussian mean-phylo Route A all-node bridge blocker by
adding a deterministic ML parity gate across native R/TMB, direct DRM.jl bridge
output, and the reconstructed `engine = "julia"` drmTMB object.

## Files Created Or Changed

- `R/julia-bridge.R`: added a route-specific tight tolerance for Gaussian
  mean-only phylo payloads.
- `tests/testthat/test-julia-tmb-parity.R`: replaced the skipped Route A row
  with a live three-route parity assertion.
- `docs/dev-log/dashboard/structured-re-q1-parity-fixture-contract.tsv`:
  marked the q1 mean-phylo parity fixture as experimental and covered by live
  evidence.
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`: replaced the
  stale Route A blocker evidence row with a live parity-test row.
- `docs/dev-log/dashboard/structured-re-balance-matrix.tsv`,
  `docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`, and
  `docs/dev-log/dashboard/structured-re-finish-100-slices.tsv`: moved only the
  q1 mean-phylo Route A evidence row from blocked/planned wording to banked
  experimental wording.
- `docs/dev-log/check-log.md`: recorded commands, outcomes, updated counts, and
  the claim boundary.

## Checks Run And Outcomes

```sh
git status --short --branch
git diff --check
```

Both active worktrees started with clean whitespace checks.

```sh
DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot Rscript --vanilla -e 'devtools::test(filter = "julia-tmb-parity")'
```

Passed: `test-julia-tmb-parity` reported 16/16 assertions, 0 failures, 0
warnings, and 0 skips in 53.3 seconds.

```sh
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
git diff --check
```

Passed. The validator reported 27 structured-RE matrix rows, 100
structured-RE balance rows, 100 structured-RE finish rows, 6 q1
parity-fixture rows, and 12 executable-evidence rows.

## Consistency Audit

The Route A row now has the same boundary in code comments, tests, dashboard
TSVs, and the check log: this is one q1 Gaussian mean-phylo ML parity fixture.
It is not a blanket q1 bridge claim.

## Tests Of The Tests

The first diagnostic reproduced the prior fixture with the old `g_tol = 1e-4`
and found small but non-gate-passing log-likelihood drift. Re-running the same
payload at `g_tol = 1e-8` reduced the native-vs-direct log-likelihood
difference to about `2.4e-9`. The final test checks convergence, finite
log-likelihoods, native-vs-direct log-likelihood parity, native-vs-reconstructed
log-likelihood parity, coefficient vector length, native-vs-direct coefficient
parity, native-vs-reconstructed coefficient parity, and direct-vs-reconstructed
coefficient identity.

## What Did Not Go Smoothly

The first direct-DRM assertion patch accidentally targeted Route C because the
non-phylo and phylo fit blocks looked similar. A debug pass showed the Route A
subprocess still returned the old six-field result. The direct-call assertions
were moved to the Route A helper and the focused test then passed.

## Team Learning And Process Improvements

Ada/Rose rule: when retiring a blocker, inspect the returned evidence shape, not
just the top-level pass/fail. Emmy/Grace rule: keep direct DRM.jl bridge output
and reconstructed R-via-Julia object checks side by side so bridge-object
reconstruction drift is visible.

## Design-Doc Updates

No design grammar or likelihood document changed. The dashboard ledgers carry
the status transition because this was a route-specific bridge evidence change,
not a formula-grammar or likelihood-parameterization change.

## pkgdown/Documentation Updates

No public README, vignette, reference, or pkgdown wording changed. Public bridge
support remains bounded by the existing status ledgers.

## GitHub Issue Maintenance

No GitHub issue was posted or edited in this local tranche. The Ayumi issue arc
remains parked until current issue text is reviewed and the exact final reply is
approved.

## Known Limitations And Next Actions

This banks only q1 Gaussian mean-phylo ML Route A parity. q1 sigma-phylo,
q1 mu+sigma, q2, q4, REML, interval coverage, non-Gaussian phylo, public
optimizer controls, and broad R-bridge support remain separate planned or
blocked rows. The next bridge actions are the q1 sigma-phylo and q1 mu+sigma
same-target fixtures, followed by q2 and q4 target-specific parity evidence.
