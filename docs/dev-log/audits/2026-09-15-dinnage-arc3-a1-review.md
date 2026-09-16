# Independent review: PR #1368, Dinnage Arc 3 Wave A1 docs

Reviewer: Cursor reviewer subagent, independent of the builder
Date: 2026-09-15
PR: https://github.com/itchyshin/drmTMB/pull/1368
PR head reviewed: `c86e86d886d16669286546d80bd4c33e913e2416`
Review branch: `claude/pr1368-a1-rereview-20260915`

## Verdict

ACCEPT-WITH-CHANGES.

The remaining A1 documentation updates claimed at head `c86e86d88` are mostly present and narrow. The PR preserves drmTMB's univariate/bivariate scope, does not touch likelihood code, does not change parameter transforms, and adds a doc-regression test for the A1 help-page caveats. The focused validation passed on the reviewed head:

```sh
Rscript -e 'devtools::test(filter = "dinnage-audit-wave1")'
# PASS 27, WARN 0, FAIL 0, SKIP 0
```

One public help page is still stale: `?mi` says the non-Gaussian response `mi()` route supports only `poisson()`, `binomial()`, `nbinom2()`, and `beta()`, while this PR correctly expands the capability vignette, `?drmTMB`, `?miss_control`, and NEWS to include `lognormal()`, `Gamma(link = "log")`, `student()`, and `beta_binomial()`. That is a documentation/API-consistency gap on the same surface as #1323.

## Findings

### P2: `?mi` still contradicts the expanded `mi()` response-family list

Status: ACCEPT-WITH-CHANGES.

The PR updates the capability table to say non-Gaussian response `mi()` supports `binomial()`, `poisson()`, `nbinom2()`, `beta()`, `lognormal()`, `Gamma(link = "log")`, `student()`, and `beta_binomial()`. The generated `?mi` page, from `R/formula-markers.R`, still lists only the old four families:

- `R/formula-markers.R:36`-`R/formula-markers.R:39`
- `man/mi.Rd:27`-`man/mi.Rd:29`
- expanded table for contrast: `vignettes/capability-and-limits.Rmd:590`-`vignettes/capability-and-limits.Rmd:593`

This does not affect likelihoods or tests, but it leaves a user-facing help page contradicting the newly corrected capability ledger. Update the `mi()` roxygen text and regenerate `man/mi.Rd`.

## Per-issue status

| Issue | Review status | Notes |
| --- | --- | --- |
| #1317 | ACCEPT | `?drmTMB` now documents the native REML `confint()` caveat, including `conf.status = "wald_unavailable"` and `method = "bootstrap"`, with NEWS credit. |
| #1320 | ACCEPT | `?predict.drmTMB` now states that `type = "response"` returns the requested distributional parameter on its response scale, not always `E[Y]`, and points fitted-row means to `fitted()`, with NEWS credit. |
| #1323 | ACCEPT-WITH-CHANGES | The capability vignette and test are correct, and NEWS credits Md-F. The remaining change is the stale `?mi` family list described above. |
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
- Docs/examples: mostly complete, with the one `?mi` inconsistency above.
- Hidden API consistency: one stale public help-page list remains for `mi()`.

No merge was performed.
