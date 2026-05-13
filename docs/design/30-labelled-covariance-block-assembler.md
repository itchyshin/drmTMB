# Labelled Covariance Block Assembler

This note defines slice 4 of the double-hierarchical covariance roadmap. The
reader is the package contributor who has to replace the current pairwise
bridges with one positive-definite block representation without changing the
public formula grammar.

## Purpose

The current code can fit several useful two-term covariance slices: ordinary
`mu` intercept-slope blocks, univariate `mu`/`sigma` random-intercept blocks,
bivariate `mu1`/`mu2` and `sigma1`/`sigma2` random-intercept blocks, and one
same-response bivariate `mu`/`sigma` random-intercept block. Those are correct
as disjoint pairwise bridges.

They are not the right abstraction once a shared label spans three or more
random-effect coefficients. A model such as:

```r
drm_formula(
  mu1 = y1 ~ x + (1 + x | p | id),
  mu2 = y2 ~ x + (1 | p | id),
  sigma1 = ~ z + (1 | p | id),
  rho12 = ~ x
)
```

does not ask for a sequence of unrelated bivariate conditionals. The label
`p` asks for one group-level covariance block for `id`, with members drawn
from the labelled random-effect terms. Slice 4 should therefore build a
labelled block assembler before adding bivariate random slopes or claiming the
full double-hierarchical endpoint.

## Scope

The first assembler should stay inside the existing `drmTMB` boundary:

- one-response and two-response models only;
- ordinary grouped random effects first, not `phylo()`, `spatial()`, or
  residual `rho12`;
- Gaussian likelihoods first;
- no formula grammar change beyond the existing `(terms | label | group)`
  syntax;
- no predictor-dependent group-level correlations.

Residual `rho12` remains a row-level residual correlation. The labelled block
contains group-level effects such as mean intercepts, mean slopes, residual
scale intercepts, and residual scale slopes.

## Block Registry

The R side should first create a registry of labelled block members. A block is
defined by the tuple:

```text
level = "group"
group = grouping variable, for example id
block = covariance label, for example p
```

Each member records:

```text
block_id
dpar            # mu, sigma, mu1, mu2, sigma1, or sigma2
response        # NA, 1, or 2
coef            # (Intercept), x, z, ...
term_index      # existing random-effect term index
coef_index      # existing coefficient index within that term
group_index     # 0-based group index vector used by TMB
design_value    # random-effect design value for each observation
```

The assembler should reject a shared label when members do not share the same
grouping factor or when the requested distributional-parameter combination is
outside the current slice. The rejection should tell the user which labelled
block was too large or unsupported, and what smaller model to try next.

## TMB Contract

For each assembled block `b` with `q_b` members and `G_b` groups, TMB should
work with standardized random effects:

```text
z_bj ~ Normal(0, I_q)
r_bj = diag(sd_b) L_corr_b z_bj
```

where `L_corr_b L_corr_b'` is a valid correlation matrix. The negative
log-likelihood contribution is the standard-normal density for `z_bj`; the
transformed effects `r_bj` enter the `mu`, `sigma`, `mu1`, `mu2`, `sigma1`,
or `sigma2` linear predictors.

Local TMB 1.9.21 exposes `UNSTRUCTURED_CORR_t` and `VECSCALE_t` for an
unstructured correlation density with scaled standard deviations. The first
TMB algebra probe confirms that a q=3 `UNSTRUCTURED_CORR_t` object reports a
positive-definite correlation matrix and can be evaluated through `VECSCALE_t`.
The follow-up probe confirms that `VECSCALE(UNSTRUCTURED_CORR(theta), s)` can
map standardized q=3 latent vectors through `sqrt_cov_scale()`. The production
likelihood slice should reuse that non-centered contract while pulling vectors
from the labelled covariance-block registry. A hidden registry-shaped probe now
checks that block/member metadata can map group-level transformed vectors back
to design-scaled member contributions. If the helper is unsuitable for the full
registry path, the fallback should still use one positive-definite
Cholesky-style parameterization for the whole block, not separate unconstrained
pairwise `tanh()` correlations.

The flattened data contract should be block-oriented rather than pair-oriented:

```text
n_re_cov_blocks
re_cov_block_size[B]
re_cov_block_group_count[B]
re_cov_block_member_start[B]
re_cov_block_pair_start[B]
re_cov_member_component[M]
re_cov_member_dpar[M]
re_cov_member_response[M]
re_cov_member_source_term[M]
re_cov_member_coef_pos[M]
re_cov_member_latent_index[n, M]
re_cov_member_design_value[n, M]
re_cov_pair_from_member[P]
re_cov_pair_to_member[P]
re_cov_pair_parameter[P]
re_cov_pair_parameter_index[P]
```

