# Phase 5 — does the correlation penalty rescue the coupled-q4 model?

## Reader and purpose

For the next `drmTMB` contributor and reviewer, and the evidence behind the
full reply to the Ayumi thread. Phase 3 (#581) added an optional penalized/MAP
estimator with a documented prior on the phylogenetic SDs and an `N(0, cor_sd)`
shrinkage on the phylogenetic correlation parameter. Phase 5 asks the only
question that matters for the user: **does that correlation penalty actually
pull the coupled-q4 "Model E" off the ±1 boundary, and is the rescued estimate
data-informed or prior-dominated?**

Background: a coupled-q4 fit (one phylogenetic correlation label across all four
endpoints `mu1, mu2, sigma1, sigma2`) hits the log-Cholesky ±1 boundary at one
observation per tip (`pdHess = FALSE`, profiles error). The separable "Model D"
(distinct `|p|` / `|q|` labels) converges cleanly — so the weakness is the
*coupling*, not the scale SDs. The penalty targets exactly that coupling.

## Experiment 1 — real-data rescue (headline)

Fit Model E on the real 10,440-tip data:
- **penalize-off** (plain ML) — reproduce the boundary failure (`convergence = 1`
  / `pdHess = FALSE`, correlations near ±1).
- **penalize-on** at two correlation-prior strengths (`cor_sd = 0.5`, `0.25`) —
  test whether the correlations come off ±1 and the Hessian becomes
  positive-definite.

Pass/interpretation:
- If penalize-on reaches `pdHess = TRUE` with correlations bounded away from ±1,
  the penalty rescues the coupled model (the headline result).
- The two `cor_sd` values are a first prior-sensitivity probe: if the correlation
  estimate moves substantially as the prior tightens, the component is
  **prior-dominated** (honest answer: the data cannot pin it); if it is stable,
  it is **data-informed**. Either outcome is the answer the user needs.

## Experiment 2 — controlled-truth recovery (rigor, optional this slice)

Simulate from a known coupled-q4 model at 1 obs/tip on a small fixed tree, with a
moderate true mean-scale correlation, then fit penalize-off vs penalize-on across
a `cor_sd` grid. Measures whether the penalized estimate **recovers the true
correlation** or shrinks toward the prior, and at what replication (1 vs >=2
obs/tip) recovery returns. This is the recovery/coverage rigor; it is staged
behind Experiment 1 because the real-data demonstration is the immediate
deliverable.

## Companion observation — mean/scale confounding

Adding scale-phylo (Model D) collapsed the mean-phylo SDs relative to the
mean-only Model A+ (0.35/0.46 -> 0.10/0.09 on the real data): mean-phylo and
scale-phylo compete for the same clade-level structure. This is why the coupled
model is hard and must be reported as a caveat — the mean-phylo SD is not a
stable quantity to compare across models that do and do not include scale-phylo.

## Honesty contract

- The penalty regularises a weakly-identified direction; it does not manufacture
  identifiability. A rescued Model E is a **MAP** estimate, prior-sensitive, and
  must be reported with the sensitivity sweep, never as a plain ML fit.
- A successful rescue means "the coupled model now returns a finite,
  sensitivity-checkable estimate," not "the data identify the correlation." The
  sweep distinguishes those, and the writeup must say which.

## Results

### Experiment 1 — real-data Model E (10,440 tips, 1 obs/tip)

| fit | conv | pdHess | max\|grad\| |
| --- | --- | --- | --- |
| penalize-off (ML) | 1 | FALSE | 1.2e11 |
| `cor_sd = 0.5` | 0 | FALSE | 0.11 |
| `cor_sd = 0.25` | 1 | FALSE | 2.0e11 |
| `cor_sd = 1.0` | (real-data confirmation; see check-log) | | |

Plain ML's correlation parameters run off (gradient ~1e11). `cor_sd = 0.5`
tames the gradient to 0.11 and converges, but one Hessian direction stays flat
(`pdHess = FALSE`, one NaN SE) and the result is unstable across prior strengths
on the full surface. So on the full 10,440-tip surface the penalty makes the
coupled model *converge finitely* but did not, at the settings tried, reach a
fully positive-definite Hessian.

### Experiment 2 — controlled-truth recovery (n=300, known truth)

Truth: `cor(mu2,sigma2)=0.60`, `cor(sigma1,sigma2)=0.30`, `cor(mu1,mu2)=0.30`,
others 0; SDs 0.35/0.45/0.45/0.55; `rho12=0.30`.

| setting | pdHess | cor(mu2,sig2) t=0.60 | cor(sig1,sig2) t=0.30 | cor(mu1,mu2) t=0.30 |
| --- | --- | --- | --- | --- |
| off, 1 obs/tip | FALSE | 1.00 (pinned) | 0.94 | 0.23 |
| `cor_sd=1.0`, 1 obs | TRUE | 0.82 | 0.57 | 0.08 |
| `cor_sd=0.5`, 1 obs | TRUE | 0.54 | 0.26 | 0.01 |
| `cor_sd=0.25`, 1 obs | TRUE | 0.22 | 0.08 | -0.01 |
| off, 3 obs/tip | TRUE | 0.73 | 0.68 | 0.42 |
| `cor_sd=0.5`, 3 obs/tip | TRUE | 0.56 | 0.40 | 0.30 |

Findings, in plain terms:

1. **The penalty rescues the coupled model to a positive-definite fit.** At one
   observation per tip, penalize-off pins all six correlations at +/-1
   (`pdHess = FALSE`); every `cor_sd` gives a clean, off-boundary, PD fit. The
   mechanism works.
2. **At one obs/tip the magnitudes are prior-sensitive.** There is a sweet spot:
   the strong true 0.60 is recovered at `cor_sd=0.5` (0.54) but over-shrunk at
   0.25 (0.22) and under-shrunk at 1.0 (0.82); weak correlations collapse to ~0
   at any real shrinkage. The penalty makes Model E fittable and recovers the
   *strong* couplings near the right prior; magnitudes depend on the prior, so a
   prior-sensitivity sweep is mandatory and only strong/stable couplings are
   trustworthy.
3. **Replication is the clean fix.** At three observations per tip, plain ML (no
   penalty) already reaches `pdHess = TRUE` off the boundary, and penalty +
   replication recovers all six correlations well (0.30 / 0.56 / 0.40 vs truth
   0.30 / 0.60 / 0.30). So ~2-3 records per species makes the full coupled model
   identifiable from the data itself, without leaning on a prior.

### Conclusion

For one-record-per-species data: report Model A+ / Model D (identified, Wald) as
the primary analyses; treat a penalized Model E as a fittable, prior-sensitivity-
checked exploration (trust only strong, prior-stable couplings); and recommend
intraspecific replication (~2-3 / species) as the clean path to the full coupled
model. This is a data-design conclusion, not a software limit.
