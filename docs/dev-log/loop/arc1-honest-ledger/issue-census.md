# Arc 1 issue census (S8)

Read-only census of open GitHub issues matched by `gh issue list --repo itchyshin/drmTMB --state open --limit 200 --search "julia OR parity OR bridge OR DRModels OR DRM.jl OR engine"` (96 hits, 2026-09-24) plus the nine issues named in the S8 brief -- all nine were already inside the search results, so the combined, deduplicated candidate list is the same 96 issues. All evidence below was read against `origin/main` at `7f7293f2d` (the tip Arc 1 is based on) inside this worktree; no file here was edited or committed. Nothing was commented on, closed, or labeled on GitHub.

## Classification

- **LIKELY-DONE**: the work the issue asks for is on `origin/main`.
- **OPEN-ARC1**: genuinely open and inside Arc 1's honest-ledger scope (generator joins, ledger rows, refusal of a silently-wrong route, receipts for cited rows).
- **OPEN-ARC2**: genuinely open widening work (new routes, lifted fences, promotions, new API).
- **OUT-OF-PROGRAMME**: not parity-ledger work (listed only).

| issue | title | class | evidence | disposition |
|---|---|---|---|---|
| #3 | Add skew-normal location-scale-shape family | OUT-OF-PROGRAMME | Feature request (skew-normal LSS family), roadmap item, not bridge ledger. | keep-open |
| #4 | Advance million-row and 10k-species large-data readiness | OUT-OF-PROGRAMME | Scaling/readiness roadmap item, not bridge ledger. | keep-open |
| #5 | Implement covariance blocks for individual-difference models | OUT-OF-PROGRAMME | Feature request (covariance blocks), roadmap item, not bridge ledger. | keep-open |
| #33 | Phase 6c: remaining structured and bivariate random slopes | OUT-OF-PROGRAMME | Feature roadmap (Phase 6c structured/bivariate slopes), not bridge ledger. | keep-open |
| #59 | Phase 18: comprehensive simulation framework and reporting | OUT-OF-PROGRAMME | Infra roadmap (Phase 18 simulation framework), not bridge ledger. | keep-open |
| #60 | Phase 19: comparator-package benchmark and model-fit comparison | OUT-OF-PROGRAMME | Infra roadmap (Phase 19 comparator benchmark), not bridge ledger. | keep-open |
| #496 | Gaussian variational approximation (GVA) — declined 2026-08-03, REOPENED post-0.7 (umbrella) | OUT-OF-PROGRAMME | Native drmTMB feature design (GVA), not the engine="julia" bridge. | keep-open |
| #499 | R bridge: dispatch drmTMB(..., engine = "julia") through DRM.jl | LIKELY-DONE | Core scope landed on origin/main: `R/drmTMB.R:277` has `engine = c("tmb", "julia")`; `R/julia-bridge.R` on origin/main is 8,688 lines implementing the full `drm_bridge()` dispatch, marshalling, and reconstruction the issue asked for (commit `0972ef9d8` "Add experimental Julia engine bridge" started it; hundreds of commits since). `git grep -n 'engine = c("tmb", "julia")' origin/main -- R/drmTMB.R` hits once. Acceptance bullets (engine arg, default unchanged, skip-safe tests, round-trip fixtures) are all met by the current bridge test suite. Epic hygiene (checkbox cleanup, doc asymmetry) is the only unclosed part, tracked piecemeal by other issues (#1146, #1224, #1150, etc.), not by unmet code in #499 itself. | awaiting-G3 |
| #555 | Ayumi 10k q4 Gaussian REML speed and bridge-status harness | OUT-OF-PROGRAMME | Performance + harness roadmap item, not ledger-row/refusal-gate scope. | keep-open |
| #680 | Methods: consider small-sample t-based CI calibration (Wald-t / profile-t), coverage-gated | OUT-OF-PROGRAMME | Native method feature request (small-sample CI calibration), not bridge ledger. | keep-open |
| #686 | Methods: non-Gaussian recovery warm starts and soft penalties, scout note | OUT-OF-PROGRAMME | Native method feature request (warm starts/soft penalties), not bridge ledger. | keep-open |
| #710 | [review][low] Numerical stability guards (6 findings) | OUT-OF-PROGRAMME | General numerical-stability code review, not bridge ledger. | keep-open |
| #714 | Feasibility idea: matrix-free + Hutchinson stochastic-trace REML for very large datasets | OUT-OF-PROGRAMME | Native performance feasibility idea (Hutchinson trace REML), not bridge ledger. | keep-open |
| #932 | Gate 0 — Laplace-only bias sweep: measure the premise before any VA/EVA code | OUT-OF-PROGRAMME | Native VA/AGHQ feasibility gate (drmTMB's own integrator), not the bridge. | keep-open |
| #933 | Gate 1 — profiled outer problem: variational parameters as outer PARAMETERs hit an O(P^2) wall | OUT-OF-PROGRAMME | Native VA/AGHQ feasibility gate, not the bridge. | keep-open |
| #934 | Gate 2 — audit drmTMB's OWN AGHQ: integrator correct vs estimator established | OUT-OF-PROGRAMME | Native VA/AGHQ feasibility gate (audits drmTMB's own AGHQ), not the bridge. | keep-open |
| #935 | Gate 3 — VA-GH engine (Design 160) — gated on Gates 0-2 | OUT-OF-PROGRAMME | Native VA/AGHQ feasibility gate, gated on 932-934, not the bridge. | keep-open |
| #963 | missing-data: allow more than one mi() term per fit | OUT-OF-PROGRAMME | Feature request (multiple mi() terms), not bridge ledger. | keep-open |
| #983 | estimator: a fit reports `estimator = "ML"` but drmTMB() only accepts "ml" | OUT-OF-PROGRAMME | Native naming bug (estimator "ML" vs "ml"), not bridge ledger. | keep-open |
| #1015 | Planning: internal validation-card pilot (parked) | OUT-OF-PROGRAMME | Parked internal planning item, not bridge ledger. | keep-open |
| #1113 | Adopt per-file check-log.d shards (merge-conflict pattern from HSquared.jl) | OUT-OF-PROGRAMME | CI/process infra item (check-log.d shards), not bridge ledger. | keep-open |
| #1116 | Port boundary-aware LRT from DRM.jl: chibar_pvalue(), lrt_boundary() | LIKELY-DONE | `git show origin/main:NAMESPACE` lines 132 and 157: `export(chibar_pvalue)` and `export(lrt_boundary)`. Landed by commit `b76d46537` "feat: port DRM.jl chibar_pvalue() and lrt_boundary() (#1116) as native R". | awaiting-G3 |
| #1117 | Port model-comparison surface from DRM.jl: aicc() and the anova/lrtest/weights suite | OPEN-ARC2 | Partly landed on origin/main: `aicc()`/`aicc.drmTMB`/`aicc.default` are exported (`NAMESPACE` lines 6-7, 118) and `weights.drmTMB` exists (`R/methods.R:773), landed by commit `b21581f95` "feat(model-comparison): port DRM.jl aicc() and lrtest() (#1117), measured against native DRM.jl at pin 430ef64cc". `anova.drmTMB` (R/methods.R:2765) always calls `cli::cli_abort("{.fn anova} likelihood-ratio comparisons are not implemented for {.cls drmTMB} fits.")`, by design (T4 owner decision: fence for Arc 1, cite on parity row 89, leave wiring to Arc 2). `update.drmTMB` does not exist (`git grep -n '^update\.' origin/main -- R/` finds only `update.drm_pair_association`). Overlaps #1240 (anova LRT) and #1241 (update.drmTMB), both explicitly Arc 2 in the plan's decision map. | narrow (draft below) |
| #1118 | Port coevolution accessors from DRM.jl: coevolution_cor(), coevolution_vc(), coevolution_summary() | LIKELY-DONE | `git show origin/main:NAMESPACE` lines 133-135: `export(coevolution_cor)`, `export(coevolution_summary)`, `export(coevolution_vc)`. Landed by commit `4708dfe5e` "feat(accessors): port DRM.jl coevolution_cor/vc/summary (#1118), measured against native DRM.jl at pin 430ef64cc". | awaiting-G3 |
| #1129 | imputed(): Gaussian mi() conditional modes off by 1e-4 to 1e-3 (inner Newton not tight at final theta) | OUT-OF-PROGRAMME | Numerical convergence bug in the native `mi()` inner-Newton mode (R/missing-data.R), not the engine="julia" bridge; the issue itself says "Fenced out of the overnight true-parity lane (D-208 scope); not a parity claim change." `git grep -n 1129 origin/main -- R/` finds no code reference, so the proposed fix (tighter inner.control / closed-form recompute) has not landed. Not ledger/generator/refusal-gate work. | keep-open |
| #1140 | roxygen2 8.0.0 vs RoxygenNote 7.3.2: regenerating docs silently strips \code{} markup and adds two man pages | OUT-OF-PROGRAMME | Native tooling bug (roxygen2 version mismatch), not bridge ledger. | keep-open |
| #1142 | Capability parity between engines: ML everywhere, REML where possible, and no silent REML-to-ML downgrade | OPEN-ARC1 | Part of the epic is landed on origin/main: the silent-downgrade behaviour the issue's point 1 names (`drm_julia_warn_reml_unsupported()` warning then fitting ML) no longer exists under that name. `git grep -n drm_julia_refuse_reml_unsupported origin/main -- R/julia-bridge.R` shows a replacement, `drm_julia_refuse_reml_unsupported()` (R/julia-bridge.R:3175), landed by commit `666bfa487` "fix(julia): REFUSE unsupported REML instead of silently fitting ML", whose abort text reads "Refusing rather than fitting by maximum likelihood instead: ... a silent downgrade would move heritability, repeatability and ICC without saying so." Points 2-4 (which cells should support REML, whether `q4_vcov` can report a REML-consistent Hessian, the target REML surface) remain open policy questions on origin/main; no code changes those. This is exactly Arc 1's refusal-of-a-silently-wrong-route scope. | narrow (draft below) |
| #1146 | CI guard: fail when a structured marker with a non-intercept left side is routed through engine = "julia" (DRM.jl #620) | LIKELY-DONE | `git grep -n structured_marker_slope origin/main -- R/julia-bridge.R tests/` shows a registered gate `structured_marker_slope` and `tests/testthat/test-julia-marker-slope-guard.R` (on origin/main) opens "drmTMB#1146 / DRM.jl#620/#621: a structured marker ... with a NON-INTERCEPT left side" and asserts `phylo()`/`relmat()` with a non-intercept lhs is refused before `engine = "julia"`. Landed by commit `d240e3515` "feat(bridge): refuse structured-marker non-intercept slope through engine='julia' (drmTMB#1146)". | awaiting-G3 |
| #1148 | perf(julia): every fixed-effect profile/bootstrap interval cold-refits the model instead of reusing the fit | OUT-OF-PROGRAMME | Bridge performance item (cold-refit on intervals); a speed defect, not an admission/ledger-honesty gap. | keep-open |
| #1150 | CI does not run the whole-file receipt checks, so a stale receipt merges green | OPEN-ARC2 | Partly mitigated on origin/main, not closed. `.github/workflows/receipt-staleness.yaml` exists (`git show origin/main:.github/workflows/receipt-staleness.yaml`) and runs `tools/ci-receipt-staleness.sh`, added by commit `7d25a1ed3` "ci: move the receipt-staleness guard off PRs and onto main". Its trigger is `on: push: branches: [main]` plus `workflow_dispatch` only -- no `pull_request` trigger. The workflow's own header comment explains the tradeoff deliberately: checking on the PR's merge preview re-staled every open PR on each unrelated merge (measured: 16 merges/afternoon x 4 live PRs = up to 64 ~40-minute cycles), so drift is now caught within ~2 minutes of a merge to main instead of blocking the PR itself. So the issue's literal complaint ("a stale receipt merges green") is still true by design: a PR is not blocked, drift surfaces one merge later on main. Wiring PR-time receipt checks into CI is listed for Arc 2 in the plan's decision map ("GitHub Actions changes (#1150) are listed for Arc2, because wiring receipt checks into CI costs minutes and is a separate decision under the local-checks rule"). | narrow (draft below) |
| #1154 | test-julia-predict-newdata.R errors only when run after the other julia files, on main | OUT-OF-PROGRAMME | Test-ordering infra bug, not bridge ledger. | keep-open |
| #1157 | Booting Julia prints a red ERROR and a 35-line stacktrace, twice — it looks exactly like a crash | OUT-OF-PROGRAMME | Cosmetic UX issue (Julia boot error formatting), not bridge ledger. | keep-open |
| #1158 | Expose the ultrametric tolerance — and: it is NOT absolute, contrary to a natural reading | OUT-OF-PROGRAMME | Feature request (expose ultrametric tolerance), not bridge ledger. | keep-open |
| #1189 | R/check.R mislabels the optimizer message as nlminb on Julia-engine fits | OUT-OF-PROGRAMME | Diagnostic-message bug in `R/check.R` (`check_optimizer_convergence()` at line 612 still hardcodes "nlminb convergence code is 0." regardless of engine, confirmed on origin/main), not the bridge's admission/ledger surface; `R/check.R` is outside the Arc 1 destination gate's OWNS list. | keep-open |
| #1190 | rho12 guard constant differs between engines (TMB 0.999999, DRM.jl 0.99999999, bridge back-transform guard 1) | OUT-OF-PROGRAMME | Cross-engine numeric-constant consistency question (TMB rho12 guard 0.999999 throughout `src/drmTMB.cpp`, confirmed on origin/main, vs a DRM.jl-side constant this repo cannot inspect); a specific numerics finding, not a ledger row/generator/refusal-gate task. | keep-open |
| #1201 | REML Wald SEs for the mean block differ by construction between engines (sdreport-inflated vs canonical GLS) | LIKELY-DONE | The decision the issue asks for (document the REML mean-block SE convention gap per cell rather than force one engine to match the other) is implemented on origin/main: `R/julia-bridge.R:520-521` carries the full measured writeup ("SE BOUNDARY, MEASURED AND NOT SMOOTHED OVER", oracle GLS check, SE_FAIL/SE_PASS split, `q4_vcov` guidance) for exactly the cells and code sites (`drm_apply_estimator_spec()`, `src/location_only.jl`) the issue names. Landed by commit `ec59a0f10` "evidence: close three UNCITED REML capabilities with same-target bridge receipts". The underlying convention difference is deliberately not reconciled (both are defensible, per the row text), which is the documented decision, not an open defect. | awaiting-G3 |
| #1224 | The G17 fixed-effect-only fence exempts bivariate families by PREFIX, so every new biv_* admission inherits an exemption it has not earned | LIKELY-DONE | `git show origin/main:R/julia-bridge.R` line 1443: "#1224: this used to be `startsWith(row$family, \"biv_\")`. ... It is now a declared per-family property (`fe_fence_exempt` in R/julia-family-registry.R)." The prefix exemption named by the issue is gone; the fence is keyed on a declared, per-family registry column. Landed by commit `2232d409d` "feat(bridge): declare each family's predictor-dpar scope in the registry, retiring the biv_ prefix exemption". | awaiting-G3 |
| #1228 | [ecology-PhD followability] Documented pak install leaves zero vignettes; vignette("drmTMB") fails | OUT-OF-PROGRAMME | Docs/onboarding issue (vignette install), not bridge ledger. | keep-open |
| #1229 | [ecology-PhD followability] Twin first-user examples diverge from DRM.jl (ecology habitat vs abstract RNG; different n/seed/DGP) | OUT-OF-PROGRAMME | Docs issue (twin example asymmetry), not bridge ledger. | keep-open |
| #1230 | [statistician] distribution-families detailed sections say skew-normal/Tweedie REs are planned, but overview and man pages say they are fitted | OUT-OF-PROGRAMME | Docs consistency issue (family status wording), not bridge ledger. | keep-open |
| #1231 | [statistician] heritability() description places the variance-share estimand on the working (log-SD) scale | OUT-OF-PROGRAMME | Docs issue (heritability() scale description), not bridge ledger. | keep-open |
| #1232 | Docs/enhancement: no TMB OpenMP single-fit path (vs glmmTMB parallel vignette); only multicore for confint/bootstrap | OUT-OF-PROGRAMME | Docs/feature issue (OpenMP single-fit path), not bridge ledger. | keep-open |
| #1233 | Docs/capability: no glmmTMB-style OpenMP single-fit parallel path (only multicore for confint/bootstrap) | OUT-OF-PROGRAMME | Docs/feature issue (OpenMP parallel path), duplicate of #1232 in spirit, not bridge ledger. | keep-open |
| #1237 | Document when to raise vs pin TMB_NTHREADS/OMP vs parallel=\"multicore\" (user nested-parallel policy) | OUT-OF-PROGRAMME | Docs issue (thread policy documentation), not bridge ledger. | keep-open |
| #1238 | [docs-readthrough] Part 2 location-scale-scale has no DRM.jl companion link (Part 1 does) — asymmetric twin | OUT-OF-PROGRAMME | docs-readthrough: vignette companion-link asymmetry, not bridge ledger. | keep-open |
| #1239 | [docs-readthrough] confint.drmTMB_julia threads=TRUE docs omit JULIA_NUM_THREADS prerequisite (10× claim can silently no-op) | OUT-OF-PROGRAMME | docs-readthrough: threads=TRUE prerequisite documentation gap, not bridge ledger. | keep-open |
| #1240 | anova.drmTMB always aborts; drm_lrtest exists but unwired (lme4/glmmTMB UX gap) | OPEN-ARC2 | Confirmed still open and unwired on origin/main: `anova.drmTMB` (R/methods.R:2765) always aborts; `drm_lrtest()` exists (R/model-comparison.R:118) but is "deliberately NOT exported and NOT wired into anova()" per its own header comment. Explicitly named Arc 2 in the plan's decision map under ticket T4 ("keep #1240 open for Arc 2") and the destination's out-of-scope list. | arc2-list |
| #1241 | Missing update.drmTMB (lme4/glmmTMB/DRM.jl have update; only update.drm_pair_association exists) | OPEN-ARC2 | Confirmed still open on origin/main: `git grep -n '^update\.' origin/main -- R/` finds only `update.drm_pair_association` (R/associate-pairs.R:967); no `update.drmTMB`. New-API work, explicitly out of scope for Arc 1 per the plan's decision map ("lifting fences, new routes, and claim_status promotion are Arc 2"). | arc2-list |
| #1242 | [docs-readthrough] large-data vignette demos parallel="multicore" without Windows abort caveat | OUT-OF-PROGRAMME | docs-readthrough: Windows caveat missing from vignette, not bridge ledger. | keep-open |
| #1243 | [Melissa consistency] Twin tutorials lack reciprocal DRM.jl companion links (R→Julia asymmetry) | OUT-OF-PROGRAMME | docs-readthrough: twin tutorial companion-link asymmetry, not bridge ledger. | keep-open |
| #1244 | [math] LSS personality vignette: define sex-specific repeatability R_i; mirror DRM.jl #694 | OUT-OF-PROGRAMME | [math] vignette content request (repeatability formula), not bridge ledger. | keep-open |
| #1245 | [math] Document Laplace for sigma~(1\|g); twin with DRM.jl GHQ (#692) | OUT-OF-PROGRAMME | [math] native drmTMB-vs-DRM.jl twin diagnosis (Laplace vs GHQ-32), a separate research thread from the engine="julia" bridge this Arc audits; no route through the bridge is at issue here. | keep-open |
| #1246 | [docs-readthrough] Only one DRM.jl companion link in all vignettes (location-scale); twin surface is one-way | OUT-OF-PROGRAMME | docs-readthrough: companion-link asymmetry, not bridge ledger. | keep-open |
| #1249 | Document/expose BLAS/OpenMP/TMB thread policy for users (campaigns pin; installed package does not) | OUT-OF-PROGRAMME | Docs issue (BLAS/OpenMP/TMB thread policy), not bridge ledger. | keep-open |
| #1251 | check_drm hessian_conditioning NOTE on clean airquality Gaussian L-S (cond≈5e8) despite twin parity | OUT-OF-PROGRAMME | Diagnostic false-positive (hessian_conditioning NOTE), native check, not bridge ledger. | keep-open |
| #1252 | Twin: Poisson RI GLMM disagrees with DRM.jl on sd_mu / logLik beyond 1e-5 (identical CSV) | OUT-OF-PROGRAMME | Twin: native drmTMB-vs-DRM.jl numeric divergence (independent fits, not the R bridge), not bridge ledger. | keep-open |
| #1253 | Twin: Beta RI mild drmTMB vs DRM.jl divergence on sd_mu / logLik (identical CSV) | OUT-OF-PROGRAMME | Twin: native numeric divergence, not bridge ledger. | keep-open |
| #1254 | Missing fit-level parallelization / threads API (only profile/bootstrap parallel today) | OUT-OF-PROGRAMME | Feature request (fit-level parallelization API), not bridge ledger. | keep-open |
| #1255 | Twin: Binomial RI GLMM disagrees with DRM.jl on sd_mu / logLik (MASS::bacteria) | OUT-OF-PROGRAMME | Twin: native numeric divergence, not bridge ledger. | keep-open |
| #1256 | Twin: binomial RI sd_mu/logLik diverge vs DRM.jl on simulated binary + bacteria + cbind | OUT-OF-PROGRAMME | Twin: native numeric divergence, not bridge ledger. | keep-open |
| #1257 | Twin: Student RI sigma/sd_mu/nu diverge vs DRM.jl on identical CSV | OUT-OF-PROGRAMME | Twin: native numeric divergence, not bridge ledger. | keep-open |
| #1258 | Twin: nbinom2 RI sd_mu disagrees with DRM.jl (~2.5%) on identical CSV | OUT-OF-PROGRAMME | Twin: native numeric divergence, not bridge ledger. | keep-open |
| #1259 | Twin: Gamma RI mild sd_mu gap vs DRM.jl (~0.29%) on identical CSV | OUT-OF-PROGRAMME | Twin: native numeric divergence, not bridge ledger. | keep-open |
| #1260 | [math] Binomial RI twin gap is TMB Laplace vs DRM.jl GHQ-32 (not shared-Laplace parity) | OUT-OF-PROGRAMME | [math] native twin diagnosis (Laplace vs GHQ-32), not the R-Julia bridge this Arc audits. | keep-open |
| #1261 | [math] Student / nbinom2 / Gamma RI gaps are TMB Laplace vs DRM.jl GHQ-32 (same as #1260) | OUT-OF-PROGRAMME | [math] native twin diagnosis (Laplace vs GHQ-32), not the R-Julia bridge this Arc audits. | keep-open |
| #1262 | Twin: Poisson RI on HSAUR3::epilepsy disagrees with DRM.jl (real-data; links #1252 / GHQ #1245) | OUT-OF-PROGRAMME | Twin: native numeric divergence (real data), not bridge ledger. | keep-open |
| #1263 | Twin: NB2 RI on HSAUR3::epilepsy soft gap vs DRM.jl (real-data) | OUT-OF-PROGRAMME | Twin: native numeric divergence (real data), not bridge ledger. | keep-open |
| #1264 | Twin: Binomial RI on HSAUR3::schizophrenia2 soft gap vs DRM.jl (links bacteria #1255 / GHQ #1245) | OUT-OF-PROGRAMME | Twin: native numeric divergence (real data), not bridge ledger. | keep-open |
| #1265 | [math] Mirror DRM.jl #721: Student fixed loglik / ν→1e16 numerical breakdown (not RI) | OUT-OF-PROGRAMME | [math] native numerical breakdown (nu -> 1e16), not bridge ledger. | keep-open |
| #1266 | Twin track: DRM.jl Student() lacks crossed RE that drmTMB student() admits (lexdec) | OUT-OF-PROGRAMME | Twin: capability asymmetry between the two independent packages (not the R bridge), not bridge ledger. | keep-open |
| #1267 | hurdle Poisson: refuses hu on poisson() while DRM.jl accepts Poisson()+hu | OPEN-ARC1 | Still true on origin/main. `R/julia-bridge.R:505` (the hurdle_nbinom2 ledger row) states as a live follow-up: "engine = 'julia' is still MORE PERMISSIVE than native about count modifiers: nbinom2() + hu and poisson() + hu route through the bridge and are refused natively ... Fencing that needs tests/testthat/test-parity-matrix.R and tools/write-parity-matrix.R to drop their bridge_family = nbinom2 pin for this route, so it is an integrator change, not a family leaf's." The gap is disclosed in the ledger (D-233 partial-with-cited-boundary) but not fenced, so `poisson() + hu` through `engine = "julia"` today silently fits DRM.jl's NB2 hurdle kernel rather than a Poisson hurdle -- a live instance of Arc 1 destination clause 3 ("no admitted route fits a different model than the user wrote"). Belongs on the D3 sweep's radar; no comment needed since the ledger already discloses it. | keep-open |
| #1268 | near-separated binary logistic FE: coef/logLik diverge vs DRM.jl (both converge) | OUT-OF-PROGRAMME | Twin: native numeric divergence under near-separation, not bridge ledger. | keep-open |
| #1270 | [math] Twin contract: binomial FE separation — detect/warn/refuse or Firth/MSPL (don’t expect coef agree) | OUT-OF-PROGRAMME | [math] native twin contract question (separation handling), not bridge ledger. | keep-open |
| #1272 | Twin: phylo() RE SD on VCV scale vs DRM.jl correlation scale (FE/logLik agree) | OUT-OF-PROGRAMME | Twin: native scale-convention difference (already the same phenomenon documented on the gaussian_phylo_mean ledger row's NOTE, but filed as a standalone native-vs-native twin issue), not bridge ledger. | keep-open |
| #1273 | Twin: BetaBinomial crossed Laplace soft gap vs DRM.jl (sigma/logLik near boundary) | OUT-OF-PROGRAMME | Twin: native numeric divergence near boundary, not bridge ledger. | keep-open |
| #1278 | Twin track: DRM.jl LogNormal() lacks crossed RE that drmTMB lognormal() admits | OUT-OF-PROGRAMME | Twin: capability asymmetry between the two independent packages, not bridge ledger. | keep-open |
| #1279 | Twin track: DRM.jl Tweedie() lacks crossed RE that drmTMB tweedie() admits | OUT-OF-PROGRAMME | Twin: capability asymmetry between the two independent packages, not bridge ledger. | keep-open |
| #1280 | Twin track: DRM.jl CumulativeLogit() lacks crossed RE that drmTMB admits | OUT-OF-PROGRAMME | Twin: capability asymmetry between the two independent packages, not bridge ledger. | keep-open |
| #1281 | Twin track: DRM.jl ZeroOneBeta lacks tree/K drm method that drmTMB phylo/relmat admits | OUT-OF-PROGRAMME | Twin: capability asymmetry between the two independent packages, not bridge ledger. | keep-open |
| #1282 | Twin: drmTMB refuses structured beta_binomial phylo/relmat; DRM.jl admits BetaBinomial phylo | OUT-OF-PROGRAMME | Twin: capability asymmetry between the two independent packages, not bridge ledger. | keep-open |
| #1283 | Twin: binomial admits phylo but refuses relmat; DRM.jl Binomial+K fits | OUT-OF-PROGRAMME | Twin: capability asymmetry between the two independent packages, not bridge ledger. | keep-open |
| #1284 | Twin: beta() refuses relmat; DRM.jl Beta+K fits (Beta phylo already burns) | OUT-OF-PROGRAMME | Twin: capability asymmetry between the two independent packages, not bridge ledger. | keep-open |
| #1287 | Twin track: DRM.jl refuses joint mu+(1\|g) and sigma+(1\|g) that drmTMB admits | OUT-OF-PROGRAMME | Twin: native-vs-native capability gap (drmTMB admits joint mu+sigma RE, DRM.jl refuses it as two independent fits, no bridge call involved), not bridge ledger. | keep-open |
| #1289 | Twin: DRM.jl Gaussian RI+sigma~ sparse-Laplace runaway (+ll); drmTMB OK on same CSV | OUT-OF-PROGRAMME | Twin: native numeric/optimizer divergence, not bridge ledger. | keep-open |
| #1290 | Twin track: DRM.jl Gaussian RI + sigma~x Laplace runaway on some seeds (drmTMB OK) | OUT-OF-PROGRAMME | Twin: native numeric/optimizer divergence, not bridge ledger. | keep-open |
| #1301 | Repeatability on non-Gaussian scales: audit against the de Villemereuil et al. 2016 three-scale framework | OUT-OF-PROGRAMME | Methods audit request (repeatability scales), not bridge ledger. | keep-open |
| #1316 | [Dinnage audit S7] Default single start lands >= 1 AIC worse on 18.3% of joint sigma+zi fits | OUT-OF-PROGRAMME | [Dinnage audit] independent evaluation finding (multistart), not bridge ledger. | keep-open |
| #1317 | [Dinnage audit S8] REML = TRUE returns NA Wald confint() on mean coefficients with no explanation | OUT-OF-PROGRAMME | [Dinnage audit] independent evaluation finding (REML confint NA), not bridge ledger. | keep-open |
| #1328 | [Dinnage audit Md-K] Halted Julia bridge's NAMESPACE footprint needs a public-status decision | OUT-OF-PROGRAMME | A CRAN-readiness / public-API-surface decision (whether the whole Julia bridge should be exported or marked experimental/internal ahead of submission), not a per-route ledger entry; the issue's own "since-audit" note says this "remains an open decision for Shinichi, not something a static read can resolve." Out of the honest-ledger destination's scope (which is about row-level honesty, not the bridge's overall public status). | keep-open |
| #1332 | [Dinnage audit A-2] `miss_control(predictor = "fail")` does not fail, and its own help page disagrees with itself | OUT-OF-PROGRAMME | [Dinnage audit] independent evaluation finding (miss_control predictor='fail'), not bridge ledger. | keep-open |
| #1334 | [Dinnage audit A-4] `meta_V()` is positional, `relmat()` is name-keyed, and only the second says so | OUT-OF-PROGRAMME | [Dinnage audit] independent evaluation finding (API argument style inconsistency), not bridge ledger. | keep-open |
| #1337 | [Dinnage audit A-7] Nothing on the diagnostic board carries sample size; the board gets cleaner as n falls | OUT-OF-PROGRAMME | [Dinnage audit] independent evaluation finding (diagnostic board sample size), not bridge ledger. | keep-open |
| #1349 | [Dinnage audit Mi-11] `?student` claims Student-t is "the one implemented family" whose `sigma` is a scale rather than `SD[y]`; false, and contradicts `?sigma.drmTMB` | OUT-OF-PROGRAMME | [Dinnage audit] independent evaluation finding (?student doc contradiction), not bridge ledger. | keep-open |
| #1359 | [Dinnage audit UX-4] `confint(parm = "sigma:z")` accepts the compact label but returns `fixef:sigma:z`, so a name-based join silently returns `NA` | OUT-OF-PROGRAMME | [Dinnage audit] independent evaluation finding (confint() label join bug), not bridge ledger. | keep-open |
| #1387 | profile: drm_profile_trace_object() records the full par vector on every objective evaluation (HSquared.jl blow-up class) | OUT-OF-PROGRAMME | Native performance/memory issue (profile trace object), not bridge ledger. | keep-open |
| #1420 | beta→beta_family migration: bare family=beta() hits base::beta with cryptic error; NEWS overclaims drmTMB::beta() | OUT-OF-PROGRAMME | Native naming-collision bug (beta() vs base::beta), not bridge ledger. | keep-open |

