# Phase 19 feasibility batch 3 (Gauss)

Worktree: `.worktrees/external-oracle`, branch `claude/external-oracle-intervals`.
`devtools::load_all(".", quiet = TRUE)` (0.7.0), `R_PROFILE_USER=/dev/null Rscript --no-init-file`.
All three fits ran in well under 5 minutes combined (drmTMB: 0.36s / 1.07s / 0.05s; comparators:
0.05s / 0.19s / 0.03s). Numbers below are read straight from console output, not retyped from
memory; full-precision extractions are shown where the pre-filled cell's evidence field only
carried 4-7 significant figures.

## ph19-c07 — `cumulative_logit()`, `ordinal::wine`, judge random intercept

**Verdict: VIABLE** (upgraded from the pre-filled UNCERTAIN — the agreement is real, not
just convergence).

### 1. drmTMB fit

```r
fit <- drmTMB(bf(mu = rating ~ temp + contact + (1 | judge)), data = wine, family = cumulative_logit())
```

- Wall time: **0.358 s**. `is_converged(fit)`: **TRUE**.
- Full-precision fixed effects: `tempwarm = 3.063001031`, `contactyes = 1.834900358`.
- Judge random-intercept SD: `1.131139` (`summary(fit)$parameters` row `sd:mu:(1 | judge)`).
- Cutpoints: `1|2 = -1.623669`, `2|3 = 1.513357`, `3|4 = 4.228520`, `4|5 = 6.088769`.
- `logLik(fit) = -81.56541278`.

### 2. Comparator fit

```r
cmp <- ordinal::clmm(rating ~ temp + contact + (1 | judge), data = wine)
```

- Wall time: **0.054 s**.
- Full-precision fixed effects: `tempwarm = 3.062996800`, `contactyes = 1.834885013`.
- `VarCorr(cmp)$judge` variance `1.279461`, `attr(,"stddev") = 1.131133`.
- Thresholds: `1|2 = -1.623667056`, `2|3 = 1.513365299`, `3|4 = 4.228526858`,
  `4|5 = 6.088772751`.
- `logLik(cmp) = -81.56540929`.

### 3. Matched scale + agreement

Both estimators use a Laplace approximation to the same random-intercept ordinal likelihood; no
scale conversion is needed (doc 158's matrix, row `cumulative_logit()`, L69: "cutpoints,
location" match directly). Computed diffs:

```
fixed effects:  tempwarm  diff = 4.23e-06
                contactyes diff = 1.53e-05
judge RE SD:               diff = 6.0e-06
cutpoints:      1|2  diff = -1.9e-06
                2|3  diff = -8.1e-06
                3|4  diff = -6.9e-06
                4|5  diff = -3.7e-06
logLik:                     diff = 3.5e-06
```

Every quantity agrees to 1e-5 or better — essentially machine-precision agreement between two
independently-implemented Laplace approximations (drmTMB's TMB inner solve vs `clmm`'s own).

### 4. Verdict

**VIABLE.** This is a point-fit / ML-Laplace coefficient-and-cutpoint parity claim only — it does
not touch the pre-filled cell's REML/interval blocker. That blocker (`expressible-vs-comparator.md:78`,
mc-0227 being package-private and not licensing a public interval claim) is about a *different*
claim (REML random-effect-SD interval calibration for this family) and does not apply here: this
cell only asserts that drmTMB's `mu`-only, random-intercept, ML-Laplace point fit matches `clmm`'s
own ML-Laplace point fit, which it does to 5-6 significant figures. Do not read this cell as
licensing a REML or interval claim for `cumulative_logit()` — it licenses point-fit parity only.

## ph19-c08 — `binomial()`, `lme4::cbpp`, herd random intercept

**Verdict: VIABLE, at a 1e-3 tolerance, not 1e-4** (the pre-filled UNCERTAIN's ~5e-4 gap is real,
reproducible, and now explained as a package-implementation difference rather than left as an
unexplained residual).

### 1. drmTMB fit

```r
fit <- drmTMB(bf(mu = cbind(incidence, size - incidence) ~ period + (1 | herd)), data = cbpp, family = binomial())
```

