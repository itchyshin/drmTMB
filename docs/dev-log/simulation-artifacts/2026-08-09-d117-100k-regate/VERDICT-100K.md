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

**Environment agreement (wording corrected).** The S0 smoke agreed on the laptop and on Totoro to
*printed* precision — same seeds, same `estimate_sd = 0.1919612`, `profile_lower = 0`,
`profile_upper = 0.6268075` (7 s.f.). This is **not** bit-level identity: `rnorm()` itself differs
by ~1 ULP between the two architectures (measured in `PROVENANCE.md`), so cross-platform bit-exact
regeneration is impossible. The agreement is a robustness result — the fit matched to 7 s.f.
*despite* ULP-different input data — and is reported as such rather than as identity.

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
on boundary incidence 4000/4000 and on conditional coverage to four decimal places.

> **Scope of that comparison — stated so it is not over-read.** The lme4 comparator ran on the
> **2026-08-04 campaign at n = 1,000 per cell** (4,000 paired fits total). It was **NOT re-run at
> n = 100,000**, so the parity claim rests on the smaller sample and is *not* independently
> confirmed on the new data. It remains the best available attribution evidence — paired, same DGP,
> same seeds, `REML = FALSE` to match drmTMB's ML default — and the prefix check shows the shared
> 1,000 replicates are bit-identical between the two campaigns, so the comparison is against data
> the 100k run genuinely contains. But 396,000 of the 400,000 new attempts have **no** lme4
> counterpart. Re-running the comparator at 100k is a cheap, obvious follow-up and has not been done.

And `confint()`
now **warns** in this regime (`drmTMB_profile_boundary_warning`, verified by execution on this
arc's own boundary seed; regression test `tests/testthat/test-d117-boundary-warning.R`, 9 PASS).

## 6b. The recovery half — measured at 100k (added after the D-43 panel)

**This section exists because the panel caught a real omission.** D-117 asks for a
*"recovery/coverage gate"*. Sections 1–6 measured **coverage only**; this document originally
contained **zero** mentions of point-estimate bias, while the recovery numbers in circulation were
still the n = 1,000 figures from 2026-08-04. The 400,000 rows needed to fix that were already on
disk. Recomputed:

| cell | truth | mean `estimate_sd` | rel. bias | MCSE | median bias | 2026-08-04 (n=1000) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `g10_n04_sd05` | 0.5 | 0.42120 | **−15.76%** | 0.122% | −13.06% | −16.90% |
| `g10_n04_sd10` | 1.0 | 0.90690 | **−9.31%** | 0.081% | −9.66% | −9.12% |
| `g10_n10_sd05` | 0.5 | 0.44870 | **−10.26%** | 0.088% | −10.45% | −9.05% |
| `g10_n10_sd10` | 1.0 | 0.91664 | **−8.34%** | 0.074% | −9.11% | −9.16% |

**All four differ from the n = 1,000 values**, and `g10_n10_sd05` moves a full point
(−9.05% → −10.26%). Any statement about recovery should now cite these, not the 2026-08-04 figures.

**Attribution is unchanged.** A downward bias in a variance component at 10 groups under ML is
expected, not anomalous, and `COMPARATOR.md`'s paired lme4 run (`REML = FALSE`, same DGP, same
seeds) agreed on point estimates to ~1e-6. This is the ML estimator, not a drmTMB defect. It is
also the mechanism behind the upper-side miss asymmetry in §6: an SD biased low yields an interval
whose upper endpoint too often falls short of the truth.

### ⚠ CORRECTION — the first version of this paragraph was WRONG, and wrong in the permissive direction

The original §6b argued the mean log-SD statistic was "not usable" and instructed readers **not to
quote it**. The D-43 re-adjudication panel returned **3 of 3 NOT-DONE**, and every seat that
examined this paragraph found it false. It is corrected here rather than deleted, because *what*
was wrong matters:

| the original claim | the truth |
| --- | --- |
| "49.7% of fits at `estimate_sd ≈ 0`" | **6.07%** of estimates are below 1e-3. 49.7% is `profile_boundary` — a column about interval **lower bounds**, not point-estimate magnitude. Two different quantities, conflated; wrong by ~8×. |
| "mean anywhere from −54% to −77% **depending on how the tail is floored**" | Not a floor effect. `min(estimate_sd) = 8.18e-06` and there are **no exact zeros**, so every floor ≤ 8.19e-6 is inert. −54% and −77% are **two different formulas**, not two floors. |
| "−77.4%" | A **unit error**. That is the mean log-ratio (−0.7740) multiplied by 100 and labelled a percentage. The multiplicative bias is `exp(−0.7740) − 1 = ` **−53.88%**. |
| "two recomputations of the same statistic disagreed by >20 points" | No such pair exists. The n=1,000 figure (−55.5%) and the 100k figure (−53.88%) agree to **1.6 points**. |
| "do not quote a mean log-SD bias for this cell" | **This suppressed the statistic that fails.** See below. |

