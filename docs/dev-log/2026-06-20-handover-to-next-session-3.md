# Handover to the next Claude session (#3) — drmTMB finish-plan

You are **Ada**, continuing an autonomous, push-LIVE run to finish drmTMB (R), its
DRM.jl twin, and the R-Julia bridge — one defended evidence slice at a time. Read the
prior handovers (`2026-06-20-handover-to-next-session-2.md` and `...-to-next-session.md`)
for identity, team, boundaries, and the deep plan map; this note is the session-4
delta + entry point. Repo state is authoritative — rerun `git status`/`git log`.

## 0. Posture

- Orchestrate as **Ada**; spawn **Rose** (claim boundary) + **Fisher** (inference) to
  verify EVERY promotion, plus Curie (sims), Florence (figures), Noether (math) as needed.
- **Pushes are LIVE** (owner-authorized); keep pushing per-slice.
- Active goal (owner, time-boxed): "finish as many planned slices as possible." Reduce
  planned/partial cells with NEW measuring evidence, never status-flips; keep the
  mission-control widget honest.

## 1. Workspaces (cwd HAZARD)

- **drmTMB (R)**: `/Users/z3437171/.codex/worktrees/540b/drmTMB`, branch
  `shannon/overnight-audit-gaps-20260619`, **HEAD `c37ec439`**, tree clean, all pushed.
- **DRM.jl (Julia)**: `/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main`,
  branch `shannon/overnight-audit-verify-20260619` — untouched this session.
- **cwd HAZARD**: every Bash/subagent shell resets to the STALE primary checkout
  `/Users/z3437171/Dropbox/Github Local/drmTMB`. IGNORE it. ALWAYS pin absolute
  `540b` paths; tell spawned agents to do the same.
- Validator: `python3 tools/validate-mission-control.py` (expect `mission_control_ok`,
  25/68). Check-log newest-first: `docs/dev-log/check-log.md`.

## 2. What this session committed (10 slices, all pushed, validator green 25/68)

1. `8de1b911` Coevolution **Stage 0** recovery — `phylo_interaction()` coevolutionary SD
   recovers (rel bias -6.4%->-1.6% over species; HELD diagnostic, no granular cell).
2. `8bb9c586` Coevolution **Stage 1** verified engine implementation plan (design 178):
   decompose into 1A multi-block Gaussian-mu engine / 1B extraction / 1C activate test;
   architecture = block-diagonal precision + concatenated u_phylo; the C++ kernel loop is
   over ENDPOINTS sharing one precision, so multi-block needs real surgery (not a guard flip).
