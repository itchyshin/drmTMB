# Phase 19 adversarial scale audit (Noether)

Reader: whoever assembles the Phase 19 write-up from
`feasibility-batch-1.md` … `feasibility-batch-4.md`, and whoever later reuses those
cells as evidence. Purpose: try to **refute** the scale conversions behind every
declared agreement, family by family, and say which cells survive.

Method: I did not read the conversion tables and check the arithmetic against them —
that would only test whether the batches copied the table faithfully. I re-derived
each conversion from the **density actually evaluated**, by refitting each family and
reconstructing the log-likelihood by hand from `stats::d*()` / `tweedie::dtweedie()`
under the candidate conversion and its plausible wrong alternatives. A conversion is
accepted only when the hand-built log-likelihood reproduces the package's own
`logLik()` and the wrong alternatives do not.

Environment: worktree `.worktrees/external-oracle`, `4530fd71a`, drmTMB 0.7.0 via
`devtools::load_all(".", quiet = TRUE)`; R 4.6.0; glmmTMB 1.1.14, metafor 5.0.1,
ordinal 2025.12.29, lme4 2.0.1, MASS 7.3.65, tweedie 3.1.0, metadat 1.6.0,
palmerpenguins 0.1.1, TMB 1.9.21. All runs under
`R_PROFILE_USER=/dev/null Rscript --no-init-file`. Scripts (disposable, scratchpad):
`noether-scales.R` (checks A–E), `noether-scales2.R` (F–H), `nt3.R` (tweedie),
`nt4.R` (polr / accessor). Every fit finished in under 2 s; nothing here needed
compute.

## Verdict summary

| Cell | Family / conversion claimed | Noether verdict |
| --- | --- | --- |
| ph19-c01 | gaussian, `log(sigma)` both sides, no transform | **CONFIRMED** (check A) |
| ph19-c02 | none claimed (comparator BLOCKED) | **NO CONVERSION AT RISK**; its forward-looking "same as c01" is now verified |
| ph19-c03 | nbinom2, `log(theta) = -2 * log(sigma)` | **CONFIRMED** (check B) |
| ph19-c04 | meta_V, `tau^2 = exp(2 * eta_sigma)` | **CONFIRMED and understated** (check D) |
| ph19-c05 | meta_V heteroscedastic, contrast → cell mean → `exp()` | **CONFIRMED and badly understated** (check F) |
| ph19-c06 | cumulative_logit, no transform vs `ordinal::clm` | **CONFIRMED** (check E) |
| ph19-c07 | cumulative_logit + RE, no transform vs `clmm` | **CONFIRMED** (check E covers the scale; RE SD is an SD, not a variance) |
| ph19-c08 | binomial, no transform | **CONFIRMED** (no conversion exists to get wrong) |
| ph19-c09 | lognormal, `mu` = meanlog, `sigma` = log-scale SD | **CONFIRMED** (check C), Jacobian offset exact |
| ph19-c10 | `rho12` link stated as `atanh` / `tanh` | **REFUTED AS STATED** — the link is `0.999999 * tanh`, see N1 |

Nine of ten conversions survive. One is wrong as written. Five secondary defects
follow (N2–N6), none of which flips a verdict but three of which would mislead a
reader reusing these cells.

---

## Part 1 — the six independent recomputations

### Check A. gaussian: is `dispformula` on the SD or the variance?

`drmTMB(bf(mu = Reaction ~ Days, sigma = ~ Days), sleepstudy, gaussian())` — fixed
effects only, so no Laplace step on either side and the likelihoods are exact.

```
drmTMB logLik(fit)                : -938.7163657
  hand dnorm with sd=exp(eta)     : -938.7163657     <- accepted
  hand dnorm with sd=sqrt(exp(eta)): -4647.816851    <- rejected
glmmTMB logLik                    : -938.7163657
  hand dnorm sd=exp(eta_disp)     : -938.7163657     <- accepted
  hand dnorm sd=sqrt(exp(eta_disp)): -4647.816068    <- rejected
drm sigma coefs : 3.389150341 0.09044489792
gtmb disp coefs : 3.389150667 0.09044487235
```

Both packages put the gaussian dispersion linear predictor on `log(SD)`. The
identity conversion c01 applied is correct, and the wrong alternative is off by
3709 log-likelihood units, so this is not a case where two scales happen to be
numerically close. Confirms `docs/design/158-phase-19-comparator-matrix.md:40` from
the density rather than from the cited test.

