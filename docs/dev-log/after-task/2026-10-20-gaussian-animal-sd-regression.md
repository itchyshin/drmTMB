# After Task: Gaussian animal-model SD regression

## 1. Goal

Add one native TMB Gaussian location random-intercept route whose animal-model
standard deviation changes with a fixed predictor, then verify and document
the behavior without claiming Julia parity or interval calibration.

## 2. Implemented

The Gaussian builder now resolves `sd(id, level = "animal") ~ z` against a
q1 `animal(1 | id, A = A)` location intercept. The existing structured-scale
likelihood applies the fitted SD by latent node. Marginal simulation now
admits this Gaussian q1 structured route and redraws the animal effects using
the fitted group-specific SDs.

## 3a. Decisions and Rejected Alternatives

The slice reuses the existing structured q1 SD machinery. It adds no new
likelihood family or user-facing function. The tests cover supplied covariance
`A` and the equivalent precision input `Ainv = solve(A)`; pedigree input
remains outside this Gaussian slice.

### Mathematical Contract

For animal effects `b`, the model uses `b ~ Normal(0, D A D)` with
`D = diag(sd_g)` and `log(sd_g) = W_g alpha`. The supplied covariance matrix
retains its existing role. Gaussian residual `sigma` remains separate from
the animal-effect SD.

## 4. Files Touched

- `R/drmTMB.R`: admit the animal provider in Gaussian structured direct-SD
  target resolution.
- `R/methods.R`: allow marginal Gaussian simulation for the fitted q1
  structured SD route.
- `tests/testthat/test-gaussian-animal-sd-regression.R`: add the independent
  synthetic recovery, output, equivalence, persistence, simulation, and
  rejection checks.
- `vignettes/predictor-dependent-random-sd.Rmd`: add an independent Gaussian
  animal example and qualify its evidence.
- `docs/design/01-formula-grammar.md` and
  `docs/design/18-random-effect-scale-models.md`: record the exact route and
  its current evidence boundary.
- `docs/dev-log/check-log.md` and
  `.unlazy/general-sd-regression/GATES.md`: record the test, rendered example,
  and partial G3/G4/G6 evidence.

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "gaussian-animal-sd-regression", reporter = "summary")'` passed. The focused file reported 16 passing expectations. Equivalent `A` and `Ainv` fits agree in log likelihood, coefficients, and animal-named SD predictions. No live Julia engine was configured, so Julia parity was not exercised.
- The named Gaussian animal tutorial chunk fit from the current worktree, converged, and returned 64 animal-named SD predictions.
- `devtools::load_all(".", quiet = TRUE)` followed by `rmarkdown::render("vignettes/predictor-dependent-random-sd.Rmd", ...)` passed using this worktree. The verified output is `/private/tmp/gaussian-animal-vignette-worktree/predictor-dependent-random-sd.html`. Pandoc reported only its `--mathjax` deprecation notice.
- `pkgdown::check_pkgdown()` passed with no problems. Pandoc reported only the same deprecation notice.
- The G3, G4, and G6 ledger rows now include this evidence. The programme-wide gates remain open.

## 6. Tests of the Tests

Before the builder change, the focused test failed because Gaussian target
resolution rejected `sd(id, level = "animal")`. During repair, the test also
exposed that supplied covariance labels determine prediction order, so the
fixture now compares predictions by animal name. The tests verify the SD slope against planted truth, group-level predictions,
marginal simulation, save/reload, equality with the constant-SD Gaussian model,
and agreement between covariance and equivalent precision inputs. A
negative case confirms that an SD predictor varying within animal ID is
rejected. The added `Ainv` comparison passed on its first run, confirming the
existing precision-input path without requiring another production-code
change.

## 7a. Issue Ledger

Read-only searches for `repo:itchyshin/drmTMB "random-effect scale"` and
`repo:itchyshin/drmTMB "sd(id" animal` found no open issue specifically
tracking this Gaussian animal SD implementation. Issue #59 is a broader
simulation-programme issue, so no issue was changed.

## 8. Consistency Audit

The equation, formula, fit, prediction, and simulation describe the same
q1 animal intercept. The exact formula-grammar row, design note, tutorial, and
acceptance ledger now distinguish the native TMB supplied-`A`/`Ainv` route
from unverified Julia or interval claims. The status inventory search was
`rg -n -i 'Gaussian.*animal|animal.*Gaussian|animal.*SD|SD.*animal' README.md NEWS.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md`.
The README, NEWS, roadmap, and known-limitations files were reviewed for a
contradiction; their broad status wording remains compatible with this one
additional Gaussian route. No pkgdown navigation change was needed.

## 9. What Did Not Go Smoothly

The first attempt to retrieve the named knitr chunk used the wrong API and
returned no code. Extracting the named chunk from the R Markdown source then
ran it successfully. An initial full render loaded an installed package from
a different worktree and stopped at the earlier Bernoulli example; explicitly
loading this checkout before rendering resolved that source mismatch. The
shared lane-lease registry also required an authorized write outside the
repository before the documentation lease could be recorded.

## 10. Known Residuals

This evidence covers only a Gaussian q1 animal location intercept with
supplied covariance `A` or its equivalent precision `Ainv`, tested on the
same synthetic data. Pedigree input,
random slopes,
additional structured providers, other endpoints, and Julia parity were not
tested in this slice. The checks do not cover profile or bootstrap refitting
or interval calibration. Calibration remains a deferred programme phase.

## 11. Team Learning

Structured covariance labels and factor levels can use different valid
orders. Tests and user-facing predictions should therefore be aligned by
names rather than assuming matrix order equals factor order.

## Prose Assessment

**Style:** 2/10, medium confidence. **Genre/coverage:** technical after-task
report, read in full. **Evidence/repair:** the exact formula and named checks
make the claim easy to audit; no repair was needed after prose review.
**Gates:** science = pass for the stated q1 covariance contract, with broader
identifiability outside scope; facts = pass against the focused test, rendered
example, and check output; references = not applicable because this report
contains no literature citations. **Provenance:** self-review of this saved
draft, version `2026-10-20`, examples and test outputs were already seen.

## 12. Cross-Product Coverage

Continue the active general SD-regression goal with the next uncovered family
and effect rows. Keep the programme-wide G3, G4, and G6 gates open until their
full capability and output inventories are reconciled. This slice does NOT cover
Gaussian pedigree inputs, non-Gaussian animal routes, other
structured providers, random slopes, correlated or bivariate blocks, Julia
parity, profile/bootstrap refitting, or interval calibration. Add this route
to NEWS after the shared release-note path is safe to edit and the release
scope is ready for integration.
