# Native scalar ordinary SD selectors

OWNS: R/drmTMB.R, R/random-effect-targets.R, R/methods.R, tests/testthat/test-binomial-sd-target-selectors.R
Scope: integrate common member identity and reserved selectors for native binomial ordinary scalar mu intercepts; no slopes or correlated/structured SD admission.

- [x] S1: Selectors resolve real scalar target identity and fail closed on ambiguity
  CHECK: OPENBLAS_NUM_THREADS=1 DRMTMB_SOURCE_ASSEMBLY=1 Rscript tools/general-sd-regression/run-source-tests.R tests/testthat/test-binomial-sd-target-selectors.R
  EXPECT: SOURCE_ASSEMBLY_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression; path=e0fb875d37d1/39 entries; output=SOURCE_ASSEMBLY_PASS | Julia bridge: 0 live tests ran, 0 skipped; the LIVE ENGINE was not exercised in this configuration (mock-driven marshalling tests are counted by CI's 'Julia bridge glue executes (mock-driven, no Julia)' step).
- [x] S2: Fresh native install preserves fitting, target outputs and constant SD equivalence
  EVIDENCE: source eaf3198f9... fresh Totoro library; selector integration22 + workflows12 and original native117 pass inside final305-assertion run; output/counts.json and runtime hashes retained.
- [x] S3: Grammar, neighbouring public outputs and independent review agree
  EVIDENCE: independent poisson-and-selectors-review.md follow-up resolves native split; root independently reviewed label mapping and added public-method plus fitted-label checks; grammar/reference/NEWS and neighbouring inventory updated; Rd/HTML/pkgdown checks pass.