I also closed doc 158's own flagged gap (`:51-64`, "`glmmTMB::sigma()` … is untested
against this claim"): for `glmmTMB(Reaction ~ Days, data = sleepstudy)`,
`sigma(g) = 47.44887999` and `exp(fixef(g)$disp[[1]]) = 47.44887999` — the accessor
does follow the SD convention **for gaussian**. It does not generalise: see check A'
below.

### Check A'. tweedie — the counter-case doc 158 warns about

No Phase 19 cell fits a tweedie, so nothing in batches 1–4 depends on this. I ran it
anyway because it is the case doc 158 uses to justify "always check the family, not
just the package", and if that warning were itself wrong the batches' reliance on the
table would be unfounded. Simulated `n = 300`, `phi = 1.5`, `power = 1.6`:

```
drm sigma: 0.1962503859   2*sigma: 0.3925007719
gtmb disp: 0.3925035328
phi = sigma^2: 1.480679008
hand dtweedie(phi = sigma^2): -624.0421526   == drmTMB logLik -624.0421526  <- accepted
hand dtweedie(phi = sigma)  : -628.9677362                                  <- rejected
glmmTMB::sigma(g) = 1.480683096  == exp(fixef(g)$disp) = 1.480683096
```

The warning holds, and sharpens: `glmmTMB::sigma()` returns the **SD** for gaussian
and the **dispersion `phi`** for tweedie. The comparator coefficient is
`+2 * coef(fit, "sigma")` for tweedie and `-2 * coef(fit, "sigma")` for nbinom2 —
same magnitude, opposite sign. Anyone who learns "the ×2 rule" from one and applies
it to the other gets a sign error that still lands in the right order of magnitude,
which is the hardest kind to notice. c03 got this right.

### Check B. nbinom2: is `size = 1/sigma^2`, `1/sigma`, or `sigma`?

Source claim: `R/family-dpq.R:902-904`, `drm_nbinom2_size <- function(sigma) 1 / sigma^2`,
with the compiled kernel cited at `src/drm_count_kernels.h:31-41`.
Fixed-effect NB2 on `Owls`:

```
drmTMB logLik                : -1725.172156
  hand dnbinom size=1/sigma^2: -1725.172156   <- accepted
  hand dnbinom size=1/sigma  : -1735.689901   <- rejected
  hand dnbinom size=sigma    : -1822.904632   <- rejected
glmmTMB logLik               : -1725.172156
  hand dnbinom size=exp(eta_disp): -1725.172156
drm sigma coefs      : -0.1308096298  0.5966010819
-2 * drm sigma coefs :  0.2616192596 -1.193202164
gtmb disp coefs      :  0.2616301421 -1.193197558
```

drmTMB's `sigma` maps to `size = 1/sigma^2`; glmmTMB's `dispformula` predictor is
`log(size)` directly. Therefore `log(theta) = -2 * log(sigma)` exactly, and it
propagates to the contrasts because the map is affine on the link scale. c03's
conversion is correct, including the sign. (c03's own counterfactual — that the
naive identity rule would miss by ~0.57 and ~1.81 — checks out on its numbers.)

### Check C. lognormal: is `mu` the meanlog or `log(E[y])`?

This is the trap that would survive a coefficient-by-coefficient eyeball, because
`mu` and `mu - sigma^2/2` differ by a term that is constant only when `sigma` is
constant — and c09 deliberately fits `sigma ~ sex`, so the offset varies by row.

```
drmTMB logLik                        : -2511.448175
  hand dlnorm(meanlog=mu)            : -2511.448175    <- accepted
  hand dlnorm(meanlog=mu-sigma^2/2)  : -2517.471754    <- rejected
  hand dnorm on log(y) (no Jacobian) :   261.3320859
  Jacobian sum(-log y)               : -2772.780261
```

`drmTMB`'s lognormal `mu` is `E[log y]`, **not** `log E[y]`
(`R/family-dpq.R:427-434`, `stats::dlnorm(y, meanlog = params$mu, sdlog = params$sigma)`).
Comparing it against a gaussian fit on `log(y)` is the right comparison, and
`-2511.448175 - 261.3320859 = -2772.780261` reproduces `sum(-log y)` to the last
digit, so c09's Jacobian explanation is exact, not approximate. c09 is clean, and its
warning that `mu` is `E[log y]` is the single most reusable sentence in these four
batches.

