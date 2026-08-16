# MSPL for boundary conditions — the transfer packet

**2026-08-16 · assembled by Claude (orchestrator) for Shinichi, from five commissioned reviews ·
question: should drmTMB generalise MSPL — implemented today for binomial separation — to deal with
boundary conditions generally (random-effect SDs at zero; correlations at ±1)?**

**Reader: Shinichi.** You asked what I think, and asked the team and the literature. This packet
gives the verdict first, then the evidence that forces it, then the programme that would earn the
capability. The five source reviews are cited throughout and live beside this file:

- [`…-fisher-verdict.md`](2026-08-16-mspl-transfer-fisher-verdict.md) — inference (Fisher, adversarial, with an exploratory measurement)
- [`…-noether-math.md`](2026-08-16-mspl-transfer-noether-math.md) — mathematical transfer conditions (Noether)
- [`…-gauss-engineering.md`](2026-08-16-mspl-transfer-gauss-engineering.md) — implementation surface (Gauss)
- [`…-pat-practitioner.md`](2026-08-16-mspl-transfer-pat-practitioner.md) — the user's seat (Pat)
- [`…-ranga-literature.md`](2026-08-16-mspl-transfer-ranga-literature.md) — external literature, NotebookLM-grounded (Ranga)

---

## 1. Verdict

**Yes to the research programme; no to shipping anything yet — and the eventual surface should be
the `penalty` vocabulary, not the `estimator = "mspl"` token.**

The *direction* is right, and the timing is right: after tonight's REML arm, the boundary is the
measured residual of the small-`g` coverage problem (pooled 0.9248 → 0.9463 under REML while
boundary incidence barely moved, 0.153 → 0.138, and conditional-on-boundary coverage stayed poor at
0.83 — `…/2026-08-15-d117-reml-arm/VERDICT.md`). A soft penalty is the one lever class aimed at
exactly that residual, the formal template was published this year, and the literature has a
measurable gap drmTMB could be first to fill (§5).

But all five reviews — independently — found that the *shipped* penalty cannot simply be switched
on for this purpose, and two of them found defects that would corrupt the very campaign meant to
validate it. The work is real: a derivation, then a design decision, then a pre-registered
campaign. Shipping first and understanding later would repeat the chi-bar mistake with a more
plausible-looking lever.

## 2. What we already have — more than the question assumed

**MSPL already penalizes a variance block.** The binomial MSPL is not fixed-effects-only: a
negative-Huber term `D(t)` on the Cholesky log-SD coordinates sits in the C++ objective today
(`src/drmTMB.cpp:5022-5046`; design 250 §181-215). So the proposal is *extending an implemented
mechanism* — past binomial, past q2, past one grouping factor — not building from nothing
(Noether §0). Gauss maps the reusable plumbing and rates the wiring **medium** feasibility.

**The theory template exists and is general.** Sterzinger, Kosmidis & Moustaki 2026
(*Psychometrika* 91:494–507) state the conditions in exactly the form a scalar-RE-SD transfer
needs: existence in the interior requires the penalty to be continuous, bounded above, and to
diverge to −∞ at the boundary (E1–E3, Thm 4.1); consistency needs `oₚ(n)`; **asymptotic normality
needs the strictly stronger `oₚ(√n)` softness rate** (Thm 5.2) (Ranga §1). One correction to the
question's framing: the Diaconis–Ylvisaker 2026 paper is a high-dimensional *separation* result,
not a boundary step — the factor-analysis paper is the template (Ranga, corrected with the full
text).

**And the adjacent practice is instructive.** Chung et al. 2013 (`blme`) measured the exact
phenomenon we measured in D-117 — at J=3 groups, 45–47% of ML/REML fits collapse to exactly zero;
their log-gamma penalty gives 0% — and measured the costs honestly: over-coverage when the true SD
*is* zero, interval widths +20% at J=5, and a shape parameter that is optimal for point bias
(α=2) but not for coverage (α=3) (Ranga §2–3).

## 3. The five findings that gate shipping

**F1 — The shipped penalty is anchored at `sd = 1` in the user's response units (Fisher; measured).**
`D(t)` penalizes distance of `log(sd)` from 0. Fisher ported it onto the D-117 design: bias
improves at true sd 0.5 (−13.2% → −6.6%), does nothing at 1.0, and *worsens* at 2 and 4; fitting
`y` vs `100·y` and back-scaling disagree by up to 0.374 in the SD. It is a prior centred on an
accident of measurement, not a bias correction. (Exploratory, 400 reps, ~1.5 pt MCSE — but the
anchor is an algebraic property of the shipped form, not a simulation artefact.)

