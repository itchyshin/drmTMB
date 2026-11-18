🎯 GOAL

```text
Solo platform: Codex; isolated temporal planning lane, Astra high, PLAN ONLY.
Deliverable: an approval-ready Gaussian temporal AR1 plan, acceptance ledger, and handover.
HEADLINE: estimate temporal persistence and process SD while retaining residual sigma.
IN PARALLEL: bounded source-map recon alongside mathematical design; completed read-only.
DEFER: OU implementation; every wider family, predictor, engine, and inference extension.
DISCIPLINE: verify=source-grounded plan audit; compute=none now; closure=local artifacts then STOP.
```

# Gaussian temporal provider: proposed implementation contract

Status: **AWAITING USER APPROVAL**. This is a design proposal, not implemented capability.
The [Ultra Plan + Unlazy execution supplement](unlazy/README.md) now supplies
command-backed gate templates, named test cases, exact leaf ownership and final
re-verification. Its test-file subdivision supersedes the three broad proposed
test filenames below; the mathematical scope and original G0–G15 requirements stay
the same. The JSON file is the requirements map, not an executable completion proof.
Reader: the fresh Terra medium/high implementer and an applied scientist approving the model.
Base: `1ae582c9fc9060071bb147ea4aa7206744392419`, equal to locally recorded `origin/main`
on 2026-09-08; no fetch or claim about the current remote tip. Planning branch:
`codex/temporal-ar1-plan-20260908`. Root:
`/Users/z3437171/.codex/worktrees/f6e8/drmTMB`.

## 1. What is already known and what was requested

The user selected a first-class temporal provider alongside ordinary/none,
phylogenetic, spatial, and kernel/relatedness structures, with this first fit:

```r
drmTMB(
  bf(y ~ x + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
  data = dat, family = gaussian(), REML = FALSE
)
```

Here location means the conditional mean; residual scale means the measurement/noise
SD `sigma`. An animal followed across occasions can deviate persistently from its
predicted mean without treating its measurement errors as the persistent process.

Prior discussion already selected separate drmTMB and gllvmTMB slices, AR1 before OU,
and a retained residual SD. Brain retrieval on 2026-09-08 (`search_notes`, all projects,
query `temporal autocorrelation drmTMB`) recovered the 2026-08-31 planning note.
Deterministic `rg -n -i 'temporal|autocorr'` over the hub AGENT_LOG, DECISIONS and
OPEN_QUESTIONS produced no additional model decision (one unrelated provenance hit).
Local branch names, `git log --all --grep='temporal\|autocorr\|AR1'`, and
`rg -n 'temporal|autocorr|AR1' R src tests/testthat docs/design` did not identify an
existing temporal implementation. These are bounded searches, not proof about all
uncommitted foreign work. The sister-package proposal remains separate; no sibling
checkout or Julia/bridge path was changed.

