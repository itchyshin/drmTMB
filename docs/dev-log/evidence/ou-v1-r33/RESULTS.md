# R3.3 importance-sampling reference

This independent small-tree reference was designed to resolve the two cells
whose tensor-product quadrature had not converged in R3.2. It samples the six
standard-normal latent coordinates from a directly optimized,
Hessian-derived Gaussian proposal; it does not reuse TMB's random-effect
Laplace integral.

| cell | Laplace NLL | importance-reference NLL | Monte Carlo SE | minimum batch ESS |
| --- | ---: | ---: | ---: | ---: |
| ridge rate / interior amplitude | 5.72479 | 5.72781 | 0.00375 | 1277.8 |
| interior rate / interior amplitude | 5.80587 | 6.12928 | 0.00595 | 991.4 |

Both cells meet the predeclared reference criteria: eight independent batches
of 2,000 draws, batch SE at most 0.01 NLL, and ESS at least 200 in every
batch. Their reference ordering is resolved: the ridge-rate/interior-amplitude
cell is better by 0.40146 NLL, much larger than the retained Monte Carlo
uncertainty. The result supports the observed profile direction in this tiny
case; it does not quantify 128-tip approximation error, establish rate
recovery, or authorize G15.
