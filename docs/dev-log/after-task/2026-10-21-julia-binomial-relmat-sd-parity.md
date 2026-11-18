# Julia bridge for Binomial relatedness-matrix SD regression

## 1. Goal

Carry one existing native Binomial `relmat()` location-intercept SD regression
through the R-to-Julia bridge and confirm point-fit behavior against native TMB
on identical synthetic observations.

## 2. Implemented

The bridge admits one complete-response Binomial `relmat(1 | id, K = K)` term
for `mu` with its matching `sd(id, level = "relmat") ~ z` formula. It carries
the target through formula translation, coefficient names, `sdpars`, and
group-level prediction. The route excludes additional random-effect terms,
other structured providers, random slopes, and additional SD targets.

The overlapping-ref review also found two definitions of
`drm_julia_rhs_is_intercept_only()`. The shadowing copy was removed, and a
source-count and formula-semantics regression test now protects the shared
definition.

The Julia result is limited to the paired local DRM.jl development checkout.
The current shared or released DRM.jl build does not yet contain this route.

## 3. Mathematical contract

For group `g`, the latent intercept has covariance `D K D`, with
`D[g,g] = exp(W_g alpha)`. Labelled covariance matrices are aligned to the
group first-seen order before marshalling; unlabelled matrices must already
follow that order. The parity fixture deliberately permutes labelled `K` and
uses a unit diagonal kernel, so the SD multiplier equals the marginal group
SD. No kernel normalization or Bernoulli residual SD is added.

## 3a. Decisions and Rejected Alternatives

The existing `sd()` interface and target selectors are sufficient; this slice
does not add a new public modelling function. The bridge admits only the exact
single-term Binomial `relmat()` SD shape tested here. It aligns labelled K/A
matrices but does not normalize their covariance or claim released Julia
support.

## 4. Files Touched

- `R/julia-bridge.R`: exact Binomial `relmat()` SD admission and translation,
  extraction, and prediction routing; labelled K/A alignment; removal of the
  duplicate intercept-only helper.
- `tests/testthat/test-julia-binomial-relmat-sd-parity.R`: target and rejection
  checks plus a same-data live TMB/Julia synthetic fit.
- `tests/testthat/test-julia-structured.R`: family-gate expectation and scoped
  route comment.
- `tests/testthat/test-julia-structured-dimnames.R`: labelled K/A alignment,
  missing-group refusal, and unlabelled positional behavior.
- `tests/testthat/test-julia-rhs-intercept-only.R`: duplicate-definition and
  intercept-semantics regression tests.
- `NEWS.md`, `docs/design/01-formula-grammar.md`,
  `docs/dev-log/known-limitations.md`, `vignettes/formula-grammar.Rmd`,
  `vignettes/model-map.Rmd`, and `vignettes/julia-engine.Rmd`: support boundary
  and synthetic example.
- `docs/dev-log/check-log.d/2026-10-21-julia-binomial-relmat-sd-parity.md`,
  this report, `LOOP/lanes/general-sd-regression/checkpoint.md`, and the
  programme gate ledger: verification record and stale-status correction.

## 5. Checks Run

- Live bridge command:
  `PATH=/Users/z3437171/.juliaup/bin:$PATH JULIA_DEPOT_PATH=/private/tmp/drmtmb-sd-julia-depot:/Users/z3437171/.julia DRM_JL_JULIA_HOME=/Users/z3437171/.juliaup/bin DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' NOT_CRAN=true Rscript -e 'devtools::load_all(".", quiet=TRUE); testthat::test_file("tests/testthat/test-julia-binomial-relmat-sd-parity.R", reporter="summary")'` passed. The output reported 14 mapping assertions and one live Julia bridge test, with no failures.
- The combined rerun of `test-julia-rhs-intercept-only.R`,
  `test-julia-binomial-relmat-sd-parity.R`, and
  `test-julia-zero-one-beta-sd.R` passed; it exercised one Binomial and two
  ZeroOneBeta live Julia bridge tests. The helper test passed five assertions.
  Before removing the duplicate, its source-count assertion failed as intended
  (`actual: 2`, `expected: 1`).
- After changing the Binomial fixture to deliberately permute the labelled K
  matrix, the live same-data Julia/TMB parity test passed again.
- The new structured-dimnames test initially failed all three intended
  alignment/error checks before the bridge change, then passed all five
  assertions after labelled K/A alignment was added.
