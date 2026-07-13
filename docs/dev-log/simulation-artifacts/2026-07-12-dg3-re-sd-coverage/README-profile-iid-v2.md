# Arc 4a IID-v2 — profile coverage for ordinary random-effect SDs

This campaign replaces the centered-v1 Arc 4a evidence. It asks whether
drmTMB's profile interval is finite and how often it covers the population
random-effect SD when the simulated effects are independent draws from the
fitted Gaussian random-effect distribution.

## Design and provenance

The run used drmTMB 0.6.0.9000 from
`feature/arc4a-profile-coverage` at `2684a9d4`, compiled from source with
`pkgload::load_all()`. Totoro ran 64 workers with
`OPENBLAS_NUM_THREADS=1`. The design crossed three specifications with
`M = {8, 16, 32, 64}` and 1,200 replicates per cell: 14,400 attempted fits in
total. Every group had 12 observations; the binomial specification used 12
trials per observation. The Gaussian and binomial random-slope SD was 0.6, and
the lognormal `sigma` random-intercept SD was 0.4.

The generator MD5 is `bd51aa9d02df6950fa2e87ef3fa14945`. The retained
artifacts are:

- `profile-coverage-results-iid-v2-raw.tsv`: one row per attempted fit;
- `profile-coverage-results-iid-v2-summary.tsv`: summary reconstructed from
  the retained raw rows;
- `profile-coverage-results-iid-v2-manifest.tsv`: source, design, host, seed,
  output and worker provenance;
- `profile-coverage-iid-v2-campaign.log`: cell-completion log.

The raw, summary and manifest MD5 values are respectively
`0b811340124794ca722952fe2fa8b7a0`,
`7cbefb9634ae50c2df99bfd358f334bc` and
`d248815f78d9db51c555b067d4781e9a`.

## Corrected results

All 14,400 fits converged with `pdHess = TRUE`; every profile interval was
finite. Coverage is conditional on a finite profile interval, but the
conditional denominator equals all attempted replicates in every cell because
there were no fit or profile failures.

| Specification | M | Covered / finite | Profile coverage | MCSE | Exact 95% binomial CI | Truth below interval | Truth above interval |
|---|---:|---:|---:|---:|---:|---:|---:|
| Gaussian slope | 8 | 1107 / 1200 | 0.9225 | 0.0077 | [0.9059, 0.9370] | 14 | 79 |
| Gaussian slope | 16 | 1135 / 1200 | 0.9458 | 0.0065 | [0.9315, 0.9579] | 10 | 55 |
| Gaussian slope | 32 | 1129 / 1200 | 0.9408 | 0.0068 | [0.9260, 0.9535] | 17 | 54 |
| Gaussian slope | 64 | 1126 / 1200 | 0.9383 | 0.0069 | [0.9232, 0.9513] | 28 | 46 |
| Binomial slope | 8 | 1104 / 1200 | 0.9200 | 0.0078 | [0.9032, 0.9347] | 14 | 82 |
| Binomial slope | 16 | 1115 / 1200 | 0.9292 | 0.0074 | [0.9132, 0.9430] | 12 | 73 |
| Binomial slope | 32 | 1139 / 1200 | 0.9492 | 0.0063 | [0.9352, 0.9609] | 16 | 45 |
| Binomial slope | 64 | 1143 / 1200 | 0.9525 | 0.0061 | [0.9389, 0.9638] | 16 | 41 |
| Lognormal `sigma` intercept | 8 | 1105 / 1200 | 0.9208 | 0.0078 | [0.9041, 0.9355] | 13 | 82 |
| Lognormal `sigma` intercept | 16 | 1119 / 1200 | 0.9325 | 0.0072 | [0.9168, 0.9460] | 19 | 62 |
| Lognormal `sigma` intercept | 32 | 1109 / 1200 | 0.9242 | 0.0076 | [0.9077, 0.9385] | 27 | 64 |
| Lognormal `sigma` intercept | 64 | 1129 / 1200 | 0.9408 | 0.0068 | [0.9260, 0.9535] | 17 | 54 |

An independent read-back of the raw TSV reproduced every coverage count,
directional miss count, MCSE and Clopper-Pearson interval in the summary.

## D-43-ratified claim boundary

The evidence supports a finite, mildly anti-conservative profile interval, not
nominal 95% coverage and not a `supported` claim. The ratified domains are the
following discrete tested designs, with no extrapolation beyond those sets:

- `mc-0382`: lognormal `sigma` random intercept, true SD 0.4,
  `n_each = 12`, tested `M = {16, 32, 64}`;
- `mc-0061`: binomial independent `mu` random slope, true SD 0.6,
  12 observations per group and 12 trials per observation, tested
  `M = {32, 64}`.

For the binomial slope, profiling did not repair the small-M point-bias problem;
the proposed claim is coverage-backed only in the two tested cells above. This
campaign does not establish unbiasedness, nominal coverage outside the stated
cells, a correlated or labelled random-slope block, a random-slope claim for
Task B's random-intercept probe, REML, marginal-integration support, or the
`supported` tier. Fresh Noether, Fisher and Pat D-43 reviews unanimously
ratified `inference_ready_with_caveats` for both exact discrete domains above;
the reviews did not authorize extrapolation beyond those tested sets or any
stronger tier.
