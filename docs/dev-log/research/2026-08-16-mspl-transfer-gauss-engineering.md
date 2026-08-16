# MSPL to boundary conditions — the engineering map

Read-only. Worktree `.worktrees/cran-07`, branch `claude/07-freeze-3-evidence`. No code changed.

**Headline: a variance-boundary penalty for one block already ships inside MSPL.**
`use_mspl == 1` in `src/drmTMB.cpp:4963-5059` already adds a negative-Huber penalty
(Sterzinger & Kosmidis 2023 eq. 5) on `log_sd_mu`/`eta_cor_mu` for the binomial `mu`
q1/q2 ordinary random-effect block (`:5018-5041`, R mirror `R/mspl.R:245-262,379-397`).
"Generalising to boundary conditions" is not a new mechanism to invent — it is fencing
that already exists for one family x one block shape, and the question is how far the
fence moves.

## 1. Existing MSPL plumbing

- **Entry**: `drm_match_estimator()` (`R/mspl-estimator.R:5-13`), `drm_is_mspl()` (`:15-20`).
- **Admission gate**: `drm_validate_mspl_request()` (`:166-231`) — binomial +
  `{logit, probit, cloglog}` only (`:190-207`), rejects `REML=TRUE` (`:209-213`), a
  non-NULL `penalty` (`:214-218`), `mi()`/missing-response (`:219-225`),
  `sparse_fixed`/`aggregate_gaussian` (`:226-231`). `drm_validate_mspl_spec()`
  (`:255-329`) requires dense full-rank `X`, finite offsets, positive-integer
  frequency weights/trials, and exactly one ordinary q1 or correlated q2 block
  (`:298-308`) — no q>=3, no structured/phylo/spatial/animal/relmat terms.
- **Objective wiring**: `spec$tmb_data$use_mspl/mspl_c_n/mspl_q` set at
  `R/drmTMB.R:1053-1107`; the single `use_mspl==1` block in
  `src/drmTMB.cpp:4963-5059` computes the fixed-effect Jeffreys term (`:4969-5017`)
  plus the variance-Huber term (`:5018-5041`), sums into `nll` (`:5043-5047`), and
  `REPORT()`s every component (`:5048-5059`).
- **Fit-time diagnostics**: Wald covariance from the *unpenalized* Hessian only
  (`drm_mspl_wald`, `:326-524`, design doc 251 sec 2 warns explicitly against using
  the penalized Hessian, `:344-347`), SPD gate + NA fallback (`:44-59`), separation
  detector via `detectseparation` (`:590-628`).
- **Inference fence**: `drm_abort_mspl_inference()` (`:26-36`) hard-blocks `logLik`,
  `confint`, `profile`, `anova`, `summary(conf.int=TRUE)` — called from
  `R/methods.R:2612,2658,2707,4158` and `R/profile.R:420,781`. Point estimates, point
  predictions, Wald SEs on `beta_mu` are the whole supported surface (design doc 250).

**Reusable for a variance penalty on other blocks**: `drm_mspl_negative_huber<Type>`
(`src/drmTMB.cpp:77-85`, R mirror `R/mspl.R:247-256`) is already parameter-agnostic —
a scalar Cholesky-log-coordinate goes in, a bounded penalty comes out. The
Wald-from-unpenalized-Hessian pattern (`:412-524`) is also block-agnostic. The
admission-gate *pattern* (dispatcher + explicit rejection list + `mspl` sub-list on
the fit) transfers directly.

**Separation-specific, not reusable**: the fixed-effect Jeffreys term (eq. 4) is a
GLM-link fixed-effect-information property with no role in a variance-only penalty —
a boundary-only variant drops `P_f` entirely. The q1/q2 Cholesky map
(`log_sd_mu(0)`, `log_sd_mu(1)+log_sech`, `L21`, `:5022-5041`) is hand-derived per `q`
and does not extend past q=2 without rewriting for the general
`qgt2_corr_parameterization` path used elsewhere.

## 2. The variance-component parameter surface

Declared TMB parameters (`src/drmTMB.cpp:481-504`):

