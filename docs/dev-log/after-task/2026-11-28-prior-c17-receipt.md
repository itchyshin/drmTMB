# Prior-table current-source compatibility receipt

The prior-table change modified `R/drmTMB.R`, making the earlier model-15
compatibility receipt stale under the source-blob check. The model-15 surface
fingerprint was unchanged.

The committed runner was executed on an isolated checkout of source
`af8497db47d574b86488f7959168e318271a11bb`. All 12 retained attempts passed
the original criteria. Mean relative errors for the three cells were
0.0990031773, 0.1660774673, and 0.0613049352; the previous results agreed
within 4e-11. The raw attempts, provenance, and summary are preserved with the
updated manifest. No thresholds or model-15 fingerprint were changed.

The run used a compiled library from the prior candidate with identical
production source. This receipt is limited to the three named compatibility
cells; it does not establish broader parameter recovery.
