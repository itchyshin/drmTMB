# Parity matrix: proposed verdict flips after the Julia stack lands, 2026-11-09

**PROPOSED. Nothing here is applied.** No verdict file, `tools/write-parity-matrix.R`, parity matrix or test was edited. Every flip is conditional on three things: the named Julia pull request merging in `itchyshin/DRModels.jl`, the R repository's Julia pin (`tools/parity-pin.R`) moving past it, and a separate reviewed drmTMB pull request that writes the verdicts.

Reader: whoever writes that reviewed pull request.

This note extends, and does not replace, `docs/dev-log/parity-crosswalk-evidence-20261107/PROPOSED-verdict-flips.md` in draft PR #1684 (branch `claude/parity-evidence-zip-gamma-20261107`). That file proposes flips by matrix row number for waves 1 to 9 and has a revision section that takes precedence over its table. It also fixes the wording rule used here: proposed claim text is "agreement-at-optimum (native Julia vs native R, ML)", never text beginning "covered (", because the evidence is agreement of two implementations at the optimum, not recovery or coverage. Read that file first.

## How to read the table

- "Cell group" names a block of cells in the gap map (3008-cell wave-10 grid, or the 492-cell v2 grid) or a shape in a pull request body. I did not map groups to parity-matrix row numbers, because the matrix is generated and its row set differs from the gap-map shapes. The reviewed pull request must do that mapping.
- "From" is the class before: for example "Julia behind" means R fits and Julia refuses. "To" is the class after, as reported by the evidence file. The proposed matrix verdict follows the #1684 vocabulary.
- Counts are copied from committed files or from pull-request bodies read with `gh pr view`. Each pull request reports counts on its own tip. No gap map was rerun on a tip that combines these pull requests, so the rows overlap in ways I could not check. Do not add the counts.
- "Evidence file" is a path in this branch, or a pull request body where no file is committed.

## Proposed flips

