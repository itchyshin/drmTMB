# Structured response-mask recovery pre-run

## Purpose

This local pre-run tests whether a single stable structured q1 recovery design
exists before requesting the planned DRAC campaign. It concerns the three
univariate Gaussian REML response-mask cells that already have G2
observed-data-oracle evidence: spatial (`mc-0287`), animal (`mc-0299`), and
relmat (`mc-0311`).

## Frozen pre-run design

- Formula: `y ~ x + provider(1 | id), sigma ~ 1`, `REML = TRUE`.
- Providers: `spatial()`, `animal()`, and `relmat()`.
- Data: 64 groups, 8 observations per group; a 25% MCAR response mask is drawn
  within every group.
- Truth: fixed effects `(0.4, 0.25)`, residual SD `0.5`, structured SD `0.5`.
- Attempts: seeds 2026081410--2026081412 for every provider, retaining all nine
  fits.

## Result

Every attempt converged with `pdHess = TRUE`. Mean absolute errors by provider
were:

| Provider | mu intercept | mu slope | residual SD | structured SD |
| --- | ---: | ---: | ---: | ---: |
| spatial | 0.1041 | 0.0259 | 0.0070 | 0.1218 |
| animal | 0.0443 | 0.0363 | 0.0098 | 0.0269 |
| relmat | 0.0455 | 0.0325 | 0.0089 | 0.0549 |

The largest individual structured-SD error was 0.2554 (spatial, seed
2026081411). This is a workable recovery design for a larger all-attempt
campaign, but the three-seed pre-run is not G3 certification and does not
promote any cell.

## Proposed DRAC gate

Run an all-attempt array with this exact design, 100 independent seeds per
provider (300 fits). Retain convergence/Hessian state and all four parameter
errors. The proposed G3 promotion rule is: no fit failures; mean absolute error
at most 0.15 for every reported target; and no structured-SD error above 0.35.
MCAR is the only proposed first campaign mechanism. MAR, profiles, and coverage
remain separate later gates.

The local pre-run took about nine seconds, so the 300-fit campaign should be
small enough for DRAC but still requires the stipulated explicit approval before
submission.
