# VERDICT — D-117 10-group profile gate, re-run at nrep = 100,000

**2026-08-09 · `claude/d117-discharge` off `origin/main @ a2695a788` · Totoro, 90 cores, ~20 min**

Rule frozen in the 2026-08-04 `PREREGISTRATION.md`; scorer `score_d117_gate.R` copied
**byte-identical** (SHA-256 `2595837e…655c`) so it could not drift. Prediction pre-registered in
this directory's `PREREGISTRATION.md`, committed `ab83638f5` **before any 100k fit**.

## 1. The verdict

```
=== OVERALL (every tested 10-group cell must pass) : PASS ===
```

| cell | n_per | N | coverage | exact 95% CI | MCSE | score | floor | verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `g10_n04_sd05` | 4 | 40 | **0.922900** | (0.9212, 0.9245) | 0.000844 | 0.924587 | 0.918 | **PASS** |
| `g10_n04_sd10` | 4 | 40 | 0.925670 | (0.9240, 0.9273) | 0.000829 | 0.927328 | 0.918 | **PASS** |
| `g10_n10_sd05` | 10 | 100 | 0.925530 | (0.9239, 0.9271) | 0.000830 | 0.927190 | 0.918 | **PASS** |
| `g10_n10_sd10` | 10 | 100 | 0.925100 | (0.9235, 0.9267) | 0.000832 | 0.926764 | 0.918 | **PASS** |

**Pooled over 400,000 attempts: 0.924800 (SE 0.000417).**
Every cell: **100,000 / 100,000** finite intervals, convergence **1.000**, `pdHess` **1.000**.

**Cross-check (pre-registered, reported alongside — not the gate).** All four cells also pass the
*strict* standard test: one-sided LCB `p̂ − 1.645·SE` = 0.9215 / 0.9243 / 0.9242 / 0.9237, every one
above 0.918; exact `binom.test(H0: coverage ≥ floor, alternative = "less")` returns **p = 1** in
all four. The frozen rule's `+2×MCSE` margin does no work here — the cells clear the floor on
**raw** coverage.

**This matters more than the verdict flip.** At n = 1,000 that same LCB **failed for three of the
four cells** (worst: 0.899 vs 0.918). The old data could not *demonstrate* adequacy whatever the
frozen rule reported. The re-run converted an unsupportable verdict into a supportable one.

## 2. The pre-registered prediction was WRONG

Predicted `g10_n04_sd05` → score 0.915773 → BORDERLINE → **no discharge**. Measured **0.922900** →
0.924587 → **PASS**. Recorded in full in `PREDICTION-OUTCOME.md`, written before the remaining
cells finished so it could not be shaded.

The 2026-08-04 value of 0.9140 was a low Monte-Carlo draw: the gap is **+0.0089 = 1.00 ×
MCSE(n=1000)**. The pre-registration characterised the uncertainty correctly (its cited CI
[0.894880, 0.930637] straddles the threshold, and the truth landed inside it) — the **point
prediction** was simply wrong. The hypothesis that motivated this arc, that the PASS was a
`+2×MCSE` artifact, is **refuted by measurement**.

## 3. Integrity controls — both passed

**Prefix reproduction.** Replicates r = 1…1000 of the 100k run reuse the banked campaign's exact
seeds. All four cells reproduce **bit-exactly**: `max|diff| = 0.000e+00` on `estimate_sd`,
`profile_lower`, `profile_upper`; **0/1000** disagreements on `profile_covers`, `profile_boundary`,
`fit_converged`, `pdHess`; prefix coverages 0.9140 / 0.9290 / 0.9370 / 0.9310 exactly matching the
banked values.

This control was load-bearing. The package was **rebuilt** from `a2695a788`, and `4b601a448` (the
boundary warning) landed between the 2026-08-04 build and this one. Without the prefix check, "the
shift is Monte-Carlo" would have been an assumption with a live alternative explanation sitting
right next to it. It is now measured.

**Environment parity.** The S0 smoke ran identically on the laptop and on Totoro — same seeds, same
`estimate_sd = 0.1919612`, `profile_lower = 0`, `profile_upper = 0.6268075`.

