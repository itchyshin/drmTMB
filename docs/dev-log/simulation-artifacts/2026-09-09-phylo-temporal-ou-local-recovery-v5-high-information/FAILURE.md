# Incomplete high-information recovery run

This directory preserves a runner failure after the 80-species fit loop: the
provenance writer referenced `n_species` outside its local fixture scope. No
criterion or results table was written, so this directory is not evidence about
model recovery. The repaired run is retained separately in the sibling
`...-v6-high-information/` directory with the same seeds and thresholds.
