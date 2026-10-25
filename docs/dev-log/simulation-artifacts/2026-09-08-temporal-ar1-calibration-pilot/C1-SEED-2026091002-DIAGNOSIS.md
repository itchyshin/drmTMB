# C1 seed 2026091002 inference diagnosis

The primary-cell C1 pilot result for seed `2026091002` was replayed once with
the same frozen generator and estimator to identify why its interval was
unavailable. The selected optimizer converged, but the residual log-SD estimate
was `-8.98805`, or residual SD approximately `0.000125`. The ordinary-intercept
SD (`0.52766`), temporal-process SD (`0.87788`), and persistence (`0.37783`)
were interior.

At that residual boundary `fit$sdr$pdHess` was `FALSE`; the observed-information
diagonal corresponding to `beta_sigma` was `-6651.8`. The fitting interface
therefore correctly marks covariance and Wald intervals unavailable rather than
returning invalid uncertainty. This explains the pilot's `NaNs produced`
warning and its 4/5 C1 interval availability.

This is a diagnosis of the retained seed, not a repair. The next method step is
to investigate residual-boundary frequency and the likelihood geometry before
requesting campaign authority or changing the model parameterization.
