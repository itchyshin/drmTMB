# Arc 1b-S2R ledger migration plan

## Decision

Use the Arc 1b-S1 stable-ID split pattern. Re-scope broad relmat REML rejection
row `mc-0201` to the exact admitted `mu1` endpoint, add `mc-0674` for the
matching `mu2` endpoint, and add `mc-0675` to preserve the still-rejected
relmat REML remainder.

The ML comparators `mc-0151` and `mc-0152` remain unchanged. No ML, spatial,
animal, phylogenetic, interval, coverage, or Julia evidence transfers into the
new REML rows.

## Exact row contract

| Field | Re-scoped `mc-0201` | New `mc-0674` | New `mc-0675` |
| --- | --- | --- | --- |
| `source_order` | retain `201` | `674` | `675` |
| `axis` | `model_surface` | same | same |
| `family_route`, `family_type`, `model_type` | `biv_gaussian`, `biv_gaussian`, `2` | same | same |
| `route_variant` | `arc1b_s2r_exact_q2_intercept` | same | `arc1b_s2r_remaining_relmat_reml` |
| `route_modifier` | `base` | `base` | `base` |
| `dpar` | `mu1` | `mu2` | `mu1` representative |
| `effect_type` | `structured` | same | same |
| `structure_provider` | `relmat` | same | same |
| `dimension`, `q_gate`, `estimator` | `bivariate`, `q2`, `REML` | same | `bivariate`, `na`, `REML` |
| `capability_status` | `implemented` | `implemented` | `rejected_by_design` |
| `work_status` | `verified` | `verified` | `deferred` |
| `evidence_tier` | `point_fit_recovery` | same | `none` |
| `test_gate` | `na` | `na` | `na` |
| `tranche_id` | `arc1b-s2r` | same | same |
| `primary_evidence_id` | `ev-mc-0201-arc1b-s2r-recovery` | `ev-mc-0674-arc1b-s2r-recovery` | `ev-mc-0675-arc1b-s2r-remainder` |

The admitted claim boundary must name matching labelled supplied-`K`
location intercepts in both endpoints, constant residual parameters, complete
pairs, unit weights, the dense restricted-likelihood oracle, retained recovery
evidence, and the `point_fit_recovery` ceiling. It must enumerate the excluded
neighbours rather than saying broadly that relmat REML is supported.

## Evidence and transitions

Append separate contract and recovery evidence for each admitted endpoint and
one rejection record for the remainder:

- `ev-mc-0201-arc1b-s2r-contract`
- `ev-mc-0201-arc1b-s2r-recovery`
- `ev-mc-0674-arc1b-s2r-contract`
- `ev-mc-0674-arc1b-s2r-recovery`
- `ev-mc-0675-arc1b-s2r-remainder`

Keep `ev-mc-0201-legacy` and its seed transition unchanged as historical
evidence. Append:

- `tr-mc-0201-arc1b-s2r-verified`: deferred -> verified;
- `tr-mc-0674-arc1b-s2r-verified`: blank -> verified; and
- `tr-mc-0675-arc1b-s2r-remainder`: blank -> deferred.

Use actual reviewed commit hashes and dates; do not prefill future commit or
PR values.

## Denominator and generator expectations

The model surface grows from 673 to 675 rows. The expected status counts move
from `303/330/40` to `305/330/40` for
implemented/rejected-by-design/not-implemented. The two new admitted endpoint
rows add two `point_fit_recovery` cells; all higher evidence-tier counts remain
unchanged.

Because the 18 missing-response rows currently occupy `source_order` 674--691,
shift only those numeric values to 676--693. Their IDs, semantics, evidence,
and generated order remain unchanged. This preserves unique global source
ordering while reserving 674 and 675 for the two new model-surface rows.

Keep `IMPORTED_MODEL_COUNT = 668`; only the additive model-surface count and
status/evidence expectations change.

Update the ledger source rows, evidence, transitions, schema, generator count
contracts, ledger tests, and ledger README before regeneration. Then run the
generator once and inspect every changed generated path. Do not hand-edit
generated census, JSON, Markdown, HTML, vignette include, or tranche files.

## Preservation checks

- `mc-0151` and `mc-0152` remain ML and retain their legacy primary evidence.
- `mc-0200` remains the animal REML rejection.
- `mc-0199`, `mc-0672`, and `mc-0673` retain Arc 1b-S1 spatial semantics.
- `mc-0675` explicitly preserves `Q`, unmatched/unlabelled, slopes/q4+,
  scale-side, extra-layer, missing/weighted, non-Gaussian, and AI-REML
  rejections.
- The generated reader surface must say “one exact supplied-`K` relmat q2
  location block,” never blanket relmat REML support.
