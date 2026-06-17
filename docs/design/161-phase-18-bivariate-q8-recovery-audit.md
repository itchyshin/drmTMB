# Phase 18 Bivariate q8 Endpoint Recovery Audit

This note records the first local multi-cell audit of the ordinary bivariate
Gaussian q8 endpoint recovery lane. It is evidence for the diagnostic boundary,
not evidence for coverage, power, or tutorial-ready q8 inference.

## Aim

The audit asks whether the fitted q8 all-endpoint route can produce stable
replicate-level recovery artifacts for the model

```r
bf(
  mu1 = y1 ~ x + (1 + x | p | id),
  mu2 = y2 ~ x + (1 + x | p | id),
  sigma1 = ~ x + (1 + x | p | id),
  sigma2 = ~ x + (1 + x | p | id),
  rho12 = ~ 1
)
```

The latent group vector has eight endpoints:

```text
mu1:(Intercept), mu1:x,
mu2:(Intercept), mu2:x,
sigma1:(Intercept), sigma1:x,
sigma2:(Intercept), sigma2:x
```

so the fitted covariance block has eight SDs and 28 group-level correlations.
Residual `rho12` remains a row-level residual coscale parameter, not one of
those group-level correlations.

## Command

The audit ran locally on 2026-06-07 from branch `codex/q8-recovery-audit`:

```sh
/usr/bin/time -p Rscript -e 'devtools::load_all(".", quiet = TRUE); source("inst/sim/run/sim_run_actions_cell.R"); phase18_actions_main(c("--task=biv_gaussian_q8_endpoint_recovery", "--output-dir=inst/sim/results/actions/biv_gaussian_q8_endpoint_recovery_audit_20260607", "--n-reps=20", "--master-seed=20260635", "--cores=4", "--backend=multicore", "--overwrite=true"))'
```

The command wrote ignored local artifacts under
`inst/sim/results/actions/biv_gaussian_q8_endpoint_recovery_audit_20260607/`.
The wall-clock time was 106.57 seconds with four multicore workers.

## Grid

The grid used the recovery writer defaults:

| Cell | `n_id` | `n_each` | Requested replicates | Observations per fit |
| --- | ---: | ---: | ---: | ---: |
| `biv_gaussian_q8_endpoint_001` | 48 | 10 | 20 | 480 |
| `biv_gaussian_q8_endpoint_002` | 72 | 10 | 20 | 720 |

The DGP uses fixed location slopes, fixed log-scale slopes, eight endpoint SDs,
28 weak-to-moderate group-level correlations, and fixed residual
`rho12 = 0.08`. The runner deliberately uses `se = FALSE` so this lane remains
a tractable point-estimate recovery artifact rather than a coverage artifact.

## Results

The artifact writer completed and emitted aggregate, replicate, manifest,
failure, Wald-interval, Wald-coverage, interval-evidence,
interval-diagnostic, and interval-failure CSVs.

| Metric | Cell 001 | Cell 002 |
| --- | ---: | ---: |
| Manifest rows | 20 | 20 |
| Manifest `ok` rows | 19 | 19 |
| Optimization error rows | 1 | 1 |
| Completed fit objects with `converged = TRUE` | 5/19 | 3/19 |
| Model convergence rate in aggregate table | 0.263 | 0.158 |
| Positive-Hessian rate in aggregate table | 0.000 | 0.000 |
| Fit warnings among completed fit objects | 0/19 | 0/19 |
| Mean elapsed time per completed fit | 7.64 s | 11.40 s |

The two failed optimization replicates were:

| Cell | Replicate | Seed | Error |
| --- | ---: | ---: | --- |
| `biv_gaussian_q8_endpoint_001` | 15 | 1911789746 | `the leading minor of order 7 is not positive` |
| `biv_gaussian_q8_endpoint_002` | 4 | 148167276 | `the leading minor of order 8 is not positive` |

Both failed replicates also recorded `NA/NaN function evaluation`.

Among completed fit objects, fixed-effect and SD point recovery was much better
than the optimizer diagnostics. Mean absolute bias averaged 0.007-0.014 for
fixed location coefficients, 0.016-0.017 for fixed log-scale coefficients, and
0.038-0.040 for random-effect SDs across the two cells. The 28 derived
group-level correlations remained noisy: their mean absolute bias averaged
0.067 in cell 001 and 0.082 in cell 002, with worst absolute aggregate biases
near 0.40.

## Interval Status

The audit produced no usable Wald intervals. All interval rows had
`interval_status = "failed"` with the message
`missing or invalid estimate/std.error`, as expected from `se = FALSE`.
Profile and bootstrap intervals were not requested. Therefore this audit does
not support coverage, interval width, power, or null-rejection claims.

## Decision

Status: `hold_diagnostic`.

The q8 route remains fitted and artifact-ready, but the local 40-fit audit is
not promotion evidence. The main blockers are the two optimizer failures,
low model-convergence rates, zero positive-Hessian rate, and unavailable
intervals. The artifact is useful because it quantifies the q8 fragility
instead of hiding it behind a successful writer.

## Next Actions

1. Keep q8 coverage and q8 power outside the power grid until a stronger
   convergence/Hessian strategy exists.
2. If q8 is revisited, first test a smaller or constrained endpoint covariance
   design, stronger starts, or a deliberately larger `n_id`/`n_each` grid.
3. Keep q8 correlations labelled as derived and interval-unavailable until a
   validated direct, derived-profile, or bootstrap interval method exists.
