# Check log: Julia Binomial animal-intercept covariance A under probit and cloglog

- Date: 2026-10-29
- Sources: drmTMB candidate `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl candidate `70dbf564eb670144c63c08f61ea099084d95add2`.
- Command: `NOT_CRAN=true JULIA_HOME='/Users/z3437171/.juliaup/bin' DRMTMB_JULIA_TESTS=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null /usr/local/bin/Rscript -e 'devtools::test(filter = "julia-binomial-animal-A-nonlogit-sd-bridge", reporter = "summary", stop_on_failure = TRUE)'`
- Result: exit 0; one live Julia bridge test covered probit and cloglog with covariance input `A`.
- Checks: both engines converged; the SD slope was within 0.55 of truth and within 0.35 across engines; log likelihoods agreed within 0.02; fitted animal SDs agreed within 0.03.
- Evidence reconciliation: PASS, 20,350 candidate rows, 188 linked rows, 20,162 unlinked rows, and 208 evidence records.
- Hashes: all files in `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-A-nonlogit-bridge-live-20261029/source-manifest.sha256` verified.
- Boundary: one synthetic q1 animal intercept with `A` under probit and cloglog. No interval calibration, coverage, or broad parity claim. Four evidence rows remain unreviewed.
- Issue search: no matching open GitHub issue found; none opened or changed.
- Full R suite, `R CMD check`, pkgdown build, and interval coverage were not run.
- Detailed report: `docs/dev-log/after-task/2026-10-29-julia-binomial-animal-A-nonlogit-bridge.md`.
