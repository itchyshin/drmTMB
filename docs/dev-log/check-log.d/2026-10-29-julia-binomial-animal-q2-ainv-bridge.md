# Check log: Julia Binomial animal q2 Ainv bridge

- Date: 2026-10-29
- Sources: drmTMB candidate `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl candidate `70dbf564eb670144c63c08f61ea099084d95add2`.
- Command: `JULIA_HOME='/Users/z3437171/.juliaup/bin' DRMTMB_JULIA_TESTS=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null /usr/local/bin/Rscript -e 'devtools::test(filter = "julia-binomial-animal-q2-sd", reporter = "summary", stop_on_failure = TRUE)'`
- Result: exit 0; the focused file passed and three live Julia bridge tests ran.
- New regression: supplied `Ainv` payload is exact; native and Julia q2 fits, coefficient-specific SD predictions, and a seeded marginal simulation agree under the fixed test tolerances.
- Evidence reconciliation: pass, 198 receipt records, 178 linked candidate rows, and 20,172 unlinked rows out of 20,350.
- Evidence receipt: `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-q2-ainv-bridge-live-20261029/receipt.md`.
- Boundary: one synthetic logit q2 animal `Ainv` route. No pedigree, probit/cloglog `Ainv`, interval calibration, coverage, full-suite, or release claim. Capability status remains unresolved.
- Detailed report: `docs/dev-log/after-task/2026-10-29-julia-binomial-animal-q2-ainv-bridge.md`.