### Check D. `meta_V`: is `exp(2 * eta_sigma)` the between-study variance added to `V`?

Source: `R/methods.R:5433-5435`, `drm_total_obs_sd <- function(v_known, sigma) sqrt(v_known + sigma^2)`.
`dat.bcg`, log-RR, 13 trials:

```
drm mu, eta_sigma, exp(2*eta) : -0.7111989566  -0.636432722  0.2800280663
drmTMB logLik                 : -12.66507635
  hand dnorm sd=sqrt(vi+tau^2): -12.66507635   <- accepted
  hand dnorm sd=sqrt(vi+exp(eta)): -13.35786993 <- rejected
rma.uni ML b, tau2, logLik    : -0.7111991392  0.280028171  -12.66507635
```

The two log-likelihoods agree to the printed precision (both `-12.66507635`), which
is a stronger statement than c04's parameter-level `1e-7`: it says the two packages
are maximising the **same function**, so the `tau^2 = exp(2 * eta_sigma)` conversion
is not merely consistent with the estimates, it is forced by them. c04 is correct and
under-reported.

### Check E. cumulative_logit: sign convention and cutpoint orientation

`ordinal::clm` parameterises `logit P(Y <= j) = alpha_j - x'beta`. If drmTMB used
`+x'beta` internally and reported the raw coefficient, c06/c07 would show a sign flip
rather than agreement. I rebuilt clm's own likelihood from its convention and
compared:

```
drm coefs : 2.503102243  1.527796993
clm coefs : 2.503102008  1.527797658
clm alpha : -1.344383411  1.250808798  3.466886926  5.006404204
clm logLik: -86.49192337   hand(alpha - x'beta): -86.49192337
drm logLik: -86.49192337
```

The hand reconstruction under `alpha_j - x'beta` reproduces clm's log-likelihood
exactly, and drmTMB's log-likelihood is identical to 10 significant figures with
coefficients of the same sign. `MASS::polr` (the other comparator doc 158 names at
`:90`) agrees too: `coef(p) = 2.503072697, 1.527785593`, `logLik = -86.49192337`,
i.e. same convention, ~3e-5 looser optimiser. c06 and c07's "no transform" is correct
against both comparators. See N6 for the residual risk this does **not** cover.

### Check F. c05 — the cell I most expected to break

`rma.mv(yi, vi, random = ~ alloc | id, struct = "DIAG")` versus
`sigma ~ alloc` is the only cell where the two models are specified in genuinely
different grammars, and batch 2 declared agreement against `rma.mv`'s **printed**
4-decimal output after admitting its first stated conversion was wrong. That is
exactly the shape of a spurious match. It is not one:

```
drm mu             : -0.657852896316
drm per-level tau^2:  0.0349727917271  0.367068222837  0.284449727832
drm logLik         : -11.9973185172
  hand dnorm sd=sqrt(vi + tau_i^2): -11.9973185172
rma.mv b           : -0.657852949188
rma.mv tau2        :  0.0349727579932  0.367067884652  0.284449711365
rma.mv logLik      : -11.9973185172
abs diff tau^2     :  3.37e-08  3.38e-07  1.65e-08
abs diff mu        :  5.29e-08
abs diff logLik    :  1.05e-12
levels             : alternate / random / systematic, reference = alternate on both sides
```

Identical log-likelihoods to `1.05e-12`. The structural reason batch 2 stopped short
of stating: with one row per `id`, `~ alloc | id` under `struct = "DIAG"` puts a
single random effect on each study with variance `tau^2_{alloc(i)}`, so the marginal
variance is `v_i + tau^2_{alloc(i)}` — which is literally
`drm_total_obs_sd()^2` (`R/methods.R:5433-5435`) with a per-level `sigma`. These are
the same model, not two close models. Write it up as an identity with the
log-likelihood as evidence, not as "agreement to 4 significant figures".

---

## Part 2 — findings

### N1 — MATERIAL. c10's `rho12` link is stated wrongly: it is guarded `tanh`, not `tanh`

`feasibility-batch-4.md:111-114` states "the link is `atanh` (Fisher z), confirmed by
computing `tanh()` of the coefficient sums". The implemented link is
`rho12 = 0.999999 * tanh(eta_rho12)` — `src/drmTMB.cpp:670`, family metadata
`rho12 = "atanh_guarded"` at `R/family.R:34`, documented at `R/family.R:13-15`.
Measured on the exact c10 fit:

