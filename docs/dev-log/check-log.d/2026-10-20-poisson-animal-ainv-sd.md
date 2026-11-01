# Native Poisson animal SD regression with Ainv precision

The existing native Poisson animal route also fits a predictor-dependent SD
when given `animal(1 | id, Ainv = Q)`. A new seeded test uses `Q = solve(A)`
from the same non-invariantly ordered covariance used to generate the latent
effects. It checks matrix-name order, point recovery, group-SD prediction, and
constant-SD likelihood equivalence. All 10 assertions passed without warnings,
failures, or skips. Independent static review passed and prompted explicit
assertions that preserve the alignment challenge. This is native point-recovery
evidence only; pedigree-built inputs, Julia parity, and interval calibration
remain open.
The final combined animal/relatedness/grammar filter passed 84 assertions with
one existing `sd_phylo()` deprecation-throttle warning and no failures or skips.
`pkgdown::check_pkgdown()` found no problems; Pandoc emitted existing `--mathml`
deprecation warnings.
