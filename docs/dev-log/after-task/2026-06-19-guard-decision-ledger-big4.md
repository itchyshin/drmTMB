# Guard Decision Ledger For Big 4 Re-Plan

## Task Goal

Convert the first fifteen `drmTMB#59` numerical-guard diagnostics into a
decision ledger for the next Big 4 finish-plan blocks. The reader is the
package contributor deciding what to run next and the project owner checking
that R/TMB, direct Julia, and Julia-via-R evidence do not collapse into one
claim.

## Files Changed

- `docs/design/176-numerical-guard-simulation-audit.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-19-guard-decision-ledger-big4.md`

## What Changed

The guard audit now has a decision ledger after the fifteenth diagnostic. It
classifies each current guard row as `promote_candidate` for diagnostic
reporting only, `needs_larger_grid`, `diagnostic_hold`, or
`blocked_by_method`, then names the next implementation blocks:
decision-ledger synchronization, a Student-t interval decision slice, one
scale/correlation sensitivity slice, and only then a reopened q8/q2/skew-normal
binomial or bridge-parity slice.

The finish worklist and R-Julia matrix now point to that ledger. The dashboard
active-work text now says the active work is decision-ledger synthesis rather
than another Student-t result artifact.

## Checks Run

```sh
git fetch origin --prune
git status --short --branch
git log -1 --format='%H %s'
gh run view 27820357294 --repo itchyshin/drmTMB --json status,conclusion,jobs,url,headSha,createdAt,updatedAt | jq '{status, conclusion, headSha, createdAt, updatedAt, url, jobs: [.jobs[] | {name, status, conclusion, startedAt, completedAt, url}]}'
gh run view 27821651619 --repo itchyshin/drmTMB --json status,conclusion,jobs,url,headSha,createdAt,updatedAt | jq '{status, conclusion, headSha, createdAt, updatedAt, url, jobs: [.jobs[] | {name, status, conclusion, startedAt, completedAt, url}]}'
curl -I -L https://itchyshin.github.io/drmTMB/
curl -I -L https://itchyshin.github.io/drmTMB/reference/check_drm.html
tools/start-mission-control.sh --background
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
git diff --check
git diff -U0 | rg -n 'CRAN ready|CRAN-ready|release ready|release-ready|coverage claim|power claim|calibrated interval|engine_control|AI-REML|Julia bridge parity|Julia-side algorithm|random effects in `rho12`|structured correlations|recovery accuracy|promote|promotion|REML' || true
rg -n "Decision Ledger After The First Fifteen Diagnostics|blocked_by_method|needs_larger_grid|diagnostic_hold|promote_candidate|Post-#633 Work Order|Current non-Ayumi checkpoint \\(2026-06-19\\)" docs/design/176-numerical-guard-simulation-audit.md docs/design/157-capability-completion-worklist.md docs/design/168-r-julia-finish-capability-matrix.md docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-19-guard-decision-ledger-big4.md
RSTUDIO_PANDOC=/opt/homebrew/bin /usr/local/bin/Rscript --vanilla -e "pkgdown::check_pkgdown()"
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter="julia-gate-vs-engine", reporter="summary")'
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter="julia-tmb-parity", reporter="summary")'
/usr/local/bin/Rscript --vanilla tools/write-julia-gate-registry.R && /usr/local/bin/Rscript --vanilla tools/write-julia-capability-comparison.R
/usr/local/bin/Rscript --vanilla -e 'devtools::test(reporter="summary")'
```

## Results

The #633 post-merge gates are closed: R-CMD-check run `27820357294` passed on
macOS, Ubuntu, and Windows for
`57ed2b1c92cacb0b63d6d37389b95863605da7b3`; pkgdown/Pages run `27821651619`
passed on the same SHA; live Pages returned HTTP 200 for `/` and
`/reference/check_drm.html` with `last-modified: Fri, 19 Jun 2026 11:07:08 GMT`;
and mission control validated at 25/68 banked_or_verified, 1 active, 0 blocked,
and 1 deferred. A #59 breadcrumb was posted at
https://github.com/itchyshin/drmTMB/issues/59#issuecomment-4750981826.

