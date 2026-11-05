# Native Beta SD regression for one structured intercept

## 1. Goal

Check three exact native TMB Beta rows: a `relmat()` random intercept supplied as
covariance `K` or precision `Q`, and a coordinate `spatial()` random intercept.
In each row the log standard deviation of the location random intercept varies
with one group predictor. This is a point-fit implementation slice of the open
general-SD goal; interval coverage remains deferred.

## 2. Implemented

Two Beta admission predicates in `R/drmTMB.R` now accept an unlabelled q1
structured intercept while retaining their existing intercept-plus-one-slope
q2 routes. They keep the coordinate, label, extra-random-effect, complete-data,
and fixed-`sigma` restrictions. No C++ source or compiled DLL changed in this
slice. The native q1 path uses the existing scalar latent field, SD map, start,
and coefficient extraction. A standalone synthetic example shows the relmat
formula and its group-SD output.

## Mathematical contract

For group `g`, `u ~ N(0,K)`, `s_g = exp(alpha0 + alpha1 z_g)`, and
`eta_i = beta0 + beta1 x_i + s_group[i] u_group[i]`. The Beta mean is
`1e-12 + (1-2e-12) plogis(eta_i)` and its precision is
`exp(-2 log_sigma)`. In R the corresponding relmat formula is
`bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1,
sd(id, level = "relmat") ~ z)`. The `sd_relmat(id)` output gives the fitted
standard deviation for each named group. The coordinate route replaces
`relmat(1 | id, K = K)` with `spatial(1 | id, coords = coords)` and uses
`sd(id, level = "spatial") ~ z`. For relmat, `sd_relmat(id)` reports the
group loading `s_g`; because the supplied `K` has a non-unit diagonal, the
marginal standard deviation of `s_g u_g` is `s_g sqrt(K[g,g])`. The spatial
output is likewise a loading relative to its raw coordinate covariance.

## 3a. Decisions and Rejected Alternatives

The q1 route reuses the scalar structured-field machinery because the native
likelihood and output map already have a q1 path. A new C++ likelihood or a
q2-only coefficient map would add mechanisms that this model does not need.
Existing q2 formulas stay supported; this slice does not reinterpret them.

## 4. Files Touched

The scoped paths are `R/drmTMB.R`, the new q1 test and example, the affected
Beta relmat/spatial q2 tests and examples, the pre-fit contract, this report,
and the local evidence directory. Existing q2 refusal assertions that
described q1 as unsupported were removed. Foreign dirty files were left in
place. No global capability map or shared ledger was promoted.

## 5. Checks Run

The pre-fit assembly check passed 13 assertions. The focused q1 test passed
in 53.34 seconds. The q1 plus affected q2 suite passed in 129.80 seconds:
56 q1, 64 relmat q2, and 47 spatial q2 success markers from the testthat
summary reporter, with zero reported failures, errors, warnings, or skips.
Both times were within the predeclared 100- and 240-second estimates. The
standalone example converged in 10.76 seconds and estimated the SD slope at
0.5086127 against simulated 0.5. These are single-seed point fits, not
coverage results. The targeted log states that zero live Julia tests ran.
`git diff --check` passed for the scoped changed source and tests.

## 6. Tests of the Tests

The fixed-seed generator uses 64 named groups and draws a named latent vector
from a non-unit-diagonal relatedness matrix or an independently computed
coordinate covariance. The test builds the Beta likelihood, analytic latent
score and Hessian, Gaussian prior constants, and Laplace correction without
package precision helpers. It checks two latent-mode starts, finite
differences, conditional predictor and likelihood against the fit. It also
checks K/Q equivalence, coordinate order, constant-SD versus baseline fits,
group-SD predictions, parameter tables, save/reload, and seeded conditional
simulation. The q1 assembly checks reject slope-only, labelled, extra-random,
sigma-random, and missing-response inputs. A controlled evaluation of the
verified extracted prior builder rejected both q1 formulas; its raw output is
`reconstructed-before.log`. The carried `red.log` is a retrospective narrative
and is not represented as raw prior stdout.

## 8. Consistency Audit

The independent oracle, R formula, and scalar TMB path describe the same q1
model. The q1 public output names are `sd_relmat(id)` and `sd_spatial(id)`;
the q2 coefficient names remain separate. I searched the status inventory
with `rg -n 'Beta.*(relmat|spatial)|relmat.*Beta|spatial.*Beta|sd_relmat\\(id\\)|sd_spatial\\(id\\)'`
across `README.md`, `docs/dev-log/internal-roadmap.md`, `NEWS.md`,
`docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`,
`vignettes/formula-grammar.Rmd`, and `_pkgdown.yml`. Broad public status and
pkgdown edits remain with the parent lane pending row-specific review. The
pre-fit contract is the scoped design record for this slice.

## Design-document updates

The pre-fit alignment document records the q1 likelihood, frozen seeds,
thresholds, three provider inputs, and the boundary that retains existing q2
support. The parent lane owns wider formula-grammar and capability-status
changes after review; this report makes no whole-family support claim.

## pkgdown and documentation updates

The new local example uses the accepted q1 formula and canonical
`sd_relmat(id)` output name. No pkgdown page or navigation changed in this
bounded slice. Public documentation should be updated with exact row scope
once the parent reviews the source-bound receipt.

## 7a. Issue Ledger

I read the open issue list with the search `Beta random SD`. It returned no
direct issue for these three rows. I made no issue change within this bounded
local task. The three candidate rows are native Beta `mu` relmat intercept
with `K_covariance`, native Beta `mu` relmat intercept with `Q_precision`, and
native Beta `mu` coordinate-spatial intercept. No row was promoted in the
shared capability ledger and no issue was posted.

## 9. What Did Not Go Smoothly

The carried fixture initially had formula symbols that did not resolve and a
latent vector without group names. Those were corrected before any production
fit. Independent review also found q2-style output keys in the new q1 tests;
the tests now assert the actual short q1 names. Both pre-fit contract copies
were corrected to keep supported q2 routes supported and to separate the two
runtime estimates.

## 11. Team Learning

For new structured SD rows, check formula environments, latent names, and
canonical output names at the assembly stage. A pre-fit review found all
three before they could be mistaken for model failures. Preserve raw command
logs separately from retrospective summaries.

## 10. Known Residuals

These results cover only complete-data native Beta q1 independent intercepts
with fixed-effect-only `sigma`. The spatial range is fixed by the supplied
coordinates; no unseen-site prediction, mesh, extra random layer, labelled
field, or multiple-slope claim follows. The focused test does not establish
interval calibration, broad recovery, or live Julia parity. The parent lane
can review the exact source manifest and three row receipts before updating
shared capability records or public documentation.

## 12. Cross-Product Coverage

This native Beta slice covers `mu` q1 structured intercepts with relmat K,
relmat Q, and coordinate spatial input; group SD prediction, parameter tables,
save/reload, and conditional simulation were checked. It does NOT cover `sigma`
structured endpoints, REML, penalties, missing data, mesh fields, extra random
effects, unused-site prediction, live Julia execution, profiles, bootstrap
intervals, or coverage calibration. These product axes remain separate gates.
