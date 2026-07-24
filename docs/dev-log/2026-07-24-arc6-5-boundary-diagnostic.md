# Arc 6.5 seed 650016 boundary diagnostic

## Question

The retained Arc 6.5 interior failure was not eligible for removal or a
post-hoc denominator change. This B0 diagnostic asks a narrower question:
does its `boundary_unresolved` status arise from a reproducible numerical
defect, or from the data's frozen-margin association likelihood?

## Reproduction

The exact simulated cell was regenerated from `n = 120`, asymmetric prevalence,
true `eta = 0.5`, replicate 1, seed `650016`. It was run at both the historical
campaign source `51647467196f9f212dea0bcb323fe649462f570d` and merged current
source `01818cfc8f29dd16e93838aad1ab9e0a1322f821`.

Both sources reproduce exactly the same fitted status:

| quantity | frozen source | current source |
| --- | ---: | ---: |
| status | `boundary_unresolved` | `boundary_unresolved` |
| association link | 2.8412830419507 | 2.8412830419507 |
| guarded latent association | 0.993212493186813 | 0.993212493186813 |
| log likelihood | -121.667840075343 | -121.667840075343 |
| optimizer convergence code | 0 | 0 |
| finite-difference score | 2.214051e-07 | 2.214051e-07 |
| finite-difference curvature | -8.526513e-06 | -8.526513e-06 |
| multistart disagreement | `TRUE` | `TRUE` |

The response-pattern table is

| `y_1` | `y_2 = 0` | `y_2 = 1` |
| --- | ---: | ---: |
| 0 | 36 | 59 |
| 1 | 0 | 25 |

The empty `(y_1 = 1, y_2 = 0)` cell is the relevant data geometry.

## Independent likelihood check

At a fixed association-link grid from -2 to 8, each row's discrete bivariate
normal rectangle was recomputed using `mvtnorm::pmvnorm()` with the Miwa
algorithm. The production and independent log likelihoods agree to less than
`3.1e-11` in the fitted/near-plateau region through association link 6. The
larger difference at deliberately extreme link 8 (`3.38e-05`) is outside the
fitted optimum and reinforces, rather than removes, the need not to report an
endpoint estimate.

The likelihood becomes effectively flat near the positive boundary: it is
-121.667840073615 at link 2.85 and -121.667840064890 at link 6, a difference
of only `8.73e-09`. The profile does not identify a stable finite interior
maximum. The multistart diagnostic therefore correctly withholds the estimate.

## Classification and decision

This is not an integration defect, endpoint-calculation defect, or optimizer
convergence failure. It is a near-boundary, weakly identified frozen-margin
association likelihood caused by the observed response geometry. The correct
disposition remains **HOLD**.

No source repair or recovery top-up is proposed from this diagnostic. A larger
campaign cannot turn this specific data geometry into an interior estimate; a
new sample-size floor or a changed boundary policy would be a new scientific
design decision, not a numerical correction. The original 220 attempts remain
the sole Arc 6.5 recovery receipt and are not pooled with this B0 replay.

## Reproducibility boundary

The read-only original artifacts remain at
`/home/snakagaw/hsq_work/arc65-runs/2026-07-24-51647467-r10/`. The two local
B0 bundles were written separately under `/private/tmp/drmtmb-arc65-b0-frozen`
and `/private/tmp/drmtmb-arc65-b0-current`; they are diagnostics, not campaign
artifacts or capability evidence. The regression test in
`test-associate-pairs-bernoulli-bernoulli.R` preserves the fail-closed behavior
for this exact seed.
