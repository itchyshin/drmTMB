# Fir temporal OU sharded campaign submission

## Frozen scope

The authorized fixed-effect profile calibration campaign contains 3,000
deterministic data sets: 1,000 each in U1, U2, and U3. Each data set retains two
optimizer starts and three mean-effect profile interval rows. The all-attempt
denominator remains 1,000 data sets per cell and coefficient.

## Submission receipt

Fir accepted Slurm array `58908599` on 2026-09-09. It contains 60 array tasks
of 50 data sets, limited to ten concurrent tasks. Each task receives one CPU,
6 GiB, and a 2.5-hour ceiling. It extracts the source archive into node-local
storage, installs the exact package once into a node-local R library, runs its
50 workers against that installed copy, then atomically publishes one sealed
`shard-###.tar.gz` archive.

The frozen source is commit `e57ed8c10ea7a715e58b4513ae17484d01b049a8` and
has SHA-256
`2e5bfeae540580983a882865fe3c44ab836be2a012914365b44824deb6c1b096`.
It is present on both Fir temporary staging and Totoro durable storage before
the array starts. The campaign job has no loose Slurm output or error files;
each sealed shard contains its status ledger, runtime receipt, package-install
log, all worker records, and any failure record.

## Retention and next check

Fir home is temporary staging because project storage has no free inodes and
nearline is not visible from Fir compute nodes. Use
`tools/mirror-temporal-ou-shard-to-totoro.sh` to checksum-mirror each completed
source or shard. Do not remove a Fir shard until its Totoro checksum matches.
After all 60 shards are durable, G15 will reverify the 3,000-task denominator
without rerunning any fits.
