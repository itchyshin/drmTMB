# CMR acceptance ledger

Scope: complete approved M0-M6 programme, no abandoned stages.

- [x] G0: accepted plan and frozen contract, recon/research recorded
  EVIDENCE: manual accepted source/contract review; docs/dev-log/cmr/m0-acceptance.md; 719 enumeration fixtures and four finite-reference layouts verified; production acceptance remains separate

- [x] G1: exact acceptance
  CHECK: env OPENBLAS_NUM_THREADS=1 Rscript tools/check-cmr.R --gate exact
  EXPECT: CMR_EXACT_OK
  CWD: .
  EVIDENCE: exit=0; shell=/bin/zsh; cwd=/private/tmp/cmr-drmtmb-20261006; path=8d2e6e29f6f6/39 entries; output=Julia bridge: 0 live tests ran, 0 skipped; the LIVE ENGINE was not exercised in this configuration (mock-driven marshalling tests are counted by CI's 'Julia bridge glue executes (mock-driven, no Julia)' step). | Julia bridge: 0 live tests r

- [x] G2: derivatives acceptance
  CHECK: env OPENBLAS_NUM_THREADS=1 Rscript tools/check-cmr.R --gate derivatives
  EXPECT: CMR_DERIVATIVES_OK
  CWD: .
  EVIDENCE: exit=0; shell=/bin/zsh; cwd=/private/tmp/cmr-drmtmb-20261006; path=8d2e6e29f6f6/39 entries; output=CMR_DERIVATIVES_OK | Julia bridge: 0 live tests ran, 0 skipped; the LIVE ENGINE was not exercised in this configuration (mock-driven marshalling tests are counted by CI's 'Julia bridge glue executes (mock-driven, no Julia)' step).

- [ ] G3: integration acceptance
  CHECK: env OPENBLAS_NUM_THREADS=1 Rscript tools/check-cmr.R --gate integration
  EXPECT: CMR_INTEGRATION_OK
  CWD: .
  EVIDENCE: pending

- [ ] G4: selection acceptance
  CHECK: env OPENBLAS_NUM_THREADS=1 Rscript tools/check-cmr.R --gate selection
  EXPECT: CMR_SELECTION_OK
  CWD: .
  EVIDENCE: pending

- [x] G5: parity acceptance
  CHECK: env OPENBLAS_NUM_THREADS=1 Rscript tools/check-cmr.R --gate parity
  EXPECT: CMR_PARITY_OK
  CWD: .
  EVIDENCE: exit=0; shell=/bin/zsh; cwd=/private/tmp/cmr-drmtmb-20261006; path=8d2e6e29f6f6/39 entries; output=2: the ‘findbars’ function has moved to the reformulas package. Please update your imports, or ask an upstream package maintainer to do so. | This warning is displayed once per session.

- [ ] G6: recovery acceptance
  CHECK: env OPENBLAS_NUM_THREADS=1 Rscript tools/check-cmr.R --gate recovery
  EXPECT: CMR_RECOVERY_OK
  CWD: .
  EVIDENCE: pending

- [ ] G7: documentation acceptance
  CHECK: env OPENBLAS_NUM_THREADS=1 Rscript tools/check-cmr.R --gate documentation
  EXPECT: CMR_DOCS_OK
  CWD: .
  EVIDENCE: pending

- [ ] G8: existing regression suite
  EVIDENCE: pending

- [ ] G9: M2 fresh completion panel
  EVIDENCE: pending

- [ ] G10: M3-M4 fresh completion panel
  EVIDENCE: pending

- [ ] G11: M5 selection completion panel
  EVIDENCE: pending

- [ ] G12: M6 final audit and reconciliation
  EVIDENCE: pending

- [ ] G13: fixed-effects bridge admission
  EVIDENCE: pending

