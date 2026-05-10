# After Task: pak Install Path

## Goal

Keep the landing-page installation workflow focused on `pak`, matching the
recommended installation path.

## Implemented

- Removed the `remotes::install_github()` fallback block from `README.md`.
- Removed stale "pak or remotes" dependency wording from `README.md`.
- Kept the tagged preview install command:
  `pak::pak("itchyshin/drmTMB@v0.1.0")`.
- Kept the development install command:
  `pak::pak("itchyshin/drmTMB")`.
- Added the same install, toolchain, and dependency guidance to the
  getting-started article.

## Mathematical Contract

No package code changed.

## Files Changed

- `README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-pak-install-path.md`

## Checks Run

- `git diff --check`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `rg -n "install_github|remotes::|pak::pak|install\\.packages\\(\"pak\"\\)" README.md pkgdown-site/index.html docs/dev-log/after-task/2026-05-10-pak-install-path.md docs/dev-log/check-log.md`:
  passed; user-facing install docs now show `pak` only.
- `rg -n "pak or remotes|remotes::install_github|install_github" README.md vignettes/drmTMB.Rmd pkgdown-site/index.html pkgdown-site/articles/drmTMB.html`:
  passed with no matches.
- `rg -n "Install the preview|Core runtime dependencies|install\\.packages\\(\"pak\"\\)|pak::pak" README.md vignettes/drmTMB.Rmd pkgdown-site/index.html pkgdown-site/articles/drmTMB.html`:
  passed and found the expected `pak` installation guidance.

## Known Limitations

Users still need a working compiler toolchain because `drmTMB` uses TMB.
