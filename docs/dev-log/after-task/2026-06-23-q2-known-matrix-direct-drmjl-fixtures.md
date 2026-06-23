# After Task: Q2 Known-Matrix Direct DRM.jl Fixtures

## 1. Goal

Bank direct DRM.jl q2 residual-correlation fixture evidence for structured
types beyond phylo without promoting R-via-Julia bridge support or q2 REML.

## 2. Implemented

DRM.jl now has `make_coevo_problem_from_precision()` and
`make_coevo_problem_from_covariance()` for known structured matrices. The q2
direct-export contract now records phylo residual-correlation evidence, animal
and relmat known-covariance direct evidence, and fixed-covariance spatial direct
evidence. The aggregate q2 acceptance gate remains blocked until spatial,
animal, and relmat R-via-Julia same-target routes and tolerances exist.

## 3a. Decisions and Rejected Alternatives

I treated spatial as fixed-covariance fixture evidence only. I did not call it a
range-estimating spatial route, and I did not change q2 REML, q4, or interval
coverage wording. I also left R-via-Julia non-phylo q2 routes planned rather
than trying to marshal them in this tranche.

## 4. Files Touched

- `DRM.jl`: `src/DRM.jl`, `src/coevolution_q.jl`, `src/bridge.jl`,
  `test/test_bridge_q2_direct_export.jl`.
- `drmTMB`: q2 dashboard ledgers, validator, structured-RE contract tests,
  bridge fixture generator, dashboard README/status/sweep/version/index, design
  matrix/narrative, check-log-adjacent after-task notes.

## 5. Checks Run

- `julia --project=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot test/test_bridge_q2_direct_export.jl`: 102/102 assertions passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts')"`: 664 assertions passed.
- `python3 tools/validate-mission-control.py`: passed.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`: passed.
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`: passed.
- `sh -n tools/start-mission-control.sh`: passed.
- `git diff --check`: clean in both active worktrees.
- Live dashboard fetches at `http://127.0.0.1:8765/` returned `version.txt`
  `r29`, valid `status.json`/`sweep.json`, and the updated q2 direct and
  acceptance TSV rows.

## 6. Tests of the Tests

The focused R contract test initially failed four assertions: old non-phylo
direct statuses, stale 66/66 Julia assertion count, and stale bridge wording.
Those failures confirmed the tests were guarding the row-contract change rather
than merely exercising code paths.

## 7a. Issue Ledger

No GitHub issue or Ayumi reply was touched. This remains local mission-control
and direct-DRM.jl evidence only.

## 8. Consistency Audit

I swept stale wording for direct q2 blockers with:

```sh
rg -n "unavailable non-phylo q2 direct|spatial/animal/relmat q2 direct fits remain unavailable|spatial/animal/relmat q2 direct and R-via-Julia|spatial/animal/relmat q2 direct routes|direct q2 fits remain unavailable|direct q2 fit support|direct q2 fits and q2-specific|direct q2 fits unavailable|no direct q2 fit" docs/dev-log/dashboard docs/design README.md tests tools inst/sim/R/sim_structured_re_bridge_fixtures.R
```

The final sweep returned no current source-truth hits.

## 9. What Did Not Go Smoothly

The first validator patch hit a sibling q2 branch, not the direct-export branch,
so the mission-control validator still rejected the new non-phylo direct rows.
The focused validator rerun exposed that immediately.

## 10. Known Residuals

SR130 remains blocked. Spatial is fixed-covariance direct evidence only, not a
range-estimating q2 spatial route. Animal and relmat have direct known-matrix
evidence only; R-via-Julia parity, precision-Q marshalling, pedigree/Ainv
marshalling, q2 REML, q4 promotion, and interval coverage remain unpromoted.

## 11. Team Learning

For q2 structured routes, separate three states in every ledger: direct
known-matrix evidence, R-via-Julia route availability, and aggregate acceptance.
Those are different gates, and collapsing them is how unsupported bridge claims
creep in.
