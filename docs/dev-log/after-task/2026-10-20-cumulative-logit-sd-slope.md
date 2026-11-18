# After Task: Native cumulative-logit random-slope SD regression

## 1. Goal

Extend cumulative-logit direct-SD regression from one ordinary location random intercept to one independent numeric location random slope, using complete responses and a fixed-seed synthetic example.

## 2. Implemented

The native TMB builder admits a coefficient-selected independent `mu` slope target such as `sd(id, coef = "x") ~ w` alongside `(0 + x | id)`. The existing ordinal likelihood already maps the group SD to each ordinary random-effect term, so the change uses the existing likelihood path. The focused test checks target identity, the TMB SD-row map, fit convergence, recovery of the log-SD predictor coefficient, and increasing predicted group SDs.

The 256-group by 30-observation synthetic fit estimated the log-SD coefficient as 0.5625 for a generating value of 0.5. Smaller pilot fits were unstable: the 64-group fit estimated about 2.16 and the 128-group fit about 0.16. These runs are retained as diagnostics and are not represented as a broad recovery study.

## 3a. Decisions and Rejected Alternatives

Kept the existing cumulative-logit likelihood, fixed cutpoints, and latent logistic scale. The new route is limited to one ordinary independent numeric `mu` slope with complete responses. Correlated or labelled blocks, structured effects, multiple targets, and scale/discrimination formulas remain outside this slice. Interval coverage validation is deferred under the revised implementation-first goal. Assumptions made without asking: none.

## 4. Files Touched

- `R/drmTMB.R`
- `tests/testthat/test-cumulative-logit-sd-slope.R`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/predictor-dependent-random-sd.Rmd`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-10-20-cumulative-logit-sd-slope.md`
- `docs/dev-log/after-task/2026-10-20-cumulative-logit-sd-slope.md`
- `docs/dev-log/after-task/2026-10-20-cumulative-logit-sd-slope.assessment.json`
- `.unlazy/general-sd-regression/GATES.md` (partial G6 evidence; the gate remains open)

## 5. Checks Run

- Before admission was enabled, the focused ordinal SD-slope tests failed at the intended builder rejection.
- `Rscript -e "devtools::test(filter = '^cumulative-logit-sd-slope$', reporter = 'summary')"` passed all 10 assertions.
- `devtools::load_all('.', quiet = TRUE)` followed by `rmarkdown::render('vignettes/predictor-dependent-random-sd.Rmd', quiet = TRUE)` passed against this worktree.
- A plain `rmarkdown::render()` first loaded a different installed drmTMB checkout and failed at its Bernoulli SD-intercept admission. The first render used another installed checkout and stopped before the new example; rendering after loading the current source passed.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site()` finished successfully and rendered the predictor-dependent-SD, formula-grammar, and model-map articles. Pandoc emitted existing `--mathml` and `--mathjax` deprecation warnings.
- Targeted `git diff --check` passed.
- `python3 ~/shinichi-brain/tools/slop_check.py <report>` reported 0 findings, and `Rscript ~/shinichi-brain/tools/check-after-task.R <report>` passed the structure check.
- The exact-draft assessment check returned `ASSESSMENT_RECORDED` for report version `v1`; the record is `docs/dev-log/after-task/2026-10-20-cumulative-logit-sd-slope.assessment.json`.
- No Julia source or engine was exercised; Julia parity is not established.

## 6. Tests of the Tests

The new builder test failed before the source change at the intended unsupported slope-target guard. The integration test fixes the seed, checks the target name and SD-row mapping, fits the public API, checks the recovered coefficient against the declared truth, and confirms predicted SDs increase over the tested predictor values. The smaller-group pilot results were retained rather than used to relax the recovery threshold.

## 7a. Issue Ledger

The exact open-issue search was `gh issue list --state open --search "cumulative-logit random-effect SD slope" --limit 10`. It returned #1551 (Julia Poisson/Gamma bridge admission) and #1463 (a broad test sweep), neither of which matches this cumulative-logit feature. No issue was opened or changed.

## 8. Consistency Audit

Updated the formula grammar, likelihood map, model map, known-limitations note, native adapter map, NEWS, and predictor-dependent-SD vignette. The vignette distinguishes ordinary random-slope support from predictor-dependent slope SDs and labels the ordinal example as one high-information point-recovery case. The README has no existing cumulative-logit direct-SD claim to revise. The precise stale-wording search was `rg -n -i 'cumulative-logit.*(direct-SD|SD regression).*(intercept-only|intercepts only|one ordinary `mu` intercept[^o])|direct-SD.*cumulative-logit.*intercept only' README.md NEWS.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md vignettes/formula-grammar.Rmd vignettes/model-map.Rmd docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`. The search returned expanded-route wording and unrelated family entries; none states that cumulative-logit direct-SD regression is intercept-only. This task does NOT establish interval calibration, Julia parity, structured or correlated effects, or general ordinal recovery.

## 9. What Did Not Go Smoothly

The initial standalone article render loaded an installed package from another checkout and failed before the new example. Explicitly loading the current source fixed the environment mismatch. The 64- and 128-group synthetic fits did not recover the generating slope well, which exposed the information sensitivity of this design; the successful higher-information case is documented with that qualification.

## 10. Known Residuals

The route remains complete-response, native TMB, one ordinary independent numeric `mu` slope, and point-fit evidence only. No coverage study was run. Profile intervals and their calibration are not advertised for this route. Julia files remain with the DRM.jl lane pending a handoff. The broader predictor-dependent random-effect SD programme remains active.

## 11. Team Learning

When the likelihood already indexes group SDs for every ordinary random-effect term, check whether the admission and target-resolution layer is the remaining constraint before changing the C++ likelihood. Keep low-information recovery failures in the record and use a separate higher-information test case without claiming that the harder designs passed.

## 12. Cross-Product Coverage

Native R/TMB formula admission, fitting, coefficient extraction, and SD prediction were checked. This slice does NOT cover simulation, save/reload, profiling, bootstrap refitting, Julia execution, or interval coverage. It does not complete the Bernoulli-first programme or the overall general predictor-dependent random-effect SD goal.
