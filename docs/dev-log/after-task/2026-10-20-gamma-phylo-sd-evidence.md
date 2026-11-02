# After Task: Gamma phylogenetic direct-SD test and example

## 1. Goal

Record and verify the existing native Gamma q1 phylogenetic location-intercept route with a predictor-dependent latent SD. The general SD-regression programme remains active.

## 2. Implemented

No production likelihood code changed. A new synthetic test exercises the Gamma phylogenetic direct-SD route, named tip-level predictions, and equivalence of an explicit constant-SD formula to the existing scalar model. The random-SD vignette now includes a separate synthetic Gamma phylogenetic example. The family registry, formula grammar, design note, NEWS, roadmap, limitations, worked-example inventory, and programme checkpoint describe this as one native point-fit row.

## 3a. Decisions and Rejected Alternatives

For tip `l`, the tested model uses `tau_l = exp(W_l alpha)` and `a = D_tau u`, where `u ~ MVN(0, A)` and therefore `Cov(a) = D_tau A D_tau`. The SD predictor is constant within species. The example uses `sigma ~ 1`; this keeps the Gamma response coefficient of variation at an intercept-only model and does not normalize or otherwise change the supplied phylogenetic covariance.

## 4. Files Touched

- `tests/testthat/test-gamma-phylo-sd-regression.R`
- `vignettes/predictor-dependent-random-sd.Rmd`
- `vignettes/formula-grammar.Rmd`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/design/37-worked-example-inventory.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/internal-roadmap.md`
- `NEWS.md`
- `.unlazy/general-sd-regression/GATES.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "gamma-phylo-sd-regression")'`: 11 passed, no failures, warnings, or skips; no live Julia test ran.
- `devtools::load_all(".", quiet = TRUE)` followed by a namespace-path assertion and `rmarkdown::render("vignettes/predictor-dependent-random-sd.Rmd", output_file = "/tmp/predictor-dependent-random-sd-gamma-phylo.html", quiet = TRUE)`: passed using this worktree's package. Pandoc emitted its deprecated `--mathjax` option warning.
- `devtools::load_all(".", quiet = TRUE); pkgdown::check_pkgdown()`: passed with no pkgdown problems; Pandoc emitted deprecated `--mathml` option warnings.
- `git diff --check` on the focused test, all changed user-facing Gamma capability documents, the check log, and the continuation checkpoint: passed after the final edits.
- `rg -n "Gamma phylogenetic direct-SD|Gamma q1 phylo|gamma-phylo-sd"` across the family/status documents, formula guide, random-SD vignette, and `_pkgdown.yml`: confirmed the route is listed with its point-fit boundary; the existing pkgdown navigation already includes the vignette.
- `python3 /Users/z3437171/shinichi-brain/tools/slop_check.py` on this report, the random-SD vignette, and `NEWS.md`: 0 findings for each file. The NEWS scan reports one pre-existing em dash in older text, but zero findings overall.
- `Rscript -e 'source("/Users/z3437171/shinichi-brain/tools/check-after-task.R"); check_after_task("docs/dev-log/after-task/2026-10-20-gamma-phylo-sd-evidence.md")'`: required report structure passed. The programme ledger remains open and was not reverified as part of this partial slice.

## 6. Tests of the Tests

The route already fit before this test was added, so there was no production fix to demonstrate with a red test. The test combines the direct-SD surface with an existing phylogenetic Gamma location effect and checks seeded positive-trend point recovery, the named SD predictions, and likelihood equivalence between the constant-SD direct formula and the scalar-SD model. It passed 11 assertions. This is one seeded test and not repeated-recovery or interval-calibration evidence.

## 7a. Issue Ledger

Searched open issues in `itchyshin/drmTMB` for “Gamma phylogenetic direct SD” and “predictor-dependent random-effect SD structured”. The first query returned no issues; the second returned unrelated issue #3. No issue comment, issue creation, or closure was needed for this documentation-and-test slice.

## 8. Consistency Audit

The family registry, both formula guides, random-effect scale design, known-limitations note, roadmap, NEWS, worked-example inventory, rendered vignette, programme gates, and checkpoint now state one native Gamma q1 phylogenetic direct-SD point-fit row. No general Gamma structured-SD support, interval calibration, or Julia parity is claimed. The first render used an installed package from another worktree and stopped at the existing Bernoulli example; explicitly loading this worktree and verifying its namespace path resolved the mismatch before the successful render.

## 9. What Did Not Go Smoothly

The vignette's initial render attached an installed `drmTMB` from a different worktree, so it failed before reaching the new Gamma example. Loading the current package with `devtools::load_all()` and asserting the namespace path corrected the environment selection. The successful render still reports the existing Pandoc MathJax deprecation.

## 11. Team Learning

For a rendered package article in a multi-worktree development setup, load the exact worktree package and verify the namespace path before interpreting an example failure as a code regression.

## 10. Known Residuals

This route is native TMB only and covers one q1 phylogenetic `mu` intercept with complete responses and intercept-only `sigma`. The test does not cover animal, relatedness, spatial, phylogenetic slopes, multiple structured providers, simulation, save/reload, profile or bootstrap refits, Julia, or interval calibration. G3, G4, G6, G7, and G8 remain open; G5 coverage is deferred.

## 12. Cross-Product Coverage

This slice does NOT cover Gamma animal or relatedness parity beyond the separate animal test, Gamma spatial effects, phylogenetic slopes, multiple structured providers, response simulation, save/reload, profile or bootstrap refits, Julia, or interval calibration. Continue with the next unevidenced family-provider row in the active capability inventory, and coordinate Julia changes through the DRM.jl lane. Keep interval calibration deferred under the revised finish line.
