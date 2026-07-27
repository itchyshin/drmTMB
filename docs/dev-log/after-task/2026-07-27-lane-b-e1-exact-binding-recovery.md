# After Task: Lane B E1 exact-binding recovery

## 1. Goal

Recover a reviewable, documentation-only source-to-target packet for the eight
count q1 one-slope cells and repair the durable source map for Arc D Design 2.

## 2. Implemented

Added a #857 trace-contract source map, an eight-row non-canonical count-q1
source-target matrix, and a candidate-contract adjudication. The packet accepts
eight *proposed* slope contracts only; it does not create canonical bindings.

## 3a. Decisions and Rejected Alternatives

Each candidate names the slope SD target `sd:mu:* (0 + x | ...)`, truth 0.45 on
the log-mu scale, and retains the distinct 0.25 intercept SD. `clamp_limited`,
`trace_incomplete`, nonfinite, failed, and missing outcomes remain unavailable
and non-covering. A finite K=12 profile remains an error.

Rejected: treating the archived recovery outputs as profile/coverage evidence,
choosing the intercept target from the shared DGP, or using Design 246 as the
Design-2 source. The packet instead maps #857 and retains proposed-only status.

## 4. Files Touched

- `docs/dev-log/2026-07-27-lane-b-e1-design2-source-map.md`
- `docs/dev-log/interval-campaign-bindings/2026-07-27-e1-count-q1-source-target-matrix.tsv`
- `docs/dev-log/2026-07-27-lane-b-e1-binding-recovery.md`
- this receipt, validation receipt, reconciliation, and handover

## 5. Checks Run

`Rscript tools/verify-lane-b-e0-readiness.R`, `git diff --check`, and TSV
field/cardinality checks passed. The verifier remains 158/62/2/97 with
`pregrid_authorized=FALSE`.

## 6. Tests of the Tests

The existing E0 verifier checks the frozen cohort, binding/state boundary, and
fail-closed pregrid status. The source map cites #857's trace, clamp, overflow,
and K=12 focused test blocks; no code path changed in E1.

## 7a. Issue Ledger

No issue action: E1 documents existing Lane-B readiness and creates no
user-facing defect. Existing #710/profile numerical-guard work covers the
surrounding technical context.

## 8. Consistency Audit

Searched the E1 artefacts for `pregrid`, `smoke`, `compute`, `K=12`,
`clamp_limited`, `trace_incomplete`, `Design 246`, and `f6cc6fe`. The results
retain the no-compute boundary and correctly exclude Design 246 bootstrap work.

## 9. What Did Not Go Smoothly

The enforced Luna dispatcher could not open the sandboxed Codex state DB. Its
failure manifests are retained; fresh Terra scouts replaced the bounded reads.

## 10. Known Residuals

The eight contracts are proposed, not canonical; no count-specific profile
calibration exists. The other 97 E0 cells remain unresolved. E1 does not
authorize any binding edit, smoke, schedule, pregrid, or compute.

## 11. Team Learning

The count recovery source identifies the slope target directly only when its
truth, DGP output, and target string are preserved together. Recovery evidence
still does not establish interval evidence.

## 12. Cross-Product Coverage

E1 does NOT cover association, bootstrap, missing response, canonical binding
insertion, endpoint-engine clamp classification, local/remote smokes, schedules,
pregrids, compute, ledger/capability changes, public/default/API behaviour, or
interval calibration. It covers only the eight-source provenance map and the
full-`tmbprofile` Design-2 trace contract needed to preserve their fail-closed
interpretation.

## Next Actions

Commit this documentation packet. A later, separately approved arc may review
the eight candidate strings against archived sources alongside every other E0
cell; only a fully reviewed cohort can support a pregrid packet, which still
requires Shinichi's explicit compute approval.
