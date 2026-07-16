# Beta phylogenetic q1 successor high-information certification

**Status:** `PASS_EXACT_G1024_ONLY`

This prospective 800-fit Totoro campaign ran from the clean pushed head
`da1a2fcc93f32d544b060344ac0f5e680301e2bf` with TMB 1.9.21, 96 workers, and
one BLAS thread per worker. The frozen master seed was `2026071641`. The two
cells were `g = 512, m = 4` and `g = 1024, m = 4`, with 400 independently
seeded attempts per cell. Every seed was unique and disjoint from the original
`m = 2`, earlier `m = 4`, repair smoke, repair pilot, unused repair design, and
successor smoke schedules.

All 800 attempts were retained. Every fit returned convergence code zero,
`pdHess = TRUE`, and finite estimates for all four fixed coefficients and the
latent phylogenetic log-SD. All fixed-effect absolute mean biases were below
`0.012` in both cells and passed the frozen `0.10` gates.

The load-bearing log-latent-SD results were:

| Exact cell | Attempts | Mean bias | MCSE | 95% MC interval | Gate |
| --- | ---: | ---: | ---: | ---: | --- |
| `g = 512, m = 4` | 400 | -0.10129 | 0.01255 | [-0.12589, -0.07668] | HOLD |
| `g = 1024, m = 4` | 400 | -0.04645 | 0.00906 | [-0.06420, -0.02870] | PASS |

The `g = 512` point estimate misses the absolute `0.10` boundary only
numerically narrowly, but its full Monte Carlo interval is not contained in
`[-0.10, 0.10]`; it is therefore a genuine HOLD under the prospective gate.
The `g = 1024` interval lies wholly inside the equivalence band and passes.
RMSE comparisons are descriptive only, as predeclared.

PR 1 may therefore claim `point_fit_recovery` only for the exact tested
`g = 1024, m = 4` regime. This is not evidence for `g >= 1024` or a universal
species-count threshold. The previous `g = 256` HOLDs, this `g = 512` HOLD,
and the inconclusive importance diagnostic remain visible. Family `sigma`
still means the Beta variability parameter with `phi = sigma^(-2)`; it is not
the latent phylogenetic location-effect SD.

The exact command was:

```sh
R_PROFILE_USER=/dev/null OPENBLAS_NUM_THREADS=1 \
  Rscript --no-init-file tools/run-beta-phylo-q1-successor-recovery.R \
  --mode=certification --cores=96 \
  --output=/home/snakagaw/drmtmb_results/2026-07-16-beta-phylo-q1-pr1-successor-certification-da1a2fcc
```

Load-bearing SHA-256 values after exact Totoro-to-local read-back:

```text
73685aed37eda78f7a5fb86cb90e0d6974a54fb1055d11214bdea8b316415b9f  design.tsv
f47002baead58600b91216fc9b2d9490565cfbea4af9fd85ff60b778719b1ff3  fixed-effect-gates.tsv
f7caebb7dde1098c7ac8da53a1fd16cdb94ec7c7a8af6b18a94fc1f74eea03d8  log-tau-equivalence-gates.tsv
2730a17c93453d8ea65aec70257a8f3744fc040d7d31ff92c32174c12db9fc3f  preflight-manifest.tsv
7aa962ccaf4a57546ac69763650371f96b4593fab61bc781f0a3d8d0a2a3443b  promotion-decision.tsv
8588499a60981f68c9030a3525a8225ce47f7fc03a7e0126dae7814d608214ed  quality-gates.tsv
7973ae57bbedd3a78da956f5d19186fcb3a0ab35e870b8a08bc5be431ca3c101  raw-attempts.tsv
7872cdeb569d1f749599437bc4265807e69662db5eb8b80b7b6f708ea7029aa2  rmse-difference.tsv
e4ce0607460d82dfdfa0d8f69753b2eac1e9281dca46f169ab89d291011c5c6d  run-provenance.tsv
365dff9720eeed1dfe6d50ee95d0ffe579257be8072b39e52c068cb8f5dd525a  seed-audit.tsv
38e35ef13a7db07a5266ac6568233d7037a472c4ff11ec4f22c726c6637fa017  session-info.txt
063573f142b5233fc8913a4aa49d117cf114aaf34e88c1dc250f66ec883dbf9f  summary.tsv
```
