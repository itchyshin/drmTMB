# D-43 panel — Fisher (inference lens): `missing_response` G3 → G5 promotion

**Reader:** the D-43 panel record and whoever writes the ledger diff if this promotion proceeds.

## Verdict

**PROMOTE-WITH-CAVEATS.** Promote 7 `missing_response` ledger rows — `mr-gaussian,
mr-biv-gaussian, mr-gamma, mr-beta-binomial, mr-binomial, mr-zero-one-beta, mr-zi-poisson` —
from G3 (`point_fit_recovery`) to G5 (archived replicated coverage evidence), at **every** rung
(0.5x/1x/2x) with no exclusions. The remaining 11 `missing_response` rows
(`student, lognormal, poisson, nbinom2, beta, truncated_nbinom2, hurdle_nbinom2,
cumulative_logit, tweedie, skew_normal, zi_nbinom2`) stay at G3 — their campaign evidence is
dominated by interval-availability failures, not coverage failures, and promoting them is a
different, unearned claim.

## What I checked and how

I loaded `docs/dev-log/simulation-artifacts/2026-08-11-g5-authenticated-panel/panel-cell-summary.csv`
(290 rows) directly into R and recomputed pass/fail myself rather than trusting the prose summary
in `docs/dev-log/2026-08-11-g5-admission-set-exhaustiveness.md`:

- Filtered to the 7 candidate routes (`gaussian, biv_gaussian, gamma, beta_binomial, binomial,
  zero_one_beta, zi_poisson`): 132 rows. **`usable_rate == 1` on all 132; `coverage` inside
  `[0.925, 0.975]` on all 132.** Zero exceptions.
- Registry-cell counts per candidate route (15/39/15/15/6/24/18) sum to exactly 132, matching the
  admission doc's table — an independent confirmation of exhaustiveness for the candidate set, not
  a re-read of the claim.
- Failure decomposition across the full 290-row panel: `usable_rate<1` on 42 rows;
  `usable_rate==1` but `coverage` outside `[0.925,0.975]` on exactly 1 row (`poisson`,
  `fixef:mu:(Intercept)`, `0.5x`, coverage 0.9217). This reproduces the brief's "42
  unusable_interval / 1 coverage_outside_policy_band" split from the raw numbers, and confirms
  **none of the 43 failures fall in a candidate route.** Failing routes: `beta(3),
  hurdle_nbinom2(1), nbinom2(6), poisson(2), skew_normal(3), student(15), truncated_nbinom2(6),
  tweedie(1), zi_nbinom2(6)` — all non-candidates.
- Isolated `biv_gaussian` at `rung=="1x"` (13 rows): minimum is `fixef:mu2:(Intercept)`, coverage
  0.9317, mcse 0.0073 — matches the flagged cell exactly. `binom.test(1118, 1200, p=0.95)` gives
  two-sided p=0.0053 (uncorrected, single cell). The expected extreme order statistic among ~132
  draws under a true calibration null is `qnorm(1-1/133) ≈ 2.43` SE; the observed deviation is
  z≈2.5–2.9 depending on which SE is used — consistent with, not larger than, what the single most
  extreme value among 132 tested cells is expected to look like under correct calibration. Checked
  for a systematic rho12/correlation-parameter shortfall: none found — the other two rho12-adjacent
  `1x` cells sit at 0.94–0.96, and `biv_gaussian` rung-level means are flat (0.5x=0.9497,
  1x=0.9490, 2x=0.9493, n=44 each).
- Cross-checked `docs/dev-log/dashboard/capability-ledger/cells.tsv`
  (`awk -F'\t' '$3=="missing_response"'`): 18 rows, all currently `evidence_tier =
  point_fit_recovery`, `test_gate = G3`. The 7 candidates map 1:1 onto the 7 rows named above.
- Read the gate ladder in `docs/dev-log/dashboard/capability-ledger/README.md:53-63`: G3 =
  "known-DGP recovery for all fitted distributional parameters", G4 = "finite correctly named
  interval at a known-DGP point", G5 = "archived replicated coverage evidence". A campaign at
  n=1200 measuring both interval availability and coverage targets G5 directly (subsuming G4).

### Correction 1 (Noether, folded in): the artifact cannot self-certify exhaustiveness

