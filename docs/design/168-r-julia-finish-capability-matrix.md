# R-Julia Finish Capability Matrix

This matrix is the claim registry for the `DRM.jl` and `drmTMB` finish plan.
It is written for package contributors who need to know whether a row is fitted,
bridged, inferentially usable, documented, visualized, and release-ready. A row
is not complete because the model fits once; it is complete only when engine
support, R bridge support, point estimates, CI/status, tests, documentation,
visual evidence, issue evidence, and Rose audit agree.

This document does not replace the older validation ledgers. It sits above
`docs/design/34-validation-debt-register.md`,
`docs/design/46-pre-simulation-readiness-matrix.md`, and
`docs/design/157-capability-completion-worklist.md` as the finish-plan summary.
When those ledgers disagree with this matrix, the stricter row wins until the
evidence is reconciled.

## Status Vocabulary

- `covered`: implementation, focused tests, public documentation, and relevant
  diagnostic or interval evidence exist for the named row.
- `partial`: a narrow cell is fitted or documented, but nearby users could
  overread the claim; the boundary must stay visible.
- `experimental`: useful for development or opt-in examples, but not yet a
  general user promise.
- `planned`: accepted as roadmap work, with no public support claim.
- `unsupported`: deliberately rejected or out of scope.

## Finish Matrix

