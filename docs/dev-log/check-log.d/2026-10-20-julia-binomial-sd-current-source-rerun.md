## Current-source Julia Bernoulli SD bridge rerun

- Command: `DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter = "julia-binomial-sd", reporter = "summary")'`.
- Result: exit 0; five live Julia tests ran, with no test failures or skips.
- Diagnostics: two Julia singular-Hessian warnings were emitted (`rcond=9.23265335367337e-10`, coordinate 7; `rcond=3.879150990279055e-17`, no flat coordinate identified). These make the affected Wald standard errors untrustworthy; the run is not interval calibration.
- Candidate pins: drmTMB HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl HEAD `70dbf564eb670144c63c08f61ea099084d95add2`.
- Post-run SHA-256: `R/julia-bridge.R` `00897301ef4db9f643ec1afa34773fc56dce177e09354f2089c32385009afd3e`; `src/drmTMB.cpp` `dc8fe935e80382939600c559ed287093b67d0ebff82882d5d5e013355d0feb03`; `tests/testthat/test-julia-binomial-sd.R` `bcc2970104bb4e30a3176f7a9ac1d95fb23d5b634607dcdf5e99c40ea360fc3c`.
- No model code, public behavior, issue, PR, or compute campaign changed. The run verifies the current candidate's bridge suite only. Bernoulli recovery/interval gates and the broader family/effect matrix remain open.
