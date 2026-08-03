# Spatial q2 Confidence Eye calibration evidence

This directory records the prospective Fir calibration campaign for the three
direct fixed-kappa Gaussian q2 spatial covariance targets:
`sd_spatial1`, `sd_spatial2`, and latent `rho_spatial`.

The campaign retained every attempted dataset. It completed 500 datasets at
each preregistered rung: L = 12 sites x 3 observations, M = 36 x 3, and
H = 36 x 8. This yielded 1,500 completed fits and 4,500 target outcomes.
Intervals are 95% endpoint profile-likelihood intervals; Wald intervals are
diagnostic only and no bootstrap result rescues a failed profile target.

## Decision

The joint gate passes at M and H and fails at L. M is therefore the lowest
tested jointly passing rung. The exact all-attempt results are:

| Rung | Target | Coverage | Finite-profile rate | Verdict |
| --- | --- | ---: | ---: | --- |
| L | `sd_spatial1` | 0.932 | 0.968 | PASS |
| L | `sd_spatial2` | 0.920 | 0.958 | FAIL |
| L | `rho_spatial` | 0.774 | 0.808 | FAIL |
| M | `sd_spatial1` | 0.938 | 1.000 | PASS |
| M | `sd_spatial2` | 0.932 | 1.000 | PASS |
| M | `rho_spatial` | 0.938 | 0.986 | PASS |
| H | `sd_spatial1` | 0.962 | 1.000 | PASS |
| H | `sd_spatial2` | 0.946 | 1.000 | PASS |
| H | `rho_spatial` | 0.940 | 1.000 | PASS |

The earned claim is limited to the exact M and H configurations under the
baseline ring geometry and fixed-kappa bivariate-Gaussian REML estimand. It
does not cover the failed L rung, mesh intervals, range estimation, spatial
slopes, q4+, non-Gaussian families, spatial sigma models, derived observed
correlations, other geometries, or the `supported` tier.

## Provenance

- Immutable source commit: `9e6804deb48436b328a41cf6dffe1eb007a3cb88`
- Full packet digest: `ace841f7054abcfff6c6ae3be935b6c6bc62b82830bbe314d579093b1cb3281a`
- Source archive SHA-256: `be72034c0ef3e50ba0483388ecea3c61a7d0eeb52de46e1c03f223510b7accab`
- Smoke packet digest: `f0b558f6c56b4818967a23788a42eeb66a57cd1ec3f70d8ee46a499304c40d66`
- Fir jobs: setup `52570123`, array `52570124`, corrected closeout `52574025`
- Fir keeper: `/project/def-snakagaw/snakagaw/drmtmb-confidence-eye/runs/spatial-q2-confidence-eye-full-ace841f7`
- Local source archive keeper: `/private/tmp/drmtmb-ce-source-9e6804deb-be72034c.tar.gz`

`resource-actual-pre-tz-fix.tsv` preserves the original zero-wall receipt.
`resource-actual.tsv` is the corrected receipt produced by the committed exact
UTC timestamp parser. The corrected wall time is 0.2063889 hours; task CPU is
3.09944 hours and maximum recorded RSS is 3.365 GB including setup.

## Review

Noether and Fisher approved the symbolic estimand and prospective gate before
compute. Grace approved both smoke and full launch packets. After completion,
the same Noether/Fisher/Rose D43 panel reached 3/3 PROMOTE following remediation
of provenance packaging, timestamp parsing, and the exact M/H claim boundary.
`packet-review-receipts.tsv` records those review receipts.
