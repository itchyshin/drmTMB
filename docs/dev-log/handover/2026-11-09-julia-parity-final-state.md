# R-Julia parity: final state of the Julia pull request stack (written 2026-11-09, updated 2026-11-10)

Reader: Shinichi, or the next session that continues the parity lane. First written on 9 November at the integration of the documentation branches. Updated on 10 November at about 19:40 CST, after the Julia stack landed on DRModels.jl main. The first section below is the current state. Everything after it was written on 9 November and is kept as the record of the review order; where it says "draft" or "unmerged", the first section overrides it.

## State on 10 November 2026, about 19:40 CST

All facts in this section were read from GitHub with `gh pr view` on 10 November 2026, unless a source is named. DRModels.jl main was `e7d5ddee1b5d` when read.

### On DRModels.jl main now

| PR | What it is | Merge commit on main |
|---|---|---|
| https://github.com/itchyshin/DRModels.jl/pull/1261 | q2, q3, q4 SD-regression shapes (wave 1) | 3e2a4bf23 |
| https://github.com/itchyshin/DRModels.jl/pull/1263 | wave 2 | ded2f6f49 |
| https://github.com/itchyshin/DRModels.jl/pull/1264 | wave 3 | 4316f4f3d |
| https://github.com/itchyshin/DRModels.jl/pull/1266 | wave 4 | fc312372d |
| https://github.com/itchyshin/DRModels.jl/pull/1267 | CumulativeLogit warm start | 61ea02859 |
| https://github.com/itchyshin/DRModels.jl/pull/1268 | Binomial phylo and spatial q2, robustness | f600e090e |
| https://github.com/itchyshin/DRModels.jl/pull/1270 | waves 7 and 8 | 9ef4672b5 |
| https://github.com/itchyshin/DRModels.jl/pull/1271 | wave 9 | b84ee2897 |
| https://github.com/itchyshin/DRModels.jl/pull/1272 | wave 10 (main was ed90ae2ea after it) | ed90ae2ea |
| https://github.com/itchyshin/DRModels.jl/pull/1294 | integration PR (see below) | e7d5ddee1 |

