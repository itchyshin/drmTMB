# MSPL for boundary variance components — external literature sweep

**2026-08-16 · Ranga (grounded-search librarian) · route: NotebookLM CLI (v0.8.0, authenticated),
degraded to WebSearch/WebFetch for two paywalled sources · feeds the MSPL transfer packet in
`docs/dev-log/research/2026-08-16-drmtmb-mspl-transfer-packet.md`**

Self-citation guardrail applied: drmTMB's own vignettes, design docs, and dev-log are excluded from
the corpus. Everything below is third-party.

## Corpus

NotebookLM notebook `d1c0243a-5286-4b29-9dbb-ae01e40e1f7d` ("MSPL boundary variance components"),
8 sources at `status: ready`, spot-checked by `source fulltext` for real content (not a block page):

| # | Source | Verified via |
|---|---|---|
| 1 | Sterzinger & Kosmidis 2023, *Stat Comput* 33:53, "Maximum softly-penalized likelihood for mixed effects logistic regression" | arXiv:2206.02561 PDF, 77,470 chars, full text confirmed |
| 2 | Sterzinger & Kosmidis 2026, *Biometrika* (advance access), "Diaconis–Ylvisaker prior penalized likelihood for p/n→κ∈(0,1) logistic regression" | arXiv:2311.07419 PDF, 244,696 chars, full text confirmed |
| 3 | Sterzinger, Kosmidis & Moustaki 2026, *Psychometrika* 91:494–507, "Maximum softly penalised likelihood in factor analysis" | arXiv:2510.06465 PDF, 86,181 chars, full text confirmed |
| 4 | Chung, Rabe-Hesketh, Dorie, Gelman & Liu 2013, *Psychometrika* 78(4):685–709, "A nondegenerate penalized likelihood estimator for variance parameters in multilevel models" (the `blme` paper) | PDF from `stat.columbia.edu`, 85,331 chars, full text confirmed |
| 5 | Chung, Gelman, Rabe-Hesketh, Liu & Dorie 2015, *J. Educational and Behavioral Statistics*, "Weakly Informative Prior for Point Estimation of Covariance Matrices in Hierarchical Models" | web page (SAGE abstract page — NotebookLM ingested abstract-level content only, see ledger) |
| 6 | Gelman 2006, *Bayesian Analysis* 1(3):515–534, "Prior distributions for variance parameters in hierarchical models" | PDF (`taumain.pdf`), full text confirmed |
| 7 | `blme` CRAN citation page | web page, ready |
| 8 | (dropped from corpus — paywalled, see below) | — |

Two sources could not be ingested and were excluded rather than left as dead weight: the *Statistics
and Computing* SpringerLink page for source 1 (paywalled; superseded by the arXiv full text already
in the corpus) and the *Biometrics* 82(1) landing page for Košuta, Langerholc & Blagus 2026 (also
paywalled). For the latter I instead read the abstract/results directly via `WebFetch` — flagged
**UNVERIFIED (abstract-level only, not NotebookLM-grounded)** throughout §3–§4 below.

---

## 1. The MSPL line

**Sterzinger & Kosmidis 2023** (mixed-effects logistic regression) introduces the additive penalty:
Jeffreys' invariant prior (for the model with no random effects) on the fixed effects, composed with
a **negative Huber loss** on the variance components, scaled so the penalized MLE lies in the
parameter-space interior while remaining asymptotically negligible.

**Sterzinger & Kosmidis 2026** (*Biometrika*, arXiv:2311.07419) is the paper that answers to
"Diaconis–Ylvisaker 2026 variant" in the task brief. Reading the actual text: **it is not a mixed-model
variance-component paper**. It is a **high-dimensional logistic-regression** result (fixed effects
only, no random effects), characterizing the maximum Diaconis–Ylvisaker-prior-penalized likelihood
estimator when the covariate-to-observation ratio `p/n → κ ∈ (0,1)`, constructing a rescaled
zero-asymptotic-bias estimator and adjusted Z-statistics. It generalizes the *separation* problem
(non-existence of the MLE) to the proportional-asymptotics regime, not the *boundary variance
component* problem. **Correction to the brief's framing:** this is a sibling extension of the
separation line, not a step toward variance-component boundaries.

