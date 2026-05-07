# After Task: First Push and pkgdown Workflow

Date: 2026-05-07

## Task

Push the initial `drmTMB` package work to GitHub, check CI, and make sure the
pkgdown Pages workflow is aligned with the repository layout.

## What Happened

- Committed the first large package slice as:
  `69f11f8 Scaffold drmTMB package and Gaussian MVPs`.
- Pushed `main` to `origin/main`.
- GitHub started `R-CMD-check` and `pkgdown`.
- GitHub `R-CMD-check` succeeded.
- GitHub `pkgdown` failed because `pkgdown::build_site_github_pages()` tried
  to use and clean the default `docs/` destination.

## Diagnosis

This repository intentionally tracks `docs/design/`, `docs/dev-log/`, and
`docs/course/`. The pkgdown destination is `pkgdown-site` in `_pkgdown.yml`.
The workflow therefore should use:

```r
pkgdown::build_site(new_process = FALSE, install = FALSE)
```

not:

```r
pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)
```

The latter ignored the intended source-layout separation and failed safely
before deleting anything.

## Fix

- Updated `.github/workflows/pkgdown.yaml` to call `pkgdown::build_site()`.
- Updated `actions/configure-pages` to `v5`.
- Updated `actions/upload-pages-artifact` to `v4`.

## Checks

- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`

Outcome:

- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully into `pkgdown-site`.

## Consistency

- `_pkgdown.yml` still uses `destination: pkgdown-site`.
- `.gitignore` still ignores generated `pkgdown-site/`.
- `.Rbuildignore` still excludes pkgdown/dev infrastructure from package
  builds.
- The pushed source package remains clean; generated site output is not tracked.

## Remaining Follow-Up

Push the workflow fix and confirm the second GitHub pkgdown run deploys
successfully.
