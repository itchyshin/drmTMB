# R-Julia parity: final state of the Julia pull request stack, 2026-11-09

Reader: Shinichi, or the next session that continues the parity lane. Written at the first integration of the documentation branches; it will be updated once the coordinator sends the final pull request list and gap-map numbers.

This note does not repeat the waves 7 to 10 handover in draft PR #1684 (`docs/dev-log/handover/2026-11-09-julia-parity-waves7-10-decisions.md` on branch `claude/parity-evidence-zip-gamma-20261107`). That note covers the first nine Julia pull requests and eight decisions. This note adds everything after it and puts the whole stack in one review order.

## What this lane did and did not do

- Julia work lives in `itchyshin/DRModels.jl` as draft pull requests. None was merged by us. An integration lane is merging them.
- No parity-matrix verdict was flipped. Flips need a separate reviewed drmTMB pull request after Julia lands and the pin moves. Proposed flips are listed in `docs/dev-log/2026-11-09-parity-matrix-proposed-flips.md`, marked PROPOSED.
- The four documentation branches named in the task (gap map wave 10, gap map v2, wave-8 disagreements, non-Gaussian REML memo) are branches of DRModels.jl, not of drmTMB. Their tip commits are docs only. Their files are copied here unchanged under `docs/dev-log/`. See "Where the evidence files are".

## Review order for the Julia stack

Review in this order. Each line says what the pull request does. All are open and draft at the time of writing, with the base shown by `gh pr view`.

Stacked chain, oldest first:

1. #1261: fits q2, q3 and q4 SD-regression shapes for Poisson, NB2 and Gaussian, plus mu+sigma SD Laplace. Base main.
2. #1263: wave 2. Labelled correlation, phylo and spatial q2, Gamma and NB2 two-field terms, joint mu+sigma. Stacked on #1261.
3. #1264: wave 3. Labelled phylo and spatial and ordinary q2. Stacked on #1263.
4. #1266: wave 4. Structured sigma, REML, conditional residuals, robust optimiser. Stacked on #1264.
5. #1267: warm-starts the inner mean fit in the CumulativeLogit crossed profile. Base main, so it is independent of the chain.
6. #1268: Binomial phylo and spatial q2, structured q2 completion, robustness, Julia 1.12 fixes. Stacked on #1266.
7. #1270: Beta and Tweedie structured SD, structured-sigma REML, native spatial kernels, robustness (waves 7 and 8). Stacked on #1268.
8. #1271: wave 9. Gaussian REML routes, SD-gap shapes, classification of the 54 log-likelihood disagreements. Stacked on #1270.
9. #1272: wave 10. Optimiser restarts for Binomial independent sd-z fits. Stacked on #1271. Its tip `0bfcde2bb` is the base of everything below.

Pull requests stacked on #1272, in the review order requested:

10. #1273: Gaussian SD "Group F": blocks beside slope terms, two blocks, mean `sd()` with a sigma intercept.
11. #1280: review fixes for waves 9 and 10 from the independent review. Its base is the #1273 branch, so it sits after #1273.
12. #1275: triage of the wave-10 non-converged cells. Gamma phylo, Gamma independent and Poisson spatial are fixed; NB2 animal q2 and Binomial q3 are left as fit-and-flag.
13. #1274: structured and positive-family SD cells: Poisson and NB2 spatial, NB2 phylo, a Gamma one-target pair, LogNormal and Student crossed.
14. #1276: Gaussian REML for correlated blocks q3 and q4, crossed terms, and structured sd intercepts.
15. #1278: independent intercept-plus-slope terms on the non-Gaussian mean routes (Poisson, NB2, Binomial, Beta, LogNormal, Tweedie), with `sd()` on Poisson, NB2, Binomial and Gamma.
16. #1283: non-Gaussian correlated-block cells: Poisson and NB2 one-target, LogNormal q2 SD, Binomial q3 and q4.
17. #1286: animal and relmat slope routes: bare Beta and Gaussian REML, and Binomial animal label semantics (the unlabelled form now means independent fields, as in R).
18. #1277: `predict(newdata)` codes factors with the fitted levels on every family.
19. #1279: gap map v2 crashes. Turns 12 of the 22 Julia crash cells into fits or clean refusals.
20. #1282: `fitted()` and `predict()` return the same response-mean quantity as drmTMB 0.8.1.

Fixes based on main, independent of the chain:

