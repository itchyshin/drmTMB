# After Task: Q8 Staged-Start Mapper And Pilot

## Goal

Close the next q8 pre-simulation start-rescue slice without adding public start
syntax. The target reader is an R package contributor deciding whether q8 can
move from diagnostic artifacts toward broader simulation grids.

## Implemented

`drmTMB()` now delegates the prepared-spec MakeADFun and optimizer tail to the
private `drm_fit_spec()` helper. The public function still has no `start =`
argument; ordinary calls use the same cold starts and call the private override
hook with no override.

The private `drm_qgt2_staged_start_override()` helper maps a fitted q4 source
into a q8 target specification. It copies shared fixed effects by
distributional parameter and model-matrix column name. It copies q>2 endpoint
SD starts by a covariance-member key containing group, block, distributional
parameter, and coefficient. It refuses `copy_theta_re_cov = TRUE` because
packed q>2 correlations still need a tested pair-key and packed-theta
reconstruction helper.

## Mathematical Contract

The fitted q8 target is the ordinary bivariate Gaussian all-endpoint block:
`mu1`, `mu2`, `sigma1`, and `sigma2` each use `(1 + x | p | id)`, while
residual coscale `rho12` stays a within-observation residual correlation. The
staged mapper may initialize common fixed-effect coefficients and endpoint SDs.
It must not treat residual `rho12` as a group-level q8 correlation, and it must
not copy packed q8 correlation parameters by raw position.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-optimizer-contract.R`
- `docs/design/163-phase-18-q8-hessian-start-rescue.md`
- `docs/design/165-phase-18-q8-start-hook-preflight.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `inst/sim/README.md`
- `ROADMAP.md`
- `docs/dev-log/simulation-artifacts/2026-06-08-q8-staged-start-pilot/`

## Checks Run

```sh
air format R/drmTMB.R tests/testthat/test-optimizer-contract.R
Rscript --vanilla -e 'devtools::test(filter = "optimizer-contract", reporter = "summary")'
Rscript --vanilla -e 'devtools::test(filter = "skew-normal-density-contract|skew-normal-location-scale|optimizer-contract|phase18-biv-gaussian-q8-endpoint", reporter = "summary")'
rg -n 'Q8 still has no start-hook implementation|Q8 still needs the q4/q6-to-q8 mapper|q4/q6-to-q8 mapper and paired cold-versus-staged diagnostic artifacts do not exist|next q8 task is the q4/q6-to-q8 mapping helper|q8 start/Hessian rescue|q8.*(coverage|power|interval).*(ready|passed|complete|supported)|q8.*positive-Hessian' NEWS.md ROADMAP.md README.md docs/design docs/dev-log/known-limitations.md inst/sim vignettes R tests --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/recovery-checkpoints/**' --glob '!docs/design/archive/**'
```

The focused optimizer-contract run passed before and after formatting. The
broader q8/skew-normal contract subset passed after the documentation pass.
The stale-wording scan returned only intended boundary rows: q8 coverage, power,
and interval readiness remain closed; the q8 start/Hessian wording now points
to the broader hard-row audit rather than a missing mapper.

## Tests Of The Tests

The new source tests build real q4 and q8 bivariate Gaussian specifications and
use a fake fitted q4 source so the test controls the fitted fixed effects and
endpoint SDs exactly. The tests verify column-name matching, member-key SD
matching, neutral `theta_re_cov` preservation, applied-count metadata, and the
error path for unvalidated packed-correlation copying.

## Consistency Audit

The q8 start-hook note, Hessian-rescue note, Phase 18 simulation programme,
ROADMAP, capability worklist, readiness matrix, known-limitations ledger, and
simulation README now agree on the same claim: the private mapper and first
paired pilot exist, but q8 remains diagnostic-only.

## GitHub Issue Maintenance

Updated issue #5 with the same boundary: q4-staged q8 improved one
low-replication row, but q8 coverage, power, and interval promotion remain
closed until broader hard-row staged-start audits pass.
<https://github.com/itchyshin/drmTMB/issues/5#issuecomment-4654290349>

## What Did Not Go Smoothly

The first member-key separator was a carriage return, which made the pilot CSV
hard to read. The key is now written as a visible string such as
`group=id;block=p;dpar=mu1;coef=(Intercept)`.

## Team Learning

The staged-start path should stay inside private prepared-spec tooling until a
public start contract is deliberately designed. For q>2 covariance blocks,
member-key SD inheritance is a safe first step; packed correlation inheritance
is a separate mathematical test.

## Known Limitations

The pilot is one low-replication condition, not a formal diagnostic grid. It
showed cold q8 convergence code 1 versus q4-staged q8 convergence code 0 on
`q8_diag_001` with seed `20260641`, but it did not test the broader hard rows
or any `se = TRUE` Hessian row. Q8 remains not interval-ready, not
coverage-ready, and not power-ready.

## Next Actions

Run a paired cold-versus-staged diagnostic audit across the hard q8 rows,
including the two `se = TRUE` Hessian probe rows. Keep `theta_re_cov` copying
closed until a pair-key and packed-theta reconstruction helper is source-tested.
