# pkgdown reader-surface audit epoch receipt

**Date:** 2026-07-21  
**Audit worktree:** `/private/tmp/drmtmb-site-audit-83d48549`  
**Branch:** `codex/site-audit-capability-limits-20260721`  
**Mode:** audit and repair one Codex-owned page at a time; stop for P1 findings,
claim-boundary changes, or material design decisions.

## Immutable inputs

| Surface | Identifier |
| --- | --- |
| `origin/main` | `83d48549e8925a97aa2c156941a97a9bf9b785c4` |
| `vignettes/capability-and-limits.Rmd` | `16bf769336e2bfa0d878e04711da672b30f504f1` |
| 0.6 release-scope manifest | `bcf72263d342d5540feae2f1b9612049f2bc74ff` |
| `_pkgdown.yml` | `e00be3f93eb7283216aae179209386040060000e` |

## Scope and ownership

Codex owns the homepage, 32 authored articles, 68 Rd topics covering 51 exports,
two legacy article routes, and navigation/search surfaces. `bivariate-coscale` is
Shinichi-owned and is excluded from Codex review and repair. This is a
reader-surface programme: it cannot make a CRAN, platform, deployment, or
capability-promotion claim.

## Inventory baseline

- 33 vignette sources; 32 Codex-owned articles plus the owner-held
  `bivariate-coscale` article.
- 68 Rd topics, 98 generated reference URLs, and 51 exported functions.
- Historical reader audits are leads only. Every finding must be checked against
  this audit epoch's source and claim-ceiling blobs.

## Claim-ceiling correction already detected

The current manifest says that `rho12 ~ x` has row-specific profile and Wald
intervals when `newdata` is supplied, but has no coverage certification. Any source
wording saying that regression-parameterised `rho12` has *no interval* is a P1
manifest conflict, not a licence to remove the interval route.
