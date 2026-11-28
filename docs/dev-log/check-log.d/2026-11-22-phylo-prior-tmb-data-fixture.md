# Phylogenetic TMB prior-data fixture

## Scope

The hand-built `phylo_prior_tmb_data()` fixture calls the TMB template directly for model types 93 and 94. The template reads prior input vectors globally, including when no prior is active. The fixture lacked several newly declared fields and caused six `MakeADFun()` errors before likelihood evaluation.

## Change

Added empty `prior_beta_df`, `prior_sd_dpar`, and `prior_cor_*` inputs to the synthetic data fixture. Updated its contract comment to cover all `DATA_*` declarations. No likelihood or prior calculation changed.

## Checks

- Before fix: `Rscript -e 'devtools::test(filter = "phylo-utils")'` reproduced the missing `prior_beta_df`, then `prior_sd_dpar`, errors in six TMB probes.
- After fix: same focused command passed 193 assertions, 0 failures, 0 warnings, 0 skips.
- `git diff --check -- tests/testthat/test-phylo-utils.R` passed.

## Limits

This is a test-fixture correction. It does not provide new prior-support evidence or a full package-suite result.
