# Interval availability is not a nuisance: it predicts miscalibration

**Reader:** whoever writes the revised G5 calibration policy, and the panel that reviews it.

**Purpose.** The arc's premise was that interval *availability* and *calibration* are different things
being conflated by one pass rule, and that gating on coverage alone would stop a numerical blip from
masquerading as a calibration failure. The first half is right. **The second half is not**, and this
note is the evidence that changed it.

## The current rule

`mr_g5_calibration_gate()`, `inst/sim/R/sim_missing_response_g4g5.R:943`:

```r
calibration_available <- n_interval_usable == n_planned                    # :966  all-1200
calibration_pass      <- calibration_complete & calibration_available &
                         calibration_precise  & calibration_in_band        # :968
```

A cell fails if even one of its 1200 replicates yields no usable interval. Under this rule the
authenticated campaign scored **247 pass / 43 fail of 290**, with 42 of the 43 failing on availability.

## The finding: coverage degrades monotonically with availability

Computed over all 290 cells of `g5-reconciled-final.rds` (`~/g5run/policy_sensitivity.R`). Coverage is
as the artifact reports it — conditional on the interval being usable.

| availability | cells | mean coverage | min | in band [0.925, 0.975] |
|---|---|---|---|---|
| ≤ 0.5 | 1 | **0.4008** | 0.4008 | 0 / 1 |
| 0.5 – 0.9 | 3 | **0.7800** | 0.7258 | 0 / 3 |
| 0.9 – 0.99 | 13 | 0.9215 | 0.8750 | 9 / 13 |
| 0.99 – 0.999 | 16 | 0.9378 | 0.9233 | 15 / 16 |
| 0.999 – 1 | 9 | 0.9454 | 0.9367 | 9 / 9 |
| exactly 1 | 248 | 0.9484 | 0.9217 | 247 / 248 |

This is a clean dose–response. **A cell that struggles to produce intervals is also a cell whose
intervals cover badly.** Availability is not an independent nuisance to be reported and set aside; it
carries information about calibration.

> **Uncertainty on the pivotal row, added after Rose's audit.** The 0.9–0.99 bucket is the entire
> empirical basis for not lowering the floor, and it is **n = 13**. Its mean of 0.9215 carries
> SE 0.0055, so the 95% interval is **[0.9107, 0.9323] — which straddles the 0.925 band floor**. The
> mean is also pulled by two outliers (0.8750, 0.8883); the **median is 0.9292**, inside the band.
> Reporting mean and min without spread overstates the separation between this bucket and the ones
> above it. The bucket boundaries here are **right-closed**, `(lower, upper]`; an earlier draft mixed
> conventions between this table and the prose below it.

### Three candidate mechanisms — (b) was adopted, then excluded; (c) holds for the heavy cells

**(a) Selection.** `near_sd_boundary` accounts for 835 of the unusable records. If profiling fails
preferentially when a variance component sits near zero, the replicates that *do* yield an interval
are the well-identified ones, and the reported coverage for a low-availability cell is a **conditional
quantity over a selected subsample** rather than the coverage a user would experience.

**(b) A common cause — optimizer trouble.** This was the arc's first hypothesis and it is now the
weaker one. The companion diagnosis
([`2026-08-11-point-estimate-outside-interval.md`](2026-08-11-point-estimate-outside-interval.md))
found **764 records where the profile located a point below the fitted objective** — i.e. the fit did
not reach the MLE. Those records concentrate in precisely the low-availability routes:
`student` 510, `truncated_nbinom2` 104, `nbinom2` 60, `skew_normal` 51, `zi_nbinom2` 29. Among the
**245** such records that nonetheless kept a retained, coverage-counted interval, coverage is
**0.890 against a 0.948 baseline**, and it degrades with the size of the objective gap
(0.930 / 0.846 / 0.750).

That points at a shared upstream cause: a fit that has not converged produces both a profile that
cannot bracket a crossing (→ unavailable) and, where it does return endpoints, an interval anchored
off the true optimum (→ undercoverage). Availability and coverage would then be **two symptoms of one
defect**, not one causing the other.