- Current-source vignette renders passed to `/private/tmp/formula-grammar-20261021-binomial-relmat.html`, `/private/tmp/julia-engine-20261021-binomial-relmat.html`, and `/private/tmp/model-map-20261021-binomial-relmat.html`.
- The neighbouring `test-julia-structured.R` suite passed its mock-driven checks; its existing live Poisson `relmat()` case was skipped because no Julia path was set for that command.
- `Rscript -e 'pkgdown::check_pkgdown()'` passed with “No problems found.” Pandoc emitted its existing deprecated `--mathml` option warning.
- `git diff --check` on the selected source, test, and documentation paths passed.
- The programme gate checker reported UNKNOWN because its Node gate runner is unavailable; no programme-wide gate is claimed as passed.
- Source pins: drmTMB candidate `425bee81572c625a634b2b083050c5c57c1dc1f1`; paired DRM.jl candidate `70dbf564eb670144c63c08f61ea099084d95add2`.
- Current worktree SHA-256 values: bridge `ab85280f678cafc4b7ddcddeb7750b0810a1807e5f8e87899e52b57914e262f1`, Binomial parity test `b2f1459d00f24576c1a840186780d2b40190c3abc3b85e59c2725ed6d699c5b9`, matrix-order test `21bddfb060a35fb947693a96aeb4a45526f2630653eb510ba90dd1002b38634a`, duplicate-helper test `47c7996900d1ab39a38fe02326aced7f33e851feb3b7ad2bedb72424b1844e4d`.

## 6. Tests of the Tests

The focused test checks the exact route predicate, formula and target mapping,
expected coefficient labels, extracted SD parameters, prediction target, and
rejection of mismatched or unsupported formula shapes. Its live fit compares
both engines on the same synthetic response and checks fit status, point
estimates, log likelihood, recovery direction, target-specific group SDs, and
prediction consistency using deliberately permuted labelled `K`. The matrix
test detects silent positional misalignment, missing group labels, and
unlabelled positional behavior. The duplicate-helper test first failed on two
definitions and passed after removal, while formula-semantics cases protect the
shared function. These checks demonstrate one point-parity cell only.

## 7a. Issue Ledger

Open issue #1283 concerns Binomial `relmat()` support and the DRM.jl route. The
issue tracker was left unchanged; no comment, duplicate issue, or public claim
was made.

## 8. Consistency Audit

The formula grammar, formula-grammar and model-map vignettes, Julia-engine
vignette, NEWS, and known-limitations entry describe the route as a narrow local development
candidate. They state that confidence-interval calibration, other Binomial
structured providers, and current shared/released DRM.jl support are not
established. Labelled K/A matrices are reordered to group first-appearance
order; unlabelled matrices use positional first-appearance order. The fixture
uses a unit-diagonal kernel with deliberately permuted labels. The stale checkpoint claim that Julia
ZeroOneBeta supported only the intercept was corrected after checking its
live bridge test and candidate-source pin. The exact status scan was:

```sh
rg -n -i 'Binomial.*(relmat|structured)|relmat.*Binomial|Julia.*relmat|align.*labelled|first-appearance' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/julia-engine.Rmd vignettes/model-map.Rmd tests/testthat/test-julia-structured.R
```

## 9. What Did Not Go Smoothly

The first live bridge attempt exposed a Julia echo-label mismatch: the direct
SD result is named `sd`, not `resd`. The bridge now preserves that name. A
second test exposed an assertion that used drmTMB's composite convergence
helper even though the native optimizer converged and its Hessian was positive
definite; the check now tests the optimizer code and Hessian directly. The
overlap audit then found a duplicate shared intercept helper; its test failed
red before the shadowing copy was removed. The final tests passed. JuliaCall
needed a writable temporary depot because the default compiled-cache path was
unavailable in the sandbox.

## 10. Known Residuals

This does not establish interval coverage, reliable Wald intervals, profile
or bootstrap behavior, arbitrary matrix-name reordering, broader structured
effects, broad engine parity, or current shared/released DRM.jl support. The
programme ledger remains open, including G3 and G6. Coverage validation remains
deferred by the user's direction. Next, continue the capability inventory and
implement the next missing, bounded cross-engine row after ownership review.

## 11. Team Learning

Structured bridge rows should test target identity across admission, formula
translation, engine output, and prediction. A point-parity test should also
document kernel scaling and matrix-order assumptions so an apparently matching
fit cannot conceal a different covariance convention.

## 12. Cross-Product Coverage

**Covers:** one complete-data Binomial `relmat()` q1 location intercept with
one matching predictor-dependent SD formula; target translation, coefficient
naming, `sdpars`, group-level prediction, and one synthetic point-parity fit
against native TMB in the paired local DRM.jl candidate.

**Does not cover:** interval calibration; profile or bootstrap refits; other
Binomial providers or slopes; arbitrary covariance ordering; general engine
parity; shared/released DRM.jl support; completion of G3 or G6; or the broader
general SD programme.

### Prose assessment

NOTASSESSED. Run the required prose naturalness and project style checks before
this report is treated as fully closed.
