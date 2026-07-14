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
| R-Julia bridge gate | partial | experimental | partial | planned | partial | partial | covered | covered | partial | planned | `drmTMB#544` is closed after the generated gate registry, capability comparison, docs-drift guard, and dashboard rendering landed. The clean-main bridge audit removed stale local DRM.jl and Julia-home test defaults; newer structured-RE evidence now banks q1 mean-phylo Route A ML parity, q1 sigma-only phylo ML parity, q1 matched `mu` plus `sigma` phylo ML parity, q1 `spatial()` mean-side ML parity via native fixed-range K, q1 `relmat()` mean-side ML parity, q1 `animal()` mean-side ML parity, q1 Poisson `phylo()` ML/Laplace parity, q1 unsupported-route preflight errors, q1 coefficient-scale maps, the q1 acceptance gate, the q2 payload-boundary contract, q2 payload provenance, q2 phylo direct/R-via-Julia fixture evidence, q2 animal and relmat direct/R-via-Julia known-covariance fixture evidence, and q2 spatial fixed-covariance direct evidence as separate row-specific fixtures. Future bridge work still needs row-specific parity issues before promoting any R-gated Julia-covered cell. |
| Gaussian phylogenetic SD target | partial | experimental | partial | partial | partial | partial | partial | planned | partial | planned | Native R/TMB now has q4 target inventory and endpoint-budget status rows, but promotion still waits for native R, R-Julia bridge, and direct Julia point estimate plus CI/status parity in one row; use `drmTMB#555` for the Ayumi q4 status harness. |
| Random slopes | partial | planned | partial | partial | planned | planned | partial | planned | partial | planned | Fixed-effect likelihoods first, independent slopes second, correlated slopes third, structured slopes last. |
| Non-Gaussian models | partial | planned | partial | partial | planned | planned | partial | planned | partial | planned | Coefficient parity first; variance, correlation, and CI claims require their own recovery rows. |
| Bernoulli/binomial response family | partial | unsupported | partial | covered | planned | unsupported | partial | planned | partial | planned | Fixed-effect `stats::binomial(link = "logit")` now fits 0/1 and `cbind(successes, failures)` responses and has `stats::glm()` parity plus a 500-replicate fixed-effect Wald interval artifact; bridge support, profile/bootstrap intervals, random effects, structured effects, headline coverage, and bivariate or mixed responses remain unavailable. |
| Bivariate residual correlation `rho12` | partial | planned | partial | partial | planned | planned | partial | planned | partial | planned | Keep residual `rho12` separate from group, phylogenetic, spatial, kernel, and cross-family correlations. |
| Mixed and cross-family correlation | planned | unsupported | planned | planned | planned | planned | planned | planned | planned | planned | Use `DRM.jl#280`-style recovery and bridge labels before user-facing promotion. |
| High-q correlations | partial | planned | partial | planned | planned | planned | partial | planned | partial | planned | q4 first, q8 second; higher q requires transform, gradient, recovery, and CI-status evidence. |
| Structural dependencies | partial | planned | partial | partial | planned | planned | partial | planned | partial | planned | Animal, phylo, relmat, spatial, kernel, and SPDE rows each need provenance, PSD/name-alignment tests, recovery, bridge parity, docs, and visuals. Q1 `spatial()`, `relmat()`, and `animal()` Gaussian mean-side ML now have one native/direct/R-via-Julia parity fixture each; spatial parity uses native fixed-range K before the DRM.jl call. Q1 Poisson `phylo()` mean-side bridge parity is banked for one approximate ML/Laplace fixture against native dense TMB. Q1 coefficient-scale maps now document fixed link-scale coefficients, response-scale structured SDs, and coupled phylo recov-to-corpars reconstruction, and the q1 acceptance gate is banked as a local transition gate. Q2 payload shape, provenance, and coefficient ordering are banked as contract evidence, coordinate-spatial, animal, and relmat q2 native ML point evidence each has focused smoke evidence, q2-plus-q2 target separation is banked as boundary evidence, scale-only q2 `sigma1`/`sigma2` blocks have native-TMB point-fit/extractor evidence only, the q2 coefficient-ordering map is banked, q2 phylo direct/R-via-Julia fixture evidence is banked, animal and relmat q2 direct/R-via-Julia known-covariance fixture evidence is banked, spatial q2 direct/R-via-Julia fixed-covariance fixture evidence is banked, and aggregate q2 parity acceptance is banked only for fixture-scoped exact-Gaussian ML routes; scale-only q2 bridge payloads, interval coverage, denominator evidence, range-estimating spatial, q2 REML, q4, and broad public bridge support remain unpromoted. The q4 phylogenetic covariance target map is banked for four direct SD targets and six derived correlation targets, the q4 profile-target bridge map is banked for the four direct SD label mappings, q4 scale-axis interval failures are banked as blocker evidence for `sd_sigma1` and `sd_sigma2`, direct DRM.jl q4 point SD exports are banked as direct-Julia evidence, the deterministic q4 balanced8 fixture is banked as reusable fixture data, and q4 point-parity tolerances are predeclared; q4 all-four parity, R-via-Julia q4 bridge parity, q4 parity acceptance, q4 profile-interval reliability, interval coverage, and q4 corpairs same-fixture parity remain blocked or unevaluated. SR160-SR170 scope-gate rows now make mesh/SPDE, sparse animal pedigree helpers, `relmat()` precision `Q`, q1-only `phylo_interaction()`, direct-SD grammar, structured slopes, structured `rho12`, and non-Gaussian q2/q4 structured covariance explicit. Structured sigma predictors, precision slots, and malformed covariance matrices stay gated or fail preflight before JuliaCall. Mesh/SPDE, Q, pedigree, and Ainv marshalling, NB2 parity, non-phylo count bridge support, intervals, REML, sigma-side support, range-estimating q2 spatial support, q4 bridge support, kernel, and SPDE bridge rows remain separate. |
| Julia speedups | experimental | experimental | planned | planned | planned | planned | partial | planned | planned | planned | No speed headline without point-estimate and CI/status evidence. Benchmark native TMB, R-Julia bridge, and direct DRM.jl separately. |
| AI-REML-inspired algorithms | partial | unsupported | planned | planned | planned | planned | partial | unsupported | partial | planned | `docs/design/178-ai-reml-hsquared-transfer-gate.md` records the transfer boundary and the internal DRM.jl exact-Gaussian location-only helper: supplied-variance REML objective, dense same-estimand comparator, boundary classifier, Takahashi trace and PEV diagnostics plus PEV summaries, AI-vs-observed information diagnostic, sparse average-information diagnostic, guarded average-information update experiment with `ai_reml_ready = false`, finite-difference optimizer experiment with `ai_reml_ready = false`, FD-stability and local-profile diagnostics, dense and sparse-Woodbury restricted-score diagnostics, dense-score and sparse-score optimizer experiments, observed-Hessian status, diagnostic payload, status/schema rows, boundary fixtures, tiny deterministic recovery-grid diagnostics, a weak-signal boundary recovery probe, machine-readable simulation-status rows, row validator, TSV writer, optional medium stress row, broader recovery-grid helper, weak-signal condition-grid helper, and a larger interior stress row. `docs/design/179-q4-patterson-thompson-is-not-hsquared-ai-reml.md` keeps q4 Patterson-Thompson separate from HSquared AI-REML, and `structured-re-native-reml-scope-status.tsv` keeps requested/effective estimator fields visible for SR151-SR159. This does not promote an average-information optimizer, R bridge row, interval coverage, q4, Laplace, or non-Gaussian AI-REML claim. |
| Missing values | partial | planned | planned | planned | planned | planned | planned | planned | planned | planned | Use likelihood/FIML-style masks. Complete-data all-true masks must match current complete-data log-likelihood exactly. |
| Visuals and articles | partial | partial | partial | partial | partial | partial | partial | planned | partial | planned | Every major capability needs a real visual: capability heatmap, profile curve, parity plot, missingness heatmap, structural visual, and runtime-plus-CI plot where relevant. |
| ADEMP and comparator program | partial | planned | partial | partial | planned | planned | partial | partial | partial | planned | Binomial fixed-effect parity, fixed-effect Wald interval calibration, the first fixed-effect `log(sigma)` clamp sensitivity pilot, the first scale-side phylogenetic clamp-active diagnostic, the first fixed-effect bivariate `sigma1`/`sigma2` clamp-sensitivity diagnostic, the larger fixed-effect bivariate `sigma1`/`sigma2` clamp diagnostic, the first Student-t finite-variance diagnostic pilot, the first Student-t Wald calibration diagnostic, the first Student-t profile/bootstrap feasibility diagnostic, the Student-t profile/bootstrap diagnostic pilot, the Student-t profile/bootstrap calibration diagnostic, the Student-t profile-failure decision audit, the skew-normal diagnostic pilot, skew-normal tail-floor source and fit-stress diagnostics, the fixed-effect skew-normal guard grid, the beta/zero-one beta support-floor diagnostic, the residual `rho12` open-interval diagnostic, the q2 `mu`/`sigma` covariance boundary diagnostic, the ordinary q2 correlation-grid diagnostic, the larger ordinary q2 covariance hardening diagnostic, the structured q2 boundary diagnostic, the numerical-guard ADEMP design, the structured-RE q1/q2/q4 ADEMP coverage-design rows, the SR142-SR149 coverage-calibration scaffold/accounting rows, and q8 staged diagnostic artifact plus endpoint-status hardening are banked as native R/TMB diagnostic evidence; direct DRM.jl smoke evidence and Julia-via-R clean-main bridge-test evidence are also banked as companion evidence; broader operating-characteristic simulations, calibrated interval coverage, q8 coverage/power, row-specific bridge parity, and release-readiness evidence remain partial or planned. |
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
- `drmTMB#547` fixed q4 Julia REML option forwarding. SEPARATELY, the native TMB
  path now DOES provide a Gaussian REML estimator (v0.2.0+, branch
  `drmtmb/biv-scale-side-reml`): admitted + recovery-validated cells are mean-side
  phylo, q2 matched mean+scale phylo, direct-SD phylo scale (`sd_phylo*() ~ x`),
  the block-diagonal bivariate location-scale layout, and ordinary sigma random
  effects (univariate intercept/slope/correlated + a bivariate labelled scale-side
  block). The scale-side REML is real, not a phantom row. Authoritative ML-vs-REML
  coverage: `docs/dev-log/ml-reml-coverage-2026-07-07.md`. Still gated (planned):
  DENSE q4, bivariate `mu`-`sigma` RE correlations, q > 2 scale blocks, and
  labelled or cross-formula correlated residual-scale slopes. Unlabelled
  ordinary correlated `sigma` blocks are fitted. REML debiases scale-side variance components
  only with adequate within-group replication (the ladders quantify the floor).
  Speed and full q4 inference validation remain separate evidence slices.
- AI-REML wording belongs only to exact Gaussian REML/MME derivations. For
  Laplace and non-Gaussian distributional models, use the actual method name.
- Speed claims require point estimate, objective/log-likelihood, CI/status,
  convergence, failure count, thread, memory, version, and dirty-state evidence.
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
