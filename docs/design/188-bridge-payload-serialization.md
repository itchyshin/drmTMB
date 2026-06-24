# Bridge Payload Serialization

This note supports S034 of the 100-slice finish run. It records the first
serialization check for the exact-Gaussian location-only bridge draft row.

The machine-readable source is
`docs/dev-log/dashboard/bridge-serialization-status.tsv`.

## Contract

The current tested format is TSV because the R package does not import a JSON
library. The test in `tests/testthat/test-bridge-payload-serialization.R`
round-trips the location-only schema tuple with base R and verifies that a
missing required field is detected.

The tested tuple is:

- `target`
- `estimator`
- `requested_estimator`
- `effective_estimator`
- `r_bridge_status`
- `claim_status`
- `boundary_status_levels`

## Boundary

This is serialization stability for an internal draft row. It does not define a
public payload format, relax a bridge gate, or promote R-via-Julia support.
JSON remains planned until the bridge has a real need for it and a dependency
decision exists.

## Next Action

S035 can use the stable tuple to sketch an R reconstruction object, keeping the
object diagnostic-only until row-specific parity exists.
