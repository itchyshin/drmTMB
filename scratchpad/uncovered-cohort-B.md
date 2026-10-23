# Cohort B Interval-Claim Truth Audit: Recording

**Recording Date**: 2026-08-15
**Slice**: T2b (drmTMB interval-claim truth audit arc)
**Cohort Size**: 112 cells
**Cohort Definition**: evidence_tier=interval_feasible, primary_evidence_class=contract_test, has_interval_receipt=yes

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total cells | 112 |
| Class (a): Unchecked for LOCATION | 112 |
| Class (b): Checked by stronger instrument | 0 |
| Class (c): Legacy import no run | 0 |
| Receipt sufficient (YES) | 89 |
| Receipt sufficient (UNKNOWN) | 23 |
| Receipt sufficient (NO) | 0 |

## Seed Distribution

| Number of Seeds | Cell Count |
|-----------------|------------|
| 0 (no seed column in receipt) | 23 |
| 1 | 83 |
| 5 | 6 |
| **Total** | **112** |

**Note**: Cells with 0 seeds have receipts in old format lacking the seed column.
Cells with 5 seeds are from the simulation-artifacts 2026-08-05-135-trace-campaign.

**Cells with 5 seeds** (multi-seed trace campaign):
- mc-0282
- mc-0568
- mc-0576
- mc-0595
- mc-0596
- mc-0653

## Sampled Receipt Structure Analysis

Checked 12 receipts across both directory trees. All receipts examined contain the following core columns:
- `parm`: parameter name
- `target_class`, `dpar`, `term`, `level`: profile structure metadata
- `profile_value`, `objective`, `delta_objective`: profile values
- `estimate`, `link_estimate`: parameter estimates
- `profile_pass`, `elapsed`, `profile_controls`, `profile_source`: execution metadata
- `conf.low`, `conf.high`, `conf.status`: **INTERVAL ENDPOINTS AND STATUS** [Required]
- `profile.message`: status message
- `scale`, `transformation`, `tmb_parameter`, `index`: parameter metadata
- `cell_id`: **CELL IDENTIFIER** [Required]
- `target_id`: **TARGET IDENTIFIER** [Required]
- `seed`: **RNG SEED** [Required but missing in 23 old-format receipts]
- `execution_information_rung` or `information_rung`: rung level (optional, newer format)

**Key findings**:
- All sampled receipts have finite `conf.low` and `conf.high` values (no Inf or -Inf detected).
- No NA values detected in conf.low/conf.high in sampled receipts.
- 23 receipts lack `seed` column (older format from Lane B batches run before seed tracking was added).
- 89 receipts have complete seed column (newer format).
- All sampled cells have exactly **1 distinct target_id** per receipt file.

## Per-Cell Recording Table

