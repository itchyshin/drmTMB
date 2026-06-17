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
| R-Julia bridge gate | partial | experimental | partial | planned | partial | partial | covered | covered | partial | planned | `drmTMB#544` is closed after the generated gate registry, capability comparison, docs-drift guard, and dashboard rendering landed. Future bridge work should open follow-on registry/parity issues before promoting any R-gated Julia-covered cell. |
| Gaussian phylogenetic SD target | partial | experimental | partial | partial | partial | partial | partial | planned | partial | planned | Native R/TMB now has q4 target inventory and endpoint-budget status rows, but promotion still waits for native R, R-Julia bridge, and direct Julia point estimate plus CI/status parity in one row; use `drmTMB#555` for the Ayumi q4 status harness. |
| Random slopes | partial | planned | partial | partial | planned | planned | partial | planned | partial | planned | Fixed-effect likelihoods first, independent slopes second, correlated slopes third, structured slopes last. |
| Non-Gaussian models | partial | planned | partial | partial | planned | planned | partial | planned | partial | planned | Coefficient parity first; variance, correlation, and CI claims require their own recovery rows. |
| Bernoulli/binomial response family | partial | unsupported | partial | covered | planned | unsupported | partial | planned | partial | planned | Fixed-effect `stats::binomial(link = "logit")` now fits 0/1 and `cbind(successes, failures)` responses and has `stats::glm()` parity plus a 500-replicate fixed-effect Wald interval artifact; bridge support, profile/bootstrap intervals, random effects, structured effects, headline coverage, and bivariate or mixed responses remain unavailable. |
| Bivariate residual correlation `rho12` | partial | planned | partial | partial | planned | planned | partial | planned | partial | planned | Keep residual `rho12` separate from group, phylogenetic, spatial, kernel, and cross-family correlations. |
| Mixed and cross-family correlation | planned | unsupported | planned | planned | planned | planned | planned | planned | planned | planned | Use `DRM.jl#280`-style recovery and bridge labels before user-facing promotion. |
| High-q correlations | partial | planned | partial | planned | planned | planned | partial | planned | partial | planned | q4 first, q8 second; higher q requires transform, gradient, recovery, and CI-status evidence. |
| Structural dependencies | partial | planned | partial | partial | planned | planned | partial | planned | partial | planned | Animal, phylo, relmat, spatial, kernel, and SPDE rows each need provenance, PSD/name-alignment tests, recovery, bridge parity, docs, and visuals. |
| Julia speedups | experimental | experimental | planned | planned | planned | planned | partial | planned | planned | planned | No speed headline without point-estimate and CI/status evidence. Benchmark native TMB, R-Julia bridge, and direct DRM.jl separately. |
| AI-REML-inspired algorithms | planned | unsupported | planned | planned | planned | planned | planned | unsupported | planned | planned | Borrow `hsquared` only as a design analogue for exact Gaussian MME cells; use observed-information, Fisher/natural-gradient, or AD-gradient methods for Laplace/non-Gaussian cells after derivation. |
| Missing values | partial | planned | planned | planned | planned | planned | planned | planned | planned | planned | Use likelihood/FIML-style masks. Complete-data all-true masks must match current complete-data log-likelihood exactly. |
| Visuals and articles | partial | partial | partial | partial | partial | partial | partial | planned | partial | planned | Every major capability needs a real visual: capability heatmap, profile curve, parity plot, missingness heatmap, structural visual, and runtime-plus-CI plot where relevant. |
| ADEMP and comparator program | partial | planned | partial | partial | planned | planned | partial | partial | partial | planned | Binomial fixed-effect parity, fixed-effect Wald interval calibration, the first fixed-effect `log(sigma)` clamp sensitivity pilot, the numerical-guard ADEMP design, skew-normal diagnostic pilot, and q8 staged diagnostic artifact are banked; broader guard-class simulations, q8 coverage/power, same-response hardening, bridge parity, and release-readiness evidence remain partial or planned. |
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
- Plain Bernoulli/binomial support means event-probability `mu` only. It is not
  beta-binomial overdispersion, beta/zero-one beta continuous-proportion
  modelling, binary missing-predictor imputation, random-effect binomial, or a
  Julia bridge claim.

## Post-#602 Work Order

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
6. Continue the broader numerical-guard programme beyond the fixed-effect
   `log(sigma)` pilot and the ADEMP design in
   `docs/design/176-numerical-guard-simulation-audit.md`: scale-side phylogeny,
   bivariate scale routes, support floors, Student-t shape restrictions,
   correlation guards, and interval consequences still need sensitivity
   evidence.
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
