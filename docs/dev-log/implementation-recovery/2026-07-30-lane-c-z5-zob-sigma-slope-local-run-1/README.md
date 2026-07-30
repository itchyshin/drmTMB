# Lane C Z5 — zero-one-beta sigma q1 slope local recovery receipt

## Exact target

This receipt concerns only ordinary ML `zero_one_beta()`:

```r
bf(y ~ x, sigma ~ x + (0 + x | id), zoi ~ 1, coi ~ 1)
```

For the centred numeric slope `x`, the interior-beta log-scale predictor is
`log(sigma_i) = X_sigma[i, ] beta_sigma + x_i exp(log_sd_sigma) u_id[i]`,
where `u_g ~ N(0, 1)`. The atom probabilities remain fixed-effect intercepts.
The source gate requires the fixed and random sigma predictors to be identical.

## Retained local result

The source SHA is `1994ab65f4ad38f84b0f35e9a21891507b9f8af1` and the runner
MD5 is `70284a00126e106ec119ae2676945ff4`. The four fixed seeds in
`raw-attempts.tsv` all converge with `pdHess = TRUE`, gradients at most 0.00477,
finite non-boundary SD estimates, inactive scale clamp, nonzero zero/one atoms
and interior observations in every group, and mode correlations 0.965--0.977.
The mean relative SD error is 0.0613. `fixed-sigma-boundary-diagnostic.tsv`
records the separate zero-true-SD diagnostic; it is not recovery or interval
evidence.

## Claim boundary

This is local technical point-fit recovery evidence only. The direct sigma-SD
target is visible but `profile_ready = FALSE` with
`profile_note = "point_fit_only_zero_one_beta_sigma_q1"`; default, direct, and
endpoint profile dispatch are fenced before a refit. No profile, interval,
bootstrap, coverage, calibration, missing-response, covariance, atom random
effect, structured provider, or joint-dpar claim follows from this receipt.
