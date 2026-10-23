# Ayumi #29 — batch Julia startup gate

## Acceptance check

**CHECK.** `drm_julia_setup()` must still abort before `JuliaCall::julia_setup()`
inside a non-interactive `R CMD check` package process, while an ordinary
non-interactive `Rscript` process is allowed to use the public Julia engine
without requiring `NOT_CRAN=true` or `DRMTMB_JULIA_TESTS=true`.

**EXPECT.** The predicate uses the check-specific
`_R_CHECK_PACKAGE_NAME_` marker set by `tools:::.check_packages()`, rather than
treating every non-interactive R session as CRAN. Existing explicit repository
test opt-ins (`NOT_CRAN=true` and `DRMTMB_JULIA_TESTS=true`) retain their
current behaviour.

## Boundary

This is startup routing only. It neither changes JuliaCall setup, installs
Julia, changes the `engine = "julia"` model admission surface, nor establishes
parity or inference claims. A check runner that does not expose
`_R_CHECK_PACKAGE_NAME_` remains outside this narrow detection contract; it
needs an explicitly reviewed check-runner signal before this guard can protect
it.

## Pure receipt

`Rscript --vanilla` loaded the source package and ran
`test-julia-batch-startup.R` plus `test-cran-lane-filter.R`: both passed on
2026-08-30. The check is pure predicate/setup-abort coverage; it does not
start JuliaCall. A separate public batch `Rscript` confirmation remains the
integration check.