| Area | Engine | R bridge | Point estimates | Wald CI | Profile CI | Bootstrap CI | Docs/article | Visual | Simulation | Release gate | Next gate |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Dashboard and issue ledger | covered | partial | covered | unsupported | unsupported | unsupported | covered | covered | unsupported | partial | Post-#635/#295 evidence now includes direct DRM.jl smoke evidence and a Julia-via-R clean-main bridge-test audit, while keeping bridge-row promotion separate. Keep `status.json`, `sweep.json`, check-log, and after-task notes synchronized with issues. |
| Master capability matrix | partial | partial | partial | partial | partial | partial | partial | planned | partial | partial | Wire README, ROADMAP, NEWS, pkgdown, Documenter, and dashboard claims to this matrix. |
| R-Julia bridge gate | partial | experimental | partial | planned | partial | partial | covered | covered | partial | planned | `drmTMB#544` is closed after the generated gate registry, capability comparison, docs-drift guard, and dashboard rendering landed. The clean-main bridge audit removed stale local DRM.jl and Julia-home test defaults; `devtools::test(filter = "julia")` passed against merged DRM.jl main with the known Route A skip. Future bridge work still needs row-specific parity issues before promoting any R-gated Julia-covered cell. |
| Gaussian phylogenetic SD target | partial | experimental | partial | partial | partial | partial | partial | planned | partial | planned | Native R/TMB now has q4 target inventory and endpoint-budget status rows, but promotion still waits for native R, R-Julia bridge, and direct Julia point estimate plus CI/status parity in one row; use `drmTMB#555` for the Ayumi q4 status harness. |
| Random slopes | partial | planned | covered | partial | planned | planned | partial | covered | partial | planned | A 500-replicate native R/TMB Gaussian correlated random-slope recovery (bf(y ~ x + (1 + x | id), sigma ~ 1); n_group in {40, 80}; 0 errors; pdHess 1.000; Curie+Fisher verified) promotes point estimates to covered, scoped to POINT recovery: fixed effects near-unbiased (rel bias <= 1%) at both group counts, and the random intercept/slope SDs consistent with the expected ML small-sample downward bias (sd_slope -6.7% at n_group=40 shrinking to -1.1% at n_group=80). A Florence-approved recovery figure (docs/dev-log/figure-audits/2026-06-20-random-slope-recovery/) of this verified artifact promotes the visual cell to covered (dots + MC error bars + zero line; POINT recovery + RE-SD consistency, not coverage). The random-effect correlation rho was not validated and RE-SD interval calibration is not claimed; Wald stays partial (n_group=40 b1 coverage 0.922 < 0.93). Independent-slope-only, non-Gaussian, structured/phylogenetic slopes, profile/bootstrap, and the Julia bridge remain planned. |
| Non-Gaussian models | partial | planned | covered | partial | partial | planned | partial | covered | partial | planned | A 500-replicate native R/TMB fixed-effect mu = b0 + b1*x recovery artifact (six one-response families poisson/nbinom2/Gamma(log)/lognormal/beta/student, n in {300, 600}, 12,000 fits, 0 errors, largest absolute bias 0.0052, pdHess >= 0.996; Rose+Fisher verified) promotes point estimates to covered, scoped to fixed-effect mu coefficient recovery for the implemented one-response families. Wald stays partial (student n=300 mu:x Wald coverage 0.926, below the 0.93 floor; recovers to 0.944/0.952 at n=600). A 500-replicate-per-cell profile-likelihood interval calibration across the same six families (`confint(method="profile")` for the two mu coefficients; n in {300,600}; 0 fit errors, 0 profile CI failures; Fisher verified; `docs/dev-log/simulation-artifacts/2026-06-20-nongaussian-profile-calibration/`) moves the **profile** cell to partial, in PARITY with Wald: profile coverage tracks Wald to within Monte-Carlo noise at every cell (max |profile-Wald| 0.004) and both reach nominal by n=600, but the n=300 slopes for the count and heavy-tailed families remain mildly sub-nominal under BOTH methods, so profile is held at partial alongside Wald rather than promoted to covered. Simulation stays partial (unauthorized here; the binomial row likewise keeps simulation partial despite covered intervals). Variance, correlation, bootstrap intervals, random/structured effects, bivariate/mixed responses, and the Julia bridge remain planned and require their own recovery rows. |
| Bernoulli/binomial response family | partial | unsupported | covered | covered | covered | unsupported | partial | covered | partial | planned | Fixed-effect `stats::binomial(link = "logit")` now fits 0/1 and `cbind(successes, failures)` responses and has `stats::glm()` parity plus 500-replicate fixed-effect Wald and profile interval artifacts (profile coverage 0.93-0.972) and a Florence-approved coverage figure (docs/dev-log/figure-audits/2026-06-20-binomial-coverage/) that promotes the visual cell; bridge support, bootstrap intervals, random effects, structured effects, headline coverage, and bivariate or mixed responses remain unavailable. |
| Bivariate residual correlation `rho12` | partial | partial | covered | covered | covered | partial | partial | covered | covered | planned | A 500-replicate fixed-effect `rho12 ~ x` recovery artifact shows near-unbiased recovery (bias <= 0.011) with Wald coverage 0.920-0.964; keep residual `rho12` separate from group, phylogenetic, spatial, kernel, and cross-family correlations. A 500-replicate-per-cell (n in {300, 600}; 0 fit errors, 0 CI failures, pdHess 1.000; Fisher verified) profile-likelihood interval calibration on the same DGP (`docs/dev-log/simulation-artifacts/2026-06-20-rho12-profile-calibration/`) promotes the **profile** cell to covered, scoped to native R/TMB fixed-effect `rho12 ~ x` profile intervals for the two rho12 coefficients via `tmbprofile` (the `auto` engine falls back to `tmbprofile` for coefficients; the fast endpoint solver is not used here). Profile coverage tracks Wald to within Monte-Carlo noise and reaches nominal by n=600 (profile 0.964/0.960, Wald 0.964/0.956); the n=300 slope cell mildly undercovers under BOTH methods (profile 0.922, Wald 0.920), so this is profile-vs-Wald parity and ~0.95 calibration at n>=600, not a small-n exactness claim. The R-Julia bridge is `partial`: `engine="julia"` reproduces native `engine="tmb"` coefficient and Wald CI-endpoint parity for `rho12 ~ x` to <= 1e-4 on one seed-fixed dataset (the narrower per-cell `nonphylo_biv_rho12_predictor` capability row is `covered` at that granularity) -- engine-vs-engine parity, not interval coverage, and not a comprehensively validated bridge. A parametric-bootstrap (`confint(method="bootstrap")`, R=199) interval pilot at 100 reps/cell (n in {300,600}) on the same DGP (`docs/dev-log/simulation-artifacts/2026-06-20-rho12-bootstrap-pilot/`; Fisher gated) moves the **bootstrap** cell to partial: bootstrap intervals are feasible (0/100 CI failures per cell, 0 fit errors, pdHess 1.000) and approximately calibrated, with widths matching the verified Wald/profile cells -- but this is pilot-scale (coverage MCSE 0.014-0.029), not the 500-rep calibration the Wald/profile cells carry, because each CI costs R refits. Random-effect `rho12` intervals remain planned. |
| Mixed and cross-family correlation | planned | unsupported | planned | planned | planned | planned | planned | planned | planned | planned | Use `DRM.jl#280`-style recovery and bridge labels before user-facing promotion. |
| High-q correlations | partial | planned | partial | planned | planned | planned | partial | planned | partial | planned | q4 first, q8 second; higher q requires transform, gradient, recovery, and CI-status evidence. |
| Structural dependencies | partial | planned | partial | partial | planned | planned | partial | planned | partial | planned | Animal, phylo, relmat, spatial, kernel, and SPDE rows each need provenance, PSD/name-alignment tests, recovery, bridge parity, docs, and visuals. Sub-type milestone (Rose+Fisher adjudicated; aggregate POINT cell HELD partial -- 4 of 6 sub-types now have native Gaussian POINT recovery, 2 unimplemented): clean held diagnostics for relmat known-K (sd_relmat -3.0% -> -1.0%), animal pedigree NRM (sd_animal -3.1% -> -1.3%), and spatial fixed-range coordinate kernel (sd_spatial -10.9% -> -2.8%), all 500 reps/cell, 0 errors, pdHess 1.000, fixed effects unbiased; the single-tree phylo SD is weakly identified (-32% -> -4.8%, intercept Wald sub-nominal even at 240 species) and the phylo_interaction/coevolution SD recovers better (-6.4% -> -1.6%). kernel() and SPDE/mesh are unimplemented (mesh fit aborts at R/drmTMB.R; the coordinate range is fixed, not estimated), so the aggregate cannot honestly reach covered (Rose+Fisher: an unscoped aggregate covered over-claims; do not redefine the denominator from 6 to 4). OWNER DECISION pending: mint per-sub-type rows (relmat/animal/spatial POINT -> covered; phylo -> partial; kernel/SPDE -> planned) so earned sub-type evidence has a home, or hold the aggregate until kernel/SPDE exist. See docs/dev-log/simulation-artifacts/2026-06-20-{relmat-structured,animal-pedigree,spatial-coords,phylo-sd,coevolution-phylo-interaction}-recovery/. |
| Julia speedups | experimental | experimental | planned | planned | planned | planned | partial | planned | planned | planned | No speed headline without point-estimate and CI/status evidence. Benchmark native TMB, R-Julia bridge, and direct DRM.jl separately. R-side profile baseline banked (`docs/dev-log/simulation-artifacts/2026-06-20-profile-engine-speed-benchmark/`): the endpoint profile engine is ~3-5x faster than `tmbprofile` on direct scale/SD/correlation targets (endpoints agree <= 1.4e-5), with the gain growing on structured GMRF SD targets. Direction for "maximized in Julia": profile/bootstrap are repeated-re-optimization workloads, so an IN-PROCESS direct DRM.jl profile/bootstrap loop (not the callr bridge, whose ~3-min round-trip swamps the gain) is the scalable path; Julia profile is partially wired (`drm_julia_profile_targets`) but gated on a stored bridge payload and unvalidated. Scoped plan in `docs/design/179-julia-inprocess-profile-bootstrap.md` (read-only map, 2026-06-20): the DRM.jl profile loop is ALREADY in-process and batched -- one `julia_call` runs the whole profile grid / bootstrap B-loop in one resident process, so the ~3-min cost is per-`confint` session cost (compile + cold re-fit), NOT per-point. Gaps: the bridge is locked to the SD block (Stage A: widen to coefficient/scale/correlation targets `profile_result` already computes -- cheapest first cell-evidence), cold-start bootstrap (Stage B: warm-start refit), and per-call cold re-fit (Stage C: resident fit handle). No cell promoted (R-side timing diagnostic + scoping note, not Julia speed evidence). |
| AI-REML-inspired algorithms | planned | unsupported | planned | planned | planned | planned | planned | unsupported | planned | planned | Borrow `hsquared` only as a design analogue for exact Gaussian MME cells; use observed-information, Fisher/natural-gradient, or AD-gradient methods for Laplace/non-Gaussian cells after derivation. |
| Missing values | partial | planned | planned | planned | planned | planned | planned | planned | planned | planned | Use likelihood/FIML-style masks. Complete-data all-true masks must match current complete-data log-likelihood exactly. |
| Visuals and articles | partial | partial | partial | partial | partial | partial | partial | planned | partial | planned | Every major capability needs a real visual: capability heatmap, profile curve, parity plot, missingness heatmap, structural visual, and runtime-plus-CI plot where relevant. |
| ADEMP and comparator program | partial | planned | partial | partial | planned | planned | partial | partial | partial | planned | Binomial fixed-effect parity, fixed-effect Wald interval calibration, the fixed-effect profile interval calibration, the first fixed-effect `log(sigma)` clamp sensitivity pilot, the first scale-side phylogenetic clamp-active diagnostic, the first fixed-effect bivariate `sigma1`/`sigma2` clamp-sensitivity diagnostic, the larger fixed-effect bivariate `sigma1`/`sigma2` clamp diagnostic, the first Student-t finite-variance diagnostic pilot, the first Student-t Wald calibration diagnostic, the first Student-t profile/bootstrap feasibility diagnostic, the Student-t profile/bootstrap diagnostic pilot, the Student-t profile/bootstrap calibration diagnostic, the Student-t profile-failure decision audit, the skew-normal diagnostic pilot, skew-normal tail-floor source and fit-stress diagnostics, the fixed-effect skew-normal guard grid, the beta/zero-one beta support-floor diagnostic, the residual `rho12` open-interval diagnostic, the q2 `mu`/`sigma` covariance boundary diagnostic, the ordinary q2 correlation-grid diagnostic, the larger ordinary q2 covariance hardening diagnostic, the structured q2 boundary diagnostic, the numerical-guard ADEMP design, and q8 staged diagnostic artifact plus endpoint-status hardening are banked as native R/TMB diagnostic evidence; direct DRM.jl smoke evidence and Julia-via-R clean-main bridge-test evidence are also banked as companion evidence; broader operating-characteristic simulations, q8 coverage/power, row-specific bridge parity, and release-readiness evidence remain partial or planned. |
| Release gate | planned | planned | planned | planned | planned | planned | planned | planned | planned | planned | Release notes must separate local package health, public CI/pkgdown state, speed evidence, unsupported cells, and remaining validation debt. No CRAN submission without user decision. |

