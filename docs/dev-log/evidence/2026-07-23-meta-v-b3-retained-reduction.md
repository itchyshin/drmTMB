# `meta_V` B3 retained campaign reduction

This compact, provenance-bearing reduction is copied verbatim in substance from
the authenticated Totoro campaign run at source commit `001ac983` on the stale
`codex/meta-v-b3-contract` branch. It is retained here so Arc 7 B0 can preserve
the negative evidence without importing raw results, shard receipts, seed maps,
launchers, or remote-compute tooling.

The campaign fitted Gaussian ML `bf(yi ~ x + meta_V(V = V), sigma ~ 1)` in 14
cells with 1,200 scheduled fits per cell (16,800 attempts). All fits were `ok`,
converged, and had `pdHess = TRUE`. The primary measure below is the rate of a
finite, truth-covering public Wald interval for `sigma` over all 1,200 attempts.
It is not conditional-on-finite coverage and it does not validate a Wald
heterogeneity interval.

| Cell | K | known `V` | true `sigma` | sampling SD | rho | finite intervals | degenerate `[0, Inf]` | finite-and-covering / all attempts |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 001 | 8 | vector | 0.10 | 0.12 | 0.00 | 703 | 497 | 0.5742 |
| 002 | 12 | vector | 0.10 | 0.12 | 0.00 | 879 | 321 | 0.7200 |
| 003 | 16 | vector | 0.10 | 0.12 | 0.00 | 956 | 244 | 0.7858 |
| 004 | 36 | vector | 0.10 | 0.12 | 0.00 | 1142 | 58 | 0.9308 |
| 005 | 72 | vector | 0.10 | 0.12 | 0.00 | 1198 | 2 | 0.9775 |
| 006 | 12 | vector | 0.10 | 0.22 | 0.00 | 522 | 678 | 0.4117 |
| 007 | 12 | dense | 0.10 | 0.12 | 0.00 | 859 | 341 | 0.7058 |
| 008 | 12 | dense | 0.10 | 0.22 | 0.00 | 533 | 667 | 0.4233 |
| 009 | 12 | dense | 0.10 | 0.12 | 0.25 | 912 | 288 | 0.7500 |
| 010 | 12 | dense | 0.10 | 0.22 | 0.25 | 586 | 614 | 0.4567 |
| 011 | 12 | vector | 0.35 | 0.12 | 0.00 | 1198 | 2 | 0.8900 |
| 012 | 36 | vector | 0.35 | 0.12 | 0.00 | 1200 | 0 | 0.9308 |
| 013 | 12 | dense | 0.35 | 0.12 | 0.25 | 1200 | 0 | 0.9000 |
| 014 | 36 | dense | 0.35 | 0.12 | 0.25 | 1200 | 0 | 0.9167 |

Across the 14 `sigma` cells, 3,712 of 16,800 intervals were
`degenerate_zero_infinite`; the all-attempt finite-and-covering rate ranged
from 0.4117 to 0.9775. The B0 plan reports the deliberately restricted small-K
negative-evidence range, 0.4117--0.8900. Conditional finite-interval set
coverage is retained in the source reduction only as a secondary diagnostic and
cannot replace this denominator.

The historical campaign report is
`docs/dev-log/after-task/2026-07-23-meta-v-b3-campaign.md`. B0 does not rerun,
extend, or promote this campaign.
