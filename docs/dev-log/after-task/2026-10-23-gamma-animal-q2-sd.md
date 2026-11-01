# After Task: Gamma Animal Intercept-and-Slope SD Regression

## 1. Goal

Add a bounded native R/TMB Gamma route for predictor-dependent SDs on an
animal intercept and one independent numeric animal slope, with separate
coefficient selectors, recovery tests, identifiability guards, and matching
documentation.

## 2. Implemented

`animal(1 + x | id, pedigree = pedigree)` now accepts one SD formula per
coefficient, for example
`sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ z0` and
`sd(id, level = "animal", dpar = "mu", coef = "x") ~ z1`. The fields remain
independent and retain the existing pedigree covariance. The builder rejects
an identically zero slope loading and the exact confounded case where the
slope loading is globally constant and both SD designs are the same constant.

## Mathematical Contract

For independent `u0, u1 ~ N(0, A)`, the animal contribution to the Gamma
log-mean is `tau0_g * u0_g + x_i * tau1_g * u1_g`, with
`log(tau0_g) = W0_g alpha0` and `log(tau1_g) = W1_g alpha1`. Its covariance is
`A[g_i, g_j] * (tau0_gi * tau0_gj + x_i * x_j * tau1_gi * tau1_gj)`. This
does not add intercept-slope correlation or rescale the existing kernel.

## 3a. Decisions and Rejected Alternatives

Keep the documented independent-field interpretation. A single correlated
intercept/slope block would change the existing model. Keep the pedigree kernel
on its existing scale. Reject only the verified zero-loading and exact
constant-loading/constant-design confounding cases; broader confounding claims
are outside this slice.

## 4. Files Touched

- `R/drmTMB.R`: coefficient-target mapping and identifiability checks.
- `src/drmTMB.cpp`: coefficient-specific observation-to-SD-row mapping in
  Gamma's structured animal likelihood.
- `tests/testthat/test-gamma-animal-pedigree-sd-regression.R`: synthetic
  recovery, constant-SD equivalence, selector errors, predictions, simulation,
  save/reload, zero-loading, and exact confounding checks.
