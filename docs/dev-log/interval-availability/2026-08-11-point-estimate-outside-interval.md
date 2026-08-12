# `point_estimate_outside_interval`: root cause and scope

Noether (mathematical-consistency lens), 2026-08-11.
Diagnostic only. No file under `R/`, `src/`, or the capability ledger was modified.

Artifact: `snakagaw@rorqual:~/g5run/g5-reconciled-final.rds` (`$records`, 348,000 rows,
`schema_version` / `cohort` / `summary` / `calibration` / `registry` / `design_state` /
`created_utc` alongside). Package source read in the worktree
`.../scratchpad/wt-interval` at `256e586e5` (branch `claude/interval-availability`,
off `origin/main`). Diagnostic scripts written to `~/g5run/diag/poe*.R` on rorqual;
no campaign was launched.

## 0. A correction to the premise

The brief states `conf.status == "point_estimate_outside_interval"`. That is not where
the flag lives. `table(records$conf.status)` has exactly two levels — `profile` (347,011)
and `profile_failed` (989). The string `point_estimate_outside_interval` is a value of
**`profile.message`**, and the six records carrying it were *already downgraded* to
`conf.status = "profile_failed"` with `conf.low`/`conf.high` set to `NA` and
`interval_usable = FALSE`.

This matters for the framing: the campaign never reported an interval that excluded its
own point estimate. `profile_conf_status_from_diagnostics()`
(`R/profile.R:3105-3114`) maps both `nonfinite_interval` and
`point_estimate_outside_interval` to `"profile_failed"`, and the caller nullifies the
interval before writing the row (`R/profile.R:3024-3027` for the tmbprofile engine,
`R/profile.R:3083-3089` for the endpoint engine). The machinery fails closed. The
serious question is not what these six rows did to the campaign — they were discarded —
but what mechanism produced them and whether that mechanism is silent elsewhere.

## 1. The six records identified

All six are `interval_method = "profile"`, `conf.level = 0.95`,
`design_state = "centre_random_effects=FALSE"`, `mask_fraction = 0.25`,
`profile_ready = TRUE`, `fit_status = "fit_ok"`, `fit_converged = TRUE`,
`target_scale = "link"`, `target_class = "fixed-effect"`,
`conf.status = "profile_failed"`, `profile.boundary = TRUE`,
`interval_usable = FALSE`, `truth_contained = FALSE`.

| row | route_id | parm | rung | replicate | truth | conf.low | conf.high | pdHess | attempt_seed |
|---|---|---|---|---|---|---|---|---|---|
| 183329 | nbinom2 | `fixef:sigma:z` | 0.5x | 754 | 0.20000 | NA | NA | TRUE | 284387674 |
| 211338 | skew_normal | `fixef:sigma:(Intercept)` | 0.5x | 1121 | -0.30000 | NA | NA | TRUE | 49929248 |
| 226594 | student | `fixef:nu:(Intercept)` | 2x | 812 | 1.94591 | NA | NA | **FALSE** | 2114137142 |
| 227679 | student | `fixef:sigma:(Intercept)` | 0.5x | 709 | -0.42000 | NA | NA | TRUE | 1928740381 |
| 247866 | truncated_nbinom2 | `fixef:sigma:z` | 0.5x | 517 | 0.15000 | NA | NA | TRUE | 859150858 |
| 305858 | zi_nbinom2 | `fixef:mu:x` | 0.5x | 870 | -0.30000 | NA | NA | TRUE | 1922287716 |

**The point estimate is not recoverable from the artifact, and neither is the rejected
interval.** The records carry no estimate column (`names(records)` has 37 entries; none
is an estimate), and `conf.low`/`conf.high` were overwritten with `NA` by
`R/profile.R:3025-3027` *before* the row was written. What survives is
`profile_trace` — the captured `TMB::tmbprofile(trace = TRUE)` stdout — and that is what
identifies the mechanism. `checkpoint_paths` points at the per-cell RDS
(`~/g5run/g5/g5-<route>-<parm>-<rung>.rds`), which is the same schema and also lacks the
estimate.

