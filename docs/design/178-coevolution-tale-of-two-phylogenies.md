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

- **Stage 0 (validate what exists). DONE 2026-06-20 -- see the Stage-0 evidence
  subsection in the Addendum below.** A recovery simulation for
  `phylo_interaction()`: simulate from `sigma^2_{[ph]} (A^(p) (x) A^(h))`, fit, and
  recover the coevolutionary SD + fixed effects (smoke -> pilot -> 500-rep ->
  Curie+Fisher), mirroring the relmat/random-slope recovery slices. This was the
  bounded, do-it-now step; it banks the headline term as recovery-validated (a HELD
  diagnostic -- no granular coevolution matrix row exists to promote).
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

## Addendum (verified 2026-06-20) — correcting the gap and the identifiability framing

Maintainer review corrected two claims above; both verified against the code:

1. **Terms 3 & 4 are NOT "missing grammar."** Every term reuses `phylo()` /
   `phylo_interaction()`; there are no new primitives. Eq. 4 makes term 3
   (`sigma^2_{p[h]} delta_{k,l} a^(h)_{i,j}` = `I^(p) (x) A^(h)`) exactly a
   `phylo_interaction(1 | host:parasite, tree1 = host_tree, tree2 = star)` where the
   parasite "tree" is a star phylogeny (so `A^(p) = I`); term 4 is the host star.
   The host/parasite main effects are `phylo(1 | host)` / `phylo(1 | parasite)`, and
   the coevolutionary term is the full two-tree `phylo_interaction()`. The earlier
   "missing grammar" rows in the table are withdrawn.

2. **The real blocker is a conservative R-level gate, and its reason is the
   larger-N identifiability concern -- not a fundamental limitation.** Fitting the
   additive model `y ~ x + phylo(1 | host, tree=ht) + phylo(1 | parasite, tree=pt) +
   phylo_interaction(1 | host:parasite, tree1=ht, tree2=pt)` (n_h=n_p=25, 1250 obs)
   parses but errors at fit time:
   `"Only one phylogenetic structured effect is implemented in mu"`
   (`R/drmTMB.R:7547`; the sibling guard at `R/drmTMB.R:2634` reads "Only one
   structured effect type is implemented per univariate Gaussian model ... **Fit one
   structured layer at a time until multiple structured layers have their own
   identifiability checks.**"). So the multi-component model is gated *pending
   identifiability validation*, which is precisely the maintainer's "we just need
   larger N, to be honest about" point.

3. **Identifiability reframed (honest, not a hold).** The phylo-SD diagnostic
   (`docs/dev-log/simulation-artifacts/2026-06-20-phylo-sd-recovery/`) is not a
   weak-identifiability *defect*; it *quantifies the N requirement* for a
   phylogenetic variance component: rel bias -32% at 60 species, -9% at 120, -4.8%
   at 240 -- a consistent estimator that needs adequate species counts. The honest
   statement for users is "phylogenetic variance components need many species; with
   few species they are downward-biased," not "this does not work."

### Revised plan to actually fit Hadfield (2014)

- **Stage 1 (engine extension -- bigger than a guard flip).** Verified: it is NOT
  just a guard. `extract_gaussian_mu_phylo_term` (`R/drmTMB.R:7534-7549`) aborts on
  more than one phylo term AND extracts a *single* structured term; the downstream
  TMB data construction is built around one structured precision per dpar. So
  admitting the additive model requires extending the assembly to COLLECT all
  structured terms, build each one's precision, and SUM their contributions (each
  with its own variance component) -- R assembly work and very likely a C++ change
  in `src/drmTMB.cpp` to loop over multiple structured RE blocks. This is a
  Gauss-level engine task, not a one-line guard relaxation. Start with the
  3-component additive model (host main + parasite main + coevolution). The
  single-term slices (`phylo()` alone, `phylo_interaction()` alone) already work, so
  the per-block machinery exists; the new work is the multi-block sum.
