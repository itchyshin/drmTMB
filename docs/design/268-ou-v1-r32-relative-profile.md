# R3.2: exact small-tree relative profile

R3.1 established that direct and Laplace *absolute* objectives can differ at
fixed independent OU hyperparameters. R3.2 asks the narrower decision-bearing
question: on the same small data set, does that difference change relative
profile ordering between an interior and a high-rate/low-amplitude setting?

The four cells are the Cartesian product of these retained pairs:

| component | interior | ridge |
| --- | ---: | ---: |
| `(alpha_mu, alpha_sigma)` | `(0.7, 1.3)` | `(8, 8)` |
| `(sd_mu, sd_sigma)` | `(0.45, 0.25)` | `(0.19, 0.057)` |

At every cell native TMB maps all four hyperparameters fixed and optimizes the
location and log-scale intercepts. An independent stationary-tip
six-dimensional product Gauss--Hermite calculation uses those intercepts.
Nine nodes per dimension are the common direct calculation; five and seven
nodes are retained for every cell. The output
compares ranks and pairwise objective differences, not parameter estimates.

This is a three-tip estimator diagnostic. It cannot establish recovery,
quantify approximation error at 128 tips, validate a new estimator, or
authorize G15. If the relative order disagrees, rate-recovery work pauses for
an estimator-design decision. If it agrees, the alpha--amplitude geometry
remains the leading explanation but still requires separate recovery evidence.