Note `boundary_or_clamp = TRUE` on all six is **not** independent evidence of a clamped
fit: `~/g5run/src/inst/sim/R/sim_missing_response_g4g5.R:1224` defines it as
`isTRUE(profile.boundary) || conf.status == "clamp_limited"`, and `profile.boundary` is
set by the very diagnostic under investigation. It is circular and carries no information
here.

## 2. Root cause

**`TMB:::confint.tmbprofile` anchors the interval at the minimum of the profile *curve*,
not at the fitted MLE. In five of the six records the profile's inner optimizer found a
point with a strictly lower objective than the fitted optimum, which moved the anchor off
the MLE and left the MLE outside the resulting interval.**

### 2a. The anchoring is `which.min`, verified in source

On rorqual (TMB 1.9.18):

```r
function (object, parm, level = 0.95, ...)
{
    i <- which.min(object$value)
    left <- head(object, i); right <- tail(object, nrow(object) - i)
    hline <- 0.5 * qchisq(level, df = 1) + object$value[i]
    lower <- approx(left[[2]], left[[1]], hline)$y
    upper <- approx(right[[2]], right[[1]], hline)$y
    ...
}
```

The threshold `hline` is referenced to `object$value[i]`, the *observed grid minimum*,
and the two sides are split at row `i`. Nothing in this function knows where the MLE is.
`drm_tmbprofile_confint()` (`R/profile.R:3700-3716`) calls it unchanged, and
`drm_profile_target_tmbprofile_confint()` (`R/profile.R:3015-3020`) feeds the result
straight into `profile_interval_diagnostics()`. So if the grid minimum is not the MLE
row, the interval brackets some other point, and the MLE can fall outside it. The
`>=` / `<=` in `profile_interval_diagnostics()` (`R/profile.R:3729-3736`) then fires.

`TMB::tmbprofile`'s own source shows why the grid minimum can move: the non-slice branch
runs `nlminb(start, newfn, newgr, ...)` at each displacement with `start <<- ans$par`
warm-started from the previous point, and `evalAlongLine` begins at `x = 0` (the fitted
value). A warm-started inner solve that walks into a better basin partway along a sweep
returns an objective *below* the value at `x = 0`.

### 2b. The traces show exactly that

Parsing `profile_trace` for the six and computing
`gap = min(finite trace values) - first trace value` (the first value is `f(0)`, the
profile at the fitted target value):

| route / parm | gap (nll units) | trace evaluations |
|---|---|---|
| student `fixef:sigma:(Intercept)` | **-1.994** | 89 |
| nbinom2 `fixef:sigma:z` | **-1.879** | 84 |
| zi_nbinom2 `fixef:mu:x` | **-1.756** | 100 |
| skew_normal `fixef:sigma:(Intercept)` | **-1.564** | 127 |
| truncated_nbinom2 `fixef:sigma:z` | **-0.998** | 83 |
| student `fixef:nu:(Intercept)` | 0.000 | 4 |

Five of six profiles reached an objective 1.0-2.0 nll units *below* the fitted optimum.
For example the nbinom2 trace opens at `307.6368` (the fit), rises to `307.6558`, and
then in the second sweep descends monotonically to `305.7576`. That is a 1.88-unit
improvement on a fit reported as `fit_converged = TRUE, pdHess = TRUE`. With
`hline = 305.7576 + 1.921`, the entire interval sits below the fitted value, so the MLE
is excluded.

The sixth record (student `fixef:nu:(Intercept)`, 2x, `pdHess = FALSE`) is a **different
sub-mechanism**: its four trace values are `-2.6e+141, 6.0e+141, -2.6e+141, 7.4e+141`.
The `nu` profile blew up numerically; `approx` over that value vector returns an
arbitrary pair of abscissae. Same flag, different cause: a degenerate objective from a
fit whose Hessian was already not positive-definite.

### 2c. Rival hypotheses, and why each is excluded

