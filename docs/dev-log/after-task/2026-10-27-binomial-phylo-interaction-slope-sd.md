# After Task: Binomial phylogenetic-interaction slope SD

## 1. Goal

Implement one predictor-dependent SD route for a Binomial random slope on a two-partner phylogenetic interaction, through native TMB and the development Julia bridge.

## 2. Implemented

The supported term is `phylo_interaction(0 + x | plant:pollinator, ...)` with `sd(pair, level = "phylogenetic_interaction", coef = "x") ~ z`. The pair-level SD multiplies the existing interaction covariance, and the observation-level loading remains `x`. The pair identifier must map one-to-one to the observed partner pairs, and each SD predictor must be constant within pair. Native and Julia tests cover recovery, target-named predictions, and marginal simulation. The bridge converts the observed pair covariance to a related-matrix route while preserving the public interaction target.

## 3a. Decisions and Rejected Alternatives

The slice admits one slope-only coefficient in one q1 interaction field. Intercept-plus-slope blocks and additive partner-main effects remain outside this delivery. Existing kernel scaling is preserved. No predictor centering or scaling is added.

Assumptions made without asking: the pair column represents exactly the observed partner pairs, and the selected SD coefficient is the interaction slope `x`. If either assumption is false, target resolution or the fit must refuse the model rather than average or reorder inconsistent rows.

## 4. Files Touched

- `R/parse-formula.R`
- `R/drmTMB.R`
- `R/methods.R`
- `R/julia-bridge.R`
- `R/julia-simulate.R`
- `tests/testthat/test-binomial-phylo-interaction-slope-sd.R`
- `tests/testthat/test-julia-binomial-phylo-interaction-slope-sd-bridge.R`
- `NEWS.md`
- `README.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/internal-roadmap.md`
- `docs/design/01-formula-grammar.md`
- `vignettes/formula-grammar.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/general-sd-regression/mechanism-templates.tsv`
- `docs/dev-log/general-sd-regression/required-rows.tsv`
- `docs/dev-log/general-sd-regression/required-universe.md`
- `tools/general-sd-regression/universe.py`
- `tools/general-sd-regression/tests/test_universe.py`
- `docs/dev-log/after-task/2026-10-27-binomial-phylo-interaction-slope-sd.md`
- Paired development checkout: `../general-sd-julia/src/binomial_sd_regression.jl`
- Paired development checkout: `../general-sd-julia/src/inference.jl`
- Paired development checkout: `../general-sd-julia/test/test_binomial_phylo_interaction_slope_sd.jl`
- Paired development checkout: `../general-sd-julia/docs/src/families.md`

## 5. Checks Run

- `PATH="/Users/z3437171/.juliaup/bin:$PATH" DRMODELS_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter = "binomial-phylo-interaction-slope-sd", reporter = "summary", stop_on_failure = TRUE)'`: passed. The native test produced nine passing checks. One live Julia bridge test ran and completed, with native-to-Julia fitting and simulation checks passing.
- `JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. test/test_binomial_phylo_interaction_slope_sd.jl`: focused run passed 14/14 checks on Totoro with Julia 1.10.10, including a test that failed before fixing the marginal simulator's missing random-slope loading.
- The direct Julia test was extended to logit, probit, and cloglog with link-matched synthetic data; all three passed 14/14 checks locally on Julia 1.10.12. The native Bernoulli spatial intercept and slope fixtures also passed 42 focused expectations across all three links.
- `python3 tools/general-sd-regression/universe.py` regenerated 19,230 required rows; `python3 -m unittest discover -s tools/general-sd-regression/tests -p 'test_universe.py'` passed 18 tests. The denominator now names `phylo_interaction_numeric_slope` explicitly for both engines and all three Binomial links. The three Julia interaction-slope link rows are admitted based on the matching direct-fit tests; this exception does not admit other structured non-logit rows.
- A follow-up local live bridge run reached JuliaCall with Julia 1.10.12 but was stopped after exceeding its two-minute estimate; it provides no new bridge verdict. The earlier live bridge pass recorded above remains separate evidence.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems. The installed pkgdown emitted existing MathML option deprecation warnings.
- `JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia +1.10.12 --project=docs docs/make.jl`: started doctests and markdown rendering but was stopped after more than seven minutes of first-time Makie/Julia dependency compilation; no full Julia docs-build verdict.
- `python3 ~/shinichi-brain/tools/slop_check.py <exact after-task report> <exact Julia family guide>`: zero findings for both saved files.
- `git diff --check` on the scoped implementation, test, and documentation paths: passed.
- `rg -n "phylo_interaction|phylogenetic_interaction|Binomial.*interaction|binary/Bernoulli.*interaction" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`: reviewed the current capability wording and navigation. The older NEWS entry at line 3821 is historical release text and remains unchanged.

## 6. Tests of the Tests

The native test-first fixture initially failed at the parser's intercept-only restriction, before the implementation change. The passing tests exercise target selection, coefficient recovery, pair-name prediction, marginal simulation, and refusals for invalid pair mapping, within-pair SD predictors, and a zero loading. The Julia test also checks pair covariance ordering against its independently constructed fixture. Its simulator regression compares the zero-slope-loading draw with an independently constructed fixed-mean draw, proving that the observation-level loading is applied.

## 7a. Issue Ledger

`gh issue list --state open --search 'phylo_interaction Binomial SD slope' --limit 10` returned no matching open issue. No issue was opened, updated, or closed.

## 8. Consistency Audit

Updated the current NEWS summary, README scope row, roadmap, and known-limitations text to state that the Binomial interaction route is slope-only and point-checked. The formula grammar and vignette already describe the selected slope coefficient and pair-constant SD design. No pkgdown navigation change was needed. Historical NEWS was retained as a record of its earlier state.

Memory receipt: `route.py` returned no LOAD-FIRST manifest for the current repository, and the Graft command was unavailable. A keyword-only read of `WHAT-WORKS.md` found the existing warning to treat comparator evidence as partial and route-specific. The Golden Set was not run because this slice did not touch a known-mistake class covered by it.

## 9. What Did Not Go Smoothly

The lane preflight could not identify the current runtime and treated all platforms as foreign. The user had already assigned this SD lane to us. The shared closeout generator resolved the task path against the Shinichi hub repository and produced a template containing unrelated hub paths. I removed that mis-scoped file and wrote this report in the drmTMB worktree.

## 10. Known Residuals

This is one Binomial structured-slope cell, not broad family or provider parity. It does not cover interaction intercepts with predictor-dependent SDs, intercept-plus-slope blocks, additive partner-main effects, interval calibration, or released DRM.jl support. The full package suite, `R CMD check`, and a rendered site build were not run.

## 11. Team Learning

Keep the public target identity intact when converting a structured covariance to a related-matrix representation for Julia. Document the exact coefficient, covariance route, and engine boundary beside the recovery evidence.

## 12. Cross-Product Coverage

- Covers: native TMB fitting, coefficient recovery, group-level SD prediction, and marginal simulation for one q1 Binomial phylogenetic-interaction slope.
- Covers: the paired development Julia fit and R bridge for logit, probit, and cloglog, with target identity retained and seeded same-engine marginal simulation checks.
- Does NOT cover: other Binomial interaction shapes, other response families or providers, broad cross-engine parity, uncertainty calibration, or released DRM.jl support.

## Next Actions

Continue from the capability matrix with the next unimplemented family/provider cell. Coordinate any R-to-Julia bridge edits with the active parity lane before changing shared bridge paths.
