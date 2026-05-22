# Article Audit Sweep Map

Date: 2026-05-22

## Purpose

This audit map starts the comprehensive article sweep before any broad pkgdown
reorganization. The goal is to make the public site easier for applied ecology,
evolution, and environmental-science users while keeping developer notes useful
for contributors and future agents.

This file is a planning artifact. It does not move articles or change the
navbar by itself.

## Review Roles

Ada coordinates the sweep and keeps edits staged in small slices. Aquinas
reviews pkgdown navigation, Helmholtz reviews developer-note/system drift, and
Goodall reviews the applied-user path as spawned reviewers for this audit.

Standing perspectives:

- Pat checks whether an applied user can find the right article and next step.
- Darwin checks that biological questions stay visible.
- Fisher checks inference, profile/bootstrap, and validation claims.
- Florence checks rendered figures and visual teaching quality.
- Boole checks formula syntax and marker naming.
- Noether checks equations, parameters, and scales.
- Emmy checks reference and S3 extractor links.
- Grace checks pkgdown, rendered pages, and reproducibility.
- Rose checks repeated inconsistencies and stale-status loops.

## Spawned Reviewer Synthesis

Three spawned reviewers inspected the article surface without editing files.

Goodall's applied-user review found that the first-user path is too split
between Model Guides and Tutorials. A new reader should see a sequence like:
`drmTMB` -> `model-map` -> `location-scale` -> `which-scale` ->
`distribution-families` -> `model-workflow`. Goodall also flagged that
structural dependence has the right ingredients but too many peer-level starts:
the overview should be the first stop, route pages should be second stops, and
`phylogenetic-spatial` should be the advanced detail page.

Aquinas' pkgdown review agreed that `figure-gallery` interrupts the biological
question -> model -> interpretation flow when it sits in the middle of
Tutorials. Aquinas recommended splitting Tutorials into core worked examples,
structured dependence, and visual interpretation, and moving
`implementation-map` toward advanced status rather than the first applied-user
path.

Helmholtz's systems audit recommended keeping public user-facing articles
public, keeping the structural split public, and keeping raw design/dev-log
ledgers internal. Helmholtz also identified a classification mismatch:
`docs/design/21-tutorial-style.md` treats `testing-likelihoods` as a Developer
Note, while `_pkgdown.yml` currently places it under Simulation & Comparison.
That should be a deliberate choice in the navigation slice.

Consensus:

- keep `model-map` as the applied "Can I fit this?" authority;
- keep `implementation-map` as the advanced status/evidence authority;
- keep `docs/design/34-validation-debt-register.md` as evidence debt, not a
  public tutorial;
- treat `docs/dev-log/after-task/*` as historical unless a note explicitly
  says it supersedes current status;
- keep `source-map`, `formula-grammar`, and `adding-families` in Developer
  Notes;
- move or relabel `testing-likelihoods` deliberately;
- keep the route-specific structural pages public;
- relabel `phylogenetic-spatial` as structural-dependence details until it is
  split or pruned;
- move figure guidance out of early Tutorials and into an inference,
  diagnostics, and figures path.

## Current Surface

The current pkgdown article surface has 26 vignettes:

- getting started: `drmTMB`
- model guides: `model-map`, `implementation-map`, `which-scale`,
  `distribution-families`, `model-workflow`, `convergence`, `large-data`
- tutorials: `location-scale`, `robust-student`, `count-nbinom2`,
  `figure-gallery`, `proportion-beta-binomial`, `meta-analysis`,
  `bivariate-coscale`, `structural-dependence`, `animal-models`,
  `phylogenetic-models`, `spatial-models`, `relmat-known-matrices`,
  `phylogenetic-spatial`
- simulation and comparison: `testing-likelihoods`,
  `simulation-plot-grammar`
- developer notes: `formula-grammar`, `adding-families`, `source-map`

The repository also has 72 top-level `docs/design/*.md` files. Those are not
all public articles. The audit should expose stable developer entry points and
keep historical phase/slice ledgers internal unless they directly help a
reader or contributor choose a current API.

## Main Problems To Solve

1. The Tutorials menu currently mixes applied tutorials, structural route maps,
   figure-gallery status displays, and the long structural-dependence detail
   page.
2. `model-map`, `implementation-map`, and `source-map` are all useful, but their
   hierarchy needs to be obvious: user capability, evidence/status, and
   developer ownership.
3. Developer notes are underexposed as a coherent contributor path, while raw
   design docs are too numerous to expose directly.
4. Figure quality and interval provenance need a common gate across public
   articles, not only the figure gallery.
5. Structured dependence now has a better split, but the reader path should be
   explicit: overview first, then animal/phylo/spatial/relmat leaf pages, then
   the long technical detail page.