The dormant TMB export contract is intentionally limited to currently
implemented two-member blocks. The internal registry scaffold can now generate
all `q * (q - 1) / 2` pair rows for a guarded three-member block, but
`labelled_covariance_block_tmb_data()` still blocks `q > 2` export until a
positive-definite likelihood parameterization exists. Names can change during
implementation, but the invariant should not: the likelihood sees one block,
its members, its standard deviations, its correlation parameters, and its
standardized random effects.

## Pair Reporting

`corpairs()` should report pairs derived from the fitted block. It should not
store a separate likelihood object for each pair.

For a block with `q` members, there are `q * (q - 1) / 2` reportable pairs.
Each row should keep the existing long-table fields:

```text
level, group, block, from_dpar, to_dpar, from_coef, to_coef,
from_response, to_response, class, estimate, link_estimate
```

Classes such as `mean-mean`, `scale-scale`, `mean-scale`, `mean-slope`, and
`slope-scale` are interpretation aids. The formal columns must be sufficient
for users to identify the pair even when no short class name is available.

## Scale Convention

The public distributional parameter remains `sigma`, and the fitted linear
predictor remains `log(sigma)`. When documentation compares to papers that
report `log(sigma^2)` or individual residual variance, it must state the
conversion:

```text
effect on log(sigma^2) = 2 * effect on log(sigma)
```

Derived summaries may report `sigma^2` or IGV when the scientific target is
variance, predictability, or malleability. The fitted package parameter should
still be named `sigma`.

## Implementation Order

1. Build the R-side block registry without changing accepted syntax. Done for
   currently implemented ordinary grouped two-member covariance bridges.
2. Keep all current pairwise bridges green by translating the existing
   two-member cases through the registry. Done as metadata-only compatibility;
   the TMB likelihood still uses the existing pairwise fields.
3. Add the TMB block data contract and a two-member compatibility path. Done
   as dormant two-member-only `random$covariance_blocks$tmb_data`; the
   likelihood still uses the existing pairwise fields.
4. Update `corpairs()`, `profile_targets()`, and `check_drm()` to derive rows
   and diagnostics from block members. `corpairs()` now uses registry pairs for
   covered two-member blocks and falls back to legacy label parsing for any
   uncovered fitted `corpars` rows. `check_drm()` now derives the covered
   two-member covariance diagnostics from registry members while preserving the
   existing row names and messages. `profile_targets()` now derives covered
   random-effect correlation targets from registry pairs while preserving
   target names, indices, and readiness.
5. Pass the two-member dormant contract through the C++ boundary as a no-op
   visibility check before using it for likelihood evaluation. Done by
   appending empty or registry block data to every TMB data list, declaring
   the `re_cov_*` fields in C++, and checking that scrambling those fields
   leaves the objective and gradient unchanged.
6. Add one guarded three-member scaffold before exposing a four-formula
   bivariate block. Done for internal registry pair enumeration: a q=3 block
   can carry three members and all three pair rows while marked
   `implemented = FALSE`, and TMB export still aborts for `q > 2`.
7. Prototype `UNSTRUCTURED_CORR_t` plus scaled standard deviations or an
   equivalent positive-definite Cholesky path for `q > 2`. Done for hidden TMB
   probes that report a positive-definite q=3 correlation matrix, finite
   objective/gradient under `VECSCALE_t`, and the non-centered
   `sqrt_cov_scale()` latent transform. Also done for a hidden
   registry-shaped member/group contribution probe; the production likelihood
   still needs real q=3 random-effect parameters and likelihood wiring.
8. Only then enable bivariate random slopes or the full shared
   `mu1`/`mu2`/`sigma1`/`sigma2` label pattern.

## Diagnostics

The assembler should make weak identification visible before users interpret
mean-scale or slope-scale correlations. `check_drm()` should warn when:

- the number of groups is small for the block dimension;
- many groups have little within-group replication;
- one fitted component SD is close to zero;
- the fitted Hessian or standard errors suggest a correlation is weakly
  identified.

Simulation tests should use enough groups and repeated observations for the
target. Tiny toy fits are useful for parser tests, but they are not persuasive
recovery evidence for dispersion random effects or slope-scale correlations.

## Non-Goals

Slice 4 does not implement phylogenetic, spatial, or residual-correlation
blocks. It creates the ordinary grouped block abstraction those later layers
can reuse. Structured covariance work must still report phylogenetic,
non-phylogenetic species or individual, and residual `rho12` correlations as
separate layers.