## Counts

- LIKELY-DONE: 6
- OPEN-ARC1: 2
- OPEN-ARC2: 4
- OUT-OF-PROGRAMME: 84
- total: 96

## Draft comments (not posted)

Plain, short, factual. None of these have been posted. Shinichi decides closures (G3); these are drafts for that decision, not requests to act.

### #499

This looks done. `drmTMB()` has an `engine` argument, `engine = "julia"` dispatches
through the bridge, and the bridge (`R/julia-bridge.R`) now runs to 8,688 lines with its own test suite,
family registry, and refusal gates. That was the whole ask in this issue's scope and acceptance sections.

What is left is not code, it is bookkeeping: several follow-on issues (#1146, #1224, #1150, and others)
already track the smaller gaps that were found after the bridge landed. Suggest closing this epic and
letting those track the remaining hygiene, rather than keeping #499 open as an umbrella.

### #1116

Done. `chibar_pvalue()` and `lrt_boundary()` are exported in NAMESPACE, landed in
commit b76d46537.

### #1118

Done. `coevolution_cor()`, `coevolution_vc()`, and `coevolution_summary()` are
exported in NAMESPACE, landed in commit 4708dfe5e.

### #1146

Done. A structured marker (`phylo()`/`relmat()`/`animal()`/`spatial()`) with a
non-intercept left side is now refused before `engine = "julia"` is reached, with its own gate
(`structured_marker_slope`) and test file (`tests/testthat/test-julia-marker-slope-guard.R`). Landed in
commit d240e3515.

### #1201

This has been answered rather than fixed: the two engines compute the REML
mean-block SE differently on purpose (drmTMB folds variance-parameter uncertainty into the mean block via
sdreport, DRM.jl reports the canonical GLS covariance), and both are defensible. That is now written down
per cell, with the numbers, in the bridge's ledger rows (R/julia-bridge.R around line 520), landed in
commit ec59a0f10.

The decision this issue asked for is: document the difference per cell rather than force one engine to
match the other. If a global summary (NEWS/vignette) is wanted instead of per-cell notes, that would be a
small follow-up, not a reopen of the investigation.

### #1224

Done. The fence no longer keys off the `biv_` name prefix. It is now a declared
per-family property (`fe_fence_exempt` in the family registry), so a new `biv_*` family has to opt in
rather than inheriting the exemption silently. Landed in commit 2232d409d, which says so directly at the
call site.

### #1142

Partly landed. Point 1, the one flagged as most user-facing (a silent REML-to-ML
downgrade), is fixed: `engine = "julia"` now refuses REML on unsupported cells instead of warning and
fitting ML anyway (commit 666bfa487). The abort message says why: "a silent downgrade would move
heritability, repeatability and ICC without saying so."

Points 2 to 4 are still open and are policy questions, not code gaps: which cells should support REML at
all, whether the q4 bivariate phylo route can report a REML-consistent covariance instead of an ML one,
and what the target REML surface should be. Recommend keeping this issue open for those, narrowed to drop
the point-1 downgrade concern since that part is closed.

### #1117

Partly landed. `aicc()` and `weights.drmTMB()` work on bridge fits (commit
b21581f95). `anova.drmTMB()` still always aborts, but that is now a deliberate fence rather than a gap: the
owner decided (2026-09-24) to keep the no-LRT refusal for Arc 1 and treat wiring `drm_lrtest()` into
`anova()` as later work, tracked by #1240. `update.drmTMB()` still does not exist, tracked by #1241.

Recommend narrowing this issue to the two still-open parts and pointing at #1240 and #1241, since the aicc
and weights work is done.

### #1150

Partly mitigated, not closed. `.github/workflows/receipt-staleness.yaml` now runs
the stale-receipt check (commit 7d25a1ed3), but only on push to main plus manual dispatch, not on pull
requests. That was a deliberate tradeoff (checking on a PR's merge preview was re-staling every open PR on
every unrelated merge, at real CI cost), explained in the workflow file itself.

So the literal complaint here still holds: a PR that forgets to regenerate a receipt still merges green,
and the drift is only caught about two minutes later on main, as a red run there instead of a red PR check.
Wiring the check into PRs is listed as a later decision (it costs CI minutes each time), not something to
fold into this pass.


## Conductor notes (2026-09-24, after reverify)

- Spot-checked against origin/main: #1146 (gate `structured_marker_slope` at `inst/extdata/julia-gates.tsv:15`, `R/julia-bridge.R:66`) and #1224 (commit `2232d409d` retires the `biv_` prefix exemption). Both hold.
- #1267's claim that `poisson()+hu` reaches DRModels' NB2 hurdle kernel through the bridge is a lead, not yet measured here; the admission census (S2) and model-identity sweep (S3) decide it.
- Closures and comments for the six LIKELY-DONE issues wait for Shinichi (G3). Nothing was posted.
