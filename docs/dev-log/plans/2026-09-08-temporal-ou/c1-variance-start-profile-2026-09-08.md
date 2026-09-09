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

The objective decreases as the residual scale start approaches zero. This is
consistent with an active residual-variance boundary, not a missed interior
solution. Selecting the higher, positive-definite interior candidate would not
be maximum likelihood. The Gaussian AR1 model remains a valid point-fit route,
but the plan's full observed-Hessian Wald covariance is unavailable in this
case.

The next method decision must choose one of the following explicitly: retain
unavailable intervals at active variance boundaries and revise the availability
criterion; adopt a justified constrained-boundary inference method; or change
the scientific model to impose a residual-scale lower bound and revalidate the
resulting estimand. No choice is implemented here.
