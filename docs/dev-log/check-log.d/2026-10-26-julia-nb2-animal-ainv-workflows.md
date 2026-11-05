# Check Log: Julia NB2 animal SD workflows with precision input

Date: 2026-10-26

Candidate pins: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`.

Command:

```sh
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 /Users/z3437171/.juliaup/bin/julia --project=. test/test_nb2_animal_sd_bootstrap.jl
```

Result: PASS, 12/12 assertions in 16.6 seconds on Julia 1.10.0. Checks sparse-precision marginal simulation, one successful bootstrap refit, and finite 80% profile endpoints for the selected SD slope. The fit emitted a non-positive-definite Hessian warning and withheld Wald standard errors. Profile execution is workflow evidence, not interval calibration.

The focused source hashes for `src/DRModels.jl`, `src/inference.jl`, `src/negbinomial.jl`, `src/sparse_laplace_glmm.jl`, and `test/test_nb2_animal_sd_bootstrap.jl` matched before and after the run. The direct console log and source manifest are in `docs/dev-log/general-sd-regression/evidence/julia-nb2-animal-ainv-workflows-20261026/`; the hash-checked receipt is `julia-nb2-animal-ainv-simulator-bootstrap-profile-20261026`.

Scope: one Julia NB2 animal mean-intercept SD model supplied with `Ainv`. Native TMB parity, pedigree inputs, broader provider support, and interval calibration remain open.
