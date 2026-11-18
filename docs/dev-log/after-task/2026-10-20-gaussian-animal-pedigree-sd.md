# After Task: Gaussian animal pedigree SD regression

## 1. Goal

Verify whether a Gaussian animal-model location intercept accepts a predictor-
dependent SD when users supply a pedigree, then retain the result as a test and
documentation evidence.

## 2. Implemented

The existing native TMB route fits `sd(id, level = "animal") ~ z` with
`animal(1 | id, pedigree = pedigree)`. No production source change was needed.
A deterministic synthetic test observes offspring while leaving their sires
and dams unobserved in the response data. It checks slope recovery, observed-
animal SD predictions, marginal simulation, and constant-SD likelihood
equivalence.

## 3a. Decisions and Rejected Alternatives

The test uses the existing animal pedigree interface and retains its latent
founders. It does not build a separate covariance adapter or change the
likelihood. The synthetic covariance is generated from the pedigree relationship
matrix, while the fitted model receives the pedigree table.

### Mathematical Contract

For the pedigree relationship matrix `A` and animal SD design rows `W_g`, the
fitted covariance is `D A D`, with `log(sd_g) = W_g alpha`. Sires and dams
without observations remain latent nodes in `A`; predictions are requested only
for animals observed in the response data.

## 4. Files Touched

- `tests/testthat/test-gaussian-animal-sd-regression.R`: add a deterministic
  pedigree fixture and fit test with unobserved founders.
- `docs/design/18-random-effect-scale-models.md`: document pedigree input and
  the exact evidence boundary.
- `.unlazy/general-sd-regression/GATES.md`: add partial G3/G4 evidence and
  retain programme gates as open.
- `docs/dev-log/check-log.md`: record the discovered existing route and test.
- This report and its exact-draft assessment record the bounded slice.

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "gaussian-animal-sd-regression", reporter = "summary")'` passed with 25 expectations. The three pedigree fits converged; the SD slope recovered within the predeclared 0.25 tolerance.
- The pedigree fixture includes 40 observed offspring and 20 unobserved parents. Predictions are checked by offspring name.
- `pkgdown::check_pkgdown()` found no problems; Pandoc printed only the existing `--mathml` deprecation notice.
- This test did not run Julia, profile or bootstrap refits, or interval calibration.

## 6. Tests of the Tests

A small exploratory fit using offspring-only observations converged and
recovered the planted positive SD trend before the permanent test was added.
The permanent fixture uses more families and checks the same result along with
prediction, simulation, and the constant-SD limit. The focused test also
retains the separate `A` versus `Ainv` equivalence test from the preceding
Gaussian slice.

## 7a. Issue Ledger

Read-only issue searches for random-effect scale and Gaussian animal SD found
no open issue specifically tracking the pedigree input for this route. No issue
was changed.

## 8. Consistency Audit

The test's DGP, pedigree formula, SD formula, and predictions use the same
animal identifiers and relationship matrix. The design note distinguishes
pedigree input from the earlier `A`/`Ainv` equivalence evidence. The broader
formula and family ledgers remain incomplete, and this result does not close a
programme gate.

## 9. What Did Not Go Smoothly

The source-file lane preflight flagged many historical refs on shared builder
and log paths. No builder edit was needed. The test path had no divergent-ref
work; the design and check-log changes were screened for this specific Gaussian
animal-pedigree topic before editing.

## 10. Known Residuals

This is one native Gaussian q1 animal location-intercept route. The test does
not establish pedigree-builder behavior for every malformed or large pedigree,
other animal effect shapes, Julia parity, profile/bootstrap refitting, or
interval calibration. The complete family, effect, provider, and engine
universe remains outstanding.

## 11. Team Learning

When a structured family already accepts multiple provider inputs, test the
existing providers independently before adding builder branches. This route
already handled pedigree input; the missing evidence was the Gaussian
predictor-dependent-SD case with founders absent from the observation data.

## Prose Assessment

**Style:** 2/10, medium confidence. **Genre/coverage:** technical after-task
report, read in full. **Evidence/repair:** concrete formulae and named checks
make the scope auditable; no repair was needed after review. **Gates:** science
= pass for the stated `D A D` contract; facts = pass against the focused test;
references = not applicable because this report makes no literature claims.
**Provenance:** self-review of this saved draft, version `2026-10-20`.

## 12. Cross-Product Coverage

The general SD-regression goal remains active. This slice does NOT cover
Gaussian animal slopes, other structured effects, other response families,
Julia parity, profile/bootstrap refitting, or interval calibration. Continue
with an uncovered family/effect/backend row; keep G3, G4, G5, G6, G7, and G8
open until their required evidence is independently reconciled.
