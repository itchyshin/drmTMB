# Independent review: PR #1368, Dinnage Arc 3 Wave A1 docs

Reviewer: Cursor reviewer subagent, independent of the builder
Date: 2026-09-15
PR: https://github.com/itchyshin/drmTMB/pull/1368
PR head reviewed: `08a15a7928d6eedae6eafdd6b6ac43ca896f3ac6`
Review branch: `claude/pr1368-a1-rereview-20260915`

## Verdict

ACCEPT.

The PR now closes the remaining A1 documentation issue found at `c86e86d88`. Commit `08a15a792` updates the `mi()` roxygen source and regenerated `man/mi.Rd`; both now list the expanded non-Gaussian response `mi()` family set: `poisson()`, `binomial()`, `nbinom2()`, `beta()`, `lognormal()`, `Gamma(link = "log")`, `student()`, and `beta_binomial()`.

The PR preserves drmTMB's univariate/bivariate scope, does not touch likelihood code, does not change parameter transforms, and keeps the existing doc-regression coverage passing on the reviewed head:

```sh
Rscript -e 'devtools::test(filter = "dinnage-audit-wave1")'
# PASS 27, WARN 0, FAIL 0, SKIP 0
```

One separate coordination note remains: the C17 receipt refresh for the `mc-0568` / `R/drmTMB.R` CI failure is not committed on the PR tip. At `08a15a792`, the relevant diff against `origin/main` still shows `R/drmTMB.R`, `R/formula-markers.R`, and `man/mi.Rd`, with no committed C17 receipt or capability-ledger refresh artifact. That is not an A1 `mi()` documentation blocker, but it matters for the failing source-tree/receipt CI path.

## Findings

No remaining P0, P1, P2, or P3 review findings for the A1 documentation slice.

The prior P2 is resolved:

- `R/formula-markers.R` now documents the expanded response-family list in the `mi()` roxygen.
- `man/mi.Rd` matches the roxygen output and includes the same expanded response-family list.

## Per-issue status

| Issue | Review status | Notes |
| --- | --- | --- |
| #1317 | ACCEPT | `?drmTMB` now documents the native REML `confint()` caveat, including `conf.status = "wald_unavailable"` and `method = "bootstrap"`, with NEWS credit. |
| #1320 | ACCEPT | `?predict.drmTMB` now states that `type = "response"` returns the requested distributional parameter on its response scale, not always `E[Y]`, and points fitted-row means to `fitted()`, with NEWS credit. |
| #1323 | ACCEPT | The capability vignette, test, NEWS credit, `?mi`, and `man/mi.Rd` now agree on the expanded response `mi()` family list. |
| #1334 | ACCEPT | `meta_V()` and the compatibility alias document positional matching and no dimname reordering, with NEWS credit. |
| #1341 | ACCEPT | `?summary.drmTMB` mentions optional `emmeans`; `?residuals.drmTMB` includes a guarded `DHARMa::createDHARMa()` plus `simulate()` example, with NEWS credit. |
| #1344 | ACCEPT for A1-owned branch-length wording | `?phylo` now says drmTMB uses the supplied ultrametric branch-length scale and does not silently rescale to unit height. The full #1344 extra-tip pruning note/test remains a separate non-A1 acceptance item unless the maintainer decides this PR should close the whole issue. |
| #1345 | ACCEPT | `cumulative_logit()` documents integer-coded ordinal responses as accepted at face value and recommends ordered factors when labels carry the scientific order, with NEWS credit. |
| #1346 | ACCEPT | `?residuals.drmTMB` now documents Pearson-residual conventions for `student()`, `skew_normal()`, and `beta()`, with NEWS credit. |
| #1349 | ACCEPT | `student()` no longer makes the false uniqueness claim about public `sigma`, and NEWS credits Mi-11. |
| #1354 | ACCEPT | `?sigma.drmTMB` now states that row-varying scale formulas return one fitted scale value per observation and warns that scalar-generic tools can summarize this away, with NEWS credit. |
| #1359 | ACCEPT | `?confint.drmTMB` documents fully qualified returned `parm` labels and the compact-label join hazard, with NEWS credit. |

## Reviewer checklist

- Scope: preserved. No higher-dimensional DRM, new family, or new public syntax introduced.
- Likelihood coherence: not affected. No likelihood implementation changed in this PR.
- Parameter transforms: not affected. No transform code changed in this PR.
- Simulation tests: not required for this documentation-only slice. The requested doc-regression coverage passed.
- Docs/examples: complete for the A1 slice reviewed here.
- Hidden API consistency: no remaining inconsistency found for `mi()` family documentation.

No merge was performed.
