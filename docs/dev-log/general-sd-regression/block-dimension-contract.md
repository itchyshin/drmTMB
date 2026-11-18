# Covariance-block dimensions and endpoint-member rules

Status: read-only source audit for the G0 row universe. Pins: native drmTMB
`d89db50975d96d9c2bcb13046453ae34c7fcf49b`; Julia DRM.jl
`b1832c7a686decf4e3d7a06ad8382bf164b9d8d4`. A source-admitted base
block is not an admitted direct-SD model, recovery result, or calibrated
interval. This note records source-shaped q rules and the finite candidate
ledger now represented in [required-rows.tsv](required-rows.tsv); it does not
classify every family/endpoint/provider cell or decide whether every candidate
member set is mathematically meaningful.

## Rule for an executable denominator

Represent a block by `engine`, `primitive`, `layout_id`, ordered
`member_dpars`, ordered `member_coefs`, `q_rule`, and `q_value` when finite.
For a generator with arbitrarily many *numeric* slopes, keep one symbolic row
with its integer domain and an explicit `slope_count` parameter. Do not
enumerate infinitely many formulas and do not replace the domain with the
uncheckable text `q-general`. Materialize the finite source examples as
validation anchors (`q_value`) under the same rule. `block_id`/tag partitions
are separate layouts even when their total q is the same. A standalone q1
axis stays a q1 row when arbitrarily many independent terms can be added;
additive term count is an incidence-layout parameter, not a new covariance q.

Use these row fields in the generated TSV:

```
block_rule_id  engine  primitive  layout_id  member_set_rule
coef_rule  q_domain  q_value  partition_rule  base_state  source_pin
```

`member_set_rule` is an ordered endpoint tuple or a formula such as
`(mu1,mu2) × (Intercept,x1,...,xp)`; an actual generator should use machine
tokens such as `mu1,mu2` and `I,x1..xp` rather
than prose. `base_state` is assessed per family route and engine later:
`source_shape` only means this covariance grammar exists. The symbolic row
needs deterministic canonical coefficient names and a test at its smallest
admitted p plus the pinned larger examples. A future implementation cap may
turn a symbolic domain into a finite set, but documentation examples alone do
not establish such a cap.

## Native ordinary block rules

| Rule ID | Ordered members and q domain | Actual source boundary |
| --- | --- | --- |
| `O1` | One ordinary group coefficient `(dpar, coef)`, `q=1`; intercept or one numeric slope. Additive independent terms, crossed/nested incidence, and multiple grouping factors repeat this **q1** primitive. | `R/drmTMB.R:12501–12612` parses; `:15366–15570` builds axes; `:17671–17689` rejects overlapping same-group coefficients. Endpoint admission remains family-specific. |
| `O2-within` | One correlated ordinary `(1+x | g)` member tuple `((dpar,I),(dpar,x))`, `q=2`; optional block label. | Parser `R/drmTMB.R:12545–12612`; `build_random_mu_structure` at `:15432–15570` creates the pair indices/correlation slot. Julia has its own q2 route below. |
| `O-multi-within` | One intercept plus `p>=2` distinct numeric slopes on one dpar: `q=1+p`; one labelled/unlabelled within-term covariance block, conditional on its family builder admitting the term. This is a **symbolic q-domain**, not every family supporting all p. | Parser accepts multiple symbols at `R/drmTMB.R:12567–12612`; `add_large_same_parameter_covariance_blocks` makes all pairs for `term_sizes>2` at `:16143–16188`; TMB generic `UNSTRUCTURED_CORR` for `block_size>2` at `src/drmTMB.cpp:813–890`. The pinned Gaussian examples include q3; no universal upper p cap is encoded there. |
| `O-cross-LS` | Matching one coefficient on `(mu,sigma)` (univariate) or same-response `(mu1,sigma1)` / `(mu2,sigma2)` (bivariate), `q=2`. Intercept or matched slope-only. | `R/drmTMB.R:15599–15705` enforces matching label/group/coef and same-response bivariate pairing. Do **not** generate `(mu1,sigma2)` or `(mu2,sigma1)` from this rule. |
| `O-biv-mean2` | Matching `(mu1,mu2)` coefficient, `q=2`: intercept pair or matched slope-only pair. | `R/drmTMB.R:17090–17280` detects matching labelled endpoints and builds one combined registry; `:16269–16320` registers same-parameter pairs. |
| `O-biv-scale2` | Matching `(sigma1,sigma2)` coefficient, `q=2`: intercept pair or matched slope-only pair where the exact builder admits it. | `R/drmTMB.R:16731–16745`, `:17090–17280`; family/shape gates still apply. |
| `O-biv-mean-m` | Matching labelled intercept-plus-`p`-slope terms in `mu1` and `mu2`, `p>=1`, ordered members `(mu1:I,x1..xp; mu2:I,x1..xp)`, `q=2(1+p)`. q4 (`p=1`) and q6 (`p=2`) are pinned anchors; do not turn this into an arbitrary four-endpoint block. | `R/drmTMB.R:15790–15843` matches source terms; `:15997–16060` creates `2*length(coef_names)` members; `:17090–17280` expands matching endpoint terms. Full block uses generic q>2 TMB path. |
| `O-biv-all4` | Matching four endpoint terms `(mu1,mu2,sigma1,sigma2)` with identical coefficient sets: `q=4` for intercept-only, `q=8` for **one** numeric slope at this native ordinary gate. | `R/drmTMB.R:15708–15789` explicitly accepts only intercept-only or one-slope per endpoint, and `:16062–16141` orders all four member groups. `src/drmTMB.cpp:813–890` evaluates the q>2 block. Do not infer ordinary q12 from the generic TMB matrix. |