- **Stage 2 (identifiability + recovery at adequate N).** A recovery sim for the
  3-component model across a host/parasite species ladder (e.g. n in {30, 60, 120}
  each), reporting the N at which each component's bias is acceptable -- the
  transparent "larger N" contract. Curie+Fisher verify; promote scoped to the N
  range where recovery holds.
- **Stage 3.** Add the evolutionary-interaction terms via star-tree
  `phylo_interaction()` (terms 3, 4); confirm the 5-component model is identifiable
  at adequate N.
- **Stage 4.** ICC / `coev_components()` accessor (aligned with DRM.jl#188), then
  Bernoulli incidence + spatial replication (eq. 7-8).

The single-term slices (`phylo_interaction()` alone; `phylo()` alone) already work
today; only the *simultaneous* multi-component fit is gated.

### Stage 0 evidence (2026-06-20) — coevolutionary term recovery validated (HELD diagnostic)

The headline coevolutionary term, fit ALONE, recovers honestly. Artifact:
`docs/dev-log/simulation-artifacts/2026-06-20-coevolution-phylo-interaction-recovery/`
(self-contained `run.R`, 500 reps/cell, `master_seed = 20260620`).

- **Model:** `bf(y ~ x + phylo_interaction(1 | host:parasite, tree1 = host_tree,
  tree2 = parasite_tree), sigma ~ 1)`, Gaussian. DGP draws the coevolutionary effect
  from `N(0, sd_coev^2 * (A_parasite (x) A_host))`, `A = cov2cor(vcv(rcoal_tree))`,
  `sd_coev = 0.7`, `b0 = 0.3`, `b1 = 0.5`, `sigma = 0.4`, `n_each = 4` obs/pair,
  species ladder `n_host = n_parasite in {6, 10, 14}`.
- **Result (0 fit errors, pdHess 1.000 across 1500 fits):** coevolutionary SD rel
  bias **-6.4% / -2.5% / -1.6%** at n_sp 6/10/14 -- a consistent estimator (the
  downward bias shrinks monotonically with species count). Slope rel bias <= 0.2%
  (Wald 0.940-0.962); residual sigma essentially unbiased. The intercept is
  near-unbiased in the mean but high-variance with under-nominal Wald coverage at
  few species (0.906 / 0.922 / 0.930) -- the grand-mean / phylogenetic-field
  confounding, approaching nominal as species grow.
- **Verification:** numerical correctness checked at code level (the DGP's
  `kronecker(A_p, A_h)` with host-fastest `expand.grid` matches the model's
  `kronecker(precision2, precision1)` with `observation_node_index =
  (node2-1)*n1 + node1`; the augmented `S^-1` tip-marginal equals
  `sd^2 * (A_p (x) A_h)`, so `sd_coev` maps 1:1 to the reported SD) plus an
  independent 30-rep re-run reproducing the pattern. Inference/scope reviewed
  (Fisher, ENDORSE-AS-HELD): scoped to POINT recovery + fixed-effect Wald only;
  coevolutionary-SD interval calibration NOT claimed; no controlled comparison with
  the single-tree phylo-SD diagnostic (different replication and total N).
- **Disposition:** HELD diagnostic, no cell promoted. There is no granular
  coevolution / `phylo_interaction` row in the capability matrix, and the aggregate
  "Structural dependencies" row cannot be flipped by one sub-type. This is the
  honest single-component baseline under any Stage-1 additive claim: the
  coevolutionary component works alone, so the Stage-1 multi-block engine extension
  builds on validated ground, and the "needs adequate N" contract is now quantified
  for the interaction term (mild bias, shrinking, even at modest species counts --
  far milder than the single-tree phylo main effect, which needs many more species).

## Stage 1 implementation plan (verified change-map, 2026-06-20)

A read-only scoping pass mapped the single-structured-term dataflow from the R
parser through the TMB data list into `src/drmTMB.cpp`, to turn "do the engine
surgery" into a precise, TDD-first plan. The load-bearing claims were checked
against the worktree.

### The real engine boundary (verified)

The current kernel's per-term loop is **over endpoints (dpars) that share ONE
precision and ONE node space**, not over distinct structured blocks. In
`src/drmTMB.cpp`: `int n_phylo = Q_phylo.rows()` (`:731`), `q_phylo =
log_sd_phylo.size()` (`:732`, the number of mu/sigma endpoints), and the eta loop
uses `effect_index = k * n_phylo + phylo_mu_node_index(i)` (`:737`) with a single
`Q_phylo` and a single `phylo_mu_node_index`. The penalty loop (`:792-817`) reuses
the same single `Q_phylo` / `log_det_Q_phylo`. The Hadfield blocks have *different*
node-space sizes (host `n_h`-augmented, parasite `n_p`-augmented, interaction
`~n_h*n_p`-augmented), so they cannot share one `n_phylo` or one
`phylo_mu_node_index`. This is why Stage 1 is genuine engine surgery, not a guard
flip. The per-term *builders* (`drm_phylo_augmented_precision`,
`build_phylo_mu_structure`, `build_phylo_interaction_mu_structure`) are already pure
and re-callable; the new work is collecting K of them and summing their
contributions.

### Verdict: decompose into three ordered sub-slices

Stage 1 is NOT a single defended slice. Decompose so each ends green:

- **Slice 1A — multi-block engine on the Gaussian `mu` path.** Sum K phylo /
  phylo_interaction blocks in eta and in the GMRF penalty. The bulk of the work.
  Testable by an assembly unit test + a penalty/eta consistency assertion before
  any reporting work.
- **Slice 1B — post-fit extraction & reporting.** `split_tmb_random_effects`,
  `split_tmb_sdpars`, `transform_gaussian_random_effects`, profile targets, so
  `fit$sdpars$mu` returns the K named SDs the acceptance test reads. This is where
  silent errors hide (aliasing, SD-name collision); it gets its own tests.
- **Slice 1C — activate the acceptance recovery test** (`test-coevolution-additive-gate.R:57`)
  at adequate N on a species ladder, and flip the gate-lock guard (`:34`).

Count models (Poisson/nbinom2) inherit Slice 1A through `make_tmb_data` + the shared
kernel but are out of scope for the Stage-1 acceptance test (Gaussian only) and stay
gated until their own recovery slice.

### Recommended architecture (lowest-risk)

**Block-diagonal precision + one concatenated `u_phylo` + length-K flat
`log_sd_phylo`, with per-block metadata for SD scaling and log-det bookkeeping.**
Do NOT attempt a `vector<SparseMatrix>` multi-block C++ loop (TMB has no native
type for it). Build `Q_phylo <- Matrix::bdiag(per-block precisions)` in R;
`uᵀ Q_phylo u` then decomposes exactly into the per-block sum with zero cross-block
coupling by construction, keeping the kernel's single sparse mat-vec (and trivially
correct autodiff). The kernel still loops over blocks for the per-block SD scaling
and the per-block normalizing constant, so it needs new `DATA_IVECTOR
phylo_block_start`, `DATA_IVECTOR phylo_block_n`, `DATA_VECTOR
log_det_Q_phylo_blocks`, and a per-block observation->node index — but no new matrix
type and no hand-written per-block Cholesky.

