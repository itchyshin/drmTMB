# Check log: Julia Binomial animal-intercept logit with A and Ainv

- Date: 2026-10-29
- Sources: drmTMB candidate `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl candidate `70dbf564eb670144c63c08f61ea099084d95add2`.
- Command: `NOT_CRAN=true JULIA_HOME='/Users/z3437171/.juliaup/bin' DRMTMB_JULIA_TESTS=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null /usr/local/bin/Rscript -e 'devtools::test(filter = "julia-binomial-animal-sd-regression", reporter = "summary", stop_on_failure = TRUE)'`
- Result: exit 0; two live Julia bridge tests ran.
- Evidence: focused test checks logit animal-intercept SD fits with supplied `A` and `Ainv`; native and Julia coefficients, likelihood, and group SD predictions agree within fixed test tolerances.
- Evidence reconciliation: pass, 204 receipt records, 184 linked rows, and 20,166 unlinked rows out of 20,350.
- Receipt: `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-logit-bridge-live-20261029/receipt.md`.
- Boundary: one synthetic logit q1 input route. No pedigree, q2, interval calibration, coverage, full-suite, or release claim.
- Detailed report: `docs/dev-log/after-task/2026-10-29-julia-binomial-animal-logit-bridge.md`.
