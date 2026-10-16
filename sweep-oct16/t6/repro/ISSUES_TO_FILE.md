# Issue / comment drafts that GitHub 403 blocked

This agent could not POST issues or comments (`403 Resource not accessible
by personal access token` on the GitHub MCP; `gh` is read-only for this
cloud run; Composio GitHub has no active connection). Drafts live here so
they can be posted as soon as write access is available. Findings are also
in `RECEIPT_t6.md`.

Do not invent issue numbers. Post these, then record the real URLs.

## Comments on existing issues (do not re-file)

| Target | Draft | One line |
| --- | --- | --- |
| itchyshin/drmTMB#1536 | `F-1536-simulate-newdata-se.fit.md` | Confirmed on every t6 cell: `simulate(newdata=)` returns 80 training rows; `predict(se.fit=TRUE)` ignored |
| itchyshin/drmTMB#1320 | `COMMENT_1320.md` | Lognormal `type="response"` is still log-Y μ; Julia twin returns `exp(η)` (max_abs 1.046) |
| itchyshin/DRModels.jl#1092 | `COMMENT_1092.md` | RE newdata is invlink(Xβ), matches drmTMB; docs still say integrated out |
| itchyshin/DRModels.jl#1000 | `COMMENT_1000.md` | Univariate non-Gaussian predict also refuses a subset of fitted factor levels |

## New issues to open (no match found)

| Repo | Draft | One line |
| --- | --- | --- |
| itchyshin/DRModels.jl | `ISSUE_predict_invlinks.md` | `_param_response` wrong invlink: Student ν=exp(η) not 2+exp; SkewNormal ν=exp; ZeroOneBeta μ=η; LogNormal μ=exp vs drmTMB identity |
| itchyshin/DRModels.jl | `ISSUE_simulate_newdata.md` | `simulate(fit; nsim, rng)` has no newdata (twin of drmTMB #1536) |
| itchyshin/DRModels.jl | `ISSUE_lognormal_marginal.md` | LogNormal `drm()` has no `marginal=` (Poisson/Gamma/NB2/Binomial/Beta/Student do) |

## Not filed (harness / MC / known)

- R `se.fit` / `simulate(newdata)` → #1536 only.
- Barely-over-3 MCSE on one of 80 rows (beta, gamma, poisson, nbinom2, lognormal, tweedie): max-of-80 z-scores / Gaussian MCSE for kurtotic families. Student-t FE `ν̂=2.48` variance z=23 is the same MCSE formula at near-infinite variance, not a simulate bug.
- nbinom2_re R vs Julia ~5e-8 (bar 1e-8): Laplace/optimizer near-miss, not filed.
- Julia lognormal simulate max_z~60: harness compared Y-scale draws to a moment that may not match `fit.means[:mu]` scale; not filed until a standalone re-check.
- Julia `char_vs_factor` harness used a 2-level subset; the real R char-vs-factor cell passed (max_abs=0). The subset refusal is the #1000 comment, not a new issue.
