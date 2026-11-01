# After Task: Beta-binomial animal-pedigree SD simulation

## 1. Goal

Complete marginal simulation for the native Beta-binomial animal-pedigree location-intercept SD regression and record its supported boundary.

## 2. Implemented

The marginal simulation guard now admits the Beta-binomial family on its existing q1 structured-count route. The synthetic test checks two marginal draws, output dimensions, and that simulated successes remain between zero and the trial total. The fit test also checks coefficient recovery, group-named SD prediction, unmapped founder nodes, constant-SD likelihood equivalence, and rejection of an SD predictor that varies within animal.

The mathematical contract is `tau_g = exp(alpha_0 + alpha_1 * z_g)` and `b ~ N(0, D A D)`, where `A` is the existing additive relationship matrix and `D = diag(tau_g)`. The animal term enters the logit success-probability predictor. Beta-binomial `sigma` is fixed. Marginal simulation draws a new structured effect using the fitted SD design, then generates counts bounded by each trial total.

## 3a. Decisions and Rejected Alternatives

The change extends the existing count-family marginal simulation admission check for this one family. It does not alter the likelihood, pedigree kernel scaling, capability-universe denominator, or interval-calibration policy. The shared `R/methods.R` guard hunk was reviewed against its overlapping local diff before editing; unrelated changes in that file were preserved.

## 4. Files Touched

- `R/methods.R` and `tests/testthat/test-beta-binomial-animal-pedigree-sd-regression.R`.
- `NEWS.md`, `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, `docs/design/18-random-effect-scale-models.md`, `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`, `docs/dev-log/general-sd-regression/inventory.md`, `docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`, `vignettes/formula-grammar.Rmd`, and `vignettes/predictor-dependent-random-sd.Rmd`.
- `.unlazy/general-sd-regression/GATES.md`, `LOOP/lanes/general-sd-regression/checkpoint.md`, and `docs/dev-log/check-log.md`.
- `docs/dev-log/after-task/2026-10-20-beta-binomial-animal-sd.md`.

## 5. Checks Run

- Before the guard change, `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "beta-binomial-animal-pedigree-sd-regression", reporter = "summary")'` failed at the new simulation assertion with the explicit unsupported heteroscedastic-scale error.
- After the guard change, the same focused test command passed with no failures or skips.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^(beta-binomial|beta-binomial-sd-integration|beta-binomial-sd-slope-integration|beta-binomial-sd-slope|beta-binomial-animal-pedigree-sd-regression)$", reporter = "summary")'`: passed with no test failures or skips. The live Julia engine was not configured, so no Julia tests ran.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/predictor-dependent-random-sd.Rmd", output_file = "/private/tmp/predictor-dependent-random-sd-beta-binomial-animal-current.html", quiet = TRUE)'`: passed; only the existing Pandoc `--mathjax` deprecation warning appeared.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'pkgdown::check_pkgdown()'` passed with existing Pandoc `--mathml` deprecation warnings.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'pkgdown::build_site()'` stopped at the home-page build because the sandbox could not resolve `cloud.r-project.org`; Sass also reported a cache write permission warning. The focused vignette render and pkgdown check passed independently.
- `gh issue list --state open --search '"beta-binomial" "animal" in:title,body' --json number,title,url` returned issue #1243 about reciprocal tutorial links. Its body concerns cross-package links and remains unchanged. No issue was changed.
- `Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R"); print(check_after_task("docs/dev-log/after-task/2026-10-20-beta-binomial-animal-sd.md"))'`: passed (`TRUE`).
- `python3 "/Users/z3437171/Dropbox/Github Local/Shinichi/tools/slop_check.py" "/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression/docs/dev-log/after-task/2026-10-20-beta-binomial-animal-sd.md"`: passed with 1.4 phrase hits per 1,000 words and no em dashes.
- Scoped `git diff --check` across the touched tracked paths passed. Whole-worktree `git diff --check` also found a trailing blank line in `tests/testthat/test-binomial-sd-integration.R`, outside this slice and already dirty; that file was preserved.

## 6. Tests of the Tests

The new assertion was observed failing before the guard change for the expected reason. It exercises the public `simulate()` method and checks response dimensions and valid count bounds, so a guard-only change without a working structured draw would still fail.

## 7a. Issue Ledger

The open-issue search found only #1243, about missing reciprocal R-to-Julia tutorial links. Issue #1243 concerns companion links between packages and remains unchanged. No issue was opened, commented on, or closed.

## 8. Consistency Audit

The formula reference, likelihood table, random-effect-scale guide, formula-grammar vignette, predictor-dependent-SD tutorial, native family adapter map, capability inventory, roadmap, known limitations, and NEWS describe the same complete-data native pedigree route. They leave A/Ainv inputs, Julia parity, other structured providers, and interval calibration open. The 19,118-row universe and programme gates remain in their prior state.

Status inventory searched with:

```sh
rg -n -i -C 2 'Beta-binomial.*animal|animal.*Beta-binomial|beta.binomial.*animal|modelled.*random.effect scale' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/18-random-effect-scale-models.md docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md docs/dev-log/general-sd-regression/inventory.md vignettes/formula-grammar.Rmd vignettes/predictor-dependent-random-sd.Rmd
```

README status and `_pkgdown.yml` navigation were checked; neither needs an update for this family-row addition.

## 9. What Did Not Go Smoothly

The public-output check exposed a real omission in the marginal simulation admission guard after fitting and prediction already passed. The correction was one family admission, but it was easy to miss without testing simulation as a separate output surface. The whole-site build also depends on a network lookup that was unavailable in this environment.

## 10. Known Residuals

This is one native R/TMB cell: complete Beta-binomial responses, one q1 pedigree animal `mu` intercept, one fixed `sigma`, and one group-constant SD predictor. A/Ainv, other animal providers, other structured effects, additional random-effect targets, Julia support, profile/bootstrap routing, interval calibration, and broad family parity remain unverified. Programme gates G3, G4, and G6 receive partial evidence only and remain open. The broader goal is incomplete.

## 11. Team Learning

For every new direct-SD family/provider row, exercise `simulate()` explicitly. Successful fitting and SD prediction do not prove that marginal random-effect draws are admitted or scaled correctly.

## 12. Cross-Product Coverage

Covers: native R/TMB complete-data Beta-binomial `mu` q1 animal-pedigree intercept direct-SD regression with fixed `sigma`, one synthetic recovery fixture, group-SD prediction, founder mapping, constant-SD equivalence, within-animal predictor validation, and marginal simulation smoke checks.

Does NOT cover: A/Ainv, other animal providers, other structured effects, additional random-effect targets, Julia support or parity, profile/bootstrap routing, interval calibration, broad family parity, or completion of the general SD-regression goal.