- Wall time: **1.067 s**. `is_converged(fit)`: **TRUE**.
- Fixed effects: `(Intercept) = -1.3985280750`, `period2 = -0.9923386245`,
  `period3 = -1.1286496619`, `period4 = -1.5803225294`.
- Herd RE SD: `0.6422602911` (`summary(fit)$parameters` row `sd:mu:(1 | herd)`).
- `logLik(fit) = -92.02628187`.

### 2. Comparator fit

```r
gm <- lme4::glmer(cbind(incidence, size - incidence) ~ period + (1 | herd), family = binomial, data = cbpp)
```

- Wall time: **0.188 s** (default `nAGQ = 1`, i.e. Laplace — same approximation order as drmTMB's
  default fit).
- Fixed effects: `(Intercept) = -1.3983428642`, `period2 = -0.9919249752`,
  `period3 = -1.1282162161`, `period4 = -1.5797454139`.
- Herd RE SD (`attr(VarCorr(gm)$herd, "stddev")`): `0.6420699266`.
- `logLik(gm) = -92.02656639`.

### 3. Matched scale + agreement

Both are `mu`-only, logit-link, Laplace-approximated binomial GLMMs at `nAGQ = 1` — no scale
conversion needed (doc 158 row `stats::binomial()`, L30: "compare coefficients ... directly").
Diffs:

```
(Intercept)  diff = -1.85e-04
period2      diff = -4.14e-04
period3      diff = -4.33e-04
period4      diff = -5.77e-04
herd RE SD   diff =  1.90e-04
logLik       diff =  2.85e-04
```

