# Fisher review — D-43 panel findings #2, #3, #4 on the D-117 10-group profile gate

Scope: findings #2, #3, #4 of
`docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/D43-PANEL.md:44-51`,
against the existing 2026-08-04 evidence (`results/*.csv`, `results-lme4/*.csv`,
`COMPARATOR.md`, `PREREGISTRATION.md`, `D97-PROVENANCE.md`). Findings #1 and #6 are
out of scope (decided by the owner / closed). The 100,000-replicate re-run on Totoro
had produced no output at the time of this review
(`docs/dev-log/simulation-artifacts/2026-08-09-d117-100k-regate/results/` empty as of
2026-08-09) — nothing below uses it. Where a conclusion would change under the re-run,
that is stated explicitly rather than assumed.

All R below run with `R_PROFILE_USER=/dev/null Rscript --no-init-file` from
`docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/`.

---

## Finding #2 — the unreported point-estimate bias

**Panel wording** (`D43-PANEL.md:44-46`): *"A large, significant point-estimate bias
went unreported — −16.9% / −9.1% / −9.1% / −9.2%, p < 1e-23 in every cell — and it is
the mechanism behind the upper-miss asymmetry the arc did report."*

### Status of the fix already in the document

`VERDICT.md:70-87` (§2.2) already carries this exact table (relative bias, one-sample
t-test) — the panel's finding is recorded there as **actioned**, not merely raised.
Independent recomputation from the raw CSVs reproduces it to the last reported digit:

```r
d <- read.csv("results/g10_n04_sd05.csv"); truth <- 0.5
mean(d$estimate_sd) - truth                 # -0.0844993  -> -16.8999% ; VERDICT: -16.9%
t.test(d$estimate_sd, mu = truth)$statistic  # t = -13.7947, p = 9.41e-40 ; VERDICT: t=-13.79, p=9.4e-40
```

Full table, all four cells (`n = 1000` each):

| cell | truth | mean(estimate_sd) | mean bias | relative bias | MCSE(bias) | t | p |
|---|---:|---:|---:|---:|---:|---:|---:|
| `g10_n04_sd05` | 0.5 | 0.41550 | -0.08450 | **-16.90%** | 0.00613 | -13.79 | 9.4e-40 |
| `g10_n04_sd10` | 1.0 | 0.90879 | -0.09121 | **-9.12%**  | 0.00791 | -11.53 | 5.9e-29 |
| `g10_n10_sd05` | 0.5 | 0.45473 | -0.04527 | **-9.05%**  | 0.00434 | -10.44 | 2.8e-24 |
| `g10_n10_sd10` | 1.0 | 0.90844 | -0.09156 | **-9.16%**  | 0.00737 | -12.42 | 4.7e-33 |

Matches `VERDICT.md:76-79` exactly. **Not a defect in the reporting as it now stands**
— the gap the panel found has been closed on the raw scale.

### What is genuinely new here: the log-scale statistic, and it is not a clean confirmation

Variance components are conventionally summarised on log SD because the sampling
distribution of an SD estimate is right-skewed; the log transform is meant to
symmetrise it. Computed directly from `estimate_sd`:

```r
logdiff <- log(d$estimate_sd) - log(truth)
mean(logdiff); t.test(logdiff, mu = 0)
```

| cell | mean(log diff) | implied mult. bias (mean) | median(log diff) | implied mult. bias (median) | t (log) | p (log) |
|---|---:|---:|---:|---:|---:|---:|
| `g10_n04_sd05` | -0.8086 | **-55.5%** | -0.1476 | -13.7% | -10.81 | 8.0e-26 |
| `g10_n04_sd10` | -0.1483 | -13.8% | -0.1005 | -9.6% | -10.63 | 4.6e-25 |
| `g10_n10_sd05` | -0.1716 | -15.8% | -0.1039 | -9.9% | -8.49 | 7.3e-17 |
| `g10_n10_sd10` | -0.1307 | -12.3% | -0.1112 | -10.5% | -15.33 | 9.0e-48 |

Three of four cells behave as expected: the log statistic is close to the raw one and
mean/median agree. **`g10_n04_sd05` does not** — its mean log bias implies a -55.5%
multiplicative bias, four times its raw-scale figure, while its *median* log bias
(-13.7%) is close to the other cells. The cause is diagnosable directly: this cell has
63/1000 estimates below `1e-3` and a minimum of `1.0e-5`
(`min(d$estimate_sd) = 1.0e-05` for `g10_n04_sd05`, vs `2.6e-01` for `g10_n10_sd10`,
which has zero sub-`1e-3` estimates). `log(1e-5/0.5) ≈ -10.8`; a handful of such rows
pull an arithmetic mean of logs far below what the bulk of the distribution shows. This
is the same 49.5%-at-boundary mass documented in `VERDICT.md:52` (conditional-coverage
finding), viewed through a different statistic.