`O-biv-mean2` and `O-biv-scale2` may also be two independent labelled q2
blocks in the same model. Record them as two block instances, not one q4 with
four free correlations. The q4 full `O-biv-all4` is a distinct covariance
layout. The `O-biv-mean-m` symbolic rule is not an ordinary all-four series.
No native ordinary covariance rule at this pin has a `nu`, `zi`, `hu`, `zoi`,
`coi`, or `rho12` member; those endpoints may still require standalone q1
base plumbing and SD regression under the approved programme. Absence from
this *block grammar* is not a blanket mathematical non-identifiability claim.

## Native structured and process rules

| Rule ID | Ordered members and q domain | Actual source boundary |
| --- | --- | --- |
| `S1` | One structured endpoint/coef field, `q=1`; tree phylo, pedigree/A/Ainv animal, K/Q relmat, coordinate spatial, mesh spatial, or two-tree `phylo_interaction` remain distinct input/provider rows. Independent structured intercept-plus-slope paths remain two **independent q1 fields** where admitted. The animal-specific correlated exception is recorded separately as `A2-animal-within`. | Structured source gates `R/drmTMB.R:12770–13010`; mesh `:14560–14690` and `src/drmTMB.cpp:1157–1173`; input/route distinctions in `R/formula-markers.R:150–360`. |
| `A2-animal-within` | One animal endpoint with a correlated intercept and one numeric slope, `q=2`; the two coefficient SDs are distinct targets. This is a within-endpoint block and does not use endpoint-member matching. | The native Binomial and Gamma routes and the Julia Binomial route are represented by the animal q2 mechanism in `block-rules.tsv`; the Julia bridge evidence currently covers supplied A covariance. Other family/provider rows remain obligations and must not be inferred from this shape. |
| `S-uni-LS` | Matching structured `(mu,sigma)` **intercepts** form a correlated q2 pair on the branches that carry `eta_cor_phylo`. Matching one-slope terms produce four axes `((mu,I),(mu,x),(sigma,I),(sigma,x))` but the current `covariance_mode="scalar"` is four independent q1 fields, **not** a full q4 covariance block. | `R/drmTMB.R:12985–13055` requires matching coefficient sets/source/label and sets scalar mode; `:13072–13086` defines the one-slope limit. The native C++ q2 cross-dpar covariance branch is `src/drmTMB.cpp:1020–1078`; other axes take scalar priors. |
| `S-biv-mean` | Matching `(mu1,mu2)` intercept or one matched slope-only coefficient `q=2`; matching **labelled** intercept-plus-`p`-slope terms use `q=2(1+p)`, `p>=1` in the native source grammar. q4 and q6 are pinned examples, not proof for every p's numerical health. | `R/drmTMB.R:13878–13978` validates equal coefficient sets and shared labels; `:13960–13982` expands `2*length(coef_names)` members. Provider-specific guards follow at `:13982–14160`. |
| `S-biv-scale2` | Matching labelled `(sigma1,sigma2)` **intercepts**, `q=2`; no slope-series inference from this branch. | `R/drmTMB.R:13604–13717` scale-only branch insists on intercept-only terms and shared source/label. |
| `S-biv-all4` | Matching all four endpoints, shared source and label. Intercepts: one full `q=4` block or two block-diagonal q2 blocks `(mu1,mu2)+(sigma1,sigma2)`. Matching labelled intercept-plus-`p` slopes, `p>=1`: full `q=4(1+p)`; q8 (`p=1`) and q12 (`p=2`) are pinned examples. The block-diagonal slope series is explicitly refused. | `R/drmTMB.R:13737–13862` forms full/block-diagonal modes and says `q=4*n_coef`; `:13788–13801` refuses slope block-diagonal. TMB's structured q>2 covariance uses `drm_qgt2_corr_matrix` at `src/drmTMB.cpp:546–589`. |
| `P-temporal` | One temporal process on `mu`, `q=1`, for each of AR1, OU, homogeneous Toeplitz. The named phylo+OU arrangement is two additive q1 providers, not one q2 cross-covariance block. Native lacks fitted temporal base plumbing at this pin. | Native grammar `docs/design/01-formula-grammar.md:1226–1230` is planned; Julia source for actual temporal shapes is `src/temporal.jl:1–20,53–86,942–1025`. |

