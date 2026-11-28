# 2026-11-27 — convergence gradient (#1452)

Branch `cursor/convergence-gradient-1452-beb6`: merged `origin/claude/converged-rule-drm-20261118`
(adopted converged rule, SHINICHI-1753-1118). Capability-ledger C17 receipt left at `main`
(no recertify run in cloud).

## Tests (local, R 4.3.x, `NOT_CRAN=true`, pkgload)

- `test-student-large-nu.R`: 23 pass (closes #1462 regression on branch)
- `test-convergence-status-twin.R`: 79 pass before new test; re-run after adding #1452 cars case
- Manual #1452 repro: `is_converged` FALSE, `convergence_status` `not_converged`,
  `max_gradient` ≈ 1.18 on `cars` with `dist * 1e4`