# Check log: Binomial animal-slope provider equivalence

Command:

```sh
OMP_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-slope-sd-regression")'
```

Result: `FAIL 0 | WARN 0 | SKIP 0 | PASS 32`, 42.0 seconds. The new synthetic
test fits one Bernoulli animal slope-only SD model through pedigree, covariance
`A`, and a label-permuted precision `Ainv`. Log likelihoods, SD coefficients,
and group-name-aligned SD predictions agree; the fitted SD slope is positive.

This receipt covers one native TMB q1 animal-slope fixture. It does not add
production code or establish Julia parity, broad provider support, interval
calibration, or other family/effect rows. The test file SHA-256 is
`e705e652a2e69b89597e617af8c4e156e61bf69574a8aa22d88cdd03e53ef482` at
candidate HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`.
