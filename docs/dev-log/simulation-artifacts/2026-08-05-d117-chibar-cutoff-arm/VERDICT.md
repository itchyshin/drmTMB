# Does a Self–Liang χ̄² cutoff repair D-117's conditional coverage? — MEASURED: NO

**Date:** 2026-08-05 · **Platform:** Claude (Claude Code), solo · `origin/main = e430d408a`
**Question asked:** does replacing the χ²₁ profile cutoff with a Self–Liang chi-bar-square
mixture at a variance boundary move conditional coverage from **0.0732** toward nominal?

**Answer: No. It moves it to 0.0488 — further from nominal, not closer.** The correction makes
coverage worse in every cell where the boundary occurs, and worse overall in all four.

---

## 1. The identity that made this cheap — no package change was needed

The endpoint solver's interval is a **pure level set**:

```r
cutoff <- stats::qchisq(level, df = 1) / 2      # R/profile.R:3117
...
out$nll - nll_hat - cutoff                       # root function, R/profile.R:3356
```

so the interval is `{θ : nll(θ) − nll_hat ≤ cutoff}`.

The 50:50 χ̄² correction (Stram & Lee 1994, for one variance component at zero) replaces
`qchisq(level, 1)` with `qchisq(2·level − 1, 1)`. Solving
`0.5 + 0.5·F_{χ²₁}(c) = level` gives `c = qchisq(2·level − 1, 1)`. At `level = 0.95` that is
`qchisq(0.90, 1)`.

**Therefore the χ̄²-corrected 95% interval is exactly the ordinary 90% interval.** Both arms are
obtained by calling `confint()` at `level = 0.95` and `level = 0.90` — no prototype, no flag, no
edit to `R/`.

| | cutoff (LR scale) | cutoff (NLL scale) |
|---|---:|---:|
| χ²₁ at 0.95 (**shipped**) | 3.841459 | 1.920729 |
| χ̄² at 0.95 (**corrected**) | 2.705543 | 1.352772 |

The corrected cutoff is **smaller** (ratio 0.704), so the interval is strictly **nested inside**
the shipped one. Coverage can therefore only *decrease*. Since 0.0732 ≪ 0.95, "decrease" means
**away from nominal**.

## 2. Harness validation — the χ²₁ arm reproduces D-117 exactly

Same DGP, same seeds, same target as
`2026-08-04-d117-10group-profile-gate/d117_profile_gate.R`
(`seed = 20260727 + 100000·cell_i + r`; `bf(y ~ x + (1 | g), sigma ~ 1)`, gaussian;
`TRUE_BETA = 0.5`, `TRUE_SIGMA = 0.7`; target `sd:mu:(1 | g)`; `n_rep = 1000` per cell).

| Cell | boundary count — **D-117** | **this run** | conditional cov — **D-117** | **this run** |
|---|---:|---:|---:|---:|
| `g10_n04_sd05` | 495/1000 | **495/1000** | 0.8566 | **0.8566** |
| `g10_n04_sd10` | 41/1000 | **41/1000** | 0.0732 | **0.0732** |
| `g10_n10_sd05` | 63/1000 | **63/1000** | 0.2540 | **0.2540** |
| `g10_n10_sd10` | 0/1000 | **0/1000** | — | — |

Exact reproduction on every cell. The harness is measuring the same thing D-117 measured.

## 3. The result

**Nesting held on 4000/4000 replicates** — the χ̄² interval was inside the χ²₁ interval every
single time, confirming the level-set structure empirically as well as analytically.

### Conditional on `profile.boundary = TRUE` (the population a user can see)

| Cell | n at boundary | χ²₁ (shipped) | **χ̄² (corrected)** | change |
|---|---:|---:|---:|---|
| `g10_n04_sd05` | 495 | 0.8566 | **0.7657** | −9.1 pp **worse** |
| `g10_n04_sd10` | 41 | **0.0732** | **0.0488** | −2.4 pp **worse** |
| `g10_n10_sd05` | 63 | 0.2540 | **0.0159** | −23.8 pp **worse** |

### Overall (unconditional)

