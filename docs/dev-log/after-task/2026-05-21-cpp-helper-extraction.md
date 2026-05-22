# After Task: C++ Helper Extraction

## Goal

Start the C++ modularization plan with the smallest safe mechanical move:
extract branch-free numeric transforms and NB2 count-kernel helpers from
`src/drmTMB.cpp` without changing formula grammar, likelihood branches, report
names, profile targets, or R-to-TMB ABI declarations.

## What Changed

The scalar helpers `drm_log1p_pos()`, `drm_log1p_exp_stable()`,
`drm_log1mexp()`, `drm_log_inv_logit()`, `drm_log1m_inv_logit()`, and
`drm_log_inv_logit_diff()` now live in `src/drm_numeric.h`. The NB2 helpers
`drm_nbinom2_log_count_product()`, `drm_nbinom2_log_density()`, and
`drm_nbinom2_log_p0()` now live in `src/drm_count_kernels.h`.

`src/drmTMB.cpp` still owns the single TMB entry point, `DATA_*` and
`PARAMETER_*` declarations, branch bodies, linear-predictor updates,
`REPORT()` and `ADREPORT()` calls, and all fitted-surface decisions. The source
map and rendered source-map article now say the first helper extraction has
landed and use `.h` filenames, because `.hpp` headers in `src/` triggered an
R-CMD-check source-package warning.

## User Value

This gives contributors the first real modularization foothold while preserving
all user-facing behavior. The NB2, zero-inflated NB2, hurdle NB2, cumulative
logit, Poisson, structured-effect, profile-target, and pkgdown surfaces remain
covered by existing tests and docs.

## Files Changed

- `src/drmTMB.cpp`
- `src/drm_numeric.h`
- `src/drm_count_kernels.h`
- `docs/design/36-cpp-modularization-source-map.md`
- `vignettes/source-map.Rmd`
- `docs/dev-log/check-log.md`

## Checks

Validation for this slice:

```sh
air format src/drmTMB.cpp src/drm_numeric.h src/drm_count_kernels.h docs/design/36-cpp-modularization-source-map.md vignettes/source-map.Rmd
Rscript -e "devtools::test(filter = 'count-kernels|cumulative-logit', reporter = 'summary')"
Rscript -e "devtools::test(reporter = 'summary')"
Rscript -e "pkgdown::build_site()"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"
rg -n "drm_numeric.h|drm_count_kernels.h|first pass has moved|first modularization slice|drm_log1p_exp_stable|NB2 count-kernel" docs/design/36-cpp-modularization-source-map.md vignettes/source-map.Rmd pkgdown-site/articles/source-map.html
git diff --check
```

Outcomes:

- The focused count-kernel and cumulative-logit test run passed.
- The full `devtools::test(reporter = "summary")` suite passed before the
  header extension rename.
- The first `devtools::check()` rerun exposed the `.hpp` source-package
  warning; renaming the headers to `.h` removed it.
- `pkgdown::build_site()` rebuilt `pkgdown-site/articles/source-map.html`, and
  `pkgdown::check_pkgdown()` reported no problems.
- The final `devtools::check(error_on = "never", env_vars =
  c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))` completed with 0 errors, 0 warnings,
  and 0 notes.

## Consistency Audit

Implemented claim: only branch-free scalar and NB2 count helpers moved out of
`src/drmTMB.cpp`; fitted likelihood branches, reports, public syntax, and ABI
declarations did not move. `git diff --check` was clean. The rendered source
map was rebuilt and confirmed with:

```sh
rg -n "drm_numeric.h|drm_count_kernels.h|first pass has moved|first modularization slice|drm_log1p_exp_stable|NB2 count-kernel" docs/design/36-cpp-modularization-source-map.md vignettes/source-map.Rmd pkgdown-site/articles/source-map.html
```

The audit did not require README, ROADMAP, NEWS, formula grammar, or
known-limitations changes because this was an internal source-layout refactor,
not a new family, formula route, fitted surface, interval claim, or user-facing
syntax change.

## GitHub Issue Maintenance

I checked for overlapping open issues with:

```sh
gh issue list --search "C++ modularization OR source map OR helper extraction OR count kernel" --limit 20 --json number,title,state,labels,updatedAt
```

The search returned tutorial/source-map adjacent issues #57 and #31, but
neither tracked the internal C++ helper extraction. No issue comment, closure,
or new issue was needed for this small refactor.

## What Did Not Go Smoothly

The source-map plan originally used `.hpp` header names. R CMD check warned
that `.hpp` files under `src/` were unlikely source filenames, so the slice
renamed the new headers and future planned header names to `.h`.

## Standing Review

Ada kept this to the first pure-helper boundary. Gauss and Noether checked that
the helper bodies and numerical transforms were moved without changing
parameterization. Curie kept the focused test gate on NB2 count kernels and
cumulative-logit probability helpers. Emmy checked that branch bodies, report
names, and ABI declarations stayed in `src/drmTMB.cpp`. Grace caught and closed
the `.hpp` R-CMD-check warning by switching the planned header filenames to
`.h`. Rose recorded the source-map drift lesson so later C++ slices do not
repeat it.

## Known Limitations

No public behavior changed. The next C++ modularization slice should still avoid
moving branch bodies, structured-effect prior attachment, reports,
`ADREPORT()` names, profile-target labels, or R-to-TMB ABI declarations until a
separate helper/report contract is designed.

## Next Actions

The next safe C++ slice is another pure-helper move, likely row-density kernels
with objective-level comparator tests. Keep the `.h` filename convention unless
the package adopts a different CRAN-clean source-file policy.