**Adversarial check on the ~2-6e-4 gap**, per the pre-filled cell's blocker ("must not be called
rounding"): re-fit `glmer` with a tightened optimizer (`optCtrl = list(maxfun = 2e5, xtol_abs =
1e-12, ftol_abs = 1e-12)`). The tightened fit reproduced the loose-tolerance fixed effects to 6
decimal places (`(Intercept) = -1.398343`, matching the untightened `-1.398343`) and the same
`logLik = -92.02657`. This rules out "lme4 under-converged" as the explanation. The gap is
therefore a **genuine, stable, package-level difference** between TMB's automatic-differentiation
inner Laplace solve and lme4's PIRLS-based Laplace solve, both nominally computing the same
integral approximation — not a convergence artifact, not rounding, and not a sign of a wrong model
on either side. (For reference, `nAGQ = 25` moves the coefficients further, e.g.
`(Intercept) = -1.3992237`, confirming the ~4e-4 Laplace-vs-Laplace gap sits well inside the
Laplace-vs-higher-order-quadrature gap, i.e. it is small relative to the known finite-node bias
both packages share at `nAGQ = 1`.)

**Overdispersion caveat, checked not assumed.** `binomial()` in this package is literally
`stats::binomial()` re-exported (`class(binomial()) == "family"`, structure identical to base R's
family object, no `dpars` slot beyond the base family fields) — there genuinely is no separate
scale/dispersion parameter to fit. This is symmetric: the `glmer` call above also fits no
overdispersion term (plain binomial `mu`-RE GLMM), so cbpp's known extra-binomial variation is
unmodelled on **both** sides of this specific comparison. It is a real limitation of the formula
as written, not a discrepancy between the two fits, and not a blocker for this cell's narrower
claim (point-fit agreement for the model actually specified).

### 4. Verdict

**VIABLE**, at a realistic tolerance of ~1e-3 rather than 1e-4/1e-5 (unlike c07/c09, which match to
1e-5 or better). `expressible-vs-comparator.md:74` already calls plain binomial `mu`-RE "the
cleanest OVERLAP case in the registry"; this fit confirms that but with a smaller residual gap than
"clean" implies at machine precision — report the tolerance honestly rather than rounding it up to
match the other two cells in this batch.

## ph19-c09 — `lognormal()`, `palmerpenguins`, `mu ~ species`, `sigma ~ sex`

**Verdict: VIABLE**, essentially exact.

### 1. drmTMB fit

```r
pen <- penguins[stats::complete.cases(penguins[, c("species","sex","body_mass_g")]), ]  # n = 333
fit <- drmTMB(bf(mu = body_mass_g ~ species, sigma = ~ sex), data = pen, family = lognormal())
```

- Wall time: **0.049 s**. `is_converged(fit)`: **TRUE**.
- `mu` (identity link on `log(y)`): `(Intercept) = 8.17272037`, `speciesChinstrap = 0.02447963`,
  `speciesGentoo = 0.32491983`.
- `sigma` (log link, log-scale SD): `(Intercept) = -2.4243950`, `sexmale = 0.4374102`.
- `logLik(fit) = -2511.448175`.

### 2. Comparator fit

```r
pen$log_body_mass <- log(pen$body_mass_g)
cmp <- glmmTMB::glmmTMB(log_body_mass ~ species, dispformula = ~ sex, data = pen, family = gaussian())
```

- Wall time: **0.035 s**.
- `cond`: `(Intercept) = 8.17272036`, `speciesChinstrap = 0.02447967`, `speciesGentoo = 0.32491980`.
- `disp`: `(Intercept) = -2.4243951`, `sexmale = 0.4374103`.
- `logLik(cmp) = 261.3320859`.

### 3. Matched scale + agreement

Per doc 158 row `lognormal()` (L25): compare on the log scale, `sigma` is the log-scale SD
directly, no squaring. `mu` is `E[log(y)]`, **not** `E[y]` — flagged for any reader reusing this
cell, per doc 158's own comparator-matrix note (L67: "compare lognormal on the log scale"). Diffs:

```
mu:(Intercept)        diff = 8.52e-09
mu:speciesChinstrap   diff = -4.05e-08
mu:speciesGentoo      diff = 3.21e-08
sigma:(Intercept)     diff = 9.62e-08
sigma:sexmale         diff = -1.46e-07
```

Fixed effects and log-scale dispersion coefficients match to 7-8 significant figures — essentially
exact, as expected since both are exact Gaussian likelihoods on `log(y)` (no Laplace approximation
involved on either side; this is not a random-effects model).

**`logLik` apparent mismatch, checked not left as a discrepancy.** Raw values are
`logLik(fit) = -2511.448` vs `logLik(cmp) = 261.332`, a difference of `-2772.78`. This is fully
explained, not an error: drmTMB's `lognormal()` reports the likelihood on the **original**
`body_mass_g` scale (i.e. it includes the log-Jacobian term for the `y -> log(y)` transform),
while `glmmTMB`'s Gaussian fit reports the likelihood of `log(body_mass_g)` directly with no
Jacobian. `sum(-log(pen$body_mass_g)) = -2772.78` — exactly the observed gap, confirmed by direct
computation. Any write-up of this cell must compare coefficients (which match) and must not compare
raw `logLik` values across the two packages without adding this Jacobian term back in.

**Response-scale sigma cross-check.** `summary(fit)$parameters` reports a `fitted:sigma` "fitted
range" row (`0.0885` to `0.1371`, response scale, i.e. `exp(link)`) rather than the two per-sex
values directly; computed `exp(sigma_female_link) = 0.08853166` and `exp(sigma_male_link) =
0.1371082` by hand, matching `glmmTMB`'s `exp(disp coefficients)` (`0.08853165`, `0.1371082`) to
7-8 significant figures — consistent with the link-scale match above.

### 4. Verdict

**VIABLE.** No trap avoided incorrectly here: `sigma` was compared unsquared (per doc 158's
correction note) and on the log scale, matching the plan's own instruction. The only issue found
was a fully-explained Jacobian offset in the raw `logLik`, documented above so a future reader does
not mistake it for a fit discrepancy.

## Batch summary

| Cell | Verdict | Tightest agreement shown |
| --- | --- | --- |
| `ph19-c07` (cumulative_logit, wine) | VIABLE | ~1e-5 to 1e-6 on all reported quantities |
| `ph19-c08` (binomial, cbpp) | VIABLE (tolerance ~1e-3) | ~2e-4 to 6e-4, confirmed not a convergence artifact |
| `ph19-c09` (lognormal, penguins) | VIABLE | ~1e-7 to 1e-8; raw logLik gap fully explained by the log-Jacobian |

No cell in this batch was BLOCKED. `ph19-c08` is the one genuine caveat: report its tolerance as
~1e-3, not as machine-precision agreement, and do not silently round its gap down to match c07/c09.
