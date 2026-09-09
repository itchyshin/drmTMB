# C1 boundary replay: current-source diagnostic

The retained AR1 C1 seed `2026091002` was replayed without changing the
immutable pilot outputs. The base AR1 source selected a lower candidate
(objective `618.882956`, residual SD `4.76e-06`, `pdHess = FALSE`). The current
OU source selected a nearby higher candidate (`618.883549`, residual SD
`2.24e-04`, `pdHess = TRUE`). Both use the same generated data and two signed
AR1 starts.

This is optimizer sensitivity near the residual-variance boundary, not evidence
that interval availability has been repaired. The lower objective remains the
relevant ML candidate, so G7 stays closed and OU Wald intervals remain guarded.
The next repair must make optimisation reliably select and diagnose the global
solution, then reassess interval availability; it must not prefer a higher
objective solely because its Hessian is positive definite.
