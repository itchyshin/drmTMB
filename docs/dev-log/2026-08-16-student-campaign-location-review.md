# Review: wiring the student Wald campaign sets `location_checked=failed`

**Date:** 2026-08-16 · **Lane:** `cursor/interval-truth-owed` · **Base:** `origin/main` @ `723ed80a0`
**Reader:** later auditors of `mc-0484` / `mc-0485` / `mc-0486`.
**Status:** WIRED. Shinichi approved option 1 on 2026-08-16. The three cells stay
`interval_feasible`. `location_checked` is now `failed`. This is not a promotion.

## The question

`mc-0484` (student `mu` fixed), `mc-0485` (student `sigma` fixed), and `mc-0486`
(student `nu` fixed) were the three remaining import cells that still claimed
`interval_feasible` with `location_checked=unchecked`. They are the class-(A)
cells from the 44-cell audit: a real campaign existed and was not cited.

The campaign is
`docs/dev-log/simulation-artifacts/2026-06-19-student-nu-wald-calibration-diagnostic/`
(200 fits; label `diagnostic_calibration_pilot`). The handover asked whether
wiring it would set `location_checked=failed`.

**Recommendation: yes — if this campaign is wired as location evidence, all
three cells should become `location_checked=failed`.** They can stay
`interval_feasible`. That pairing is what design 255 already decided: the tier
is shape; location is a separate column. This is not a promotion.

## What the campaign actually measured

The fitted model is `bf(y ~ x, sigma ~ z, nu ~ w)` with `family = student()`,
`nu = 2 + exp(eta_nu)` (finite-variance by construction). Two cells, 100
replicates each, `n = 180`:

| cell | `nu(w = 0)` | converged | `pdHess` |
| --- | ---: | ---: | ---: |
| `student_shape_001` (low) | 2.8 | 0.91 | 0.90 |
| `student_shape_002` (ordinary) | 8.0 | 0.92 | 0.89 |

Intervals are **Wald only**. Profile and bootstrap were deliberately absent.
Coverage below is among *usable* Wald intervals (89–90 of 100; the rest are
unusable, not misses). Source:
`tables/student-nu-wald-diagnostics.csv`.

| cell | parameter | usable | coverage | MCSE | gap from 0.95 |
| --- | --- | ---: | ---: | ---: | ---: |
| low | `mu:(Intercept)` | 90 | **0.84** | 0.037 | −0.11 |
| low | `mu:x` | 90 | **0.82** | 0.038 | −0.13 |
| low | `sigma:(Intercept)` | 90 | **0.85** | 0.036 | −0.10 |
| low | `sigma:z` | 90 | **0.84** | 0.037 | −0.11 |
| low | `nu:(Intercept)` | 90 | 0.87 | 0.034 | −0.08 |
| low | `nu:w` | 90 | 0.90 | 0.030 | −0.05 |
| ordinary | `mu:(Intercept)` | 89 | **0.86** | 0.035 | −0.09 |
| ordinary | `mu:x` | 89 | **0.85** | 0.036 | −0.10 |
| ordinary | `sigma:(Intercept)` | 89 | **0.81** | 0.039 | −0.14 |
| ordinary | `sigma:z` | 89 | **0.81** | 0.039 | −0.14 |
| ordinary | `nu:(Intercept)` | 89 | 0.89 | 0.031 | −0.06 |
| ordinary | `nu:w` | 89 | 0.89 | 0.031 | −0.06 |

The handover's "0.81–0.86" is the **mu / sigma** band. Nu is higher (0.87–0.90)
and still below nominal. A true 0.95 coverage at `n = 90` has binomial SE ≈
0.023; 0.81 is about six standard errors low. This is not a small-sample
wobble around the gate.

Map to ledger cells:

- `mc-0484` (`mu`) → 0.82–0.86
- `mc-0485` (`sigma`) → 0.81–0.85
- `mc-0486` (`nu`) → 0.87–0.90

## Why `failed`, not `passed` or `unchecked`

Design 255: `location_checked` asks whether the interval covers the known
truth, not whether an interval exists. This campaign answers that question
for Wald intervals on the exact fixed-effect student surface, and the answer
is no.

`failed` is the honest token. Leaving the cells `unchecked` after this review
would hide a measured miss. `passed` would launder 0.81–0.86 as location
support.

`interval_feasible` can remain. Shape (a finite Wald interval from a
converged fit) is what the cited tests already speak to for `mc-0486`, and
what the generic `drm_profile_targets()` path is claimed to provide for
`mc-0484` / `mc-0485`. Location failure does not retract shape.

## Why this is still not a promotion

The artifact's own after-task
(`docs/dev-log/after-task/2026-06-19-student-nu-wald-calibration-diagnostic.md`)
caps the claim at Wald-only diagnostic calibration. It does not certify
profile intervals, random effects, coverage at the `inference_ready`
bar, or a `supported` cell.

Wiring it as `location_checked=failed` records a negative location fact. It
does not move `evidence_tier` up, and it must not be written as if it did.

## Caveats that stay on the verdict

- **Wald, not profile.** The package's preferred interval for structured and
  RE-SD work is profile. This campaign does not speak to profile location.
- **Usable-interval denominator.** Coverage drops the 10–11% unusable
  intervals. Including them as misses would make the rates worse, not better.
- **Two DGPs, n = 180, 100 replicates.** Enough to reject 0.95; not a
  certified floor across sample sizes.
- **Fixed-effect student only.** No RE, no structured term, no bivariate.
- The campaign predates the location-checked column. It was not
  pre-registered as a location gate.

## Decision (recorded)

Shinichi chose **option 1** on 2026-08-16: wire as `location_checked=failed`
for `mc-0484` / `mc-0485` / `mc-0486`, citing this campaign, leaving
`interval_feasible` in place.

Receipts: `ev-mc-0484-student-wald-location`, `ev-mc-0485-student-wald-location`,
`ev-mc-0486-student-wald-location` and the matching `tr-*-student-wald-location`
rows. Primary shape evidence remains the legacy rows.

Rejected alternatives that stay rejected:

2. Leave `unchecked` after the evidence is known.
3. Wire the campaign as a pass or as a tier promotion.

A later profile campaign would be a new, pre-registered slice (Totoro / DRAC,
D-50), not a re-score of these Wald rows.
