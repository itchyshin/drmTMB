# Phase 19 candidate workflow cells (10 proposals)

Author: Ada (integrator), Phase 19 external-oracle survey, 2026-08-14.
Worktree: `.worktrees/external-oracle`, drmTMB 0.7.0 (`DESCRIPTION:3`).
Status of every cell below: **UNCERTAIN**. These are *proposals*. Each formula was
parsed and fitted once to confirm drmTMB can express it and that the fit converges;
none has been through a matched-scale verification pass, a review lens, or a claim
gate. Do not treat any number quoted here as banked evidence.

## What a "cell" is here

Each cell is a data-to-**interpretation** journey, not a bare fit. It names:

1. the reader's question, in the reader's words;
2. a real dataset already reachable from `DESCRIPTION` `Suggests`
   (`DESCRIPTION:39-70`) — no new dependency, no vendored data;
3. the drmTMB model;
4. the comparator model, or an explicit statement that none exists;
5. the **matched-scale conversion** that has to happen before the two sets of
   numbers are comparable;
6. what the reader concludes.

## Governing constraints applied

- `docs/design/242-external-comparator-evidence-class.md:82` — "Agreement licenses
  the overlap region only, never the frontier." Cells 2 and 10 are frontier cells;
  they are included **to draw the boundary honestly**, not to borrow credibility.
- Issue #60 guardrail (quoted in `158-plan-of-record.md:119`) — "Do not imply that
  every `drmTMB` model has a one-to-one comparator."
- `dataset-inventory.md:47-51` — must not repeat the existing
  `biv_lognormal(body_mass_g, flipper_length_mm)` penguins fit from
  `vignettes/bivariate-nongaussian.Rmd:80-105`. Cell 10 uses `biv_gaussian()` on
  `bill_length_mm`/`bill_depth_mm`, a different family and a different variable pair.
- `reader-gap-audit.md:74-80` — `metafor::rma()` (`vignettes/meta-analysis.Rmd:228-242`)
  and `lme4::lmer(REML=TRUE)` (`vignettes/model-selection.Rmd:143-157`) are the only
  live comparator calls in the corpus today, both on **simulated** data. Every cell
  below uses a **real** dataset, which no vignette currently does
  (`reader-gap-audit.md:81-87`).
- `betareg` is installed locally (3.2.5) but is **not** in `DESCRIPTION` `Suggests`
  (`DESCRIPTION:39-70`). No cell uses it. `gamlss` is **absent** from this machine
  entirely, so doc 158's `gamlss` comparator column (`158-plan-of-record.md:34-39`,
  itself flagged unverified) cannot be exercised here at all.

## Coverage against the brief

| Requirement | Cells |
| --- | --- |
| Distributional (`sigma`/dispersion) submodel | 1, 2, 3, 5, 9 (five) |
| Meta-analysis via `meta_V(V = V)` vs `metafor` | 4, 5 |
| Ordinal vs `ordinal::clm`/`clmm` | 6, 7 |
| Count vs `glmmTMB` | 3 |
| No comparator can fit the same thing | 2, 10 |

---

## Cell 1 — Does reaction-time *variability* grow with sleep deprivation?

- **Reader question.** "I already fit `lmer(Reaction ~ Days + (Days|Subject))`. I
  suspect the spread of reaction times widens as well as the mean. Can I model that,
  and does drmTMB give me the same mean model I already trust?"
- **Dataset.** `lme4::sleepstudy` (180 rows, 18 `Subject`; `dataset-inventory.md:68`).
- **drmTMB.**
  `drmTMB(bf(mu = Reaction ~ Days + (1 + Days | Subject), sigma = ~ Days), data = sleepstudy, family = gaussian())`
- **Comparator.**
  `glmmTMB(Reaction ~ Days + (Days | Subject), dispformula = ~ Days, data = sleepstudy)`
- **Matched scale.** Both parameterize the residual SD as `log(sigma)` — **no
  squaring** (`158-plan-of-record.md:23`, verified against
  `tests/testthat/test-comparators.R:780-784`). Compare `fixef(fit)$sigma` to
  `fixef(g)$disp` element-wise.
