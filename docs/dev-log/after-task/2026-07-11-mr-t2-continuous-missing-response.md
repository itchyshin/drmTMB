# MR-T2 continuous missing-response routes

## Outcome

MR-T2 adds G3 recovery-verified missing-response handling for Student-t,
skew-normal, lognormal, and Gamma. The capability board now records 10 verified
routes and eight G0 routes. No MR-T3 family was implemented.

## Implementation

Each builder keeps the response row under
`missing = miss_control(response = "include")`, validates and initializes from
observed responses, and supplies a data-time `observed_y` mask to TMB. The
Student-t, skew-normal, lognormal, and Gamma likelihood branches guard their
whole response contribution. In particular, the lognormal and Gamma branches
do not evaluate `log(y)` for a masked sentinel. Lognormal and Gamma residuals
now follow the shared full-length response-mask contract.

Student-t, lognormal, and Gamma were exercised through their existing ordinary
random-intercept recovery routes. Skew-normal remains fixed-effect only. The
route-level evidence does not promote structured effects, REML, intervals, or
coverage.

## Evidence

- Focused MR-T2 and neighbouring family tests passed.
- The combined `devtools::test(filter = "missing")` suite passed after updating
  one stale control-parser expectation; two unavailable Julia routes were
  skipped and two pre-existing beta-binomial optimizer warnings remained.
- Direct retapes require objective/gradient agreement within `1e-8` and
  independently optimized coefficient/log-likelihood agreement within `1e-6`.
- Every recovery case uses an exact fixed-seed 25% MCAR mask and the existing
  family DGP size and tolerance.
- `python3 tools/capability_ledger.py --check`, six generator unit tests, and
  `tools/check-capability-runtime.R` pass with 18 routes, 10 verified, and eight
  G0.
- `devtools::document()` and the live-source `missing-data` pkgdown article
  build passed.
- `git diff --check` passed.

## Review

The independent review first returned NOT DONE because runtime admission had
landed before the four ledger promotions. The repair added separate same-cell
G2 and G3 evidence, evidence-citing transitions, generated surface updates, and
runtime/generator reconciliation. The same reviewer was asked to recheck the
closed boundary before the PR.

## Remaining boundary

MR-T3 starts only after this tranche passes Ubuntu R-CMD-check and the required
intermediate `clang-ubsan` run. Tweedie, zero-one beta, encoded responses,
truncated counts, and mixture routes remain G0. G4/G5 evidence remains outside
this arc.
