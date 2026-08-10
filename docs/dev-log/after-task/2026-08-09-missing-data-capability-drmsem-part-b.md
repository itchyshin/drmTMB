# After Task: missing-data capability build (drmSEM Part B)

## 1. Goal

Act on the nine engine-side asks drmSEM raised against drmTMB: bring the
missing-**predictor** subsystem under G0–G5 discipline, make `imputed()` standard
errors machine-readable, widen the `missing = "model"` response-family gate,
resume the missing-response G4/G5 campaign, and file the corrected ask-set.

## 2. Implemented

`imputed()` now reports a genuine conditional standard error for 12 of 13 predictor
routes, computed as the posterior SD of probability grids already persisted on the
fit — no new TMB computation. Only `categorical()` remains `NA`, because its estimate
is a mode over unordered nominal codes with no metric variance; it is tagged
`route_conditional_se_unavailable`. Fit-level `sdreport` state still takes precedence
over the route-level value.

The capability ledger gained a `missing_predictor` axis with 17 rows over the truly
admitted (response × predictor) surface: 14 at `diagnostic_only`/G2 and 3 at
`point_fit_recovery`/G3.

The G4/G5 runner gained a declared centring switch and now resolves its own symbols,
described below.

## 3a. Decisions and Rejected Alternatives

**The response-family gate was NOT widened.** drmSEM framed Issue 1 as a whitelist
narrower than the implementation. An audit of `src/drmTMB.cpp` found the opposite: only
`model_type == 1` (gaussian, full predictor catalogue) and 10/18/6/7 (beta, binomial,
poisson, nbinom2 — bernoulli predictor only) carry any `has_mi`/`mi_family` wiring.
Gamma, lognormal, student, beta_binomial, zi_poisson and zi_nbinom2 have none. Admitting
them would have exposed families whose observed-data likelihood cannot integrate the
missing predictor. `R/missing-data.R:366-368` and `R/drmTMB.R:308-317` already describe
the implemented surface accurately and were left unchanged. Recorded as issue #962.

**Centring was made a switch, not an edit.** Deleting `u <- u - mean(u)` would have
destroyed v1 reproducibility. `options(drmTMB.mr_g4g5_centre_random_effects = )` defaults
to the v1 behaviour, so the frozen manifest still hashes to
`d3eea7eda9a67725189e6aef3e12a88fee5927d4b10a0bd6a915f0e5df392828`, and a v1 and a v2
artifact cannot be silently conflated.

**An `exists()` guard was rejected** for the runner's symbol resolution: `exists()`
inherits to the global environment, so under `devtools::load_all()` it finds the test
helper and resolves differently in test than in deployment — the exact split it was meant
to remove. Both symbols are now bound unconditionally under runner-owned names.

## 4. Files Touched

`R/missing-data.R` (route-conditional SE + status vocabulary), `man/imputed.Rd` and three
new `man/` pages, `inst/sim/R/sim_missing_response_g4g5.R` (centring switch, symbol
resolution), `tools/capability_ledger.py` and the ledger/dashboard/vignette surfaces,
and five test files.

## 5. Checks Run

`devtools::document()` clean. Full `devtools::test()` baseline on the fresh worktree:
**0 failures, 0 errors** (72 pre-existing documented warnings). All `missing-*` suites:
0 failures. `tools/capability_ledger.py --write` and `--check`: pass (31 generated
outputs). 66 ledger generator unit tests: pass. `tools/check-capability-runtime.R`: pass.
Frozen manifest hash re-verified after every runner change: matches.

## 6. Tests of the Tests

Two regression tests were added to `test-missing-response-g4g5-foundation.R`. The first
rebuilds every one of the 18 route fixtures in an environment parented only by the package
namespace — the environment an installed run actually sees — so a route that silently
depends on a test helper fails the suite instead of failing in deployment. The second
asserts the runner's own skew-normal transform agrees with the testthat helper, guarding
the two copies against drift. An earlier version of the first test passed for the wrong
reason (`exists()` reached the helper through the global environment); that is what
motivated binding the symbols unconditionally.

## 7a. Issue Ledger

Filed #962–#969 on the corrected ask-set. drmSEM's Issues 4 and 5 were implemented here
rather than filed. Six of the nine original asks carried line references that had drifted
from `main`; all were corrected before filing.

## 8. Consistency Audit

The ledger, generated dashboard, capability surface HTML/MD and the vignette include were
regenerated together and agree. `drm_standard_error_status()` was left untouched so its
other caller (`R/methods.R:4282`, the fixed-effect coefficient table) is unaffected;
`test-control.R` confirms it.

## 9. What Did Not Go Smoothly

Three self-inflicted errors, each caught before it reached a conclusion. A review-lens
sub-agent (read-only by construction) was dispatched to an implementation slice and could
not edit anything; it reported the blocker rather than faking completion, and the work was
re-dispatched. A validation script indexed `conf.low`/`conf.high` on a `confint()` result
whose columns are `lower`/`upper`, silently yielding all-NA — caught only because the
script counted usable rows. A route-runnability audit read `names()` of a data frame and
"tested" seven column names as if they were routes.

## 10. Known Residuals

`cumulative_logit` cutpoint targets cannot reach G4 at all: `confint()` has no profile
interval for target class `ordinal-cutpoint-internal`, so six of its nine cells fail
deterministically at every information rung (#967). The v2 campaign is running and no route
has been promoted; promotion still requires a fresh D-43 review. The v1 evidence remains
valid but is not comparable to v2. `beta_binomial` predictor fits emit pre-existing
false-convergence warnings.

## 11. Team Learning

Sub-agent dispatch discipline currently audits *which model* but not *which tools*. Review
lenses (Emmy, Rose, Fisher, Noether, Boole, Darwin, Florence, Ada) are read-only by
construction; implementation must go to `tmb_engineer`, `simulation_tester`,
`documentation_writer` or `general-purpose`. The existing `claude-routing-audit` cannot
catch this because it inspects the model field only.

A simulator can fail in the package's favour. Over-coverage reads as "safe" and is a
calibration failure: `nbinom2` was the one route that never centred and the one route whose
intercept passed, which is a controlled contrast that sat unexamined in the results for
over a week.

## 12. Cross-Product Coverage

This arc covers the missing-predictor SE surface, the `missing_predictor` ledger axis, the
G4/G5 runner's deployment correctness and centring design, and the corrected upstream
ask-set. It does **NOT** cover: any response-family gate widening (#962), multiple `mi()`
terms (#963), mediator-model reuse (#964), ordinal scale sub-models (#966), ordinal cutpoint
intervals (#967), spatial Matérn (#968), multinomial responses (#969), or any route-level
G4/G5 promotion. No missing-response ledger row moved off G3.