**(c) Genuine identifiability boundaries — this is the answer for the heavy cells, and it settles it.**
The concentrated-failure diagnosis
([`2026-08-11-diagnosis-concentrated-failures.md`](2026-08-11-diagnosis-concentrated-failures.md))
**refuted (b) directly**: reprofiling from scratch at the reported MLE, independent of both drmTMB
profile engines, found no non-convergence (`|Δnll| < 0.01` near `theta_hat`). `near_sd_boundary` and
`nonfinite_interval` do share one root cause, but it is not a broken optimizer — **the profile
genuinely does not cross the χ²₁ threshold before the internal floor.** Three of the four heavy cells
are identifiability limits; `student fixef:nu` is mixed, majority genuine `nu → ∞` flatness plus a
separable `TMB::tmbprofile()` bracket-search overflow. **None would flip pass/fail from an engine fix.**

So the honest reading is that low availability is usually the parameter telling you something true:
it is near a boundary, and near a boundary the profile has no crossing to find and the interval is
correspondingly hard to cover. Selection (a) remains plausible as a contributor and is not excluded;
optimizer failure (b) is excluded for these cells.

## The decisive argument against the all-1200 rule

The diagnosis makes a structural point that is stronger than any of the above, and it is statistical
rather than practical:

> the all-1200 bar will fail cells with any nonzero genuine boundary-touching rate by binomial chance,
> independent of code quality.

If a parameter legitimately sits near a boundary on a fraction *p* of draws, the probability a cell of
1200 replicates produces 1200 usable intervals is (1 − *p*)¹²⁰⁰. At *p* = 0.001 that is **0.30**; at
*p* = 0.002 it is **0.09**. A perfectly well-behaved cell fails the rule most of the time, and whether
it passes is close to a coin toss over which seeds were drawn.

**The all-1200 rule is therefore not merely strict — it is incoherent for any parameter that can
legitimately approach a boundary.** That, and not the convenience of admitting 25 more cells, is the
reason to replace it.

**Two limits on this argument, both raised by Rose's audit and both conceded.**

*It assumes independence across replicates, and that assumption is unverified.* The binomial form
requires boundary-touching to be iid over the 1200 draws. Replicates within a cell share a design, so
they may not be. **The direction is unfavourable to the claim**: positive dependence would *raise*
P(all 1200 usable) and weaken the incoherence result, so this argument is not conservative in its own
favour. Whether the simulator redraws the design per replicate has not been traced.

*It is a negative result only.* It establishes that all-1200 is a bad rule. It says **nothing** about
where the replacement floor should sit — 0.99, 0.98 and 0.97 are equally consistent with it. Calling
it "decisive" (as an earlier draft did, and as commit `19e4a1d03` repeats) conflates a sound negative
with a positive it cannot support. The floor rests on the out-of-band discontinuity above, not on this.

## Note on the 245 contaminated records

Removing all 245 non-MLE-anchored records moves route coverage by ≤0.0003, so the table above stands
as a description of the campaign.

## Consequence 1 — the obvious fix is wrong

The mechanical change suggested by reading the code is to drop `& calibration_available` from the pass
predicate. Threshold sensitivity over the same 290 cells:

| rule (full gate: availability × in band × MCSE ≤ 0.01) | cells passing |
|---|---|
| `avail == 1` (current) | 247 |
| `avail ≥ 0.999` | 256 |
| **`avail ≥ 0.99`** | **272** |
| `avail ≥ 0.98` | 276 |
| `avail ≥ 0.97` | 280 |
| `avail ≥ 0.95` | 280 |
| `avail ≥ 0.90` | 280 |
| no availability constraint | 280 |

> **Corrected 2026-08-11 after Rose's closeout audit.** An earlier version of this table reported 277
> at 0.95 and 279 at 0.90, and omitted the 0.98 and 0.97 rows — the only two that bracket the actual
> decision. The error was scoring `availability & in_band` while the shipped gate also requires
> `MCSE ≤ 0.01`: the table described a predicate that was never the one in force. Re-verified directly
> against the artifact (`~/g5run/verify_rose.R`).

**The corrected shape changes the argument.** The lowest availability of any in-band, precise cell is
**0.9708**, so nothing whatever is gained below 0.97. This is not a gentle ramp on which 0.99 is one
point among many — it is a **step to a plateau at 0.97**. Any threshold in [0.97, 1) admits between 272
and 280 cells, and the choice between them cannot be made from this table alone.

