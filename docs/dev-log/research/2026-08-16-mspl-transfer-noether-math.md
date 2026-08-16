# MSPL transfer to RE-SD/correlation boundaries — mathematical consistency review (Noether)

**2026-08-16 · Noether (math-consistency lens) · input to
`2026-08-16-drmtmb-mspl-transfer-packet.md` · written by the orchestrator from Noether's returned
content (the `math_consistency_reviewer` agent type carries no Write tool).**

**Verdict: mathematically plausible but not clean.** Biggest risk: a single shared softness
constant `c_n` (calibrated to fixed-effect information growth ~n) applied to a variance-component
penalty whose true information-growth rate is governed by the number of groups `g << n` can
silently violate the softness condition the consistency argument depends on, exactly in the
small-`g` regime this generalisation targets.

## 0. What already exists

`estimator = "mspl"` already carries a variance-component boundary penalty, for the q1/q2
binomial-logit random block only:

- `drm_mspl_negative_huber(x)` = negative Huber loss D(t) = -t²/2 for |t|≤1, D(t) = -|t|+1/2 for
  |t|>1 — `src/drmTMB.cpp:77-85`.
- Applied to Cholesky log-SD/off-diagonal coordinates: `D(log_sd_mu(0))` for q1;
  `D(a1) + D(a2 + log sech z) + D(e^{a2} tanh z)` for q2 — `src/drmTMB.cpp:5022-5042`, matching
  `docs/design/250-mspl-binomial-logit-alignment.md:181-215`.
- Combined with the fixed-effect Jeffreys term under one softness constant:
  `mspl_log_objective_bonus = mspl_c_n * (mspl_jeffreys + mspl_variance_negative_huber)`;
  `nll += -mspl_log_objective_bonus` — `src/drmTMB.cpp:5043-5046`.
- Source: Sterzinger & Kosmidis 2023, *Stat. Comput.* 33:53, eq. (4)-(5), Sec. 7 for
  c_n = 2√(p/n) — `docs/design/250:25-30`, coded in `R/mspl.R:112-128`.

So this is extending an already-implemented mechanism past q2, past one grouping factor, past
binomial `link_code`, and into Laplace-marginalised non-binomial families with no separation
event, only an RE-SD/correlation boundary.

## 1. Parameterisation growth condition

Condition: with $a = \log(\mathrm{sd})$, a soft penalty $P(a)$ prevents collapse to $a \to -\infty$
iff $\liminf P(a)/(-a) = c > 0$ as $a \to -\infty$. Equivalently the induced density on sd has a
polynomial zero $p(\mathrm{sd}) \sim \mathrm{sd}^{c-1}$ near 0.

- Repo Huber term (`src/drmTMB.cpp:77-85`): **c = 1** (satisfies the condition, correct order).
- Chung et al. 2013 Gamma(shape k=2, rate λ) on sd (cited `R/penalty.R:40-42`):
  $-\log p(a) = -k a + \lambda e^{a} + \text{const}$ → **c = 2**.
- Repo's `drm_phylo_penalty_value` (`src/drmTMB.cpp:87-125`, line 105:
  `pen += lam * sd_k - log_sd_phylo(k) - log(lam)`) is the log-scale change-of-variables of an
  Exponential(λ)/PC prior (`R/penalty.R:9-16`): **c = 1**, same order as the MSPL Huber term, but
  *not* Chung's recommended k=2.
- **Jeffreys prior for a variance component (p(sd) ∝ 1/sd) is flat on the log scale: c = 0. It
  does NOT repel the boundary** — using a Jeffreys-style prior for the variance component by
  analogy with the fixed-effect Jeffreys term is a category error; the two need structurally
  different penalty families.

## 2. Separation vs. RE-SD boundary — not the same event

Separation: β→∞ on the natural scale, driven by Fisher information for β becoming singular
(|I(β)|→0); `mspl_jeffreys` (`src/drmTMB.cpp:5015-5016`) is designed exactly to diverge where
information collapses.

