# After Task: Slice 1178a Structural Parity And Issue Maintenance

## Goal

Record the user's structural-dependence route order and keep the planned
animal, spatial, phylo, phylo+spatial, and `relmat()` ladder tied to existing
issues instead of chat memory.

## Implemented

Ada updated the structural-dependence article so the reader route is explicitly
animal, phylo, spatial, phylo+spatial, then `relmat()`. The article now states
that "same as phylo" is a parity target: univariate location structure,
bivariate q=2 location-location correlations, q=4 location-scale blocks,
structured `corpair()` regressions, and direct-SD siblings should eventually
exist for animal, spatial, and `relmat()` where scientifically meaningful and
identifiable.

The added animal q=2 and q=4 examples are marked planned and not fitted. The
article still says animal and `relmat()` are planned markers, and spatial is
only fitted for univariate Gaussian coordinate-spatial `mu` intercepts and one
independent `mu` slope.

## Files Changed

- `vignettes/phylogenetic-spatial.Rmd`
- `docs/design/53-structural-dependence-article-split.md`
- `docs/design/10-after-task-protocol.md`
- `.agents/skills/after-task-audit/SKILL.md`
- `docs/dev-log/forgotten-promises-status-2026-05-20.md`
- `docs/dev-log/slice-plan-1139-1238-visual-reference-convergence.md`
- `docs/dev-log/team-improvements.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-20-slice-1178a-structural-parity-issue-maintenance.md`

## Checks Run

```sh
Rscript -e "devtools::load_all('.', quiet = TRUE); rmarkdown::render('vignettes/phylogenetic-spatial.Rmd', output_dir = '/tmp/drmtmb-structural-parity', output_options = list(self_contained = FALSE), quiet = TRUE)"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
rg -n "animal -> phylo|phylo\\+spatial|structural-dependence article|relmat\\(\\)|GitHub Issue Maintenance|After-Task Issue Maintenance|1178a" docs vignettes .agents/skills/after-task-audit/SKILL.md
```

Outcomes: the article rendered, `pkgdown::check_pkgdown()` reported no
problems, and `git diff --check` passed.

## Tests Of The Tests

This was documentation and process work, not a likelihood change. The useful
test of the edit is the rendered article plus the stale-wording search showing
the new route order, issue-maintenance rule, and split-plan design note in
repository files.

## Consistency Audit

The new wording keeps fitted and planned routes separate:

- fitted phylo: univariate `mu`, bivariate q=2 `mu1`/`mu2`, q=4
  location-scale, direct `sd_phylo*()`, and q=2 phylogenetic `corpair()`;
- fitted spatial: univariate coordinate-spatial `mu` intercept and one
  independent `mu` slope;
- planned animal and `relmat()`: parser/reference markers only;
- planned phylo+spatial: no simultaneous fitted route yet.

## GitHub Issue Maintenance

Inspected open issues #147, #33, #31, and #5. No issue was closed.

- Commented on #147 to record the animal/`relmat()` parity ladder with phylo.
- Commented on #33 to record spatial as the phylo sibling while preserving the
  narrow fitted status.
- Commented on #31 to record the future article split into animal, phylo,
  spatial, phylo+spatial, and `relmat()` pages.
- Left #5 unchanged because it already tracks the broader ordinary
  individual-difference covariance endpoint; this slice was about structured
  dependence and documentation architecture.

## What Did Not Go Smoothly

The first attempt to patch the issue-maintenance process docs failed because
the surrounding text had drifted. Ada redid the edit in smaller patches.

## Team Learning

Rose's process rule is now explicit: meaningful after-task reports should
inspect overlapping GitHub issues. This should prevent old promises such as
animal examples, relmat parity, visual standards, and convergence follow-ups
from being remembered only in conversation.

## Known Limitations

No animal, `relmat()`, bivariate spatial, spatial `sigma`, mesh/SPDE,
phylo+spatial, or structured `corpair()` parity implementation was added. The
new animal q=2/q=4 examples are planned syntax only.

## Next Actions

Split the structural-dependence article after the next reference and learning
path audit. Keep the first split order as animal, phylo, spatial,
phylo+spatial, then `relmat()`.