- `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, and
  `docs/design/18-random-effect-scale-models.md`: public syntax and model
  contract.
- `vignettes/predictor-dependent-random-sd.Rmd` and
  `vignettes/formula-grammar.Rmd`: worked example and status table.
- `README.md`, `NEWS.md`, `docs/dev-log/internal-roadmap.md`, and
  `docs/dev-log/known-limitations.md`: current status and limits.
- `docs/dev-log/check-log.md`: verification receipt.

## 5. Checks Run

- Test-first red run:
  `Rscript -e 'devtools::test(filter = "gamma-animal-pedigree-sd-regression", reporter = "progress")'`
  reported 2 failures and 35 passes. Both new identifiability assertions failed
  because the model fit instead of refusing the unsupported case.
- After the guard, the same focused command passed: 0 failures, 0 warnings,
  0 skips, 37 passes; test duration 29.6 seconds.
- Full guide render from the candidate source:
  `Rscript -e 'devtools::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/predictor-dependent-random-sd.Rmd", output_file = "/private/tmp/drmTMB-predictor-dependent-random-sd.html", quiet = TRUE)'`
  completed and emitted only the existing Pandoc `--mathjax` deprecation
  warning. The rendered file was checked for the new section and model
  interpretation.
- `Rscript -e 'pkgdown::check_pkgdown()'` completed with `No problems found.`
  Pandoc printed its existing `--mathml` deprecation warnings.
- Exact status inventory scan:
  `rg -n -i 'Gamma.*animal|animal.*Gamma|intercept-plus-independent-slope|coef = "\(Intercept\)"' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/18-random-effect-scale-models.md vignettes/formula-grammar.Rmd vignettes/predictor-dependent-random-sd.Rmd _pkgdown.yml`.
  The scan shows the narrow route and its limits in the README, roadmap,
  limitation register, grammar, likelihood/design notes, and both guides; the
  existing pkgdown navigation already links the worked example.
- Earlier q2-only snapshot hashes, before subsequent shared-file edits, were:
  `R/drmTMB.R` `adf066e0d9d6cdef105bc6db3fc366723ece9d62`, `src/drmTMB.cpp`
  `4b639239dea1538ea2ed5bef7ba2d59b21e6ad6f`, and focused test
  `6c061f900f81e6b38517320c357434107a760f94`. Those are historical q2-snapshot
  hashes, not the current live files.
- The final 37/37 rerun was against the following current files:
  `R/drmTMB.R` `c42afd967853eeaaa7147c7bbdc93b6b870ca37c`, `src/drmTMB.cpp`
  `6d2566288a9837a481cc71814c143b1e0fd76497`, and focused test
  `98a100552186416ad3ed07687d46c65503c2f0ac`. The R and C++ files contain
  concurrent broader general-SD edits; these are composite live-file hashes,
  not q2-only diffs. I preserved those edits. The focused test was rerun after
  observing the changed hashes and passed 37/37 in 28.6 seconds.
- Full package checks, pkgdown site build, interval-coverage calibration, and
  Julia runtime checks were not run for this slice.

## 6. Tests of the Tests

The two new malformed/weak-design assertions were observed failing before the
guard and passing after it. The recovery fixture independently simulates two
animal fields from the pedigree covariance and fixes the recovery thresholds
before fitting. The same fixture checks both coefficient-specific public
predictions and constant-SD equivalence.

## 8. Consistency Audit

The formula example, likelihood equation, and TMB coefficient-to-row map agree:
`coef = "(Intercept)"` scales the intercept field and `coef = "x"` scales the
independent slope field. The route uses a unit-diagonal pedigree fixture and
does not claim correlated slopes. The same audit leaves the separate Gamma q1
animal slope-only `A`/`Ainv` provider rows explicitly unverified.

| Symbol | Formula/TMB target | Synthetic generator | Public check | Truth |
|---|---|---|---|---|
| `alpha0[z0]` | `coef = "(Intercept)"`, row `z0` | `exp(log(0.35) + 0.45 * z0_id) * u0` | `coef()` and `predict(..., dpar = "sd")` for the intercept field | `0.45` |
| `alpha1[z1]` | `coef = "x"`, row `z1` | `exp(log(0.30) - 0.4 * z1_id) * u1`, loaded by `x` | `coef()` and `predict(..., dpar = "sd")` for the slope field | `-0.4` |

The test fixture also checks that replacing both SD designs by `~ 1` agrees
with the existing constant-SD fit. The covariance oracle for this slice is the
independent-field construction above and the constant-SD likelihood comparison;
a separate dense joint-Laplace likelihood oracle was not implemented.

## 7a. Issue Ledger

No issue was changed. The local `gh` executable is unavailable, so overlapping
open issues could not be searched from this lane. Check the repository's
connected GitHub issue surface before a larger programme closeout.

## 9. What Did Not Go Smoothly

The first article render attached an older installed package from another
worktree and failed before the Gamma examples. Explicitly loading this
candidate before rendering fixed the mismatch. One test run also spent several
minutes in silent setup before progress appeared; the subsequent warm runs
completed quickly. The repository graph refresh could not run because the
`graft` executable is unavailable in this shell (`command not found`).

## 11. Team Learning

Use an explicit `devtools::load_all('.')` when rendering a worktree vignette if
the installed package could come from a sibling checkout. Prefer the progress
reporter for long TMB tests so startup delay can be distinguished from fit
progress.

## 10. Known Residuals

This is one native, complete-data, unit-diagonal pedigree q2 recovery/workflow
slice. It does not establish interval coverage, Julia parity, or broad family,
provider, or random-effect parity. The separate Gamma q1 animal slope-only
`A`/`Ainv` provider rows remain unverified. Programme breadth G3 and uncertainty
gate G5 remain open.

## Design-Doc and pkgdown Updates

The grammar, likelihood, and random-effect-scale design notes plus the formula
grammar and predictor-dependent-SD vignettes were updated. `pkgdown::check_pkgdown()`
reported no problems; the worked vignette rendered from this candidate source.
The existing pkgdown navigation already links the article, so `_pkgdown.yml`
needed no change.

## 12. Cross-Product Coverage

This slice covers the native R/TMB Gamma animal intercept-plus-independent
numeric-slope route with a unit-diagonal pedigree covariance, including fitting,
coefficient-specific extraction/prediction, simulation, and save/reload. It does NOT cover other Gamma providers, Julia parity, interval coverage, other family
or random-effect rows, or full G3/G5 acceptance. The independent Gamma q1
animal slope-only `A`/`Ainv` rows remain unverified.

## Next Actions

Integrate only after the parent lane's review. Keep the Julia acceptance, other
Gamma provider rows, and G3/G5 evidence separate. No email, release, or public
publication action is part of this task.
