# After Task: Julia-via-R clean-main bridge audit

## Goal

Make the Julia-via-R bridge tests name their DRM.jl and Julia runtime evidence
sources explicitly, then verify the current R bridge test surface against the
clean merged DRM.jl main worktree.

## Implemented

The live Julia bridge tests now use `tests/testthat/helper-julia-bridge-path.R`
for DRM.jl checkout discovery. Specialized variables such as
`DRM_JL_XFAM_PATH`, `DRM_JL_XFAM_TIER2_PATH`, `DRM_JL_XSIGMA_PATH`,
`DRM_JL_RELMAT_PATH`, and `DRM_JL_PATH` are still honored, but they fall back to
`DRM_JL_PHYLO_PATH` only when an explicit specialized path is absent. The tests
no longer fall back to old local checkouts such as `DRM-integrate`,
`DRM-RELEASE`, `DRM-relmatext`, cross-family worktrees, or the saved dirty
DRM.jl checkout.

The helper also centralizes Julia home discovery for parent-process tests.
Child `callr` processes now read `DRM_JL_JULIA_HOME`, then `JULIA_HOME`, and
only set `JULIA_HOME` when one of those variables is present. This preserves
local opt-in evidence while avoiding a maintainer-local hardcoded Julia path in
portable live tests.

The Julia gate registry and capability-comparison generators were rerun. They
still write 15 Julia bridge gate rows and 9 Julia capability rows, so this slice
does not widen the bridge registry.

## Mathematical Contract

No likelihood, formula grammar, parameterization, estimator, or interval method
changed. This is a test-harness and evidence-source cleanup only. Native R/TMB,
direct DRM.jl, and Julia-via-R evidence remain separate lanes.

## Files Changed

