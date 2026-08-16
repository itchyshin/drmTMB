# Lane B E2 — unresolved source-coverage census

## Scope and identity

This document is the canonical manifest for the E2 census.  Its 97 rows are
the exact union of the three frozen-for-review source-card files below; it does not
create, amend, or approve a canonical binding.

| Source-card file | Frozen cells | `source_found_field_missing` | `source_found_not_direct` | `candidate_review` |
| --- | ---: | ---: | ---: | ---: |
| `2026-07-27-e2-source-cards-fixed-ordinary.tsv` | 15 | 9 | 6 | 0 |
| `2026-07-27-e2-source-cards-phylo-spatial.tsv` | 46 | 42 | 4 | 0 |
| `2026-07-27-e2-source-cards-animal-relmat-interaction.tsv` | 36 | 34 | 2 | 0 |
| **Union** | **97** | **85** | **12** | **0** |

The union is keyed by `cell_id`.  Each source-card file uses the same
18-column schema and contributes a disjoint E0 subset selected only from
`binding_status == "needs_exact_binding"`.

## Field-level rule

Each card records the primary evidence path and source receipt plus the state
of DGP/version, formula, truth/reporting scale, direct profile target,
information rung, and target cardinality.  A field state of `present` means
only that the cited source contains that field; it does not approve a binding.
`source_fields_complete_pending_review` would be required before a row could
enter a proposed exact-binding-review tranche.  No E2 census row has that
state.

`provider_q` and `estimand_stratum` are routing metadata.  They are never
used to choose an intercept, slope, endpoint, or covariance component.

## Boundary observations

The eight E1 count-q1 proposed contracts are not rows in this census: the E2
input is the distinct 97-cell E0 unresolved inventory, whereas E1 documents a
separate proposed source-to-target review set.  E2 neither upgrades those
proposals nor converts them into canonical bindings.

`mc-0260m` remains the sole K=12 negative control outside this unresolved
union.  Generic structured `q12` labels are not K=12 evidence.  No finite
endpoint, Wald route, recovery result, or generic target assertion fills a
missing field in this census.

## Reproduction check

The E2 validation receipt runs an explicit source-card union comparison before
running the E0 verifier.  The expected readiness state remains 158 target
cells, 62 recovered targets, 2 retained negative targets, 97 unresolved cells,
and `pregrid_authorized=FALSE`.
