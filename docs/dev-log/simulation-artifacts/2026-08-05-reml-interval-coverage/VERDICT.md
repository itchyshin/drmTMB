# REML and profile interval coverage — measured; headline claim WITHHELD

**Date:** 2026-08-05 · **Platform:** Claude (Claude Code), solo · `origin/main = e430d408a`
**Pre-registration:** [`PREREGISTRATION.md`](PREREGISTRATION.md), committed at **`041905883`,
07:16:39** — *before* any campaign fit. **Design: 6 cells × 1000 replicates, paired arms.**

> **VERDICT: the pre-registered headline claim is NOT ADMITTED.**
> Condition 1 passed, **condition 2 failed**. The measurement stands; the claim is withheld.
> This is the D-117 pattern, deliberately: the number exists, the claim is a separate question.

---

## 1. The pre-registered rule, applied mechanically

From `PREREGISTRATION.md` §5 — "REML buys interval coverage" is admitted only if:

| # | Condition | Result |
|---|---|---|
| 1 | `REML_HELPS` in ≥ 2 of the 3 `n_each = 10` cells | **PASS** — 2 of 3 |
| 2 | **NOT** `REML_HELPS` in *any* `n_each = 3` cell | **FAIL** — 2 of 3 helped |
| 3 | Width guard passes | mixed — see §4 |

**Claim NOT ADMITTED.** Reported as **NOT ESTABLISHED**, with the numbers and no capability claim.
Nothing promotes. Census verified **182 / 60**, unchanged.

## 2. The full grid

Profile-interval coverage of the true `sd:sigma:(1 | id)` = 0.5, paired ML vs REML on identical data.

| Cell | `n_id` | `n_each` | ML | REML | paired Δ (SE) | `ss_floor` | verdict |
|---|---:|---:|---:|---:|---|---:|---|
| `g10_ne03` | 10 | 3 | 0.9082 | **0.9576** | +0.0494 (0.0076) | 0.918 | **REML_HELPS** ⚠ falsifier |
| `g20_ne03` | 20 | 3 | 0.9220 | **0.9430** | +0.0210 (0.0048) | 0.934 | **REML_HELPS** ⚠ falsifier |
| `g40_ne03` | 40 | 3 | 0.9440 | 0.9400 | −0.0040 (0.0028) | 0.942 | INCONCLUSIVE |
| `g10_ne10` | 10 | 10 | 0.9240 | **0.9510** | +0.0270 (0.0057) | 0.918 | **REML_HELPS** |
| `g20_ne10` | 20 | 10 | 0.9280 | **0.9370** | +0.0090 (0.0041) | 0.934 | **REML_HELPS** |
| `g40_ne10` | 40 | 10 | 0.9530 | 0.9600 | +0.0070 (0.0036) | 0.942 | INCONCLUSIVE |

## 3. The falsifier fired — and the investigation cleared the harness

`PREREGISTRATION.md` §6(a) required: if `REML_HELPS` at `n_each = 3`, **treat it as suspected
harness defect and investigate before reporting anything.** Done
([`ADJUDICATION.txt`](ADJUDICATION.txt)). Four independent checks say the harness is sound:

**(a) It reproduces the repo's own committed probe, in both directions.** The 2026-07-08 ladder
(`R/drmTMB.R:2250-2258`) records that REML debiases the scale-RE SD at `n_each >= 8` and
**underperforms ML at `n_each = 3`**. The point-estimate shift measured here flips sign at exactly
that boundary:

| | `n_each = 3` (REML worse) | `n_each = 10` (REML better) |
|---|---|---|
| REML − ML point shift | **−0.0196 / −0.0095 / −0.0087** | **+0.0215 / +0.0106 / +0.0059** |

A harness that independently reproduces a committed finding — including its sign reversal — is not
plausibly the source of the anomaly.

**(b) Both miss directions improved, with *narrower* intervals.** In `g10_ne03`:
lower-misses 37 → **15**, upper-misses 54 → **27**, while mean width fell 0.9862 → **0.8732**
(ratio 0.885). Widening cannot produce that; only better *positioning* can.

**(c) It is not a boundary artifact.** The gain is present both at the boundary (+0.0451) and away
from it (+0.0561).