6. CI/profile/bootstrap guidance is spread across model workflow, structured
   dependence, NEWS, and reference pages. A dedicated inference article is now
   likely justified.
7. `testing-likelihoods` is contributor-facing but currently grouped as
   Simulation & Comparison; decide whether that menu is a validation menu for
   users/reviewers or a developer menu.
8. Release/version wording may drift: `_pkgdown.yml` labels the site
   `0.1.3.9000 development`, while public installation/status text may still
   refer to tagged `0.1.3`.

## Proposed Public Navigation

This is the proposed target grouping for a future `_pkgdown.yml` slice.

| Group | Purpose | Articles |
| --- | --- | --- |
| Start Here | first path for new users | `drmTMB`, `model-map`, `model-workflow` |
| Choose Your Model | choose family, scale, and response structure | `which-scale`, `distribution-families`, `location-scale`, `bivariate-coscale`, `meta-analysis` |
| Applied Families | family-specific teaching examples | `robust-student`, `count-nbinom2`, `proportion-beta-binomial` |
| Structured Dependence | random effects and known structure | `structural-dependence`, `animal-models`, `phylogenetic-models`, `spatial-models`, `relmat-known-matrices`, `phylogenetic-spatial` |
| Inference, Diagnostics, and Figures | model checking and visual interpretation | `convergence`, `large-data`, `figure-gallery`, future CI/profile/bootstrap article |
| Simulation and Validation | evidence and comparator work | `implementation-map`, `testing-likelihoods`, `simulation-plot-grammar` |
| Developer Notes | contributor and source-map path | `formula-grammar`, `adding-families`, `source-map`, future developer-note index |

Alternative to decide in the navigation slice: move `testing-likelihoods` into
Developer Notes if the page continues to be written mainly for contributors.
If it stays under Simulation And Validation, its opening should say clearly
that it is evidence for reviewers and advanced users, not a beginner tutorial.

## Developer Notes Policy

Do not publish every `docs/design/*.md` file as a pkgdown article. Split
developer material into four tiers:

| Tier | Treatment | Examples |
| --- | --- | --- |
| Stable contributor articles | exposed in Developer Notes | `formula-grammar`, `adding-families`, `source-map` |
| Stable design references | linked from a future developer-note index | `00-vision`, `01-formula-grammar`, `03-likelihoods`, `12-profile-likelihood-cis`, `39-visualization-grammar` |
| Validation and programme ledgers | linked from validation articles when current | `34-validation-debt-register`, `41-phase-18-simulation-programme`, `46-pre-simulation-readiness-matrix` |
| Historical phase/slice ledgers | remain internal | implementation-map slice ledgers, after-task reports, recovery checkpoints |

The future developer-note index should answer: where is the parser contract,
where is the likelihood contract, where is the source map, where are validation
debts, and where should a new contributor add a family or structured route?

## Authority Hierarchy

The sweep should make the authority hierarchy visible:

| Question | Current authority | Notes |
| --- | --- | --- |
| Can a user fit this model today? | `model-map` | Public applied status page. |
| What evidence tier supports the claim? | `implementation-map` and `docs/design/34-validation-debt-register.md` | Public map plus internal evidence ledger. |
| Where does the code live? | `source-map` | Developer/public source ownership map. |
| What formula syntax is accepted or planned? | `formula-grammar` and `docs/design/01-formula-grammar.md` | Public developer note plus design contract. |
| What changed historically? | `docs/dev-log/after-task/*` | Historical unless a newer note explicitly supersedes current status. |

First high-risk stale-status scans should target:

- spatial q4 fitted versus planned wording;
- animal q4 and `relmat()` q4 fitted versus planned wording;
- Poisson phylogenetic q=1 boundaries;
- `confint(method = "bootstrap")` support versus planned wording;
- `meta_V(V = V)` versus `meta_known_V(V = V)`;
- deprecated `gr()` public syntax.

## Article Inventory And First Verdicts