RE-SD boundary: sd→0 is a finite point of [0,∞); on the fitting scale a=log(sd) this maps to −∞
as a coordinate artefact, not a divergence of the underlying parameter — a nonregular-boundary
problem (Self & Liang-type), not generally an information-singularity event.

Verdict on the Sterzinger existence machinery: same theorem template plausible, but the
sufficient conditions are local-geometry conditions that differ between the two cases and must be
re-verified separately for the RE-SD case; they do not transfer by citing the binomial-separation
verification. This repo's own precedent (`docs/design/252-binomial-link-generalisation.md:184-199`)
shows even a same-mechanism, smaller step (probit/cloglog links) required 460,000 fits of
dedicated evidence before the existence claim extended — a binomial-separation → RE-SD-boundary
transfer is a larger jump.

## 3. Laplace interaction

Two effects, easy to conflate: (1) Laplace approximation *bias*, which is not maximal at sd=0 (at
sd=0 the Laplace step is exact) — pushing sd away from 0 does not straightforwardly improve
validity and may move the fit into the region of worse Laplace bias; (2) inner-optimisation
numerical conditioning, which is a separate and narrower claim. Repo evidence (`AGENTS.md`
2026-07-13 entry: RE-SD downward Laplace bias attributed to finite-n-per-cluster / finite-g, fixed
by AGHQ / Cox-Reid REML respectively, not by sd magnitude) undercuts the "free benefit" framing.
**Verdict: wishful as a general Laplace-validity claim**; a numerical-conditioning claim would
need its own separate evidence, and should not be used to justify strengthening the penalty
beyond the o(n) softness the consistency argument needs.

## 4. Composite penalty

Already implemented additively under one c_n (`docs/design/250:167`; `src/drmTMB.cpp:5043-5046`).
At the penalty level the two terms are functionally separable (P_f(β) depends only on β evaluated
fixed-only, `src/drmTMB.cpp:4964-4966`; P_v(ψ) only on covariance coordinates), so no
penalty-level cross-Hessian interaction — any β–ψ coupling comes from the shared likelihood, not
the penalty.

**Named condition/risk: c_n = 2√(p/n_eff) (`R/mspl.R:112-128`) is calibrated to the fixed-effect
information rate (~n_eff). Variance-component information typically grows at the rate of the
number of groups g, not n. A single c_n = o(n) does not imply o(g), and g << n is exactly the
regime this generalisation targets** (mc-0596-class small-g cells). This is the single sharpest
mathematical risk in the transfer.

## 5. TMB implementation surface

Location: the penalty must live in the C++ objective, added to `nll` as a function of fixed
(non-random) TMB parameters only, on the same tape TMB differentiates for the outer optimisation —
not an R-side outer wrapper (`docs/design/250:170-177`; `src/drmTMB.cpp:4963-5051`). A generalised
RE-SD penalty for non-binomial Laplace-marginal families belongs in the same place by the same
algebraic argument.

REML: currently a hard reject for both `penalty` (`R/drmTMB.R:372-378`) and MSPL
(`R/mspl-estimator.R:212-214`), with the stated reason that REML and a penalty are different
estimators of the variance components (`tests/testthat/test-reml-penalty-guard.R:1-3`). This
generalises to a concrete concern: REML's marginal-likelihood criterion has a different effective
sample size than the ordinary-likelihood n_eff that c_n is built from, so the softness condition
needs re-derivation against REML's own curvature/effective count, not an assumed transfer. No
such re-derivation exists in this repo or in the cited literature summary; **the current hard
reject is the mathematically defensible stance, not a gap to relax.**

## Files reviewed

`R/mspl-estimator.R`, `R/mspl.R`, `R/penalty.R`, `R/drmTMB.R:365-378`, `src/drmTMB.cpp` (lines
40-125, 340-350, 4963-5054), `docs/design/250-mspl-binomial-logit-alignment.md`,
`docs/design/252-binomial-link-generalisation.md`, `tests/testthat/test-reml-penalty-guard.R`.
