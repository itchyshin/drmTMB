# Finite-universe contract for random-effect SD regression

## Scope freeze and current boundary

The approved denominator is every mathematically well-formed family-specific
parameter endpoint crossed with each frozen latent primitive/provider/block
mechanism. It includes missing base plumbing, excludes new response families
and responses beyond bivariate, uses one provider at a time plus only existing
simultaneous-provider/layout mechanisms, and treats general q as a mechanism
template rather than enumerating an unbounded predictor count. A true
structural-inapplicability label is reserved for a nonexistent endpoint or a
mathematical-review exclusion.

I have not expanded the 703 native capability-ledger `model_surface` rows into
SD rows: the ledger is an evidence index, not the approved denominator. Its
marginals cannot be crossed to manufacture family × endpoint × block rows.
The pinned constructor/spec enumeration now appears in
[family-endpoints.tsv](family-endpoints.tsv): 20 family routes and 54 declared
endpoint rows. It is the endpoint side of the universe only; latent mechanism
templates now appear in [mechanism-templates.tsv](mechanism-templates.tsv): 28
finite templates from ordinary, structured, provider-combination, and temporal
source labels. The animal mechanism set now distinguishes independent q1
fields, same-endpoint correlated intercept-slope q2 blocks, and labelled
cross-endpoint blocks. The generated [required-rows.tsv](required-rows.tsv) is
now a finite 20,350-row required-candidate ledger. Its current breakdown is
5,600 non-block rows, 8,000 source-shaped or fallback block rows, and 6,750
broader endpoint-subset candidate rows. An earlier revision expanded the
19,342-row snapshot by 336 animal plus coordinate-spatial obligations for
pedigree, A covariance, and A-inverse precision inputs. The native Binomial
logit slice fits the phylo-tree plus relmat K-covariance/Q-precision
intercept pair, and the animal plus coordinate-spatial pair with pedigree,
A-covariance, and A-inverse precision inputs.
The other rows remain obligations and do not imply admission. The ledger also
includes 1,440 native rows mirroring Julia's finite tagged-q4 partitions.
The new 672 rows encode a single-endpoint animal q2 mechanism across the
declared endpoints, provider inputs, links, and engines; they do not claim
those cells are all implemented. These are candidate obligations, not 20,350
independent implementation tasks
or a claim that each row has an admitted or identifiable base model. Earlier
denominator snapshots and their correction receipts remain historical.

Binomial also needs a link dimension. The pinned native family admits logit,
probit, and cloglog; the pinned Julia `Binomial()` constructor is logit-only.
[family-links.tsv](family-links.tsv) distinguishes 42 admitted engine-link rows
from two union obligations for Julia probit/cloglog, whose base links are
blocked. The earlier link-only expansion added 122 rows: 18
retain the existing structural cross-endpoint exclusion and 104 remain
`blocked_base_plumbing` for missing Julia link admission. Those rows remain in scope and expand to `blocked_base_plumbing` unless
the exact cell is structurally inapplicable. The table keeps SD evidence
separate from base-link admission.

Pins used here are drmTMB `d89db50975d96d9c2bcb13046453ae34c7fcf49b` and DRM.jl
`b1832c7a686decf4e3d7a06ad8382bf164b9d8d4`; source was read with `git show`.
The existing [inventory](inventory.md) remains the pinned count and direct-route
receipt. This contract adds the missing row-universe decision; it does not
revise those counts.

## What the source does and does not enumerate

