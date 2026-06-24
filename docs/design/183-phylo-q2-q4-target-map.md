# Phylo q2/q4 Target Map

This map supports S028 of the 100-slice finish run. Its purpose is to keep
lower-dimensional bivariate phylogenetic correlation evidence (`q2`) separate
from four-axis location-scale evidence (`q4`) before any bridge, profile, or
interval wording is promoted.

The machine-readable source is
`docs/dev-log/dashboard/phylo-q2-q4-target-map.tsv`.

## Contract

- `q2` means the bivariate location block for `mu1` and `mu2`.
- `q4` means the four-axis location-scale block for `mu1`, `mu2`, `sigma1`,
  and `sigma2`.
- `q2_plus_q2` means block-diagonal evidence: one location block and one scale
  block. It is not a full unstructured `q4` covariance.
- Native TMB ML, native TMB REML, and R-to-Julia bridge rows stay separate.
- Direct-ready SD or q2 correlation targets do not make derived q4 correlation
  targets profile-ready.
- No row in this table is interval-coverage evidence.

## Rows

| Row | Meaning | Boundary |
| --- | --- | --- |
| `native_tmb_q2_location_phylo_ml` | Native TMB ML location-location phylogenetic correlation. | q2 only; no scale-axis or q4 support. |
| `native_tmb_q2_location_phylo_corpair_ml` | Native TMB ML q2 phylogenetic corpair regression. | q2 covariate-correlation evidence only. |
| `native_tmb_q2_location_phylo_reml` | Tempting native bivariate phylo REML row. | Unsupported until a native estimator is designed and validated. |
| `native_tmb_q4_full_phylo_ml` | Native TMB ML full four-axis phylogenetic block. | Diagnostic point/status evidence only; derived q4 correlations have no interval coverage. |
| `native_tmb_q4_blockdiag_phylo_ml` | Two labelled q2 blocks, one for location and one for scale. | Block diagonal, not full q4 unstructured support. |
| `native_tmb_q4_full_phylo_reml` | Tempting native q4 REML row. | Unsupported; q4 Patterson-Thompson REML is not HSquared AI-REML. |
| `julia_bridge_q4_full_phylo_reml` | Experimental Julia q4 REML bridge row. | Bridge evidence only; no native TMB REML or public bridge promotion. |

## Next Action

S029 should inspect summary/extractor status fields so `corpairs()`,
`summary(fit)$covariance`, `profile_targets()`, and confidence-status payloads
carry target readiness without implying Wald or interval support.