**F2 — And that anchor poisons the obvious validation campaign (Fisher).** The D-117 grid has
`sd_mu ∈ {0.5, 1.0}` — at or below the anchor — so a campaign on that grid **cannot separate
"corrects bias" from "pulls toward 1, and 1 is near the truth."** The rigged-DGP failure mode,
self-inflicted. Any claim-bearing campaign needs an sd-ladder *spanning* the anchor and a
scale-equivariance gate run first.

**F3 — The softness constant does not transfer (Noether + Gauss, independently).**
`c_n = 2√(p/n_eff)` is calibrated to fixed-effect information, which grows at rate ~n.
Variance-component information grows at the rate of the number of groups `g`, and `oₚ(√n)` does
not imply `oₚ(√g)` — precisely in the small-`g` regime this targets. Each block class needs its
own symbolic `c` derivation and calibration study before the wiring is even correct. Related
category error to avoid: a Jeffreys-style prior on a variance component is *flat on the log
scale* (growth order c = 0) — it does not repel the boundary at all; the FE and VC penalties need
structurally different families (Noether §1).

**F4 — The most certain effect is deleting the boundary *flag*, not the boundary *miss* (Fisher).**
`profile.boundary ⟺ profile_lower == 0` exactly; a penalized profile never reaches zero, so 49.7%
incidence reads ~0% while the upper endpoint — the only side that misses — is set by the
likelihood where the penalty is flat. The chi-bar arm already proved the boundary sub-population
is a *selection effect*: any campaign must score conditional coverage on the **ML-defined**
boundary subset via paired seeds, or it will report a fix that does not exist. Ranga's sweep
confirms the pattern externally: Chung's penalty repairs under-coverage when sd > 0 but
*over-covers* at the true null — penalties relocate the failure mode; they do not abolish it.

**F5 — Downstream inference is where undecayed penalties kill (Ranga; the sharpest external
warning).** In the factor-analysis paper's simulations, non-decaying versions of the classical
penalties made AIC/BIC "completely fail" to select the correct model — restored only by the
`oₚ(√n)` decay. The softness rate is not cosmetic; it is what protects `anova`/AIC/model-selection
downstream. Note also `blme`'s documented one-sided failure: its penalty guards sd = 0 but let
estimates diverge past 800 under separation — a boundary penalty must state which boundaries it
guards.

## 4. The design decision — Pat's answer, and I adopt it

**Surface it through `penalty`, not `estimator`.** Design doc 250 already disclaims
`estimator = "mspl"` as *not* an alias for the `penalty` mechanism; adding a third overloaded
meaning to "MSPL" would land in exactly the gap that disclaimer fenced. The least-confusing
surface for the boundary generalisation is an explicit, inspectable, opt-in `penalty` object
(blme's `cov.prior` shape; the `drm_phylo_penalty()` precedent, with the fit already visibly
relabeled MAP-class) extended to ordinary `sd(group)` targets (Pat §3). This also sidesteps the
estimator-token ledger problem entirely.