21. #1284: three Julia 1.12 test failures (a Binomial animal q2 inner mode defect, and two tests that depended on the 1.10 random stream).
22. #1285: q4 REML stall on uncertified inner modes, and two Julia 1.12 tests made version independent.
23. #1287: cross-family profile confidence interval no longer drops a resolvable arm when the far point stalls.

Later lane pull requests: none listed yet. The coordinator will send them; they go below this line when they arrive.

On the drmTMB side:

- #1684 (draft): evidence, proposed flips and the waves 7 to 10 handover. Review first among the drmTMB pull requests, because the proposed-flips file is the base for the new note.
- #1687 (draft): R warns and prints FAILED FIT when the Julia bridge reports a failed fit. Needs Julia #1270, which sends `fit_failed`. Harmless without it. Tested only with hand-built bridge results.
- #1688 (draft): fixes `convergence_status()` for cross-family Julia fits, which said "degenerate" although the optimiser succeeded. R code in `R/check.R`. Its body reports 499 passing offline tests in the filtered run, 0 failed, and says the full suite was not run. Three NB2 by Gaussian profile interval assertions still fail live; its body calls that a separate Julia-side issue.
- This pull request: documentation only.

## What is verified and what is not

Verified, each on the exact tip of its own pull request (not on one combined tip):

- #1273, #1274, #1275, #1276, #1278, #1279, #1280, #1282, #1283, #1286 and #1287 each report a full Totoro suite on Julia 1.10.12 with no failure other than cases named in their own body (#1276 and #1286 each updated one stale refusal test and reran it; #1287 skipped one file, see below). For Julia 1.12 (1.12.6 or 1.12.7, as each body states) #1273, #1274, #1275, #1276, #1280, #1282, #1283 and #1287 report only the five files that already fail on main.
- #1284 reports its own tip clean on 1.10.12 except one shard where `test_crossed_tweedie.jl` timed out, and on 1.12.7 failing `test_reml_q4_missing_response`, `test_binomial_spatial_sd_regression` and `test_binomial_animal_q2_sd.jl:47`.
- #1285 reports `test_binomial_animal_q2_sd` as a sixth failure on 1.12 that predates it and was left alone.
- #1287 skipped `test_crossed_tweedie.jl` in its suite run because that single file takes 3629 to 4428 seconds.
- Gap-map wave 10, at the #1272 tip: 3008 cells, 32 of the 145 Julia-behind cells now fit and agree, 113 remain, no regression. See the wave-10 note.
- Gap map v2, at the #1272 tip: 492 cells, 216 agree on log-likelihood and fitted values, 22 Julia crash cells.
- The 54 wave-8 log-likelihood disagreements: 0 Julia defects. Class counts are in the disagreements note.

Not verified:

- There is no gap-map rerun on one combined tip that includes #1273 to #1287. Each pull request reports its own cell counts: #1278 says 49 flips to agreement, #1276 says 19 flips among 85 Gaussian REML cells, #1274 says 12 cells. These overlap in ways I could not check, so they must not be added.
- #1277 says its full-suite result was to follow in a comment; I did not read the comment.
- The R-calling-Julia bridge was not exercised for any of the new Julia routes.
- #1287 and #1283 report Binomial q4 or profile-interval cases where R itself does not converge or where the integrator differs; agreement there is not a correctness claim.

## Decisions made without asking

The first eight are in the #1684 handover and still stand. Added since:

- Censored-response routes stay unbuilt. Neither engine fits a censored response, so there is nothing to compare (drmTMB issue 1455). Source: the lane's finding note, not committed in a repository.
- Non-Gaussian REML: recommendation is to keep refusing `method = :REML` on Binomial in Julia, fix the refusal message, and not build a matching estimator yet. Reason and design are in `docs/dev-log/2026-11-09-nongaussian-reml-decision.md`.
- #1280 softened statements that Julia "reaches R's value" where the two objectives differ at R's estimate.
- The Beta structured SD route was accepted on the agreement table in the lane's notes (7 shapes, one boundary case). That table is not committed in a repository.
- The four DRModels.jl documentation branches were brought into drmTMB `docs/dev-log/` unchanged, rather than summarised, so the numbers can be audited against the raw outputs.

## Known limits that must travel with any claim