- **Observed (single exploratory fit, 0.4 s + comparator).** drmTMB
  `mu` = (252.85599, 10.08607), `sigma` = (2.81184909, 0.08463394); glmmTMB
  conditional = (252.86, 10.09), dispersion = (2.81185, 0.08463). Agreement to the
  printed digits on all four coefficients.
- **Interpretation the reader takes away.** `sigma` slope on `Days` is positive, so
  residual spread grows with each day of deprivation — a claim `lmer()` cannot make
  at all because it has one residual SD. The mean model is unchanged, so this is an
  *addition* to what they already believe, not a replacement.
- **Why this cell.** `reader-gap-audit.md:98-106` names this exact comparison the
  "single highest-leverage" one, because location-scale is drmTMB's stated
  differentiator (`CLAUDE.md`, Project Identity).

## Cell 2 — Does *each subject* have their own residual spread? (FRONTIER)

- **Reader question.** "Some subjects are just more erratic than others, regardless
  of the day. Can I put a random effect on the residual SD itself?"
- **Dataset.** `lme4::sleepstudy`.
- **drmTMB.**
  `drmTMB(bf(mu = Reaction ~ Days, sigma = ~ (1 | Subject)), data = sleepstudy, family = gaussian())`
- **Comparator.** **None that works.** `gamlss` (doc 158's nominated scale-RE
  comparator, `158-plan-of-record.md:57`) is not installed on this machine.
  `glmmTMB 1.1.14` *accepts* `dispformula = ~ (1 | Subject)` syntactically but the
  fit returns "Model convergence problem; non-positive-definite Hessian matrix" —
  so it is not a usable oracle here.
- **Matched scale.** N/A — there is nothing to match to.
- **Observed (exploratory).** drmTMB converged (`is_converged() == TRUE`), `mu` =
  (257.4034, 10.5163), `sigma` intercept = 3.627089.
- **Interpretation.** This is the honest boundary. `expressible-vs-comparator.md:109-113`
  classifies scale-side random effects as frontier: "`glmmTMB` treats dispersion as a
  fixed nuisance parameter, not a formula-driven random-effect target." The reader
  should learn that Cell 1's agreement licenses Cell 1, and **not** this.
- **Caveat to carry forward.** The glmmTMB syntactic acceptance is a real nuance and
  must be stated. Writing "no package can express this" would be false; "no package
  produced a usable fit here" is what the evidence supports. This needs a second
  opinion before it goes in front of a reader.

## Cell 3 — Are satiated owl broods *more variable*, not just quieter?

- **Reader question.** "I fit this in `glmmTMB` with a single overdispersion
  parameter. Does food treatment change the overdispersion as well as the mean call
  rate?"
- **Dataset.** `glmmTMB::Owls` (599 rows, 27 `Nest`; `dataset-inventory.md:70`).
- **drmTMB.**
  `drmTMB(bf(mu = SiblingNegotiation ~ FoodTreatment * SexParent + (1 | Nest), sigma = ~ FoodTreatment), data = Owls, family = nbinom2())`
- **Comparator.**
  `glmmTMB(SiblingNegotiation ~ FoodTreatment * SexParent + (1 | Nest), dispformula = ~ FoodTreatment, family = nbinom2, data = Owls)`
- **Matched scale — the load-bearing one.** drmTMB's `sigma` satisfies
  `size = 1 / sigma^2` (`158-plan-of-record.md:31`), so glmmTMB's dispersion
  coefficients (which are `log(size)`) equal **`-2 * coef(drm, "sigma")`**, sign and
  factor both. This is the same trap doc 158 flags for tweedie
  (`158-plan-of-record.md:42-46`: "always check the family, not just the package") —
  Cell 1's *unsquared, unsigned* gaussian rule does **not** transfer here.
