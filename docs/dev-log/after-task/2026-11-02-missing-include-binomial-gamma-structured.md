# After-task note: missing responses kept for Binomial ordinary SD and Gamma structured SD

Date: 2026-11-02. Branch: codex/general-sd-regression (private copy, no lane commit).

## What was asked

Admit `miss_control(response = "include")` for (1) Binomial and Bernoulli ordinary `mu` SD regression, and (2) Gamma structured SD routes (animal, relmat, phylo, spatial intercept with SD formulas). Probe what refuses, admit where the C++ already masks missing responses, and test against independent oracles.

## Probe results

Binomial ordinary SD regression (`bf(y ~ x + (1 | id), sd(id) ~ w)`, intercept and independent slope, Bernoulli and `cbind()` responses) was already accepted under include. No R guard fires for it, and the C++ Binomial branch (model_type 18) guards every density with `observed_y(i) == 1`. The gap was evidence, not code. The probe also showed that a Binomial relmat intercept with an SD formula, a probit link and a crossed pair of random intercepts already fit under include. Those three were not tested here and have no oracle (see open items). Binomial correlated (`(1 + x | id)`) SD regression is refused with "requires complete responses" and stays so.

Gamma structured SD regression was refused for all four providers by one builder guard in `drm_build_gamma_ls_spec()`. The C++ Gamma branch (model_type 5) masks each density per row, and the field prior does not depend on the response, so the guard was the only obstacle.

## Source edits (R/drmTMB.R, man/drmTMB.Rd)

1. The Gamma include refusal now lets through exactly one shape: SD formulas only on one unlabelled q1 structured intercept (animal, relmat, phylo or spatial), with no ordinary mu random effect, no sigma random effect, and no ordinary or sigma SD formula. Everything else keeps the old refusal, whose hint text now also names the structured intercept.
2. The `missing` argument documentation names Binomial and the Gamma structured intercepts. The Rd file was edited by hand to match, not regenerated.

Nothing in `src/` changed.

## Evidence (tests/testthat/test-binomial-gamma-sd-missing-include.R, new file)

Binomial: Bernoulli and six-trial `cbind()` responses, each with a random intercept and a random slope, 80 groups of 16 rows, shuffled row and level order, 90 random missing responses plus one group with no observed response. Gamma structured: four providers, 30 groups of 12 rows, Toeplitz K with diagonal 1.7 and reversed object order for animal and relmat, `cov2cor(ape::vcv(tree))` for phylo, irregular random coordinates for spatial.

- Include equals complete-case: log-likelihood within 1e-8, coefficients within 1e-6, observed-row predictions within 1e-6.
- Independent oracles at the fitted parameters, within 1e-4: a per-group scalar Laplace oracle for Binomial, and a dense Newton and log det(I + K W) oracle over the full latent vector for Gamma. Neither uses drmTMB code. The spatial kernel is built by hand as exp(-d / median positive distance) plus 1e-6 on the diagonal.
- Sensitivity: scoring masked rows as placeholder responses, dropping the SD slope, and (relmat, animal) converting K to a correlation matrix each move the oracle by more than 0.05.
- Whole group missing (Gamma layout B): the oracle keeps the empty group inside the latent vector. For relmat and animal the complete-case fit (rows dropped) still agrees to 1e-8, and an oracle on the kernel with that group removed agrees to 1e-6, as marginalisation requires. For spatial the empty site stays in the prior: the fit matches the 30-site oracle within 1e-4 and differs from an oracle that re-derives the kernel from 29 sites by more than 5e-4 (measured about 0.0015).
- Predictions for masked rows: finite, one per input row. Binomial masked rows and the empty group sit on the fixed-effect line, and `newdata` rows with a missing response get population-level values. For Gamma structured with an empty group, predicted linear predictors equal the oracle's conditional mode within 1e-4 and differ from the fixed-effect line (the empty group borrows from relatives). `predict(dpar = <SD>)` is name-aligned for every group, including the empty one.
- Constant SD under include equals the plain random-effect fit within 1e-5 and the complete-case fit within 1e-8.
- Refusal pins with message patterns: Binomial correlated SD; Gamma sigma-target SD, structured slope-only, labelled structured q2, structured SD beside an ordinary random intercept, and ordinary SD beside a structured intercept.

One pre-declared bar was revised after the first run, and nothing else. The spatial empty-group contrast was declared as "oracle values differ by more than 0.01"; the measurement was 0.0015 because the range shifts by only a few percent. It was replaced by "fit-versus-29-site-oracle difference above 5e-4, with fit-versus-30-site-oracle agreement within 1e-4". No agreement tolerance was changed and no assertion was deleted from the new file. Two earlier failures in the same first run were test-code errors (formula construction through `as.formula()` inside `bf()`), fixed without changing any bar.

Optimiser warnings ("NA/NaN function evaluation") appear on both the include and the complete-case fit of the same Gamma structured case, so they are not specific to masking.

## Existing test edited

`tests/testthat/test-nb2-gamma-sd-missing-include.R` pinned a refusal of Gamma relmat q1 SD regression under include, which is now admitted. The pin now runs for NB2 only, with a comment pointing to the new file. This removes one `expect_error` (114 expectations before, 113 after, all passing). That file has no row in `direct-sd-evidence.tsv`, so it is not a receipted file. No receipted test file was edited.

## Runs (Totoro, cores 4-7, NOT_CRAN=true, `pkgload::load_all`)

- New file: 242 passed, 0 failed, 0 errors, 0 skipped.
- Neighbours, all 0 failed and 0 errors: nb2-gamma include 113; gamma iid-structured 114; ordinary-beside-structured 55; structured-slope 87; mu-sigma-joint 26; animal-pedigree 37; relmat 11; phylo 15; spatial 11 (1 skipped, environment); missing-data capability gate 11; missing-data control 23; structured-sd-nonunit-k-and-missing 53; poisson include 37; binomial sd integration 366; binomial ordinary phylo 18; missing-response binomial 27 and continuous 181; guard-branch continuity 87; gamma sd regression 17, batch3 21, batch4 30, integration 23.

## Not covered

No recovery, coverage, calibration or Julia parity claim; one fixture seed per case. Binomial non-logit links, Binomial structured providers under include, and `mi()` predictors were not tested. Gamma structured slope, q2, labelled, ordinary-beside-structured and sigma-target routes stay refused. The capability registry, the vignettes and `direct-sd-evidence.tsv` were not touched, so the new test file has no evidence row or receipt yet.