## Consequence 2 — but the catastrophic cells disqualify themselves

Worth recording, because it bounds the risk of getting the threshold slightly wrong. The three
lowest-availability cells fail on coverage regardless:

| cell | usable | conditional coverage |
|---|---|---|
| `truncated_nbinom2 sd:mu:(1 | id)` 1x | 498 / 1200 | **0.4008** |
| `student fixef:nu:(Intercept)` 2x | 912 / 1200 | **0.7258** |
| `truncated_nbinom2 fixef:sigma:(Intercept)` 1x | 926 / 1200 | **0.7325** |

Even with availability removed entirely, none passes. The selection effect is severe enough to be
self-reporting at the extreme — it is the *middle* of the range, not the tail, that a careless rule
would let through.

## Recommendation

**Report availability; gate on coverage AND availability ≥ 0.99.**

**The justification originally given here was circular and has been replaced.** It read: the line
"admits the 25 cells that miss by ≤ 12 replicates of 1200". Since 12/1200 = 0.01, that is "availability
≥ 0.99" restated — a description of the threshold, not evidence for it. The threshold was also chosen
with the admission count already in view, and carries **no pre-registration**, in a repository that
pre-registers campaigns routinely (`61169b204`, `b352116ab`, `822117366`). Treat it as a **post-hoc
choice, disclosed as such**.

**The actual basis is a discontinuity in the out-of-band rate**, which the sensitivity table above
cannot show:

| availability band | cells | out of band |
|---|---|---|
| [0.97, 0.99) | 11 | **3** |
| (0.99, 0.999] | 16 | 1 |
| (0.999, 1) | 9 | 0 |
| exactly 1 | 248 | 1 |

A cell just below the line is out of band roughly **27%** of the time; just above it, ~6%; at or near
full availability, under 1%. That break sits at 0.99, and it is why the floor stops there rather than
riding the plateau down to 0.97. This is the argument the recommendation rests on.

**One boundary cell is admitted that the prose above would exclude.** The floor is `>=`, so
`student fixef:mu:x` 0.5x — availability exactly 0.9900, coverage 0.9317 — passes, while the bucket
table places it in the `(0.9, 0.99]` band. The earlier text claimed the rule "stops immediately before"
that zone; it stops *within* it by one cell. Stated rather than resolved: the cell's coverage is in
band on its own merits, and moving the comparison to `>` to exclude it would be a change made to fit
the prose rather than the evidence.

Additional requirements, following the panel lenses:

- Where availability < 1, coverage must be **labelled a conditional quantity** (Fisher).
- Availability must appear as its **own reported number** on every row, not folded into a pass/fail.
- No cell may change status without its **old-rule verdict recorded alongside** — a rule change that
  converts a past failure into a pass is indistinguishable from moving the goalposts unless both
  numbers are visible.

## What this does not settle

The heavy-cell question **is** now settled — see §(c) above and
[`2026-08-11-diagnosis-concentrated-failures.md`](2026-08-11-diagnosis-concentrated-failures.md):
three of the four are genuine identifiability limits and none would flip pass/fail from an engine fix.
An earlier version of this section described that question as still open, and was stale.

What remains genuinely unsettled:

- **Whether 0.99 is the right line, as opposed to a defensible one.** It rests on an out-of-band
  discontinuity across 11 and 16 cells respectively. That is thin, and it was chosen post hoc. A
  future campaign should **pre-register the floor** rather than inherit this one.
- **Whether replicates are independent**, which the (1−p)¹²⁰⁰ argument assumes and nobody has traced.
- **Mechanism (a), selection**, which is neither established nor excluded.

**The 0.99 line is a reading of this campaign, not a constant.** If the `student nu` tmbprofile
overflow or the below-fit anchoring defect are fixed, the availability distribution moves and the floor
should be re-derived rather than carried forward.

## Reproduce

```
ssh rorqual 'module load StdEnv/2023 r-bundle-bioconductor/3.21; \
  export R_LIBS_USER=$HOME/R/g4g5-lib; Rscript ~/g5run/policy_sensitivity.R'
```
