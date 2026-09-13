# R4 geometry-aware recovery preflight

All six native fits converged with positive-definite Hessians, no warnings, no
boundary flag, and identical estimates across three dispersed starts. Numerical
convergence is therefore not the deciding issue in this screen.

| regime | truth `(alpha_mu, alpha_sigma)` | fitted `(alpha_mu, alpha_sigma)` | absolute log-rate errors |
| --- | --- | --- | --- |
| weak | `(0.7, 1.3)` | `(0.884, 2.792)` | `(0.233, 0.764)` |
| separated | `(0.3, 2.5)` | `(14.231, 4.160)` | `(3.859, 0.509)` |

Increasing amplitude and separating the two true rates did not create an
informative regime: it drove the location rate to a high-rate solution. This
one-seed screen neither proves a universal failure nor supplies a valid
multi-seed campaign design. The next design must vary within-species
replication, tree depth/topology, and rate/amplitude combinations under an
explicit profile-curvature criterion rather than assuming rate separation is
informative.
