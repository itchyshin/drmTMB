# AOI-3R2 fresh diagnostic-smoke manifest

Status: **FROZEN, NOT EXECUTABLE WITHOUT A FURTHER OWNER APPROVAL.**

This manifest is the replacement-local-smoke seed allocation after AOI-3R1
reported `AOI3R1_DIAGNOSTIC_INVALID`. It is disjoint from AOI-3R1 and fixes
the runner source to `296d2db3396148fee3eb36e1b564a98a73d097eb`, whose SHA-256 is
`caaefe40a6f737f5bb971a8796d44420c9278e09d34c5bdb0a87766261f5ab98`.

It schedules 15 outer and 45 inner attempts: five fixed-effect formula classes,
each at `n = 720`, with three outer attempts and three scheduled inner
attempts per outer attempt. No result directory is allocated here. A future
owner-approved local invocation must use this manifest, a fresh immutable
result directory, and the stated source SHA. It may not overwrite or re-use
AOI-3R1 output.

