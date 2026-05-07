# After Task: Phylogenetic And Spatial Common Math

## Task Goal

Read the local phylogenetic/spatial meta-analysis tutorial and record the
shared mathematical abstraction that will guide future phylogenetic A-inverse
and spatial SPDE implementation in `drmTMB`.

Also clean up public wording around double-hierarchical individual-differences
models so package docs use professional terminology and cite O'Dea, Noble, and
Nakagawa (2022) properly.

## Files Created Or Changed

- Created `docs/design/16-phylo-spatial-common-math.md`.
- Updated `docs/design/09-phylogenetic-and-spatial-speed.md` with the shared
  structured-effect abstraction and a `gllvmTMB` source map.
- Updated `docs/design/08-meta-analysis.md` to connect meta-analysis,
  sampling covariance `V`, phylogenetic matrix `A`, and spatial matrix `M`.
- Updated `docs/design/11-reference-programme.md` with the local tutorial
  source and package implications.
- Updated `vignettes/phylogenetic-spatial.Rmd` with symbolic math and the
  separation between `rho12`, `A`, and `M`.
- Updated `README.md` and `ROADMAP.md` so the same phylogenetic/spatial plan is
  visible on the package front page and roadmap.
- Updated `vignettes/drmTMB.Rmd`, `vignettes/bivariate-coscale.Rmd`, and
  design docs to use professional double-hierarchical wording.
- Added bibliography entries for O'Dea et al. (2022) and the local
  phylogenetic/spatial meta-analysis tutorial in `REFERENCES.bib`.
- Added `.codex/agents/user-tester.toml` for Pat, the applied PhD student user
  tester role, and documented the standing team roles in `AGENTS.md`.
- Added Jason, Curie, Emmy, Grace, and Rose project agent configs for landscape
  scouting, literature, pkgdown/course editing, reproducibility, and systems
  auditing.

## Checks Run

- `pdfinfo /Users/z3437171/Downloads/Tutorial___Phylo_spatial_meta_analysis_2.pdf`
  confirmed the source has 29 pages.
- `pdftotext` plus targeted `rg` searches checked the tutorial for the core
  equations, kernel correspondences, package examples, and identifiability
  warnings.
- Sidecar source-only inspection of sibling `gllvmTMB` identified the relevant
  phylogenetic and SPDE source-map files.
- `git diff --check`: passed.
- `Rscript -e "devtools::test()"`: 148 passed, 0 failed, 0 warnings, 0 skips.
- `air format .`: failed because `air` is not installed locally.
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`: no problems;
  site built successfully.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.
- Remote GitHub R-CMD-check for the previous pushed commit completed
  successfully on macOS, Windows, and Ubuntu while this task was underway.

## Consistency Audit

- Searched active docs, vignettes, roadmap, README, and references for casual
  author-name shorthand, package-name shorthand, `meta_gaussian`, `tau ~`, and
  `rho ~`.
- Removed casual author-name and package-name shorthand from active docs and
  vignettes.
- Remaining `meta_gaussian` and `tau ~` matches are intentional guardrails
  stating that meta-analysis remains Gaussian regression with `sigma`, not a
  separate family or `tau ~` grammar.
- Confirmed `rho12` remains documented as residual response-response coupling,
  distinct from phylogenetic, spatial, and group-level covariance correlations.

## Tests Of The Tests

- The code test suite is unchanged because this was a design/documentation
  task, but the full test suite was rerun to ensure no package behaviour
  regressed.
- The pkgdown build is the relevant documentation test here: it rebuilt the
  changed README and vignettes, including `drmTMB`, `bivariate-coscale`, and
  `phylogenetic-spatial`.
- The wording consistency scan specifically checked the phrase that was visible
  on the preview page and confirmed it no longer appears in active docs.

## Design-Doc Updates

The new source-of-truth abstraction is:

```text
eta_d = X_d beta_d + Z_d z
z ~ MVN(0, sigma_z^2 K)
```

with:

- `K = A` for phylogenetic correlation;
- `K = M` for spatial correlation;
- sparse `A^{-1}` as the phylogenetic speed path;
- sparse SPDE/GMRF precision as the spatial speed path;
- `rho12` reserved for residual response-response correlation.

## Pkgdown And Documentation Updates

The pkgdown site rebuilt locally after:

- adding the common phylo/spatial math to the roadmap article;
- updating the bivariate coscale and getting-started articles;
- correcting the public double-hierarchical wording;
- adding professional references.

## Known Limitations And Next Actions

- No phylogenetic or spatial model-fitting code was implemented in this task.
- `phylo(species)` and `spatial(easting, northing)` remain planned syntax.
- Full known covariance `V`, sparse precision inputs, A-inverse, and SPDE
  modules remain future phases.
- Future implementation should start with one structured `mu` effect, then
  compare sparse and dense phylogenetic paths before moving to bivariate or
  scale-parameter models.
