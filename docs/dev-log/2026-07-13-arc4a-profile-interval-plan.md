# Next arc (ratified) — Arc 4a: profile-CI DG3 rerun → interval_feasible promotion

Status: **PLAN, ratified by a 5-agent design workflow (2026-07-13).** Chosen over three
alternatives (Gaussian REML, AGHQ axis, 2c student/beta) by a parallel scope + adversarial
Opus synthesis. This is the direct sequel to today's DG3 coverage finding.

## Why this, and why now

Today's DG3 campaign showed the **Wald(log-SD) interval for the random-effect SD degenerates
at small M** (∞ upper limit → trivial over-coverage for gaussian/lognormal; anti-conservative
for binomial). The DG3 README named the **profile interval** (drmTMB's featured method, D-12)
as the deferred fix. This arc runs it.

It is ranked first because it is the **only candidate that advances a cell's evidence tier
this session** (point_fit_recovery → the existing `interval_feasible` tier), it is the
**cheapest** (exercises an already-tested `confint(method="profile")` path — *not* new
capability), it is **best-motivated by today's evidence**, and it is **diagnostic**: by
isolating interval-construction from point-estimate bias, it tells us whether **REML** (Arc 1,
the finite-M/Gaussian remedy) or **AGHQ** (the per-cluster-n remedy) is the genuinely binding
constraint — so the next, more expensive arc is chosen on evidence, not assumption.

**Ranking (workflow):** 1) profile-CI DG3 rerun · 2) Gaussian REML→ML parity (Arc 1a/1b,
strong second, ~1 week) · 3) AGHQ axis (highest payoff, highest effort/risk, moves no cell
past point_fit_recovery) · 4) 2c student/beta (off-roadmap; but see the bug note below).

## The honest catch (do NOT over-claim)

The workflow's own live probe found that **profile removes the ∞-width artifact but does NOT
by itself restore nominal coverage at M=8** (gaussian_slope true coverage ≈ 0.885 once the
∞-upper replicates are replaced by bounded intervals; recovers to ≈0.96 only by M=16). And
**binomial's gap is point-bias, not interval construction** (AGHQ's remit) — profile (~0.93)
was indistinguishable from Wald (~0.95) at M=8. So the realistic committed yield may be **ONE
promotion (lognormal `mc-0382`) at M≥16, with binomial `mc-0061` a documented non-promotion.**
A rigorous negative counts as a satisfied evidence bar.

## Mechanism (grounded)

`confint.drmTMB(method="profile")` (R/profile.R:255-462) routes a random-effect-SD parm through
`drm_profile_confint` → `drm_profile_target_confint` → the bounded scalar endpoint solver
(R/profile.R:2827-2969), which roots the LR crossing on the internal log-SD scale and **allows
the SD=0 lower boundary** (R/profile.R:3175-3185) — the structural reason it is bounded where
Wald-on-log is not. `profile_targets()` already marks the DG3 targets `profile_ready = TRUE`
(asserted in test-arc2b-mu-random-slope.R:41-44, test-arc2c-sigma-random-intercept.R:37-39).
**The installed Totoro build is stale — reload from source (`pkgload::load_all`), do not use
the library build.**

## Slices

- **S1 — harness patch (no promotion).** Add `confint(fit, parm=<sd_parm>, method="profile")`
  per replicate to `docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage/generate.R`
  (or a `generate-profile.R` sibling), ALONGSIDE the Wald read; record `conf.status`
  (profile / profile_failed), both widths, and denominator columns (`n_profile_finite`,
  `profile_finite_rate`, `frac_wald_hi_inf`). **Check:** reproduce the isolated Wald-∞ /
  profile-finite case (gaussian_slope M=8 seed 20260976: Wald upper=Inf, profile upper≈0.327);
  zero silent `profile_failed` on the smoke batch.
- **S2 — full profile campaign (Totoro, ~80-90 cores).** 3 existing specs × M∈{8,16,32,64} ×
  600 sims. **Check:** a TSV with per spec×M `profile_coverage`, `profile_finite_rate`
  (≈1.0 or state+apply an exclusion policy), mean profile width, MCSE ≤ ~0.01; identify the
  **certified M-floor** at which coverage is finite-width AND ≥ the ~0.91-0.93 bar the q-series
  precedent accepted. Report whether binomial improves over Wald (probe says it did NOT at M=8
  — a valid negative).
- **S3 — per-family generalization (FOLLOW-ON, not this session).** New sim/fit closures for
  the other 5 point_fit_recovery cells (cumulative_logit mc-0227, skew_normal mc-0464, tweedie
  mc-0539, zero_one_beta mc-0575, Gamma sigma mc-0242), each with its OWN family-specific
  evidence (no cross-family borrowing). Report per-family `profile_failed` rate.
- **S4 — adversarial NOT-DONE review (before any ledger edit).** Fisher/Rose/Noether, D-43
  (≥2 NOT-DONE withholds). Reviewers specifically test that the claim_boundary (a) states the
  TRUE certified M-floor (probe suggests M≥16 for gaussian/lognormal), and (b) does NOT conflate
  "profile removed the ∞-width artifact" with "profile fixed the coverage gap."
- **S5 — ledger + honest-scope docs.** `tools/capability_ledger.py --write`: add evidence rows,
  flip `point_fit_recovery → interval_feasible` ONLY for cells clearing the bar at the certified
  M; leave `coverage_status`/`claim_boundary` honestly scoped (no jump to inference_ready/
  supported — those need the point-bias fix). Mirror `docs/dev-log/after-task/2026-06-27-interval-feasible-promotion.md`.
  After-task report.

## Estimate

Committed core (S1, S2, S4, S5 on the 3 existing specs → cells `mc-0061`, `mc-0382`) **fits one
session**. Be skeptical of "well under an hour" on Totoro — binomial at M=64 was ~8.9 s/profile;
the profile refit dominates — but it is a same-day campaign. S3 (5-family extension) is a
separate session.

## Spin-off bug (found while scoping lever 4)

`has_sigma_random_effects()` reportedly omits lognormal/Gamma — an omission from Arc 2c. Fix as
a **tiny standalone slice**, not carried as an arc. Verify + add a test.

## Deferred (evidence-motivated, in order)

Arc 1a/1b Gaussian REML (the finite-M/df-bias remedy) · then the AGHQ estimator axis (the
per-cluster-n integral-bias remedy) — Arc 4a's diagnostic result decides which binds first.
Full scopings: workflow run `wf_d42c1616-6a3` (journal in the session subagents dir).
