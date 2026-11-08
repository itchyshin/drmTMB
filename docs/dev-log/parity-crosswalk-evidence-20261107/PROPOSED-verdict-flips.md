# Proposed verdict flips (PROPOSAL ONLY; nothing applied)

All flips are CONDITIONAL on the Julia branches (claude/q2-final-20261107 and its parents, plus the wave-2 branches below) landing in DRModels.jl main and the R repo's Julia pin (tools/parity-pin.R) moving to that commit. Evidence: one dataset/seed per shape, ML, likelihood agreement at the optimum only. Nothing here is applied; no verdict file, tool or test was edited.

## Wave 2 (added 2026-11-07)

Four new evidence folders sit beside this file: `wave2-labelled-rho`, `wave2-phylo-spatial-q2`, `wave2-gamma-nb2-ordinary`, `wave2-joint-sigma`. The Julia code for all four is on branch `claude/q2-wave2-merge-20261107` (itchyshin/DRModels.jl, not yet a PR). Native R is drmTMB 0.8.1 built from `origin/main`. Every number below is quoted from those READMEs.

Caveats that apply to every wave-2 row:

- One dataset and one seed per case. ML only (no REML). Agreement at the optimum, not recovery, bias or coverage.
- Native-only evidence: the R-calling-Julia bridge was not exercised.
- Post-fit methods were not tested on the new routes (predict is population-level only; quantile residuals ignore random effects; simulate and profile were not exercised).
- Mesh/SPDE `spatial(..., mesh = )` q2 was not attempted. Labelled (rho) phylo and spatial q2 were not done.
- Gamma crossed joint mu + sigma did NOT agree: R and Julia stopped at different local maxima (see row 18).
- Stress case 6a (Gaussian `sigma ~ 1 + (1 | site)`, 200 x 200, n 2400) is a multi-mode inner problem. It is not fixed. Julia now warns and sets `converged = false`; R gives no warning.
- Two wave-2 Julia branches change the NB2 SD dispatch (gamma-nb2-ordinary and labelled-rho); merging both will conflict and needs one owner.

## Table

The first four columns are the earlier proposal. The last column is what wave 2 adds.

