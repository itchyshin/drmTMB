# 247 — Arc D / D1: what a scale clamp may do to a profile endpoint

**Status:** **DECISION REQUIRED FROM SHINICHI.** D0 inventory and the decisive
measurement are complete; no code has been changed. Per the Arc D plan (#847) and its
Claude counterpart, implementation is fenced until a design is selected **in writing**.

**Owners:** Fisher (contract), Gauss (numerics), Rose (closeout).
**Reads:** `docs/design/245-f5-sd-regression-clamp-and-identifiability.md` first.

---

## Hard fences (carried forward verbatim from the Codex Arc D plan, #847)

These are binding on this arc regardless of which design is selected. They originate in
`docs/dev-log/2026-07-26-arc-d-scale-clamp-profile-contract-ultra-plan.md` (#847) and are
reproduced here so this document is self-sufficient — #847 may be closed without losing them.

- **Do not edit the nine `sd()` predictor sites** during the plan phase.
- **Do not change `interval_status`, the capability ledger, or public inference** until the
  owner approves a selected design.
- **Do not launch the 177-cell interval campaign**, or any simulation, recovery, coverage,
  bootstrap, or full-refit study, on the strength of this arc.
- **Do not expose PR #846's private association sandwich engine** through `vcov()`,
  confidence intervals, profiles, `confint()`, or public documentation. That is the
  *association* lane's property; this is the `sd()`/scale/intervals lane.
- **Do not treat a finite interval as identified** merely because a clamp bound was reached.
  This is the whole point of the arc.

## The question

Arc B finding **F5**: nine sites in `src/drmTMB.cpp` take `exp()` of a
regression-predicted log-SD (from `sd(group) ~ x`) with no clamp, while the residual
`log_sigma` **is** soft-clamped by default. Arc C implemented the obvious repair —
reuse the residual band — and **reverted it**: at the dense K=12 meta-V cell it turned a
genuinely non-identified heterogeneity slope into a finite, vacuous profile interval
`[-4.1428, 27.7859]`, where widening the band to `c(-200, 200)` restored
`profile_failed`. The bound, not the data, supplied the endpoint.

So: **what may a clamp do to a profile endpoint?**

---

## The measurement that reframes the question

The blast-radius scout found that **exactly one capability-ledger cell has certified
interval evidence on a `sd(...) ~ x` path**: `mc-0017`
(`inference_ready_with_caveats`, brain `D-62`), certified on **profile** coverage of
`sd_phylo(spp_id) ~ x_tau` — both intercept and slope — at `profile_finite_rate = 1.000`.
Its certified coverage was measured with **no clamp** on that path, so the obvious fear
was that any clamp design would invalidate it and force a re-run.

**Measured on an `mc-0017`-shaped fit (`g = 120`, `m = 4`, truths `log(0.30)`, `0.25`):**

| | predicted log-SD |
| --- | --- |
| at the optimum | `[-1.604, 0.335]` |
| worst \|log-SD\| across the whole profile box | **2.629** |
| margin to the `c(-12, 12)` band | **9.371** |

`drm_softclamp_log_sigma` is **exactly** identity inside `[lo, hi]` — not approximately.
Therefore **a default-band clamp cannot move `mc-0017`'s endpoints at all.** The feared
owner gate does not bind, and the blast radius on certified claims is **zero**.

### The principle this exposes

| Case | Identified? | Profile excursion | Clamp effect |
| --- | --- | --- | --- |
| `mc-0017`, `sd_phylo ~ x_tau` | yes | max \|log-SD\| 2.63 | **identity — no effect** |
| K=12 dense LSS, `sd(study) ~ z_study` | **no** | ran to the **bound** | **manufactured an endpoint** |

**A clamp on the `sd()` path is identity wherever the parameter is identified, and binds
only where it is not.** It is therefore not a numerical guard that incidentally corrupts
intervals — it is, in effect, a **non-identification detector**. It changes the answer in
exactly the cases where the honest answer is "not identified."

That is the fact the design choice should turn on.

---

## D0 inventory — what any design must cover

**The nine C++ sites** (`sd_*_group(g) = exp(eta_sd)`, guarded only by
`has_sd_mu_model`/`has_sd_phylo_model`, never by `use_logsigma_clamp`):
`src/drmTMB.cpp` `:831`, `:921`, `:2279`, `:2826`, `:3282`, `:3490`, `:4017`, `:4119`,
`:4514` — across `model_type` 1 (gaussian), 10 (beta), 6 (poisson), 7 (nbinom2), and
2/19/20 (bivariate).

**Three gaps that any design must confront:**

1. **A TENTH SURFACE, outside `src/`.** `R/drmTMB.R:20181` `sd_mu_group_values()` and
   `:20193` `sd_phylo_group_values()` **independently re-derive `exp(eta)` in R** from
   `par$beta_sd_mu` — *not* from `obj$report()`. They feed `mu_sd_by_random_effect()`
   (`:20169`), `biv_phylo_node_sd_values()` (`:20208`), and the simulate/ranef paths.
   **A clamp applied only in C++ would not cover them, silently creating a C++/R
   inconsistency.** This was not in the Arc B audit and is new here.
2. **`model_type` 6 and 7 never REPORT `sd_mu_group`** (`src/drmTMB.cpp:3271-3415`,
   `:3478-3682`). Any design that detects clamping by reading REPORT fields is blind to
   poisson and nbinom2 until those REPORTs are added.
3. **No boundary check exists for the relevant transformation.** The profiled quantity is
   `beta_sd_mu` — the regression *coefficient*, pre-`exp()` — with
   `transformation = "linear_predictor"`. `profile_interval_diagnostics()`
   (`R/profile.R:3407-3430`) special-cases only `"exp"` and `"derived_group_scale"`;
   `"linear_predictor"` gets no boundary check at all.

**Where an endpoint check would have to live:**
`drm_profile_target_tmbprofile_confint()` (`R/profile.R:2825-2864`) and
`drm_profile_target_endpoint_confint()` (`R/profile.R:2867-2900+`), at the point
`profile_conf_status_from_diagnostics()` finalises status.

**Existing clamp diagnostics are unusable as-is.** `drm_logsigma_clamp_active()`
(`R/drmTMB.R:2650-2677`) and `check_logsigma_clamp_active()` (`R/check.R:470-508`) read
only `log_sigma`/`log_sigma1`/`log_sigma2` by exact name, are gated on a family whitelist
with no sd-regression concept, and inspect **the fitted optimum only** — they have no
notion of a profile step or an endpoint.

**Tests that would move:** `tests/testthat/test-phase18-meta-v-lss-runner.R:66-79` (the
F5 negative-control sentinel; internal names `fixef:sd(study):(Intercept)` / `:z_study`,
aliased in `inst/sim/fit/sim_summarise_meta_v_lss.R:57-58`). `mc-0017`'s coverage logic
lives in the dev-only `tools/run-beta-phylo-q1-sd-coverage.R:65-66,268,282,304-305`, not
in the default `testthat` run.

---

## The three designs, costed

### Design 1 — overflow-only guard
Bound at the scale where `exp()` genuinely overflows (order `±700`), far outside anything
a profile explores.

- **Preserves the honest answer.** K=12 keeps `profile_failed`; nothing is manufactured.
- **Provably free for identified cells** — `mc-0017` has 9.37 of margin at `±12`, and
  ~697 at `±700`.
- **Cost:** delivers little of doc 170's stated rationale, which is inner-Laplace
  stability, not merely overflow. It prevents `Inf`, not a runaway.
- Must still cover the tenth surface (gap 1) to stay consistent.

### Design 2 — clamp, and report `clamp_limited`
Clamp at the residual band, and mark an endpoint `clamp_limited` rather than `ok` when it
meets the bound.

- **The measurement argues this is the natural design**, not merely the most honest one:
  since the clamp is identity where identified and binds only where it is not, the clamp
  *and* the non-identification signal are the same mechanism. `clamp_limited` is then a
  strictly more informative `profile_failed`.
- **Cost is real and concentrated in the three D0 gaps:** new REPORTs for `model_type`
  6/7, a `"linear_predictor"` boundary check that does not exist, endpoint-level plumbing
  into `R/profile.R:2825-2900`, and the tenth surface. It also changes the
  `interval_status` contract that the meta-V lane and the ledger both read.

### Design 3 — clamp the fit, leave the profile unclamped
- Endpoints unshaped, so K=12 stays honest and `mc-0017` is untouched.
- **Statistical objection, and it is not small:** the profile would then be a profile of a
  *different objective* than the one fitted. The interval would not correspond to the
  reported model. Recommend rejecting unless someone can show the two objectives coincide
  wherever it matters.

---

## Recommendation (Ada), for Shinichi's decision

**Design 1 now; Design 2 as the target once its prerequisites exist.**

Design 1 is cheap, provably cannot move any identified interval, preserves the honest
`profile_failed` on non-identified ones, and addresses the literal audit finding
(unguarded `exp()`). It requires no change to `interval_status`, so it cannot disturb
`mc-0017` or the ledger.

Design 2 is where this should end up — the measurement shows clamping and
non-identification detection are the same act — but it needs the `"linear_predictor"`
boundary check, endpoint plumbing, and the missing REPORTs first. Those are independently
useful and can be built without committing to a clamp.

**Whatever is chosen must cover the tenth surface** (`R/drmTMB.R:20181`/`:20193`), or
C++ and R will disagree about the same quantity.

**Not recommended:** Design 3, on the objective-mismatch objection above.

---

## What this does NOT establish

- **No claim that the unguarded `exp()` is unsafe in practice.** The Arc B finding was
  `PLAUSIBLE`, Low-Med, explicitly "no fit run to drive `eta_sd > 709`". It remains
  untested in either direction; nothing here demonstrates a reachable overflow.
- The `mc-0017` margin was measured on a **rebuilt fixture** (`g = 120`) matching its
  formula and truths, not on the original `g = 1024, m = 4` promotion arms. The margin is
  large enough (9.37) that the conclusion is robust, but it is a reconstruction.
- No capability-ledger cell is promoted or demoted by anything here.
