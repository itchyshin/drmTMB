# After Task: pkgdown Rendered Site Revalidation

## Goal

Validate the rebuilt pkgdown site after the overnight validation notes and the
existing pkgdown/CSS dirty-tree lane.

## Implemented

No source behavior changed. The task rebuilt the local pkgdown site and checked
rendered pages for stale NB2 promotion wording.

## Mathematical Contract

No model changed.

## Files Changed

- `docs/dev-log/after-task/2026-05-24-pkgdown-rendered-site-revalidation.md`
- `docs/dev-log/check-log.md`

The rebuilt `pkgdown-site/` output is generated site output and is not part of
the package source diff.

## Checks Run

```sh
Rscript -e "pkgdown::build_site()"
rg -n 'NB2.*q1.*formal recovery.*(now|passed|complete|closed)|NB2.*q1.*coverage.*(now|passed|complete|closed)|nbinom2_phylo_q1.*promote_narrowly|broad NB2 structured.*(ready|now)|NB2 sigma phylogeny.*now|zero-inflated NB2 phylogeny.*now|count covariance.*now' pkgdown-site -g '*.html'
rg -n '556|578|579|605|hold_smoke_only|NB2 q1 formal|nbinom2_phylo_q1_formal_541_555|ordinary NB2 log-.*sigma.*random intercept|ordinary Poisson/NB2 q=1' pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html pkgdown-site/articles/source-map.html pkgdown-site/articles/implementation-map.html pkgdown-site/articles/count-nbinom2.html -g '*.html'
find docs/dev-log/figure-audits/2026-05-24-home-logo -type f -maxdepth 1 -print -exec file {} \;
git diff --check
```

Results:

- `pkgdown::build_site()` completed.
- The rendered stale-promotion scan returned no hits.
- The rendered positive scan found current NB2 q1, `hold_smoke_only`, ordinary
  NB2 log-`sigma` random-intercept, and ordinary Poisson/NB2 q=1 wording.
- Saved homepage logo screenshots exist at `2048 x 900` and `390 x 844`.
- `git diff --check` was clean.

## Tests Of The Tests

The rendered stale scan checks generated HTML, not only source markdown. The
positive scan confirms that the current bounded-support wording is actually
present in the rebuilt site.

## Consistency Audit

Rendered pages keep fitted support, local formal-admission evidence, and
missing formal recovery separate. No rendered page claims broad NB2 structured
parity, NB2 `sigma` phylogeny, zero-inflated NB2 phylogeny, or q4 count
covariance.

## GitHub Issue Maintenance

No issue mutation was done. This was a local rendered-site validation pass.

## What Did Not Go Smoothly

No callable in-app browser tool was available in this session, so the pass used
generated-site logs, rendered HTML scans, and saved screenshot metadata rather
than live browser inspection.

## Team Learning

When browser tools are unavailable, Grace should say so explicitly and fall
back to generated-site checks rather than implying visual inspection happened.

## Known Limitations

The pass did not visually inspect the rendered site in a browser. The existing
desktop and mobile screenshots remain the local visual evidence for the logo
lane.

## Next Actions

If a browser tool becomes available, open `pkgdown-site/index.html` and inspect
the homepage logo/header spacing directly at desktop and mobile widths.
