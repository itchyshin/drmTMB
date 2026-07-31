# AOI-3R2 fresh diagnostic-smoke manifest

Status: **FROZEN, NOT EXECUTABLE WITHOUT A FURTHER OWNER APPROVAL.**

This manifest is the replacement-local-smoke seed allocation after AOI-3R1
reported `AOI3R1_DIAGNOSTIC_INVALID`. It is disjoint from AOI-3R1 and fixes
the runner source to `4d2b1afac7c45bdef74b98487a16a69535db2b81`, whose SHA-256 is
`5f735070caab7356db23bfbf313fd56379c3c1f2536c6619eeda8e64b2120b1f`.

It schedules 15 outer and 45 inner attempts: five fixed-effect formula classes,
each at `n = 720`, with three outer attempts and three scheduled inner
attempts per outer attempt. No result directory is allocated here. A future
owner-approved local invocation must use this manifest, a fresh immutable
result directory, and the stated source SHA. It may not overwrite or re-use
AOI-3R1 output.
