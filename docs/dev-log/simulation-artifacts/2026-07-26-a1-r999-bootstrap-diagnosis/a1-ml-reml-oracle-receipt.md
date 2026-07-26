# Scalar A1 ML-versus-REML oracle receipt

## Invocation

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file a1_ml_reml_oracle.R
```

The command exited zero.  All six ML/REML fixture rows passed the fail-closed
oracle gate.

## Environment and provenance

| Field | Value |
| --- | --- |
| R | 4.6.0 |
| drmTMB | 0.6.0 |
| lme4 | 2.0.1 |
| TMB | 1.9.21 |
| oracle SHA-256 | `557cfcab8edec40f9a0f1c3f0b2229369d50a5bcd99f71387013672a8fb9fafc` |
| helper SHA-256 | `f23ee237b00c93f4b5ac20355679b86384278f051ee05dd4e980739eaf2f7178` |
| package tarball SHA-256 | `9fc6ad979ce0fcdffe83134e27352bb3af8efb4470c63ec4a5f303ffe731237c` |

## Six-row result

| Cell | Estimator | Endpoint reference | Upper-endpoint delta | Tolerance | Oracle |
| --- | --- | --- | ---: | ---: | --- |
| g10 | ML | lme4 ML profile | 0.000009 | 0.011245 | pass |
| g10 | REML | direct restricted likelihood | 0.000006 | 0.000200 | pass |
| g25 | ML | lme4 ML profile | 0.000002 | 0.010000 | pass |
| g25 | REML | direct restricted likelihood | 0.000003 | 0.000200 | pass |
| g50 | ML | lme4 ML profile | 0.000000 | 0.010000 | pass |
| g50 | REML | direct restricted likelihood | 0.000015 | 0.000200 | pass |

All six likelihood and random-effect SD comparisons met the `1e-5` tolerance.
The earlier apparent REML endpoint failure was traced to the comparator:
`lme4` 2.0.1's REML `profile()` followed the ML variance-component curve in
all three fixtures (largest endpoint difference `1.5e-10`).  It
is therefore retained for ML endpoint validation and point/likelihood parity,
but excluded from the REML endpoint test.  A direct dense restricted-likelihood
profile now validates the matching drmTMB REML endpoints.