```
eta_rho12          : 0.406880709656  0.781444355062  0.782293180518
plain tanh(eta)    : 0.385820920476  0.653534946759  0.654020962407
0.999999*tanh(eta) : 0.385820534655  0.653534293224  0.654020308386
predict(response)  : 0.385820534655  0.653534293224  0.654020308386
predict - tanh     : -3.86e-07  -6.54e-07  -6.54e-07
predict - guarded  :  0          0          0
```

`predict(..., type = "response")` matches the guarded form **exactly** (difference
identically zero) and the plain `tanh` form only to ~6e-7. Two consequences:

1. The inverse conversion a reader would derive from batch 4's sentence,
   `eta = atanh(rho12)`, is wrong; the correct inverse is
   `eta = atanh(rho12 / 0.999999)`.
2. Batch 4's residuals against the descriptive correlations are
   `7.33e-06 / -1.91e-06 / -3.01e-06`. The mis-stated link accounts for 5–34% of
   those, so the residual batch 4 attributes wholly to optimiser tolerance is partly
   its own conversion error. (The remainder really is optimiser tolerance: the fitted
   `sigma1`/`sigma2` sit ~1e-5 relative from the ML per-species SDs — check H —
   which is the same size.)

The cell's UNCERTAIN verdict and its qualitative conclusion both stand. The stated
conversion does not.

### N2 — MINOR. Two of c10's three quoted `tanh` values are misrounded

`feasibility-batch-4.md:113-115` writes `tanh(0.4068807) = 0.3860` and
`tanh(0.4068807+0.3745636) = 0.6536`. The correct values are `0.3858209` and
`0.6535349`, i.e. `0.3858` and `0.6535`. The quoted digits are wrong by ~1.8e-4 and
~6.5e-5 — roughly 300× the 6e-7 guard effect the same paragraph was trying to
confirm. As printed, the check could not have distinguished the right link from the
wrong one; it was only ever a 3-decimal sanity check presented as a link
confirmation.

### N3 — MINOR. One `abs diff` in c01's table is wrong by an order of magnitude

`feasibility-batch-1.md:35` reports `sigma:(Intercept)` `abs diff = 1e-6` for
`2.81184909` vs `2.8118492`. The difference is `1.1e-7`. The error is in the
conservative direction (it overstates the disagreement), and c01's verdict is
unaffected, but the same table's "agreement to 4-5 significant figures" also
understates the sigma coefficients, which agree to 8. Recompute the column before
this table is reused as a tolerance reference.

### N4 — CITATION. Batch 3's "doc 158" line numbers point at the extract, not doc 158

`feasibility-batch-3.md` cites "doc 158's matrix, row `cumulative_logit()`, L69"
(`:43-44`), "doc 158 row `stats::binomial()`, L30" (`:104`), and "doc 158 row
`lognormal()` (L25)" (`:177`). Those are line numbers in
`docs/dev-log/external-oracle/phase19/158-plan-of-record.md`, which is the *extract*.
In `docs/design/158-phase-19-comparator-matrix.md` the same rows are at `:90`, `:47`,
and `:42`. Batch 1 gets this right (it names `158-plan-of-record.md:42-46`
explicitly). A reader following batch 3's citations into the design doc lands on
unrelated lines.

### N5 — CITATION. c10's "credibility-laundering" citation is off by five lines