## 4. What n = 1,000 got wrong about the *shape* of the result

At n = 1,000 the four cells read 0.914 / 0.929 / 0.937 / 0.931 — a spread of 0.023 that invited a
story about the `n_per = 4, sd = 0.5` corner being distinctly worse. **At n = 100,000 the four
cells are 0.9229 / 0.9257 / 0.9255 / 0.9251 — a spread of 0.0028.** The apparent heterogeneity was
noise. There is no meaningfully "worst cell"; the 10-group corner behaves uniformly at ~0.925.

## 5. Panel finding #3 — the comparator, not the corner, was the problem

The claim under review was that the corner is *"detectably below the pooled figure"* at z ≈ 2.5.
Re-derived from the actual 100k data rather than a projection:

| comparator | value | z | reading |
| --- | --- | --- | --- |
| **like-for-like `g = 10`-only** (2026-07-26) | 0.9370 | **−1.586** | **not significant** |
| pooled across `g` (D-97 corrected) | 0.9400 | −3.490 | significant |

**The "detectably below" finding depends entirely on comparing a `g = 10` result against a figure
pooled across larger `g`** — which is precisely the structural error D-117 was created to catch.
Against a like-for-like 10-group comparator the difference is **not statistically significant**.

This vindicates S3's catch (`PANEL-FINDINGS-2-3-4.md`, RULING #4) and resolves finding #3 in the
package's favour. Note the direction of honesty here: at n = 100,000 the *pooled-across-g*
comparison becomes **more** significant, not less, because our SE shrank ~10×. It is the choice of
comparator, not the sample size, that settles it.

## 6. The genuinely open caveat — the boundary sub-population

Conditional on `profile.boundary`, the picture is now complete and precise for the first time.
`profile_boundary` ⟺ `profile_lower == 0` exactly in every cell, so the interval there is `[0, U]`
and a miss can only be an **upper**-side miss (U < truth).

| cell | boundary incidence | conditional coverage | SE | share of total miss |
| --- | --- | --- | --- | --- |
| `g10_n04_sd05` | 49.70% | 0.8683 | 0.0015 | **85%** |
| `g10_n04_sd10` | 3.70% | 0.1021 | 0.0050 | 45% |
| `g10_n10_sd05` | 7.63% | 0.2387 | 0.0049 | 78% |
| `g10_n10_sd10` | 0.09% | **0.0000** (0/89) | — | 1% |

**Three things to state plainly:**

1. **The numbers did not materially worsen** versus 2026-08-04 (0.8566→0.8683, 0.0732→0.1021,
   0.2540→0.2387). They are confirmed, now on 49,696 / 3,704 / 7,632 events instead of 495 / 41 /
   63. The pre-declared dialogue trigger — *"if the conditional numbers get materially worse, stop
   and re-ask"* — therefore **does not fire**.
2. **One datum is genuinely new.** `g10_n10_sd10` had **zero** boundary events at n = 1,000, so its
   conditional coverage was `NA` and unmeasurable. It now shows **0/89 covered**. Incidence is
   0.09%, so it moves the pooled number by 0.0009 — operationally negligible, but it is new
   information and it is stark.
3. **The pooled figure is not hiding a large badly-covered mass — but it is close.** Where
   incidence is high (49.7%) conditional coverage is tolerable (0.868); where conditional coverage
   is bad (0.10, 0.00) incidence is low (3.7%, 0.09%). Still, the boundary sub-population
   contributes **85% / 45% / 78% / 1%** of each cell's total miss. That is the honest cost of the
   pooled estimand and it belongs in front of the owner, not buried.

