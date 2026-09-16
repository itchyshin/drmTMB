# 276 — Phylogenetic small-sample bias correction: what should `g` count?

**Status:** draft / not implemented (design question only).

**Reader:** maintainers working Wave B structured-RE intervals and anyone
interpreting default `confint()` rows on `phylo()` / `animal()` / `relmat()`
location-axis SD targets.

## Purpose

Russell Dinnage's evaluation (Md-J, issue [#1327](https://github.com/itchyshin/drmTMB/issues/1327))
flags two separable points. Discoverability (`conf.status` should record when
the default centre shift ran) is a small API fix. This note holds only the
**functional** question: for a phylogenetic (or other structured) variance
component, what denominator `g` should drive the small-sample centre shift
`log(g / (g - 1))` and the between-group t width `df = g - 1`?

Current behaviour is documented in
[`docs/design/219-structured-re-small-sample-bias-correction.md`](219-structured-re-small-sample-bias-correction.md):
`g` is `length(phylo_mu$group_levels)`, i.e. the number of tip / group labels
in the fitted random-effect field. That matches ordinary `(1 | group)` counting
but is **not** the effective number of independent evolutionary units implied
by a correlated phylogenetic random effect.

## The g-question (only)

When the focal target is a structured SD on the location axis (`mu`, `mu1`,
`mu2`), should `g` remain:

1. **Tip / level count** (status quo): one degree per labelled unit in the
   RE field, independent of correlation structure.
2. **Effective independent units**: a function of the phylogenetic (or
   kernel) correlation matrix that reflects how many independent pieces of
   information the likelihood actually has for that variance component
   (analogous in spirit to effective sample size or trace-based summaries,
   but tied to the interval recipe in design 219).
3. **Route-specific defaults**: tip count for ordinary `(1 | group)`, a
   structured definition for `phylo()` / `animal()` / `relmat()` / `spatial()`,
   with explicit opt-out via existing `bias_correct` / `small_sample_df`
   controls.

Secondary questions (out of scope for this stub; do not implement here):

- Whether the same `g` should feed **both** the centre shift and the t
  quantile, or whether width and centre need different effective counts.
- Whether `heritability()` / `icc()` / `repeatability()` denominators
  (design [`259-heritability-icc-repeatability.md`](259-heritability-icc-repeatability.md))
  should eventually align with whatever `g` wins for intervals.

## Related tracking

| Item | Role |
| --- | --- |
| [#1327](https://github.com/itchyshin/drmTMB/issues/1327) | Md-J: discoverability + raises the phylo `g` concern |
| [219-structured-re-small-sample-bias-correction.md](219-structured-re-small-sample-bias-correction.md) | Implemented default interval recipe using tip-level `g` |
| [#1332](https://github.com/itchyshin/drmTMB/issues/1332) | Unrelated Dinnage item (missing-predictor `miss_control`); listed only because Wave B briefs sometimes cite nearby audit IDs |

## Acceptance for a future implementation slice

- [ ] Written decision on (1)–(3) with at least one simulation or parity
      check on a small-tree vs large-tree phylo SD cell showing coverage
      impact of changing `g`.
- [ ] User-facing prose states which count `g` uses for each structured
      provider, or documents that tip count remains intentional.
- [ ] Tests and NEWS only after code changes; this file stays the design
      anchor until then.