- **Observed (exploratory, 3 s).** drmTMB `sigma` = (-0.1887961, 0.6040870); glmmTMB
  dispersion = (0.3776, -1.2082). `-2 * (-0.1887961) = 0.3776`,
  `-2 * 0.6040870 = -1.2082`. Mean-model coefficients agree to five decimals.
- **Interpretation.** Satiated broods have *higher* NB2 `sigma`, i.e. *lower* `size`,
  i.e. more overdispersion. The reader sees that the two packages agree once the
  conversion is applied — and sees, concretely, why reading the raw numbers
  side-by-side without converting would have looked like a disagreement.

## Cell 4 — Pooled BCG vaccine effect and its heterogeneity

- **Reader question.** "I run meta-analysis in `metafor`. If I write the same model
  in drmTMB, do I get the same pooled log risk ratio and the same `tau^2`?"
- **Dataset.** `metadat::dat.bcg` (13 trials), reached via `library(metafor)`
  (`dataset-inventory.md:20-24, 72`), effect sizes built with
  `metafor::escalc(measure = "RR", ai = tpos, bi = tneg, ci = cpos, di = cneg)`.
- **drmTMB.**
  `drmTMB(bf(mu = yi ~ 1 + meta_V(V = vi), sigma = ~ 1), data = dat, family = gaussian())`
- **Comparator.** `metafor::rma.uni(yi, vi, data = dat, method = "ML")`
- **Matched scale.** `V` is known input data in both (`158-plan-of-record.md:32`).
  drmTMB reports `log(tau)` as the `sigma` intercept; metafor reports `tau^2`.
  Convert with `tau^2 = exp(2 * coef(drm, "sigma"))`. Estimator must be **ML on both
  sides** — `rma.uni()` defaults to REML, so `method = "ML"` is mandatory, and doc
  158's matched-scale table has no estimator column at all
  (`158-plan-of-record.md:174-179`).
- **Observed (exploratory, 0.2 s).** drmTMB `mu` = -0.711199, `sigma` = -0.6364327
  → `tau^2` = 0.2800281. metafor ML: `b` = -0.7111991, `tau2` = 0.2800282.
- **Interpretation.** BCG reduces TB risk on average, with substantial
  between-trial heterogeneity. The reader confirms drmTMB reproduces the tool they
  already trust before being asked to trust anything new.
- **Non-duplication.** `vignettes/meta-analysis.Rmd:83` fits the same *grammar* but
  on **simulated** `dat` (`dataset-inventory.md:55-59`). This cell is the first use
  of a real, citable meta-analysis (Colditz et al. 1994) in the corpus.

## Cell 5 — Is heterogeneity itself different between allocation designs?

- **Reader question.** "Randomised and systematically-allocated trials feel like
  different populations. Can I let each allocation type have its own `tau`, instead
  of splitting the dataset and running three meta-analyses?"
- **Dataset.** `metadat::dat.bcg`, `alloc` as a factor.
- **drmTMB.**
  `drmTMB(bf(mu = yi ~ 1 + meta_V(V = vi), sigma = ~ alloc), data = dat, family = gaussian())`
- **Comparator.**
  `metafor::rma.mv(yi, vi, random = ~ alloc | id, struct = "DIAG", data = dat, method = "ML")`
- **Matched scale — two conversions stack.** (i) variance to log-SD as in Cell 4;
  (ii) **contrast to cell mean**: drmTMB uses treatment contrasts, `rma.mv(struct="DIAG")`
  reports one `tau^2` per level. Compare `cumsum`-style: level `k`'s drmTMB log-tau is
  `intercept + coef_k`.
- **Observed (exploratory, <1 s).** drmTMB `sigma` = (-1.676592, +1.175489, +1.047993)
  → cell means (-1.676592, -0.501103, -0.628599). metafor DIAG `log(tau)` =
  (-1.676593, -0.5011042, -0.6285994).
- **Interpretation.** Alternate-allocation trials are nearly homogeneous
  (`tau ≈ 0.19`) while randomised and systematic trials are not (`tau ≈ 0.61`,
  `0.53`) — a *distributional* meta-analysis result, delivered from one fit.
