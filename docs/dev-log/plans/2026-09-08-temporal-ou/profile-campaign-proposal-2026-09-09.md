# Temporal OU fixed-effect profile campaign proposal

## Aim

Measure empirical 95% profile-interval coverage for the three Gaussian mean
coefficients in the admitted temporal OU workflow. This is the calibration
step that the deterministic oracle and G16 pilot cannot replace.

## Frozen design

The campaign uses the G16 generator and production two-start ML fit without
changing profile controls. It has three cells, each with 1,000 disjoint,
deterministic seeds: U1 (80 sites x 6 irregular occasions, ordinary intercept
plus OU, decay 0.40), U2 (80 x 12, ordinary intercept plus OU, decay 0.15),
and U3 (80 x 12, OU only, decay 0.70). Each replicate profiles intercept,
between-site, and within-site mean effects.

Each cell-coefficient denominator is all 1,000 generated data sets. A missing
or non-finite interval counts as unavailable and uncovered in the all-attempt
coverage result; conditional coverage among available intervals is reported
separately. The campaign retains every optimizer start, fit/profile error,
Hessian state, profile warning, estimate, interval, and elapsed time.

The primary engineering criteria are interval availability at least 0.99,
coverage within 0.925--0.975, absolute bias at most 0.10 empirical SD, and
mean reported profile-SE analogue assessed through interval width against
empirical SD. These are calibration criteria, not a public guarantee beyond
the simulated cells.

## Measured cost and routing

G16 profiled 15 data sets in 759.24 seconds wall time. Median profile times
were 34.764, 47.133, and 64.638 seconds for U1--U3, with 663,764,992 bytes
maximum resident size. For 3,000 replicates this projects to about 42--55
single-core CPU-hours after allowing for cell differences and artifact writes.

Use DRAC/Fir after a live capacity check immediately before submission. Submit
one replicate per array task, `--cpus-per-task=1`, `OPENBLAS_NUM_THREADS=1`,
2 GB memory, and a 10-minute task wall-time request. Store raw shards and the
frozen source bundle under durable project storage, not `/scratch`; no login
node computation and no GitHub Actions. Start with one scheduled smoke task,
read `seff`, then submit the bounded array only if the measured DRAC resource
use fits the request.

`tools/slurm/temporal-ou-profile-fir.sbatch` is a non-submitting template. It
maps array task IDs 1--3,000 to the worker and refuses to run until the
submission environment names an immutable `/project` source directory, durable
output root, and frozen source commit.

## Authority and closure

This document is a proposal only. It does not authorize a job submission,
change a coverage claim, or satisfy G14. G14 requires Shinichi's explicit
approval of this exact target, 3,000-replicate denominator, Fir routing, and
resource ceiling. After submission, G15 will recompute summaries from immutable
outputs without launching another campaign.

## Storage-consolidating alternative — pending revised authorization

Fir currently has no free project inodes (`500K / 500K`). The prepared
alternative stages one immutable `tar.gz` source archive, runs 50 data sets per
array task in node-local storage, then publishes one atomic `tar.gz` evidence
shard. It preserves every original per-data-set CSV, RDS, session record, worker
log, and task status inside the shard. G15 can extract and recompute the same
3,000-data-set denominator from all 60 shards. This follows earlier drmTMB
campaign practice, where formal shard archives were later independently audited
and aggregated.

It reduces durable inode demand from roughly 24,000 loose worker files and
6,000 Slurm logs to 62 files: one source archive, 60 immutable shards, and one
recomputed summary. It changes the predeclared one-dataset array grain to 60
batches of 50, the array concurrency to 10, and the requested wall time to 90
minutes. It therefore requires a revised G14 authorization before submission.
It also still requires roughly 100 free project inodes; no script can create an
artifact in a full allocation.
