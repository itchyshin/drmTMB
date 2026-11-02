# After Task: Binomial animal-slope SD bridge

## 1. Goal

Close the logit Binomial animal slope SD route through native TMB and the development Julia bridge, and keep the native animal-plus-IID admission boundary consistent with its existing recovery tests.

## 2. Implemented

The Julia Binomial structured-SD builder now accepts an omitted coefficient selector when its admitted route identifies one animal slope. An explicit nonmatching coefficient still fails. The native animal-plus-IID gate continues to admit animal intercept combinations, and admits an animal slope plus one ordinary IID intercept when the IID term has its matching SD formula. It rejects the same slope model when that IID term has no matching SD formula.

The public example is `animal(0 + x | id, A = A)` with `sd(id, level = "animal") ~ z`. The bridge retains the public `sd_animal(id)` target and simulates the animal contribution using the observation-level slope loading.

## 3a. Decisions and Rejected Alternatives

The model has one q1 animal slope, so the bridge resolves its coefficient from the fitted formula rather than requiring a redundant `coef = "x"` selector. The native mixed animal-plus-IID route is kept only under its tested matching-SD condition. I rejected restricting all animal-plus-IID models to intercepts because an existing synthetic recovery test covers the slope combination.

Assumptions made without asking: the supplied test uses the default logit link and the pair of development checkouts. If the intended scope includes non-logit animal slopes or Julia animal-plus-IID parity, those are separate unfinished cells.

## 4. Files Touched

- `R/drmTMB.R`
- `../general-sd-julia/src/binomial_sd_regression.jl`
- `NEWS.md`
- `README.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/internal-roadmap.md`
- `docs/design/01-formula-grammar.md`
- `vignettes/formula-grammar.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-27-binomial-animal-slope-sd-bridge.md`

The exercised fixtures were already present in this candidate: `tests/testthat/test-binomial-animal-slope-sd-regression.R`, `tests/testthat/test-binomial-animal-iid-sd-regression.R`, and `tests/testthat/test-julia-binomial-animal-sd-regression.R`.

## 5. Checks Run

- Final combined command: `PATH="/Users/z3437171/.juliaup/bin:$PATH" DRMODELS_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter = "binomial-animal-slope-sd-regression|binomial-animal-iid-sd-regression|julia-binomial-animal-sd-regression", reporter = "summary", stop_on_failure = TRUE)'`: passed. Both native test files passed, and two live Julia bridge tests ran.
- The live bridge fixture checked animal-slope recovery in TMB and Julia, group-level SD prediction, seeded Julia marginal simulation against an independent draw construction, plus the adjacent animal-intercept `Ainv` route.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems. Pkgdown emitted existing MathML option deprecation warnings.
- Scoped `git diff --check` in both drmTMB and the paired Julia worktree: passed.
- Status inventory search: `rg -n "phylo_interaction|phylogenetic_interaction|Binomial.*animal|animal.*Binomial|Bernoulli.*animal|animal.*Bernoulli" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`. Current docs now distinguish the Julia animal-slope route from native-only animal-plus-IID support. Historical NEWS remains unchanged.
- `gh issue list --state open --search 'Binomial animal slope SD' --limit 10` returned two unrelated issues (general test sweep and Phase 18); no matching issue was updated or closed.

## 6. Tests of the Tests

The first live run exposed the Julia target mismatch because the formula omitted a coefficient selector for its unique slope. A native negative assertion also exposed an overly broad animal-plus-IID gate. Narrowing that gate to animal intercepts then broke the existing positive animal-slope-plus-IID recovery fixture. The final predicate and combined rerun demonstrate both required behaviors: the existing mixed slope route passes when both SD targets are present, and the unmatched IID case is refused.

## 7a. Issue Ledger

No matching open GitHub issue was found in the bounded search. No issue was opened, commented on, or closed.

## 8. Consistency Audit

Updated the current README, NEWS, roadmap, known-limitations, formula-grammar, and formula-grammar vignette entries. They distinguish native TMB support for one animal slope plus IID intercept from the Julia bridge's animal-slope-only route via supplied `A`. The same pages keep interval calibration deferred. No navigation change was needed.

Memory receipt: `route.py` returned no LOAD-FIRST manifest for this checkout, and the Graft CLI was unavailable. I used a keyword-only read of the `WHAT-WORKS.md` partial-comparator guidance. The Golden Set was not run because the change did not match a known-mistake class covered by that set.

## 9. What Did Not Go Smoothly

The first narrow native-gate edit accidentally excluded a previously implemented animal-slope-plus-IID case. The adjacent recovery test caught this immediately; I changed the gate to preserve that route only when the IID SD formula is present, then reran both native fixtures and the live Julia bridge tests.

## 10. Known Residuals

The Julia bridge check covers a logit animal slope with supplied `A`. It does not establish Julia animal-slope parity for pedigree or `Ainv`, or Julia parity for the mixed animal-plus-IID model. Non-logit animal slopes, interval calibration, the full test suite, `R CMD check`, and a rendered site build remain unverified.

## 11. Team Learning

When tightening an admission gate, run the newest positive neighboring fixture as well as the test that requested the refusal. A later supported slice can make an older negative assertion stale or reveal that the true boundary is a required companion SD formula.

## 12. Cross-Product Coverage

- Covers: native TMB logit Binomial animal-slope SD regression, one animal slope plus one IID intercept with both matching SD formulas, coefficient recovery, group-level SD prediction, and save/reload checks from the retained fixture.
- Covers: the development Julia bridge for one logit animal slope using supplied `A`, with same-data point checks, public target naming, prediction, and seeded marginal simulation.
- Does NOT cover: Julia animal-slope pedigree or `Ainv` parity, Julia animal-plus-IID parity, other links or families, interval calibration, or release support in the shared DRM.jl package.

## Next Actions

Continue the capability inventory at the next unimplemented family/effect/provider cell, and coordinate bridge ownership with the parity lane before changing shared routes.