For `S-biv-mean` and `S-biv-all4`, the symbolic p-rule is a *source-shape*
rule, not a blanket fitted-family or inferential claim. The named provider
and input rows stay separate: `phylo`, `animal`, `relmat`, and coordinate
`spatial` share some shape constructors but not every admission gate; mesh
remains q1 at this pin. `phylo_interaction` remains q1 and does not inherit
the single-tree q2/q4 grammar.

## Julia rules at the pinned dispatch

| Rule ID | Ordered members and q domain | Actual source boundary |
| --- | --- | --- |
| `J-iid1` | Ordinary `(1|g)` or `(0+x|g)` is one q1 axis; multiple independent q1 axes may be additive. | `src/gaussian_ranef.jl:193–208` classifies these terms; `src/gaussian_lss.jl:531–542,687–745` and `src/gaussian_multi_re_sparse.jl:1–80` handle selected multi-component Gaussian routes. |
| `J-iid2` | One correlated `(1+x|g)` is q2 on one Gaussian mean endpoint. No general multi-slope ordinary q or labelled cross-endpoint family is established. | `src/gaussian_ranef.jl:193–208,768–800`; combination with structured ordinary is refused at `src/gaussian_structured.jl:518–523`. |
| `J-structured1` | One Gaussian structured intercept q1 for phylo, animal, relmat, or coordinate spatial. One structured plus ordinary q1 terms, or two eligible structured q1 providers, are **additive** fields without a free cross-provider covariance. Spatial pairing is refused. | `src/gaussian_structured.jl:196–224,236–260,389–423,486–525`. |
| `J-phylo-slope1` | Gaussian phylogenetic mean intercept and one numeric slope are **two independent q1 fields**, with separate amplitudes and no intercept–slope correlation. | `src/gaussian_structured.jl:309–380` states and evaluates `V = D + sigma_a^2 Z C Z' + sigma_b^2 Z_x C Z_x'`. |
| `J-biv-structured2` | `mu1,mu2` structured intercepts, q2, with matching provider/group/tag. | `src/gaussian_bivariate.jl:597–627,703–724,736–810`. |
| `J-biv-structured4` | Intercepts on `mu1,mu2,sigma1,sigma2`, total q4. All untagged axes form one full block; when every axis is tagged, equality of tags defines a partition of these **four fixed axes** (at most 15 set partitions), with zero cross-tag covariance. This is a finite partition rule, not a q8 slope rule. | `src/gaussian_bivariate.jl:630–674` computes the tag partition and zeroed Cholesky entries; `:675–724` refuses slope markers. The source supports tag partitions algebraically; no claim is made that all 15 have recovery evidence. |
| `J-temporal1` | AR1, OU, or homogeneous Toeplitz temporal mean process q1; the one named phylo+OU partner is additive q1+q1. | `src/temporal.jl:65–86,942–1025`. |

