# After-Task: Gaussian Sigma Start Hardening

## Scope

This task hardened Gaussian fixed-effect `sigma` starts. The previous builders
started the `sigma` intercept from the residual scale and left all non-intercept
`sigma` coefficients at zero. The new helper uses a guarded residual log-scale
regression for univariate Gaussian `sigma` predictors and bivariate Gaussian
`sigma1` / `sigma2` predictors, then falls back to the old intercept-only start
if the candidate is non-finite or extreme.

## Evidence

- Focused test: `Rscript -e "devtools::test(filter = 'optimizer-contract')"`:
  102 passed.
- Focused test:
  `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`: 80 passed.
- Whitespace check: `git diff --check`.
- Ayumi beak evidence comment:
  <https://github.com/itchyshin/drmTMB/issues/570#issuecomment-4713358135>
- Real-data artifact:
  `/tmp/drmtmb-ayumi-evidence/beak-patched-sigma-start-20260615/patched-default.csv`

## Result

The new start helper changes the full beak initial scale coefficients from the
old all-zero slope vector to a residual-scale vector. That is an improvement in
the start builder, but it does not solve the full 10,440-tip beak sigma-phylo
failure: the real-data fit still returns false convergence in a starting-like
basin.

## Claim Boundary

Do not present this as Ayumi's beak fix. It is a first hardening step before the
needed `drmTMB#570` candidate-start/selection ladder.
