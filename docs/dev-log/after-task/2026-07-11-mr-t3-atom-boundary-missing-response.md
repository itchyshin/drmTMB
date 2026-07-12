# MR-T3 atom and boundary missing-response routes

## Outcome

MR-T3 adds G3 recovery-verified missing-response handling for Tweedie and
zero-one beta. The capability board now records 12 verified routes and six G0
routes. No MR-T4 family was implemented.

## Implementation

Both builders retain missing-response rows, validate and initialize from
observed responses only, and use a support-valid zero production sentinel. The
Tweedie C++ route guards the whole compound Poisson-Gamma density. The
zero-one beta route guards zero-atom, one-atom, and continuous beta decisions
together, so a masked sentinel cannot select a mixture component. Response and
Pearson residuals follow the shared full-length mask contract.

Both families remain fixed-effect only. The route-level evidence does not
promote random or structured effects, REML, response plus `mi()`, intervals, or
coverage.

## Evidence

- Tweedie direct retapes compare valid sentinels `0` and `1`; zero-one beta
  compares `0` and `1` atoms separately with the valid interior sentinel `0.5`.
- Objective/gradient agreement is required within `1e-8`; independently
  optimized coefficients/log-likelihood are required within `1e-6`.
- Exact fixed-seed 25% MCAR recovery reuses the existing Tweedie `n = 500` and
  zero-one beta `n = 1600` DGPs and their established every-dpar tolerances.
- The focused MR-T3, original family, whole missing-response, and combined
  missing-data suites passed. Two unavailable Julia tests were skipped; the
  two existing beta-binomial optimizer warnings remained.
- Deterministic ledger generation, six Python unit tests, and live runtime
  reconciliation pass with 18 routes, 12 verified, and six G0.
- `devtools::document()` and the live-source missing-data pkgdown article build
  passed.
- `git diff --check` passed.

## Remaining boundary

MR-T4 starts only after the Ubuntu R-CMD-check gate for this tranche. Encoded
responses, truncated counts, and mixture routes remain G0. G4/G5 evidence
remains outside this arc.
