# Native Bernoulli ordinary-intercept SD calibration

OWNS: tools/general-sd-regression/native-calibration/, docs/dev-log/general-sd-regression/evidence/calibration-20261017/
Scope: native logit Bernoulli scalar intercept, G160/m16, slope truths -0.5/0/0.5, original ede274ab... source/library capsule. Global G5 preceded harness work; this bounded leaf is written before production fits. Qualification and timing repeats are not calibration replicates.

- [x] C1: Frozen generator, integrity, staged analyzer and owned-process cleanup controls pass
  CHECK: OPENBLAS_NUM_THREADS=1 python3 tools/general-sd-regression/native-calibration/self-test.py
  EXPECT: NATIVE_CALIBRATION_SELF_TEST_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression; path=e0fb875d37d1/39 entries; output=NATIVE_CALIBRATION_SELF_TEST_PASS integrity=pass dgp=pass identities=pass supervisor_cleanup=pass
- [x] C2: Externally sealed live qualification and 15-process timing stress pass
  EVIDENCE: qual02 full summary passed3 healthy profiles. Final seal ad8ab89... stress passed all15 healthy profiles/five summaries; peak15 concurrency; max13.1497s,188 waves+180s=2652.14s under3000s gate and3600s cap. Sol independently recomputed; no calibration claim.
- [ ] C3: First-look production retains all3000 attempts with complete source-bound receipts
  EVIDENCE: launched2026-10-17T22:05Z; Totoro supervisor2920795; registryd2e1080d...; master1703,16 workers, per-case120s, campaign3600s; first46 completed rows observed, no retries. Complete3000 readback pending.
- [ ] C4: Frozen two-look decision accepts or records a nonqualifying outcome without relaxing margins
  EVIDENCE: not evaluated; nominal95% profile coverage with97.5% metric intervals at each look. A nonqualifying first look cannot satisfy global G5; stage2 uses preassigned9000 additions only if the frozen ambiguity rule requests it, and any run over3h requires specific compute approval.
- [ ] C5: Independent inference readback, scoped claims and complete checkpoint agree
  EVIDENCE: pending production analysis/review; one domain cannot promote other links, endpoints, effect types, providers or engines.
