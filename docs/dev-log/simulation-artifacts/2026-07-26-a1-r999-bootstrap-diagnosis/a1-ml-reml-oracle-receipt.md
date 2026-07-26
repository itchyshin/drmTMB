# Scalar A1 ML-versus-REML oracle receipt

## Invocation

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file a1_ml_reml_oracle.R
```

The command exited non-zero because its fail-closed gate detected two failing
REML profile endpoint rows.  This is the expected stop behavior, not a passing
oracle execution.

## Environment and provenance

| Field | Value |
| --- | --- |
| R | 4.6.0 |
| drmTMB | 0.6.0 |
| lme4 | 2.0.1 |
| TMB | 1.9.21 |
| oracle SHA-256 | `f96d3ea715dcdd31d1e1d886ddaae33ad0e648347b085db7b5a7ae585cc11a7a` |
| helper SHA-256 | `99a87dd0719357ff64c607c3d53a47daa126ec07eebe2d09ec9052e0d85b5853` |

## Six-row result

| Cell | Estimator | Oracle | Upper-endpoint delta | Tolerance |
| --- | --- | --- | ---: | ---: |
| g10 | ML | pass | 0.000009 | 0.011245 |
| g10 | REML | fail | 0.079768 | 0.011245 |
| g25 | ML | pass | 0.000002 | 0.010000 |
| g25 | REML | fail | 0.018972 | 0.010000 |
| g50 | ML | pass | 0.000000 | 0.010000 |
| g50 | REML | pass | 0.008910 | 0.010000 |

All six likelihood and random-effect SD comparisons met the `1e-5` tolerance.
The gate stops because profile endpoint agreement is jointly required.
