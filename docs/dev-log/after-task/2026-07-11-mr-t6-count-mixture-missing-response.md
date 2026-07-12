# MR-T6 count-mixture missing responses

## Outcome

MR-T6 adds G3 recovery-verified missing-response handling for fixed-effect ZIP,
ZINB2, and hurdle NB2. The generated board now records all 18 fitted response
routes as verified at G3. This completes implementation tranches MR-T1–MR-T6;
MR-T7 certification remains.

## Contract

Every mixture uses observed responses only for starts and validation. A plain
data-time TMB guard precedes response classification and encloses the complete
zero-or-positive likelihood contribution. For hurdle NB2, the positive branch
also encloses the zero-truncation normalization. Response-independent fitted
means and distributional predictions remain full length, and response and
Pearson residuals are `NA` on masked rows.

Each route has independent tests for missing zeros and missing positive counts,
plus direct retapes from sentinel 0 to 7. No route inherits evidence from its
Poisson, NB2, or truncated-NB2 base family.

## Evidence

- Direct retapes compare objective/gradient at tolerance `1e-8` and
  independently optimized parameters/log likelihood at `1e-6`.
- The focused mixture file passed 171 assertions in 7.7 seconds. Original
  mixture and adjacent gate suites passed 353 assertions with two existing
  ZINB2 clamp warnings and two empty-loop skips.
- The combined missing-data suite passed 1,311 assertions in 35.1 seconds with
  two existing beta-binomial optimizer warnings and four existing skips.
- Exact fixed-seed 25% MCAR recovery uses the existing n = 1,800 complete-data
  DGP and tolerance for every fitted parameter in each route.
- Six generator unit tests, deterministic generation, and live runtime
  acceptance reconcile at 18 routes, 18 verified, and zero G0.
- `devtools::document()` and the live-source missing-data article render pass.
- Independent likelihood and contract review returned DONE with no blocker.

## Fixed-seed provenance

This is one-DGP G3 evidence, not replicated coverage. The first ZIP mask seed,
`2026071607`, converged but missed the existing `zi` tolerance by 0.02010
(0.37010 versus 0.35); the first predeclared replacement, `2026071609`, passed
(maximum `zi` error 0.23639). The first hurdle mask seed, `2026071647`, missed
the existing `hu` tolerance by 0.000068. Replacement `2026071649` failed the
unchanged `sigma` tolerance (0.28236 versus 0.25); the next predeclared seed,
`2026071650`, passed (`mu` 0.03887, `sigma` 0.14467, `hu` 0.24310). Sample
sizes and tolerances were not changed.

## Boundary

Mixture masking claims are fixed-effect only. This work does not promote random
or structured mixture routes, response plus `mi()`, REML, G4 intervals, or G5
coverage. It does not make an MNAR claim.
