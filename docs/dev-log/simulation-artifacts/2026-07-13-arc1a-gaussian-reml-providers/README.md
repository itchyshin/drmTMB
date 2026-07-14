# Arc 1a exact-Gaussian REML provider campaign

This directory contains the retained Arc 1a recovery and profile-coverage
evidence for the pure-`mu`, univariate Gaussian `spatial()`, `animal()`, and
`relmat()` REML routes. The campaign evaluates both admitted shapes: an
unlabelled random intercept and an unlabelled independent intercept plus one
numeric random slope. It does not evaluate labelled or multiple slopes,
matched `mu` plus `sigma` blocks, bivariate or non-Gaussian REML, estimated
spatial range, fixed-effect REML profiles, or broad provider support.

## Frozen design

- Source: clean commit `1a0854401f7646a849dad2497dfc8a9e6761d2fb`.
- Host: Totoro, 90 workers, with OpenBLAS, OMP, MKL, and TMB threads pinned to
  one per worker.
- Cells: spatial and relmat at `M = {8, 16, 32}`; animal at the fixed `M = 8`
  pedigree; each crossed with the intercept and one-slope shapes (14 cells).
- Observations: `n_each = 20` and the same fixed
  `seq(-1, 1, length.out = 20)` design for the fixed and random slopes.
- Truth: `beta = (0.4, 0.25)`, residual `sigma = 0.5`, intercept structured
  SD scale `s0 = 0.5`, and slope structured SD scale `s_x = 0.38` (stored in
  the campaign's historical `tau0` and `tau_x` columns).
- Effects: uncentred independent Gaussian fields generated as `s * L_K * z`,
  giving latent-field covariance `s^2 K`. Node `i` has marginal SD
  `s * sqrt(K[i, i])`, which equals `s` only when that diagonal entry is one.
- Campaign representations: spatial coordinates, the animal `A` matrix, and
  the relmat `K` matrix. The `A`/`Ainv`/pedigree and `K`/`Q` equivalence claims
  come from one deterministic representation-parity fixture each, not from the
  multi-seed campaign or broad large/sparse-matrix validation.
- Seeds: `set.seed(20260714)` followed by 19,600 unique draws from
  `sample.int(.Machine$integer.max, 19600, replace = FALSE)`. Recovery uses
  indices 1--5,600 and profile coverage uses 5,601--19,600 in stable
  cell-major, replicate-minor order.

Recovery used 400 datasets per cell, pairing ML and REML on each dataset:
11,200 fits and 16,800 retained fit-target rows. Coverage used 1,000 independent
datasets per cell: 14,000 REML fits and 21,000 strict endpoint-profile targets.
All attempted datasets remain in the primary denominators.

## Frozen results and D-43 decision

All 11,200 recovery fits converged and had finite target estimates and
gradients. Of these, 11,199 had `pdHess = TRUE`, including all 5,600 REML fits;
one spatial `M = 8` one-slope ML fit had `pdHess = FALSE`. Every one of the 14
cell-level and 21 target-level
admission rows passed the approved gates. Across providers, the worst absolute
signed median errors were 0.048 for `beta0`, 0.023 for `beta_x`, 0.0084 on the
relative residual-sigma scale, and 0.0915 on the relative structured-scale
scale. The highest structured near-boundary rate was 0.0475, below the 0.05
gate.

All 14,000 coverage fits converged and all 21,000 target profiles were valid,
two-sided, finite endpoint-profile intervals. Cell-target coverage ranged from
0.932 to 0.960; the largest Monte Carlo standard error was 0.00796. All 21
targets passed the discrete small-`M` floor after adding two MCSEs, with a
minimum margin of 0.0124. Exact binomial intervals and lower/upper misses are in
`profile-summary.tsv`.

The miss tails are asymmetric and must remain a caveat. The most pronounced
cell is the animal one-slope target at `M = 8`, with 8 lower and 59 upper
misses. These results support neither nominal-exact coverage nor extrapolation
beyond the tested finite domains.

Fresh default-NOT-DONE reviews by Noether, Fisher, and Pat support all three
provider cells at no higher than `inference_ready_with_caveats`. Noether's
decisive review used the final admission guard at commit `384a526d`, which also
rejects ordinary sigma random effects for every Arc 1a provider. The reviewers
withhold `supported` and require the discrete domains, structured-SD
interpretation, miss asymmetry, boundary-truncated slope profiles, and
deterministic-only representation parity above to remain in every claim.

## Commands

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 \
R_PROFILE_USER=/dev/null ARC1A_CHECKPOINT_SIZE=360 \
Rscript --no-init-file tools/run-arc1a-gaussian-reml-provider-campaign.R \
  --phase=recovery --output-dir="$HOME/drmtmb_arc1a_results/full-1a085440" \
  --n-rep=400 --ncores=90 --overwrite=true

OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 \
R_PROFILE_USER=/dev/null ARC1A_CHECKPOINT_SIZE=360 \
Rscript --no-init-file tools/run-arc1a-gaussian-reml-provider-campaign.R \
  --phase=profile --output-dir="$HOME/drmtmb_arc1a_results/full-1a085440" \
  --n-rep=1000 --ncores=90 --overwrite=true
```

The two `*-artifact-hashes.tsv` files provide read-back hashes for the raw,
manifest, and summary artifacts. `session-info.txt` records the live R/TMB
toolchain. The raw TSVs are authoritative; the standalone summarizer can
reconstruct every summary:

```sh
Rscript --no-init-file tools/summarize-arc1a-gaussian-reml-provider-campaign.R \
  --phase=recovery --output-dir=PATH
Rscript --no-init-file tools/summarize-arc1a-gaussian-reml-provider-campaign.R \
  --phase=profile --output-dir=PATH
```
