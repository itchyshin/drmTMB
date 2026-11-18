# Check log: PR shard 1 timeout

Release run `43731130544`, job `132864164830`, was cancelled after about 75 minutes, matching its configured job limit, while `testthat.R` was running. The log identifies neither the cancellation initiator nor the slow test. Raising the shard 1 limit to 150 minutes retains the same tests and gives the next exact-head run a bounded chance to finish. GitHub completion time remains unmeasured. Other PR shards retain 75 minutes and unsharded jobs retain 180 minutes.

The exact `e65cd0ac64edc425383cc6e8009267e98a0cd216` release artifact's shard 1 completed on Totoro in 897.58 seconds with 13,157 passes, 27 test warnings and 150 skips, including 79 live-Julia skips. The package check reported one warning and two notes; the warning included unavailable Pandoc and `checkbashisms`, and the non-standard `news` directory. This different host and R environment do not make the cancelled GitHub run pass or prove how long a GitHub rerun will take.

The workflow parsed with `yaml::read_yaml`; comparison with the base YAML found only the timeout value changed. A fresh GitHub run and integration review remain necessary. Open PRs #1612, #1575 and #1033 also touch this workflow and must be reconciled without overwriting their work.