## Issue-Led Slice Rules

1. Prefer updating an existing issue over opening a duplicate.
2. Every issue or issue comment should state fitted, planned, missing, and
   unsupported status for the row it owns.
3. Every implementation issue needs acceptance gates for engine, bridge, point
   estimates, CI/status, tests, docs, visuals, and after-task evidence.
4. If GitHub writing is unavailable in a session, record the attempted issue
   action in the after-task report and put the comment text in local evidence.
5. A closed issue must name the check-log entry, after-task report, and next
   issue if a neighbouring row remains planned.

## Bridge Gate Registry Contract

`drmTMB#544` closed the first generated bridge-gate registry slice. Each
intentional `engine = "julia"` rejection should still have a row with these
fields:

```text
gate_id
family_type
syntax
r_bridge_status
drmjl_status
message_pattern
review_due
evidence_url
```

The CI guard should fail when an R-side Julia rejection lacks a registry row,
when a registry row lacks a representative test, when a DRM.jl-covered cell
remains R-gated without an intentional reason, or when public docs claim more
than the registry supports. The registry should cross-link `gllvmTMB#488` for
the mirror drift pattern, but it should not borrow `gllvmTMB`'s higher
dimensional model scope.

The generated dashboard artifact is
`docs/dev-log/dashboard/julia-gates.tsv`; the same generator also writes
`inst/extdata/julia-gates.tsv` so the synchronization test can run inside R CMD
check, where `docs/` is not installed. Regenerate both copies with:

