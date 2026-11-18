# Check log: Bernoulli phylogenetic SD interval diagnostics, 2026-10-20

On `codex/general-sd-regression`, with `OPENBLAS_NUM_THREADS=1`, `OMP_NUM_THREADS=1`, and `JULIA_NUM_THREADS=1`:

- `Rscript tools/general-sd-regression/probes/bernoulli-phylo-interval-smoke.R`: 16 tips × 12 observations/tip; profile status `clamp_limited` with NA bounds; two bootstrap refits succeeded and returned finite bounds.
- A deterministic temporary variant used seed `20261021`, 48 tips × 24 observations/tip, and the same simulated phylogenetic logit-SD model. Fit: slope estimate 0.1244214, convergence 0, max absolute gradient `7.610516e-11`, Hessian not positive definite. Profile 95% interval `[-0.1301244, 0.4571525]`, status `profile`, boundary false. Parametric-bootstrap 95% interval from 50/50 successful refits: `[-1.825134, 2.929679]`.
- A first temporary R=50 run ended at a stale post-run assertion expecting two refits. It was rerun with the assertion corrected to 50; the reported successful result is from the corrected run.

**Interpretation boundary:** two designs and one larger-design seed are diagnostics, not coverage evidence. The R=50 interval is conditional on one synthetic dataset, has unstable tail quantiles, and differs greatly from the profile interval. The non-positive-definite Hessian prevents an inference-quality claim even though the profile endpoints are finite.
