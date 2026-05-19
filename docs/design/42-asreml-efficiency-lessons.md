# ASReml Efficiency Lessons For drmTMB

This note records design lessons from inspecting the local ASReml-R archive
`asreml-4.1.0.130-macOS-10.13.2-R4.0.tar.gz`. I inspected package metadata,
the exported API, and installed help topics, especially `ainverse`,
`knownStruc`, and model-constructor documentation. I did not copy proprietary
implementation code; the archive exposes a compiled library, so the useful
lessons here are interface and architecture lessons.

## What ASReml Makes Cheap

ASReml's animal-model strength comes from making the inverse relationship
matrix a first-class object. The public `ainverse()` documentation describes a
sparse triplet `ginv` object with row names, inbreeding coefficients, genetic
group metadata, and a log determinant. The important design point for `drmTMB`
is not the exact implementation. It is that animal-model workflows should avoid
turning a large pedigree into a dense covariance matrix when a sparse precision
matrix is the natural computational object.

ASReml's known-structure interface also accepts several representations of a
known relationship or inverse relationship matrix. The public `vm()` /
`knownStruc` documentation distinguishes sparse inverse matrices, sparse
relationship matrices, dense `matrix` or `Matrix` objects, and lower-triangle
vectors, with explicit attributes for row names and whether the object is an
inverse. That suggests a `drmTMB` rule for future `animal()` and `relmat()`
work: accept a friendly biological surface, but normalize early to a strict
internal contract with row names, matrix orientation, inverse/covariance state,
and singularity status.

ASReml's model-constructor documentation exposes many structure-specific terms:
direct sums, conditioning factors, moving-average terms, spline terms, grouped
covariates, and known-structure terms. `drmTMB` should not copy that broad
grammar. The lesson is narrower: keep the user-facing model term biological,
then translate to a low-level structure object that the engine can process
without rediscovering design metadata on every fit.

## Implications For `animal()` And `relmat()`

For the first `animal()` path, `drmTMB` should prefer a sparse precision route
when possible:

```r
animal(1 | id, pedigree = pedigree)
relmat(1 | id, Q = Ainv)
relmat(1 | id, K = A)
```

The biological alias `animal()` can build or receive a pedigree relationship
object. The lower-level `relmat()` path should make the matrix contract clear:
`K` is a known covariance or relationship matrix, and `Q` is a known precision
or inverse relationship matrix. A future implementation should preserve row
names, detect missing or unmatched levels, and record whether the fit used a
dense covariance, sparse covariance, or sparse precision representation.

The speed target should be honest. Dense `K` support is enough for small
examples and parity with current `phylo()`/known-covariance thinking, but it is
not enough to compete with ASReml on large single-trait animal models. The
performance-critical target is a direct sparse-precision path with stable log
determinants and no avoidable dense inverse.

Use this representation boundary when writing examples or planning code:

| Public input | Mathematical object | Near-term use | Scalability claim |
| --- | --- | --- | --- |
| `animal(1 | id, pedigree = ped)` | Additive relationship derived from a pedigree, preferably normalized internally to a sparse inverse relationship precision. | First biological animal-model surface after parser and validation gates. | Do not claim large-pedigree speed until the sparse inverse path is fitted, tested, and benchmarked. |
| `animal(1 | id, A = A)` | Dense or sparse additive relationship covariance. | Small examples, dense parity checks, and user-supplied relationship matrices when inversion is explicit and safe. | Small-to-moderate only if the engine must invert or factor a dense matrix. |
| `animal(1 | id, Ainv = Ainv)` | User-supplied inverse additive relationship or precision matrix. | Preferred scalability route once row-name, positive-definiteness, and log-determinant checks exist. | Potential large-pedigree route after recovery and scaling evidence. |
| `relmat(1 | id, K = K)` | Lower-level user-supplied relatedness covariance. | Expert route for known latent relatedness that is not animal, phylogenetic, or spatial. | Small-to-moderate until sparse covariance or precision handling is proven. |
| `relmat(1 | id, Q = Q)` | Lower-level user-supplied precision or inverse relationship matrix. | Expert sparse route after orientation, row-name, and determinant contracts are implemented. | Potential scalable route, but only after diagnostics and benchmarks. |
| `meta_V(V = V)` | Known sampling covariance among observations or effect-size estimates. | Gaussian meta-analysis and related known-observation-covariance models. | Separate problem: dense `V` remains small-to-moderate until sparse/block-sparse sampling-covariance storage is implemented. |

## Immediate Design Rules

- Keep `animal()` as biological sugar and `relmat()` as the lower-level known
  matrix surface.
- Support both covariance (`K`) and precision (`Q`) arguments in the roadmap,
  but do not claim large-pedigree speed until `Q` is fitted and tested.
- Store row names and matching diagnostics as part of the processed structure,
  not as informal attributes used only during parsing.
- Treat singular or semi-definite relationship structures as a separate design
  decision. Do not silently coerce them into positive-definite dense matrices.
- Report which structure was used in diagnostics, because users need to know
  whether a model ran through dense covariance, sparse covariance, or sparse
  precision.
- Keep factor-analytic multi-trait animal-model ambitions separate from the
  first univariate intercept path; the first path should prove correctness and
  scaling before richer G-matrix examples.

## What Not To Claim Yet

This inspection does not show that `drmTMB` is faster than ASReml for large
Gaussian animal models. It supports the opposite near-term position: ASReml is
the benchmark for sparse REML animal-model infrastructure, while `drmTMB`'s
near-term differentiators are unified distributional regression, TMB-based
non-Gaussian likelihoods, shared animal/phylogenetic/spatial grammar, and later
reduced-rank or cross-parameter extensions.
