# After Task: Heterogeneous AR1 P3 closeout

## 1. Goal

Deliver `temporal(1 | id, time = occasion, structure = "hetar1")` for a Gaussian location model. The model gives each common discrete occasion its own temporal-process SD while retaining one AR1 persistence parameter and a separate, constant residual `sigma`. The public inference claim is limited to availability of fixed-mean Wald intervals for regular fits; it is not a coverage or standard-error-calibration claim.

## 2. Implemented

The fitted within-series covariance is `D R(phi) D + sigma^2 I`, where the diagonal of `D` contains labelled occasion-specific temporal-process SDs and `R(phi)[k,l] = phi^abs(t_k-t_l)`. The parser admits complete, equally spaced integer schedules with 3--12 common occasions and at least one odd raw lag. It preserves raw gaps, uses both signed persistence starts, and rejects an ordinary random intercept for this structure.

The S3 surface returns labelled process SDs, constant residual `sigma`, fitted values, residuals, seeded simulations, the fixed-mean covariance from the full observed Hessian, and Wald intervals when the Hessian is positive definite. Profiles and variance-, persistence-, and residual-scale intervals remain unavailable.

## 3a. Decisions and Rejected Alternatives

P3 implements heterogeneous **temporal-process** variation in the location model. It does not implement a time-varying residual scale, an ordinary random intercept, irregular-time OU, or the marginal Toeplitz parameterization. Those choices would answer different questions and need their own identification and validation evidence.

## 3b. Mathematical Contract

For series `i` and occasion `k`, `y_ik = x_ik^T beta + a_ik + e_ik`, with `Cov(a_ik, a_il) = s_k s_l phi^abs(t_k-t_l)` and `e_ik ~ N(0, sigma^2)`. Different series are independent. Equal `s_k` reduces exactly to AR1; `phi = 0` yields diagonal temporal-process covariance.

## 4. Files Touched

The implementation spans the temporal parser, layout, TMB provider, methods, tests and generated reference documentation. This closeout adds the final source-wording correction in `R/check.R` and `R/temporal.R`, retained final fixture outputs under `docs/dev-log/simulation-artifacts/2026-09-11-temporal-hetar1-interval-feasibility/`, and the P3 gate and check-log receipts. Earlier source revisions of the pilot and full outputs are retained in sibling `*-pre-81e5232-wording/` directories.

## 5. Checks Run

- `T4-1` through `T4-5` passed: grammar/layout, native D-R-D likelihood, independent dense likelihood/score/two-step Hessian comparison, public methods, and reduction/mutation checks.
- The refreshed final-source pilot retained 5 fixtures, 10 signed-start attempts and 15/15 finite fixed-mean Wald rows. Its median selected-fit time was 2.507 seconds and maximum was 5.693 seconds.
- The refreshed full panel retained 20 fixtures, 40 signed-start attempts and 60/60 finite fixed-mean Wald rows. Its median selected-fit time was 2.3705 seconds and maximum was 5.467 seconds.
- `T4-6`, `T4-7` and `T4-11 --reverify` passed from source `81e5232ef75cf24f1af07fda8f025f2f764c4da7` with runner hash `582452e5c3c85d9f48915a07d623a7ab`. Reverification read retained outputs and launched no fits.
- `T4-12` rendered the reader workflow and verified that its visible boundary distinguishes finite fit-level intervals from coverage and scale-side claims.
- `R CMD build` and `R CMD check --no-manual` completed from the final source. The check had two established source-layout warnings because vignette sources are present without installed `inst/doc` outputs; installation, R code, examples, tests and vignette rebuild otherwise passed.
- The after-task structure validator passed. Its repository-wide ledger recheck correctly remains open because the parent temporal programme includes later, unstarted structures; P3 itself is closed by the checked T4 ledger.

## 6. Tests of the Tests

The deterministic oracle independently builds the dense `D R D + sigma^2 I` covariance and checks likelihood, score and Hessian at two finite-difference steps. It also detects equal-SD and `phi = 0` reductions, raw-gap compression, shared series states, omitted normalizers, omitted residual scale and a mutated `D` factor. A public covariance test initially failed only because the raw TMB matrix and public matrix used different dimnames; numeric values agreed. The expectation now compares the intended numeric block rather than names.

## 8. Consistency Audit

The following inventory scan was run before closeout:

```sh
rg -n -i "hetar1.*(pending|remain unavailable|not yet qualified)|P3 interval-feasibility evidence.*(complete|pending)|interval-feasibility fixtures have not yet" README.md NEWS.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md vignettes/formula-grammar.Rmd vignettes/temporal-random-effects.Rmd _pkgdown.yml R man tests
```

It found only the intended statement that fixed-mean Wald intervals are available while profile and variance-parameter intervals are unavailable. The review-discovered stale profile wording and internal status comment were fixed before the final evidence refresh.

## 7a. Issue Ledger

`gh issue list --state open --search temporal --limit 50` found one matching open issue: #1302, “Feature: phylogenetically correlated temporal OU series.” No issue was opened, edited or closed during P3. It is the next, separate phylogenetic OU arc.

## 9. What Did Not Go Smoothly

The first full interval export had missing optional reported SEs because of a CSV covariance-label mismatch; those outputs remain retained under `full-reporter-error-20260911/`. A corrected runner used the same frozen fixtures, seeds, likelihood and selection rule. Independent reader review then found stale user-facing wording and an undefined example helper. The final source refresh corrected both and retained every earlier output.

## 11. Team Learning

Noether's independent review found the D-R-D covariance, raw integer gaps, parameter transforms, reductions and fixed-mean Hessian boundary consistent. Pat's reader review made the public interface clearer by requiring explicit regular-panel construction, usable parser hints, and an unambiguous distinction between available fixed-mean Wald intervals and unavailable profile/variance intervals. This is a useful pattern for later covariance structures.

## 10. Known Residuals

P3 has no coverage calibration, empirical SE calibration, confidence intervals for variance components, persistence or `sigma`, likelihood profiles, forecasting, `newdata` prediction, irregular schedules, ordinary random intercepts, or scale-side temporal effects. Its feasibility fixtures are not evidence that Wald intervals achieve nominal coverage.

## 12. Cross-Product Coverage

This arc does NOT cover temporal structures in `sigma`, ordinary random intercepts, `REML = TRUE`, missing-response fitting, the optional Julia engine, forecasting, or `newdata` prediction. It covers only native Gaussian maximum-likelihood location fits with the admitted complete regular panel and one `hetar1` term. The fixed-mean Wald path was checked through extraction, `vcov()`, `confint()`, summary diagnostics and simulation; it does NOT qualify profiles, variance/persistence/residual-scale intervals, coverage, or reported-SE calibration.

## Next Actions

Close P3 with `T4-14 --reverify`, release its lease, and begin the distinct phylogenetic OU design/implementation arc attached to issue #1302. Do not infer support for a temporal OU process, a spatial OU process, or temporal effects in `sigma` from this phylogenetic covariance work.
