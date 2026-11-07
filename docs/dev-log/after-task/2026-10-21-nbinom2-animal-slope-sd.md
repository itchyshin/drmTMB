# After Task: NB2 Animal Slope-Only SD Regression

## 1. Goal

Add predictor-dependent SD regression for one NB2 animal-model location slope,
using a group-level predictor and complete data.

## 2. Implemented

NB2 now admits one q1 slope-only animal coefficient through
`animal(0 + x | id, pedigree = pedigree)` with fixed `sigma ~ 1` and
`sd(id, level = "animal") ~ z`. The existing structured field scaling already
handled a single coefficient; this slice removed the NB2 admission block and
parser restriction that had required an intercept. No TMB likelihood changes
were needed.

## 3a. Decisions and Rejected Alternatives

Keep this slice to one structured coefficient. The existing q1 scale path
already applies the group-specific SD correctly, so a new likelihood branch
would add risk without changing the model. A multi-coefficient animal block is
not admitted because it needs coefficient-specific scale indexing and
covariance tests.

### Mathematical Contract

For animal coefficient (b_i), the model uses
\(\log(\tau_i)=W_i\alpha\) and \(\operatorname{Cov}(b)=D A D\), where
\(D=\operatorname{diag}(\tau_i)\) and `A` is the supplied pedigree
relationship matrix. The SD predictor must be constant within each animal.
The existing relationship-matrix scaling and NB2 overdispersion parameter
`sigma` are unchanged.

## 4. Files Touched

- `R/drmTMB.R`: admit NB2 slope-only animal terms and permit single-coefficient
  structured SD targets.
- `src/drmTMB.cpp`: align the defensive structured-target error with the
  single-coefficient limit.
- `tests/testthat/test-nbinom2-animal-slope-sd-regression.R`: add a seeded
  synthetic DGP and recovery, prediction, equivalence, and invalid-design checks.
- `R/random-effect-scale-formulas.R` and
  `man/random_effect_scale_formulas.Rd`: describe the supported route.
- `docs/design/01-formula-grammar.md`,
  `docs/design/18-random-effect-scale-models.md`,
  `docs/dev-log/general-sd-regression/inventory.md`,
  `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`,
  `docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`,
  `vignettes/formula-grammar.Rmd`, and `NEWS.md`: align support claims and
  limitations.
- `docs/dev-log/check-log.md`: record exact checks and outcomes.

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "nbinom2-animal-slope-sd-regression", reporter = "summary")'`
  passed with 9 assertions, including the tightened absolute log-SD-slope
  recovery tolerance of 0.25.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "nbinom2-animal-sd-regression|nbinom2-animal-slope-sd-regression|beta-animal-pedigree-sd-regression|poisson-animal-sd-regression", reporter = "summary")'`
  passed: NB2 intercept 9, NB2 slope-only 9, Beta animal 12, and Poisson
  animal 13 expectations. No live Julia engine tests ran.
- `Rscript -e 'devtools::document()'` passed and regenerated the help page.
- `Rscript -e 'pkgdown::check_pkgdown()'` passed with no problems; existing
  Pandoc `--mathml` deprecation warnings remain.
- An independent read-only implementation review confirmed the recovery
  threshold, defensive C++ message, and support boundaries in the formula
  grammar, family inventory, and adapter map.
- `Rscript ~/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-10-21-nbinom2-animal-slope-sd.md`
  passed the report-structure check. Its programme acceptance-ledger check
  reports 11 broader gates still unmet, so the overall goal remains active.
- `pkgdown::build_site()` failed before rendering articles because cdnjs could
  not be resolved for `headroom.min.js`. Redirecting the Sass cache to
  `/private/tmp` resolved the initial protected-cache failure but did not
  restore network access.
- `git diff --check` reported pre-existing blank lines at EOF in the programme
  checkpoint, check log, and an unrelated binomial integration test. Those
  unrelated files were not edited to clean them up.

## 6. Tests of the Tests

The new test failed before the fix because NB2 rejected the q1 animal slope-only
term. After enabling that term, it failed again at the explicit parser guard
that only allowed an intercept. The final test passes the seeded fit, recovery
tolerance for the log-SD slope, exact prediction mapping by animal name,
constant-SD likelihood equivalence, and within-animal predictor rejection.

## 8. Consistency Audit

The implementation, generated help, design contract, formula grammar table,
family support vignette, inventory, adapter map, roadmap, limitations, and NEWS now describe the same
NB2 animal slope-only boundary. The model has one structured coefficient and
does not imply support for an intercept-plus-slope animal block. The exact
support inventory scan was:

```sh
rg -n -i "animal.*(random )?slopes?.*(not|planned|defer|unsupported)|((random )?slopes?).*animal.*(not|planned|defer|unsupported)|NB2.*animal|animal.*NB2" README.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/dev-log/general-sd-regression/inventory.md docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

The support inventory surfaces were inspected: README status, internal
roadmap, NEWS, known limitations, formula grammar, formula-grammar vignette,
the active family inventory and adapter map, and `_pkgdown.yml`. Navigation
did not change. The live Julia engine did not
run, and this slice does not establish interval calibration.

## 7a. Issue Ledger

Open-issue searches for `animal random slope SD NB2`, `animal SD`, and
`random-effect scale` found no issue specifically tracking this implementation
slice. The tracker was left unchanged.

## 9. What Did Not Go Smoothly

The first test exposed a missing NB2 admission flag, then the next run exposed
the parser's intercept-only assumption. The full pkgdown site could not be
rendered because the environment could not resolve its cdnjs dependency.

## 11. Team Learning

Structured SD scaling already operates on the single coefficient in a q1
structured term, including a slope-only coefficient. Future family/provider
admissions should test that existing path before adding family-specific
likelihood code. Multi-coefficient structured blocks still require a separate
covariance and target-indexing design.

## 10. Known Residuals

This is native R/TMB point-recovery evidence for one complete-data NB2 animal
slope-only term with fixed `sigma`. It does not cover ordinary random effects
combined with the animal field, zero inflation, random `sigma`, multi-coefficient
animal blocks, Julia execution/parity, or calibrated uncertainty. The active
programme still requires calibrated uncertainty for overall completion.

Continue the native family/provider inventory, coordinate any Julia edits with
the active DRM.jl lane, and keep calibration as a required later programme
gate. Do not treat this slice as whole-goal completion.

## 12. Cross-Product Coverage

The native R/TMB fit, prediction, and simulation interfaces retain the animal
group identity for this q1 route. The live Julia engine was not exercised, so
this work does not establish DRM.jl implementation or cross-engine parity. This
slice does NOT cover Julia execution, other providers, multi-coefficient animal
blocks, or interval calibration.

### Prose Assessment

Genre: technical after-task report. Coverage: this full report, reviewed
against the focused test output, documentation checks, issue-search results,
and current implementation scope. Perceived AI-like style: 2/10, with medium
confidence; the prose uses concrete syntax and check results, and follows the
required report sections. Scientific and factual gates: pass for this bounded
slice. Reference gate: not applicable because no external literature claims
are made. Method: self-review under the writing-naturalness protocol and the
project prose-style checklist, 2026-10-21. No prose score establishes
authorship.
