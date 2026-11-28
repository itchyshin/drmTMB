2026-11-22: prior bridge news correction.

The generalized-prior news bullet said the Julia bridge still refused the new
residual-SD and correlation target classes pending a matching contract. The
current `R/julia-bridge.R` contains v5 contract generation and result checks
for selected residual-SD and correlation compositions, while retaining
explicit refusals for unsupported combinations. Updated the news bullet to
describe that partial support. This was a static source review; no tests or
bridge code were changed. `slop_check.py` reported zero findings for both
the news bullet and this entry.
