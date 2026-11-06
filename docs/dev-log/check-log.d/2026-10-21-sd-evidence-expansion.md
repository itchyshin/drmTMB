# Check log: Bernoulli direct-SD evidence expansion (2026-10-21)

- Added two source-bound native Bernoulli random-intercept workflow receipts (profile and marginal simulation) and one Julia correlated q2 bridge smoke receipt. The integration test was excluded because its current source hash mismatches the retained manifest.
- Exact-key overlay: `EVIDENCE_RECONCILIATION_PASS candidate_rows=19118 linked_rows=4 unlinked_rows=19114 evidence_records=5`.
- All receipts remain unreviewed. Julia q2 remains unresolved and carries singular-Hessian warnings; this does not establish parity or inference readiness.
- After-task structure check passed; prose check reported zero findings. `git diff --check` passed on the owned paths.
- Candidate universe SHA-256 unchanged: `3183257b390c1994b2b0c6ffab0301943983089ab23b2ae6d57ed31682927253`.
- See `docs/dev-log/after-task/2026-10-21-sd-evidence-expansion.md`.
