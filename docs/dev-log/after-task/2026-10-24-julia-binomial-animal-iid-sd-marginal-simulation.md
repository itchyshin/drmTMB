## 1. Goal

Extend Julia Binomial marginal simulation to one complete-data animal random intercept plus one ordinary independent IID random intercept, with covariance and precision input support.

## 2. Implemented

- Added the admitted combined animal-intercept plus one IID-intercept shape to Julia Binomial marginal simulation.
- Kept animal and IID targets separate, applied their predicted group SDs to independent link-scale draws, and restored covariance ordering to first-seen fitted group order after bridge serialization removed matrix dimnames.
- Accepted both supplied covariance A and precision Ainv; the synthetic fixture checks same-data TMB/Julia estimates, likelihood, target predictions, and seeded public simulation.
- Updated roxygen and generated simulate.drmTMB help for this bounded route.

## 3a. Decisions and Rejected Alternatives

- Kept the extension to one animal intercept and one independent ordinary intercept. Random slopes, extra IID components, varying residual dispersion, and incomplete data remain refused by the route guard.
- Reused the established fitted A scale and first-seen group order. No kernel normalization or new public syntax was introduced.
- Assumption made without asking: the bridge-aligned covariance payload remains ordered to match first-seen groups when dimnames are removed. The A/Ainv equality and simulator tests check this assumption; if bridge payload ordering changes, simulation must carry an explicit identity mapping.

## 4. Files Touched

- R/julia-simulate.R
- tests/testthat/test-julia-binomial-animal-iid-sd-parity.R
- man/simulate.drmTMB.Rd
- .unlazy/general-sd-regression/GATES.md
- docs/dev-log/check-log.md
- docs/dev-log/after-task/2026-10-24-julia-binomial-animal-iid-sd-marginal-simulation.md

## 5. Checks Run

- Focused devtools test filter julia-binomial-animal-iid-sd-parity with live Julia bridge and thread caps passed: one live test, 35 expectations, no failures or skips, about 90 seconds.
- R parsing of source and test passed.
- Scoped git diff whitespace check passed for source, test, and generated help.
- Source SHA-256: R/julia-simulate.R cfa4b4ccd71fbf8b9cfe1bf3a314fe0ee617072356a0a8276e641e3d92632864; test f3a8d784402cb1a6496e293a4239ebf8acbd73ff03c11b8967afcbe186bb6a3b; help f4fe6ef3fedd47c9635f4155fc495b3dc4e77c24a1e9b85a8bed7d50ea983f46.
- After-task closeout compiler passed; prose check reported zero findings.

## 6. Tests of the Tests

The earlier focused regression run exposed that bridge serialization removed covariance dimnames. The simulator now restores labels in the documented first-seen group order; the current test compares the recovered matrix to the original A and checks seeded public simulation for both A and Ainv. This is a regression control for the failure observed during development, not a separate deliberate code mutation.

## 7a. Issue Ledger

- Fixed: public Julia Binomial marginal simulation previously refused an animal intercept combined with an ordinary IID intercept.
- Fixed: simulator-side covariance name loss after bridge serialization.
- Deferred: broader structures and interval-coverage calibration.

## 8. Consistency Audit

Checked the Julia Binomial route guard, target identities, link-scale draw composition, group ordering, both covariance input forms, roxygen source, and generated help. The focused parity and simulator test exercises the admitted combination. The route remains deliberately narrow.

## 9. What Did Not Go Smoothly

The first focused regression run detected missing covariance dimnames after bridge serialization. Carrying the matrix's established first-seen ordering through the simulator resolved the mismatch; the rerun passed.

## 10. Known Residuals

The feature covers one complete-data Julia Binomial simulation shape. It does NOT cover animal slopes, more than one ordinary IID term, correlated blocks, other distributions or structured providers, missing-data simulation, or coverage calibration. G3 and G4 remain open, and the full capability universe is outstanding.

## 11. Team Learning

Memory receipt: the repository route script returned no LOAD-FIRST manifest for this worktree. I consulted the repository after-task protocol and used the existing candidate evidence ledger; no routed guard or lesson was available to load. Golden Set: not in scope for this bridge serialization regression.

## 12. Cross-Product Coverage

Covers: Julia bridge marginal simulation for the admitted Binomial animal-intercept plus one IID-intercept shape; A and Ainv inputs; same-data TMB/Julia point parity in the focused fixture.

Does NOT cover: other engines' simulator behavior, other families, slopes, multiple IID or correlated effects, other structured providers, incomplete data, or uncertainty coverage. This is candidate evidence only and closes no programme gate.

