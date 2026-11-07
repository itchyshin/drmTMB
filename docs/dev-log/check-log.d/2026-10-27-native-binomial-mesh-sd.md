# Native Binomial mesh SD check log (2026-10-27)

Source: branch `codex/general-sd-regression`, HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`.

- Focused combined check: `Rscript -e 'devtools::test(filter = "binomial-mesh-sd-regression|mesh-contract|binomial-phylo-sd-simulation")'` — PASS, 71 assertions, 0 failures, 0 warnings, 0 skips. Captured at `docs/dev-log/general-sd-regression/evidence/native-binomial-mesh-sd-20261027/test-console.log`.
- Evidence reconciliation: `python3 tools/general-sd-regression/reconcile_evidence.py` — PASS, 19,230 candidate rows, 82 linked, 19,148 unlinked, 102 evidence records.
- `git diff --check` on the scoped source, test and API-reference files — PASS.
- Targeted formula-reference Rd generation completed; the isolated temporary-package run warned about unresolved links because it did not include the package's other Rd topics. Full documentation build and package checks were not run.
- This is point-recovery and workflow evidence for one native Binomial logit mesh intercept. It is not interval-coverage evidence or a capability admission.
