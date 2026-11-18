# Integration, independent review and handover

OWNS: .Rbuildignore, docs/dev-log/check-log.md, docs/dev-log/after-task/2026-09-08-temporal-ar1-implementation.md, docs/dev-log/plan-actual/2026-09-08-temporal-ar1.md, docs/dev-log/plans/2026-09-08-temporal-ar1/implementation-review.md

- [ ] G14: The current source package check completes with zero errors, warnings and notes
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R G14
  EXPECT: TEMPORAL_G14_PASS
  EVIDENCE: pending

- [ ] G15: Independent mathematical/API/user reviews, final re-verification, after-task and plan-versus-actual closeout cover every original requirement
  EVIDENCE: pending

Before G14, exclude `.unlazy` explicitly in `.Rbuildignore`. Make that source edit
before final re-verification so prerequisite receipts bind the final packaging rules.

Manual: reviewers cite specific tests/results at the final implementation source
revision, inspect all supported and refused methods, and inspect the article and
figures. A mathematical reviewer must examine independence of the oracle/DGP and
the four mutation failures. Ada re-runs every runnable leaf with --reverify and
compares source/DLL/test/reference/recovery hashes before recording this gate.
Missing, stale, skipped or abandoned requirements cannot be called feature-complete.
Evidence-only closure commits may follow without rerunning unchanged model work;
record both the implementation revision and closure revision with the same source
hashes. Preserve failures, findings, leases and local-only landing state.