**Why suppressing it was wrong.** The log-scale mean is the statistic this repository has
historically used to judge recovery, so telling readers not to quote it removed the number most
likely to embarrass the result. Report it, with its dispersion and its sensitivity to the
near-zero tail:

| cell | mean log bias | MCSE | multiplicative | median log bias | mean log, tail-trimmed (`≥1e-3`) | share `<1e-3` |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `g10_n04_sd05` | −0.7740 | 0.00733 | −53.88% | −0.1400 | **−0.1973** | 6.07% |
| `g10_n04_sd10` | −0.1535 | 0.00151 | −14.23% | −0.1016 | −0.1407 | 0.13% |
| `g10_n10_sd05` | −0.2018 | 0.00234 | −18.28% | −0.1104 | −0.1574 | 0.47% |
| `g10_n10_sd10` | −0.1221 | 0.00087 | −11.49% | −0.0955 | −0.1219 | 0.00% |

**Read `−0.7740` carefully — it is dominated by boundary mass, not by central bias.** Removing the
6.07% of estimates below 1e-3 moves it to **−0.1973**, statistically indistinguishable from
`g10_n10_sd05`'s −0.2018. So −0.774 is *not* evidence that this cell's estimator is ~4× worse than
its siblings; the four cells are alike once the near-zero tail is separated (−0.197 / −0.141 /
−0.157 / −0.122). Pooled, only **1.67%** of estimates fall below 1e-3.

**The mean–median gap has an ordinary cause**: left skew from that tail, not an arbitrary floor.

> **Cross-reference, NOT a criterion applied here.** `AGENTS.md` records the Beta-phylogenetic arc
> being STOPPED at `mean log-latent-SD bias −0.2214` against a frozen absolute **0.10** gate. Every
> number above exceeds 0.10. **That bar is not applied as this gate's criterion, and it would be
> unfair to do so**: it was frozen for a different family, a different estimand, and — decisively —
> **`g = 256`**. At `g = 256` a −0.22 log bias signals a defect; at `g = 10` a downward
> variance-component bias is the expected ML property, which is why this document's *coverage* floor
> is `g`-tapered in the first place. Holding coverage to a `g`-tapered bar while holding recovery to
> a `g`-flat one imported from a 25×-larger design would be internally inconsistent. And since
> drmTMB matches `lme4` here to ~1e-6, that bar fails the **estimator class**, not the
> implementation — which makes it evidence about ML at ten groups, not about this package.
>
> It is recorded because it is the only recovery bar this repository has ever frozen, and a future
> arc setting one should start from it knowingly — not because it adjudicates this result.

**Bias is not a function of `g` alone.** At fixed `g = 10`, raw-scale bias grows by **1.54×** when
`n_per` drops from 10 to 4 at `sd = 0.5` (−10.26% → −15.76%). *(The original said "roughly doubles";
that overstated a 1.54× change, and the `sd = 1.0` pair moves only 1.12×.)* This still mirrors the
`ss_floor` observation in §7: within-group replication matters and a `g`-only floor does not price
it.

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

**REVISED after the re-adjudication panel. The earlier wording — "the statistical gate D-117 named
has been met" — is withdrawn.** It was true of the coverage half and silently generalised to the
whole gate.

D-117 names a **"recovery/coverage"** gate. The two halves now land differently:

| half | pre-registered criterion? | result |
| --- | --- | --- |
| **coverage** | **yes** — `ss_floor(10) = 0.918`, frozen before results | **PASSES** on every cell, on raw coverage, and on the strict one-sided LCB |
| **recovery** | **none, at either n** | **measured** (§6b) — but with no threshold it can be scored neither pass nor fail |

**So D-117 does not fully discharge on this evidence — because half of it was never made
scoreable.** The coverage question is answered convincingly, at replication that removes
Monte-Carlo doubt. The recovery half is now measured rather than assumed, but *"recovery/coverage
gate"* with a criterion for only one half cannot be adjudicated as passed. **That is
under-specification, not failure**, and it is the load-bearing reason here.

Deliberately **not** the reason: the Beta-phylogenetic 0.10 log-scale bar. All four cells exceed it,
and an earlier draft of this document leaned on that as a FAIL. §6b now explains why that would be
an unfair transplant — different family, different estimand, `g = 256` versus `g = 10`, and a bar
that `lme4` would fail identically on the same data. **Reporting a number against a bar it was never
bound to is the mirror image of suppressing it; this document should do neither.**

