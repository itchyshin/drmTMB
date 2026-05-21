# Correlation Gallery Q2 Refresh Figure Audit

Date: 2026-05-21

## Scope

Ada, Florence, Pat, Fisher, Grace, and Rose audited the rendered correlation
panels after the post-0.1.3 spatial, animal, and `relmat()` q=2 fitted slices
landed. These are role perspectives, not spawned agents.

The useful-user question was: can an applied reader see which correlation
layers now have fitted q=2 rows, without mistaking richer spatial, animal, or
`relmat()` correlation paths for implemented support?

## Render Evidence

The article was rendered with:

```sh
Rscript -e "devtools::load_all('.', quiet = TRUE); rmarkdown::render('vignettes/figure-gallery.Rmd', output_dir = '/tmp/drmtmb-correlation-gallery-q2-refresh', output_options = list(self_contained = FALSE), quiet = FALSE)"
```

Rendered panels copied here for durable audit evidence:

- `correlation-display-1.png`
- `correlation-layer-boundaries-1.png`

## Figure Inventory

| Rendered figure | Visual data grain | Uncertainty source | Verdict |
| --- | --- | --- | --- |
| `correlation-display-1.png` | `corpairs()`-compatible illustrative rows for residual, ordinary group, phylogenetic, spatial, animal, and `relmat()` q=2 correlations | finite illustrative Wald/profile bounds on Fisher's `z` scale | Acceptable: six layers are visible and separated; legend and row labels fit. |
| `correlation-layer-boundaries-1.png` | support-status strip, not estimates | no intervals; status only | Acceptable: constant q=2 rows are fitted first slices, while richer regression or q4/scale extensions remain planned. |

## Florence Notes

The six-row raindrop panel remains legible at the rendered vignette size. The
support-boundary strip is intentionally categorical rather than inferential. It
uses blue for fitted q=2 rows, green for partly fitted richer paths, and yellow
for planned boundaries; the label contrast is sufficient in the rendered PNG.

## Fisher And Rose Notes

The display does not claim formal simulation coverage or default profile
coverage for spatial, animal, or `relmat()` rows. The text explicitly says
richer structured correlation regressions, q=4 location-scale blocks, and
structured `sigma` correlations remain planned.

## Remaining Limits

The correlation display still uses a compact compatible fixture so the gallery
builds quickly. A future worked example should use real fitted `corpairs()`
outputs from the structural-dependence examples once those examples are split
into separate animal, phylogenetic, spatial, and `relmat()` articles.
