# After-task: Julia profile bridge parity

Date: 2026-06-09

## Summary

The Julia-engine bridge now admits profile likelihood intervals for the first
Gaussian phylogenetic SD target:
`sd:mu:phylo(1 | species)` with `sigma ~ 1`.

The previous R-side profile guard was correct when the generic DRM.jl sparse
profile returned a mismatched lower endpoint. The DRM.jl side now uses a
specialized sparse location-only profile route for this cell, and the R bridge
keeps the narrow target validation while allowing `method = "profile"`.

## Evidence

Focused checks passed:

- R bridge test: `tests/testthat/test-julia-bridge.R`, 71 expectations.
- DRM.jl bridge test: `test/test_bridge.jl`, 46 expectations.
- DRM.jl sparse phylo test: `test/test_conjugate_em.jl`, 34 expectations.
- DRM.jl profile CI focused tests: `test/test_profile_ci.jl`.

The live AVONET/Hackett 1,000-species parity probe compared the native R
endpoint profile with the Julia bridge profile primitive:

| engine | lower | upper |
| --- | ---: | ---: |
| R native profile | 1.162186 | 1.350848 |
| Julia bridge profile | 1.162188 | 1.350846 |

The refreshed public benchmark recorded:

| route | elapsed s | lower | upper |
| --- | ---: | ---: | ---: |
| R native profile serial | 13.357 | 1.162186 | 1.350848 |
| R native profile multicore | 7.611 | 1.162186 | 1.350848 |
| Julia public profile serial | 2.548 | 1.162188 | 1.350846 |
| Julia public profile threaded | 1.126 | 1.162188 | 1.350846 |

The article preview was regenerated at
`/tmp/drmtmb-julia-engine-preview/julia-engine.html` with compact profile and
bootstrap tables.

## Scope

This admits one profile target only. Fixed-effect profile/bootstrap intervals,
non-Gaussian families, phylogenetic scale models, multiple structured terms,
and neighbouring formula syntax still need separate target maps and parity
tests before the R bridge should expose them.
