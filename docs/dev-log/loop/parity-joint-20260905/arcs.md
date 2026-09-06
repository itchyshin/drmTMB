# arcs.md — parity-joint-20260905 (status-marked; gates flagged)

Legend: [ ] pending · [~] in progress · [x] landed (verified) · [!] OPEN GATE (needs Shinichi) · [-] abandoned (reason in checkpoint)

## Foundation (serial)
- [~] A0   re-pin e0a65f96b → 430ef64cc — sweep running (~/local-scratch/parity-joint/a0-sweep.log); then breakage conversion (if any), receipt LAST, PR. Ledger leaf-a0.
- [~] A0.5 family registry (R/julia-family-registry.R) — DONE + pinned 462/0/0; PR drmTMB #1162 in merge gate. Ledger: the registry test IS the gate.
- [~] A0.v vendor Totoro run_suite.sh — DRM.jl PR #638 in merge gate.

## The fan-out (ULTRACODE; launches when A0 + A0.5 are on main)
- [ ] A1  CI trust (#1083 #1081 #1150) — leaf-a1
- [ ] A2  THE MATRIX generator + admitted-needs-row test — leaf-a2
- [ ] A3  ledger the 9 working-but-unledgered routes (student, lognormal, FE gamma/poisson/nbinom2/beta, ZIP, ZINB, hurdle) — leaf-a3
- [ ] A4  admit the 6 refused families: tweedie · skew_normal(needs DRM.jl case) · zero_one_beta · beta_binomial · truncated_nbinom2 · cumulative_logit — leaf-a4-<family> ×6
- [ ] A5  ordinary RE census + rows — leaf-a5
- [ ] A6  formula constructs (#467 + #609 factors) — leaf-a6, DRM.jl PR first
- [ ] A7  U ports: #1116 lrt-boundary · #1117 model-comparison · #1118 coevolution-accessors — leaf-a7-<slug> ×3
INTEGRATION ORDER: A5, A7×3 (independent files) → A6 (DRM.jl PR first) → A3 rows → A4 rows (skew_normal's DRM.jl PR first) → A2 (regenerates the matrix over everything) → FINAL tip-identity receipt regeneration by the integrator — AT THE FINAL DRM.jl MERGE COMMIT (A6's and A4-skew_normal's DRM.jl PRs move the pin; the receipt pins every DRM.jl src/*.jl too, so it must be taken against the clone AFTER those land, and source-pins.json advanced to that commit) → A1 LAST (its hard-fail staleness step must land onto a fresh receipt). A0's own receipt (taken after #1162) is the INTERIM one; it will go stale again by design as wave PRs land, and that is expected, not a defect.

## Qualification
- [ ] A8  G3 bridge-side inference (profile + bootstrap, small cells, LOCAL) — unblocks TSV rows 2/3/5/12
- [ ] A9  remaining P: DRM.jl #620 two-SD slope · #609 varying-scale · #1156 profile_targets · #1144 cutpoint polish · #569/#1108 diagnostics consumer
- [ ] A10 P4 warm-workflow grid — PRE-RUN on Totoro (<10 min) then [!] FULL GRID = OPEN GATE, ask in the morning

## Closure
- [ ] A11 matrix regenerated · scoreboard · capability-status join · NEWS both · DESCRIPTION 0.7.1 PREPARED (not tagged) · Melissa · Rose · handover

## Corrections to the plan made by measurement (so the morning report is honest)
- A4 was "9 families"; it is 6. ZIP/ZINB/hurdle are zi/hu dpars on poisson/nbinom2 and ALREADY FIT through the bridge (ZIP logLik −176.9550 on both engines). Moved to A3 as unledgered routes. The scout's List A1 was built from the family-tag list without executing — the same error class as the bivariate blocker.
- DRM.jl's bridge already accepts 5 of the 6 (tweedie, zero_one_beta, beta_binomial, truncated_nbinom2, cumulative_logit); only skew_normal needs a Julia-side case.
- (20:40) A1 builder reported a "second A1 agent" editing its worktree. Verified by transcript grep: the plant string and both background tasks exist ONLY in the builder's own transcript; three wave-2 agents merely `find`-listed the path with zero tool calls under it. Phantom orchestrator pattern (LESSONS 2026-07-05). Builder's backup-and-restore remediation was correct. OPEN: wt-a1 carries a change to tests/testthat/test-bridge-payload-serialization.R outside OWNS — asked the builder to justify or revert before PR.
- (2026-09-05 04:30) OUTAGE: all 17 builders + the A1 resume died at 20:40 on "session limit · resets 12:40am"; the main lane was stalled until ~04:20. Nothing reported; wave journals empty. Harvest: PR #1163 (A1, RED by design at the staleness step) and #1164 (A7 model-comparison, all green) exist; 13 worktrees hold uncommitted partial work; wt-a6-drmtmb, wt-a9a, wt-a9b-drmjl, wt-a7-model-comparison clean. #1162 and #638 MERGED. Recovery: OWNS granted to A9a (one expectation in test-julia-bridge.R) and A4-cumulative_logit (three guarded hooks in R/julia-bridge.R); A0 receipt regen launched at 04:28 in wt-drmtmb-a0 (merged main 9230a9b97); Rose dispatched on #1164; builders relaunched in priority order with resume prompts, ≤6 concurrent so the 5-h cap is not hit again in 20 minutes.
- (04:55) Rose on #1164 (A7 model-comparison): G3 NOT refuted — R vs native DRM.jl aicc/lrtest agree to ≤1.4e-12 on two fixtures, both red controls bite (k(k+1)→k(k-1): 10 failures; LR sign flip: statistic −102.8). MUST-FIX (integrator doing both): `_pkgdown.yml` reference index lacks `model-comparison` (pkgdown runs only on tags/cron, so PR CI is blind to it); the leaf ledger was never filled (builder died) — transcribing Rose's live numbers. FOLLOW-UPS (not this leaf): (1) drm_lrtest() accepts a REML-vs-ML pair when mean structures match — faithful to DRM.jl comparison.jl:133-142, hazard in BOTH engines → file as a DRM.jl issue + R guard before any export; (2) aicc() on a drmTMB_julia fit emits no REML warning (class does not inherit drmTMB; matches the existing AIC convention; name it in the parity table); (3) bivariate: DRM.jl's _mean_structure is vacuous on :mu1/:mu2 (R's grep is stricter, safe direction; document); drm_lrtest_vc_labels() inert on bivariate; (4) the user-facing half (anova.drmTMB still aborts; no lrtest export) is the declared D-204 follow-up — capability-status.md:106 'planned' stays correct. METHOD NOTE: load_all(export_all=TRUE) publishes a second copy of internals into the attached env; runtime red controls must patch BOTH envs.
- (05:10) DRM.jl #639 filed: lrtest accepts REML-vs-ML when mean structures match; _mean_structure + VC-boundary labels blind on bivariate (Rose finding on #1164). A7 model-comparison ledger transcribed (G1–G7 ticked from Rose's live numbers; G8 pending merge); _pkgdown.yml index fixed a05b2f82c; gate armed on #1164.
- (05:20) A1 resumed and reported: PR #1163 met 4/5 (G5 = merge LAST, by design). Kept 603f02003 after re-measuring the glue step (1212/0/0 twice); dropped the unreproduced '1958 expectations' figure. Its staleness script now also catches R/ files ADDED since the receipt (found: 49 files vs 48 entries after #1162). NOT COVERED by A1: DRM.jl-side receipt entries are never verified on CI (no DRM_JL_PATH there); live engine on any runner; the dated phylo-labels receipts are not graded. A7 lrt-boundary: PR #1166 met 7/8. Both await Rose.
- (05:40) Tweedie (#1169) parity PASS (|d| 2.8e-11, logLik -463.227431798281 both; SE rtol max 3.3e-6; negative control OK). Left to the integrator, now ledgered as leaf-a4-integration.md: nu default in drm_julia_bridge_default_dpar_labels() (tweedie/skew_normal), the six TSV rows, ONE after-task for A4 (the leaves' OWNS omitted it — my planning error), design 258 §8 header conflict. DECISION: Julia-ahead shapes (tweedie nu ~ z) are documented in claim_boundary, not pre-refused. Order: A3 #1168 → six family PRs → a4-integration → A2.
- (05:55) zero_one_beta (#1171) parity PASS (|d| 4.0e-11; logLik -811.772322246398 vs -811.772322246396; SE rtol max 9.8e-7; negative control OK). Same integrator items as tweedie: TSV row + default labels (zoi/coi) → leaf-a4-integration.md updated.
- (06:00) #1165 (A0 re-pin + receipt) MERGED 10:53Z. A0 DONE. #1164 gate refused: one check non-green after a05b2f82c — diagnosing.
- (06:10) pr_merge_when_green.sh refused #1164 with an EMPTY settled table: status "" counted as settled, conclusion "" as non-green, and an empty rollup would have MERGED (vacuity). Patched (vault): empty rollup = pending; any non-COMPLETED status = pending; one fetch feeds table + verdict. Probed with four fake rollups. #1164 re-armed.
- (06:30) beta_binomial (#1172) PARTIAL: registry admission breaks test-julia-bridge.R:494 + test-julia-gate-vs-engine.R:59/388 (the retired base_unsupported_family gate row); builder left a verified patch; pulled into a4-integration as a PRE-merge step after A3. Parity rows byte-identical to the dead attempt's (FIXTURE_ROW_IDENTICAL, SE_ROW_IDENTICAL).
- (05:20) #1164 gate stalled on a NEWS.md conflict at update-branch (every parity PR adds a NEWS bullet at the top). Resolved by union merge (0f6f05255), pushed, re-armed. integrate.sh to be taught the same.
- (05:25) integrate.sh now self-heals a NEWS.md-only conflict: finds the PR's worktree, merges main, union-merges NEWS.md, pushes, re-probes; any other conflict stays manual. Backup integrate.sh.bak.
- (05:35) A9 remainder ledgered + worktrees: a9c two-SD slope (DRM.jl #620), a9d diagnostics consumer (#1108/#569), a9e marker-LHS guard (#1146), a9f REML-by-route table (#1142). Launching as wave A9-rest, ≤3 live.
- (06:05) cumulative_logit (#1174) parity OK (tmb logLik -903.2753487508; cutpoints via  slot); integrator items: TSV row, predict() design alignment (gap), 258 §8 header, and the six leaves' parity rows uncommitted in the pin clone → ONE DRM.jl evidence PR (a4-integration G11). skew_normal: DRM.jl #641 opened (merges before drmTMB #1176). A6 (#1175 + DRM.jl #640): the five constructs measured ALREADY at parity (≤2.9e-11); non-treatment contrasts (contr.poly ordered factor 1.18, contr.sum 1.76) differ silently → the PR REFUSES them before Julia. A9-rest relaunched TIERED (wf_e67d5668-848: a9c Fable high, a9d/a9f Sonnet high, a9e Sonnet medium, Rose Opus). main run after A0: success.
- (06:20) ZERO Rose verdicts from wf_06 after 1h40: its five slots are held by the last builders (a2, a10, a9a, a9b, skew_normal), twelve reviews queued behind them. Split: Rose-A4 workflow wf_bd7fb2a8-421 (Opus, ≤4 live) reviews the six family PRs (#1169 #1171 #1172 #1173 #1174 #1176+#641) NOW; wf_06's own Roses will take, in FIFO order as slots free, a7-lrt #1166, a1 #1163, a7-coev #1167, a3 #1168, a5 #1170. STOP wf_06 (TaskStop wtaywieti) once those five verdicts are in the journal, so it never reaches the A4 items and duplicates. A6 (#1175 + DRM.jl #640) has not reported yet — its Rose runs separately after it does.
- (06:30) Rose on #1173 (truncated_nbinom2): NOT refuted (independent driver: |d| 8.8e-11, logLik diff 2.8e-12, names identical). Must-fix → a4-integration (TSV row; registry-derived refusal text; G13 registry↔comparison guard test; G11 DRM.jl evidence PR). Gate armed on #1173. Family PRs need not wait for A3 — only a4-integration and beta_binomial's patch touch the comparison function.
- (06:40) A10 pre-run receipt PR #1177 (6/6 gates): Totoro run 48 s; R 0.181 s vs Julia 0.385 s warm (ratio 2.15); logLik gap 1.9e-5, max |d coef| 1.7e-4 (> 1e-4 bar) → unmatched optima; sdreport()/q4_vcov asymmetry; Julia 1.12.6 caveat; Julia JIT ~35 s cold. FULL GRID NOT RUN (owner gate); recommendation drafted in checkpoint OPEN GATES: fix tolerance + covariance asymmetry, re-pre-run, then grid. #1177 awaits its Rose (separate run with A6's).
- (06:45) Rose on #1171 (zero_one_beta): NOT refuted (independent generator; bit-for-bit). New integrator items G14 (fixef block order alphabetical on Julia) and G15 (one full devtools::test() after the six merge). Family PRs conflict pairwise on the registry list/test vectors/258 §8/NEWS → merge sequentially with hand-resolved unions: #1173 → #1171 → #1169 → #1174 → #1176 (after #641) → #1172 (after A3, with patch).
- (06:50) A9b: premise false — #609's gap was drmTMB's (#1130); DRM.jl #642 pins the Julia side (12/12; LSS suite 1401/0). Integrator: runtests.jl wiring + merge. Rose on #1169 (tweedie): NOT refuted.
- (07:00) DRM.jl #642: runtests.jl wiring added by the integrator; Rose on #642 + #1177 dispatched (Opus). Tweedie's Rose items banked (G16 inform-not-refuse for Julia-ahead dpar shapes; G11 dedupe).
- (05:37, from `date`) TIMESTAMP CORRECTION: the labels on the entries from '(05:55)' through '(07:00)' above were written from a wrong mental clock and run up to ~90 min FAST; the true span was ~05:00–05:35. From here on every entry uses `date`. Also: the A6 builder is alive (polling a Totoro suite run over the socket); #1175 and DRM.jl #640 CI in progress; wt-a6 worktrees clean.
- (09:12) SECOND CAP HIT ~05:45 (resets 09:10): killed Rose-A4's last three (beta_binomial, cumlogit, skew_normal), the tiered A9 wave (all four, nothing reported), the a9a Rose; I had already stopped wf_06 (a2 + a6 builders, three Opus Roses) and the a9b/a10 Roses on Shinichi's credit warning. MERGED: #1164 (A7 model-comparison) 11:41Z, #1173 (trunc-nb2) 11:37Z. POLICY from here: Sonnet for every builder and for mechanical reviews; Opus only for the numerics reviews (#1172 #1174 #1176 #1175/#640); ≤2 agents live; the integrator (me) does merges by hand; monitors trimmed to merges + workflow completions. #1171 (zob) conflicts hand-resolved (registry order: truncated_nbinom2, zero_one_beta), tests green offline, gate armed.
- (09:15) Shinichi: Opus for difficult work, not Fable; other models for most work. Applied: a9c → Opus high when relaunched; all else Sonnet; Rose numerics Opus. Gates armed on #1166 #1167 (A7 arc has Rose coverage via #1164 — N4 is per ARC). Frugal Rose workflow launched (≤2 live).
- (09:24) Rose (Sonnet) on #1170 A5: clear, 0 must-fix → gate armed. Rose (Sonnet) on #1168 A3: clear; must-fix = dedupe pin-clone TSV duplicates (→ a4-integration G11) + honour 'A3 after A6'. RE-JUSTIFIED: A6 measured the five constructs already at parity and only ADDS a refusal for non-treatment contrasts, so it changes no A3 receipt — A3 no longer waits for A6; gate armed on #1168. hurdle_nbinom2 ledgered 'experimental' (native and bridge spell the model differently) — honest downgrade.
- (09:27) CRAN replied on drmTMB 0.7.0 (submitted 08-24 by Shinichi): 3 fixes + resubmit. Codex brief written (LOOP/2026-09-05-codex-brief-…md): Part 1 CRAN fixes on a disjoint file set, no version bump, no submission; Part 2 DRM.jl registry prep with the NAME blocker (≥5 chars) put to Shinichi first. #1168 (A3) MERGED 15:24Z.
- (09:34) GitHub API rate limit hit (reviewers' gh calls + 5 polling gates); gates fail closed until it frees. #1178 (A9a) MERGED 15:32Z. #1170 (A5) red: committed TSV stale after update-branch over A3's rows — Sonnet agent resolving the 10-column merge + regen + tests. #1177 (A10): Rose must-fix applied as an integrator correction in the receipt (ratio not like-for-like); gate to be armed when the API frees. Rose (Sonnet) clear on #1163 (A1, 0 must-fix, merges LAST) and #1178.
- (09:42) #1171 (zero_one_beta) MERGED 15:41Z. Tweedie #1169 hand-merged (registry order trunc, zob, tweedie; parse OK; registry + family tests green offline), gate armed. DRM.jl #642 gate armed (Rose clear).
- (09:43) A5 #1170: Sonnet merge agent stalled after staging the 10-column merge (stopped); integrator proved it (12 ids in order, TSVs regenerate byte-identically, gate-vs-engine 149/0, registry 22/0, bridge 140/0, ledger OK), committed, pushed, gate re-armed.
- (09:47) Frugal Rose workflow done 9/9, 0 refuted. Opus: #1172 bb clear (must-fix → a4-integration: registry-derived refusal text; bridge-rejection-messages.tsv row + validate-mission-control.py; new G17 fe-only RE pre-refusal); #1174 cumlogit clear (integrator items already ledgered); #1175/#640 A6 clear (Totoro suite 179/179 on 6af7a14a4 transcribed into leaf-a6; #640 gate armed, #1175 after it). Family merge order stays strictly sequential: tweedie #1169 (gate polling) → bb → cumlogit → skew. A9 wave relaunched tiered (a9c Opus high; a9d/a9e/a9f Sonnet; ≤2 live).
- (09:49) Rose (Sonnet) on skew_normal (#1176 + DRM.jl #641): NOT refuted (|d| 1.9e-11; same transform). #641 gate armed. ALL SIX families and every other leaf now have a Rose verdict; nothing refuted across 15 reviews. FINAL STEP NOTE: the final re-pin (last DRM.jl merge commit: #640 #641 #642 + a9c) must repeat A0's protocol in full — probe clone, Manifest carry-over, precompile, the whole live test-julia-* sweep (now with six new family tests), THEN the tip-identity receipt — because six admissions + A6 + a9c changed what the pin fits.
- (09:51) #1166 #1167 (A7 ports) hit NEWS.md conflicts at the merge step (main moved after the probe); hand-merged (union), port tests green offline (lrt 62/0; coev see log), re-armed. DRM.jl #640 #641 #642 auto-merge ARMED (verified).
- (10:22) #1172 beta_binomial: merge + integrator patch landed properly on the second attempt (first commit's message over-claimed the comparison row — corrected in a follow-up commit, never merged). Findings: mission-control validator vocabulary lacked 'partial' (12 pre-existing errors on main) → added; regeneration-status counts stale on main (9/15) → set 22/13. Gate re-armed.
- (10:29) #1170 A5 red = R CMD check WARNING 'non-ASCII in code files' (two comparison-row strings with en-dashes); fixed (ASCII), TSV regenerated (24 rows on that branch), re-armed. Other branches' non-ASCII hits are pre-existing comment characters in five R files (main is green with them). #1166/#1167 self-healed via the patched integrate.sh (NEWS union, d0ac5411f / 9d17fcd9d). EXPECT: #1170 and #1172 both touch drm_julia_capability_comparison() + the TSVs → whichever merges second needs a hand-merge (not NEWS-only). a4-integration must set capability-regeneration-status.tsv counts to the FINAL row totals.
- (10:49) DRM.jl #640 #641 #642 were unmergeable: main merged #626 (4-way CI shards + ci-ok aggregator, now the only required context) after the branches were cut, so their heads never produced ci-ok. Merged main into all three (NEWS union where needed), pushed; auto-merge stays armed.
- (10:50) DRM.jl #642: after merging main's regenerated sharded runner, the merge had kept a bare include (would run in every shard); replaced with _shard_include (8fafa2844). All three DRM.jl PRs now carry the ci-ok aggregator; CI rerunning; auto-merge armed.
- (10:52) GH Actions audit (Shinichi asked): both repos PUBLIC → Linux minutes are free; today drmTMB 53 runs (32 ok, 10 red = A5's ASCII/TSV reds + #1163's designed red, 6 superseded), DRM.jl 50 runs (0 red, 9 superseded); 5 + 7 runs live, no queue backlog beyond 1. A CODEX LANE IS NOW LIVE on drmTMB (codex/cran-examples-resubmission-2, the CRAN brief) — its OWNS (roxygen of the named topics, man/, cran-comments.md) is disjoint from every parity leaf; do not touch those files in a4-integration or A11.
- (10:56) Rose (Opus) on #1180 A9e: NOT refuted; must-fix done by the integrator (animal()/spatial() assertions added, 36/0; pre-rebase md5 annotated), pushed df2fb12c8, gate armed. #1166 (A7 lrt-boundary) MERGED 16:53Z.
- (11:01) #1172 bb re-merged over A5 and pushed (65d3677e9); its gate keeps polling. a9c reported DRM.jl #644 (two-SD slope) 7/7 met, 3 blockers; a9d Rose: not refuted, 3 must-fix.
- (11:01) A9c DRM.jl #644: two-SD Gaussian phylo random slope IMPLEMENTED; same-target vs drmTMB on the fixture: logLik |d| 2.2e-13, sd_a/sd_b/betas/log_sigma |d| ≤ 4.6e-13; DRM.jl resd block coef_names [species, species:x]. Two declared OWNS deviations (runtests _shard_include; test_bridge_formula_translation.jl assertion flipped from 'refused' to 'fits + names') — both necessary. Dense n×n only (no sparse spine); non-Gaussian families still refused; pre-existing test_bootstrap_marginal.jl:143 failure proven on clean main (another lane's). Rose pending. A9d must-fix (3 items) delegated to a Sonnet agent.
- (11:05) A9d #1181: Rose's three fixes applied by a Sonnet agent (gradient_names contract asserted; length mismatch named; two mock tests; diagnostics 29/0, bridge 140/0), pushed 33765d81f, gate armed. A9f #1182: Rose found the bridge probe read a nonexistent field (all 11 bridge cells NA) — Sonnet agent fixing the probe, removing the NA masking, re-running the cells live, regenerating the table. NOTE: the A9 worktrees had upstream=origin/main from ; push.default=simple refused plain pushes (safe); upstreams now set to their own branches.
- (11:07) A9 wave COMPLETE (8/8, 0 refuted). #644 Rose: not refuted (four attacks). Integrator signed off the flipped DRM.jl bridge-translation assertion (correct given #620). Gate armed on #644. After the final re-pin: flip A9e's Gaussian marker-slope switch + R-side receipt.
- (11:12) #1172 bb CI red: test-julia-phylo-count.R:54 expects beta_binomial+phylo to be REFUSED — the fe early-return in drm_julia_family_tag() admitted it (Rose's G17 gap, live). Fixed in the function: fe-only families refuse phylo() unless a registry phylo column admits them; existing phylo families unchanged; 8 test files green offline; pushed.
- (11:14) #1172: my tag-level phylo refusal broke biv_gaussian's bivariate phylo routes and the leaf's own design (tag admits; a pre-Julia scope fence refuses bb+phylo) → reverted; instead updated the third stale refusal test (test-julia-phylo-count.R:54) the patch had missed. G17 (generic fe-only phylo/RE fence) stays with a4-integration and must EXEMPT the bivariate families whose phylo gates live downstream.
- (11:17) A9f #1182: probe defect fixed (fit$bridge$estim_method; NA masking removed; 11 bridge cells re-measured in 47 s: 3 FITS with oracle==belief, 8 REFUSES with real text; design 261 regenerates byte-identically sha 818ac2f1…; 30 rows, 22 agree / 7 disagree / 1 unclassified → the 7 gaps feed A11/#1142). Pushed 37dcbd545; gate armed.
- (11:18) a4-integration worktrees created (drmTMB off main; DRM.jl evidence branch off main). Launching the a4-integration build now (Sonnet high) rather than waiting for the last three family merges; the integrator re-merges main over them as they land.
- (11:21) DRM.jl #644 (two-SD slope) MERGED 17:19Z. a4-integration launched (wf_c5c01d25-79b: Sonnet build → Opus Rose; wt-a4-integration + wt-a4-evidence-drmjl). A8 launched (wf_ff46a79a-602: Sonnet build → Opus Fisher; wt-a8; 'after A6' ordering relaxed by A6's own measurement). Live: 2 Sonnet builders; 5 drmTMB gates; 3 DRM.jl auto-merges pending ci-ok.
- (12:13) A8 #1183: Fisher NOT refuted (every number reproduced). 2 of 4 rows promoted partial→supported (base_gaussian_location_scale, plain_binomial_nonphylo); biv_gaussian_residual: no profile-ready target through the bridge (structural gap, stays partial); gaussian_response_mask: Julia bootstrap fails 99/99 + convergence flag FALSE (stays partial) → DRM.jl issue filed. #1183 merges AFTER #1172 (both touch the comparison function).
- (12:16) A8 #1183: Fisher's corrections applied (b1956a2ec BROKE R/julia-bridge.R — the '#646' insertion landed inside an escaped quote and my test guard passed on EMPTY output; caught within minutes, redone safely in 03d3258dc: parse OK, 24 rows, gate-vs-engine 151/0, registry 22/0). DRM.jl #646 filed (response_mask bootstrap 99/99 fail + convergence flag). #1183 merges after #1172 (shared comparison function). MERGED meanwhile: #1180 (A9e), #1181 (A9d), #1167 (A7 coev — arc complete).
- (12:18) #1182 a9f red = test sourced tools/ at file level (absent under R CMD check) → guarded + skip; design 261 regenerated over the 24-row TSV (A5 merged); re-armed. #1172 re-armed on db7ff6ae3 (its gate had exited on the superseded run). DRM.jl #640: only 'Julia 1 - shard 3/4' still running → ci-ok next.
- (12:26) a4-integration DONE: drmTMB #1184 + DRM.jl #645 (evidence rows, dedupe); Rose NOT refuted (G2 live: tweedie/zob short forms fit at identical logLik). Builder corrections to MY claims: tweedie/zob/trunc had NO comparison rows on any branch (their leaves abandoned G6; I had assumed they landed) → Sonnet agent adding the three rows + fixing the now-stale zob 'KNOWN HOLE' live test on #1184; G17 (generic fe-only RE fence) BLOCKED on OWNS → deferred as a DECLARED GAP for the handover (live risk: RE shapes of fe-only families reach DRM.jl unmeasured; DRM.jl refuses most itself). A2 (THE MATRIX) relaunched: wf_3d9e6ee6-b28 (Sonnet → Opus Rose; resume of wt-a2). Merge order for the comparison-function PRs: #1172 → #1174 → #1176 → #1183 → #1184 (last, regenerates all) → A2.
- (12:39) Shinichi task: profile/bootstrap targets for the residual-only bivariate route (A8's gap). Leaf a8b ledgered; worktrees wt-a8b (drmTMB) + wt-a8b-drmjl created; scout→build→Fisher workflow launching (build on Opus if DRM.jl numerics are needed, Sonnet otherwise). DRM.jl #645 MERGED 18:26Z.
- (12:41) Shinichi task 2: gaussian_response_mask defects (DRM.jl #646). Leaf a8c ledgered; worktrees wt-a8c + wt-a8c-drmjl; scout→build(Opus)→Fisher workflow launching.
- (12:42) A8c launched (wf_9f82b82c-974). Live agents ≈ 4; no further launches until one returns.
- (12:44) #1184: three missing rows added (29 rows; pushed 9aa5d020e; live zob test 48/0). Deviation noted: the five new rows are 'experimental' pending the validator vocabulary fix on #1172 → set to 'partial' at #1184's final re-merge; design 261 regen deferred to the same step (#1182 unmerged). Live agents: A8b, A8c, A2.
- (12:46) #1172 bb re-merged over main (gate registry: main's structured_marker_slope kept, base_unsupported_family retired; 14 gates / 25 rows; validator new=0, fixed=14; six test files green), pushed ce7ba9ed1, re-armed. DRM.jl #640/#641/#642: ci-ok SUCCESS; re-merged main / re-armed auto-merge where needed.
- (12:47) DRM.jl #640/#642 were BEHIND (protection requires up-to-date branches): merged main, pushed; CI reruns; auto-merge armed. Each DRM.jl merge makes the others BEHIND again — serial chain, ~40 min per PR.
- (12:48) #1182 (A9f REML-by-route table, design 261 + generator + test) MERGED 18:47Z. Design 261 will be stale on main until the comparison-row PRs regenerate it; CI skips that test (tools/ absent under check), and #1184's final re-merge + A11 regenerate it — accepted, not churning #1172 again for it.
- (12:52) A2 THE MATRIX DONE: PR #1185; Rose NOT refuted (359/359 citations resolve; 221 semantic checks; byte-identical ×3). Headline (computed): 43 rows, 4 GREEN on all three axes, 39 with cited boundary, 0 uncited. Join corrected 47 DRM.jl rows / 4 DRM.jl-only. Its admitted-without-row test names tweedie/zob/trunc (fixed by #1184) → #1185 merges AFTER #1184; regenerate the matrix at A11 (GREEN count will move when A8's promotions land). Lesson from the builder: hand-authored fallback strings in a generator go stale when upstream rows land — re-validate against the raw TSV. Live agents: A8b, A8c.
- (12:54) SCOUTS (confirmed live at the pin): A8b — profile already works for a bivariate residual DrmFit (no ranef; _fit_bivariate_residual attaches a plain nll closure); only drm_julia_wald_targets() (R/julia-bridge.R:4296-4337, is_biv gate) blocks it; BOOTSTRAP needs DRM.jl: _bootstrap_fit_formula (src/inference.jl:1764-1771) accepts DrmFormula only, not BivariateDrmFormula → Opus building both halves. A8c — (1) false 'not converged': _nondegenerate_fit (summary.jl:125-142) takes std over the full 60-row response that still carries NaN at the 6 masked rows (left by _with_full_fixed_gaussian_rows) → NaN yscale → degenerate → convergence=1 on a fit Optim reports converged; (2) bootstrap 99/99: _simulate_once (gaussian_core.jl:1685-1699) DimensionMismatch 60 vs 54 because the masked fit carries nobs=54 while means/scales have 60 rows → Opus building the DRM.jl fixes + tests + re-qualification.
- (13:01) Shinichi asked 'all OK?' on the Actions page. Parity lane: yes (in-progress = expected; the cancelled main runs for #1180/#1181 were superseded by later main pushes, and main's current run 3714cc80e is being waited on). One real red outside the lane: R-hub #22 on the Codex CRAN branch — rchk (TMB-header protect-stack pattern) and clang-asan (two vignettes numerically fragile under instrumentation; no sanitizer report). Recorded as an addendum to the Codex brief.
- (13:15) main run 3714cc80e (after #1182) SUCCESS — main green on the whole tree. #1172 gate refused at merge time ('requirements have been met' = branch behind after #1182); integrate.sh re-entry now also fires on that message; bb merged main again (261 test included), re-armed.
- (13:16) Since #1182 landed, every comparison-row PR must regenerate design 261 before merging (source-tree test pins it byte-identical; CI skips it). bb regenerated 261 (25 rows), pushed, re-armed. zsh note: unquoted $VAR does not word-split — loops over conflict lists must use ${=VAR} or run under sh (the earlier 'MANUAL: NEWS.md' misfire).
- (13:20) Pre-merged main into cumulative_logit (#1174; registry pins fe + dispersionless; 7 files green; armed) and into A8 (#1183; see above). bb #1172, cumlogit #1174, A8 #1183 gates now RACE on CI; each loser needs one more small re-merge (registry row / comparison rows / 261). This trades serial hand-merges for parallel CI.
- (13:22) Pre-merged main into A6-drmTMB (#1175, clean, 4 files green) and A1 (#1163). Three gates racing (#1172 #1174 #1183); #1176/#1175 armed on their DRM.jl halves' merges; A1 last.

### 2026-09-05 13:46 MDT — validator vocabulary fix (owner task, measured)
- Task: admit "partial" to R_BRIDGE_STATUSES in tools/validate-mission-control.py:12888 with a design/192 citation; confirm the error delta equals the partial-row count and nothing else moves.
- Measured on clean origin/main 3714cc80e (wt-main-probe): 33 errors before, 12 of them "invalid r_bridge_status 'partial'"; 12 partial rows in inst/extdata/julia-capabilities.tsv. Scratch-applied one-line change, re-run: 21 errors, 0 partial-vocab; remaining 21 lines byte-identical to before-minus-partial (diff empty). Probe file removed; probe tree clean.
- Landing: the set line already sits in #1172 (121f48d0e, 3/4 shards green at 13:43) — NOT re-pushed (would restart its CI). The identical set line + citing comment committed on claude/parity-a4-integration at 1b144eb67 (unpushed; goes out with the #1184 final re-merge; identical hunk → clean merge over #1172). Validator on that branch: 19 errors, 0 partial-vocab. No row status changed.
- Owner asked (13:4x): "speed things up", "accurate and cost efficient, ultracode": inline for this one-liner (a workflow would cost more than the edit); Workflow stays the vehicle for the substantive arcs (A8b/A8c live; integration steps next).

### 2026-09-05 13:52 MDT — #1172 MERGED (19:46Z); racers re-merge; A8c built and reviewed
- drmTMB #1172 beta_binomial MERGED -> main 802522384. Post-merge main run: see below.
- #1174 and #1183 now conflict beyond NEWS (registry row / test pins / 258 addendum; regeneration counts) -> hand re-merge dispatched as Workflow wf_695a7fc1-c01 (two Sonnet agents, commit only; I verify and push). Their integrate.sh gates (pids 25665/25779, 28368/28502) keep polling the PR numbers and will pick up the new heads.
- A8c workflow wf_9f82b82c-974 DONE: PR_OPEN drmTMB #1186 + DRM.jl #648; Fisher not refuted; 5 must-fix items -> Workflow wf_136d228b-be9 (Sonnet). Details in leaf-a8c-response-mask.md addendum.
- Validator vocabulary fix: on main via #1172; cited comment at 1b144eb67 on claude/parity-a4-integration (unpushed).

### 2026-09-05 13:54 MDT — A8b DONE (built + reviewed); Fisher must-fix dispatched; DRM.jl #647 armed
- Workflow wf_99dbb160-055: PR_OPEN drmTMB #1187 + DRM.jl #647; 10/10 gates; Fisher not refuted; 4 must-fix (rho12 guard-offset disclosure; Wald-bar qualification; real G6(b) hash; guard-constant issue) -> wf_c95aab20-b83 (Sonnet). Details: leaf-a8b-biv-inference.md addendum.
- DRM.jl #647 needs no change from the must-fix list -> integrate.sh itchyshin/DRM.jl 647 (auto-merge arm) started; keep-current loop #2 started for 647 -> wt-a8b-drmjl and 648 -> wt-a8c-drmjl (5 h). #648 is armed only after wf_136d228b-be9 pushes its test annotation.

### 2026-09-05 13:58 MDT — DRM.jl main moved (owner's docs PR #643, 19:53Z); four DRM.jl branches re-based; Totoro dispatched
- DRM.jl main 4fea04338 -> 292067b0f (Shinichi, docs only). Up-to-date rule => every open DRM.jl PR needed a re-merge; the keep-current loops only react after CI flips BLOCKED->BEHIND, so I merged main into the four clean worktrees once, proactively: #640 d74ed062e, #641 79f3f7af0, #642 df1a3d102, #647 e0e39fd00 (no conflicts). #648 left alone (wf_136d228b-be9 is editing it; keep-current-2 pid 98260 covers 647/648 afterwards).
- Owner (14:0x): "ultracode our way to success" · "Remember we do have Totoro and all DRACs". Totoro use found: the A8b/A8c builders ran only blast-radius subsets of the DRM.jl suite and no full drmTMB suite. Workflow wf_1f641ab8-58c (Sonnet): full DRM.jl suites on #647/#648 heads + full no-Julia drmTMB devtools::test() on #1186/#1187 heads, via the cm- socket only, <=40 cores. D-139 ESTIMATE: DRM.jl ~10-20 min/branch, drmTMB ~30-45 min/branch (pre-run filter="julia" first), all parallel, ~1 h wall; overrun x2 => stop and re-report. DRAC: no multi-seed campaign in the remaining arcs (D-181 #2); bridge work cannot leave the Mac (JuliaCall segfault on Totoro) — nothing to submit.
- Live agents: wf_695a7fc1-c01 (racer re-merge x2), wf_136d228b-be9 (A8c must-fix), wf_c95aab20-b83 (A8b must-fix), wf_1f641ab8-58c (Totoro). Session model unchanged (Fable); children Sonnet, Opus only for numerics/adversarial.

### 2026-09-05 14:00 MDT — racers re-merged and pushed
- wf_695a7fc1-c01 (2x Sonnet) COMMITTED: #1174 cumulative_logit f2a7a6f11 (registry: tweedie -> beta_binomial -> cumulative_logit; pins unioned; 258 addenda 8.2 then 8.9; TSV 25 rows unchanged), #1183 A8 47e7b1baf (counts 25/25, gates 14/14 = main; promoted rows intact). Tests on both: family-registry 22/0, reml-route-table 5/5, gate-vs-engine 142-144/0, phylo-count 17/0/1 skip. Validator 19 lines each (all pre-existing on main). Pushed after my checks (porcelain empty, no conflict markers, parse ok, contains main).
- FINDING (cumlogit agent): #1174 never added a comparison row (its leaf added only the registry row). Not a blocker: #1184 carries fe_cumulative_logit (+ fe_skew_normal, fe_tweedie, fe_zero_one_beta, fe_truncated_nbinom2; 29 rows, 30 after re-merge with fe_beta_binomial); the guard test passes on the merged #1174. Same holds for #1176 skew_normal.
- Agent hygiene: a scratch dir scratchpad/main-check left behind (rm -rf denied) — harmless, outside every worktree.
- [ ] A4.G17 fe-only scope fence (declared gap from leaf-a4-integration) — leaf-a4g17-fe-only-fence, wt-a4-g17, merges after #1184

### 2026-09-05 14:05 MDT — A8c must-fix applied; DRM.jl #648 armed; G17 leaf dispatched
- wf_136d228b-be9 DONE: #1186 e2731cb51, #648 ae8a0246e, issues #1188/#1189. integrate.sh itchyshin/DRM.jl 648 started (BEHIND main 292067b0f -> update-branch then arm). Details: leaf-a8c addendum.
- G17 leaf (fe-only scope fence): ledger leaf-a4g17-fe-only-fence.md (G0-G10), worktree wt-a4-g17 @ 802522384; Workflow scout(Sonnet) -> build(Sonnet) -> Rose(Opus).

### 2026-09-05 14:08 MDT — Totoro suites running; harvester started
- wf_1f641ab8-58c returned PARTIAL (agent session ended mid-run; nothing killed). On Totoro (~/parity-joint, socket pid 9961, load 17 on 384 cores): DRM.jl-647 (e0e39fd00) and DRM.jl-648 (3d11bf9b0) Pkg.test running (julia 1.12.6, 8 threads each); drmTMB-1186 (cd98e5190) and drmTMB-1187 (00f4ce19f, pre-must-fix head) full no-Julia devtools::test running (8 workers each; pre-runs skipped 33/32 live tests as designed). Started 13:58; harvester totoro-harvest.sh polls every 3 min, copies logs to totoro-logs/, 3 h bound.
- Note: pre-existing julia-1.10.10 processes on Totoro belong to an earlier lane, not this run; left alone.

### 2026-09-05 14:10 MDT — A8b must-fix applied
- wf_c95aab20-b83 DONE: #1187 fe1959aec; issue #1190; offset reproduced 3.7714e-07 vs 3.7715e-07; G6(b) corrected (2+2, not 3+3). #1187 merges after #1183/#1184 (re-merge; wave-1 guard split union) and after DRM.jl #647 (armed).
- Backlog check (gh): #1156/#1144 addressed by merged #1178 but still OPEN; #1108 addressed by #1181/#1112 but OPEN; #1083/#1081/#1150 -> #1163 (A1, last). DRM.jl #620 CLOSED; #606/#609/#624/#471/#627 OPEN.

### 2026-09-05 14:12 MDT — BEYOND: two REML parity gaps opened (#1142 / DRM.jl #624 remainder)
- 261 shows TMB FITS / DRM.jl REFUSES / bridge REFUSES for gaussian_phylo_mean REML (#624 item c) and biv_gaussian_residual REML (new finding of #1182). Leaves leaf-reml-phylo-mean and leaf-reml-biv-residual (G0-G9), worktrees wt-reml-* (drmTMB @ 802522384) and wt-reml-*-drmjl (DRM.jl @ 292067b0f). Shape: Sonnet scout -> Opus build (DRM.jl numerics + bridge gate + receipt) -> Opus Fisher. Their DRM.jl PRs join the chain; the final re-pin waits for them.
- Also dispatched (Sonnet, parallel): issue reconciliation (#1156/#1144/#1108/#1142 vs merged PRs), the bivariate Student/LogNormal cells census (#471 prerequisite, fog ticket), and the #606/#1129 precision-bar decision DRAFT (owner decision; doc PR only).

### 2026-09-05 14:16 MDT — owner: "make sure these will be OK" (DRM.jl Actions screenshot)
- Red = Documenter run 33988880206 on #648 (ae8a0246e): docs built + doctests OK; failed at 'git push upstream HEAD:gh-pages' ("failed to push some refs") = gh-pages preview-deploy race with the other parity PRs' docs runs (5 branches synchronised within one minute). Not a content failure. 'docs' IS a required context on DRM.jl main (["docs","ci-ok"]), so it blocks #648 until green -> rerun requested. Everything else in the screenshot = queued/in-progress.
- Root cause: docs/make.jl push_preview = true (owner's recorded choice, kept) + per-ref concurrency in Documenter.yml => concurrent PR preview deploys race on gh-pages. #640's docs run also lost (33988604977) -> both re-run. drmjl-docs-rerun.sh (pid 63687, 5 h) re-runs only push-race failures every 5 min. Filed DRM.jl issue (above) with a retry-step patch; NOT opened as a PR now because every DRM.jl merge forces a full CI rerun of every other open PR under the up-to-date rule — the loop is free, a PR is not.

### 2026-09-05 14:27 MDT — Totoro drmTMB suites hit testthat's 10-failure cap; restart with a main baseline
- drmTMB-1186 and drmTMB-1187 both stopped at 10 failures, identical and in files neither PR touches (test-associate-pairs-gaussian-bernoulli.R:213, test-b2-q6-serial-proof-receipt-audit.R:11 Error, test-check-conditioning.R:60-61, test-function-map-cheatsheet.R:20 x6). CI on ubuntu is green on main => Totoro-environment delta. Restart plan: run-full-test.R (max_fails Inf, 8 workers) on drmTMB-main @ 802522384, drmTMB-1186, drmTMB-1187; verdict = branch failure set minus main failure set must be EMPTY. D-139 ~30-45 min each. First attempt was cut by the 3-min tool timeout during the clone; state re-inspected before restarting.
- 14:28: Totoro state confirmed after the timeout: runner present, drmTMB-main @ 80252238, three run-full-test.R runs live (logs ~340 lines); harvester v2 (task byuy1obja) polls for DONE-*.txt + the two DRM.jl suites, copies logs + failure CSVs to totoro-logs/. Docs audit leaf launched: wf_4e7c27eb-d37 (Sonnet) on wt-docs-julia -> PR to merge after #1184 and the G17 PR. Live workflows: G17 wf_f1db2e83-0f3, REML gaps wf_c86e02c0-34a, small leaves wf_3e52710b-527, docs wf_4e7c27eb-d37.

### 2026-09-05 14:35 MDT — small leaves DONE; owner: "keep pushing, as many agents as possible"; DRM.jl chain rebased again
- wf_3e52710b-527: issues #1156/#1144/#1108 CLOSED with file:line proof comments; #1142 status checklist (stays open: two REML gaps in build). Census PR #1192 (docs): biv_student + any marker refused on BOTH engines (#471 fence binding); biv_gaussian + animal() q2 REML refused by drmTMB (drm_validate_reml_spec_biv admits phylo/spatial/relmat only, R/drmTMB.R:2953-2977) but fit by DRM.jl -> candidate R-side leaf; biv_gaussian + spatial() q2: direct DRM.jl refuses, bridge rewrites to relmat+K and fits; biv_gaussian + meta_V REML: TMB fits (logLik -103.231247629401), DRM.jl refuses (no REML target), bridge cannot marshal V (known 261 boundary). Precision-bar owner draft PR #1191 (DRAFT).
- DRM.jl main -> d3efbad2f (owner's #420 LOOP docs). Five PRs rebased: #640 7bea27829, #641 60f09f959, #642 805a0dd80, #647 a395643a0, #648 20b2fb72e. #641 had a REAL failure (Julia 1.10 shard 1/4 on 79f3f7af0) -> wf_92291e40-798 (Sonnet) diagnosing.
- ZIP/ZINB/hurdle: NOT a gap (zi/hu dpars on poisson/nbinom2; already bridged and ledgered by A3 #1168) — verified before dispatching anything.
- New leaves: leaf-cumlogit-predict (wt-cumlogit-predict off #1174's head); reverify sweep of merged leaves + Julia-ahead census dispatched (Sonnet).
- 14:38: worktrees wt-julia-ahead (for the Julia-ahead census agent in wf_861ff36c-308) and wt-biv-animal-reml (+ ledger leaf-biv-animal-reml, G0-G9) created; cumlogit predict leaf launched wf_f18c77ad-600; reverify sweep + Julia-ahead census wf_861ff36c-308.
- 14:41: owner screenshot: Documenter #1208 red on #642 (805a0dd80) = push race again after the 5-branch rebase (20:39Z); re-run by hand (33990394770); loop pid 63687 covers later ones. Other rows queued/in progress.

### 2026-09-05 14:42 MDT — docs audit DONE: PR #1193 (a0eae8e13)
- Fixed stale user-facing claims: R/drmTMB.R @param engine ("bridge is halted ... not a current fitting route") and @param REML; julia-engine.Rmd boundaries + new family/route/receipt table; README.md:209-210 and proportion-beta-binomial.Rmd:170 blanket "unsupported" narrowed; man/drmTMB.Rd regenerated; vignette renders.
- CORRECTIONS TO MY BRIEF (recorded): zi_poisson/zi_nbinom2/hurdle_nbinom2 are admitted (dpar routes) — matches my own check; the G17 fence PR did not exist yet when it wrote, so #1193's random-effect paragraph describes DRM.jl's own refusal, not the fence. MUST-DO before merging #1193 (after G17 lands): rewrite that paragraph to describe the pre-Julia fence (one mechanical edit on the same branch).
- FOLLOW-UPS it surfaced: more "halted"/"deferred" roxygen in R/julia-bridge.R (~4063 confint.drmTMB_julia, ~4771 summary.drmTMB_julia, ~6969/~7075 cross-family methods); vignettes/capability-and-limits.Rmd not audited; R/julia-family-registry.R's "NO case yet" comment block stale (integrator fixes at the final re-merge — #1174/#1176 touch that region). -> extending the SAME branch (wt-docs-julia, #1193) with a Sonnet sweep now.
- 14:44: #641 shard failure = FLAKY (wf_92291e40-798): test_locscale_profile_threads.jl non-finite endpoints, non-sparse Gamma LSS profile route, unrelated to #641; 7/7 local passes; filed DRM.jl issue (above) as the partially-closed #631 class. No code change; rebased head 60f09f959 re-running.

### 2026-09-05 14:47 MDT — audits DONE: N1 reverify sweep + Julia-ahead census (#1194)
- N1: reverify-merged-leaves.md written (15 ledgers re-run with --reverify; gates without CHECK lines confirmed via mergedAt only; a0:G6 JSON-spacing mismatch and origin/main-diff staleness on a0:G7 / a7-coev G6-G7 flagged as evidence, not defects). Agent ran a duplicate gate-check on the coev worktree and killed it before its file-modifying step — worktree cleanliness checked here.
- Julia-ahead census PR #1194 (docs): "Tweedie random intercept (mean)" and "Gaussian phylo intercept+slope two SDs" are ALREADY native in drmTMB (R/drmTMB.R:20063-20067; test-tweedie-location-scale.R:456-483) — documentation gaps in drmTMB's capability-status.md, not code gaps; live join is 48 DRM.jl rows / 5 DRM.jl-only (plan said 46/3 -> 47/4). Two user-facing Julia-ahead port candidates: general-q coevolution; generic epsilon-method bias correction (sizes estimated). Engine-internal exports accounted in Table D. -> #1185 (A2) re-merge checklist: add the two native rows to capability-status.md, update the join counts to the live 48/5, regenerate the matrix.

### 2026-09-05 14:50 MDT — #1174 MERGED (cumulative_logit); chain advances
- #1174's integrate.sh gate had died (no process); all five checks were green and CLEAN -> merged by hand with pr_merge_when_green.sh (settled table quoted in its output). #1183's gate (pid 28503) alive; #1183 re-merged over new main (NEWS union) and pushed — see above.
- Docs sweep wf_e8079ac9-faa PUSHED fe3e1cadc on #1193: confint/summary/xfam roxygen + capability-and-limits.Rmd de-"halted"; man/ regenerated. Note: on main no row is r_bridge_status "supported" yet (#1183/#1187 promote rows) -> at #1193's re-merge (after G17 + #1183 + #1187): rewrite the fence paragraph AND mention the supported rows.
- Totoro: DRM.jl-647/648 full suites: 432/427 test sets, 0 failure columns, but "ERROR: LoadError: wrong thread budget" (line 3333) -> the harness ran Pkg.test with JULIA_NUM_THREADS=8 against a guard expecting the CI budget; rerun with the guard's expectation. drmTMB-1186 [FAIL 15|ERROR 1|SKIP 91|PASS 46255] 7.5 min; drmTMB-1187 [FAIL 15|ERROR 1|SKIP 91|PASS 46293] 7.6 min; main baseline still running -> delta when it lands.

### 2026-09-05 14:54 MDT — stash collision between the two REML DRM.jl worktrees; repaired
- The biv-residual builder reported (agent message): git stash is REPO-GLOBAL across worktrees; its RED-CONTROL stash and the phylo-mean lane's stash swapped (~14:46). Repair (integrator): reverted the biv hunk in wt-reml-phylo-mean-drmjl (its copy is committed on the biv branch at 7bb952809), popped stash@{0} "redctrl-b" back into the phylo-mean worktree (src/gaussian_core.jl, src/location_only.jl, test/runtests.jl restored; test file present; shard line present). Stray untracked copies left in the biv worktree (test_reml_reml_phylo_mean.jl, _neighbours_tmp.jl), harmless. No REML PR existed yet, so nothing shipped incomplete. LESSON (vault at closure): never git stash in a multi-worktree repo; use git diff > patch / git show HEAD:file for red controls.
- #1183 (A8) re-merged over main 58fa2374d (NEWS union only) and pushed: 466600320 (gate pid 28503 keeps polling). The earlier "MANUAL" verdict was my zsh word-splitting bug (unquoted $CONF) — fixed with ${=CONF}.
- Totoro: DRM.jl-647/648 single-threaded reruns started (JULIA_NUM_THREADS=1, OPENBLAS 1, as the joint-missing test guards require) -> suite2.log (143 lines at start). drmTMB-main v2 log stuck at 34 lines since ~14:20 -> inspecting.
- 14:55: drmTMB-main baseline on Totoro had crashed (testthat parallel event-loop worker error, 34-line log kept as full-test-v2.crashed.log); re-run alone (8 workers). Branch results stand: 1186 [FAIL 15|ERROR 1], 1187 [FAIL 15|ERROR 1]; delta computed when main lands.

### 2026-09-05 14:57 MDT — G17 builder interim report (agent message)
- Implementation done, tests green, PR imminent. Declared OWNS deviation: ONE line added to tests/testthat/test-julia-gate-vs-engine.R (the literal expected_gate_ids vector gains "fe_only_random_effects") because G5 (new gate row) and G8 (that test must pass) contradict otherwise — accepted; Rose will check it is one line. Scope finding: phylo() on fe-only families is already refused pre-Julia by drm_julia_phylo_payload(); relmat()/animal()/spatial() by drm_julia_structured_family_tag() (measured) — so the fence covers ordinary bar terms + sd() submodels, the actual gap; adding phylo() would have shadowed the existing message and broken test-julia-family-beta_binomial.R's pin.
- INTEGRATION NOTE: test-julia-gate-vs-engine.R is now edited by #1183 (A8: wave-1 guard split), #1187 (A8b: split incl. biv_gaussian_residual supported) and the G17 PR (one line) -> three-way union at the #1184 / #1187 / G17 re-merges; the expected_gate_ids vector and the wave-1 assertions must each end up as the union.

### 2026-09-05 14:59 MDT — CORRECTION: DRM.jl main does NOT require up-to-date branches
- Measured: gh api repos/itchyshin/DRM.jl/branches/main/protection -> strict=false, contexts [docs, ci-ok], 0 reviews; no rulesets. drmTMB main: unprotected. So a BEHIND PR auto-merges when its own docs+ci-ok are green. The "up-to-date serial chain" premise (inherited from the earlier lane's notes) was WRONG; today's two proactive rebases of five branches (14:0x after #643, 14:3x after #420) restarted their CI needlessly and caused the gh-pages preview races (#649). Both keep-current loops (57241, 98260) stopped; docs-rerun loop kept. LESSON (vault): measure the protection rule (strict / contexts / rulesets) before assuming an up-to-date requirement; "BLOCKED" meant pending/missing required contexts, not staleness.
- Estimate revised: DRM.jl #640/#641/#642/#647/#648 merge as each goes green (~15:15-15:40); the REML DRM.jl halves likewise; the final re-pin can start as soon as the last DRM.jl PR merges. Closure ~20:30-21:30 if no new reds.

### 2026-09-05 14:59 MDT — ledger hygiene DONE (wf_aadedb0f-974)
- a0:G6 -> JSON-parsed pin check (PASS, drmjl_base=430ef64cc); a0:G7 and coev:G6 -> diff vs the leaf's own base (PR baseRefOid, merge-base confirmed) (both PASS). coev:G7 now FAILS for a real reason: merge-in cd08bdc0a resurrected three man/ files revert 2c448a24c had removed (man/confint.drmTMB.Rd, drm_julia_joint_prepare.Rd, drm_julia_joint_result.Rd). Benign on main today (document() no-op, CI green) -> ABANDON with reason in the ledger; closure lesson: merge-ins must not resurrect reverted files (check commit fd93c8710cc0173b3a042cfd9625833bccc1f8b7
Author: Shinichi Nakagawa <itchyshin@gmail.com>
Date:   Wed Aug 19 12:01:52 2026 -0600

    docs: restore original function map artifacts

commit 30c50cee90f93ebdaf7bfcd7ad6d24bcb2708073
Author: Shinichi Nakagawa <itchyshin@gmail.com>
Date:   Tue Aug 18 14:38:35 2026 -0600

    docs(release): repair 0.7.0 candidate surfaces

commit 8659319cc72b40158cc593c4fb390077ba7f97e9
Author: Shinichi Nakagawa <itchyshin@gmail.com>
Date:   Sat Aug 15 08:00:37 2026 -0600

    chore: drop stray figure/ debris from the package root
    
    The third --as-cran run reported 0 errors, 0 warnings and 2 notes. One note was
    "Non-standard file/directory found at top level: 'figure'" -- two PNGs that
    knitr wrote into the package root while I was knitting spatial-models.Rmd to
    diagnose the search-path leak, and that git add -A then swept into a commit.
    
    The repo's guidance is to stage scoped paths and never git add -A. Not following
    it put build debris in the tree and cost a check note.
    
    The remaining note is the expected New submission. No unstated-dependency note
    appeared, which is what makes the metadat declaration observed rather than
    merely reasoned.
    
    Refs #60.
    
    Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

commit e7570030f50780c64136e04bfed00e4df35b745c
Author: Shinichi Nakagawa <itchyshin@gmail.com>
Date:   Sun Aug 9 20:32:58 2026 -0600

    fix(cran): resolve the file-URI NOTE without shipping a loose PNG
    
    The first attempt at this NOTE traded one NOTE for another. Adding
    vignettes/.install_extras installed function-map-cheatsheet.png into inst/doc,
    which did clear the invalid-file-URI NOTE but immediately raised a new one:
    
      * checking installed files from 'inst/doc' ... NOTE
      The following files should probably not be installed:
        'function-map-cheatsheet.png'
    
    Measured, not assumed: a local R CMD check --as-cran returned Status 2 NOTEs.
    
    Root cause, corrected. The vignette uses the image TWICE. knitr::include_graphics()
    embeds it, and html_vignette is self-contained, so that reference was never the
    problem. The problem was a separate hyperlink -- "[Open the full-size function
    map](function-map-cheatsheet.png)" -- which cannot be embedded and needs a real
    file on disk. Shipping the PNG treated the symptom.
    
    The link now points at the published copy on the pkgdown site, verified to return
    HTTP 200 before use (CRAN checks URLs, so a guessed path would have traded the
    NOTE a third time). The image remains embedded at 100% width with its full
    fig.alt, so nothing is lost for a reader offline; the affordance is preserved for
    a reader on a small screen.
    
    .install_extras is reverted -- nothing loose ships.
    
    Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

commit 82f0da85fdad8fe3d23d179e75a127e9b562512d
Author: Shinichi Nakagawa <itchyshin@gmail.com>
Date:   Sun Aug 2 17:47:48 2026 -0600

    test(arc3): 3-seed Totoro campaign for mc-0421/mc-0424 after DGP redesign
    
    Reruns the interval-feasibility campaign for mc-0421 (nbinom2 ML,
    sd:sigma:phylo(1 | species)) and mc-0424 (nbinom2 ML,
    sd:sigma:relmat(1 | id)) on Totoro with the SAME seeds
    (2026080301/02/03) as the prior 2/3 failures, to test the redesigned
    DGPs: mc-0421's coalescent tree (condition number 98,563) replaced
    with a Grafen-branch-length tree (183); mc-0424's n_id raised 40 -> 80
    to shrink the finite-sample intercept/slope confounding (cor -0.457
    -> 0.135) diagnosed from the seed 2026080303 failure.
    
    All 6 receipts (2 cells x 3 seeds) now PASS: converged, pdHess=TRUE,
    profile_boundary=FALSE, promotion_eligible=TRUE, including seed
    2026080303, which failed both cells before the redesign. Both cells
    reconcile 3/3 PASS via tools/arc2_profile_reconcile.py.
    
    Replaces the prior superseded FAILED receipts/traces/fixtures/logs for
    these two cells (source_sha a34bb7509, matching the base commit the
    Totoro worktree was checked out from) with the fresh 6-run cohort;
    they are superseded by the DGP redesign, not hidden. mc-0424's
    artifact rung label also changes (id40_each25 -> id80_each25) to
    reflect the larger n_id.
    
    Adds tools/run-arc3-totoro-campaign.sh, mirroring the existing
    tools/run-arc2-totoro-campaign.sh driver pattern for this cell pair
    ('^'-delimited fields; a literal '|' would silently shift the
    random-effect target strings).
    
    Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

commit 48b4b0df378359581c0be53af1c1f7f15edb817e
Author: Shinichi Nakagawa <itchyshin@gmail.com>
Date:   Mon Jul 20 21:20:22 2026 -0600

    docs(release): post-merge honesty sweep — retire residual v0.5.0-as-milestone claims
    
    A final adversarial completeness audit of merged main found two residual instances of the
    v0.5.0-stale defect class the D-43 panel had caught once in ROADMAP (0.5.0 was ditched / never
    accepted; 0.6.0 is the first CRAN submission):
    - NEWS.md:363 "0.5.0 is the first CRAN release" -> corrected to a superseded historical note.
    - cross-family.Rmd:23,308 "ships in 0.5.0" -> "ships in `drmTMB`" (drop the misleading v0.5.0 anchor).
    
    Also: remove the stale CRAN-SUBMISSION marker (Version: 0.5.0, from the ditched cycle;
    .Rbuildignore'd, regenerated on real submission) and land the plan-vs-actual reconcile on main
    (carried from commit 77457878). Exhaustive re-sweep of all shipped-surface "0.5.0" mentions confirms
    the rest are honest (README/ROADMAP "first tagged release" / "not a supported install target").
    No R/src/tests change.
    
    Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>

commit a5f5d40fa05f72f0c116e035b0124d338ca9b9e8
Author: Shinichi Nakagawa <itchyshin@gmail.com>
Date:   Sun Jul 19 09:14:43 2026 -0600

    chore: keep future coverage S0 out of AGHQ PR

commit d64882bffbafce91e083befca8878d253b50d535
Author: Shinichi Nakagawa <itchyshin@gmail.com>
Date:   Fri Jul 3 14:00:49 2026 -0600

    Shorten T124 artifact paths for Windows checkout

commit dc669bd072bff0507964f13acea46456254cc723
Author: Shinichi Nakagawa <itchyshin@gmail.com>
Date:   Tue Jun 9 19:07:05 2026 -0600

    Add skew-normal fixed-effect first slice (#514)

commit db20e1db69a9c0721883a2cfaea09216520612f6
Author: Shinichi Nakagawa <itchyshin@gmail.com>
Date:   Thu May 21 07:18:46 2026 -0600

    Add structured one-slope parity slices
    
    Merged after R-CMD-check passed on macOS, Ubuntu, and Windows. Local validation also included devtools::document(), focused tests, pkgdown::check_pkgdown(), a stale-status scan, full devtools::test(), and git diff --check.

commit 886a456ea9a28954798059fd15c110087aa6ade2
Author: Shinichi Nakagawa <itchyshin@gmail.com>
Date:   Mon May 18 16:35:28 2026 -0600

    Add convergence and figure gallery guides (#211)

commit 22a6d10499bbd427cd136b9311cf0499f11fd5d7
Author: Shinichi Nakagawa <itchyshin@gmail.com>
Date:   Mon May 18 15:30:40 2026 -0600

    Remove stale sim gitkeep files for files a merge re-adds).

### 2026-09-05 15:04 MDT — Totoro full-suite delta: #1186 and #1187 add ZERO failures vs clean main
- FULL-SUITE EVIDENCE (Totoro, R 4.5.3, 8 workers, testthat max_fails Inf, 2026-09-05 ~14:20-15:05): drmTMB-1186 (cd98e5190) [FAIL 15|ERROR 1|SKIP 91|PASS 46255] 390 files 7.5 min; drmTMB-1187 (00f4ce19f) [FAIL 15|ERROR 1|SKIP 91|PASS 46293] 391 files 7.6 min; clean origin/main 802522384 on the same host: 6 failing tests. Branch-minus-main failure set = EMPTY for both (6 == 6, identical tests). The 6 are a Totoro-environment set (also present on main; CI ubuntu green): test-associate-pairs-gaussian-bernoulli.R, test-b2-q6-serial-proof-receipt-audit.R, test-check-conditioning.R (hessian_conditioning), test-function-map-cheatsheet.R, test-reader-vignette-contracts.R (manifest), test-reml-phylo-location.R (q2 REML). Logs: ~/local-scratch/parity-joint/totoro-logs/. Live Julia tests skipped by design (no bridge on Totoro).
- FOLLOW-UP CANDIDATE (not a parity item): the 6-test Totoro-environment failure set on main (Linux R 4.5.3, OpenBLAS single thread) deserves one look before 0.7.1 — two are numeric (check-conditioning, reml-phylo-location q2), four look like file/manifest dependencies. Recorded for the closure report; not dispatched now.
- DRM.jl-647/648 single-threaded reruns (suite2.log) still running; result harvested by hand when done.

### 2026-09-05 15:07 MDT — #1176 skew_normal re-merged and pushed (39feedfc0)
- wf_420c96a5-34d: registry order tweedie -> beta_binomial -> cumulative_logit -> skew_normal; pins unioned; 258 addenda kept in order; NEWS union; TSV 25 rows / gates 14 / 261 30 rows byte-identical; tests 22/5/142/18(1 skip)/24(1 skip) all 0 failed; validator 19 lines = main's. Pushed after my checks. ARM after DRM.jl #641 merges (integrate.sh itchyshin/drmTMB 1176).
- FINDING (pre-existing on main): docs/design/258-coefficient-naming-contract.md section 8 has the A4 family addenda interleaved/spliced into garbled prose (the "design-258 interleaving defect" A4-integration's after-task also flagged). No content lost (verified by the agent). -> CLEANUP LEAF after #1176 merges: rewrite section 8 as one clean addendum per family in registry order (Sonnet, docs only, no semantic change; reviewer checks every sentence survives).

### 2026-09-05 15:11 MDT — cumlogit predict leaf: PR #1195 (Rose refuted G2 as written -> renegotiated)
- Build (Sonnet): the abort was drm_julia_predict_design() rebuilding mu's design with an intercept the fitted block had dropped; fixed in that one function (17 lines); response/link match TMB to 1.0e-13 stored / 4.4e-14 newdata; 15 tests live; red control sha-verified; neighbours green. Scout showed TMB's own predict() never exposes category probabilities (only eta; probabilities via ordinal_category_probabilities()).
- Rose (Opus): REFUTED G2 as written — TMB supports type="quantile" on cumulative_logit; predict.drmTMB_julia has no quantile path for ANY family. Integrator decision: renegotiate G2 to response/link, file drmTMB#1198 (bridge-wide quantile path), NEWS + PR comment carry the boundary; pushed a5c5461e4. #1184 checklist: update the fe_cumulative_logit row's claim_boundary/next_action (predict response/link closed by #1195; quantile tracked as #1198).

### 2026-09-05 15:20 MDT — G17 #1196 built; Rose REFUTED G3 (stale 6-family pin after #1174); owner: "get these working, Opus max"
- Owner screenshot: #1193 R-CMD-check RED = tools/tests/test_capability_ledger.py C14/C17 whole-file receipt guard (R/drmTMB.R blob differs; the docs sweep edited roxygen without regenerating the receipt LAST). #1195's two "!" rows = runs cancelled by my consecutive pushes; queued rows = GitHub concurrent-job cap (6 PRs x 5 jobs). -> wf_05d7746d-b37: two Opus (max) receipt agents over #1193/#1195/#1196/#1197 and #1186/#1187/#1183/#1176 (verify-first).
- G17: PR #1196 b43897d03; 100 fence tests; positive controls byte-identical to main; phylo/relmat/animal/spatial already refused upstream (fence = bars + sd()). Rose must-fix (5 items, ledger addendum) sequenced AFTER receipt-agent-A leaves wt-a4-g17. LESSON: every leaf ledger touching R/ needs "receipt regenerated LAST" as its penultimate gate (the A4 template had it; my newer ledgers dropped it).
- 15:24: OWNER: a webpage lane is now live in DRM.jl (docs/src, docs/make.jl, Documenter.yml expected). Not rebasing my DRM.jl PRs for its main moves (strict=false); union NEWS/rosetta.md at merge time if needed; docs-rerun loop covers extra gh-pages races; final re-pin takes DRM.jl main as-is including web-lane commits. drmTMB web lane pending; my held files listed in the 15:1x reply.

### 2026-09-05 15:29 MDT — Totoro DRM.jl full suites PASS (single-threaded)
- FULL DRM.jl SUITE (Totoro, julia 1.12.6, JULIA_NUM_THREADS=1, OPENBLAS 1, Pkg.test unsharded, 2026-09-05 ~14:55-15:25): PR #647 head e0e39fd00 (build head + main merge; later pushes are a rebase merge only): 467 test-set summaries, 0 failure columns, 'Testing DRM tests passed'. First attempt with 8 threads passed every test set but died on the joint-missing tests' 'wrong thread budget' guard (Threads.nthreads()==1 && BLAS 1 required) -> harness setting, not code. Log: ~/local-scratch/parity-joint/totoro-logs/DRM.jl-647-suite2.log.
- FULL DRM.jl SUITE (Totoro, same setup): PR #648 head 3d11bf9b0 (build head; ae8a0246e adds only a test comment; later push is a rebase merge): 463 test-set summaries, 0 failure columns, 'Testing DRM tests passed'. Log: DRM.jl-648-suite2.log.

### 2026-09-05 15:37 MDT — REML gaps DONE: both NOT refuted; DRM.jl #652/#653 armed
- phylo-mean: DRM.jl #653 + drmTMB #1199 (logLik 6.6e-10; SE convention difference documented as must-fix). biv-residual: DRM.jl #652 + drmTMB #1197 (logLik diff 0.0). OWNS extensions ratified (261 generator; two pinned-refusal test files). Must-fix (docs/ledger/receipt) -> Sonnet pass AFTER receipt-agent-A leaves wt-reml-biv-residual; #1199 also needs the receipt regenerated LAST. DRM.jl halves need no code change -> integrate.sh armed #652/#653 (strict=false: merge on own green).
- stash@{0} in the shared DRM.jl repo = biv leaf's superseded control-plant (7202623e4); drop after #652 merges. Both builders' incident reports differ in detail; the integrator's repair at ~15:0x used the correct entry (phylo-mean's redctrl-b) and Fisher confirmed the phylo-mean diff is exactly its 5 declared DRM.jl files.
- LESSON (vault): (a) git stash is repo-global across worktrees; (b) gate-check --reverify --approve OVERWRITES hand-written EVIDENCE lines; (c) a bare EXPECT is a literal, wrap regexes in /.../; (d) run drmTMB neighbours with NOT_CRAN=true or skips masquerade as passes.

### 2026-09-05 15:38 MDT — receipt agents DONE (wf_05d7746d-b37): diagnosis CORRECTED
- The CI guard is the C17/C14 model-15 compatibility receipt (tools/capability_ledger.py C17_C14_SOURCE_FILES = R/drmTMB.R, R/methods.R, src/drmTMB.cpp, tests/testthat/test-zero-one-beta.R, tools/run-lane-c-c17c1-c14-model15-compatibility.R), re-certified by tools/recertify-c17.py (drift guard). It does NOT pin every R/*.R and carries no drmjl_ref. The Julia phylo-labels receipt (run-julia-phylo-labels-public.R) is separate and not in any workflow (A1 #1163 adds the staleness job). CI step: R-CMD-check.yaml "Validate generated capability ledger" (Linux shards).
- #1193: R/drmTMB.R roxygen-only edit -> recertified (3 cells bit-identical at tolerance 0.0), pushed 8c5828a23. #1195/#1196/#1197 and agent B's #1186/#1187/#1183/#1176: no pinned file touched, nothing pushed.
- CONSEQUENCE: only leaves editing one of the five pinned files need recertify-c17 LAST: biv-animal REML (R/drmTMB.R drm_validate_reml_spec_biv) WILL; #1184's final re-merge (R/julia-bridge.R only) will not. Earlier ledger notes saying "whole-file receipt over every R/*.R" are superseded by this entry.
- 15:48: biv-animal REML DONE: PR #1200 d0675d7a1, Fisher not refuted (animal(A) == relmat(K) mathematics; DRM.jl REML 5.8e-10). Must-fix (regexes, receipt doubles, 211 sentence, recertify-c17 LAST) -> Sonnet. Merges after #1184.

### 2026-09-05 15:56 MDT — must-fix passes PUSHED (wf_aec8d443-e21)
- #1196 G17 @ b4d7b8b19: merged main 58fa2374d; cohort derived from the registry via new drm_julia_fe_only_fence_families() (7 families incl. cumulative_logit); gate-row family_type live; message_pattern wrap-safe (TRUE at width Inf and 80 for all 7; old pattern FALSE for 4/7); fence tests 182/0/1; EXPECTs re-measured; CI ledger step green locally. The ledger's phylo-labels receipt item was based on my superseded diagnosis (that receipt is not in CI; the final re-pin regenerates it) — not a gap.
- #1197 @ 21fbe76bd: rho12 guard convention recorded (natural-rho agreement 3.95e-12; gap 4.950025e-04 at rho = 0.999; drmTMB#1190) in receipt, 261 row, NEWS, ledger. #1199 @ 76e8170ba: G6 hashes re-quoted against shipped heads; G3 re-worded to the defended bar (oracle rtol ~5e-7; cross-engine 2.5e-3); SE-convention statement in NEWS/261/receipt; issue drmTMB#1201 (REML mean-block Wald SEs differ by construction). CI ledger step green on both.
- #1193 checklist addition: at its rewrite (after #1196/#1183/#1187) add one sentence on the REML SE convention (#1201) to vignettes/julia-engine.Rmd.

### 2026-09-05 16:00 MDT — DRM.jl "Julia 1 - shard 4/4" HUNG on #640/#641/#642 (66-78 min vs 34 min normal on #648); no job timeout in CI.yml (default 360 min)
- Cancelled the three runs and re-ran their failed/cancelled jobs (33990381998, 33990386582, 33990394754). The owner's other branch ci/loop-prose-allowlist shows the same shard in progress since 20:32 — not touched (not my lane). Shard 4 (positional) holds the bootstrap/thread tests (test_lss_bootstrap_contract, test_bootstrap_marginal, test_locscale_bootstrap_refit), test_bridge*, test_parity_harness, test_optimizer_robustness, test_variational* — the #633/#651 race class is a candidate. Totoro reproduction of shard 4/4 on Julia 1.12 for the a6 branch dispatched (Sonnet) to name the hanging file if deterministic.

### 2026-09-05 16:01 MDT — #1183 (A8) MERGED 21:59Z; #1200 must-fix pushed (ddc449c18, C17 recertified)
- Order now: #1176 (skew) waits for DRM.jl #641 (shard re-run) -> then #1184 final re-merge + gate. To shorten the tail, #1184's hard merge (A8 rewrote the comparison function on main) is done NOW as a pre-merge (Sonnet); the tiny registry/258/NEWS union after #1176 follows. #1187 (A8b) re-merge waits until #1184 merges (both edit the comparison function); #1186 (A8c) likely auto-merges.
- 16:02: #1184 pre-merge over main 2e9a358a6 dispatched (wf_555f426e-87e, Sonnet; push, no gate). #1186 re-merged (NEWS union) and pushed so CI runs; its gate waits for #1184. #1187 re-merge deferred until #1184 merges (shared comparison-function conflict).
- 16:04: my 15:5x 'rerun --failed' calls did NOT take (runs were still queued on ci-ok); #640 re-run by hand now; drmjl-shard-watch.sh started (cancel >70 min shards; rerun cancelled/failed shards, max 2 per run) — covers #641/#642 once their runs settle and #648's 1.10 shard 4/4 (51 min so far).
- 16:09: OWNER: 'keep going, do not wait for merging'. Fan-out on branches now (re-merge again later): #1187 re-merge; #1185 re-merge + native rows + join 48/5 + matrix regen; #1193 fence/supported/SE paragraphs + merge main; #1175 re-merge; NEW leaf design-258 section-8 cleanup (wt-258-cleanup off #1176 head 39feedfc0). Also running: Totoro shard-4 repro + closure drafts (wf_24308d83-b2c), #1184 pre-merge (wf_555f426e-87e).
- 16:22: OWNER: 'Opus Max for now' + 'do both DRM.jl and drmTMB'. DRM.jl front opened with three Opus-max leaves: leaf-jl-profile-finite (#651 non-finite endpoints, non-sparse LSS; also the shard-4 hang suspect), leaf-jl-q2-spatial (census: DRM.jl-native refuses what TMB and the bridge fit), leaf-jl-q2-vcov (all-NaN SEs on the q2 structured route). Worktrees wt-jl-* off DRM.jl origin/main. Attribution switches to Claude Opus 5 from here.

### 2026-09-05 16:27 MDT — #1184 pre-merged over main 2e9a358a6 and PUSHED (f9022fbaf)
- Comparison function resolved by loading BOTH sides' function definitions in R and diffing per capability_id (not by splicing conflict markers) -> 30 rows: main's 24 + fe_beta_binomial + this branch's 5, with fe_cumulative_logit/fe_skew_normal/fe_tweedie/fe_zero_one_beta/fe_truncated_nbinom2 promoted experimental -> partial; A8's two "supported" rows carried unchanged. Gates 14; 261 30 rows; counts 30/30 and 14/14; validator 0 NEW; tests 148/22/5/18(1 skip) + branch-added files green (test-julia-registry-vs-comparison.R needed the two new map entries — fixed by the agent). CI ledger step green.
- NOTE for the 258-cleanup leaf (wt-258-cleanup, cut from #1176 head): #1184 now adds HEAD's reassembly note + two reassembled sections on top of main's 367-line section 8 -> the cleanup PR must re-merge after #1184 and reconcile with those; its mechanical proof must run against the POST-#1184 file.
- Gate order unchanged: #1176 (waits DRM.jl #641) -> #1184 (one small union then arm) -> #1185/#1186/#1187 -> the leaf PRs.
- 16:31: #648's 'Julia 1.10 - shard 4/4' hit 77 min (its Julia-1 twin passed in 34) -> cancelled + rerun by hand; the watcher's 70-min rule had not fired yet on that run. #640/#641/#642 reruns are 6-15 min in and healthy. DRM.jl main moved to b4db190e7 (web lane).
- 16:31: #1176 is fully green (0 pending, 0 failed) and waits ONLY on DRM.jl #641 -> arm-1176-after-641.sh started: polls #641 every 2 min and runs integrate.sh on drmTMB 1176 the moment it merges. Deliberately not armed now: merging the R-side skew_normal claim before the engine half would put a capability on main that DRM.jl main cannot fit.

### 2026-09-05 16:40 MDT — five-branch fanout all PUSHED (wf_9f6688ff-229)
- #1187 f7b8f8b8c: comparison function = main's two "supported" rows + biv_gaussian_residual "supported" (fence sentence removed from that row only); gate test now names all three explicitly and pins gaussian_response_mask "partial"; pilot keeps both --g3-qualify and --g3-qualify-biv; TSVs/gates/261 regenerated; validator 0 new; CI ledger green. FINDING: its live test FAILS against the pin clone drmjl-430ef64cc (that pin predates DRM.jl #647) and PASSES against wt-a8b-drmjl -> #1187 must merge after DRM.jl #647, and the FINAL RE-PIN must move the pin to a DRM.jl main containing #647/#648/#652/#653 before any receipt is re-run.
- #1185 1cde89fa8: merged main; added the two natively-implemented rows (Tweedie random intercept, Gaussian phylo intercept+slope two SDs) with file:line citations; join section re-measured against DRM.jl pin d3efbad2f. WATCH: it reports 3 PRE-EXISTING test-parity-matrix.R failures (bridge-route TSV gaps for beta_binomial/truncated_nbinom2/zero_one_beta/tweedie) — those rows land with #1184, so after #1184 merges, #1185 must re-merge, regenerate the matrix and the failures must disappear. If they do not, that is a real defect in the generator's expectations, not a merge artefact.
- #1193 2d5aa6e39: fence paragraph rewritten to describe #1196 (lands first), supported rows + bootstrap caveat in prose, REML SE convention sentence citing #1201; vignette renders; man/ regenerated.
- #1175 32316d66c: clean auto-merge, no conflicts; gate opens when DRM.jl #640 merges.
- NEW PR #1202 (aea76c5f4): design-258 section 8 rewritten as one addendum per family in registry order, with a mechanical proof (410 non-blank lines old and new, sorted-multiset diff EMPTY; sections 1-7 byte-identical). It was cut from #1176's head, so it re-merges after #1184 (which appends more section-8 content) and re-runs the proof before its gate.
- 16:43: #1196 RED root cause = tests/testthat/helper-fe-only-fence-probe.R calling devtools::load_all() -> R CMD check 'unstated dependencies in tests' WARNING -> all 4 shards red (tests were FAIL 0). Fixed by moving it to tools/fe-only-fence-probe.R (in .Rbuildignore; precedent: other tools/*.R use devtools::); ledger paths updated; fence suite 182/0/1 after the move. LESSON: never put a probe/runner under tests/testthat/.
- 16:46: shard-watch had a UTC-vs-local date bug (elapsed came out negative, so the 70-min cancel rule never fired) -> rewritten to compute elapsed in python3, restarted. Cancelled the two clearly hung runs by hand (#652 82 min, #647 74 min); the watcher reruns them when they settle. #648 is down to ci-ok only.

### 2026-09-05 16:58 MDT — the DRM.jl shard-4 stall is VERSION-SPECIFIC, not branch-specific
- Measured across all seven open parity branches at 16:56: "Julia 1.10 - shard 4/4" SETTLED SUCCESS on every one of them; the long/hanging job is always "Julia 1 - shard 4/4" (the matrix's version: '1' leg, i.e. latest = 1.12.x on the runners). Durations on the 1 leg today: 34 min (a8c, PASSED), then 41, 41, 32 min in progress, and earlier 66, 73, 74, 77, 78, 82 min before cancellation.
- So it is not a branch's diff and not shard membership: the same file set passes on 1.10 and stalls on 1.12. Candidates: a Julia 1.12 compile-time/GC regression on this suite, or a latent non-termination (the #651 profile-endpoint class) that only manifests under 1.12's scheduling. The #651 Opus leaf and the Totoro shard-4 reproduction (single-threaded, Julia 1.12) are both live and will discriminate; the repro runs the SAME version, so if it terminates there the runner environment is implicated instead.
- Operationally: the watchdog's 70-minute rule is doing its job (cancel 33992768855 at 73 min 16:53, rerun 16:57). Not filing an issue yet — one issue with the full discrimination is worth more than a hunch, and #651 already holds the related flake.
- Chain state 16:56: every PR is one job from green; #653 shows failed=ci-ok only because its shards were cancelled under it, and its rerun is in flight.
- 17:00: OWNER: 'do as much as we can'. Four more leaves scaffolded: biv-q2-reml-bridge (drmTMB, the bridge refuses q2 structured REML for every provider while both native engines fit it), quantile-bridge (drmTMB#1198, off #1195's head), jl-609-gtol (DRM.jl #609 outstanding item), plus a diagnosis of the six Totoro-environment test failures on clean main. NOTE: three PRs (#1197, #1199, and the new biv-q2 leaf) all edit drm_julia_reml_supported() -> union re-merge expected.

### 2026-09-05 17:05 MDT — shard-4 stall DISCRIMINATED: hosted-runner contention, not a code hang
- Totoro reproduction (same Julia 1.12, single-threaded, DRM_TEST_SHARD=4/4, 40-min timeout) on the exact three branch shas whose CI job ran 66-78 min: a6 (7bea278) PASS in ~19 min incl. clone; skew_normal (60f09f9) PASS ~13 min; a9b (805a0dd) PASS ~13 min. Exit code 0 on all three. Logs in totoro-logs/DRM.jl-shard4-*.log.
- So the suite terminates well inside the budget on the same version, and the "Julia 1 vs 1.10" asymmetry seen on GitHub is not reproduced off it. Conclusion: the stall is GitHub-hosted-runner behaviour (contention / resource limits / cache), not non-termination in DRM.jl. Consequence: cancel-and-rerun IS the right remediation (the watchdog), and no DRM.jl code change is owed for it. NOT the same thing as #651 (a genuine intermittent non-finite endpoint on the same route) — that stays open on its own evidence.
- Caveat recorded by the reproducing agent: one trial per branch on an idle 384-core host does not exclude a rare intermittent hang that only a constrained runner triggers.
- Pre-flight audit (14 branches): 13 fully clean on all five checks; the only fix was a leftover uncommitted comment edit in #1196's probe header (committed b02c03927; fence suite 182/0/1). No branch touches a C17-pinned file; no stale generated artefact anywhere; no conflict markers; no undeclared test-time imports. It also flagged that #1196 now reports CONFLICTING against main.
- Closure drafts written and validated: after-task-drmTMB.DRAFT.md and after-task-DRMjl.DRAFT.md both PASS check-after-task.R (12 required sections); handover.DRAFT.md and the plan-vs-actual draft updated. The finaliser must re-poll gh before executing the handover's next steps (the drafts are dated to the 16:02 snapshot).
- 17:01: #1196 was CONFLICTING on NEWS.md only -> re-merged with the union and pushed. #1185 head 1607cb915 ('make test-parity-matrix.R honest about its two live gaps'), CI running. Vault committed 1fd7826 (8 lessons, D-231..D-234, 5 what-works entries).

### 2026-09-05 17:07 MDT — DRM.jl CI sequenced into waves (acting on the contention finding)
- Eight drmTMB PRs are now fully green (#1175 #1176 #1184 #1186 #1193 #1195 #1197 #1199) and EVERY one is gated on a DRM.jl merge, so the DRM.jl queue is the whole critical path. With 7 PRs x 8 matrix jobs the queue starves itself, which is exactly the contention the Totoro reproduction implicated. Wave 1 = #641 (unblocks #1176 -> #1184 -> most of the chain), #648 (#1186), #640 (#1175); cancelled the in-flight runs on #642/#647/#652/#653 to free capacity. drmjl-wave2.sh re-triggers those four once two of the three priority PRs have merged.
- Still red and needing diagnosis: drmTMB #1200 (one shard) and #1163 (all four shards; A1 is the CI-trust PR whose staleness script exits 1 by design, so its red may or may not be the intended one) -> dispatched.
- 17:08: scoped drmjl-shard-watch.sh to the three wave-1 branches only (it would otherwise have re-run the four runs I cancelled seconds earlier and undone the sequencing).
- 17:16: DRM.jl #648 MERGED 23:15Z (wave-1 first). Its drmTMB half #1186 (A8c response-mask: is_converged and the 99/99 bootstrap failure) was green and is now unblocked -> gate armed. #1184 will need one small re-merge over it; that is cheaper than holding #1186. Wave-2 trigger needs 2 of 3 priority merges; #641 (47 min) and #640 (56 min) still running.

### 2026-09-05 17:17 MDT — A8c COMPLETE on both repos
- DRM.jl #648 merged 23:15Z, drmTMB #1186 merged 23:16Z (gate verified all five checks settled green). The gaussian_response_mask route's two defects are now fixed on both mains: is_converged reporting false on a converged masked fit (the NaN-carrying degeneracy bar) and every bootstrap replicate failing on a 60-vs-54 draw-length mismatch. drmTMB main and DRM.jl main both moved (109b6421c on DRM.jl).
- Neither repo requires up-to-date branches, so the green PRs behind the new main do NOT need rebasing; only genuine textual conflicts matter, and the table above records which PRs GitHub now considers conflicting.
- 17:18: OWNER-RELAYED FINDING (from the q2-vcov leaf, out of its OWNS): check_drm() THROWS on AD-hostile routes (TypeError from CHOLMOD on a ForwardDiff.Dual) instead of reporting, violating its own 'a diagnostic must REPORT trouble, not crash on it' comment. Leaf leaf-jl-checkdrm-adsafe scaffolded (G0-G8) with a mandatory Rose sweep over every non-dual-safe route, and an explicit gate that an uncomputable gradient must not look like a passing one.
- 17:25: DRM.jl #640 MERGED 23:23Z (2 of 3 wave-1 priorities in). Armed drmTMB #1175 (A6 formula constructs). Wave-2 trigger condition met -> the four cancelled PRs get their CI re-triggered by drmjl-wave2.sh.
- 17:26: drmTMB #1175 MERGED 23:24Z. Wave 2 fired (#653 re-triggered by the watcher; #642/#647/#652 re-triggered by hand — the watcher logs only successful reruns and exits after one pass). Armed #1195 (cumlogit predict): green and independent; its soft 'after #1184' ordering was only so #1184 could cite it, which still works in either order.
- 17:28: #1195 MERGED 23:26Z. Armed the two independent docs PRs #1192 (bivariate cells census) and #1194 (Julia-ahead census); #1191 left as the owner's DRAFT decision.
- 17:29: #1194 MERGED; #1192 hit 'Base branch was modified' (the two simultaneous merges raced) -> retried.
- 17:31: #641 showed DIRTY after main moved; the merge was actually CLEAN (no conflicted files) -> merged main in and pushed 2db17711d, which also restarts its CI on a current base. Ten drmTMB PRs now report 0 pending / 0 failed, including #1200 and #1196 (their diagnosis agents' fixes landed); #1163 is re-running.

### 2026-09-05 17:33 MDT — final re-pin runner DONE and dry-run end to end (wf_0faff3be-347)
- LOOP/final-repin.sh + LOOP/repin-sweep-runner.R implement all eight protocol steps and were dry-run against the CURRENT pin. The dry run is itself a parity receipt: the full live engine-backed sweep ran 46 test-julia-*.R files in one warm R session and reported TOTAL pass=1758 fail=0 err=0 skip=0 (A0's sweep was 37 files; main has grown). Receipt regenerated to public-003.json and verified with --current --self-test: all 12 mutations printed SELFTEST_REJECTED. Precompile 6 s on a warm cache.
- ALL FOUR REFUSALS PROVED FIRING: an unmerged branch head is refused as "NOT an ancestor of DRM.jl origin/main"; a nonexistent sha is refused; a doctored Project.toml prints the FINDING and resolves fresh instead of silently reusing the Manifest; and, decisively, a sweep run with DRM_JL_PATH unset detects the engine-not-available SKIP BY MESSAGE TEXT and fails (ENGINE_SKIP_DETECTED / SWEEP_FAIL, exit 1) rather than reporting a green run that never touched Julia.
- Two errors the agent caught on itself: the drmTMB-worktree dirty check counted untracked files, so a second invocation would have refused because step 6 legitimately leaves a new receipt (fixed to --untracked-files=no, both directions verified); and the dry run overwrote the shared source-pins.json, which it restored byte-identically from the script's own backup. I have now added a --dry-run flag so a future validation cannot mutate that file at all.
- CONSEQUENCE FOR CLOSURE: the re-pin is one command once the last DRM.jl PR merges. Note the sweep took ~19 min under heavy contention from the sibling lanes; budget accordingly.
- 17:40: verified #1185's matrix test is safe in BOTH directions before merging (skips only while exactly the four known-pending families lack rows; passes once #1184 lands; still FAILS for any other newly-admitted family without a row, so the red control survives) -> merged. #1193 held until #1196 lands, since its prose describes the fence as already present.

### 2026-09-05 17:47 MDT — the two reds diagnosed (wf_0954fcd4-7c5)
- #1200: a REAL failure and exactly the class Fisher's must-fix anticipated. Widening drm_validate_reml_spec_biv()'s refusal message ("...spatial or supplied-`K` relmat q2..." -> "...spatial, supplied-`K` relmat, or supplied-`A` animal q2...") broke three expect_error() regexes in an UNRELATED file, tests/testthat/test-reml-bivariate-spatial-q2.R:389/402/415, which asserted on the old connector. Fixed by matching a substring still unique to that rejection path ("exact fixed-covariance spatial") rather than loosening to something that matches everything. Reproduced byte-for-byte before, full pass after. No production code touched, so no C17 re-certification.
- #1163: the red was CORRECT — tools/ci-receipt-staleness.sh genuinely detected a stale lss-tip-identity receipt (3 R/ file hashes changed, 4 new R/ files unrecorded). The agent regenerated it against the pinned clone (PHYLO_LABEL_PUBLIC_PASS, 33.8 s; checker --current --self-test PASS; the CI script itself then printed FRESH, 53/53 recorded files match, exit 0). BUT the next run went red again for a NEW reason, and this is the structural finding: the pull_request trigger checks out the MERGE-PREVIEW commit (branch + current main), so every time main gains an R/ file the receipt is stale again — and main took three more R/-touching PRs in the interim. CONSEQUENCE FOR CLOSURE: #1163 cannot be made durably green while main churns; its procedure is merge main -> regenerate the receipt -> push -> merge IMMEDIATELY, as the last PR, when main is quiet. That is already its documented position in the order; this makes the reason explicit.
- Brief-writing correction for future agents: my standing "never merge" means never merge a PULL REQUEST; merging origin/main INTO a branch is routine and expected. That agent read it as forbidding both and left the branch behind main. Every re-merge brief must say so explicitly.
- Also flagged, unexplained: GitHub did not auto-fire a pull_request run for #1200's pushed head for ~25 minutes while other branches got runs normally; the agent worked around it with a manual workflow dispatch, and my later merge of main into that branch re-triggered it properly.

### 2026-09-05 18:03 MDT — fence merged; dirty-branch sweep complete
- #1196 (G17 fixed-effect-only scope fence) MERGED, which makes #1193's prose true, so #1193 followed. The fence now refuses ordinary random-effect terms and sd() submodels before Julia for every fe-only admitted family (7 families, derived from the registry at generation time), while phylo/relmat/animal/spatial on those families keep their pre-existing upstream refusals.
- wf_0d7c5f9c-9df resolved all eight DIRTY branches with verification, not just mechanically: #1176 de2106f51, #1184 315df5dc1 (comparison function verified by CALLING it: 30 rows, all ten columns length 30, no duplicate ids, main's fe_beta_binomial and the branch's five new rows both present, and main's separate location_scale_scale promotion preserved), #1187 a087a715b (wave-1 guard cross-checked against the live function: three rows "supported", gaussian_response_mask "partial"), #1202 0aa8ef852 (258 proof re-run: 410 old and 410 new non-blank lines, the only five "missing" being the garbled duplicate heading numbers the cleanup exists to fix), and DRM.jl #642 718e53e8a, #647, #652, #653.
- Two honest disclosures from that agent worth keeping: it forgot `git add` after resolving NEWS on two branches and caught it before committing; and it did NOT verify that validate-mission-control.py's warnings on #1184 are pre-existing rather than merge-introduced, flagging it as an assumption instead of asserting it. I will confirm that at #1184's gate.

## 2026-09-06 00:35 — GitHub Actions health sweep (owner asked: "make sure they are all fine")

MEASURED across both repos. Four findings, three of them acted on.

1. **drmTMB main's pkgdown site was BROKEN.** `pkgdown::build_site()` aborted in
   `build_reference_index()` -- fatal, not a warning -- because `_pkgdown.yml` was missing
   the two topics merged today (#1116 chibar_pvalue/lrt_boundary, #1118 the three
   coevolution accessors). Zero reference pages and zero article pages written. `R CMD check`
   never reads `_pkgdown.yml` and pkgdown is not in Suggests, so nothing looked.
   FIXED + GUARDED in PR #1206, with a red control and an alias-keyed regression test.

2. **Two drmTMB PRs had ZERO checks and read as "not red".** #1203 and #1204 were
   `mergeStateStatus = DIRTY`; GitHub does not run a `pull_request` workflow on a conflicted
   PR because there is no merge-preview commit to run against. An empty rollup is PENDING,
   never green -- the gate script already keys on `n >= 1`, but a human scanning the PR list
   would have seen nothing wrong. Same trap on DRM.jl #659, where GitHub reported DIRTY while
   `git merge-tree --write-tree` merged CLEAN at the identical base (518f489e8) -- a stale
   mergeability cache that `gh pr update-branch` refused to clear; a real pushed merge commit
   cleared it. All three unblocked; CI now running on each.

3. **#1176's CI failure was a guard working, and an off-by-one.** `test-parity-matrix.R:138`
   -- "every route the bridge admits has a TSV row" -- fired because #1176 adds the
   skew_normal registry row. The test's own comment names FIVE routes pending #1184 including
   `fe_skew_normal`, but its `pending_1184` vector listed only four. Verified #1184 really
   carries the row (36 hits in its diff) rather than assuming. Fixed on the branch with a red
   control showing the guard still fires when skew_normal is removed again.

4. **The cancelled `main` runs are GitHub's documented behaviour, not a misconfiguration.**
   drmTMB's `cancel-in-progress: ${{ github.event_name == 'pull_request' }}` is correct and
   present at every cancelled run's sha. What cancels them is the separate rule that a NEW
   pending run supersedes an ALREADY-PENDING one in the same concurrency group, regardless of
   `cancel-in-progress`. Confirmed by evidence: every cancelled main run has ZERO jobs, i.e.
   it never started. CONSEQUENCE worth stating in the closure: with back-to-back merges,
   main's evidence is per-final-state, not per-commit.
   DRM.jl main has no CI runs at all -- that is deliberate (`on: pull_request` +
   `workflow_dispatch`, "cost-disciplined ... Linux only"), not a gap.

Only genuinely red PR across both repos: drmTMB #1163, the known receipt-staleness structure
(`ci-receipt-staleness.sh` runs against the merge-preview commit, so main churn re-stales it:
`R/julia-bridge.R`, `R/julia-family-registry.R` differ; `R/julia-family-cumulative_logit.R`
added since). Confirms it must merge LAST, immediately after regeneration. DRM.jl #573 is red
but is a dormant codex PR, not this lane's.

CI contention managed: 10 concurrent DRM.jl PRs saturated the runner pool (5 runs QUEUED).
Cancelled the queued runs on the three non-critical PRs (#655, #657, #658) to free shards for
the critical path (#641 -> drmTMB #1176; #647/#652/#653 -> #1187/#1197/#1199), with
`drmjl-wave3.sh` armed to re-trigger them once >=3 of the critical five have merged.

## 2026-09-05 19:35 — session limit, and what it cost

At 19:05 all 19 build agents across three waves died with "You've hit your session limit
· resets 7:10pm". Not partway -- they never started. Zero output from a full fan-out.
Two things to carry forward:

- STAGGER. 19 Opus-max agents at once is not throughput, it is a self-inflicted outage.
  Relaunched at effort 'high' in two groups (10 + 2), with the five heaviest held back.
- A KILLED AGENT CAN LEAVE A RED CONTROL UNRESTORED. wt-reader-contracts held a PLANTED
  private-slot violation in a shipped vignette (vignettes/articles/model-workflow.Rmd),
  uncommitted, when its agent was killed mid-control. Restored from HEAD before pushing.
  Check `git status` in any killed agent's worktree before trusting its branch.

Landed by hand while the limit blocked agents (both re-measured from scratch, both
red-controlled, neither taken on the dead agents' word):
  #1207 reader contracts -- the linter now polices vignettes/articles again. The finding
        worth keeping: baseline is 0 problems, so during the 18 days it was blind it did
        not miss a real violation. Luck, not design; discovery now lives in one shared
        function so the two corpora cannot drift apart again.
  #1208 cheatsheet -- the nine exports the printable PDFs never mentioned. The PDFs
        themselves remain stale; that is stated in the PR, not glossed.

Merged since: #1206 (pkgdown, main's docs site builds again) and #1200 (biv-animal REML).

The integrator now DISCOVERS open claude/parity-* PRs each pass instead of following a
fixed list, so tonight's leaves merge as they land without editing the script.

## 2026-09-05 19:50 — DRM.jl #651 is now failing other people's PRs

DRM.jl #652 (an unrelated REML change gating drmTMB #1197) went RED on 'Julia 1.10 -
shard 1/4' with test_locscale_profile_threads.jl:55 and :91 --
"isfinite((only(one.ci)).lower) && isfinite((only(one.ci)).upper)", 18 passed / 2 failed.
That is #651, the non-finite profile-CI endpoint on the NON-SPARSE location-scale route,
not anything #652 did. A flaky defect that fails unrelated PRs at random is no longer a
backlog item, so its build leaf was relaunched (its scout had already completed and
replays from cache: the search at src/locscale_profile.jl:192-317 returns a signed Inf
from EIGHT sites, and BOTH failing assertions are on SERIAL results -- so this is a
missing fail-closed guard, NOT the data race #633 fixed for the sparse route).

Runner contention managed decisively: cancelled CI on 5 more non-critical DRM.jl PRs
(#656 #659 #661 #662 #663) on top of the earlier three, leaving the pool to the critical
five. drmjl-retrigger.sh re-runs all eight, STAGGERED 20 s apart, once >=4 of the five
have merged -- staggered because a re-trigger that fires eight runs at once would recreate
the exact contention it is recovering from. The owner's website lane (#660) is untouched.

## 2026-09-05 19:55 — unblocking the critical chain by hand

Three red/blocked PRs on the path, each a different cause, each fixed at the source
rather than by loosening a check:

#1176 (skew_normal) — `test-julia-gate-vs-engine.R:135`, "dashboard Julia gate artifact
  matches the registry". The `fe_only_random_effects` row DERIVES its refusal list from
  the family registry (#1196's fence), so adding a family stales the generated artifact.
  Regenerated with tools/write-julia-gate-registry.R: exactly one row in each of the two
  julia-gates.tsv files, skew_normal appended. 2 files, 2 insertions, 2 deletions.

#1202 (design-258 cleanup) — failed `test-parity-matrix.R:138` for a reason that was not
  its own: it was branched off `claude/parity-a4-skew_normal`, NOT off main, so it carries
  #1176's registry row and inherited both of #1176's guard failures. Merged #1176's branch
  in (the same work, so this is consistent rather than a workaround) and left an ordering
  note on the PR. Locally green: parity-matrix 134, gate-vs-engine 144, family-registry 22,
  all failed=0.

#1184 (A4 integration) — conflicted on capability-regeneration-status.tsv, and NEITHER
  side was correct for the merged tree: this branch says 30 comparison rows / 14 gate rows,
  main says 25 / 15. The merged truth is 30 AND 15. Resolved that way and then VERIFIED by
  running the generators rather than trusting the arithmetic -- they wrote 30 and 15 and
  left the tree byte-identical.

  This also closes the one assumption I recorded as unverified at #1184's gate. A previous
  agent had honestly flagged that it had NOT checked whether validate-mission-control.py's
  warnings here were pre-existing. Measured against a clean origin/main checkout:
  19 errors on the branch, 19 on main, and `comm -23` of the two sorted error sets is
  EMPTY. Every one is pre-existing; this PR introduces none.

## 2026-09-05 20:03 — the waves landed; two more integrator bugs found and fixed

Wave 3 + ci-blindspot produced ELEVEN PRs: #1208 cheatsheet, #1209 conditioning guard,
#1210 cutpoints, #1211 docs staleness, #1212 jl-620 verification, #1213 zi_poisson,
#1214 zi_nbinom2, #1215 route diagnostics, #1216 biv_lognormal, #1217 biv_student,
#1218 profile_targets -- plus DRM.jl #661 #662 #663. All eleven have real checks; none
fell into the conflicted-PR-gets-zero-checks trap. Night wave (5 heavy leaves) deployed
once capacity freed: G3 profile, G3 bootstrap + #1188, #467/#609 factors,
engine_control_surface, closure artefacts.

TWO BUGS IN MY OWN AUTOMATION, both found by watching it rather than trusting it:

1. drmjl-shard-watch keyed its "already cancelled" guard on the RUN ID alone. `gh run
   rerun` reuses that id, so after one cancellation the watcher could never act on that
   run again -- which is exactly why DRM.jl #641 sat at 144 minutes with nobody killing
   its hung shard. Guard is now keyed on (run id, attempt).

2. overnight.sh handed every eligible PR straight to pr_merge_when_green.sh, which POLLS
   until the checks settle. Since the loop merges one PR per pass, a PR whose CI had just
   restarted parked the entire queue behind that single run while an already-green PR
   waited. It now checks the rollup first and SKIPS to the next PR unless the current one
   is settled -- with an empty rollup still counted as pending, never as green.

Neither bug lost work; both cost hours of throughput, and neither would have surfaced
from reading the scripts.
