# Native-GMRF mesh repair: current-source C14 compatibility

This retained Totoro control authenticates the exact pushed PR #893 source at
`ba5c1bcdb288c30fa8350977e7e90dda3dd2220d` after drmTMB adopted TMB's native
normalized `GMRF()` density for the fixed-kappa mesh field.

The frozen runner retained 12/12 attempts: `mc-0568`, `mc-0569`, and
`mc-0576` each passed 4/4. These are model-15 non-regression controls only. The
receipt does not validate the mesh field scale, promote a model-15 cell, or
expand any recovery, interval, coverage, or range claim.

The run used one thread per fit on Totoro:

```sh
OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 \
C17_COMPAT_RUN_ID=2026-08-02-mesh-spde-native-gmrf-c14-final-ba5c1bcdb \
R_PROFILE_USER=/dev/null Rscript --no-init-file \
tools/run-lane-c-c17c1-c14-model15-compatibility.R
```
