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

- [x] G2: R native engine passes independent fixed-point, derivative, conditional ridge and fitted-objective checks at the frozen thresholds.
  EVIDENCE: R engine 5d0f1596; configured native R multi_start=5 with recorded RNG policy passed all twelve unchanged oracle checks; default ri_10 failure retained. Root independently reran all 36 comparisons with exit0. See guarded-numerical-evidence/SUMMARY.json and R-MULTISTART-POLICY.md.

- [x] G3: Julia native engine passes the same independent checks without GPL source copying.
  EVIDENCE: Julia ff10a2f9 passed all twelve unchanged oracle checks; root independently reran the downloaded results with exit0. Implementation uses native Julia objective and standalone generated data; source review found no imported R implementation. See completion-julia-review.md and guarded-numerical-evidence/.

- [x] G4: R-to-Julia bridge passes all twelve fixtures and selector/refusal controls against the oracle, independently of native pair agreement.
  EVIDENCE: bridge passed all twelve unchanged oracle fitted checks; guarded-source live focused tests passed87 expectations in47.25s, including selector mismatch, inference refusal and zero-ridge controls; exactsource/DLLreceipts in guarded-focused-live/. Numeric indicator transport preserves exact design; raw-factor frontend remains refused. Arbitrary-point bridge derivatives remain unavailable. See guarded-numerical-evidence/ and completion-inference-review.md.

- [x] G5: No-prior/zero-ridge regression, inference fences, update/reporting, focused affected tests and measured full suites pass or have explicitly adjudicated baseline failures.
  EVIDENCE: R 5d0f1596 full check passed 42125 expectations and source-tree 26516 with0 failures; all 3 hosted R platforms passed. Julia ff10a2f9 local 8-shard suite passed all 561 files and every JET gate. The existing unpenalized binomial convergence assertion has an independently adjudicated kernel-sensitive baseline exception: baseline 86ee and candidate ff10 each pass44/44 on Cooperlake and fail43/44 on Haswell, with identical within-kernel fit fields and condition diagnostics. Original candidate CI attempts remain failed; their actual historical kernel is unknown. No assertion, threshold or prior changed in this fixture. See kernel-pair-outcome-review.md and hosted-ci-baseline/kernel-pair/.

- [x] G6: Documentation, examples, check-log and after-task reports match observed supported scope; independent reviewer signs off; PR1651 and dirty cleanup are preserved; no merge/release occurred.
  EVIDENCE: ACCEPTANCE-AUDIT.json records exact production/test/API/oracle equivalence, original protected configuration hashes, PR1651 exact protected head, unchanged historical raw receipts and current draft PR states. After-task/check-log reports and PR descriptions explicitly retain the kernel-sensitive baseline exception and original red CI attempts. Independent source/runtime/inference/reader reviews and final kernel adjudication support bounded draft qualification. No merge, release or version bump occurred.

Requalification note: earlier numerical checks passed under recorded configurations. Fresh source-pinned numerical checks passed after the derived-ratio interval guard repair; local full-suite qualification passed; the bounded hosted baseline exception is independently adjudicated; final report/protection reconciliation is recorded in ACCEPTANCE-AUDIT.json. Frozen references and limits remain unchanged.

Repaired-source numerical receipts: R 5d0f1596 and Julia ff10a2f9 passed all 36 checks against unchanged frozen references. Root independently reran the comparator on downloaded outputs with exit0. See guarded-numerical-evidence/SUMMARY.json. Guarded live tests passed87 expectations including one actual bridge test; exact source/DLL receipts are in guarded-focused-live/. G5 is satisfied through its explicit baseline-exception path. G6 final report/protection reconciliation is recorded in ACCEPTANCE-AUDIT.json.