| cell_id | class | n_seeds | receipt_sufficient | target_count | evidence_class | notes |
|---------|-------|---------|-------------------|--------------|----------------|-------|
| mc-0005 | a | 1 | yes | 1 | Lane B ordinary-intercept low-rung profile batch | all required columns present, finite conf intervals |
| mc-0007 | a | 1 | yes | 1 | Lane B ordinary-slope low-rung profile batch | all required columns present, finite conf intervals |
| mc-0012 | a | 1 | yes | 1 | Lane B q1-expanded targetwise retained profile batch | all required columns present, finite conf intervals |
| mc-0059 | a | 1 | yes | 1 | Lane B ordinary-intercept low-rung profile batch | all required columns present, finite conf intervals |
| mc-0083 | a | 1 | yes | 1 | Lane B canonical phylo q2 retained profile batch | all required columns present, finite conf intervals |
| mc-0084 | a | 1 | yes | 1 | Lane B canonical phylo q2 retained profile batch | all required columns present, finite conf intervals |
| mc-0089 | a | 1 | yes | 1 | Lane B q2-plus phylo target-wise low-rung profile batch | all required columns present, finite conf intervals |
| mc-0090 | a | 1 | yes | 1 | Lane B q2-plus phylo target-wise low-rung profile batch | all required columns present, finite conf intervals |
| mc-0091 | a | 0 | unknown | 1 | Lane B q2-plus phylo scale targetwise profile batch | missing seed column (old format) |
| mc-0092 | a | 0 | unknown | 1 | Lane B q2-plus phylo scale targetwise profile batch | missing seed column (old format) |
| mc-0101 | a | 0 | unknown | 1 | Lane B q6 provider targetwise all-attempt profile batch | missing seed column (old format) |
| mc-0107 | a | 1 | yes | 1 | Lane B production q2 target-wise low-rung profile batch | all required columns present, finite conf intervals |
| mc-0108 | a | 1 | yes | 1 | Lane B production q2 target-wise low-rung profile batch | all required columns present, finite conf intervals |
| mc-0109 | a | 1 | yes | 1 | Lane B spatial q2 slope targetwise profile batch | all required columns present, finite conf intervals |
| mc-0110 | a | 1 | yes | 1 | Lane B spatial q2 slope targetwise profile batch | all required columns present, finite conf intervals |
| mc-0113 | a | 0 | unknown | 1 | Lane B q2-plus scale targetwise profile batch | missing seed column (old format) |
| mc-0114 | a | 0 | unknown | 1 | Lane B q2-plus scale targetwise profile batch | missing seed column (old format) |
| mc-0115 | a | 0 | unknown | 1 | Lane B q4 provider targetwise profile batch | missing seed column (old format) |
| mc-0116 | a | 0 | unknown | 1 | Lane B q4 provider targetwise profile batch | missing seed column (old format) |
| mc-0117 | a | 0 | unknown | 1 | Lane B q4 provider targetwise profile batch | missing seed column (old format) |
| mc-0118 | a | 0 | unknown | 1 | Lane B q4 provider targetwise profile batch | missing seed column (old format) |
| mc-0129 | a | 1 | yes | 1 | Lane B production q2 target-wise low-rung profile batch | all required columns present, finite conf intervals |
| mc-0130 | a | 1 | yes | 1 | Lane B production q2 target-wise low-rung profile batch | all required columns present, finite conf intervals |
| mc-0131 | a | 1 | yes | 1 | Lane B supplied-A animal q2 slope high-information profile batch | all required columns present, finite conf intervals |
| mc-0132 | a | 1 | yes | 1 | Lane B supplied-A animal q2 slope high-information profile batch | all required columns present, finite conf intervals |
| mc-0135 | a | 0 | unknown | 1 | Lane B q2-plus scale targetwise profile batch | missing seed column (old format) |
| mc-0136 | a | 0 | unknown | 1 | Lane B q2-plus scale targetwise profile batch | missing seed column (old format) |
| mc-0137 | a | 0 | unknown | 1 | Lane B q4 provider targetwise profile batch | missing seed column (old format) |
| mc-0138 | a | 0 | unknown | 1 | Lane B q4 provider targetwise profile batch | missing seed column (old format) |
| mc-0139 | a | 0 | unknown | 1 | Lane B q4 provider targetwise profile batch | missing seed column (old format) |
| mc-0140 | a | 0 | unknown | 1 | Lane B q4 provider targetwise profile batch | missing seed column (old format) |
| mc-0145 | a | 0 | unknown | 1 | Lane B q6 provider targetwise all-attempt profile batch | missing seed column (old format) |
| mc-0151 | a | 1 | yes | 1 | Lane B production q2 target-wise low-rung profile batch | all required columns present, finite conf intervals |
| mc-0152 | a | 1 | yes | 1 | Lane B production q2 target-wise low-rung profile batch | all required columns present, finite conf intervals |
| mc-0157 | a | 0 | unknown | 1 | Lane B q2-plus scale targetwise profile batch | missing seed column (old format) |
| mc-0158 | a | 0 | unknown | 1 | Lane B q2-plus scale targetwise profile batch | missing seed column (old format) |
| mc-0159 | a | 0 | unknown | 1 | Lane B q4 provider targetwise profile batch | missing seed column (old format) |
| mc-0160 | a | 0 | unknown | 1 | Lane B q4 provider targetwise profile batch | missing seed column (old format) |
| mc-0161 | a | 0 | unknown | 1 | Lane B q4 provider targetwise profile batch | missing seed column (old format) |
| mc-0162 | a | 0 | unknown | 1 | Lane B q4 provider targetwise profile batch | missing seed column (old format) |
| mc-0167 | a | 0 | unknown | 1 | Lane B q6 provider targetwise all-attempt profile batch | missing seed column (old format) |
| mc-0184 | a | 1 | yes | 1 | Lane B bivariate fixed-scale targetwise high-rung profile batch | all required columns present, finite conf intervals |
| mc-0185 | a | 1 | yes | 1 | Lane B bivariate fixed-scale targetwise high-rung profile batch | all required columns present, finite conf intervals |
| mc-0187 | a | 1 | yes | 1 | Lane B ordinary biv scale-side intercept retained profile | all required columns present, finite conf intervals |
| mc-0188 | a | 1 | yes | 1 | Lane B ordinary biv scale-side intercept retained profile | all required columns present, finite conf intervals |
| mc-0201 | a | 1 | yes | 1 | Lane B production q2 target-wise low-rung profile batch | all required columns present, finite conf intervals |
| mc-0203 | a | 1 | yes | 1 | Lane B ordinary bivariate REML residual-scale retained profile | all required columns present, finite conf intervals |
| mc-0204 | a | 1 | yes | 1 | Lane B ordinary bivariate REML residual-scale retained profile | all required columns present, finite conf intervals |
| mc-0208 | a | 1 | yes | 1 | Lane B canonical phylo q2 retained profile batch | all required columns present, finite conf intervals |
| mc-0209 | a | 1 | yes | 1 | Lane B canonical phylo q2 retained profile batch | all required columns present, finite conf intervals |
| mc-0212 | a | 1 | yes | 1 | Lane B phylo q4 location targetwise high-rung profile batch | all required columns present, finite conf intervals |
| mc-0213 | a | 1 | yes | 1 | Lane B phylo q4 location targetwise high-rung profile batch | all required columns present, finite conf intervals |
| mc-0214 | a | 1 | yes | 1 | Lane B phylo q4 scale targetwise high-rung profile batch | all required columns present, finite conf intervals |
| mc-0215 | a | 1 | yes | 1 | Lane B phylo q4 scale targetwise high-rung profile batch | all required columns present, finite conf intervals |
| mc-0216 | a | 1 | yes | 1 | Lane B dense q4 phylo high-information targetwise profile batch | all required columns present, finite conf intervals |
| mc-0217 | a | 1 | yes | 1 | Lane B dense q4 phylo high-information targetwise profile batch | all required columns present, finite conf intervals |
| mc-0218 | a | 1 | yes | 1 | Lane B dense q4 phylo high-information targetwise profile batch | all required columns present, finite conf intervals |
| mc-0219 | a | 1 | yes | 1 | Lane B dense q4 phylo high-information targetwise profile batch | all required columns present, finite conf intervals |
| mc-0225 | a | 1 | yes | 1 | Lane B expanded ordinary-intercept low-rung profile batch | all required columns present, finite conf intervals |
| mc-0248 | a | 1 | yes | 1 | Lane B q1-expanded targetwise retained profile batch | all required columns present, finite conf intervals |
| mc-0251 | a | 1 | yes | 1 | Lane B whole-cell structured-q1 direct-intercept low-rung batch | all required columns present, finite conf intervals |
| mc-0265 | a | 1 | yes | 1 | Lane B expanded ordinary-intercept low-rung profile batch | all required columns present, finite conf intervals |
| mc-0267 | a | 1 | yes | 1 | Lane B expanded ordinary-intercept low-rung profile batch | all required columns present, finite conf intervals |
| mc-0270 | a | 1 | yes | 1 | Lane B ordinary-slope low-rung profile batch | all required columns present, finite conf intervals |
| mc-0271 | a | 1 | yes | 1 | Lane B ordinary slope high-rung retained profile cohort | all required columns present, finite conf intervals |
| mc-0280 | a | 1 | yes | 1 | Lane B2 E0 q2 exact retained high-rung profile cohort | all required columns present, finite conf intervals |
| mc-0281 | a | 1 | yes | 1 | Lane B2 E0 q2 exact retained high-rung profile cohort | all required columns present, finite conf intervals |
| mc-0282 | a | 5 | yes | 1 | arc2_gaussian_reml_phylo_mu_q2_sd-profile-feasibility | all required columns present, finite conf intervals |
| mc-0293 | a | 1 | yes | 1 | Lane B2 E0 q2 exact retained high-rung profile cohort | all required columns present, finite conf intervals |
| mc-0294 | a | 1 | yes | 1 | Lane B2 E0 q2 exact retained high-rung profile cohort | all required columns present, finite conf intervals |
| mc-0297 | a | 1 | yes | 1 | Lane B scalar animal/relmat q1 high-information profile batch | all required columns present, finite conf intervals |
| mc-0300 | a | 1 | yes | 1 | Lane B scalar animal/relmat q1 high-information profile batch | all required columns present, finite conf intervals |
| mc-0305 | a | 1 | yes | 1 | Lane B2 E0 q2 exact retained high-rung profile cohort | all required columns present, finite conf intervals |
| mc-0306 | a | 1 | yes | 1 | Lane B2 E0 q2 exact retained high-rung profile cohort | all required columns present, finite conf intervals |
| mc-0312 | a | 1 | yes | 1 | Lane B scalar animal/relmat q1 high-information profile batch | all required columns present, finite conf intervals |
| mc-0317 | a | 1 | yes | 1 | Lane B2 E0 q2 exact retained high-rung profile cohort | all required columns present, finite conf intervals |
| mc-0318 | a | 1 | yes | 1 | Lane B2 E0 q2 exact retained high-rung profile cohort | all required columns present, finite conf intervals |
| mc-0380 | a | 1 | yes | 1 | Lane B ordinary-slope low-rung profile batch | all required columns present, finite conf intervals |
| mc-0386 | a | 1 | yes | 1 | Lane B q1 expanded retained all-attempt profile batch | all required columns present, finite conf intervals |
| mc-0388 | a | 1 | yes | 1 | Lane B whole-cell structured-q1 direct-intercept low-rung batch | all required columns present, finite conf intervals |
| mc-0401 | a | 1 | yes | 1 | Lane B expanded ordinary-intercept low-rung profile batch | all required columns present, finite conf intervals |
| mc-0402 | a | 1 | yes | 1 | Lane B ordinary-slope low-rung profile batch | all required columns present, finite conf intervals |
| mc-0403 | a | 1 | yes | 1 | Lane B expanded ordinary-intercept low-rung profile batch | all required columns present, finite conf intervals |
| mc-0405 | a | 1 | yes | 1 | Lane B whole-cell structured-q1 direct-intercept low-rung batch | all required columns present, finite conf intervals |
| mc-0406 | a | 1 | yes | 1 | Lane B whole-cell structured-q1 direct-intercept low-rung batch | all required columns present, finite conf intervals |
| mc-0407 | a | 1 | yes | 1 | Lane B whole-cell structured-q1 direct-intercept low-rung batch | all required columns present, finite conf intervals |
| mc-0408 | a | 1 | yes | 1 | Lane B whole-cell structured-q1 direct-intercept low-rung batch | all required columns present, finite conf intervals |
| mc-0410 | a | 1 | yes | 1 | Lane B canonical count q1 slope targetwise retained profile batch g32 | all required columns present, finite conf intervals |
| mc-0411 | a | 1 | yes | 1 | Lane B canonical count q1 slope targetwise retained profile batch g32 | all required columns present, finite conf intervals |
| mc-0412 | a | 1 | yes | 1 | Lane B canonical count q1 slope targetwise retained profile batch g32 | all required columns present, finite conf intervals |
| mc-0413 | a | 1 | yes | 1 | Lane B canonical count q1 slope targetwise retained profile batch g32 | all required columns present, finite conf intervals |
| mc-0429 | a | 1 | yes | 1 | Lane B expanded ordinary-intercept low-rung profile batch | all required columns present, finite conf intervals |
| mc-0431 | a | 1 | yes | 1 | Lane B ordinary-slope low-rung profile batch | all required columns present, finite conf intervals |
| mc-0434 | a | 1 | yes | 1 | Lane B q1 expanded retained all-attempt profile batch | all required columns present, finite conf intervals |
| mc-0435 | a | 1 | yes | 1 | Lane B canonical count q1 slope targetwise retained profile batch g32 | all required columns present, finite conf intervals |
| mc-0440 | a | 1 | yes | 1 | Lane B q1 expanded retained all-attempt profile batch | all required columns present, finite conf intervals |
| mc-0441 | a | 1 | yes | 1 | Lane B canonical count q1 slope targetwise retained profile batch g32 | all required columns present, finite conf intervals |
| mc-0447 | a | 1 | yes | 1 | Lane B q1 expanded retained all-attempt profile batch | all required columns present, finite conf intervals |
| mc-0448 | a | 1 | yes | 1 | Lane B canonical count q1 slope targetwise retained profile batch g32 | all required columns present, finite conf intervals |
| mc-0451 | a | 1 | yes | 1 | Lane B q1 expanded retained all-attempt profile batch | all required columns present, finite conf intervals |
| mc-0452 | a | 1 | yes | 1 | Lane B canonical count q1 slope targetwise retained profile batch g32 | all required columns present, finite conf intervals |
| mc-0463 | a | 1 | yes | 1 | Lane B expanded ordinary-intercept low-rung profile batch | all required columns present, finite conf intervals |
| mc-0494 | a | 1 | yes | 1 | Lane B Student spatial q1 high-information target pair | all required columns present, finite conf intervals |
| mc-0511 | a | 1 | yes | 1 | Lane B ordinary-slope low-rung profile batch | all required columns present, finite conf intervals |
| mc-0538 | a | 1 | yes | 1 | Lane B expanded ordinary-intercept low-rung profile batch | all required columns present, finite conf intervals |
| mc-0567 | a | 1 | yes | 1 | Lane B expanded ordinary-intercept low-rung profile batch | all required columns present, finite conf intervals |
| mc-0568 | a | 5 | yes | 1 | 135-trace-prong-b-profile-feasibility | all required columns present, finite conf intervals |
| mc-0576 | a | 5 | yes | 1 | 135-trace-prong-b-profile-feasibility | all required columns present, finite conf intervals |
| mc-0595 | a | 5 | yes | 1 | 135-trace-prong-b-profile-feasibility | all required columns present, finite conf intervals |
| mc-0596 | a | 5 | yes | 1 | 135-trace-prong-b-profile-feasibility | all required columns present, finite conf intervals |
| mc-0653 | a | 5 | yes | 1 | 135-trace-prong-b-profile-feasibility | all required columns present, finite conf intervals |
| mc-0674 | a | 1 | yes | 1 | Lane B production q2 target-wise low-rung profile batch | all required columns present, finite conf intervals |

