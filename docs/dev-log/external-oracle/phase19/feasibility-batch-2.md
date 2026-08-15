# Phase 19 feasibility batch 2 (Gauss)

Reader: whoever adjudicates Phase 19 candidate cells. Purpose: report actual
fit results for three candidate cells, not reasoning about whether they would
work. Every number below came from an executed R session in this worktree
(`R_PROFILE_USER=/dev/null Rscript --no-init-file`, `devtools::load_all()`
against this 0.7.0 worktree, not the installed 0.6.0 package). Package
versions used: `metafor` 5.0.1, `ordinal` 2025.12.29, `metadat` 1.6.0.

Script: `/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/55be482f-02d5-4bbb-8b85-7fd279d63c57/scratchpad/ph19-batch2.R`
(full console log at `ph19-batch2.log` alongside it).

---

## ph19-c04 — Gaussian meta-analysis, `dat.bcg` (13 trials, RR)

**drmTMB call:**
```r
data(dat.bcg, package = "metadat")
dat <- escalc(measure = "RR", ai = tpos, bi = tneg, ci = cpos, di = cneg, data = dat.bcg)
fit <- drmTMB(bf(mu = yi ~ 1 + meta_V(V = vi), sigma = ~ 1), data = dat, family = gaussian())
```
- Wall time: **0.209 s**. `is_converged(fit)`: **TRUE**.
- `coef(fit)$mu["(Intercept)"] = -0.7111990`, `coef(fit)$sigma["(Intercept)"] = -0.6364327`
  (log(tau)), `sigma:(Intercept)` back-transformed to response scale by `summary()`:
  `0.5291768`.

**Comparator (verbatim call, `method = "ML"` as the plan-of-record blocker requires):**
```r
metafor::rma.uni(yi, vi, data = dat, method = "ML")
```
- `b = -0.7111991`, `tau2 = 0.2800282`.

**Also ran the trap explicitly** — `rma.uni(..., method = "REML")` gives
`b = -0.7145323`, `tau2 = 0.3132433`, materially different from the ML fit. This
confirms the plan-of-record's stated blocker is real: `rma.uni()` defaults to
REML, and comparing drmTMB's ML fit against that default silently compares two
different estimators. `method = "ML"` is mandatory, exactly as flagged.

