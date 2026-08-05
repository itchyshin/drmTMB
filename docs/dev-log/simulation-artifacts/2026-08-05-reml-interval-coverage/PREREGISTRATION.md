# Pre-registration — does REML's centre fix buy PROFILE interval coverage?

**Committed BEFORE any campaign fit.** Written 2026-08-05 against `origin/main = e430d408a`.
Platform: Claude Code, solo. Foreign lane: codex PR #858, no overlap.

## 1. Aim

Every repo has measured REML's effect on the **point estimate** of a variance component. No repo
has measured its effect on **interval coverage** — the cross-repo map says so outright ("Needs a
REML interval route, which none of the repos has"). D-117 established that the mechanism behind
its 10-group undercoverage is an RE-SD biased 9.1–16.9% low, and drmTMB's own REML probe
(2026-07-08, `scratchpad/reml_ordinary_sigma_re_probe.R`) shows REML debiases exactly that
quantity **at `n_each >= 8`**, while **underperforming ML at `n_each = 3`**.

**Question:** does `REML = TRUE` move profile-interval coverage for an ordinary sigma-axis
random-effect SD toward nominal, relative to ML, at small group counts?

## 2. Data-generating mechanism

```
id     : n_id groups, n_each observations each
x      ~ N(0, 1)
v_i    ~ N(0, SD_SIGMA)          # the sigma-axis random effect  <- the estimand
y      ~ N(1 + 0.5 * x, exp(B0 + v_i))
```

with `SD_SIGMA = 0.5` (truth), `B0 = -0.3`. Model fitted:
`bf(y ~ x, sigma ~ 1 + (1 | id))`, `family = gaussian()`.

**Estimand:** `sd:sigma:(1 | id)`, true value **0.5**.

**Grid (6 cells):** `n_id` ∈ {10, 20, 40} × `n_each` ∈ {3, 10}.

`n_each = 10` is the regime where the shipped probe says REML should help.
**`n_each = 3` is the pre-registered FALSIFIER** — the probe says REML *underperforms* ML there.

**Replicates:** `n_rep = 1000` per cell (matching D-117).
**Seeds:** `seed = 20260805 + 1000000 * cell_i + r`. **Arms are PAIRED** — ML and REML are fitted
to the *same* simulated dataset within a replicate, so the only difference is the estimator.

## 3. Methods compared

Four arms per replicate: {ML, REML} × {Wald, profile}. Profile is primary; Wald is carried to test
D-12's "profile is the hero" doctrine directly (see §6).

## 4. Performance measures

Primary: **coverage** of the true 0.5 by the 95% interval.
Secondary, all reported whether or not the primary moves: **mean interval width**, **point bias**
of the SD estimate, **boundary incidence** (`profile.boundary`), **miss direction** (upper/lower),
convergence and `pdHess` rates.

## 5. Decision rule — fixed now, before any data

For each cell, with paired indicators `C_ML`, `C_REML` ∈ {0,1} per replicate and
`D = C_REML − C_ML`:

- `delta = mean(D)`, `SE(delta) = sd(D)/sqrt(n)` (paired; this is the correct SE, not two
  independent binomial SEs).
- **`REML_HELPS(cell)`** iff **`delta - 2*SE(delta) > 0`** (paired improvement significant)
  **AND** `coverage_REML + 2*MCSE_REML >= ss_floor(n_id)`, using the repo's own
  `tools/gate-inference-ready.R` convention `ss_floor(g) = 0.95 - 0.04*(8/g)`
  → **0.918 / 0.934 / 0.942** at `n_id` = 10 / 20 / 40.
- **`REML_HURTS(cell)`** iff `delta + 2*SE(delta) < 0`.
- Otherwise **`INCONCLUSIVE(cell)`**.

**Headline claim — "REML buys interval coverage" — is admitted only if:**
1. `REML_HELPS` in **at least 2 of the 3** `n_each = 10` cells, **and**
2. it is **not** the case that `REML_HELPS` in any `n_each = 3` cell (see §6 falsifier), **and**
3. the width guard in §6 passes.

Anything less is reported as **NOT ESTABLISHED**, with the numbers, and no capability claim.

## 6. Pre-registered falsifiers and guards

**(a) The `n_each = 3` falsifier.** The shipped probe says REML *underperforms* ML at
`n_each = 3`. If this campaign finds `REML_HELPS` at `n_each = 3`, that **contradicts committed
repo evidence** and is to be treated as **suspicion of a harness defect**, not as a discovery.
Investigate the harness before reporting anything.

**(b) The width guard.** A coverage gain bought purely by wider intervals is not calibration. For
every cell report `mean_width_REML / mean_width_ML`. If coverage improves while width increases by
a comparable or larger proportion, the finding is reported as **"REML widens"**, not
**"REML calibrates"**. Both numbers appear in the verdict regardless of outcome.

**(c) Convergence guard.** Any cell where REML's converged-and-`pdHess` rate is more than 5
percentage points below ML's is flagged: a coverage difference could then be a survivorship
artifact of *which* replicates produced an interval, not of the estimator.

**(d) Boundary confound.** Report boundary incidence per arm. If REML changes boundary incidence
materially, conditional and unconditional coverage are reported separately, as in D-117.

## 7. D-12 side question (secondary, not gating)

The 2026-07-06 Totoro pilot measured, on a sigma-axis structured SD: Wald coverage **0.9928** but
profile **0.8533**, with the point estimate biased **−21%**. That suggests Wald over-covers because
it is too wide, which *masks* a biased centre, while profile is shape-honest and therefore
*exposes* it. This campaign carries the Wald arm so that contrast can be measured on an ordinary
sigma RE. **This is exploratory and gates nothing** — it is reported as an observation, not a
claim about D-12.

## 8. What this does NOT do

No census cell promotes; the census stays **182 interval_feasible / 60 point_fit_recovery**. No
default changes — `REML` remains opt-in whatever the result. This is Gaussian, ordinary (not
structured) sigma-axis, scalar-target only. The DEFER fence is untouched: the 135-trace campaign,
the full 7-method coverage-mapping grid, `predict()` scale-axis, the CI guard/check split, B4-CI
`SOURCE_COMMIT`, and mc-0282 are all out of scope.

## 9. Compute

Smoke 1 cell × 5 replicates and confirm non-empty, in-range output before any grid. Then size:
if the full grid is under ~10 minutes locally it runs locally (results stay local either way);
otherwise it goes to Totoro, ≤ 150 cores. **Never GitHub Actions (D-50).** The decision and its
timing evidence are recorded in the verdict.