- **Caveat.** `rma.mv(struct = "DIAG")` is a close but not obviously identical
  parameterization to `sigma ~ alloc`; the numeric agreement above is suggestive, not
  proof. Whether these are the same model needs a symbolic check, not just matching
  digits.

## Cell 6 — Does serving temperature shift wine bitterness ratings?

- **Reader question.** "I use `ordinal::clm()` for proportional-odds models. Does
  drmTMB's `cumulative_logit()` give me the same cutpoints and slopes?"
- **Dataset.** `ordinal::wine` (72 rows, 5-level `rating`, 9 `judge`;
  `dataset-inventory.md:73`).
- **drmTMB.**
  `drmTMB(bf(mu = rating ~ temp + contact), data = wine, family = cumulative_logit())`
- **Comparator.** `ordinal::clm(rating ~ temp + contact, data = wine)`
- **Matched scale.** Same logit link and same cumulative direction; compare location
  slopes directly, and compare the four cutpoints as an ordered set. No conversion.
- **Observed (exploratory, <1 s).** drmTMB `tempwarm` = 2.503102, `contactyes` =
  1.527797; `clm` = 2.503102, 1.527798.
- **Interpretation.** Warm serving and contact both push ratings toward "more
  bitter", on a well-known teaching dataset (Randall 1989) the reader can look up.
- **Boundary to state explicitly.** `cumulative_logit()`'s `dpars` is `c("mu")` only
  (`R/family.R:415-418`) — there is **no** scale/discrimination submodel, matching
  doc 158's "scale/discrimination not modelled here"
  (`158-plan-of-record.md:69`). `dataset-inventory.md:73` suggests "a scale submodel
  `~ temp`" for this dataset; **that is not expressible in drmTMB 0.7.0** and no cell
  here proposes it. A reader wanting non-proportional odds should be pointed at
  `ordinal::clm(..., scale = ~ temp)` instead.

## Cell 7 — Do judges differ, and does that change the temperature effect?

- **Reader question.** "Nine judges each rated eight bottles. If I add a judge random
  intercept, do my conclusions move — and does drmTMB match `clmm()`?"
- **Dataset.** `ordinal::wine`.
- **drmTMB.**
  `drmTMB(bf(mu = rating ~ temp + contact + (1 | judge)), data = wine, family = cumulative_logit())`
- **Comparator.** `ordinal::clmm(rating ~ temp + contact + (1 | judge), data = wine)`
- **Matched scale.** Compare fixed slopes, cutpoints, and the `judge` SD. `clmm`
  stores the RE SD in its `ST` component; drmTMB exposes it via `ranef()`/`summary()`.
  **Estimator caveat:** `clmm` uses Laplace by default and drmTMB is ML-Laplace here,
  but this must be checked, not assumed — `expressible-vs-comparator.md:78` notes
  the only REML comparator study on this family (`mc-0227`) is package-private and
  licenses no public interval claim.
- **Observed (exploratory, 0.3 s).** drmTMB converged; `clmm` gives `tempwarm` =
  3.062997, `contactyes` = 1.834885, `judge` variance component 1.131133. Both
  slopes move away from Cell 6's marginal estimates in the same direction — the
  expected conditional-vs-marginal shift.
- **Interpretation.** Ignoring judge identity attenuates the temperature effect.
  This is a genuine applied lesson, and the comparator makes it checkable.
- **Caveat.** drmTMB's numbers for this cell were not extracted in this survey —
  only convergence was confirmed. The agreement claim is untested.

## Cell 8 — Contagious bovine pleuropneumonia risk across periods and herds

- **Reader question.** "This is the `glmer` binomial example I learned mixed models
  on. Does drmTMB reproduce it?"
- **Dataset.** `lme4::cbpp` (56 rows, 15 `herd`; `dataset-inventory.md:69`).
- **drmTMB.**
  `drmTMB(bf(mu = cbind(incidence, size - incidence) ~ period + (1 | herd)), data = cbpp, family = binomial())`
