# Julia Poisson slope SD bridge parity

- From `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia`: `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=2 JULIA_DEPOT_PATH=/private/tmp/general-sd-regression-julia-depot:/Users/z3437171/.julia julia --compiled-modules=no --threads=2 --project=. -e 'include("test/test_poisson_sd_regression.jl")'`: pass, 35 assertions, including one slope recovery and independent quadrature test.
- From `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression`: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=2 JULIA_DEPOT_PATH=/private/tmp/general-sd-regression-julia-depot:/Users/z3437171/.julia DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' Rscript -e 'devtools::test(filter = "julia-poisson-sd")'`: pass, 22 assertions, 2 live Julia fits; one non-fatal JuliaCall startup warning.
- From `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression`: `Rscript -e 'pkgdown::check_pkgdown()'`: pass, no problems found.
- `git diff --check`: pass in both worktrees.

The R bridge fits identical seeded data through TMB and Julia and compares both log-SD coefficients within 0.25. Evidence remains limited to this single seeded comparison; it does not assess interval calibration.

Reverification after the formula-guide edits: the direct Julia Poisson suite passed 35/35 assertions; the R bridge passed 22/22 assertions with two live Julia fits and one non-fatal JuliaCall dependency-install warning; `pkgdown::check_pkgdown()` reported no problems, with only the existing Pandoc `--mathml` deprecation notices.
