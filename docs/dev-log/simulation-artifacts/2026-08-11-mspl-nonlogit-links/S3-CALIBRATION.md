# S3 — separation-depth calibration, and the corner timing. FROZEN 2026-08-11.

Run before any G1 replicate, per `PREREGISTRATION.md` §4 and §8.1. This closes the
`FROZEN-PENDING-PROBE` state: the `η_d` values below are now frozen and the grid is complete.

Runner `s3_probe.R`, raw `s3_probe_raw.tsv`, console `s3_probe.log`. 3 conditions × 10 candidate
`η_d` × 20 replicates = **600 ML fits**, `q1`, `G = 12` (the smaller main-grid `G`, so the calibration
is conservative — separation is hardest there). 76 s, one core, local.

## The selection rule, fixed before the output was read

`η* =` the **shallowest** (largest) `η_d` whose ML divergence fraction reaches **≥ 0.50**, divergence
being `|SE| > 10³`, a failed fit, or a non-finite/absent SE — F1 §6's threshold verbatim. Then

```
grid = {0, 0.4·η*, 0.7·η*, η*, 1.4·η*}
```

five points (the count is frozen by §4), whose **two deepest** are `η*` and `1.4·η*`. Both therefore
satisfy the control condition by construction, which is what §5.3 hands to the adversarial corner.

## Result

| condition | `η*` | frozen `η_d` grid | divergence at the two deepest | event rate at `η*` |
|---|---|---|---|---|
| probit | −3 | `{0, −1.2, −2.1, −3, −4.2}` | 0.65 → 0.90+ | 0.016 |
| cloglog-standard | −5 | `{0, −2, −3.5, −5, −7}` | 0.85 → 1.00 | 0.018 |
| cloglog-mirrored | −6 | `{0, −2.4, −4.2, −6, −8.4}` | 0.50 → 0.80+ | 0.994 |
| logit-control | — | `{0, −2, −4, −6, −10}` | **not S3's to set** — F1's, reused verbatim (§5.2) | — |

Divergence rises monotonically with depth in all three conditions, with no reversal.

## What this vindicates — requirement (d) was not a formality

F1's logit grid would have been **wrong for every non-logit condition**, in both directions:

- **Probit separates at −3, not −10.** `pnorm(−10) = 7.6e−24` against `plogis(−10) = 4.5e−5`; F1's
  deepest logit cell transplanted to probit is roughly nineteen orders of magnitude more extreme.
  Probit reaches 0.65 divergence at `η_d = −3` and is already at 0.10 by −2.5.
- **The two cloglog orientations need different grids** (−5 against −6). This is the operational form
  of doc 253 §4's "both orientations mandatory, because cloglog is asymmetric": the asymmetry is not
  only a statement about tail orders, it moves the separation depth by a full unit of `η_d`.
  `PREREGISTRATION.md` §4 point 2 explicitly permitted two grids here; the probe used that permission.
- **The orientations separate into opposite tails**, as intended. cloglog-standard drives the event
  rate to ~0 (rare ones, 0.018 at `η*`); cloglog-mirrored drives it to ~1 (rare zeros, 0.994). One
  tail each, which is the whole reason both are in the grid.

Had F1's values been reused unchecked, the shallow cells would have been non-separating and the deep
ones degenerate, and a PASS would have been vacuous in the precise sense §3(e) warns about.

**One caveat, recorded rather than smoothed:** cloglog-mirrored's `η* = −6` sits exactly **at** the
0.50 threshold on 20 replicates (10/20), so its placement is the least precisely determined of the
three. It is not adjusted here — the rule was fixed in advance and post-hoc movement is exactly what
§8.6 forbids. The graded run draws 500 replicates per cell, which resolves it; if that cell's ML
control then falls below 0.50, §7 voids cloglog-mirrored's deep cells and that is reported, not patched.

## Corner timing (prereg §8.4) and the run estimate (§8.5, D-139)

One fit timed at the adversarial-corner size `G = 400, n_per = 10` (`N = 4,000`), local, one core:

| link | `η_d` | mspl | ml | event rate |
|---|---|---|---|---|
| logit | −6 | 18.61 s | 4.64 s | 0.0060 |
| probit | −3 | 19.05 s | 10.89 s | 0.0318 |
| cloglog | −5 | 3.41 s | 1.80 s | 0.0168 |

Mean ≈ **9.7 s/fit** at corner size — emphatically *not* proportional to the main grid, which is why
§8.4 requires it be timed rather than extrapolated.

| block | fits | s/fit | core-hours |
|---|---|---|---|
| main grid (80 cells, `G ∈ {12,30}`) | 80,000 | ~0.25 | ~5.6 |
| adversarial corner (8 cells, `G = 400`) | 8,000 | ~9.7 | ~21.6 |
| **total** | **88,000** | — | **~27** |

**Estimate, declared before the run: ~20–30 minutes wall-clock on Totoro at 100 cores**, the corner
dominating at roughly 13 minutes of it. Per §8.5 and D-139, if the actual run exceeds this it stops
and re-reports rather than continuing quietly.