**Sterzinger, Kosmidis & Moustaki 2026** (*Psychometrika* 91:494–507, factor analysis / Heywood
cases) is the paper that generalizes MSPL to a genuine **boundary-of-parameter-space** problem
(non-positive unique-variance estimates), and its conditions are stated formally (Theorem 4.1, 5.1,
5.2; quoted verbatim from the ingested text, not paraphrased):

- **Existence in the interior (Thm 4.1).** The penalty `P*(θ)` must be (E1) continuous on the
  parameter space `Θ`; (E2) bounded above on `Θ`; (E3) diverge to `−∞` along any sequence approaching
  the boundary `∂Θ` while the minimum eigenvalue of the implied covariance `Σ(θ)` stays bounded away
  from 0.
- **Consistency (Thm 5.1, condition C3 + rate).** `P*(θ) ≤ 0` everywhere, and pointwise at the truth
  `θ₀`, `n⁻¹P*(θ₀) →ᵖ 0` — i.e. the penalty is `oₚ(n)`.
- **√n-consistency and asymptotic normality — the "softness" rate (Thm 5.2, condition N4).** Writing
  `P*(θ) = cₙP(θ)` with `P` fixed, nonpositive, rotation-invariant and continuously differentiable, the
  scaling factor must satisfy `cₙ = oₚ(√n)`, i.e. the **penalty overall must be `oₚ(√n)`, not merely
  `oₚ(n)`** — a strictly stronger rate than the existence condition alone requires. For the classical
  Akaike (1987) / Hirose et al. (2011) penalties, written as `P*(θ) = −(ρn/2)tr(·)`, this is achieved
  by decaying `ρ = 2√(2/n³)`, derived from the `√(n/2)` rate at which Fisher information accumulates
  for a variance parameter under independence.

**Does the paper name mixed-model variance components as a next target?** Asked directly of the
ingested text: **no.** Section 9 ("Concluding remarks") names three explicit future directions —
(i) a least-false/misspecified-covariance extension in the spirit of White (1982), (ii) alternative
penalty functions within the same factor-analysis model, (iii) logistic factor analysis / item-response
models, where the same Heywood-type boundary problem recurs for loadings. **It does not mention
multilevel/mixed-model random-effect variances at all** — because, read against the corpus's own
publication history, that direction is not "next", it is *already prior work*: Sterzinger & Kosmidis
2023 is the mixed-model MSPL paper, published three years before the factor-analysis one. The factor-
analysis paper cites it as an existing instance of the same MSPL framework, not as a target.
**Net correction for the transfer packet:** MSPL already exists for one class of mixed-model boundary
problem (singular/near-singular RE covariance matrices, i.e. `pdHess`-failure cases in glmm-style
models), via the 2023 paper — the generalization drmTMB would need is not "MSPL has never touched
variance components" but "MSPL's existing mixed-model treatment targets the *matrix-singularity*
boundary, and the sufficient-condition machinery for a *scalar RE-SD-near-zero* boundary (drmTMB's
D-117/D-139 target) would need to be re-derived from the factor-analysis paper's cleaner (E1)–(E3) +
rate-condition template, since the 2023 paper's own conditions are stated for the logistic-regression
composite penalty specifically, not restated in the general form Theorem 4.1/5.1/5.2 give.**

## 2. Chung, Rabe-Hesketh, Dorie, Gelman & Liu 2013 (the `blme` paper)

Penalty: a **gamma(α, λ)** prior on the group-level SD `σ_θ` (not on the variance, and not
inverse-gamma), giving additive log-penalty `(α−1)log σ_θ − λσ_θ + const`. Default: **α = 2, λ → 0**,
reducing the penalty to `log p(σ_θ) ∝ log σ_θ`.