### Ordered change list (file:line)

1. **Gates (relax):** `R/drmTMB.R:7545-7550` (`extract_gaussian_mu_phylo_term`
   abort) -> return a *list* of phylo terms; siblings
   `:8215-8225/:8291-8301/:8342-8352/:8391-8401` and `single_entry_structured_term`
   (`:7860-7873`). `:2632-2638` active-structured gate -> for Stage 1 allow multiple
   phylo/phylo_interaction terms while keeping mixed-type (phylo+spatial) gated.
2. **Fan-out:** `R/drmTMB.R:2650-2654` (singular `structured_term` selection) ->
   keep all active terms; `:2961` -> `lapply(terms, build_structured_mu_structure)`
   producing a `phylo_mu_blocks` list. Do not change the builders.
3. **Block-diagonal assembler** in the `make_tmb_data` Gaussian region
   (`R/drmTMB.R:14503-14524`): `bdiag` of per-block precisions; per-observation
   per-block node index rebased by `cumsum(n_re)`; sum/collect per-block log-dets;
   emit `phylo_block_start` / `phylo_block_n`.
4. **Parameters (R start + map):** concatenate `u_phylo <- rep(0, sum(q_k*n_re_k))`
   and `log_sd_phylo <- c(per-block SDs)` (length K for the q=1-per-block Hadfield
   case); `gaussian_ls_map` `log_sd_phylo` length becomes K
   (`R/drmTMB.R:12544/:13718/:14113`).