- Poisson REML in Julia is its own Cox-Reid adjusted profile. drmTMB has no Poisson REML and refuses it. Julia's source comments say this criterion over-corrects when clusters are plentiful (cited in the REML memo, section 2). The size of the over-correction, about 4 percent of the SD at 40 groups and up to 8 percent for phylo, comes from the coordinator's brief. I could not find it in a committed file, so treat it as unverified until a file carries it.
- drmTMB admits REML for Gaussian and Binomial only. Its Binomial REML is a joint Laplace fold that its own design document classes `diagnostic_only`. In the memo's 40-data-set check the REML SD was at least the ML SD in every complete data set. That check shows wiring, not recovery.
- Disagreements of integrator class are R's Laplace approximation against Julia's adaptive Gauss-Hermite quadrature. The disagreements note puts 46 of the 54 cells in that class, plus 1 cell where Julia estimates a spatial range that R fixes. Where exact quadrature could be computed, Julia was the accurate one.
- NB2 spatial sd-z: the coordinator's brief reports a stuck lower mode. #1274's body lists NB2 spatial q1 `sd-one` and `sd-z` as agreeing with R (log-likelihood difference 3e-10). I found no committed file describing the stuck mode, so the two statements are not reconciled here.
- Julia 1.12: five known failing files on main, addressed by #1284 and #1285 on their own tips; a sixth, `test_binomial_animal_q2_sd`, was left alone. Different Julia versions draw different data from `MersenneTwister`, which is why those tests moved to committed or portable generators.
- `fitted()` and `predict()` convention: gap map v2 found 104 cells with equal log-likelihood but a different fitted quantity (lognormal, zero-truncated and hurdle NB2, zero-inflated Poisson and NB2). #1282 changes Julia's default to R's meaning. #1282 itself notes that `predict(newdata)` still fails without every factor level; that is the separate #1277 fix.
- Crash cells: 22 Julia crashes in gap map v2; #1279 converts 12. The rest include `poly()` in the mean formula and the double-bar `||` syntax.
- R fixes in this stack: #1687 (failed-fit message) and #1688 (cross-family convergence status). The R-side non-Gaussian REML label "Laplace/Cox-Reid adjusted profile" is wrong for the Binomial route according to the REML memo (section 1, `R/methods.R:4494`). It was reported, not fixed.

## Cleanup left for you on Totoro

Listed from the coordinator's brief; I did not check which still exist, and I ran nothing on Totoro.

- `~/drm_w8final_20261109`
- `/home/snakagaw/drm_w9_20261109`
- `/home/snakagaw/drm_w9v_20261109`
- `~/drm_w10_20261109`
- `~/drm_gap10_20261109`
- `~/drm_triage_20261109`
- `~/drm_sdf_20261109`
- `~/drm_gapv2_20261109`
- `~/rfx_20261109`
- `~/drm_mfci_20261109`
- `~/drm_ngi_20261109`
- `~/drm_ssc_20261109`
- `~/drm_animal_suite_20261109`
- `~/drm_ep_20261109`
- `~/claude_val_pa_reml`
- `~/claude_cellpp`
- `~/drm_conf_c07_20261109`

One uncapped R job, `rms.R` with pid 2318499 in `~/drm_pn2_20261109`, is not ours and was left alone.

## Where the evidence files are

| Item | Path in this branch | Source |
|---|---|---|
| Gap map wave 10 note and data | `docs/dev-log/2026-11-09-gap-map-wave10.md`, `docs/dev-log/gap-map-wave10-20261109/` | DRModels.jl `claude/gap-map-wave10-20261109`, tip `96919d58c` |
| Gap map v2 note and data | `docs/dev-log/2026-11-09-gap-map-v2.md`, `docs/dev-log/gap-map-v2-20261109/` | DRModels.jl `claude/gap-map-v2-20261109`, tip `92da2491a` |
| Wave-8 disagreements | `docs/dev-log/2026-11-09-wave8-disagreements.md`, `docs/dev-log/evidence/wave8-disagreements-20261109/` | DRModels.jl `claude/disagreements-wave8-20261109`, tip `cf3b92ed8` |
| Non-Gaussian REML memo | `docs/dev-log/2026-11-09-nongaussian-reml-decision.md`, `docs/dev-log/evidence/reml-nongauss-20261109/` | DRModels.jl `claude/reml-nongauss-memo-20261109`, tip `88495a0bb` |
| Proposed flips, waves 1 to 9 | in #1684 | drmTMB `claude/parity-evidence-zip-gamma-20261107` |

The BLUP NaN test branch (`claude/blup-nan-e2e-20261109`) was not brought in, because it holds a test, fixtures and a shard line rather than docs.

Next action for the reader: review #1684 first, then this pull request, then the Julia stack in the order above.
