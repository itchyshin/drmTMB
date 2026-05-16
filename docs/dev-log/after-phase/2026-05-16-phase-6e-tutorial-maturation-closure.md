# After Phase: Phase 6e Tutorial Maturation Closure

Date: 2026-05-16

## Goal

Close the local Phase 6e tutorial-maturation pass after Slices 89 to 92. The
goal was to make the tutorial layer easier to navigate before moving to larger
post-gate asks: worked-example inventory, flagship Gaussian location-scale
polish, structural-dependence routing, stale-status scans, pkgdown evidence,
and source/rendered-site agreement.

## Implemented Scope

Phase 6e changed documentation and planning artifacts only. It did not change
formula grammar, likelihood parameterization, TMB code, exported functions,
extractors, or fitted-object structure.

The locally closed tutorial boundary is:

- Slice 89 created `docs/design/37-worked-example-inventory.md`, separating
  worked tutorials from guides and naming the next tutorial candidates.
- Slice 90 deepened `vignettes/location-scale.Rmd` with trait-named Gaussian
  equations, parameter definitions, response-scale interpretation, and a
  meta-analysis design reservation.
- Slice 91 reframed `vignettes/phylogenetic-spatial.Rmd` and the navigation as
  "Structural dependence", with the route phylogeny, spatial, and planned
  phylogeny plus spatial.
- Slice 92 closed the local gate with stale-status scans, roadmap/design-note
  cleanup, pkgdown build/check, and this after-phase report.

## Mathematical Contract

The tutorial layer now carries three stable teaching contracts:

```text
Gaussian location-scale:
  mu slope                  -> expected-response effect
  sigma slope               -> log residual-SD effect
  exp(sigma slope)          -> residual-SD ratio
  exp(2 * sigma slope)      -> residual-variance ratio
  random-slope SD           -> among-group reaction-norm variation
  sd(group) slope           -> group-level model for mean-effect SD

Structural dependence:
  phylo(1 | species, tree = tree)      -> current tree-structured mu field
  spatial(1 | site, coords = coords)   -> current coordinate-structured mu field
  phylo() + spatial() in the same mu    -> planned until identifiability checks

Meta-analysis:
  meta_known_V(V = V)       -> current additive known sampling covariance
  weights = w               -> row likelihood multipliers, not sampling variance
  meta_V(...)               -> reserved future umbrella, not implemented
```

The source and rendered tutorials keep residual `rho12` separate from
structural covariance summaries such as `corpairs()`, and they keep public
`sigma` terminology separate from meta-analysis `tau` notation.

## Files Changed In Gate Slice

- `ROADMAP.md`
- `docs/design/00-vision.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/design/21-tutorial-style.md`
- `docs/design/32-phase-6b-tutorial-source-map.md`
- `docs/design/37-worked-example-inventory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-phase/2026-05-16-phase-6e-tutorial-maturation-closure.md`

## Checks Run

- `air format ROADMAP.md docs/design/00-vision.md docs/design/09-phylogenetic-and-spatial-speed.md docs/design/21-tutorial-style.md docs/design/32-phase-6b-tutorial-source-map.md docs/design/37-worked-example-inventory.md`:
  passed.
- `rg -n 'Structured dependence|Structured-dependence|structured-dependence|structured dependence' README.md NEWS.md ROADMAP.md _pkgdown.yml docs/design vignettes pkgdown-site --glob '!pkgdown-site/search.json' --glob '!docs/dev-log/**'`:
  found old source labels before cleanup and returned no matches after cleanup.
- `rg -n 'Slice 91 should|Slice 90 should|Done when a reader can choose|TODO|FIXME|not implemented yet.*implemented|implemented.*not implemented' ROADMAP.md docs/design/37-worked-example-inventory.md README.md NEWS.md vignettes pkgdown-site/articles pkgdown-site/ROADMAP.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`:
  found stale Slice 91 future wording and old rendered ROADMAP text before
  cleanup. The source was cleaned; the rendered site was refreshed with
  `pkgdown::build_site()`.