- `tests/testthat/helper-julia-bridge-path.R`
- `tests/testthat/test-julia-missing.R`
- `tests/testthat/test-julia-slope-nongaussian.R`
- `tests/testthat/test-julia-tmb-parity.R`
- `tests/testthat/test-julia-phylo-count.R`
- `tests/testthat/test-julia-phylo-nongaussian.R`
- `tests/testthat/test-julia-inference.R`
- `tests/testthat/test-julia-sigma-phylo-reml.R`
- `tests/testthat/test-julia-phylo-q4-corpairs.R`
- `tests/testthat/test-julia-structured.R`
- `tests/testthat/test-xfam-bridge.R`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`

## Checks Run

```sh
git fetch origin --prune
git status --short --branch
git log -1 --format='%H %s'
git -C /Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main fetch origin --prune
git -C /Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main status --short --branch
git -C /Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main log -1 --format='%H %s'
git -C '/Users/z3437171/Dropbox/Github Local/DRM.jl' status --short --branch
air format tests/testthat/helper-julia-bridge-path.R tests/testthat/test-julia-missing.R tests/testthat/test-julia-slope-nongaussian.R tests/testthat/test-julia-tmb-parity.R tests/testthat/test-julia-phylo-count.R tests/testthat/test-julia-phylo-nongaussian.R tests/testthat/test-julia-inference.R tests/testthat/test-julia-sigma-phylo-reml.R tests/testthat/test-julia-phylo-q4-corpairs.R tests/testthat/test-julia-structured.R tests/testthat/test-xfam-bridge.R
DRM_JL_PHYLO_PATH=/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main JULIA_HOME=/Users/z3437171/.juliaup/bin /usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "julia-gate-vs-engine|julia-tmb-parity", reporter = "summary")'
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "julia-gate-vs-engine|julia-tmb-parity", reporter = "summary")'
DRM_JL_PHYLO_PATH=/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main JULIA_HOME=/Users/z3437171/.juliaup/bin /usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "julia", reporter = "summary")'
/usr/local/bin/Rscript --vanilla tools/write-julia-gate-registry.R
/usr/local/bin/Rscript --vanilla tools/write-julia-capability-comparison.R
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
git diff --check
rg -n 'JULIA_HOME = "/Users/z3437171/.juliaup/bin"|Sys\.setenv\(JULIA_HOME = "/Users|local_envvar\(c\(JULIA_HOME = "/Users|DRM-integrate|DRM-RELEASE|DRM-relmatext|DRM-crossfamily' tests/testthat docs/design/168-r-julia-finish-capability-matrix.md docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json || true
git diff -U0 | rg -n 'CRAN ready|CRAN-ready|release ready|release-ready|coverage claim|power claim|calibrated interval|AI-REML|Julia bridge parity|Julia-side algorithm|random effects in `rho12`|recovery accuracy|promote|promotion' || true
RSTUDIO_PANDOC=/opt/homebrew/bin /usr/local/bin/Rscript --vanilla -e 'pkgdown::check_pkgdown()'
tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8765/status.json | jq '{updated, metrics, drmTMB_repo: (.repos[] | select(.name=="drmTMB"))}'
curl -s http://127.0.0.1:8765/sweep.json | jq '{updated, active_work: .active_work[0].text}'
```

Result: the no-env focused test passed by skipping Route B and Route C because
no DRM.jl path was available, with the known Route A skip retained. The explicit
clean-main focused test passed with the known Route A skip. The broader
`devtools::test(filter = "julia")` pass against
`/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main` also passed with the
same known Route A skip. Dashboard JSON parsing, mission-control validation,
`git diff --check`, and `pkgdown::check_pkgdown()` passed. Mission control
served `2026-06-19 17:12 MDT` with 25/68 banked_or_verified, 1 active, 0
blocked, and 1 deferred.

## Tests Of The Tests

The no-env focused test is the failure-path guard for this slice: without
`DRM_JL_PHYLO_PATH`, the live Route B and Route C parity checks skip because no
DRM.jl engine path is available. Before this cleanup, those tests could find
stale local defaults and accidentally create evidence from an unrelated
checkout. The explicit-path focused and broad Julia runs then prove the same
tests still execute when a clean DRM.jl main worktree is intentionally supplied.

## Consistency Audit

The live test source scan found no maintainer-local hardcoded `JULIA_HOME`
defaults, no stale live DRM.jl checkout defaults, and no old `DRM-integrate`,
`DRM-RELEASE`, `DRM-relmatext`, or cross-family default paths in the touched
test and dashboard/matrix surfaces.

The claim-boundary scan found only negative or planned boundary wording in the
changed files. Matrix, worklist, dashboard, check-log, and this report all keep
the same boundary: the slice banks bridge-test hygiene and clean-main
Julia-via-R test evidence only.

## GitHub Issue Maintenance

No issue comment was posted during the local edit because the branch still needs
PR review and CI before public breadcrumbing. After PR CI, pkgdown/Pages, and
live Pages are green, post a `drmTMB#59` breadcrumb that includes the PR number,
merge SHA, R-CMD-check run, pkgdown/Pages run, and the same boundary wording.

## What Did Not Go Smoothly

The first cleanup removed stale DRM.jl checkout defaults but missed hardcoded
`JULIA_HOME = "/Users/z3437171/.juliaup/bin"` in live child processes. Grace's
review caught that portability risk before PR. The broader phrasing "full Julia
bridge sweep" was also too broad; the docs now name the exact
`devtools::test(filter = "julia")` command and the known Route A skip.

## Team Learning

Bridge tests should require explicit evidence paths and explicit runtime
configuration. A clean no-env skip test should accompany every live bridge test
surface so stale local checkouts cannot silently become evidence.

## Known Limitations

This does not promote any bridge registry row. It does not support plain
non-phylo binomial through `engine = "julia"`, Route A Gaussian phylo-mean
parity, q4/q8 bridge parity, speed claims, release readiness, CRAN readiness,
selectable Julia-side `engine_control`, non-Gaussian REML/AI-REML, recovery
accuracy, coverage, or power claims.

## Next Actions

Open the PR for this bridge-hygiene slice, wait for R-CMD-check, pkgdown/Pages,
live Pages, and mission-control verification, then post the `drmTMB#59`
breadcrumb. After that, choose the next row-specific bridge parity or q8/skew
native evidence slice from the finish plan rather than relaxing any Julia gate
globally.
