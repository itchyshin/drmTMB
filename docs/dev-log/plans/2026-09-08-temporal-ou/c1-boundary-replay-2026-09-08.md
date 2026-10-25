# C1 boundary replay: current-source diagnostic

The retained AR1 C1 seed `2026091002` was replayed without changing the
immutable pilot outputs. The base AR1 source selected a lower candidate
(objective `618.882956`, residual SD `4.76e-06`, `pdHess = FALSE`). The current
OU source selected a nearby higher candidate (`618.883549`, residual SD
`2.24e-04`, `pdHess = TRUE`). Both use the same generated data and two signed
AR1 starts.

The independent dense marginal oracle subsequently established that the current
candidate matches the marginal objective (`618.883549144532` at its smallest
grid value), whereas the older lower objective does not. The older objective is
therefore a pre-repair numerical artifact, not an ML improvement. Current source
reproducibly returns the positive-definite candidate.

This corrects the historical C1 numerical failure but does not qualify temporal
Wald coverage. A separate current-source seed still has a genuine
residual-variance boundary and unavailable covariance; see
`c1-current-source-reconciliation-2026-09-09.md`.
