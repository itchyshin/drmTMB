# R3.1 exact marginal diagnostic

On one fixed 3-tip, three-replicate-per-tip data set, compare the native TMB
Laplace marginal objective against independent 5/7-node product
Gauss--Hermite integration at two retained points:

| point | alpha_mu | alpha_sigma | sd_mu | sd_sigma |
| --- | ---: | ---: | ---: | ---: |
| interior | 0.7 | 1.3 | 0.45 | 0.25 |
| ridge | 8 | 8 | 0.19 | 0.057 |

Rates and field SDs are fixed at these values in the native objective; fixed
location and log-scale intercepts are optimised and retained for the direct
integration. The direct integrator marginalises the six tip effects from their
stationary OU covariance. Retain tree/data hashes, intercepts, both native and
quadrature objectives, and the 5-to-7-node refinement. This is a small-tree
estimator diagnostic only: it neither validates 128-tip Laplace behaviour nor
authorises G15.
