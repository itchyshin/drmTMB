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

## Required preflight at execution time

`source_sha` identifies the runner/package-code commit, not the later
documentation-only manifest commit. Before an authorized run, verify that the
computational package surface has not changed since that source commit:

```sh
git diff --quiet 4d2b1afac7c45bdef74b98487a16a69535db2b81 -- \
  R src DESCRIPTION NAMESPACE tools/run-aoi3-bernoulli-nb2-full-refit.R
```

Only if that returns success, invoke the runner with
`AOI3_SOURCE_SHA=4d2b1afac7c45bdef74b98487a16a69535db2b81` and this manifest.
The runner independently rejects any other source SHA before creating the
requested result directory. This preflight does not authorize an invocation.
