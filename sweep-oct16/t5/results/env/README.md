# t5 environment record

- R 4.3.3 (Ubuntu 24.04 apt), R dependencies from Ubuntu noble apt (`r-cran-*`): TMB 1.9.10, Matrix 1.6-5, RcppEigen 0.3.4.0.0, nlme 3.1-164, cli 3.6.2.
- JuliaCall 0.17.6 built from `github.com/cran/JuliaCall` tag 0.17.6 (CRAN host blocked in this container).
- drmTMB installed from the checkout at `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a` with `R CMD INSTALL --no-docs`.
- Julia 1.12.7 from conda-forge (julialang.org and Docker Hub were blocked or rate-limited). The General registry was cloned from GitHub (`JULIA_PKG_SERVER=""`).
- DRModels.jl at `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7`, `Pkg.instantiate()` from its committed compat bounds. Resolved versions are in `drmodels_manifest_status.txt`. RCall 0.14.14 is in the default `@v1.12` environment only (needed by JuliaCall); it is not added to DRModels' project.
- R < 4.4 shim: the bridge-leg scripts define base R 4.4's `%||%` in `globalenv()` (drmTMB#1550). Native-leg scripts do not.
