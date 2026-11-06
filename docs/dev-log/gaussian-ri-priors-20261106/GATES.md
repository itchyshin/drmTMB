# Gates: Gaussian random-intercept fixed-effect priors

OWNS: tools/gaussian-ri-prior-validation/**,docs/dev-log/gaussian-ri-priors-20261106/**

Scope: independent oracle first, both native engines and bridge validated on the approved one-IID-mean-intercept Gaussian route; reviewable isolated results with no merge or release.

- [x] G1: Independent oracle self-tests, high-precision checks and mutation controls all pass on frozen fixtures.
  CHECK: OPENBLAS_NUM_THREADS=1 /Users/z3437171/miniconda3/bin/python tools/gaussian-ri-prior-validation/verify.py --self-test
  EXPECT: ORACLE_SELF_TEST_PASS
  CWD: /Users/z3437171/.codex/worktrees/drm-priors-design-20261105/drmTMB
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/.codex/worktrees/drm-priors-design-20261105/drmTMB; path=e47cbc5e6903/39 entries; output=} | ORACLE_SELF_TEST_PASS

- [x] G1b: Frozen oracle sources, fixtures, limits and fitted references match the manifest.
  CHECK: shasum -a 256 -c SHA256SUMS
  EXPECT: fit-reference-totoro.json: OK
  CWD: /Users/z3437171/.codex/worktrees/drm-priors-design-20261105/drmTMB/tools/gaussian-ri-prior-validation
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/.codex/worktrees/drm-priors-design-20261105/drmTMB/tools/gaussian-ri-prior-validation; path=e47cbc5e6903/39 entries; output=fit-reference-totoro.json: OK | fit-provenance.md: OK

- [ ] G2: R native engine passes independent fixed-point, derivative, conditional ridge and fitted-objective checks at the frozen thresholds.
  EVIDENCE: pending source-pinned candidate receipts

- [ ] G3: Julia native engine passes the same independent checks without GPL source copying.
  EVIDENCE: pending source-pinned candidate receipts and license review

- [ ] G4: R-to-Julia bridge passes all twelve fixtures and selector/refusal controls against the oracle, independently of native pair agreement.
  EVIDENCE: pending preflight and final twelve-fixture grid

- [ ] G5: No-prior/zero-ridge regression, inference fences, update/reporting, focused affected tests and measured full suites pass or have explicitly adjudicated baseline failures.
  EVIDENCE: pending exact-source tests, bounded review and full-suite receipts

- [ ] G6: Documentation, examples, check-log and after-task reports match observed supported scope; independent reviewer signs off; PR1651 and dirty cleanup are preserved; no merge/release occurred.
  EVIDENCE: pending independent completion review and final protected-state checks