`feasibility-batch-4.md:137-139` cites
`docs/design/242-external-comparator-evidence-class.md:82-84`. The passage is at
`:86-91` ("Agreement licenses the **overlap** region only, never the **frontier** …
A design that blurs the two is credibility-laundering."). Lines 82-84 are about
whether `lme4` point agreement was withheld from the ledger. The claim batch 4 makes
is correct and the doc does support it — at a different address.

### N6 — SCOPE. The batches license two conversion shapes, not the table

`feasibility-batch-1.md:155-158` reads the c01/c03 pair as "good coverage evidence
that the scale-conversion table … is being read correctly, not just copied." Counting
the table (`docs/design/158-phase-19-comparator-matrix.md:38-49`, ten rows):
batches 1–4 exercise `gaussian()`, `lognormal()`, `stats::binomial()`, `nbinom2()`
and `meta_V(V=V)`. Five rows are never fitted: `student()`, `Gamma(link="log")`,
`tweedie()`, `beta()`, `beta_binomial()`. Of the five exercised, three are identity
conversions; only **two** non-trivial conversions are actually tested — nbinom2's
`-2x` and the meta-analysis `exp(2x)`. Three of the five untested rows
(`Gamma` shape `= 1/sigma^2`, `beta` precision `= 1/sigma^2`, `tweedie`
`phi = sigma^2`) are precisely the non-identity ones. Say "two conversion shapes
verified against densities", not "the table is being read correctly".

Two related gaps, neither an error in the batches:

- **No sign-convention row exists for `cumulative_logit()`.** The scale-conversion
  table has no ordinal row at all; the comparator matrix row
  (`docs/design/158-phase-19-comparator-matrix.md:90`) lists `ordinal::clm`,
  `MASS::polr` and `brms` for "cutpoints, location" without stating whether the
  comparator writes `alpha_j - x'beta` or `alpha_j + x'beta`. I verified `clm`,
  `clmm` and `polr` all use the minus form and all agree with drmTMB unsigned
  (check E). A future cell that swaps in an implementation using the plus form
  would get a clean sign flip with identical magnitudes — the failure mode most
  likely to be read as "our sign convention is documented somewhere" rather than as
  an error. Add the convention to the row.
- **`gamlss` remains untested**, as doc 158 itself already says at `:51-64`. Nothing
  in batches 1–4 changes that, and no cell used `gamlss`.

---

## Part 3 — what I could not refute

For the record, so this audit is not read as broader than it is. These claims I
attacked and failed to break:

- c01, c03, c04, c05, c06, c07, c09: conversions re-derived from the density and
  confirmed, with the wrong alternatives shown to be rejected by large margins
  (checks A–F). No cell declared agreement on incomparable scales.
- c02 declares no conversion, and its parenthetical ("if it had converged, the
  conversion would be the same as c01's") is now verified rather than assumed
  (check A). Its implicit comparison — drmTMB's `sd:sigma:(1|Subject) = 0.506`
  against glmmTMB's collapsed `1.233e-06` — is on a matched scale, since check A
  establishes both dispersion predictors are `log(SD)`; the comparison is therefore
  legitimate and the BLOCKED verdict rests on convergence, not on a scale artefact.
- c08 involves no conversion at all, and its honesty about the ~1e-3 tolerance is
  the correct call — I have no scale-based explanation for the 2–6e-4 gap either, and
  its ruling out of under-convergence by re-fitting `glmer` with tightened tolerances
  is the right test.
- c07's `sd:mu:(1 | judge) = 1.131139` is compared against `clmm`'s `stddev`
  `1.131133`, not its variance `1.279461` — the SD/variance confusion is not present.
- c09's raw `logLik` gap is correctly excluded from the comparison rather than
  explained away.

## Recommended edits

1. `feasibility-batch-4.md:111-115` — replace "the link is `atanh` (Fisher z)" with
   `rho12 = 0.999999 * tanh(eta_rho12)` (`src/drmTMB.cpp:670`, `R/family.R:13-15`),
   give the inverse as `atanh(rho12 / 0.999999)`, and restate the three
   response-scale values to 6 decimals. Note that ~6e-7 of the quoted residual is the
   guard, not optimiser noise.
2. `feasibility-batch-1.md:35` — correct `1e-6` to `1.1e-7`.
3. `feasibility-batch-3.md:43-44,104,177` — repoint the "doc 158 Lnn" citations at
   `158-plan-of-record.md`, or renumber to `docs/design/158-…:90,:47,:42`.
4. `feasibility-batch-4.md:137-139` — repoint to `docs/design/242-…:86-91`.
5. `feasibility-batch-2.md:118-129` — upgrade c05's evidence from "matches to
   `rma.mv`'s printed 4 s.f." to the log-likelihood identity (`1.05e-12`) plus the
   structural argument, and state full-precision `tau^2` diffs (`3.4e-08`,
   `3.4e-07`, `1.6e-08`).
6. `feasibility-batch-1.md:155-158` — narrow the coverage claim per N6.
7. `docs/design/158-phase-19-comparator-matrix.md:90` — add the ordinal sign
   convention (`logit P(Y <= j) = alpha_j - x'beta`, shared by `ordinal` and
   `MASS::polr`, verified here) to the `cumulative_logit()` row.