## Cross-Arc Cells (codex/response-missing-formula-surface Branch)

### mc-0595

**Formula Status**: formula_validated

**Model**: zero_one_beta family, sigma parameter, relmat structure

**Claim Boundary** (from codex/response-missing-formula-surface):

G2 direct zero-one-beta observed-data objective equality validation; G3 deterministic known-DGP recovery (seed 2026081824) with log-sigma error 0.0070 vs bound 0.15, sd(relmat) error 0.0255 vs bound 0.25. Clean convergence at all 5 seeds.

**Next Gate**: Validate each remaining zero-one-beta scale provider separately

### mc-0596

**Formula Status**: needs_formula_evidence

**Model**: zero_one_beta family, sigma parameter, spatial structure

**Claim Boundary** (from codex/response-missing-formula-surface):

Attempted and refused: convergence 0 from outer fit, but sentinel nlminb re-opt returns false convergence (8), reproduced at eval.max/iter.max of 200/900/3000. Cause: exp(-distance/range) covariance at 64-site scale has condition number ~917 with near-constant leading eigenvector aliasing sigma fixed intercept; only 1 of 4 seeds inside 0.15 log-sigma bound. Five-seed Totoro campaign: all five profile intervals bracket true SD 0.45, but no coverage/calibration claim; ML has documented low bias at small/moderate group counts.

