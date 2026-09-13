# R3.1 exact marginal diagnostic

This two-point, three-tip calculation tests a narrow estimator question: at
fixed OU rates and phylogenetic field SDs, how close is TMB's Laplace marginal
objective to a direct stationary-tip Gaussian integral? It is neither a rate
recovery study nor evidence for a general OU capability.

| point | Laplace objective | 9-node quadrature objective | Laplace minus quadrature | 7-to-9 refinement |
| --- | ---: | ---: | ---: | ---: |
| interior | 5.80587 | 6.21236 | -0.40649 | 0.02200 |
| ridge | 4.66645 | 4.73996 | -0.07351 | 0.00014 |

The ridge quadrature is numerically stable at the retained resolution. The
interior calculation is substantially more stable than at five nodes, but its
0.022 7-to-9 refinement means that its direct value is not claimed exact. The
much larger 0.406 difference from Laplace is therefore retained as evidence of
a material approximation contribution in this diagnostic, pending independent
review. It does not by itself quantify the contribution in the 128-tip R2
fits or decide whether an alternative estimator can recover the two rates.
