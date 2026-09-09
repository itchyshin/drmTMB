# C1 residual-boundary start probe

This bounded diagnostic replayed immutable C1 seed `2026091002` on the current
OU branch. It used the production `nlminb` control and changed only the starting
residual log-SD. It did not overwrite the retained pilot or initiate a campaign.

| residual SD start | objective | convergence |
| ---: | ---: | ---: |
| 0.4 | 618.883549324 | 0 |
| 0.1 | 618.883549221 | 0 |
| 0.01 | 618.883548969 | 0 |
| 1e-4 | 618.883548215 | 1 |
| 1e-6 | 618.880626547 | 1 |

This start probe predates the current AR1 transition-stability repair. Its
lowest recorded objective does not agree with the independent dense marginal
oracle and must not be treated as the current ML value. The current source
reproducibly selects the oracle-matched positive-definite candidate for this
historical seed. The table remains retained as an explanation of the former
numerical failure, not as current inference evidence.

The current method decision instead rests on a separate current-source seed
whose independent dense profile reaches the residual boundary with unavailable
covariance; see `c1-current-source-reconciliation-2026-09-09.md`.

## Cross-package precedent

The locally installed `glmmTMB` troubleshooting vignette identifies near-zero
dispersion and random-effect variances as common causes of a non-positive-
definite Hessian and `NaN` standard errors. It advises treating the model as
poorly fitted rather than silently using the objective for inference. Its
covariance vignette sets dispersion to a small controlled value only for models
that intentionally specify `dispformula = ~0`; that is a different estimand
from the current model, which includes residual `sigma`.

This supports retaining the unavailable-inference diagnostic at an active
residual boundary. It does not choose between revising the coverage-availability
criterion and adding a separately validated constrained-boundary method.