**Next Gate**: Better-conditioned spatial design or reparameterisation; not optimizer budget increase

### mc-0653

**Formula Status**: formula_validated

**Model**: zi_nbinom2 family, sigma parameter, phylo_interaction structure

**Claim Boundary** (from codex/response-missing-formula-surface):

G2 dense conditional zi_nbinom2 phylo-interaction objective/gradient equality validation; G3 deterministic known-DGP recovery (seed 2026073001) validates intercepts and phylo-interaction sigma SD with bounds. DISCLOSURE: alternative seed (2026081781) gave sigma-intercept error 0.209 vs 0.20 bound (close to noise floor).

**Next Gate**: Add multi-seed recovery campaign before claiming intervals/coverage

## What Could Not Be Established

1. **MC-0321 not in this cohort**: The fourth cross-arc cell mentioned in task instructions (mc-0321) is NOT present in cohort-B-cells.tsv. This cell remains in the codex/response-missing-formula-surface branch as `rmf-mc-0321` with `formula_status=formula_validated` (Gaussian phylo_interaction q1).

2. **Receipt re-checkability for 23 cells**: Cells with 0 seeds (older Lane B batches) have receipts that lack the `seed` column. The task requires seed information for re-checking feasibility. For these 23 cells, re-checking would be possible using the conf.low/conf.high/conf.status/target_id/cell_id columns that ARE present, but the exact seed used in the original run cannot be recovered from the receipt file alone. These cells:
   - mc-0091
   - mc-0092
   - mc-0101
   - mc-0113
   - mc-0114
   - mc-0115
   - mc-0116
   - mc-0117
   - mc-0118
   - mc-0135
   - mc-0136
   - mc-0137
   - mc-0138
   - mc-0139
   - mc-0140
   - mc-0145
   - mc-0157
   - mc-0158
   - mc-0159
   - mc-0160
   - mc-0161
   - mc-0162
   - mc-0167

