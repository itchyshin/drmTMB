# Check Log: Bernoulli Phylogenetic SD Timing and Recovery Pilot

## Design and DGP check

```sh
DRMTMB_PILOT_DEVTOOLS=true Rscript --vanilla tools/general-sd-regression/probes/bernoulli-phylo-calibration-pilot.R --self-test
```

Passed locally and on Totoro. The self-test verifies 16 tips, 12 responses per
tip, a standardized predictor, four design cells, and equality of the pruned
tree covariance with the matching original submatrix.

## Package build and installation

```sh
R CMD build --no-build-vignettes --no-manual <capsule>/drmTMB
OPENBLAS_NUM_THREADS=1 R CMD INSTALL --preclean --library=<isolated-library> drmTMB_0.7.1.tar.gz
```

The full-worktree build stopped while copying the 1.1 GB development archive.
The filtered source capsule built successfully. The exact tarball installed on
Totoro and loaded from its isolated library. Tarball SHA-256:
`54ed1b3a52113494528605f191c1d928c801731c2ee437b2ea7fa9e95e212a18`.

## Bounded Totoro run

```sh
PILOT_R_LIBRARY=<isolated-library> PILOT_R_DEPENDENCY_LIBRARY=/home/snakagaw/R/lib \
  PILOT_WORKERS=4 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 \
  timeout 1800s Rscript --vanilla bernoulli-phylo-calibration-pilot.R <empty-output-dir>
```

Final v4 exit status: 0. There are 12 rows, no fit errors, optimizer
convergence code 0 for all fits, 8 `profile` statuses, 3 `clamp_limited`
statuses, and 1 `profile_failed` status. Seven of eight finite intervals
contain the true slope 0.45. This is not coverage evidence. Median fit times
by cell were 0.955, 2.281, 1.572, and 6.568 seconds. Maximum covariance
submatrix difference: `2.22e-16`.

## Readback and remaining validation

Local RDS/CSV readback confirmed all 12 rows, three distinct replicate seeds,
the status counts, optimizer codes, and covariance tolerance. The profile
endpoints and truth-in-interval flags were read from the v4 RDS and CSV.
Harness failures from v1-v3 remain in the evidence directory. No full package
test suite, independent marginal-likelihood oracle, interval calibration, or
Julia run was part of this pilot. Programme gates remain open.

## Deterministic recovery summary

`Rscript --vanilla tools/general-sd-regression/probes/summarize-bernoulli-phylo-calibration-pilot.R docs/dev-log/general-sd-regression/evidence/phylo-calibration-pilot-20261020/totoro/output/results-v4/attempts.rds docs/dev-log/general-sd-regression/evidence/phylo-calibration-pilot-20261020/totoro/output/results-v4/recovery-summary.csv` exited 0. It recomputed per-cell completion, slope bias and MCSE, RMSE and bootstrap SE, profile availability, truth-in-returned-interval counts, fit timing, and covariance differences from all 12 retained attempts. Each cell has three replicates; these are descriptive pilot metrics only. Summarizer SHA-256: `8900f5641ff9784d3b7dcd03f5c6f923ec1ba7650da217cf780209716b7bed7a`. Output SHA-256: `2a9aabe0b34be048b6ed6dba96ad200def40e503cf97d90a8fe6155d08c61fb8`.
