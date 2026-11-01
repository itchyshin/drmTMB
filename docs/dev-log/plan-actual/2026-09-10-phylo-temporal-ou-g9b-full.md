# Plan versus actual — G9b full phylogenetic-stable plus independent OU recovery

## Planned

Run a new frozen 24-fixture contrast study and a separate 300-tree ensemble intercept study. Preserve every fit, start, failure, warning, manifest, and provenance record. Keep original G9 failed regardless of G9b.

## Actual

The successful v5 run retained every requested denominator: 24 contrast fits and 48 starts, plus 300 independent-tree ensemble fits and 600 starts. All G9b-A criteria passed: between/within MAE 0.123/0.071, median absolute log-SD error 0.163, and median absolute log-decay error 0.280. The three ensemble standardized signed-bias diagnostics were 0.032, 0.072, and 0.063, all below 0.10.

## Evidence

- `docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g9b-full-v5/criteria.csv`
- `docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g9b-full-v5/provenance.csv`
- `Rscript --vanilla tools/phylo-temporal-ou-gates.R G9b-full`

## Variance

The initial 5--10 minute estimate was conservative: the successful four-minute run stayed below the 15-minute stop limit. Four runner-level setup attempts preceded v5; their immutable partial artifacts are retained, and no seeds, thresholds, or successful results were reused. This outcome repairs point-recovery evidence only and does not advance to Toeplitz or qualify interval claims.
