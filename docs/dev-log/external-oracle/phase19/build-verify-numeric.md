# Noether — numeric verification of the BUILT Phase 19 artifacts

**Reviewer:** Noether (mathematical consistency), adversarial pass on built artifacts
**Date:** 2026-08-15
**Worktree:** `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/phase19`
**Branch:** `claude/phase19-comparator-workflows` (off `origin/main@82cd00560`)

## Artifacts under review

- `vignettes/comparing-with-other-packages.Rmd` (604 lines, untracked)
- `tests/testthat/test-comparators-phase19.R` (586 lines, untracked)
- supporting diffs: `_pkgdown.yml`, `inst/reader-contracts/vignette-manifest.csv`,
  `tests/testthat/test-reader-vignette-contracts.R`

## Method

Every number below was **re-fitted independently** in a fresh R session — I accepted no
value I did not reproduce. Three independent scripts refit all eight `drmTMB` models and
all eight comparator models from scratch, recomputed every scale conversion by hand from
the coefficient vectors, and recomputed every hand-built likelihood directly from
`stats::dnorm` / `dlnorm` / `dnbinom` rather than trusting the article's chunk output.
I then knit the vignette end to end and read the rendered output, and ran both test files.

```
R_PROFILE_USER=/dev/null Rscript --no-init-file   # R 4.6.0
devtools::load_all(quiet = TRUE)                  # drmTMB 0.7.0 (worktree)
lme4 2.0.1 · metafor 5.0.1 · metadat 1.6.0 · ordinal 2025.12.29
glmmTMB 1.1.14 · palmerpenguins 0.1.1
```

Reproduction scripts:
`/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/55be482f-02d5-4bbb-8b85-7fd279d63c57/scratchpad/noether/{c1-3.R,c4-5.R,c6.R,c7-8.R,extra.R}`

**Gate results.** `testthat::test_file("tests/testthat/test-comparators-phase19.R")` —
41 expectations, 0 failures, 0 skips. `test-reader-vignette-contracts.R` — 21
expectations, 0 failures. `knitr::knit()` on the vignette — all 73 chunks evaluated,
**zero warnings, zero unhandled errors** (the two `error = TRUE` chunks fire as intended).

---

## Verdict

**NOT-DONE.** Two blocking findings, two serious.

Every *arithmetic* claim in both artifacts is correct — I could not break a single scale
conversion, and the Comparison 6 / Comparison 8 fixed-effect-versus-random-effect
separation (the R1 repair) is present and correctly executed. The failures are of a
different kind: **evidence attributed to a model other than the one displayed**
(the exact recurrence class this phase was warned about), a **false statement about the
package's own `DESCRIPTION`**, and **advice that errors on the data shown**.

---

## Findings

### N1 — BLOCKING. Comparison 5 cites the wrong ledger cell: a random-*slope* cell for a random-*intercept* model

The article's Comparison 5 fits and displays

```r
bf(mu = rating ~ temp + contact + (1 | judge))   # ordinary random INTERCEPT
```

and then states:

> The public `mc-0227` slope capability behind this family uses ML-Laplace and is
> point-fit-recovery only; its retained higher-order evidence concerns a package-private
> estimator and grants no public interval or reporting permission.

`mc-0227` is not the cell behind that model. From
`docs/dev-log/dashboard/capability-ledger/cells.tsv`:

| cell | `dpar` | `effect_type` | estimator | `evidence_tier` |
| --- | --- | --- | --- | --- |
| `mc-0225` | `mu` | `ordinary_re_intercept` | ML | **`interval_feasible`** |
| `mc-0227` | `mu` | `ordinary_re_slope` | ML | `point_fit_recovery` |

The displayed model is governed by **`mc-0225`**. The article imports `mc-0227`'s tier
(`point_fit_recovery`) and `mc-0227`'s boundary prose (the O3 AGHQ+Cox-Reid
package-private-estimator caveat) and attaches both to a model neither describes.
`mc-0225`'s own boundary text is materially different:

> interval_feasible only for the named cell x direct intercept-SD target x frozen
> low-rung fixture using an exact retained unclamped tmbprofile receipt.

This is precisely the defect class named in the brief — *a plan cited fixed-effect
log-likelihoods as verification of models it displayed as random-effect* — recurring in
the same phase, now with a ledger cell instead of a log-likelihood. The direction happens
to be conservative (`point_fit_recovery` under-claims relative to `interval_feasible`), but
a boundary statement that names the wrong cell is not a safe boundary statement: a reader
who follows `mc-0227` to the ledger finds a model with `(0 + x | id)`, not `(1 | judge)`.

