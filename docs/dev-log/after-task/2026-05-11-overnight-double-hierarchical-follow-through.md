# After Task: Overnight Double-Hierarchical Follow-Through

## Goal

Continue the low-budget double-hierarchical Gaussian follow-through, keep the
univariate/bivariate scope boundary intact, and hand back a concrete proposal
for the tutorial/article layout plus equation-format consistency.

## Implemented

- Audited the current repo state without attempting a broad reorganization.
- Reviewed the tutorial and design-doc inventory against the current pkgdown
  article map.
- Normalized the front-door symbolic equations in
  `vignettes/location-scale.Rmd` and the first model blocks in
  `vignettes/which-scale.Rmd` so the most visible examples now read as LaTeX
  display math followed by fenced R syntax.
- Kept the broader article structure unchanged: separate tutorial pages still
  look like the right default, and the next step remains a clearer landing-page
  map rather than a merge into one long article.

## Article Structure Proposal

The current article split is already close to the right shape. The main fix is
navigation clarity, not consolidation:

- keep `location-scale`, `which-scale`, `bivariate-coscale`, `meta-analysis`,
  and `phylogenetic-spatial` as separate tutorials;
- keep `distribution-families` and `robust-student` as the non-Gaussian family
  cluster;
- keep `formula-grammar`, `adding-families`, `testing-likelihoods`, and
  `source-map` as developer notes;
- add a clearer landing-page table or section in `vignettes/drmTMB.Rmd` that
  groups articles by question, not by implementation phase.

If a rename happens later, `phylogenetic-spatial` is the only title that might
benefit from a later split or retitle. For now it still communicates the key
boundary: implemented phylogeny, planned spatial dependence.

## Equation Consistency Gaps

The most important pages to normalize later are:

- `vignettes/drmTMB.Rmd`
- `vignettes/location-scale.Rmd`
- `vignettes/which-scale.Rmd`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `docs/design/28-double-hierarchical-endpoint.md`

The cleaner contract is:

1. use LaTeX display math for the model statement readers should learn;
2. use fenced R blocks for `drmTMB(...)` syntax;
3. use short narrative paragraphs to connect the model to the biological
   question;
4. reserve compact text-style equations for implementation cross-checks only.

That keeps the symbolic equation, the R syntax, and the interpretation aligned
without overfitting the prose to implementation details.

## Checks Run

- inventory scan of the current article and tutorial titles
- scan for equation-format hotspots in tutorials and design docs
- `git diff --check`

## What Did Not Change

- No package code was edited in this pass.
- No heavy tests were rerun.
- No tutorial/article reorganization was applied yet.

## Next Actions

1. Normalize the next highest-traffic tutorial pages so the symbolic model is
   consistently LaTeX, the syntax is R, and the interpretation follows
   directly.
2. Decide whether to add a tutorial landing-page map or a short "start here"
   section in `vignettes/drmTMB.Rmd`.
3. If the tutorial architecture expands again, separate the biological
   case-study examples from the model-class pages so readers can navigate by
   question instead of by implementation detail.
