# Missing-predictor transformed uncertainty

## 1. Goal
Continue approved Julia–R parity programme #563. Repair public covariance and interval coordinates for implemented native missing-predictor summaries and match the Gaussian predictor-SD Wald construction in the R Julia adapter. Programme G0–G8 remain OPEN.

## 2. Implemented
Exact metadata maps public scales, mixture probabilities and grouped/structured predictor SDs to their raw log/logit slots. Public covariance applies the Jacobian on both axes; profile metadata retains raw coordinates; Wald endpoints transform once. Predictor random-effect SDs retain boundary warnings. Julia adapter Gaussian predictor-SD intervals now exponentiate raw log-Wald endpoints while public covariance stays on the natural scale.

## 3a. Decisions and Rejected Alternatives
Do not expose raw covariance as natural covariance or use a natural-scale symmetric interval under a log-Wald label. Native joint bootstrap lacks joint predictor simulation and missingness-preserving refits; it now fails before compute. Implementing that workflow remains required. No estimator, optimizer, comparator or parity threshold changed.

## 4. Files Touched
R/profile.R, R/methods.R, R/julia-joint-methods.R, focused new and existing tests, bounded verification runner, related Rd help, retained evidence and this report. Foreign R/julia-bridge.R ZOB edits are untouched.

## 5. Checks Run
The source-stamped native-mi-transform-receipt-001.json records 194 new transformed-covariance assertions, 101 regression covariance assertions, 47 bridge adapter assertions and 100 assertions across seven ordinary profile/Wald/bootstrap tests: 442 total. Elapsed 9.432 seconds includes package startup, not warm timing. Both edited Rd files parse. The covariance sentinel tests primary/fallback raw-versus-natural ADREPORT selection, not joint REML admission.

## 6. Tests of the Tests
Retained RED runs have 41 initial failures, five boundary/bootstrap failures and three bridge interval failures. The initial summary test used the wrong label fields; it was repaired to use row names. Logit tails, malformed names, slot separation, covariance cross-blocks and no-SE behaviour are checked. Genuine fitted Gaussian/two-Gaussian, zero-one-beta and grouped/relmat predictor cases provide the raw covariance oracles; bridge transport unit cases are synthetic and are not claimed as live Julia fits.

## 7a. Issue Ledger
DRM.jl#563 remains OPEN. All native obligations remain required, including joint simulation/refitting, profile/bootstrap evidence, direct Julia operations, every registered warm win, worktree recovery, full documentation and final integration. This repair does not close a whole capability row.

## 8. Consistency Audit
Rose approved the covariance and interval code after requiring predictor-SD boundary classification and an explicit joint-bootstrap guard. Both requested help/rejection-message corrections are included. Golden Set: original missing-predictor regression tests, exact transformed raw covariance/Wald checks and ordinary inference neighbours. Bridge interval metadata still uses public parameter labels and is not fully identical to native metadata.

## 9. What Did Not Go Smoothly
Wald eligibility initially omitted logistic transformations. Random predictor SDs remained fixed-effect rows and bypassed boundary warnings. Shared bootstrap eligibility exposed the incomplete joint refit contract. These were addressed without changing fitted likelihoods or hiding failures.

## 10. Known Residuals
Joint missing-predictor bootstrap remains unimplemented on both engines; the explicit refusal is a safety repair, not parity completion. Julia joint profile intervals remain unavailable. Native profile execution/coverage and all other Julia-engine profile/bootstrap workflows still require evidence. Strict 4e-6 native fit differences remain open. Ayumi-san's separate polytomy restriction is reproduced and queued; her inference report has not yet been tied to a specific model. No release, registration, deployment or collaborator message.

## 11. Team Learning
A public transformation changes covariance on both axes and may change interval construction. Reusing eligibility lists can admit an inference method whose simulation/refit contract is incomplete. Keep those contracts explicit.

## 12. Cross-Product Coverage
This slice does NOT cover joint bootstrap implementation, native/Julia interval coverage, complete profile execution, joint REML, all families/providers, every public operation, warm performance or clean final-head integration. Actual agent-hours were not instrumented. The full approved programme remains active.
