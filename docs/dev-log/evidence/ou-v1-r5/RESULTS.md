# R5 fixed-alpha OU sensitivity grid

This is a fixed-assumption sensitivity display on one retained 128-species
Gaussian fixture. BM is the baseline; OU values are not estimates.

| model | assumed alpha | AIC | location intercept | log residual scale |
| --- | ---: | ---: | ---: | ---: |
| BM | — | 1414.593 | 0.526 | -0.986 |
| OU | 0.1 | 1417.344 | 0.520 | -0.986 |
| OU | 0.3 | 1416.433 | 0.507 | -0.987 |
| OU | 0.7 | 1416.263 | 0.483 | -0.987 |
| OU | 1.3 | 1417.207 | 0.450 | -0.987 |
| OU | 2.5 | 1420.355 | 0.406 | -0.988 |

All six fits converged with positive-definite Hessians. BM has the lowest AIC
in this one fixture; among the assumed OU values, 0.7 is closest. The grid
demonstrates robustness to an assumed evolutionary-decay value. It neither
estimates alpha nor establishes that BM is generally preferred.
