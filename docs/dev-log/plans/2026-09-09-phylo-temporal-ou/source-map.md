# Temporal covariance source map

**Scope.** This is a Phase-0 design and provenance map for the native drmTMB
programme. A cited source records what its own author or software documents;
it does not validate a drmTMB likelihood, parser, numerical implementation, or
scientific claim. The implementation evidence begins with the independent dense
oracle in P1.

**Notebook receipt.** NotebookLM notebook `drmTMB temporal covariance source
map` (`73d1649d-e9a3-4428-b5b7-a39aed8dc0e7`) was created on 2026-09-09. The
three accessible pages below completed processing. Its synthesis response was
empty, so this map uses the pages directly and makes no claim based on an
unreturned NotebookLM answer.

## Verified sources

1. Brooks et al.'s [glmmTMB covariance-structures article](https://glmmtmb.github.io/glmmTMB/articles/covstruct.html)
   (NotebookLM source `7765183d-8775-48d5-bbab-cbd554e893a2`) documents the
   package's structured-covariance formula interface, including AR1 and OU,
   and describes Toeplitz and heterogeneous structures as part of its broader
   covariance catalogue. It is a comparison and interface source only: its
   implementation is not copied and it does not establish correctness for
   drmTMB.
2. The [glmmTMB function reference](https://glmmtmb.github.io/glmmTMB/reference/glmmTMB.html)
   (NotebookLM source `8a19b81f-50ad-4f2c-b5ce-0f37f7963018`) independently
   records that covariance structures are part of `glmmTMB` model fitting.
   It supports source-map terminology, not an equivalence or compatibility
   claim for drmTMB.
3. The [Matilda ARMA guide](https://matilda.fss.uu.nl/articles/arma-model.html)
   (NotebookLM source `871b7562-6ebe-4150-8754-5429ce1581ed`) describes ARMA
   as a single time-series process containing autoregressive and moving-average
   terms, with stationarity and invertibility conditions. It supports keeping
   ARMA as a later, use-case-triggered candidate rather than treating it as an
   additive AR plus MA random-effect block.
4. Felsenstein's [Phylogenies and the Comparative Method](https://doi.org/10.1086/284325)
   (NotebookLM source `c2404e5e-3278-4d8d-8144-e4345d6f07a2`) is the primary
   provenance for phylogenetic comparative covariance. P1 uses the existing
   drmTMB `phylo()` convention after explicit tree-tip matching; it does not
   silently replace that convention with a newly inferred matrix definition.

## Unverified leads

1. Pourahmadi (1999), [Joint mean-covariance models with applications to
   longitudinal data: unconstrained parameterisation](https://doi.org/10.1093/biomet/86.3.677),
   is a useful primary lead for positive-definite covariance parameterisation.
   NotebookLM ingested the DOI landing page as `Just a moment...` (source
   `42b6697b-2737-47da-9682-b950e454c8e9`), and its accessible publisher record
   was rejected as paywalled. It therefore supplies no verified implementation
   rule here; a later design slice must obtain and check the paper before using
   it to choose a Toeplitz parameterisation.
2. The user-supplied ARMA material supports a later research question only.
   No ARMA order, estimator, formula grammar, or implementation is approved by
   this map.

## Decisions carried into Phase 1

- Retain the separate roles of a stable phylogenetic intercept and independent
  within-species OU deviations; do not substitute a separable phylogeny-by-OU
  field.
- Treat GLMMTMB naming and structure catalogues as cross-learning input, not a
  license to port code or imitate an API without native likelihood and oracle
  evidence.
- Leave homogeneous Toeplitz, heterogeneous AR1, heterogeneous Toeplitz and
  ARMA in later phases of the committed master plan.
