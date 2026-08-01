# After Task: Arc 6 Association Eta Uncertainty

## 1. Goal

Expose bounded latent-association uncertainty from the already implemented
two-stage Godambe alpha covariance without widening the fitted association
model, launching compute, or claiming new coverage calibration.

## 2. Implemented

`confint(assoc, type = "eta")` now returns the transformed pointwise interval
for every intercept-only admitted pair association whose stored alpha
covariance passes its fit-specific diagnostics.

`predict(assoc, newdata = ..., type = "eta", se.fit = TRUE, interval =
"confidence")` now returns row-specific bounded eta estimates, delta-method
standard errors, and pointwise confidence limits. The existing `"response"`
prediction type remains an alias for `"eta"`; point prediction without
uncertainty preserves its historical numeric return. New-data prediction
remains limited to the Bernoulli x ordinary-NB2 fixed-effect association
formula. Other pair classes can report their constant fitted-row eta and its
uncertainty but do not accept a new association design.

A covariate-varying association has no single eta parameter. Consequently,
`confint(type = "eta")` gives an actionable error directing the user to
row-specific `predict(..., newdata = ...)` rather than silently choosing a
design row.

## 3a. Decisions and Rejected Alternatives

The eta confidence limits transform the link-scale Wald endpoints. A symmetric
eta-scale interval was rejected because it can ignore the nonlinear shape and
bounded range. A new bootstrap, profile, or coverage campaign was rejected for
this slice because eta is a deterministic monotone transformation of the
existing alpha estimator; such methods remain separate future estimators.

The public eta standard error uses the delta method. `vcov(assoc)` remains an
alpha-coefficient covariance because a covariate-varying eta is a row-specific
derived estimand, not a coefficient vector with one universal covariance
matrix.

## 3b. Mathematical Contract

For design row \(x_i^\top\), alpha coefficients \(\boldsymbol\alpha\), and
guard \(c=0.999999\),

\[
 a_i=x_i^\top\boldsymbol\alpha,
 \qquad \eta_i=c\tanh(a_i).
\]

Given the stored two-stage Godambe covariance \(\widehat V_\alpha\),

\[
 \widehat{\mathrm{SE}}(\hat a_i)
 =\sqrt{x_i^\top\widehat V_\alpha x_i},
 \qquad
 \widehat{\mathrm{SE}}(\hat\eta_i)
 =c\{1-\tanh^2(\hat a_i)\}
  \widehat{\mathrm{SE}}(\hat a_i).
\]

For link-scale limits \((L_{a,i},U_{a,i})\), the eta interval is
\((c\tanh L_{a,i},c\tanh U_{a,i})\). Code, equations, tests, Roxygen, and the
three public articles use this same contract.

## 4. Files Touched

- `R/associate-pairs.R`: eta prediction and confidence-interval API.
- `R/associate-pairs-sandwich.R`: actionable covariance-failure guidance.
- `tests/testthat/test-associate-pairs-*.R`: independent delta calculation,
  transformed endpoints, all-pair integration, new-data regression, invalid
  arguments, varying-association guidance, and unavailable covariance.
- `man/*.Rd`, `vignettes/cross-family.Rmd`,
  `vignettes/bivariate-nongaussian.Rmd`, and
  `vignettes/capability-and-limits.Rmd`: public syntax and interpretation.
- `docs/design/01-formula-grammar.md`, `03-likelihoods.md`, and Arc 6 design
  notes 230, 231, 232, 236, 239, and 240: current symbolic and scope contract.
- `NEWS.md` and `docs/dev-log/known-limitations.md`: release-facing capability
  and remaining exclusions.

## 5. Checks Run

- Focused implementation tests for the Bernoulli x NB2 regression, staged
  sandwich, and all-pair integration: PASS.
- Focused snapshot and interface tests for Bernoulli x Bernoulli and Gaussian
  x Bernoulli: PASS after retaining their established new-data error wording.
- Complete `associate-pairs` test family: first run found only two expected
  message snapshots; the final full rerun is recorded in the check log.
