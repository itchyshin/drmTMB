# 2026-10-20: Native cumulative-logit random-slope SD regression

Native cumulative-logit SD regression now admits one complete-response ordinary independent numeric `mu` slope, selected with `sd(id, coef = "x") ~ w` alongside `(0 + x | id)`. The seeded 256-group by 30-observation fit estimated the log-SD slope as 0.5625 for truth 0.5 and predicted increasing group SDs. Exploratory 64- and 128-group fits estimated about 2.16 and 0.16, respectively, and are retained as warnings about information sensitivity.

Checks:

- Before source admission, the new focused test failed at the intended slope-target guard.
- `Rscript -e "devtools::test(filter = '^cumulative-logit-sd-slope$', reporter = 'summary')"` passed: 10 assertions.
- `devtools::load_all('.', quiet = TRUE); rmarkdown::render('vignettes/predictor-dependent-random-sd.Rmd', quiet = TRUE)` passed against the current worktree.
- Plain standalone rendering first loaded a different installed checkout and failed before the new example; it was rerun with the current worktree explicitly loaded.
- `Rscript -e "pkgdown::check_pkgdown()"` reported no problems.
- `Rscript -e "pkgdown::build_site()"` finished successfully. Pandoc emitted existing mathml/mathjax deprecation warnings.
- Scoped `git diff --check` passed.
- `slop_check.py` reported 0 findings; the after-task structure check passed; the exact-draft assessment returned `ASSESSMENT_RECORDED` for `v1`.
- Exact inventory search: `rg -n -i 'cumulative-logit.*(direct-SD|SD regression).*(intercept-only|intercepts only|one ordinary `mu` intercept[^o])|direct-SD.*cumulative-logit.*intercept only' README.md NEWS.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md vignettes/formula-grammar.Rmd vignettes/model-map.Rmd docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`.
- Exact open issue search: `gh issue list --state open --search "cumulative-logit random-effect SD slope" --limit 10`; returned #1551 and #1463, neither specific to this route. No issue was changed.

The slice remains native-TMB point-fit evidence only. It does not establish interval coverage, Julia parity, structured effects, or broad ordinal recovery. See `docs/dev-log/after-task/2026-10-20-cumulative-logit-sd-slope.md`.
