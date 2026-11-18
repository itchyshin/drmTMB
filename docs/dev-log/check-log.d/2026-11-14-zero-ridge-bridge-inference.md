# Julia-engine zero-ridge inference replay

The R fixed-effect inference shim now decodes unversioned fixed-prior records and verifies the resolved targets before reconstructing a Julia fit. The prior-free route retains its existing path. Versioned SD-prior inference is refused.

The defect reproduced on the earlier two-intercept foundation for both profile and bootstrap intervals. The live test on the revised R and Julia sources passed 50 assertions with no test warnings or skips. It checks zero-ridge table and constructor fits, no-prior fits, profile and seeded three-replicate bootstrap intervals, target metadata, missing and mismatched expected records, versioned SD-prior refusals and active-prior guards. Source and test fingerprints matched before and after. Elapsed-time metadata is excluded from interval comparisons. The three-replicate bootstrap is a route check, not an interval-coverage study.

The prior full-package check was run before this source change. Full regression on the revised source remains open. No merge or release follows from the focused result.

A separate isolated test against Julia commit `dd0d984b`, which predates the SD-prior protocol helpers, passed eight fixed-only Gaussian checks for profile, bootstrap, target validation and refusals. It used Julia 1.10.12, a copied TMB library and a three-replicate bootstrap. This is one compatibility example and does not establish support for every older backend.