```sh
Rscript tools/write-julia-gate-registry.R
```

For `drmTMB#569`, the bridge registry may acknowledge DRM.jl Binomial support
where it exists, but the first public binomial response family claim remains
native TMB only until R-side response parsing, likelihood parity, method tests,
and separate bridge parity evidence exist.

## Dashboard Contract

The live dashboard is an operating surface, not a release claim. It should show
what is queued, active, blocked, verified, banked, and deferred. It should warn
when the checkout is detached or dirty and should never mark a row `verified`
without an evidence entry.

The durable dashboard source lives in `docs/dev-log/dashboard/`. The live copy
is served from `/tmp/drm-dashboard` at `http://127.0.0.1:8765/`.

The issue-led finish board is row-oriented. It separates the critical path,
issue ledger, twin claim board, cross-package lessons, evidence gates, and
release readiness so that fitted, planned, unsupported, experimental, and
weakly identified cells cannot collapse into one status word.

## Claim Guards

- Current `engine = "julia"` examples use the default `DRM.jl` fitting path.
  They are not evidence that users can choose Julia-side algorithms from R.
- The lead `drmTMB` novelty is predictor-dependent residual `rho12`, not speed
  and not scale-side phylogenetic effects.
- Scale-side phylogenetic fields with about one observation per tip should be
  described as weakly identified, confounding-prone, or prior-sensitive. Do not
  promote them with stronger language, and do not cite the Ayumi Model A
  likelihood-ratio result until Claude banks that number reproducibly.