My working draft had planned to cite the admission doc's now-superseded "n_attempt is asserted
from intent" explanation for why the four truncated `beta` cells still read as complete. That
explanation is wrong. Noether verified `n_attempt == nrow(x)` for all 290 reconciled cells, and the
four truncated `beta` 2x cells are **absent from `$summary` entirely** — they were dropped from the
embedded registry *before* the completeness check ran, so `calibration_complete` passes vacuously
for the 290 it does see. The correct statement is: **the reconciled artifact cannot certify its own
exhaustiveness from the inside** — the "290/294" figure and the identity of the missing four are
established only by the external check in `2026-08-11-g5-admission-set-exhaustiveness.md`
(comparing the registry against on-disk cell files with ≥1200 records), not by any internal
validator on the RDS. This does not touch the 7 candidate routes — none of the missing `beta`
cells belongs to a candidate route, and `beta` is not itself a candidate — but it means the
"0 UNAUTHENTICATED / exhaustive" claim rests on that external reconciliation script, which I have
not independently re-run. See Residual risk.

### Correction 2 (Rose, folded in): the interval boundary is scale-dependent, not "profile-first"

My working draft described the boundary as "profile CI where available, Wald otherwise," treating
`profile_ready` as roughly incidental. Rose is right that this understates a structural split:
`inst/sim/R/sim_missing_response_g4g5.R:639` sets `interval_method <-
ifelse(profile_ready, "profile", "wald")`, and `profile_ready` is not a coin flip — for
derived/reporting-scale targets it is set to `FALSE` by construction. I checked this directly in
`R/profile.R:1503-1505`: any non-direct (`is_direct == FALSE`) SD/correlation-type target returns
`list(profile_ready = FALSE, profile_note = "derived_target")` before profiling is even attempted.
In the `biv_gaussian` cell list this maps onto exactly the parameters Rose named: `rho12`,
`sigma1`, `sigma2`, and `cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)` are reporting-scale
derived quantities and always take the Wald branch, while their link-scale counterparts
(`fixef:rho12:(Intercept)`, `fixef:sigma1:(Intercept)`, `fixef:sigma2:(Intercept)`) are direct
targets and can be profile-ready. The correct boundary wording is **profile likelihood for
profile-ready link-scale targets, Wald delta-method for derived/reporting-scale targets** — not a
uniform method, and not "profile-first, Wald as a fallback for occasional failures."

**Neither correction changes the verdict.** Both change the wording I use in the report (see below)
and, for Correction 1, sharpen a residual-risk item I had already flagged as unresolved rather than
close it out.

## Rung-by-rung recommendation

| route | 0.5x | 1x | 2x | recommendation |
|---|---|---|---|---|
| gaussian | 5/5 pass | 5/5 pass | 5/5 pass | promote all 3 rungs, G3→G5 |
| biv_gaussian | 13/13 pass | 13/13 pass (min 0.9317, see ruling) | 13/13 pass | promote all 3 rungs, G3→G5 |
| gamma | 5/5 pass | 5/5 pass | 5/5 pass | promote all 3 rungs, G3→G5 |
| beta_binomial | 5/5 pass | 5/5 pass | 5/5 pass | promote all 3 rungs, G3→G5 |
| binomial | 2/2 pass | 2/2 pass | 2/2 pass | promote all 3 rungs, G3→G5 |
| zero_one_beta | 8/8 pass | 8/8 pass | 8/8 pass | promote all 3 rungs, G3→G5 |
| zi_poisson | 6/6 pass | 6/6 pass | 6/6 pass | promote all 3 rungs, G3→G5 |

No rung of any candidate route should be excluded — the evidence is uniformly clean at every rung
tested. All 11 non-candidate routes stay at G3 unconditionally; this table does not touch them.

## The biv_gaussian 1x ruling

**Promote, with the number recorded**, not silently folded into a blanket "in band" statement.
0.9317 is inside the pre-declared `[0.925, 0.975]` band. The single-cell binomial test is nominally
"significant" (p=0.0053), but that is exactly the behaviour expected once the multiple-comparison
context is made explicit: among 132 tested cells, seeing one value this extreme as the single most
extreme observation is close to what a true null predicts (expected extreme z≈2.4 vs. observed
z≈2.5–2.9). The surrounding rho12/correlation cells and the rung-level means show no directional
drift that would suggest a defect localized to this rung or this parameter class. This is a
"record it, don't hide it" case, not a "hold the route" case. One caveat on the statistical
argument itself: the 132 cells are not fully independent draws (several parameters are estimated
from the same fit/replicate within a route/rung), so the effective number of independent tests is
smaller than 132, which weakens — but does not reverse — the "expected extreme order statistic"
reasoning. A stricter reviewer could ask for this to be quantified before treating the point as
fully closed.

## Sufficiency of the evidence for G5