**Opt-in, never default — and the reason is the audience, not just caution.** drmTMB's own
citation base (Wolak's repeatability paper in `?confint.drmTMB`) says the primary RE-SD audience
asks *"is there any among-group variance?"* — the question a never-zero estimator erases by
construction. And the lme4-to-1e-6 agreement plus 4000/4000 boundary-incidence parity is the sole
basis for attributing the D-117 shortfall to the ML *estimator class* rather than to drmTMB; a
penalized default destroys that attribution (Fisher R3, Pat §2/§4). The documentation obligation,
when it ships: state in the first paragraph that lme4/glmmTMB return exactly 0 on the same data
and that the estimand is a regularized point, not the MLE.

**REML × penalty stays mutually exclusive for now.** The current hard reject is the
mathematically defensible position — the softness rate would need re-derivation against REML's own
effective information, and no such derivation exists anywhere yet (Noether §5).

## 5. Why still yes — the opportunity is real and specific

- **The residual is boundary-shaped and nothing else on the shelf touches it.** REML is spent;
  chi-bar made it worse; design 219's Wald correction is fenced away from boundaries by its own
  documentation. This is the last named lever class.
- **The literature gap is ours to take:** Ranga found **no study anywhere of profile-likelihood
  interval coverage under a penalized variance-component estimator** — the 2013/2015 evidence is
  Wald-on-fixed-effects only. drmTMB's D-117 harness is purpose-built to produce exactly that
  evidence at 400k-replicate scale. First-to-measure, on top of first-to-implement.
- **A fresh lead to read before deriving:** Košuta, Langerholc & Blagus 2026 (*Biometrics* 82(1))
  — data-augmentation (pseudo-observation) priors that implement a boundary-avoiding penalty
  inside existing ML/REML machinery, reporting near-nominal Wald coverage for their penalized ML.
  Paywalled; abstract-level only; **UNVERIFIED** — but if it holds, the pseudo-observation route
  might deliver the penalty without touching the C++ objective at all.
- **The heritability question is unstudied and is our audience's question.** No source connects
  penalized variance components to heritability/repeatability estimation. The mechanical worry
  (upward bias in a variance *ratio* when the true numerator is near zero) is AGENT-INFERRED, not
  sourced — a small ratio-target simulation would be both a safety check and a novel result
  (Ranga §5).

## 6. The programme — earn it in five slices

| slice | what | cost | gate |
| --- | --- | --- | --- |
| **S0** | Fisher's two pre-run gates on the *shipped* penalty: scale-equivariance test + anchor-sensitivity ladder. Documents F1 precisely, in-repo | hours, local/Totoro-light | produces the defect record that motivates S1 |
| **S1** | **The derivation** (the real work): a scale-equivariant penalty form (anchor from the data scale, e.g. relative to residual σ, or standardized parameterisation) with softness `c_g = oₚ(√g)` derived for group-rate information, on the E1–E3 + rate template; state which boundaries it guards (zero AND divergence); the composite condition with the FE Jeffreys term; read Košuta 2026 in full first | days; Noether-led, symbolic-alignment discipline | Noether + Fisher sign-off on the derivation before any code |
| **S2** | Narrow implementation: the derived penalty on the A1 iid `sd(group)` cell only, as a `penalty` vocabulary extension (NOT an estimator token), experimental, fit visibly MAP-labeled, `confint` withheld | Gauss: medium; the D-117 harness gains one argument | tests ship with implementation; no user-facing claim |
| **S3** | **The pre-registered campaign**: sd-ladder spanning the anchor (≥ {0.25, 0.5, 1, 2, 4}) × g-ladder ({5, 10, 25}), paired seeds, arms ML / REML / penalized; conditional coverage scored on the **ML-defined** boundary subset; prediction committed before results, per house practice | Totoro, ~1–2 h at 150 cores (estimate to be re-based on an S2 timing probe — D-139) | the numbers decide option-vs-nothing; two NOT-DONE verdicts withhold |
| **S4** | The audience slice: heritability/repeatability *ratio-target* simulation under the penalty — tests the AGENT-INFERRED upward-bias risk that no literature covers | Totoro, small | gates any recommendation to the quantitative-genetics audience |

Sequencing note: S0 is independent and cheap — it can run any time. S1 blocks S2 blocks S3/S4.
Nothing here belongs in 0.7.0; the candidate is frozen and this programme is 0.8.0-track at the
earliest.

## 7. What I think, in three sentences

The question found the right target — the boundary is the measured residual, the softness theory
is fresh, and the audience is everyone who fits a mixed model at ten groups. The shipped penalty
is not that tool yet: it is anchored to the response scale, its softness constant is calibrated to
the wrong information rate, and the obvious validation grid would have flattered it — three
defects that five independent reviews surfaced before a line of code was written, which is
exactly what the consult was for. Do the derivation first, surface it as an opt-in `penalty` with
the honesty label Pat specified, and let a pre-registered ladder campaign — scored on the
ML-defined boundary subset — decide whether it ever becomes more than an option.

---

## Provenance and negative space

Assembled from five independent reviews commissioned 2026-08-16 (each cites file:line for repo
claims; Ranga's carries an explicit UNVERIFIED ledger, including the corrected Diaconis–Ylvisaker
framing and the abstract-only Košuta read). Fisher's §0 numbers are an exploratory 400-replicate
port, labeled as such — not package output, not claim-bearing. This packet makes **no capability
claim, changes no code, and touches no release surface**; the 0.7.0 candidate (`302ac2579`) is
unaffected. What this packet does NOT cover: correlations at ±1 beyond noting them as a target
class (the derivation slice must treat them explicitly); bivariate/structured blocks (S2 is
deliberately iid-only); and any REML-composite variant (deferred with reasons, Noether §5).

> Related: design 250 (MSPL binomial alignment) · design 218/219 (the bias-correction wall) ·
> `…/2026-08-15-d117-reml-arm/VERDICT.md` · `…/2026-08-05-d117-chibar-cutoff-arm/VERDICT.md` ·
> brain `ENGINEERING-NOTEBOOK` (the MSPL trilogy) · dr20 · dr32
