# Controls, convergence, and the generalization principle

## Reader and purpose

For the next `drmTMB` contributor and reviewer. This note is the durable record
of (a) the **generalization-via-controls principle** the package follows, (b)
the **catalog of fit controls** and their general semantics, and (c) the
**convergence and interval-method guidance** behind the user-facing
`vignettes/convergence.Rmd` article. It exists because much of the recent
hardening was driven by one real dataset (the Ayumi bird location-scale case),
and the project rule is that *one-dataset work must leave behind general,
recorded controls — never dataset-specific tuning baked into the code.*

## The generalization principle (the rule)

A feature added because a specific dataset needed it ships as a **general
control with a generic default**, validated and documented, not as a special
case in the fitting path. Concretely:

- The Ayumi data lives only in throwaway experiment scripts (under `/tmp` and
  `inst/sim/run/`), never in package `R/` or `src/`. The package has no
  bird-data constants.
- Every knob added for that work — `drm_phylo_penalty()`, the (planned)
  `log(sigma)` clamp band, `optimizer_preset` — is a general control with a
  default that reproduces the prior behavior, so existing fits are unchanged.
- A tuning value that worked for one dataset is **not** promoted to a default.
  The clearest example is the penalty's `cor_sd`: the value that best recovered
  the simulated/real correlation (around 0.5) is **data-specific** — it tracks
  the unknown true correlation magnitude. There is **no universal `cor_sd`**;
  users run a prior-sensitivity sweep, and `cor_sd` defaults to `NULL` (no
  correlation penalty).

When a future dataset motivates a new behavior, add it the same way: a control,
a generic default, validation, docs, and a row in the catalog below.

## Control catalog

| Control | Where | Default (generic) | Semantics |
| --- | --- | --- | --- |
| `optimizer_preset` | `drm_control()` | `"default"` (no extra `nlminb` limits) | `"careful"` = iter/eval 1000; `"robust"` = 5000. Larger deterministic budget for stiff models; the fit records the selected preset and the attempt table. |
| `optimizer = list(...)` | `drm_control()` | `nlminb` defaults | Explicit `iter.max`/`eval.max` etc.; explicit controls are respected over the preset ladder. |
| `penalty = drm_phylo_penalty(sd_u, sd_alpha, cor_sd)` | `drmTMB()` | `NULL` (plain ML) | Optional penalized/MAP estimator: PC prior on each phylogenetic SD; optional `N(0, cor_sd)` on the phylo correlation. ML stays bit-identical when `NULL`. A penalized fit is labeled `MAP`; `logLik()` returns the **unpenalized** data value; `check_drm()` flags it; LRT/AIC across penalized fits are not standard. `cor_sd` has no universal value — sweep it. |
| `log(sigma)` clamp | `src/drmTMB.cpp` (guard); `drm_control(logsigma_clamp = c(lo, hi), logsigma_clamp_margin = m)` | identity in `[-12, 12]`, saturating to `[-15, 15]` (default; configurable) | Numerical guard so a scale-side phylogenetic field cannot overflow `log(sigma)`; bit-identical inside the band, and `logsigma_clamp = NULL` disables it. Still planned: warn when the clamp is active at the optimum (doc 170). |
| `se` | `drm_control()` | `TRUE` | `FALSE` skips `sdreport()` (no Wald SE/`vcov`/Wald CI); point estimates, prediction, simulation, profiles remain. |
| `missing = miss_control(...)` | `drmTMB()` | drop responses, fail on missing predictors | Missing-data policy; `response = "include"` (Gaussian), `predictor = "model"` (Gaussian/Poisson). |
| `REML` | `drmTMB()` | `FALSE` | Restricted ML for the first univariate Gaussian mixed slice (intercept-only `sigma`); not a defined estimator for scale models generally. |

## Convergence diagnostics (read as a table, not one flag)

- `convergence` — `nlminb` code 0 = converged; inspect the message + gradient.
- `max|grad|` (fixed-gradient row of `check_drm()`) — large gradient = an
  optimization problem before any inference; treat first.