- **Mode.** For general gamma(α,λ), mode = `(α−1)/λ`. At α=2 this is `1/λ`; but the *recommended*
  default takes `λ → 0`, so the density `p(σ_θ) ∝ σ_θ` is monotone increasing with **no finite mode**
  — the "prior" is used purely as a penalty shape, not as a proper density to summarize.
- **Justification for α=2 specifically (Property 1 in the paper):** under a quadratic approximation of
  the profile log-likelihood, when the ML estimate is exactly at the boundary (`σ̂_θ^ML = 0`), the
  penalized estimate satisfies `σ̂_θ = ŝe(σ̂_θ^ML)·√(α−1)`. Setting α=2 collapses this to **exactly one
  standard error**, giving an LRT statistic of exactly 1.0 — a value the paper explicitly argues is
  statistically indistinguishable from the data supporting zero.
- **Point-bias simulation (balanced varying-intercept, J∈{3,5,10,30}, n∈{5,30}, σ_θ∈{0,1/√3,1}).** At
  J=3, n=5, σ_θ=1/√3 (ICC=0.25): **47% of ML and 45% of REML estimates collapsed to exactly zero**;
  even at J=5, n=30, **5%/4%** still did. MPL (log-gamma(2,0)) had **0% boundary estimates** across all
  conditions. When σ_θ>0, ML/REML are severely downward-biased; MPL(2,0) is downward-biased but much
  less so; MPL(3,0) is the largest estimator, tending to *over*estimate, with smallest bias only at the
  largest true σ_θ=1. RMSE of both MPL variants is consistently smaller than ML/REML when σ_θ>0,
  because REML's own sampling variance is extreme at small J.
