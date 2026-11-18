# After Task: Beta-binomial ordinary SD bridge

## 1. Goal

Admit and verify the paired Julia candidate's ordinary Beta-binomial mean SD regression through the R bridge for a random intercept and an independent numeric slope.

## 2. Implemented

The bridge now admits only one matching ordinary `mu` SD target when `sigma ~ 1`. Same-data synthetic comparisons cover the ordinary q1 intercept and independent numeric-slope routes. Public group-SD extraction and `predict_parameters()` label alignment are checked. The R registry remains fenced for correlated blocks, structured effects, mismatched targets, random or nonconstant `sigma`, and other unsupported shapes.

## 3a. Decisions and Rejected Alternatives

Kept Beta-binomial behind the generic fixed-effect-only fence and added a family-specific narrow admission predicate. A broad family exemption would admit shapes that have no paired implementation. Assumption: the current candidate's `sigma ~ 1` boundary remains part of this route; allowing a modeled or random `sigma` would require a separate identifiability and parity review.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-beta-binomial-sd-parity.R`
- `tests/testthat/test-julia-family-beta_binomial.R`
- `vignettes/julia-engine.Rmd`
- `vignettes/formula-grammar.Rmd`
- `NEWS.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/general-sd-regression/inventory.md`
- `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`
- `docs/dev-log/general-sd-regression/evidence/betabinomial-ordinary-sd-parity-20261024-v1/`
- `.unlazy/general-sd-regression/GATES.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-24-julia-beta-binomial-ordinary-sd-parity.md`

## 5. Checks Run

- Direct Julia regression: 25/25 intercept assertions and 8/8 independent-slope assertions passed.
- Focused R bridge filter `julia-beta-binomial-sd-parity|julia-family-beta_binomial`: 70 passed, 0 failed, 0 warnings, 0 skipped; three live Julia fits; 57.3 seconds.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: PASS; 41 receipt records, 32 linked rows, 19,086 unlinked candidates.
- `gh issue list --search 'beta_binomial sd Julia' --limit 10` and `gh issue view 1273`: the open crossed-Laplace near-boundary issue is adjacent to the family but does not cover this ordinary SD route; no issue action taken.
- A Graft CLI query was unavailable because `graft` is not installed in this environment. `route.py` found no LOAD-FIRST manifest for this checkout.

## 6. Tests of the Tests

The initial bridge run reproduced the fixed-effect-only rejection before the admission change. Negative admission cases keep nonmatching targets, random/nonconstant `sigma`, and unsupported random-effect shapes fenced. Direct Julia tests include independent numerical checks from the existing Beta-binomial SD regression fixture.

## 7a. Issue Ledger

No issue was opened or changed. Issue #1273 concerns crossed Laplace behavior near the Beta-binomial overdispersion boundary. This slice exercises the ordinary q1 SD bridge, so that issue remains an independent follow-up.

## 8. Consistency Audit

Updated the Julia-engine guide, formula-grammar vignette, NEWS, known limitations, family adapter map, and inventory to state the narrow ordinary route and its limits. Reconciled the generated candidate-evidence counts. The 19,118 rows enumerate candidate combinations; delivered capabilities require a separate verified count. Neighbour scans used `rg -n -i 'beta.?binomial.*(julia|bridge|parity)|julia.*beta.?binomial|beta.?binomial.*remain open|beta.?binomial.*planned|fixed.effect.*beta.?binomial' docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd README.md NEWS.md` and `rg -n -C 1 'beta_binomial\(\).*Implemented first slice|Julia parity.*beta-binomial|beta-binomial.*Julia parity|beta_binomial.*random' docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd docs/dev-log/internal-roadmap.md README.md docs/dev-log/known-limitations.md`. They exposed stale wording that was corrected in the formula-grammar entry.

## 9. What Did Not Go Smoothly

The first bridge test failed at the registry fence, which was the missing admission rather than a Julia fitter failure. JuliaCall startup made the final rerun slightly longer than the earlier timing. The Graft command and repository LOAD-FIRST manifest were unavailable.

## 10. Known Residuals

This is candidate-only point-recovery and public-output evidence for two complete-response ordinary q1 cells. Structured and correlated Beta-binomial effects, other distributional endpoints, save/reload and refit workflows for this new bridge route, and interval calibration remain unverified. The full native/Julia family-effect-provider universe remains open. This does not complete the overall goal.

## 11. Team Learning

Family admission should remain a narrow predicate at the bridge boundary when a fitter implements only selected random-effect shapes. Memory receipt: D-93 was retrieved and preserves the requirement that known undercoverage must not be published as calibrated; no LOAD-FIRST manifest was available. Golden Set: not checked because this slice did not investigate a known Golden Set mistake class. No cross-project discovery was performed.

## 12. Cross-Product Coverage

Covers: the Beta-binomial ordinary mean q1 intercept and independent numeric slope on the paired R/TMB and Julia development candidates, with fixed `sigma ~ 1`, same-data point comparisons, group-SD extraction, and `predict_parameters()` row alignment.

Does NOT cover: structured providers, correlated or labelled blocks, random or nonconstant `sigma`, other distributional endpoints, full save/reload/profile/bootstrap semantics for these bridge cells, interval coverage, or programme-wide engine parity.