- `pdHess` — positive-definite Hessian from `sdreport()`. `FALSE` means the
  surface is nearly flat in at least one direction; it is a **Wald-inference
  warning, never an automatic discard** of the point estimate.
- `check_drm()` — the diagnostic table (convergence, budget, gradient, Hessian,
  finite SEs, boundary SDs/correlations, structured-effect and penalized-fit
  notes). A warning is a prompt to decide: unfinished optimization vs weak
  identifiability vs an unnecessary component.

## Interval methods — when to use which (findings)

| Method | `confint(method=)` | Works when | Evidence / caveat |
| --- | --- | --- | --- |
| Wald | `"wald"` | `pdHess = TRUE`, parameter off its boundary | Instant. On a penalized PD fit it returns finite SD/correlation intervals immediately. Invalid when `pdHess = FALSE`. |
| Profile | `"profile"` | identified targets; gold standard near boundaries | Requires **explicit target names** (`parm = "sd:mu:..."` / compact labels) — calling it with no target errors by design. A flat profile is honest evidence of weak identifiability; can fail/slow on the coupled-q4 boundary (the q4 profile errors at ~1 obs/tip). |
| Parametric bootstrap | `"bootstrap"` | PD fits (including penalized PD); well-posed refits | **Works on a positive-definite fit but is expensive** (~17 min at n=300 on a penalized coupled-q4 fit; returned intervals for all 12 targets). **Fails on a non-PD flat ridge** — refits inherit the ridge and 0 converge (Guedon et al. 2024). So the penalty, by restoring a PD fit, also restores bootstrap as an option. |

Summary: for the **identified** models (mean-phylo, fixed-effect scale, residual
`rho12`, separable blocks that reach `pdHess = TRUE`) all three methods are
available and Wald is instant. A **penalized fit that reaches `pdHess = TRUE`
likewise restores all three** (Wald instant, profile with named targets,
bootstrap slow but returning) — confirmed on the n=300 penalized coupled-q4 case.
For the **non-PD coupled** case, profile and bootstrap both fail at the boundary —
the honest routes are a simpler model, the penalized/MAP estimator with a
prior-sensitivity sweep, or within-group replication.

## The penalized/MAP estimator (the new control)

`drmTMB(..., penalty = drm_phylo_penalty(sd_u = 1, sd_alpha = 0.05, cor_sd = ...))`
regularizes a weakly-identified phylogenetic SD or correlation so the fit
returns a finite, positive-definite estimate instead of pinning at a boundary.
Honest use (recorded so it cannot be misused):

- It is a **MAP** point estimate, not ML: report it as such, with the prior.
- **`logLik()` returns the unpenalized data log-likelihood** (the penalty is
  stored as `fit$phylo_penalty`); LRT/AIC across penalized fits are not standard.
- **Run a `cor_sd` (and `sd_u`/`sd_alpha`) sensitivity sweep**: if an estimate
  moves with the prior it is prior-dominated; if it is stable it is
  data-informed. Interpret only strong, prior-stable quantities.
- It makes a model *fittable*, which is not the same as *identified*. The clean
  route to a fully identified coupled model is within-group replication
  (recovery evidence: doc 173).

## Cross-references

- `docs/design/170-...` — the `log(sigma)` clamp (numerical guard).
- `docs/design/172-phylo-penalized-map.md` — the penalty/MAP estimator design.
- `docs/design/173-phylo-penalty-model-e-rescue.md` — the recovery evidence
  (penalty rescues to PD; prior-sensitive at 1 obs/tip; replication is the clean
  fix).
- `vignettes/convergence.Rmd` — the user-facing how-to that this note backs.

## References

Simpson et al. 2017 (PC priors); Chung et al. 2013 (penalized variance
components); de Villemereuil & Nakagawa 2014; Nakagawa et al. 2025 (PLSM);
Guedon et al. 2024 (bootstrap failure on a singular FIM); Self & Liang 1987
(boundary inference).
