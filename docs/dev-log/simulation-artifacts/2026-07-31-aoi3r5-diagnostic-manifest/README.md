# AOI-3R5 supervised diagnostic-smoke manifest

Status: **FROZEN FOR THE OWNER-AUTHORIZED R5 LOCAL SMOKE ONLY.**

This 60-row manifest allocates the five fixed-effect Bernoulli x ordinary-NB2
formula classes, three outers per formula, and three scheduled inners per
outer. Its seeds are unique and disjoint from R1--R4. Computational provenance
is `69325cf1f4bb13e94358e6bd4f1078cc4e4a8944`, which adds the process-isolated
supervisor; the original private runner remains source-pinned.

Run only through `tools/run-aoi3-bernoulli-nb2-supervised.py` with an
`--attempt-wall-time-seconds=180` limit. Each outer runs in a child `Rscript`
process. A timeout writes a durable `outer_wall_time_exceeded` supervisor event
and `INCOMPLETE`; it is not converted to a finite estimate or omitted.

This authorization excludes DRAC, covariance/coverage calibration, public
uncertainty APIs, `vcov()`, `confint()`, standard errors, and capability claims.
