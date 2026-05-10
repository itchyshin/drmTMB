# Sleep Consolidation: After Phase 9 Release-Readiness Push

Date: 2026-05-10

Reader: Ada, the standing review team, and future contributors restarting work
after the first large release-readiness push.

## Why Pause

The package just moved through a large documentation, family, comparator, and
release-readiness batch. CI caught one brittle beta-binomial boundary test, and
the landing page wording revealed an audience problem: internal shorthand can
hide the model class from new users. Both were fixable. The useful step now is
to consolidate before starting another implementation branch.

## What Is Stronger Now

- GitHub Actions are green again for R-CMD-check on Ubuntu, macOS, and Windows.
- pkgdown deploys the shorter landing page.
- The public roadmap says `0.1.0` is a reliable preview release, not the final
  double-hierarchical individual-difference endpoint.
- Public scale language stays on `sigma`; variance-facing summaries are
  derived as `sigma^2`.
- The newest docs describe individual-difference location-scale models in words
  a reader can understand before they know the source papers.
- The Gaussian location-scale comparator harness gives Fisher and Gauss an
  executable overlap check against `glmmTMB`.

## Mistakes Worth Keeping

- A boundary test accidentally asserted optimizer convergence instead of the
  intended finite-behaviour contract. Curie and Grace should now ask whether a
  convergence-code assertion is testing the model, the optimizer, or a
  pathological edge case.
- The first landing-page pass tried to carry too much of the package at once.
  Pat should keep the home page as an overview and routing surface, with full
  details in articles.
- Author-name shorthand leaked into reader-facing prose. Rose and Pat should
  replace project nicknames with model classes, scientific quantities, or
  formal citations.

## Refocused Phase Map

| Horizon | Strongest next move | Why it matters |
| --- | --- | --- |
| Immediate | Close the `0.1.0` release gate as an explicit checklist | Users need a stable preview more than another half-started feature. |
| Next implementation | Pin and run the Gaussian individual-difference location-scale examples that current drmTMB can already fit | This turns roadmap claims into reproducible evidence. |
| Next design | Specify labelled covariance blocks across `mu` and `sigma` before coding full double-hierarchical models | This is the bridge to personality, plasticity, predictability, and malleability correlations. |
| Shape/asymmetry | Keep Student-t location-scale-shape stable, then add skew-normal as the first asymmetry family | Shape models are valuable, but identifiability and naming must be clear. |
| User trust | Keep landing page, tutorials, limitations, and CI green after every batch | Users will trust drmTMB when the package is honest about what works now. |

## Team Re-Entry

- Ada: choose one next target and keep the release gate visible.
- Grace: keep CI and pkgdown as hard gates after every push.
- Pat: read every public page as a first-time applied user.
- Rose: scan for terminology drift, stale claims, and unsupported promises.
- Gauss and Noether: do not let equations, parameter transforms, and TMB code
  drift apart.
- Fisher and Curie: prefer executable comparators and simulation checks over
  confident prose.
- Jason and Darwin: keep examples grounded in real ecological, evolutionary,
  and environmental questions.
- Boole and Emmy: protect syntax, object structure, and extractors before the
  feature surface grows.

## Return Rule

After this pause, the next batch should start with one of two moves:

1. Finish the `0.1.0` preview-release checklist and decide what remains
   post-release.
2. Run the first real-data Gaussian individual-difference location-scale
   replication that current drmTMB can honestly fit.

Do not start full double-hierarchical covariance, skew-normal, or spatial
scale models until the chosen next batch has a bounded acceptance test.
