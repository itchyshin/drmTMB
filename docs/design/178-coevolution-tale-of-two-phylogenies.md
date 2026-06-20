# Coevolution of interacting traits: implementing Hadfield et al. (2014)

**Status:** design note (plan before code). No likelihood or grammar change yet.
**Reader:** drmTMB method developers and the DRM.jl coevolution team.
**Source:** Hadfield, J. D., Krasnov, B. R., Poulin, R. & Nakagawa, S. (2014).
"A Tale of Two Phylogenies: Comparative Analyses of Ecological Interactions."
*The American Naturalist* 183(2):174-187. DOI 10.1086/674445.

## Purpose

The maintainer asked us to revisit coevolution-of-interaction models in drmTMB and
implement the Hadfield et al. (2014) "double phylogeny" GLMM. drmTMB already has the
headline term (`phylo_interaction()`, the coevolutionary Kronecker effect) for a
narrow slice; this note maps the *full* paper to drmTMB's grammar, states honestly
what is implemented vs missing, and proposes a staged, evidence-gated plan. It is
the design gate that must precede any TMB/grammar change (AGENTS.md design rules 2-5).

## The model (Hadfield et al. 2014, eq. 3-6)

The response is a property `y_ik` of the interaction between host `i` and parasite
`k` (incidence, abundance, a trait of the interaction). Conditioning on a linear
predictor, the covariance of the latent interaction outcomes (eq. 3) decomposes
into up to FIVE phylogenetic variance components, each a Kronecker product of the
host and parasite phylogenetic correlation matrices `A^(h)`, `A^(p)` with `J`
(all-ones) and `I` (identity):

```text
W^(a) = sigma^2_{l[h]} (J^(p) (x) A^(h))   # 1. host main effect    (phylo variation in parasite species richness, PSR)
      + sigma^2_{l[p]} (A^(p) (x) J^(h))   # 2. parasite main effect (phylo variation in host range, HR)
      + sigma^2_{p[h]} (I^(p) (x) A^(h))   # 3. host evolutionary interaction
      + sigma^2_{p[p]} (A^(p) (x) I^(h))   # 4. parasite evolutionary interaction
      + sigma^2_{[ph]} (A^(p) (x) A^(h))   # 5. COEVOLUTIONARY interaction (headline)
```

`(x)` is the Kronecker product. Eq. 5 adds non-phylogenetic analogues
(`sigma^2_h (J (x) I)`, `sigma^2_p (I (x) J)`, `sigma^2_ph (I (x) I)` = non-phylo
PSR, HR, specificity). Eq. 4/6 give the implied covariance between two interacting
pairs `(i,k)` and `(j,l)` as the sum of these terms with the appropriate `A`
entries and Kronecker deltas. Results are reported as intraclass correlations
(ICCs), not raw variances, because the relative sizes are the biology.

Interpretation (paper, fig. 1):
- term 1: related hosts have similar-sized parasite assemblages;
- term 2: related parasites have similar host ranges;
- term 3: related hosts share parasite *assemblages* irrespective of parasite phylogeny;
- term 4: related parasites share host *assemblages* irrespective of host phylogeny;
- term 5: **related parasites live on related hosts** -- coevolution.

Practical notes from the paper: fit on the `S^-1` (phylogenetic precision with
ancestral nodes) parameterization, not `A^-1` (sparser, ~4x larger but ~1.7 GB ->
5.5 MB on their data); region/spatial replication enters via a design matrix `Z`
mapping observations to host-parasite combinations (eq. 7) or a direct sum over
regions (eq. 8); for incidence (Bernoulli) data `sigma^2_ph` (non-phylo
specificity) is not identifiable without replicate matrices; ICCs on the latent
scale use the `pi^2/3` logit-link variance (Nakagawa & Schielzeth 2010).

## drmTMB grammar mapping

