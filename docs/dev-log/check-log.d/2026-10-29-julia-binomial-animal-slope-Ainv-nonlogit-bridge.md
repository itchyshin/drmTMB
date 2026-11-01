# Check log: Julia Binomial animal-slope Ainv under probit and cloglog

- Date: 2026-10-29
- Source candidates: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`. Both worktrees were dirty; the exact model/test source hashes are in the evidence manifest.
- Test command: `PATH="/Users/z3437171/.juliaup/bin:$PATH" DRMTMB_JULIA_TESTS=true DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null Rscript -e 'devtools::load_all(".", quiet=TRUE); testthat::test_file("tests/testthat/test-julia-binomial-nonlogit-structured-sd-bridge.R", reporter="summary")'`.
- Result: exit 0; three live bridge test cases passed on Julia 1.10.0. Animal-slope `Ainv` fits covered probit and cloglog in both TMB and Julia.
- Assertions: convergence, finite/named SD coefficients, SD-slope recovery within 0.5 of truth, cross-engine log likelihood within 0.1, and group-SD prediction agreement. This is focused synthetic point-fit evidence, not coverage.
- Local guard/marshalling assertions passed; unsupported animal correlated block and pedigree forms remain rejected.
- `pkgdown::check_pkgdown()` reported no problems; existing Pandoc `--mathml` deprecation warnings remain.
- Evidence reconciliation: 20,350 candidate rows, 194 linked rows, 20,156 unlinked rows, and 216 evidence records. Four exact Ainv animal-slope rows were linked and remain unreviewed.
- Issue search returned no matching open issue; no issue was changed.
- `git diff --check` passed for the scoped files. The after-task structure check passed; the acceptance-ledger scan found 13 ledgers not runnable because Node or `gate-check` is unavailable, so state is UNKNOWN. `slop_check.py` found 0 hits. The exact-draft assessment was recorded, and the close-out compiler passed.
- Full R suite, `R CMD check`, interval calibration, and a full pkgdown build were not run.
- Full report: `docs/dev-log/after-task/2026-10-29-julia-binomial-animal-slope-Ainv-nonlogit-bridge.md`.
