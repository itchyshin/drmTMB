# After-task: convergence honesty (#1857, #1875)

**Reader:** Shinichi and reviewers checking whether failed fits stop looking usable for model comparison.

**Outcome:** Under the unchanged twin thresholds in `docs/design/278-twin-convergence-status.md`, student() all-zero with `se = FALSE` now returns `convergence_status() = "degenerate"`. Residual `sigma` on the lower clamp classifies as `boundary` when the fit is not already degenerate (Gaussian constant-`y` stays `converged`). `logLik()`, `AIC()`, and `BIC()` warn with class `drmTMB_ic_convergence_warning` when status is not `"converged"` but still return finite values. `confint()` tables warn on infinite endpoints via `drmTMB_confint_infinite_endpoint_warning`.

**Evidence:** `docs/dev-log/check-log.d/2026-11-26-convergence-honesty-1857-1875.md`.