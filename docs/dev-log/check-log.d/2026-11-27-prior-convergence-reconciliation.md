# Prior-table and convergence reconciliation

The isolated reconciliation combines the generalized prior-table candidate with the existing convergence diagnostic changes. Full-suite and live R–Julia bridge validation remain open.

| Check | Result | Scope |
| --- | --- | --- |
| Prior convergence contract | Pass | Penalized objective diagnostics, including the no-SE path |
| Prior table, oracle and generalized native tests | Pass | Three test files on the combined working source |
| Bivariate, input errors and bridge adapter tests | Pass with three live tests skipped | Bridge marshalling only; embedded Julia was not exercised |
| Convergence and temporal tests | Pass | Four focused files; these ran before the provisional CJS dispatch was removed |
| Convergence help pages | Pass | Four Rd files parsed |

The code-bearing combined patch before this log entry has SHA-256 `534c6af25cb98eef943a4deeebe4f78a7d4b19f155c6baf808fba47f145163be`, excluding pre-existing editor settings. Logs and the patch are retained under `~/.codex/evidence/unified-prior-table-20261127/convergence-reconcile-focused/`. The prior-convergence, native-table and adapter logs have SHA-256 `1109e9b0dfe201719ce6d120f823fb99133fa41df86486aced302fb22abee0cc`, `9bbd06db6f4a547aa5395a29398d94235fb2d68971e550d831b1b93f33da96a5` and `85f6e649808e7b0562e6b235e65ffce0c83352b0f00aaa137ac2e8427573db67`, respectively. The source is still being reviewed and is not frozen for release.
