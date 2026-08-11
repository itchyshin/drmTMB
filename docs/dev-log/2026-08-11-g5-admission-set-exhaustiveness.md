# The four unreconciled G5 cells, and why the admission set is now exhaustive

**Reader:** the next D-43 panel, and anyone deciding whether a `missing_response` row may leave G3.

**Purpose.** The first D-43 panel withheld promotion on one blocking objection, raised independently
by two reviewers: the admission set was incomplete — 290 of 294 registry cells were reconciled, and
nobody had identified the missing four. This note identifies them, gives the cause, and states
exactly which claims the gap does and does not touch.

**Short answer.** The four cells are all `beta` at rung `2x`. `beta` is neither a promotion candidate
nor one of the nine clean routes, and **every cell of all seven candidate routes is complete**. The
objection does not reach the promotion set.

## The four cells

| Cell | Array task | Rows retained | Result |
|---|---|---|---|
| `beta fixef:mu:(Intercept)` 2x | `18777800_222` | 818 / 1200 | `TIMEOUT` at 08:00:14 |
| `beta fixef:mu:x` 2x | `18777800_223` | 1042 / 1200 | `TIMEOUT` at 08:00:14 |
| `beta fixef:sigma:(Intercept)` 2x | `18777800_224` | 851 / 1200 | `TIMEOUT` at 08:00:14 |
| `beta fixef:sigma:z` 2x | `18777800_225` | 1132 / 1200 | `TIMEOUT` at 08:00:14 |

The fifth cell in that block, `beta sd:mu:(1 | id)` 2x (task 226), completed in 2:54.

**These are truncated runs, not filtered results.** `replicate` is contiguous `1..N` in each file, and
`sacct` reports `TIMEOUT` against an 8:00:00 limit. No fit was rejected, excluded, or lost to a guard;
the wall clock simply ran out. The distinction matters: a filtered result would be evidence about the
estimator, whereas a truncated result is evidence about the scheduler.

## Exhaustiveness of the claim-bearing routes

Checked by comparing every registry cell against the set of cell files holding ≥1200 records
(`~/g5run/exhaust.R`):

| Route | Registry cells | Complete | Status |
|---|---|---|---|
| `gaussian` | 15 | 15 | EXHAUSTIVE — candidate |
| `biv_gaussian` | 39 | 39 | EXHAUSTIVE — candidate |
| `gamma` | 15 | 15 | EXHAUSTIVE — candidate |
| `beta_binomial` | 15 | 15 | EXHAUSTIVE — candidate |
| `binomial` | 6 | 6 | EXHAUSTIVE — candidate |
| `zero_one_beta` | 24 | 24 | EXHAUSTIVE — candidate |
| `zi_poisson` | 18 | 18 | EXHAUSTIVE — candidate |
| `lognormal` | 15 | 15 | EXHAUSTIVE |
| `cumulative_logit` | 3 | 3 | EXHAUSTIVE |
| `beta` | 15 | **11** | the four cells above |

No missing cell belongs to a promotion-candidate route, and none belongs to the nine routes reported
as passing every cell. That claim therefore holds exhaustively.

## One correction to the campaign record

**`beta`'s reported "3 fail / 8 pass" covers 11 of 15 cells and must be read as partial.** It is not a
route result and must not be written into the ledger as one. Whether the remaining four change the
balance is unknown until they finish.

## A fifth defect of the same class as the four already found

The campaign's four known defects — the intercept centring, the frozen `skew_normal` DGP, the permuted
`student` quantile multiset, and the two wrong-scale truth constants — share a shape: **each passed
every procedural check because the check could not see the thing that was wrong.**

The truncation belongs to that family, but by a different mechanism than this note first claimed.

**The incomplete cells are dropped from the artifact's embedded registry before the completeness
check runs.** `$summary` holds 290 rows, not 294; the four truncated cells are absent from it
entirely, and `$registry` has been reduced to match. `calibration_complete` therefore evaluates only
over cells that were already complete — it passes **vacuously**, and it would pass no matter how many
cells had been dropped. The artifact cannot certify its own exhaustiveness: nothing inside it records
that four cells were expected and are missing.

That is why the gap had to be found by inspecting the registry against the cell files from outside,
rather than being raised by the gate. **The completeness check must compare against the full frozen
registry, not against the surviving subset** — and the artifact should carry the expected cell count
so a reader can falsify its own coverage.

> **Correction (2026-08-11).** An earlier draft of this section asserted that `n_attempt` reported
> 1200 for the truncated cells, i.e. a denominator taken from intent rather than measurement. That is
> **wrong**: `n_attempt` is already computed as `nrow(x)` and is correct for every cell in `$summary`.
> The error came from reading the head of a 290-row `str()` output — whose leading rows are *complete*
> `beta` cells — and generalising it to cells that are not in that frame at all. Two panel reviewers
> caught it independently. The vacuous-completeness mechanism above is the verified finding.

## Candidate evidence, for the panel

From `rorqual:~/g5run/g5-reconciled-final.rds` (schema `mr-g4g5-v2`, cohort `authenticated_uncentred`,
created 2026-08-11 00:52 UTC):

- 348,000 records, **0 UNAUTHENTICATED**; every record carries `design_state =
  centre_random_effects=FALSE`. Noether's estimand objection is answerable from the artifact itself
  rather than inferred from its results.
- Across all seven candidate routes × three rungs: **every cell is 100% interval-usable, and every
  coverage lies inside the [0.925, 0.975] policy band.**
- Closest to an edge: `biv_gaussian` `1x` at **0.9317** (MCSE 0.0073), roughly one MCSE above the
  lower bound. Flagged for an explicit panel ruling rather than waved through.

Per-cell figures: [`panel-cell-summary.csv`](simulation-artifacts/2026-08-11-g5-authenticated-panel/panel-cell-summary.csv)
(290 rows: route, parm, rung, n, usable, usable_rate, coverage, mcse).

## Status of the gap

The four cells were resubmitted as array `18826926` (`--array=222-225 --time=0-12:00`), which resumes
from the retained checkpoints on the same deterministic seeds — `mr_g5_run_campaign()` skips any
`(route, parm, rung, replicate)` key already present, so the completed replicates are not recomputed
and the resumed rows are exact rather than approximate. Estimated 3.7 h wall for the longest task.
Completion takes the campaign to 294/294; **it does not gate the promotion decision.**
