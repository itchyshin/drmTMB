# Binomial Bridge Map

Slice S041 maps binomial evidence without changing support. The important split
is:

- native TMB fits fixed-effect `stats::binomial(link = "logit")` rows for 0/1
  responses and `cbind(success, failure)` responses;
- non-logit links, `sigma`, random effects, structured effects, bivariate
  responses, malformed encodings, and proportion-plus-weights remain
  unsupported for the native first slice;
- `engine = "julia"` without `phylo()` remains an intentional R bridge error,
  even though direct DRM.jl has Binomial evidence;
- `engine = "julia"` with a Binomial `phylo(1 | group, tree = tree)` term is an
  experimental finite-and-sane bridge route, not native TMB parity.

The dashboard table `binomial-bridge-map.tsv` keeps these rows separate so
native #569 evidence, direct DRM.jl evidence, and R-to-Julia bridge evidence do
not collapse into one "binomial supported by Julia" claim.

## Boundary

This map does not add a binomial bridge route, random effects, structured
effects, q4 support, REML/AI-REML wording, interval coverage, or public
optimizer controls.
