# Ultra-Plan: Distributional Output & Adequacy Layer (issues #747 + #748)

Status: **APPROVED & UNDERWAY (2026-07-12).** Goal set by Shinichi; plan
approved. Implementation on branch `feature/distributional-output-adequacy` (off
`main` @ 35db8917). DO-T0a (foundation + tweedie/skew_normal feasibility spike)
building toward the CP1 API-freeze gate. Live orchestration + goal in the plan
file `~/.claude/plans/concurrent-gliding-zebra.md`; DG2/DG3 verification backbone
in `scratchpad/nextarc/verification-spec.md`; 7-member panel deliberation folded
into the plan file. This doc = the design rationale; the plan file = the live
execution state.

**Goal (Shinichi, 2026-07-12):** give every drmTMB user a straight answer to
"did I model the whole distribution, not just its average?" and "how likely is
this to exceed a threshold for its covariates?" — via one family-general
`{d,p,q}` foundation carrying #747 (adequacy diagnostics) + #748 (distributional
outputs). Done = all 18 families at DG2 correctness + DG3 behavioural recovery
(with the honest power arm), surfaces shipped and honestly labelled
(`calibrated=FALSE`, "no detectable departure"), landed with the surface
regenerated. Not done: DG4/DG5 coverage, RE/structured adequacy, bivariate joint
— named, not forgotten.