Primary precedents checked: [glmmTMB covariance vignette](https://cran.r-project.org/web/packages/glmmTMB/vignettes/covstruct.html)
documents AR1 on unit-spaced levels, OU on coordinates, independent groups sharing
covariance parameters, and a separate measurement error. Its warning about a short
series motivates replicated fixtures. [TMB AR1 documentation](https://kaskr.github.io/adcomp/classdensity_1_1AR1__t.html)
provides the standard stationary Markov-density precedent. This plan derives the
gap-aware transition below; it does not copy a generic parser or claim novelty.

## 2. Preserve the provider map

| Provider | Existing/proposed formula and covariance source | What stays unchanged |
| --- | --- | --- |
| Ordinary / none | Existing `(1 | id)` has independent group levels; a fixed-only formula has no random field. `none` is a conceptual dependence category, not a proposed `none()` function. | Ordinary intercept/slopes, covariance labels, `sd(group)` and absence of random effects retain their meanings. |
| Phylogenetic | `phylo(1 | species, tree = tree)`; phylogenetic covariance/precision. | Existing tree construction, supported endpoints and phylogenetic interaction grammar. |
| Spatial | `spatial(1 | site, coords = coords)` and the separate existing mesh route. | Coordinate/mesh construction, fixed-range rules and existing admission boundaries. |
| Temporal (new) | `temporal(1 | id, time = occasion, structure = "ar1")`; learned stationary correlation across occasions within a series. | Adds one additive structured marker to the existing grammar; does not reinterpret `(1 | id)` as time dependence. |
| Kernel / relatedness | `relmat(1 | line, K = K)` or `Q = Q`; `animal()` is the existing pedigree relative. | Known matrix validation and scaling; no new `kernel()` alias, no learned temporal process through `meta_V(V = V)` or fixed `Q`. |

`R/parse-formula.R:714` enumerates existing structured markers. `R/drmTMB.R:13904`
dispatches their builders; several historical generic fields are named `phylo_mu`
even for spatial/relatedness providers. Preserve those fields and all old paths.
Do not rewrite the provider registry, distributional grammar, `rho12`, or sd/corpair
syntax. Temporal phi is a process parameter, not bivariate residual correlation.

## 3. Symbolic model first

For series i, observed integer occasions t_ij, and j in increasing time order:

\[
y_{ij}=x_{ij}^{T}\beta+a_{ij}+\epsilon_{ij},\qquad
\epsilon_{ij}\stackrel{ind}{\sim}N(0,\sigma^2),\qquad a_{ij}=s_a u_{ij},
\]
\[
u_{i1}\sim N(0,1),\quad
u_{ij}\mid u_{i,j-1}\sim N(c_{ij}u_{i,j-1},1-c_{ij}^2),\quad
c_{ij}=\phi^{d_{ij}},\ d_{ij}=t_{ij}-t_{i,j-1}>0.
\]

Different series, innovations and residual errors are independent. Shared scalars
are `s_a = exp(log_sd_temporal) > 0`, `sigma = exp(beta_sigma[1]) > 0`, and
`phi = tanh(theta_temporal)` in (-1,1). `s_a` is the **stationary marginal process
SD**, not the innovation SD `s_a * sqrt(1 - phi^2)`. Do not constrain or centre
realised fields to sum to zero. `u` is correlated with unit marginal variance;
it is not a vector of independent standard-normal innovations.

Consequently `Cov(a_ij,a_ik) = s_a^2 * phi^abs(t_ij-t_ik)` and the observed block
covariance is `V_i = s_a^2 R_i(phi) + sigma^2 I`. The exact marginal ML negative
log-likelihood is the sum over series of
`0.5 * [n_i log(2*pi) + logdet(V_i) + r_i' solve(V_i,r_i)]`, with `r_i=y_i-X_i beta`.
For Gaussian responses the latent Gaussian integral is exact under Laplace
integration, up to numerical solution tolerance. Use this identity as the oracle.

For integer gaps the transition above integrates out unobserved intermediate states.
Never compress times to consecutive observed ranks and never insert fake responses.
Negative phi is supported. Use integer multiplication/exponentiation in templated
code, including at phi=0; do not use `exp(d * log(phi))`. Keep normalising constants,
including the first-state density and each transition variance. Avoid a variance
floor that silently changes the model near |phi|=1; diagnose nonfinite transformed
endpoints, and test finite values such as ±0.95 separately from exact boundaries.

At phi=0, `V_i=(s_a^2+sigma^2) I`. This is equivalent to an iid Gaussian with
SD `sqrt(s_a^2+sigma^2)`, **not** to an ordinary series random intercept. Separate
SD recovery at phi=0 is impossible. If all within-series gaps are even, the sign of
phi is also unidentified. A lone lag length cannot generally identify both SDs
and persistence. Reject a design without any odd lag, or without at least two
distinct positive within-series lag distances; allow short individual series when
the pooled design meets these conditions. Warn that passing this necessary check
does not establish strong identification. One long series is allowed; singletons
contribute only diagonal variance information. Constant responses and nearly zero
process SD remain numerical/identification diagnostics, not silently repaired data.

### Symbolic-alignment table (all names below are proposed)

| Symbol | API / formula | TMB data / parameter | DGP | Recovery / extractor | Required test |
| --- | --- | --- | --- | --- | --- |
| X beta | `y ~ x + temporal(...)` | existing `X_mu`, `beta_mu` | fixed X; beta=(0.3,0.7) | existing `fixef(fit, "mu")` | dense identity; slope/intercept recovery |
| sigma | `sigma ~ 1` | existing `X_sigma`, `beta_sigma` | independent N(0,0.4²) residuals | `predict(fit,dpar="sigma")` | residual vs process label; recovery |
| s_a | intercept amplitude in `temporal(1 | id,...)` | scalar-length `log_sd_temporal` | multiply u by 0.8 | `fit$sdpars$temporal_mu`, named full term | stationary SD/innovation SD distinction; recovery |
| phi | `structure="ar1"`; one shared scalar, no phi formula | scalar-length `theta_temporal`; report `tanh(theta_temporal)` | phi=0.6 or -0.6 | `fit$corpars$temporal`, named `phi`; metadata calls this lag-one process correlation | sign, transform, gradients, recovery |
| u, a | one latent node per retained id/occasion | `u_temporal`; zero-based row-to-node index; add s_a*u to mu | independent stationary starts and gap transitions per series | `ranef(fit,"temporal_mu")$latent` = standardized correlated u; `$values` = a; id/time node table | conditional modes vs dense BLUP; permutation |
| i, t, d | `id`, `time=occasion` bare data-column names | start offsets, positive integer gaps, observation-node index; no fitted Q as data | fixed unbalanced series layout | `structured_effects(fit)` plus temporal block's `nodes` (series, occasion, node_index) | independent blocks, gaps, missingness, malformed inputs |
| alpha (future) | `structure="ou"` rejected now | future `log_rate_temporal`, alpha=exp(.) | future c=exp(-alpha*delta) | future positive rate, same s_a interpretation | analytic reference correspondence only now |

## 4. Admission and data contract

Admit exactly one intercept-only, unlabelled temporal term on **univariate Gaussian
mu**, fixed-effect mean regressors and optional existing mean offset, constant
`sigma ~ 1`, default native TMB ML. No other random/structured term in the same fit
in this slice. Explicitly reject slopes, labels, multiple temporal terms, process-SD
regression, phi regression/random phi, temporal scale/shape/zero-inflation terms,
non-Gaussian/bivariate fits, REML, `meta_V`, imputation, response aggregation,
non-unit weights and alternative engines. Existing fits without temporal retain
their present admission rules. These exclusions bound interaction validation, not
theoretical impossibility; the Gaussian integral provides a decisive first oracle.

`time` must name a finite numeric/integer data column on a unit grid. Require
integer-valued values within R's safe integer range and differences representable
as positive integers. Accept zero/negative origins; require no global common origin.
Reject factors, strings, Date/POSIXct, Inf/NaN, fractional times, missing series IDs
or missing times with offending rows named. Explain how to construct meaningful
integer occasions; do not suggest ranking irregular observations. Reject unknown
arguments/structures and nested/non-additive markers. The literal default is `"ar1"`.

Validate duplicate `(id,occasion)` keys and missing/nonfinite ID/time metadata before
response omission, including duplicates involving an NA response. The first slice
does not support replicate measurements at a single latent occasion. Same occasion
in different series is valid. Stable sort nodes by series and numeric time; preserve
the original observation-row order throughout X, y, outputs, and `na.action`.

Use the package's existing listwise response/fixed-covariate omission policy for
otherwise valid rows; no missing-response likelihood or imputation extension.
Omitted rows leave true elapsed gaps. Drop resulting empty series from the latent
layout and report counts; retain singleton series; reject zero usable rows and
pooled designs failing the lag checks above. Store original/retained row mapping,
nodes, series start offsets and gaps; unit-test `na.omit`/`na.exclude` reconstruction
against the existing package convention before documenting an exact returned length.

## 5. Native implementation boundary and user outputs

**Decision:** add a dedicated `spec$structured$temporal_mu` plus compact temporal
TMB data/parameters, through the existing additive marker/parser mechanism. Reuse
fixed-effect/residual construction and generic random-effect output conventions.
Do not rename existing `phylo_mu` internals. The source scout identified reuse of
`Q_phylo` as possible for a *fixed* phi. That is insufficient here: phi is estimated,
so computing Q once in R would freeze the parameter and invalidate its gradients.

Assert temporal fits have `spec$structured$temporal_mu$has=TRUE` and
`spec$structured$phylo_mu$has=FALSE`. Reject all other random/structured layers
before spec construction. Never feed this field through `has_phylo_mu`, `u_phylo`,
`Q_phylo`, or the generic structured simulator, and never add it to mu twice.

New TMB data: `has_temporal_mu`, `temporal_series_start` (zero-based offsets plus
terminal offset), `temporal_gap` (one per noninitial state), and
`temporal_mu_node_index` (one per retained row). New parameter vectors:
`u_temporal`, `log_sd_temporal`, `theta_temporal`. Every TMB call path, including
probe model types, must supply `has_temporal_mu=0`, valid empty/dummy index/gap/offset
data and zero-length temporal parameter starts/maps when absent. Unconditional TMB
declarations cannot rely on a later family branch to hide missing inputs. These
defaults must add **no** free parameters to any existing family. Evaluate
the normalized stationary Markov prior in C++, with phi on the AD tape, add
`exp(log_sd_temporal[0])*u_temporal[node]` only to Gaussian mu, and register only
`u_temporal` as the new Laplace random block. Disable Gaussian row aggregation for
this provider. Run two independent optimisation attempts starting at phi=±0.3,
using identical documented data-derived beta/SD starts and zero latent modes.
Do not start at the nonidentifiable zero-persistence split. Retain both attempts'
starts, objective, convergence code, gradient, warnings and timings. Select the
lowest finite marginal objective, with exact ties going to the +0.3 start; reconstruct
the chosen opt/obj/parList/reports together and test that they refer to that attempt.
Neither nonconvergence nor failed starts disappear from diagnostics. If no attempt
is finite, return an informative fitting failure. A chosen nonconverged attempt
retains the package's unsuccessful-fit warning/status. This is one likelihood with
two numerical starts, not a changed estimator.

Construct a fitted temporal covariance/precision summary in R only **after** fitting
for metadata or draws. It must not become the likelihood's fixed input. Prefer a
dedicated stationary recursion for marginal `simulate()` so both production paths
can be compared with an independent dense-Cholesky reference. Preserve the existing
semantics: `simulate(re.form=NULL)` draws fresh process and residuals;
`simulate(re.form=NA)` holds fitted process modes fixed and draws residuals.

Return named SD and phi slots from the table, structured metadata (`type=temporal`,
`structure=ar1`, unit, series/time columns, n_series/n_nodes and ordering counts),
and a `temporal_mu` random-effects block. `REPORT` the standardized state
`u_temporal`, transformed `sd_temporal` and `phi_temporal`, and its mu contribution;
retain fitted log-SD/theta in the parameter list. `sdpars$temporal_mu` is a named
length-one vector keyed by the full temporal term; `corpars$temporal[["phi"]]` is
the scalar transformed phi. `random_effects$temporal_mu$latent=u_temporal`,
`$values=sd_temporal*u_temporal`, and `$nodes` is the sorted series/time/node table.
Use ADREPORT only for clearly labelled diagnostic uncertainty if needed by the
existing fit machinery; it does not enable public intervals or calibrated inference.
Explicitly document that its `latent`
values are correlated standardized states. There is no existing package VarCorr
method to extend; do not promise `VarCorr()` or introduce a new extractor family.
In-sample `predict`/`fitted` include a. Support in-sample point predictions and
residuals. Reject **every** `predict(newdata=...)` call on temporal fits in this slice,
including a copy of the training data, with an informative temporal-prediction error.
Current predict has no `re.form` selector and silently omits structured effects for
newdata; do not inherit that ambiguity. Population newdata prediction, interpolation
and forecasting need a separate explicit contract.

Fitted objects must not silently advertise interval, bootstrap, repeatability,
phylogenetic-signal or predictive-SE support for temporal fits. Audit every public
entry point and add fail-closed admission using existing target/readiness machinery
where possible. If that requires edits owned by the interval/bootstrap/repeatability
lane (especially `R/profile.R` or owned parts of `R/methods.R`), return the exact
guard diff for owner coordination; do not bypass the ownership gate or ship silent
fallbacks. No interval/coverage claim follows from this point-fit slice.

S0 must turn this entry-point table into an exact guard-location/owner receipt:

| Entry point | Temporal first-slice contract | Guard file / ownership |
| --- | --- | --- |
| `predict`, `fitted`, `residuals` | In-sample points; reject newdata and quantile/predictive-uncertainty routes | `R/methods.R`, temporal executor only after shared-file lease |
| `simulate` | Dedicated temporal recursion for NULL; fixed modes for NA | `R/methods.R`, `R/temporal.R`; never fall through to generic structured draws |
| `summary`, `print` | Point coefficients/SD/phi and diagnostics; no misleading derived repeatability rows; reject `conf.int=TRUE` | `R/methods.R`; coordinate repeatability-owned portions |
| `corpairs` | Reject for this fit; temporal phi is not a coefficient-pair correlation | `R/methods.R`; do not enter profile-target lookup |
| `confint` (wald/profile/bootstrap), `profile`, `profile_targets` | Refuse inference calls; targets absent or explicitly not ready | `R/profile.R`, protected interval/bootstrap owner; required owner-coordinated guard if readiness alone is insufficient |
| `vcov` and default inferential tables | Explicitly refuse unsupported output rather than omit temporal parameters | `R/methods.R`, shared owner coordination; retain internal optimizer/Hessian diagnostics |

These are admission guards, not authorisation to implement interval, bootstrap or
repeatability methods. Every refused route gets an error test, every supported
route an identity test, before the temporal fit becomes user-visible.

## 6. OU compatibility without OU implementation

For future finite real times, `c(delta)=exp(-alpha*delta)`, alpha>0, with stationary
SD s_a and transition variance `1-c²`. On a regular grid with spacing h,
`phi=exp(-alpha*h)` gives exactly the same R and observed V. The correspondence
holds only for 0<phi<1: phi=0 is a limit, and negative AR1 persistence has no such
OU representation. Keep this kernel contract and metadata names compatible, but
reject `structure="ou"` with a clear planned/not-supported message now. The OU
acceptance test evaluates an independent mathematical reference, not an OU fit.

## 7. Proposed files, not edits made by this task

| Slice | Exact proposed files | Integration purpose and boundary |
| --- | --- | --- |
| Parser + layout | new `R/temporal.R`; `R/parse-formula.R` | Export marker/roxygen and internal temporal validator/layout; add only marker registration and argument dispatch (`:683–734`). Preserve common bar grammar. |
| Native fit | `R/drmTMB.R`; `src/drmTMB.cpp`; new `src/temporal-ar1.hpp` | Gaussian builder (`R:4283–4497`), admission helpers (`R:12620`), start/maps, data defaults (`R:20468`), parameter splitting (`R:22153,22331`), dynamic normalized prior and mean contribution. Existing generic provider dispatcher is `R:13904`; no old-provider refactor. |
| Outputs | `R/methods.R`; `R/check.R`; `R/temporal.R` | Structured metadata (`methods:183`), ranef (`:166`), prediction (`:2821`), simulate (`:2982,6336`), diagnostics and explicit unsupported surfaces. Shared-file ownership must be resolved first. |
| Guard contingency | `R/profile.R` only if existing readiness metadata cannot block unsupported calls | Coordinate a minimal refusal/target-readiness patch with its owner. No interval/bootstrap implementation or unilateral edit. If unavailable, execution remains incomplete at this gate. |
| Tests | new `tests/testthat/test-temporal-parser.R`, `test-temporal-gaussian.R`, `test-temporal-methods.R`, `helper-temporal-reference.R` | Pure parsing/layout; independent dense oracle/gradients; fits, outputs, simulation and exclusions. Reuse testing style from `test-spatial-gaussian.R`, `test-phylo-gaussian.R`, `test-simulate-re-form.R`; do not copy their DGP blindly. |
| Recovery | new `inst/validation/temporal-ar1-recovery.R` | Bounded, explicitly invoked replicated fixture; fixed seeds and retained attempt-level results. Not an automatic CRAN campaign. |
| Docs/generated | `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, `vignettes/formula-grammar.Rmd`, new `vignettes/temporal-correlation.Rmd`, `README.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`, `docs/dev-log/internal-roadmap.md`, `_pkgdown.yml`; generated `NAMESPACE`, `man/temporal.Rd`, changed method Rd files | New provider, decomposition, supported example, SD/phi interpretation and explicit limits. Render reference/article and inspect figures before publication claims. No deployment in this approval envelope. |
| Evidence/closure | `docs/dev-log/check-log.md`, new dated after-task report, this lane's `acceptance.json`; `inst/COPYRIGHTS` only if code is ported | Record exact source/tests/limitations. Lease shared paths after approval, before any edit. |

## 8. Acceptance and small recovery fixtures

The companion [acceptance.json](acceptance.json) distinguishes plan checks from
unrun execution gates. No gate is passed by existence of a file alone.

1. **Fixed-parameter identity:** use independently formed dense `V_i` and base-R
   Cholesky NLL, not the production recursion. Include unbalanced series of 3,4,5
   occasions, shuffled rows, missing occasions, phi in {-0.6,0,0.6,±0.95}, s_a=0.8,
   sigma=0.4, beta=(0.3,0.7). Compare normalized *marginal* ML NLL, not joint latent
   NLL, at every point. Target absolute error <=1e-7*(1+abs(reference NLL)); compare
   AD gradients with central finite differences (two step sizes) within 1e-5 scaled
   tolerance. A failure is investigated, not hidden by dropping constants.
2. **Reductions:** phi=0 agrees with iid total SD; prior-only fixed-parameter
   singleton and two-node probes have correct normalisation despite fitting-design
   rejection. Future OU reference agrees on regular and integer-gapped grids at
   positive phi (max covariance error <=1e-12); negatives excluded from correspondence.
3. **Independence/order:** full NLL equals sum of independent series NLLs with shared
   parameters; relabel and permute rows/series without changing likelihood or inverse-
   reordered output. Dense covariance has zero off-series entries. Splitting a
   genuinely connected series must change NLL. Gap [1,3] uses phi², not phi.
4. **Malformed/missingness:** assert messages and parsed fields, not only class;
   duplicates, ID/time NA, factors/dates/fractional/infinite times, all-even gaps,
   insufficient lag design, empty rows, unsupported formula/product cells. Omission
   plus preserved gaps must agree with manual row removal in dense V.
5. **Outputs and simulation:** sigma and process SD/phi labels separate; conditional
   modes agree with `K solve(V,y-X beta)` and fitted values with X beta+a. Seed/RNG
   restoration and independent fresh-series draws follow existing semantics. Dense
   draw moments check marginal V; conditional draws check variance sigma². Include
   intentional mutations: rank-compressed gaps, shared initial state across series,
   dropped first-state normalizer and swapped process/innovation SD must fail tests.
6. **Replicated recovery (bounded fixture, not calibration campaign):** freeze six
   datasets, seeds 2026090801:2026090806, 50 independent series × 20 unit occasions,
   beta=(0.3,0.7), s_a=0.8, sigma=0.4; alternate phi=+0.6/-0.6 (three seeds each).
   Draw X independently from Uniform(-1,1); do not centre latent draws. Independent
   dense-Cholesky DGP. Estimate all five fixed covariance/mean parameters; preserve
   every start/failure. Require all six finite fits, correct phi sign, max absolute
   covariance-parameter error <=0.25, and per-sign mean absolute error <=0.15 for
   phi/s_a/sigma; mean beta error <=0.15. These are predeclared engineering thresholds,
   not nominal interval coverage. Report gradient/Hessian diagnostics alongside raw
   estimates; no post-hoc seed selection or tolerance relaxation. One additional
   shuffled/gapped deterministic fixture checks layout, not a new recovery cell.

## 9. Slices, routing, estimates and authority

Ultra Plan Phases 0–2 end here. D-251 in
`~/shinichi-brain/memory/MODEL-ROUTING.md:284–307` requires a **fresh Terra task**
after approval; changing the model in this Astra task is not a handover.

| Slice | Owner / model / effort | Depends on | Estimated wall time |
| --- | --- | --- | --- |
| RECON (this plan) | bounded explorer, Terra medium, native explicit | orientation | 5–10 min; completed read-only |
| S0 ownership refresh + freeze acceptance | Terra medium | user approval; exact shared-file leases | 15–30 min |
| S1 marker/layout and pure tests | Terra medium | S0 | 1–2 h |
| S2 native dynamic likelihood + dense identity | Terra high | S1 | 2–3 h |
| S3 extraction/prediction/simulation/guard tests | Terra high | S2; guard owner if needed | 1–2 h |
| S4 small recovery fixture + retained results | Terra medium | S2 identity, timing pre-run | 30–60 min including analysis; runtime below |
| S5 docs + generated/rendered output | Terra medium | S3; can overlap S4 on disjoint files | 1–2 h |
| MECHANICAL-VERIFY + RECONCILE | Terra medium; independent bounded review | S3–S5 | 30–60 min |

Implementation/validation estimate before final re-verification: **6–11 agent-hours**, roughly **5–10 elapsed
hours** with a disjoint documentation lane; ownership waits and toolchain repair
excluded. Estimates are planning hypotheses, not measured temporal performance.
Budget about **7–12 agent-hours** including the explicit final re-verification pass
in the Unlazy supplement.
Compile estimate 3–10 min; pure checks <1 min; dense identity <3 min; one fit pre-run
1–3 min; six-dataset/two-start recovery estimate 5–15 min serial after compile; targeted integration
suite 5–15 min; package check 10–30 min. The executor must announce/refine each run's
estimate before launching and stop/re-report an overrun. No fit or compilation ran here; the recovery estimate includes twelve optimisation attempts.

Use the Mac for pure checks and bounded fixtures (at most four workers/cores per
lane; `OPENBLAS_NUM_THREADS=1`, `OMP_NUM_THREADS=1`, `MKL_NUM_THREADS=1`,
`VECLIB_MAXIMUM_THREADS=1`). Load compute-routing at execution. Time one full fixture
first, inspect non-empty estimates and the dense identity, then estimate total.
If total recovery exceeds 30 min, pause that run for a separate pre-run-result and
target approval. Serious retained recovery/coverage uses a separately approved DRAC
array (Fir by default, live capacity checked); Totoro may rehearse a bounded case.
No campaign on GitHub Actions; no remote job is authorised by this plan.

Future fan-out budget: at most two disjoint build/review children after S0, Terra
medium/high with explicit routing; no extra Astra parent. RECON is already supplied;
repeat only source/lease drift checks. Mathematical or API contradictions go back to
the owner with a concrete revised choice. Mechanical checks stay with Terra because
they require the R toolchain and coupled artifact review. No D-43 completion panel
is claimed for this plan; execution must obtain the required independent reviews
once for its completed scope, under the then-current routing contract.

PRE-AUTHORISED AFTER APPROVAL AND S0: only scoped edits in an isolated worktree;
pure testthat tests, one compilation, dense-oracle and targeted integration tests,
the bounded timing/recovery fixtures above, `devtools::document()`, package checks,
local vignette/reference rendering, checkpoints and scoped local commits.
OPTIONAL REMOTE AUTHORITY: none. MUST STOP for owner overlap; changed estimand/API;
unavailable guard integration; >30-min recovery without separate approval; exhausted
estimate; external messages, GitHub/API login, push/merge/release/deployment.

## 10. Team-raised concerns and approval decision

The read-only Terra scout supplied source anchors and found no existing VarCorr
method. Its fixed-Q reuse suggestion would freeze learned phi; the plan therefore
chooses a dedicated dynamic TMB block. This is the planner's correction, not an
independent mathematical-review sign-off.

Fisher/Noether lenses (planner assessment): zero persistence confounds the two SDs,
even-only gaps lose the sign, and lag-one-only designs lack enough covariance
information. The recommendation is transparent data checks and fixed-parameter
identity at those limits, with recovery in an identifiable replicated design.
Rose/Pat lenses (planner assessment): generic methods can return plausible incomplete
answers when they omit a new field. The recommendation is explicit downstream tests
and refusals, with guard ownership resolved before execution claims completion.

**Ada's recommendation:** approve this Gaussian, native-ML, one-temporal-provider
slice with integer gaps and both signs of phi; defer OU and mixed-provider fits.
Decisions already supplied by the user: temporal provider, separate sigma, AR1 first,
OU later, plan-only now, fresh Terra execution. Proposed choices requiring approval:
the exact data rules, dedicated native block, bounded supported methods and estimates
above. No optional interview blocks writing these artifacts.

**Approval still open:** approve this plan for a fresh Terra medium/high task, subject
to S0 shared-file ownership. Suggested reply: “Approve this Gaussian AR1 plan; start
a fresh Terra high task and resolve the listed path leases before implementation.”
Until that approval, no execution or model runs. The new task must be explicitly
created/authorised; this planner stops after local closeout.