- **Interval coverage.** ML systematically under-covers (boundary collapse silently zeroes the
  group-level contribution to fixed-effect SEs); REML under-covers too, especially at small J. MPL
  substantially repairs this — but **α=2 (best for point bias) is not the best for coverage**: **α=3
  gave the coverage closest to nominal 95%** when σ_θ>0. Width cost at σ_θ=1/√3: **+20% at J=5, +8% at
  J=10, +2% at J=30** (n=5) — a genuine but bounded cost. At the true-null case σ_θ=0, **all penalized
  estimators over-cover** (paper's own words: *"For σ_θ = 0, all the methods except ML tend to have
  higher than nominal coverage"*), and at σ_θ=0 with small J the width penalty is much larger:
  **+60% at J=3, +30% at J=5** under log-gamma(3,0).

**Follow-up coverage study.** Chung, Gelman, Rabe-Hesketh, Liu & Dorie 2015 (*J. Educational and
Behavioral Statistics*, "Weakly Informative Prior for Point Estimation of Covariance Matrices in
Hierarchical Models") extends the same log-gamma-as-penalty logic to full covariance matrices via
Wishart priors, reporting (per the ingested abstract-level content, **flag: NotebookLM ingested the
SAGE abstract page, not the full article — treat depth-of-detail claims from this source as
UNVERIFIED beyond the abstract**) that the resulting fixed-effect uncertainty is less underestimated
than under ML/REML, consistent with the 2013 mechanism.

## 3. Conditional-on-boundary coverage under penalized estimators

The corpus is explicit and directly load-bearing for drmTMB's own D-117 framing: **penalizing does
not "fix" coverage so much as relocate the failure mode.** Three points, all corpus-grounded:

1. **The boundary is a genuine coverage problem for ML/REML, not a flag artifact.** Accepting the
   ML boundary estimate `σ̂=0` collapses the group-level error prediction entirely, which understates
   fixed-effect SEs and produces real (not merely cosmetic) under-coverage — this is the 2013 paper's
   central empirical claim, independent of any framing about "conditional-on-boundary" summaries.
2. **The trade is bias direction, not a free repair.** When the true `σ_θ=0`, the very design of a
   penalty that keeps estimates positive **forces** an upward-biased estimate, which inflates the
   estimated fixed-effect SEs and produces measured **over-coverage** at the null. The 2013 paper
   states this explicitly rather than leaving it implicit. This is the same shape of result Fisher's
   in-package probe (§0 of the sibling verdict note in this packet) found for the shipped `D(t)`
   penalty: it "relabels more than it repairs" near the anchor.
3. **Best point-estimator ≠ best interval-coverage penalty strength.** The 2013 paper's own tuning
   split (α=2 optimal for bias/RMSE, α=3 optimal for coverage) is itself evidence that a single penalty
   calibrated for one target (point recovery) is not automatically well-calibrated for a different
   target (interval coverage) — the two objectives pull the shape parameter in different directions
   even within one well-studied penalty family.

I did not find, in this corpus or in the wider search that fed it, a paper reporting **profile-
likelihood** interval coverage under a penalized variance estimator specifically (the 2013/2015 studies
are Wald-type CIs on fixed effects, not profile CIs on the variance component itself). This is a gap:
**UNVERIFIED / not found** whether anyone has measured profile-CI coverage on the penalized variance
parameter directly, as opposed to Wald coverage on downstream fixed effects.

## 4. Priors-as-penalties in practice; frequentist package landscape

**Gelman 2006** argues against inverse-gamma(ε,ε) priors on variance parameters: as ε→0 the posterior
becomes improper and, more practically, the posterior near `σ=0` becomes acutely sensitive to the
arbitrary choice of ε, because the marginal likelihood stays finite and positive as `σ→0` (the data can
never fully rule out zero variance). The proposed alternative, the **half-Cauchy** on the SD scale, has
a flat positive density at zero (no artificial dead-zone that forces the estimate away from a true
zero) and a heavy right tail that lets the likelihood dominate when the variance is genuinely large; a
parameter-expansion trick (`α_j = ξη_j`) makes it conditionally conjugate for Gibbs sampling. Practical
adoption: **brms and rstanarm both ship half-Cauchy/Student-t-family weakly-informative defaults for
group-level SDs**, per general documentation knowledge — this specific claim was not re-verified inside
the notebook corpus (the corpus contains Gelman 2006 itself but not brms/rstanarm documentation) and
should be treated as **UNVERIFIED-in-this-sweep** even though it is uncontroversial in the applied
literature.

**`blme` adoption.** The CRAN citation page confirms `blme` as the direct software realization of the
2013 log-gamma penalty, wrapping `lme4`'s `lmer`/`glmer` (`bglmer`/`blmer`). Sterzinger & Kosmidis 2023
independently stress-tested `blme`'s default penalty and found a real limitation directly relevant to
drmTMB: the log-gamma-type penalty **guards the lower boundary but not the upper one** — in their
separation simulations, both plain ML and `bglmer` returned variance-component estimates with absolute
value **>800** under a data-separation regime, because the default penalty was never designed to
counteract divergence to `+∞`. This is a documented failure mode of the "prior-as-penalty" approach
when the boundary problem is separation-driven rather than shrinkage-to-zero-driven, and is directly
analogous to a possible drmTMB failure mode if a boundary-avoiding penalty is added without also
bounding the upper tail.

**Frequentist packages offering a boundary-avoiding penalty as a documented feature.** Searched both
inside the notebook corpus and via direct web search (`glmmTMB`, `GLMMadaptive`, `spaMM`): **no
evidence found, either way, inside this corpus** — the sources here compare only `lme4`/`glmer`,
`blme`/`bglmer`, `brglm2`, Stata's `gllamm`, and the MSPL papers' own routines. A direct web search
(outside the notebook) surfaced no documented boundary-avoiding-penalty feature in `glmmTMB`,
`GLMMadaptive`, or `spaMM`'s reference manuals; **flag as UNVERIFIED-negative** (absence of evidence,
not confirmed absence — I did not exhaustively read all three packages' full manuals). One genuinely
new and directly relevant hit from the wider search, **not previously in the drmTMB team's evidence
base as far as I can tell**: **Košuta, Langerholc & Blagus, 2026, *Biometrics* 82(1), "Non-boundary
covariance matrix estimation in generalized linear mixed effects models using data augmentation
priors."** This is closer to a frequentist-facing boundary-avoiding penalty than anything else found:
inverse-Wishart-derived penalties on RE covariance matrices, implemented via **pseudo-observations**
that let the penalty be applied inside existing ML/REML software by augmenting the data — i.e., no
custom optimizer needed. **Read via WebFetch abstract/results summary only (paywalled; NOT
NotebookLM-grounded; UNVERIFIED beyond what the abstract/results section states):** reports (i) ML/REML
frequently boundary (esp. with high correlations, small variances), their penalized-ML method (PML)
and a Bayesian MAP variant both consistently avoid the boundary; (ii) PML beats ML/REML on a
PRIAL-type loss metric across settings, close to an oracle shrinkage target; (iii) **95% Wald CI
coverage was close to nominal for PML and ML/REML, but the Bayesian MAP variant over-covered** in
linear/binomial models and showed mixed over/under-coverage by regime in the Poisson model; (iv) bias
and RMSE improve with more clusters and larger cluster size, performance "reasonable" even at 25
clusters. This paper is 2026 and evidently unknown to the rest of the MSPL transfer packet — worth a
follow-up read of the actual PDF (not just the WebFetch summary) before citing it as evidence rather
than a lead.

## 5. Known criticisms — testing, model selection, heritability

Asked per-source, with explicit silence flagged rather than inferred:

- **Testing σ=0 / LRT.** The 2013 paper pre-empts this criticism directly: because their default
  penalty shifts the MPL estimate away from a true zero by at most one SE (LRT statistic ≈1.0, far
  below the ≥3.48 99th-percentile threshold of the non-standard `0.5χ²₀+0.5χ²₁` null distribution even
  at J=5), they argue the shift is "statistically insignificant" and does not itself manufacture a
  significant random effect. Sterzinger & Kosmidis 2023 separately criticize `bglmer`'s default penalty
  for the opposite failure — not guarding the *upper* boundary (§4 above) — with consequences for Wald
  tests, which they say become "substantially impacted, resulting in spuriously strong or weak
  conclusions" under boundary conditions generally.
- **Model selection (AIC/BIC).** Only the **factor-analysis** paper addresses this directly, and its
  finding is a genuine warning shot for any drmTMB implementation: **naive (non-decaying) penalties
  actively break AIC/BIC-based model selection** — in their simulations, non-decaying versions of the
  Akaike (1987) / Hirose et al. (2011) penalties introduce enough finite-sample shrinkage bias that
  AIC/BIC "completely fail to select the correct number of factors," essentially never recovering the
  true model. The MSPL scaling (`cₙ = oₚ(√n)`) is specifically what restores correct AIC/BIC behavior
  in their simulations. **This is the strongest single piece of evidence in this sweep that penalty
  *rate*, not just penalty *shape*, is what protects downstream inference — a softness condition is not
  cosmetic.** Chung et al. 2013/2015 and Gelman 2006 are silent on AIC/BIC-style selection.
- **Heritability / repeatability (animal-breeding variance partitioning).** **No source in this
  corpus, and none surfaced by the wider search feeding it, discusses penalized/MSPL-style variance-
  component estimators in the context of heritability, repeatability, or animal-model variance
  decomposition.** This is a genuine gap, not a negative result — general REML/heritability literature
  (Heredity 2022, "Evaluation of alternative methods for estimating the precision of REML-based
  estimates of variance components and heritability," and related animal-breeding sources found in the
  wider sweep) documents that **classical REML asymptotic CIs for heritability are known to be biased
  and can spread outside `[0,1]`, especially at low/high heritability and small sample sizes** — the
  same small-sample regime where a boundary-avoiding penalty would bite — but none of these sources
  discuss what a log-gamma/Huber/MSPL-type penalty would do to a heritability point estimate or its
  interval. **Flag: UNVERIFIED / no direct literature link found** connecting the MSPL line to
  heritability estimation specifically. Given that heritability is a ratio of variance components
  (`Vₐ/Vₚ`), a penalty that biases the numerator variance component upward at small g (as documented
  above for the 2013 estimator) would mechanically bias heritability upward too whenever the true
  additive variance is near zero — but this inference is **AGENT-INFERRED**, not sourced, and should be
  treated as a hypothesis for drmTMB's own simulation to test, not a citable claim.

---

## UNVERIFIED ledger

| Claim | Status | Why |
|---|---|---|
| Diaconis–Ylvisaker 2026 paper is a variance-component-boundary generalization of MSPL | **CORRECTED, not just unverified** | Full text read: it is a high-dimensional logistic-regression (separation) paper, `p/n→κ`, no random effects. |
| Chung et al. 2015 (Wishart covariance-matrix penalty) coverage/bias numbers beyond the abstract | UNVERIFIED beyond abstract | NotebookLM ingested only the SAGE abstract page; full-text PDF not in corpus. |
| brms/rstanarm ship half-Cauchy/Student-t defaults for group-level SDs | UNVERIFIED-in-this-sweep | Not re-checked against current brms/rstanarm docs inside this task; stated from general knowledge only. |
| glmmTMB / GLMMadaptive / spaMM have no documented boundary-avoiding penalty for variance components | UNVERIFIED-negative | Absence of evidence from a non-exhaustive search of manuals/docs, not a confirmed absence. |
| Košuta, Langerholc & Blagus 2026 (*Biometrics* 82(1)) full methodology, simulation grid, and real-data example | UNVERIFIED beyond WebFetch abstract/results summary | Paper is paywalled; not ingested into NotebookLM; read only via a small-model summarization of the OUP abstract page, not the primary PDF. |
| Penalizing variance components upward-biases heritability estimates at small g | **AGENT-INFERRED** | Mechanical inference from the 2013 paper's own upward-bias-at-null finding, applied to a variance ratio; no heritability-specific source found. |
| No profile-likelihood-CI-coverage study of a penalized variance component exists | UNVERIFIED / negative search result | Not found in this corpus or the wider search; could exist outside what a bounded sweep covers. |

## What this means for drmTMB

The corpus supports treating the factor-analysis paper's Theorem 4.1/5.1/5.2 template — not the 2023
mixed-logistic paper's composite penalty — as the right formal scaffold for a drmTMB scalar RE-SD
penalty, because it is stated in the general boundary/rate form drmTMB would need to re-derive anyway;
the 2023 paper is prior art for matrix-singularity boundaries, a different failure mode from the
scalar-SD-near-zero target in D-117/D-139. Two corpus-grounded cautions bound how far that template can
be trusted without new work: `blme`'s default penalty is a documented one-sided guard (it stops
collapse to zero but not divergence to `+∞`, exactly the direction Fisher's own probe in this packet
flags as understudied for the shipped `D(t)`), and a penalty tuned for point-estimate bias is not
automatically well-tuned for interval coverage — the 2013 paper needed a different shape parameter
(α=3 vs α=2) for each target, so a drmTMB penalty calibrated against point-recovery evidence should not
be assumed calibrated for coverage without its own coverage simulation. The factor-analysis paper's
AIC/BIC finding is the sharpest transferable warning: an *undecayed* penalty does not merely shift
point estimates, it can silently break downstream model-selection machinery, so any drmTMB penalty
should ship with the `oₚ(√n)`-type decay condition from the start rather than as a later correction.
Finally, the corpus contains no heritability/repeatability-specific evidence at all — that connection
remains open, and if drmTMB's boundary work is meant to serve Shinichi's own quantitative-genetics
audience, a dedicated small simulation on a variance-ratio target (not just the raw SD) is the way to
close that gap rather than relying on literature that does not yet exist.

> Related: `docs/dev-log/research/2026-08-16-drmtmb-mspl-transfer-packet.md` ·
> `docs/dev-log/research/2026-08-16-mspl-transfer-fisher-verdict.md` ·
> `docs/dev-log/research/2026-08-16-mspl-transfer-gauss-engineering.md` ·
> `docs/dev-log/research/2026-08-16-mspl-transfer-noether-math.md`
