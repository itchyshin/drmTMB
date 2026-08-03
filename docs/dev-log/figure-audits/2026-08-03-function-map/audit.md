# Figure audit: function map and cheat sheet

## Purpose

Help an installed-package user choose the next `drmTMB` task without implying
that model structure is a post-fit stage or that interpretation, prediction,
and uncertainty form one compulsory sequence.

## Audit table

| Figure | Source object | Visual data grain | Uncertainty source | Missing-cell display | Reader risk | Final verdict | Fix |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `drmTMB function map` | Image 2.0 base plus deterministic SVG label overlay | Task and public-function navigation; no statistical data | Not applicable | Not applicable | A circular or sequential map could put structured terms after inference, misclassify `profile_targets()`, or hide object-specific prerequisites | Florence PASS; Pat PASS; Rose PASS | Use the numbered primary route Specify → Fit → Check, then three unnumbered conditional branches; keep structured terms in specification; move `profile_targets()` to uncertainty; use `rho12()` rather than `association()` on the ordinary fitted-object route |

## Image 2.0 provenance

The built-in Image 2.0 path generated the base artwork. The successful final
base prompt was:

> Create a polished, reader-first landscape `drmTMB` function map for pkgdown.
> Show the primary route `1 Specify model → 2 Fit → 3 Check fit health`, then
> branch to Interpret, Predict & assess, and Uncertainty & simulate. Put
> `phylo()`, `spatial()`, and `relmat()` inside Specify model. Use crisp flat
> vector-like cards, drmTMB's teal/blue/amber/green/coral palette, exact public
> R function spelling, strong arrows, generous spacing, a warm white
> background, and no browser chrome, watermark, Julia note, or engine argument.

The saved base is `image2-base.png`. Image 2.0 produced the overall composition,
icons, palette, and arrow system. After the reviewers found semantic label
problems, repeated Image 2.0 edit and regeneration requests failed with network
errors. `function-map-final-overlay.svg` therefore applies auditable text-only
corrections to that base. Rasterize it from this directory with:

```sh
rsvg-convert --width 1536 --height 1024 \
  --output ../../../../vignettes/function-map-cheatsheet.png \
  function-map-final-overlay.svg
```

The overlay is intentionally limited to labels and the two obsolete branch
badges. It does not redraw the Image 2.0 icons, cards, palette, arrows, or page
composition.

## Render inspection

- `rendered-desktop.png`: top-and-figure viewport capture at 1440 × 1800 px.
- `rendered-mobile-390x844.png`: top-of-page viewport capture under true
  390 × 844 px mobile emulation.
- The mobile figure has an adjacent full-size-image link. The route table uses
  a labelled, keyboard-focusable horizontal scroll region with a 46 rem minimum
  width, so its columns do not collapse into one-word lines.
- The image alt text names the primary route, revision arrow, three conditional
  branches, and every displayed function.

## Final review

- **Florence — PASS:** hierarchy, label size, colour, arrow semantics, spacing,
  and overlay seams passed at source and rendered scale.
- **Pat — PASS:** the next task, failed-fit recovery, unsupported-route advice,
  full-size mobile figure, and responsive route table are usable by an applied
  first-time reader.
- **Rose — PASS:** formula, family, structured-term, object-transition,
  `profile_targets()`, family-specific location, adequacy scope, and deferred
  Julia boundaries match the current source and nearby public documentation.

## Checksums

```text
ad709c25d9942ed8e03b08d0e24ffece20f3161e81587e25b04dad12f287729d  vignettes/function-map-cheatsheet.png
d1533d12e166f74e450f4189805fa9c267e473ef7aa68d5d840390423a4d388d  image2-base.png
8e4c5f1729413dfe9d8feb82c5e6ba19e74e3cb87bd05724c272690f20e132a3  function-map-final-overlay.svg
747a62b5c962180ae0a720a10dd8e680e5260d224d3f242154a76782570cd7a7  rendered-desktop.png
94154d63466faabc9d04a4586aaca1463d91041fb7e07452c80010aaf13902d8  rendered-mobile-390x844.png
```

These are the final synchronized values after the label-size, responsive-table,
and two-destination Get started navigation corrections.
