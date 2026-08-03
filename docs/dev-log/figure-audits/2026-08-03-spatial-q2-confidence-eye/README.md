# Confidence Eye visual audit

## Artifact

`confidence-eye.png` is the figure rendered from
`vignettes/spatial-models.Rmd` with the live source namespace on 2026-08-03.
The complete article rendered successfully before this review.

## Contract check

| Check | Result |
| --- | --- |
| Three direct fixed-kappa Gaussian q2 targets | PASS |
| Pale 95% endpoint profile regions | PASS |
| Hollow estimate circles | PASS |
| No filled points, horizontal CI bars, or row guides | PASS |
| Dotted zero reference only for the correlation target | PASS |
| Separate facet scales for SD and correlation | PASS |
| Exact M rung and baseline ring geometry named | PASS |
| M/H pass and L fail named | PASS |
| Broader spatial and `supported` claims withheld | PASS |
| Readability and monochrome accessibility | PASS |

## Visual verdicts

**FLORENCE_VISUAL_FINAL = APPROVE**

**PUFF_VISUAL_FINAL = APPROVE**

The first two rendered versions were superseded after user review. The first
used full-panel pale rectangles whose interval width disappeared; the next
added a horizontal CI line through each eye, contrary to the trademark visual
grammar. Both earlier Florence approvals were withdrawn.

The final bitmap was supplied directly, alongside the established animal,
phylogenetic, and relmat pkgdown exemplars, to Florence and an independent
second visual reviewer acting as Puff. Both confirmed pale coloured tapered
eyes, prominent hollow estimate circles, no horizontal CI bars or row guides,
a meaningful dotted zero reference only for latent correlation, readable
scales, and no crowding or clipping.