- **Scale mismatch (estimate on link, endpoints on response).** Excluded. All six targets
  are built by the fixed-effect loop at `R/profile.R:1394-1416`, which sets
  `estimate = link_estimate = beta[i]`, `scale = "link"`,
  `transformation = "linear_predictor"`. `profile_transform_interval()`
  (`R/profile.R:3753-3762`) is the identity for `linear_predictor`. The records confirm
  `target_scale = "link"`, `target_class = "fixed-effect"`. Estimate and endpoints are on
  the same scale by construction. (The genuinely response-scale targets — `sigma`,
  `rho12` at `R/profile.R:1425-1470` — are not among the six.)
- **Endpoint ordering swapped by a monotone-decreasing transform.** Excluded twice over:
  no transform is applied to these targets at all, and the only transforms in the package
  (`exp`, `tanh`, `rho12_tanh`) are monotone *increasing*. A swap would also be
  systematic, not 6-in-348,000.
- **Clamped/boundary fit reporting an unclamped estimate.** Excluded. The clamp path is a
  separate, earlier branch: `drm_profile_direct_sd_clamp_trace()` returns
  `clamp_limited` and short-circuits before `confint` is ever called
  (`R/profile.R:3003-3011`). None of the six is `clamp_limited`. The `boundary_or_clamp`
  column that might suggest otherwise is circular (§1).
- **Profile search returning the bracket rather than the crossing.** Excluded for the
  tmbprofile engine: `confint.tmbprofile` interpolates the crossing with `approx`, and
  when it cannot (too few non-NA values) it errors — that error is the *other* 511
  `profile_failed` records, whose `profile.message` is the verbatim
  `"need at least two non-NA values to interpolate"` abort from
  `drm_tmbprofile_confint()` (`R/profile.R:3700-3716`). Different failure, different
  message.
- **Delta-method / derived-target recomputation of the estimate.** Not applicable:
  `target_type = "direct"` for all six; no derived path is involved.

## 3. Scope verdict: **tip of the iceberg, confined to the tmbprofile engine**

The flag is a *consequence* test (does the MLE land outside?), not a *cause* test (did
the profile beat the fit?). The cause is measurable directly from the stored traces, and
it is roughly 100× more common than the flag.

Computed over all 348,000 records (`~/g5run/diag/poe7.R`, 36 s):

| statistic | count |
|---|---|
| records with a usable trace | 296,927 |
| `gap < -1e-6` (profile beat the fit at all) | **973** |
| `gap < -1e-3` | **764** |
| `gap < -0.1` | 605 |
| `gap < -1.0` | 464 |
| of the 764: interval discarded by some flag | 519 |
| of the 764: **interval retained, `interval_usable = TRUE`, unflagged** | **245** |
| of the 764: caught by `point_estimate_outside_interval` | 5 |

So **245 records carry a retained, coverage-counted interval that was anchored at a point
the profile itself considered better than the reported MLE, and no status flag fired.**
That is 0.083% of the 295,940 usable traced records.

The coverage signature is consistent with mis-anchoring, and dose-responsive in the size
of the anchoring error:

| subset (usable intervals only) | n | empirical coverage |
|---|---|---|
| not shifted | 345,931 | 0.9479 |
| shifted, 0 < &#124;gap&#124; ≤ 0.1 | 142 | 0.930 |
| shifted, 0.1 < &#124;gap&#124; ≤ 1 | 91 | 0.846 |
| shifted, &#124;gap&#124; > 1 | 12 | 0.750 |

A monotone decline in coverage with the size of the objective improvement is what a
shifted anchor predicts. I flag one honest confound: shifted records are also the
numerically hardest fits (185 of 245 are at the 0.5x information rung), so part of the
coverage deficit may be genuine small-information behaviour rather than the anchoring bug
alone. With n = 245 the MCSE on 0.890 is about 0.020, so the 0.948 → 0.890 contrast is
roughly 3 SE — real, but not a precise effect size.

**Aggregate impact is negligible.** Removing all 245 from their routes moves route-level
coverage by at most 0.0003:

```
truncated_nbinom2 0.9458 -> 0.9458   student 0.9393 -> 0.9396
skew_normal       0.9461 -> 0.9463   nbinom2 0.9499 -> 0.9500
zi_nbinom2        0.9488 -> 0.9488   hurdle_nbinom2 0.9507 -> 0.9508
tweedie           0.9451 -> 0.9450
```

### The engine boundary (important, and it bounds the blast radius)

51,073 records have **no trace at all** (`nchar(profile_trace) == 0`). These are not
undiagnosed — they never touched `TMB::tmbprofile`. Their `parm` values are exactly the
classes routed to the **endpoint engine** by
`profile_endpoint_target_supported()` (`R/profile.R:3213-3227`):
`sd:mu:(1 | id)` (29,472), `rho12`, `sigma1`, `sigma2`,
`sd:mu:mu1:(1 | p | id)`, `sd:mu:mu2:(1 | p | id)`, `cor:mu:cor(...)` (3,600 each).
No `fixef:*` target lacks a trace (one lone exception out of 44,400).

The endpoint engine is **structurally immune to this failure**:
`drm_profile_endpoint_result()` (`R/profile.R:3153-3186`) takes
`theta_hat <- object$opt$par[[position]]` and `nll_hat <- object$opt$objective`, then
root-finds `nll(theta) - nll_hat = cutoff` outward in each direction from `theta_hat`.
The estimate is the *origin* of the search, so it always lies between the two crossings.
If the inner solve finds a better objective than `nll_hat`, the effect is that the
bracket keeps widening — the interval becomes too wide, never one that excludes the
estimate. That is a different (and much less alarming) failure mode, and it is invisible
to the same diagnostic, so I state it as an open question rather than a clean bill of
health.

**Verdict.** Confined in the sense that matters for the campaign: the affected population
is bounded (245 unflagged usable records, 0.083%), it is entirely inside the tmbprofile
engine, and its aggregate coverage effect is ≤ 0.0003 per route. Tip-of-the-iceberg in
the sense that matters for the code: the shipped diagnostic catches 5 of 764 instances of
the underlying defect, i.e. it is a ~0.7%-sensitivity detector for the condition it is
meant to guard against. Anyone reading `point_estimate_outside_interval = 6` as "six bad
intervals" is reading it wrong; the correct reading is "six cases where the underlying
problem was severe enough to become self-evident".

## 4. Are any promoted routes affected? **No.**

The seven routes just promoted to G5 — `gaussian`, `biv_gaussian`, `gamma`,
`beta_binomial`, `binomial`, `zero_one_beta`, `zi_poisson` — have:

- **zero** of the six flagged records;
- **zero** records with `gap < -1e-6`, at any usability status;
- and this is a non-vacuous zero: they contribute 125,800 tmbprofile-engine records with
  a real trace to test against.

| promoted route | records | tmbprofile-engine (traced) | shifted |
|---|---|---|---|
| gaussian | 18,000 | 14,400 | 0 |
| biv_gaussian | 46,800 | 25,200 | 0 |
| gamma | 18,000 | 14,400 | 0 |
| beta_binomial | 18,000 | 14,400 | 0 |
| binomial | 7,200 | 7,200 | 0 |
| zero_one_beta | 28,800 | 28,800 | 0 |
| zi_poisson | 21,600 | 21,600 | 0 |

Every affected route is unpromoted: `student` (510 shifted), `truncated_nbinom2` (104),
`nbinom2` (60), `skew_normal` (51), `zi_nbinom2` (29), `hurdle_nbinom2` (7),
`tweedie` (3). **The promotion is not implicated.** The defect concentrates in the
heavy-tailed and count/zero-inflated families whose inner optimizations are hardest,
exactly where one would expect it.

## 5. Recommended fix

I recommend fixing it, at low priority, and I recommend fixing the *detector*, not the
interval.

