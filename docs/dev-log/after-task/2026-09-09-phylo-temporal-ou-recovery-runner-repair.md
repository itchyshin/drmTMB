# After-task — phylogenetic-temporal OU recovery runner repair and diagnosis

## 1. Goal

Repair the future G9 recovery runner after paired-model component labels changed, and determine which estimand caused the retained recovery failure.

## 2. Implemented

The runner now retrieves paired OU decay through `temporal_mu_decay_label()`. A focused methods regression confirms that this helper resolves the public `decay_temporal` entry. A disposable six-species, 24-fixture smoke retained all 24 finite decay estimates; it was deleted because it is neither the frozen G9 denominator nor claim-bearing evidence.

## 3a. Decisions and Rejected Alternatives

The immutable v4 and v6 recovery artifacts were not rewritten. The aggregate threshold, seeds, fixture count, and G9 status remain unchanged. The repair applies only to a future deliberately authorized rerun.

## 4. Files Touched

- `tools/run-phylo-temporal-ou-recovery.R`
- `tests/testthat/test-phylo-temporal-ou-methods.R`
- `docs/dev-log/check-log.md`
- this report and matching plan-versus-actual record

## 5. Checks Run

The focused methods suite passed. The disposable six-species smoke created 24 selected rows with 24 finite `decay_estimate` values after the repaired lookup. `git diff --check` passed before commit.

## 6. Tests of the Tests

The smoke deliberately used only six species, so its recovery criteria failed and it cannot replace G9. It nevertheless exercised every balanced and unbalanced fixture and caught the old label lookup that would otherwise have made a future full rerun fail during result extraction.

## 7a. Issue Ledger

G9 remains failed. In v4, intercept, between-species, and within-species coefficient MAEs were 0.339, 0.131, and 0.077. In v6 they were 0.336, 0.104, and 0.055. The aggregate criterion therefore fails because the sampled stable phylogenetic intercept shifts the realised population mean; the two scientifically varying contrast effects meet the original aggregate bound separately.

## 8. Consistency Audit

The paired model estimates a fixed intercept alongside one realised tree-correlated stable vector. The retained tree draws are finite samples with a zero distributional mean, not a constraint that each realised stable vector has exactly zero tip average. Persistent intercept error across 50 and 80 species is therefore consistent with the model’s estimand and does not demonstrate a decay, temporal-SD, or treatment-contrast routing error.

## 9. What Did Not Go Smoothly

The label improvement added after the retained recovery run made the runner's old direct formula-label lookup stale. A documentation example exposed the mismatch before a later recovery campaign did.

## 10. Known Residuals

A revised recovery contract requires an explicit decision. The current predeclared aggregate fixed-effect threshold remains failed; no interval calibration, campaign, forecasting, `newdata`, or next temporal structure is qualified.

## 11. Team Learning

For a correlated stable random intercept, finite-tree population-mean error and contrast-effect recovery answer different questions. A recovery contract must declare whether it evaluates conditional realised intercept accuracy, ensemble bias, or reportable contrasts before running its seeds.

## 12. Cross-Product Coverage

This repair and diagnosis does NOT cover the separable phylogeny-by-OU field, AR1, Toeplitz, heterogeneous AR1/Toeplitz, ARMA, seasonal, random-walk, or temporal Matérn structures.
