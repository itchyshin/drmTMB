# Native Poisson ordinary SD regression

OWNS: R/drmTMB.R, src/drmTMB.cpp, R/methods.R, new Poisson SD tests
Scope: ordinary scalar location intercepts only, existing Poisson response route.

- [x] P1: Poisson SD design reaches the exact target without dispersion drift
  CHECK: OPENBLAS_NUM_THREADS=1 Rscript tools/general-sd-regression/run-source-tests.R tests/testthat/test-poisson-sd-assembly.R
  EXPECT: SOURCE_ASSEMBLY_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression; path=e0fb875d37d1/39 entries; output=SOURCE_ASSEMBLY_PASS | Julia bridge: 0 live tests ran, 0 skipped; the LIVE ENGINE was not exercised in this configuration (mock-driven marshalling tests are counted by CI's 'Julia bridge glue executes (mock-driven, no Julia)' step).
- [x] P2: Fresh native fits pass constant-SD, independent likelihood and point recovery checks
  EVIDENCE: new source archive eaf3198f9... installed fresh on Totoro; Poisson integration28 passes including independent Laplace oracle, wrong-index control, constant-SD reduction and one point recovery check.
- [x] P3: Prediction/simulation/refit/target-output tests pass
  EVIDENCE: Poisson integration28 and all305 final native assertions pass with retained source/binary hashes; prediction/storage/simulation/bootstrap targets checked.
- [x] P4: Documentation and independent review reflect actual scope
  EVIDENCE: independent source review plus root output review pass for the bounded slice; labelled Poisson base route remains fenced; documentation qualified and checked. Calibration remains a separate programme obligation.
