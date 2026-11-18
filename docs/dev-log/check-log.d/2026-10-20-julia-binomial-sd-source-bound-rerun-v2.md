# Source-bound Julia Bernoulli SD bridge rerun (v2)

- Command: `DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-binomial-sd", reporter = "summary")'`.
- Result: `R_EXIT_CODE=0`; five live Julia bridge tests ran; no failures or skips.
- Diagnostics: two singular-Hessian warnings recurred (`rcond=9.23265335367337e-10`, flat coordinate 7; `rcond=3.879150990279055e-17`, no flat coordinate identified). Wald standard errors for affected fits are not trustworthy.
- Candidate pins: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`.
- Before/after SHA-256 values were identical for the seven selected relevant source and test files listed below. This v2 receipt is superseded by the broader source manifest in `docs/dev-log/general-sd-regression/evidence/julia-bridge-source-bound-20261020-v3/`.
  - `R/julia-bridge.R`: `00897301ef4db9f643ec1afa34773fc56dce177e09354f2089c32385009afd3e`
  - `src/drmTMB.cpp`: `dc8fe935e80382939600c559ed287093b67d0ebff82882d5d5e013355d0feb03`
  - `tests/testthat/test-julia-binomial-sd.R`: `bcc2970104bb4e30a3176f7a9ac1d95fb23d5b634607dcdf5e99c40ea360fc3c`
  - paired Julia `src/binomial.jl`: `7bfa5fc5c4fca1bf578830f7d4d6dd524b5c0624f791eae7f827f219e45c3e09`
  - paired Julia `src/binomial_sd_regression.jl`: `ada3807f2d8c3ee20666a8f5c8c69ae2bb54ccc8a90c367ab23f7a7b3aea4d67`
  - paired Julia `src/inference.jl`: `1f09f0c3605f55f93286477e414fb8dcbd6887180a7f51c95cebe88a35f98e09`
  - paired Julia `test/test_binomial_sd_regression.jl`: `0ba3407b132c349ca84e0e9863389c82820bbc556de4f42bb7569dbceb1c4013`
- This verifies Bernoulli Julia fitting, recovery smoke, and bridge outputs only. It does not validate interval coverage or establish family/effect/provider parity.
