# Proposed verdict flips (PROPOSAL ONLY; nothing applied)

All flips are CONDITIONAL on the Julia branches (claude/q2-final-20261107 and its parents) landing in DRModels.jl main and the R repo's Julia pin (tools/parity-pin.R) moving to that commit. Evidence: one dataset/seed per shape, ML, likelihood agreement only.

| # | Row (fragment) | Proposed verdict | Supported fragment | Still NOT shown |
|---|---|---|---|---|
| 1 | Poisson animal slope-only + SD | COVERED (unchanged) | n/a | n/a |
| 2 | Gaussian ordinary correlated q3 and q4, one SD per coefficient | **COVERED** (conditional) | q3, q4 (13/18 params, corr matrix 2.5e-11/6.7e-11) | other seeds, REML, intervals, BLUPs |
| 3 | Gaussian correlated q2, same-group, relmat/spatial, mu+sigma joint | **PARTIAL; split** | ordinary/same-group q2, relmat q2, joint mu+sigma (different groups) | spatial q2; joint mu+sigma on the SAME group; labelled forms |
| 4 | Poisson phylo/relmat slope-only, ... | unchanged PARTIAL | none (relmat q2 is not slope-only) | as in crosswalk |
| 5 | NB2 relmat/spatial intercept, ... | unchanged PARTIAL | none | spatial intercept is a refusal |
| 6 | Poisson phylo_interaction | unchanged NOT_COVERED | none | |
| 7 | Gamma crossed / ordinary+relmat | unchanged NOT_COVERED | none (no Gamma q2 or sigma evidence) | |
| 8 | Gamma animal correlated q2 | unchanged PARTIAL | none | Gamma not in new evidence |
| 9 | Gamma ordinary + animal/phylo/spatial intercept | unchanged NOT_COVERED | none | |
| 10 | Gamma and NB2 same-group intercept+slope, coef SDs | unchanged NOT_COVERED | none (new q2 is Gaussian ordinary only) | |
| 11 | ZIP plain independent slope, no sd() | **no flip proposed** | zip_probe.log shows plain slope REFUSED in Julia ("random effects cannot be combined with zi/hu yet") | a Julia fit and R-vs-Julia agreement; not in the new evidence |
| 12 | Gaussian structured q2 (animal, relmat, phylo; unlabelled+labelled) | **PARTIAL; split** | animal q2, relmat q2 unlabelled (1.4e-10) | phylo q2; all labelled (rho) forms |
| 13 | Gaussian structured sigma intercept (phylo, animal, relmat, spatial) | **PARTIAL; split** | animal, relmat (Laplace, 1.2e-11 SE) | phylo, spatial sigma |
| 14 | Gaussian/NB2 phylo_interaction | unchanged NOT_COVERED | none | |
| 15 | Poisson and NB2 structured q2 (animal, relmat, phylo, spatial); NB2 labelled animal | **PARTIAL; split** | Poisson animal, Poisson relmat, NB2 animal, NB2 relmat (unlabelled, independent fields) | phylo (refused on both families), spatial, NB2 labelled animal |
| 16 | Gamma slope-only phylo/spatial/relmat | unchanged NOT_COVERED | none | |
| 17 | Binomial phylo and spatial q2 | unchanged NOT_COVERED | none (Binomial animal q2 is a different kernel) | |
| 18 | NB2 and Gamma joint ordinary mu+sigma | unchanged NOT_COVERED | none (joint evidence is Gaussian only) | |
| 19 | Gaussian spatial q2 | unchanged NOT_COVERED | none | |
| 20 | Poisson and NB2 labelled relmat q2 | unchanged NOT_COVERED | none (tested forms are unlabelled) | labelled rho forms |
| 21 | miss_control(response="include") SD regression | unchanged | none | |
| 22 | Julia bridge relmat/spatial/animal slope-only SD | unchanged | none | bridge label parity, bridge receipts |

## Rows that remain unreconciled
Only row 2 would flip outright. Rows 3, 12, 13 and 15 are partly supported but name shapes with no evidence (spatial, phylo, labelled), so under the all-shapes rule they stay unreconciled or must be split. Rows 1 and 4-11, 14, 16-22 gain nothing: they are Gamma, phylo_interaction, spatial, labelled, miss_control, bridge or ZIP shapes.

## Edits needed (not written)
tools/write-parity-matrix.R
- `pm_pending_capabilities()`: remove row 2 (and row 1 if it already has a TSV row). Rows to split: replace each of 3, 12, 13, 15 with two names, a supported one and a residual naming the missing shapes. Each new name must exist in the R capability-status.md (`pm_build_matrix` stops otherwise), so capability-status.md needs the matching rows.
- `pm_capability_entries(ctx)`: add entries for the removed/split-off supported rows, each a list with `name`, `bridge_route`, `r_bridge_status`, `claim_status` ("covered (...)"), `boundary`, `next_action`, `green_override`, `gate_ids`. Because GREEN needs the Julia status row `implemented` too, `ctx$j_status` (DRM.jl capability file at the pin) must carry rows of the same names; claim_status should cite the receipt ids in step1-poisson-animal-q2-agreement. Given that evidence is native-only (no bridge), keep `green_override = "native only; bridge not exercised"` unless bridge parity is shown.
- Residual rows: keep the `unreconciled` template in `pm_build_matrix`, with a boundary naming the missing shapes.
- julia-gates.tsv: add gate rows citing the evidence if the entries use `gate_ids`.

tools/test-parity-matrix.R (the live file is tests/testthat/test-parity-matrix.R; there is no tools/ copy)
- Line ~386 `known_shared <- setdiff(..., pm_pending_capabilities())[[1L]]`: no change unless the first remaining name changes.
- Any assertion on the count of pending/unreconciled rows (22 now) needs updating to the new count, and a test that each flipped row is non-`unreconciled` and cites a receipt.

## Commands
```
Rscript tools/parity-pin.R           # after the pin update
Rscript tools/write-parity-matrix.R  # regenerate docs/design/parity-matrix.md (check its arg for the DRM.jl path)
Rscript tools/parity-honesty-gate.R  # must exit 0
Rscript tools/write-parity-scoreboard.R
Rscript -e 'testthat::test_file("tests/testthat/test-parity-matrix.R")'
```
Check whether julia-gates.tsv and docs/design/168 are generated by these scripts; if not, update by hand.
