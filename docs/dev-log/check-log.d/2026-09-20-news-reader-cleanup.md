# 2026-09-20: NEWS reader-language cleanup

Bounded documentation repair: 16 heading-defined NEWS sections changed, including all 13 artifact-lane paragraphs and eleven native Arc-labelled headings. Native model limits and historical evidence caveats retained; no Julia bridge content changed.

PASS: `git diff --check`; `pkgdown::build_news()`; regenerated NEWS against the existing checker process patterns; browser inspection of the Bernoulli and initial Student-t sections. Exhaustive broader source scan: 344 to 305 matching lines, with exact pattern counts and section ranges in `after-task/2026-09-20-news-reader-cleanup.md`.

NOT A FULL SITE PASS: the public reader checker stops on inherited private pages in the copied local site snapshot. No fresh full-site build, model test, merge, or deployment is claimed. Historical NEWS cleanup remains a measured backlog.
