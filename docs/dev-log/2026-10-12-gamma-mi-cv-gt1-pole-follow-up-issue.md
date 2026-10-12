# Follow-up issue draft (file from a token that can create issues)

This run cannot open GitHub issues. Paste the title and body below
into a new issue that refs #1477. Do not close #1477.

## Title

Gamma mi() adaptive GH misses the pole at CV > 1

## Body

Refs #1477.

Posterior-mode Gauss-Hermite for Gamma `mi()` now uses each response
family's own log-density gradient and Hessian, skips a non-negative
Hessian, and falls back to the prior mode. Near the pole and in the
tail at CV 0.05, 0.5, and 1 the per-row logLik error versus a
fine-split `integrate()` on `u = log(x)` is under `1e-4`. Poisson
times Gamma at CV 1 is `5.17e-5`.

At CV 2 with `y = 2.05`, `mu_y = 2`, `sd_y = 0.1`, `beta_x = 0.5`,
`mu = 10` (posterior piled near `x ≈ 0.1`), the same 51-node rule is
still `9.51e-2` log units off. The test
`Gamma adaptive GH at CV > 1 near the pole is a labelled skip (#1477)`
skips and names this follow-up. Do not loosen that `1e-4` pin.

A later rule needs either more than one mode, a heavier-tailed
proposal, or a different transform so the pole at CV `> 1` matches
`integrate()` without moving the CV `<= 1` numbers.
