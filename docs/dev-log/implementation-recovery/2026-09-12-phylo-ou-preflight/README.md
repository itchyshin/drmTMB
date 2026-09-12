# Predictor-aware phylogenetic OU diagnostic preflight

This is the output from `tools/phylo-ou-recovery-preflight.R`, run at source
commit `9d78f85d5` with seeds `2026091201:2026091206`.  It is a 12-fit local
diagnostic, not a recovery, coverage, or interval-calibration campaign.

The clean design has 24 species with 8 observations each and truth
`alpha_mu = 0.8`; all six fits have a positive-definite Hessian but their
alpha estimates range from 0.211 to 5.188.  The deliberately weak design has
12 species with one observation each and truth `alpha_mu = 0.05`; three of
six fits have a non-positive-definite Hessian and all estimates are far from
the truth.  These failures are retained as negative evidence: they prohibit a
point-recovery, interval, coverage, or general inferential claim for this OU
slice.

The raw CSV is SHA-256
`de283bc17a178d5830953748ba78f9a0bfd5686e30ba496b180107098e25e64a` from the
original local receipt.
