# After Task: Experimental Julia Engine Bridge Packaging

## Goal

Package the experimental `drmTMB(..., engine = "julia")` bridge and the
R-Julia article as a focused drmTMB branch, without mixing in concurrent
skew-normal, q8, or release-readiness edits from the detached working tree.

## Implemented

The branch adds explicit `engine = c("tmb", "julia")` dispatch to `drmTMB()`.
The default remains native TMB. The Julia route returns a `drmTMB_julia` object
for Gaussian fixed-effect models and for one Gaussian phylogenetic mean
intercept route, `phylo(1 | species, tree = tree)` with `sigma ~ 1`.

`R/julia-bridge.R` validates the admitted bridge surface, serializes formulas
and binary phylogenies for JuliaCall, reconstructs coefficients, fitted values,
likelihood metadata, fitted `sigma`, residual `rho12`, and phylogenetic SD
targets, and converts the narrow Julia-side profile/bootstrap result for the
phylogenetic SD back to the public drmTMB response scale.

## Mathematical Contract

The admitted one-response fixed-effect bridge keeps the standard Gaussian
distributional-regression contract:

```text
y_i ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
```

The admitted phylogenetic bridge keeps the same R syntax as native drmTMB but
uses the DRM.jl sparse all-node route under the bridge:

```r
bf(growth ~ temperature + phylo(1 | species, tree = tree), sigma ~ 1)
```

The R-facing contract does not expose Julia optimizer choices yet. The article
states that `engine = "julia"` should be read as the current default Julia
route for the admitted cell, not a user-facing algorithm selector.

## Files Changed

- `R/drmTMB.R`
- `R/julia-bridge.R`
- `R/profile.R`
- `tests/testthat/test-julia-bridge.R`
- `vignettes/julia-engine.Rmd`
- `tools/benchmark-julia-engines.R`
- `tools/benchmark-r-julia-bootstrap-refits.R`
- `DESCRIPTION`, `NAMESPACE`, `NEWS.md`, `_pkgdown.yml`, and `man/drmTMB.Rd`
- Julia bridge benchmark records under `docs/dev-log/benchmarks/`
- Related after-task records under `docs/dev-log/after-task/`

## Checks Run

- `air format R/drmTMB.R R/julia-bridge.R R/profile.R tests/testthat/test-julia-bridge.R tools/benchmark-julia-engines.R tools/benchmark-r-julia-bootstrap-refits.R`
  completed without errors.
- `Rscript --vanilla -e 'devtools::document()'` completed; generated changes
  were kept to `NAMESPACE` and `man/drmTMB.Rd` after reverting unrelated roxygen
  link/author rewrites.
- `Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'`
  returned 71 passes with no failures, warnings, or skips.
- `pkgdown::build_article("julia-engine")`, `pkgdown::check_pkgdown()`, and
  full `pkgdown::build_site()` completed. The generated page is
  `pkgdown-site/articles/julia-engine.html`, and the article appears under
  Developer Notes in both the navbar and article index.
- `git diff --check` passed.

## Tests Of The Tests

The new test file checks formula marshalling, phylogeny serialization,
same-tree cache reuse, row-order restoration, `drmTMB_julia` methods,
profile-target inventory, profile/bootstrap response-scale interval conversion,
mocked public `confint()` routing, partial covariance handling, and guardrails
that fail before JuliaCall setup. The guardrail checks cover unsupported
weights, non-default control, and non-Gaussian families.

## Consistency Audit

The article uses supported syntax and labels the benchmark rows as warm-session
local timing evidence, not broad validation. The profile table is rendered as a
normal HTML table rather than the earlier hard-to-read monospaced block.

Scans run:

```sh
rg -n 'engine = "julia"|drmTMB_julia|JuliaCall|DRM\.jl|profile_unavailable|skew_normal\(' README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/julia-engine.Rmd _pkgdown.yml R tests/testthat man --glob '!docs/dev-log/check-log.md'
rg -n '68\.405|4\.710|partial: mu|This is the beauty|cannot read thsi|wokr|eengines|guassian|Jula |spare matrix' vignettes/julia-engine.Rmd pkgdown-site/articles/julia-engine.html docs/dev-log/after-task docs/dev-log/benchmarks NEWS.md
rg -n "Working with the Julia engine|Developer Notes|Julia-engine profile|Native R profile|B=10 timing smoke|What works now|What does not work yet|Next parity steps" pkgdown-site/articles/julia-engine.html pkgdown-site/articles/index.html pkgdown-site/sitemap.xml
```

The scans found expected current bridge/article/code hits, historical roadmap
skew-normal planning rows, and benchmark history rows. They did not find the
old unreadable profile table wording in the rendered article.

## GitHub Issue Maintenance

`gh issue list --repo itchyshin/drmTMB --state open --search "Julia OR JuliaCall OR DRM.jl OR engine=julia OR engine \"julia\"" --limit 20 --json number,title,state,url,labels`
found issue #499, "R bridge: dispatch drmTMB(..., engine = \"julia\") through
DRM.jl", as the matching tracker. No duplicate issue was opened.

## What Did Not Go Smoothly

The source working tree was detached and contained many unrelated active
changes, so the branch had to be assembled in a clean side worktree. Roxygen
also rewrote a few unrelated Rd links and author boilerplate; those generated
diffs were reverted manually so the branch stays focused.

Two direct `tools::checkRd()` directory-style attempts failed because this R
version expects an explicit Rd file. An internal
`tools:::tidy_validate_package_Rd_files_from_dir(".", verbose = FALSE)` call
exited 0 but prints broad pre-existing tidy diagnostics, so the reliable
documentation gates for this slice are `devtools::document()`,
`pkgdown::check_pkgdown()`, and the full pkgdown build.

## Team Learning

For bridge work that starts in a dirty experimental checkout, create a clean
side worktree before packaging. Copy new files, then patch mixed tracked files
by hand. This avoided pulling skew-normal, q8, and release-readiness edits into
the Julia PR.

## Known Limitations

The Julia bridge remains experimental. It does not support likelihood weights,
missing-data routes, imputation, non-default `control`, non-Gaussian families,
broader phylogenetic formulas, random-effect scale formulas, `corpair()`
entries, `newdata` prediction, simulation, or persistent Julia fit handles.
The profile/bootstrap bridge supports only the admitted Gaussian phylogenetic
SD target.

## Next Actions

Open the focused branch against issue #499, then pair it with the DRM.jl bridge
branch that supplies `DRM.drm_bridge()` and the sparse phylogenetic
profile/bootstrap primitive. After both sides are reviewable, the next useful
slice is a live R-side `engine = "julia"` benchmark with the same R script,
metadata, and worker/thread labels used in the article.
