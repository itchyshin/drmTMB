# Julia current-route documentation surface

| Check | Result | Evidence |
|---|---|---|
| R source parses | pass | `Rscript -e 'parse("R/julia-bridge.R")'` |
| Generated Julia help renders | pass | `tools::Rd2txt()` for `confint.drmTMB_julia.Rd` and `summary.drmTMB_julia.Rd` |
| Roxygen outputs refreshed | pass | `devtools::document(quiet = TRUE)` |
| Intended diff is whitespace-clean | pass | `git diff --check` |
| Generic stale wording scan | pass | no generic `halted/deferred`, `future/deferred`, or legacy current-route wording remains in the touched surfaces; retained cross-family legacy notices are scope-specific |

The documentation describes `engine = "julia"` as optional and current only for documented admitted cells. It explicitly retains native TMB as the route for unsupported models, controls, and inference paths; it makes no universal parity, profile, bootstrap, or performance claim.
