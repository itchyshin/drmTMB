# Native Poisson scalar block identity

OWNS: R/drmTMB.R, tests/testthat/test-poisson-sd-assembly.R, tests/testthat/test-poisson-sd-integration.R
Scope: one labelled scalar mu intercept per group, ordinary Poisson only. Labels identify an existing coefficient; they add no correlation parameter. Independent slopes and correlated labelled blocks remain separate required work.

- [x] L1: Source assembly resolves the labelled scalar target and preserves other-family fences
  CHECK: OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript tools/general-sd-regression/run-source-tests.R tests/testthat/test-poisson-sd-assembly.R
  EXPECT: SOURCE_ASSEMBLY_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression; path=e0fb875d37d1/39 entries; output=SOURCE_ASSEMBLY_PASS | Julia bridge: 0 live tests ran, 0 skipped; the LIVE ENGINE was not exercised in this configuration (mock-driven marshalling tests are counted by CI's 'Julia bridge glue executes (mock-driven, no Julia)' step).
- [x] L2: Matching compiled engine proves labelled equivalence and public workflows
  EVIDENCE: Totoro repaired capsule6ad295b3... completed60s under240s cap, exit0;154 compiled expectations (Poisson43,binomial22,Gaussian89); RruntimeSHAd88ff604... matches manifest. repaired-output/tests.log and installed-source-sha256.txt retained.
- [x] L3: Independent review, neighbouring documentation and checkpoint agree
  EVIDENCE: final independent readback in poisson-label-review.md verifies source/test hashes,39assembly and154compiled assertions; negative control exposes both pre-fence admissions. Grammar, likelihoods, NEWS, runnable guide, assessment and after-task report agree. No calibration or broad support claim.
