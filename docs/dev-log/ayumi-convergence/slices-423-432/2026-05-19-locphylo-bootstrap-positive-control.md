# Slice 423-432: Locphylo Bootstrap Positive Control

Reader: `drmTMB` contributors deciding which Ayumi Mass + Beak model should be
used as the clean example while q4 fallback models remain diagnostic.

## Question

Slices 413-422 showed that the block-diagonal phylogenetic fallback is not a
usable uncertainty target yet: the bounded profile failed, all bootstrap refits
false-converged, and a simpler scale formula did not solve the boundary. Ada
therefore reran the same bootstrap diagnostic on the clean q2 location-only
phylogenetic model, `PV2_locphylo`.

## Result

The clean model fit from slices 391-402 had convergence 0 and `pdHess = TRUE`
on all 6,196 species. The matching 10-core bootstrap diagnostic used the same
script, seed, worker cap, and optimizer budget as the fallback run.

| quantity | `PV2_locphylo` | block fallback |
| --- | ---: | ---: |
| refits returned | 10 | 10 |
| convergence code 0 | 10 | 0 |
| convergence code 1 | 0 | 10 |
| median max gradient | 0.043 | 37.45 |
| max gradient | 0.121 | 75.30 |
| mean residual `rho12` | -0.802 | -0.746 |
| mean phylogenetic `mu1`-`mu2` | -0.884 | -0.824 |
| mean Beak-on-Mass coefficient | 2.100 | 1.807 |

The clean-model bootstrap completed in 117.7 seconds. All optimizer messages
were `relative convergence (4)`, and there were no warning rows in
`bootstrap-conditions.csv`.

Artifacts:

- `docs/dev-log/ayumi-convergence/slices-423-432/mass-beak-locphylo-bootstrap-diagnostics/`

## Interpretation

This run is the positive control for the bootstrap machinery. The same refit
code that exposes the fallback as boundary-selected and false-converged behaves
well for the location-only phylogenetic model. That supports a clear reporting
split:

- `PV2_locphylo` is the clean Mass + Beak demonstration model and a reasonable
  bootstrap uncertainty target after more replicates.
- `PV2_phylo_fallback` and full q4 PV2-main remain diagnostic stress cases until
  convergence, gradients, and boundary behavior improve.

The bootstrap prototype should therefore stay developer-only, but it now has
both a failure-control and a positive-control example.