- **Comparator.**
  `lme4::glmer(cbind(incidence, size - incidence) ~ period + (1 | herd), family = binomial, data = cbpp)`
- **Matched scale.** Logit coefficients directly; `herd` SD vs `sqrt(VarCorr)`. Both
  are ML-Laplace at `nAGQ = 1`.
- **Observed (exploratory, 0.1 s).** drmTMB `mu` = (-1.3985281, -0.9923386,
  -1.1286497, -1.5803225); `glmer` = (-1.398343, -0.991925, -1.128216, -1.579745).
  Differences ~2e-4 to 5e-4 — close, **not** the exact agreement of Cells 1/3/4.
- **Interpretation.** Infection risk falls monotonically after period 1. The reader
  sees agreement at the level a Laplace-vs-Laplace comparison actually supports.
- **Caveat.** The residual ~5e-4 gap is unexplained and must not be waved away as
  "rounding" — it needs either an explanation (different Laplace inner solve,
  different convergence tolerance) or an honest "we do not know why" before this
  goes in front of a reader. `158-plan-of-record.md:174-179` records the same class
  of problem for `lme4`'s shipped fixtures.
- **Boundary.** `stats::binomial()` in drmTMB has `dpars = c("mu")` only
  (`expressible-vs-comparator.md:74`) — no overdispersion submodel. Overdispersion
  in `cbpp` is real and should be named as a limitation, pointing the reader to
  `beta_binomial()` or `nbinom2()`.

## Cell 9 — Are male penguins more variable in body mass than females?

- **Reader question.** "I want the mean difference between species *and* whether one
  sex is more variable. Can one model give me both?"
- **Dataset.** `palmerpenguins::penguins`, complete cases on
  `species`/`sex`/`body_mass_g` (333 rows).
- **drmTMB.**
  `drmTMB(bf(mu = body_mass_g ~ species, sigma = ~ sex), data = pen, family = lognormal())`
- **Comparator.**
  `glmmTMB(log(body_mass_g) ~ species, dispformula = ~ sex, data = pen)`
- **Matched scale.** drmTMB `lognormal()` puts an identity `mu` on `log(y)` and
  `sigma` is the **log-scale SD** (`158-plan-of-record.md:25`), so the comparison is
  a Gaussian fit on `log(y)`, coefficient-for-coefficient, `log(sigma)` unsquared.
  The reader must be told `mu` here is **not** `E[y]`.
- **Observed (exploratory, 0.9 s).** drmTMB `mu` = (8.17272037, 0.02447963,
  0.32491983), `sigma` = (-2.4243950, 0.4374102); glmmTMB conditional =
  (8.17272, 0.02448, 0.32492), dispersion = (-2.4244, 0.4374).
- **Interpretation.** Gentoo penguins are ~38% heavier than Adélie on the response
  scale, and males are ~55% more variable in log body mass than females
  (`exp(0.4374)`). The sex-variance result is the part `lm()`/`lmer()` cannot deliver.
- **Non-duplication.** `vignettes/bivariate-nongaussian.Rmd:80-105` uses
  `biv_lognormal()` on `body_mass_g` + `flipper_length_mm`. This is univariate, a
  different family object, a different second axis (`sigma ~ sex`), and a different
  question (`dataset-inventory.md:47-51` permits exactly this reuse).

## Cell 10 — Does bill shape *co-vary* differently across species? (NO COMPARATOR)

- **Reader question.** "Within a species, do penguins that have a longer bill also
  have a deeper one? And is that coupling the same in all three species?"
- **Dataset.** `palmerpenguins::penguins`, complete cases (333 rows).
- **drmTMB.**
  ```r
  drmTMB(bf(mu1 = bill_length_mm ~ species, mu2 = bill_depth_mm ~ species,
            sigma1 = ~ species, sigma2 = ~ species, rho12 = ~ species),
         data = pen, family = biv_gaussian())
  ```
