# Non-logit Binomial intercept-plus-slope Julia bridge

- Test-first focused test `julia-binomial-nonlogit-intercept-slope-sd-bridge` — RED before the bridge predicate change: the matching pair was refused. PASS after the change: three fit-free admission assertions pass.
- `DRMTMB_JULIA_TESTS=true NOT_CRAN=true DRM_JL_PATH=... DRM_JL_JULIA_HOME=... JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter = "julia-binomial-nonlogit-intercept-slope-sd-bridge", reporter = "summary", stop_on_failure = FALSE)'` — PASS; 28 expectations across one paired probit fit and one paired cloglog fit.
- `PATH=/Users/z3437171/.juliaup/bin:$PATH JULIA_HOME=/Users/z3437171/.juliaup/bin DRMTMB_JULIA_TESTS=true NOT_CRAN=true DRM_JL_PATH=... DRM_JL_JULIA_HOME=... JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter = "julia-binomial-nonlogit-slope-sd-bridge", reporter = "summary", stop_on_failure = FALSE)'` — PASS; 27 expectations in the adjacent slope-only probit/cloglog bridge test.
- `rmarkdown::render("vignettes/julia-engine.Rmd", output_file = file.path(tempdir(), "julia-engine.html"), quiet = TRUE)` — PASS; existing Pandoc mathjax deprecation warning.
- `rmarkdown::render("vignettes/formula-grammar.Rmd", output_file = file.path(tempdir(), "formula-grammar.html"), quiet = TRUE)` — PASS; existing Pandoc mathjax deprecation warning.
- `git diff --check` on touched files — PASS.
- Profile confidence intervals and interval-coverage calibration — NOT RUN. A two-refit bootstrap smoke was run only to check Julia target routing and result columns.
- Follow-up selected-target profile inventory and two-refit Julia bootstrap smoke — PASS; at least one refit returned a finite interval. This is not interval calibration.
