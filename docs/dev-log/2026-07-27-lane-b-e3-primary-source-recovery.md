# Lane B E3 — primary-source recovery packet

**PLATFORM: Codex | LANE: B — `sd()` scale and intervals | FOREIGN LANE: none detected (weak evidence).**

## Purpose and non-authority fence

This packet audits original local evidence supporting the eight E1 count-q1
*proposals* and classifies the frozen E2 unresolved census for a later review
order. It is not a canonical binding table, a profile result, a recovery result,
or permission to run a smoke, pregrid, or compute campaign.

The E1 adjacent set and E2 census are mechanically disjoint: **8 E1 proposals**
and **97 E2 cells**. They must never be described as a combined 105-cell cohort.

## Immutable inputs

| Input | SHA-256 / commit | Role |
|---|---|---|
| E1 source-target matrix | `4cea6daa51333597d8a2d892aca7abd4083aa46fed24e93c0ed6f52ed70c68ed` | E1 field inventory |
| E2 fixed/ordinary cards | `6ddbbe2ca0af9f353d1d38ba28e6db80b174681bdd3c80bb1205a280b766119a` | 15-cell audit input |
| E2 phylo/spatial cards | `bd20414e0cd273a5448bf430fbec30c5bce2e057a9940eb94d3ac282ca418370` | structured audit input |
| E2 animal/relmat/interaction cards | `d3f1692d6b01a6e61d41ecad04bcad9630506ce3a581dab9291f2db51b2580f1` | structured audit input |
| Count-slope Rorqual sbatch | `dd5a28fa40a5086d31ab3d2982ae290ab6a5dca375bf1815947542539d164a9d` | recovery-rung provenance only |

The receipt rows for the E1 adjacent set are in
`interval-campaign-bindings/2026-07-27-e3-primary-source-receipts.tsv`.
Each preserves the original source function, DGP/version, formula, slope-scale
truth, direct namespaced target, singular cardinality, and retained recovery
rung. The common DGP also has an intercept SD of 0.25; that is not substituted
for the selected 0.45 slope member.

## E1 verdict

All eight E1 rows have sufficient provenance to remain
`pending_exact_binding_review`, and no more. Their 80-replicate archived
recovery rung does not include a count-specific `confint()`/profile trace or
interval calibration. `mc-0411` also retains 2/80 `pdHess = FALSE`. Therefore
no row is recovered, accepted, interval-ready, or eligible for a status change.

## E2 source-only adjudication

### Fixed and ordinary block: 15 rows

| Class | Cells | Source-only conclusion |
|---|---|---|
| Structurally non-direct | mc-0182, mc-0183, mc-0261, mc-0263, mc-0207, mc-0269 | REML-marginalised or representative source; a direct profile target cannot be recovered by label inference. |
| Target ambiguity | mc-0187, mc-0188, mc-0203–mc-0206 | DGP/formula evidence exists, but no singular namespaced profile target is recorded. Owner selection or a new direct source record is required. |
| Exact DGP absent | mc-0260, mc-0262, mc-0266 | Generic API/test evidence does not select a replayable DGP, truth, rung, and target. A new DGP design is required. |

This is the frozen split `15 = 9 source_found_field_missing + 6
source_found_not_direct`; it creates no binding candidate.

### Remaining structured non-direct block: 6 rows

| Cells | Blocker | Source-only conclusion |
|---|---|---|
| mc-0113, mc-0114 | rejected scale-profile route | A rejected/fixture record is not a direct binding. |
| mc-0214, mc-0215 | q4 scale target unknown | The original probe reports unknown CI targets. |
| mc-0321 | provider-boundary/no row DGP | Generic profile-ready API support cannot supply a row DGP. |
| mc-0409 | recovery DGP/no profile binding | The retained 160-fit recovery source lacks a row-level direct target. |

### Structured field-missing review order: 76 rows

The remaining 76 rows remain `source_found_field_missing`. The deterministic
order is to resolve the smallest, source-complete groups first, without
selecting a target from provider/q metadata:

1. Existing q1 one-slope sources with one documented DGP but unselected member
   (for example `ONE_SLOPE_COMPONENT_UNSELECTED` or
   `DIRECT_PROFILE_TARGET_UNRECORDED`).
2. Exact q2/q4 sources where directness or cardinality is absent.
3. Fixture/parity and q6 sources that lack a cell-specific DGP/rung.
4. q12 or weak-identification sources, retaining their unavailable status and
   K=12 negative-evidence fence.

This is a review order only, not a selected tranche, a recovery claim, or
permission to construct new DGPs.

## Inference and safety constraints

- `clamp_limited`, `trace_incomplete`, nonfinite, failed, and missing outcomes
  remain unavailable/non-covering. A finite K=12 endpoint is an error, not
  evidence.
- Design-2 trace semantics refer only to full `tmbprofile` work from merged
  #857; endpoint profiles cannot be substituted.
- `source_found_field_missing` and `source_found_not_direct` retain their
  meanings. A source location never supplies a missing target, scale, or rung.
- E0 remains authoritative: 158 targets, 62 recovered targets, two retained
  K=12 negatives, 97 unresolved, `pregrid_authorized=FALSE`.

## Next gate

No execution authority carries over. A future owner may request a reviewed
exact-binding decision for a clearly eligible cohort; only after that can a
separate smoke/pregrid packet be planned, followed by Shinichi's distinct
compute approval.