**This is a genuine methodological caveat the current document does not carry**: at
this cell's boundary-heavy regime, the log-SD convention — adopted specifically to
tame skew — is itself dominated by a small number of near-zero draws and gives a
number four times larger than the median-based or raw-scale figure. Reporting "log-SD
bias -55%" without this caveat would overstate the point-estimate problem; reporting
only the raw -16.9% understates how heavy the near-zero tail is. Both belong in the
document together.

### Attribution: is this drmTMB's ML, or is it the estimator?

`COMPARATOR.md` already ran `lme4::lmer(..., REML = FALSE)` on the identical DGP and
identical seeds. Its own text states point estimates "agree to ~1e-6"
(`COMPARATOR.md:49`); this was not previously checked against the bias claim
specifically. Recomputed directly:

```r
ld <- read.csv("results-lme4/lme4_g10_n04_sd05.csv")
stopifnot(identical(d$seed, ld$seed))
mean(ld$est_sd) - 0.5   # lme4 mean bias
```

| cell | drmTMB mean bias | drmTMB rel. bias | lme4 mean bias | lme4 rel. bias | max\|drmTMB − lme4\| (paired) |
|---|---:|---:|---:|---:|---:|
| `g10_n04_sd05` | -0.08450 | -16.900% | -0.08450 | -16.900% | 1.86e-04 |
| `g10_n04_sd10` | -0.09121 | -9.121%  | -0.09121 | -9.121%  | 1.40e-04 |
| `g10_n10_sd05` | -0.04527 | -9.055%  | -0.04527 | -9.055%  | 2.53e-05 |
| `g10_n10_sd10` | -0.09156 | -9.156%  | -0.09156 | -9.159%  | 3.58e-05 |

Paired agreement is to 4-6 significant figures in every cell, including the outlier
`g10_n04_sd05`. **This settles attribution.** The bias — magnitude, direction, and its
disproportionate size in the smallest-N cell — is reproduced by an independently
written reference implementation on the same data. It is not a drmTMB coding defect;
it is the ML estimator's behaviour for a random-effect SD at `g = 10`, and it gets
worse specifically when `n_per` is also small (4 vs 10), not from `g` alone.

### Is the magnitude "consistent with the well-known downward ML bias"?

Partially, and this is inference rather than a checked citation. The classical
balanced one-way result gives `E[σ̂²_ML] ≈ σ²_true × (g-1)/g`; at `g = 10` that is a
-10% *variance*-scale bias, which (Jensen's inequality on the concave `sqrt`, applied
to a random, not deterministic, quantity) predicts an SD-scale bias somewhat larger
than the naive `sqrt(0.9) - 1 = -5.1%`. The three `n_per = 10`-or-comparable cells
(-9.1 to -9.2%) sit in a plausible range above that naive floor. **The `n_per = 4`,
`sd_mu = 0.5` cell's -16.9% (raw) / -13.7% (median-log) does not fit a `g`-only
explanation** — `g` is identical (10) across all four cells — and is better attributed
to `n_per = 4` giving very little information to separate between- from within-group
variance, compounded by the smaller true SD (0.5) sitting closer to the zero boundary.
I could not find a citation in this repository quantifying that interaction; it is
recorded as a plausible mechanism, not a verified one.

**RULING #2: RESOLVED as originally raised — `VERDICT.md` §2.2 already reports the
raw-scale bias accurately, and the lme4 pairing settles attribution to the ML
estimator, not a drmTMB defect. Two things are genuinely new and not yet in
`VERDICT.md`: (a) the log-SD statistic is unstable in the boundary-heavy cell (mean
-55.5% vs median -13.7%, entirely a near-zero-tail artefact), and (b) the bias is not
a function of `g` alone — it roughly doubles when `n_per` also drops to 4. Both should
be added before this document is cited as complete.**

---

## Finding #3 — "not materially worse than the pooled figure" at z ≈ 2.5

**Panel wording** (`D43-PANEL.md:47-48`): *""Not materially worse than the pooled
figure" is contradicted by the arc's own numbers at z ≈ 2.5 (worst cell 0.9140 vs
0.9368)."*

### Recomputation

```r
p1 <- 914/1000; se1 <- sqrt(p1*(1-p1)/1000)          # worst cell: 0.9140, SE=0.008866
p2 <- 0.9368;   se2 <- (0.9411-0.9323)/(2*1.96)       # stale D-97 figure, SE backed out of its CI
(p1 - p2) / sqrt(se1^2 + se2^2)                       # z
```
gives **z = -2.4930** against the stale 0.9368 figure — matching `VERDICT.md:93`
exactly (`z = -2.49`).

Against the now-corrected comparator (see Finding #4), **0.9400 [3 cells, 3,000
attempts, `2820/3000`]**:

```r
p2b <- 2820/3000; se2b <- sqrt(p2b*(1-p2b)/3000)      # 0.9400, SE=0.004341
(p1 - p2b) / sqrt(se1^2 + se2b^2)                     # z = -2.6344
```

matches `D97-PROVENANCE.md:73` (`z ≈ 2.63`) exactly.

**Pooled across all four 10-group cells** (3711/4000 = 0.92775, SE 0.00409) against
0.9400: **z = -2.05**. Against 0.9368: **z ≈ -1.94** (matches `VERDICT.md:94`).

### Verdict on the claim itself

The claim as literally written ("not materially worse than the pooled figure") is
**not defensible at face value** — the arc's own worst cell is 2.5-2.6 combined-SE
below the comparator it was checked against, and, per `VERDICT.md:95`, every one of
the four cells sits at or below that comparator, none above. `VERDICT.md`'s own §2.3
rewrite (lines 104-109) already concedes this and replaces the sentence with "the
corner is nonetheless **detectably below**" — the document has already corrected
itself on this point; the panel's finding is again already actioned in the current
text.

### A comparator-population problem that is new (see also Finding #4)

The 0.9400 figure pools the committed campaign's `n_groups ∈ {10, 25, 50}` *at fixed
`n_per = 10`*, and `g = 25`/`g = 50` cover better (0.942, 0.941) than `g = 10` (0.937)
in that same campaign. Using the **like-for-like subset — `g = 10` only, 0.937,
937/1000** — as the comparator instead of the 3-cell pool:

```r
p2c <- 0.937; se2c <- sqrt(0.937*0.063/1000)          # SE = 0.00768
(p1 - p2c) / sqrt(se1^2 + se2c^2)                     # worst cell (n_per=4) vs g=10-only (n_per=10)
(0.92775 - p2c) / sqrt(0.00409^2 + se2c^2)            # pooled 4-cell vs g=10-only
```
gives **z = -1.96** (worst cell) and **z = -1.06** (pooled 4-cell) — both materially
weaker than the -2.5/-2.6 reported. Using the pooled-across-`g` comparator for a
claim specifically about the 10-group corner repeats, at one remove, the exact pooling
critique that motivated D-117 in the first place (a pooled figure can hide/flatter a
smaller-group cell). This does not overturn the direction of the finding — the point
estimate is still below every version of the comparator — but it changes the strength
of the "detectably below" language from p ≈ 0.01 to p ≈ 0.05 (worst cell) or
non-significant (pooled). **Neither `VERDICT.md` nor `D97-PROVENANCE.md` runs this
like-for-like check**, and it belongs in the document precisely because they are the
documents making the significance claim.

### What n = 100,000 does to z

MCSE shrinks as `1/√n`, but only on the D-117 side — the comparator campaigns (3,000
and 1,000 attempts respectively) are fixed, historical evidence, not being re-run.
Holding the worst cell's point estimate at 0.9140 (`PREREGISTRATION.md:38` predicts an
almost-unchanged **0.915773** at n=100,000, i.e. the point estimate is not expected to
move materially):

```r
se_new <- sqrt(0.9140*0.0860/100000)                  # 0.000887
(0.9140 - 0.9400) / sqrt(se_new^2 + 0.004341^2)        # z vs committed 0.9400
```
gives **z ≈ -5.87**, not the naïve `sqrt(100) × -2.63 ≈ -26.3` that a blanket "z
scales as √n" heuristic would suggest. The naïve heuristic assumes *both* sides of the
comparison shrink in SE; here only one does, and the combined SE is bounded below by
the fixed comparator's own SE (0.00434 at n=3,000, or 0.00768 for the g=10-only
subset). **Predicted direction: the same sign, and more significant than at n=1,000
(z moving from roughly -2.6 to roughly -6, or -2.0 to roughly -2.4 against the
like-for-like g=10-only comparator), but not open-endedly — the comparator's own
finite `n` puts a ceiling on how large |z| can get without also re-running it.** If
the 100k point estimate lands materially above 0.9140 (the pre-registration's own
0.916227 threshold is the number to watch, `PREREGISTRATION.md:38-41`), this
significance calculation is moot and should be re-run on the actual number, not
projected from the 2026-08-04 estimate.

**RULING #3: RESOLVED as literally stated (the claim was already corrected in
`VERDICT.md` to "detectably below," matching my independent z = -2.49 / -2.63
recomputation) but OPEN on comparator choice — the like-for-like `g = 10`-only
comparator (0.937) roughly halves the reported significance (z ≈ -2.0 to -2.6 → -1.1
to -2.0), and neither existing document runs that check. Add it before treating the
"detectably below" language as settled, and re-derive the 100k projection from the
actual re-run numbers rather than this document's point-estimate-held-fixed
projection.**

---

## Finding #4 — D-97 provenance vs the arc's premise