| Class | Parameter(s) | Penalty status | Generic vs per-block |
| --- | --- | --- | --- |
| `mu` ordinary RE (q1/q2) | `log_sd_mu`, `eta_cor_mu` | **already penalized** under `use_mspl` (`:5018-5041`) | per-block (hand-derived q1/q2 map) |
| `sigma` ordinary RE | `log_sd_sigma`, `eta_cor_sigma` | not touched | needs a near-duplicate q1/q2 map unless refactored into a shared helper |
| `zoi`/`coi` RE | `log_sd_zoi`, `log_sd_coi` | not touched | same shape as `sigma` |
| general/structured RE (q>=3, multi-group) | `log_sd_re_cov`, `theta_re_cov` | not touched; correlation is `qgt2_corr_parameterization` (angles/onion-peel), not `tanh(eta)` | needs a genuinely different routine, not a q1/q2 copy |
| phylo axis 1 | `log_sd_phylo`, `theta_phylo`, `eta_cor_phylo` | **a different penalty exists here** — see §3 | precedent for *a* penalty, not for *this* penalty |
| phylo axis 2 | `log_sd_phylo2` | none | — |
| animal/relmat/spatial | reuse `log_sd_re_cov`/`log_sd_phylo`-style params via structure-provider machinery | none | inherits the general-block answer above |
| bivariate `rho12` | `eta`-parameterised, `tanh(eta)` | not a variance component; boundary is `eta`, not `log_sd` | separate design decision from "sd -> 0" |
| MI random effects | `log_sd_mi_group`, `log_sd_mi_struct` | excluded by the admission gate (`R/mspl-estimator.R:219-225` rejects `mi()`) | out of scope, not merely unimplemented |

**One generic penalty function?** Partially. `drm_mspl_negative_huber<Type>(x)` already
works unchanged as `sum_k D(coord_k)`. What is not generic is the map from a block's
native parameterisation to those scalar coordinates: q1/q2 uses `tanh`+`log_sech`;
q>=3/structured uses `qgt2_corr_parameterization`; phylo uses its own split. A single
dispatcher is architecturally plausible but each branch needs independent symbolic
derivation and a simulation study — one switch statement wrapping N separately
justified penalty forms, not one derivation.

## 3. The `drm_phylo_penalty` precedent and the REML exclusion

`drm_phylo_penalty_value()` (`src/drmTMB.cpp:92-125`) is a genuine Bayesian MAP prior
(exponential rate on `exp(log_sd_phylo)`, normal on the correlation coordinate) — a
**different penalty family** from MSPL's hyperparameter-free negative-Huber. Switched
via `penalty` (`R/drmTMB.R:305,588`), reported as `fit$phylo_penalty`
(`:650-654,692`), labels the fit `"MAP"` (`:178-182`, doc `172-phylo-penalized-map.md`).

**REML exclusion**: `isTRUE(REML) && !is.null(penalty)` hard-aborts
(`R/drmTMB.R:372-378`): "a penalized fit is a MAP estimator and REML is a
restricted-likelihood estimator; they are different estimators of the variance
components." MSPL independently re-derives the same exclusion against both `REML`
(`R/mspl-estimator.R:209-213`) and `penalty` (`:214-218`) — **three pairwise-exclusive
variance-component estimators already exist (ML, MAP-via-`penalty`, MSPL), and REML is
excluded from two of the three.**

**Implication for penalized-REML MSPL**: not a small extension — a fourth estimator
with no precedent here. Combining MSPL's variance bonus with Cox-Reid REML
(`R/aghq-coxreid.R`) requires deciding whether the restricted-likelihood correction is
computed on the penalized or unpenalized objective; design doc 251 already flags mixing
the penalty's curvature into an inference quantity as "exactly the sign bug... easiest
to get backwards" (`R/mspl-estimator.R:344-347`) for the simpler Wald case. That's a
math design question first, not an engineering task.

## 4. Cost of a minimal viable slice (`mu` iid-intercept `log_sd`, non-binomial)

Narrower than what ships today (current penalty already covers `log_sd_mu` q1/q2, but
only inside binomial's `use_mspl` leaf). A minimal slice extending it to e.g. Gaussian
`mu` iid intercept (the A1/D-117 cell) would touch:

- `src/drmTMB.cpp`: extract the q1 case of `:5018-5041` into a family-agnostic helper
  reachable outside binomial's `model_type`-specific leaf — ~30-50 LOC, plus moving the
  guard so it can see `log_sd_mu` regardless of `model_type`.
- `R/drmTMB.R`: a validation branch parallel to `drm_validate_mspl_request()` plus flag
  wiring near `:1053-1107` — ~40-80 LOC.
- `R/mspl-estimator.R` or a sibling: admission gate scoped to "one q1 `mu` block, any
  admitted family," a finalizer mirroring `:557-652` (much of `numerical`/`wald`/
  `boundary` is already generic) — ~60-120 LOC.
