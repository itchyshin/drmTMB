# Recon: Arc 1 Honest Ledger

Base: origin/main 7f7293f2d

## Section 1: Base Commit Measurements

At commit 7f7293f2d (2026-09-24 Merge #1421):

**Parity matrix rows and GREEN count:**
- Command: `git show 7f7293f2d:docs/design/parity-matrix.md | grep -c "^|"`
  Result: 53 rows (including header), so 52 data rows
- Command: `git show 7f7293f2d:docs/design/parity-matrix.md | grep -E "^\|" | grep -i "green" | wc -l`
  Result: 8 GREEN rows

**UNCITED cells headline:**
- Command: `git show 7f7293f2d:docs/design/parity-scoreboard.md | grep "^\\*\\*UNCITED cells:"`
  Result: `**UNCITED cells: 8 of 135** (45 capabilities x 3 axes). 8 of the 45 capabilities`

**julia-capabilities.tsv counts (37 data rows):**
- claim_status counts: 10 covered, 4 experimental, 22 partial, 1 unsupported
- r_bridge_status counts: 13 experimental, 6 partial, 17 supported, 1 unsupported
- Command: `git show 7f7293f2d:inst/extdata/julia-capabilities.tsv | awk -F'\t' '{print $4, $6}' | sort | uniq -c`

**julia-gates.tsv rows:**
- Command: `git show 7f7293f2d:inst/extdata/julia-gates.tsv | wc -l`
  Result: 17 lines (including header), so 16 data rows

## Section 2: #1111 Overlap on R/julia-bridge.R

PR #1111 is OPEN (not merged). Two hunks touch R/julia-bridge.R:

1. `@@ -2808,13 +2808,14 @@` - roxygen comments for `confint.drmTMB_julia()` (function definition at line 2856 in base 27073059ea)
2. `@@ -3512,11 +3513,12 @@` - roxygen comments for `summary.drmTMB_julia()` (function definition at line 3544 in base 27073059ea)

Checked functions in worktree (all found):
- drm_julia_biv_phylo_dimension (line 1347)
- drm_julia_family_tag (line 1271)
- drm_julia_intentional_gates (line 50)
- drm_julia_phase15_admitted_cells (line 590)
- drm_julia_refuse_unadmitted_predictor_dpars (line 1531)
- drm_julia_refuse_biv_lognormal_unsupported (line 1587)
- drm_julia_refuse_fe_only_random_effects (line 1620)
- drm_julia_refuse_biv_student_beyond_native (line 1697)
- drm_julia_check_ordinary_sigma_ranef_route_limits (line 1752)
- drm_julia_check_factor_level_fidelity (line 2103)
- drm_julia_refuse_reml_unsupported (line 3175)
- drm_julia_refuse_marker_slope_unsupported (line 3260)
- drm_julia_check_manifest_runtime (line 4297)
- drm_julia_predict_check_dpar (line 7061)
- drm_julia_quantile_refuse_meta_v (line 7143)

#1111 overlap: NONE

Evidence: The #1111 hunks only modify roxygen documentation comments in confint.drmTMB_julia and summary.drmTMB_julia help text. They do not touch the function bodies or any of the specified functions (drm_julia_biv_phylo_dimension, drm_julia_family_tag, or any refuse/gate/admit/check functions).

## Section 3: Leaf Reconciliation

Scanned 62 leaf files across .unlazy/parity/gates, .unlazy/true-parity/gates, and .unlazy/followup/gates.

| leaf | gates | checked | class | reason |
|---|---|---|---|---|
| NODE-overnight-20260905 | 12 | 11 | DONE | Unchecked gate refs merged PR #1163 |
| leaf-a0 | 8 | 7 | ARC-2 | Unchecked gate has no PR ref |
| leaf-a1 | 5 | 4 | DONE | Unchecked gate refs merged PR #1163 |
| leaf-a10-prerun | 6 | 6 | DONE | All gates checked |
| leaf-a2 | 7 | 6 | DONE | Unchecked gate refs merged PR #1185 |
| leaf-a3 | 7 | 6 | DONE | Unchecked gate refs merged PR #1168 |
| leaf-a4-beta_binomial | 10 | 7 | DONE | Unchecked gates ref merged PRs |
| leaf-a4-cumulative_logit | 10 | 9 | DONE | Unchecked gate refs merged PR #1174 |
| leaf-a4-integration | 18 | 15 | DONE | Unchecked gates ref merged PRs |
| leaf-a4-skew_normal | 10 | 7 | ARC-2 | Unchecked gates ref open PRs (641, 1171 via 1172-1173) |
| leaf-a4-truncated_nbinom2 | 10 | 8 | DONE | Unchecked gates ref merged PRs |
| leaf-a4-tweedie | 10 | 8 | DONE | Unchecked gates ref merged PRs |
| leaf-a4-zero_one_beta | 10 | 8 | DONE | Unchecked gates ref merged PRs |
| leaf-a4g17-fe-only-fence | 11 | 11 | DONE | All gates checked |
| leaf-a5 | 5 | 4 | ARC-2 | Unchecked gate has no PR ref |
| leaf-a6 | 7 | 5 | ARC-2 | Unchecked gates have no PR refs |
| leaf-a7-coevolution-accessors | 8 | 6 | ARC-2 | Unchecked gates have no PR refs |
| leaf-a7-lrt-boundary | 8 | 7 | DONE | Unchecked gate refs merged PR #1166 |
| leaf-a7-model-comparison | 8 | 7 | ARC-2 | Unchecked gate has no PR ref |
| leaf-a8 | 10 | 10 | DONE | All gates checked |
| leaf-a8b-biv-inference | 10 | 10 | DONE | All gates checked |
| leaf-a8c-response-mask | 9 | 0 | ARC-2 | SCOUT leaf (read-only discovery); all 9 gates unchecked |
| leaf-a9a | 7 | 6 | ARC-2 | Unchecked gate has no PR ref |
| leaf-a9b | 5 | 5 | DONE | All gates checked |
| leaf-a9c-two-sd-slope | 7 | 7 | DONE | All gates checked |
| leaf-a9d-diagnostics | 7 | 7 | DONE | All gates checked |
| leaf-a9e-marker-lhs | 5 | 5 | DONE | All gates checked |
| leaf-a9f-reml-table | 6 | 6 | DONE | All gates checked |
| leaf-biv-animal-reml | 10 | 10 | DONE | All gates checked |
| leaf-biv-q2-reml-bridge | 10 | 8 | DONE | Unchecked gates ref merged PRs #1197, #1199 |
| leaf-cumlogit-predict | 8 | 8 | DONE | All gates checked |
| leaf-docs-staleness | 12 | 12 | DONE | All gates checked |
| leaf-fam-biv-lognormal | 13 | 13 | DONE | All gates checked |
| leaf-fam-biv-student | 13 | 13 | DONE | All gates checked |
| leaf-fam-hurdle-nbinom2 | 12 | 12 | DONE | All gates checked |
| leaf-fam-zi-nbinom2 | 16 | 16 | DONE | All gates checked |
| leaf-fam-zi-poisson | 17 | 17 | DONE | All gates checked |
| leaf-jl-609-gtol | 9 | 9 | DONE | All gates checked |
| leaf-jl-620-two-sd | 14 | 14 | DONE | All gates checked |
| leaf-jl-checkdrm-adsafe | 9 | 9 | DONE | All gates checked |
| leaf-jl-profile-finite | 8 | 8 | DONE | All gates checked |
| leaf-jl-q2-spatial | 9 | 9 | DONE | All gates checked |
| leaf-jl-q2-vcov | 9 | 9 | DONE | All gates checked |
| leaf-p-1144-cutpoints | 12 | 12 | DONE | All gates checked |
| leaf-p-1156-profile-targets | 8 | 8 | DONE | All gates checked |
| leaf-p-route-diagnostics | 10 | 10 | DONE | All gates checked |
| leaf-quantile-bridge | 9 | 9 | DONE | All gates checked |
| leaf-reml-biv-residual | 10 | 10 | DONE | All gates checked |
| leaf-reml-phylo-mean | 11 | 10 | ARC-2 | Unchecked merge gate has no PR ref |
| leaf-a4 (true-parity) | 6 | 6 | DONE | All gates checked |
| leaf-a5 (true-parity) | 4 | 4 | DONE | All gates checked |
| leaf-s1 | 5 | 2 | DONE | Unchecked gates ref merged PR #1112 |
| leaf-s2 | 4 | 4 | DONE | All gates checked |
| leaf-s3 | 14 | 13 | ARC-2 | Unchecked gate has no PR ref |
| leaf-s4 | 4 | 4 | DONE | All gates checked |
| leaf-s5 | 3 | 3 | DONE | All gates checked |
| leaf-s6 | 6 | 6 | DONE | All gates checked |
| leaf-s7 | 2 | 2 | DONE | All gates checked |
| leaf-f1 | 7 | 6 | ARC-2 | Unchecked gate has no PR ref |
| leaf-f2 | 7 | 6 | ARC-2 | Unchecked gate has no PR ref |
| leaf-f3 | 9 | 7 | ARC-2 | Unchecked gates have no PR refs |
| leaf-f4 | 10 | 8 | DONE | Unchecked gates ref merged PRs |
| leaf-f6 | 8 | 7 | ARC-2 | Unchecked gate has no PR ref |
| leaf-f7 | 7 | 6 | ARC-2 | Unchecked gate has no PR ref |

**Summary:** DONE: 49, ARC-2: 13, OWED-TO-ARC1: 0, ABANDONED-CANDIDATE: 0.

## Section 4: Surprises

**Surprise 1: fe_zero_one_beta stale in parity-matrix.md**

Assumption (b) stated: fe_zero_one_beta is at inst/extdata/julia-capabilities.tsv:30 while parity-matrix.md:65 says NO TSV ROW.

Evidence: fe_zero_one_beta IS present in julia-capabilities.tsv line 30 (verified). But parity-matrix.md line 65 (Zero-one-inflated beta row) says "NO TSV ROW" and "unledgered (no TSV row)". This is contradictory. The TSV row was added (likely in #1171 or around that time), but the parity-matrix.md documentation was not regenerated. This is a doc staleness issue, not a data problem.

**Assumptions (a) and (c) verified:**
- (a) #1421 merged (YES), tree identical to 8a3aeb02a (YES)
- (c) #1116 (chibar_pvalue, lrt_boundary) and #1118 (coevolution_*) functions exported in NAMESPACE (YES)

## Conductor notes (2026-09-24, after reverify)

- The zero-one-inflated beta "NO TSV ROW" is a generator join defect, not staleness: #1421 regenerated the matrix at `da8b3f871` and the line survived, because the plain-family join treats `zoi`/`coi` as modifier dpars (`tools/write-parity-matrix.R:151,172-181`). Slice S1a fixes the join.
- `#1111 overlap: NONE` re-checked by the conductor: every changed line #1111 makes in `R/julia-bridge.R` begins with `#'` (roxygen), in hunks near `vcov.drmTMB_julia` and `drm_julia_inference_confint_multi`. T10 is not raised.
- The leaf classification (49 DONE, 13 ARC-2, 0 OWED-TO-ARC1) came from a scout tier and is used as a lead, not as evidence of done work.
