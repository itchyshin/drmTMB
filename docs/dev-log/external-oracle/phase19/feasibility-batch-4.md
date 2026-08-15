# Phase 19 feasibility batch 4 (Gauss)

Worktree: `.worktrees/external-oracle`, branch `claude/external-oracle-intervals`.
`devtools::load_all(".", quiet = TRUE)` (0.7.0), `R_PROFILE_USER=/dev/null Rscript --no-init-file`.
Scripts run and their raw output are reproduced below; no numbers were hand-typed from
memory.

## ph19-c10 — `biv_gaussian()`, predictor-dependent `rho12`, `palmerpenguins`

**Verdict: UNCERTAIN** (confirmed; the pre-filled cell body over-claimed on one point,
corrected below).

### 1. drmTMB fit

```r
pen <- penguins[complete.cases(penguins), ]   # nrow(pen) = 333
fit <- drmTMB(
  bf(mu1 = bill_length_mm ~ species, mu2 = bill_depth_mm ~ species,
     sigma1 = ~ species, sigma2 = ~ species, rho12 = ~ species),
  data = pen, family = biv_gaussian()
)
```

- Wall time, fit call only (load_all excluded): **0.3126 s**. (Original cell estimate
  "0.3" is right when timed this way; the first run I did, which included
  `devtools::load_all()` inside the timer, read 1.86 s — that overhead is load_all, not
  the fit. Report the 0.31 s number.)
- `is_converged(fit)`: **TRUE**.
- `n = 333` (146 Adelie / 68 Chinstrap / 119 Gentoo), matching the plan's "complete
  cases (333 rows)" claim.
- `summary(fit)` (`logLik = -1274`, `convergence = 0`):

```
                           estimate  std_error
mu1:(Intercept)         38.82398411 0.21960293
mu1:speciesChinstrap    10.00985309 0.45803023
mu1:speciesGentoo        8.74409899 0.35863430
mu2:(Intercept)         18.34726040 0.10056746
mu2:speciesChinstrap     0.07332652 0.16968474
mu2:speciesGentoo       -3.35062159 0.13496251
sigma1:(Intercept)       0.97586907 0.05852082
sigma1:speciesChinstrap  0.22246477 0.10381503
sigma1:speciesGentoo     0.15327931 0.08732886
sigma2:(Intercept)       0.19487681 0.05852089
sigma2:speciesChinstrap -0.07529809 0.10381556
sigma2:speciesGentoo    -0.21319501 0.08732911
rho12:(Intercept)        0.40688071 0.08276106
rho12:speciesChinstrap   0.37456365 0.14681746
rho12:speciesGentoo      0.37541247 0.12350221
```

### 2. Comparator fit

Confirmed the plan's "NONE" claim by actually trying the one Suggests-listed package
that could plausibly take a two-column response, `glmmTMB`:

```r
> glmmTMB(cbind(bill_length_mm, bill_depth_mm) ~ species, data = pen)
[1] "matrix-valued responses are not allowed"
```

`DESCRIPTION`'s `Suggests:` (checked directly, not from memory) contains `ape`,
`callr`, `detectseparation`, `emmeans`, `extraDistr`, `fmesher`, `glmmTMB`, `ggplot2`,
`JuliaCall`, `knitr`, `lme4`, `MASS`, `metafor`, `mvtnorm`, `numDeriv`, `ordinal`,
`palmerpenguins`, `pkgload`, `rmarkdown`, `sf`, `spelling`, `statmod`, `testthat`,
`tweedie`, `withr` — no `brms`, no `MCMCglmm`. So the plan's claim ("No frequentist
comparator exists... MCMCglmm/brms are Bayesian... and are not in DESCRIPTION
Suggests") is **verified**, not just asserted: the only package in Suggests that could
in principle carry a two-response bivariate model rejects the call outright with
`"matrix-valued responses are not allowed"`, and the two named Bayesian alternatives
are absent from Suggests entirely. There is nothing here to fit a comparator to; §3/§4
below are therefore N/A for a comparator and the cell is scored on the sanity check
alone.

### 3/4. Matched scale + verdict

