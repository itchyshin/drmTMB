# M1 native likelihood checks

OWNS: .unlazy/cmr-m1/

Scope: native exact fixed-effects history likelihood and interior derivatives; no calibration claim.

- [x] G1: exact native production gate
  CHECK: env OPENBLAS_NUM_THREADS=1 Rscript tools/check-cmr.R --gate exact
  EXPECT: CMR_EXACT_OK
  CWD: .
  EVIDENCE: exit=0; shell=/bin/zsh; cwd=/private/tmp/cmr-drmtmb-20261006; path=8d2e6e29f6f6/39 entries; output=Julia bridge: 0 live tests ran, 0 skipped; the LIVE ENGINE was not exercised in this configuration (mock-driven marshalling tests are counted by CI's 'Julia bridge glue executes (mock-driven, no Julia)' step). | Julia bridge: 0 live tests r

- [x] G2: derivatives native production gate
  CHECK: env OPENBLAS_NUM_THREADS=1 Rscript tools/check-cmr.R --gate derivatives
  EXPECT: CMR_DERIVATIVES_OK
  CWD: .
  EVIDENCE: exit=0; shell=/bin/zsh; cwd=/private/tmp/cmr-drmtmb-20261006; path=8d2e6e29f6f6/39 entries; output=CMR_DERIVATIVES_OK | Julia bridge: 0 live tests ran, 0 skipped; the LIVE ENGINE was not exercised in this configuration (mock-driven marshalling tests are counted by CI's 'Julia bridge glue executes (mock-driven, no Julia)' step).


- [x] G3: literal fixed-parameter and marked comparator parity
  CHECK: env OPENBLAS_NUM_THREADS=1 Rscript tools/check-cmr.R --gate parity
  EXPECT: CMR_PARITY_OK
  CWD: .
  EVIDENCE: exit=0; shell=/bin/zsh; cwd=/private/tmp/cmr-drmtmb-20261006; path=8d2e6e29f6f6/39 entries; output=2: the ‘findbars’ function has moved to the reformulas package. Please update your imports, or ask an upstream package maintainer to do so. | This warning is displayed once per session.