5. **C++ kernel** (`src/drmTMB.cpp`): new per-block DATA near `:161-169`; replace
   the flat `k*n_phylo` arithmetic in eta (`:735-749`) and penalty (`:791-817`) with
   `phylo_block_start(b) + within-block index`, per-block `log_det_Q_phylo_blocks(b)`
   and `log_sd_phylo(b)`.
6. **Extraction (Slice 1B):** `split_tmb_random_effects` (`:16182`), `split_tmb_sdpars`
   (`:15837`), `transform_gaussian_random_effects` (`:16189`), `drm_profile_targets`
   (`R/profile.R:1240-1250`) -> loop blocks; give each block a distinct SD namespace
   (two bare `phylo` terms would both label `phylo:(Intercept)` and alias).

### Identifiability / N caveats to carry forward

- Phylo variance components are consistent but downward-biased at small N (single-tree
  phylo-SD: -32% @60 species -> -4.8% @240). The Stage-0 coevolution evidence shows
  the *interaction* term is milder (-6.4% @6 -> -1.6% @14 per tree, with `n_each=4`).
  The acceptance test must use a species ladder with tolerances that widen at small N,
  not a single tight bound.
- Main-vs-interaction separability: `J(x)A` (main) and `A(x)A` (coevolution) are
  distinct but correlated; with few species the host-main and coevolution SDs trade
  off. Report the *joint* bias of all three components, coevolution SD as headline.
- Keep the augmented `S^-1` parameterization the builders already use
  (`drm_phylo_augmented_precision`); do not switch to `A^-1`. Flag the interaction
  block size `~(2n_h-1)(2n_p-1)` for memory/runtime. Keep `n_rep >= 2`.

### TDD steps and silent-failure guards

- **Step 0 (red):** un-`skip` `test-coevolution-additive-gate.R:57` and write the
  body; it fails at the gate (`R/drmTMB.R:7547`) -- the Stage-1 entry condition.
- **Assembly guard (anti-aliasing):** the 3-term `bf()` yields a `phylo_mu_blocks`
  list of length 3 with the right `n_re`, and `bdiag` of the three precisions has all
  off-block entries zero.
- **Penalty correctness:** with fixed `log_sd_phylo` and a known `u_phylo`, the C++
  `quadratic` REPORT equals the hand-computed `Σ_b u_bᵀ Q_b u_b / sd_b²` -- catches
  double-counting and the scale-by-1/sd placement.
- **Eta correctness (block-aliasing):** fitting each block alone reproduces the
  additive eta at matched parameters (no cross-block leakage).
- **SD naming:** `names(fit$sdpars$mu)` are three *distinct* labels and
  `length(...) == 3` -- guards the bare-`phylo` collision and a stale length-1 `map`
  that would silently fix two SDs equal.
- **Recovery (1C):** the activated acceptance test on the species ladder.

This is Gauss-level work; do it TDD-first with Noether checking the Kronecker /
block-diagonal math and Curie+Fisher gating the recovery.