There is no scale-conversion table row for this cell (doc 158's table has no
entry for predictor-dependent `rho12`; comparator matrix row 58 explicitly excludes
it: "predictor-dependent `rho12 ~ x` has essentially no frequentist comparator").
The only available partial check is the descriptive one the plan names: per-species
Pearson `cor(bill_length_mm, bill_depth_mm)`, valid as a sanity check **only** because
every submodel (`mu1`, `mu2`, `sigma1`, `sigma2`, `rho12`) is species-saturated, so the
MLE has no borrowing of information across species and should reduce to the per-group
sample statistics.

I pulled the actual response-scale fitted `rho12` per species via `predict(fit,
newdata = data.frame(species = levels(pen$species)), dpar = "rho12", type =
"response")` rather than reading the raw link-scale coefficients, and compared them to
the direct per-species correlations:

```
          descriptive cor   fitted rho12         diff
Adelie        0.3858132       0.3858205      7.33e-06
Chinstrap     0.6535362       0.6535343     -1.91e-06
Gentoo        0.6540233       0.6540203     -3.01e-06
```

Agreement to ~1e-5 in all three species — exactly what a saturated model should give,
confirming the fit is doing what it claims and the internal link is invertible/sane.
Pooled (species-ignoring) `cor(bill_length_mm, bill_depth_mm) = -0.2286`: strongly
negative, versus positive 0.39/0.65/0.65 within every species — the Simpson's-paradox
reversal the plan describes is real and reproduced.

**Correction to the pre-filled cell's evidence field.** The pre-filled text reported
"rho12 (internal correlation link) = (0.4068807, +0.3745636, +0.3754125)" as if those
were the per-species values. Those three numbers are the raw `rho12` **linear-predictor
coefficients** (`(Intercept)`, `speciesChinstrap`, `speciesGentoo` — i.e. Adelie's
coefficient and two offsets from it), not per-species correlation estimates, and they
are not additive to the correlation scale: the link is `atanh` (Fisher z), confirmed by
computing `tanh()` of the coefficient sums and matching `predict(..., type =
"response")` exactly (`tanh(0.4068807) = 0.3860`≈`0.3858`,
`tanh(0.4068807+0.3745636) = 0.6536`≈`0.6535`,
`tanh(0.4068807+0.3754125) = 0.6540`≈`0.6540`). The qualitative claim in the pre-filled
evidence ("positive within-species coupling in all three, stronger in Chinstrap and
Gentoo than Adelie") survives because `tanh` is monotone, but the specific numbers
quoted are link-scale coefficients mislabeled as response-scale correlations, and the
pre-filled text also undersold how close Chinstrap and Gentoo are to each other
(0.6535 vs 0.6540 — not meaningfully distinguishable, not "different strengths").
Use the corrected response-scale triple `(0.386, 0.654, 0.654)` if this cell is written
up further.

**Verdict: UNCERTAIN**, unchanged from the pre-filled cell, and for the same reason:
`expressible-vs-comparator.md:79` classes formula-capable `biv_gaussian()` `rho12` as
FRONTIER — expressible by drmTMB but with no comparator to check it against — so
"VIABLE" is not available (nothing to agree with) and "BLOCKED" is wrong (the fit
converges cleanly and the one sanity check available passes to 1e-5). What is newly
verified here, beyond the pre-filled draft: (a) the fit actually converges and returns
the specific numbers above, (b) the "no comparator" claim was checked, not assumed,
against both `DESCRIPTION`'s actual `Suggests:` list and a live `glmmTMB` rejection
message, and (c) the internal `rho12` link is `atanh`/`tanh`, so any reader comparing
raw coefficients to a correlation must transform first — the pre-filled draft did not
do this and reported link-scale numbers as if they were response-scale correlations.

**Blocker (unchanged, restated for this write-up):** this cell must be labelled
frontier/unlicensed-by-the-comparator-agreement wherever it is presented next to any
`VIABLE` cell from batches with a real comparator (per c01/c03/c04/c06/c08/c09 in
earlier batches); doc 242 (`docs/design/242-external-comparator-evidence-class.md:82-84`)
names presenting frontier results next to overlap-agreement results without
distinguishing them "credibility-laundering."
