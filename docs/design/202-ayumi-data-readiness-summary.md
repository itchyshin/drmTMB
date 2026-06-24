# Ayumi Data Readiness Summary

## Purpose

This note banks the Ayumi-data wave for the phylogenetic balance arc. The raw
benchmark bundle was not present in this session, so the wave uses persisted
local artifacts and prior after-task reports rather than rerunning large models.

## Current Data Availability

The expected temporary bundle
`/tmp/ayumi-ls-ecogeo/for_test/birds_tarsus_beak_10440.rds` was absent in this
session. No fresh full-data fit was launched.

Persisted evidence is available under `docs/dev-log/ayumi-convergence/` and in
the prior after-task reports. The stored RDS fit bundles for
`slices-1189-1208/mass-beak-current` and
`slices-391-402/mass-beak-pv2-q4-main` read cleanly.

## Practical Anchor

`docs/dev-log/after-task/2026-06-16-ayumi-model-a-plus-evidence.md` records the
cleanest current practical real-data answer. Model A+ uses phylogenetic
location covariance for Tarsus and Beak means, fixed-effect scale models, and
constant residual `rho12`. It fit the full data with `convergence = 0`,
`pdHess = TRUE`, `logLik = 10358.44`, and a mean-side phylogenetic LRT of
`36583.32` against the no-mean-phylo null.

The current Mass+Beak rerun artifact in
`docs/dev-log/ayumi-convergence/slices-1189-1208/mass-beak-current/` reinforces
the same practical split. `PV2_locphylo` returned with `convergence = 0` and
`pdHess = TRUE`; the q4 fallback variants returned false convergence,
`pdHess = FALSE`, and large fixed-gradient diagnostics.

## q4 And Profile Status

The q4 main artifact
`docs/dev-log/ayumi-convergence/slices-391-402/mass-beak-pv2-q4-main/` records a
returned native q4 fit with false convergence, skipped Hessian, residual
`rho12` near the boundary, and a q4 covariance warning. It is diagnostic status
evidence, not a usable inference result.

`docs/dev-log/after-task/2026-06-15-endpoint-profile-budget-status.md` records a
250-tip q4 endpoint profile-budget status row. The large full-species profile
attempt in
`docs/dev-log/after-task/2026-05-20-slices-1189-1208-ayumi-current-convergence-profile.md`
did not finish in a reasonable window, while the retained preflight tables show
that direct profile targets are exposed. That is a compute-status fact, not an
interval result.

## Run-Now Wrappers

Two wrappers remain the right entry points when the raw bundle is supplied:

- `inst/sim/run/ayumi_model_a_plus_evidence.R` banks Model A+ and the no-phylo
  null from `DRMTMB_AYUMI_DATA`.
- `tools/ayumi-q4-status-harness.R` writes q4 fit, profile-target, interval,
  condition, and metadata rows from `DRMTMB_AYUMI_Q4_RDS`.

Both scripts parsed in this session. They are evidence generators, not
automatic public support claims.

## Decision

The data wave supports a practical answer, not a solved q4 answer. Ayumi can
run or interpret Model A+ today as the clean real-data anchor. Full q4 native ML
and scale-phylo fallback artifacts remain diagnostic because the available
real-data rows show false convergence, boundary or gradient warnings, and
unresolved profile/bootstrap status. No large Julia q4 ladder should run before
direct DRM.jl small gates and row-specific bridge parity are current.