1. **Add a cause-level diagnostic to the tmbprofile path.** At
   `R/profile.R:3015-3020` the profile data frame is already in hand and
   `object$opt$objective` is available. Compare `min(profile$value)` against the
   objective at the fitted parameter; if the profile is lower by more than a tolerance
   (1e-3 nll units is the natural threshold — it separates 764 from 0 cleanly and 973
   at 1e-6, so the distribution is not dense near zero), emit a new message such as
   `profile_below_fit_objective` and route it through
   `profile_conf_status_from_diagnostics()` to `profile_failed`. This turns a
   0.7%-sensitivity detector into a complete one, costs no additional model
   evaluations, and is a pure addition — no existing passing record changes status.
2. **Do not attempt to repair the interval in place.** A profile that beats the fit means
   the *fit* is wrong, not the interval. Re-anchoring `confint` at the MLE while the MLE
   is not the optimum would produce a confidently-wrong interval instead of a flagged
   one. If a repair is ever wanted, the correct one is to refit from the better point and
   re-profile — that is a real cost and belongs in `drmTMB` fit control, not in
   `confint`.
3. **Note the convergence gap for the record.** Five of the six had
   `fit_converged = TRUE` *and* `pdHess = TRUE`. `pdHess` is a local curvature test and
   cannot see a better basin 1-2 nll units away. This is not a bug in `pdHess`; it is a
   reason not to treat `pdHess = TRUE` as evidence of a global optimum, which the repo's
   own LOAD-FIRST manifest already says.
4. **Consider extending the endpoint engine to `linear_predictor` fixed-effect targets**
   as a separate, larger piece of work. It anchors at `theta_hat` by construction and
   therefore cannot produce this class of interval at all. `profile_endpoint_target_supported()`
   currently excludes them (`R/profile.R:3213-3227`). This is a design change, not a
   bug fix, and should not be bundled with (1).

None of this blocks the G5 promotion, and none of it requires re-running the campaign:
the 245 affected records are all in unpromoted routes and shift no route's coverage by
more than 0.0003.

## 6. Confidence

- **Mechanism (`which.min` anchoring + profile beating the fit): high.** It is deductive
  from the printed `TMB:::confint.tmbprofile` source plus `TMB::tmbprofile`'s
  warm-started inner solve, and the stored traces show the below-baseline descent
  directly in five of six records. I did not need to reproduce a fit to establish it.
- **The sixth record (`student fixef:nu`) being a distinct numerical blow-up: high.**
  Objective values of ±1e+141 with `pdHess = FALSE` are unambiguous.
- **Scope counts (973 / 764 / 245 / 519, and the promoted-route zeros): high.** These are
  exact counts over the full artifact, not estimates. The one assumption is that the
  first trace value is `f(0)`; that is confirmed in `TMB::tmbprofile`'s `evalAlongLine`
  (`x <- 0; y <- f(x)`), and every sweep restarts there.
- **Coverage attribution (0.948 → 0.890): moderate.** The dose-response by |gap| is the
  right shape, but n = 245, MCSE ≈ 0.02, and the shifted records are confounded with the
  0.5x information rung. I would not quote the 0.890 as an effect size.
- **Endpoint-engine immunity: moderate-high.** The argument from
  `R/profile.R:3153-3186` is sound (search originates at `theta_hat`), but I verified it
  by reading the code, not by exercising it. The endpoint engine's own failure mode —
  an over-wide interval when the inner solve beats `nll_hat` — is **untested here** and
  is the honest residual gap in this analysis. Settling it would need a targeted probe
  of `drm_profile_endpoint_crossing()` on a fit known not to be at its optimum; that is a
  local unit-scale experiment, well under 30 minutes, not a campaign.

## Reproduction

```sh
SOCK=$(ls ~/.ssh/cm-*rorqual* | head -1)
ssh -o ControlPath="$SOCK" -o ControlMaster=no -o BatchMode=yes rorqual \
  'module load StdEnv/2023 r-bundle-bioconductor/3.21; export R_LIBS_USER=$HOME/R/g4g5-lib
   cd ~/g5run/diag && Rscript poe3.R   # the six records
   Rscript poe6.R                      # TMB:::confint.tmbprofile source
   Rscript poe7.R                      # full-campaign gap statistic (36 s)
   Rscript poe10.R'                    # engine attribution + promoted-route zeros
```