| # | Cell group | From | To (proposed) | Julia PR that enables it | Evidence |
|---|---|---|---|---|---|
| 1 | Gaussian `crossed` SD shapes: ML q2 (no SD, labelled, one, z, first, last), ML q3 and q4 no SD, REML q1. 11 cells | Julia behind | Both fit, agree (log-likelihood within 1e-4; largest gap 1e-10) | #1271 (wave 9, Gaussian SD work); measured on the #1272 tip | `docs/dev-log/2026-11-09-gap-map-wave10.md`, `gap-map-wave10-20261109/compare/flipped_to_fit.tsv` |
| 2 | Gaussian `indep` SD shapes: ML q2 (one, z, first, last), ML q3 and q4 (z, first), REML q2 to q4. 11 cells | Julia behind | Both fit, agree | #1271; measured on the #1272 tip | same files |
| 3 | Gaussian `ordinary`: labelled q2 to q4 and plain q3 and q4 with no SD, labelled REML q2. 6 cells | Julia behind | Both fit, agree | #1271; measured on the #1272 tip | same files |
| 4 | Gaussian `animal`, `phylo`, `relmat`, `slope` REML with no SD formula. 4 cells | Julia behind | Both fit, agree | #1271; measured on the #1272 tip | same files |
| 5 | Gaussian blocks beside slope terms, two blocks, mean `sd()` with sigma intercept ("Group F") | Julia behind (wave 9 left them refused) | Both fit, agree at the optimum, 3 committed datasets, point estimates only | #1273 (with review fixes in #1280) | #1273 body; no committed file read |
| 6 | Gaussian REML: correlated blocks q3 and q4, crossed, structured sd intercept. 85 cells re-run, 19 flipped from error to fit | Julia behind (refused) | Both fit, agree with R REML (log-likelihood within 6e-12 on 35 of 36 fits where R converged) | #1276 | #1276 body; the full 3008-cell rerun was not done |
| 7 | Poisson and NB2 spatial, NB2 phylo, a Gamma one-target pair, LogNormal and Student crossed SD. 12 cells | Julia behind | Both fit, agree (log-likelihood difference at most 2e-9 in the rows shown; NB2 spatial q1 `sd-one` and `sd-z` 3e-10) | #1274 | #1274 body |
| 8 | Independent intercept-plus-slope terms on Poisson, NB2, Binomial, Beta, LogNormal and Tweedie, with `sd()` on Poisson, NB2, Binomial and Gamma. 136 cells tested, 96 of them cells drmTMB fits | Julia behind | 75 of the 96 agree; 49 flips to agreement on the full grid; 2 Binomial `sd-first` cells become non-converged | #1278 | #1278 body and its design note `docs/dev-log/2026-11-09-nongauss-indep-design.md` (that file is on the pull request branch, not here) |
| 9 | Poisson and NB2 `(1 + x \| g)` with an SD formula on one coefficient (`sd-first`, `sd-last`); LogNormal `(1 + x \| g)` q2 with SD formulas on one or both coefficients (4 cells) | Julia behind | Both fit, agree to 1e-10 | #1283 | #1283 body |
| 10 | Binomial bare `(1 + x + z [+ w] \| g)` q3 and q4 | Julia behind | **Not an agreement flip.** Julia fits, but its adaptive quadrature log-likelihood is 0.57 (q3) and 0.65 (q4) above R's Laplace value; at q3, `nq = 1` reproduces R to 1e-5; R's q4 fit is not converged | #1283 | #1283 body. Classify as integrator difference, not agreement |
| 11 | Binomial `animal(1 + x \| g)` q2, unlabelled form | Fit and disagree (convention gap: Julia always estimated the correlation) | Fit and agree (independent fields); labelled form `(1 + x \| p \| g)` gives the correlated model, as in R | #1286 | #1286 body; `docs/dev-log/2026-11-09-wave8-disagreements.md` (class a, 2 cells) |
| 12 | Bare Beta animal and relmat; Gaussian animal and relmat REML (bare form) | Julia behind | Both fit, agree (rows in the #1286 table marked pass) | #1286 | #1286 body |
| 13 | Gamma phylo `sd-z` q1, Gamma `(1 \| g) + (0 + x \| g)`, Poisson spatial fixed (three previously non-converged cells) | Non-converged (R fits) | Converged, same log-likelihood as R (Gamma phylo reported at -621.x in the body; check the file before quoting) | #1275 | #1275 body; `docs/dev-log/2026-11-09-nonconv-triage.md` on the pull request branch |
| 14 | `fitted()` and `predict()` response-mean convention for lognormal, zero-truncated and hurdle NB2, zero-inflated Poisson and NB2. 104 cells in gap map v2 | Both fit, log-likelihood equal, `fitted()` differs | Agree (34 checks against a committed R reference, five families) | #1282 | `docs/dev-log/2026-11-09-gap-map-v2.md`; #1282 body |
| 15 | `predict(newdata)` for non-Gaussian families when a factor level is missing from `newdata`. 69 grid cells | Julia throws | Works on seven families (189 expectations) | #1277 | `docs/dev-log/2026-11-09-gap-map-v2.md`; #1277 body. The 69 cells were not rerun |
| 16 | Julia crash cells in gap map v2. 22 cells | Crash (uncaught exception) | 12 become fits or clean refusals | #1279 | `docs/dev-log/2026-11-09-gap-map-v2.md`; #1279 body |
| 17 | Binomial independent sd-z, q2 and q3 (two cells that disagreed with R) | Fit and disagree; Julia 1.3 to 2.0 nats below a point its own objective scores higher | Julia log-likelihood rose in 3 cells at the #1272 tip, but the cells still disagree with R (q2 from -1.69 to +0.38 relative to R) | #1272, softened by #1280 | `docs/dev-log/2026-11-09-gap-map-wave10.md`; `docs/dev-log/2026-11-09-wave8-disagreements.md`. **No flip proposed.** Listed so nobody counts it as one |

## Rows that must not flip

- The 47 integrator-class disagreements (R Laplace against Julia quadrature). A verdict for them should say the engines differ by integrator, not that they agree.
- Non-Gaussian REML. drmTMB admits Binomial REML only, as a joint Laplace; Julia's one non-Gaussian REML is Poisson Cox-Reid. The memo recommends keeping the Binomial REML refusal in Julia. No agreement claim is available. See `docs/dev-log/2026-11-09-nongaussian-reml-decision.md`.
- Censored responses: neither engine fits them.
- The 43 cells that Julia fits and R refuses (wave 10, `maps/julia_only_cells.tsv`). These have no R reference, so they are Julia-only scope, not agreement.
- Cells from Julia pull requests with no gap-map or R reference in the pull request body.

## Final numbers and the tree each is from

Update, 10 November 2026: DRModels.jl #1294 merged into main as `e7d5ddee1` at 19:27 CST, together with the wave stack #1261 to #1272 earlier the same day. The Julia pull requests named in rows 1 to 17 below are therefore on main, directly or through #1294 (GitHub still shows some of them as open because they were folded in by merge). The R pin has not moved and owner question P4 (approve, approve a subset, or hold the flips) is still open, so every flip below is still PROPOSED. Nothing was flipped.

Numbers, with the tree each one is from (details in `docs/dev-log/handover/2026-11-09-julia-parity-final-state.md`). No gap map was run on main at `e7d5ddee1`.

- Tree A, the #1294 branch before main was merged into it (`78b571496`), 3008 cells, re-measured on 10 November: 358 both fit and agree, 54 both fit but disagree, 10 R-only, 83 Julia-only, 5 not converged. Second map (492 cells): 272 agree, 37 R-only.
- Tree B, all lane drafts #1305 to #1314 and #1316 merged together on the #1294 head (not on main): 363 agree, 54 disagree, 6 R-only; second map 283 agree, 19 R-only. Rows that depend on those drafts (offsets, `meta_V` REML, weights, sigma random effects, NB2 and Student spatial, Gaussian REML `(1 | p | g)`) must not be flipped from main numbers. They stay open until the drafts merge.
- The coordinator's 9 November figures for the integrated tip (260 to 357 agree, R-only 107 to 17) are superseded. The original #1294 description gave 10 R-only for the same tree, and I did not reconcile 17 against 10.

About 70 of the 427 R-fit cells can never read "agree" (46 Laplace against adaptive quadrature, REML by definition, R not converged, others), so a verdict file must not treat the gap to 427 as open work. Agreement means log-likelihood and point estimates at the optimum; standard errors were compared only in some pull requests. Julia-only cells (83) have no R reference. #1293 (opt-in `marginal = :Laplace`, 44 of 54 integrator cells agree) is a draft and not on main. #1299 and #1298 are inside #1294. #1290 was closed.

## Not verified

- Rows 5 to 16 rest on pull-request bodies, not on committed files in this repository. I read the bodies on 2026-11-09; they may change before merge.
- The gap-map counts for trees A and B in the section above are read from the lane's reports, which are not committed here. The older combined-tip figure is from the coordinator. Wave 10 on the #1272 tip, committed here, gives 113 remaining out of the 145 at wave 8.
- The bridge (R calling Julia) was not exercised for any row.
- Row 13's log-likelihood and row 8's breakdown are quoted from truncated reads of the pull-request bodies; confirm against the body before writing a verdict.