What the recovery measurement *does* support, stated positively: the point-estimate bias is
**−15.76 / −9.31 / −10.26 / −8.34%** on the raw scale, consistent in sign and magnitude with the
expected ML downward bias for a variance component at ten groups, matching `lme4` to ~1e-6, and
tightly estimated (MCSE ≤ 0.13%). A user should expect their random-effect SD estimate at this
design to run low by roughly 8–16%.

**Setting the recovery criterion is the owner's call, and it belongs before scoring, not after** —
otherwise the choice of statistic (mean vs median, raw vs log, trimmed vs not) decides the outcome,
and §6b shows those choices span −0.12 to −0.77 on the same data.

Panel findings #2, #3 and #6 are resolved; #4 is resolved for the arc's premise with a
comparator-choice caveat quantified in §5.

**The discharge decision remains Shinichi's**, and it should be taken with §6 in view: the pooled
estimand passes, and the boundary sub-population it pools over is poorly covered in three of four
cells. That tension is real, is shared with `lme4`, is now warned about at the point of use, and is
documented in `NEWS.md`, `man/confint.drmTMB.Rd` and the vignettes.

### D-43 panel verdict — RAN 2026-08-09, and the composite claim is WITHHELD

Three fresh reviewers, distinct lenses, each **with Bash and git** (the 2026-08-04 panel's Noether
seat lacked them and its NOT-DONE was recorded as a dispatch error; that seat has now been taken
properly).

| seat | lens | model | verdict |
| --- | --- | --- | --- |
| Noether | mathematical consistency | Sonnet | **DONE** |
| Grace | reproducibility / evidence chain | Sonnet | **NOT-DONE** |
| Rose | claims and scope (load-bearing) | Opus | **NOT-DONE** |

**2 of 3 NOT-DONE → under D-43 the claim is WITHHELD.** Precisely which claim matters:

- **The coverage result SURVIVES.** Noether recomputed every mathematical claim from the raw rows —
  coverage, MCSE, score, the `profile_covers` definition (0/400,000 mismatches), the LCB and
  `binom.test`, both z-statistics, the boundary identity, the seed algebra — with **zero**
  discrepancies. Rose independently re-scored all 400,000 rows bypassing `profile_covers` entirely
  and reproduced every headline exactly, and verified the pre-registration was committed at
  16:04:54 against a campaign starting 16:09:52 — genuinely unshaded.
- **The composite claim FAILS**, on two blocking grounds, both now repaired above: this document
  measured only the *coverage* half of D-117's "recovery/coverage" gate (fixed in **§6b**), and the
  arc had shipped no after-task report closing panel finding #5 (now at
  `docs/dev-log/after-task/2026-08-09-d117-discharge-100k-regate.md`). Grace's reproducibility
  findings are answered in `PROVENANCE.md` and in §9's corrected commands.

**A repaired claim has not been re-adjudicated.** These repairs were made *after* the panel
reported; no reviewer has seen them. Under the arc's own "own the verifier" rule, the fixes do not
retroactively convert the verdict — a re-run panel would be required for that, and has not
happened.

Two process faults of mine that the panel caught and that belong on the record: I **edited a
document while the panel was reviewing it** (the lme4 scope fix, `423b30ac6`), creating a moving
target — Noether noticed HEAD advancing mid-review; and the brief said 9 commits when there were
11. Freeze the tree before dispatching reviewers.

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

  This omission is stated rather than silent. The campaign fully regenerates in ~20 minutes.
  **Corrected after the D-43 panel found the earlier command did not work as written** — it omitted
  the working directory (the harness lives in the **2026-08-04** directory, not this one) and the
  `--repo=` argument needed unless drmTMB is installed:

  ```sh
  cd docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate
  R_PROFILE_USER=/dev/null Rscript --no-init-file d117_profile_gate.R \
      --cell=<1|4|5|6> --nrep=100000 --cores=90 \
      --outdir=<OUT> --repo=<path/to/drmTMB/worktree>
  ```

  Scoring (the scorer reads `<its own dir>/results/`, and requires exactly 4 CSVs):

  ```sh
  mkdir -p score/results && cp <OUT>/*.csv score/results/
  cp 2026-08-04-d117-10group-profile-gate/{score_d117_gate.R,a1_profile_common.R} score/
  cd score && R_PROFILE_USER=/dev/null Rscript --no-init-file score_d117_gate.R
  ```

  Environment the numbers were produced under is recorded in `PROVENANCE.md` (R 4.5.3, TMB 1.9.21,
  Matrix 1.7.5, reference BLAS/LAPACK, Totoro). Cross-R-version reproducibility is **not**
  demonstrated by this arc.

  **Do not exceed `--nrep=100000`**: seeds are `20260727 + 100000*cell_i + r` with
  `cell_i ∈ {1,4,5,6}`, so cells 4/5 and 5/6 abut exactly at 100,000 and **collide at 100,001**.
