# After-task — Lane C Z7 zero-one-beta sigma spatial q1

## 1. Goal

Recover only `mc-0596`: ordinary ML zero-one-beta with one unlabelled,
fixed-coordinates spatial q1 random intercept on `sigma`.

## 2. Implemented

The exact parser, active structured sigma carrier, extractor, profile fence,
dense spatial oracle, and source-bound local fixture are present.

## 3a. Decisions and Rejected Alternatives

Only `spatial(1 | site, coords = coords)` is admitted. Mesh/range forms,
slopes, labels, other providers/dpars, and ordinary RE combinations are closed.

## 4. Files Touched

The scoped implementation/test commits, corrected runner, both retained run
directories, and this closeout are the complete candidate record.

## 5. Checks Run

Focused zero-one-beta tests passed. The independent objective/AD-FD oracle and
corrected four-seed local recovery fixture passed their stated rules.

## 6. Tests of the Tests

The oracle rebuilds the coordinates precision and emitted level ordering. The
initial fixture’s draw-order defect was caught by independent review, retained,
then corrected in run 2.

## 7a. Issue Ledger

No ledger transition occurs in this receipt. Promotion requires fresh review
of run 2 and can state point-fit recovery only.

## 8. Consistency Audit

The corrected DGP names its draw by coordinate row names; formula, precision
oracle, carrier, extraction, and reporting scale all agree.

## 9. What Did Not Go Smoothly

The first fixture was permutation-mismatched. It was never used for promotion.

## 10. Known Residuals

This does NOT cover profile intervals, coverage, mesh/range estimation,
slopes, covariance, other providers, or inference readiness.

## 11. Team Learning

Named precision inputs require verifying the DGP’s latent draw ordering, not
only the fitted-object order and likelihood oracle.

## 12. Cross-Product Coverage

This Z7 spatial q1 receipt covers only sigma with fixed coordinates; it does NOT cover Lane A association, Lane B scale/interval work, the Future-extension audit, other dpars/providers, public defaults, or API surface.
