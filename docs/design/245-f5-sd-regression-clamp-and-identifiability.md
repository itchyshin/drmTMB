# 245 — F5: why clamping the `sd()` regression was reverted

**Status:** decided 2026-07-25 (Shinichi). F5 is **not repaired**; the attempt is
recorded here so the follow-up arc starts from evidence rather than from the
audit's hypothesis.

**Owners:** Gauss (numerics), Fisher (inference contract).

---

## The finding, as Arc B stated it

Arc B finding **F5**, severity **Low-Med**, label **PLAUSIBLE**:

> `sd()` regression takes `exp()` of an unbounded regression-predicted log-SD with
> no clamp, bound, or `CondExp` (`drmTMB.cpp:831, 921, 2279, 2815, 4107`), while
> residual `log_sigma` is clamped by default and every correlation is
> `tanh`-bounded. Doc 170's own justification for the clamp — "a runaway
> per-observation scale… estimated from one observation per group" — applies
> verbatim to the unguarded case.

The audit was explicit that this was **not demonstrated**: "PLAUSIBLE (no fit run
to drive `eta_sd > 709`)". It is a hypothesised overflow, not an observed defect.

Two corrections to the finding, both established while attempting the repair:

- **There are nine sites, not five** — `drmTMB.cpp` `831, 921, 2279, 2826, 3282,
  3490, 4017, 4119, 4514` (pre-edit numbering). The audit's list was short by
  four, the same undercount pattern as its own "3 dead `sigma_i`" that was
  really 12.
- **The premise holds.** `drm_control()` defaults `logsigma_clamp = c(-12, 12)`
  (`R/control.R:134`), so `use_logsigma_clamp` really is `1L` by default and the
  residual clamp really is on. The asymmetry the audit describes is real.

## What was implemented

`drm_softclamp_log_sigma`'s scalar core was extracted as
`drm_softclamp_log_sigma_one` (the vector form calling it, so behaviour stayed
bit-identical), and a `drm_softclamp_log_sd` wrapper applied it at all nine
sites — gated on the same `use_logsigma_clamp` switch, the same band, the same
margin. Deliberately **not** a second, separately-tuned bound.

The change compiled cleanly and passed the numeric-kernel oracle (376), the
FD-vs-AD gradient conformance suite (36), the clamp suites, and the beta
location-scale and beta-phylo suites.

## Why it was reverted

It broke a **negative control** — and the way it broke it is the finding.

`test-phase18-meta-v-lss-runner.R`'s *"Arc 7B dense LSS sentinel retains
incomplete direct-SD profiles"* pins the known K=12 degeneracy: the dense
location–scale–scale meta-analysis cell must report
`interval_status = "incomplete"` and `interval_message = "nonfinite_interval"`
for its direct-SD profiles. With the clamp in place, `sd:study:z_study` instead
reported `ok` with a finite interval.

The decisive experiment, refitting that exact cell and profiling the same
target under two bands:

| `logsigma_clamp` | profile result for `sd(study):z_study` |
| --- | --- |
| `c(-12, 12)` (default; clamp active) | **finite** `[-4.1428, 27.7859]`, `conf.status = profile` |
| `c(-200, 200)` (clamp effectively off) | **`profile_failed`**, `lower = upper = NA` |

Widening the bound restores the non-identification. **The finite endpoint is an
artifact of the bound, not information from the data.**

This is worse than the behaviour it replaced. `[0, Inf]` is self-evidently
uninformative and gets flagged as such; `[-4.14, 27.79]` looks like an ordinary
interval and would pass any gate that asks only whether an interval is finite —
in the meta-analysis heterogeneity setting, at the exact `K = 12` cell whose
degeneracy is already reproduced and on record. On the log-SD slope scale an
upper endpoint of 27.79 implies the study SD multiplying by roughly `1e12` per
unit of `z_study`; it is finite and vacuous.

It also runs straight into the **asymmetric tier fence**: correctness evidence
may never *promote* a ledger cell, but it can compel a demotion. Re-pinning the
sentinel to accept the finite interval would have recorded a clamp artifact as a
capability gain.

## Decision

**Drop F5 from Arc C.** Ship A5 (beta `mi()` clamp ordering) and A7 (rotted
anchors), which are independent and clean. F5 becomes its own arc.

The open question is not numerical, it is inferential, which is why it needs
Fisher rather than a bigger `if`: **what is a scale clamp allowed to do to
identifiability?** Three candidate designs, none free:

1. **Pure overflow guard.** Bound only where `exp()` genuinely overflows
   (order `±700` for double), far outside any region a profile explores. Keeps
   the honest non-identified result. Weaker than F5 intended, because doc 170's
   rationale for the *residual* clamp is inner-Laplace stability, not merely
   overflow — so this may not deliver the benefit the audit was reaching for.
2. **Clamp, but report it.** Keep the tight band and have the profile emit
   `clamp_limited` rather than `ok` when an endpoint's predicted log-SD sits at
   or near the bound. Most honest, but it changes the `interval_status`
   contract that both the meta-V lane and the capability ledger read.
3. **Clamp the fit, not the profile.** Apply the bound during optimisation for
   stability but disable it while profiling, so interval endpoints are never
   shaped by it. Needs care that the two objectives stay comparable.

## What this does NOT establish

No claim that the unguarded `exp()` is safe. The nine sites remain unbounded and
the audit's hypothesis is untested either way — no fit has yet been driven to
`eta_sd > 709`. What is established is only that **the specific remedy of
reusing the residual band silently converts non-identification into false
precision on a load-bearing inference path**, and must not ship in that form.

> Related: Arc B audit (`docs/dev-log/after-task/2026-07-25-arc-b-cpp-numerical-audit.md`) ·
> doc 170 (sigma-phylo conditioning and the log-sigma clamp) ·
> doc 241 (Arc 7B meta-V heterogeneity ladder contract)