- The wave stack (#1261 to #1272) is on main. The lane's STATUS file records seven of these merges (#1263 to #1272, by GitHub auto-merge) between 10:59 and 11:08 CST on 10 November; I did not read the merge time of #1261 and #1267. The same STATUS file of the lane (kept outside this repository) records that #1263, #1264 and #1266 went in inside #1268, and #1270 and #1271 inside #1272. The per-PR merge commits above are what GitHub reports for each.
- https://github.com/itchyshin/DRModels.jl/pull/1294 merged into main at 19:27 CST as `e7d5ddee1` (head `713b77957`). On that head the four Julia test shards, `ci-ok` and `docs` were all green (lane STATUS file, 19:33 CST check). Two test-only fixes were added on the way: a shard-2 name clash (`lrtest`, defined by both DRModels and StatsModels) and a shard-4 start-value difference between two spellings of one Binomial model (no tolerance, default or optimiser change).
- #1294 folded in these earlier lane PRs (from its own description): #1273, #1280, #1275, #1274, #1276, #1278, #1283, #1286, #1277, #1279, #1282, #1284, #1285, #1287, #1289, #1291, #1292. GitHub still lists #1273 to #1283, #1291 and #1292 as OPEN because they were folded in by merge, not merged one by one. Their content is on main through #1294.
- Also merged earlier: #1284, #1285, #1287 and #1289 (each into main), and #1296, #1298, #1300, #1301, #1302 (each into an integration branch, whose content came to main through #1294).
- https://github.com/itchyshin/DRModels.jl/pull/1290 was closed as agreed (P3). Two test-only commits for Julia 1.12 are not on main; the branch is kept.
- https://github.com/itchyshin/DRModels.jl/pull/1299 is still OPEN on GitHub, but its head `b34b250df` is already inside main through #1294. Nothing is left to merge. Closing it waits on owner question P18.

### Still draft (none of this is on main)

All are open drafts, read on 10 November. "Question" names the open owner question in the lane's `DECISIONS-PENDING.md` (the file is outside this repository). P4 (the drmTMB verdict flips) is open for all of them and is not repeated.

Drafts opened by the lane that target `claude/integration-final-20261109`, not main, so GitHub CI does not run on them (P18b):

| PR | What it does | Question |
|---|---|---|
| https://github.com/itchyshin/DRModels.jl/pull/1305 | NB2 `spatial(1 \| g)` with coordinates, on drmTMB's fixed-range kernel | P18b; related to P6c (range default) |
| https://github.com/itchyshin/DRModels.jl/pull/1306 | REML for the Gaussian labelled `(1 \| p \| g)` pair on mean and sigma | P14a (test-only slack in a reference solver) |
| https://github.com/itchyshin/DRModels.jl/pull/1307 | Student `spatial(1 \| g)` and `spatial(1 + x \| g)` with coordinates | P14a (test text accepts either refusal wording) |
| https://github.com/itchyshin/DRModels.jl/pull/1308 | independent-term Laplace guard no longer blocks an SD at zero (guard value 30 raised to 300) | P7a, P7b |
| https://github.com/itchyshin/DRModels.jl/pull/1309 | a second structured term on a non-Gaussian model is refused instead of silently dropped | none of its own. Note: some fits that returned a wrong answer become errors |
| https://github.com/itchyshin/DRModels.jl/pull/1311 | finite standard errors for Tweedie with crossed random intercepts | P8 (SE policy at a boundary) |
| https://github.com/itchyshin/DRModels.jl/pull/1312 | several `offset()` terms, zero-inflated Poisson offset, `meta_V` offset | none recorded |
| https://github.com/itchyshin/DRModels.jl/pull/1313 | `meta_V` under REML | P9f |
| https://github.com/itchyshin/DRModels.jl/pull/1314 | prior weights with random effects, `meta_V` and bivariate Gaussian | P9g (`update()` on a weighted fit now errors unless `weights =` is given) |
| https://github.com/itchyshin/DRModels.jl/pull/1316 | sigma random effects beyond a single Gaussian intercept | P9i (an older engine's `simulate` may still include random effects set to zero) |
| https://github.com/itchyshin/DRModels.jl/pull/1317 | zero-inflated, hurdle, truncated NB2 and SkewNormal with a random intercept, and two more shapes | P11 |
| https://github.com/itchyshin/DRModels.jl/pull/1318 | `predict`: ignores a text response column on ordinal fits; missing-predictor `predict` pinned to drmTMB | P9j (Julia has no `predict(fit)` without new data) |
| https://github.com/itchyshin/DRModels.jl/pull/1319 | `simulate` and bootstrap: fresh random-effect draws for several random intercepts | P12, answered: keep the refusal without `data =` but print the call to use; accept the new bootstrap draw |
| https://github.com/itchyshin/DRModels.jl/pull/1320 | bivariate Gaussian with `(1 \| p \| g)`, pinned to drmTMB | P15, answered: rename the `:phylocov` block on this route only; the new name is not chosen |
| https://github.com/itchyshin/DRModels.jl/pull/1321 | `meta_V` under REML with prior weights (stacked on #1313 and #1314) | P14b, answered: add it as a draft |

Other drafts:

| PR | What it does | State | Question |
|---|---|---|---|
| https://github.com/itchyshin/DRModels.jl/pull/1293 | opt-in `marginal = :Laplace` on quadrature routes (reproduces drmTMB's integrator) | draft, base main, head `42241a7a3`; CI started about 19:45 CST; at the 19:38 CST read the `docs` check had failed and the four test shards were pending (cause not read) | P10 if the boundary cell is red on GitHub; P6a |
| https://github.com/itchyshin/DRModels.jl/pull/1310 | merge of #1293 onto the integration tip, with measured effect | draft; its content is inside #1293; open only because #1315 is stacked on it | P10, P18c |
| https://github.com/itchyshin/DRModels.jl/pull/1315 | option for P10: keep the Binomial correlated block out of the rounding-noise region | draft, left out of every combined run on purpose | P10 (options A, B, C) |

### Gap-map numbers, and which tree each one is from

No gap map was run on main at `e7d5ddee1`. The numbers below come from two other trees. Do not read either as "main".

Tree A: the #1294 branch before main was merged into it (`78b571496`), re-measured on 10 November (lane STATUS, item G5; Julia 1.10.12, R 4.6.1, drmTMB 0.8.1, pre-registered rule |log-likelihood difference| at most 1e-4):

- Map 1 (3008 cells; 427 are cells that R fits): 358 both fit and agree, 54 both fit but disagree, 10 R-only, 83 Julia-only, 5 not converged, 1 timeout.
- Map 2 (492 cells): 272 agree, 37 R-only, 10 Julia crashes.
- Main at `e7d5ddee1` is tree A plus main's own commits and the two test-only fixes named above, so main should give similar counts. That is an inference. I did not measure it.

Tree B: all lane drafts merged together onto the #1294 head `2a2eec788` (#1305 to #1314 and #1316; #1315 left out), from `combined-wave12-report.md` of the lane. This tree is NOT on main. Two test-only fixes were needed on it (#1307 and #1306 branches). The full suite was not re-run after them.

- Map 1: 363 agree (358 before), 54 disagree, 6 R-only (10 before), 83 Julia-only, 3 not converged, 2 timeouts caused by load. 7 cells changed class; no agreeing cell got worse. One new disagreement appeared that no draft claimed: `binomial|indep|lab0|q4|sd-first` (Julia -253.5513, R -253.5425).
- Map 2: 283 agree (272 before), 57 agree on log-likelihood but differ in fitted values (51 before), 28 disagree (27 before), 19 R-only (37 before), 10 Julia crashes. 18 cells changed class, all from R-only. No cell got worse.
- The drafts #1317 to #1321 were not in tree B.

An older figure in the table further down (357 agree, 17 R-only, "integrated tip") came from the coordinator on 9 November and is not on file. The original #1294 description gives 10 R-only for the same tree. I did not reconcile 17 against 10. Use the tree A figures above.

Fitted-value check (lane report `fitted-diff-report.md`): of 57 cells where log-likelihood agrees but fitted values differ, none is a numerical difference. 36 are a harness artefact, 17 are R `fitted()` including random-effect modes while Julia is population level, 4 are row counts with missing responses. This is owner question P17.

### Parity-matrix verdicts

Nothing is flipped. Every flip in `docs/dev-log/2026-11-09-parity-matrix-proposed-flips.md` stays PROPOSED until Shinichi answers P4, a separate reviewed drmTMB pull request applies it, and the Julia pin moves.

### What is not verified

- The full suite on Julia 1.10.12 was not run at the final head of several drafts. For example, tree B ran it before its two test-only fixes, and #1317 to #1321 were not in tree B.
- GitHub CI has not run on the lane drafts #1305 to #1321, because they target the integration branch (P18b). Their evidence is full suites on Totoro, a shared 384-core machine. Lane reports said GitHub CPU types can behave differently from Totoro (shard 4 of #1294 failed on GitHub and passed on Totoro until the CPU types were emulated).
- The P10 boundary cell (`binomial|corr|lab0|q2|sd-last`) is off by 1.8e-4 from R on Julia 1.13.3 and passes on 1.10.12. If it is red on GitHub for #1293, that PR waits for P10.
- Julia 1.12.7: tree B was not run on it. On the #1294 tip of 9 November the full suite was clean on 1.12.7; on the later head `1c9c41a7a` three assertions failed there (P1c, still pending).
- Gap maps ran on Julia 1.10.12 only, under heavy shared load for tree B.
- Standard errors, `vcov` and fitted values were not compared on the newly agreeing cells of tree B.
- The R bridge (R calling Julia) was not exercised for any of the new Julia routes.
- `meta_V` plus `(1 | g)` with weights under REML was not measured in R or Julia.
- I did not read the `docs` failure on #1293, and I did not check any Totoro folder.

This note does not repeat the waves 7 to 10 handover in draft PR #1684 (`docs/dev-log/handover/2026-11-09-julia-parity-waves7-10-decisions.md` on branch `claude/parity-evidence-zip-gamma-20261107`). That note covers the first nine Julia pull requests and eight decisions. This note adds everything after it and puts the whole stack in one review order.

## What this lane did and did not do

- Julia work lives in `itchyshin/DRModels.jl`. On 9 November these were draft pull requests and none was merged by us. On 10 November the stack and the integration PR #1294 were merged (see the first section).
- No parity-matrix verdict was flipped. Flips need a separate reviewed drmTMB pull request after Julia lands and the pin moves. Proposed flips are listed in `docs/dev-log/2026-11-09-parity-matrix-proposed-flips.md`, marked PROPOSED.
- The four documentation branches named in the task (gap map wave 10, gap map v2, wave-8 disagreements, non-Gaussian REML memo) are branches of DRModels.jl, not of drmTMB. Their tip commits are docs only. Their files are copied here unchanged under `docs/dev-log/`. See "Where the evidence files are".

## Review order for the Julia stack

Historical, written on 9 November. See the first section for the state on 10 November: all of these are now on main, either directly or through #1294. Each line says what the pull request does. All were open and draft at the time of the first writing.

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

Later lane pull requests (coordinator's list at about 15:55, not read from the pull requests by me):

- #1294 (draft on 9 November, tip `d78214757`; merged on 10 November as `e7d5ddee1`): integration pull request that folds #1273 to #1280, #1282 to #1287, #1289, #1291 and #1292. Full suites on its source tip `bf566192c`: 619 files, 0 failing files on Julia 1.10.12 and 1.12.7.
- Not in the integrated tip on 9 November, separate drafts: #1293 (Laplace objective option), #1299 (spatial parity), #1298 (review fixes, docs and tests), #1290 (the failures did not reproduce). On 10 November #1298 and #1299 were found to be inside #1294, #1290 was closed, and #1293 is still a draft.
- Julia 1.13: CI uses 1.13.3. Five test files failed on 1.13.2 because they depend on the random stream; fixed by #1296, #1300, #1301 and #1302. All 16 shards pass with them applied, on 1.13.2, not 1.13.3.

The review order above still describes the individual pull requests; #1294 has since been merged as the integrated tip.

On the drmTMB side:

- #1684 (draft, still open on 10 November): evidence, proposed flips and the waves 7 to 10 handover. Review first among the drmTMB pull requests, because the proposed-flips file is the base for the new note.
- #1687 (draft, still open): R warns and prints FAILED FIT when the Julia bridge reports a failed fit. Needs Julia #1270, which sends `fit_failed` (now on main). Harmless without it. Tested only with hand-built bridge results.
- #1688 (draft, still open): fixes `convergence_status()` for cross-family Julia fits, which said "degenerate" although the optimiser succeeded. R code in `R/check.R`. Its body reports 499 passing offline tests in the filtered run, 0 failed, and says the full suite was not run. Three NB2 by Gaussian profile interval assertions still fail live; its body calls that a separate Julia-side issue.
- This pull request: documentation only.

## What is verified and what is not

Verified on 9 November, each on the exact tip of its own pull request (not on one combined tip):

- #1273, #1274, #1275, #1276, #1278, #1279, #1280, #1282, #1283, #1286 and #1287 each report a full Totoro suite on Julia 1.10.12 with no failure other than cases named in their own body (#1276 and #1286 each updated one stale refusal test and reran it; #1287 skipped one file, see below). For Julia 1.12 (1.12.6 or 1.12.7, as each body states) #1273, #1274, #1275, #1276, #1280, #1282, #1283 and #1287 report only the five files that already fail on main.
- #1284 reports its own tip clean on 1.10.12 except one shard where `test_crossed_tweedie.jl` timed out, and on 1.12.7 failing `test_reml_q4_missing_response`, `test_binomial_spatial_sd_regression` and `test_binomial_animal_q2_sd.jl:47`.
- #1285 reports `test_binomial_animal_q2_sd` as a sixth failure on 1.12 that predates it and was left alone.
- #1287 skipped `test_crossed_tweedie.jl` in its suite run because that single file takes 3629 to 4428 seconds.
- Gap-map wave 10, at the #1272 tip: 3008 cells, 32 of the 145 Julia-behind cells now fit and agree, 113 remain, no regression. See the wave-10 note.
- Gap map v2, at the #1272 tip: 492 cells, 216 agree on log-likelihood and fitted values, 22 Julia crash cells.
- The 54 wave-8 log-likelihood disagreements: 0 Julia defects. Class counts are in the disagreements note.

Final gap-map numbers from the coordinator on 9 November (3008 cells, integrated tip against the wave-10 base; I did not recompute them and the files are not in this branch; superseded by the tree A and tree B numbers in the first section):

| Class | Wave-10 base | Integrated |
|---|---|---|
| Both fit and agree | 260 | 357 |
| R-only (Julia behind) | 107 | 17 |
| Julia-only | 43 | 83 |
| Both fit but disagree | 54 | 55 |
| Non-converged | 5 | 4 |

No cell regressed. #1293 reports 44 of the 54 integrator cells agreeing under `marginal = :Laplace`; its full suite was not rerun after the last fixes.

Caveats that go with these numbers:

- Parity claims are for log-likelihood and point estimates at the optimum. Standard errors were compared only in some pull requests.
- About 70 of the 427 R-fit cells can never read "agree": 46 are Laplace against adaptive quadrature, some are REML by definition, some are cases where R does not converge, and others.
- Verdict flips stay PROPOSED until Julia lands and the pin moves.

Not verified on 9 November (see "What is not verified" in the first section for 10 November):

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

## Default changes users will see

- `fitted()` and `predict()` now return the response mean E[Y], as drmTMB does (#1282).
- New Gaussian REML routes (#1276, #1286).
- Binomial `animal(1 + x | g)` unlabelled now means independent intercept and slope fields; the labelled form `(1 + x | p | g)` is the correlated model. Shinichi approved this (#1286).
- Independent-term fits on the non-Gaussian routes are tagged `marginal = :Laplace` (#1278).

## Laplace or adaptive quadrature: which number to trust

drmTMB integrates out random effects with a Laplace approximation. Julia's default is adaptive Gauss-Hermite quadrature, which is more accurate when a group has few observations or the random-effect SD is large. For the same model and the same estimates, the two log-likelihoods can therefore differ by a small amount, usually under 0.1 and in the Binomial q3 and q4 cases about 0.6.

- To compare Julia with R, ask Julia for the Laplace objective where available (`marginal = :Laplace`; the general option is #1293, still a draft on 10 November). Then the numbers should match.
- To report a log-likelihood, AIC or likelihood-ratio test, do not mix engines. Compare models fitted by one engine with one integrator.
- Where exact quadrature was computed for the 36 one-dimensional wave-8 cells, Julia's value was the accurate one and R's Laplace value was below it in 36 and above it in 10 of the 46 integrator cells (disagreements note). Accuracy is not the same as agreement with R: a gap here is not a Julia defect.
- Parameter estimates agree much more closely than the log-likelihood does. In the integrator cells R's objective at Julia's estimate was within 0.015 of R's own optimum in all 36 one-dimensional cells.

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

Next action for the reader: answer the owner questions named in the first section (P4 first, because it gates the verdict flips), then review the lane drafts. The Julia stack itself needs no further review order.