**(d) Survivorship is near-complete.** 991/1000 replicates produced usable intervals in *both*
arms; the 9 exclusions were ML-usable/REML-failed. Under §6(c)'s 5 pp threshold, but the direction
means the 0.9% exclusion mildly *favours* REML and is recorded as a caveat, not dismissed.

## 4. Width guard (§6(b)) — and a genuine surprise

| Cell | coverage Δ | width ratio REML/ML | reading |
|---|---:|---:|---|
| `g10_ne03` | +0.0494 | **0.885** | better coverage, **narrower** → calibration |
| `g20_ne03` | +0.0210 | **0.986** | better coverage, **narrower** → calibration |
| `g10_ne10` | +0.0270 | 1.098 | better coverage, **wider** → ambiguous |
| `g20_ne10` | +0.0090 | 1.046 | better coverage, **wider** → ambiguous |

**The unambiguous calibration evidence sits in the falsifier cells, not the designed ones.** At
`n_each = 3` REML delivers better coverage from a *narrower* interval — which cannot be a width
effect. At `n_each = 10`, where the design expected the win, the gain is partly width and the guard
is not clean. That is the opposite of what the pre-registration anticipated.

## 5. What the pre-registration got wrong

**The falsifier was mis-specified.** It reasoned: *the probe says REML underperforms at
`n_each = 3`; therefore REML helping on coverage there indicates a broken harness.* But the probe's
claim is about the **point estimate**, and the falsifier tested **interval coverage**. Those are
different estimands, and this campaign shows they genuinely diverge: at `n_each = 3` REML makes the
**point estimate worse** *and* the **interval better**.

**This is stated as a defect in my own rule, not as a rescue of the claim.** I wrote both the rule
and this reinterpretation, which is exactly the move pre-registration exists to prevent. So the
verdict above stands at **NOT ADMITTED** on the rule as written. Whether a corrected falsifier
(one that tests the point estimate, which the data *confirms*) would change that is **the owner's
call, not mine** — routed to Rose.

## 6. The finding that is actually supported

Stated as an observation, **not** as the pre-registered claim and **not** as a capability:

> Across all six cells REML's profile interval covered at least as well as ML's in five, and
> significantly better in four. The mechanism differs by regime: at `n_each = 10` REML shifts the
> interval **up** toward truth (debiasing the centre) and widens slightly; at `n_each = 3` it
> shifts **down** and narrows, yet still covers better, by producing **fewer extreme collapses in
> both tails**. Point-estimate bias and interval calibration moved in *opposite* directions at
> `n_each = 3`.

This is the thing the cross-repo map said no repo had measured. It now has a number. It does not
have an admitted claim.

## 7. D-12 side observation (exploratory, gates nothing)

Wald coverage was **far** below profile at the smallest cell — `g10_ne03`: Wald 0.7225 (ML) /
0.8355 (REML) versus profile 0.9082 / 0.9576 — and above it at `g40_ne03` (0.9830 / 0.9900 vs
0.9440 / 0.9400, i.e. Wald over-covering). So on an *ordinary* sigma RE, profile is markedly better
where the sample is small, which supports D-12's "profile is the hero" framing in this regime. That
is the opposite of the 2026-07-06 *structured* spatial pilot (Wald 0.9928 vs profile 0.8533), so
the two regimes genuinely differ and neither generalises to the other.

## 8. Caveats

- Gaussian, **ordinary** (not structured) sigma-axis, scalar target, one true SD (0.5), one
  `B0`. No claim outside that box.
- `n = 1000` per cell gives MCSE ≈ 0.007 at 95% coverage; differences below ~1.5 pp are not resolved.
- The 9 REML failures in `g10_ne03` are excluded from both arms by the paired design.
- Compute ran **locally**, not Totoro: the full grid took ~7 minutes (32 replicates of the largest
  cell = 3.19 s on 16 cores). Totoro was verified reachable (384 cores, load 2.69) and not needed.
  Nothing ran on GitHub Actions; results stayed local (D-50).

## 9. Files

`PREREGISTRATION.md` (committed pre-fit) · `reml_interval_arc.R` (runner) · `adjudicate.R`
(the §6(a) investigation) · `ADJUDICATION.txt` (its output) · `results/cell{1..6}.csv`
(6000 replicate rows, both arms, all endpoints, flags and diagnostics).
