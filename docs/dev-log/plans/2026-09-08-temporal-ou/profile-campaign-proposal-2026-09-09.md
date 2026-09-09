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

## Storage-consolidating campaign — approved and smoke-tested

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
recomputed summary. It changes the predeclared one-dataset array grain to 60 batches of 50 and
the array concurrency to 10. Shinichi approved this revised route on 2026-09-09
(`merge files as you go`; retain keepers on Totoro and keep DRAC relatively
clean). Fir project storage remains unavailable because its inode allocation is
full, and Fir nearline is not mounted on compute nodes. The live route therefore
uses Fir home only as transient staging: one source archive and at most 60 sealed
shards. Each completed shard is checksum-verified after transfer to Totoro before
any Fir cleanup. Totoro is the durable campaign store.

A one-dataset scheduled Fir smoke, job `58907593`, completed at source
`e46bf2e702c08383e1883de34b07163a5d9ba896`. It used one CPU, 2 minutes 30
seconds elapsed, and 4,183,676 KiB peak RSS. Its sealed shard
`shard-001.tar.gz` has SHA-256
`20a6bf2fa205fb3815cf4746850cba3c26cfd6684266e37b5a3bfcd58ff8b49d` and
contains an exact source/runner provenance record, a successful node-local
package-install log, `task,status` = `1,0`, two starts, and three finite profile
intervals. The prior 2 GiB request failed during package compilation; the
production script now compiles `drmTMB` once per shard into node-local storage,
reuses that binary for all 50 data sets, requests 6 GiB and 2.5 hours, and never
writes intermediate task files to Fir.

The retained local U1--U3 pilot gives median profile times of 34.764, 47.133,
and 64.638 seconds. With the measured one-time installation, 20 50-data-set
shards per cell project to roughly 43 single-core CPU-hours and about 5 hours of
array wall time at concurrency 10, before queue delay. The 2.5-hour task ceiling
leaves deliberate tail room; it is a ceiling, not an expected duration.

The reusable `tools/mirror-temporal-ou-shard-to-totoro.sh` helper transfers one
source archive or completed shard through the existing Fir and Totoro sockets,
compares SHA-256 at both ends, refuses a non-identical overwrite, and never
deletes Fir content. Its first use copied the smoke source archive (SHA-256
`75c62050400259fa2c90163f92c96378bc23ff3c66e317376dc6f86d969d4d6d`) and
smoke shard with matching hashes to
`/home/snakagaw/hsq_work/temporal-ou-profile-fir-e46bf2e7-smoke` on Totoro.
Only then was the verified Fir smoke directory removed.