n=1200 per cell gives MCSE≈0.006–0.007, i.e., roughly ±1.2–1.4 percentage points of resolving power
per cell at 95% confidence. That is enough to detect gross miscalibration — which the campaign did
catch, in non-candidate routes (e.g., `student`'s `fixef:sigma:(Intercept)` cells at 0.899/0.901) —
but not enough, cell by cell, to distinguish 95% from 93–94% with high power. The claim this
evidence supports is the aggregate one: 132 cells across 7 routes × 3 rungs, zero failures, no
directional bias, mean coverage 0.9493 essentially at nominal. That aggregate pattern is strong
evidence even though no single cell in isolation proves calibration to within a point. G5 wording
should say "measured coverage within a pre-declared band across the full tested grid," not "exact
nominal coverage" and not "profile-interval coverage" without qualifying which targets are profile
versus Wald (see Correction 2).

## Availability-vs-coverage honesty

Confirmed independently, not just repeated from the brief: 42 of 43 panel failures are
`usable_rate<1` (an interval could not be computed for some replicates — for profile-ready targets
this is a profile-likelihood failure, e.g. boundary or non-monotonic profile; the derived/
reporting-scale targets never enter this failure mode via profile machinery since they are Wald by
construction), 1 is a genuine coverage failure, and 0 of either type occur in a candidate route.
This split is real, and the report going back to the ledger should say plainly that promoting these
7 routes says nothing about whether the interval-availability defect in the other 11 is fixed. It
should not be framed as "the campaign mostly passed on calibration" when the dominant failure mode
was a different thing (interval computability, not coverage).

## What I tried to falsify and failed to

- A route-level or rung-level pattern in the `biv_gaussian` rho12/cor cells — none found; flat
  across rungs.
- Any candidate-route cell with `usable_rate<1` — none found (132/132 at exactly 1.0).
- Any candidate-route cell outside the policy band — none found (132/132 in band).
- The exhaustiveness claim, reproduced from raw registry-cell counts rather than trusted from
  prose — sums to exactly 132, independently confirming no gap in the candidate set specifically
  (though see Correction 1 for the artifact's own inability to self-certify this).
- A live estimand confound of the class that sank the prior panel (random-effect centring): found
  and read the centring-defect history in
  `docs/dev-log/after-task/2026-08-09-missing-data-capability-drmsem-part-b.md`, which documents
  that a v1 DGP centred random-effect draws (`u <- u - mean(u)`) in a way that can **inflate**
  apparent coverage ("A simulator can fail in the package's favour. Over-coverage reads as 'safe'
  and is a calibration failure" — line 114). This campaign is stamped
  `design_state = centre_random_effects=FALSE`, the corrected, non-inflating DGP — if anything the
  harder test, not an easier one.
- A uniform-method mischaracterization of the interval boundary (Correction 2) — caught by Rose,
  verified against `R/profile.R:1503-1505` and `inst/sim/R/sim_missing_response_g4g5.R:639`; folded
  in above.

## Residual risk

1. **I did not independently recompute from `~/g5run/g5-reconciled-final.rds` on rorqual.** My
   analysis rests entirely on `panel-cell-summary.csv`, a derived artifact, and on the two prose
   documents cited above. Given Correction 1, this matters more than my original draft implied: the
   RDS cannot certify its own exhaustiveness, so the "290/294 accounted for, candidate routes
   unaffected" claim depends on the external `exhaust.R` reconciliation described in the admission
   doc, which I have not re-run myself. A future reviewer with SSH access should re-run that
   reconciliation independently before treating exhaustiveness as closed.
2. A `beta` array job (18826926) was actively rewriting files at the time of review — irrelevant to
   this verdict since `beta` is not a candidate route, but any panel regeneration between now and a
   ledger write should re-diff the candidate-route numbers first, in case a shared script changed.
3. The multiple-comparisons argument for `biv_gaussian` 1x treats the 132 candidate cells as
   approximately independent, which is only approximate (see the ruling above).

## Exact claim-boundary wording I would accept in the ledger

For each of the 7 promoted rows, style-matched to the existing G3 wording:

> "G5 verifies, in addition to the G3 point-recovery claim: at n=1200 replicates per cell, across
> three information rungs (0.5x/1x/2x) and [N] distributional-parameter targets, every interval was
> computable (100% usable) and measured coverage fell inside the pre-declared [0.925, 0.975] policy
> band at every rung, under 25% MCAR response masking with the corrected
> (`centre_random_effects=FALSE`) random-effects DGP. Intervals use profile likelihood for
> profile-ready link-scale targets and Wald delta-method for derived/reporting-scale targets
> (e.g. `rho12`, `sigma1`, `sigma2`, correlation summaries) — not a single uniform method. This does
> not claim exact nominal coverage for any single target (n=1200 resolves calibration to roughly
> ±1.3pp), does not extend to other missing mechanisms, other masking fractions, or structured/slope
> random effects beyond what was fitted, and does not extend to any route/rung outside this grid.
> The biv_gaussian 1x rung's minimum observed coverage (0.9317, mcse 0.0073) is recorded here rather
> than only in the underlying artifact."
