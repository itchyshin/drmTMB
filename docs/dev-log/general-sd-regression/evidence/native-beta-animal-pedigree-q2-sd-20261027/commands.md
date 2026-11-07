# Commands and budgets

Local native R 4.5.1 candidate, OPENBLAS_NUM_THREADS=1, OMP_NUM_THREADS=1, NOT_CRAN=true. Existing compiled DLL retained; no rebuild.

Red: devtools::test(filter="^beta-animal-pedigree-q2-sd-regression$",reporter="summary",stop_on_failure=TRUE); estimate15s, failed at intended provider guard.

Focused: same command after narrow R patch; estimate90s, actual31.088s, 32passed.

Regression: devtools::test(filter="beta-animal-(pedigree-)?q2-sd-regression|beta-animal-pedigree-sd-regression|^beta-sd-regression$|nongaussian-structured-mu-slope|gamma-relmat-q2-sd-regression",reporter="summary",stop_on_failure=TRUE); estimate210s, actual166.220s, 194passed, zero failures/errors/warnings/skips.

Example: pkgload::load_all(quiet=TRUE);source("inst/examples/beta-animal-pedigree-q2-sd.R"); estimate25s, actual8.683s, convergence0.

No interval coverage simulations. No full package check. Aggregate acceptance ledger checker unavailable, state UNKNOWN. Absolute-path prose checker and scoped git diff --check run during closeout.