| Article | Current group | Proposed group | Reader | First audit risk | Next action |
| --- | --- | --- | --- | --- | --- |
| `drmTMB` | Getting Started | Start Here | new user | first page may not give the shortest successful fit path | tighten first-screen path and links |
| `model-map` | Model Guides | Start Here | applied user | central status claims can drift quickly | make it the capability authority |
| `implementation-map` | Model Guides | Simulation and Validation | advanced user / reviewer | overlaps with model map and source map | state evidence tiers and scope |
| `which-scale` | Model Guides | Choose Your Model | applied user | scale terminology can drift | check `sigma`, `rho12`, coscale wording |
| `distribution-families` | Model Guides | Choose Your Model | applied user | family support and planned cells can stale | compare to family registry and NEWS |
| `model-workflow` | Model Guides | Start Here or Inference | applied user | CI/profile/bootstrap guidance is central but spread out | decide whether to split inference article |
| `convergence` | Model Guides | Inference, Diagnostics, And Figures | applied user | Hessian warnings can sound like total failure | align with `check_drm()` wording |
| `large-data` | Model Guides | Inference, Diagnostics, And Figures | applied user | speed claims need evidence boundaries | check aggregation/sparse claims |
| `location-scale` | Tutorials | Choose Your Model | applied user | high-traffic tutorial needs equation/syntax/interpretation alignment | prose and figure pass |
| `robust-student` | Tutorials | Applied Families | applied user | shape parameter wording | check `nu` and interval claims |
| `count-nbinom2` | Tutorials | Applied Families | applied user | count random-effect and structured boundaries changed recently | stale support scan |
| `figure-gallery` | Tutorials | Inference, Diagnostics, And Figures | applied user / maintainer | figure standards and Confidence Eye direction | rendered figure audit |
| `proportion-beta-binomial` | Tutorials | Applied Families | applied user | zero/one boundary support can be overimplied | status and examples check |
| `meta-analysis` | Tutorials | Choose Your Model | applied user | `meta_V(V = V)` versus latent relatedness | matrix-layer audit |
| `bivariate-coscale` | Tutorials | Choose Your Model | applied user | `rho12`, coscale, and residual correlation naming | equation and syntax audit |
| `structural-dependence` | Tutorials | Structured Dependence | applied user | needs to be the route chooser | simplify and link leaf pages |
| `animal-models` | Tutorials | Structured Dependence | applied user | fitted q2/q4 and planned routes can blur | status and example audit |
| `phylogenetic-models` | Tutorials | Structured Dependence | applied user | Poisson q1 and Gaussian routes must stay separated | status and example audit |
| `spatial-models` | Tutorials | Structured Dependence | applied user | q2/q4 fitted claims changed recently | status and example audit |
| `relmat-known-matrices` | Tutorials | Structured Dependence | advanced applied user | use cases were too abstract | monitor after new use-case patch |
| `phylogenetic-spatial` | Tutorials | Structured Dependence detail | advanced user / developer | long technical page may absorb too many roles | rename or frame as detail page |
| `testing-likelihoods` | Simulation & Comparison | Simulation and Validation | developer / reviewer | comparator claims need current evidence | check comparator scope |
| `simulation-plot-grammar` | Simulation & Comparison | Simulation and Validation or Figures | maintainer / reviewer | figure/data-grain contract is central | Florence/Fisher render audit |
| `formula-grammar` | Developer Notes | Developer Notes | contributor | must track parser support exactly | parser/status scan |
| `adding-families` | Developer Notes | Developer Notes | contributor | family-add path must match current tests/source map | source/test path check |
| `source-map` | Developer Notes | Developer Notes | contributor / future agent | source ownership can stale after C++ work | source-map authority check |

## First Sweep Slices

1. Create this article sweep map and record review roles.
2. Add a `docs/dev-log/audits/` rendered-page checklist for all 26 articles.
3. Reorganize `_pkgdown.yml` navigation only, without rewriting prose.
4. Add a developer-note index article or design note that links stable design
   docs without exposing all historical ledgers.
5. Pass the Start Here triad: `drmTMB`, `model-map`, `model-workflow`.
6. Pass the Choose Your Model group.
7. Pass the Structured Dependence overview and leaf pages.
8. Decide whether `phylogenetic-spatial` should be renamed, split, or clearly
   framed as the advanced detail page.
9. Create or plan a dedicated inference article for Wald/profile/bootstrap,
   profile precision, and Confidence Eye-compatible displays.
10. Run the Florence/Fisher figure sweep across figure-gallery,
    simulation-plot-grammar, and any tutorial figures with intervals.

## Required Gates For Each Article

Each article audit should record:

- intended reader and first task;
- fitted versus planned claims;
- core R syntax and whether examples are runnable;
- equation and parameter naming;
- links to reference pages and model maps;
- figure inventory with data grain and interval source;
- stale wording searches;
- rendered HTML or PNG inspection evidence;
- relevant GitHub issues and after-task reports.

## Immediate Recommendation

Do the next commit as a navigation-only pkgdown slice after this audit map is
reviewed. Avoid broad prose rewrites until the new navigation groups are stable,
because the article openings should be rewritten for their final position in the
learning path.

The first navigation-only slice should avoid moving source files. It should
change `_pkgdown.yml` menu grouping, relabel `phylogenetic-spatial` as
Structural dependence details, move `figure-gallery` out of early Tutorials,
and make the first-user sequence visible. Then a rendered-page review can check
whether the menu actually feels simpler before any article prose is rewritten.
