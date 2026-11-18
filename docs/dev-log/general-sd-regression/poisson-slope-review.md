# Poisson slope-only SD slice: source/API review

## Verdict

No source-level admission or target-mapping blocker found in the reviewed
Poisson slope-only assembly. This is a conditional review of the R-side
builder and target identity changes, not approval of the compiled likelihood,
parameter recovery, interval behavior, or calibration. Fresh compiled and
fit-level checks remain necessary.

## Scope reviewed

Reviewed `docs/dev-log/general-sd-regression/poisson-slope-contract.md`,
`R/random-effect-targets.R`, the Poisson builder changes in `R/drmTMB.R`, and
`tests/testthat/test-poisson-slope-sd-assembly.R`. No fits or tests were run
for this review.

## Findings

The family opt-in is isolated. `drm_poisson_sd_mu_targets()` is called from
the Poisson builder and passes `allow_slopes = TRUE`; the shared scalar helper
defaults to intercept-only and the binomial adapter preserves that default.
The NB2 builder does not call the Poisson adapter. The Poisson builder rejects
zero-inflated models before assembly and rejects direct-SD combinations with
missing responses, `mi()` predictors, or structured random effects. The
existing Poisson term validator also rejects labelled slopes and correlated
blocks. The new adapter requires one independent slope-only term whenever a
slope is targeted, so mixed intercept/slope and crossed-slope layouts do not
slip through.

The resolver maps `sd(id, coef = "x")` to the `x` member of the ordinary
random-effect structure. The new assembly test checks the resolved coefficient,
observation-level design values, group-scale design matrix, group-row indices,
and zero random-effect correlation count. The model assembly carries `x` in
`mu_re_value`, so the implied latent contribution is `x * tau_g * u_g`; the
contract's marginal mean `exp(eta_fixed + x^2 tau_g^2 / 2)` follows from that
Gaussian scalar effect. The coefficient splitter stores SD-regression
coefficients under the formula's `dpar` name and uses the scale design-matrix
column names; `coef.drmTMB()` then returns the selected entry by `dpar`.

The new test also exercises explicit versus shorthand target selection,
ambiguous intercept/slope selection, an invalid intercept selector for a
slope-only term, mixed terms, a correlated block, a non-constant group
predictor, and preservation of the binomial intercept-only fence. The source
guards for zero inflation, missing-data/structured combinations, and labelled
slopes are clear, but those particular negatives are not asserted in this new
test file. Adding one compact negative assertion per guard would protect the
intended boundary; this is a test-coverage suggestion, not an identified
source bug.

## Boundary

This review supports continued validation of the single unlabelled
independent numeric slope-only Poisson target. It does not validate the TMB
likelihood numerically or establish successful recovery. No claim is made for
binomial slopes, NB2 or zero-inflated families, multiple or correlated slope
terms, mixed intercept/slope scale models, structured partners, missing-data
routes, or calibrated uncertainty.

**Naturalness assessment:** 2/10, medium confidence; genre: concise internal
source/API review, entire note reviewed. The phrase “conditional review”
clearly identifies what the evidence does and does not establish; no repair
needed. Science = pass for the scalar Gaussian algebra only, with compiled
likelihood validation still open; facts = pass against the inspected builder,
resolver, coefficient splitter, and test; references = pass for these local
source pointers. Reviewer: Codex self-review, independent mode, 2026-10-17;
this reviewer ran no fit or test, and no independent review is implied.

## Compiled re-review

The corrected Totoro receipt supports a bounded native implementation/workflow
GO for this slice. `counts.json` reports 235 expectations across seven suites:
23 Poisson-slope integration, 24 independent scalar-reference, 43 Poisson
intercept, 22 binomial-selector integration, 18 binomial integration, 16
binomial profile, and 89 Gaussian random-effect-scale expectations. The final
source regression log also records 18 source expectations for the slope
assembly after four new unsupported-combination checks.

The source-identity check passes: current SHA-256 values match both the
source manifest and `installed-source-sha256.txt` for `R/drmTMB.R`
(`81c17c49…`), `R/random-effect-targets.R` (`366a0b88…`), and unchanged
`src/drmTMB.cpp` (`b46f05de…`). The post-build reconciliation records changes
only to the slope assembly and integration test files, with
`runtime_unchanged: true`; the corrected integration test was copied outside
the immutable source and run against the same compiled library. The initial
failure remains preserved in `output/tests.log`: a test passed the returned
interval list to `is.finite()`. The corrected output reports all seven suites
complete and `NATIVE_BINOMIAL_SD_PASS`. The correction concerns the test
assertion; the compiled model source did not change.

Public wording is consistent about the estimand and the limit: the top of
`NEWS.md`, the Poisson slope section in `docs/design/03-likelihoods.md`, and
`poisson-slope-contract.md` all state that the SD is per unit of `x`, while
interval calibration, Julia integration, and mixed/structured layouts remain
open. One unrelated stale statement still prevents complete documentation
sign-off: the `mu` eligibility row in `docs/design/01-formula-grammar.md:1096`
says the Beta q1 direct latent-SD regression, intervals, and coverage remain
deferred. This contradicts the exact ratified Beta `mc-0017` exception and
should be reconciled in the existing Beta wording repair; it does not broaden
or invalidate the Poisson slope result.

This GO covers compiled native implementation and workflow for one complete-
data, ordinary Poisson, unlabelled independent slope-only target. It is not
recovery or uncertainty calibration and does not authorize other response
families, mixed or crossed layouts, structured partners, missing-data routes,
or Julia support.

**Naturalness assessment v2:** 2/10, medium confidence; genre: internal
verification note, entire updated note reviewed. “The corrected Totoro receipt
supports a bounded native implementation/workflow GO” ties the conclusion to
its evidence and scope; no repair needed. Science = pass for implemented
behavior only, with calibration explicitly open; facts = pass against the
receipts and source hashes, with the Beta wording discrepancy recorded;
references = pass for the local paths and evidence cited above. Reviewer:
Codex self-review, independent mode, 2026-10-17; prior package examples and
tests were already seen, so this is not held-out evidence.

## Final documentation and provenance resolution

The Beta wording discrepancy recorded above is resolved in the current docs.
The `mu` policy row in `docs/design/01-formula-grammar.md` now distinguishes
the exact q1 constant-SD Beta phylogenetic point-fit cell from the separate
q1 direct latent-SD route. The latter is explicitly limited to the exact
`mc-0017` profile-coverage regime (`g = 1024, m = 4`) and its stated caveats;
random-effect slopes, labels/q2+, broader designs, and broader interval or
coverage claims remain deferred. The adjacent `phylo()` row describes the
constant-SD intercept-only exception and directs readers to the separate
direct-SD row, so it does not override that exception. The Beta paragraph in
`docs/design/03-likelihoods.md` and the two Beta limitation passages in
`docs/dev-log/known-limitations.md` use the same boundary. I checked these
paths exhaustively for the prior blanket-deferral wording; no remaining
contradictory blanket statement was found. This resolves the docs blocker
without changing the Poisson claim or expanding Beta support.

The compiled evidence remains bounded and source-bound: the preserved source
regression has 18 slope assertions, the independent scalar likelihood
reference has 24, and the corrected compiled capsule has 235 expectations
across seven suites. The reconciliation records only two test-file changes,
`runtime_unchanged: true`, and no calibration claim. These receipts support
the native Poisson slope-only implementation/workflow review above; they do
not establish recovery, interval calibration, Julia parity, or programme-wide
completion.