Per `COMPARATOR.md`, this is **not a drmTMB defect**: `lme4::lmer` on the same DGP and seeds agreed
on boundary incidence 4000/4000 and on conditional coverage to four decimal places. And `confint()`
now **warns** in this regime (`drmTMB_profile_boundary_warning`, verified by execution on this
arc's own boundary seed; regression test `tests/testthat/test-d117-boundary-warning.R`, 9 PASS).

## 7. What this does and does not establish

**Establishes.** For the **A1 scalar Gaussian 10-group corner**, the profile random-effect-SD
interval attains pooled coverage 0.9248 (SE 0.0004), clearing the pre-registered `ss_floor(10) =
0.918` on raw coverage in every tested cell, and passing the strict one-sided test as well.

**Does not establish.** Anything outside that corner. The DGP fixes `TRUE_BETA = 0.5`, residual
`sigma = 0.7`, and one mean formula throughout; only `n_per ∈ {4, 10}` and `sd_mu ∈ {0.5, 1.0}`
vary, at `g = 10`, Gaussian, ML. It is **not** a statement about non-Gaussian families, other
providers, slopes, bivariate models, or other group counts. It is also **not** nominal-exact
coverage: 0.9248 against a nominal 0.95 is real undercoverage, which is why the floor is
`g`-tapered in the first place.

**Recorded, and deliberately not used.** `ss_floor(g) = 0.95 − 0.04 × (8/g)` is a function of `g`
alone; it ignores `n_per`/`N`, so the N = 40 cells were held to the same bar as the N = 100 cells.
Logged in the pre-registration *before* results precisely so it could not later look like a rescue
— and it did not need to be one: the N = 40 cells cleared the bar. Whether the floor should price
within-group replication is a question for a separate, separately pre-registered arc.

## 8. Recommendation

**The statistical gate D-117 named has been met**, on the frozen rule, on the strict cross-check,
and with both integrity controls passing. Panel findings #2, #3 and #6 are resolved; #4 is resolved
for the arc's premise with a comparator-choice caveat now quantified in §5.

**The discharge decision remains Shinichi's**, and it should be taken with §6 in view: the pooled
estimand passes, and the boundary sub-population it pools over is poorly covered in three of four
cells. That tension is real, is shared with `lme4`, is now warned about at the point of use, and is
documented in `NEWS.md`, `man/confint.drmTMB.Rd` and the vignettes.

A fresh D-43 panel — **with Bash and git**, unlike the 2026-08-04 panel whose Noether seat was
dispatched Read/Grep/Glob-only and could not reach the branch — should adjudicate before the
recommendation is acted on.

## 9. Provenance and data

- Campaign log: `campaign100k.log`. Cells run in order 4, 5, 6, 1; every `rc=0`;
  16:09:52 → 16:30:08 (~20 min at 90 cores).
- Derived artifacts committed here: `results/SUMMARY.csv`, `CROSSCHECKS.csv`, `campaign100k.log`,
  the scorer and cross-check scripts, `PREREGISTRATION.md`, `PREDICTION-OUTCOME.md`,
  `PANEL-FINDINGS-2-3-4.md`.
- **The raw per-replicate CSVs are NOT committed** — 4 files, ~195 MB total (~31 MB gzipped), which
  is disproportionate for this repository. They are retained on Totoro at
  `~/d117_100k/score/results/` with SHA-256:

  ```
  7fa8598ea53e3ed21b09d2ab9439e743942d02b68f370bc0095557d7bdffecd1  g10_n04_sd05.csv
  877ccc9a66748ff8bcf5217c62afe84a859b2854d62b2c35870d15a730c667be  g10_n04_sd10.csv
  b24e2b9f0f3f51bebf0fed3ff48569a5b3fd7d71cf96318afbdee0580b0388c9  g10_n10_sd05.csv
  9d56a179cd639fd6eac1dfc97f551cc886ef9cfd5427e42d043aaef6e330d0ed  g10_n10_sd10.csv
  ```

  This omission is stated rather than silent. The campaign fully regenerates in ~20 minutes:

  ```sh
  Rscript --no-init-file d117_profile_gate.R --cell=<1|4|5|6> --nrep=100000 --cores=90 --outdir=OUT
  ```

  **Do not exceed `--nrep=100000`**: seeds are `20260727 + 100000*cell_i + r` with
  `cell_i ∈ {1,4,5,6}`, so cells 4/5 and 5/6 abut exactly at 100,000 and **collide at 100,001**.
