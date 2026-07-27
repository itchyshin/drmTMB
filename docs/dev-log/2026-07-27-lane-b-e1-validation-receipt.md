# Lane B E1 validation receipt

## Scope

This receipt validates the documentation-only E1 packet.  It does not create a
canonical binding, local smoke, schedule, pregrid request, compute result,
capability conclusion, or public/default change.

## Artefact checks

- `2026-07-27-e1-count-q1-source-target-matrix.tsv` has 8 data rows, 12 fields
  per row, and exactly one row for each of `mc-0410`--`mc-0413`, `mc-0435`,
  `mc-0441`, `mc-0448`, and `mc-0452`.
- All eight rows name the direct `sd:mu:* (0 + x | ...)` slope target and retain
  the separate intercept as out of scope; their blocker says that no
  count-specific profile route or interval calibration is evidenced.
- `2026-07-27-lane-b-e1-design2-source-map.md` maps the merged #857 source and
  explicitly excludes `docs/design/246-marginal-bootstrap-coverage.md`.
- `2026-07-27-lane-b-e1-binding-recovery.md` contains 8 proposed candidates,
  no canonical binding insert, and the K=12 / unavailable-status fence.

## Mechanical checks

```sh
Rscript tools/verify-lane-b-e0-readiness.R
git diff --check
awk -F '\t' 'NF != 12 { exit 1 }' \
  docs/dev-log/interval-campaign-bindings/2026-07-27-e1-count-q1-source-target-matrix.tsv
```

All passed.  The E0 verifier still reports 158 target cells, 62 recovered
targets, 2 retained negative targets, 97 unresolved cells, and
`pregrid_authorized=FALSE`.

## Review receipt

- Fisher: **CONDITIONAL GO**. The eight are proposed slope-target contracts,
  not calibrated profile or coverage evidence; retain lower-bound and the
  `mc-0411` 2/80 `pdHess = FALSE` caveat.
- Rose: **GO**. The packet remains Lane B only, no-compute/no-public/no-ledger;
  the only delivery requirement is to commit the reviewed artefacts before
  calling them landed.

## Routing receipt

The planned Luna scout jobs were attempted through the enforced tiered runner
with `gpt-5.6-luna`, medium effort, and retained manifests in
`/private/tmp/lane-b-e1-tier/`. Both failed before work because the sandbox
blocked the ephemeral Codex process from opening `~/.codex/state_5.sqlite`.
Two fresh Terra-medium scouts produced the disjoint source map and matrix
instead. This is a recorded compatibility fallback, not a claim that Luna ran.