3. `be399767` **Kernel abstraction** (DRM.jl#270) synthesis into design 178: A^(h)/A^(p)
   generalize to estimated kernels; in-process DRM.jl is the scalable path; adopt GLLVM.jl#62
   for Matern-SPDE; Stage-1 bdiag architecture is kernel-forward-compatible.
4. `c06da850` **Random slopes visual -> covered** (Florence): bias/consistency recovery figure.
5. `3631c57e` **Animal + spatial** structured recovery (HELD): pedigree NRM sd -3.1%->-1.3%;
   spatial exp-kernel sd -10.9%->-2.8%.
6. `f87ec09c` **Structural dependencies adjudicated -> HELD partial (4/6)** (Rose+Fisher):
   all 4 IMPLEMENTED sub-types (animal/phylo/relmat/spatial) now have recovery; kernel+SPDE
   unimplemented, so the aggregate can't flip. **OWNER DECISION pending** (see §4).
7. `ebb8cc47` **rho12 Profile -> covered** (Fisher): 500-rep profile calibration tracks Wald.
8. `58eb3bb5` **Profile-engine speed benchmark**: endpoint engine 3-5x faster than tmbprofile
   (agree <=1.4e-5).
9. `f0fb4f7f` **feat(profile): endpoint solver now handles fixed-effect COEFFICIENT profiles**
   (R-only engine change). Every coefficient profile is now ~3-5x faster by default (auto),
   agreeing with tmbprofile to 4e-6; tmbprofile fallback intact. test-profile-targets PASS 795,
   test-biv-gaussian PASS 945. THIS UNBLOCKS feasible profile calibration for RE/non-Gaussian.
10. `c37ec439` **rho12 Bootstrap -> partial** (Fisher): parametric-bootstrap pilot (R=199,
    100 reps), feasible + approximately calibrated. **rho12 now has all three interval methods:
    Wald covered, profile covered, bootstrap partial.**

## 3. Owner steer this session: profile + bootstrap + Julia (profile is the favorite)

Delivered: rho12 all-three; the endpoint-coefficient speedup (the big one — makes profile
fast by default); benchmark; Julia in-process direction documented. **Next on this thread
(now FEASIBLE because coefficient profiles are fast):**
- **Broaden profile calibration** to the planned Profile cells: **Non-Gaussian** (fixed-effect,
  fast fits — most tractable) and **Random slopes** (RE fits slower but only 2 coefficients).
  Reuse `2026-06-20-rho12-profile-calibration/run.R` as the pattern; Fisher-gate; scope honestly.
- **Bootstrap pilots** for the same rows (planned -> partial; bounded, R=199, ~100 reps).
- **"maximized in Julia"** = an in-process direct DRM.jl profile/bootstrap loop (repeated
  re-optimization workload); NOT the callr bridge (~3-min round-trip). Julia profile is
  partially wired (`drm_julia_profile_targets`) but gated on a bridge payload + unvalidated.
  This is the honest home of the "Julia speedups" row (experimental/planned).
- A further R-side win: parallelize profiling across targets (the `parallel`/`workers` plumbing
  exists for bootstrap; profile is per-target sequential).

## 4. Owner decisions PENDING (highest-leverage first)

1. **Mint per-sub-type Structural rows** (Rose+Fisher both recommend). This converts the
   already-verified relmat/animal/spatial recovery into **3 covered POINT cells** (relmat/animal/
   spatial -> covered; phylo -> partial weakly-identified; kernel/SPDE -> planned). It is an
   owner-reserved matrix-structure decision (changes row counts/metrics). Recorded in design 168
   "Structural dependencies" next-gate + status.json blocker. **This is the single highest-yield
   unlock available.**
2. **GitHub coordination comments** (still parked from session 2): drmTMB#499 bridge status +
   DRM.jl#294 Route A — content in `docs/dev-log/2026-06-20-bridge-parity-verification.md`;
   auto-denied. Post them or grant `gh issue comment`.

## 5. Active strategic threads (owner-directed, deferred to fresh context)

- **Coevolution Stage 1 engine surgery** — the verified plan is in
  `docs/design/178-coevolution-tale-of-two-phylogenies.md` ("Stage 1 implementation plan");
  TDD spec: `tests/testthat/test-coevolution-additive-gate.R` (skipped target). Gauss-level,
  R assembly + `src/drmTMB.cpp` block loop. Do with FRESH context, TDD-first.
- **Kernel abstraction** (NNGP/Matern/SPDE) — net-new; design 178 "Kernel generalization".
  Adopt GLLVM.jl#62 for Matern-SPDE (provenance in `inst/COPYRIGHTS` if ported).

## 6. Boundaries (Rose enforces — non-negotiable)

Every promotion Rose+Fisher (or Curie/Florence/Noether) verified, scoped, evidence-first.
Aggregate rows need a SET of sub-type sims OR per-sub-type rows (do NOT redefine the
denominator). Cite ASSERTED tolerances, not measured values. Keep native R/TMB ↔ direct
DRM.jl ↔ Julia-via-R in separate lanes. No release/CRAN claim. Bridge parity is NOT interval
coverage. partial/planned fall only to NEW measuring evidence. For package code changes, run
the targeted test suites (a full `devtools::check()` before any release). Reusing gllvm/Julia
code requires `inst/COPYRIGHTS` provenance + tests.

## 7. Reusable patterns banked this session

- Recovery sim: self-contained `run.R [n_rep]`, n-ladder for consistency, extract SD from
  `fit$sdpars`, smoke->pilot->500, Curie+Fisher, HELD if no granular cell.
- Profile calibration: `confint(method="profile")` + `method="wald"` alongside, 500 reps, track
  conf.status; coefficients now use the fast endpoint engine via `auto`.
- Bootstrap pilot: `confint(method="bootstrap", R=199)` — bounded (R refits/CI), ~100 reps ->
  partial.
- Visual flip: figure of already-verified data -> Florence gate -> matrix visual cell.
- Profile speed: endpoint engine = 3-5x; profile-target name is `sd:mu:<term>` /
  `fixef:<dpar>:<coef>`; relmat marker needs a precomputed `Q`/`K` symbol (no inline `solve()`).

Hand off the same way when context fills. Good luck.

## 8. Continuation (same session, after the handover commit) — interval-method broadening

Owner steer continued: get profile + bootstrap going across the rows, profile is the
favorite. **HEAD now `abc0e390`** (3 more slices after the handover; all pushed, tree
clean, validator green 25/68).

- `8ee77fbf` **Non-Gaussian Profile -> partial** (Fisher, parity). 6-family x n {300,600}
  x 500-rep profile calibration; profile tracks Wald to within MC noise (max diff 0.004),
  nominal by n=600; the count/heavy-tailed n=300 slopes mildly sub-nominal under BOTH
  methods, so parity-partial with the Wald cell.
- `8b2924e5` **design 179** (`docs/design/179-julia-inprocess-profile-bootstrap.md`):
  scoped the "maximized in Julia" direction. KEY: the DRM.jl profile loop is ALREADY
  in-process and batched (one `julia_call` runs the whole loop; ~3-min is per-`confint`
  session cost, not per-point). Staged plan: **Stage A** widen the bridge past the SD
  block to the coefficient/scale/correlation profiles DRM.jl already computes (cheapest
  first Julia-speedup cell-evidence; unlocks the native R coefficient weak spot);
  Stage B warm-start in-process bootstrap (the marquee Julia differentiator); Stage C
  resident fit handle. Recommendation: Stage A first.
- `abc0e390` **Random slopes Profile -> partial** (Fisher). Profile is parity-or-BETTER
  than Wald (all 4 cells clear the 0.93 floor where the n=40 Wald slope is 0.922); held
  partial not covered because the n=40 profile cells are within ~1 MCSE of the floor and
  RE-SD/rho/bootstrap are unaddressed.

**Interval-method status now:** profile broadened across the three fixed-effect-bearing
rows (rho12 covered; non-Gaussian partial; random-slope partial). Bootstrap: rho12
partial (pilot); broadening to other rows is cost-prohibitive (R refits x families/RE) --
the honest path is the Julia warm-start bootstrap (design 179 Stage B). The
endpoint-coefficient profile speedup (`f0fb4f7f`) is what made coefficient profile
calibration feasible.

**Marquee next (both genuinely want FRESH context):**
1. **Julia Stage A** (design 179) — widen the bridge to expose the coefficient/scale/
   correlation profiles DRM.jl already computes; cheapest first "Julia speedups" cell
   evidence; needs the Julia toolchain (~3-min round-trips) + per-target parity gates.
2. **Coevolution Stage 1 engine surgery** (design 178) — the Hadfield additive model;
   Gauss-level R assembly + `src/drmTMB.cpp` block loop; TDD-first.
3. ~~Owner decision pending: mint per-sub-type Structural rows~~ **DONE** (`733724f4`,
   owner-approved): the aggregate "Structural dependencies" row was replaced with 6
   per-sub-type rows (matrix 17 -> 22). relmat/animal/spatial POINT -> covered; phylo
   POINT -> partial; kernel/SPDE -> planned. The 25/68 slice metric is unchanged.

## 9. Final state (HEAD drmTMB `942d1fd0`, DRM.jl `1ef441e`)

15 defended slices this session, all pushed, both repos clean, validator green (25/68
slice metric, 22 matrix rows, 11 Julia capability rows). Interval-method broadening +
per-sub-type Structural rows + **Julia Stage A (LANDED)** are complete.

**Julia Stage A — LANDED this session (owner "push").** The R-Julia bridge now
profiles fixed-effect COEFFICIENTS via `confint(engine="julia", method="profile")`
(was SD-block only). Cross-repo: DRM.jl `bridge.jl` `1ef441e` (opts
profile_param/profile_coef passthrough) + drmTMB `bc467293` (R/julia-bridge.R target
enumeration / gate / identity transform / options merge; no-parm stays SD-only;
bootstrap-of-coef rejected) + `942d1fd0` (capability row). Parity via the callr Julia
harness: engine="julia" coefficient profile endpoints match native TMB to the asserted
**1e-3** (measured ~2e-5 on one Gaussian phylo fixture; engines fit identically).
Capability row `phylo_coef_profile_bridge` -> **partial** (Fisher). Live test in
`test-julia-inference.R`.

**Stage A finish + Stage B bootstrap — LANDED (owner "finish A and B").** mu
fixed-effect coefficients now have **Wald + profile + bootstrap** through the bridge
(DRM.jl `4c04559`, drmTMB `e6ba7d55`). Bootstrap-of-mu-coef is cold parametric (reuses
existing machinery); live `test-julia-inference.R` PASS 53/0. **sigma** coefficient
profiles withdrawn (DRM.jl `parm=:sigma` diverges at the log-sigma boundary, ~10
disagreement — verification caught it). Capability row `phylo_coef_profile_bridge`
covers profile+bootstrap (partial).

**Remaining (FRESH context):**
- **Multi-coefficient batching** (design 179): the SD-axis-specific multi-row join —
  efficiency (single-coef works today).
- **Boundary-robust sigma coefficient profiles** — a DRM.jl-side fix (log-sigma boundary).
- **Warm-start in-process bootstrap** (design 179 Stage B optimisation): the
  fixed-effect Gaussian location-scale cell **LANDED** in the direct DRM.jl lane
  (2026-06-20, opt-in `warmstart=true`; warm==cold parity gate; after-task
  `2026-06-20-julia-stageB-warmstart-bootstrap.md`). STILL DEFERRED: the EXPENSIVE
  refit cells (Gaussian phylo / RE — the bridge's bootstrap path) need a packed-start
  fitter entrypoint before the bridge can pass `warmstart` through; the LocScale q2
  path additionally needs an RE-conditional `simulate` (its population-level draw makes
  the parametric bootstrap degenerate at the boundary).
- **Coevolution Stage 1** (design 178): the Hadfield additive-model engine surgery
  (R assembly + `src/drmTMB.cpp` block loop), TDD-first.
- **Promote covered** only with multi-seed/model parity (Stage A is single-fixture).
- Pre-existing drift: `inst/extdata/julia-capabilities.tsv` lags the dashboard registry.
- GitHub coordination comments (drmTMB#499 / DRM.jl#294) still parked (auto-denied).