The native formula grammar says the family determines which distributional
parameters exist ([formula grammar, lines 1–4](../../design/01-formula-grammar.md#L1-L4)).
Its family-specific builders and existing capability ledger are therefore
needed to establish endpoint membership. In particular, a non-existent
endpoint (for example, a dispersion parameter on a dispersionless family) is
`inapplicable_endpoint`, while an endpoint/effect combination whose base model
route is absent or refused is `blocked_base_plumbing`; the latter must remain
visible and must not be counted as a direct-SD success or silently dropped.

The Julia registry is intentionally one row per family. Its
`predictor_dpars` field governs which existing dpars may carry predictors on
the Julia route, not which dpars exist, and it does not enumerate random-effect
block shapes ([registry contract, lines 13–35](../../../R/julia-family-registry.R#L13-L35)).
For example, the registry records Gaussian LSS/structured admissions and
family-specific fixed-effect fences at lines 67–97 and 99–159. Those flags do
not establish that each family supports each provider, endpoint, effect type,
or block layout.

The frozen Julia SD source is likewise narrower than a registry-wide
crossproduct: its public contract is univariate Gaussian, with plain `sd(g)`
targeting an iid intercept and `sd(group, phylogenetic)` targeting a phylogenetic
SD; it also documents combining iid and phylogenetic components (DRM.jl
`src/gaussian_lss.jl` at the pinned snapshot, lines 13–44).
That is positive evidence for those layouts only. It is not evidence that other
Julia family rows or slope/correlated/temporal layouts are structurally
inapplicable.

The pinned formula grammar lists structured markers including `phylo()`,
`spatial()`, `animal()`, `relmat()`, and `phylo_interaction()` but does not
declare them interchangeable ([grammar, lines 112–117](../../design/01-formula-grammar.md#L112-L117)).
It also labels bivariate random-slope syntax as a long-term direction beyond
the current implemented random-intercept surface ([grammar, lines 12–27](../../design/01-formula-grammar.md#L12-L27)).
These must not be collapsed into one generic “structured” or “correlated” row.

## Required row key and status vocabulary

Each expanded row identifies one exact base-model cell and one engine:

`engine × family_route × dimension × endpoint × endpoint_member × link_variant_when_admitted × provider × effect_type × layout × block_shape`

Here `endpoint` is the distributional parameter (`mu`, `sigma`, `mu1`,
`rho12`, etc.); `endpoint_member` identifies a component inside a multivariate
or covariance block when relevant; `provider` is the actual source primitive
(`iid`, `phylo`, `animal`, `relmat`, `spatial`, `phylo_interaction`, temporal
primitive, or a specifically named provider); `effect_type` distinguishes
intercept, slope, structured intercept/slope, and other implemented effects;
`layout` names independent, correlated, crossed, nested, or structured
arrangements; `block_shape` carries q and the member/correlation structure.
Do not use a wildcard or an unqualified `structured` value where the source
distinguishes these cases.

The generated ledger currently uses these four status values:

- `required`: a retained required candidate; this does not establish that the
  exact base route is admitted or the SD target is identifiable;
- `unresolved`: source admission, provider compatibility, or mathematical
  interpretation still needs review;
- `blocked_base_plumbing`: the endpoint exists, but the exact base model cell
  is not implemented/admitted yet; retain it inside the denominator as a
  dependency, not as a direct-SD pass;
- `structural_inapplicable`: currently reserved for 90 cross-endpoint-block
  rows in the single-endpoint `binomial`, `cumulative_logit`, and `poisson`
  routes. Each has `endpoint_members=none`: there is no second declared
  endpoint for that cross-endpoint block. This narrow exclusion does not cover
  within-endpoint covariance, additive q1 fields, or other block mechanisms.

The earlier design labels `structural_reviewed`, `missing`,
`inapplicable_endpoint`, and `inapplicable_math` are not generated status
values. Do not use them as if the current TSV had classified those states.
Direct-SD support remains `none` for every generated row.

Estimator is a row-specific prerequisite, not a global crossproduct. The
direct-SD denominator is ML-first. Preserve estimator-specific prerequisites
and existing constant-SD or direct-SD estimator routes as evidence, but do not
cross every family with Gaussian REML or AI-REML options.

## Remaining G0 review

The mechanical candidate expansion is present, but G0 remains open. The
20,350 rows are not yet a reviewed family × endpoint × provider/input × layout
base-route classification. In particular, the 4,893 `required` rows need
source admission review, and the 6,750 endpoint-subset candidates need
mathematical and identifiability review. Retain uncertain rows as unresolved;
do not promote rows from candidate presence or source-shaped q rules alone.

Keep source-shaped q rules separate from the broader candidate obligations.
Source rules describe mechanisms found in pinned source; candidate rows retain
finite canonical intercept-only endpoint subsets, including special endpoints,
without asserting that every member set is a fitted or identifiable block.
The 1,440 native tagged-q4 mirrors are marked `blocked_base_plumbing`, not
native support. The 90 structural exclusions apply only to cross-endpoint
blocks where the family declares a single endpoint.

Several exact Julia Binomial rows have been verified despite the family-level
probit/cloglog link registry remaining blocked: a tree-backed phylogenetic
numeric slope, and coordinate-spatial intercept and numeric-slope routes. The
generated rows for these link/provider/effect cells are marked `required` with
`base_link_status=admitted`. Their test receipts cover the phylogenetic slope
through the R bridge and both spatial effects in the direct Julia suite.
Other non-logit Julia Binomial ledger rows remain blocked pending row-specific
review. These exceptions do not declare general probit or cloglog support
across Binomial effect types.

The remaining gates are family/engine/provider/input/layout base-route
classification, review of endpoint-subset compatibility and identifiability,
and the later implementation, recovery, and uncertainty-calibration work.
Estimator prerequisites remain family-specific; do not cross a global
estimator list into every family. No fits were used to construct this
contract.
