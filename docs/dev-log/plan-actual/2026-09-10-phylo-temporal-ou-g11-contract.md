# Plan versus actual — phylogenetic-temporal OU G11 calibration contract

## Planned

Freeze P1--P4, three fixed mean targets, all-attempt endpoint handling, coverage-tail reporting, acceptance criteria, Monte Carlo precision, and fail-closed checks before any campaign proposal.

## Actual

The retained contract has 3,500 tasks: 1,000 each in P1--P3 and 500 in P4. It has 12 cell-target rows and specifies 95% profile endpoints for intercept, between-species, and within-species effects. The assessment helper carries all-attempt and conditional coverage, lower and upper tail fields, availability, bias, empirical SD, profile-width SE analogue, and primary qualification criteria. P4 is report-only stress evidence.

## Evidence

- `docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g11-contract/`
- `Rscript --vanilla tools/run-phylo-temporal-ou-g11-contract.R --self-test`
- `Rscript --vanilla tools/phylo-temporal-ou-gates.R G11`

## Variance

This no-fit preparation completed in seconds. It does not change the measured G10 estimate of 335.080 seconds for 20 datasets, nor does it authorize the 3,500-dataset campaign. The next action is an explicit G12 campaign decision.