**Scale conversion (158-plan-of-record.md's `meta_V(V=V)` row):** `tau^2 =
exp(2 * coef(fit, "sigma"))`.
- `tau2_drm = exp(2 * -0.6364327) = 0.2800281`
- `tau2_rma_ML = 0.2800282`
- `|diff mu| = 1.83e-7`, `|diff tau2| = 1.05e-7`.

**Verdict: VIABLE.** Both fit, both converge, and match to 1e-7 on both `mu`
and `tau^2` when the comparator is called with `method = "ML"`. The blocker
flagged in the input cell (REML-default trap) is confirmed real and is fully
avoided by the explicit `method = "ML"` argument — not a residual risk once
stated in the doc. Not duplicative of `vignettes/meta-analysis.Rmd:83`, which
uses the same grammar on simulated data; this is real trial data from
`metadat`.

---

## ph19-c05 — Gaussian meta-analysis with distributional `sigma ~ alloc`

**drmTMB call:**
```r
fit <- drmTMB(bf(mu = yi ~ 1 + meta_V(V = vi), sigma = ~ alloc), data = dat, family = gaussian())
```
(same `dat` as c04; `alloc` is a 3-level factor: `alternate` n=2, `random`
n=7, `systematic` n=4.)
- Wall time: **1.254 s**. `is_converged(fit)`: **TRUE**.
- `coef(fit)$mu["(Intercept)"] = -0.6578529`.
- `coef(fit)$sigma = (Intercept) -1.676592, allocrandom 1.175489,
  allocsystematic 1.047993` — treatment contrasts, reference level
  `alternate` (first level alphabetically, drmTMB's default contrast
  ordering).

**Comparator (verbatim call):**
```r
dat$id <- seq_len(nrow(dat))
metafor::rma.mv(yi, vi, random = ~ alloc | id, struct = "DIAG", data = dat, method = "ML")
```
- Ran without error. `b = -0.6579` (mean). Per-level variance components
  (`struct="DIAG"`, one `tau^2` per `alloc` level):

| level | `rma.mv` `tau^2` | `rma.mv` `sqrt(tau^2)` (= tau) |
|---|---|---|
| alternate | 0.0350 | 0.1870 |
| random | 0.3671 | 0.6059 |
| systematic | 0.2844 | 0.5333 |

**Scale conversion — two stacked steps, exactly as the input cell predicted:**
1. drmTMB contrasts → cell means (log(tau) scale): `alternate = -1.676592`,
   `random = -1.676592 + 1.175489 = -0.501104`, `systematic = -1.676592 +
   1.047993 = -0.628599`.
2. `tau = exp(cell mean)` (per the plan-of-record's gaussian row: drmTMB
   `sigma` linear predictor is `log(sigma)`, i.e. `log(tau)` here, not
   `log(tau^2)`):

```r
exp(c(alternate = -1.6765924, random = -0.5011038, systematic = -0.6285994))
#  alternate     random systematic
#  0.1870101  0.6058615  0.5333383
```

- `tau` match: `0.1870101` vs `0.1870`, `0.6058615` vs `0.6059`, `0.5333383`
  vs `0.5333` — agreement to the 4 decimal digits `rma.mv` prints.
- `tau^2` match (`exp(cell mean)^2`): `0.0349728` vs `0.0350`, `0.3670682` vs
  `0.3671`, `0.2844497` vs `0.2844` — same agreement.
- `mu`: `-0.6578529` (drmTMB) vs `-0.6579` (rma.mv) — matches to displayed
  precision.

**Self-correction (adversarial check on my own draft):** my first pass through
this conversion asserted "no `exp()` needed, log(tau) matches log(tau)
directly" — that claim was **wrong**, caught only by computing `exp()` of the
cell means and comparing against `rma.mv`'s printed `sqrt(tau^2)` column.
`rma.mv` prints `tau` and `tau^2` on the *response* scale, not the log scale;
drmTMB's `sigma` linear predictor is on the log scale (per the plan-of-record
gaussian row). The exponentiated values are what agree with `rma.mv`; the raw
linear-predictor cell means do not. This is the kind of "matching digits by
accident on the wrong scale" trap the task brief warned about — it very
nearly reproduced itself here on the *right* underlying result but the *wrong*
stated conversion.

**Verdict: VIABLE**, with the conversion path corrected above (two steps:
contrast→cell-mean, then `exp()` to go from log(tau) to tau). Levels line up
correctly by name (`rma.mv`'s `level` column matches drmTMB's factor-level
order — both use `alternate` as the implicit reference), so this is not a
spurious digit match: the same three levels agree on both `tau` and `tau^2`
simultaneously to 4 significant figures, and the fixed-effect mean also
agrees. `struct = "DIAG"` in `rma.mv` is not merely "close" to `sigma ~
alloc` for this dataset — it is numerically identical to 4-figure precision,
which is stronger evidence than the input cell's "suggestive, not proof"
framing suggested was available. A symbolic check would still be worth
banking for the design doc, but the empirical match is exact within
`rma.mv`'s own display precision.

---

## ph19-c06 — `cumulative_logit()`, `ordinal::wine`

**drmTMB call:**
```r
data(wine, package = "ordinal")
fit <- drmTMB(bf(mu = rating ~ temp + contact), data = wine, family = cumulative_logit())
```
- Wall time: **0.020 s**. `is_converged(fit)`: **TRUE**.
- `coef(fit)$mu = tempwarm 2.503102, contactyes 1.527797`.
- Cutpoints (from `summary()`): `1|2 -1.344385, 2|3 1.250807, 3|4 3.466888,
  4|5 5.006405`.
- `logLik = -86.49`.

**Comparator (verbatim call):**
```r
ordinal::clm(rating ~ temp + contact, data = wine)
```
- `tempwarm = 2.5031`, `contactyes = 1.5278`, cutpoints `1|2 -1.3444, 2|3
  1.2508, 3|4 3.4669, 4|5 5.0064`, `logLik = -86.49`.

**Scale conversion:** none — same logit link, same cumulative direction, no
transform.
- `tempwarm`: `2.503102` (drmTMB) vs `2.5031` (clm) — match to 6 s.f.
- `contactyes`: `1.527797` vs `1.5278` — match to 6 s.f.
- cutpoints: `-1.344385/1.250807/3.466888/5.006405` (drmTMB) vs
  `-1.344383/1.250809/3.466887/5.006404` (clm) — match to ~6 s.f.,
  well inside any reasonable tolerance (differences are ~2e-6, likely pure
  optimizer-tolerance noise between the two implementations).

**Boundary claim check** (the cell's stated blocker: `sigma ~ temp` for
`cumulative_logit()` is not expressible):
```r
drmTMB(bf(mu = rating ~ temp + contact, sigma = ~ temp), data = wine, family = cumulative_logit())
```
raises, verbatim:
```
`cumulative_logit()` models currently support only a `mu` location
formula.
✖ Unsupported parameter: "sigma".
ℹ Ordinal scale/discrimination formulas are planned after the identifiability
  contract is finalized.
```
Confirmed — this is a real rejection, not a hypothetical. And the reader
pointer the blocker note suggests is real too:
```r
ordinal::clm(rating ~ temp + contact, scale = ~ temp, data = wine)
```
fits without error (`logLik = -86.439`, a modest improvement over the
constant-scale model's `-86.49` from the one extra parameter, as expected).

**Verdict: VIABLE** for the `mu`-only fit (both fit, converge, agree to 6
s.f. on all 6 free parameters — 2 slopes + 4 cutpoints). The dataset-inventory
proposal of a `sigma ~ temp` scale submodel for this cell is **not
expressible** in drmTMB today; the boundary is real and the error message
already points at the right constraint (`cumulative_logit()` supports only
`mu`), though it doesn't itself name `ordinal::clm(scale = ~ ...)` as the
comparator's equivalent — that pointer should be added to reader-facing docs
if this cell is written up, since Fisher/Pat would want a "try this instead"
note per the repo's writing-style rule for unsupported syntax.

---

## Summary

| id | verdict | wall s | drmTMB vs comparator |
|---|---|---|---|
| ph19-c04 | VIABLE | 0.209 | `mu` diff 1.8e-7, `tau^2` diff 1.0e-7 (both ML) |
| ph19-c05 | VIABLE | 1.254 | `mu`, `tau`, `tau^2` all match to `rma.mv`'s printed 4 s.f., all 3 `alloc` levels simultaneously |
| ph19-c06 | VIABLE | 0.020 | 2 slopes + 4 cutpoints match `clm()` to ~6 s.f.; `sigma ~ temp` boundary confirmed real, `clm(scale=~temp)` confirmed as the working alternative |

All three cells fit and converge in under 1.3 s each — well inside the 5-minute
per-fit budget. No blocker survived contact with an actual fit: c04's REML
trap is real but fully neutralized by `method = "ML"`; c05's "suggestive, not
proof" scale match turned out to be an exact match once the conversion path
was corrected (caught and fixed in this pass, documented above so the mistake
isn't silently repeated); c06's stated non-expressibility of `sigma ~ temp`
is confirmed as a real, correctly-worded rejection, with a working comparator
alternative (`clm(scale = ~ temp)`) verified to exist for reader guidance.
