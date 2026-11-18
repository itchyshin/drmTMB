# Native Bernoulli SD regression slice

OWNS: R/drmTMB.R, src/drmTMB.cpp, tests/testthat/test-binomial-random-effect-scale.R, tests/testthat/test-binomial-sd-integration.R, tools/general-sd-regression/run-source-tests.R

Scope: First native ordinary-intercept Bernoulli/binomial slice. This does not
close the cross-engine or calibration programme gate.

- [x] B1: SD formula design and data filtering reach native TMB assembly
  CHECK: Rscript tools/general-sd-regression/run-source-tests.R tests/testthat/test-binomial-random-effect-scale.R
  EXPECT: SOURCE_ASSEMBLY_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression; path=6df32789272f/34 entries; output=SOURCE_ASSEMBLY_PASS | Julia bridge: 0 live tests ran, 0 skipped; the LIVE ENGINE was not exercised in this configuration (mock-driven marshalling tests are counted by CI's 'Julia bridge glue executes (mock-driven, no Julia)' step).
- [x] B2: Freshly compiled native likelihood passes end-to-end tests
  CHECK: OPENBLAS_NUM_THREADS=1 DRMTMB_SD_TEST_LIBRARY=/private/tmp/drmtmb-general-sd-library Rscript tools/general-sd-regression/run-native-tests.R
  EXPECT: NATIVE_BINOMIAL_SD_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression; path=6df32789272f/34 entries; output=Julia bridge: 0 live tests ran, 0 skipped; the LIVE ENGINE was not exercised in this configuration (mock-driven marshalling tests are counted by CI's 'Julia bridge glue executes (mock-driven, no Julia)' step). | Julia bridge: 0 live tests r
- [x] B3: Independent numerical oracle and recovery tests pass
  CHECK: OPENBLAS_NUM_THREADS=1 DRMTMB_SD_TEST_LIBRARY=/private/tmp/drmtmb-general-sd-library Rscript tools/general-sd-regression/run-native-tests.R tests/testthat/test-binomial-sd-integration.R
  EXPECT: NATIVE_BINOMIAL_SD_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression; path=6df32789272f/34 entries; output=NATIVE_BINOMIAL_SD_PASS | Julia bridge: 0 live tests ran, 0 skipped; the LIVE ENGINE was not exercised in this configuration (mock-driven marshalling tests are counted by CI's 'Julia bridge glue executes (mock-driven, no Julia)' step).
- [ ] B4: Native-slice docs and independent review agree with actual scope
  EVIDENCE: pending
