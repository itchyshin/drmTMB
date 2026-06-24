# q4 derived-correlation DRAC/totoro dispatch pack

This is a dry-run dispatch pack. It should not be submitted until a DRAC
account, cluster, module stack, and login session have been selected.

- `slurm/q4-derived-correlation-delta-grid-array.sbatch` is an eight-task
  DRAC SLURM array template for shards 1-8.
- `slurm/q4-derived-correlation-delta-grid-array-worker.sh` runs a forced
  compute pass and a no-force resume pass inside each DRAC shard root.
- `slurm/q4-derived-correlation-delta-grid-totoro-worker.sh` runs shard 9
  separately on `totoro` if the hybrid plan is used.
- `slurm/q4-derived-correlation-delta-grid-aggregate.sh` aggregates only
  after all nine private shard manifests exist and enables diagnostic rate
  MCSE fields.

The pack is CPU-only, uses private shard roots, and does not promote q4
interval reliability, interval coverage, q4 REML, AI-REML, HSquared
transfer, broad bridge support, DRAC readiness, or SR150 acceptance.
