# After Task: Large-Data Workflow Article and Benchmark Harness

## Goal

Make the large-data path usable for applied ecology, evolution, and
environmental-science users by adding a short workflow article and an optional
benchmark harness.

## Implemented

- Added `vignettes/large-data.Rmd`.
- Added `bench/large-phylo-location.R`.
- Added the article to `_pkgdown.yml` under Tutorials and to the pkgdown navbar.
- Updated `NEWS.md`, `ROADMAP.md`, `docs/design/23-large-data-memory.md`, and
  `docs/dev-log/known-limitations.md`.
- Added `^bench$` to `.Rbuildignore` so the benchmark is kept out of the R
  source package tarball.

## Mathematical Contract

No likelihood changed. The benchmark uses the existing univariate Gaussian
phylogenetic location model:

```r
y ~ x1 + x2 + phylo(1 | species, tree = tree)
sigma ~ 1
```

and optional variants with `sigma ~ x1` or a factor-heavy `mu` formula. The
article explains that current memory controls reduce fitted-object storage but
do not yet avoid building model frames or dense fixed-effect matrices before
optimization.

## Files Changed

- `.Rbuildignore`
- `bench/large-phylo-location.R`
- `vignettes/large-data.Rmd`
- `_pkgdown.yml`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/23-large-data-memory.md`
- `docs/dev-log/known-limitations.md`

## Checks Run

- `air format bench/large-phylo-location.R`
- `Rscript bench/large-phylo-location.R --rows 200 --species 16 --eval-max 80 --iter-max 80 --memory-light true`
- `Rscript bench/large-phylo-location.R --rows 120 --species 10 --tree star --eval-max 80 --iter-max 80 --memory-light true`
- `Rscript bench/large-phylo-location.R --help | head -n 20`
- temporary CSV-output smoke run with `--factor-heavy true --sigma-x true`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

The final R CMD check completed with 0 errors, 0 warnings, and 0 notes.

## Tests Of The Tests

The benchmark was smoke-tested on two synthetic tree shapes: a balanced
ultrametric tree and a star tree. A CSV-output smoke run exposed a header bug
when writing to an empty `mktemp` file; the script now writes headers when the
output file is absent or empty.

## Consistency Audit

The pkgdown site rendered `articles/large-data.html`, and the navbar includes
"Working with large data". The roadmap now says the initial benchmark harness
exists, while keeping repeated 100k to 5M row benchmark runs as future evidence.
The known limitations page no longer says explicit benchmark scripts are wholly
absent.

## What Did Not Go Smoothly

The first package check reported one note because top-level `bench/` is a
non-standard R package directory. Adding `^bench$` to `.Rbuildignore` resolved
the note without hiding the script from the repository.

## Team Learning

Pat's reader needs a practical page more than another design promise. Rose
should continue checking that "planned" language changes when a partial tool
lands. Grace caught the package-build detail: repository artifacts and package
tarball artifacts are not the same thing.

## Known Limitations

The benchmark reports object sizes and garbage-collector summaries from base R.
It does not report portable peak resident memory; users should use external
tools such as `/usr/bin/time -l` on macOS. The script uses synthetic data and
does not yet include repeated benchmark result files for 100k to 5M rows.

## Next Actions

1. Add a benchmark result template or example CSV with documented columns.
2. Prototype a safe `keep_model_frame = FALSE` fallback map before code.
3. Add a sparse fixed-effect design experiment with dense-versus-sparse parity
   tests on small data.
