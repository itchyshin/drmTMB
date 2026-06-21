# R and Julia Bootstrap Refit Benchmark Metadata

- timestamp: 2026-06-09 06:04:00 -0600
- repo: /Users/z3437171/Dropbox/Github Local/drmTMB
- git_head: b4a4d7be
- git_status_short: |
   M .Rbuildignore
   M DESCRIPTION
   M NAMESPACE
   M NEWS.md
   M R/check.R
   M R/drmTMB.R
   M R/family.R
   M R/formula-markers.R
   M R/methods.R
   M R/missing-data.R
   M R/profile.R
   M README.md
   M ROADMAP.md
   M _pkgdown.yml
   M docs/design/01-formula-grammar.md
   M docs/design/02-family-registry.md
   M docs/design/03-likelihoods.md
   M docs/design/123-phase-18-skew-normal-source-map-slices-1519-1538.md
   M docs/design/125-phase-18-next-two-team-slices-1619-1718.md
   M docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md
   M docs/design/129-phase-18-semantic-boundary-tests-slices-1629-1630-1687-1688.md
   M docs/design/132-phase-18-skew-normal-implementation-gate-slices-1689-1702.md
   M docs/design/157-capability-completion-worklist.md
   M docs/design/158-phase-19-comparator-matrix.md
   M docs/design/159-drmtmb-0-2-0-release-readiness.md
   M docs/design/19-family-link-contract.md
   M docs/design/34-validation-debt-register.md
   M docs/design/37-worked-example-inventory.md
   M docs/design/41-phase-18-simulation-programme.md
   M docs/design/46-pre-simulation-readiness-matrix.md
   M docs/design/67-sdstar-p8-poisson-q1.md
   M docs/dev-log/check-log.md
   M docs/dev-log/known-limitations.md
   M docs/dev-log/team-improvements.md
   M inst/sim/README.md
   M inst/sim/dgp/sim_dgp_biv_gaussian_q8_endpoint.R
   M inst/sim/fit/sim_summarise_biv_gaussian_q8_endpoint.R
   M inst/sim/run/sim_run_biv_gaussian_q8_endpoint_smoke.R
   M inst/sim/run/sim_summary_biv_gaussian_q8_endpoint_smoke.R
   M man/check_drm.Rd
   M man/drmTMB.Rd
   M man/gr.Rd
   M man/imputed.Rd
   M man/meta_known_V.Rd
   M man/sigma.drmTMB.Rd
   M src/drmTMB.cpp
   M tests/testthat/helper-skew-normal-density.R
   M tests/testthat/test-biv-gaussian.R
   M tests/testthat/test-family-link-contract.R
   M tests/testthat/test-optimizer-contract.R
   M tests/testthat/test-phase18-biv-gaussian-q8-endpoint.R
   D tests/testthat/test-skew-normal-boundary.R
   M tests/testthat/test-skew-normal-density-contract.R
   M vignettes/distribution-families.Rmd
   M vignettes/drmTMB.Rmd
   M vignettes/figure-gallery.Rmd
   M vignettes/formula-grammar.Rmd
   M vignettes/model-map.Rmd
   M vignettes/robust-student.Rmd
   M vignettes/source-map.Rmd
  ?? R/julia-bridge.R
  ?? cran-comments.md
  ?? docs/design/162-phase-18-skew-normal-fixed-effect-formal-recovery-design.md
  ?? docs/design/163-phase-18-q8-hessian-start-rescue.md
  ?? docs/design/164-phase-18-skew-normal-hessian-comparator-pilot.md
  ?? docs/design/165-phase-18-q8-start-hook-preflight.md
  ?? docs/design/166-phase-18-skew-normal-comparator-scale-map.md
  ?? docs/dev-log/after-task/2026-06-07-cran-readiness-sprint.md
  ?? docs/dev-log/after-task/2026-06-08-capability-freeze-profile-skew-normal.md
  ?? docs/dev-log/after-task/2026-06-08-experimental-julia-engine-bridge.md
  ?? docs/dev-log/after-task/2026-06-08-q8-diagnostic-presets-skew-normal-recovery.md
  ?? docs/dev-log/after-task/2026-06-08-q8-diagnostic-summaries-skew-normal-smoke-artifacts.md
  ?? docs/dev-log/after-task/2026-06-08-q8-hessian-skew-normal-comparator-pilot.md
  ?? docs/dev-log/after-task/2026-06-08-q8-profile-bootstrap-fallback-pilot.md
  ?? docs/dev-log/after-task/2026-06-08-q8-skew-normal-diagnostic-hardening.md
  ?? docs/dev-log/after-task/2026-06-08-q8-skew-normal-evidence-agents.md
  ?? docs/dev-log/after-task/2026-06-08-q8-staged-start-mapper-pilot.md
  ?? docs/dev-log/after-task/2026-06-08-q8-start-hook-skew-normal-scale-map.md
  ?? docs/dev-log/after-task/2026-06-08-q8-start-override-glmmtmb-comparator-cleanup.md
  ?? docs/dev-log/after-task/2026-06-08-q8-stress-audit-skew-normal-false-positive-design.md
  ?? docs/dev-log/after-task/2026-06-08-r-julia-threading-comparison.md
  ?? docs/dev-log/after-task/2026-06-09-bootstrap-refit-benchmark-slice.md
  ?? docs/dev-log/after-task/2026-06-09-julia-bridge-overhead-reduction.md
  ?? docs/dev-log/after-task/2026-06-09-julia-sparse-lbfgs-phylo-default.md
  ?? docs/dev-log/after-task/2026-06-09-q8-usability-sample-size-starts.md
  ?? docs/dev-log/after-task/2026-06-09-r-engine-comparison-benchmark.md
  ?? docs/dev-log/agent-notes/
  ?? docs/dev-log/benchmarks/bootstrap-phylo-2026-06-08-r-compare.csv
  ?? docs/dev-log/benchmarks/julia-bridge-fixed-gaussian-2026-06-08.csv
  ?? docs/dev-log/benchmarks/julia-bridge-overhead-avonet-2026-06-09.csv
  ?? docs/dev-log/benchmarks/julia-bridge-phylo-gaussian-2026-06-08.csv
  ?? docs/dev-log/benchmarks/julia-bridge-phylo-gaussian-2026-06-09.csv
  ?? docs/dev-log/benchmarks/julia-bridge-phylo-gaussian-sparse-lbfgs-2026-06-09.csv
  ?? docs/dev-log/benchmarks/profile-scalar-endpoint-2026-06-08-r-compare.csv
  ?? docs/dev-log/benchmarks/r-engine-comparison-2026-06-09-metadata.md
  ?? docs/dev-log/benchmarks/r-engine-comparison-2026-06-09.csv
  ?? docs/dev-log/benchmarks/r-engine-comparison-fixed-smoke-2026-06-09-metadata.md
  ?? docs/dev-log/benchmarks/r-engine-comparison-fixed-smoke-2026-06-09.csv
  ?? docs/dev-log/benchmarks/r-julia-bootstrap-refits-2026-06-09.csv
  ?? docs/dev-log/benchmarks/r-julia-threading-comparison-2026-06-08.md
  ?? docs/dev-log/figure-audits/2026-06-08-profile-likelihood-article/
  ?? docs/dev-log/simulation-artifacts/
  ?? inst/sim/dgp/sim_dgp_skew_normal_fixed_effect.R
  ?? inst/sim/fit/sim_summarise_skew_normal_fixed_effect.R
  ?? inst/sim/run/sim_run_biv_gaussian_q8_usability_pilot.R
  ?? inst/sim/run/sim_run_skew_normal_fixed_effect_smoke.R
  ?? inst/sim/run/sim_summary_skew_normal_fixed_effect_smoke.R
  ?? inst/sim/run/sim_write_biv_gaussian_q8_endpoint_diagnostic_grid.R
  ?? inst/sim/run/sim_write_skew_normal_fixed_effect_grid.R
  ?? man/skew_normal.Rd
  ?? tests/testthat/test-julia-bridge.R
  ?? tests/testthat/test-phase18-skew-normal-fixed-effect.R
  ?? tests/testthat/test-skew-normal-location-scale.R
  ?? tools/benchmark-julia-engines.R
  ?? tools/benchmark-r-julia-bootstrap-refits.R
  ?? vignettes/julia-engine.Rmd
  ?? vignettes/profile-likelihood.Rmd
- R: R version 4.5.2 (2025-10-31)
- platform: aarch64-apple-darwin20
- drmTMB_version: 0.2.0
- TMB_version: 1.9.21
- JuliaCall_version: 0.17.6
- ape_version: 5.8.1
- julia_bin: /Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia
- species: 1000
- B: 10
- seed: 20260609
- r_workers: 1,4
- run_julia_bridge: TRUE
- run_direct_julia: FALSE
- direct_julia_threads: 4
- direct_julia_B: 10
- base_fit_s: 2.844
- target: sd:mu:phylo(1 | species)
- OMP_NUM_THREADS: 1
- OPENBLAS_NUM_THREADS: 1
- MKL_NUM_THREADS: 1
- VECLIB_MAXIMUM_THREADS: 1
- output_csv: docs/dev-log/benchmarks/r-julia-bootstrap-refits-2026-06-09.csv

The R native rows call public confint(..., method = "bootstrap"). The Julia
bridge row is a benchmark-only R loop over simulated responses and
drmTMB(..., engine = "julia") refits. It is not a public bootstrap CI path
and is not Julia-threaded from R yet. Direct DRM.jl rows, when requested,
come from the sibling DRM.jl benchmark script and are labelled separately.