- `devtools::document()`: PASS for the touched Roxygen pages.
- Full `pkgdown::build_site(new_process = FALSE)`: PASS after granting the
  build access to CRAN metadata and the standard R cache.
- `pkgdown::check_pkgdown()`: PASS, no problems found.
- Capability ledger: 46 unit tests PASS and all 30 generated outputs current.
- `git diff --check`: PASS.

## 6. Tests of the Tests

The first focused run failed because a vector was compared to a one-row matrix,
showing that the test retained output shape rather than accepting values alone.
The complete association suite then caught two changed error-message snapshots;
the code restored the established wording because this slice did not need to
change that behavior.

The regression test independently computes
`sqrt(rowSums((X %*% V_alpha) * X))`, applies the eta derivative, and transforms
the two link endpoints. Integration tests repeat the transformed-endpoint
identity for all five admitted pair classes. Failure tests cover invalid
levels, invalid `se.fit`, varying-association misuse, unavailable covariance,
and boundary-unresolved fits.

## 7a. Issue Ledger

No matching open issue was identified during the parent alpha-interval audit.
This implementation remains part of the same focused Arc 6 association PR; no
duplicate issue was opened.

## 8. Consistency Audit

The stale-source scan covered `R`, `NEWS.md`, current design documents,
known limitations, vignettes, Roxygen output, and the rebuilt pkgdown site for
`eta-scale intervals`, `eta intervals remain unavailable`, `point-only`
association prediction, and old alpha-only help. Current reader surfaces now
distinguish alpha coefficient covariance from bounded eta derived uncertainty.

The Arc 6 overview and early pair contracts retain their historical sequence
but now carry explicit supersession/current-capability wording. The formula
grammar uses the exact guarded transform `0.999999 * tanh()`. The function map,
rho12 article, staged-association article, error/convergence guide, and
location-scale-scale navigation repaired by the parent slice remain intact.

## 9. What Did Not Go Smoothly

The initial full pkgdown build failed because the sandbox blocked CRAN metadata
DNS and the normal R cache. The identical build passed with explicit local and
network permission. Roxygen also surfaced unrelated generated-manual drift for
`drmTMB.Rd` and `zero_one_beta.Rd`; those files are excluded from this focused
eta change unless separately authorized.

Pat identified that a constant-association `predict()` example would print one
identical result per fitted row. The quick workflows now use
`confint(type = "eta")`; row-specific `predict()` is demonstrated only with an
association regression and explicit `newdata`.

## 10. Known Residuals

The eta intervals are pointwise transformed Godambe-Wald intervals. They are
not simultaneous bands, profile intervals, bootstrap intervals, or a new
coverage campaign. They inherit the underlying alpha route's tier and warning.

Only Bernoulli x ordinary-NB2 admits a covariate-varying association formula
and new-data association design. Random or structured association effects,
incomplete pairs, offsets, weights, REML, Julia fitting, and generic family
pairs remain outside the contract.

## 11. Team Learning

Fisher passed the derivative, endpoint transformation, evidence inheritance,
and failure boundary. Pat's review changed the learning path so constant and
varying association uncertainty are not visually conflated. Rose found early
contract notes and generated pkgdown pages that would otherwise have preserved
the old point-only story; the full-site rebuild and supersession notes close
that gap.

## 12. Cross-Product Coverage

This slice covers derived eta uncertainty for the five admitted intercept-only
pair classes and for the admitted Bernoulli x ordinary-NB2 fixed-effect
association regression. It does NOT cover a new family-pair likelihood,
association random effects, missing-pair handling, simultaneous confidence
bands, profiles, bootstrap, new calibration, public `rho12` reinterpretation,
or a capability-tier promotion beyond the underlying alpha evidence.

## 13. Next Actions

1. Open the focused association public-interval PR after final tests, rendered
   stale scans, review closure, and maintainer approval of the preview.
2. Calibrate additional exact pair routes or association-regression designs in
   later compute-approved campaigns; promote only the cells supported by their
   retained evidence.
3. Consider simultaneous eta bands or an explicit bootstrap only as separate
   estimators with their own design and validation.