- `pdHess = FALSE` blocks Wald promotion, but it does not automatically discard
  a useful point estimate.
- Profile and bootstrap intervals are target-specific. Endpoint parity for one
  Gaussian phylogenetic SD target does not promote fixed effects, non-Gaussian
  families, scale formulas, multiple structured terms, or neighbouring syntax.
- `drmTMB#547` fixes q4 Julia REML option forwarding only. The native TMB path
  does not currently provide a general REML estimator; do not add a phantom
  scale-side REML gap row unless a real estimator design exists. Speed
  and full q4 inference validation remain separate evidence slices.
- AI-REML wording belongs only to exact Gaussian REML/MME derivations. For
  Laplace and non-Gaussian distributional models, use the actual method name.
- Speed claims require point estimate, objective/log-likelihood, CI/status,
  convergence, failure count, thread, memory, version, and dirty-state evidence.
- GPU, CUDA, TPU, accelerator, compute-target, and offload vocabulary stays
  `planned` or `unsupported` until benchmark evidence exists.
  `tools/validate-mission-control.py` lints the public reference files (README,
  ROADMAP, NEWS, `_pkgdown.yml`, the dashboard README, and known-limitations)
  for accelerator claims that lack a `planned`/`unsupported` guard; this design
  matrix is the source of truth and is itself exempt from the scan. The token
  "backend" is
  deliberately excluded because it denotes the parallel-execution mode
  (`backend = "multicore"`/`"none"`) and the TMB precision backend, not a
  hardware accelerator.
- Plain Bernoulli/binomial support means event-probability `mu` only. It is not
  beta-binomial overdispersion, beta/zero-one beta continuous-proportion
  modelling, binary missing-predictor imputation, random-effect binomial, or a
  Julia bridge claim.

## Post-#633 Work Order

1. Keep the dashboard live at `http://127.0.0.1:8765/`.
2. Keep the finish-board widget, generated Julia gate tables, and issue-led
   evidence rows synchronized with merged PRs. The widget, `#569` native
   binomial slice, `#544` bridge-gate guard, `#591` comparator artifact,
   `#593` binomial Wald interval artifact, and `#602` q8 staged diagnostic
   artifact are banked.
