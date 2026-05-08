# Claude Code Instructions for drmTMB

This repository is shared by humans, Codex, and Claude Code. Read
`AGENTS.md` first; it is the source of truth for project rules.

## Project Identity

`drmTMB` is a sister package to `gllvmTMB`, but it has a different role:

- `drmTMB`: univariate and bivariate distributional regression.
- `gllvmTMB`: higher-dimensional GLLVM and many-response models.

Keep `drmTMB` focused on one or two responses and one formula per estimated
distributional parameter.

## Syntax Rules to Preserve

- Use `sigma`, not `tau`, in the public API.
- Treat meta-analysis as `family = gaussian()` plus `meta_known_V(V = V)`.
- Use `rho12` for bivariate residual correlation. Phylogenetic,
  non-phylogenetic species, spatial, study, site, and other group-level
  correlations should be named as separate covariance summaries, not as
  residual `rho12`.
- Prefer implemented fixed-effect bivariate formulas such as:

```r
bf(
  mu1 = y1 ~ x1 + x2,
  mu2 = y2 ~ x1,
  sigma1 = ~ x1 + x2,
  sigma2 = ~ x1,
  rho12 = ~ x1 + x2
)
```

- Future bivariate random-effect syntax may look like:

```r
bf(
  mu1 = y1 ~ x1 + x2 + (1 | p | id),
  mu2 = y2 ~ x1      + (1 | p | id),
  sigma1 = ~ x1 + x2,
  sigma2 = ~ x1,
  rho12 = ~ x1 + x2
)
```

## Before Finishing Work

- Run the narrow tests you touched, then the broader package checks when
  practical.
- Update design docs if grammar, likelihoods, random effects, families,
  phylogenetic, spatial, or meta-analysis behaviour changes.
- Add or update an after-task report in `docs/dev-log/after-task/`.
- For substantial prose, apply the project-local `prose-style-review` standard:
  name the reader, lead with purpose, use concrete claims, keep terms stable,
  cite factual or literature claims, and explain what users should try next
  when syntax is unsupported.
- Do not revert Codex or human changes unless explicitly asked.

## Reusing gllvmTMB Code

Selective reuse of A-inverse or SPDE speed code may be appropriate later, but
copying code requires provenance notes in `inst/COPYRIGHTS` and tests around
the ported behaviour.
