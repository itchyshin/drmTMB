# E1 probe — HALTED before grading, and why

**Status: the grid was NOT run against the frozen decision rule.** Written 2026-08-09, the same
night the pre-registration was written, before any fixture was graded.

## What happened

The E1 harness was built, smoked, and repaired three times (below). At the point where it produced
correct ray evaluations, the **logit control** still scored FAIL. Per PREREGISTRATION §6 rule 1, a
control failure means **the harness is wrong, not the estimator** — so no probit or cloglog result
from that run may be interpreted.

Inspecting a single ray past its guards (§6 rule 2) showed the harness was not merely buggy: **the
frozen decision rule cannot be evaluated as written.**

## The measurement

One logit fixture (`G = 10`, `n_g = 5`, `σ = 1`, `p = 2`, complete separation), profiled ray:

| `t` | Jeffreys bonus | log-likelihood |
|---|---|---|
| 0 | +0.8269 | −34.66 |
| 1 | +0.6870 | −34.76 |
| 2 | +0.4304 | −43.58 |
| 5 | −0.1803 | −85.31 |
| 10 | −0.7483 | −163.68 |
| 20 | −1.3505 | **−Inf** |
| 50 | −2.2922 | −Inf |
| 100 | −3.0430 | −Inf |
| 300 | −5.2369 | −Inf |
| 1000 | **`rank_deficient_information`** | −Inf |
| 3000 | `rank_deficient_information` | −Inf |
| 10000 | `rank_deficient_information` | −Inf |

**The objective descends, decisively and early.** The Jeffreys term falls monotonically throughout
the computable range, and the likelihood reaches −Inf by `t = 20`.

## Why the rule cannot be evaluated as frozen

Two of the pre-registered parameters were chosen without knowing the numerics:

1. **`t_max = 10⁴` is beyond the computable range.** Past `t ≈ 10³` every working weight `w(η)`
   underflows to zero, so `det XᵀWX` underflows and the implementation correctly reports
   `rank_deficient_information`. **That is the numerical signature of the §2 condition
   `det XᵀWX → 0`, not a failure** — but it means no *number* exists at those `t` to test
   monotonicity against.
2. **The "drop < −50 nats" threshold presumes a finite objective.** The likelihood is −Inf from
   `t = 20` onward, so the drop is not a real number over most of the specified range.

## Why the probe was HALTED rather than adjusted

Rescoring `rank_deficient_information` as "descent" would convert FAIL to PASS for every fixture.
That is a **post-hoc reinterpretation of the decision rule**, which PREREGISTRATION §6 rule 6
forbids, and it is precisely the error the SE-calibration campaign made earlier the same day when it
read `R > 1` as "conservative" without asking whether `R` was meaningful.

The reinterpretation may well be *correct*. It is not mine to make after seeing the output.

**The criterion needs revision by its author (Noether), before any grading**, along these lines:
- replace `t_max = 10⁴` with the largest `t` at which the penalty remains computable, determined
  per fixture rather than fixed in advance;
- state explicitly whether `det XᵀWX` underflowing to rank-deficiency **counts as** descent — it is
  the finite-precision image of the §2 limit, so it probably should, but that must be decided as a
  criterion, not as a rescue;
- replace the absolute nat threshold with a rule that admits −Inf, since the likelihood diverges
  well inside the range.

## Three harness bugs found and fixed on the way (all mine, none drmTMB's)

1. **Internals not exported.** The runner called `mspl_penalty_components()` directly; on Totoro the
   *installed* package hides internals, unlike `devtools::load_all()` locally. Needs `drmTMB:::`.
2. **A stale build.** Totoro carried a build predating the `link` argument fix by 30 minutes, so
   every call errored with *"unused argument (link)"*. Local fixes do not reach the cluster by
   themselves.
3. **`is.finite()` discarded the evidence.** The first scorer filtered non-finite `R(t)`, which
   removed exactly the −Inf values that constitute descent.

## What this does and does not establish

**Does:** the MSPL objective descends along an escape ray for a logit fixture, over the computable
range — consistent with the proved logit result, and a working instrument for probit/cloglog once
the criterion is repaired.

**Does NOT:** anything about probit or cloglog. No fixture for those links has been validly graded.
The guard at `R/mspl-estimator.R:179-184` stays, on the same grounds as before — doc 253's
underived coercivity — with no empirical evidence yet added either way.
