# Bridge Reconstruction Status

This note supports S035 of the 100-slice finish run. It adds an internal R
status object for reconstructed Julia bridge fits without promoting bridge
inference.

The machine-readable source is
`docs/dev-log/dashboard/bridge-reconstruction-status.tsv`.

## Implemented Boundary

`drm_julia_reconstruction_status()` is internal. It accepts a `drmTMB_julia`
object and returns one diagnostic row with:

- model type;
- requested and effective estimator;
- payload status;
- coefficient status;
- fixed-effect covariance status;
- profile-target status;
- corpair status;
- bridge status;
- inference-promotion status.

The first covered test uses a synthetic Gaussian bridge fit. It reports finite
fixed-effect covariance and profile-target inventory, but intentionally keeps
`payload_status = "missing"` and `inference_promotion = "none"` so missing
reconstruction pieces stay visible.

## Not Implemented

The exact-Gaussian location-only bridge reconstruction object remains planned.
S035 does not add R-via-Julia fitting, public bridge inference, or interval
coverage.

## Next Action

S036 should keep Julia-home CI smoke checks separate from this reconstruction
status object.