3. Preserve the `drmTMB#569` binomial response boundary:
   `stats::binomial(link = "logit")`, 0/1 and `cbind(successes, failures)`,
   fixed-effect `mu` only, no weights-as-trials, no `sigma`, no structured or
   random effects, no bivariate route, and no Julia bridge claim.
4. Treat q8 as diagnostic-only until deliberately sized recovery, coverage,
   and power evidence exists. `#602` provides a cold-vs-staged artifact route;
   it does not promote q8 intervals, speed, release readiness, or public
   warm-start support.
5. Open follow-on bridge issues before relaxing any R-side Julia gate. The
   current registry and capability comparison are banked; bridge promotion
   still needs per-cell parity evidence and explicit owner review.
   The post-#634 companion evidence is now banked for direct DRM.jl smoke
   checks and the Julia-via-R clean-main bridge-test audit. Future bridge work
   should be row-specific parity work from a clean DRM.jl worktree; the user's
   saved DRM.jl checkout may contain unrelated Ayumi files and should not be
   reused as the implementation surface.
6. Continue the broader numerical-guard programme beyond the fixed-effect
   `log(sigma)` pilot, the Student-t finite-variance diagnostic pilot, the
   Student-t Wald calibration diagnostic, the Student-t profile/bootstrap
   feasibility diagnostic, the Student-t profile/bootstrap diagnostic pilot,
   the Student-t profile/bootstrap calibration diagnostic,
   the Student-t profile-failure decision audit,
   the larger fixed-effect bivariate `sigma1`/`sigma2` clamp diagnostic,
   the skew-normal diagnostic pilot, fixed-effect skew-normal guard grid,
   the skew-normal tail-floor source and fit-stress diagnostics,
   the beta/zero-one beta support-floor diagnostic, the residual
   `rho12` open-interval
   diagnostic, the q2 `mu`/`sigma` covariance boundary diagnostic, the ordinary
   q2 correlation-grid diagnostic, the structured q2 boundary diagnostic, the
   scale-side phylogenetic clamp-active diagnostic, the fixed-effect bivariate
   `sigma1`/`sigma2` clamp-sensitivity diagnostic, and the ADEMP design in
   `docs/design/176-numerical-guard-simulation-audit.md`: larger bivariate
   scale-route grids, formal skew-normal operating-characteristic grids,
   additional
   random-effect and structured correlation guard depth, larger scale-side
   phylogeny grids, and broader interval consequences still need sensitivity
   evidence. The post-#633 decision ledger keeps Student-t profile intervals
   blocked by method until failure modes are investigated, keeps Student-t
   bootstrap intervals diagnostic until the target/refit budget is justified,
   and names fixed-effect bivariate `sigma1`/`sigma2` clamp sensitivity as the
   strongest next scale-guard candidate.
   The four-block operating plan in
   `docs/design/177-big4-finish-plan-2026-06-19.md` sequences that scale
   slice before ordinary q2/same-response hardening, q8 endpoint hardening,
   and fixed-effect skew-normal guard-grid work. The larger scale slice is
   now banked as native R/TMB diagnostic evidence only: upper-side guard
   visibility is visible, while lower-tail rows retain numerical roughness and
   need follow-up before any interval, recovery, or bridge claim.
   The ordinary q2 hardening slice is also now banked as native R/TMB
   diagnostic evidence only: all 2100 primary fits returned, converged, and
   had `pdHess = TRUE`, but bivariate-route fixed-gradient status and
   fitted-minus-true correlation errors keep this out of promotion, bridge,
   interval, release, and CRAN language.
7. Leave release, comparator, and CRAN readiness planned until implementation,
   evidence, pkgdown, issue comments, dashboard rows, and 3-OS CI agree.

## Public Claim Lint

`tools/validate-mission-control.py` is the local guard for this matrix. It
checks dashboard status counts and registry schemas, then checks that README,
ROADMAP, NEWS, pkgdown navigation, the dashboard README, and any local
Documenter.jl source files link back to this claim registry. It also rejects
public-facing "release-ready" wording outside the release-gate row and rejects
reserved `engine_control` language until a supported public control surface has
design, tests, documentation, dashboard evidence, and review.
