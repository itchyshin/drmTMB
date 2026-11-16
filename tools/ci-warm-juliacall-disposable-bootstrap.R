#!/usr/bin/env Rscript
# CI-only: mirror drm_julia_setup()'s disposable JULIA_PROJECT bootstrap and
# run JuliaCall::julia_setup(install = TRUE) so RCall/Suppressor land in that
# active project before covr (see hsquared test-coverage-julia + JuliaCall#238).

fail <- function(...) stop(sprintf(...), call. = FALSE)

if (!requireNamespace("JuliaCall", quietly = TRUE)) {
  fail("JuliaCall is required for the julia-bridge coverage job")
}

runner_temp <- normalizePath(Sys.getenv("RUNNER_TEMP"), winslash = "/", mustWork = TRUE)
bootstrap <- file.path(runner_temp, "drmTMB-juliacall-disposable-check")
if (dir.exists(bootstrap)) {
  unlink(bootstrap, recursive = TRUE)
}
if (!dir.create(bootstrap, recursive = TRUE)) {
  fail("could not create disposable bootstrap at %s", bootstrap)
}
writeLines("[deps]", file.path(bootstrap, "Project.toml"))

Sys.setenv(JULIA_PROJECT = bootstrap)
Sys.setenv(R_HOME = R.home())

suppressPackageStartupMessages(library(JuliaCall))
JuliaCall::julia_setup(
  installJulia = FALSE,
  install = TRUE,
  verbose = TRUE,
  force = TRUE
)
active <- JuliaCall::julia_eval("string(Base.active_project())")
if (!grepl(basename(bootstrap), active, fixed = TRUE)) {
  fail(
    "Julia active project %s does not match disposable bootstrap %s",
    active,
    bootstrap
  )
}
JuliaCall::julia_command("using RCall")
JuliaCall::julia_command("using Suppressor")
cat(sprintf("juliacall_disposable_bootstrap=%s\n", bootstrap))
cat("juliacall_disposable_bootstrap=ok\n")
