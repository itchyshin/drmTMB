# Native Binomial animal-intercept SD inputs

The captured focused run includes three intended native Binomial logit test files for ordinary animal intercept SD regression with covariance `A`, inverse precision `Ainv`, and pedigree input. The tests use independent fixed-seed synthetic fixtures, check fitted SD targets and prediction names, and compare constant-SD formulas with the corresponding base model. They also include a recovery tolerance for the simulated SD slope.

Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-(sd-regression|ainv-sd-regression|pedigree-sd-regression)", reporter = "summary", stop_on_failure = TRUE)'`

Result: exit 0. The three target Binomial files passed 33 focused expectations in total. The broad filter also ran one adjacent Beta-binomial pedigree test (21 expectations passed) and matched a Julia bridge test file whose two live-engine checks were skipped because the Julia paths are not configured in this run; neither contributes to the native Binomial rows.

This is one-seed native fit, output, and constant-SD-equivalence evidence for Binomial logit animal intercepts with `A_covariance`, `Ainv_precision`, or pedigree input. Recovery tolerances are fixture checks, not a calibrated performance claim. No Julia parity or interval-coverage claim.
