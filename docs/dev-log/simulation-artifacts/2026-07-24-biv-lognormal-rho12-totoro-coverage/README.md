# Arc 6 direct bivariate-lognormal `rho12` coverage result

**Result:** the predeclared fixed-effect direct-lognormal coverage gate passes
for the tested domain. This supports profile likelihood as the primary interval
for constant `rho12` in this exact model; Wald and joint parametric bootstrap
are grid-specific comparators whose coverage was measured here. It does **not** establish a
general non-Gaussian, random-effect, predictor-varying, Student-t, missing-data,
or staged-eta inference claim.

## Reproducibility

Totoro ran commit `1e5bd4291f0bc1aaaaf9b13a072f434a38dad0f0` with package
version 0.6.0, `OPENBLAS_NUM_THREADS=1`, 90 outer workers, 300 outer attempts
per cell, and 199 whole-model bootstrap attempts per outer fit. The immutable
grid is `n = 100, 300, 1000` by true `rho12 = 0, 0.5, 0.85`, giving 2,700 outer
fits and 537,300 bootstrap refits. The machine-readable manifest and compact
method summary are tracked beside this file. Full outer and bootstrap attempt
ledgers remain local on the campaign checkout and Totoro; they are ignored here
because the latter is 117 MB.

The local campaign checkout and Totoro source checkout retain the full ledgers
at this artifact path. Their SHA-256 digests are:

```text
47f224e0d654faa3a104a8dcfc7892730579b36838d032a1ad051dd263572518  direct-biv-lognormal-rho12-attempts.csv
fc91f4cd6587f0b3fed4ca7f01c7515736a7500ac3e42ca7c68cab354801ebd7  direct-biv-lognormal-rho12-bootstrap-attempts.csv
```

## Failure behaviour

- All 2,700 fits returned an object and had `pdHess = TRUE`; 2,699 reported
  optimizer convergence zero.
- The single outer false-convergence diagnostic was `n=1000`, `rho12=0.85`,
  seed `2026972434`; it is retained in the local all-attempt ledger.
- Profile endpoints were finite for 2,698/2,700 attempts. The two retained
  endpoint failures were also at `n=1000`, `rho12=0.85` (seeds `2026972519`
  and `2026972674`); both had successful outer fits and `pdHess = TRUE`, but a
  constrained endpoint re-optimization returned false convergence.
- Bootstrap refits retained 537,022 successful and 278 non-converged attempts
  (0.052%); each outer interval had 194--199 usable bootstrap draws, so all
  2,700 percentile intervals were available.

## Coverage summary

The table gives conditional 95% coverage and exact binomial intervals. `all`
counts unavailable intervals as non-covering. Profile meets the predeclared
gate at every `n >= 300` cell: at least 98% convergence/PD-Hessian and finite
interval availability, with the conditional-coverage interval overlapping
`[0.925, 0.975]`.

| n | truth | Wald | Profile | Bootstrap |
| ---: | ---: | ---: | ---: | ---: |
| 100 | 0.00 | 0.943 (0.911, 0.967) | 0.947 (0.915, 0.969) | 0.947 (0.915, 0.969) |
| 100 | 0.50 | 0.953 (0.923, 0.974) | 0.953 (0.923, 0.974) | 0.937 (0.903, 0.961) |
| 100 | 0.85 | 0.957 (0.927, 0.977) | 0.957 (0.927, 0.977) | 0.953 (0.923, 0.974) |
| 300 | 0.00 | 0.940 (0.907, 0.964) | 0.940 (0.907, 0.964) | 0.943 (0.911, 0.967) |
| 300 | 0.50 | 0.940 (0.907, 0.964) | 0.943 (0.911, 0.967) | 0.937 (0.903, 0.961) |
| 300 | 0.85 | 0.947 (0.915, 0.969) | 0.947 (0.915, 0.969) | 0.957 (0.927, 0.977) |
| 1000 | 0.00 | 0.947 (0.915, 0.969) | 0.947 (0.915, 0.969) | 0.937 (0.903, 0.961) |
| 1000 | 0.50 | 0.963 (0.935, 0.982) | 0.963 (0.935, 0.982) | 0.967 (0.940, 0.984) |
| 1000 | 0.85 | 0.957 (0.927, 0.977) | 0.956 (0.927, 0.977); all 0.950 | 0.960 (0.931, 0.979) |

At this regular fixed-effect DGP, Wald and profile are nearly identical. That
is an observed property of this grid, not a reason to bypass profile or its
endpoint diagnostics on a new data set.
