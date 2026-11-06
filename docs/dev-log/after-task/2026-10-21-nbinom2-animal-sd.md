# After Task: NB2 animal-model SD regression

## 1. Goal

Add and test a bounded native TMB NB2 route for a predictor-dependent standard
deviation on one animal-model location intercept.

## 2. Implemented

The NB2 builder now accepts one complete-data q1 animal location intercept
with `sd(id, level = "animal") ~ z`. It resolves the animal SD design,
passes group-row mappings into TMB, scales the latent animal field by its
group-specific SD, and uses the standard-normal precision penalty for the
unscaled latent field. The existing scalar-SD NB2 branch is retained when no
SD formula is supplied.

## 3a. Decisions and Rejected Alternatives

The first implementation is limited to one q1 animal location intercept. The
builder rejects combinations with ordinary random effects, zero inflation,
random slopes, correlated blocks, and random `sigma` effects. Broadening those
combinations without their own likelihood and recovery tests would exceed this
slice.

### Mathematical Contract

For the animal latent field, this route uses `b = D u`, where
`D = diag(exp(W alpha))` and `u ~ Normal(0, A)`. Equivalently,
`Cov(b) = D A D`. The NB2 `sigma` remains the observation-level overdispersion
parameter. The predictor `z` must be constant within animal. This slice uses
the existing pedigree-derived animal covariance and does not change its
scaling.

## 4. Files Touched

- `R/drmTMB.R`: admit and validate the animal SD formula in the NB2 builder;
  pass its design and observation-to-animal mapping through the TMB data
  assembly.
- `src/drmTMB.cpp`: evaluate group SDs and scale the animal field in model type
  7; use the unit-covariance latent penalty for this route and retain the old
  scalar-SD penalty otherwise.
- `tests/testthat/test-nbinom2-animal-sd-regression.R`: add an independent
  synthetic pedigree recovery, prediction, constant-SD equivalence, and
  within-animal-variation rejection test.
- `vignettes/predictor-dependent-random-sd.Rmd`,
  `vignettes/formula-grammar.Rmd`, and `docs/design/01-formula-grammar.md`:
  document the exact supported route and limits.
- `NEWS.md`, `docs/dev-log/known-limitations.md`,
  `docs/design/18-random-effect-scale-models.md`,
  `docs/dev-log/internal-roadmap.md`,
  `docs/dev-log/check-log.md`, `.unlazy/general-sd-regression/GATES.md`, and
  `LOOP/lanes/general-sd-regression/checkpoint.md`: record the capability and
  evidence boundary.

## 5. Checks Run

- Before the builder change, the focused test failed because NB2 rejected
  `sd_animal(id)`. After the R and TMB wiring, the focused command
  `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e
  'devtools::test(filter = "nbinom2-animal-sd-regression", reporter =
  "summary")'` passed all nine expectations.
- The broader command
  `devtools::test(filter =
  "nbinom2|student-location-scale|animal-sd-regression")` completed but had
  eight failures: two NB2 structured-recovery thresholds, two Poisson animal
  prediction-order checks, and four Student-t start errors. Seven Julia bridge
  tests skipped because no Julia engine was configured. The run also reported
  two existing zero-inflated NB2 clamp warnings. These are unresolved and are
  not counted as passes for this slice.
- The vignette first rendered against a different installed checkout and
  failed at an earlier Bernoulli example. After loading this worktree with
  `devtools::load_all(".", quiet = TRUE)`, the full
  `predictor-dependent-random-sd.Rmd` render passed. Its output is
  `vignettes/predictor-dependent-random-sd.html`; Pandoc reported its existing
  MathJax option deprecation.
- `devtools::load_all(".", quiet = TRUE)` followed by
  `pkgdown::check_pkgdown()` passed with no problems. Pandoc reported its
  existing MathML option deprecation.
- `check-after-task.R` passed the report-structure check, then returned
  nonzero because the programme ledger still has the root gate and ten
  independent capability gates open. That is consistent with this being one
  partial row in the active goal; no gate was marked complete or abandoned.
- `git diff --check -- src/drmTMB.cpp R/drmTMB.R
  tests/testthat/test-nbinom2-animal-sd-regression.R` passed before the final
  documentation and ledger edits. A final full changed-path whitespace check
  remains part of closeout.

## 6. Tests of the Tests

The initial red test exercised the public formula and failed at the intended
NB2 admission guard. The passing fit checks planted SD-slope recovery and
animal-named predictions. The constant formula matches the existing scalar
animal-SD model by log likelihood. A negative case changes `z` for one row of
an animal and confirms that the builder rejects the inconsistent group-level
predictor.

## 7a. Issue Ledger

Read-only searches with `gh issue list --repo itchyshin/drmTMB --state open
--search 'NB2 animal SD'` and `--search '"sd_animal" NB2'` found no directly
matching open issue. No issue was changed.

## 8. Consistency Audit

The TMB code scales the latent animal field and uses the corresponding
unit-covariance precision penalty, which matches the documented `D A D`
covariance. The user example uses the supported `animal()` and `sd()` syntax.
Status searches covered the README, roadmap, NEWS, known limitations, formula
grammar, random-effect-scale guide, and both relevant vignettes with
`rg -n -i 'NB2.*structured|structured.*NB2|nbinom2.*animal|animal.*nbinom2|structured effects' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`.
The public status remains explicitly partial. No navigation change was needed.

## 9. What Did Not Go Smoothly

The first TMB patch matched a similar structured-effect block in the Student-t
branch. A source check caught this before the focused fit; the Student-t block
was restored and the NB2 logic was moved under `model_type == 7`. The first R
classification patch also matched the earlier Tweedie builder; that unrelated
change was reverted, and the NB2 classification was applied at its named
builder. The first full vignette render loaded another checkout; explicitly
loading the current worktree fixed the source selection.

## 10. Known Residuals

This evidence covers one native TMB NB2 animal q1 location intercept with a
pedigree-derived covariance. It does not establish covariance-matrix or
precision-matrix inputs, Julia parity, interval calibration, profiling,
bootstrap refits, simulation semantics, mixed ordinary and structured random
effects, random slopes, correlated blocks, zero inflation, or a random `sigma`
effect. G3, G4, and G6 receive partial evidence only; the programme gates remain
open. The eight broader-test failures remain unresolved. The next action is to
triage those failures in their owning slices, then continue with another
uncovered family/provider row. Keep this NB2 animal row restricted to the exact
tested formula until covariance and workflow extensions receive their own
evidence.

## 11. Team Learning

Several likelihood branches share nearly identical structured-effect code.
When editing one branch, anchor patches on its explicit `model_type` and verify
the diff in the neighboring family branches before compiling. Full vignettes
must load the intended source checkout before they are used as implementation
evidence.

## Prose Assessment

Style review: 2/10 AI-like style, medium confidence. The report names the exact
model, tests, and boundaries. Scientific and factual claims match the focused
test and render; no external references are used. The automated slop check
found 0 hits per 1,000 words, with no em dashes. The after-task structure check
passed.

## 12. Cross-Product Coverage

This slice adds one native NB2 animal-provider row to the larger
general predictor-dependent random-effect SD goal. It does not establish Julia
parity, general structured-effect support, or programme completion.
It does NOT cover matrix-input animals, Julia, other structured providers,
random slopes, correlated blocks, simulation, persistence/refitting, or
interval calibration.
