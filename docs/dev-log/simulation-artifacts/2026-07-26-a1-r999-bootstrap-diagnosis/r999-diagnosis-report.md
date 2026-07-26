# R=999 paired marginal-bootstrap diagnosis

## Question

Does the original `R = 199` bootstrap-tail resolution materially explain the
undercoverage of percentile intervals for scalar random-effect SDs after the
marginal-resimulation repair?

The prespecified materiality rule requires both a paired coverage gain of at
least 0.020 and a paired 95% CI excluding zero. Marginal coverage intervals use
exact binomial CIs. The paired difference CI is a labelled normal approximation
for the mean of `I(R=999 covers) - I(R=199 covers)`.

## Results

| Cell | R | Coverage (exact 95% CI) | Median width |
|---|---:|---:|---:|
| `c01`: 10 groups x 4 | 199 | 0.835 (0.811, 0.857) | 0.6720 |
| `c01`: 10 groups x 4 | 999 | 0.836 (0.812, 0.858) | 0.6773 |
| `c03`: 50 groups x 4 | 199 | 0.928 (0.910, 0.943) | 0.3076 |
| `c03`: 50 groups x 4 | 999 | 0.931 (0.913, 0.946) | 0.3068 |

| Cell | R=199 only covers | R=999 only covers | Paired difference | Paired 95% CI | Material? |
|---|---:|---:|---:|---:|---|
| `c01` | 10 | 11 | +0.001 | (-0.0080, 0.0100) | No |
| `c03` | 7 | 10 | +0.003 | (-0.0051, 0.0111) | No |

## Interpretation

`R = 999` does not materially alter the percentile interval’s coverage in
either matched cell. It therefore rules down finite bootstrap-tail resolution
at `R = 199` as the dominant explanation for the observed A1 shortfall. This
does **not** distinguish between percentile behavior near the variance boundary
and low-group Laplace refit bias, and it does not prove that R=999 would never
matter in another design.

The next unblocked question is whether likelihood profiles are better
calibrated for this exact scalar A1 target. The separate profile comparator is
specified and smoke-tested, but its full campaign remains held for explicit
compute approval.
