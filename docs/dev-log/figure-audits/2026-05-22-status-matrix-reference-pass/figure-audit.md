# Status-Matrix Reference Pass

Date: 2026-05-22

## Scope

Ada, Florence, Pat, Fisher, Grace, and Rose rechecked the two `figure-gallery`
status-boundary figures that were left on the Florence watchlist. These are
role perspectives, not spawned agents.

The useful-user question was: can a reader see the supported boundary without
staring at heavy tile plots or mistaking planned cells for estimates?

## Render Evidence

Rendered with:

```sh
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('figure-gallery', new_process = FALSE, quiet = TRUE)"
```

Rendered panels copied here:

- `emmeans-boundary-strip-1.png`
- `correlation-layer-boundaries-1.png`

## Figure Inventory

| Rendered figure | Visual data grain | Uncertainty source | Verdict |
| --- | --- | --- | --- |
| `emmeans-boundary-strip-1.png` | status matrix for the current `emmeans` bridge | none; support status only | Improved: the old heavy tile strip is now a lighter row display with a status marker and current route. |
| `correlation-layer-boundaries-1.png` | status matrix for residual, ordinary group, phylogenetic, spatial, animal, and `relmat()` correlation layers | none; support status only | Improved after rerender: labels now sit beside larger markers, so no cell text is clipped or hidden. |

## Rose Consistency Note

The earlier status code treated animal and `relmat()` q4 or regression
extensions as planned-only, while the surrounding prose and implementation map
say their constant q4 location-scale blocks have first-slice evidence. The
refreshed matrix marks ordinary group, phylogenetic, spatial, animal, and
`relmat()` richer routes as partial, with residual `rho12` remaining planned
for the richer route.

## Remaining Limits

These are still support-boundary displays rather than estimate plots. They do
not supply intervals, simulation coverage, or profile evidence for the richer
rows. Future manuscript figures should probably use a custom compact table,
not these tutorial status matrices.

## Future Visual Language

Florence and Fisher should treat the proposed "Confidence Eye" as a separate
visual-design slice, not as part of this status-matrix repair. The intended
grammar is a pale, low-alpha confidence or compatibility area; denser interval
or outline strokes; and a white-filled central point-estimate circle with a
darker outline. The conventional confidence interval can remain optional, but
the display should state whether the eye comes from Wald, profile, bootstrap,
simulation, or another interval source so readers do not mistake a frequentist
compatibility display for posterior draws.
