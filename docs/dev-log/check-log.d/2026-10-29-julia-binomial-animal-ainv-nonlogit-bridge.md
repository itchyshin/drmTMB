# Check log: Julia Binomial animal-intercept Ainv under probit and cloglog

- Date: 2026-10-29
- Sources: drmTMB candidate `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl candidate `70dbf564eb670144c63c08f61ea099084d95add2`.
- Command: `NOT_CRAN=true JULIA_HOME='/Users/z3437171/.juliaup/bin' DRMTMB_JULIA_TESTS=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null /usr/local/bin/Rscript -e 'devtools::test(filter = "julia-binomial-animal-ainv-nonlogit-sd-bridge", reporter = "summary", stop_on_failure = TRUE)'`
- Result: exit 0; one live Julia bridge test covered probit and cloglog.
- Fixture correction: fixed the seed before group-level SD-predictor sampling.
- Evidence reconciliation: pass, 202 receipt records, 182 linked rows, and 20,168 unlinked rows out of 20,350.
- Receipt: `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-ainv-nonlogit-bridge-live-20261029/receipt.md`.
- Boundary: one synthetic animal-intercept `Ainv_precision` route. No interval calibration, coverage, q2, pedigree, full-suite, or release claim.
- Detailed report: `docs/dev-log/after-task/2026-10-29-julia-binomial-animal-ainv-nonlogit-bridge.md`.