- **Comparator.** **None.** Doc 158's own matrix states it: "predictor-dependent
  `rho12 ~ x` has essentially no frequentist comparator"
  (`158-plan-of-record.md:58`). `expressible-vs-comparator.md:79` classifies
  `biv_gaussian()` with formula-capable `rho12` as FRONTIER throughout;
  `MCMCglmm`/`brms` fit multivariate mixed models but are Bayesian and do not share
  this grammar, and neither is in `DESCRIPTION` `Suggests`.
- **Matched scale.** N/A. The nearest *partial* check a reader can run themselves is
  a per-species `cor(bill_length_mm, bill_depth_mm)` — which recovers the residual
  correlation only because every submodel here is species-saturated. That is a
  descriptive sanity check, **not** a comparator, and must be labelled as such.
- **Observed (exploratory, 0.3 s).** Converged. `rho12` (on the internal
  correlation link) = (0.4068807, +0.3745636, +0.3754125) — positive coupling in all
  three species, and stronger in Chinstrap and Gentoo than in Adélie.
- **Interpretation.** Bill length and depth are positively coupled *within* species —
  the opposite sign to the raw pooled correlation, a textbook Simpson's-paradox
  reversal that the reader can see resolved by the model. And the coupling itself
  varies by species, which is the parameter no other frequentist package estimates.
- **Why this cell earns its place.** It is the honest counterweight to Cells 1, 3, 4,
  6, 8, 9. Per `docs/design/242-external-comparator-evidence-class.md:82-84`,
  presenting frontier results next to overlap agreement *without saying which is
  which* is named "credibility-laundering". This cell must be explicitly marked as
  unlicensed by any of the agreements above.

---

## Cross-cutting risks for whoever builds these

1. **Estimator is unstated everywhere.** Doc 158's matched-scale table has no ML/REML
   column (`158-plan-of-record.md:174-179`). Cells 4, 5, 7, 8 are all
   estimator-sensitive; Cell 4 already needs an explicit `method = "ML"` to avoid a
   silent REML-vs-ML comparison. Every cell needs its estimator pinned on both sides
   before any agreement is claimed.
2. **Two cells report *inexact* agreement** (8 at ~5e-4, 5 at a possibly-different
   parameterization). Those gaps are findings, not noise, until explained.
3. **`beta_binomial()` with `sigma ~ period` on `cbpp` was tried and rejected** — it
   returns "false convergence (8)" with `NaN` standard errors and an implausible
   `sigma` coefficient of -7.09. It is not proposed as a cell. Recording the negative
   result so nobody re-derives it.
4. **All timings above are single exploratory fits on this machine**, longest 3 s
   (Cell 3). No cell is near the 5-minute budget, but no cell has been timed
   reproducibly with versions/platform recorded, which issue #60 requires
   (`158-plan-of-record.md:122-124`).
5. **A new reader vignette carries four coupled edits**, not one:
   the `.Rmd`, `_pkgdown.yml`, `inst/reader-contracts/vignette-manifest.csv`, and the
   hard-coded `37L` row count in `tests/testthat/test-reader-vignette-contracts.R`
   (`reader-gap-audit.md:184-211`). The forbidden-vocabulary linter applies to
   **prose as well as code chunks** (`reader-gap-audit.md:135-163`).

## Commands used for the expressibility checks

All run from `.worktrees/external-oracle` as
`R_PROFILE_USER=/dev/null Rscript --no-init-file <script>` with
`devtools::load_all(".", quiet = TRUE)` (drmTMB 0.7.0 from this worktree, never the
installed 0.6.0). Scripts are scratch files under the session scratchpad and are not
committed. Comparator versions on this machine: `glmmTMB` 1.1.14, `lme4` 2.0.1,
`metafor` 5.0.1, `metadat` 1.6.0, `ordinal` 2025.12.29, `MASS` 7.3.65,
`palmerpenguins` 0.1.1, `betareg` 3.2.5 (present but not in `Suggests`),
`gamlss` ABSENT.