| Paper term | Kronecker | drmTMB grammar | Status |
| --- | --- | --- | --- |
| 5. coevolutionary interaction | `A^(p) (x) A^(h)` | `phylo_interaction(1 \| h:p, tree1, tree2)` | **Implemented** (q=1 mu; Gaussian, Poisson, NB2) -- builds the sparse Kronecker precision from both trees |
| 1. host main effect | `J^(p) (x) A^(h)` | `phylo(1 \| h, tree = host_tree)` | Implemented as a standalone phylo RE; not yet *simultaneous* with the interaction |
| 2. parasite main effect | `A^(p) (x) J^(h)` | `phylo(1 \| p, tree = parasite_tree)` | As above |
| 3. host evolutionary interaction | `I^(p) (x) A^(h)` | (no grammar) host phylo effect that varies by parasite identity | **Missing** |
| 4. parasite evolutionary interaction | `A^(p) (x) I^(h)` | (no grammar) parasite phylo effect varying by host identity | **Missing** |
| non-phylo analogues (eq. 5) | `J (x) I`, `I (x) J`, `I (x) I` | `(1 \| h)`, `(1 \| p)`, `(1 \| h:p)` ordinary REs | Ordinary REs implemented; not co-fitted with the phylo terms |
| ICC / variance-component report | -- | `summary()` / a new `coev_components()` accessor | **Missing** (the paper's primary output) |

The bipartite vignette (`vignettes/bipartite-phylogenetic-interactions.Rmd`)
already frames `phylo_interaction()` as "A tale of two phylogenies" and explicitly
flags the additive model (`phylo(1|h) + phylo(1|p) + phylo_interaction(...)`) as
**Planned**.

## Honest gap

1. **Simultaneous additive model.** The paper's value is the *joint* decomposition
   (main effects + interactions in one fit, then ICCs). drmTMB fits the
   coevolutionary term alone, or main effects alone, but the joint multi-component
   fit is not validated (identifiability of `J(x)A` main vs `A(x)A` interaction,
   and the `S^-1` vs `A^-1` parameterization choice, are open).
2. **Evolutionary interaction terms (3, 4).** `I^(p)(x)A^(h)` and `A^(p)(x)I^(h)`
   have no grammar. These are the host-side / parasite-side evolutionary
   interactions (related hosts share assemblages irrespective of parasite phylogeny).
3. **ICC / variance-component reporting.** The paper reports ICCs (relative
   variances). drmTMB reports per-term SDs (`fit$sdpars$mu`) but has no
   coevolution ICC accessor.
4. **Distribution scope.** Implemented for q=1 mu, Gaussian/Poisson/NB2. The
   paper's case study is Bernoulli incidence + the spatial-replication design
   (eq. 7-8) and abundance.

## Staged, evidence-gated plan

- **Stage 0 (validate what exists).** A recovery simulation for
  `phylo_interaction()`: simulate from `sigma^2_{[ph]} (A^(p) (x) A^(h))`, fit, and
  recover the coevolutionary SD + fixed effects (smoke -> pilot -> 500-rep ->
  Curie+Fisher), mirroring the relmat/random-slope recovery slices. This is the
  bounded, do-it-now step; it banks the headline term as recovery-validated.
- **Stage 1.** The simultaneous additive model `phylo(1|h, tree1) +
  phylo(1|p, tree2) + phylo_interaction(1|h:p, tree1, tree2)`: identifiability
  diagnostics (can the three components be separated?), then a 3-component recovery
  sim. Decide `S^-1` (ancestral-node precision) vs `A^-1` per the paper.
- **Stage 2.** The two evolutionary-interaction terms (`I(x)A`, `A(x)I`): new
  grammar (e.g. `phylo_by(host_tree | parasite)`-style sugar over a Kronecker
  precision), then recovery.
- **Stage 3.** A `coev_components()` accessor returning the five variance
  components + latent-scale ICCs (with `pi^2/3` for logit; Nakagawa-Schielzeth),
  with provenance/`conf.status` columns matching the project's interval contract.
- **Stage 4.** Bernoulli incidence + the spatial/region replication design
  (eq. 7-8); abundance; then bivariate-trait coevolution links (the q4 PLSM /
  DRM.jl#186 `Sigma_a` cross-trait correlations).

## Connections (do not duplicate effort)

- **Kernel abstraction (DRM.jl#270; gllvm direction).** `A^(h)`, `A^(p)` are fixed
  phylogenetic correlation matrices; the gllvm team is moving to a kernel/sparse-GP
  abstraction (NNGP/Matern) as the scalable replacement for fixed relatedness. A
  kernelized double-phylogeny would replace `A` with a kernel `K(theta)` whose
  hyperparameters are estimated -- a natural generalization of terms 1-5. Jason's
  landscape scout (in flight) is mapping the kernel API; fold its result here
  before committing to the Stage-2 grammar.
- **DRM.jl coevolution epic.** #186 (bivariate phylo coevolution, q4 PLSM), #188
  (Sigma_a cross-trait correlation accessors + CIs), #189 (coevolution from a
  spatial kernel / known relmat). The ICC accessor (Stage 3) should align with the
  #188 `rho_a(.)` reporting so the R and Julia sides report coevolution the same way.
- **Existing drmTMB surfaces.** `phylo_interaction()` (parser, TMB, methods,
  profile, bridge), `phylo()`, `relmat()` (low-level Kronecker escape hatch:
  `relmat(1 | h_p, Q = Q_pair)`), and the `bipartite-phylogenetic-interactions`
  vignette.

## Boundary

This is a design note only. No grammar, likelihood, or family change is made here.
Each stage ships with its own recovery/identifiability evidence and Curie+Fisher
(and Noether for the Kronecker math) verification before any status promotion. The
"Structural dependencies" matrix row (the home for these structured terms) stays
partial until the staged evidence lands.
