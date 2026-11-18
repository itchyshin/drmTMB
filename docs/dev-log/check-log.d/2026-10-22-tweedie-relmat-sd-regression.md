# 2026-10-22: Tweedie related-matrix SD route and skew-normal SD repair

The native Tweedie q=1 related-matrix location-intercept route passed the
focused recovery and output test. The test now retains the synthetic group
predictor used to check group-named `predict()` values and row-expanded
`predict_parameters()` output. A source-loaded render of
`vignettes/predictor-dependent-random-sd.Rmd` passed and includes the
synthetic Tweedie example. `pkgdown::check_pkgdown()` found no problems.
The full temporary site build passed its metadata checks but stopped before
rendering because the environment could not resolve cdnjs for
`headroom.min.js`.

The render exposed an undefined `mu_structured_term` in the skew-normal
builder, which blocked its ordinary random-effect SD routes. Removing the
unused structured setup fixed the path; the focused skew-normal SD assembly
tests now pass. The combined Tweedie and skew-normal filters passed 29
expectations. These checks do not establish Julia parity or interval
calibration, and do not close programme-wide capability or documentation
gates. Full details are in
`docs/dev-log/after-task/2026-10-22-tweedie-relmat-sd-regression.md`.

Reverification on 2026-10-22: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1
MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter =
"tweedie-relmat-sd-regression")'` passed all 12 expectations in 7 seconds,
with 0 failures, warnings, or skips. Julia bridge tests were not exercised.

Reverification on 2026-10-23: with
`DRM_JL_PATH=/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia`,
`JULIA_DEPOT_PATH=/private/tmp/drmtmb-julia-depot:/Users/z3437171/.julia`,
and Julia/OpenBLAS each limited to one thread,
`Rscript -e 'devtools::test(filter = "julia-tweedie-relmat-sd", reporter = "summary")'`
completed successfully. The live bridge test checked that `K` is marshalled as
the structured covariance keyword, then fit the synthetic Tweedie model and
checked convergence, SD coefficients, and group predictions. JuliaCall emitted
a dependency-install/precompile warning (`LogExpFunctionsInverseFunctionsExt`
reported `UndefVarError: loglogistic`), but the live fit and test completed
without failed assertions. Source hashes: `R/julia-bridge.R`
`e0cb8328c8cd553627b1a94ccfd74db62698359b1e7c70a8a406535c1e867ccb`,
`tests/testthat/test-julia-tweedie-relmat-sd.R`
`f00d9e41c9ea6f42f223091944116793a08f1ed00f5e5e06fddc6b7206fc0762`, and
paired Julia `src/tweedie.jl`
`c3644d8c32d0021a9f7aa17af84ae9494d9c7fd56043332f26c759f3e4e93460`.

Open consistency issue from the independent route audit: the Tweedie family
example asks `predict_parameters()` for `:marginal_sd`, while the current
predictor returns `:sd` (the SD multiplier). The fit stores marginal SDs in
`fit.scales`; update the example or public prediction contract after the active
documentation lane is reconciled. This bridge run does not establish general
Julia parity or interval calibration.
