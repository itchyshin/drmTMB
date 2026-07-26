# For the drmTMB lane — a gap in the Cox-Reid justification, and a rate you can now cite (2026-07-22)

**Status: UNCOMMITTED, written by an out-of-lane session.** Nothing else in this repo was touched. Commit
it, move it, or delete it — it is a message, not a change. Written while `claude/handover-freshness-0718`
was live with 58 dirty files; deliberately not staged so it cannot entangle that work.

**Provenance.** Built from a curated literature corpus (13 hand-verified primaries) assembled today for
Shinichi's Learning Library, after he supplied four paywalled papers via institutional access. Every claim
below is cited to a primary that was **content-verified** (character counts checked; one scanned
cover-page-only decoy caught and replaced). Still machine-extracted — see "verify before use".

---

## 1. The one that matters: drmTMB's Cox-Reid REML justification has a gap

drmTMB shipped an **AGHQ + Cox-Reid REML** estimator on 2026-07-19 for small-cluster non-Gaussian
variance-component bias. The question asked of the literature was simple: **does Cox & Reid (1987)
establish that their modified profile likelihood recovers or generalises REML for variance components?**

**Answer: they assert it. They do not derive it.**

Cox & Reid 1987 §3.3, discussing orthogonality of β and ψ under a multivariate normal with covariance
V(ψ), states plainly:

> *"this generalisation includes, in particular, components of variance models (Patterson and Thompson,
> 1971)."*

§4.1 cites Patterson & Thompson again, among "a long chain of work on conditional and marginal
inference." Asked directly whether either passage is a worked derivation: **it is not.** No equations in
the 1987 paper show their conditional likelihood reducing to Patterson-Thompson's REML equations.

**What this means concretely.** The Cox-Reid modified profile likelihood is
ℓ_CR(ψ) = ℓ_p(ψ) − ½log|j_λλ(ψ, λ̂_ψ)|, valid **only when ψ is orthogonal to the nuisance parameter λ**
(i_ψλ = 0). Reid & Fraser (2003), written by the original co-author, states this formula and the
orthogonality precondition — and, asked directly, does **not** claim ℓ_CR recovers Patterson-Thompson REML
either.

So: the original authors place REML for variance components as **one instance** of their general
orthogonal-parameter framework. That is a strong signal and probably correct. But if drmTMB's estimator
documentation, NEWS, or a method paper states or implies that Cox-Reid *is* REML for variance components,
**that step is drmTMB's own contribution, or draws on later literature — it is not citable to Cox & Reid
1987 directly.**

**Two further caveats from the primaries, both worth knowing:**

- **ℓ_CR is NOT invariant to reparametrisation of λ** — not even to reparametrisations that preserve
  orthogonality (Reid & Fraser 2003, stated as an explicit drawback). If drmTMB reparametrises nuisance
  covariance parameters internally (log-Cholesky, log-SD, etc.), the modified profile likelihood is not
  guaranteed to be the same object across those parametrisations. Worth checking against what the
  estimator actually computes.
- **REML's own asymptotics are conditional, not automatic** (Jiang 1996, Annals of Statistics): REML
  variance-component estimates are **consistent** if the model is asymptotically identifiable and
  infinitely informative under the location-invariant class, and **additionally asymptotically normal**
  only if the model is also asymptotically nondegenerate. Neither requires normality nor bounded rank of
  X. These are the conditions to cite for REML's general guarantees — Patterson & Thompson 1971 does not
  supply them (it is the founding balanced/unbalanced block-design derivation, nothing more).

**Suggested action:** locate wherever the Cox-Reid estimator's theoretical basis is stated, and make the
citation chain honest — Cox & Reid for the framework and the orthogonality condition, Patterson & Thompson
/ Harville for REML itself, Jiang for the asymptotic conditions, and drmTMB's own derivation for the link,
if one exists. If no such derivation exists, that is worth knowing before a method paper claims it.

---

## 2. The AGHQ error rate is now citable in quantified form

Previously the corpus supported only a qualitative statement ("more nodes help where Laplace is weakest").
Liu & Pierce (1994, *Biometrika* 81(3):624–629, "A note on Gauss-Hermite quadrature"), read in full, give
the rate explicitly:

> For an **m-node** Gauss-Hermite quadrature, transformed and centred at the mode, the asymptotic error is
> **O(n^−⌊m/3 + 1⌋)**, where n scales the exponentiated function being integrated.

**At m = 1 this recovers Laplace's known O(n⁻¹) exactly.** So "AGHQ is a higher-order Laplace
approximation" is now a *formal, quantified* statement, not an analogy: Laplace is the m = 1 member of the
family.

Usable wherever drmTMB documentation or a method paper needs to justify *why* additional quadrature nodes
help and *by how much*.

**Also citable now:** Patterson & Thompson's own restricted log-likelihood, §4 eq. (13):
L′ = const − ½Σ log ξₛ − ½(n−t) log σ² − R/(2σ²), with ξₛ (s = 1,…,n−t) the nonzero latent roots of HS
(H = V/σ²), and R = Σ(u²ₛ/ξₛ) = y′(SHS)⁻ᵍy (eq. 14, S = I − X(X′X)⁻¹X′). Same error-contrast idea Harville
(1977) later generalised — so a claim previously resting on Harville's secondary treatment can now cite the
primary directly.

---

## 3. What the literature does NOT supply

- **Non-standard asymptotics for a correlation parameter at ±1.** Self & Liang (1987) and Stram & Lee
  (1994) give the chi-bar-square machinery for a **variance component at zero** — for the Laird-Ware model,
  testing one variance component gives a 50:50 mixture of χ²₀ and χ²₁; adding a random slope to an existing
  intercept gives 50:50 χ²₁ and χ²₂; adding k correlated effects to q existing ones spans df kq to (k+1)q.
  Comparing a naive LRT to a standard χ² with df = number of added parameters is **asymptotically
  conservative**. But Stram & Lee's positive-semidefinite constraint is discussed **only via the variances**,
  never the correlation hitting its own boundary. Asked twice, independently: **confirmed absent.** If
  drmTMB needs boundary inference for a correlation, that is a derivation, not a citation.
- **Cox & Reid 1987 → REML equivalence**, as above.

---

## 4. Verify before load-bearing use

All quotes and equations were machine-extracted from born-digital text-layer PDFs (confirmed not scanned,
so OCR risk is low) — but still machine-extracted. Before any of this enters a manuscript or a derivation:

- **Liu & Pierce's exponent** O(n^−⌊m/3+1⌋) — check the floor-function argument against their equation
  (m/3 + 1, not (m+1)/3). Transcription of exponent expressions is the exact failure class this exercise
  has repeatedly caught.
- **Patterson & Thompson eq. (13)/(14)** — check subscripts and the generalized-inverse notation.
- **Reid & Fraser's ℓ_CR** — check symbol placement of j_λλ and the orthogonality condition.
- The Cox & Reid §3.3 quotation is short and verbatim; the §4.1 mention is a citation in a list.

Source PDFs are with Shinichi (fetched via UAlberta library today).

---

## 5. If you want more

The corpus is a registered NotebookLM notebook (`ada0a323-14a2-48c0-81d0-33feac988cd9`, "Learning Library
#4b — REML, quadrature and boundary asymptotics"), 13 curated sources, no auto-research. Ranga can be sent
back at it with a narrower question. The full distillate lives in the vault at
`memory/ENGINEERING-NOTEBOOK.md` § "Learning Library drip #4b" (round 1 + round-2 addendum).