| Cell | χ²₁ (shipped) | **χ̄² (corrected)** | change |
|---|---:|---:|---|
| `g10_n04_sd05` | 0.9140 | 0.8590 | −5.5 pp |
| `g10_n04_sd10` | 0.9290 | 0.8790 | −5.0 pp |
| `g10_n10_sd05` | 0.9370 | 0.8670 | −7.0 pp |
| `g10_n10_sd10` | 0.9310 | 0.8690 | −6.2 pp |

Mean interval width falls ~18% in every cell (e.g. 0.7295 → 0.6011), as the quadratic
approximation `sqrt(2.7055/3.8415) = 0.839` predicts.

## 4. Why the premise was wrong

Three reasons, all now supported by measurement rather than only argument:

1. **Scope.** The 50:50 mixture is the null distribution for *testing* a variance component at
   zero. A confidence interval inverts the LR test at *interior* candidate values, where the null
   is not on the boundary and ordinary χ²₁ is correct. The sources treat the machinery as an LRT
   property and never warrant the transfer to interval inversion.
2. **Direction.** Measured above: the cutoff is smaller, the interval nests, coverage falls
   4000/4000.
3. **It is a selection effect, not a calibration error.** Conditioning on `profile.boundary`
   selects replicates whose SD estimate collapsed toward zero; those have low upper endpoints and
   miss a non-zero truth almost by construction. Note that overall coverage under χ²₁ is
   0.914–0.937 *because* the interior over-covers while the boundary sub-population under-covers.
   This is post-selection inference. **No cutoff choice repairs it** — and this measurement shows
   the specific proposed cutoff makes it worse.

## 5. Consequences

- **Do not implement the χ̄² cutoff.** It is not a latent fix that was being missed; it is a
  change that would degrade every number this arc cares about.
- **D-117's "not a drmTMB defect" is strengthened**, now against a measured challenge rather than
  an argued one. It named a specific line, a specific correction, and a specific predicted
  direction, and the data went the other way.
- **The `drmTMB_profile_boundary_warning` (PR #924) is confirmed as the right remedy**, not a
  stopgap. The boundary sub-population cannot be handed a nominal interval by adjusting the
  cutoff, so telling the user is the honest response.
- **Unrelated and still open:** issue **#680** / D-12(b), the small-sample *width* recalibration
  (`qchisq(1−α,1) → qt(1−α,df)²`). That is a *larger* cutoff, i.e. the opposite direction, and is
  a different problem. D-12 separates them deliberately; this result says nothing about it.

## 6. Provenance and honest caveats

- **The prediction was committed BEFORE the measurement.** No separate pre-registration file was
  written; instead the predicted direction and reasoning were committed at `b89ea4e55`
  (2026-08-05 06:55:09 −0600, merged in `e430d408a`) and this run executed at ~07:07. A public,
  time-stamped, falsifiable prediction that preceded the data serves the same evidentiary purpose,
  but it is a deviation from the pre-registration discipline D-117 used and is recorded as such.
- **Compute: local, not Totoro.** 16 replicates took 1.66 s on 8 cores, so the full 4×1000 grid is
  a ~4-minute job; deploying to Totoro would have cost more than the compute. D-50's rule (no
  campaigns on GitHub Actions, results stay local) is honoured. Totoro was verified reachable
  (384 cores, load 2.69) and was simply not needed.
- **Conditional cells are small.** `n = 41` and `n = 63` carry wide binomial uncertainty. The
  *direction* does not depend on them: nesting is exact and holds 4000/4000, so the inequality
  coverage(χ̄²) ≤ coverage(χ²₁) is guaranteed replicate-by-replicate, not merely on average.
- **Scope of the claim.** Gaussian, scalar `sd:mu:(1 | g)`, 10 groups, the four D-117 cells only.
  Nothing here promotes a census cell. Census verified **182 / 60**, unchanged.

## 7. Files

- `chibar_arm.R` — the runner (DGP and seeds copied verbatim from the D-117 gate).
- `results/chibar_cell{4,5,1,6}.csv` — replicate-level output, 1000 rows per cell, including both
  arms' endpoints, boundary flags, coverage indicators, widths, and the per-replicate nesting check.
