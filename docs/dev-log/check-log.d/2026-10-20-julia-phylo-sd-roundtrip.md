# Julia phylogenetic SD scale round-trip

Lane: `codex:general-sd-scale-roundtrip`
Change: extend the non-unit-height Julia/TMB phylogenetic SD regression test. It checks that `saveRDS()` / `readRDS()` preserve adjusted SD coefficients, predictions, and Wald intervals, including a no-intercept SD formula.

**Checks (20 October 2026, paired candidate source):**

- `DRMODELS_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' DRMTMB_JULIA_TESTS=true JULIA_DEPOT_PATH='/private/tmp/drmtmb-julia-depot:/Users/z3437171/.julia' JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-binomial-phylo-sd", reporter = "summary")'`: PASS, 33 assertions, 0 failures, 0 warnings, 0 skips; one live Julia fit, about 40 seconds. The test reports the expected raw-tree-height warning for a tree of height 2.5.
- `git diff --check -- tests/testthat/test-julia-binomial-phylo-sd.R`: PASS.
- `git diff --check -- tests/testthat/test-julia-binomial-phylo-sd.R docs/dev-log/check-log.d/2026-10-20-julia-phylo-sd-roundtrip.md docs/dev-log/after-task/2026-10-20-julia-phylo-sd-roundtrip.md`: PASS.
- `slop_check.py` on both records: PASS, zero findings.

The live test also saves and reloads the fitted Julia object, then checks its public SD coefficients and new-data SD prediction. This verifies public scale conversion through serialization for the tested ultrametric tree of height 2.5. It does not establish Bernoulli uncertainty calibration or parity for other distributions or structured effects. The result is from a dirty paired candidate worktree, not a clean or released source snapshot.
