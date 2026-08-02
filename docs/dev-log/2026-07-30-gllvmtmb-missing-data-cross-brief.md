# Cross-package brief for the drmTMB team — missing-data findings from gllvmTMB

_Written 2026-07-30 by the gllvmTMB missing-data lane. **No drmTMB code was changed and no drmTMB
fits were run.** Everything below is measured on gllvmTMB; the drmTMB statements are quotations from
drmTMB's own docs. Read every claim about this package as a question, not a result._

Companion issues: **#865** (bivariate row-vs-cell), **#866** (`include` family scope),
**#867** (`engine=` signature). This brief is the synthesis; the issues are the actionable items.

---

## 1. Why this may be worth your time

gllvmTMB audited its missing-data surface and expected to find silent row-dropping. It found the
opposite, and the interesting part is **which direction the errors ran**: the machinery was better
than the documentation said. Both packages share Design 59's FIML-via-Laplace contract and the same
four-export API, so the *shape* of the findings is likely to transfer even where the numbers do not.

drmTMB's own 2026-07-11 shipped-docs audit concluded the surface *"errs overwhelmingly toward
UNDER-claiming."* Everything below is consistent with that pattern continuing.

## 2. What gllvmTMB established (measured)

**The default is cell-wise, not case-wise.** `miss_control(response = "drop")` removes the individual
`(unit, trait)` cell, not the row: 30 units × 2 traits, one `NA` → `nobs` **80 → 79**, not 78. The
one-`NA` fit is logLik-identical (Δ = 1.4e-14) to hand-removing just that cell, and clearly different
(Δ = 0.66) from removing the whole unit.

**`drop` and `include` reach the same optimum** — 14 paired fits, max |ΔlogLik| **1.3e-9**:

| family | \|ΔlogLik\| |
|---|---|
| gaussian | 1.5e-09 |
| poisson | 4.0e-10 |
| binomial (0/1) | 4.8e-12 |
| binomial `cbind(succ, fail)`, `NA` in *either* component | 1.1e-09 |
| ordinal_probit | 2.6e-10 |
| delta_gamma | 3.8e-10 |
| delta_lognormal | 2.1e-09 |
| tweedie | 7.3e-10 |
| nbinom2 | 8.0e-11 |

Also held under `latent()`, `dep()`, `indep()`, ordinary `(1|g)`, an all-`NA` unit, and a factor level
whose only unit was entirely `NA` (Δ = 2.8e-14).

**The mechanism is architectural, not family-specific.** With conditional independence given the
random effects the likelihood is a per-row sum, so omitting an unobserved cell and masking it out are
the same operation. That is why the equivalence generalised far beyond the Gaussian cell the tests
covered — and why drmTMB's Gaussian-only scope statement is worth re-checking (#866).

**The distinction is substantive.** 20 of 40 units each missing one trait: cell-wise retains 100
cells across all 40 units where complete-case keeps 60 across 20 — **40 observed cells rescued**.

**It composes with all three estimators.** Verified for Laplace, AGHQ, and REML. The REML restriction
turned out to be conservative and was lifted (agreement 1.4e-14); AGHQ needed a non-Gaussian family
to test at all — see §4.

## 3. The documentation defects found, and their direction

Two, pointing opposite ways. Both are the kind that survive a claims-reconciliation pass.

**Under-claim.** The article said the default *"drops **rows** with missing responses."* Exact in long
format, where a row *is* a cell — but the worked examples lead with the wide shape, where "row" is the
reader's word for a **unit**. A wide-data reader concluded units were being discarded. Meanwhile the
runtime message was *more precise than the documentation*: it said **"cell"**.

**Overclaim.** The article description promised readers would see *"how **each** choice changes the
estimand."* Two of the three choices do not — `drop` and `include` are numerically identical. Worse,
the article's own body already said so 100 lines later. A **cross-page contradiction**, which is the
category most likely to survive review because each page reads fine alone.

**Terminology.** The docs called the default *"the historical complete-case behaviour"* — "complete-case"
being the standard name for listwise deletion, the behaviour this default avoids. That is the seed of
#865: for a **univariate** model the word is exactly right; for **bivariate partial-response rows** it
may not be.

## 4. Traps that cost us time — these are the transferable part

**A claims-reconciliation audit of this article had already passed, three weeks earlier, with no open
items.** Repeating the method would have re-passed it. Every finding above came from *running fits*.
**If a surface has already been audited clean, change the instrument, not the effort.**

**`devtools::test()`-green is not evidence for anything path- or namespace-related.** Three separate
defects shared one shape — green under `load_all()`, red under `R CMD check`: two source-layout path
resolutions (`docs/` and `inst/` do not exist in an installed package) and an `.onLoad` failure.
`load_all()` short-circuits installation, so any bug that only exists in an *installed* package is
invisible to it.

