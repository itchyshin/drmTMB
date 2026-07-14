# q4 Target And Estimator Inventory

This inventory supports S021 of the 100-slice finish run. It separates the q4
target rows that are easy to conflate in conversation: native TMB ML evidence,
native TMB q4 REML recovery, Julia bridge q4 REML, profile-target extraction,
and bootstrap smoke or negative evidence.

The machine-readable dashboard row source is
`docs/dev-log/dashboard/q4-target-inventory.tsv`.

## Inventory Rules

- q4 Patterson-Thompson REML is not HSquared AI-REML.
- Native TMB ML q4 point/status rows and native TMB q4 REML recovery rows are
  separate evidence channels.
- Julia bridge q4 REML remains experimental until row-specific native R, direct
  DRM.jl, and R-via-Julia parity evidence agree.
- Profile-target rows are target inventories, not interval-coverage evidence.
- Bootstrap `B = 2` rows are plumbing or refit-stability evidence, not calibrated
  uncertainty evidence.
- Ayumi-facing text remains parked until the later Ayumi arc.

## Current Rows

| Target | Meaning | Boundary |
| --- | --- | --- |
| `native_tmb_q4_ml_all_axes` | Native TMB ML q4 location-scale point/status evidence for the four phylogenetic axes. | Partial diagnostic evidence only; no calibrated interval or 10k sigma-phylo claim. |
| `native_tmb_q4_reml_all_axes` | Native TMB block-diagonal and dense q4 phylogenetic REML. | Recovery evidence at the tested information scale; no calibrated interval or coverage claim, and not HSquared AI-REML. |
| `julia_bridge_q4_reml_all_axes` | R-to-Julia q4 PLSM REML route when installed DRM.jl supports it. | Experimental bridge evidence only; native recovery is separate and does not establish same-target parity. |
| `julia_profile_targets_q4_phylocov` | R extraction of q4 profile-target names and estimates from the Julia phylocov block. | Target inventory only; no interval coverage. |
| `native_tmb_q4_bootstrap_30tip_smoke` | Native ML q4 bootstrap plumbing smoke where careful 30-tip refits returned. | `B = 2` refit-stability evidence only. |
| `native_tmb_q4_bootstrap_100tip_negative` | Native ML q4 bootstrap negative evidence at 100 tips under careful and robust settings. | No Ayumi-scale fallback claim. |
| `native_tmb_q4_profile_250tip_budget` | Native ML q4 endpoint-profile budget smoke at 250 tips. | Row-level `profile_failed` status only; no practical interval claim. |

## Next Gate

Promotion beyond native q4 recovery needs matching target-specific interval,
coverage, engine, tests, docs, and dashboard evidence. No Ayumi reply follows
from this inventory alone.
