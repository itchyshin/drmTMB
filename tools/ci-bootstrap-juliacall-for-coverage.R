#!/usr/bin/env Rscript
# One-shot JuliaCall bootstrap for the julia-bridge coverage job. covr runs
# many tests that each call drm_julia_setup(); warming RCall/Suppressor in the
# same Julia depot before package_coverage reduces setup.jl failures (CI only).

if (!requireNamespace("JuliaCall", quietly = TRUE)) {
  stop("JuliaCall is required", call. = FALSE)
}
Sys.setenv(R_HOME = R.home())
JuliaCall::julia_setup(installJulia = FALSE, install = TRUE)
cat("juliacall_bootstrap=ok\n")