The upstream plan text is the source (`PR2-build-plan.md:541-546` — "The only REML
comparator study on `cumulative_logit()` (`mc-0227` …)"), where the citation is correct in
its own context (it is about the *REML* study). The article dropped that context and turned
it into "the … capability behind this family."

**Fix:** cite `mc-0225` for the displayed intercept model, with `mc-0225`'s own boundary;
keep `mc-0227` only if the article separately explains it is the slope cell and is not what
Comparison 5 fits.

---

### N2 — BLOCKING. The article's closing framing claim is false: `metadat` is not in `Suggests`

Closing paragraph:

> These eight models were compared against packages listed in `drmTMB`'s `DESCRIPTION`
> under `Suggests`, because those are the packages this article can call.

`metadat` appears nowhere in `DESCRIPTION` (`grep -n -i metadat DESCRIPTION` → no match;
the `Suggests:` block lists ape, callr, detectseparation, emmeans, extraDistr, fmesher,
glmmTMB, ggplot2, JuliaCall, knitr, lme4, MASS, metafor, mvtnorm, numDeriv, ordinal,
palmerpenguins, pkgload, rmarkdown, sf, spelling, statmod, testthat, tweedie, withr).

Comparisons 2 and 3 call it ten times, starting at
`vignettes/comparing-with-other-packages.Rmd:139`, `data(dat.bcg, package = "metadat")`.
So the sentence that justifies the article's scope is contradicted by the article's own
code. It is also the one sentence a reader would use to predict what the article can and
cannot do.

The test file is *honest* about exactly this gap, in its header:

> `metadat` is NOT in DESCRIPTION Suggests. Comparisons 2 and 3 need `metadat::dat.bcg`,
> and the build plan itself recommends adding metadat to Suggests … That DESCRIPTION edit
> is out of scope for this test-only task under the "no new package dependency" constraint

The article asserts the opposite of what the test file records. One of the two is wrong,
and it is the article. (The `has_metadat` guard means the vignette degrades gracefully, so
this is a truth defect, not a render defect — though it is separately an undeclared-vignette-
dependency risk for `R CMD check` that belongs in Grace's lane.)

**Fix:** either narrow the sentence (e.g. "against packages `drmTMB` already suggests, plus
`metadat`, which `metafor` depends on"), or land the `DESCRIPTION` change under a task that
is allowed to make it.

---

### N3 — SERIOUS. Comparison 1 recommends `nbinom2()` as a remedy that errors on the response it displays

> `cbpp`'s known extra-binomial variation is therefore unmodelled symmetrically, not a
> discrepancy between the packages; `beta_binomial()` or `nbinom2()` add a dispersion
> parameter if that matters for your own data.

Run on the model displayed two chunks above:

```
family = beta_binomial()  ->  FITS, logLik = -88.0416468242
family = nbinom2()        ->  ERROR: Internal model-frame mismatch in nbinom2 model.
```

`nbinom2()` is a count family; it cannot take the two-column
`cbind(incidence, size - incidence)` proportion response the comparison is built on. The
sentence names it alongside `beta_binomial()` as if the two were interchangeable remedies
for the situation just described. A reader following it lands on an internal-sounding error
with no guidance — and the project's own writing standard requires telling the reader what
to try next when something is unsupported, not what to try next when it is broken.

**Fix:** drop `nbinom2()` from that sentence, or scope it explicitly to a single-column
count response, which `cbpp` as modelled here does not have.

---

### N4 — SERIOUS. Comparison 5 claims cutpoint agreement but never displays `drmTMB`'s cutpoints

> Every quantity here — slopes, cutpoints, the random-intercept SD, and the
> log-likelihood — agrees closely between the two fits.

The claim is numerically **true** — I measured the cutpoint differences at
`2.36e-06 / 8.65e-06 / 6.69e-06 / 3.48e-06` — but it is not checkable from the article.
Comparison 5's chunks show:

- `summary(fit5)$coefficients` → slopes only (`mu:tempwarm`, `mu:contactyes`)
- `coef(cmp5)` → `clmm`'s **cutpoints and** slopes
- `summary(fit5)$parameters`, `VarCorr` stddev, both `logLik`s

So the reader sees `ordinal`'s four cutpoints (`1|2 … 4|5`) with no `drmTMB` counterpart
anywhere on the page, and is asked to accept agreement on them. Comparison 4 does it
correctly — it prints `summary(fit4)$ordinal$cutpoints` — which makes the omission an
inconsistency inside the same article, not a house style.

The regression test does assert the cutpoints, so the *claim* is guarded; it is the
*article* that asserts more than it shows.

**Fix:** add `summary(fit5)$ordinal$cutpoints` to the `comparison5-drmtmb` chunk (verified
to work: it returns the four named cutpoints), or drop "cutpoints" from the sentence.

---

### N5 — MINOR. The capability table omits Comparison 2 from the `sigma` fixed-effects row

The table row reads

| `Distributional (`sigma`) submodel, fixed effects` | `3, 6, 7, 8` | … |

but Comparison 2 also compares a `sigma` quantity — its intercept, converted as
`tau^2 = exp(2 * coef(fit2, "sigma"))` = `0.280028066337` against
`metafor` `tau2 = 0.28002817105` (abs diff `1.05e-07`), and displayed in the article.
The closing section's "The one separate-engine check on a `sigma` linear predictor is the
meta-analysis comparison" reads as Comparison 3 only. Under-claiming, so not blocking, but
the table states "only what this article did" and here it does not.

---

### N6 — MINOR. Comparison 8's sign remark mangles the plan's cleaner statement

Article: "it is signed the opposite way for `nbinom2()` than it was for the identity rule
in Comparison 6."

The plan's version (`PR2-build-plan.md:730-736`) is sharper and is the one that is actually
symmetric: "the factor is signed by family: it is `-2 *` for nbinom2 and `+2 *` for tweedie
… same magnitude, opposite sign." Contrasting `-2` against a gaussian *identity* rule
(factor `+1`) is not false but loses the point.

I verified the tweedie half of the plan's claim, since it ships as an assertion in the test
file's comment and is verified nowhere in the artifacts: on a simulated tweedie fit,
`2 * coef(fit, "sigma")` = `0.444313202235` against `glmmTMB` `fixef(g)$disp` =
`0.444312479351`, abs diff **7.23e-07**. The `+2 *` claim holds.

---

### N7 — MINOR / cosmetic. Rendered error chunks leak internal function names and source locations

The two `error = TRUE` chunks render as:

```
#> Error in `drm_build_cumulative_logit_spec()` at phase19/R/drmTMB.R:424:3:
#> Error in `drm_family_type()` at phase19/R/drmTMB.R:314:3:
```

The `phase19/` path prefix is a `pkgload` artifact of my worktree build and will differ in
a real build, but the internal function name and a source line reference reach reader-facing
output either way. Both messages themselves are excellent (they name the supported surface
and what to try instead); it is only the `Error in <internal fn> at <file:line>:` header
that is noise for the audience this article names.

---

### N8 — MINOR / cosmetic. `tau_by_level` renders with mangled labels

Comparison 3's convert chunk renders as

```
#>  alternate.(Intercept)     random.(Intercept) systematic.(Intercept)
#>              0.1870101              0.6058616              0.5333383
```

because `sigma3[1]` carries its own `(Intercept)` name into the `c()`. Values are correct;
`unname()` inside the `c()` would fix the labels.

---

## What I verified and could NOT break

All conversions in the brief's checklist were tested against the artifacts. Every one is
right for its family.

| Rule | Where used | Independently reproduced |
| --- | --- | --- |
| gaussian `dispformula` = `log(sigma)`, **no squaring** | Comparison 6 | `coef(fit6,"sigma")` vs `fixef(cmp6)$disp` abs diff `1.5696e-07`, `3.7678e-08`. Hand density with `sd = exp(eta)` reproduces `logLik = -938.716365659` to `3.6e-12`; `sd = sqrt(exp(eta))` misses by **3709.10** ("thousands of units" ✓) |
| `nbinom2` `theta = 1/sigma^2` | Comparison 8 | Hand `dnbinom(size = 1/sigma^2)` reproduces `logLik = -1725.17215645` to `1.1e-10`; `size = 1/sigma` misses by `10.52`; `size = sigma` misses by `97.73`. `-2*coef(fit8,"sigma")` vs `fixef(cmp8)$disp` abs diff `1.1535e-06`, `1.3150e-06` |
| `tweedie` disp = `2*coef(fit,"sigma")` | test-file comment only | verified separately, abs diff `7.23e-07` (N6) |
| `meta_V` `tau^2 = exp(2*sigma)` | Comparisons 2, 3 | C2 `0.280028066` vs `0.280028171` (`1.05e-07`). C3 per level `3.37e-08 / 3.38e-07 / 1.65e-08` |
| `beta` `phi = 1/sigma^2` | not used | n/a |
| `rho12 = 0.999999*tanh(eta)` | not used | n/a |
| lognormal `mu = E[log y]`, not `log E[y]` | Comparison 7 | `meanlog = mu` reproduces `logLik = -2511.44817527` to `2.1e-11`; `meanlog = mu - sigma^2/2` misses by **6.024** |
| lognormal cross-package Jacobian | Comparison 7 | `logLik(fit7) - logLik(cmp7)` = `-2772.78026116` = `sum(-log(y))`, residual `1.55e-11` |

**Fixed-effect versus random-effect separation (the named prior defect) is correct.**
Comparisons 6 and 8 each verify the scale conversion on an explicitly labelled
*fixed-effect variant* where the likelihood is exact, then state plainly that on the
displayed random-effect model `logLik()` is a Laplace marginal and no row-by-row density
identity holds. Comparison 7 has no random effect at all, so its density check is on the
displayed model itself — also correct. I found **no** instance of a fixed-effect number
presented as verification of a random-effect model.

**Every number the test file states as "Measured" is accurate.** Spot-reproduced all of
them: C1 `5.8e-04` / `1.9e-04` / `2.8e-04` (I get `5.771e-04`, `1.904e-04`, `2.845e-04`);
C2 `1.8e-07` / `1.0e-07` / `5.8e-13`; C3 `3.4e-07`, `3.4e-08`, `1.6e-08`, logLik `1.05e-12`;
C4 `~1.5e-06` / `~2.0e-06` / `3.9e-11`; C5 `~1.5e-05` / `~6e-06` / `~3.5e-06`;
C6 `1.57e-07` / `3.77e-08`, logLik `1.63e-11`; C7 mu `~4e-8`, sigma `~1.5e-7`;
C8 mu `~3.1e-06`, sigma `1.15e-06` / `1.32e-06`, logLik `4.20e-10`, naive diff
`-0.566` / `+1.812`.

**Every file:line citation in the test file is accurate.** Given that stale line
references have recurred three times in this phase, I checked all 20 `PR2-build-plan.md`
ranges, all 3 `adversarial-scales.md` ranges, and both `docs/design/242-…md` ranges by
reading the cited content, not by trusting the number. All point at the claimed material
(e.g. `242:108-109` is exactly the **strong** `lme4`/`metafor` bullet; `242:110-111` is
exactly the **weak** `glmmTMB` bullet). I also confirmed `242` contains **no** mention of
`ordinal`, which is what licenses the article's "not yet classified" label for Comparisons
4 and 5.

**Directional / substantive claims all hold.** BCG reduces risk (`mu = -0.711` log RR,
13 trials, alloc counts 2/7/4 ✓); warm serving and contact both increase bitterness (both
slopes positive); the conditional slope exceeds the marginal (`3.063 > 2.503`); residual
spread grows with sleep deprivation (`sigma:Days = +0.0846`); Gentoo heavier than Adelie
on the log scale (`+0.325`); males more variable in log body mass (`sigma:sexmale = +0.437`);
satiated broods more overdispersed (`sigma` `+0.604` ⇒ `size` `1.459 → 0.436`, i.e. lower
size ✓). Dataset facts check out: 5 rating levels, 9 judges × 8 bottles = 72 rows, 333
complete penguins, 599 Owls rows.

**The two boundary demonstrations really fire.** `cumulative_logit()` + `sigma ~ temp`
aborts with "Unsupported parameter: \"sigma\"" while `ordinal::clm(scale = ~ temp)` fits
(`logLik = -86.4394628794`); and with `glmmTMB` attached, a bare `nbinom2()` is rejected by
`drm_family_type()` — I confirmed the masking message lists exactly
`fixef, lognormal, nbinom2, ranef, truncated_nbinom2, tweedie`, which is what the article's
prose claims.

**The article's `predict_parameters()` arithmetic is right per family**, and this is a
place an error would have been easy. It uses `type = "response"` for gaussian and nbinom2
`mu` and `type = "link"` for lognormal `mu`, which is correct for what each hand-built
density needs (`dnorm(mean=)`, `dnbinom(mu=)`, `dlnorm(meanlog=)`). I confirmed each
against `X %*% coef` directly: max abs diffs `5.7e-14`, `0`, `0`, `0`.

---

## Required before this can be called done

1. **N1** — repoint Comparison 5's ledger citation from `mc-0227` to `mc-0225`, with
   `mc-0225`'s own boundary text.
2. **N2** — fix or remove the "packages listed in `DESCRIPTION` under `Suggests`" claim;
   it is false while `metadat` is used.
3. **N3** — remove `nbinom2()` from Comparison 1's remedy sentence.
4. **N4** — display `summary(fit5)$ordinal$cutpoints`, or stop claiming cutpoint agreement.

N5–N8 are worth fixing in the same pass but do not block on their own.
