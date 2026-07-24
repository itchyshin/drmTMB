# After-task report — meta_V trust infrastructure and B3 gate

## 1. Goal

Make the Phase 18 known-`V` evidence path truthful at the `K = 12`,
`sigma = 0.10` interval boundary, without launching compute or making a
capability claim.

## 2. Implemented

The frozen 14-cell B3 design is now executable. Every scheduled fit receives
an accounting row; fit error, convergence/Hessian state, nonfinite estimates,
failed intervals, and `degenerate_zero_infinite` are retained. The primary
interval endpoint is the all-attempt finite-and-covering rate; finite-interval
rate and conditional finite-interval set coverage are separate. K=12 diagonal
and dense **ML** comparator fixtures use the matching `metafor` ML routes. The
reader article now provides a dense-`V` preflight and executable example.

## 3a. Decisions and Rejected Alternatives

Kept ML because the B3 packet freezes ML; REML small-K fixtures were replaced.
Kept `[0, Inf]` as a retained degenerate interval rather than reconstructing a
symmetric interval. Chose Totoro as the future primary host after approval;
DRAC is fallback. Rejected new API/likelihood work, promotion, CRAN work, and
campaign execution.

## 4. Files Touched

- `docs/design/48-phase-18-meta-v-ademp.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/2026-07-22-meta-v-b3-decision-packet.md`
- `docs/dev-log/2026-07-22-meta-v-b3-ultra-plan.md`
- `docs/dev-log/after-task/2026-07-22-meta-v-ademp-b3-reconciliation.md`
- `inst/sim/dgp/sim_dgp_meta_v.R`
- `inst/sim/fit/sim_summarise_meta_v.R`
- `inst/sim/run/sim_run_meta_v_smoke.R`
- `inst/sim/run/sim_summary_meta_v_smoke.R`
- `inst/sim/run/sim_write_meta_v_grid.R`
- `tests/testthat/test-comparators.R`
- `tests/testthat/test-phase18-meta-v-dgp.R`
- `tests/testthat/test-phase18-meta-v-grid-writer.R`
- `tests/testthat/test-phase18-meta-v-summary-smoke.R`
- `vignettes/meta-analysis.Rmd`, `vignettes/implementation-map.Rmd`,
  `vignettes/drmTMB.Rmd`, and `vignettes/source-map.Rmd`

## 5. Checks Run

- Focused Phase-18 meta_V tests: 123 passed, 0 failed/warned/skipped.
- Focused comparator tests: 134 passed, 0 failed/warned/skipped.
- Earlier combined meta_V/comparator/known-V run: 340 passed, 0 failed/warned/skipped; the subsequent output-name clarification is covered by the final 123-test meta_V rerun.
- `pkgdown::build_article("meta-analysis", new_process = FALSE)`: rendered; a local sass-cache permission warning did not affect output.
- `git diff --check`: PASS.
- Full uncapped `testthat::test_local(".", reporter = "silent")` was started with the required environment but stopped for elapsed-time control while executing a long q6 Phase 18 test. It returned no totals and is not a full-suite pass.

## 6. Tests of the Tests

The accounting fixture injects a fit error, a `[0, Inf]` sigma interval, and
finite endpoints on nonconverged and `pdHess = FALSE` fits; the latter cannot
enter either interval rate. Tests assert generic recovery aliases are absent.
The K=12 fixtures compare the frozen ML estimator directly with `rma.uni()`
and `rma.mv()`.

## 7a. Issue Ledger

- Fixed: high-K-only grid omitted the applied K=12 boundary.
- Fixed: returned `[0, Inf]` intervals could be hidden by successful-fit-only summaries.
- Fixed: initial new K=12 comparator fixtures accidentally used REML.
- Fixed: interval endpoint and recovery labels could overstate their conditioning.
- Deferred: B3 timing smoke and formal campaign require explicit approval.

## 8. Consistency Audit

Rose checked public reader surfaces and found consistent “implemented/tested,
tier unregistered, no interval/coverage claim” wording. Fisher checked
estimator matching and interval estimands. The LOAD-FIRST compute and
truth-recovery guards shaped the design; the prior-work sweep used the local
brain query and twin-repo inspection. No Golden-Set memory-regression command
was applicable because no hub guard or durable-brain rule changed.

## 9. What Did Not Go Smoothly

Fisher caught the ML/REML mismatch and Rose caught invalid finite endpoints
before closeout; both led to targeted repairs. The full silent suite was too
long for this interactive slice and was stopped honestly rather than reported
as green. A local sass cache lacked write permission during article build.

## 10. Known Residuals

B3 remains NO-GO. No formal smoke, run-contract freeze, 16,800-attempt
campaign, or full-suite total exists. The article render has a local cache
warning. The current evidence does not establish coverage certification.

## 11. Team Learning

For boundary intervals, separate “finite and covering” from conditional set
coverage, and name every recovery statistic by its retained denominator. An
estimator-specific oracle must match the frozen campaign estimator at the same
small-K boundary.

## 12. Cross-Product Coverage

**Covers ✓:** Gaussian ML `meta_V(V = V)`, constant `sigma ~ 1`, vector/dense
known covariance, K=12 comparator fixtures, all-attempt accounting, and the
reader’s dense-`V` preflight.

**does NOT cover ✗:** REML, `sigma ~ x`, profile/bootstrap intervals,
non-Gaussian meta-analysis, sparse/proportional/misspecified `V`, bivariate
random effects plus `meta_V`, campaign evidence, coverage certification,
capability promotion, CRAN readiness, deployment, or Julia support.