- A simulation/coverage test (AGENTS.md: "every likelihood change needs simulation
  tests"), comparable in shape to the 2026-08-09 D-117 campaigns — dominant cost, not
  the diff size. Note: the D-117 fitting harness itself lives on Totoro, not in this
  repo tree (only its scorer/outputs are checked in under
  `docs/dev-log/simulation-artifacts/2026-08-09-d117-100k-regate/`), so "pass one
  argument to the existing harness" could not be verified from the repo alone.
- A design-doc update: doc 250 is scoped to "binomial-logit" in its own title.

**Total estimate**: ~150-250 LOC across 3 files — small in compiler terms. **Hardest
part is not the code**: `mspl_c_n()`'s softness scale `2*sqrt(p/n_eff)`
(`R/mspl-estimator.R:317-319`) and `objective_identity_error`
(`:588-590`) both assume the fixed-effect Jeffreys term and the variance-Huber term
share one binomial-trial-derived `n_eff`. A variance-only penalty for a non-binomial
family has no natural `n_eff` and no Jeffreys term to co-scale against — `c_n` needs
its own derivation and calibration study before the C++/R wiring can be written
correctly.

## 5. Interaction inventory

- **`profile`/`confint`**: N/A today by construction (`R/profile.R:420,781`). A
  boundary-penalty variant inherits the fence unless deliberately opened. If opened,
  profiling must use `use_mspl==1`'s penalized objective, not the `use_mspl=0` one used
  for Wald SEs (`:412-424`) — two different "the objective" concepts already coexist
  (`penalized_objective` vs `unpenalized_laplace_objective`, `:594-596`); profiling the
  unpenalized one would defeat the point of a boundary penalty.
- **`sdreport()`**: not called for MSPL at all — the Wald path deliberately bypasses it
  in favor of `optimHess()` on a second `use_mspl=0` object (`:412-424,495-524`).
- **Boundary-warning machinery** (`R/profile.R:1824-2029`, `profile.boundary`, class
  `drmTMB_profile_boundary_warning`): built for the unpenalized ML profile, where a
  boundary-hugging profile is a real signal. Under a working penalty the optimum is
  interior by construction, so `profile.boundary` should rarely fire — but since
  `profile()` is hard-blocked for MSPL, this is dead code for MSPL today, not a live
  interaction. Wiring it in later needs "boundary" re-derived on a penalized surface.
- **`bias_correct`**: no `mspl` references anywhere outside the MSPL files and their
  direct call sites — bias-correction paths do not branch on `drm_is_mspl()` at all;
  they are simply unreachable for MSPL fits today.
- **Capability ledger `estimator` column** (`tools/capability_ledger.py:731,1018,1095,
  2991,3012-3013,3656-3673`): observed enum is `{ML, REML, AI-REML}` — zero `MSPL`/
  `mspl` hits in the file. MSPL is entirely off-ledger today, consistent with design doc
  250's "Phase 3... not evidence the route is inference-ready" framing. Per the
  estimator-token lesson (a new token flips `planning_class()`'s branch at
  `:3012-3013` and the ML/REML route-pairing logic at `:3656-3673`), adding an
  `"MSPL"`/`"MSPL-boundary"` token would need a third `planning_class()` branch and an
  explicit cap in `widget_value()`'s tier matrix (`:3022-3026`) at `point_fit_recovery`
  or below, given the hard confint/profile/logLik fence — the tier the binomial route
  sits at implicitly today by being absent rather than explicitly capped. Adding the
  token without the cap would silently let MSPL cells inherit the ML/REML branch's
  logic, which is wrong for a route that cannot report `logLik()`.

## Reply summary

feasibility: **medium**. Small LOC diff for one new q1/family slice; medium overall
because `c_n`/objective-identity semantics need a genuine family-general redefinition
before any flag can be wired, and every downstream consumer (profile, sdreport,
boundary warnings, bias_correct, the ledger's `estimator` enum) currently assumes
"MSPL" means "binomial fixed-effect Jeffreys + q1/q2 mu variance term," not "any
penalized variance component."

hardest problem: **`mspl_c_n()`'s common softness scale is derived from `p` and a
binomial trial-weighted `n_eff` and is co-scaled with the fixed-effect Jeffreys term
via `objective_identity_error`; a variance-only penalty for a non-binomial family or a
non-`mu` block has neither a natural `n_eff` nor a Jeffreys term to check against, so
`c_n` cannot be reused as-is — it needs its own symbolic derivation and softness
calibration per block class before the otherwise-mechanical C++/R wiring is even
correct, let alone tested.**