Author context: drafted by Claude on `main` @ `35db8917` after the MR-T0–MR-T7
missing-response arc closed (#761) and the 0.5.0 CRAN resubmission fix was
prepared (`release/0.5.0-cran-resubmit` @ `a25cc3b8`). Prior-work sweep,
capability-frontier map, and roadmap map are archived at
`scratchpad/nextarc/{A,B,C}.md` for this session.

---

## 1. Goal (one sentence)

Give every fitted `drmTMB` family a first-class fitted-distribution object with
per-observation density/CDF/quantile (`{d,p,q}`) primitives, then build on it the
two user-facing surfaces that make distributional regression *honest* and
*useful*: randomized quantile-residual adequacy diagnostics (#747) and
conditional-quantile / exceedance / centile outputs (#748).

## 2. Why this arc (mission fit)

- **Mission — "usable packages for many."** This layer is *family-general*: one
  `{d,p,q}` foundation serves all 18 fitted families at once, and the outputs
  (worm/QQ adequacy plots, `Pr(Y > c | x)`, centile charts, conditional
  quantiles) are exactly what the eco/evo + health audience reaches for on
  *every* model. Highest breadth-of-impact of any candidate next arc.
- **On the declared v1.0 critical path.** ROADMAP.md:20-24 defines the `1.0`
  maturity milestone as the full distributional-regression story — "location +
  scale + shape + **adequacy diagnostics + quantile/exceedance outputs**." Two
  of those five legs are this arc. Location and scale are largely done; this arc
  builds the output/diagnostic leg.
- **External anchor.** The GAMLSS Primer (Merder, Rigby, Stasinopoulos et al.,
  *Nat Rev Methods Primers* 2026, 6:49) makes normalized/randomized quantile
  residuals (Dunn–Smyth) the central model-check for DR, and frames conditional
  quantiles / exceedance / centiles as the *point* of DR beyond coefficients.
  Both issues cite it; surfaced by scout note
  `docs/dev-log/scout/2026-07-10-gamlss-primer-dr.md`.
- **Clear of the guarded areas.** Touches none of the forbidden/deferred
  candidates (non-Gaussian REML wording scan SR159, MNAR design-223 rejection,
  G4/G5 coverage promotion). It adds features on top of the existing fit surface
  without reopening any estimator or masking contract.

## 3. Scope and non-scope

**In scope (v1.0 target — stop at behavioural recovery, gate DG3):**
- A per-family `{d,p,q}` registry evaluated at fitted per-observation parameters.
- Randomized (normalized) quantile residuals `r_i = Φ⁻¹(F(y_i; θ̂_i))`, with the
  discrete-family randomization contract; `residuals(fit, type = "quantile")`.
- Worm plots (detrended QQ) and QQ plots; optional bucket plots + subregion Z/Q
  statistics as a stretch within DO-T1.
- `predict(fit, type = "quantile", prob = ...)` → conditional quantiles / centile
  curves; `exceedance(fit, threshold, newdata)` → `Pr(Y > c | x)`; a centile-chart
  helper keyed on one covariate.
- Distribution-based prediction intervals (point-wise, from the fitted
  distribution at `θ̂` — **not** a calibrated-coverage claim; see non-scope).
- Vignette wiring: the "did I model the distribution, not just the mean?" step.

**Explicitly NOT in scope (this arc):**
- **Coverage / interval calibration promotion (DG4/DG5).** Prediction intervals
  are reported from the fitted distribution; *calibrated coverage evidence* is a
  separate, separately-authorized evidence campaign (v1.0 defers coverage —
  ROADMAP.md:33-34). This arc stops at DG3 (behavioural recovery vs known DGP).
- **Uncertainty propagation into the outputs** beyond plug-in `θ̂` (i.e. no
  delta-method / posterior / bootstrap bands on quantiles/exceedance in v1) —
  banked as a DG4 follow-on.
- **Bivariate joint outputs.** `biv_gaussian` gets marginal `{d,p,q}` per
  response only; joint/conditional bivariate quantiles are a later slice.
- **New families, new estimators, REML changes, missing-data changes.** None.

## 4. Mathematical contract

For a fitted family with per-observation parameter vector `θ̂_i` (from
`predict_parameters()`):

- **Density / mass** `d`: `f(y; θ)`. **CDF** `p`: `F(y; θ) = Pr(Y ≤ y; θ)`.
  **Quantile** `q`: `F⁻¹(α; θ)`, the smallest `y` with `F(y; θ) ≥ α`.
- **Continuous families** — randomized quantile residual is exactly
  `r_i = Φ⁻¹(F(y_i; θ̂_i))`.
- **Discrete families** (poisson, nbinom2, binomial, beta_binomial, truncated /
  hurdle nbinom2, zi_poisson, zi_nbinom2, cumulative_logit) — Dunn–Smyth
  randomization: draw `u_i ~ Uniform(F(y_i⁻; θ̂_i), F(y_i; θ̂_i)]` and set
  `r_i = Φ⁻¹(u_i)`, where `F(y_i⁻)` is the CDF just below the atom. Randomization
  seed is user-controllable and recorded.
- **Correctness identity (DG2):** `F(F⁻¹(α; θ); θ) = α` (to tolerance) for
  continuous families; `q` is the correct right-inverse for discrete families;
  `d`/`p` agree (`∑`/`∫ d = 1`, `p` monotone in `[0,1]`); each family's `{d,p,q}`
  matches its base-R / reference implementation at fixed `θ` (e.g. `pnorm`,
  `pgamma`, `ppois`, and the package's own likelihood in `src/drmTMB.cpp`).
- **Adequacy claim (DG3):** under the correct data-generating process, the
  randomized quantile residuals are ~ `N(0,1)` (equivalently PIT ~ Uniform);
  verified by a known-DGP uniformity/normality test. Under a *mis-specified*
  model (e.g. location-only fit to heteroscedastic data — the Primer's Fig 4c),
  the worm/QQ plot shows the expected systematic departure.
- **Exceedance / centile (DG3):** `exceedance = 1 − F(c; θ̂)`; conditional
  quantile = `F⁻¹(α; θ̂)`. Verified against a large-sample Monte Carlo estimate
  from `simulate.drmTMB` at known `θ`.

## 5. Per-family rollout order (the `{d,p,q}` matrix)

Ordered by implementation ease and reuse; each family must reach DG2 before its
diagnostics/outputs are exposed.

1. **Continuous, closed-form CDF (easiest):** gaussian, student, lognormal,
   skew_normal *(note: skew_normal is at `diagnostic_hold`; its `{d,p,q}` are
   still well-defined — this arc does not depend on promoting it)*.
2. **Positive / bounded continuous:** gamma, beta, tweedie (compound
   Poisson–gamma CDF needs care at the zero atom), zero_one_beta (mixed
   discrete–continuous: atoms at 0/1 + interior beta).
3. **Discrete (need randomization):** poisson, binomial, nbinom2,
   beta_binomial, truncated_nbinom2, hurdle_nbinom2, zi_poisson, zi_nbinom2.
4. **Ordinal:** cumulative_logit (CDF is the natural object here).
5. **Bivariate:** biv_gaussian — marginal `{d,p,q}` per response only in v1.

Families with atoms / mixtures (tweedie, zero_one_beta, zi_*, hurdle_*) are the
highest-risk `{d,p,q}` cells and get explicit DG2 atom/boundary tests, mirroring
how MR-T3/MR-T6 handled those same families.

## 6. Evidence gates (arc-local, mapped to the capability ledger)

Parallels the missing-response G-ladder so it integrates with
`tools/capability_ledger.py` and the `evidence_tier` vocabulary; **v1.0 target is
DG3**, DG4/DG5 deferred.

| Gate | Meaning | Evidence |
|---|---|---|
| DG0 | absent | none |
| DG1 | `{d,p,q}` route callable per family at fitted params | code admits the route |
| DG2 | correctness contract | inverse identity + normalization + reference cross-check, per family |
| DG3 | known-DGP behavioural recovery | quantile residuals ~N(0,1); exceedance/centile match `simulate()` MC truth |
| DG4 | *(deferred)* calibrated prediction-interval coverage at a known DGP point | — |
| DG5 | *(deferred)* archived replicated coverage | — |

## 7. Slices (dependency-ordered tranches)

```
DO-T0  Foundation: fitted-distribution object + {d,p,q} registry + gate ledger   [SEQUENTIAL, first]
DO-T1  Adequacy diagnostics (#747): quantile residuals + worm/QQ (+bucket/Z-Q)    [parallel after DO-T0]
DO-T2  Distributional outputs (#748): predict(type="quantile"), exceedance(),     [parallel after DO-T0]
        centile helper, distribution-based PIs
DO-T3  Per-family rollout to DG2/DG3 across all 18 families                        [pipeline, batched by §5 tiers]
DO-T4  Docs/vignette + NEWS + capability-surface regeneration + review            [SEQUENTIAL, last]
```

- **DO-T0** is the shared bottleneck both issues name. It: audits the family
  registry (`R/family.R`) and `predict_parameters()` (`R/methods.R`); designs the
  fitted-distribution representation; implements `{d,p,q}` for tier-1 families as
  the reference pattern; defines the discrete randomization contract; adds the
  arc's ledger cells + DG-gate grader to `tools/capability_ledger.py`. Modeled on
  MR-T0.
- **DO-T1** consumes only `p` (CDF). **DO-T2** consumes `p` and `q`. Both can run
  in parallel once DO-T0 delivers both `p` and `q` for tier-1 families.
- **DO-T3** is the per-family pipeline (each family: DG1 → DG2 → DG3), batched by
  the §5 tiers; the atom/mixture families are their own careful batch.
- **DO-T4** regenerates the capability surface (do **not** hand-edit the
  generated board — change `tools/capability_ledger.py`), wires the vignette, and
  runs the review panel.

**Parallel set:** {DO-T1, DO-T2} after DO-T0; DO-T3 pipelines per family.
**Sequential:** DO-T0 first; DO-T4 last.

## 8. R-API surface (for Boole/Emmy review before coding)

- `residuals(fit, type = "quantile", ...)` — extend existing
  `residuals.drmTMB` (currently `c("response", "pearson")`, `R/methods.R:3172`).
- `predict(fit, type = "quantile", prob = c(0.025, 0.5, 0.975), newdata, ...)` —
  extend `predict.drmTMB` (`R/methods.R:2649`).
- `exceedance(fit, threshold, newdata, ...)` — new generic + `drmTMB` method.
- Plot helpers: `worm_plot()`, `qq_plot()` (or a `type=` on an `autoplot`/
  `plot`-family entry) — honour the **Confidence Eye** figure contract; Florence
  gate. Optional `bucket_plot()`.
- `centile_chart(fit, covariate, prob, ...)` — the WHO-style reference-chart
  helper keyed on one covariate.
- Naming/grammar decision needed at DO-T0: is the residual type `"quantile"` or
  `"quantile-randomized"`, and how is the randomization seed exposed
  (`residuals(fit, type = "quantile", seed = ...)`)? Boole owns this.

## 9. Verification plan

- **DG2 (correctness):** per-family unit tests — `p∘q` inverse identity;
  `d`/`p`/`q` cross-checked against base-R reference distributions at fixed `θ`;
  atom/boundary tests for tweedie / zero_one_beta / zi_* / hurdle_*; agreement
  with `src/drmTMB.cpp` likelihood at the same `θ`.
- **DG3 (recovery):** known-DGP simulation — (a) quantile residuals pass a
  KS/normality test under the correct model and *fail* under a deliberately
  mis-specified model (Primer Fig 4c reproduction); (b) `exceedance()` and
  conditional quantiles match a large-`n` Monte Carlo estimate from
  `simulate.drmTMB` at known `θ` (the package's own truth oracle). Route heavy
  known-DGP grids off the routine CRAN lane (the NOT_CRAN gate added in the
  pretest fix) and, if scaled, onto Totoro/DRAC.
- **Review panel (independent, post-implementation):** Noether (math: `{d,p,q}`
  consistency + the residual identity), Fisher (inference: adequacy claim, PI
  honesty), Curie (simulation cross-checks + randomization correctness), Emmy
  (R-API coherence of predict/residuals/exceedance), Boole (arg grammar),
  Florence (worm/QQ/centile visual quality vs Confidence Eye), Darwin (do the
  outputs answer real eco/evo questions), Rose (scope honesty: claim = DG3, not
  coverage).

## 10. GitHub issue setup (proposed — outward-facing, needs your go-ahead)

- Keep **#747** (diagnostics) and **#748** (outputs) as the two deliverable
  issues; add a short note to each that they share the DO-T0 `{d,p,q}` foundation
  and are being scoped together, linking this plan.
- Optionally open one tracking parent issue "Distributional output & adequacy
  layer (v1.0 DR story)" that references #747, #748, and this plan, mirroring how
  #761 tracked the missing-response arc.
- No stale-issue cleanup is required here (that was a skew-normal concern, #3).

## 11. What this arc does NOT cover (honesty ledger)

- No calibrated-coverage / DG4-DG5 claim; prediction intervals are plug-in from
  the fitted distribution.
- No uncertainty propagation beyond `θ̂` into quantiles/exceedance in v1.
- No bivariate joint outputs (marginal only).
- No new families, estimators, REML, or missing-data behaviour.
- Does not promote skew_normal past `diagnostic_hold`; it only defines its
  `{d,p,q}` like every other family.

## 12. Risks

- **Atom/mixture CDFs** (tweedie, zero_one_beta, zi_*, hurdle_*) are the numeric
  risk — same families that needed care in MR-T3/MR-T6. Mitigate with explicit
  DG2 atom tests and `simulate()` cross-checks before exposing outputs.
- **Discrete randomization reproducibility** — seed handling must be explicit and
  documented, or residual plots become non-reproducible.
- **Check-time budget** — per-family known-DGP grids are heavy; keep them behind
  the NOT_CRAN gate from day one so CRAN check-time (the thing we just fixed) does
  not regress.
- **API surface creep** — resist adding bucket plots / Z-Q statistics /
  bivariate joint outputs into v1; they are stretch/deferred.

## 13. Immediate next steps (once you approve the direction)

1. Approve scope (DG3 target, deferred DG4/DG5, marginal-only bivariate).
2. I write the DO-T0 sub-agent briefs and, on your go-ahead for outward-facing
   actions, annotate #747/#748 and (optionally) open the tracking issue.
3. Implementation begins with DO-T0 on a post-release feature branch (not on the
   frozen release line), following the sub-agent-economy + verification pattern
   that MR-T0–MR-T7 used.