Julia's bivariate Gaussian structured dispatcher has only q2 and q4; its
q4 parser expressly requires intercept markers. Its residual-only bivariate
route has `rho12` but no latent covariance member; `rho12` is not a fifth
random-effect axis (`src/gaussian_bivariate.jl:597–609`). Mixed-family
bivariate dispatch presently rejects random and structured terms
(`src/mixed_family.jl:510–570`), so its endpoint cells are
`blocked_base_plumbing`, not quietly removed. The R-to-Julia bridge can impose
additional fences: do not infer a Julia base fit merely because one Julia
source helper accepts a term.

## Endpoint join and exclusions for the TSV generator

1. Join each rule to the actual family endpoint rows in
   [family-endpoints.tsv](family-endpoints.tsv). A standalone q1 member is
   generated for each declared endpoint **where the primitive is
   mathematically applicable**; a missing random-effect builder stays
   `blocked_base_plumbing`. The generator expands only declared endpoint rows;
   absent endpoints therefore do not appear as generated rows. The older
   design label `inapplicable_endpoint` is not in the current status vocabulary.
   Keep admitted link variants separate.
2. The source-shaped cross-endpoint member tuples are the rules above: `(mu,sigma)` for a
   univariate location-scale pair; `(mu1,mu2)`, `(sigma1,sigma2)`,
   same-response `(mu1,sigma1)` or `(mu2,sigma2)`, full
   `(mu1,mu2,sigma1,sigma2)`, and the explicitly described block-diagonal
   partition. A bivariate family with `nu` also has `nu` as an endpoint, but
   **no source-shaped q-block rule adds `nu` to those tuples**. Likewise
   `rho12` is residual correlation, not a latent fifth member. Separately,
   the approved denominator includes 6,750 finite candidate rows formed from
   size-two-or-larger subsets of each family's actual endpoint set for the
   existing cross-endpoint block/provider mechanisms. These are canonical
   intercept-only obligations with `unresolved_candidate` partitions; they
   retain special endpoints such as `nu`, `zi`, `hu`, `zoi`, `coi`, and `rho12`
   for review. Candidate presence does not establish a source-shaped block,
   an admitted fit, or identifiability.
3. For the native bivariate all-four blocks, use the endpoint/coef order
   asserted by `R/drmTMB.R:16062–16141`. For Julia q4 use the fixed axis order
   in `src/gaussian_bivariate.jl:630–674`. These need not share the same
   allowed partitions. Emit one row per target **member** within a block as
   well as a block-shape record; `sd()` addresses a member, not an undivided
   block.
4. The symbolic q domains describe only the source-shaped ordinary/structured
   coefficient patterns above. They do not license arbitrary slope patterns,
   more than two responses, unrelated provider pairs, node-level mesh SD
   predictors, or new correlation-regression formulas. The broader finite
   intercept-only endpoint-subset candidates are a separate denominator
   obligation, not an extension of these source rules. If a family builder
   refuses a source-shaped row, retain it as `blocked_base_plumbing` where
   justified; do not turn the generic TMB covariance matrix into an admission
   claim.

The generator now records 20,350 rows, including 6,750 endpoint-subset
candidates, 1,440 native counterparts for Julia's finite tagged-q4
partitions, and 672 rows for the animal within-endpoint q2 mechanism. Its 90
`structural_inapplicable` rows are limited to cross-endpoint
blocks in single-endpoint families: `binomial`, `cumulative_logit`, and
`poisson`. They do not exclude within-endpoint covariance or additive q1
fields.

Remaining G0 work is the exact engine/family/endpoint/provider/input/layout
base-route audit and independent mathematical/identifiability review of the
candidate endpoint sets. Row statuses do not prove admission, support,
estimability, or identifiability. G0 remains open; implementation, recovery,
and uncertainty calibration are later gates.

Update 2026-11-01: the generator now records 21,246 rows after adding the
phylo, relmat and spatial within-endpoint q2 templates (896 rows); see the
2026-11-01 follow-up in [universe-contract.md](universe-contract.md). The
counts above are historical.
