# After-task — Lane C Z7 zero-one-beta sigma relmat q1

## 1. Goal

Recover only ordinary-ML `mc-0595`, an unlabelled supplied-`K` relmat q1
random intercept on zero-one-beta `sigma`.

## 2. Implemented

The exact parser, structured carrier, extraction, profile status, full oracle,
and retained four-seed recovery fixture are implemented for the q1 route.

## 3a. Decisions and Rejected Alternatives

Only `relmat(1 | species, K = K)` is accepted. `Q`, slopes, labels, other
providers, other dpars, and ordinary random-effect combinations remain closed.

## 4. Files Touched

The R implementation, zero-one-beta test, local runner, and source-bound
receipt are scoped to the relmat sigma candidate. Ledger change awaits review.

## 5. Checks Run

Focused zero-one-beta tests passed; objective and AD/central-FD gradient agree
with the independent full likelihood; the fixture passed all four attempts.

## 6. Tests of the Tests

The oracle reverses the supplied `K` order and computes its `K^{-1}` precision
and determinant independently. Direct, standard-profile, and endpoint entry
points are all rejected before a refit.

## 7a. Issue Ledger

No ledger row is moved by this receipt. Promotion requires a fresh completion
panel and then may claim point-fit recovery only.

## 8. Consistency Audit

Formula, TMB path, natural-scale `tau_sigma`, dense precision oracle, and DGP
agree on `K` covariance and log-sigma reporting scale.

## 9. What Did Not Go Smoothly

The initial local artifact predated its source commit, so it was rerun after
the code commit rather than used as evidence.

## 10. Known Residuals

This does NOT cover profiles, intervals, coverage, Q inputs, slopes,
cross-dpar covariance, other providers, or inference readiness.

## 11. Team Learning

`relmat(K)` requires an oracle that proves both covariance-to-precision
conversion and level ordering; a generic structured fit is insufficient.

## 12. Cross-Product Coverage

This Z7 relmat q1 receipt covers only sigma with supplied K; it does NOT cover Lane A association, Lane B scale/interval work, the Future-extension audit, other dpars/providers, public defaults, or API surface.
