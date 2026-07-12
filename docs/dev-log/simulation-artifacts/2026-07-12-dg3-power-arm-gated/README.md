# DG3 power-arm — gated campaign (2026-07-12)

Release-grade evidence for the distributional-output/adequacy layer's criterion 3
(#747/#748). The reusable harness is `inst/dg3-power-arm/harness.R` +
`inst/dg3-power-arm/families.R`; the drivers here call it.

**Tracked (verifiable):**
- `summary-gated-full.tsv` — the aggregated power table (family × arm × mis-spec ×
  n × type-I × power × MCSE) that every doc cites.
- `run-gated-shard.R` — 17-family, 400-seed campaign (4 parallel shards).
- `run-nladder-shard.R` — n ∈ {1000, 3000} reruns for the mechanism mis-specs.
- `run-tweedie-capped.R` — tweedie with a tight optimizer budget (completed 99/400
  seeds locally; 66/99 dispersion-arm non-convergence — full 400 deferred to Totoro).
- `mechanism-inspection-*.R` — direct before/after nuisance-parameter checks.

**Untracked (regenerable, `.gitignore`d):** the per-cell `<family>.tsv` raw
streams (~5.7M) and heartbeat `.log` files — rerun the drivers to regenerate.

**Headline results:** shape/atom mis-specs detect at power ≥ 0.8 (400 seeds; the
KS+PIT statistic is conservative, so power is understated). Nuisance-absorbable
mis-specs are undetectable: hurdle and zero-one-inflation *mechanism* mis-specs
stay flat at the type-I rate through n=3000 (structural blind spot), while the
zi_poisson/zi_nbinom2 mechanism mis-specs rise only weakly with n (to ~0.06/0.11
at n=3000 — sample-size-limited but far below detectable). gamma-vs-lognormal is
the one cleanly sample-size-limited case (0.19→0.79→1.0 at n=300/1000/3000).
