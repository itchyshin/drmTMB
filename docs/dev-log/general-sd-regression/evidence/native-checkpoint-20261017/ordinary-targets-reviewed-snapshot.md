# Ordinary SD member identity

OWNS: R/random-effect-targets.R, tests/testthat/test-random-effect-targets.R
Scope: internal identity/validation module, no fitting admission.

- [x] T1: Real ordinary and bivariate registries map to stable identities
  CHECK: OPENBLAS_NUM_THREADS=1 DRMTMB_SOURCE_ASSEMBLY=1 Rscript tools/general-sd-regression/run-source-tests.R tests/testthat/test-random-effect-targets.R
  EXPECT: SOURCE_ASSEMBLY_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression; path=6df32789272f/34 entries; output=SOURCE_ASSEMBLY_PASS | Julia bridge: 0 live tests ran, 0 skipped; the LIVE ENGINE was not exercised in this configuration (mock-driven marshalling tests are counted by CI's 'Julia bridge glue executes (mock-driven, no Julia)' step).
- [x] T2: Independent structural review passes the internal identity contract
  EVIDENCE: target-resolver-review.md final pair-validation rereview; no admission claim.
