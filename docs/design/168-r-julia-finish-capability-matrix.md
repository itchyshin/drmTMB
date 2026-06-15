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
| Dashboard and issue ledger | covered | partial | covered | unsupported | unsupported | unsupported | covered | covered | unsupported | partial | Keep `status.json`, `sweep.json`, check-log, and after-task notes synchronized with issues. |
| Master capability matrix | partial | partial | partial | partial | partial | partial | partial | planned | partial | partial | Wire README, ROADMAP, NEWS, pkgdown, Documenter, and dashboard claims to this matrix. |
| R-Julia bridge gate | partial | experimental | partial | planned | partial | partial | partial | planned | partial | planned | Keep `drmTMB#544` open, but finish the native R/TMB support-status harness first so the bridge is not the only usable path. |
| Gaussian phylogenetic SD target | partial | experimental | partial | partial | partial | partial | partial | planned | partial | planned | Promote only after native R, R-Julia bridge, and direct Julia point estimate plus CI/status parity are recorded in one row; use `drmTMB#555` for the Ayumi q4 status harness. |
| Random slopes | partial | planned | partial | partial | planned | planned | partial | planned | partial | planned | Fixed-effect likelihoods first, independent slopes second, correlated slopes third, structured slopes last. |
| Non-Gaussian models | partial | planned | partial | partial | planned | planned | partial | planned | partial | planned | Coefficient parity first; variance, correlation, and CI claims require their own recovery rows. |
| Bivariate residual correlation `rho12` | partial | planned | partial | partial | planned | planned | partial | planned | partial | planned | Keep residual `rho12` separate from group, phylogenetic, spatial, kernel, and cross-family correlations. |
| Mixed and cross-family correlation | planned | unsupported | planned | planned | planned | planned | planned | planned | planned | planned | Use `DRM.jl#280`-style recovery and bridge labels before user-facing promotion. |
| High-q correlations | partial | planned | partial | planned | planned | planned | partial | planned | partial | planned | q4 first, q8 second; higher q requires transform, gradient, recovery, and CI-status evidence. |
| Structural dependencies | partial | planned | partial | partial | planned | planned | partial | planned | partial | planned | Animal, phylo, relmat, spatial, kernel, and SPDE rows each need provenance, PSD/name-alignment tests, recovery, bridge parity, docs, and visuals. |
| Julia speedups | experimental | experimental | planned | planned | planned | planned | partial | planned | planned | planned | No speed headline without point-estimate and CI/status evidence. Benchmark native TMB, R-Julia bridge, and direct DRM.jl separately. |
| AI-REML-inspired algorithms | planned | unsupported | planned | planned | planned | planned | planned | unsupported | planned | planned | Borrow `hsquared` only as a design analogue for exact Gaussian MME cells; use observed-information, Fisher/natural-gradient, or AD-gradient methods for Laplace/non-Gaussian cells after derivation. |
| Missing values | partial | planned | planned | planned | planned | planned | planned | planned | planned | planned | Use likelihood/FIML-style masks. Complete-data all-true masks must match current complete-data log-likelihood exactly. |
| Visuals and articles | partial | partial | partial | partial | partial | partial | partial | planned | partial | planned | Every major capability needs a real visual: capability heatmap, profile curve, parity plot, missingness heatmap, structural visual, and runtime-plus-CI plot where relevant. |
| ADEMP and comparator program | partial | planned | partial | partial | planned | planned | partial | planned | partial | planned | Big simulations start only after smoke, parity, recovery, bridge, CI-status, and visual gates pass. |
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

## Dashboard Contract

The live dashboard is an operating surface, not a release claim. It should show
what is queued, active, blocked, verified, banked, and deferred. It should warn
when the checkout is detached or dirty and should never mark a row `verified`
without an evidence entry.

The durable dashboard source lives in `docs/dev-log/dashboard/`. The live copy
is served from `/tmp/drm-dashboard` at `http://127.0.0.1:8765/`.

## Claim Guards

- Current `engine = "julia"` examples use the default `DRM.jl` fitting path.
  They are not evidence that users can choose Julia-side algorithms from R.
- `pdHess = FALSE` blocks Wald promotion, but it does not automatically discard
  a useful point estimate.
- Profile and bootstrap intervals are target-specific. Endpoint parity for one
  Gaussian phylogenetic SD target does not promote fixed effects, non-Gaussian
  families, scale formulas, multiple structured terms, or neighbouring syntax.
- `drmTMB#547` fixes q4 Julia REML option forwarding only. Native
  `engine = "tmb"` is not a full REML fallback for Ayumi's bivariate q4
  phylogenetic location-scale model, and speed plus full q4 inference
  validation remain separate evidence slices.
- AI-REML wording belongs only to exact Gaussian REML/MME derivations. For
  Laplace and non-Gaussian distributional models, use the actual method name.
- Speed claims require point estimate, objective/log-likelihood, CI/status,
  convergence, failure count, thread, memory, version, and dirty-state evidence.

## First Work Order

1. Keep the dashboard live at `http://127.0.0.1:8765/`.
2. Finish the R-first Ayumi q4 support/status path in `drmTMB#555`: native TMB
   ML fit status, native REML rejection status, profile-target inventory,
   interval rows, warnings/messages/errors, and metadata.
3. Keep native `engine = "tmb"` useful for supported point-estimate,
   reduced-model, and ML profile-status checks before promising Julia speed.
4. Keep `drmTMB#544` active as the bridge-gate epic, but run it after the
   native R/TMB status path is visible and honest.
5. Add the shared CI-status vocabulary.
6. Promote the Gaussian phylogenetic SD profile/bootstrap target only after all
   point-estimate and interval-status evidence is in one matrix row.
7. Start missing values with observed-response masks and complete-data
   equivalence tests.