- `rg -n 'meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]' README.md NEWS.md ROADMAP.md docs/design vignettes R tests pkgdown-site --glob '!pkgdown-site/search.json'`:
  found only intentional guardrails or historical design references, not new
  user-facing syntax.
- `rg -n 'phylogeny-plus-spatial|phylogenetic-plus-spatial|simultaneous \`phylo\\(\\)\` plus \`spatial\\(\\)\`|contains both|multiple structural \`mu\` layers|multiple structured layers' README.md NEWS.md ROADMAP.md docs/design vignettes R tests pkgdown-site --glob '!pkgdown-site/search.json'`:
  confirmed the planned combined route and the code-side rejection boundary.
- `pdfinfo "/Users/z3437171/Downloads/Brit J Math Statis - 2023 - Rodriguez - Heterogeneous heterogeneity by default Testing categorical moderators in.pdf"`:
  confirmed the local Rodriguez et al. 2023 source for later
  heterogeneous-heterogeneity parameterization and simulation planning.
- `pdftotext ... | rg -n -i 'parameter|location|scale|heterogeneous|heterogeneity|simulation|moderator|categorical|variance|tau|log|model|data generating|recommend|default' | head -n 100`:
  inspected enough source text to record the paper as a future meta-analysis
  parameterization and simulation-design source.
- `pkgdown::build_site()`: passed after gate cleanup.
- `pkgdown::check_pkgdown()`: passed with "No problems found."
- `git diff --check`: passed.
- Patch-only non-ASCII scan with `LC_ALL=C rg -n '[^\\x00-\\x7F]'`: returned
  no matches.

## Tests Of The Tests

No testthat tests were added because Phase 6e is documentation and tutorial
coordination only. The gate tested the tutorial layer by rebuilding pkgdown and
by checking source/rendered text for the claims that could mislead users:
implemented versus planned syntax, `rho12` versus structural covariance,
`meta_known_V(V = V)` versus weights, and the old "structured dependence"
label.

## Standing Review Closure

- Ada: Phase 6e is locally closed as a tutorial-routing and consistency lane,
  not a modelling-surface expansion.
- Boole: no formula grammar changed; planned syntax remains labelled planned.
- Gauss: no likelihood or TMB contract changed.
- Noether: equations, R syntax, and interpretation now line up across the
  flagship Gaussian and structural-dependence tutorials.
- Darwin: examples now use biological names such as parrot beak length, heat
  tolerance, habitat, depth, and future count/proportion responses.
- Fisher: Rodriguez et al. 2023 is queued for later simulation and
  heterogeneous-heterogeneity design, not silently folded into the current
  release gate.
- Pat: applied readers have a clearer path from a biological question to the
  correct tutorial, guide, or unsupported-boundary message.
- Jason: future example sources are named in the inventory before more tutorial
  work starts.
- Curie: no new tests were needed for this gate; future count/proportion and
  meta-analysis examples should add runnable checks when they add new examples.
- Grace: local pkgdown build/check and diff hygiene passed; GitHub Actions is
  the PR-side gate.
- Rose: stale Slice 91 future wording and old "structured dependence" labels
  were removed from active source docs.

## What Did Not Go Smoothly

The first stale-status scan found a real source-doc drift: Slice 91 was merged,
but `docs/design/37-worked-example-inventory.md` still described it as a future
candidate, and older design notes still used "structured dependence". The gate
did its job; those labels were cleaned before closing.

## Known Limitations

- Phase 6e does not implement non-Gaussian tutorials, simultaneous phylogeny
  plus spatial models, mesh/SPDE fitting, proportional sampling variance, or
  alternative meta-analysis parameterizations.
- The Rodriguez et al. paper is recorded as a source for later work; no
  simulation code or tutorial section was added from it in this gate.
- Public release preparation for `0.1.2` should wait until this gate PR has
  remote CI evidence and the user has had a chance to define the two larger
  post-gate asks.

## Next Actions

1. Open and merge the Slice 92 gate PR after GitHub Actions pass.
2. Stop the slice sequence and ask the project owner for the two large
   post-gate asks.
3. When tutorial work resumes, choose one lane at a time: meta-analysis
   parameterization/simulation, non-Gaussian count/proportion tutorials, or
   another named worked-example gap.
