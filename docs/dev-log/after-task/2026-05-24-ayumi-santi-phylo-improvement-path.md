# After-Task Report: Ayumi and Santi Phylogenetic Improvement Path

Date: 2026-05-24

Reader: Ayumi, Santi, and `drmTMB` contributors deciding what to implement or
validate next for the phylogenetic protocol models.

## Task

Read the three local protocol PDFs and turn them into a clear package
improvement path for the Ayumi and Santi phylogenetic work.

## What Changed

- Added `docs/design/76-ayumi-santi-phylo-model-improvement-path.md`.
- Mapped the avian clutch-size, mammalian litter-size, and passerine
  ecogeographic protocols to current `drmTMB` formula surfaces.
- Separated fitted routes from diagnostic routes and planned routes:
  q2 phylogenetic location models and univariate PLSMs are the immediate
  validation targets; q4 location-scale PLSMs need hardening before showcase;
  lifestyle and nest-habitat covariance contrasts need split-fit sensitivity
  before single-model covariance syntax.

## Protocol Reading Notes

The avian and mammalian life-history protocols share a three-objective ladder:
baseline bivariate phylogenetic location covariance, bivariate phylogenetic
location-scale covariance, and class-specific covariance by nest habitat or
lifestyle. The ecogeographic preregistration makes univariate phylogenetic
location-scale models the primary species-level route, with selected bivariate
PLSMs and family-level slope synthesis as complementary analyses.

## Current Boundary

The current package surface is enough for the next q2 and univariate applied
validation slices. It is not enough to present full q4 PLSMs, class-specific
covariance matrices, partially missing bivariate responses, or Bayesian
posterior tree pooling as routine `drmTMB` features.

## Validation

No R models were fitted for this planning task. Validation was source-reading
and source-map based:

```sh
pdfinfo /Users/z3437171/Desktop/dis_reg_models/Avian_co_scale__protocol_.pdf
pdfinfo /Users/z3437171/Desktop/dis_reg_models/Mammalian_location_co_scale_trade_offs_protocol.pdf
pdfinfo /Users/z3437171/Desktop/dis_reg_models/Pre_registration_for_ecogeographic_rules.pdf
pdftotext -layout /Users/z3437171/Desktop/dis_reg_models/Avian_co_scale__protocol_.pdf tmp/pdf-extract/avian-co-scale.txt
pdftotext -layout /Users/z3437171/Desktop/dis_reg_models/Mammalian_location_co_scale_trade_offs_protocol.pdf tmp/pdf-extract/mammalian-location-co-scale.txt
pdftotext -layout /Users/z3437171/Desktop/dis_reg_models/Pre_registration_for_ecogeographic_rules.pdf tmp/pdf-extract/ecogeographic-prereg.txt
rg -n "Ayumi|Santi|phylo|coscale|location-scale|q=4|rho12" ROADMAP.md docs/design vignettes README.md NEWS.md
```

## Next Step

Start with Phase 0 and Phase 1 from the design note: isolate the current
phylogenetic feature lane, then create a formula gallery/checklist for the
three protocols before running applied q2 Objective 1 fits.
