# Native Binomial animal pedigree plus relmat K

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-pedigree-relmat-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0; seven expectations passed without warnings. Animal pedigree plus relmat K matched the pedigree-derived A-matrix fit in likelihood, SD coefficients, and named predictions.

Evidence reconciliation passed with 19,678 candidate rows, 113 linked rows, 19,565 unlinked rows, and 135 records. Source hashes and console output are in `docs/dev-log/general-sd-regression/evidence/native-binomial-animal-pedigree-relmat-sd-20261027/`. No interval-coverage or Julia-parity claim.