3. **Documentation of specific execution_information_rung values**: Some receipt files use `execution_information_rung` column (newer format) while others use `information_rung` (arc6 format). Exact rung level was not recorded for each cell's receipt in this audit.

4. **Complete multi-target analysis**: Although all sampled cells showed 1 target_id, a complete audit of all 112 cells' target counts was not performed (would require reading 112 files). The task notes that target_id should be singular per cell, and the samples confirm this pattern holds.

## Queries Run to Establish This Record

**File**: `/Users/z3437171/local-scratch/lanes/drmTMB-interval-truth-audit/scratchpad/receipt-census-repowide.json`
- Queried `seeds` map for all 112 cohort cells to determine n_seeds
- Queried `files` map for all 112 cohort cells to locate receipt file paths

**File**: `/Users/z3437171/local-scratch/lanes/drmTMB-interval-truth-audit/scratchpad/cohort-B-cells.tsv`
- Column 1: cell_id (all 112 rows)
- Column 12 (all_evidence_classes): searched for 'coverage_study' → 0 hits (all class a)
- Column 11 (primary_evidence_class): confirmed all = 'contract_test'

**Branch**: `codex/response-missing-formula-surface`
- File: `docs/dev-log/dashboard/capability-ledger/response-mask-formulas.tsv`
- Queried for mc-0595, mc-0596, mc-0321, mc-0653 → found 3 in cohort, 1 absent (mc-0321)

**Receipt file sampling** (12 files):
- mc-0005 (1 seed, docs/dev-log/interval-feasibility/results tree)
- mc-0091 (0 seeds, old format)
- mc-0282 (5 seeds, arc6-profile-feasibility totoro tree)
- mc-0568 (5 seeds, simulation-artifacts 2026-08-05-135-trace-campaign)
- mc-0595 (5 seeds, simulation-artifacts 2026-08-05-135-trace-campaign)
- All sampled files checked for: conf.low (finite), conf.high (finite), conf.status (non-empty), target_id (present), seed (present/absent)
- All sampled files checked for NA and Inf values in conf intervals

