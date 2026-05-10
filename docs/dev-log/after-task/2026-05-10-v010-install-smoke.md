# After Task: Version 0.1.0 Installation Smoke Test

## Goal

Check whether a new user can install the tagged `0.1.0` preview from GitHub and
run the landing-page Gaussian location-scale example.

## What Happened

The clean-install smoke test used a temporary R library, installed `pak` if it
was not already available, and ran:

```r
pak::pak("itchyshin/drmTMB@v0.1.0")
```

`pak` installed `drmTMB 0.1.0` from GitHub commit `5f8e669` plus the hard
runtime dependencies `cli`, `Rcpp`, `RcppEigen`, and `TMB`. The package loaded
successfully and the README Gaussian location-scale model fit returned finite
`mu`, `sigma`, and `sigma(fit)` values.

## Documentation Change

The README installation section now distinguishes the tagged preview from the
moving development branch:

- `pak::pak("itchyshin/drmTMB@v0.1.0")` installs the released preview.
- `pak::pak("itchyshin/drmTMB")` installs the newest development build from
  `main`.
- The `remotes` fallback now pins `ref = "v0.1.0"` for the preview install.

## User-Facing Friction

Loading `drmTMB` reports that the exported `beta()` family masks `base::beta()`.
This is not an installation failure, but it is a real first-use message. A later
API pass should consider whether to keep `beta()` as the family name, add a
clearer alias, or document the masking message in the family guide.

## Checks Run

- Clean temporary-library install with `pak::pak("itchyshin/drmTMB@v0.1.0")`:
  passed.
- README smoke model from the installed package: passed.
- `Rscript -e "pkgdown::build_home()"`: passed and regenerated the rendered
  landing page.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- Rendered install-section scan over `README.md` and `pkgdown-site/index.html`:
  confirmed the tagged `pak` install, the development-branch `pak` install, and
  the pinned `remotes` fallback.
- `Rscript -e "devtools::test()"`: 1400 passed, 0 failed, 0 warnings, 0 skips.
- `git diff --check`: clean.

## What Did Not Go Smoothly

One first-pass rendered-text scan put Markdown backticks inside a double-quoted
shell pattern, so `zsh` tried to run `0.1.0` as a command. The scan was rerun
with a single-quoted pattern. Rose's repeated lesson is now painfully clear:
release and documentation scans should use boring single-quoted shell patterns.
