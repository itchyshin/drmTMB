# After Task: meta_V B3 retained-evidence campaign

## 1. Goal

Run the separately approved B3 Gaussian known-`V` campaign only after an
authenticated two-cell Totoro smoke, reduce all retained attempts, and close
without an automatic capability claim or CRAN action.

## 2. Implemented

The frozen contract at source commit `001ac983` ran 96 deterministic Totoro
shards of 175 fits (16,800 attempts). The reducer authenticated the 96 shard
receipts, campaign receipt, 11 source hashes, and smoke artifact before writing
the retained summary. The full raw result and reduction directories are local
at `inst/sim/results/meta-v-b3-2026-07-23/`; the compact receipt and coverage
tables are versioned beside the smoke artifact.

## 3. Mathematical Contract

The exact fitted model is Gaussian ML
`bf(yi ~ x + meta_V(V = V), sigma ~ 1)`. Known sampling covariance is input
data; `sigma` is fitted residual heterogeneity. The primary rate is finite and
truth-covering Wald intervals over all 1,200 scheduled attempts, not coverage
conditional on finite intervals.

## 3a. Decisions and Rejected Alternatives

The 96-worker campaign stayed on Totoro because the authenticated smoke and
frozen policy selected it. Conditional-on-finite coverage summaries were
retained but rejected as promotion evidence because they omit the predeclared
degenerate interval rows.

## 4. Files Touched

Campaign provenance and compact reductions are under
`docs/dev-log/simulation-artifacts/2026-07-22-meta-v-b3-smoke/repeat-001ac983/`.
The raw 203 MB retained result and full 31 MB reduction are deliberately in the
ignored local simulation-results store, not Git history.

## 5. Checks Run

- Totoro smoke receipt: K=12/vector seed 4 retained the required `sigma`
  `[0, Inf]` interval; K=36/dense control had finite intervals for all targets.
- Campaign reducer: 96 receipts, 16,800 manifest rows, and 50,400 parameter
  rows; 50,400 fit results were `ok`, with zero convergence, Hessian, or fit
  errors.
- The reducer recorded 3,712 `degenerate_zero_infinite` intervals and 46,688
  finite intervals. Its failure ledger has zero rows.
- Full local `testthat::test_local()` census was launched with `NOT_CRAN=true`,
  `R_PROFILE_USER=/dev/null`, and `Rscript --no-init-file`; record its final
  failure/error count in the check log before handoff.
- Fisher and Rose independently found coherent 96-receipt provenance and an
  intact denominator, but both withhold promotion. The all-attempt `sigma`
  finite-and-covering rate ranges from 0.4117 to 0.8900, while the higher
  conditional-on-finite values cannot replace it.

## 6. Tests of the Tests

The B3 suite exercises distinct failure paths: a missing/incorrect approval
scope, a mismatched host label, absent receipt, altered completion count,
unavailable Totoro, excessive projected shard time, and transferred smoke
approval evidence. The failed first smoke and the failed first campaign launch
were retained rather than silently overwritten.

## 7a. Issue Ledger

Issue #59 remains the Phase 18 umbrella. No issue comment was posted because
this campaign changes no public status and needs no release-tracker action.

## 8. Consistency Audit

`rg -n "meta_V|meta_v|B3|known-V" README.md ROADMAP.md NEWS.md docs vignettes R tests`
found existing public language that calls the route implemented/tested but
tier-unregistered, with no interval or coverage claim. No reader-facing status,
formula grammar, NEWS, roadmap, or pkgdown wording changed: the campaign is
internal evidence and does not satisfy a promotion gate.

## 9. What Did Not Go Smoothly

The first smoke failed before fitting because its wrapper did not attach
`drmTMB`; the repair was source-hashed and re-approved. The first formal launch
then failed before fitting because a locally authored campaign receipt pointed
to a local smoke-artifact path. All 96 preflight logs are retained. The same
unchanged contract was then used to create the host-local receipt, after which
all formal fits completed.

## 10. Known Residuals

This campaign is only the stated Gaussian ML, `sigma ~ 1`, known-vector/dense
`V` grid. It found many degenerate `sigma` Wald intervals at lower-information
cells, so it cannot supply a coverage, inference, capability-tier, or public
performance claim. It does not change REML, non-Gaussian meta-analysis,
predictor-dependent `sigma`, formula grammar, CRAN status, or Julia support.

## 11. Team Learning

An approval receipt that includes a retained artifact path must be authored on,
or made portable to, the execution host. A hash can authenticate a file while
an inaccessible path still prevents a valid launch; preserve that failed-closed
state and make the next launch use a fresh result directory.

## 12. Cross-Product Coverage

This internal evidence lane does not alter the public R API, formula grammar,
likelihood, Rd files, pkgdown reader surface, Julia bridge, or CRAN state. It
does not cover REML, penalties, alternative engines, missing-data routes,
`sigma ~ x`, profile/bootstrap intervals, or non-Gaussian meta-analysis.

## Next Actions

Record the full-suite census, commit compact provenance and this report, write
a handoff, and keep `meta_V()` tier-unregistered. Do not promote any row
automatically.
