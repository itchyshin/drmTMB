# PR 1 Beta phylogenetic q1 recovery: original campaign HOLD

This directory is the verbatim retained output from the first predeclared PR 1
Totoro campaign. It ran from source commit
`d4ae525d34bef08b5e6cd546f917e525e91c29f8` with 32 workers and
`OPENBLAS_NUM_THREADS=1`; GitHub Actions was not used.

The campaign retained all 1,200 attempted fits: 400 replicates in each of
`g = 64, 256, 1024`, with two observations per species. All 1,200 fits
converged, 1,190 had `pdHess = TRUE`, 10 emitted `NaNs produced`, and 59 hit
the predeclared latent-SD boundary flag.

The fixed `mu` and family-`sigma` slopes passed their bias gates, every RMSE
non-worsening gate passed, and the `g = 1024` log-phylogenetic-SD bias gate
passed. The campaign remains **HOLD**, however, because the predeclared
`g = 256` absolute mean log-SD bias was `0.520323`, above the `0.10` gate.
Nine of 400 `g = 256` fits were boundary-flagged. The corresponding mean
public-SD estimate was `0.253684` for truth `0.30`, but that post-run summary
does not replace the failed log-scale gate.

No row was removed and no threshold was changed. A separately predeclared
replication addendum tests whether more within-species information removes the
lower-boundary tail. This original campaign remains load-bearing evidence for
the limitation and cannot by itself support `point_fit_recovery` promotion.

## SHA-256 provenance

```text
203025d9e593ae0b1a56d45fbbf35ab6f9fc959fee78bf4a14b1f5215f8e2b8a  design.tsv
e00e150c24fcd6deb7d8879cecd82962dd2a0982c99c5509c55eff4fb906ab39  gates.tsv
19256eaeecdf586f252148f90f0bedd18ba2510654c5bea3aca594388dded7d4  raw-attempts.tsv
a6c11cb71948d238c3bd163bfaee66c37f955b32146c1d1032fb62d7eff64032  rmse-difference.tsv
7c3faefc23dc093463e2bd690ff7515b4afab749eec19f2e275072336214e726  session-info.txt
ebf94269b865259770595dd9732fad20d795ef97539f172d6eb9127adfebf260  summary.tsv
```
