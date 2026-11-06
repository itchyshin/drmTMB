## 2026-10-23: Julia Binomial related-matrix simulation oracle

The Julia Binomial relmat SD test now uses a labelled non-reversal-invariant
covariance with a non-unit diagonal and checks a seeded response draw against
an independent reconstruction from the fitted link predictor, predicted group
SDs, and group-aligned covariance. `devtools::test(filter =
"julia-binomial-relmat-sd-parity", reporter = "summary")` passed with one live
Julia bridge fit. JuliaCall reported its known non-fatal extension/dependency
warning. See `docs/dev-log/after-task/2026-10-23-julia-binomial-relmat-sd-simulation-oracle.md`.
