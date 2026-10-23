# The 73 "re-run" cells — scoping, and why they are not a compute job

**Arc:** drmTMB interval-claim truth audit · lane `claude/lane-interval-truth-audit` · 2026-08-15
**Status:** SCOPED, NOT STARTED. **No compute spent.** D-139 estimate below.

## The headline

**"Re-run the 73" is not a compute job. It is a fixture-and-contract construction programme.**

A re-run presumes there is something to re-run. There is not:

| | of the 73 |
| --- | ---: |
| have a frozen campaign **contract** (i.e. a declared `true_parameter_scale`) | **0** |
| have a **profile runner** on disk | **0** |
| have neither | **73** |

The 12 that appeared to have a runner all cite `tools/check-capability-runtime.R` — a **runtime
capability checker, not a profile runner**. It cannot produce a profile interval.

So even if every one of the 73 were profiled tomorrow, **there would be no truth to check the
intervals against.** The location check needs a declared, derived `true_parameter_scale`, and not one
of these cells has ever had one. This is the difference between the 116 (evidence exists, truth
recoverable — re-check) and the 73 (neither exists — construct).

## What the 73 actually are

```
tier      : 47 interval_feasible · 22 inference_ready_with_caveats · 4 supported
axis      : 56 model_surface · 12 missing_response · 5 association
estimator : 66 ML · 2 REML · 5 two_stage_Godambe
tranche   : 56 legacy-census (of 73)
```

**The 47 `interval_feasible` cells are 47 DISTINCT (family × provider × dpar × effect_type)
combinations — one per cell.** There is no fixture reuse to exploit; every cell is its own DGP.

```
family    : biv_gaussian 7 · student 5 · beta_binomial 4 · gamma 4 · zero_one_beta 4 ·
            hurdle_nbinom2 3 · lognormal 3 · truncated_nbinom2 3 · tweedie 3 · zi_nbinom2 3 · …
provider  : none 45 · phylo 2
effect    : fixed 37 · ordinary_re_intercept 5 · ordinary_re_slope 3 · structured 2
dpar      : mu 19 · sigma 9 · alpha 5 · nu 2 · zi 2 · hu 1 · zoi 1 · coi 1 · rho12 1 · …
```

### Two structural facts that change the design

1. **37 of 47 are `fixed`-effect targets, not random-effect SDs.** The whole truth-gate apparatus —
   manifest, `source_kind` (`fixture_builder` / `arc1_runner_constant`), the `sd:…` target grammar —
   was built for **RE-SD** targets. A fixed-effect coefficient's truth is far *easier* to declare (it
   is the simulated β), but the manifest and gate have never carried one. **Extending the gate to
   fixed-effect targets is a design decision, not a fixture chore**, and it should be taken
   deliberately rather than discovered mid-campaign.
2. **The 5 `association` cells (`two_stage_Godambe`) can never be closed this way.** Established in
   Wave 1: their intervals come from a Godambe sandwich, not from `tmbprofile`. No profile mechanism
   applies. They need either a separate Wald/sandwich-truth check or an explicit out-of-scope label.

## D-139 estimate

**The compute is negligible; the work is design.** Each individual profile is seconds to minutes —
the repaired q4 fit measured **7.5 s**, and a q1 fixed-effect fit is far cheaper. Even 73 profiles
with 5 seeds each is well under an hour of CPU. **Neither Totoro nor DRAC is warranted.**

What is expensive, per cell: design a DGP with a known true value → write the frozen contract → wire a
runner → profile → verify bracketing. With 47 distinct combinations and no reuse, a defensible figure
is **roughly 0.5–1.5 h per cell of careful work**, i.e. **~40–70 h** for the 47, plus the gate
extension for fixed-effect targets, plus a separate decision on the 22 + 4 higher-tier cells.

**That is a multi-arc programme, not a slice of this arc.** I am not starting it, and I would not
recommend absorbing it here.

**Confidence in that estimate: moderate.** It rests on the measured per-fit cost and the 47-distinct-
combination count, both solid. It does *not* rest on a pre-run of an actual new fixture build, because
none exists to measure. The first three cells would firm it up considerably.

## Recommendation

Split it, and do the cheap high-value part first:

1. **Decide the fixed-effect question first** (design, ~half a day). Can the truth manifest carry a
   fixed-effect coefficient target? If yes, 37 of the 47 become genuinely tractable, because their
   truth is simply the simulated β rather than a latent SD derived through a covariance structure.
2. **Then a pilot of 3 cells**, one per family shape, to replace the estimate above with a measurement.
3. **Handle the 4 `supported` and 22 `inference_ready_with_caveats` cells as a claims question, not a
   fixture question.** All four `supported` cells rest on evidence rows with **no command, no run_id,
   no replicates**, and two state `coverage=planned` in their own boundary. Whether the ledger's top
   tier should be occupied by cells with no run behind them is a decision about the ledger, and it
   does not wait on any fixture work.
4. **Label the 5 association cells out of the profile gate's domain**, explicitly, rather than leaving
   them looking unexamined.

## What is NOT established

- No fixture was built, no contract written, no profile run. **Nothing here is measured about the
  construction cost** beyond the per-fit timing.
- Whether every one of the 47 combinations is even *fittable* at a useful information rung is unknown;
  some may turn out to be weakly identified, as the spatial cells were.
- The 12 `missing_response`-axis cells may be closable by a different instrument than a profile —
  not investigated.