| # | Row (fragment) | Proposed verdict | Supported fragment | Still NOT shown | Wave 2: newly supported, and what is still not shown |
|---|---|---|---|---|---|
| 1 | Poisson animal slope-only + SD | COVERED (unchanged) | n/a | n/a | No change. |
| 2 | Gaussian ordinary correlated q3 and q4, one SD per coefficient | **COVERED** (conditional) | q3, q4 (13/18 params, corr matrix 2.5e-11/6.7e-11) | other seeds, REML, intervals, BLUPs | No wave-2 case targets q3/q4. Unchanged. |
| 3 | Gaussian correlated q2, same-group, relmat/spatial, mu+sigma joint | **PARTIAL; split** | ordinary/same-group q2, relmat q2, joint mu+sigma (different groups) | spatial q2; joint mu+sigma on the SAME group; labelled forms | Newly supported: Gaussian spatial q2, coordinate kernel (7 params, max abs diff 4.2e-11, log-lik diff -3.2e-11); joint mu+sigma on the SAME group with both SD formulas (7 params, 1.5e-10, log-lik diff 3.8e-11); correlated `(1 \| p \| id)` mu + sigma with no SD formula (6 params, 1.2e-8, rho 0.6684865 in both). Still not shown: mesh/SPDE spatial q2, labelled phylo/spatial, correlated mu+sigma WITH SD formulas (R refuses it), other seeds, REML, bridge. Residual after split is narrower: mesh spatial and labelled phylo/spatial. |
| 4 | Poisson phylo/relmat slope-only, ... | unchanged PARTIAL | none (relmat q2 is not slope-only) | as in crosswalk | The new Poisson phylo case is q2 with two SD formulas (6 params, 5.9e-7, log-lik diff 2.9e-10), not slope-only, so it does not close this row. Caution: the Poisson phylo slope-SD SE differs 3.0e-3 relative from R, from a finite-difference Hessian step (h = 1e-4) in the shared Poisson q2 Laplace helper; with h = 3e-3 the gap is 3e-5. Helper not changed. Unchanged PARTIAL. |
| 5 | NB2 relmat/spatial intercept, ... | unchanged PARTIAL | none | spatial intercept is a refusal | No direct evidence. Related only: NB2 ordinary + relmat two-field intercepts agree (7 params, 1.4e-7), and NB2 spatial q2 agrees (7 params, 5.5e-8), but neither is the row's spatial intercept fragment. Unchanged PARTIAL. |
| 6 | Poisson phylo_interaction | unchanged NOT_COVERED | none | | No wave-2 case. Unchanged. |
| 7 | Gamma crossed / ordinary+relmat | **NOT_COVERED to PARTIAL or COVERED for the intercept-SD fragments (conditional; split)** | none in the earlier evidence | | Newly supported, with `sigma ~ 1` and one SD formula per field: Gamma crossed `(1 \| g) + (1 \| h)` (7 params, 3.2e-8, log-lik diff -3.2e-11) and Gamma ordinary + relmat (7 params, 1.3e-7, log-lik diff 1.4e-11). All 24 fits in that folder converged; SE ratio 0.9999967 to 1.0000007. Not shown: any Gamma with sigma random effects (Gamma crossed joint mu+sigma did not agree, row 18), other seeds, REML, bridge, post-fit methods. |
| 8 | Gamma animal correlated q2 | unchanged PARTIAL; proposed to split | none in the earlier evidence | Gamma not in new evidence | Newly supported: labelled (rho) Gamma `animal(1 + x \| p \| g, A)` with two coef SDs (8 params, 7.4e-7, log-lik diff 1.8e-11) and the same for `relmat` (identical, same kernel); independent Gamma `relmat(1 + x \| g, K)` (7 params, 1.2e-7). Julia's atanh_rho equals R's eta_cor_phylo with no conversion. Not shown: Gamma ordinary correlated `(1 + x \| g)` (refused by both R and Julia), phylo/spatial Gamma, `Ainv` input, other seeds. |
| 9 | Gamma ordinary + animal/phylo/spatial intercept | unchanged NOT_COVERED; animal fragment proposed | none in the earlier evidence | | Newly supported: Gamma ordinary + animal intercept (7 params, 1.3e-7, log-lik diff 1.4e-11). Not shown: phylo and spatial beside an ordinary term (refused in Julia, no evidence). Split needed; the row stays NOT_COVERED for phylo and spatial. |
| 10 | Gamma and NB2 same-group intercept+slope, coef SDs | **NOT_COVERED to PARTIAL (conditional; split)** | none (new q2 is Gaussian ordinary only) | | Newly supported: independent `(1 \| g) + (0 + x \| g)` with `sd(coef = ...)` for NB2 (7 params, 6.3e-8) and Gamma (7 params, 8.5e-8); NB2 ordinary correlated `(1 + x \| g)` with two coef SDs and rho (8 params, 7.4e-8, log-lik diff -6.5e-10). Not shown: Gamma ordinary correlated `(1 + x \| g)` (R refuses it; Julia keeps the refusal), one-SD variants (Julia refuses), other seeds. |
| 11 | ZIP plain independent slope, no sd() | **no flip proposed** | zip_probe.log shows plain slope REFUSED in Julia ("random effects cannot be combined with zi/hu yet") | a Julia fit and R-vs-Julia agreement; not in the new evidence | No wave-2 case. Unchanged. |
| 12 | Gaussian structured q2 (animal, relmat, phylo; unlabelled+labelled) | **PARTIAL; split** | animal q2, relmat q2 unlabelled (1.4e-10) | phylo q2; all labelled (rho) forms | Newly supported: Gaussian phylo q2 unlabelled (7 params, 5.3e-12, log-lik -907.7386, diff 4.0e-11); Gaussian labelled animal/relmat (8 params, 8.8e-12, rho 0.6592, log-lik diff 8.8e-11). Still not shown: labelled phylo, labelled spatial, `Ainv` input, labelled intercept-only terms. Residual after split: labelled phylo. |
| 13 | Gaussian structured sigma intercept (phylo, animal, relmat, spatial) | **PARTIAL; split; now every named shape has a case, so COVERED (conditional) is proposed** | animal, relmat (Laplace, 1.2e-11 SE) | phylo, spatial sigma | Newly supported: Gaussian `sigma ~ 1 + phylo(1 \| id)` with `sd(level = "phylogenetic", dpar = "sigma")` (48 tips, 5 params, 8.1e-9, max SE rel diff 5.1e-6) and spatial (48 sites, 5 params, 4.6e-11, SE rel 3.5e-6). R fits both; the earlier note that R refuses phylo sigma was wrong (the level name is "phylogenetic"). Not shown: NB2/Gamma structured sigma, sigma slopes, mesh spatial, other seeds, REML, bridge. This is the clearest candidate for a flip beyond row 2, but it rests on one fit per kernel. |
| 14 | Gaussian/NB2 phylo_interaction | unchanged NOT_COVERED | none | | No wave-2 case. Unchanged. |
| 15 | Poisson and NB2 structured q2 (animal, relmat, phylo, spatial); NB2 labelled animal | **PARTIAL; split; every named shape now has a case, so COVERED (conditional) is proposed for the coordinate-kernel forms** | Poisson animal, Poisson relmat, NB2 animal, NB2 relmat (unlabelled, independent fields) | phylo (refused on both families), spatial, NB2 labelled animal | Newly supported: phylo (Poisson 6 params, 5.9e-7; NB2 7 params, 1.3e-7), spatial coordinate kernel (Poisson 6 params, 3.9e-8; NB2 7 params, 5.5e-8), and NB2 labelled animal/relmat (8 params, 1.1e-7, rho 0.6124, log-lik diff -3.2e-9). Poisson labelled animal/relmat also agrees (7 params, 3.1e-8, rho 0.6071). Caveat: Poisson phylo SE gap 3.0e-3 relative (finite-difference Hessian step). Not shown: mesh/SPDE spatial, labelled phylo/spatial, non-ultrametric trees (refused), offsets for NB2, bridge. |
| 16 | Gamma slope-only phylo/spatial/relmat | unchanged NOT_COVERED; relmat fragment proposed | none | | Newly supported: Gamma relmat q2 with two coef SDs (7 params, 1.2e-7). Gamma phylo and spatial: no R-vs-Julia case (a Julia-only test shows `coef(intercept)` on `phylo(1 \| g)` matches the selector-free fit). Row stays NOT_COVERED for phylo and spatial. |
| 17 | Binomial phylo and spatial q2 | unchanged NOT_COVERED | none (Binomial animal q2 is a different kernel) | | No wave-2 case; Julia still refuses Binomial on these routes. Unchanged. |
| 18 | NB2 and Gamma joint ordinary mu+sigma | **NOT_COVERED to PARTIAL (conditional; split)** | none (joint evidence is Gaussian only) | | Newly supported: NB2 crossed (n 600, 7 params, 5.0e-8, log-lik -1110.7409394814 in both), NB2 same group (7 params, 1.0e-7), Gamma same group (7 params, 3.0e-12). NOT supported: Gamma crossed. There R and Julia stopped at different local maxima: max abs diff 0.37, 1.93 SE units, log-lik -832.5245271528 (R) versus -832.5085162004 (Julia), diff 0.016. R's own objective at Julia's estimate is -832.5085161977 with gradient 1e-7, so Julia's point is a stationary point of R's objective; R's default start went to the lower maximum. Which package finds the better maximum more often is not shown. Also not shown: sigma slopes (R refuses them in the joint route), structured NB2/Gamma sigma, stress case 6a (a Laplace inner multi-mode failure, detectable in Julia, not fixed). |
| 19 | Gaussian spatial q2 | **NOT_COVERED to PARTIAL (conditional)** | none | | Newly supported: coordinate kernel, `exp(-d / median positive distance) + 1e-6 I`, fixed range (7 params, 4.2e-11, max diff 3.9e-10 SE units, log-lik -888.8679, diff -3.2e-11). Not shown: mesh/SPDE `spatial(..., mesh = )`, labelled spatial, other seeds. |
| 20 | Poisson and NB2 labelled relmat q2 | **NOT_COVERED to COVERED (conditional) for the tested forms** | none (tested forms are unlabelled) | labelled rho forms | Newly supported: labelled `relmat(1 + x \| p \| g, K)` with two coef SDs for Poisson (7 params, 3.1e-8, log-lik diff -4.2e-10) and NB2 (8 params, 1.1e-7, log-lik diff -3.2e-9), plus Gaussian (8 params, 8.8e-12). Animal and relmat results are identical because both use the same raw matrix (K = A), so this does not separate the two code paths. Julia test: 95 assertions including eta = 0 reproducing the unlabelled fit. Not shown: `Ainv` input, labelled intercept-only terms, Gamma/Binomial labelled (Gamma labelled is covered under row 8; Binomial refused). |
| 21 | miss_control(response="include") SD regression | unchanged | none | | No wave-2 case. Unchanged. |
| 22 | Julia bridge relmat/spatial/animal slope-only SD | unchanged | none | bridge label parity, bridge receipts | Wave 2 is native-only; the bridge was not exercised and predict/simulate were not wired for the new routes. Unchanged. |

## Rows that remain unreconciled
Earlier proposal: only row 2 flips outright; rows 3, 12, 13 and 15 are partly supported and must be split.

With wave 2 (still conditional, still proposal only):

- Rows with a proposed outright flip: 2 (earlier), 13 (phylo and spatial sigma now have cases beside animal and relmat), 15 (phylo, spatial coordinate and NB2 labelled animal now have cases), 20 (labelled relmat for Poisson and NB2).
- Rows proposed to split or partly move: 3, 7, 8, 9, 10, 12, 16, 18, 19. Each keeps a named residual: mesh spatial, labelled phylo/spatial, Gamma ordinary correlated, Gamma phylo/spatial, Gamma crossed joint mu+sigma, or one-SD variants.
- Rows that gain nothing: 1, 4, 5, 6, 11, 14, 17, 21, 22. Row 4 and row 5 have related evidence that does not match their fragments.
- Because the evidence is one seed, ML, native-only and likelihood agreement at the optimum, "COVERED (conditional)" should be read as "agrees at the optimum on these cases", not as validated for coverage or recovery.

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