**Engagement before equivalence.** An AGHQ probe reported perfect `drop` vs `include` agreement while
silently **falling back to Laplace** (the model was ineligible for the AGHQ stage). The agreement was
real and meaningless. Every comparison of two routes must first prove they are different
computations. The same trap applies to REML-vs-ML and to any engine flag.

**Gaussian cannot test an engine that improves on Laplace.** Laplace is exact for a Gaussian response
with Gaussian random effects, so AGHQ and LA agree by construction. **Bernoulli** is the discriminating
case — it gave an engagement gap of **0.266** versus Poisson's **5.9e-04**, ~450× larger, because
Laplace is genuinely poor there.

**Automated string checks lie confidently.** A case-insensitive search for `"NA"` matched the letters
in *"diago**na**l"* and returned a verdict that was the exact opposite of the truth. Separately, macOS
BSD `grep -E` silently ignores `\b` and returns zero matches. **Read the matched text; never trust the
boolean.** A grep that requires two tokens on the *same line* also missed a real guard spanning two
lines, and produced a published "0 guards exist" claim that was false.

**"Did it error?" is not a test.** A guard shipped past a green test while emitting
`Invalid cli literal` instead of its intended message, because the test only asserted that *something*
errored. Assert the **diagnosis**.

## 5. Concrete, cheap probes you can lift

Each is a few lines and each settled a real question here.

1. **Cell vs row.** Fit complete; set **one** member of a pair/row to `NA`; refit with defaults.
   Compare `nobs`/`logLik` against two hand-built datasets — one with just that cell removed, one with
   the whole row removed. Whichever it matches is the answer. (This is #865.)
2. **Policy equivalence per family.** Same data, same `NA` pattern, fit under `drop` and `include`,
   compare `logLik`/`coef`/`nobs`. Agreement ⇒ the family already works and only the doc needs
   widening. (This is #866.)
3. **Engine engagement.** Before comparing policies under a non-default engine, prove the engine
   changed the answer on *complete* data. Use a family where Laplace is weak.
4. **Silent-term sweep.** For each formula term a user might plausibly write, classify:
   changes the fit / errors / **accepted-but-bit-identical-to-baseline**. That third class is the
   dangerous one. In gllvmTMB it had exactly one member — `offset()`, which was being silently
   dropped by `model.matrix()`. drmTMB appears **not** to have this (it handles offsets deliberately,
   `allow_offset=`), which is worth knowing as a difference rather than a defect.

## 6. What we checked in drmTMB and found CLEAN

Recorded so nobody re-runs it:

- **`offset()`** — handled deliberately (`drm_reject_phase1_terms(..., allow_offset =)`). Not the
  gllvmTMB bug. Note the asymmetry in drmTMB's favour: **drmTMB supports offsets; gllvmTMB now
  rejects them outright.**
- **`docs/` paths under check** — one runtime reference, guarded, and `^tools$` is build-excluded so
  the block never runs under check.
- **`predict_missing()` mis-attribution** — already fixed; the vignette now correctly reads
  *"`gllvmTMB` adds `predict_missing()`"*.

## 7. Where each package leads

Complements, not competitors — each led where its lane invested.

| | gllvmTMB | drmTMB |
|---|---|---|
| response families with `include` | 9, verified | *"univariate Gaussian … and bivariate Gaussian partial-response rows"* (per your docs) |
| masked-cell extractor | `predict_missing()` | none |
| missing-**predictor** families | Gaussian / binary / ordered / unordered / phylo | **all of those plus** beta, zero-one beta, beta-binomial, Poisson, NB, truncated NB, lognormal, Gamma, Tweedie |
| non-Gaussian response + `mi()` | not established | poisson, binomial, nbinom2, beta |
| offsets | rejected | supported |

Design 67 says gllvmTMB's predictor work was *"grounded in the drmTMB lane's ALREADY-IMPLEMENTED
predictor handling … the concrete porting source."* The borrow direction for **responses** now runs
the other way, if you want it.

## 8. Two caveats on our own claims

- **`|REML − ML|` is an engagement check only.** The two log-likelihoods are not on a common scale;
  REML's is computed after integrating out the fixed effects. Nothing we did shows REML is
  *preferable*.
- **`drop` == `include` is an ML statement, and equality of two optimisation routes is not a claim
  that the marginalisation is exact.** For non-Gaussian families the marginal is a **Laplace
  approximation**. We deliberately walked back an "is FIML over the observed data" phrasing to the
  full-information *principle* plus an explicit note about the approximation — an adversarial pass
  caught it. Worth not overstating the same way.
- **No coverage claim is made anywhere**, and none should be read in.