Both dashboard JSON files parsed cleanly, `tools/validate-mission-control.py`
passed, `git diff --check` passed, and `pkgdown::check_pkgdown()` found no
problems. The added-line claim scan found only negative or cautionary boundary
wording. `devtools::test(filter = "julia-gate-vs-engine")` passed.
`devtools::test(filter = "julia-tmb-parity")` passed with one intentional skip
for the tracked Route A Gaussian phylo-mean all-node log-likelihood bug.
Regenerating the Julia gate and capability tables rewrote 15 gate rows and 9
capability rows with no resulting file diff.

Full `devtools::test()` completed successfully. It covered the Phase 18
simulation infrastructure, q8 endpoint/staged diagnostics, Student-t shape
runner tests, and JuliaCall bridge tests. The final summary reported five
skips: sigma-phylo REML via `engine = "julia"` skipped because the local DRM.jl
engine path predates that support, Route A Gaussian phylo-mean parity skipped
for the tracked all-node log-likelihood bug, and three cross-family bridge
skips where the external DRM.jl checkout does not yet accept `Xsigma1` and
`Xsigma2` keywords. The warnings were expected diagnostic warnings from clamp,
convergence, missing-predictor, profile/bootstrap, reference-grid, Tweedie, and
zero-inflated NB2 tests.

## Consistency Audit

The change is documentation and dashboard state only. It does not change code,
likelihood parameterization, formula grammar, package exports, or examples. It
keeps Student-t profile/bootstrap, q2 or structured covariance, q8, Julia
bridge, release readiness, CRAN readiness, and non-Gaussian REML/AI-REML
language unpromoted.

Direct `DRM.jl` verification is not locally testable from this `drmTMB`
worktree because it does not vendor the Julia package or contain a Julia
project. Direct Julia evidence must come from a DRM.jl checkout; this slice
verifies native R/TMB and R-side Julia bridge gates only.

## Tests Of The Tests

The validation pass parsed both dashboard JSON files, ran
`tools/validate-mission-control.py`, ran `git diff --check`, ran
`pkgdown::check_pkgdown()`, and scanned the added lines for forbidden promotion
wording. Full `devtools::test()` also exercised the native R/TMB and
Julia-via-R bridge surfaces. No statistical artifact runner was added in this
slice, so no simulation rerun was needed to validate the edit.

## GitHub Issue Maintenance

The post-#633 evidence breadcrumb was posted to `drmTMB#59` before this ledger
edit. The decision-ledger breadcrumb was posted to `drmTMB#59` after the final
local validation pass:
https://github.com/itchyshin/drmTMB/issues/59#issuecomment-4751313278.

## Known Limitations

This slice does not run direct DRM.jl tests. It records the boundary that direct
Julia evidence must come from a DRM.jl checkout. It also does not change
likelihoods, formula grammar, profile budgets, bootstrap refit budgets, q8
diagnostics, or bridge gates.

## Next Actions

1. Post a `drmTMB#59` breadcrumb for this decision ledger.
2. Start the Student-t interval decision slice, with Fisher reviewing profile
   target construction before any larger profile run.
3. Then run one scale/correlation sensitivity slice, with fixed-effect
   bivariate `sigma1`/`sigma2` clamp sensitivity as the strongest next
   candidate.

## What Did Not Go Smoothly

The post-#633 gate was still waiting on Windows at takeover. The gate later
passed cleanly, and the same-SHA pkgdown/Pages run also passed before this
decision-ledger slice began.

## Team Learning And Next Actions

Fisher should review the Student-t rows before any interval promotion language.
Grace should keep native R/TMB, direct Julia, and Julia-via-R bridge evidence
separate. Ada should sequence the next work as one Student-t interval decision
slice followed by one scale/correlation sensitivity slice.
