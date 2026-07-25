# After Task: Arc 6.7 ordinary NB2 × ordinary NB2 frozen-margin association

## 1. Goal

Add one fixed-effect, complete-pair ordinary-NB2 × ordinary-NB2 latent-normal
association adapter without altering either margin or claiming inference or a
capability tier.

## 2. Implemented

`associate_pairs()` now accepts two ordinary fixed-effect ML `nbinom2()` fits
on identical complete rows, in either input order. It freezes both marginal
mean and overdispersion vectors and estimates only intercept-only
latent-normal `eta`. The existing private versioned descriptor distinguishes
the two NB2 roles while preserving input response labels in `fitted()`,
`predict()`, and `simulate()`.

## 3. Mathematical Contract

Each count pair is a latent-normal rectangle formed from two tail-stable NB2
CDF jumps. Production evaluates it as a one-dimensional conditional-normal
integral with log-space inner differences and a mixed absolute/relative error
rule. Endpoint or quadrature failure withholds `eta` and retains row-level
diagnostics; it never clips probabilities or uses four-corner subtraction.
[Design 237](../../design/237-arc6-7-nbinom2-nbinom2-contract.md) records the
equation and scope boundary.

## 3a. Decisions and Rejected Alternatives

The slice retains the general frozen-margin latent-normal route rather than
introducing a direct shared-Gamma count model. `eta` remains distinct from
`rho12`, and a failed numerical row is retained rather than clipped, floored,
or silently discarded. S0 recovery and all inference work remain separate
owner-gated work.

## 4. Files Touched

- `R/associate-pairs.R` and regenerated `man/associate_pairs.Rd`.
- `tests/testthat/test-associate-pairs-nbinom2-nbinom2.R`.
- Design 237, the series overview, formula grammar, NEWS, limitations, and
  check log.

## 5. Checks Run

- `devtools::document()` regenerated `man/associate_pairs.Rd`.
- Focused Arc 6.1/6.2/6.6/6.7 association tests: 152 pass, 0 fail/warn/skip.
- `git diff --check` passed.
- Hosted package CI is required before merge and is not claimed here.

## 6. Tests of the Tests

The suite compares direct production rectangles with an independent
`mvtnorm::pmvnorm()` oracle, checks the `eta = 0` product identity, finite-grid
normalization, high-tail accuracy, input-order symmetry, response-label
preservation, deterministic simulation, and explicit endpoint/integration
failures.

## 7a. Issue Ledger

`gh issue list --state open --search 'associate pairs OR NB2 pair OR Arc 6'`
found no overlapping open issue requiring an update. No issue was created,
changed, or closed.

## 8. Consistency Audit

The Roxygen help, formula grammar, Arc 6 roadmap, NEWS, and limitations now
name all four reviewed latent-normal pair classes. Historical reports retain
their then-correct boundaries. Exact `biv_lognormal()` and `biv_student()`
remain separate models with their own `rho12` contracts.

## 9. What Did Not Go Smoothly

Initial implementation omitted the second NB2 role from `fitted()` and
`predict()` dispatch, and the first test matrix lacked a tail-normalization
regression. Both were added before documentation and review closure.

## 10. Known Residuals

This is construction-level evidence only. Recovery, intervals, coverage,
standard errors, association slopes, random or structured effects, partial
pairs, offsets, weights, missingness, `mi()`, `meta_V()`, REML, Julia, and
generic count-pair support remain outside the contract. Hosted CI and PR review
remain necessary before source merge.

## 11. Team Learning

For same-family discrete pairs, identical family labels are not enough:
private component roles must remain position-specific while user-facing
response names follow the input order. Tail stress and a retained numerical
failure are part of the adapter contract, not optional test extras.

## 12. Cross-Product Coverage

The source contract checks interaction with prior latent-normal pairs through
the focused Arc 6.1/6.2/6.6/6.7 suite. It does not yet claim Arc 6.8
cross-pair integration: Arc 6.5 is retained HOLD and all pair source slices
must first merge in order. This report does NOT cover REML, random or
structured effects, missingness, weights, offsets, new-data prediction,
association slopes, intervals, coverage, recovery, capability promotion,
Julia, direct count kernels, exact-special `rho12` models, or any provider
beyond fixed-effect ordinary-NB2 frozen margins.

## Next Actions

Run the focused suite and package CI on the final branch, then open/review the
source PR. Any S0 campaign needs a separate all-attempt approval and a
Totoro/DRAC receipt. Arc 6.8 must not integrate this slice before each Arc 6
pair has completed its own source gate.