**Panel wording** (`D43-PANEL.md:49-51`): *"D-97's provenance contradicts the arc's
central premise ('12 A1 cells, 11,988 retained attempts' vs a bootstrap-only 12-cell
campaign and a 3-cell profile campaign). Unresolved."*

### The correction, verified against both copies

`docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/D97-PROVENANCE.md`
and `~/shinichi-brain/memory/DECISIONS.md` (D-97 entry, `⚠ PROVENANCE CORRECTED
2026-08-05` block; the parallel D-117 entry carries the same correction as item (a) in
its own `⚠ 2026-08-05` note) state the same facts and agree with each other verbatim
on the numbers. Independently verified against the actual committed campaign on
`codex/sd-bootstrap-r999-diagnosis` (`4cc837a85`,
`docs/dev-log/simulation-artifacts/2026-07-26-a1-r999-bootstrap-diagnosis/profile-vs-bootstrap-report.md`):

```
10 groups  Profile  0.937 (0.920, 0.951)  1000/1000
25 groups  Profile  0.942 (0.926, 0.956)  1000/1000
50 groups  Profile  0.941 (0.925, 0.955)  1000/1000
```
`(937+942+941)/3000 = 2820/3000 = 0.9400` exactly — matches the correction's cited
figure to the last digit. The 12-cell/bootstrap-only campaign
(`2026-07-25-a1-marginal-bootstrap-coverage/a1_coverage.R`,
`expand.grid(n_groups=c(10,25,50), n_per=c(4,10), sd_mu=c(0.5,1.0))`, `method =
"bootstrap"` only) independently checks out as the source of "12 cells" and "0.8714,
n=12,000"; `11,988 = 12 × 999` and `999` only ever appears in this evidence as the
bootstrap resample count `R = 999`, never as a retained-attempt count (every real
campaign retained 1,000/1,000 with zero attrition).

### Does the correction resolve the arc's premise?

**Yes, for the premise specifically.** `PREREGISTRATION.md:41-45` claims three of the
four 10-group cells (`n_per=4, sd_mu∈{0.5,1.0}` and `n_per=10, sd_mu=1.0`) were never
measured on the profile route before this arc; only `n_per=10, sd_mu=0.5` (the
"reproduction" cell) had a prior committed measurement. The committed 3-cell campaign
varies only `n_groups` at fixed `n_per=10, sd_mu=0.5` — it contains exactly one of
this arc's four cells (the `n_groups=10` row, 0.937, reproduced almost exactly by
`g10_n10_sd05` at 0.9370). The other three genuinely are first measurements. This
holds under either citation (0.9368 or 0.9400): neither traces to a campaign that
covers `n_per=4` or `sd_mu=1.0` at `g=10`. **The premise survives the correction, and
did not depend on which of the two figures was right.**

### Does something survive that the correction does not fix?

Yes, and it is the comparator-population problem documented in Finding #3, not a new
provenance defect. The corrected figure (0.9400) is *itself* a pooled figure across
`n_groups ∈ {10,25,50}`, and the arc's whole argument is that pooling across group
sizes can hide the worst corner. Citing 0.9400 as "the profile route's baseline" and
then testing the 10-group corner against it **reintroduces exactly the pooling
critique D-117 exists to police**, just with a smaller and better-characterised pool
than the original 0.9368/12-cell claim. The correct fix is not a citation fix; it is
using the `g=10`-only subset (0.937, n=1,000) as the comparator for any claim
specifically about the 10-group corner, which is available in the same 3-cell dataset
and requires no new measurement.

A second, narrower thing does not fully close: `D97-PROVENANCE.md:86-91` frames
correcting `DECISIONS.md` as *"the owner's call"*, but the DECISIONS.md text I read
(`~/shinichi-brain/memory/DECISIONS.md`, D-97 and D-117 entries) already contains the
correction, applied. I could not establish from files in this worktree whether
Shinichi reviewed and authorised that edit (per the brain's own D-37 rule that vault
writes need explicit approval) or whether an agent applied it directly; the correction
document itself is agnostic on this and I have no access to the conversation that
produced it. This is a provenance-of-the-correction question, not a statistical one,
and belongs to a governance/process review rather than this one, but it is why I am
not calling the citation question fully closed end-to-end.

**RULING #4: RESOLVED for the arc's stated premise (three of four cells genuinely
novel, confirmed against the committed 3-cell campaign independently of this repo's
citation error) — but a SEPARATE, narrower problem SURVIVES: the corrected comparator
(0.9400) is itself pooled across `n_groups`, which is the same structural issue D-117
was created to catch. Use the `g = 10`-only subset (0.937) for 10-group-specific
significance claims (feeds directly into Finding #3's z-recomputation above), and note
that whether the `DECISIONS.md` edit itself carried explicit owner sign-off could not
be verified from repository evidence.**
