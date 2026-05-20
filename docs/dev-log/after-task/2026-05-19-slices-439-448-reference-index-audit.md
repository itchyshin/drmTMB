# After-Task Report: Slices 439-448 Reference Index Audit

## Active Perspectives

Ada ran the package-surface audit. Pat read the rendered Reference index as a
new applied user looking for formula syntax. Grace compared exports, pkgdown
reference entries, article sources, and rendered navbar links. Emmy checked
whether S3 and post-fit helpers stayed grouped coherently. Rose watched for
empty or stale rendered sections.

## Goal

Check that exported functions, formula-only marker topics, articles, and
pkgdown reference groups remain discoverable after the phylogenetic fallback
and profile-diagnostic documentation work.

## Implemented

- Removed the empty `Family internals` reference group from `_pkgdown.yml`.
- Confirmed all 32 exported functions have literal coverage in `_pkgdown.yml`.
- Confirmed all 20 article entries have matching vignette sources.
- Confirmed all 20 navbar article links have rendered targets in
  `pkgdown-site/`.
- Rebuilt the local pkgdown site and checked that the Reference index no longer
  contains the empty `Family internals` heading.

## Evidence

The rendered Reference index still exposes the formula-marker aliases a user is
likely to search for: `sd`, `sd1`, `sd2`, `sd_phylo`, `sd_phylo1`,
`sd_phylo2`, `animal()`, `phylo()`, `spatial()`, `relmat()`, and `corpair()`.
The empty `Family internals` section was a pkgdown-only navigation paper cut,
not a missing exported function or missing Rd topic.

## Checks Run

```sh
Rscript -e "pkgdown::check_pkgdown()"
Rscript - <<'EOF'
exports <- sub('^export\\((.*)\\)$', '\\1', grep('^export\\(', readLines('NAMESPACE'), value = TRUE))
yml <- readLines('_pkgdown.yml')
missing <- exports[!vapply(exports, function(x) any(grepl(paste0('(^|[^[:alnum:]_.])', gsub('([.|()\\\\+*?{}\\[\\]^$])', '\\\\\\1', x), '([^[:alnum:]_.]|$)'), yml)), logical(1))]
cat('Exports:', length(exports), '\n')
cat('Missing literal _pkgdown.yml refs:', if (length(missing)) paste(missing, collapse = ', ') else 'none', '\n')
EOF
Rscript -e "pkgdown::build_site()"
rg -n "Family internals|Reserved marker internals|Structured-effect markers|random_effect_scale_formulas|sd_phylo|corpair|Model fitting and post-fit tools|Visualization" pkgdown-site/reference/index.html --glob '!pkgdown-site/search.json'
Rscript - <<'EOF'
y <- yaml::read_yaml('_pkgdown.yml')
article_names <- unlist(lapply(y$articles, function(section) section$contents), use.names = FALSE)
missing_articles <- paste0('vignettes/', article_names, '.Rmd')[!file.exists(paste0('vignettes/', article_names, '.Rmd'))]
hrefs <- unlist(lapply(y$navbar$components, function(component) {
  menu <- component$menu
  if (is.null(menu)) character() else vapply(menu, function(x) if (is.null(x$href)) NA_character_ else x$href, character(1))
}), use.names = FALSE)
hrefs <- hrefs[!is.na(hrefs)]
missing_hrefs <- hrefs[!file.exists(file.path('pkgdown-site', hrefs))]
cat('article entries:', length(article_names), '\n')
cat('missing vignette sources:', if (length(missing_articles)) paste(missing_articles, collapse = ', ') else 'none', '\n')
cat('navbar hrefs:', length(hrefs), '\n')
cat('missing rendered hrefs:', if (length(missing_hrefs)) paste(missing_hrefs, collapse = ', ') else 'none', '\n')
EOF
git diff --check
```

## Validation Notes

- `pkgdown::check_pkgdown()` reported no problems.
- The export audit reported `Exports: 32` and no missing literal
  `_pkgdown.yml` references.
- The article/navbar audit reported 20 article entries, no missing vignette
  sources, 20 navbar hrefs, and no missing rendered hrefs.
- The rendered Reference scan found structured-effect aliases and post-fit
  sections, and did not find the removed `Family internals` heading.
- `git diff --check` reported no whitespace problems.

## Known Limitations

This was a navigation audit only. It did not inspect every Rd page for prose
quality or every example for copy-run behaviour.

## Next Actions

Continue with a function-by-function reference prose audit, prioritizing pages
whose examples mention planned syntax or advanced covariance layers.
