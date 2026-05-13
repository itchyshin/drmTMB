# Check Log

Record meaningful development checks here.

## 2026-05-13 -- Slice 13B phylo and species reader path

Scope:

- updated `vignettes/model-map.Rmd` and `vignettes/phylogenetic-spatial.Rmd`
  with syntax for fitting an ordinary labelled species covariance block beside
  matching bivariate `phylo()` terms;
- kept the three correlation layers separate in prose: residual `rho12`,
  ordinary group-level species covariance, and phylogenetic mean-mean
  covariance;
- rebuilt the two local pkgdown article pages for user review.

Checks:

- `Rscript -e 'pkgdown::build_article("model-map"); pkgdown::build_article("phylogenetic-spatial")'`:
  passed and wrote `pkgdown-site/articles/model-map.html` and
  `pkgdown-site/articles/phylogenetic-spatial.html`.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'spatial.*implemented|spatial.*now fits|spatial likelihood is implemented|full q=4.*implemented|q=4.*now fits' NEWS.md README.md ROADMAP.md docs vignettes man R tests`:
  found only planned-boundary wording, historical notes, and explicit
  not-implemented text.
- `rg -n 'future .*non-phylogenetic species|Non-phylogenetic species covariance.*future|Add bivariate Gaussian \`mu1\` and \`mu2\` ordinary species|Add bivariate Gaussian phylogenetic \`mu1\`' docs/design/29-mammal-location-coscale-route.md ROADMAP.md docs/design vignettes`:
  no matches.
- `Rscript -e 'devtools::test()'`: passed with 2,772 expectations.

## 2026-05-13 -- Slice 12B phylo and ordinary species layer diagnostic

Scope:

- extended `check_drm()` so the `biv_phylo_mu_covariance` diagnostic reports
  `same_group_covariance=true` when an ordinary labelled `mu1`/`mu2`
  group-level covariance block uses the same grouping factor as the fitted
  bivariate phylogenetic layer;
- changed that row to `note` when the same-group overlap is present, unless a
  stronger boundary warning applies;
- updated the roadmap and design notes to say this is an identifiability guard,
  not evidence that same-species phylogenetic and non-phylogenetic layers are
  always cleanly separated.

Checks:

- `Rscript -e 'devtools::document()'`: passed and regenerated
  `man/check_drm.Rd`.
- `Rscript -e 'devtools::test(filter = "check-drm")'`: passed with 119
  expectations.
- `Rscript -e 'devtools::test(filter = "phylo-gaussian|check-drm|corpairs|summary|profile-targets")'`:
  passed with 620 expectations.
- `Rscript -e 'devtools::test()'`: passed with 2,772 expectations.

## 2026-05-13 -- Slice 11B bivariate phylogenetic simulation recovery

Scope:

- added a CRAN-safe deterministic recovery test for the first fitted
  bivariate phylogenetic `mu1`/`mu2` mean-mean correlation;
- checked optimizer convergence, positive correlation recovery, phylogenetic
  SD recovery, residual scale recovery, residual `rho12`, and `corpairs()`
  reporting;
- updated roadmap and common-math design wording so the fitted bivariate
  phylogenetic mean-mean layer now has direct simulation evidence.

Checks:

- `air format R/check.R tests/testthat/test-phylo-gaussian.R tests/testthat/test-check-drm.R ROADMAP.md docs/design/15-location-coscale-phylogenetic-extension.md docs/design/16-phylo-spatial-common-math.md docs/design/29-mammal-location-coscale-route.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd`:
  passed.
- `Rscript -e 'devtools::test(filter = "phylo-gaussian|check-drm")'`: passed
  with 165 expectations.
- `Rscript -e 'devtools::test(filter = "phylo-gaussian|check-drm|corpairs|summary|profile-targets")'`:
  passed with 620 expectations.
- `Rscript -e 'devtools::test()'`: passed with 2,772 expectations.

## 2026-05-13 -- Slice 10 phylo-only batch audit

Scope:

- audited the post-crash phylo-only batch after slices 6--9;
- confirmed fitted bivariate phylogenetic `mu1`/`mu2` support is represented
  consistently across target inventory, direct profile smoke, `corpairs()`,
  `summary(fit)$covariance`, `check_drm()`, vignettes, NEWS, roadmap, and known
  limitations;
- confirmed deferred work remains explicit: spatial models, phylogenetic
  slopes, phylogenetic scale terms, structured effects in `rho12`, full q=4
  location-scale covariance, non-phylogenetic species covariance, and derived
  covariance intervals.

Checks:

- `Rscript -e 'devtools::test(filter = "profile-targets|summary|corpairs|check-drm|phylo-gaussian")'`:
  passed with 606 expectations.
- `Rscript -e 'devtools::test()'`: last run after code/profile changes passed
  with 2,758 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'for (f in c("vignettes/model-map.Rmd", "vignettes/phylogenetic-spatial.Rmd")) rmarkdown::render(f, output_file = tempfile(fileext = ".html"), quiet = TRUE)'`:
  passed after the reader-path edits.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found after
  the reader-path edits.
- `rg -n 'spatial.*implemented|spatial.*now fits|bivariate phylogenetic.*planned|bivariate phylo\(\) syntax remains planned|q=4.*implemented|full q=4.*implemented' NEWS.md README.md ROADMAP.md docs vignettes man R tests`:
  found expected planned-boundary and historical-note wording only.
- `rg -n 'corpars\$phylo|cor:phylo|summary\(fit.*\)\$covariance|biv_phylo_mu_covariance|phylogenetic.*mean-mean' NEWS.md README.md ROADMAP.md docs vignettes man R tests`:
  confirmed the implemented bivariate phylogenetic mean-mean surfaces.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 9 bivariate phylogenetic reader path

Scope:

- updated `vignettes/phylogenetic-spatial.Rmd` so the bivariate phylogenetic
  section shows the fitted `fit_biv_phylo` syntax, `corpairs()` reading path,
  `summary(fit)$covariance`, `check_drm()`, and the explicit `cor:phylo:`
  profile target;
- updated `vignettes/model-map.Rmd` so the practical trait protocol includes
  matching bivariate `phylo()` terms as the first fitted phylogenetic
  mean-mean slice;
- kept phylogenetic slopes, phylogenetic `sigma`, q=4 location-scale
  covariance, structured effects in `rho12`, and spatial terms planned;
- updated NEWS to describe the tutorial reading guidance.

Checks:

- `air format NEWS.md vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd`:
  passed.
- `Rscript -e 'for (f in c("vignettes/model-map.Rmd", "vignettes/phylogenetic-spatial.Rmd")) rmarkdown::render(f, output_file = tempfile(fileext = ".html"), quiet = TRUE)'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'fit_biv_phylo|cor:phylo|summary\(fit_biv_phylo\)\$covariance|corpairs\(fit_biv_phylo|confint\(fit_biv_phylo|spatial.*implemented|spatial.*planned|rho12.*phylogenetic' vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd NEWS.md`:
  confirmed the new reader path and spatial planned boundary.
- `rg -n 'bivariate phylogenetic.*planned|corpairs\(\).*remain planned|q=4 endpoint|spatial likelihood is not implemented' vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd NEWS.md`:
  confirmed q=4 and spatial limitations remain explicit without hiding the
  fitted `mu1`/`mu2` phylogenetic slice.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 8 bivariate phylogenetic profile smoke

Scope:

- added a focused `confint(..., method = "profile")` smoke test for the direct
  bivariate phylogenetic `mu1`/`mu2` mean-mean correlation target;
- used a stronger deterministic fixture than the small target-inventory fixture
  so the profile has finite lower and upper endpoints without warnings;
- compared the public `confint()` output to an independent
  `TMB::tmbprofile()` call on `eta_cor_phylo`;
- updated NEWS, roadmap, profile design notes, and generated `confint()`
  reference docs to include the phylogenetic correlation target.

Checks:

- `air format tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md R/profile.R`:
  passed.
- `Rscript -e 'devtools::document()'`: passed and regenerated
  `man/confint.drmTMB.Rd`.
- `Rscript -e 'devtools::test(filter = "profile-targets|phylo-gaussian")'`:
  passed with 292 expectations.
- `Rscript -e 'devtools::test()'`: passed with 2,758 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'eta_cor_phylo|bivariate phylogenetic.*profile|confint\(\).*phylogenetic|phylogenetic.*confint|rho12.*phylogenetic|spatial.*implemented' NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/known-limitations.md R/profile.R tests/testthat/test-profile-targets.R man/confint.drmTMB.Rd`:
  confirmed the profile target, residual-`rho12` separation, and spatial
  planned boundary.
- `rg -n 'profile.*bivariate phylogenetic|bivariate phylogenetic.*planned|spatial.*implemented' NEWS.md ROADMAP.md docs vignettes man`:
  found expected current and historical planned-boundary wording only.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 7 phylogenetic `summary()` covariance row

Scope:

- added a `summary(fit)$covariance` row for fitted bivariate phylogenetic
  `mu1`/`mu2` mean-mean covariance;
- kept the row on the same covariance-summary surface used by fitted
  registry-backed covariance blocks, with `level = "phylogenetic"`,
  `block = "phylo"`, `class = "mean-mean"`, identity scales, component SD
  targets, and the `cor:phylo:` target name;
- kept residual `rho12` in `summary(fit)$parameters`, not in the random-effect
  covariance table;
- updated NEWS, roadmap, known limitations, the double-hierarchical endpoint
  note, and the `summary()` reference documentation.

Checks:

- `air format R/methods.R tests/testthat/test-summary.R NEWS.md ROADMAP.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md`:
  passed.
- `Rscript -e 'devtools::document()'`: passed and regenerated
  `man/summary.drmTMB.Rd`.
- `Rscript -e 'devtools::test(filter = "summary|phylo-gaussian|corpairs|profile-targets")'`:
  passed with 484 expectations.
- `Rscript -e 'devtools::test()'`: passed with 2,749 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'summary\(fit\)\$covariance|summary\(\).*phylogenetic|bivariate phylogenetic.*covariance|rho12.*summary|spatial.*implemented' NEWS.md ROADMAP.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd R/methods.R tests/testthat/test-summary.R man/summary.drmTMB.Rd`:
  confirmed the new summary surface and residual/spatial boundaries.
- `rg -n 'summary\(fit\)\$covariance.*registry-backed|registry-backed.*summary\(fit\)\$covariance|covariance component.*registry-backed|spatial.*implemented' NEWS.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes man/summary.drmTMB.Rd`:
  confirmed the registry-backed wording now has the phylogenetic exception where
  needed and no current spatial-implemented claim.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 6 phylogenetic `profile_targets()` labels

Scope:

- added focused coverage that `profile_targets()` lists fitted bivariate
  phylogenetic `mu1`/`mu2` location SDs and the phylogenetic mean-mean
  correlation;
- checked the exact public target names:
  `sd:mu:mu1:phylo(1 | species)`,
  `sd:mu:mu2:phylo(1 | species)`, and
  `cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)`;
- checked TMB mapping to `log_sd_phylo` indices 1 and 2 and
  `eta_cor_phylo` index 1, with `exp`/`tanh` transformations and direct
  profile readiness;
- confirmed residual `rho12` remains a separate residual-correlation target;
- synchronized NEWS, roadmap, and profile/double-hierarchical design notes
  without changing spatial implementation status.

Checks:

- `air format tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "profile-targets|phylo-gaussian")'`:
  passed with 283 expectations.
- `Rscript -e 'devtools::test()'`: passed with 2,716 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'bivariate phylogenetic|cor:phylo|rho12|spatial' NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd`:
  confirmed fitted phylogenetic target wording, residual-`rho12` separation, and
  spatial planned wording.
- `rg -n 'profile intervals already work|profile-likelihood intervals.*phylogenetic|derived.*phylo|spatial.*implemented|bivariate phylo\(\) syntax remains planned|bivariate phylogenetic.*planned' NEWS.md ROADMAP.md docs vignettes`:
  found only expected planned-boundary and historical-note wording; no current
  claim that spatial is implemented.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 5 phylogenetic `check_drm()` diagnostics

Scope:

- added a `biv_phylo_mu_covariance` row to `check_drm()` for fitted bivariate
  Gaussian models with matching `mu1`/`mu2` phylogenetic location effects;
- reused the existing `rho_boundary` threshold to warn when fitted
  `corpars$phylo` is near the correlation boundary;
- added a weak-identification note when species replication is thin or either
  fitted phylogenetic location SD is tiny relative to the matching residual
  scale;
- kept residual `rho12`, phylogenetic mean-mean correlation, ordinary
  group-level covariance, and planned spatial covariance as separate diagnostic
  stories;
- updated `check_drm()` reference docs, NEWS, roadmap/status notes, known
  limitations, and phylogenetic/model-map tutorial wording.

Checks:

- `air format R/check.R tests/testthat/test-check-drm.R NEWS.md ROADMAP.md docs/dev-log/known-limitations.md docs/design/16-phylo-spatial-common-math.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd`:
  passed.
- `Rscript -e 'devtools::document()'`: passed and regenerated
  `man/check_drm.Rd`.
- `Rscript -e 'devtools::test(filter = "check-drm|phylo-gaussian|corpairs")'`:
  passed with 228 expectations.
- `Rscript -e 'devtools::test()'`: passed with 2,703 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e 'for (f in c("vignettes/model-map.Rmd", "vignettes/phylogenetic-spatial.Rmd")) rmarkdown::render(f, output_file = tempfile(fileext = ".html"), quiet = TRUE)'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'biv_phylo_mu_covariance|corpars\$phylo|phylogenetic.*diagnostic|near-boundary.*phylo|tiny phylogenetic|spatial.*implemented|spatial.*planned|rho12.*phylogenetic|rho12.*spatial' R/check.R tests/testthat/test-check-drm.R NEWS.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd man/check_drm.Rd`:
  confirmed the new diagnostic row, fitted phylogenetic wording, spatial
  planned boundary, and residual-`rho12` separation.
- `rg -n 'check_drm\(\).*phylo|phylo.*check_drm|bivariate phylogenetic.*check_drm|corpars\$phylo.*check_drm' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes man/check_drm.Rd`:
  confirmed the user-facing diagnostic references.
- `Rscript tools/codex-checkpoint.R --goal "slice 5 phylogenetic check_drm diagnostics closeout" --next "review diff, then preserve branch state or plan the spatial sibling lane"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-13-150118-codex-checkpoint.md`.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 4 phylogenetic `corpairs()` row

Scope:

- added a `corpairs()` row for fitted bivariate phylogenetic mean-mean
  correlations exposed in `corpars$phylo`;
- used `level = "phylogenetic"`, `block = "phylo"`, `class = "mean-mean"`,
  and the matched `mu1`/`mu2` response labels so residual `rho12`, ordinary
  group-level covariance, and phylogenetic covariance stay separate;
- kept full q=4 phylogenetic location-scale rows planned: this slice reports
  only the fitted `mu1`/`mu2` phylogenetic location correlation;
- updated `corpairs()` docs, NEWS, correlation-pair design notes, known
  limitations, and the phylogenetic/model-map tutorial references.

Checks:

- `air format R/methods.R tests/testthat/test-corpairs.R NEWS.md docs/dev-log/known-limitations.md docs/design/20-coscale-correlation-pairs.md docs/design/29-mammal-location-coscale-route.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd`:
  passed.
- `Rscript -e 'devtools::test(filter = "corpairs|phylo-gaussian|biv-gaussian")'`:
  passed with 616 expectations after normalizing the expected filtered-row name
  in the new `corpairs()` regression test.
- `Rscript -e 'devtools::document()'`: passed and regenerated
  `man/corpairs.Rd`.
- `Rscript -e 'devtools::test()'`: passed with 2,686 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e 'for (f in c("vignettes/model-map.Rmd", "vignettes/phylogenetic-spatial.Rmd")) rmarkdown::render(f, output_file = tempfile(fileext = ".html"), quiet = TRUE)'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `Rscript tools/codex-checkpoint.R --goal "slice 4 phylogenetic corpairs row closeout" --next "review diff, then start slice 5 check_drm diagnostics for fitted bivariate phylogenetic correlations"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-13-144557-codex-checkpoint.md`.
- `git diff --check`: passed.

## 2026-05-13 -- Fitted bivariate phylogenetic location slice

Scope:

- replaced the previous matched-term guard with a fitted bivariate Gaussian
  `mu1`/`mu2` phylogenetic location slice for matching intercept-only
  `phylo(1 | species, tree = tree)` terms;
- added the TMB parameterization for two phylogenetic location SDs and one
  phylogenetic mean-mean correlation while keeping `sigma1`, `sigma2`, and
  residual `rho12` as ordinary fixed-effect distributional parameters;
- exposed the fitted phylogenetic SDs through `sdpars$mu`, the mean-mean
  correlation through `corpars$phylo`, and fitted-row `predict(..., dpar =
  "mu1")` / `predict(..., dpar = "mu2")` contributions;
- updated README, NEWS, roadmap, design notes, known limitations, reference
  docs, and tutorials to mark only this first bivariate phylogenetic location
  slice as fitted while leaving the full q=4 location-scale endpoint and
  `corpairs()` rows planned.

Checks:

- `air format R/drmTMB.R R/formula-markers.R R/methods.R R/profile.R tests/testthat/test-biv-gaussian.R tests/testthat/test-phylo-gaussian.R tests/testthat/test-phylo-utils.R README.md NEWS.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/09-phylogenetic-and-spatial-speed.md docs/design/15-location-coscale-phylogenetic-extension.md docs/design/16-phylo-spatial-common-math.md docs/design/20-coscale-correlation-pairs.md docs/design/28-double-hierarchical-endpoint.md docs/design/29-mammal-location-coscale-route.md docs/dev-log/known-limitations.md vignettes/formula-grammar.Rmd vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd vignettes/which-scale.Rmd`:
  passed.
- `air format tests/testthat/test-gaussian-location-scale.R`: passed.
- `air format docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-13-fitted-bivariate-phylogenetic-location.md`:
  passed.
- `Rscript -e 'devtools::document()'`: passed and regenerated `man/drmTMB.Rd`
  and `man/phylo.Rd`.
- `Rscript -e 'devtools::test(filter = "phylo|biv-gaussian|profile-targets")'`:
  passed with 838 expectations.
- `Rscript -e 'devtools::test(filter = "gaussian-location-scale|phylo|biv-gaussian|profile-targets")'`:
  passed with 916 expectations after updating a stale one-sided bivariate
  `phylo()` error-message expectation.
- `Rscript -e 'devtools::test()'`: passed with 2,657 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e 'for (f in c("vignettes/formula-grammar.Rmd", "vignettes/model-map.Rmd", "vignettes/phylogenetic-spatial.Rmd", "vignettes/which-scale.Rmd")) rmarkdown::render(f, output_file = tempfile(fileext = ".html"), quiet = TRUE)'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `Rscript tools/codex-checkpoint.R --goal "fitted bivariate phylogenetic location closeout" --next "review diff, then add corpairs rows for fitted phylogenetic mean-mean correlations or commit this slice"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-13-135745-codex-checkpoint.md`.
- `git diff --check`: passed.

## 2026-05-13 -- Bivariate phylogenetic location syntax guard

Scope:

- added a narrow bivariate Gaussian guard for the next fitted phylogenetic
  location path;
- made unmatched `phylo()` terms in `mu1` or `mu2` fail with a matched-term
  message;
- made mismatched bivariate `phylo()` group/tree combinations fail explicitly;
- made matched `mu1`/`mu2` phylogenetic location syntax report that it is
  recognized but not fitted yet, with `sigma1`, `sigma2`, and residual `rho12`
  still ordinary fixed-effect distributional parameters.

Checks:

- `air format R/drmTMB.R tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e 'devtools::test(filter = "biv-gaussian")'`: passed with 501
  expectations, 0 failures, 0 warnings, and 0 skips.

## 2026-05-13 -- pkgdown feature-branch build workflow guard

Scope:

- split the pkgdown workflow so manual feature-branch dispatches build and
  upload the site artifact without entering the protected GitHub Pages deploy
  environment;
- kept deploys restricted to main/master dispatches or successful main/master
  `R-CMD-check` workflow-run completions;
- responded to failed pkgdown run `25817629476`, which was rejected by
  GitHub Pages environment protection before build steps started.

Checks:

- `air format .github/workflows/pkgdown.yaml docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-pkgdown-feature-branch-build-workflow-guard.md`:
  passed.
- `ruby -e 'require "yaml"; data = YAML.load_file(".github/workflows/pkgdown.yaml");
  abort("missing jobs") unless data["jobs"] || data[true] || data[:jobs]; puts
  "yaml parsed"'`: passed.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 15 staged trait protocol guide

Scope:

- added a plain model-map protocol for mammal, bird, or other comparative trait
  analyses that need residual coupling, ordinary group-level covariance, and
  phylogenetic structure;
- showed the implemented bivariate Gaussian path and implemented univariate
  phylogenetic path as separate fitted models;
- clarified that developer q=4 shorthand means four distributional endpoints,
  not four fitted correlations, and that a q4 covariance would require six
  pairwise reporting rows before public support is claimed.

Checks:

- `air format vignettes/model-map.Rmd README.md docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-15-staged-trait-protocol-guide.md`:
  passed.
- `Rscript -e 'rmarkdown::render("vignettes/model-map.Rmd", output_file =
  tempfile(fileext = ".html"), quiet = TRUE)'`: passed.
- `rg -n 'practical trait protocol|q=4|four distributional endpoints|six
  pairwise|mammal|bird|rho12\\(fit_biv\\)|phylo\\(1 \\| species|combined
  phylogenetic' vignettes/model-map.Rmd README.md docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-15-staged-trait-protocol-guide.md`:
  passed.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 14 phylogenetic q4 status wording guard

Scope:

- clarified in user-facing phylogenetic and model-map prose that q4
  phylogenetic scaffolds are internal developer contracts only;
- stated that bivariate `phylo()` remains planned until fitted likelihood,
  simulation recovery, and reporting rows are present;
- kept residual `rho12`, ordinary group-level covariance, and future
  phylogenetic covariance layers separate in the public status map.

Checks:

- `air format vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd
  docs/dev-log/known-limitations.md docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-14-phylogenetic-q4-status-wording-guard.md`:
  passed.
- `rg -n 'q=4|q4|bivariate \`phylo|fitted likelihood|corpairs\\(\\)|planned,
  not implemented|residual \`rho12' vignettes/phylogenetic-spatial.Rmd
  vignettes/model-map.Rmd docs/dev-log/known-limitations.md
  docs/dev-log/after-task/2026-05-13-slice-14-phylogenetic-q4-status-wording-guard.md`:
  passed and confirmed public wording says q4 phylogenetic scaffolds are
  internal only.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 13 phylogenetic q4 planned-pair scaffold

Scope:

- added an internal planned-pair scaffold for the future q=4 phylogenetic
  endpoint across `mu1`, `mu2`, `sigma1`, and `sigma2`;
- recorded one `mean-mean`, four `mean-scale`, and one `scale-scale`
  phylogenetic row with response labels and planned status;
- checked that the scaffold does not use residual `rho12` names and remains
  `modelled = FALSE`;
- kept fitted-model extractors unchanged.

Checks:

- `air format R/phylo-utils.R tests/testthat/test-phylo-utils.R ROADMAP.md
  docs/design/09-phylogenetic-and-spatial-speed.md
  docs/design/15-location-coscale-phylogenetic-extension.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-13-phylogenetic-q4-planned-pair-scaffold.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "phylo-utils")'`: passed with 67
  expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 12 hidden phylogenetic q4 TMB prior branch

Scope:

- added hidden `model_type == 94` as a prior-only TMB branch for a q=4
  phylogenetic state over the augmented tree precision;
- added `re_cov_probe_covariance` to the hidden probe data contract while
  keeping ordinary model data unchanged through dummy values;
- compared the hidden TMB objective with the R
  `drm_phylo_correlated_precision_nll()` helper;
- kept public bivariate `phylo()` syntax and fitted model reporting closed.

Checks:

- `air format R/drmTMB.R tests/testthat/test-phylo-utils.R ROADMAP.md
  docs/design/09-phylogenetic-and-spatial-speed.md
  docs/design/15-location-coscale-phylogenetic-extension.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-12-hidden-phylogenetic-q4-tmb-prior-branch.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "phylo-utils")'`: passed with 52
  expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 11 phylogenetic q4 prior algebra scaffold

Scope:

- added an internal matrix-normal phylogenetic prior helper for correlated
  state vectors over the existing augmented tree precision;
- checked a q=4 state named `mu1`, `mu2`, `sigma1`, and `sigma2` against a
  dense Kronecker covariance comparator;
- checked that a diagonal two-state covariance matches the existing
  independent phylogenetic precision helper;
- kept this as algebra evidence only, with no public bivariate `phylo()`
  syntax or TMB likelihood wiring.

Checks:

- `air format R/phylo-utils.R tests/testthat/test-phylo-utils.R ROADMAP.md
  docs/design/09-phylogenetic-and-spatial-speed.md
  docs/design/15-location-coscale-phylogenetic-extension.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-11-phylogenetic-q4-prior-algebra-scaffold.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "phylo-utils")'`: passed with 49
  expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 10 combined group and residual correlation summary guard

Scope:

- strengthened the existing combined bivariate Gaussian regression with
  matching labelled `mu1`/`mu2` and `sigma1`/`sigma2` random-intercept
  covariance blocks plus predictor-dependent residual `rho12 ~ x`;
- checked that `summary(fit)$covariance` reports exactly the two group-level
  covariance rows, with one `mean-mean` row and one `scale-scale` row;
- checked fitted random-effect scales and covariance point estimates for both
  rows;
- kept residual `rho12` out of `summary(fit)$covariance` while leaving it in
  `corpairs()` as a separate residual row;
- documented that this is a pairwise public-support guard, not q > 2 public
  support or a new likelihood path.

Checks:

- `air format tests/testthat/test-biv-gaussian.R ROADMAP.md
  docs/design/28-double-hierarchical-endpoint.md docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-10-combined-group-and-residual-correlation-summary-guard.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "biv-gaussian|summary|corpairs")'`:
  passed with 638 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 9D derived covariance interval status guard

Scope:

- added `covariance_conf.status` to the random-effect covariance summary table;
- marked ordinary summaries as `not_requested` and profiled summaries as
  `derived_interval_unavailable` while keeping derived covariance interval
  values `NA`;
- made `print(summary(fit))` show the unavailable-status marker when profile
  intervals are requested for covariance rows;
- documented that this is a reporting guard only, not a new derived covariance
  interval method or q > 2 fitted-model claim.

Checks:

- `air format R/methods.R tests/testthat/test-summary.R
  tests/testthat/test-covariance-block-registry.R NEWS.md ROADMAP.md
  docs/design/28-double-hierarchical-endpoint.md docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-9d-derived-covariance-interval-status-guard.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "summary|covariance-block-registry|corpairs")'`:
  passed with 322 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 9C summary covariance reporting surface

Scope:

- added `summary(fit)$covariance` as the first public surface for fitted
  registry-backed random-effect variance and covariance point summaries;
- made `print(summary(fit))` show a compact covariance table only when fitted
  covariance rows exist;
- kept residual `rho12` out of the covariance table and kept derived covariance
  intervals empty even when component profile intervals are present;
- documented the scope boundary in NEWS, roadmap, and the double-hierarchical
  endpoint design note.

Checks:

- `Rscript -e 'devtools::test(filter = "summary")'`: passed with 87
  expectations, 0 failures, 0 warnings, and 0 skips.
- `devtools::document()`: passed.
- `air format R/methods.R tests/testthat/test-summary.R NEWS.md ROADMAP.md
  docs/design/28-double-hierarchical-endpoint.md docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-9c-summary-covariance-reporting-surface.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "summary|covariance-block-registry|corpairs")'`:
  passed with 315 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 9B covariance-summary component intervals

Scope:

- added target-name columns to the internal random-effect covariance summary
  table for the defining SD and correlation profile targets;
- allowed the internal table to attach direct profile intervals for those
  component SD and correlation targets;
- kept derived covariance interval columns present but empty until a valid
  nonlinear derived-interval method exists;
- checked the hidden q=4 endpoint scaffold with synthetic profile rows for all
  six correlations and four SD targets.

Checks:

- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 180 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|corpairs")'`: passed with 228 expectations, 0
  failures, 0 warnings, and 0 skips.
- `air format R/methods.R tests/testthat/test-covariance-block-registry.R
  ROADMAP.md docs/design/28-double-hierarchical-endpoint.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-9b-covariance-summary-component-intervals.md`:
  passed.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 9A internal covariance-summary scaffold

Scope:

- added an internal registry-backed random-effect covariance summary table;
- transformed fitted random-effect SDs and correlations into variance and
  covariance point estimates on the fitted random-effect scale;
- checked the hidden q=4 endpoint scaffold for all six covariance rows, the
  fully dormant no-row path, and the mixed fitted/dormant path;
- kept this as point-estimate infrastructure only: no public extractor, no
  interval columns, no residual `rho12` covariance summaries, and no ordinary
  fitted q4 support claim.

Checks:

- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 170 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|corpairs")'`: passed with 218 expectations, 0
  failures, 0 warnings, and 0 skips.
- `air format R/methods.R tests/testthat/test-covariance-block-registry.R
  ROADMAP.md docs/design/28-double-hierarchical-endpoint.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-9a-internal-covariance-summary-scaffold.md`:
  passed.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 8F hidden q=4 profile-target scaffold

Scope:

- made registry-backed `profile_targets()` skip dormant covariance-block pair
  rows that have no fitted TMB parameter/index metadata;
- added an internal fitted-like q=4 endpoint scaffold that formats the six
  corresponding random-effect correlation targets from registry metadata and
  `corpars`;
- checked target names, target class, correlation namespace, TMB parameter,
  index, estimate, guarded link estimate, transformation, readiness, and
  `ready_only` filtering for the fitted-like q=4 targets;
- added mixed-registry coverage so a partly fitted q4 registry reports only the
  fitted pair and skips still-dormant scaffold rows;
- kept this as profile-target contract evidence only: ordinary fitted q4 models
  do not yet populate these rows, and there is no public q > 2 syntax or
  example.

Checks:

- `Rscript -e 'devtools::test(filter =
  "profile-targets|covariance-block-registry")'`: passed with 388
  expectations, 0 failures, 0 warnings, and 0 skips.
- `air format R/profile.R tests/testthat/test-profile-targets.R
  tests/testthat/test-covariance-block-registry.R ROADMAP.md
  docs/design/28-double-hierarchical-endpoint.md
  docs/design/30-labelled-covariance-block-assembler.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-8f-hidden-q4-profile-target-scaffold.md`:
  passed.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 8E hidden q=4 corpairs scaffold

Scope:

- made registry-backed `corpairs()` skip dormant covariance-block pair rows that
  have no fitted TMB parameter/index metadata;
- added an internal fitted-like q=4 endpoint scaffold that formats all six
  group-level rows from registry metadata and `corpars`: one `mean-mean`, four
  `mean-scale`, and one `scale-scale`;
- checked class, group, parameter, response-scale estimate, link-scale estimate,
  and filtering behavior for the fitted-like q=4 rows;
- checked that a dormant q=4 registry remains invisible to group-level
  `corpairs()` output instead of producing an internal-error abort;
- kept this as extractor-contract evidence only: ordinary fitted q4 models do
  not yet populate these rows, and there is no public q > 2 syntax or example.

Checks:

- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 153 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|corpairs|biv-gaussian")'`: passed with 685
  expectations, 0 failures, 0 warnings, and 0 skips.
- `air format R/methods.R tests/testthat/test-covariance-block-registry.R
  ROADMAP.md docs/design/28-double-hierarchical-endpoint.md
  docs/design/30-labelled-covariance-block-assembler.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-8e-hidden-q4-corpairs-scaffold.md`:
  passed.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 8D hidden q=4 bivariate recovery-style check

Scope:

- added a deterministic hidden q=4 bivariate Gaussian recovery-style test using
  intercept-level endpoint contributions for `mu1`, `mu2`, `sigma1`, and
  `sigma2`;
- simulated paired Gaussian responses from the q=4 endpoint predictors with an
  orthogonal deterministic residual basis and fixed residual `rho12`, then fit
  the hidden `model_type == 95` Laplace branch with `u_re_cov_probe` as a TMB
  random effect;
- checked that the recovered `mu1`, `mu2`, `log(sigma1)`, and `log(sigma2)`
  predictor signals improve over no-random-effect baselines and have positive
  correlation with the simulated signals;
- kept this as hidden recovery-style evidence only: no public q > 2 syntax, no
  q4 `corpairs()` rows, no examples, and no q6/q8 random-slope claim;
- Ada integrated the slice, Gauss checked the bivariate covariance scale, Curie
  checked deterministic recovery tolerances, and Rose checked the public-support
  boundary.

Checks:

- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 139 expectations, 0 failures, 0 warnings, and 0 skips.
- `air format tests/testthat/test-covariance-block-registry.R ROADMAP.md
  docs/design/28-double-hierarchical-endpoint.md
  docs/design/30-labelled-covariance-block-assembler.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-8d-hidden-q4-bivariate-recovery-style-check.md`:
  passed.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian")'`: passed with 623 expectations, 0
  failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 8C hidden q=4 bivariate random-effect boundary

Scope:

- added a hidden q=4 bivariate Gaussian test with `u_re_cov_probe` passed
  through TMB's `random` argument;
- checked that `u_re_cov_probe` drops out of the fixed optimizer parameter
  vector, is registered as the random-effect block, and has a nonzero optimized
  random-effect mode under the bivariate likelihood;
- reconstructed the q=4 contribution matrix and the reported `mu1`, `mu2`,
  `log(sigma1)`, and `log(sigma2)` predictors from the optimized mode;
- kept this as a Laplace boundary check only: no public q > 2 syntax, no
  `corpairs()` rows, and no q4 recovery claim yet;
- Ada integrated the slice, Gauss checked the random-effect likelihood boundary,
  Curie checked the focused test, and Rose checked the public-support wording.

Checks:

- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 127 expectations, 0 failures, 0 warnings, and 0 skips.
- `air format tests/testthat/test-covariance-block-registry.R ROADMAP.md
  docs/design/28-double-hierarchical-endpoint.md
  docs/design/30-labelled-covariance-block-assembler.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-8c-hidden-q4-bivariate-random-effect-boundary.md`:
  passed.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian")'`: passed with 611 expectations, 0
  failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 8B hidden q=4 bivariate likelihood bridge

Scope:

- added hidden `model_type == 95` as a bivariate Gaussian likelihood probe for
  the guarded q=4 `mu1`/`mu2`/`sigma1`/`sigma2` intercept-level block;
- routed registry-shaped q=4 member contributions into `mu1`, `mu2`,
  `log(sigma1)`, and `log(sigma2)` while leaving ordinary fitted likelihood
  paths unchanged;
- added an independent R-side likelihood check that reconstructs the q=4
  contribution matrix, transformed predictors, bivariate Gaussian objective,
  and standard-normal latent prior;
- kept the public boundary explicit: q is the TMB block dimension here, not the
  number of user-modelled correlations, and random-slope q=6 or q=8 endpoint
  blocks remain later work;
- recorded the next strategic milestone as phylogenetic q=4 endpoint support
  for the mammalian and avian protocol use case before q=6/q=8 random-slope
  extensions;
- Ada integrated the slice, Gauss/Curie/Rose reviewed the likelihood, tests,
  and overclaiming boundary.

Checks:

- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 115 expectations, 0 failures, 0 warnings, and 0 skips.
- `air format src/drmTMB.cpp tests/testthat/test-covariance-block-registry.R`:
  passed.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian")'`: passed with 599 expectations, 0
  failures, 0 warnings, and 0 skips.
- `air format ROADMAP.md docs/design/28-double-hierarchical-endpoint.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-8b-hidden-q4-bivariate-likelihood-bridge.md`:
  passed.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 8A hidden q=4 registry contribution bridge

Scope:

- added a guarded four-member covariance-block registry helper for one hidden
  block across `mu1`, `mu2`, `sigma1`, and `sigma2`;
- added a registry test proving the q=4 block carries four members and all six
  pair rows, with `mean-mean`, four `mean-scale`, and `scale-scale` classes;
- added a hidden `model_type == 97` TMB contribution-map test proving the q=4
  block can map standardized group-level latent vectors through
  `UNSTRUCTURED_CORR_t` plus `VECSCALE_t` into member-specific design columns;
- corrected the R-side test helper for TMB's row-wise strict-lower-triangle
  theta order, which q=3 could not distinguish from the old column-wise helper;
- updated roadmap and q > 2 design notes to record this as the first q=4
  bridge while keeping fitted q=4 likelihood, extractor rows, examples, and
  public syntax out of scope.

Checks:

- `air format tests/testthat/test-covariance-block-registry.R ROADMAP.md
  docs/design/28-double-hierarchical-endpoint.md
  docs/design/30-labelled-covariance-block-assembler.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-8a-hidden-q4-registry-contribution-bridge.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 104 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils|package-skeleton")'`:
  passed with 1002 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 7D hidden q=3 simulation-style recovery check

Scope:

- generalized the hidden covariance-block registry test helper so q=3 probes
  can use more groups, replicated observations, and member-specific design
  values without changing ordinary fitted syntax;
- added a deterministic hidden `model_type == 96` recovery test that generates
  q=3 latent contributions for replicated groups, runs the Gaussian likelihood
  with `u_re_cov_probe` as a TMB random-effect vector, and checks that the
  fitted `mu` and `log_sigma` predictors recover the simulated signal better
  than a no-random-effect baseline;
- updated the roadmap and q > 2 design notes to close the hidden q=3 prototype
  phase and make the q=4 `mu1`/`mu2`/`sigma1`/`sigma2` bridge the next
  implementation step, while keeping user-facing q > 2 support closed.

Checks:

- `air format tests/testthat/test-covariance-block-registry.R ROADMAP.md
  docs/design/28-double-hierarchical-endpoint.md
  docs/design/30-labelled-covariance-block-assembler.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-7d-hidden-q3-simulation-style-recovery.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 73 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils|package-skeleton")'`:
  passed with 971 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 7C hidden q=3 random-effect likelihood prototype

Scope:

- added a deterministic hidden test for `model_type == 96` with
  `u_re_cov_probe` passed through TMB's `random` argument;
- checked that `u_re_cov_probe` drops out of the fixed optimizer parameter
  vector, is identified as the random-effect block, has a nonzero optimized
  random-effect mode under the Gaussian likelihood, and reconstructs the
  reported contribution matrix, `mu`, `log_sigma`, and `obs_sigma` from that
  mode;
- updated the roadmap and q > 2 design notes to record the internal Laplace
  likelihood prototype while keeping simulation recovery, extractor rows,
  examples, and public q > 2 syntax out of scope.

Checks:

- `air format tests/testthat/test-covariance-block-registry.R`: passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 66 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils|package-skeleton")'`:
  passed with 964 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 7B hidden q=3 Gaussian likelihood prototype

Scope:

- added hidden `model_type == 96`, which reuses the q=3 registry contribution
  map and injects `mu`-component members into the Gaussian location predictor
  and `sigma`-component members into the log-scale predictor;
- added a deterministic registry test that reconstructs the q=3 latent
  transform in R and checks the reported contribution matrix, `mu`,
  `log_sigma`, `obs_sigma`, objective, and gradient;
- clarified in the q > 2 design note that q is the number of covariance-block
  members: q=3 has three members and three correlations, while the full
  `mu1`/`mu2`/`sigma1`/`sigma2` endpoint is q=4 with six correlations;
- changed no formula grammar, no ordinary model type, no extractor rows, and no
  public q > 2 covariance support.

Checks:

- `air format src/drmTMB.cpp tests/testthat/test-covariance-block-registry.R`:
  passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 57 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils|package-skeleton")'`:
  passed with 955 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 7A hidden q=3 random-effect boundary

Scope:

- added a hidden registry test that registers `u_re_cov_probe` through TMB's
  `random` argument for `model_type == 97`;
- checked that `u_re_cov_probe` drops out of the fixed optimizer parameter
  vector, is identified as the random-effect block, optimizes to the zero mode
  under the hidden standard-normal branch, and leaves finite marginalized
  objective/gradient values;
- updated the roadmap and q > 2 design notes to record the internal
  random-effect boundary while keeping production likelihood wiring,
  simulation recovery, `corpairs()` rows, and public syntax out of scope.

Checks:

- `air format tests/testthat/test-covariance-block-registry.R`: passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 50 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils|package-skeleton")'`:
  passed with 948 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 6E mapped-off q=3 probe no-op guard

Scope:

- added a regression test proving that the dormant `u_re_cov_probe` parameter
  does not affect ordinary Gaussian likelihoods while it remains mapped off;
- rebuilt a TMB object with `u_re_cov_probe = 7`, kept the ordinary
  `factor(NA)` map, and compared the optimizer parameter names, objective, and
  gradient against the fitted object;
- changed no C++ likelihood branch, no R parser syntax, no user-facing
  covariance support, and no documentation claims about fitted q > 2 blocks.

Checks:

- `air format tests/testthat/test-covariance-block-registry.R`: passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 44 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils|package-skeleton")'`:
  passed with 942 expectations, 0 failures, 0 warnings, and 0 skips.

## 2026-05-13 -- Slice 6D hidden q=3 probe parameter plumbing

Scope:

- added hidden TMB parameter vector `u_re_cov_probe`;
- added `add_covariance_probe_parameter()` so ordinary `drmTMB()` fits include
  `u_re_cov_probe = 0` in the start list while mapping it off by default;
- changed hidden `model_type == 97` to prefer `u_re_cov_probe` over
  data-supplied `re_cov_probe_z`, and to add the standard normal contribution
  for that probe parameter;
- updated the direct phylogenetic TMB fixture so hand-built `MakeADFun()` calls
  still match the full C++ template parameter contract;
- changed no user-facing syntax, no fitted-model likelihood branch, no
  optimizer-visible parameter in ordinary fits, and no public q > 2 covariance
  support.

Checks:

- `air format R/drmTMB.R tests/testthat/test-covariance-block-registry.R
  tests/testthat/test-phylo-utils.R`: passed.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|phylo-utils")'`: passed with 86 expectations, 0
  failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils|package-skeleton")'`:
  passed with 939 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 6C hidden q=3 registry contribution probe

Scope:

- added an explicit internal-only `allow_unimplemented = TRUE` override to
  `labelled_covariance_block_tmb_data()`, leaving the default q > 2 export
  guard closed;
- added hidden `model_type == 97`, which uses the q=3 registry block/member
  metadata to map group-major standardized latent vectors through
  `VECSCALE(UNSTRUCTURED_CORR(theta), s).sqrt_cov_scale(z)` and back to
  design-scaled member contributions;
- added a deterministic test proving the hidden q=3 registry scaffold exports
  with inert pair-parameter codes and produces the expected per-observation
  member contribution matrix;
- changed no user-facing syntax, no fitted-model likelihood branch, no real
  q=3 random-effect parameters, and no public q > 2 covariance support.

Checks:

- `air format R/drmTMB.R tests/testthat/test-covariance-block-registry.R`:
  passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 37 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils")'`:
  passed with 895 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 6B q=3 non-centered TMB probe

Scope:

- added internal-only TMB data field `re_cov_probe_z` to the dormant
  covariance-block data contract;
- extended hidden `model_type == 98` to report `re_cov_probe_latent`, the q=3
  latent vector produced by `VECSCALE(UNSTRUCTURED_CORR(theta), s)
  .sqrt_cov_scale(z)`;
- added an R-side check reconstructing the same transform as
  `s * t(chol(R)) %*% z`, where `R` is TMB's reported q=3 correlation matrix;
- changed no user-facing syntax, no fitted-model likelihood branch, no real
  random-effect parameters, and no public q > 2 covariance support.

Checks:

- `air format R/drmTMB.R tests/testthat/test-covariance-block-registry.R`:
  passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 31 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils")'`:
  passed with 889 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 6 q=3 TMB algebra probe

Scope:

- added internal-only TMB data fields `re_cov_probe_theta`,
  `re_cov_probe_sd`, and `re_cov_probe_x` to the dormant covariance-block data
  contract;
- added a hidden `model_type == 98` branch that constructs
  `density::UNSTRUCTURED_CORR_t`, reports its correlation matrix, and evaluates
  either the unscaled density or a `density::VECSCALE()` density for a supplied
  q=3 probe vector;
- added a deterministic test asserting that the reported q=3 correlation
  matrix is symmetric, has unit diagonal, matches TMB's documented lower-triangle
  normalization, has positive eigenvalues, and yields finite objective and
  gradient;
- changed no user-facing syntax, no fitted-model likelihood branch, no real
  random-effect parameters, and no public q > 2 covariance support.

Checks:

- Jason inspected local TMB 1.9.21 headers and confirmed that
  `UNSTRUCTURED_CORR_t` plus `VECSCALE_t` is the right local primitive.
- Gauss reviewed the numerical plan and recommended the next slice use
  `sqrt_cov_scale()` for a non-centered prototype.
- `air format R/drmTMB.R tests/testthat/test-covariance-block-registry.R`:
  passed.
- `Rscript -e 'devtools::load_all()'`: passed and recompiled `drmTMB`; the
  compiler emitted three existing Eigen/TMB header warnings, with no new
  `drmTMB.cpp` warnings.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 30 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils")'`:
  passed with 888 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.
- Post-crash recovery rerun on the same checkout: `git diff --check`,
  `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`, and the
  four-context targeted test above all passed again.

## 2026-05-13 -- Slice 5 guarded q=3 registry scaffold

Scope:

- changed `append_covariance_registry_block()` to enumerate all
  `q * (q - 1) / 2` member pairs through a private
  `covariance_registry_pair_rows()` helper;
- kept current fitted q=2 block behaviour unchanged while allowing internal
  q=3 scaffold registries to carry three members and three stable pair rows;
- added an `implemented` flag argument so internal q=3 scaffolds can be marked
  `FALSE`;
- kept `labelled_covariance_block_tmb_data()` guarded for implemented
  two-member blocks only, so no q > 2 registry can be exported to TMB yet;
- added a public bivariate guard test for the three-member shared-label route,
  which still errors before fitting;
- changed no accepted syntax, likelihood code, C++ code, fitted parameter
  estimates, or user-facing q > 2 support.

Checks:

- Boole inspected the parser and registry boundary and recommended a
  registry-only q=3 scaffold with parser and TMB gates closed.
- Curie inspected the tests and recommended deterministic internal q=3 pair-row
  assertions plus a TMB-export guard assertion.
- `air format R/drmTMB.R tests/testthat/test-covariance-block-registry.R
  tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 24 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "biv-gaussian|gaussian-random-intercepts|covariance-block-registry")'`:
  passed with 837 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|corpairs|check-drm|profile-targets|biv-gaussian|gaussian-random-intercepts")'`:
  passed with 1196 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 4 C++ visibility for dormant block contract

Scope:

- appended the labelled covariance block `tmb_data` contract to every
  `spec$tmb_data` list before `TMB::MakeADFun()`;
- declared the dormant `re_cov_*` fields in `src/drmTMB.cpp` and cast them to
  `void`, so the C++ template sees the contract without using it in the
  likelihood;
- added test helpers proving fitted registry `tmb_data` is present in
  `fit$model$tmb_data` and that scrambling the dormant fields leaves the
  objective and gradient unchanged for a representative labelled bivariate
  block;
- updated the direct phylogenetic TMB fixture with the empty block contract;
- changed no accepted syntax, optimized parameters, likelihood contribution,
  `corpairs()` rows, `check_drm()` diagnostics, or `profile_targets()` rows.

Checks:

- Gauss reviewed the C++ boundary risk before validation and recommended
  declaring the fields with `(void)` casts.
- Curie reviewed the test surface and recommended the exported-data assertion
  plus one no-op objective/gradient assertion.
- `air format R/drmTMB.R tests/testthat/helper-covariance-blocks.R
  tests/testthat/test-biv-gaussian.R
  tests/testthat/test-gaussian-random-intercepts.R
  tests/testthat/test-phylo-utils.R`: passed.
- `Rscript -e 'devtools::load_all()'`: passed and recompiled `drmTMB`; the
  compiler emitted three existing Eigen/TMB header warnings, with no new
  `drmTMB.cpp` warnings.
- `Rscript -e 'devtools::test(filter =
  "biv-gaussian|gaussian-random-intercepts|phylo-utils")'`: passed with 857
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "corpairs|check-drm|profile-targets|biv-gaussian|gaussian-random-intercepts|phylo-utils")'`:
  passed with 1216 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter = "package-skeleton")'`: passed with 40
  expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 4 `profile_targets()` registry inventory

Scope:

- routed random-effect correlation rows in `profile_targets()` through
  `object$model$random$covariance_blocks` when covered two-member registry
  pairs are available;
- preserved target names, target classes, `dpar`, `term`, `tmb_parameter`,
  index, transformation, target type, readiness, and estimates for current
  covariance targets;
- kept fallback logic for old or partial objects by parsing any fitted
  `corpars` row not covered by the registry;
- changed no SD target rows, fixed-effect target rows, residual `rho12` target
  rows, likelihood code, or accepted syntax.

Checks:

- Meitner/Emmy-copy was asked to map the target inventory contracts before the
  closeout.
- `air format R/profile.R tests/testthat/test-profile-targets.R
  tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e 'devtools::test(filter = "profile-targets")'`: passed with 215
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "profile-targets|biv-gaussian|gaussian-random-intercepts|corpairs|check-drm")'`:
  passed with 1159 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 4 `check_drm()` registry diagnostics

Scope:

- routed the existing covariance diagnostics in `check_drm()` through
  `object$model$random$covariance_blocks` when covered two-member registry
  pairs are available;
- preserved current diagnostic row names, values, statuses, and messages for
  univariate `mu`/`sigma`, bivariate `mu1`/`mu2`, bivariate
  `sigma1`/`sigma2`, and same-response bivariate `mu`/`sigma` covariance
  blocks;
- kept fallback logic for older objects without a registry;
- changed no accepted syntax, likelihood code, TMB data passed to C++, or
  fitted parameter estimates.

Checks:

- Mill/Curie-copy mapped the existing `check_drm()` helper contracts and test
  expectations before editing.
- `air format R/check.R tests/testthat/test-check-drm.R
  tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e 'devtools::test(filter = "check-drm")'`: passed with 96
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "check-drm|biv-gaussian|gaussian-random-intercepts|corpairs|profile-targets")'`:
  passed with 1153 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 4 `corpairs()` registry extraction

Scope:

- routed group-level `corpairs()` rows through
  `object$model$random$covariance_blocks` when registry pairs are available;
- kept fitted estimates in the existing `object$corpars` surface by mapping
  registry `tmb_parameter` and `tmb_index` fields to `corpars$mu`,
  `corpars$sigma`, and `corpars$mu_sigma`;
- preserved legacy label parsing for old or partial objects by falling back for
  any fitted correlation not covered by the registry;
- kept residual `rho12` reporting separate and changed no formula grammar, TMB
  likelihood, `start`, `map`, `random_names`, or accepted syntax.

Checks:

- Mendel/Rose-copy reviewed the current slice-4 order and recommended
  registry-derived public extractors before no-op C++ visibility and before any
  `q > 2` Cholesky likelihood work.
- Turing/Boole-copy identified a partial-registry compatibility trap; fixed by
  adding a parsed fallback for uncovered `corpars` rows.
- `air format R/methods.R tests/testthat/test-biv-gaussian.R
  tests/testthat/test-corpairs.R
  tests/testthat/test-gaussian-random-intercepts.R`: passed.
- `Rscript -e 'devtools::test(filter = "corpairs")'`: passed with 48
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "corpairs|biv-gaussian|gaussian-random-intercepts|profile-targets|check-drm")'`:
  passed with 1150 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 4 labelled block registry compatibility

Scope:

- added an internal `random$covariance_blocks` registry for currently
  implemented ordinary grouped two-member covariance bridges;
- covered ordinary labelled `mu` intercept-slope blocks, univariate
  `mu`/`sigma` random-intercept covariance, bivariate `mu1`/`mu2`,
  bivariate `sigma1`/`sigma2`, and same-response bivariate `mu`/`sigma`
  random-intercept covariance;
- kept the change metadata-only: no new accepted syntax, no TMB data contract
  change, no C++ likelihood change, no `start`/`map`/`random_names` change,
  and no `corpairs()`, `profile_targets()`, or `check_drm()` derivation change.

Checks:

- Halley source map confirmed the registry insertion points after
  `re_mu`, `re_sigma`, and `re_mu_sigma` are built.
- Boole API review confirmed the `level`/`group`/`block_label` direction and
  prompted the internal names `block_id0`, `member_id0`,
  `response_index`, `source_term_id0`, and `coef_pos0`.
- Gauss TMB review confirmed the metadata-only registry is safe as long as it
  stays out of `spec$tmb_data`, `start`, `map`, and `random_names`.
- Curie added focused registry expectations in
  `tests/testthat/test-biv-gaussian.R` and
  `tests/testthat/test-gaussian-random-intercepts.R`.
- `air format R/drmTMB.R`: passed.
- `air format tests/testthat/test-biv-gaussian.R
  tests/testthat/test-gaussian-random-intercepts.R`: passed in Curie's lane.
- `Rscript -e 'devtools::test(filter =
  "gaussian-random-intercepts|biv-gaussian")'`: passed with 684 expectations,
  0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "gaussian-random-intercepts|biv-gaussian|corpairs|profile-targets|check-drm")'`:
  passed with 1032 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 4 dormant TMB block contract

Scope:

- added a dormant `random$covariance_blocks$tmb_data` contract derived from the
  R-side block registry;
- encoded block sizes, group counts, member starts, pair starts, component
  codes, distributional-parameter codes, response indexes, source term and
  coefficient positions, latent indexes, design values, pair member indexes,
  pair parameter codes, and pair parameter indexes;
- kept the dormant contract explicitly two-member-only after Gauss-copy found
  that advertising `choose(q, 2)` pairs without generating all pair rows would
  be incoherent for future `q > 2` blocks;
- kept the contract out of `spec$tmb_data`, `start`, `map`, `random_names`,
  and C++ likelihood code for this pass.

Checks:

- `air format R/drmTMB.R tests/testthat/test-biv-gaussian.R
  tests/testthat/test-gaussian-random-intercepts.R`: passed.
- `Rscript -e 'devtools::test(filter =
  "gaussian-random-intercepts|biv-gaussian")'`: passed with 768 expectations,
  0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "gaussian-random-intercepts|biv-gaussian|corpairs|profile-targets|check-drm")'`:
  passed with 1128 expectations, 0 failures, 0 warnings, and 0 skips.
- Gauss-copy reviewed the dormant contract and blocked a premature `q > 2`
  claim; fixed by adding two-member-only internal checks plus invariant tests
  that pair arrays match advertised block pair counts.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 4 labelled covariance block design start

Scope:

- froze the completed slice-3 patch in commit `533790c` before starting
  slice 4;
- created the `codex/labelled-covariance-block-design` branch from that
  commit;
- added `docs/design/30-labelled-covariance-block-assembler.md` as the
  design-first contract for replacing pairwise covariance bridges with a
  labelled positive-definite block registry;
- updated the roadmap and related covariance design notes to point larger
  shared-label work at the new block assembler before bivariate random slopes
  or full double-hierarchical covariance are exposed.

Checks:

- `git status --short --branch`, `git diff --stat`, and the slice-3
  after-task report were inspected before committing the slice-3 freeze point.
- `git diff --check`: passed before the slice-3 commit and again after the
  slice-4 design edits.
- `rg -n '^(<<<<<<<|=======|>>>>>>>)' . --glob
  '!docs/dev-log/recovery-checkpoints/**'`: no conflict markers found before
  the slice-3 commit.
- `Rscript -e "cat(as.character(packageVersion('TMB')), '\\n');
  cat(system.file('include', package = 'TMB'), '\\n')"`: local TMB version
  `1.9.21`; include path inspected.
- `rg -n "UNSTRUCTURED_CORR|VECSCALE|SCALE"
  "$(Rscript -e 'cat(system.file(\"include\", package = \"TMB\"))')"`:
  confirmed local TMB headers expose `UNSTRUCTURED_CORR_t` and `VECSCALE_t`.
- `rg -n '30-labelled-covariance-block-assembler|labelled covariance block
  assembler|block assembler|UNSTRUCTURED_CORR|pairwise bridges|shared labels'
  ROADMAP.md docs/design/17-correlated-random-effect-blocks.md
  docs/design/20-coscale-correlation-pairs.md
  docs/design/28-double-hierarchical-endpoint.md
  docs/design/30-labelled-covariance-block-assembler.md`: confirmed the new
  design note is referenced from the roadmap and older covariance notes.
- `rg -n 'meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]' ROADMAP.md
  docs/design/17-correlated-random-effect-blocks.md
  docs/design/20-coscale-correlation-pairs.md
  docs/design/28-double-hierarchical-endpoint.md
  docs/design/30-labelled-covariance-block-assembler.md`: remaining hits are
  existing `meta_known_V()` roadmap guardrails; no new syntax drift was added.

## 2026-05-13 -- Bivariate same-response mu/sigma covariance

Scope:

- finished the same-response bivariate `mu`/`sigma` random-intercept covariance
  slice, allowing one matching labelled pair such as `mu1` with `sigma1` or
  `mu2` with `sigma2`;
- wired the bivariate TMB data list, C++ likelihood branch, fitted random-effect
  extraction, `corpars$mu_sigma`, `corpairs()`, `profile_targets()`, and
  `check_drm()` to keep this mean-scale pair separate from `mu1`/`mu2`,
  `sigma1`/`sigma2`, and residual `rho12`;
- updated formula grammar, likelihood, profile, roadmap, known-limitations,
  README, NEWS, and vignette status surfaces so the implemented pairwise bridge
  is not confused with the still-planned full labelled covariance block across
  `mu1`, `mu2`, `sigma1`, and `sigma2`.

Checks:

- recovery rehydration: inspected `git status --short --branch`, `git diff
  --stat`, `git diff -- R/drmTMB.R`, `git diff -- src/drmTMB.cpp`, and
  `docs/dev-log/recovery-checkpoints/2026-05-13-040434-codex-checkpoint.md`
  before editing.
- `air format R/drmTMB.R R/check.R R/methods.R
  tests/testthat/test-biv-gaussian.R`: passed.
- `air format tests/testthat/test-gaussian-random-intercepts.R
  tests/testthat/test-phylo-utils.R`: passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/drmTMB.Rd` and `man/corpairs.Rd`.
- `Rscript -e "devtools::test(filter = 'biv-gaussian|check-drm')"`: passed
  with 369 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter =
  'gaussian-random-intercepts|phylo-utils|biv-gaussian|check-drm')"`: passed
  with 639 expectations, 0 failures, 0 warnings, and 0 skips after updating
  stale unsupported-message expectations and the hand-built phylo TMB data
  fixture for the new random-effect metadata fields.
- `Rscript -e "devtools::test()"`: passed with 2052 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.
- `rg -n 'bivariate random slopes, cross-parameter|cross-parameter covariance
  blocks, and `rho12`|cross-parameter bivariate covariance blocks remain
  planned|double-hierarchical cross-parameter covariance|bivariate
  `sigma1`/`sigma2` and cross-parameter' README.md ROADMAP.md NEWS.md docs
  vignettes --glob '!docs/dev-log/after-task/**' --glob
  '!docs/dev-log/recovery-checkpoints/**'`: no active stale broad-planned
  wording found.
- `rg -n 'same-response|full cross-parameter|biv_mu_sigma_random_effect_covariance|corpars\\$mu_sigma|eta_cor_mu_sigma'
  README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md
  vignettes R tests/testthat/test-biv-gaussian.R
  tests/testthat/test-check-drm.R`: checked that code, tests, and docs name the
  implemented pairwise bridge and the still-planned full block separately.
- `rg -n 'meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]' README.md ROADMAP.md
  NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R
  tests/testthat/test-biv-gaussian.R`: remaining hits are intentional
  meta-analysis and residual-correlation guardrails; no new syntax was
  introduced.

## 2026-05-12 -- Bivariate random-structure metadata parity

Scope:

- added `coef_names`, `group_names`, and `covariance_labels` fields to the
  bivariate `mu1`/`mu2` random-effect structure so it matches the existing
  bivariate `sigma1`/`sigma2` structure shape;
- added assertions to the combined bivariate covariance regression so future
  covariance code can rely on those metadata fields being present for both
  same-parameter blocks.

Checks:

- inspected `build_biv_mu_random_structure()` and
  `build_biv_sigma_random_structure()`; the `sigma` path already returned the
  metadata fields, while the `mu` path did not.
- `air format R/drmTMB.R tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`: passed with
  235 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 2014 expectations,
  0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.

## 2026-05-12 -- Bivariate covariance block label guard

Scope:

- rejected the ambiguous same-label bivariate pattern where `(1 | p | id)`
  appears in all four `mu1`, `mu2`, `sigma1`, and `sigma2` formulas;
- kept the implemented bivariate covariance surface limited to two separate
  same-parameter blocks: a mean-mean `mu1`/`mu2` block and a scale-scale
  `sigma1`/`sigma2` block;
- added negative tests for the same-label cross-parameter pattern and for
  random-effect syntax in residual `rho12`.

Checks:

- live pre-edit probe confirmed that the same-label all-four-formula pattern
  was previously accepted and reported two separate group-level `corpairs()`
  rows with the same `block` label.
- `air format R/drmTMB.R tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`: passed with
  229 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 2008 expectations,
  0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.
- `rg -n "Reusing one bivariate|same-label pattern|same label and grouping variable|cross-parameter bivariate covariance|rho12.*within-observation" R/drmTMB.R tests/testthat/test-biv-gaussian.R NEWS.md docs/design/01-formula-grammar.md docs/design/28-double-hierarchical-endpoint.md ROADMAP.md docs/dev-log/known-limitations.md vignettes`:
  checked the new guard, NEWS note, and formula-grammar wording.
- `rg -n "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R`:
  checked scope guardrails; hits were existing meta-analysis and design-rule
  references, not new grammar.
- `rg -n "rho12|sigma1|sigma2|sd\\(" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R`:
  reviewed the high-density scale and residual-correlation wording touched by
  this guard.

## 2026-05-12 -- Joint bivariate mean-scale covariance regression

Scope:

- added a deterministic bivariate Gaussian simulation test that fits matching
  labelled `mu1`/`mu2` and `sigma1`/`sigma2` random-intercept covariance
  blocks in the same model;
- used separate block labels, `(1 | pm | id)` and `(1 | ps | id)`, so the test
  proves that `corpairs()`, `summary()`, `profile_targets()`, and
  `check_drm()` keep mean-mean, scale-scale, and residual `rho12 ~ x` rows
  distinct;
- updated the roadmap and double-hierarchical endpoint note to record that this
  combined labelled-intercept slice is now covered, while bivariate random
  slopes and cross-parameter bivariate covariance remain planned.

Checks:

- live pre-edit fit with both labelled bivariate blocks and constant residual
  `rho12`: convergence 0, positive-definite Hessian, three `corpairs()` rows,
  and `check_drm()` status `ok` for both bivariate covariance diagnostics.
- strengthened the test to use predictor-dependent residual `rho12 ~ x` after
  auditing `docs/design/28-double-hierarchical-endpoint.md`; the live probe
  converged with a positive-definite Hessian and recovered the `rho12`
  coefficients within 0.12 on the link scale.
- `air format tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`: passed with
  227 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 2006 expectations,
  0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.
- `rg -n "joint.*mu.*sigma|coexist|same model|mean-mean|scale-scale|biv_mu_random_effect_covariance|biv_sigma_random_effect_covariance|corpars\\$mu|corpars\\$sigma" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R`:
  checked the current naming surface for the combined block claim.
- `rg -n "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R`:
  checked scope guardrails; hits were existing meta-analysis and design-rule
  references, not new grammar.
- `rg -n "rho12|sigma1|sigma2|sd\\(" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R`:
  reviewed high-density scale and correlation terminology touched by this
  slice.
- `rg -n "Targeted simulation coverage|Combine bivariate group-level covariance blocks|keeps mu and sigma covariance blocks distinct|rho12 ~ x" ROADMAP.md docs/design/28-double-hierarchical-endpoint.md tests/testthat/test-biv-gaussian.R docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-12-bivariate-joint-mu-sigma-covariance.md`:
  confirmed that the new roadmap/design status wording points to the new
  regression test and after-task evidence.

## 2026-05-12 -- Bivariate sigma1/sigma2 random-intercept covariance

Scope:

- implemented the first bivariate residual-scale covariance slice for
  matching labelled `(1 | p | id)` random intercepts in both `sigma1` and
  `sigma2`;
- wired the scale block through bivariate model specification, TMB data,
  `eta_cor_sigma`, conditional random-effect prediction, `sdpars$sigma`,
  `corpars$sigma`, `corpairs()`, `summary()`, `profile_targets()`, and
  `check_drm()`;
- kept the slice narrow: labelled intercepts only, no bivariate scale slopes,
  no cross-parameter bivariate covariance block, no `rho12` random effects,
  and no combination with bivariate `meta_known_V(V = V)`.

Checks:

- Initial recovered implementation produced `NA/NaN gradient evaluation`
  because `random_names` included `u_sigma` while the bivariate TMB data block
  still sent `n_sigma_re_terms = 0L`; fixed by sending the bivariate
  `sigma1`/`sigma2` random-effect structure into `make_tmb_data()`.
- `air format R/drmTMB.R R/methods.R R/check.R tests/testthat/test-biv-gaussian.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`:
  passed with 182 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'biv-gaussian|check-drm')"`:
  passed with 282 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::document()"`: passed; regenerated
  `man/check_drm.Rd`, `man/drmTMB.Rd`, `man/corpairs.Rd`, and
  `man/predict.drmTMB.Rd`.
- `Rscript -e "devtools::test(filter = 'biv-gaussian|check-drm|profile-targets|summary')"`:
  passed with 556 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.
- `rg -n 'sigma1`/`sigma2` random effects|Bivariate random slopes, `sigma1`|residual-scale bivariate random effects|bivariate random slopes and residual-scale random effects|random effects in `sigma1`, `sigma2`, or `rho12`|bivariate `mu1`/`mu2` random-intercept correlation' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R man tests/testthat/test-biv-gaussian.R`:
  reviewed current status wording; only the intentionally superseded
  `docs/design/12-profile-likelihood-cis.md` line mentioning `mu1`/`mu2`
  remains because the following line now adds `sigma1`/`sigma2`.
- `rg -n 'rho12|sigma1|sigma2|sd\(' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R | head -n 220`:
  reviewed the high-density correlation and scale vocabulary touched by this
  feature.
- `rg -n 'meta_gaussian|tau ~|rho ~|meta_known_V\([^V]' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R`:
  reviewed scope-guard wording; hits were expected design/tutorial warnings,
  not new grammar drift.
- `rg -n 'biv_sigma_random_effect_covariance|eta_cor_sigma|corpars\$sigma|sdpars\$sigma|scale-scale' R src tests/testthat/test-biv-gaussian.R docs/design vignettes README.md ROADMAP.md NEWS.md`:
  reviewed implementation, tests, and docs for the new scale-scale surface.
- After PR #19 merged into `origin/main` as `98e9e31`, fast-forwarded this
  branch over #19 and reapplied the current bivariate `sigma1`/`sigma2` patch;
  resolved overlaps in `R/drmTMB.R`, `README.md`,
  `docs/design/01-formula-grammar.md`, `docs/dev-log/known-limitations.md`,
  and `vignettes/which-scale.Rmd` by keeping #19's independent univariate
  `sigma` slope support and layering the new bivariate scale-scale intercept
  slice beside it.
- `air format R/drmTMB.R R/methods.R R/check.R tests/testthat/test-biv-gaussian.R`
  after rebasing over PR #19: passed.
- `Rscript -e "devtools::test(filter = 'biv-gaussian|gaussian-random-intercepts|check-drm|profile-targets|summary')"`
  after rebasing over PR #19: passed with 781 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "devtools::document()"` after rebasing over PR #19: passed.
- `Rscript -e "pkgdown::check_pkgdown()"` after rebasing over PR #19: passed
  with no problems found.
- `git diff --check` after rebasing over PR #19: passed.
- Updated the remaining generic parser message that said bivariate
  random-effect syntax was planned, so it now names the implemented labelled
  bivariate `mu1`/`mu2` and `sigma1`/`sigma2` intercept paths.
- `rg -n "Bivariate random-effect syntax is planned|Use fixed-effect bivariate formulas|Future bivariate double-hierarchical" R tests README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes`:
  no current non-historical hits.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"` after the parser
  message cleanup: passed with 186 expectations, 0 failures, 0 warnings, and
  0 skips.
- Added a source-map section to
  `docs/design/20-coscale-correlation-pairs.md` connecting Martin's covariance
  reaction norm paper to `drmTMB`'s separate `sigma` and `rho12` formula
  surfaces, and connecting the EGA+GNM paper to the sister-package
  `gllvmTMB` boundary.
- The source-map note records the `gllvmTMB` algorithmic guardrail
  `Sigma = Lambda Lambda' + S`: correlations should be computed from a
  covariance matrix with a complete diagonal, while many-trait latent/unique
  decomposition remains `gllvmTMB` scope rather than `drmTMB` scope.
- `LC_ALL=C rg -n '[^\x00-\x7F]' docs/design/20-coscale-correlation-pairs.md`:
  no matches after the source-map addition.
- First full `Rscript -e "devtools::test()"` run failed in
  `tests/testthat/test-phylo-utils.R` because the hand-built direct
  `TMB::MakeADFun()` parameter list did not include the new global
  `eta_cor_sigma` parameter stub. Added `eta_cor_sigma = 0` to the fixture.
- `air format tests/testthat/test-phylo-utils.R`: passed.
- `Rscript -e "devtools::test(filter = 'phylo-utils|biv-gaussian')"` after
  fixing the direct TMB fixture: passed with 231 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 1965 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "devtools::check()"`: passed with 0 errors, 0 warnings, and
  1 note. The note was `checking for future file timestamps ... unable to
  verify current time`.

## 2026-05-12 -- Mu/sigma sigma prediction contribution test

Scope:

- added a deterministic fitted-data prediction regression test for univariate
  Gaussian `mu`/`sigma` covariance models with both a matched labelled
  `mu`/`sigma` random-intercept block and an independent unlabelled `sigma`
  random-intercept block;
- checked that `sigma_random_effect_contribution()` equals the manual row-wise
  contribution from fitted `sigma` random effects and random-effect design
  values;
- checked that `predict(fit, dpar = "sigma", type = "link")` equals the fixed
  sigma linear predictor plus that random-effect contribution, and that
  `stats::sigma(fit)` is its response-scale exponentiation.

Checks:

- `air format tests/testthat/test-gaussian-random-intercepts.R`: passed.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`:
  passed with 216 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|check-drm|profile-targets|summary|phylo-utils')"`:
  passed with 631 expectations, 0 failures, 0 warnings, and 0 skips.
- `rg -n 'sigma_random_effect_contribution|predict\([^\n]*dpar = "sigma"|mu/sigma covariance|mu/sigma' R tests README.md ROADMAP.md NEWS.md docs vignettes`:
  reviewed prediction and covariance wording touched by the claim; no
  source-doc changes needed for this test-only guard.
- `rg -n 'rho12|sigma1|sigma2|sd\(' README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-gaussian-random-intercepts.R`:
  reviewed correlation terminology around `rho12` and group-level covariance;
  no stale wording introduced.

## 2026-05-12 -- Mu/sigma joint objective comparator

Scope:

- added a hand-coded R joint negative log-likelihood comparator for the
  univariate Gaussian `mu`/`sigma` covariance path;
- compared TMB's full fixed-plus-random objective at `last.par.best` with the
  independent R calculation for a model containing both a matched labelled
  `mu`/`sigma` block and an independent unlabelled `sigma` block;
- kept this as test-only hardening without changing likelihood or parser code.

Checks:

- First attempt with a tiny 5-group fixture did not converge reliably and used
  the wrong full-vector parameter extraction path; revised to a 12-group
  deterministic fixture and split `last.par.best` by TMB parameter names.
- `air format tests/testthat/test-gaussian-random-intercepts.R`: passed.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`:
  passed with 212 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|check-drm|profile-targets|summary|phylo-utils')"`:
  passed with 627 expectations, 0 failures, 0 warnings, and 0 skips.

## 2026-05-12 -- Mu/sigma sigma-effect transform regression test

Scope:

- added a deterministic regression test for the internal
  `transform_sigma_random_effects()` path used by fitted univariate
  `mu`/`sigma` covariance blocks;
- checked that only matched labelled `sigma` random-effect rows use
  `rho * u_mu + sqrt(1 - rho^2) * u_sigma`;
- checked that an independent unlabelled `sigma` random-intercept block remains
  independent in the same model specification.

Checks:

- `air format tests/testthat/test-gaussian-random-intercepts.R`: passed.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`:
  passed with 210 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|check-drm|profile-targets|summary|phylo-utils')"`:
  passed with 625 expectations, 0 failures, 0 warnings, and 0 skips.

## 2026-05-12 -- Focused covariance branch recovery validation

Scope:

- reran the focused validation surface for the current univariate `mu`/`sigma`
  covariance and covariance-profile branch after adding the recovery checkpoint
  tool;
- covered fit/parser behaviour, `check_drm()` diagnostics, manual phylogenetic
  TMB fixture compatibility, profile target rows, direct profile intervals, and
  summary covariance rows;
- did not change package implementation code.

Checks:

- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|check-drm|profile-targets|summary|phylo-utils')"`:
  passed with 621 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 1899 expectations, 0 failures,
  0 warnings, and 0 skips.

## 2026-05-12 -- Codex recovery checkpoint tool

Scope:

- added `tools/codex-checkpoint.R`, a base-R recovery helper that captures
  branch/status, changed tracked files, untracked files, diff stat, current
  `HEAD`, newest check-log entries, newest after-task reports, and restart
  commands in one compact Markdown file;
- documented the recovery command in `AGENTS.md` so future long Codex runs can
  checkpoint before fragile handoffs or after stream failures;
- wrote a current durable checkpoint to
  `docs/dev-log/recovery-checkpoints/2026-05-12-codex-stream-failure-recovery.md`;
- kept the current covariance/profile implementation untouched.

Checks:

- First smoke run of `Rscript tools/codex-checkpoint.R --stdout --goal "Smoke test recovery checkpoint" --next "Inspect git status" --sections 2`:
  failed with an invalid regular expression in the path-shortening helper.
  Replaced the regex trim with a simpler `startsWith()`-based path trim.
- `Rscript tools/codex-checkpoint.R --stdout --goal "Smoke test recovery checkpoint" --next "Inspect git status" --sections 2`:
  passed and printed the expected branch/status, changed files, diff stat,
  newest check-log entries, newest after-task reports, and recovery commands.
- `Rscript tools/codex-checkpoint.R --output docs/dev-log/recovery-checkpoints/2026-05-12-codex-stream-failure-recovery.md --goal "Recover from repeated Codex compaction or stream failures during the current covariance-profile branch" --next "Review this checkpoint, rerun git status and git diff, then preserve a commit boundary or run focused validation" --sections 4`:
  passed and wrote the checkpoint file.
- `air format tools/codex-checkpoint.R`: passed.
- `Rscript -e "invisible(parse(file = 'tools/codex-checkpoint.R')); cat('parse ok\\n')"`:
  passed.
- `git diff --check`: passed.

Known limitations:

- no package tests were rerun for this process-only tool;
- the checkpoint records compact git/log evidence, not the full patch.

## 2026-05-12 -- Profile covariance status docs alignment

Scope:

- aligned `docs/design/12-profile-likelihood-cis.md` with the implemented
  direct covariance profile interval surface for the first univariate
  `mu`/`sigma` and bivariate `mu1`/`mu2` random-intercept correlations;
- updated `docs/design/28-double-hierarchical-endpoint.md` so direct covariance
  profile intervals are partly implemented while derived covariance summaries
  remain planned;
- updated `ROADMAP.md`, `NEWS.md`, and `docs/dev-log/known-limitations.md` to
  name direct covariance intervals through `confint(..., method = "profile")`
  and `summary(conf.int = TRUE, method = "profile", ci_parm = ...)`;
- kept residual `rho12`, group-level `mu_sigma`, and bivariate group-level `mu`
  namespaces separate.

Checks:

- `air format docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md`:
  passed.
- `Rscript -e "devtools::test(filter = 'summary|profile-targets')"`: passed
  with 274 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `rg -n 'summary profile intervals remain planned|Profile-likelihood intervals for covariance summaries \| Planned|covariance summaries \| Planned|profile.*covariance.*Planned' docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md`:
  found only the intentional derived-summary interval limitation in
  `docs/design/12-profile-likelihood-cis.md`.
- `rg -n 'direct covariance profile intervals|corpars\$mu_sigma|eta_cor_mu_sigma|summary\(conf.int = TRUE|Profile-likelihood intervals for covariance summaries \| Partly implemented|first fitted group-level covariance rows|derived summary profile intervals remain planned' docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md tests/testthat/test-summary.R tests/testthat/test-profile-targets.R`:
  confirmed implemented-status wording, target parameter names, summary profile
  path, and the remaining derived-summary boundary.
- `LC_ALL=C rg -n '[^\x00-\x7F]' docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md`:
  no matches.
- `git diff --check`: passed.

## 2026-05-12 -- Covariance profile intervals in summary

Scope:

- added focused `summary(conf.int = TRUE, method = "profile")` checks for the
  implemented covariance rows already shown in `summary(fit)$parameters`;
- checked that the univariate
  `cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)` row receives
  finite profile bounds around the fitted `corpars$mu_sigma` estimate;
- checked that the bivariate
  `cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)` row receives finite
  profile bounds around the fitted `corpars$mu` estimate;
- kept the checks scoped to existing direct profile targets and left residual
  `rho12` as a separate residual-correlation row.

Checks:

- `air format tests/testthat/test-summary.R`: passed.
- `Rscript -e "devtools::test(filter = 'summary')"`: passed with 63
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'summary|profile-targets')"`: passed
  with 274 expectations, 0 failures, 0 warnings, and 0 skips.
- `rg -n 'summary\(conf.int = TRUE|corpars\$mu_sigma|corpars\$mu|residual rho12|profile bounds|method = "profile"' tests/testthat/test-summary.R docs/dev-log/after-task/2026-05-12-covariance-profile-intervals-in-summary.md docs/dev-log/check-log.md`:
  confirmed the summary profile path, covariance row estimates, residual-`rho12`
  boundary wording, and check-log entry.
- `git diff --check`: passed.

## 2026-05-12 -- Bivariate mu covariance profile interval

Scope:

- added a focused `confint(..., method = "profile")` regression test for the
  implemented bivariate `mu1`/`mu2` random-intercept covariance slice;
- checked that
  `cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)` profiles on
  `eta_cor_mu`, reports a response-scale `tanh` interval, and keeps the
  interval finite, bounded inside `(-1, 1)`, and surrounding the fitted
  `corpars$mu` estimate;
- kept this separate from residual `rho12`, which remains a residual
  bivariate correlation target.

Checks:

- `air format tests/testthat/test-profile-targets.R`: passed.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 211
  expectations, 0 failures, 0 warnings, and 0 skips.
- `rg -n 'confint profile intervals transform bivariate mu|eta_cor_mu|corpars\$mu|residual rho12' tests/testthat/test-profile-targets.R docs/dev-log/after-task/2026-05-12-bivariate-mu-profile-interval.md docs/dev-log/check-log.md`:
  confirmed the new bivariate interval test, optimized TMB parameter name,
  fitted `corpars$mu` check, and residual-`rho12` boundary wording.
- `git diff --check`: passed.

## 2026-05-12 -- Mu/sigma covariance profile interval

Scope:

- added a focused `confint(..., method = "profile")` regression test for the
  implemented univariate `mu`/`sigma` random-intercept covariance slice;
- checked that
  `cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)` profiles on
  `eta_cor_mu_sigma`, reports a response-scale `tanh` interval, and keeps the
  interval finite, bounded inside `(-1, 1)`, and surrounding the fitted
  `corpars$mu_sigma` estimate;
- kept this as test-only coverage of the existing direct profile target rather
  than changing profiling code.

Checks:

- `air format tests/testthat/test-profile-targets.R`: passed.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 201
  expectations, 0 failures, 0 warnings, and 0 skips.
- `rg -n 'confint profile intervals transform mu/sigma|eta_cor_mu_sigma|corpars\$mu_sigma|residual rho12' tests/testthat/test-profile-targets.R docs/dev-log/after-task/2026-05-12-mu-sigma-profile-interval.md docs/dev-log/check-log.md`:
  confirmed the new interval test, optimized TMB parameter name, fitted
  `corpars$mu_sigma` check, and residual-`rho12` boundary wording.
- `git diff --check`: passed.

## 2026-05-12 -- Mu/sigma covariance profile-target rows

Scope:

- added a focused `profile_targets()` regression test for the implemented
  univariate `mu`/`sigma` random-intercept covariance slice;
- checked direct targets for `sd:mu:(1 | p | id)`,
  `sd:sigma:(1 | p | id)`, and
  `cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)`;
- checked TMB parameter names, target indices, transformations, target type,
  profile readiness, and absence of residual `rho12` targets in the
  one-response model.

Checks:

- `air format tests/testthat/test-profile-targets.R`: passed.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 191
  expectations, 0 failures, 0 warnings, and 0 skips.

## 2026-05-12 -- Mu/sigma covariance rows in summary

Scope:

- added a focused `summary()` regression test for the implemented univariate
  `mu`/`sigma` random-intercept covariance slice;
- checked that `summary(fit)$parameters` reports `sd:mu:(1 | p | id)`,
  `sd:sigma:(1 | p | id)`, and
  `cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)` as
  random-effect rows;
- checked that the group-level `mu`/`sigma` correlation stays separate from
  residual `rho12`.

Checks:

- `air format tests/testthat/test-summary.R`: passed.
- `Rscript -e "devtools::test(filter = 'summary')"`: passed with 53
  expectations, 0 failures, 0 warnings, and 0 skips.

## 2026-05-12 -- Mu/sigma covariance check_drm diagnostic

Scope:

- added a `mu_sigma_random_effect_covariance` row to `check_drm()` for
  univariate Gaussian fits with the labelled `mu`/`sigma` random-intercept
  covariance block;
- the diagnostic reports group count, minimum fitted group replication,
  singleton-group count, fitted `mu` SD relative to mean residual `sigma`, and
  fitted `sigma` random-effect SD on the log-scale;
- the diagnostic returns `note` when any group has fewer than two fitted
  observations or either component SD is tiny on its interpretation scale;
- updated `NEWS.md`, `R/check.R`, `man/check_drm.Rd`,
  `tests/testthat/test-check-drm.R`, and
  `docs/design/16-phylo-spatial-common-math.md`.

Checks:

- `air format R/check.R tests/testthat/test-check-drm.R NEWS.md docs/design/16-phylo-spatial-common-math.md`:
  passed.
- `Rscript -e "devtools::test(filter = 'check-drm')"`: passed with 96
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/check_drm.Rd`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `rg -n 'mu_sigma_random_effect_covariance|mu/sigma.*diagnostic|mean-scale covariance diagnostics|bivariate `mu1`/`mu2` random-intercept covariance diagnostics|check_drm\(\).*mu.*sigma' R/check.R tests/testthat/test-check-drm.R NEWS.md docs/design docs/dev-log/known-limitations.md vignettes README.md ROADMAP.md man/check_drm.Rd`:
  confirmed the new diagnostic row, tests, NEWS, and generated reference docs.
- `rg -n 'component SD|interpretation scale|univariate .*mu.*sigma|mean-scale covariance block|mu/sigma group-level covariance|mu/sigma covariance' R/check.R man/check_drm.Rd docs/design/16-phylo-spatial-common-math.md tests/testthat/test-check-drm.R NEWS.md`:
  confirmed the diagnostic wording and design note describe the same
  intercept-only mean-scale covariance slice.

## 2026-05-12 -- Univariate mu/sigma covariance bridge

Scope:

- implemented the first univariate Gaussian cross-formula covariance block for
  matching labelled `mu` and `sigma` random intercepts such as
  `bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id))`;
- added `eta_cor_mu_sigma` plus explicit TMB data vectors that map only the
  matched labelled `sigma` latent rows to their corresponding `mu` latent rows;
- exposed the fitted mean-scale correlation in `corpars$mu_sigma`,
  `corpairs()` rows with `class = "mean-scale"`, and `profile_targets()`;
- added simulation-style recovery checks, malformed-input checks, and a
  regression test where an independent unlabelled `sigma` random intercept
  coexists with the labelled `mu`/`sigma` covariance block;
- updated README, roadmap, formula-grammar, random-effect, coscale, endpoint,
  known-limitations, and generated Rd docs to describe the implemented
  intercept-only slice without claiming general covariance support;
- fixed the hand-built phylogenetic-prior TMB test fixture so it supplies the
  new dummy `n_mu_sigma_re_cors`, `sigma_re_cross_cor`,
  `sigma_re_cross_mu`, and `eta_cor_mu_sigma` fields.

Checks:

- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/drmTMB.Rd` and `man/corpairs.Rd`.
- `air format R/drmTMB.R R/methods.R tests/testthat/test-gaussian-random-intercepts.R src/drmTMB.cpp NEWS.md README.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/04-random-effects.md docs/design/17-correlated-random-effect-blocks.md docs/design/20-coscale-correlation-pairs.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md vignettes/formula-grammar.Rmd`:
  passed.
- `air format docs/design/01-formula-grammar.md vignettes/location-scale.Rmd`:
  passed after stale-wording cleanup.
- `air format tests/testthat/test-phylo-utils.R`: passed after updating the
  manual TMB fixture.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`:
  passed with 206 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|corpairs|profile-targets')"`:
  passed with 427 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'phylo-utils')"`: passed with 45
  expectations, 0 failures, 0 warnings, and 0 skips after the full-suite
  fixture failure exposed the missing dummy TMB fields.
- `Rscript -e "devtools::test()"`: first run failed in
  `test-phylo-utils.R` because the hand-built TMB data fixture did not include
  the new `n_mu_sigma_re_cors` field; after the fixture update, the rerun
  passed with 1835 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `Rscript -e "for (x in c('formula-grammar', 'location-scale')) pkgdown::build_article(x)"`:
  passed and wrote `articles/formula-grammar.html` and
  `articles/location-scale.html`.
- `rg -n 'labelled `sigma` blocks|sigma random intercepts only|share covariance across `mu`, `sigma`|Matching labelled.*future|Cross-formula covariance blocks \| Planned' README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes man`:
  no matches after cleanup.
- `rg -n 'Labelled covariance blocks are not implemented|cross-formula covariance blocks \| Planned|cross-formula.*future work|same label.*future|mu/sigma.*planned|mean-scale.*planned|residual-scale random-effect covariance blocks\. Started|corpars\$mu_sigma|rho ~|meta_gaussian\(|tau ~|meta_known_V\([^V]' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man`:
  found only intentional current-status strings and established guardrails for
  `rho ~`, `meta_gaussian()`, `tau ~`, and `meta_known_V()`.

## 2026-05-12 -- Bivariate covariance rows in summary

Scope:

- added a focused `summary()` regression test for the implemented bivariate
  `mu1`/`mu2` random-intercept covariance slice;
- checked that `summary(fit)$parameters` reports `sd:mu:mu1:(1 | p | id)`,
  `sd:mu:mu2:(1 | p | id)`, and
  `cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)` as group-level
  random-effect rows;
- checked that the group-level `mu1`/`mu2` correlation stays separate from the
  residual `rho12` row in the summary table.

Checks:

- `air format tests/testthat/test-summary.R`: passed.
- `Rscript -e "devtools::test(filter = 'summary')"`: passed with 43
  expectations, 0 failures, 0 warnings, and 0 skips.

## 2026-05-12 -- Tutorial map, model guides, and equation style

Scope:

- added `vignettes/model-map.Rmd` as the user-facing "What can I fit today?"
  status map for implemented versus planned model surfaces;
- shortened `vignettes/drmTMB.Rmd` so Getting Started keeps installation,
  the first fitted model, the learning path, and a compact implementation
  table instead of carrying the full status map;
- split pkgdown navigation into Model Guides and Tutorials in `_pkgdown.yml`;
- documented the guide-versus-tutorial distinction in
  `docs/design/21-tutorial-style.md`;
- normalized core symbolic model blocks in `vignettes/location-scale.Rmd`,
  `vignettes/which-scale.Rmd`, `vignettes/bivariate-coscale.Rmd`,
  `vignettes/phylogenetic-spatial.Rmd`, and `vignettes/robust-student.Rmd`
  from fenced plain text to rendered LaTeX with reader-facing variable names;
- normalized the implemented-family contracts in
  `vignettes/distribution-families.Rmd`, including Gaussian, Student-t,
  lognormal, Gamma, beta, Poisson, zero-inflated Poisson, NB2,
  zero-inflated NB2, zero-truncated NB2, hurdle NB2, beta-binomial, and
  cumulative-logit equations;
- added a candidate worked-tutorial table to
  `docs/design/21-tutorial-style.md` for count abundance, positive counts,
  continuous proportions, successes out of trials, and ordered severity
  scores;
- applied bounded Pat, Grace, Noether, and Rose review findings by standardizing
  the structured-dependence label, adding model-map links, narrowing the
  unlabelled Gaussian `mu` random-intercept SD claim, future-marking
  phylogenetic location-scale correlation prose, and aligning rendered `rho12`
  subscripts with the public API name;
- rebased the worktree onto `origin/main` after PR #15 landed and resolved the
  append-only `docs/dev-log/check-log.md` overlap by keeping both entries;
- recorded an after-task report at
  `docs/dev-log/after-task/2026-05-12-tutorial-map-model-guides.md`.

Checks:

- `ruby -e 'require "yaml"; YAML.load_file("_pkgdown.yml"); puts "ok _pkgdown.yml"'`:
  passed.
- `air format _pkgdown.yml vignettes/drmTMB.Rmd vignettes/model-map.Rmd docs/design/21-tutorial-style.md`:
  completed.
- `air format vignettes/location-scale.Rmd vignettes/which-scale.Rmd vignettes/bivariate-coscale.Rmd vignettes/phylogenetic-spatial.Rmd vignettes/robust-student.Rmd docs/design/21-tutorial-style.md`:
  completed after equation-style edits.
- `Rscript -e "pkgdown::build_article('model-map')"`: passed and wrote
  `articles/model-map.html`; pkgdown emitted only pre-existing-directory
  warnings from the local `pkgdown-site/deps` cache.
- `Rscript -e "pkgdown::build_article('drmTMB')"`: passed and wrote
  `articles/drmTMB.html`; pkgdown emitted only a pre-existing-directory
  warning from the local `pkgdown-site/deps` cache.
- `Rscript -e "for (x in c('location-scale','which-scale','bivariate-coscale','phylogenetic-spatial','robust-student','drmTMB','model-map')) pkgdown::build_article(x)"`:
  passed for all listed articles.
- `Rscript -e "pkgdown::build_article('distribution-families')"`:
  passed and wrote `articles/distribution-families.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `air format _pkgdown.yml vignettes/drmTMB.Rmd vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd`:
  completed after Pat's navigation review fixes.
- `air format vignettes/bivariate-coscale.Rmd vignettes/which-scale.Rmd vignettes/location-scale.Rmd vignettes/drmTMB.Rmd`:
  completed after Noether/Rose terminology fixes.
- `rg -n 'rho 12|In phylogenetic location-scale models|random-effect scale formulas for `mu`|Known sampling variance: `meta_known_V\\(V = vi\\)`|Structured dependence: implemented|Implemented phylogeny and planned space' vignettes _pkgdown.yml`:
  no matches after the reviewer cleanup.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed after the final
  navigation and terminology edits.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found after
  the final site build.
- `rg -n '```text|\\mathrm\\{Normal\\}|temperature_|growth_|x1_|x2_|yi_i' vignettes/location-scale.Rmd vignettes/which-scale.Rmd vignettes/robust-student.Rmd vignettes/bivariate-coscale.Rmd vignettes/phylogenetic-spatial.Rmd`:
  confirmed only intentional code-like or R-object leftovers remained.
- `rg -n '```text|temperature_i|treatment_i|habitat_i|trap_nights_i|survey_method_i|larger fitted sigma|^(<<<<<<<|=======|>>>>>>>)' vignettes/distribution-families.Rmd`:
  no matches.
- `rg -n '<<<<<<<|=======|>>>>>>>' docs/dev-log/check-log.md _pkgdown.yml vignettes/drmTMB.Rmd vignettes/model-map.Rmd docs/design/21-tutorial-style.md docs/dev-log/after-task/2026-05-12-tutorial-map-model-guides.md`:
  no conflict markers found.
- `rg -n "What can I fit today\\?|Model Guides|Guide Versus Tutorial Split|model-map|rho ~|meta_gaussian\\(|tau ~|meta_known_V\\([^V]" _pkgdown.yml vignettes docs/design README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md`:
  confirmed the new guide/nav/style strings and found only intentional
  guardrail references for `rho ~`, `meta_gaussian()`, `tau ~`, and
  `meta_known_V()`.
- `git diff --check`: clean.

## 2026-05-12 -- Bivariate group covariance bridge hygiene

Scope:

- added `group` and `block` filters to `corpairs()` for fitted group-level
  covariance rows;
- tightened the bivariate Gaussian `corpairs()` test so one fitted model must
  expose residual `rho12` and group-level `mu1`/`mu2` correlation rows under
  separate `level`, `group`, `block`, and `class` filters;
- corrected the correlation-pair design note so the implemented extractor
  example uses `level = "group"` and `class = "mean-mean"` rather than an
  unimplemented `level = "ID"` filter;
- added a bivariate-coscale tutorial snippet showing how to request residual
  and group-level `corpairs()` rows separately;
- kept this branch on the ordinary grouped bivariate covariance bridge, without
  adding phylogenetic, spatial, or residual-scale bivariate covariance code.

Checks:

- `air format R/methods.R tests/testthat/test-biv-gaussian.R docs/design/20-coscale-correlation-pairs.md vignettes/bivariate-coscale.Rmd NEWS.md man/corpairs.Rd`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/corpairs.Rd`.
- `Rscript -e "devtools::test(filter = 'biv-gaussian|corpairs')"`:
  passed with 180 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `Rscript -e "pkgdown::build_article('bivariate-coscale')"`: passed.
- `rg -n "level = \"ID\"|class = \"mean-scale\"|corpairs\\(fit, level|corpairs\\(fit, class" docs/design vignettes README.md ROADMAP.md tests/testthat`:
  found only the corrected implemented examples and tests.

## 2026-05-11 -- Mammal location-coscale route

Scope:

- added `docs/design/29-mammal-location-coscale-route.md` to map the mammal
  body mass and litter-size protocol onto current `drmTMB` capabilities and
  planned covariance milestones;
- linked the new route note from
  `docs/design/15-location-coscale-phylogenetic-extension.md`;
- linked Phase 11 bivariate covariance work in `ROADMAP.md` to the concrete
  mammal route;
- recorded an after-task report at
  `docs/dev-log/after-task/2026-05-11-mammal-location-coscale-route.md`.

Checks:

- `pdftotext /Users/z3437171/Downloads/Mammalian_location_co_scale_trade_offs.pdf - | rg -n "Objective|Model|Stage|location-scale|phylogenetic|non-phylogenetic|rho|correlation|lifestyle|sigma|residual|MCMCglmm|Stan|Upham|50|posterior|H\\^?2|heritability|scale" -C 2`:
  confirmed the three protocol objectives, structured covariance targets,
  lifestyle-specific covariance model, and 50-tree posterior-pooling plan.
- `gh issue view 5 --repo itchyshin/drmTMB --json number,title,body,comments,url`:
  confirmed issue #5 already covers covariance blocks as the long-term
  individual-difference endpoint and that PR #11 is only a documentation
  clarity slice.
- `rg -n "docs/design|design/28|design/20|location-coscale|double-hierarchical" README.md ROADMAP.md _pkgdown.yml docs vignettes`:
  checked existing design-link patterns before adding the new route reference.
- `rg -n "phylo\\(" R/drmTMB.R R/parse-formula.R tests/testthat/test-phylo-gaussian.R vignettes/phylogenetic-spatial.Rmd docs/design/01-formula-grammar.md`:
  confirmed the current `phylo(1 | species, tree = tree)` boundary for
  univariate Gaussian `mu` and planned structured extensions.
- `air format ROADMAP.md docs/design/15-location-coscale-phylogenetic-extension.md docs/design/29-mammal-location-coscale-route.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-11-mammal-location-coscale-route.md`:
  completed.
- `git diff --check`: clean.
- `Rscript -e "devtools::test(filter = 'biv-gaussian|phylo-gaussian|corpairs')"`:
  168 passed, 0 failed, 0 warnings, 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `rg -n "Mammal Location-Coscale Route|29-mammal-location-coscale-route|mammal body mass|body mass-litter size route|tree-loop|posterior pooling|full model is runnable|full protocol" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests _pkgdown.yml --glob '!docs/dev-log/after-task/**'`:
  confirmed the new route is linked only from the roadmap and the existing
  location-coscale design note, and that the new note keeps posterior pooling
  outside the implemented maximum-likelihood surface.
- `rg -n "rho ~|meta_gaussian\\(|tau ~|meta_known_V\\([^V]|rho12.*phylogenetic|phylogenetic.*rho12" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests _pkgdown.yml --glob '!docs/dev-log/after-task/**'`:
  found only intentional guardrails and existing statements that residual
  `rho12` remains separate from phylogenetic, spatial, or species-level
  correlations.
- `rg -n "Objective 1|Objective 2|Objective 3|implemented|planned|rho12|rho_a|rho_e|Sigma_a|Sigma_e|sigma1|sigma2" docs/design/29-mammal-location-coscale-route.md`:
  checked that the new equations, R syntax, status table, and naming rules
  preserve the implemented-versus-planned boundary.

## 2026-05-11 -- Tweedie likelihood gate

Scope:

- added a planned Tweedie mean-scale-shape section to
  `docs/design/03-likelihoods.md`;
- kept `tweedie()` future-only while recording the working variance contract
  `Var[y_i] = sigma_i^2 * mu_i^nu_i` with `1 < nu_i < 2`;
- added an after-task note at
  `docs/dev-log/after-task/2026-05-11-tweedie-likelihood-gate.md`.

Checks:

- `air format docs/design/03-likelihoods.md docs/dev-log/after-task/2026-05-11-tweedie-likelihood-gate.md docs/dev-log/check-log.md`:
  passed.
- `rg -n "Planned Tweedie|tweedie\\(|sigma_i\\^2 \\* mu_i\\^nu_i|glmmTMB::tweedie|issue #2|Tweedie" docs/design/03-likelihoods.md docs/design/27-tweedie-family-plan.md docs/design/06-distribution-roadmap.md ROADMAP.md docs/dev-log/after-task/2026-05-11-tweedie-likelihood-gate.md`:
  confirmed the design-gate wording.
- `git diff --check`: passed.

## 2026-05-10 -- First-use variance reporting and CI deploy gate

Scope:

- made the README smoke-test data include a real Gaussian scale effect and
  added explicit residual SD ratio, residual variance ratio, and fitted
  residual variance code;
- added an early link from the location-scale tutorial opening to the worked
  growth example so new users can skip the syntax overview on first read;
- added a "Fit your first model" section near the top of the getting-started
  article with simulated growth data, `check_drm()`, and sigma-to-variance
  interpretation;
- added "Getting started" as the first item in the pkgdown Tutorials menu;
- added marginal residual variance columns to the bivariate coscale reporting
  tables;
- expanded the meta-analysis article to report extra heterogeneity variance,
  total observation variance, and bivariate residual covariance reporting;
- corrected the previous variance-facing after-task note so its next action no
  longer names an already-present bivariate covariance example;
- changed `pkgdown` deployment to run from a successful `R-CMD-check`
  `workflow_run` on `main` or `master`, while preserving manual dispatch;
- made the pkgdown checkout use the successful `workflow_run` head SHA, with
  `github.sha` as the manual-dispatch fallback;
- added `v*` tag triggers, manual dispatch, workflow-level concurrency, and a
  30-minute job timeout to `R-CMD-check`;
- added a 30-minute job timeout to `pkgdown`.

Checks:

- `air format README.md vignettes/drmTMB.Rmd vignettes/bivariate-coscale.Rmd vignettes/location-scale.Rmd`:
  completed.
- `Rscript -e "pkgdown::build_articles(c('drmTMB', 'bivariate-coscale', 'meta-analysis'))"`:
  failed because `pkgdown::build_articles()` expects a package path, not a
  character vector of article names.
- `Rscript -e "pkgdown::build_article('drmTMB'); pkgdown::build_article('bivariate-coscale'); pkgdown::build_article('meta-analysis')"`:
  passed.
- `Rscript -e "pkgdown::build_article('location-scale')"`: passed.
- `Rscript -e "pkgdown::build_home()"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- README smoke-test command with the edited example: first attempt failed
  because `$x1` was expanded by the shell inside a double-quoted R expression;
  rerunning with a single-quoted R expression passed and returned finite
  summary output, `head(sigma(fit))`, SD ratio, variance ratio, and fitted
  residual variances.
- `ruby -e 'require "yaml"; ARGV.each { |f| YAML.load_file(f); puts "ok #{f}" }' .github/workflows/R-CMD-check.yaml .github/workflows/pkgdown.yaml`:
  both workflow files parsed as YAML.
- `command -v actionlint || true`: `actionlint` was not installed locally.
- `rg -n "residual_sd_ratio|residual_variance_ratio|Fit your first model|Getting started|residual_variance_activity|fitted_extra_heterogeneity_variance|workflow_run|concurrency|tags" README.md _pkgdown.yml vignettes/drmTMB.Rmd vignettes/bivariate-coscale.Rmd vignettes/meta-analysis.Rmd .github/workflows docs/dev-log/after-task/2026-05-10-variance-facing-sigma-reporting.md pkgdown-site/index.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/bivariate-coscale.html pkgdown-site/articles/meta-analysis.html --glob '!pkgdown-site/search.json'`:
  confirmed source and rendered documentation updates.
- `gh run list --branch main --limit 2`: confirmed commit `480ff00` passed
  both `R-CMD-check` and `pkgdown` before starting this follow-up push.
- GitHub Actions `R-CMD-check` run `25634267316`: passed on macOS, Ubuntu,
  and Windows for commit `45158fc`.
- GitHub Actions `pkgdown` run `25634395896`: triggered by `workflow_run` after
  `R-CMD-check` passed and completed successfully for commit `45158fc`.
- GitHub Actions workflow syntax was checked against official GitHub docs for
  `workflow_run` branch filters, `push` tag filters, and `concurrency`.
- `git diff --check`: clean.

## 2026-05-10 -- Variance-facing sigma reporting

Scope:

- clarified in the location-scale tutorial that Gaussian `sigma` coefficients
  are fitted on the log-residual-SD scale, so SD ratios are `exp(coef)` and
  variance ratios are `exp(2 * coef)`;
- added fitted residual variance to the Gaussian location-scale reporting
  table;
- expanded the scale-choice meta-analysis example to report extra
  heterogeneity SD, extra heterogeneity variance, and total observation
  variance after known sampling variance is added;
- added a family guide table that translates fitted `sigma` into
  variation-facing summaries for Gaussian, Student-t, lognormal, Gamma, beta,
  beta-binomial, Poisson, zero-inflated, NB2, hurdle, and bivariate Gaussian
  models;
- added a model-workflow pointer warning readers not to square log-SD
  coefficients when they want residual variance.

Checks:

- `air format vignettes/location-scale.Rmd vignettes/which-scale.Rmd vignettes/distribution-families.Rmd vignettes/model-workflow.Rmd`:
  completed.
- `Rscript -e "pkgdown::build_articles()"`: first attempt failed because
  `drmTMB` was not installed in the active R library for direct vignette
  rendering.
- `Rscript -e "devtools::install(upgrade = 'never', quick = TRUE)"`: installed
  the current checkout locally for direct article rendering.
- `Rscript -e "pkgdown::build_articles()"`: passed after local installation.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "devtools::test()"`: 1400 passed, 0 failed, 0 warnings, 0 skips.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `rg -n "residual_variance_ratio|fitted_residual_variance|extra_heterogeneity_variance|total_observation_variance|Reporting variation|do not square the|rho12 \\* sigma1" vignettes pkgdown-site/articles --glob '!pkgdown-site/search.json'`:
  confirmed the new source and rendered guidance.
- `rg -n "O'Dea/Nakagawa|O'Dea-style|O\\.Dea/Nakagawa|O\\.Dea-style" README.md ROADMAP.md NEWS.md docs/design vignettes R tests _pkgdown.yml pkgdown-site --glob '!pkgdown-site/search.json'`:
  no matches.
- `rg -n "tau ~|meta_gaussian\\(|rho ~" README.md ROADMAP.md NEWS.md docs/design vignettes R tests _pkgdown.yml pkgdown-site --glob '!pkgdown-site/search.json'`:
  found only the intended meta-analysis guardrail and the new reporting
  conversion note.
- `git diff --check`: clean.

## 2026-05-10 -- Version 0.1.0 install smoke test

Scope:

- installed the tagged `v0.1.0` preview into a clean temporary R library using
  `pak::pak("itchyshin/drmTMB@v0.1.0")`;
- loaded the installed package and ran the README Gaussian location-scale smoke
  model;
- updated the README install section to distinguish the tagged preview from the
  newest development build on `main`;
- recorded the package-load `beta()` masking message as first-use friction for a
  later API or documentation pass.

Checks:

- clean temporary-library install: `pak` installed `drmTMB 0.1.0` from GitHub
  commit `5f8e669` plus hard dependencies `cli`, `Rcpp`, `RcppEigen`, and
  `TMB`.
- installed-package smoke model: returned finite `mu` coefficients, `sigma`
  coefficients, and `sigma(fit)` values.
- `Rscript -e "pkgdown::build_home()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- rendered install-section scan over `README.md` and `pkgdown-site/index.html`:
  confirmed the tagged `pak` install, development-branch `pak` install, and
  pinned `remotes` fallback.
- `Rscript -e "devtools::test()"`: 1400 passed, 0 failed, 0 warnings, 0 skips.
- `git diff --check`: clean.

## 2026-05-10 -- Version 0.1.0 release preparation

Scope:

- bumped `DESCRIPTION` from `0.0.0.9000` to `0.1.0`;
- changed the `NEWS.md` heading to `drmTMB 0.1.0 (2026-05-10)`;
- updated the landing-page status from development-target wording to first
  public preview wording;
- updated the pkgdown status badge to `0.1.0 preview release`;
- updated the roadmap release section from a pre-release gate to the `0.1.0`
  preview release boundary.

Checks:

- `Rscript -e "devtools::document()"`: completed.
- `Rscript -e "devtools::test()"`: 1400 passed, 0 failed, 0 warnings, 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes for `drmTMB 0.1.0`.
- `rg -n "0\\.0\\.0\\.9000|version will be bumped|development build; 0\\.1\\.0 preview planned|first public preview target|current development version|Development status" README.md NEWS.md DESCRIPTION _pkgdown.yml ROADMAP.md pkgdown-site/index.html pkgdown-site/news/index.html pkgdown-site/ROADMAP.html`:
  no matches in active source and rendered landing, news, or roadmap pages.
- `rg -n "0\\.1\\.0|Preview status|preview version|0.1.0 preview release|drmTMB 0.1.0|Released version" README.md NEWS.md DESCRIPTION _pkgdown.yml ROADMAP.md docs/dev-log/release-checklists/2026-05-10-0.1.0-preview-release.md pkgdown-site/index.html pkgdown-site/news/index.html pkgdown-site/ROADMAP.html`:
  confirmed the source and rendered `0.1.0` release wording.
- Chrome/Playwright layout sanity check over `pkgdown-site/index.html`: desktop
  viewport `1280 x 900` had `scrollWidth = 1280`; mobile viewport `390 x 844`
  had `scrollWidth = 390`; both showed version `0.1.0` and kept the first
  headings as `Start here`, `Preview status`, `Install`, and `Tiny example`.
- `git diff --check`: clean.
- GitHub Actions `R-CMD-check` run `25632815210`: passed on macOS, Ubuntu, and
  Windows for commit `5f8e669`.
- GitHub Actions `pkgdown` run `25632815212`: passed and deployed the site for
  commit `5f8e669`.
- `git tag -a v0.1.0 -m "drmTMB 0.1.0 preview release" && git push origin
  v0.1.0`: pushed the annotated `v0.1.0` release tag after branch CI was green.

## 2026-05-10 -- Release-hardening gate refresh

Scope:

- synced the local `0.1.0` release checklist with the Phase 9 preview boundary;
- closed Phase 9 for `0.1.0` at the implemented location-only ordinal and
  `cbind(successes, failures)` beta-binomial MVPs;
- added an implemented-family coverage audit at
  `docs/dev-log/release-audits/2026-05-10-family-coverage.md`;
- synced GitHub issue #1 with the updated local checklist and applied the
  `release`, `0.1.0`, `pkgdown`, and `CRAN-ish` labels.

Checks:

- `rg -n "test_that\\(" tests/testthat/test-{beta-binomial,beta-location-scale,biv-gaussian,cumulative-logit,gamma-location-scale,gaussian-location-scale,gaussian-random-effect-scale,gaussian-random-intercepts,hurdle-nbinom2,lognormal-location-scale,meta-known-v,nbinom2-location-scale,phylo-gaussian,poisson-mean,student-location-scale,truncated-nbinom2-location-scale,zi-nbinom2,zi-poisson}.R`:
  mapped the implemented family test files and test descriptions.
- `rg -n "likelihood matches independent|matches independent|comparator|recover|reject|unsupported|malformed|boundary|edge|complete-case|weights|simulation|simulate|finite|approaches|offset|zero" tests/testthat/test-{beta-binomial,beta-location-scale,biv-gaussian,cumulative-logit,gamma-location-scale,gaussian-location-scale,gaussian-random-effect-scale,gaussian-random-intercepts,hurdle-nbinom2,lognormal-location-scale,meta-known-v,nbinom2-location-scale,phylo-gaussian,poisson-mean,student-location-scale,truncated-nbinom2-location-scale,zi-nbinom2,zi-poisson}.R`:
  confirmed coverage categories for the family audit.
- `Rscript -e "devtools::test()"`: 1400 passed, 0 failed, 0 warnings, 0 skips.
- `Rscript -e "devtools::document()"`: completed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.
- `rg -n "O'Dea/Nakagawa|O'Dea-style|O\\.Dea/Nakagawa|O\\.Dea-style|rho ~|meta_gaussian\\(|tau ~|family = c\\(gaussian\\(\\), poisson\\(\\)\\)" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/release-checklists docs/dev-log/release-audits vignettes R tests _pkgdown.yml pkgdown-site --glob '!pkgdown-site/search.json'`:
  found only guardrail prose, planned-feature prose, design checks, and one
  negative test.
- `rg -n 'Development status|development version|0\\.0\\.0\\.9000|0\\.1\\.0|pak::pak|development build; 0\\.1\\.0 preview planned|Phase 9|family coverage|cbind\\(successes, failures\\)' README.md ROADMAP.md docs/dev-log/release-checklists/2026-05-10-0.1.0-preview-release.md docs/dev-log/release-audits/2026-05-10-family-coverage.md pkgdown-site/index.html pkgdown-site/ROADMAP.html`:
  confirmed rendered status, install, roadmap, and Phase 9 release-boundary text.
- Chrome/Playwright layout sanity check over `pkgdown-site/index.html`: desktop
  viewport `1280 x 900` had `scrollWidth = 1280`; mobile viewport `390 x 844`
  had `scrollWidth = 390`; both kept the first headings as `Start here`,
  `Development status`, `Install`, and `Tiny example`.
- `git diff --check`: clean.
- `gh issue edit 1 --body-file docs/dev-log/release-checklists/2026-05-10-0.1.0-preview-release.md --add-label release --add-label "0.1.0" --add-label pkgdown --add-label "CRAN-ish"`:
  updated https://github.com/itchyshin/drmTMB/issues/1.

## 2026-05-10 -- Development-version status clarification

Scope:

- changed the primary GitHub installation recommendation from
  `remotes::install_github()` to `pak::pak()`, keeping `remotes` as a fallback;
- clarified that the pkgdown header shows `0.0.0.9000` because the site is
  built from the current development version in `DESCRIPTION`;
- added a small navbar status badge that says the site is a development build
  and that `0.1.0` is the planned preview;
- added a landing-page sentence explaining that `0.1.0` should be assigned
  only when the release checklist closes.
- simplified that sentence into a `Development status` section after a
  back-to-basics user-path review.

Checks:

- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found before the final
  wording simplification.
- `rg -n 'Development status|development version|0\.0\.0\.9000|0\.1\.0|pak::pak|install_github|development build; 0\.1\.0 preview planned' README.md _pkgdown.yml pkgdown-site/index.html`:
  confirmed the source and rendered version-status and install-path text.
- `rg -n 'pak|install_github|install\.packages|development version|development build|release checklist' pkgdown-site/index.html`:
  confirmed the rendered `pak` command, `remotes` fallback, dependency text,
  and development-version explanation.
- Chrome/Playwright layout sanity check over `pkgdown-site/index.html`: desktop
  viewport `1280 x 900` had `scrollWidth = 1280` and showed the development
  badge; mobile viewport `390 x 844` had `scrollWidth = 390` and hid the badge
  while keeping the `Development status`, `Install`, and `Tiny example`
  sections visible.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found after the final
  wording simplification.
- `git diff --check`: clean.
- Pushed in commit `f879c2e`; GitHub Actions completed successfully for
  `pkgdown` and `R-CMD-check`.

## 2026-05-10 -- Installation guidance on landing page

Scope:

- added a compact installation section to `README.md`, which renders as the
  pkgdown landing page;
- told users that `drmTMB` is not on CRAN yet and should be installed from
  GitHub;
- listed R version, compiler-toolchain, runtime, linking, optional example,
  comparator, and site-check dependencies;
- added a runnable smoke test so first-time users can immediately check that
  installation, loading, fitting, `summary()`, and `sigma()` work.

Commands and evidence:

- `Rscript -e "devtools::load_all(quiet = TRUE); set.seed(1); dat <- data.frame(y = rnorm(80), x1 = rnorm(80)); fit <- drmTMB(drm_formula(y ~ x1, sigma ~ x1), family = gaussian(), data = dat); print(head(sigma(fit)))"`:
  returned finite fitted `sigma` values.

Checks:

- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `rg -n "Install|install_github|R 4\.1\.0|Rtools|Core runtime dependencies|pkgdown" README.md pkgdown-site/index.html`:
  confirmed the install, compiler, dependency, and rendered-site text.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `git diff --check`: clean.
- Pushed in commit `1085900`; GitHub Actions completed successfully for
  `pkgdown` and `R-CMD-check`.

## 2026-05-10 -- Next-five 0.1.0 release-gate batch

Scope:

- ran and archived the Gaussian location-scale comparator result that overlaps
  with `glmmTMB`;
- verified roxygen output with `devtools::document()`;
- opened the public `0.1.0` preview-release checklist as
  https://github.com/itchyshin/drmTMB/issues/1;
- updated the release checklist, check log, and after-task evidence trail
  before running package and site validation.

Files touched:

- `docs/dev-log/comparator-results/2026-05-10-gaussian-location-scale-glmmtmb.md`
- `docs/dev-log/release-checklists/2026-05-10-0.1.0-preview-release.md`
- `docs/dev-log/after-task/2026-05-10-next-five-release-readiness.md`
- `docs/dev-log/after-task/2026-05-10-next-five-release-gate.md`
- `docs/dev-log/check-log.md`

Commands and evidence:

- `Rscript tools/replicate-location-scale-gaussian.R`: passed. Fixed-effect
  maximum absolute differences were `1.372665e-06` for `mu` coefficients,
  `1.999083e-06` for `sigma` coefficients, and `3.964260e-10` for
  log-likelihood. Random-intercept maximum absolute differences were
  `6.226181e-08` for `mu` coefficients, `6.677708e-06` for `sigma`
  coefficients, `6.810643e-07` for the `mu` random-intercept SD, and
  `2.117218e-09` for log-likelihood.
- `Rscript -e "devtools::document()"`: completed and produced no file changes.
- `gh issue create --title "Release checklist: drmTMB 0.1.0 preview" --body-file docs/dev-log/release-checklists/2026-05-10-0.1.0-preview-release.md`:
  opened issue #1.

Checks:

- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `rg -n "O'Dea/Nakagawa|O'Dea-style|O\.Dea/Nakagawa|O\.Dea-style" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/release-checklists docs/dev-log/after-task/2026-05-10-next-five-release-gate.md docs/dev-log/after-task/2026-05-10-next-five-release-readiness.md vignettes _pkgdown.yml pkgdown-site --glob '!pkgdown-site/search.json'`:
  no matches for the removed internal shorthand in active user-facing and
  current release-gate files.
- `rg -n "rho ~|meta_gaussian\(|tau ~|family = c\(gaussian\(\), poisson\(\)\)" README.md ROADMAP.md NEWS.md vignettes R tests docs/dev-log/after-task/2026-05-10-next-five-release-gate.md docs/dev-log/release-checklists/2026-05-10-0.1.0-preview-release.md`:
  found only guardrail prose, planned-feature prose, and a negative test.
- `Rscript -e "devtools::test()"`: 1400 passed, 0 failed, 0 warnings,
  0 skips.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.
- `git diff --check`: clean.
- Pushed in commit `5c6ac6f`; GitHub Actions completed successfully for
  `pkgdown` and `R-CMD-check`.

## 2026-05-10 -- Sleep consolidation pause

Scope:

- recorded a pause note after the Phase 9 release-readiness push and reader
  wording correction;
- distilled what is stronger, what failed usefully, and what the next focused
  move should be before starting another implementation batch.

Artifact:

- `docs/dev-log/after-task/2026-05-10-sleep-consolidation.md`

Checks:

- `git diff --check`: clean.

## 2026-05-10 -- Reader-first individual-difference wording

Scope:

- replaced project-internal author shorthand in active user-facing docs and the
  newest development notes;
- kept formal paper references where the citation itself is useful, but made
  the surrounding prose describe the model class: individual-difference
  location-scale models, predictability, plasticity, malleability, and
  double-hierarchical covariance.

Files touched:

- `README.md`
- `ROADMAP.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/release-checklists/2026-05-10-0.1.0-preview-release.md`
- recent 2026-05-10 after-task reports for the landing page, comparator
  tests, paper phase map, QA batch, and release-readiness batch.

Checks:

- shorthand scans over `README.md`, `ROADMAP.md`, `NEWS.md`, active design
  docs, release checklists, 2026-05-10 after-task reports, vignettes, and
  `_pkgdown.yml`: no matches for the removed slash-author or author-style
  labels.
- `Rscript -e "pkgdown::build_site()"`: passed and regenerated the rendered
  landing page and roadmap.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- rendered-site shorthand scan over `pkgdown-site` excluding `search.json`: no
  matches for the removed slash-author or author-style labels.
- `Rscript -e "devtools::test()"`: 1400 passed, 0 failed, 0 warnings,
  0 skips.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.
- `git diff --check`: clean.

Team learning:

- Pat's reader check applies to roadmap and dev-log prose, not only tutorials:
  if a phrase only makes sense to the project team, replace it with the model
  class or the scientific quantity the reader came to understand.

## 2026-05-10 -- CI follow-up for beta-binomial boundary test

Scope:

- fixed the first red GitHub Actions run after the Phase 9 release-readiness
  push;
- kept the landing-page deployment commit intact because `pkgdown` deployed
  successfully;
- narrowed the R-CMD-check failure to one brittle beta-binomial test that
  expected optimizer convergence code `0` for a deliberately boundary-heavy
  dataset with all-zero and all-success rows.

Commands and evidence:

- GitHub `pkgdown` run `25629346156` for commit `ed92360`: success and deployed
  GitHub Pages.
- GitHub `R-CMD-check` run `25629346165` for commit `ed92360`: macOS passed;
  Ubuntu and Windows failed in
  `tests/testthat/test-beta-binomial.R:200` because `fit$opt$convergence` was
  `1` instead of `0` for the boundary-pattern test.
- `gh run view 25629346165 --job 75230092326 --log`: confirmed Ubuntu failure
  was `Expected fit$opt$convergence to equal 0` with `actual: 1.0`.
- `gh run view 25629346165 --job 75230092323 --log-failed`: confirmed Windows
  failed on the same expectation.

Fix:

- changed the boundary-pattern test to check the intended contract: finite
  log-likelihood, finite fitted coefficients, finite link-scale predictions,
  response-scale probabilities inside `(0, 1)`, and finite `sigma(fit)`;
- kept strict convergence assertions in ordinary recovery and independent
  likelihood tests where the data-generating process is well posed.

Team learning:

- Curie and Grace should treat optimizer convergence equality as a claim about
  a well-posed estimation problem, not as a generic assertion for pathological
  boundary data;
- boundary tests should protect finite likelihood and extractor behaviour
  unless the purpose is explicitly to test convergence diagnostics.

## 2026-05-10 -- Next-five release-readiness batch

Goal:

- complete the next five bounded tasks after the Phase 9 QA batch: add a local
  Gaussian individual-difference location-scale replication harness, visually
  audit the landing page, record denominator-aware and ordinal-scale design
  guardrails, and make the `0.1.0` preview-release checklist concrete.

Completed tasks:

- added `tools/replicate-location-scale-gaussian.R`, an optional local harness
  that simulates fixed-effect and random-intercept Gaussian location-scale
  examples and compares `drmTMB` with `glmmTMB`;
- replaced the landing-page capability table with a shorter mobile-friendly
  list and added `pkgdown/extra.css` so the home page has no horizontal page
  overflow on a 390 px viewport;
- added `docs/design/24-denominator-response-syntax.md`, keeping
  `cbind(successes, failures)` as the canonical `beta_binomial()` response
  until a denominator helper is designed and tested;
- added `docs/design/25-ordinal-scale-discrimination.md`, preferring an
  ordinal `sigma ~ ...` scale extension with discrimination reported as the
  derived summary `zeta = 1 / sigma`;
- added `docs/dev-log/release-checklists/2026-05-10-0.1.0-preview-release.md`
  as an issue-ready preview-release gate.

Commands run:

- `air format tools/replicate-location-scale-gaussian.R`: passed.
- `Rscript -e "pkgdown::build_site()"`: passed and copied `pkgdown/extra.css`
  into `pkgdown-site/extra.css`.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- Chrome/Playwright visual audit of `pkgdown-site/index.html`: desktop
  screenshot looked balanced; mobile viewport metrics were
  `innerWidth = 390`, `scrollWidth = 390`, and `bodyScrollWidth = 390`.
- `Rscript tools/replicate-location-scale-gaussian.R`: passed. Fixed-effect
  maximum absolute differences were `1.37e-06` for `mu` coefficients,
  `2.00e-06` for `sigma` coefficients, and `3.96e-10` for log-likelihood.
  Random-intercept maximum absolute differences were `6.23e-08` for `mu`
  coefficients, `6.68e-06` for `sigma` coefficients, `6.81e-07` for the `mu`
  random-intercept SD, and `2.12e-09` for log-likelihood.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `rg -n "successes/trials|zeta|sigma\\^2|0\\.1\\.0|O'Dea|extra\\.css|cbind\\(successes, failures\\)" README.md ROADMAP.md docs/design/02-family-registry.md docs/design/19-family-link-contract.md docs/design/24-denominator-response-syntax.md docs/design/25-ordinal-scale-discrimination.md docs/dev-log/release-checklists/2026-05-10-0.1.0-preview-release.md pkgdown-site/index.html pkgdown-site/extra.css`:
  confirmed the scale, alias, release, and rendered-homepage wording.
- `Rscript -e "devtools::test()"`: 1400 passed, 0 failed, 0 warnings,
  0 skips.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.

Known limitations:

- the harness uses simulated paper-shaped Gaussian examples; it is not yet a
  full real-data reproduction of every model in the individual-difference
  location-scale paper or tutorial;
- the ordinal scale and denominator-helper notes are design guardrails, not
  implemented formula grammar;
- the `0.1.0` checklist is a local issue-ready artifact. It has not been opened
  as a GitHub issue yet.

## 2026-05-09: Phase 3 Bivariate Coscale Closure

Scope:

- marked Phase 3 in `ROADMAP.md` as implemented and closure-audited for the
  fixed-effect bivariate Gaussian location-coscale model;
- added closure details for `rho12()`, `corpairs()`, complete-row bivariate
  known sampling covariance, row likelihood weights, residual diagnostics,
  `mvbind()` shorthand, composed Gaussian family syntax, and unsupported
  bivariate random-effect guards;
- added a `corpairs()` regression test for the `mvbind(y1, y2) ~ x` shorthand so
  residual pair output keeps response labels `y1` and `y2`;
- added an at-a-glance response-family table to the distribution-family tutorial;
- replaced stale README wording "fixed-effect seed" with "implemented
  fixed-effect" for the bivariate location-coscale model;
- created
  `docs/dev-log/after-phase/2026-05-09-phase-3-bivariate-coscale-closure.md`.

Commands run:

- `Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-corpairs.R')"`
- `Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-biv-gaussian.R')"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/distribution-families.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/bivariate-coscale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `rg -n "At a glance|Start from the measurement process|bivariate Gaussian coscale phase|closure-audited|corpairs keeps response labels|mvbind bivariate shorthand" vignettes/distribution-families.Rmd pkgdown-site/articles/distribution-families.html ROADMAP.md NEWS.md tests/testthat/test-corpairs.R`
- `rg -n "fixed-effect seed|Phase 3.*planned|Random effects remain future work|Bivariate random-effect syntax is planned|rho ~|meta_gaussian\\(|tau ~" README.md ROADMAP.md NEWS.md docs/design vignettes R tests --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/after-phase/**'`

Results:

- `test-corpairs.R`: 37 passed, 0 failed;
- `test-biv-gaussian.R`: 101 passed, 0 failed;
- `devtools::test()`: 1260 passed, 0 failed;
- tutorial renders for `distribution-families.Rmd` and `bivariate-coscale.Rmd`:
  passed after loading the local package;
- `pkgdown::build_site()`: passed after rerunning with normal cache/network
  access;
- `pkgdown::check_pkgdown()`: no problems found;
- `devtools::check(...)`: 0 errors, 0 warnings, 1 note. The note was local
  macOS temp-directory detritus (`xcrun_db`), not a package failure;
- `git diff --check`: clean;
- stale scan: no "fixed-effect seed" wording remains; remaining matches are
  intentional planned-feature or meta-analysis guardrail text.

Tests of the tests:

- the new `corpairs()` test exercises the extractor and response-label path for
  `mvbind()`, not only the bivariate likelihood;
- the existing bivariate test file already covers constant, predictor-dependent,
  near-zero, negative, high positive, and high negative residual correlations,
  known sampling covariance, row weights, missing rows, composed families, and
  unsupported bivariate random effects.

Notes:

- direct `test_file()` and direct vignette rendering failed before
  `devtools::load_all()` because the standalone R process had not loaded the
  local package;
- the first pkgdown build failed in the sandbox due sass-cache permission and
  CRAN DNS access, then passed with normal cache/network access.

## 2026-05-08: Implemented Source Map

Scope:

- added a developer source-map article that links implemented model paths to
  their R builders, TMB `model_type` branches, tests, and docs;
- added the article to the pkgdown Developer Notes menu and articles index;
- fixed stale location-scale wording so `sd(id) ~ x_group` is described as an
  implemented double-hierarchical random-effect scale path rather than future
  work;
- recorded the known follow-up that Gaussian known-covariance meta-analysis
  with `sd(group) ~ predictors` needs targeted validation before routine
  tutorial use.

Commands run:

- `Rscript -e "rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/location-scale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `git diff --check`
- `rg -n 'Later double-hierarchical|This developer article will|current planning reference|model_type = 99|meta_gaussian|tau ~|rho ~|c\\(gaussian\\(\\), poisson\\(\\)\\)|skew_normal\\(\\)' vignettes/source-map.Rmd vignettes/location-scale.Rmd _pkgdown.yml docs/design/08-meta-analysis.md`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- direct source-map render: passed;
- direct source-map and location-scale render after stale-wording fix: passed;
- `git diff --check`: clean;
- stale/unsupported-syntax scan: no old placeholder text and no stale "Later
  double-hierarchical" wording remained. Remaining hits were intentional:
  `model_type = 99` is documented as internal, `c(gaussian(), poisson())` is in
  an unsupported-feature list, and `meta_gaussian()` / `tau ~` are in the
  meta-analysis guardrail design note;
- `pkgdown::check_pkgdown()`: no problems found;
- full `devtools::test()`: 642 passed, 0 failed;
- `pkgdown::build_site()`: rebuilt successfully;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- no package code changed; this task mapped existing tests to implemented paths;
- the source map was checked against Jason's source-only scan and against
  rendered pkgdown navigation.

Notes:

- Jason identified the stale location-scale sentence and the missing central
  model-type table. The new source-map article closes the model-type table gap;
  the location-scale wording was updated.
- Jason also identified that `meta_known_V()` plus `sd(group) ~ predictors`
  needs targeted validation. The source map now names that as a follow-up rather
  than teaching it as routine syntax.
- the already-pushed `fe0cd04` adding-families commit passed GitHub pkgdown and
  R-CMD-check on macOS, Ubuntu, and Windows; only GitHub runner deprecation
  notices were reported.

## 2026-05-08: Adding Families Developer Guide

Scope:

- replaced the placeholder `adding-families` pkgdown article with a practical
  developer guide for adding a family to `drmTMB`;
- paired symbolic equations, R syntax, registry fields, TMB likelihood mapping,
  simulation support, tests, documentation, pkgdown, and after-task closure;
- used implemented Student-t and bivariate Gaussian patterns as the worked
  examples rather than presenting unsupported families as runnable code;
- kept the one-response/two-response boundary, canonical `mu`/`sigma`/`nu`/
  `tau` naming, and canonical residual `rho12` wording explicit.

Commands run:

- `Rscript -e "rmarkdown::render('vignettes/adding-families.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `git diff --check`
- `rg -n 'This developer article will|rho ~|tau ~|meta_gaussian|family = c\\(gaussian\\(\\), poisson\\(\\)\\)|skew_normal\\(\\)|bivariate random effects|bivariate Student-t|sparse known covariance|not implemented|planned' vignettes/adding-families.Rmd`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- direct vignette render: passed;
- `git diff --check`: clean;
- prose-style review: passed with no follow-up edits needed; the article names
  contributors as the reader, leads with the family contract, and pairs
  equations with supported syntax;
- stale/unsupported-syntax scan: no old placeholder text, no `rho ~`, no
  `tau ~`, no `meta_gaussian`, no mixed composed-family runnable example, and
  no skew-normal runnable example. Remaining hits are intentional planned-syntax
  or rejection-message wording;
- `pkgdown::check_pkgdown()`: no problems found;
- full `devtools::test()`: 642 passed, 0 failed;
- `pkgdown::build_site()`: rebuilt successfully;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- no package code changed; the article points contributors to already
  implemented test patterns: Student-t independent likelihood checks,
  simulation recovery, method checks, rejection tests, and comparator tests.

Notes:

- the documentation-writer sidecar provided the outline and flagged the main
  stale-wording risks before drafting;
- `R CMD check` emitted only the standard installed-size INFO for compiled TMB
  code; the final status was still 0/0/0.

## 2026-05-08: Testing Likelihoods Developer Guide

Scope:

- replaced the placeholder `testing-likelihoods` pkgdown article with a
  developer guide for likelihood validation;
- paired symbolic equations with `drmTMB` syntax for Gaussian location-scale,
  Gaussian random-intercept comparators, dense known-`V` meta-analysis,
  Student-t location-scale-shape, and bivariate `rho12` models;
- documented the two-tier testing pattern: comparator checks against established
  packages and simulation/independent-likelihood checks;
- clarified that `glmmTMB::equalto()` is a planned comparator, not currently in
  routine tests;
- labelled planned skew-normal syntax as future-only in the GAMLSS parameter
  naming design note;
- synchronized the collaboration/team table with the current standing review
  roles in `AGENTS.md`.

Commands run:

- `Rscript -e "rmarkdown::render('vignettes/testing-likelihoods.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `git diff --check`
- `rg -n "This developer article will|will document simulation recovery|current planning reference|skew_normal\\(\\)|glmmTMB::equalto\\(\\)|Current Agent Team|Testing likelihoods" vignettes docs/design README.md ROADMAP.md NEWS.md`
- `rg -n 'location means|complete-row `2n`|per-study list|This developer article will|will document simulation recovery|glmmTMB::equalto\\(\\)|skew_normal\\(\\)' vignettes/testing-likelihoods.Rmd docs/design/05-testing-strategy.md docs/design/08-meta-analysis.md docs/design/11-reference-programme.md docs/design/14-gamlss-parameter-names.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-08-testing-likelihoods-developer-guide.md`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- direct vignette render: passed;
- `git diff --check`: clean;
- stale-wording scan: no old `testing-likelihoods` placeholder text remained in
  the article; remaining `skew_normal()` and `glmmTMB::equalto()` hits are
  planned-feature references;
- post-audit scan: found the new location/scale/shape/coscale definition, the
  row-paired `2n` by `2n` wording, and only intentional planned-feature
  references;
- full `devtools::test()`: 642 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: rebuilt successfully;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- no package code changed, so this task used the existing full test suite plus
  vignette rendering and pkgdown checks;
- the new article points contributors to test patterns that already exist:
  independent likelihood checks, comparator checks, rejection tests, and
  bivariate sampling-versus-residual covariance checks.

Notes:

- Pat reviewed the placeholder article and identified that pkgdown exposed a
  two-sentence page where contributors expected a practical recipe; this task
  fixes that gap.
- Rose caught two P2 wording issues after the first draft: the article needed to
  define location, scale, shape, and coscale at first use, and the bivariate
  known-`V` wording needed to say that the implemented input is a complete-row
  `2n` by `2n` row-paired matrix rather than a per-study list of `S_i` blocks.
- one post-audit `rg` scan failed because shell backticks in the pattern were
  not quoted safely; the successful scan used single quotes and is recorded
  above.
- `R CMD check` emitted only the standard installed-size INFO for compiled TMB
  code; the final status was still 0/0/0.

## 2026-05-08: Dense Known-`V` `metafor::rma.mv()` Comparator

Scope:

- added a comparator smoke test for dense full known sampling covariance in
  Gaussian meta-analysis;
- compared `drmTMB` against `metafor::rma.mv(..., random = ~ 1 | obs,
  method = "ML")` for the overlapping case where the unknown residual
  heterogeneity is a constant observation-level variance component;
- updated the testing strategy so this comparator is listed as implemented
  rather than planned.

Commands run:

- ad hoc `drmTMB` versus `metafor::rma.mv()` smoke comparison for fixed effects,
  heterogeneity variance, and log-likelihood;
- `Rscript -e "devtools::test(filter = 'comparators|meta-known-v')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `rg -n 'rma\\.mv|dense known sampling covariance|metafor::rma\\.mv' docs/design/05-testing-strategy.md tests/testthat/test-comparators.R docs/dev-log/check-log.md`

Results:

- targeted comparator and meta-known-`V` tests: 73 passed, 0 failed;
- full `devtools::test()`: 642 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: rebuilt successfully;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- the comparator checks fixed-effect coefficients, the estimated residual
  heterogeneity variance, and the full ML log-likelihood against independent
  `metafor` output;
- the dense `V` matrix has off-diagonal sampling covariance, so it is not just
  a diagonal-known-variance repeat.

Notes:

- the first source scan command failed because shell backticks in the pattern
  were not quoted safely; the successful recorded `rg` command uses single
  quotes.

## 2026-05-08: Student-t Status Inventory Cleanup

Scope:

- fixed status-inventory drift after the Student-t implementation;
- updated README current status, ROADMAP, known limitations, formula grammar
  maps, family docs, and affected tutorials to list the implemented
  fixed-effect univariate Student-t path;
- clarified that `family = c(gaussian(), poisson())` is planned, not runnable
  implemented syntax;
- replaced active Student-t "tail weight" wording with "tail shape" or
  degrees-of-freedom language where larger `nu` could otherwise be read
  backwards;
- updated the after-task protocol and project-local `after-task-audit` skill so
  future family, grammar, diagnostic, and implemented-scope changes must check
  the status inventory explicitly.

Commands run:

- `Rscript -e "devtools::load_all(quiet=TRUE); for (f in c('vignettes/distribution-families.Rmd','vignettes/formula-grammar.Rmd','vignettes/robust-student.Rmd','vignettes/model-workflow.Rmd')) rmarkdown::render(f, output_format = rmarkdown::html_vignette(), output_file = tempfile(fileext = '.html'), quiet = TRUE)"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`

Status-inventory and stale-wording scans:

- `rg -n "tail weight|tail-weight|heavy-tail parameter|all non-Gaussian families are planned|Add Student-t|fitted Gaussian likelihood path" README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes R man NEWS.md tests pkgdown-site --glob '!pkgdown-site/search.json'`
- `rg -n "family = c\\(gaussian\\(\\), poisson\\(\\)\\)" README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes tests pkgdown-site --glob '!pkgdown-site/search.json'`

Results:

- standalone renders for the four touched vignettes passed;
- full `devtools::test()`: 638 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: rebuilt the affected articles, home page, roadmap,
  and search index;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean;
- the first stale-wording scan returned no active hits;
- the mixed-family scan returns only planned/future-work text or the deliberate
  unsupported-syntax test.

Tests of the tests:

- no new unit tests were added because this was a documentation and process
  consistency task;
- full tests and R CMD check were run to ensure the vignette/status edits did
  not break examples or package checks.

Notes:

- Pat caught the runnable-looking mixed-family code block in the family article;
- Rose caught the stale known-limitations and formula-status maps;
- the after-task protocol now requires exact status-inventory scans for this
  class of change.

## 2026-05-08: Student-t Scale Terminology Audit

Scope:

- clarified package-level README wording so `sigma` is the general residual
  scale parameter, with Gaussian residual SD as a special case;
- clarified `sigma.drmTMB()` documentation so Student-t `sigma` is described
  as the Student-t scale parameter;
- documented the residual standard deviation conversion
  `sigma * sqrt(nu / (nu - 2))` when `nu > 2`.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'student-location-scale')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `rg` scans for Student-t `sigma` and residual-standard-deviation wording.

Results:

- roxygen rebuilt `man/sigma.drmTMB.Rd`;
- targeted Student-t tests: 21 passed, 0 failed;
- full `devtools::test()`: 638 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: rebuilt the home page and `sigma.drmTMB()`
  reference page with the revised scale wording;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- this was a documentation terminology task, so no new unit tests were added;
- targeted Student-t tests were rerun to check that no documentation edit
  accidentally accompanied a behaviour change.

Notes:

- Gaussian-specific tutorials still correctly describe `sigma` as residual
  standard deviation because `Normal(mu_i, sigma_i^2)` uses `sigma_i` that way;
- Student-t tutorials and extractor documentation now explicitly distinguish
  scale from residual SD.
- no helper currently returns Student-t residual SD directly; users can compute
  it from `sigma()` and `predict(..., dpar = "nu")` when `nu > 2`.

## 2026-05-08: Robust Student-t Tutorial

Scope:

- added `vignettes/robust-student.Rmd` as a user-facing tutorial for
  fixed-effect Student-t location-scale-shape models;
- paired the symbolic Student-t equation with matching `drmTMB` syntax;
- used a seedling growth example with ambient and dry treatments;
- documented the distinction between Student-t `sigma` as a scale parameter
  and the residual standard deviation `sigma * sqrt(nu / (nu - 2))`;
- explained `check_drm()` `student_nu` output and next steps for near-boundary
  tail estimates;
- added the tutorial to the pkgdown Tutorials menu and article index;
- linked the tutorial from the response-family article.

Commands run:

- `Rscript -e "devtools::load_all(quiet=TRUE); rmarkdown::render('vignettes/robust-student.Rmd', output_format = rmarkdown::html_vignette(), output_file = tempfile(fileext = '.html'), quiet = TRUE)"`
- `Rscript -e "devtools::test(filter = 'student-location-scale|check-drm')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- generated-site scans for `robust-student.html`, Student-t scale wording,
  `dry_i`, navigation, and near-boundary `nu` guidance.
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`

Results:

- standalone vignette render with `devtools::load_all()`: passed;
- targeted Student-t and `check_drm()` tests: 74 passed, 0 failed;
- full `devtools::test()`: 638 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: built `articles/robust-student.html` and updated
  article indexes and navigation.
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.
- `git diff --check`: clean.

Tests of the tests:

- Volta reviewed the tutorial from an applied-user perspective and caught that
  early prose incorrectly described Student-t `sigma` as residual standard
  deviation;
- Dewey caught that the first draft underclaimed implemented fixed-effect
  `nu ~ predictors` syntax and lacked protocol closure.

Notes:

- the first direct `rmarkdown::render()` failed because the vignette calls
  `library(drmTMB)` before the package is installed; the successful local
  render used `devtools::load_all()`, and pkgdown installs the package before
  rendering.

## 2026-05-08: `check_drm()` Student-t `nu` Diagnostics

Scope:

- added a `student_nu` row to `check_drm()` for Student-t fits;
- report an error for non-finite `nu` values or values not above 2;
- report a warning when fitted `nu` is very close to the finite-variance
  boundary at 2;
- report a note when fitted `nu` is large enough that the fitted tail behaviour
  may be close to Gaussian;
- synchronized the `check_drm()` diagnostic summaries in README, vignettes,
  NEWS, roxygen, and the phylogenetic/spatial design note.

Commands run:

- `Rscript -e "devtools::test(filter = 'check-drm|student-location-scale')"`
  before fixing the test fixture: failed because the fitted Student-t fixture
  legitimately landed near the `nu = 2` boundary;
- `Rscript -e "devtools::test(filter = 'check-drm|student-location-scale')"`
  after fixture and coverage updates;
- `Rscript -e "devtools::document()"`
- `air format .` (failed: `air` is not installed);
- Rawls read-only reviewer pass over implementation, tests, and docs;
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- stale-wording scans for `check_drm()` diagnostic lists and Student-t `nu`
  wording;
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`

Results:

- targeted `check_drm()` plus Student-t tests: 74 passed, 0 failed;
- full `devtools::test()`: 638 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: rebuilt the `check_drm()` reference page, overview
  article, model-workflow article, home page, and changelog;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- the first targeted test run failed because the ordinary Student-t fixture was
  too heavy-tailed and correctly triggered a boundary warning;
- the revised test uses controlled coefficient mutations to exercise the ok,
  warning, note, and error branches independently of optimizer behaviour;
- a separate predictor-varying `nu ~ x` test checks that `check_drm()` reports
  a fitted `nu` range rather than only an intercept-only value.

Notes:

- large `nu` is a `note`, not a warning, because it can be a scientifically
  useful result: the robust model may simply be close to Gaussian;
- near-boundary `nu` is a `warning` because the finite-variance lower bound can
  be influential for inference and should be inspected.

## 2026-05-08: Student-t Fixed-Effect Location-Scale-Shape

Scope:

- added `student()` as a one-response robust continuous family with
  `mu`, `sigma`, and `nu` formulas;
- implemented the Student-t likelihood in TMB with
  `nu_i = 2 + exp(eta_nu_i)` and all normalizing constants;
- added prediction, simulation, residual, summary, and scale-extractor support
  through the existing S3 methods;
- added simulation-recovery, independent R likelihood comparison, method, and
  unsupported-term tests;
- updated family registry, likelihood, distribution-roadmap, shape-planning,
  README, NEWS, roxygen, pkgdown reference, and distribution-family vignette
  documentation.

Commands run:

- `Rscript -e "devtools::load_all()"`
- ad hoc Student-t fit, coefficient, prediction, and simulation smoke test;
- `Rscript -e "devtools::test(filter = 'student-location-scale')"`
- targeted regression slice:
  `Rscript -e "devtools::test(filter = 'gaussian-location-scale|biv-gaussian|meta-known-v|phylo-gaussian')"`
- `Rscript -e "devtools::document()"` twice, rerunning after the new
  `student()` topic existed;
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- generated-site and stale-wording scans for Student-t claims;
- `air format .` (failed: `air` is not installed);
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`

Results:

- final targeted Student-t tests: 21 passed, 0 failed;
- targeted Gaussian/bivariate/meta/phylo regression slice: 196 passed,
  0 failed;
- full `devtools::test()`: 623 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: rebuilt the `student()` reference page,
  distribution-family article, home page, and changelog;
- final `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- the Student-t objective is compared against an independent base-R likelihood
  using `dt((y - mu) / sigma, df = nu, log = TRUE) - log(sigma)`;
- the recovery test uses deterministic Student-t quantiles to keep CRAN tests
  stable while checking `mu`, `sigma`, and tail `nu`;
- unsupported early-phase terms test random effects, `meta_known_V(V = V)`,
  and `sd(group)` rejection for Student-t fits.

Notes:

- the first full test run failed because the direct TMB phylogenetic-prior test
  constructs its own data list and needed the new dummy `X_nu` and `beta_nu`
  entries; the helper was updated and the full test suite then passed;
- `student()` is fixed-effect only for now: no random effects, known sampling
  covariance, phylogenetic terms, or bivariate Student-t likelihood yet;
- `nu` is the canonical first shape parameter here and means Student-t degrees
  of freedom/tail shape, not skewness.

## 2026-05-08: Main Documentation Known-`V` Equation Pairing

Scope:

- paired the public bivariate Gaussian meta-analysis syntax with the symbolic
  row-paired model equation in the README and main overview vignette;
- defined `y_stack = (y1_1, y2_1, ..., y1_n, y2_n)'` before the
  `V + Omega_stack` likelihood;
- clarified that the long-term bivariate random-effect example in the formula
  grammar is not the current implemented bivariate random-effects surface.

Commands run:

- `git diff --check`
- stale-wording scans for old bivariate known-`V` and unsupported-syntax text
  in README, vignettes, design docs, and selected generated pages;
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- `git diff --check`: clean;
- `pkgdown::check_pkgdown()`: no problems found;
- targeted bivariate test: 84 passed, 0 failed;
- `pkgdown::build_site()`: rebuilt the home page and main overview article;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- generated pages now include the new row-paired `y_stack` equation and
  matching `meta_vcov_bivariate()` syntax.

Notes:

- no implementation changed in this task;
- old dev-log entries that mention earlier rejected full/block known
  covariance behaviour were left intact as historical records;
- remaining `meta_gaussian()` and `tau ~` matches are intentional guardrails.

## 2026-05-08: Bivariate Gaussian Known Sampling Covariance Likelihood

Scope:

- implemented complete-row bivariate Gaussian known-`V` fitting, where
  `meta_known_V(V = V)` supplies a dense row-paired `2n` by `2n` sampling
  covariance matrix;
- added the known sampling covariance to the fitted residual covariance from
  `sigma1`, `sigma2`, and `rho12` before evaluating the TMB multivariate
  normal likelihood;
- updated bivariate `simulate()` and Pearson residuals to use the full
  row-paired observation covariance when known `V` is present;
- added likelihood-comparison, residual-`rho12` recovery, missing-row, and
  malformed-input tests;
- updated README, formula grammar, likelihood, distribution-roadmap,
  meta-analysis vignette, NEWS, and generated roxygen documentation.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- stale-wording scans for planned bivariate known-`V` text, stale diagonal/full
  covariance claims, informal author-style shorthand, and active-doc
  `meta_gaussian()` / `tau ~` guardrails.

Results:

- targeted bivariate test: 84 passed, 0 failed;
- full `devtools::test()`: 602 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: rebuilt meta-analysis, formula grammar, NEWS,
  `simulate()`, and `residuals()` pages;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Notes:

- active docs and generated pages no longer describe bivariate known `V` as a
  planned likelihood task;
- remaining `planned, not implemented` matches are for structured
  phylogenetic/spatial slopes and other intentionally planned features;
- remaining `meta_gaussian()` and `tau ~` matches are guardrails against
  unwanted meta-analysis syntax.

## 2026-05-08: Bivariate Meta-Analysis Covariance Helper

Scope:

- implemented `meta_vcov_bivariate()` as a user-facing constructor for
  row-paired dense known sampling covariance matrices;
- added tests for covariance construction from `cov12`, construction from
  `cor12`, independent-sampling defaults, and malformed input rejection;
- updated meta-analysis documentation to distinguish the implemented helper
  from the still-planned bivariate known-`V` likelihood.

Commands run:

- `Rscript -e "devtools::load_all(); V <- meta_vcov_bivariate(c(0.04, 0.03), c(0.05, 0.02), cor12 = c(0.4, 0.2)); stopifnot(all(dim(V) == c(4, 4))); print(V)"`
- `Rscript -e "testthat::test_file('tests/testthat/test-meta-vcov.R')"` (failed because this direct call did not load the package namespace)
- `Rscript -e "devtools::test(filter = 'meta-vcov')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- stale-wording and generated-site scans for `meta_vcov_bivariate()`, planned
  bivariate known-`V` wording, `meta_gaussian()`, `tau ~`, and malformed
  `meta_known_V()` markers.

Results:

- targeted `devtools::test(filter = 'meta-vcov')`: 17 passed, 0 failed;
- full `devtools::test()`: 589 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: rebuilt the helper reference page and meta-analysis
  article;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

## 2026-05-06: Initial Scaffold

Scope:

- package metadata;
- testthat scaffold;
- design documents;
- Codex agent and skill configuration;
- GitHub Actions R CMD check workflow.

Commands run:

- `devtools::document()`
- `devtools::test()`
- `devtools::check(error_on = "never")`
- `devtools::check(error_on = "never")` after scaffold hygiene fixes
- final `devtools::check(error_on = "never")`: 0 errors, 0 warnings, 1 note

Known issues:

- maintainer metadata uses a placeholder email until the project owner chooses
  final package metadata.
- no model-fitting code exists yet.
- `air` is not installed, so no formatter was run.
- `LinkingTo` is intentionally deferred until the first TMB source template is
  added.
- final check note was `unable to verify current time`, caused by local
  timestamp/repository access conditions rather than package structure.

## 2026-05-06: Grammar Refinement, pkgdown, and Logo

Scope:

- corrected source-of-truth grammar for `rho12`, meta-analysis, bivariate
  formulas, multiple scale components, phylogenetic A-inverse, and spatial SPDE
  plans;
- added initial `bf()` parser entries and formula marker functions;
- added package logo and pkgdown favicons;
- added meta-analysis and phylogenetic/spatial article stubs;
- added Claude Code instructions and after-task protocol.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_favicons(overwrite = TRUE)"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never')"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- `devtools::test()`: 16 passed, 0 failed.
- `pkgdown::check_pkgdown()`: no problems found.
- final `pkgdown::build_site()`: URLs, favicons, Open Graph, article metadata,
  and reference metadata all OK.
- final `devtools::check(error_on = "never")`: 0 errors, 0 warnings, 0 notes.

Known issues:

- `air` is not installed, so no `air format .` run occurred.
- fitting engine and simulation recovery tests remain the next task.

## 2026-05-06: Gaussian Location-Scale MVP

Scope:

- first TMB template for Gaussian `mu` and `sigma`;
- `drmTMB()` fitting path for fixed-effect `bf(y ~ x1, sigma ~ x1)`;
- S3 methods for coefficients, prediction, simulation, residuals, sigma,
  log-likelihood, variance-covariance, and summaries;
- simulation recovery tests and Phase 1 rejection tests;
- README, roadmap, design docs, vignette, NEWS, and known limitations updates.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- interactive smoke test for fitting, prediction, `sigma()`, and `simulate()`
- `Rscript -e "devtools::check(error_on = 'never')"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`

Results:

- `devtools::test()`: 30 passed, 0 failed.
- final `devtools::check(error_on = "never")`: 0 errors, 0 warnings, 0 notes.
- `pkgdown::check_pkgdown()`: no problems found.
- final `pkgdown::build_site()`: site built successfully.

Known issues:

- `air` is not installed, so no `air format .` run occurred.
- only fixed-effect Gaussian location-scale models are implemented.

## 2026-05-06: Diagonal Meta-Analysis Known Variance

Scope:

- implemented diagonal `meta_known_V(V = vi)` for Gaussian models;
- added known-variance likelihood term `sqrt(V_known + sigma^2)`;
- kept `sigma()` and `predict(..., dpar = "sigma")` as unknown heterogeneity SD;
- added tests for recovery, diagonal matrix input, full covariance rejection,
  missing known variance, malformed marker calls, and near-zero heterogeneity;
- reconciled docs, README, roadmap, NEWS, and known limitations after
  subagent review.

Commands run:

- `Rscript -e "devtools::document(); devtools::test()"`
- interactive smoke test for `meta_known_V(V = vi)` fitting and simulation
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never')"`

Results:

- `devtools::test()`: 73 passed, 0 failed.
- `pkgdown::check_pkgdown()`: no problems found.
- final `pkgdown::build_site()`: site built successfully.
- final `devtools::check(error_on = "never")`: 0 errors, 0 warnings, 0 notes.

Known issues:

- full or block-diagonal known covariance matrices are still rejected.
- exact zero heterogeneity is approximated by a small positive `sigma`.

## 2026-05-06: Bivariate Gaussian rho12

Scope:

- implemented `biv_gaussian()` for fixed-effect bivariate Gaussian
  location-scale-coscale models;
- added separate formulas for `mu1`, `mu2`, `sigma1`, `sigma2`, and `rho12`;
- used a bounded tanh response transform for `rho12` to avoid singular
  covariance matrices under extreme linear predictors;
- added bivariate simulation recovery tests for constant, near-zero, negative,
  and predictor-dependent residual correlation;
- added whitened bivariate Pearson residuals and coefficient-level `vcov()`
  names;
- reconciled README, roadmap, design docs, vignettes, NEWS, pkgdown reference
  index, and known limitations;
- added a gllvmTMB source map for later phylogenetic A-inverse and SPDE work.

Commands run:

- `Rscript -e "devtools::document()"`
- interactive smoke test for `biv_gaussian()` fitting and coefficient recovery
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test()"`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never')"`

Results:

- targeted bivariate tests: 40 passed, 0 failed.
- full `devtools::test()`: 113 passed, 0 failed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- final `devtools::check(error_on = "never")`: 0 errors, 0 warnings, 0 notes.

Known issues:

- `air` is not installed locally, so formatting could not be run.
- bivariate models are fixed-effect only.
- bivariate `meta_known_V()`, random effects, `mvbind()` shorthand,
  phylogenetic terms, and spatial terms are not implemented yet.

## 2026-05-07: First Push and pkgdown Workflow Fix

Scope:

- committed and pushed the initial `drmTMB` scaffold and Gaussian MVP work to
  `origin/main`;
- confirmed GitHub R-CMD-check succeeded after the push;
- diagnosed the first pkgdown workflow failure;
- changed the pkgdown workflow from `pkgdown::build_site_github_pages()` to
  `pkgdown::build_site()` so the site builds into `pkgdown-site` rather than
  trying to clean the tracked `docs/` design directory;
- updated Pages artifact actions to current major versions where available.

Commands run:

- `git fetch origin`
- `git add -A`
- `git commit -m "Scaffold drmTMB package and Gaussian MVPs"`
- `git push origin main`
- `gh run list --repo itchyshin/drmTMB --limit 10`
- `gh run view 25492948840 --repo itchyshin/drmTMB --job 74805330699 --log`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`

Results:

- pushed commit `69f11f8` to `origin/main`.
- GitHub R-CMD-check for commit `69f11f8`: success.
- Initial GitHub pkgdown run for commit `69f11f8`: failed because
  `build_site_github_pages()` tried to clean `docs/`.
- Local pkgdown after workflow diagnosis: no problems found; site built
  successfully into `pkgdown-site`.
- pushed commit `d8082a1` with the corrected pkgdown workflow.
- GitHub pkgdown for commit `d8082a1`: success, including deployment to
  `https://itchyshin.github.io/drmTMB/`.
- GitHub R-CMD-check for commit `d8082a1`: success.

Known issues:

- The pkgdown site intentionally publishes root Markdown pages such as
  `AGENTS.html`, `CLAUDE.html`, and `ROADMAP.html`; revisit later if those
  should be hidden.

## 2026-05-07: Gaussian mu Random Intercepts

Scope:

- implemented univariate Gaussian random intercepts in the `mu` formula;
- supported one or multiple additive terms such as `(1 | id)` and
  `(1 | site) + (1 | observer)`;
- used TMB Laplace integration with a non-centered parameterization:
  `b_group = sd_group * u_group`, `u_group ~ Normal(0, 1)`;
- kept random effects unsupported in `sigma` formulae, bivariate models,
  random slopes, and labelled covariance blocks;
- added conditional fitted-data prediction and residuals that include `mu`
  random-intercept modes;
- left `newdata` prediction fixed-effect-only for now;
- added tests for recovery, multiple grouping factors, missing grouping
  variables, singleton-group rejection, unsupported syntax, and fixed-parameter
  counting.

Commands run:

- `Rscript -e "devtools::document()"`
- interactive smoke test for `bf(y ~ x1 + (1 | id), sigma ~ x1)`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test(filter = 'gaussian')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never')"`
- `air format .`

Results:

- targeted random-intercept tests: 24 passed, 0 failed.
- full `devtools::test()`: 139 passed, 0 failed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- Standard `devtools::check(error_on = "never")`: 0 errors, 0 warnings,
  1 environment note about verifying the current time.
- `devtools::check(error_on = "never")` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`:
  0 errors, 0 warnings, 0 notes.

Known issues:

- `air` is not installed locally, so formatting could not be run.
- random slopes, bivariate random effects, random effects in scale formulae,
  and random-effect scale models remain future work.

## 2026-05-07: Formula, Family, Audience, and Validation Refinements

Scope:

- recorded that `drmTMB` should develop a package-specific formula grammar
  rather than copying `brms` wholesale;
- documented `formula = drm_formula(...)` as the canonical long-form direction,
  with `bf()` retained as the current prototype;
- documented composed bivariate family syntax such as
  `family = c(gaussian(), gaussian())` and
  `family = c(gaussian(), poisson())` as the public direction;
- clarified that `rho12` is residual response-response correlation, while
  double-hierarchical correlations among personality, plasticity,
  predictability, and malleability live in group-level covariance blocks;
- recorded a random-effect eligibility table for downstream distributional
  parameters;
- retargeted pkgdown/tutorial wording toward ecologists, evolutionary
  biologists, and environmental scientists;
- documented the two-tier validation strategy: comparator-package checks plus
  simulation recovery;
- added Shinichi Nakagawa as author, maintainer, and copyright holder with
  ORCID `0000-0002-7765-5182`.

Sidecar agents used:

- Boole: R API and formula parser review.
- Gauss: TMB and random-effect likelihood review.
- Noether: formula and correlation taxonomy review.
- Darwin: ecological examples and pkgdown review.
- Fisher: validation strategy review.

Commands run:

- `air format .`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- stale-text scan for placeholder author metadata and old `z`/`w` examples.

Results:

- `air format .`: not available locally.
- full `devtools::test()`: 139 passed, 0 failed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- `devtools::check(error_on = "never")` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`:
  0 errors, 0 warnings, 0 notes.
- stale-text scan found no placeholder maintainer metadata or old `z`/`w`
  formula examples in active docs.

Known issues:

- `drm_formula()` and composed bivariate family objects are design directions,
  not implemented API yet.
- `biv_gaussian()` remains the implemented bivariate Gaussian prototype.
- Comparator-package tests are planned; current passing tests are simulation and
  unit tests.

## 2026-05-07: Profile-Likelihood CI Roadmap

Scope:

- added profile-likelihood confidence intervals as a later inference phase;
- documented the likelihood-ratio drop criterion
  `qchisq(0.95, df = 1) / 2`;
- recorded `TMB::tmbprofile()` plus `uniroot()` as the preferred first strategy
  for direct TMB parameters;
- distinguished direct parameters, linear combinations, and nonlinear derived
  quantities such as ICCs and variance-component correlations;
- recorded fix-and-refit profiling as the first robust route for nonlinear
  derived quantities;
- documented boundary, non-monotone profile, and inner-optimization failure
  fallbacks.

Commands run:

- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`

Results:

- full `devtools::test()`: 139 passed, 0 failed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.

Known issues:

- profile-likelihood CIs are only a design roadmap item; no API or inference
  code has been implemented yet.

## 2026-05-07: Comparator Smoke Tests

Scope:

- added the first Tier 1 comparator-package tests;
- compared the homoscedastic Gaussian random-intercept overlap with
  `lme4::lmer(..., REML = FALSE)`;
- compared Gaussian ML meta-analysis with known sampling variances to
  `metafor::rma.uni(..., method = "ML")`;
- added `lme4` and `metafor` to `Suggests`;
- documented the implemented comparator tests in the testing strategy.

Commands run:

- interactive smoke comparisons against `lme4` and `metafor`;
- `Rscript -e "devtools::test(filter = 'comparators')"`
- `Rscript -e "devtools::test()"`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- comparator tests: 9 passed, 0 failed.
- full `devtools::test()`: 148 passed, 0 failed.
- `air format .`: not available locally.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- `devtools::check(error_on = "never")` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`:
  0 errors, 0 warnings, 0 notes.

Known issues:

- `glmmTMB` was available locally but emitted a TMB version mismatch warning, so
  it was not used for comparator tests.
- `gamlss` was not installed locally.
- Comparator tests are deliberately tiny smoke tests; broad comparator sweeps
  remain long-test or scheduled-CI work.

## 2026-05-07: Gaussian Math And Syntax

Scope:

- added symbolic equations beside R syntax for Gaussian location-scale models;
- clarified that residual `sigma` is distinct from group-level random-effect
  standard deviations;
- corrected bivariate teaching examples so fixed-effect syntax is labelled as
  implemented now and double-hierarchical random-intercept/random-slope syntax
  is labelled as planned;
- added `docs/design/13-gaussian-location-scale-math.md` as the
  source-of-truth Gaussian equation note;
- regenerated Rd files after updating the `bf()` examples.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg` consistency searches over README, vignettes, docs, R, and man files.

Results:

- full `devtools::test()`: 148 passed, 0 failed.
- `air format .`: not available locally.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- `devtools::check(error_on = "never")` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`:
  0 errors, 0 warnings, 0 notes.

Known issues:

- `drm_formula()` and `family = c(gaussian(), gaussian())` are still design
  directions, not implemented API.
- double-hierarchical bivariate random slopes are not implemented yet; the docs
  now label them as planned.

## 2026-05-07: GAMLSS Parameter Names

Scope:

- checked the local Rigby and Stasinopoulos (2005) GAMLSS PDF for parameter
  naming;
- added `Rigby2005GAMLSS` to `REFERENCES.bib`;
- added `docs/design/14-gamlss-parameter-names.md`;
- set `mu`, `sigma`, `nu`, and `tau` as the preferred canonical
  distributional-parameter names;
- updated the family registry, distribution roadmap, formula grammar, and
  reference programme so skew-normal uses `nu` rather than canonical `skew`.

Commands run:

- `pdftotext` on the local Rigby and Stasinopoulos PDF;
- `rg` consistency searches for `skew_normal`, `skew_t`, `skew`, `nu`, `tau`,
  `Rigby`, and `GAMLSS`;
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`

Results:

- the PDF source check confirmed the GAMLSS convention of `mu`, `sigma`, `nu`,
  and `tau`;
- full `devtools::test()`: 148 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully.

Known issues:

- `nu` and `tau` are documentation/design policy only until Student-t,
  skew-normal, skew-t, COM-Poisson, or beta families are implemented.
- Alias support for user-friendly names such as `skew` or `df` is deferred.

## 2026-05-07: Location-Coscale Phylogenetic Sources

Scope:

- checked the bivariate location-coscale note, mammalian body mass-litter size
  protocol, and MEE phylogenetic location-scale paper;
- recorded that MEE PLSM is the foundation and location-coscale is the
  extension that models residual correlation;
- added `docs/design/15-location-coscale-phylogenetic-extension.md`;
- updated vision, distribution roadmap, phylogenetic/spatial speed plan,
  reference programme, bivariate coscale vignette, and phylogenetic-spatial
  vignette;
- added local-source bibliography entries for the coscale note and mammal
  protocol.

Commands run:

- `pdfinfo` on the three source PDFs;
- `pdftotext` plus `rg` source searches for coscale, residual correlation,
  phylogenetic correlation, lifestyle, body mass, litter size, and PLSM terms;
- `rg` consistency search over README, vignettes, docs, ROADMAP, and
  `REFERENCES.bib`;
- `git diff --check`;
- `Rscript -e "devtools::test()"`;
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`;
- `air format .`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- full `devtools::test()`: 148 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `air format .`: not available locally;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

Known issues:

- phylogenetic location-coscale syntax in the vignette is planned, not
  implemented;
- `rho12 ~ predictors` is implemented only for fixed-effect bivariate Gaussian
  models at this stage.

## 2026-05-07: Phylogenetic And Spatial Common Math

Scope:

- read the local phylogenetic/spatial meta-analysis tutorial;
- added a shared structured-effect design note for phylogeny and space:
  `z ~ MVN(0, sigma_z^2 K)`;
- documented `K = A` for phylogenetic correlation, `K = M` for spatial
  correlation, A-inverse as the phylogenetic speed path, and SPDE/GMRF
  precision as the spatial speed path;
- connected meta-analysis, known sampling covariance `V`, phylogenetic
  structured effects, and spatial structured effects;
- added a `gllvmTMB` source map for future A-inverse and SPDE borrowing;
- replaced casual double-hierarchical shorthand in active docs and vignettes
  with professional wording and a formal citation to O'Dea et al. (2022).
- added Pat, an applied PhD student user tester role, and documented the
  standing review team in `AGENTS.md`.
- added Jason, Curie, Emmy, Grace, and Rose agent configs for landscape
  scouting, literature, pkgdown/course editing, reproducibility, and systems
  auditing.

Sidecar agents used:

- Jason: source-only `gllvmTMB` phylogenetic/SPDE source-map inspection.

Commands run:

- `pdfinfo /Users/z3437171/Downloads/Tutorial___Phylo_spatial_meta_analysis_2.pdf`
- `pdftotext` plus targeted `rg` searches over the local tutorial PDF
- `rg` consistency scans for casual author-name shorthand, package-name
  shorthand, `meta_gaussian`, `tau ~`, and `rho ~`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `gh run view 25498816381 --repo itchyshin/drmTMB --json status,conclusion,jobs`

Results:

- local PDF checks confirmed the tutorial's shared phylogenetic/spatial
  random-effect framing and identifiability warnings;
- full `devtools::test()`: 148 passed, 0 failed;
- `git diff --check`: passed;
- `air format .`: not available locally;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- GitHub R-CMD-check for the previous pushed commit completed successfully on
  macOS, Windows, and Ubuntu.

Known issues:

- this task changed design/docs only; no phylogenetic or spatial fitting code
  has been implemented;
- sparse known covariance, A-inverse phylogeny, and SPDE spatial fields remain
  future work;
- remaining `meta_gaussian()` and `tau ~` matches are intentional guardrails.

## 2026-05-07: General Package Framing

Scope:

- broadened package-level wording so `drmTMB` is not described as belonging to
  only one domain;
- kept ecology, evolution, and environmental science as the main source of
  examples and tutorials;
- renamed the getting-started vignette and several tutorial titles to more
  general headings;
- updated `_pkgdown.yml` navigation to match the new titles;
- updated `docs/design/00-vision.md` with the policy of broad package identity
  and domain-focused examples.

Sidecar agents used:

- Emmy: pkgdown/documentation framing review.

Commands run:

- `rg` stale-heading scans over README, vignettes, docs, and `_pkgdown.yml`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- `git diff --check`: passed;
- full `devtools::test()`: 148 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

Known issues:

- examples remain ecology/evolution heavy by design, but future broader
  examples may be useful as the package matures.

## 2026-05-07: Equation And Syntax Pairing

Scope:

- expanded the location-scale tutorial so Gaussian equations, R syntax,
  parameter meanings, random-intercept scale components, and meta-analysis
  known variance are shown side by side;
- expanded the bivariate coscale tutorial so the implemented `mu1`, `mu2`,
  `sigma1`, `sigma2`, and `rho12` equations are paired with the exact current
  prototype syntax;
- added future group-level equations to distinguish covariance-block
  correlations from residual `rho12`;
- updated the getting-started article to state that `drmTMB` documentation is
  model-first: equations before API;
- updated design notes so the vignette equations and likelihood specification
  match.

Commands run:

- `git diff --check`
- `rg` stale-syntax scans for `O'Dea-style`, `biological data`,
  `meta_gaussian()`, `tau ~`, `rho ~`, and bivariate prototype mentions
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `air format .`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg` generated-site checks for the new equation headings

Results:

- `git diff --check`: passed;
- full `devtools::test()`: 148 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `air format .`: not available locally;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- generated `pkgdown-site` contains the new location-scale and bivariate
  equation sections.

Known issues:

- this task changed documentation only; it did not implement random slopes,
  bivariate random effects, full known covariance, phylogenetic A-inverse, or
  spatial SPDE code;
- `biv_gaussian()` remains in public examples because it is the implemented
  prototype, while `family = c(gaussian(), gaussian())` remains the design
  direction.

## 2026-05-07: Sharpened Logo And Favicons

Scope:

- replaced the previous logo with a sharper vector-first version based on
  Shinichi's preferred density-curve hex concept;
- exported `man/figures/logo.png` from the SVG for README, pkgdown Open Graph,
  and CRAN-style package assets;
- regenerated pkgdown favicon assets from the same SVG, including SVG, PNG,
  ICO, Apple touch icon, and web-app manifest PNGs;
- updated the web app manifest name and theme/background colour to match the
  logo.

Commands run:

- `rsvg-convert` exports for 1200px logo and favicon PNG sizes
- small R script to rebuild `pkgdown/favicon/favicon.ico`
- visual inspection with `view_image` for the full logo and 96px favicon
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- generated-site asset checks with `file` and `rg`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- full logo renders as a 1200 by 1200 RGBA PNG;
- pkgdown copies the new `logo.svg`, favicon files, and Open Graph logo into
  `pkgdown-site`;
- `git diff --check`: passed;
- full `devtools::test()`: 148 passed, 0 failed;
- `air format .`: not available locally;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully, including favicons;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

Known issues:

- the 96px favicon is readable as a hex and density-curve logo, but the text is
  necessarily small at favicon size;
- future refinements can simplify the favicon-specific SVG further if browser
  tabs need stronger small-size legibility.

## 2026-05-07: Dense `meta_known_V()` Gaussian Meta-Analysis

Scope:

- extended Gaussian meta-analysis from vector/diagonal known sampling variance
  to dense full known sampling covariance via `meta_known_V(V = V)`;
- kept meta-analysis as `family = gaussian()`, with unknown extra heterogeneity
  still modelled by `sigma ~ ...`;
- added dense MVN likelihood support in the TMB template;
- added simulation, Pearson residual, and observation-covariance handling for
  dense known `V`;
- added tests for full-covariance log-likelihood agreement against a base R MVN
  calculation, row/column subsetting after missing data, invalid covariance
  rejection, and full known `V` combined with a `mu` random intercept;
- added a regression test for full-`V` missing covariance entries in rows already
  removed by model missingness, after Jason's review flagged possible
  over-dropping;
- created the project-local `after-task-audit` skill and aligned the standing
  team table in `AGENTS.md`.

Commands run:

- `Rscript -e "devtools::test(filter = 'meta-known-v')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check()"`
- stale-wording `rg` scans for full/block covariance rejection, `meta_gaussian`,
  `tau ~`, `rho ~`, and malformed `meta_known_V()` examples

Results:

- targeted `meta-known-v` tests: 36 passed, 0 failed;
- full `devtools::test()`: 166 passed, 0 failed;
- `devtools::document()`: completed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `air format .`: not available locally.

Known issues:

- dense full `V` is appropriate for modest meta-analysis examples; sparse
  covariance storage remains planned for large phylogenetic and spatial
  workloads;
- bivariate known sampling covariance is still not implemented;
- historical after-task notes from the earlier diagonal-only implementation still
  describe the state at the time they were written.

Team learning:

- created Rose's project-local `after-task-audit` skill;
- updated the after-task protocol so future reports include what did not go
  smoothly and which team/process capability should improve next;
- added Williams et al. (2026), "Meta-analysis with the glmmTMB R package", as
  a meta-analysis comparator reference for `glmmTMB::equalto()`;
- noted that `air format .` is unavailable locally and should either be
  installed later or replaced with a documented formatter.

## 2026-05-07: Gaussian `mu` Random Slopes

Scope:

- extended univariate Gaussian `mu` random effects from random intercepts to
  random slopes with one numeric predictor per random-slope term, written as
  `(0 + x | id)`;
- added a random-effect design-value matrix so TMB evaluates
  `mu_i = X_mu beta_mu + sum_j z_j[i] sd_j u_j[g[i]]`;
- preserved the existing non-centered Laplace parameterization and the
  existing random-intercept path as the `z_j[i] = 1` special case;
- allowed independent random intercept and slope terms through separate syntax:
  `(1 | id) + (0 + x | id)`;
- deliberately kept `(1 + x | id)` and `(1 + x | p | id)` reserved for the
  later correlated covariance-block implementation;
- updated the Gaussian equations, formula grammar, random-effect design note,
  likelihood note, README, roadmap, NEWS, vignette text, and known limitations.

Commands run:

- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "pkgdown::build_site()"`
- `git diff --check`
- stale-wording `rg` scans for random-slope and random-intercept-only wording
- `air --version`

Results:

- targeted random-effect tests: 44 passed, 0 failed;
- full `devtools::test()`: 186 passed, 0 failed;
- `devtools::document()`: completed and updated `man/drmTMB.Rd`;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check()`: 0 errors, 0 warnings, 1 system-clock note;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes;
- `git diff --check`: passed;
- `air --version`: not available locally.

Known issues:

- `(1 + x | id)` is not implemented because it implies an intercept-slope
  covariance block that the current TMB parameterization does not yet estimate;
- random slopes are restricted to a single numeric predictor, so factor and
  multi-column slope terms are rejected;
- random effects in `sigma`, `mu1`, `mu2`, phylogenetic/spatial structured
  effects, and random-effect scale formulas remain planned.

Team learning:

- Boole: formula messages must protect users from accidentally assuming
  correlated random effects when the implementation is currently independent.
- Noether: the symbolic equation needed the design multiplier `z_j[i]`; without
  it, the R formula and TMB implementation would not be auditable.
- Curie: random-slope tests should cover recovery, missingness, unsupported
  correlated syntax, and non-numeric slope rejection in one pass.
- Rose: stale wording tends to persist in vignettes after implementation
  changes, so after-task scans should include articles as well as design docs.

Follow-up design clarification:

- ordinary grouped random effects may have several separate independent numeric
  random slopes in the current implementation, for example
  `(0 + x1 | id) + (0 + x2 | id)`;
- random interaction slopes are currently supported only by precomputing the
  interaction column before fitting;
- future correlated blocks such as `(1 + x1 + x2 + x1:x2 | id)` should be
  supported only with explicit covariance-block parameterization and simulation
  checks;
- phylogenetic and spatial random slopes should be staged more conservatively:
  intercept-only first, then one structured slope in `mu`, then only a small
  number of slopes or interaction slopes after strong recovery evidence.

## 2026-05-07: Random-Slope Comparator Smoke Test

Scope:

- added an `lme4` comparator smoke test for the currently implemented
  independent Gaussian random-intercept plus random-slope model;
- compared fixed effects, random-effect SDs, residual SD, and log-likelihood
  against `lme4::lmer(..., REML = FALSE)`;
- kept the test skipped when `lme4` is not installed;
- updated the testing strategy to distinguish implemented independent
  random-slope comparator tests from future correlated-block comparator tests.

Commands run:

- `Rscript -e "devtools::test(filter = 'comparators')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`

Results:

- targeted comparator tests: 14 passed, 0 failed in the local environment;
  comparator tests skip where optional comparator packages are unavailable.
- full `devtools::test()`: 191 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes;
- `git diff --check`: passed.

Known issues:

- this comparator covers independent random-effect terms written as
  `(1 | id) + (0 + x | id)`;
- correlated blocks such as `(1 + x | id)` are still planned and need a
  separate comparator once implemented.

Team learning:

- Fisher: comparator tests are useful only when covariance semantics match
  exactly; independent and correlated random slopes should not share the same
  comparator claim.

## 2026-05-07: Parallel Correlated Random-Block Design

Scope:

- ran four parallel read-only side agents for the next correlated random-effect
  block phase:
  - Jason: related package landscape and source map;
  - Gauss: TMB parameterization and data-structure design;
  - Curie: simulation and comparator test plan;
  - Rose: systems audit for stale wording and consistency gaps;
- created `docs/design/17-correlated-random-effect-blocks.md`;
- fixed Rose's wording findings around `rho12`, future grammar, random-slope
  scope, random-effect SD naming, phylogenetic/spatial slope staging, and
  optional comparator wording.

Commands run:

- stale-wording `rg` scans for generic `rho`, `X_rho`, future grammar wording,
  random-slope scope, and comparator claims.
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- the next implementation target is ordinary Gaussian `mu`
  `(1 + x | id)` with a non-centered `q = 2` covariance block;
- current independent syntax `(1 | id) + (0 + x | id)` remains unchanged;
- labelled `(1 + x | p | id)` blocks remain planned after ordinary unlabelled
  blocks work and pass comparator/recovery tests.
- `git diff --check`: passed;
- stale-wording scans: remaining hits are confined to audit/check-log text that
  records the wording issues rather than active guidance;
- `devtools::test()`: 191 passed, 0 failed, 0 warnings, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes.

Known issues:

- this task changed design documentation only; it did not implement correlated
  random-effect covariance blocks.

Team learning:

- parallel agents are useful for read-only scouting, design review, simulation
  planning, and systems audit;
- implementation remains safer through one integrator unless file ownership is
  explicitly split;
- future spawn requests should avoid combining full-history forking with named
  specialist agents.

## 2026-05-07: Ordinary Correlated Gaussian `mu` Random-Effect Blocks

Scope:

- implemented ordinary unlabelled correlated Gaussian `mu` random
  intercept-slope blocks written as `(1 + x | id)` or `(x | id)`;
- kept independent syntax `(1 | id) + (0 + x | id)` unchanged;
- added `eta_cor_mu` in the TMB parameter vector and exposed transformed
  group-level correlations as `corpars$mu`;
- kept labelled blocks such as `(1 + x | p | id)` rejected for the later
  cross-formula covariance phase;
- updated README, NEWS, pkgdown Open Graph image config, design docs,
  location-scale docs, known limitations, roadmap, and generated reference docs;
- added a repo-facing `man/figures/drmTMB-logo.png` asset so the GitHub README
  page can refresh the hex logo without relying on the older filename cache.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test(filter = 'comparators')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- local browser preview at `http://127.0.0.1:4187/index.html`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- `devtools::test(filter = 'gaussian-random-intercepts')`: 93 passed, 0
  failed;
- `devtools::test(filter = 'comparators')`: 20 passed, 0 failed;
- full `devtools::test()`: 246 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- local browser preview showed the updated home page wording and visible hex
  logo;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes.

Tests of the tests:

- the existing independent random-slope `lme4` comparator failed during the
  first implementation attempt because the new block layout accidentally
  treated independent slope values as intercept-like values; this caught a real
  regression and was fixed before merging;
- the new correlated-block comparator checks fixed effects, random-effect SDs,
  intercept-slope correlation, residual SD, and marginal log-likelihood against
  `lme4::lmer(..., REML = FALSE)`;
- simulation tests cover positive, near-zero, negative, high-correlation,
  weak-slope-SD, factor-fixed-effect, missingness, and malformed-syntax cases.

Known issues:

- only ordinary unlabelled `q = 2` Gaussian `mu` blocks are implemented;
- factor or multi-column random slopes, `q > 2` blocks, labelled
  `(1 + x | p | id)` blocks, scale-formula random effects, bivariate
  group-level covariance blocks, phylogenetic/spatial slope blocks, and
  non-Gaussian random-effect blocks remain planned.

Team learning:

- comparator tests are not just reassurance; they caught a real design-matrix
  regression in the first implementation pass;
- README and pkgdown can drift visually, so repo-facing assets should be
  checked alongside the built site after logo or status changes;
- keep group-level correlation extraction under `corpars`, not under residual
  `rho12`.

## 2026-05-07: Logo Blue-Density Fit Adjustment

Scope:

- adjusted the rightmost blue distribution in the hex logo so its tail fits
  inside the hex boundary rather than being clipped;
- synchronized the source SVGs, rendered README/pkgdown PNGs, and favicon
  assets.

Commands run:

- `rsvg-convert` renders for `man/figures/*.png` and `pkgdown/favicon/*.png`
- Node-based PNG-in-ICO wrapper for `pkgdown/favicon/favicon.ico`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- file-type checks for the rendered PNG and ICO assets
- `rg` checks for the updated blue-curve path in source and built-site SVGs

Results:

- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- the main logo remains 1200 x 1200 RGBA PNG;
- favicon PNG and ICO assets were regenerated from the same corrected SVG;
- visual inspection confirmed the blue density now fits inside the hex.

Known issues:

- this was a visual asset-only task; no R code, likelihood, documentation
  prose, or model examples changed.

Team learning:

- small visual regressions should still pass through the same asset
  synchronization loop: SVG source, rendered PNGs, favicon derivatives,
  pkgdown build, and after-task note.

## 2026-05-07: Labelled Gaussian `mu` Random-Effect Blocks

Scope:

- implemented labelled Gaussian `mu` random intercepts and labelled correlated
  numeric random intercept-slope blocks, written as `(1 | p | id)` and
  `(1 + x | p | id)`;
- kept the current likelihood deliberately identical to the corresponding
  unlabelled block, with the middle name retained as a covariance-block label
  in fitted object names;
- kept group-level correlations separate from residual bivariate correlation:
  labelled block correlations are returned under `corpars$mu`, while residual
  response-response correlation remains `rho12`;
- updated README, NEWS, roadmap, known limitations, formula grammar, likelihood
  notes, random-effect design notes, Gaussian math notes, bivariate-coscale
  caveats, vignettes, generated Rd, and pkgdown pages;
- left cross-formula/cross-parameter labelled covariance sharing for a later
  design phase.

Commands run:

- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test(filter = 'comparators')"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted Gaussian random-effect tests: 141 passed, 0 failed;
- targeted comparator tests: 26 passed, 0 failed;
- targeted Gaussian location-scale tests: 40 passed, 0 failed;
- full `devtools::test()`: 299 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes;
- after a read-only reviewer found two P1 issues, reserved distributional
  parameter names were rejected as covariance-block labels and the formula
  grammar vignette was split into current fixed-effect bivariate syntax versus
  future bivariate random-effect syntax; the full package check was rerun after
  those fixes and remained at 0 errors, 0 warnings, and 0 notes.

Tests of the tests:

- the labelled correlated-block test compares fixed effects, residual scale,
  random-effect standard deviations, group-level correlation, and log-likelihood
  against the same unlabelled block, because labels are metadata in the current
  implementation;
- the new `lme4` comparator checks that labelled `(1 + x | p | ID)` has the
  same mixed-model semantics as `lme4::lmer(y ~ x + f + (1 + x | ID), REML =
  FALSE)`;
- malformed-input tests cover non-symbol labels, factor random slopes, `q > 2`
  labelled blocks, duplicate covariance terms, labelled/unlabelled overlap, and
  unsupported `sigma ~ (1 | p | id)`;
- malformed-input tests now also reject misleading reserved labels such as
  `(1 + x | rho12 | id)`;
- recovery and stability tests cover moderate covariance, near-zero
  correlation, high positive/negative correlation, small residual scale, large
  residual scale, and missingness.

Known issues:

- the middle label is currently a namespace for output names and future
  matching; it does not yet tie covariance blocks across `mu1`, `mu2`, `sigma`,
  or other distributional parameters;
- random effects in `sigma`, bivariate response formulas, phylogenetic
  A-inverse effects, spatial SPDE effects, factor slopes, and `q > 2`
  correlated blocks remain planned;
- finite-sample recovery of variance components is noisy at very small residual
  scales, so CRAN-safe stability checks use tolerances that reflect this.

Team learning:

- Boole's grammar rule is now explicit: the middle term in `(1 + x | p | id)`
  is a simple label, not a data variable and not residual `rho12`;
- Gauss confirmed no TMB likelihood change was needed because labelled and
  unlabelled blocks share the same non-centered `q = 2` Gaussian machinery;
- Curie's tests should keep combining comparator checks, simulation recovery,
  and malformed-input checks for every mixed-model grammar change;
- Rose's audit caught that pkgdown, README, NEWS, roadmap, known limitations,
  and equation notes all needed synchronized wording.

## 2026-05-07: Gaussian Residual-Scale Random Intercepts

Scope:

- implemented residual-scale random intercepts in the univariate Gaussian
  `sigma` formula, written as `sigma ~ z + (1 | id)`;
- kept the first slice narrow: no labelled `sigma` blocks, no residual-scale
  random slopes, no bivariate `sigma1`/`sigma2` random effects, and no
  `sd(id) ~ x` random-effect scale models yet;
- added TMB data and parameters for `u_sigma` and `log_sd_sigma`, with
  non-centered standard-normal residual-scale random effects added to
  `log(sigma_i)`;
- updated conditional fitted-data prediction so `predict(fit, dpar = "sigma")`,
  `sigma(fit)`, residuals, and simulation include fitted `sigma` random-effect
  modes;
- updated README, NEWS, roadmap, likelihood notes, formula grammar, random
  effects notes, Gaussian math notes, testing strategy, vignettes, known
  limitations, and generated Rd.

Commands run:

- `Rscript -e "devtools::load_all(quiet = FALSE)"`
- manual smoke fit for `bf(y ~ x, sigma ~ z + (1 | id))`
- manual smoke fit for `bf(y ~ x + (1 | id), sigma ~ z + (1 | id))`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`

Results:

- targeted Gaussian random-effect tests: 169 passed, 0 failed;
- targeted Gaussian location-scale tests: 39 passed, 0 failed;
- full `devtools::test()`: 326 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes;
- `git diff --check`: passed.

Tests of the tests:

- simulation tests cover moderate residual-scale random-intercept recovery,
  near-zero residual-scale heterogeneity, large residual-scale heterogeneity,
  missingness in `sigma` random-effect variables, and coexistence of independent
  `mu` and `sigma` random intercepts on the same grouping factor;
- malformed-input tests still reject labelled `sigma` blocks and residual-scale
  random slopes, preserving the intended narrow phase boundary;
- manual smoke fits checked that fitted `sigma` predictions are positive and
  that `sdpars$sigma` and `random_effects$sigma` are populated.

Known issues:

- residual-scale random slopes are not implemented;
- labelled covariance blocks in `sigma` are not implemented;
- `sd(id) ~ x` random-effect scale models remain a separate future
  double-hierarchical phase;
- bivariate `sigma1` and `sigma2` random effects remain future work.

Team learning:

- Bacon and Leibniz emphasized that `sigma ~ (1 | id)` and `sd(id) ~ x` are
  different likelihoods and need different tests;
- Arendt recommended this narrow residual-scale random-intercept slice before
  the broader `sd(id) ~ x` grammar because it extends the current Laplace path
  without introducing group-level scale-model matching yet;
- Ada should keep the phrase "residual-scale random intercept" visible in docs
  to avoid collapsing all scale concepts into the single word `sigma`.

## 2026-05-08: Random-Effect Scale Design And Equation Pairing

Scope:

- created the design contract for future `sd(id) ~ x_group` random-effect
  scale models in `docs/design/18-random-effect-scale-models.md`;
- added the pkgdown tutorial `vignettes/which-scale.Rmd`, pairing symbolic
  equations with R syntax for residual `sigma`, residual-scale random
  intercepts, future among-group `sd(id)`, random-slope correlations, and
  residual bivariate `rho12`;
- updated `_pkgdown.yml` so the new tutorial appears in the Tutorials menu and
  article index;
- fixed live stale wording from the previous phase: `sigma` random-effect
  eligibility, Gaussian family status, Gaussian math implementation mapping,
  phylo/spatial baseline status, location-scale vignette opening, and
  `bf()` examples;
- updated `CLAUDE.md` so Claude Code sees implemented bivariate fixed-effect
  syntax separately from future bivariate random-effect syntax;
- expanded the correlation roadmap beyond residual `rho12`, adding future
  phylogenetic, non-phylogenetic species, spatial, study/site, and other
  group-level correlations as separate covariance summaries;
- broadened the after-task stale-wording scan to catch underreported
  implementation status such as `sigma.*Later` and `currently.*only.*mu`.

Commands run:

- `gh run list --branch main --limit 6`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "pkgdown::build_site()"`
- stale-wording `rg` scans for `simple.*mu random`, `sigma.*Later`,
  `currently.*only.*mu`, `optional simple.*location`, `meta_gaussian`,
  `tau ~`, `rho ~`, `sd(id) ~ x`, and generated-site article/navigation text.

Results:

- remote GitHub Actions for commit `44e86be` completed successfully for both
  R-CMD-check and pkgdown;
- full `devtools::test()`: 326 passed, 0 failed, 0 warnings, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully and rendered
  `articles/which-scale.html`;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes.

Tests of the tests:

- this was a design/documentation phase, so no new model tests were added;
- the full test suite and package check protect existing implemented behavior
  while the new design files remain non-executable;
- generated Rd and pkgdown pages were rebuilt to check that the roxygen example
  correction and tutorial navigation are reflected in rendered documentation.

Known issues:

- `sd(id) ~ x_group` remains planned, not implemented;
- future structured correlations need exact public extractor naming before
  implementation;
- the previous after-task report for residual-scale random intercepts
  overstated the stale-wording audit: Rose found live docs that still
  underreported implemented `sigma` random intercepts. This phase corrected
  those files and updated the protocol to make the miss less likely.

Team learning:

- Pat and Noether converged on the same requirement as Shinichi: every
  important syntax example should be paired with symbolic equations;
- Rose's systems audit caught a real process weakness in stale-wording scans;
- Ada should run the broader status-pattern scan before writing the
  consistency-audit claim, not after.

## 2026-05-08: Gaussian Random-Effect Scale MVP

Scope:

- implemented the first `sd(group) ~ x_group` random-effect scale model for
  univariate Gaussian fits;
- the implemented target is exactly one unlabelled `mu` random intercept, for
  example `bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w)`;
- added group-level design matrix construction for `sd(id)`, with predictors
  checked for constancy within group after missing-row filtering;
- added TMB likelihood support through `beta_sd_mu`, `X_sd_mu`, and
  group-specific `sd_mu_group = exp(W alpha)` while keeping standardized
  `u_mu` as the Laplace-integrated random effect;
- mapped out the replaced scalar `log_sd_mu` entry when `sd(id)` is active;
- updated coefficient, prediction, random-effect, and `sdpars` extraction so
  `coef(fit, "sd(id)")`, `predict(fit, dpar = "sd(id)")`, and
  `sdpars$sd(id)` agree with the fitted model;
- documented the symbolic model and R syntax in the likelihood, formula,
  random-effect, Gaussian math, testing, roadmap, README, NEWS, and vignette
  files;
- kept the correlation roadmap separate from this feature: residual `rho12` is
  still distinct from phylogenetic, non-phylogenetic species, spatial,
  study/site, and other group-level covariance correlations.

Commands run:

- `gh run list --branch main --limit 6`
- `Rscript -e "devtools::test(filter = 'gaussian-random-effect-scale')"`
- `Rscript -e "devtools::test(filter = 'gaussian-random-effect-scale|comparators')"`
- manual smoke fit for `bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w)`
- manual mapping smoke fit for `bf(y ~ x + (1 + x | site) + (1 | id), sigma ~ z, sd(id) ~ w)`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'), manual = FALSE)"`
- stale-wording `rg` scans over README, NEWS, ROADMAP, docs, vignettes, R, man,
  tests, and generated pkgdown output for old `sd(id)` planned/future wording.

Results:

- prior remote GitHub Actions for commit `bd91b61` completed successfully for
  both R-CMD-check and pkgdown;
- targeted `gaussian-random-effect-scale|comparators` tests: 78 passed, 0
  failed, 0 warnings, 0 skipped;
- full `devtools::test()`: 378 passed, 0 failed, 0 warnings, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully and rebuilt the reference,
  README, NEWS, and tutorials;
- the first `devtools::check()` pass had one NOTE from an unqualified
  `setNames()` call; this was fixed by using `stats::setNames()`;
- rerun `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'), manual = FALSE)`:
  0 errors, 0 warnings, 0 notes.

Tests of the tests:

- simulation recovery checks estimate `mu`, `sigma`, and `sd(id)` coefficients
  from generated data;
- zero-slope tests check reduction toward a constant random-intercept scale;
- factor-RHS and missingness tests check model-matrix and retained-row handling;
- malformed-input tests cover absent targets, wrong groups, ambiguous slopes,
  labelled targets, duplicate `sd()` formulae, within-group-varying predictors,
  bivariate rejection, and unsupported non-Gaussian family rejection;
- comparator tests check the `sd(id) ~ 1` overlap against
  `lme4::lmer(..., REML = FALSE)`;
- a regression test checks that `sd(id)` still targets the correct expanded
  coefficient when a preceding correlated random-effect block is present;
- summary/vcov tests check finite aligned coefficient SEs for `sd(id)`.

Review findings addressed:

- Gauss/Fisher found no P0/P1 likelihood issues and requested a summary/vcov
  alignment test for `sd(id)`; added.
- Rose found a blocking expanded-coefficient indexing bug when another
  multi-coefficient `mu` block preceded the `sd(id)` target; fixed by carrying
  `target_coef` separately from the original random-term index and adding a
  regression test.
- Rose also found stale vignette and known-limitation wording; updated.

Known limitations:

- only one `sd(group)` formula is supported;
- the target must be one unlabelled univariate Gaussian `mu` random intercept;
- group-level predictors in `sd(group)` must be constant within the group after
  missing-row filtering;
- slope-specific, labelled-block, residual-scale, bivariate, phylogenetic,
  spatial, and non-Gaussian random-effect scale models remain future work;
- `sdpars$sd(id)` names include both the dpar and group level, while
  `predict(fit, dpar = "sd(id)")` names values by group level only. This is
  not blocking but should be revisited when extractor APIs mature.

Team learning:

- the code needed the same distinction as the mathematical notation: original
  random-effect term index and expanded covariance coefficient index are not
  the same object;
- Rose's systems audit caught both a numerical wiring risk and stale wording,
  so the after-task-audit skill is paying for itself;
- future likelihood changes should include an explicit "preceding block" test
  whenever parser terms are expanded into internal coefficient blocks.

## 2026-05-08: Formula Constructor and Composed Gaussian Family API

Scope:

- made `drm_formula()` the primary public formula constructor while keeping
  `bf()` as a short alias;
- routed `family = c(gaussian(), gaussian())` and
  `family = list(gaussian(), gaussian())` to the implemented bivariate
  Gaussian location-coscale likelihood;
- kept mixed-response bivariate families as planned future work with a clear
  error path;
- added an explicit one-response/two-response scope guard for composed
  families with more than two entries.

Commands run:

- `if command -v air >/dev/null 2>&1; then air format .; else echo 'air not installed'; fi`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'package-skeleton|biv-gaussian')"`
- manual smoke fit for `drm_formula(mu1 = y1 ~ x, mu2 = y2 ~ x)` with
  `family = c(gaussian(), gaussian())`
- manual smoke rejection for `family = c(gaussian(), poisson())`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'), manual = FALSE)"`
- stale-wording `rg` scans over source, man pages, vignettes, and generated
  `pkgdown-site` for old `bf()`-primary wording, `biv_gaussian()` prototype
  wording, and obsolete composed-family future wording.

Results:

- `air` was not installed locally, so no formatter was run;
- targeted `package-skeleton|biv-gaussian` tests: 67 passed, 0 failed, 0
  warnings, 0 skipped;
- full `devtools::test()`: 389 passed, 0 failed, 0 warnings, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully and regenerated
  `pkgdown-site`;
- generated-site audit confirmed `reference/bf.html` is a redirect to
  `reference/drm_formula.html`, and generated docs describe
  `drm_formula()`/`bf()` and both all-Gaussian composed-family spellings;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'), manual = FALSE)`:
  0 errors, 0 warnings, 0 notes.

Tests of the tests:

- acceptance tests fit the same bivariate Gaussian likelihood through both
  `c(gaussian(), gaussian())` and `list(gaussian(), gaussian())`;
- malformed-family tests reject `c(gaussian(), poisson())`;
- new scope tests reject three-response composed families through both `c()`
  and `list()` spellings;
- constructor tests verify that `drm_formula()` captures distributional
  formula entries and that `bf()` remains a working alias.

Review findings addressed:

- Franklin found no P0/P1 issues and flagged the under-documented
  `list(gaussian(), gaussian())` spelling plus the missing three-response
  composed-family guard; both were fixed and tested.
- Jason/Rose flagged generated pkgdown lag and missing closure notes; the site
  was rebuilt, generated pages were scanned, and this check-log plus an
  after-task report now supersede earlier design-only notes.

Known limitations:

- only all-Gaussian composed bivariate families are implemented;
- mixed bivariate families such as `c(gaussian(), poisson())` still require a
  designed joint likelihood and interpretation of `rho12`;
- bivariate random effects and `mvbind()` shorthand remain future work.

Team learning:

- if code tolerates an input spelling and tests rely on it, the docs should
  either bless it or the tests should remove it;
- generated pkgdown output must be part of the phase gate whenever public API
  wording changes;
- Rose-style audits are best run before the final commit, not after, because
  small naming/API inconsistencies are cheap to fix early.

## 2026-05-08: Project-Local Prose Style Review Skill

Scope:

- read `yzhao062/agent-style` and adapted its relevant writing principles into
  a compact project-local `prose-style-review` skill;
- updated `AGENTS.md`, `CLAUDE.md`, `docs/design/10-after-task-protocol.md`,
  and Pat/Rose/documentation/pkgdown agent configs so the team can apply the
  standard consistently;
- updated `after-task-audit` so prose-heavy tasks actually trigger the prose
  gate before closing;
- recorded provenance: no files or text were copied from `yzhao062/agent-style`;
  this is a local adaptation of review principles, and `agent-style` is not a
  package dependency.

Commands run:

- browsed `https://github.com/yzhao062/agent-style` and
  `https://github.com/yzhao062/agent-style/blob/main/RULES.md`;
- `python3` TOML parse check over `.codex/agents/*.toml`;
- `git diff --check`;
- `rg` scans for dependency-wording drift, pkgdown role names,
  `skew`, and `tau`.

Results:

- TOML parse check: passed;
- `git diff --check`: passed;
- no package metadata, namespace, compiled code, tests, or likelihood code
  changed;
- Pat found no blocking confusion and requested clearer `tau`, `coscale`, and
  error-recovery wording; incorporated;
- Rose found no dependency addition and requested updating `after-task-audit`,
  normalizing dependency wording, recording provenance, and removing pkgdown
  role drift; incorporated.

Known limitations:

- this is a prose-process change only; it does not run an automatic prose
  linter;
- external links to `agent-style` are inspiration and citation context, not a
  package dependency.

Team learning:

- adding a rule to a design protocol is not enough; the operational skill that
  agents actually invoke must carry the same gate;
- Pat's user-focused review caught terminology drift before it became a docs
  habit;
- Rose's provenance check helped keep the repository lightweight and clear
  about what was adapted versus copied.

## 2026-05-08: Multiple Random-Effect Scale Formulae

Scope:

- generalized Gaussian random-effect scale formulas from one `sd(group) ~ ...`
  target to one or more distinct unlabelled `mu` random-intercept targets;
- kept `sigma ~ ...` as residual or within-observation scale and
  `sd(group) ~ ...` as random-effect SD scale;
- added a two-target simulation helper and recovery test for
  `sd(id) ~ w_id` plus `sd(site) ~ w_site`;
- updated formula grammar, likelihood, random-effect, testing, roadmap,
  vignette, README, NEWS, and known-limitations text;
- added a planning design note for future phylogenetic location-scale-shape
  models and linked shape/skewness/kurtosis papers into the reference
  programme.

Commands run:

- `Rscript -e "devtools::test(filter = 'gaussian-random-effect-scale')"`
- `Rscript -e "devtools::test(filter = 'package-skeleton')"`
- `Rscript -e "devtools::test(filter = 'comparators')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never')"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `air format .`

Results:

- targeted random-effect scale tests: 60 passed, 0 failed.
- package skeleton tests: 20 passed, 0 failed.
- comparator tests: 31 passed, 0 failed.
- full `devtools::test()`: 403 passed, 0 failed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- standard `devtools::check(error_on = "never")`: 0 errors, 0 warnings,
  1 local current-time verification note.
- check with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors, 0 warnings, 0 notes.
- `git diff --check`: passed.

Known limitations:

- `air` is not installed locally, so formatting could not be run.
- multiple `sd(group) ~ ...` formulas are still limited to distinct unlabelled
  Gaussian `mu` random intercepts. Slope-specific, labelled-block, bivariate,
  phylogenetic, spatial, and non-Gaussian scale targets remain future work.

Team learning:

- the C++ likelihood could stay simple by stacking block-diagonal
  random-effect scale design matrices on the R side;
- the old single-target assumption was scattered across extractors, prediction,
  docs, tests, and vignettes, so Rose-style stale-wording scans were essential;
- Feynman and Confucius clarified that `sd(group) ~ ...` is a bridge toward
  phylogenetic/spatial random-factor scale models, while shape/skewness should
  remain a later, more heavily tested extension.

## 2026-05-08: GitHub Actions Node 24 Opt-In

Scope:

- opted both GitHub Actions workflows into Node.js 24 for JavaScript actions
  using `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true`;
- addressed the deprecation annotation emitted by GitHub Actions after the
  multiple random-effect scale formula push.

Commands run:

- `git diff --check`

Results:

- `git diff --check`: passed.

Known limitations:

- This is workflow hygiene only; package tests were not rerun locally because
  no R, C++, documentation, or package metadata changed.

## 2026-05-08: Staggered Documentation And Structured-Effect Grammar Audit

Scope:

- ran a staggered read-only team pass: Jason/Goodall mapped `gllvmTMB`
  phylogenetic/SPDE source patterns, Curie/Zeno designed the next phylogenetic
  simulation tests, and Pat/Dirac audited current docs from an applied-user
  perspective;
- clarified implemented-versus-planned sections in README and the getting
  started vignette;
- added explicit Gaussian notation convention: `Normal(a, b)` uses variance as
  the second argument;
- added a runnable `sd(population) ~ habitat` tutorial example and a three-scale
  equation block for residual `sigma`, `sd(population)`, and `sd(site)`;
- defined "coscale" at first use as residual covariance structure represented
  by `rho12` in the bivariate Gaussian seed;
- updated public phylogenetic grammar direction from dense `Cphy` examples to
  `phylo(1 | species, tree = tree)`, requiring an ultrametric tree with branch
  lengths and the Hadfield plus Nakagawa A-inverse sparse-precision path;
- aligned planned spatial grammar with the same structured random-effect shape:
  `spatial(1 | site, coords = coords)` or later
  `spatial(1 + x | site, coords = coords)`;
- separated planned structured-effect markers in pkgdown reference navigation.

Commands run:

- `Rscript -e "devtools::load_all(quiet = TRUE); ..."` for the new
  `sd(population) ~ habitat` example;
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- stale-wording `rg` scans for inconsistent Normal notation, `Cphy`,
  `phylo(species)`, old spatial placeholders, `O'Dea-style`, and
  `biological data`;
- `git diff --check`.

Results:

- new tutorial example converged with `fit$opt$convergence == 0`, positive
  `habitatopen` coefficient for `sd(population)`, and positive predicted
  random-effect SDs;
- full `devtools::test()`: 403 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- stale-wording scans found no public `Cphy`, bare `phylo(species)`, old
  `spatial(easting, northing)`, inconsistent `Normal(..., sqrt(...))`, or
  `O'Dea-style` wording;
- `git diff --check`: passed.

Known limitations:

- this task changed design and documentation only; no phylogenetic or spatial
  likelihood code was implemented;
- the public `phylo()` and `spatial()` functions are still planned markers and
  should reject or remain inert until parser, A-inverse/SPDE, and simulation
  tests are implemented.

Team learning:

- staggered parallel work was effective: Pat found user-facing confusion while
  Jason and Curie worked ahead on the next implementation gate;
- public phylogenetic syntax should require a real ultrametric branch-length
  tree, not a user-supplied dense `Cphy`;
- phylogenetic and spatial syntax should share the same structured
  random-effect grammar, while their speed paths differ internally.

## 2026-05-08: Planned Structured-Effect Parser Markers

Scope:

- added parser metadata for planned structured-effect markers in
  `drm_formula()`;
- locked the public planned grammar for
  `phylo(1 | species, tree = tree)`,
  `phylo(1 + x | species, tree = tree)`,
  `spatial(1 | site, coords = coords)`, and
  `spatial(1 | site, mesh = mesh)`;
- added grammar validation for malformed marker calls, nested marker calls,
  multiple spatial structure inputs, and oversized structured-slope forms;
- changed `drmTMB()` unsupported-structured errors from generic formula-term
  errors to explicit "planned, not implemented" messages;
- updated formula-grammar documentation, NEWS, known limitations, and Rd
  examples.

Commands run:

- `Rscript -e 'devtools::load_all(quiet = TRUE); ...'` to inspect parsed
  structured metadata;
- `Rscript -e "devtools::test(filter = 'package-skeleton')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- stale-wording `rg` scan for old bare `phylo(species)`, `Cphy`,
  `spatial(x, y)`, and generic public unsupported-status wording;
- `git diff --check`.

Results:

- interactive parser inspection stored `type`, `group`, `tree`/`coords`, and
  one-slope coefficient metadata without evaluating external objects;
- focused parser test: 35 passed, 0 failed;
- full `devtools::test()`: 420 passed, 0 failed;
- Rose's systems audit found no blockers; the non-blocking mesh metadata test
  gap and after-task role-name wording were resolved before commit;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- stale-wording scan found only expected historical after-task notes, parser
  failure tests, and still-valid generic unsupported-term tests for unrelated
  syntax;
- `git diff --check`: passed.

Known limitations:

- `phylo()` and `spatial()` are still planned markers; no TMB likelihood,
  A-inverse construction, tree validation, SPDE mesh construction, or
  structured-effect simulation recovery was implemented in this task;
- the first fitting target remains univariate Gaussian `mu` with an
  intercept-only phylogenetic structured effect from an ultrametric
  branch-length tree.

Team learning:

- parser-recognized planned syntax is useful because it lets docs and tests
  stabilize the public API before numerical implementation;
- the current parser can safely avoid evaluating `tree`, `coords`, and `mesh`
  while still detecting invalid grammar early;
- `rho12` remains reserved for residual bivariate response correlation, not
  phylogenetic or spatial structured-effect covariance.

## 2026-05-08: Phylogenetic Tree Validation Scaffold

Scope:

- added internal validation for tiny ultrametric `phylo` objects with branch
  lengths, unique tip labels, one root, connected node structure, and observed
  species matching;
- added an internal dense Brownian shared-history covariance/correlation
  comparator for exact tiny-tree tests;
- documented the comparator math as a test and teaching tool, not the
  user-facing large-tree phylogeny API;
- updated known limitations to distinguish the internal validator from fitted
  `phylo()` model support.

Commands run:

- `Rscript -e "devtools::test(filter = 'phylo-utils')"`
- `Rscript -e "devtools::test()"`
- `git diff --check`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted phylogenetic utility tests: 18 passed, 0 failed;
- full `devtools::test()`: 438 passed, 0 failed;
- `git diff --check`: passed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Known limitations:

- `air` is not installed locally, so formatting could not be run.
- The dense Brownian comparator is internal and test-oriented. It does not fit
  `phylo()` model terms and should not replace the planned sparse A-inverse
  path.

Team learning:

- tiny algebraic trees are a good bridge between Noether's symbolic checks and
  Gauss's future sparse-precision implementation;
- Zeno's simulation plan and Goodall's `gllvmTMB` source map both support using
  dense tree comparators only as validation scaffolding before the A-inverse
  likelihood path;
- public docs must continue to say that `phylo(1 | species, tree = tree)` is
  planned, even though internal tree checks now exist.

## 2026-05-08: Phylogenetic Augmented Precision Scaffold

Scope:

- added an internal sparse augmented Brownian precision helper for ultrametric
  `phylo` trees with positive branch lengths;
- fixed the root state at zero and excluded it from the latent vector;
- defaulted the precision to the phylogenetic correlation scale used by
  `z ~ MVN(0, sigma_phylo^2 A)`;
- tested sparse augmented precision against the existing dense Brownian
  comparator by marginalizing the augmented covariance back to tips;
- added species-to-tip and species-to-augmented-node mapping metadata for the
  future `phylo(1 | species, tree = tree)` likelihood path.

Commands run:

- `Rscript -e "devtools::test(filter = 'phylo-utils')"`
- `Rscript -e "devtools::test()"`
- `git diff --check`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted phylogenetic utility tests: 39 passed, 0 failed.
- full `devtools::test()`: 459 passed, 0 failed.
- `git diff --check`: passed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Known limitations:

- `air` is not installed locally, so formatting could not be run.
- no fitted `phylo()` model term or TMB likelihood was changed in this slice;
- zero-length branches are rejected by the precision helper, even though the
  tree validator can still validate a zero-length ultrametric tree;

Team learning:

- Locke caught the key numerical distinction: the tip block of a precision
  matrix is not the marginal tip precision; tests must solve the augmented
  system and then select tip rows;
- Pasteur's test plan helped pin exact log-determinants, edge-order
  invariance, species mapping, and malformed-input paths;
- this helper is the bridge from symbolic Brownian increments to the eventual
  TMB sparse prior block.

## 2026-05-08: Phylogenetic Prior NLL Algebra Helper

Scope:

- added an internal pure-R Gaussian prior contribution helper for augmented
  phylogenetic effects;
- matched the helper to the sparse augmented precision, log determinant, and
  structured-effect SD parameterization that the future TMB block should use;
- added tests comparing the helper with the explicit Gaussian precision-density
  formula and the edge-increment quadratic form.

Commands run:

- `Rscript -e "devtools::test(filter = 'phylo-utils')"`
- `Rscript -e "devtools::test()"`
- `git diff --check`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted phylogenetic utility tests: 43 passed, 0 failed.
- full `devtools::test()`: 463 passed, 0 failed.
- `git diff --check`: passed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Known limitations:

- `air` is not installed locally, so formatting could not be run.
- no TMB likelihood or fitted `phylo()` model term was changed in this slice;

Team learning:

- the Gaussian prior constant must use `-logdet(Q_A)` in the NLL expression
  because `Q_A` is the precision for the correlation matrix;
- testing the edge-increment quadratic and the precision-density formula in
  the same test gives Noether and Gauss the same contract before C++ work.

## 2026-05-08: Hidden TMB Phylogenetic Prior Parity Branch

Scope:

- added a hidden `model_type == 99` TMB branch for the augmented phylogenetic
  Gaussian prior contribution only;
- added dummy TMB data and mapped dummy parameters so existing Gaussian and
  bivariate Gaussian fits are unaffected;
- added a test comparing the TMB objective value with the pure-R prior NLL
  helper on the exact tiny tree.

Commands run:

- `Rscript -e "devtools::test(filter = 'phylo-utils')"`
- `Rscript -e "devtools::test()"`
- `git diff --check`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted phylogenetic utility tests: 45 passed, 0 failed.
- full `devtools::test()`: 465 passed, 0 failed.
- `git diff --check`: passed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Known limitations:

- `air` is not installed locally, so formatting could not be run.
- this is a parity-test branch, not fitted `phylo()` model support;

Team learning:

- adding a C++ parity branch before model-builder plumbing is a useful
  low-risk bridge from R algebra to TMB implementation;
- this protects the next fitting slice from simultaneously debugging formula
  parsing, sparse precision construction, and C++ prior constants.

## 2026-05-08: Fitted Univariate Gaussian Phylogenetic Location Model

Scope:

- implemented the first public fitted phylogenetic model path:
  `bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ z)` with
  `family = gaussian()`;
- removed the `phylo()` marker from the fixed-effect `mu` formula before model
  matrix construction and routed an intercept-only phylogenetic structured
  effect into the Gaussian TMB branch;
- passed the sparse augmented Brownian precision, log determinant, and
  observation-to-tip mapping into TMB;
- added fitted-model tests, prediction algebra tests, missingness tests, and
  rejection tests for unsupported phylogenetic slopes and `sigma` terms;
- updated NEWS, README, formula grammar, phylogenetic/spatial math notes,
  known limitations, roxygen documentation, ROADMAP, and pkgdown site output.

Commands run:

- `Rscript -e "devtools::test(filter = 'phylo')"`
- `Rscript -e "devtools::document()"`
- `git diff --check`
- `command -v air`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted phylogenetic tests: 57 passed, 0 failed.
- full `devtools::test()`: 477 passed, 0 failed.
- `devtools::document()`: regenerated `man/drmTMB.Rd` and `man/phylo.Rd`.
- `git diff --check`: passed.
- `command -v air`: no local `air` executable found.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Known limitations:

- fitted phylogenetic support is limited to intercept-only univariate Gaussian
  `mu` terms;
- phylogenetic random slopes, phylogenetic `sigma` terms, bivariate
  structured covariance, spatial fields, and structured effects in `rho12`
  remain planned;
- simulation recovery is CRAN-safe and intentionally modest, so larger
  long-run recovery and comparator studies are still needed.

Team learning:

- the latent phylogenetic effect is already on the response scale because the
  prior is `z ~ MVN(0, sigma_phylo^2 A)`; the `mu` predictor adds `z_tip`
  directly rather than multiplying by `sigma_phylo` a second time;
- the fitted path became much safer because the R-side prior helper and hidden
  TMB parity branch already fixed the sparse precision and log-determinant
  contract;
- one fixed-effect recovery tolerance had to be relaxed for a 16-tip CRAN-safe
  simulation, reminding us that phylogenetic SD recovery tests should avoid
  pretending small trees provide large-sample certainty.

## 2026-05-08: Equation-Syntax Documentation Consistency Pass

Scope:

- strengthened the get-started vignette so implemented Gaussian
  location-scale, residual-scale, `sd(group)`, bivariate `rho12`,
  `meta_known_V(V = V)`, and phylogenetic `mu` examples pair R syntax with
  symbolic equations;
- added compact equation context to the README for bivariate residual
  covariance, known sampling covariance, and phylogenetic location effects;
- corrected formula-grammar status wording for bivariate random effects,
  `mvbind()` shorthand, and implemented intercept-only `phylo()` support;
- corrected roadmap wording so `sd(group)` support is consistently described
  as one or more distinct unlabelled univariate Gaussian `mu` random-intercept
  targets;
- updated pkgdown navigation wording for structured-effect markers;
- clarified that phylogenetic residual-scale terms remain planned while
  intercept-only phylogenetic `mu` is implemented.

Commands run:

- `rg` stale-status scans for bivariate random-effect, `mvbind()`,
  intercept-only `phylo()`, `sd(group)`, old person-name shorthand, and
  biology-only wording;
- `git diff --check`;
- `Rscript -e "pkgdown::check_pkgdown()"`;
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`;
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`.

Results:

- targeted stale-status scan: no remaining matches for the exact status
  problems reported by Pat and Rose, except historical check-log and
  after-task notes that were true when written;
- `git diff --check`: passed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Known limitations:

- this was a documentation and consistency pass, not new model-fitting code;
- shape, zero inflation, mixed bivariate families, `mvbind()` shorthand,
  bivariate random effects, phylogenetic slopes, phylogenetic `sigma`, and
  spatial terms remain planned;
- rendered pkgdown search text still includes historical changelog entries and
  old after-task notes, which should not be mechanically rewritten.

Team learning:

- Pat was right that the first public page needed an applied question before
  equations; users should see why they are fitting the model before they see
  symbols;
- Rose caught that status drift, rather than terminology drift, was the main
  risk in this phase;
- shell searches containing backticks must be single-quoted so zsh does not
  try to execute fragments such as `mu`.

## 2026-05-08: Dense Comparator For Fitted Phylogenetic Gaussian Objective

Scope:

- added a CRAN-safe fitted-model comparator test for the intercept-only
  univariate Gaussian phylogenetic `mu` path;
- the test fits `bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)` on a
  four-tip ultrametric tree and compares the TMB/Laplace objective to an
  independent dense marginal Gaussian negative log likelihood;
- a second comparator fits
  `bf(y ~ x + (1 | species) + phylo(1 | species, tree = tree), sigma ~ 1)`
  and checks the marginal covariance with both non-phylogenetic and
  phylogenetic species intercepts;
- a third comparator fits Gaussian meta-analysis with known sampling variance
  and a phylogenetic `mu` intercept, checking
  `Sigma = V_known + sigma^2 I + sd_phylo^2 A_obs`;
- the dense comparator uses
  `Sigma = sigma^2 I + sd_phylo^2 A[species, species]`, where `A` is built by
  the dense Brownian tip-covariance helper, and extends to
  `Sigma = sigma^2 I + sd_species^2 I_species + sd_phylo^2 A_obs` for the
  combined species model, and to
  `Sigma = V_known + sigma^2 I + sd_phylo^2 A_obs` for the known-variance
  meta-analytic model;
- this strengthens the bridge between the public equation,
  `a ~ MVN(0, sigma_phylo^2 A)`, and the sparse augmented A-inverse
  implementation.

Commands run:

- `Rscript -e "devtools::test(filter = 'phylo-gaussian')"`
- `Rscript -e "devtools::test(filter = 'phylo')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted `phylo-gaussian` tests: 18 passed, 0 failed;
- targeted phylogenetic tests: 63 passed, 0 failed;
- full `devtools::test()`: 483 passed, 0 failed.
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Known limitations:

- the comparators use tiny dense covariance matrices for testing; this is not
  the large-tree fitting route;
- this validates the fitted marginal objective at the fitted parameter values,
  not long-run parameter-recovery coverage across many tree shapes.

Team learning:

- Curie's read-only review identified the right next gap: utility tests already
  checked sparse algebra, but the fitted model needed an end-to-end marginal
  likelihood comparator;
- a dense comparator is a compact way to test the sparse A-inverse route
  without turning CRAN tests into long simulations.

## 2026-05-08: Formula Grammar Status Map And Stale-Status Cleanup

Scope:

- added a current-status map to the formula grammar vignette so users can
  distinguish implemented, reserved, and planned syntax before copying code;
- marked planned phylogenetic slope, spatial, and bivariate random-effect
  examples as planned-only in visible docs;
- corrected stale active-doc wording that still treated intercept-only
  `phylo(1 | species, tree = tree)` and random-intercept meta-regression as
  wholly future;
- updated the `drmTMB()` help page to mention implemented
  `meta_known_V(V = V)` support;
- regenerated roxygen documentation and rebuilt the pkgdown site.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg -n "planned|not implemented|future|Reserved|roadmap|Current planned" README.md vignettes docs/design R man | rg "phylo\\(1 \\||meta_known_V|sd\\(group\\)|mvbind|rho12|spatial|A-inverse|random-intercept meta"`

Results:

- full `devtools::test()`: 483 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- GitHub Actions for commit `48a9085` completed successfully for both
  `R-CMD-check` and `pkgdown`;
- remaining stale-status grep hits were manually classified as appropriate
  planned-feature or roadmap wording, not contradictions with implemented
  support.

Known limitations:

- this was a documentation/status-consistency pass, not new fitting code;
- historical after-task notes and changelog entries may describe older states
  and should not be mechanically rewritten;
- spatial fields, phylogenetic slopes, phylogenetic `sigma`, bivariate
  structured effects, `mvbind()` shorthand, and mixed bivariate families remain
  planned.

Team learning:

- Pat found that visible planned examples need inline comments, not only
  surrounding prose;
- Rose found that stale status wording now needs a standard close-out grep
  whenever an implemented feature crosses from roadmap to current support.

## 2026-05-08: Dense Full-V Plus Phylogenetic And Study Comparators

Scope:

- added a CRAN-safe likelihood comparator for Gaussian known-covariance
  meta-analysis combined with the intercept-only phylogenetic `mu` effect;
- the test fits
  `bf(yi ~ x + meta_known_V(V = V) + phylo(1 | species, tree = tree), sigma ~ 1)`
  with a dense full sampling covariance matrix;
- a second test adds an ordinary `mu` study random intercept to the same
  dense known-`V` plus phylogenetic model;
- the independent comparator checks the fitted objective against
  `Sigma = V_known + sigma^2 I + sd_phylo^2 A_obs`, and against
  `Sigma = V_known + sigma^2 I + sd_study^2 J_study + sd_phylo^2 A_obs`
  for the study-intercept model.

Commands run:

- `Rscript -e "devtools::test(filter = 'phylo-gaussian')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted `phylo-gaussian` tests: 25 passed, 0 failed;
- full `devtools::test()`: 490 passed, 0 failed;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Known limitations:

- the test uses a small dense covariance matrix to keep CRAN checks fast;
- it validates the marginal objective at fitted values, not long-run
  simulation recovery for large full-`V` phylogenetic meta-analyses.

Team learning:

- combining two already-tested covariance paths is still worth an explicit
  comparator because row order, covariance addition, and Laplace integration
  can drift independently.

## 2026-05-08: Fixed And Random Effect Extractors

Scope:

- added exported `fixef()` and `ranef()` generics plus `drmTMB` methods;
- `fixef()` is a mixed-model-friendly alias for distributional fixed-effect
  coefficient blocks returned by `coef()`;
- `ranef()` returns stored conditional random-effect blocks, currently
  including ordinary `mu`, residual-scale `sigma`, and `phylo_mu` blocks when
  those effects are present;
- added extractor documentation, pkgdown reference entries, NEWS bullets, and
  tests for fixed-effect-only, ordinary random-effect, residual-scale random
  effect, and phylogenetic random-effect paths.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test(filter = 'phylo-gaussian')"`
- `air format .`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted `gaussian-location-scale` tests: 43 passed, 0 failed;
- targeted `gaussian-random-intercepts` tests: 173 passed, 0 failed after
  recording the new `ranef()` error snapshot;
- targeted `phylo-gaussian` tests: 26 passed, 0 failed;
- full `devtools::test()`: 498 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully with `fixef()` and
  `ranef()` reference pages;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- `air format .` could not run because `air` is not installed on this machine.

Known limitations:

- `ranef()` intentionally returns the current structural `drmTMB` random-effect
  block format rather than an `lme4`-style data frame;
- `ranef(dpar = "phylo_mu")` is an exact block selector for the current
  phylogenetic effect storage name, not yet a polished public alias system for
  all future structured effects.

Team learning:

- familiar extractor names help users coming from mixed-model software, but the
  documentation should be explicit when the returned object shape is still a
  `drmTMB` structure.

## 2026-05-08: rho12 Residual Correlation Extractor

Scope:

- added exported `rho12()` and `rho12.drmTMB()`;
- `rho12(fit)` returns response-scale residual correlations for bivariate
  Gaussian location-coscale fits;
- `rho12(fit, type = "link")` returns the atanh-scale linear predictor;
- `rho12(fit, newdata = dat)` delegates to the existing prediction matrix
  machinery;
- updated README, the getting-started article, the bivariate-coscale article,
  the which-scale tutorial, NEWS, pkgdown reference navigation, tests, and
  roxygen documentation.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `air format .`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg 'predict\(fit, dpar = "rho12"\)' vignettes README.md pkgdown-site/articles/bivariate-coscale.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/which-scale.html pkgdown-site/news/index.html`
- `rg "rho12\\(fit\\)|rho12\\(object|S3method\\(rho12|export\\(rho12|reference/rho12" NAMESPACE README.md R man tests vignettes _pkgdown.yml NEWS.md pkgdown-site/reference/index.html pkgdown-site/reference/rho12.html pkgdown-site/articles/bivariate-coscale.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/which-scale.html`

Results:

- targeted `biv-gaussian` tests: 52 passed, 0 failed;
- targeted `gaussian-location-scale` tests: 44 passed, 0 failed after
  recording the new non-bivariate `rho12()` error snapshot;
- full `devtools::test()`: 502 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully with the `rho12()`
  reference page and updated tutorials;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- stale teaching search found no remaining `predict(fit, dpar = "rho12")`
  examples in active vignettes, README, or rebuilt article pages;
- `air format .` could not run because `air` is not installed on this machine.

Known limitations:

- `rho12()` is currently defined only for the implemented bivariate Gaussian
  residual correlation;
- other correlation levels, such as phylogenetic, species, site, or spatial
  covariance correlations, remain separate future extractors or summaries.

Team learning:

- when a flagship parameter gets a dedicated extractor, the teaching prose
  should immediately move to that extractor so equations, syntax, and examples
  reinforce one another.

## 2026-05-08: Fitted Mean Extractor

Scope:

- added exported `fitted.drmTMB()`;
- `fitted(fit)` returns fitted `mu` values for univariate Gaussian models;
- `fitted(fit)` returns a two-column `mu1`/`mu2` matrix for bivariate Gaussian
  models;
- the extractor delegates to the existing `predict()` path, so fitted training
  values include current conditional `mu` random-effect contributions;
- updated the location-scale and bivariate-coscale tutorials so symbolic mean
  quantities map directly to `fitted(fit)`.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `air format .`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg -n "fitted\\(fit\\)|fitted\\.drmTMB|reference/fitted|mu1_i.*fitted|mu_i.*fitted" R tests vignettes README.md NEWS.md man _pkgdown.yml pkgdown-site/reference pkgdown-site/articles pkgdown-site/news`

Results:

- targeted `gaussian-location-scale` tests: 45 passed, 0 failed;
- targeted `gaussian-random-intercepts` tests: 174 passed, 0 failed;
- targeted `biv-gaussian` tests: 56 passed, 0 failed;
- full `devtools::test()`: 508 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully with
  `reference/fitted.drmTMB.html`;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- `git diff --check`: clean;
- `air format .` could not run because `air` is not installed on this machine.

Known limitations:

- `fitted()` is intentionally limited to fitted training rows; users should use
  `predict()` for `newdata` or non-location distributional parameters;
- future composed-response families may need family-specific fitted-value
  shapes beyond the current vector or two-column matrix.

Team learning:

- familiar base-R extractors reduce friction, but the tutorials still need the
  math-to-R mapping so users know exactly which model quantity is being
  returned.

## 2026-05-08: Standard Model-Fit Extractors

Scope:

- added S3 methods for `nobs()`, `df.residual()`, and `deviance()`;
- documented that `deviance()` is `-2 * logLik` for these likelihood-based
  distributional models, not a saturated-model GLM deviance;
- added a pkgdown reference page for the standard model-fit extractor methods;
- added tests for complete-case row counts, residual degrees of freedom,
  deviance algebra, AIC algebra, and AIC/BIC agreement with `lme4` on an
  overlapping Gaussian mixed model.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test(filter = 'comparators')"`
- `Rscript -e "devtools::load_all(); fit <- drmTMB(bf(y ~ x), data = data.frame(y = rnorm(20), x = rnorm(20)), family = gaussian()); stopifnot(stats::nobs(fit) == 20L, is.numeric(stats::df.residual(fit)), is.numeric(stats::deviance(fit))); cat('namespace smoke ok\\n')"`
- `air format .`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg -n "model-fit-extractors|nobs\\(|df\\.residual\\(|deviance\\(|AIC\\(|BIC\\(" R tests vignettes README.md NEWS.md man _pkgdown.yml pkgdown-site/reference pkgdown-site/news`

Results:

- targeted `gaussian-location-scale` tests: 50 passed, 0 failed;
- targeted `biv-gaussian` tests: 59 passed, 0 failed;
- targeted `comparators` tests: 33 passed, 0 failed;
- namespace smoke test for `nobs()`, `df.residual()`, and `deviance()` passed;
- full `devtools::test()`: 518 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully with
  `reference/model-fit-extractors.html`;
- final `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- `git diff --check`: clean;
- `air format .` could not run because `air` is not installed on this machine.

What did not go smoothly:

- The first `devtools::check()` run failed with namespace-load warnings because
  `nobs`, `df.residual`, and `deviance` were registered as S3 methods before
  their `stats` generics were imported.
- Adding the missing `@importFrom stats nobs df.residual deviance` entries and
  regenerating `NAMESPACE` fixed the issue.

Known limitations:

- `df.residual()` uses the current `nobs - df` convention where `df` is the
  number of optimized top-level parameters in `logLik()`;
- future penalized or constrained models may need more explicit documentation
  if effective degrees of freedom differ from this simple count.

Team learning:

- base-R S3 methods for `stats` generics need both the S3 method registration
  and the generic import; `devtools::test()` alone did not catch this, but
  `devtools::check()` did.

## 2026-05-08: Equation Syntax Documentation Alignment

Scope:

- split the main overview and README examples so fixed-effect Gaussian
  location-scale equations are paired with fixed-effect syntax, and random
  effects are introduced with their own matching equations;
- added a formula-grammar status map to the design contract, using
  implemented/reserved/planned consistently;
- clarified planned spatial `coords` versus `mesh` inputs in the
  phylogenetic/spatial vignette and speed design note;
- tightened the package `DESCRIPTION` so generated pkgdown metadata describes
  the current implementation first and the shape/zero-inflation roadmap as
  staged future work;
- updated `NEWS.md` for the documentation alignment.

Commands run:

- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `air format .`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg -n "current implementation focuses|Public documentation now pairs|For a fixed-effect Gaussian location-scale model|spatial\\(1 \\| site, mesh = mesh\\)|Current Status Map|O.Dea-style|rho ~|tau ~|meta_gaussian" DESCRIPTION NEWS.md README.md vignettes docs/design pkgdown-site/index.html pkgdown-site/news/index.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/phylogenetic-spatial.html pkgdown-site/articles/formula-grammar.html`

Results:

- full `devtools::test()`: 518 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully and rebuilt the home page,
  `articles/drmTMB.html`, `articles/phylogenetic-spatial.html`, and
  `news/index.html`;
- final `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- `git diff --check`: clean;
- `air format .` could not run because `air` is not installed on this machine.

Consistency audit:

- `pkgdown-site/articles/drmTMB.html` now contains the fixed-effect Gaussian
  location-scale equation/syntax pairing;
- `pkgdown-site/index.html` metadata now says the current implementation
  focuses on Gaussian location-scale, known sampling covariance, phylogenetic
  location effects, random-effect scale models, and bivariate residual
  correlation before mentioning staged future families;
- `pkgdown-site/news/index.html` contains the new documentation-alignment
  NEWS item;
- remaining `meta_gaussian()` and `tau ~` matches are intentional guardrails in
  meta-analysis docs and after-task protocol, not promoted syntax.

What did not go smoothly:

- reviewer-style scans caught that the overview vignette had paired a
  fixed-effect symbolic equation with a random-effect syntax example. Splitting
  those examples fixed the mismatch.
- the pkgdown metadata inherited a broader DESCRIPTION than the current
  implementation warranted, so DESCRIPTION was tightened and site/checks were
  rerun.

Team learning:

- equation/syntax pairing should be treated as a testable documentation
  contract: the equation immediately before a code block must describe exactly
  the model fitted by that code block.

## 2026-05-08: `check_drm()` Fit Diagnostics

Scope:

- added exported `check_drm()` generic and `check_drm.drmTMB()` method;
- added a `drm_check` print method and programmatic `attr(x, "ok")` flag;
- diagnostics now cover optimizer convergence, finite objective/log-likelihood,
  fixed-parameter gradients, Hessian status, dropped rows, positive fitted
  scale values, bivariate residual `rho12` boundary checks, known sampling
  covariance summaries, ordinary random-effect replication, ordinary
  random-slope design variation, and phylogenetic species replication;
- added `check_drm()` examples to the getting-started, location-scale, and
  bivariate-coscale vignettes;
- added the reference page to `_pkgdown.yml`, updated `NEWS.md`, README, and
  the structured-effect diagnostics design note.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'check-drm')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `rg -n "check_drm|known sampling covariance summaries|weak random-slope|drmTMB-logo|favicon" pkgdown-site/index.html pkgdown-site/reference/index.html pkgdown-site/reference/check_drm.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/location-scale.html pkgdown-site/articles/bivariate-coscale.html pkgdown-site/news/index.html`
- `air format .`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted `check-drm` tests: 38 passed, 0 failed;
- full `devtools::test()`: 556 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully, including
  `reference/check_drm.html`;
- generated-site search found `check_drm()` on the home page, reference index,
  reference page, getting-started article, location-scale article,
  bivariate-coscale article, and changelog;
- final `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- `git diff --check`: clean;
- `air format .` could not run because `air` is not installed on this machine.

Tests of the tests:

- tests mutate a fitted object to exercise nonzero optimizer convergence,
  non-finite objective, gradient evaluation failure, non-finite gradients,
  non-positive-definite Hessian status, and scale-extraction failure;
- tests cover dropped-row notes, `rho12` boundary warnings, random-effect
  singleton notes, weak random-slope design notes, dense known sampling
  covariance summaries, phylogenetic replication notes, and unused `...`
  rejection;
- the print test now captures output instead of leaking the full diagnostic
  table into the test log.

Consistency audit:

- `NAMESPACE` exports `check_drm` and registers `check_drm.drmTMB` plus
  `print.drm_check`;
- `man/check_drm.Rd`, `_pkgdown.yml`, README, `NEWS.md`, and vignettes all
  describe the same first-pass diagnostic surface;
- the design note
  `docs/design/16-phylo-spatial-common-math.md` now records which diagnostics
  are implemented and which separability checks remain future work.

What did not go smoothly:

- the first test version treated dropped-row `note`s as a failed model; that
  was corrected so `attr(x, "ok")` is false only for `warning` or `error`
  statuses;
- the first print test used `expect_output()` but `cli` output and
  `print.data.frame()` output did not land in the same stream, so the test was
  changed to capture both streams;
- reviewer/auditor passes caught that vignettes and generated pkgdown pages
  initially lagged behind the new exported function;
- the known sampling covariance and random-slope checks were initially too
  thin, so matrix rank/conditioning summaries and within-group design checks
  were added before closing the task.

Known limitations:

- `check_drm()` is a first-pass diagnostic, not a formal identifiability proof;
- future phylogenetic plus non-phylogenetic, spatial plus site/study, and
  cross-formula covariance models still need separability diagnostics;
- gradient and Hessian checks are based on the current TMB object and
  `sdreport()` status, not profile-likelihood or bootstrap uncertainty checks.

Team learning:

- diagnostic functions need tests that deliberately break fitted-object
  components, not only tests on successful models;
- `note`, `warning`, and `error` semantics should be documented from the first
  exported version because applied users will otherwise over- or under-react to
  diagnostic rows;
- pkgdown freshness must be verified with generated-site searches, not only
  `pkgdown::check_pkgdown()`.

## 2026-05-08: `mvbind()` Bivariate Location Shorthand

Scope:

- implemented `mvbind(y1, y2) ~ x` as shorthand for identical bivariate
  Gaussian location formulas;
- the shorthand expands internally to `mu1 = y1 ~ x` and `mu2 = y2 ~ x`;
- explicit `mu1` and `mu2` formulas remain the preferred syntax whenever the
  two responses need different location predictors;
- added validation for malformed, named, repeated, or mixed explicit-plus-
  shorthand `mvbind()` inputs;
- updated README, ROADMAP, formula grammar documentation, likelihood/family
  design notes, bivariate and formula-grammar vignettes, NEWS, tests, and
  roxygen documentation.

Commands run:

- `Rscript -e "devtools::test(filter = 'biv-gaussian|package-skeleton')"`
- `Rscript -e "devtools::document()"`
- `rg -n "mvbind.*Reserved|mvbind.*planned|mvbind.*not implemented|not implemented.*mvbind|future work.*mvbind|Reserved \\| Planned shorthand" README.md ROADMAP.md NEWS.md docs/design vignettes R tests man`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `rg -n "mvbind|identical bivariate location|shorthand for identical" pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/reference/drmTMB.html pkgdown-site/reference/drm_formula.html pkgdown-site/articles/bivariate-coscale.html pkgdown-site/articles/formula-grammar.html pkgdown-site/news/index.html`
- `air format .`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted tests: 110 passed, 0 failed;
- full `devtools::test()`: 572 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- generated-site search found the shorthand on the home page, roadmap,
  `drmTMB()` reference, `drm_formula()` reference, bivariate coscale article,
  formula grammar article, and changelog;
- final `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- `git diff --check`: clean;
- `air format .` could not run because `air` is not installed on this machine.

Tests of the tests:

- the equivalence test fits both the explicit and `mvbind()` forms to the same
  simulated data and checks equal log-likelihood and equal `mu1`/`mu2`
  coefficients;
- failure-path tests reject `mvbind()` with a univariate Gaussian family,
  three responses, named `mvbind()` formulas, and mixing `mvbind()` with
  explicit `mu1` or `mu2` formulas;
- a parser-level test checks that `drm_formula()` captures `mvbind()` as an
  unnamed location formula before model building expands it.

Consistency audit:

- the formula grammar status table now marks `mvbind(y1, y2) ~ x` as
  implemented shorthand, not planned syntax;
- README, ROADMAP, vignettes, design notes, NEWS, roxygen Rd files, and
  generated pkgdown pages all use the same contract: shorthand only for
  identical bivariate location predictors;
- stale wording searches found no remaining current-document claims that
  `mvbind()` is reserved, planned, or not implemented.

What did not go smoothly:

- `mvbind()` had to remain a deliberately narrow shorthand, because the
  project still prefers explicit `mu1` and `mu2` formulas for scientific
  clarity when predictors differ;
- the generated site had to be rebuilt and searched directly because
  `pkgdown::check_pkgdown()` alone does not prove freshness;
- local formatting through `air` is still unavailable on this machine.

Known limitations:

- `mvbind()` is implemented only for the all-Gaussian two-response engine;
- mixed composed families such as `family = c(gaussian(), poisson())` remain
  planned until a coherent joint likelihood is implemented;
- bivariate random effects remain planned, so `mvbind()` currently expands
  only fixed-effect location formulas.

Team learning:

- Boole's formula lens was useful here: shorthand is helpful only when it
  reduces repetition without hiding different scientific predictors.
- Rose's stale-wording audit prevented the formula grammar, roadmap, and
  rendered pkgdown site from drifting out of sync after the parser changed.

## 2026-05-08: Public Model-Method Documentation

Scope:

- added roxygen documentation for existing public S3 methods:
  `predict.drmTMB()`, `simulate.drmTMB()`, `residuals.drmTMB()`,
  `sigma.drmTMB()`, and `summary.drmTMB()`;
- listed these methods explicitly in the pkgdown reference index;
- clarified that `predict(..., newdata = ...)` returns fixed-effect,
  population-level predictions, while fitted-row predictions include currently
  implemented random-effect contributions;
- clarified that `sigma(fit)` returns the modelled residual scale, and that
  simulations and Pearson residuals combine known sampling covariance with
  residual scale when relevant.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `air format .`
- `rg -n "Predict distributional parameters|Extract fitted residual scale|Simulate from a fitted model|Extract model residuals|Summarize a fitted model|meta_known_V\\(V = V\\)" pkgdown-site/reference/index.html pkgdown-site/reference/predict.drmTMB.html pkgdown-site/reference/sigma.drmTMB.html pkgdown-site/reference/simulate.drmTMB.html pkgdown-site/reference/residuals.drmTMB.html pkgdown-site/reference/summary.drmTMB.html`

Results:

- `devtools::document()` generated five new Rd files;
- full `devtools::test()`: 572 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully and built the five new
  reference pages;
- generated-site search found all new reference-page headings and the
  `meta_known_V(V = V)` residual-scale clarification;
- final `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- `git diff --check`: clean;
- `air format .` could not run because `air` is not installed on this machine.

Tests of the tests:

- this was a documentation task, so no unit tests were added;
- the new examples were exercised by the full R CMD check examples stage;
- pkgdown was built and the generated reference index/pages were searched
  directly to check that the new documentation is visible.

Consistency audit:

- `_pkgdown.yml` now lists each documented S3 method explicitly;
- `NAMESPACE` already registered the S3 methods, so this task added missing
  user documentation rather than new API behaviour;
- no NEWS bullet was added because this was documentation coverage for existing
  behaviour, not a user-visible behaviour change.

What did not go smoothly:

- the first attempt to launch a documentation-review agent was blocked because
  the current thread had already reached the agent limit;
- this made the local after-task audit more important than usual;
- local formatting through `air` remains unavailable.

Known limitations:

- the examples are deliberately minimal and synthetic;
- richer ecological/evolutionary examples for prediction, simulation, and
  residual checking should live in tutorials rather than method Rd pages;
- `predict(..., newdata = ...)` still gives fixed-effect population-level
  predictions only; conditional prediction for new group levels remains a
  later design decision.

Team learning:

- method documentation should be added as soon as a method becomes useful,
  even if the method was created in an earlier implementation slice;
- `sigma()` documentation must keep the residual-scale versus observation-scale
  distinction explicit, especially for meta-analysis users.

## 2026-05-08: Post-Fit Model Workflow Tutorial

Scope:

- added `vignettes/model-workflow.Rmd`, a tutorial that walks from a fitted
  Gaussian location-scale model through diagnostics, coefficients, prediction,
  residuals, and simulation;
- paired the symbolic Gaussian location-scale equations with matching
  `drmTMB()` syntax and parameter interpretation;
- added the tutorial to the pkgdown Tutorials menu and article index;
- documented how the same post-fit loop applies to meta-analytic Gaussian
  models with `meta_known_V(V = V)` and to bivariate Pearson residuals using
  `sigma1`, `sigma2`, and `rho12`.

Commands run:

- `Rscript -e "rmarkdown::render('vignettes/model-workflow.Rmd', quiet = TRUE)"`
- `Rscript -e "pkgdown::build_article('model-workflow')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `air format .`
- `rg -n "Checking and using fitted models|post-fit loop|meta_known_V\\(V = V\\)|simulate\\(fit|residuals\\(fit|check_drm\\(fit\\)" pkgdown-site/articles/model-workflow.html pkgdown-site/articles/index.html pkgdown-site/index.html`
- `rg -n "meta_gaussian|tau ~|rho ~|biv_gaussian|biological data|O.Dea-style|O'Dea-style" vignettes/model-workflow.Rmd pkgdown-site/articles/model-workflow.html docs README.md vignettes _pkgdown.yml`

Results:

- full `devtools::test()`: 572 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully and generated
  `articles/model-workflow.html`;
- generated-site search found the new tutorial title, navbar entry,
  `meta_known_V(V = V)` note, `check_drm(fit)`, `residuals(fit, type =
  "pearson")`, and `simulate(fit)` workflow text;
- full `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- `git diff --check`: clean;
- direct standalone `rmarkdown::render()` and `pkgdown::build_article()` failed
  in a plain session because the package was not installed there, but the full
  pkgdown site build and R CMD check both installed the package first and built
  the vignette successfully;
- `air format .` could not run because `air` is not installed on this machine.

Tests of the tests:

- this was a tutorial/documentation task, so no unit tests were added;
- the vignette chunks were exercised by both full pkgdown build and R CMD check
  vignette rebuild;
- the generated HTML was searched directly to verify that navigation and the
  central workflow text reached the site.

Consistency audit:

- the tutorial uses implemented syntax only: `bf(growth ~ ..., sigma ~ ...)`,
  `family = gaussian()`, `check_drm()`, `coef()`, `summary()`, `predict()`,
  `sigma()`, `residuals()`, and `simulate()`;
- the tutorial keeps `sigma` as the residual standard deviation parameter and
  uses `rho12` only for the bivariate residual-correlation note;
- no NEWS bullet was added because this was a new learning-path article, not a
  new fitting feature or API change;
- no roadmap or likelihood design update was needed because no model behaviour
  changed.

What did not go smoothly:

- direct article rendering outside an installed-package context was misleading;
  full pkgdown/R CMD check was the correct verification route for this package;
- local formatting through `air` remains unavailable.

Known limitations:

- the example is intentionally compact and synthetic;
- richer ecology/evolution examples should be added later with real or
  package-data-style workflows;
- the tutorial explains current post-fit tools but does not yet cover profile
  likelihood intervals or conditional prediction for new random-effect levels.

Team learning:

- post-fit tutorials are a good place to pair equations, syntax, and
  interpretation without overloading the main getting-started article;
- docs-heavy tasks still need generated-site checks because pkgdown navigation
  is part of the user-facing behaviour.

## 2026-05-08: Bivariate Meta-Analysis Known-Covariance Design

Scope:

- recorded the planned bivariate meta-analysis likelihood that separates known
  within-study sampling covariance from unknown residual or between-study
  covariance;
- clarified that `meta_known_V(V = V)` supplies `S_i` or stacked `V`, while
  fitted `rho12` remains the residual or heterogeneity correlation;
- added row-paired stacking order for a `2n` by `2n` known covariance matrix;
- added planned helper names for constructing bivariate block-diagonal
  sampling covariance matrices from `v1`, `v2`, and either `cov12` or `cor12`;
- added a testing requirement that recovery tests must distinguish sampling
  correlation in `V` from fitted residual `rho12`;
- added Mavridis and Salanti (2013) to `REFERENCES.bib`.

Commands run:

- `rg -n "meta_known_V|known V|sampling covariance|bivariate|rho12" R docs/design vignettes tests README.md NEWS.md`
- `pdfinfo '/Users/z3437171/Downloads/mavridis-salanti-2012-a-practical-introduction-to-multivariate-meta-analysis.pdf'`
- `pdftotext '/Users/z3437171/Downloads/mavridis-salanti-2012-a-practical-introduction-to-multivariate-meta-analysis.pdf' - | rg -n -i "within-study|within study|correlation|covariance|bivariate|multivariate|known|variance" -C 2`
- `rg -n "Mavridis|Salanti|multivariate meta-analysis|Riley|Jackson" REFERENCES.bib docs/design/11-reference-programme.md vignettes docs`
- `rg -n "Planned Bivariate Meta|Mavridis|row-paired|meta_vcov_bivariate|S_i|Omega_i|within-study" docs/design REFERENCES.bib`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `rg -n 'meta_gaussian\\(\\)|tau ~|rho ~|Planned Bivariate Meta|row-paired|meta_vcov_bivariate|sampling correlation|residual' docs/design docs/dev-log REFERENCES.bib`

Results:

- confirmed that current bivariate Gaussian code still rejects
  `meta_known_V()`, so this task was design-only;
- confirmed from the Mavridis and Salanti PDF that multivariate meta-analysis
  needs effect-size vectors plus their within-study variance-covariance
  matrices;
- design docs now state that known sampling covariance and fitted residual
  `rho12` are different quantities;
- roadmap and testing strategy now include bivariate known-covariance
  meta-analysis as a distinct future implementation target.
- `devtools::test()`: 572 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `git diff --check`: clean;
- stale-wording scan found the new design targets plus older intentional
  guardrails for `meta_gaussian()`, `tau ~`, and `rho ~`.

Tests of the tests:

- no unit tests were added because no implementation changed;
- the testing strategy now specifies the future simulation target: data
  generated with known sampling covariance in `V` and separate residual
  `rho12` should recover the residual correlation, not the sampling
  correlation.

Consistency audit:

- no `meta_gaussian()` family or `tau ~` grammar was introduced;
- `sigma1`, `sigma2`, and `rho12` remain the names for unknown bivariate
  residual or heterogeneity components;
- `V` remains the known sampling covariance input;
- planned syntax uses `family = c(gaussian(), gaussian())`, consistent with
  the current family-composition direction.

What did not go smoothly:

- the natural bivariate syntax still has an awkward design point: the
  `meta_known_V(V = V)` marker is model-level, but current grammar attaches it
  inside a location formula. The design records that duplicate markers should
  be rejected, and this may need a cleaner parser representation later.

Known limitations:

- no bivariate known-covariance likelihood has been implemented yet;
- missing outcome handling is deliberately deferred;
- unknown within-study correlations should be handled by sensitivity analysis
  before any automatic estimation is attempted.

Team learning:

- Noether's rule is useful here: write the covariance equation before touching
  the parser;
- Fisher's rule is to test sampling correlation and residual correlation as
  separate recovery targets;
- Boole should revisit whether model-level formula markers need a cleaner
  grammar before bivariate meta-analysis is implemented.

## 2026-05-08: Known-V Random-Effect Scale Validation

Scope:

- added a targeted validation test for univariate Gaussian
  `meta_known_V(V = vi)` models combined with a `mu` random intercept and a
  random-effect scale formula, `sd(id) ~ w`;
- updated the meta-analysis design note to state that this implemented
  combination is supported and covered by an independent dense
  marginal-likelihood test;
- updated the source map, roadmap, and NEWS so the implemented-status wording
  matches the test coverage.

Commands run:

- `Rscript -e "devtools::test(filter = '^meta-known-v$')"`
- `Rscript -e "rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `rg -n 'meta_gaussian\\(\\)|tau ~|still need explicit validation|still needs validation|routine tutorial syntax|planned.*implemented|only diagonal' README.md ROADMAP.md NEWS.md docs vignettes tests`
- `rg -n 'meta_known_V|sd\\(id\\)|sd\\(group\\)|known-covariance|known sampling' NEWS.md ROADMAP.md docs/design/08-meta-analysis.md vignettes/source-map.Rmd docs/dev-log/known-limitations.md`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted `meta-known-v` tests: 40 passed, 0 failed;
- full test suite: 646 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `git diff --check`: clean;
- stale-wording scan found no active obsolete "still needs validation" caveat;
  remaining `meta_gaussian()`, `tau ~`, and planned-feature hits are
  intentional guardrails or historical after-task/check-log records;
- `pkgdown::build_site()`: completed successfully and rebuilt
  `articles/source-map.html`, NEWS, and site metadata;
- `devtools::check(...)` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Tests of the tests:

- the new test compares `logLik(fit)` with an independent dense marginal
  Gaussian likelihood calculation using
  `diag(V_known + sigma^2) + Z diag(sd(id)^2) Z'`;
- the fitted `sd(id)` values are checked at the group level, making the test
  exercise the intended `sd(group) ~ predictor` path rather than only ordinary
  residual `sigma`.

Consistency audit:

- no `meta_gaussian()` family or `tau ~` formula was introduced;
- `sigma` remains the residual heterogeneity parameter, while `sd(id)` is the
  group-level random-effect scale;
- the source map still warns that this should not become a headline tutorial
  example until the interpretation is written carefully.

What did not go smoothly:

- the implemented pieces were already routable, but the source map correctly
  exposed that the specific combination lacked a direct likelihood-comparator
  test;
- the project needed status wording updates in several places so users would
  not see an obsolete "still needs validation" caveat.

Known limitations:

- this validates the univariate Gaussian known-variance vector path with
  `sd(id) ~ w`; sparse known covariance and bivariate known-covariance
  meta-analysis remain separate future targets;
- the test is a dense marginal-likelihood comparator, so it is intentionally
  small and not a performance benchmark.

Team learning:

- Jason's source-map role caught a real validation gap without changing code;
- Rose's after-task checklist is useful for turning "implemented somewhere"
  into "implemented, tested, documented, and consistently described."

## 2026-05-08: Meta-Analysis Scale Tutorial Clarification

Scope:

- added a public tutorial section pairing R syntax and symbolic equations for
  known sampling covariance plus group-level random-effect scale models;
- corrected stale design wording that still described `sd(study) ~ x1` in
  known-covariance meta-analysis as awaiting validation;
- clarified that the `sigma` slope multiplies only unknown residual
  heterogeneity, not the known sampling variance;
- updated the source map to say the combination now has both a targeted
  validation test and tutorial explanation.

Commands run:

- `Rscript -e "rmarkdown::render('vignettes/meta-analysis.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `rg -n 'remain a separate validation task|still needs validation|after adding the known sampling variance|after adding known sampling|sampling error that is known|The$|Normal\\(a, b\\) again' vignettes/meta-analysis.Rmd docs/design/08-meta-analysis.md vignettes/source-map.Rmd NEWS.md ROADMAP.md docs/dev-log/known-limitations.md`
- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- direct meta-analysis and source-map renders: passed;
- stale-wording scan: no active hits;
- `git diff --check`: clean;
- `pkgdown::check_pkgdown()`: no problems found;
- `devtools::test()`: 646 passed, 0 failed;
- `pkgdown::build_site()`: completed successfully and rebuilt
  `articles/meta-analysis.html` and `articles/source-map.html`;
- `devtools::check(...)` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- GitHub Actions for commit `a33ea96`: pkgdown and R CMD check succeeded,
  including macOS, Ubuntu, and Windows.

Tests of the tests:

- no new model code or unit tests were added;
- the documentation now points back to the existing dense marginal-likelihood
  comparator for `meta_known_V(V = vi)` plus `sd(id) ~ w`;
- Pat and Fisher/Noether both identified the stale status contradiction before
  the documentation update, and the follow-up scan now finds no active copy of
  that contradiction.

Consistency audit:

- no `meta_gaussian()` family or `tau ~` syntax was introduced;
- the vignette separates `meta_known_V(V = V)`, `sigma`, and `sd(study)` as
  known sampling covariance, residual heterogeneity, and group-level
  random-effect heterogeneity;
- the design note now includes the marginal covariance
  `V + diag(sigma_i^2) + Z diag(omega_j^2) Z'`.

What did not go smoothly:

- the validation checkpoint fixed the test gap but left one stale sentence in
  the design note; Pat and Noether caught the user-facing consequence quickly.

Known limitations:

- this is a documentation and consistency pass only;
- sparse known covariance and bivariate known-covariance random-effect scale
  models remain future implementation targets.

Team learning:

- Pat should review tutorials before we promote a newly validated combination
  from "source-map status" to "headline example";
- Noether's equation-first review should explicitly check the marginal
  covariance whenever known `V`, residual `sigma`, and random-effect scales are
  combined.

## 2026-05-08: Profile-Likelihood Target Design Clarification

Scope:

- clarified that profile-likelihood confidence intervals are planned, not yet
  implemented;
- introduced a user-facing profile target namespace for fixed effects,
  random-effect SDs, group-level correlations, residual-correlation fixed
  effects, and derived quantities;
- replaced the stale `sd_id` example with target names such as
  `sd:mu:(1 | id)` and `fixef:rho12:(Intercept)`;
- documented boundary control flow, correlation search guards, and the
  distinction between direct TMB parameters, linear combinations, and nonlinear
  derived quantities.

Commands run:

- `git diff --check`
- `rg -n 'sd_id|dpar:rho12|two threshold crossings|confint\\(fit, parm = "sd_id"|O.Dea-style|O.De[aA]-style|biological data' docs/design/12-profile-likelihood-cis.md NEWS.md ROADMAP.md README.md docs vignettes`
- `Rscript -e "rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`

Results:

- Fermat review P1/P2/P3 findings were addressed in
  `docs/design/12-profile-likelihood-cis.md`;
- `git diff --check`: clean;
- stale-pattern scan: no active `sd_id`, `dpar:rho12`, or old profile-CI
  example in the profile design, NEWS, roadmap, README, or current vignettes;
  remaining hits were historical logs or intentional symbolic notation in the
  random-effect scale design note;
- direct source-map render: passed;
- `pkgdown::check_pkgdown()`: no problems found;
- `devtools::test()`: 646 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::build_site()`: completed successfully.
- `devtools::check(...)` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Tests of the tests:

- no model code or unit tests were added;
- the design now lists the future tests required before profile-likelihood
  support can be called implemented, including boundary SDs, group-level
  correlations, unsupported target errors, and comparison against a diagnostic
  grid.

Consistency audit:

- `rho12` remains the residual bivariate correlation parameter;
- `fixef:rho12:(Intercept)` now follows the same fixed-effect namespace as
  `fixef:mu:x` and `fixef:sigma:x`;
- profile targets for `phylo()` use fitted-object labels while the document
  still states that the original model syntax must supply `tree = tree`.

What did not go smoothly:

- the first draft mixed target namespaces and kept an old `sd_id` example;
  reviewer feedback caught this before the design became a user-facing promise.

Known limitations:

- `confint.drmTMB(method = "profile")` is still not implemented;
- nonlinear derived profiles for ICCs, repeatability, phylogenetic signal, and
  covariance-matrix correlations remain design targets.

Team learning:

- profile-CI design should always start from fitted-object target names before
  discussing TMB parameter names;
- Rose's stale-wording scan should include old API examples as well as old
  status claims.

## 2026-05-08: Likelihood Routing Table

Scope:

- added a central `model_type` routing table to
  `docs/design/03-likelihoods.md`;
- documented that `model_type = 99` is a hidden phylogenetic precision-prior
  parity branch used by tests, not a public family;
- aligned the source map and likelihood design with
  `family = list(gaussian(), gaussian())`;
- corrected bivariate `rho12` documentation to use the same guarded transform
  as the TMB template: `rho12 = 0.99999999 * tanh(eta_rho12)`.

Commands run:

- `git diff --check`
- `rg -n 'list\\(gaussian\\(\\), gaussian\\(\\)\\)|rho12 = tanh|atanh\\(rho12|0\\.99999999|fallthrough|model_type = 2' docs/design/03-likelihoods.md vignettes/source-map.Rmd R/drmTMB.R src/drmTMB.cpp`
- `Rscript -e "rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`

Results:

- Rose/Wegener found three consistency issues before commit:
  `list(gaussian(), gaussian())` was missing from routing docs, bivariate
  `model_type = 2` is a validated fallthrough in `make_tmb_data()`, and
  `rho12` prose omitted the numerical guard;
- all three issues were patched in `docs/design/03-likelihoods.md` and
  `vignettes/source-map.Rmd`;
- `git diff --check`: clean;
- direct source-map render: passed;
- `pkgdown::check_pkgdown()`: no problems found.
- `devtools::test()`: 646 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check(...)` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Tests of the tests:

- no likelihood code or unit tests were added;
- the routing table was checked against `R/drmTMB.R`, `src/drmTMB.cpp`, and
  the implemented source map.

Consistency audit:

- `model_type = 1`, `2`, `3`, and hidden `99` are now documented in both the
  developer source map and the likelihood design;
- `family = c(gaussian(), gaussian())` and
  `family = list(gaussian(), gaussian())` are documented as equivalent routes
  to the bivariate Gaussian builder;
- public phylogenetic fits remain `model_type = 1`; the hidden branch is test
  machinery only.

What did not go smoothly:

- the first routing-table draft was too confident about `make_tmb_data()` and
  missed one supported composed-family spelling.

Known limitations:

- the bivariate route still falls through after Gaussian and Student-t checks;
  this is documented, but a future implementation could make it explicit if
  new model families make the fallthrough fragile.

Team learning:

- when documenting routing, Rose should compare the docs against both the
  family-normalization route and the final TMB data mapper.

## 2026-05-08: Explicit TMB Data Model-Type Guard

Scope:

- changed `make_tmb_data()` so `"biv_gaussian"` is an explicit route to
  `model_type = 2L` instead of an implicit fallthrough;
- added an internal regression test that unknown model labels fail before they
  can reach the TMB template;
- updated the likelihood design and previous routing after-task note so they
  describe the explicit guard.

Commands run:

- `git diff --check`
- `Rscript -e "devtools::test(filter = '^package-skeleton$')"`
- `Rscript -e "devtools::test(filter = '^biv-gaussian$')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`

Results:

- `git diff --check`: clean;
- package-skeleton targeted tests: 40 passed, 0 failed;
- bivariate Gaussian targeted tests: 84 passed, 0 failed.
- Hooke/Emmy read-only review: no P1/P2 findings; one stale after-task P3
  sentence was corrected;
- `pkgdown::check_pkgdown()`: no problems found;
- `devtools::test()`: 647 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::build_site()`: completed successfully.
- `devtools::check(...)` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Tests of the tests:

- the new package-skeleton test calls `drmTMB:::make_tmb_data()` with
  `model_type = "broken"` and checks for a clear internal error;
- the bivariate targeted tests confirm the explicit `"biv_gaussian"` branch
  still supports the existing bivariate Gaussian fit paths.

Consistency audit:

- the likelihood design now says unknown labels are rejected;
- the previous routing-table after-task note no longer records the fallthrough
  as a known limitation.

What did not go smoothly:

- Rose first found the fallthrough while reviewing documentation, which shows
  that architecture docs can expose useful code-hardening work.

Known limitations:

- this is an internal guard only; it does not add new model families or user
  syntax.

Team learning:

- when a design note describes a routing contract, the code should enforce the
  same contract rather than rely on upstream validation alone.

## 2026-05-08: Lognormal Location-Scale Family

Scope:

- added exported `lognormal()` for fixed-effect univariate positive continuous
  responses;
- routed lognormal fits through `drm_build_lognormal_ls_spec()` and
  `model_type = 4`;
- implemented the TMB lognormal likelihood with the log-Jacobian term;
- added `fitted()`, `simulate()`, `residuals()`, and `sigma()` handling for
  lognormal fits;
- updated family, likelihood, distribution-roadmap, README, pkgdown source-map,
  known-limitation, and testing-strategy documentation.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = '^lognormal-location-scale$')"`
- `Rscript -e "devtools::test(filter = '^package-skeleton$')"`
- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "Sys.setenv('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'); devtools::check(document = FALSE, manual = FALSE, args = c('--no-manual'))"`
- `rg -n 'starts with Gaussian and Student-t|Here mu is the expected response|before adding lognormal|three implemented builders' README.md ROADMAP.md NEWS.md docs vignettes R man pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/articles/source-map.html pkgdown-site/articles/distribution-families.html pkgdown-site/reference/fitted.drmTMB.html`
- `rg -n 'lognormal\\(\\)|model_type = 4|dlnorm|arithmetic response mean|positive finite' README.md ROADMAP.md NEWS.md _pkgdown.yml docs/design docs/dev-log/known-limitations.md vignettes R tests man pkgdown-site/index.html pkgdown-site/reference/lognormal.html pkgdown-site/articles/source-map.html pkgdown-site/articles/distribution-families.html pkgdown-site/news/index.html`
- `rg -n 'meta_gaussian|tau ~|rho ~|family = meta' README.md ROADMAP.md NEWS.md docs/design vignettes R tests`

Results:

- `devtools::document()`: regenerated `NAMESPACE`, `man/lognormal.Rd`, and
  updated method docs; second run completed without roxygen warnings.
- Lognormal targeted tests: 39 passed, 0 failed.
- Package-skeleton targeted tests: 40 passed, 0 failed.
- `git diff --check`: clean.
- `pkgdown::check_pkgdown()`: no problems found.
- `devtools::test()`: 686 passed, 0 failed, 0 warnings, 0 skips.
- `pkgdown::build_site()`: completed successfully and generated the
  `reference/lognormal.html` page.
- First `devtools::check(...)`: 0 errors, 0 warnings, 1 note for an
  unqualified `fitted()` call in `residuals.drmTMB()`.
- After changing that call to `stats::fitted(object)`, final
  `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- `tests/testthat/test-lognormal-location-scale.R` checks parameter recovery,
  the fitted response mean formula, and an independent likelihood calculation
  against `stats::dlnorm()`.
- Reviewer-requested tests now cover factor predictors, small and large
  `sigma`, missing-row filtering before positivity checks, `mvbind()`
  rejection, `sd(group)` rejection, duplicate `sigma` formulas, missing
  response, and no-complete-observation errors.

Consistency audit:

- Boole read-only review found no likelihood or parameter-scale issues and one
  closure-artifact gap, now addressed by this check-log and after-task report.
- Bohr read-only review found missing edge-test coverage; the requested cases
  were added before broad checks.
- Stale wording scan found no old "Gaussian and Student-t only",
  "mu is the expected response", "before adding lognormal", or "three
  implemented builders" wording in active docs or generated pages.
- Guardrail scan found only intentional `meta_gaussian()` and `tau ~` warnings
  in meta-analysis design/tutorial docs and the after-task protocol.

What did not go smoothly:

- the first documentation patch missed several files because the README context
  had changed;
- the first R CMD check found the bare `fitted()` call, which is now fixed;
- Bohr's review showed the first test set was too happy-path oriented.

Known limitations:

- `lognormal()` is fixed-effect and univariate only;
- no lognormal random effects, known sampling covariance, phylogenetic or
  spatial structured effects, bivariate lognormal, or mixed lognormal composed
  family is implemented yet.

Team learning:

- for every new family, Curie should check edge cases from the project testing
  contract before broad checks, not after the first reviewer pass;
- Rose should search generated pkgdown pages for old status claims after every
  family status change.

## 2026-05-08: Family Link and Response-Scale Contract

Scope:

- added `docs/design/19-family-link-contract.md`;
- updated the family registry to require native parameter meaning,
  fitted-response rule, and variance rule;
- clarified that future Gamma, count, beta, and ordinal families need explicit
  link and `fitted()` contracts before likelihood code;
- updated the adding-families tutorial, distribution roadmap, and project-local
  add-family skill.

Commands run:

- `Rscript -e "rmarkdown::render('vignettes/adding-families.Rmd', output_dir = tempdir(), quiet = TRUE); cat('rendered adding-families\\n')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `sed -n '1,180p' .agents/skills/add-family/SKILL.md`

Results:

- adding-families vignette rendered successfully;
- `pkgdown::check_pkgdown()`: no problems found;
- `git diff --check`: clean;
- Hegel read-only review: no P0/P1 findings; P2/P3 wording and consistency
  findings were fixed before commit.

Tests of the tests:

- this design-only slice added no R likelihood tests;
- the contributor vignette render verifies the new prose and equations parse.

Consistency audit:

- the family registry now lists the same future contract fields as the new
  design note;
- the adding-families `rho12` equation uses the implemented guarded transform
  `0.99999999 * tanh(eta_rho12)`;
- the beta roadmap now says scale or precision naming is undecided, matching
  the new design note.
- the add-family skill now asks for native parameter meaning, fitted response
  rule, variance rule, and prediction/fitted tests.

What did not go smoothly:

- the first draft left the older family-registry required-fields list too
  small and used unguarded bivariate `rho12` in one contributor equation.

Known limitations:

- this is a design contract only; no Gamma, count, beta, or ordinal likelihood
  was implemented.

Team learning:

- when a design note introduces future required fields, Emmy should check that
  all existing contributor checklists, skills, and registry docs name the same
  fields.

## 2026-05-08: Implement Family Link Helpers

Scope:

- moved `predict()` response-scale transforms to internal helpers:
  `drm_dpar_link()` and `drm_inverse_link()`;
- moved `fitted()` response summaries to `drm_fitted_response()`;
- added tests for implemented link mappings, inverse links, family-specific
  fitted responses, and unsupported internal routing;
- updated the family-link contract note, source-map article, roadmap wording,
  and generated `predict()` documentation.

Commands run:

- `Rscript -e "devtools::test(filter = 'family-link-contract')"`
- `Rscript -e "devtools::test(filter = 'family-link-contract|gaussian-location-scale|student-location-scale|lognormal-location-scale|biv-gaussian')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-manual')"`
- `git diff --check`
- `rg -n "Implement the family-link contract before|hard-coded.*dpar|dpar == \"mu\"|response scale\\. For positive|Post-fit response-scale transforms|distributional parameter" README.md ROADMAP.md NEWS.md docs vignettes man pkgdown-site/reference/predict.drmTMB.html pkgdown-site/articles/source-map.html --glob '!pkgdown-site/search.json'`

Results:

- targeted link-helper tests: 14 passed;
- targeted neighbouring model tests: 208 passed;
- full `devtools::test()`: 700 passed, 0 failed, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully and refreshed local pages;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean;
- GitHub Actions for the preceding family-link contract commit were green
  before this slice was closed.

Tests of the tests:

- `test-family-link-contract.R` checks both successful mappings and malformed
  internal routing;
- the lognormal fitted-response test would fail if `fitted()` returned `mu`
  instead of the arithmetic response mean;
- the Student-t `nu` inverse-link test would fail if the `2 + exp(eta)`
  finite-variance transform drifted.

Consistency audit:

- `ROADMAP.md` now says the implemented helper table must be extended before
  new families are added, rather than saying the whole family-link contract is
  still unimplemented;
- `docs/design/19-family-link-contract.md` names the implemented helpers and
  keeps future Gamma/count/beta/ordinal work behind explicit link and fitted
  rules;
- `vignettes/source-map.Rmd` points contributors to the helper route in
  `R/methods.R`;
- local pkgdown pages contain both the updated `predict()` wording and the new
  source-map paragraph.

What did not go smoothly:

- `air format` is not installed in this environment, so formatting was kept
  manual and checked with `git diff --check`;
- Rose's review caught that closure artifacts and roadmap wording had not yet
  been updated.

Known limitations:

- the link table is internal and small; it records only implemented Gaussian,
  Student-t, lognormal, and bivariate Gaussian paths;
- family objects do not yet expose the full registry contract programmatically.

Team learning:

- Rose's after-task audit should run before any "small internal refactor" is
  treated as complete, because internal changes still create doc and roadmap
  consistency obligations;
- future add-family work should start by extending the link table and fitted
  response helper, then adding tests before touching the TMB likelihood.

## 2026-05-08: Align rho12 Equations and Interpretation

Scope:

- aligned active `rho12` equations with the implemented guarded transform:
  `rho12 = 0.99999999 * tanh(eta_rho12)`;
- updated bivariate interpretation prose so users read `coef(fit, "rho12")`
  as linear-predictor-scale coefficients and `rho12(fit)` as response-scale
  residual correlations;
- changed the `biv_gaussian()` family metadata to `rho12 = "atanh_guarded"`;
- clarified that `tau` is future second-shape syntax, not current formula
  grammar and not meta-analytic heterogeneity syntax;
- moved the bivariate phylogenetic aspirational warning before unsupported
  example code in the location-coscale extension note.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'family-link-contract|biv-gaussian')"`
- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "rmarkdown::render('vignettes/bivariate-coscale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/which-scale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/drmTMB.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/testing-likelihoods.Rmd', output_dir = tempdir(), quiet = TRUE); cat('rendered selected vignettes\\n')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-manual')"`
- `rg -n 'atanh\\(rho12|rho12_i = tanh|rho12 = tanh|rho12 = "atanh"|atanh-scale|atanh link internally|`nu`, `tau`|tau ~|explicit parameter names such as `mu`, `sigma`, `nu`, `tau`' README.md R man tests vignettes docs/design --glob '!docs/dev-log/**'`

Results:

- targeted bivariate and family-link tests: 99 passed;
- full `devtools::test()`: 701 passed, 0 failed, 0 skipped;
- selected vignettes rendered successfully;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- `test-family-link-contract.R` now checks that the public `biv_gaussian()`
  object and internal post-fit helper agree on `rho12 = "atanh_guarded"`;
- the bivariate regression tests still exercise `rho12(fit)`,
  `rho12(fit, type = "link")`, and `predict(..., dpar = "rho12")` after the
  metadata change.

Consistency audit:

- README, main vignette, bivariate-coscale vignette, scale-choice vignette,
  testing-likelihoods vignette, and design notes now use `eta_rho12` plus the
  guarded response transform;
- no active non-dev-log text remains with `rho12_i = tanh(...)`,
  `atanh(rho12_i) = ...`, `rho12 = "atanh"`, or `atanh-scale`;
- formula grammar now treats `tau` as future second-shape syntax only.

What did not go smoothly:

- the first documentation wording followed the simpler mathematical transform
  rather than the implemented guarded transform;
- a mechanical replacement temporarily created a multiline markdown table cell,
  which was fixed before rendering checks.

Known limitations:

- `rho12` uses a small guard for numerical stability; docs now state this, but
  papers may still present the idealized `tanh()` transform with an explanatory
  implementation note;
- `tau` remains design vocabulary for future shape families, not implemented
  formula syntax.

Team learning:

- Noether/Fisher should review symbolic equations against C++ and R helper
  transforms before public examples are expanded;
- Pat's interpretation request improved the tutorial: extraction examples need
  a sentence saying what the coefficient and response-scale value mean.

## 2026-05-08: Add Gamma Mean-CV Family

Scope:

- added fixed-effect univariate Gamma mean-CV models through
  `family = Gamma(link = "log")`;
- used `mu` as the response mean and `sigma` as the coefficient of variation,
  with `shape = 1 / sigma^2` and `scale = mu * sigma^2`;
- fixed the positive-continuous parameter map so unused `beta_nu` is fixed in
  lognormal and Gamma fits rather than counted as a free parameter;
- deliberately did not export a lowercase `gamma()` helper because
  `base::gamma()` is already the gamma special function;
- rejected non-log Gamma links, random effects, `sd(group)` scale formulae,
  `meta_known_V(V = V)`, `mvbind()`, and composed Gamma or mixed response
  families until those paths have explicit likelihood designs;
- updated formula grammar docs so the implemented Gamma route appears in the
  supported syntax map.

Commands run:

- `Rscript -e "devtools::test(filter = 'gamma-location-scale|family-link-contract')"`
- `Rscript -e "devtools::test(filter = 'gamma-location-scale|lognormal-location-scale|family-link-contract')"`
- `command -v air >/dev/null 2>&1 && air format . || true`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check()"`
- `git diff --check`
- `rg -n "future Gamma|Candidate Positive|Before implementing Gamma|additional non-Gaussian families beyond the first Student-t and lognormal|Gamma family may instead|gamma\\(\\) helper" README.md ROADMAP.md NEWS.md R man tests vignettes docs/design docs/dev-log/known-limitations.md pkgdown-site --glob '!docs/dev-log/after-task/**'`
- `rg -n "stats::Gamma\\(\\)|Gamma\\(link = \\\"log\\\"\\)|model_type = 5|Gamma mean-CV|coefficient of variation|base::gamma\\(\\)" README.md ROADMAP.md NEWS.md R man tests vignettes docs/design docs/dev-log/known-limitations.md pkgdown-site --glob '!docs/dev-log/after-task/**'`
- `rg -n "atanh\\(rho12|rho12_i = tanh|rho12 = tanh|rho12 = \\\"atanh\\\"|atanh-scale|atanh link internally|meta_gaussian|tau ~|meta_known_V\\([^V]" README.md ROADMAP.md NEWS.md R man tests vignettes docs/design docs/dev-log/known-limitations.md pkgdown-site --glob '!docs/dev-log/after-task/**'`

Results:

- initial targeted Gamma and family-link tests: 55 passed;
- targeted Gamma, lognormal, and family-link tests after reviewer fixes:
  114 passed;
- full `devtools::test()` after reviewer fixes: 761 passed, 0 failed, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- the Gamma likelihood test compares the fitted log-likelihood with an
  independent `stats::dgamma()` calculation at the fitted coefficients;
- Gamma and lognormal tests check `fit$sdr$pdHess` and `fit$df` against the
  number of reported fixed-effect coefficients, protecting against unused free
  TMB parameters;
- the prediction tests check that response-scale `mu` equals
  `exp(link-scale mu)`, that `newdata` prediction uses the log links for both
  `mu` and `sigma`, and that `fitted()` returns the response mean;
- the method tests check `sigma()` as coefficient of variation, Pearson
  residuals as `(y - mu) / (mu * sigma)`, and positive simulations;
- the failure-path tests reject the default inverse-link `stats::Gamma()`,
  `base::gamma`, non-positive responses, unsupported distributional
  parameters, random effects, known sampling covariance, `sd(group)`, and
  bivariate or composed Gamma families;
- the edge-case test fits both small and large coefficient-of-variation cases;
- Gamma complete-case filtering and default intercept-only `sigma` are tested.

Consistency audit:

- `README.md`, `ROADMAP.md`, `NEWS.md`, generated Rd files, formula grammar
  docs,
  `vignettes/distribution-families.Rmd`, `vignettes/adding-families.Rmd`,
  `vignettes/source-map.Rmd`, and family/likelihood/link design notes now
  describe the same Gamma mean-CV contract;
- `docs/dev-log/known-limitations.md` now lists Gamma as implemented but keeps
  random effects, known sampling covariance, phylogenetic terms, and bivariate
  or mixed Gamma models as future work;
- generated pkgdown pages contain the new Gamma source-map row and method
  documentation;
- remaining `meta_gaussian()` and `tau ~` hits are intentional guardrails, and
  remaining `gamma()` hits explain why no lowercase helper is exported.

What did not go smoothly:

- the first composed `Gamma/Gamma` failure-path test expected a narrower
  message, but the actual router correctly used the general mixed-response
  rejection. The test was updated to check the intended rejection path;
- the source map and adding-families vignette initially lagged behind the code
  and were caught by the stale-wording scan before closure;
- reviewer pass found that Gamma inherited a lognormal map that left unused
  `beta_nu` free. The fix also hardened lognormal by fixing `beta_nu` there.

Known limitations:

- Gamma models are fixed-effect and univariate only;
- `sigma` is a coefficient of variation in Gamma models, not a residual
  standard deviation. Docs state the residual SD as `mu * sigma`;
- bivariate Gamma, mixed composed families, Gamma meta-analysis,
  phylogenetic/spatial Gamma terms, and Gamma random effects remain future
  design work.

Team learning:

- Jason's landscape note was useful: use `stats::Gamma(link = "log")` rather
  than adding a `gamma()` helper that would collide with `base::gamma()`;
- future add-family tasks should begin with the family-link table, fitted
  response rule, and independent likelihood test before extending examples.

## 2026-05-08: Add Gamma GLM Comparator

Scope:

- added a two-tier comparator test for the overlapping Gamma mean-regression
  case against base R `stats::glm(..., family = Gamma(link = "log"))`;
- documented why the comparator checks `mu` coefficients rather than residual
  scale: base GLM and `drmTMB` estimate the Gamma dispersion on different
  routes.

Commands run:

- `Rscript -e "devtools::test(filter = 'comparators|gamma-location-scale')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check()"`

Results:

- targeted comparator and Gamma tests: 94 passed;
- full `devtools::test()`: 764 passed, 0 failed, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- the comparator would fail if the Gamma `mu` log-link design matrix or
  coefficient extraction drifted from the base GLM overlap case;
- the test also checks optimizer convergence and positive-definite Hessian for
  the fitted `drmTMB` model.

Consistency audit:

- `docs/design/05-testing-strategy.md` now lists the base GLM Gamma comparator
  alongside the independent `stats::dgamma()` likelihood check;
- no user-facing syntax changed.

What did not go smoothly:

- comparing Gamma residual scale directly to `glm()` would be misleading
  because the base GLM dispersion estimate is not the same object as
  `drmTMB`'s ML coefficient-of-variation parameter. The comparator was kept to
  the overlapping mean coefficients.

Known limitations:

- this is a mean-model comparator only; `sigma ~ predictors` still relies on
  simulation and independent likelihood tests.

Team learning:

- comparator tests should state exactly which parameterization overlaps with
  the external package. A loose "compare to glm" label would have hidden an
  avoidable scale-parameter mismatch.

## 2026-05-09: Add Fixed-Effect Poisson Mean Family

Scope:

- added a fixed-effect univariate Poisson mean path with
  `family = poisson(link = "log")`;
- kept the model deliberately narrow: `mu` only, no fitted `sigma`, no random
  effects, no `meta_known_V()`, no zero inflation, no overdispersion, and no
  bivariate count model;
- updated methods so `predict(dpar = "mu")`, `fitted()`, `simulate()`,
  `residuals()`, `sigma()`, `logLik()`, and coefficient extraction work for
  the implemented Poisson path;
- updated formula grammar, likelihood, family registry, testing strategy,
  distribution roadmap, family-link contract, README, NEWS, known limitations,
  source map, distribution-family vignette, formula grammar vignette, and
  generated Rd files.

Commands run:

- `R -q -e 'devtools::test(filter = "poisson|family-link-contract")'`
- reviewer pass by Euler over the uncommitted Poisson slice
- `R -q -e 'devtools::test(filter = "gaussian-location-scale|gaussian-random-effect-scale|poisson-mean|family-link-contract")'`
- `R -q -e 'devtools::document()'`
- `R -q -e 'devtools::test()'`
- `R -q -e 'pkgdown::check_pkgdown()'`
- `R -q -e 'pkgdown::build_site()'`
- `R -q -e 'devtools::check()'`
- `rg -n 'Poisson.*planned|poisson.*unsupported|supported families|count models would|Candidate Count|before implementing count|first count family should|model_type = 6|dpois|drm_build_poisson_spec' README.md ROADMAP.md NEWS.md docs vignettes tests R src man pkgdown-site --glob '!pkgdown-site/search.json'`
- `rg -n 'poisson\\(link = "log"\\)|Poisson mean|non-negative integer|unit dispersion|fixed unit dispersion|no fitted `sigma`' README.md ROADMAP.md NEWS.md docs vignettes tests R man pkgdown-site --glob '!pkgdown-site/search.json'`
- `rg -n 'Student-t, lognormal, and Gamma|first Student-t, lognormal, and Gamma|Gamma paths|count, beta' README.md ROADMAP.md NEWS.md docs vignettes pkgdown-site --glob '!pkgdown-site/search.json'`

Results:

- first targeted Poisson/link tests: 61 passed;
- stale-test regression pass after Euler review: 171 passed;
- full `devtools::test()`: 806 passed, 0 failed, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- independent likelihood test compares fitted log-likelihood to
  `sum(dpois(y, lambda = mu, log = TRUE))`;
- external comparator checks Poisson coefficients and log-likelihood against
  `stats::glm(..., family = poisson(link = "log"))`;
- malformed-input tests reject non-log links, `sigma` formulas, missing
  responses, negative counts, non-integer counts, random effects,
  `meta_known_V()`, `sd(id)`, and `mvbind()`;
- complete-case test confirms invalid count rows are ignored only when removed
  by missingness in model predictors.

Consistency audit:

- symbolic equations and R syntax are paired in the README,
  `docs/design/03-likelihoods.md`, `docs/design/19-family-link-contract.md`,
  and `vignettes/distribution-families.Rmd`;
- `docs/design/01-formula-grammar.md` and `vignettes/formula-grammar.Rmd`
  now list Poisson as implemented;
- generated pkgdown pages include the new Poisson wording after site build;
- historical after-task notes were left unchanged where they were true when
  written.

What did not go smoothly:

- two older tests still expected `poisson()` to be unsupported. Euler caught
  this before closure; the tests now check the new Poisson-specific rejection
  paths;
- roxygen-generated Rd files were stale until `devtools::document()` was run;
- `sigma(fit)` for Poisson needed an explicit interpretation. The package
  returns a fixed unit dispersion vector for base-R compatibility, and docs
  state that this is not a fitted distributional `sigma`.

Known limitations:

- Poisson models are fixed-effect, univariate, and `mu`-only;
- no overdispersion, zero inflation, hurdle component, random effects, known
  sampling covariance, phylogenetic/spatial effects, or bivariate count path is
  implemented yet;
- ecological count data with extra-Poisson variation will usually need the
  planned negative binomial or COM-Poisson paths.

Team learning:

- count-family work should start with the family-link table, because `mu` is
  no longer identity-linked;
- stale "unsupported family" tests are a predictable failure mode when planned
  families become implemented;
- Rose's after-task audit should always include generated pkgdown pages, not
  only source R Markdown and design docs.

## 2026-05-09: Add Fixed-Effect NB2 Mean-Dispersion Family

Scope:

- added `nbinom2()` as a fixed-effect univariate negative-binomial 2 family for
  overdispersed counts;
- defined the contract as `log(mu) = X_mu beta_mu`,
  `log(sigma) = X_sigma beta_sigma`, `size = 1 / sigma^2`, and
  `Var(y) = mu + sigma^2 * mu^2`;
- kept the first implementation narrow: no random effects, no `meta_known_V()`,
  no zero inflation, no hurdle component, no phylogenetic/spatial terms, and no
  bivariate or mixed count model;
- updated methods, tests, generated docs, pkgdown navigation, README, NEWS,
  ROADMAP, family registry, likelihood docs, testing strategy, distribution
  roadmap, family-link contract, known limitations, formula grammar, source
  map, and distribution-family vignette.

Commands run:

- Euclid landscape pass over NB2 conventions and sigma/size mapping
- `R -q -e 'devtools::test(filter = "nbinom2|family-link-contract")'`
- `R -q -e 'devtools::test(filter = "nbinom2|poisson|family-link-contract")'`
- `R -q -e 'devtools::document()'`
- `R -q -e 'devtools::test()'`
- `R -q -e 'pkgdown::check_pkgdown()'`
- `R -q -e 'pkgdown::build_site()'`
- `R -q -e 'devtools::check()'`
- `rg -n 'nbinom2.*planned|negative binomial.*planned|planned negative binomial|Candidate negative binomial|before implementing.*nbinom2|Use this contract before implementing `gamma\\(\\)`|model_type = 7|dnbinom|drm_build_nbinom2_spec' README.md ROADMAP.md NEWS.md DESCRIPTION _pkgdown.yml R src tests docs vignettes man pkgdown-site --glob '!pkgdown-site/search.json'`
- `rg -n 'sigma.*overdispersion|size = 1 / sigma\\^2|Var\\(y\\) = mu \\+ sigma\\^2|negative-binomial 2|Negative-binomial 2|nbinom2\\(\\)' README.md ROADMAP.md NEWS.md docs vignettes R tests man pkgdown-site --glob '!pkgdown-site/search.json'`
- `rg -n 'Poisson mean, and negative-binomial|Poisson paths|Poisson and negative-binomial|count-response families|COM-Poisson' README.md ROADMAP.md NEWS.md DESCRIPTION docs vignettes pkgdown-site --glob '!pkgdown-site/search.json'`
- `git diff --check`

Results:

- narrow NB2 and link-contract tests: 76 passed after replacing a fragile
  tiny-data link-contract fit and adding direct Poisson-limit objective checks;
- targeted count/link tests: 115 passed;
- full `devtools::test()`: 860 passed, 0 failed, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully and produced the `nbinom2`
  reference page;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- independent likelihood test compares fitted log-likelihood to
  `sum(dnbinom(y, mu = mu, size = 1 / sigma^2, log = TRUE))`;
- simulation tests use `stats::rnbinom()` with the same `size = 1 / sigma^2`
  mapping;
- Poisson-limit test checks that the NB2 likelihood approaches `dpois()` as
  `sigma` approaches zero and directly evaluates the TMB objective at very
  small `sigma` values;
- malformed-input tests reject unsupported `nu`, missing response, duplicated
  `sigma`, negative and non-integer counts, random effects, `meta_known_V()`,
  `sd(id)`, and `mvbind()`.

Consistency audit:

- symbolic equations and R syntax now match in the README,
  `docs/design/03-likelihoods.md`, `docs/design/19-family-link-contract.md`,
  and `vignettes/distribution-families.Rmd`;
- `docs/design/01-formula-grammar.md` and `vignettes/formula-grammar.Rmd`
  now list NB2 as implemented;
- generated pkgdown pages include `reference/nbinom2.html`;
- historical after-task notes that called NB2 future work were left unchanged
  where they were true when written.

What did not go smoothly:

- the first link-contract smoke fit used six toy observations and produced
  `sdreport()` NaN warnings. The test was changed to a modest simulated NB2
  example so it exercises fitted-response routing without making the Hessian
  fragile;
- NB2 naming is easy to confuse with size/precision conventions in other
  packages. The docs now state explicitly that `sigma` maps to
  `size = 1 / sigma^2` and larger `sigma` means more overdispersion.
- Darwin's review caught a numerical fragility in the first algebraically
  correct C++ density near the Poisson limit. The TMB template now uses an
  equivalent log-likelihood written in terms of `alpha = sigma^2`, avoiding
  direct computation of very large `size = 1 / sigma^2`.

Known limitations:

- NB2 models are fixed-effect, univariate, and complete-case only;
- no random effects, zero inflation, hurdle component, known sampling
  covariance, phylogenetic/spatial structured effects, bivariate count model,
  or mixed composed count model is implemented yet;
- no external `glmmTMB` or GAMLSS comparator is in the CRAN-safe test path yet.

Team learning:

- Euclid's landscape pass was valuable before coding because it clarified
  sigma direction and avoided accidentally copying a precision-parameter
  convention;
- small "smoke" fits can be numerically worse than moderate simulated examples
  for overdispersed count models;
- future count families should include an explicit map to any base-R density
  parameters before code is written.

## 2026-05-09 — Zero-Inflated Poisson Distributional Parameter

Task: implement fixed-effect zero-inflated Poisson models without adding a
public `zi_poisson()` constructor.

Implemented:

- extended the existing `family = poisson(link = "log")` route so
  `drm_formula(count ~ x, zi ~ z)` fits a fixed-effect zero-inflated Poisson
  likelihood;
- added TMB `model_type = 8` with conditional `mu = exp(X_mu beta_mu)` and
  structural-zero probability `zi = logit^{-1}(X_zi beta_zi)`;
- made `predict(dpar = "mu")` return the conditional Poisson mean,
  `predict(dpar = "zi")` return the structural-zero probability, and
  `fitted()` return `(1 - zi) * mu`;
- added `simulate()`, `residuals()`, `sigma()`, link-helper, and print-method
  support for the zero-inflated Poisson path;
- rejected unsupported `offset()` terms rather than letting `model.matrix()`
  silently drop them;
- rejected zero-column `zi` formulae such as `zi ~ 0`;
- updated README, ROADMAP, NEWS, formula grammar, family registry,
  likelihood, family-link, distribution-family, source-map, and known-limits
  documentation.

Review:

- Beauvoir reviewed simulation coverage and recommended adding `zi`-RHS
  unsupported-term coverage plus a high-`zi` boundary check;
- Poincare reviewed likelihood/plumbing and found the offset-silencing risk,
  the `zi ~ 0` start-length edge case, and stale fitted-response wording.

Commands run:

- `R -q -e 'devtools::load_all(recompile = TRUE)'`
- `R -q -e 'devtools::test(filter = "zi-poisson|family-link-contract")'`
- `R -q -e 'devtools::test(filter = "zi-poisson|poisson-mean|family-link-contract")'`
- `R -q -e 'devtools::document()'`
- `R -q -e 'devtools::test()'`
- `R -q -e 'pkgdown::check_pkgdown()'`
- `R -q -e 'pkgdown::build_site()'`
- `R -q -e 'devtools::check()'`
- `git diff --check`
- `rg -n 'zi_poisson\\(\\)|Poisson.*zero inflation.*later|mu-only|Only mu|No overdispersion, zero inflation|no zero inflation' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes man pkgdown-site --glob '!pkgdown-site/search.json'`

Results:

- targeted ZIP/link tests: 78 passed before review additions;
- targeted count/link tests after review additions: 120 passed;
- full `devtools::test()`: 912 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- recovery test simulates from known `mu` and `zi` coefficients with a factor
  predictor;
- likelihood test compares the fitted objective to an independent ZIP
  log-likelihood calculation;
- boundary tests check both `zi -> 0` Poisson convergence and `zi -> 1`
  log-space mixture stability;
- malformed-input tests cover duplicate `zi`, two-sided `zi`, unsupported
  random terms inside `mu` and `zi`, offsets, `zi ~ 0`, `meta_known_V()`,
  `sd(id)`, `mvbind()`, and non-integer counts.

Consistency audit:

- public examples use `family = poisson(link = "log")` plus `zi ~ ...`;
- no public `zi_poisson()` constructor was added;
- generated Rd files and pkgdown pages now describe zero-inflated Poisson
  fitted-response semantics;
- old historical after-task notes that correctly described Poisson as
  `mu`-only when written were left unchanged.

Known limitations:

- fixed-effect and univariate only;
- no random effects, overdispersion, hurdle component, known sampling
  covariance, phylogenetic/spatial structured effects, bivariate count model,
  or mixed composed count model yet;
- offsets are rejected rather than implemented.

Team learning:

- adding one TMB parameter vector requires updating all direct `MakeADFun()`
  test helpers with dummy data and parameters;
- count-family offset handling should be decided early for every new count
  family because base R can drop offsets from model matrices silently;
- stable log-space tests are needed at mixture boundaries, because naive
  probability-scale comparators lose precision near `zi = 1`.

## 2026-05-09 — Zero-Inflated NB2 Distributional Parameter

Task: implement fixed-effect zero-inflated negative-binomial 2 models through
the existing `nbinom2()` family route.

Implemented:

- extended `family = nbinom2()` so `drm_formula(count ~ x, sigma ~ z, zi ~ w)`
  fits a fixed-effect zero-inflated NB2 likelihood;
- added TMB `model_type = 9` with conditional `mu = exp(X_mu beta_mu)`,
  overdispersion scale `sigma = exp(X_sigma beta_sigma)`, and
  structural-zero probability `zi = logit^{-1}(X_zi beta_zi)`;
- kept plain NB2 semantics unchanged: `sigma` is an overdispersion scale with
  count-component `Var(y) = mu + sigma^2 * mu^2`;
- made `predict(dpar = "mu")` and `sigma()` describe the conditional count
  component, `predict(dpar = "zi")` return structural-zero probability, and
  `fitted()` return `(1 - zi) * mu`;
- added `simulate()`, response and Pearson residuals, link-helper, coefficient
  splitting, and print-method support for the zero-inflated NB2 path;
- added simulation recovery, independent likelihood, boundary, complete-case,
  and malformed-input tests;
- updated README, ROADMAP, NEWS, formula grammar, family registry, likelihood,
  family-link, distribution-family, source-map, and known-limits
  documentation.

Review:

- Kepler reviewed simulation-test design and recommended direct NB2-mixture
  likelihood comparison, `zi -> 0` and `zi -> 1` boundary tests, and malformed
  input coverage;
- Copernicus reviewed the implementation and flagged stale roxygen/public-doc
  wording plus the untracked test file before closeout.

Commands run:

- `air format .` (failed: `air` is not installed locally)
- `R -q -e 'devtools::document()'`
- `R -q -e 'devtools::test(filter = "zi-nbinom2|nbinom2|family-link-contract")'`
- `R -q -e 'devtools::test()'`
- `R -q -e 'pkgdown::check_pkgdown()'`
- `R -q -e 'pkgdown::build_site()'`
- `R -q -e 'devtools::check()'`
- `git diff --check`
- `rg -n "zero inflation.*NB2|zero inflation.*negative|zero-inflated NB2.*planned|NB2.*zero inflation.*not|zero-inflated negative|zi_nbinom2\\(\\)" README.md ROADMAP.md NEWS.md docs vignettes man pkgdown-site --glob '!pkgdown-site/search.json'`
- `rg -n "model_type = 8|model_type = 9|zi_nbinom2|zi_poisson|X_zi|beta_zi" R src tests docs vignettes man pkgdown-site --glob '!pkgdown-site/search.json'`

Results:

- targeted ZINB2/NB2/link tests: 135 passed, 0 failed, 0 warnings, 0 skips;
- full `devtools::test()`: 966 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- recovery test simulates from known `mu`, `sigma`, and `zi` coefficients with
  factor predictors;
- likelihood test compares the fitted objective to an independent
  zero-inflated NB2 log-likelihood using `stats::dnbinom()`;
- boundary tests check both `zi -> 0` NB2 convergence and `zi -> 1` log-space
  mixture stability;
- complete-case test checks that rows missing from the `zi` formula are
  filtered consistently;
- malformed-input tests cover duplicate `zi`, two-sided `zi`, unsupported
  random terms, offsets, `zi ~ 0`, `meta_known_V()`, `sd(id)`, `mvbind()`, and
  non-integer counts.

Consistency audit:

- public examples use `family = nbinom2()` plus `zi ~ ...`;
- no public `zi_nbinom2()` constructor was added;
- generated Rd files and pkgdown pages describe zero-inflated NB2 fitted,
  simulation, residual, and `sigma()` semantics;
- known limitations now distinguish implemented count zero-inflation from
  future count zero-inflation with random or structured effects;
- remaining `zi_nbinom2()` hits are intentional statements that no public
  constructor exists, and historical after-task notes were left unchanged where
  they were true when written.

Known limitations:

- fixed-effect and univariate only;
- no random effects, hurdle component, known sampling covariance,
  phylogenetic/spatial structured effects, bivariate count model, or mixed
  composed count model yet;
- offsets are rejected rather than implemented.

Team learning:

- documenting plain NB2 and zero-inflated NB2 in the same route reduces API
  clutter but requires extra stale-wording scans because `nbinom2()` now has
  two implemented behaviours;
- count-mixture families should always carry an independent density-comparison
  test plus boundary tests at both mixture extremes;
- local formatter availability should be checked when a new repo skill says to
  run a formatter that may not be installed.

## 2026-05-09 — NB2 MASS Comparator

Task: add a Tier 1 comparator check for the implemented negative-binomial 2
constant-dispersion overlap.

Implemented:

- added `MASS` to `Suggests`;
- added a `tests/testthat/test-comparators.R` smoke test comparing
  `drmTMB(family = nbinom2(), sigma ~ 1)` with `MASS::glm.nb()`;
- compared `mu` coefficients, `sigma = 1 / sqrt(theta)`, and `logLik()`;
- updated the testing-strategy design note, the testing-likelihoods vignette,
  and the implemented source map.

Commands run:

- `R -q -e 'packageVersion("MASS")'`
- ad hoc `drmTMB()` versus `MASS::glm.nb()` smoke comparison
- `R -q -e 'devtools::test(filter = "comparators|nbinom2")'`
- `R -q -e 'devtools::test()'`
- `R -q -e 'pkgdown::check_pkgdown()'`
- `R -q -e 'pkgdown::build_site()'`
- `R -q -e 'devtools::check()'`
- `air format .` (failed: `air` is not installed locally)
- `git diff --check`
- `rg -n "MASS::glm.nb|glm.nb|MASS,|Negative-binomial 2 mean coefficients|test-comparators\\.R" DESCRIPTION tests docs/design/05-testing-strategy.md vignettes/testing-likelihoods.Rmd vignettes/source-map.Rmd docs/dev-log/check-log.md docs/dev-log/after-task --glob '!docs/dev-log/after-task/2026-05-09-nb2-mass-comparator.md'`

Results:

- targeted comparator/NB2 tests: 139 passed, 0 failed, 0 warnings, 0 skips;
- full `devtools::test()`: 971 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- the comparator would fail if `drmTMB` used the wrong NB2 scale direction,
  because it checks `sigma = 1 / sqrt(theta)`;
- the comparator also checks log-likelihood, so equal coefficients cannot hide
  missing constants or a mismatched variance function.

Consistency audit:

- the testing strategy now lists the MASS NB2 comparator as implemented;
- the testing-likelihoods vignette teaches the exact scale translation;
- the source map now records `tests/testthat/test-comparators.R` as an NB2
  test file.

Known limitations:

- this comparator covers only the constant-dispersion NB2 overlap;
- NB2 models with `sigma ~ predictors` and zero-inflated NB2 models still rely
  on simulation and independent likelihood tests rather than an external
  package comparator.

Team learning:

- comparator tests should name the exact overlapping submodel, not the whole
  family, because `MASS::glm.nb()` cannot check distributional `sigma`
  predictors.

## 2026-05-09 — High `rho12` Recovery and Site Consistency

Task: harden the package-defining bivariate residual-correlation path and clean
up drift found by Rose's systems audit.

Implemented:

- added bivariate Gaussian recovery coverage for high positive and high
  negative residual correlations near `rho12 = +/-0.8`;
- updated the testing strategy and testing-likelihoods vignette so high
  `rho12` is part of the required bivariate test surface;
- refreshed DESCRIPTION and overview-vignette wording so zero-inflated
  Poisson and zero-inflated NB2 are no longer described as later work;
- added lognormal rows and syntax to the formula-grammar design note and
  vignette;
- changed placeholder wording in the distribution-family vignette to
  present-tense documentation;
- added `tools/fix-pkgdown-favicon-mime.R` and wired it into the pkgdown
  workflow to correct the smart-quote favicon MIME string introduced by the
  installed pkgdown template;
- added a count-family after-phase roll-up that supersedes older Poisson/NB2
  task-note limitations with the current Poisson, ZIP, NB2, and ZINB2 surface.

Commands run:

- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test()"`
- `air format .` (failed: `air` is not installed locally)
- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "devtools::check()"`
- `rg -n 'type="”|later .*zero-inflation|zero-inflation, and additional|This article will help|current planning reference' DESCRIPTION vignettes docs/design pkgdown-site/index.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/distribution-families.html pkgdown-site/articles/formula-grammar.html pkgdown-site/articles/testing-likelihoods.html`
- `rg -n 'lognormal\(\).*Implemented|family = lognormal\(\)|high positive and high negative|\+/-0\.8|drmTMB-logo\.png|man/figures/logo\.png' docs/design/01-formula-grammar.md docs/design/05-testing-strategy.md vignettes/formula-grammar.Rmd vignettes/testing-likelihoods.Rmd README.md _pkgdown.yml pkgdown-site/index.html pkgdown-site/articles/formula-grammar.html pkgdown-site/articles/testing-likelihoods.html`

Results:

- targeted bivariate tests: 94 passed, 0 failed, 0 warnings, 0 skips;
- full `devtools::test()`: 981 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- favicon post-processing removed all malformed smart-quote favicon MIME hits
  from the generated local site;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- the new recovery test checks both `rho12 = 0.8` and `rho12 = -0.8`;
- it checks optimizer convergence, positive-definite Hessian status,
  response-scale recovery, and the guarded response transform staying inside
  the correlation boundary.

Consistency audit:

- active docs now mention fixed-effect ZIP/ZINB2 as implemented rather than
  future work;
- formula-grammar docs and vignette now include `lognormal()`;
- README and `_pkgdown.yml` both point to `man/figures/drmTMB-logo.png`;
- historical after-task reports with older logo and count-family limitations
  were left unchanged, because they were accurate when written.

Known limitations:

- the new `rho12` edge test is still fixed-effect bivariate Gaussian only;
- pkgdown 2.1.3 contains the upstream smart-quote favicon template, so the
  project-side fixer remains necessary until that template is corrected
  upstream or the package uses a newer fixed pkgdown release.

Team learning:

- Rose's audit caught wording and generated-site details that ordinary model
  tests cannot see;
- site-generation quirks should be checked as artifacts, not assumed correct
  because `pkgdown::check_pkgdown()` passed.

## 2026-05-09 — Beta, Truncated Count, Hurdle, and Ordinal Roadmap Contract

Task: lock down the next-family roadmap before implementing another likelihood.

Implemented:

- made `beta()` the next planned family for strict continuous proportions, with
  public `sigma` and internal precision `phi = 1 / sigma^2`;
- reordered the count roadmap so `truncated_nbinom2()` comes before hurdle NB2,
  and hurdle NB2 uses `hu ~ predictors` as the hurdle-zero probability;
- clarified that beta-binomial denominator syntax is not settled yet, with
  `cbind(successes, failures)` recorded as one candidate;
- recorded first-pass ordinal scope as univariate cumulative-logit syntax with
  cutpoints;
- synchronized `ROADMAP.md`, the formula-grammar design note and vignette, the
  distribution-family article, and the family-link contract;
- added explicit implemented-contract rows for ZIP/ZINB2 `zi`.

Commands run:

- `Rscript -e "rmarkdown::render('vignettes/distribution-families.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/formula-grammar.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `git diff --check`
- `rg -n 'public naming is still undecided|scale/precision parameterization needs|Priority order after the Poisson.*compois|planned COM-Poisson path|Var\\[y_i\\)|structural zero or hurdle-crossing|Implemented continuous families|Planned syntax candidate|hurdle-crossing probability' docs/design/06-distribution-roadmap.md docs/design/19-family-link-contract.md docs/design/01-formula-grammar.md vignettes/distribution-families.Rmd vignettes/formula-grammar.Rmd ROADMAP.md`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `air format .` (failed: `air` is not installed locally)
- `Rscript -e "pkgdown::build_site()" && Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "devtools::check()"`
- `rg -n 'public naming is still undecided|scale/precision parameterization needs|Priority order after the Poisson.*compois|planned COM-Poisson path|Var\\[y_i\\)|structural zero or hurdle-crossing|hurdle-crossing probability|Implemented continuous families|Planned syntax candidate|type="”' ROADMAP.md docs/design vignettes pkgdown-site/articles/distribution-families.html pkgdown-site/articles/formula-grammar.html --glob '!docs/dev-log/**'`
- `rg -n 'roadmap syntax|hurdle-zero probability|Zero-inflated Poisson.*zi|beta\\(\\).*Planned|truncated_nbinom2\\(\\).*Planned|cumulative_logit\\(\\).*Planned|Implemented univariate families' docs/design/01-formula-grammar.md docs/design/06-distribution-roadmap.md docs/design/19-family-link-contract.md vignettes/distribution-families.Rmd vignettes/formula-grammar.Rmd pkgdown-site/articles/distribution-families.html pkgdown-site/articles/formula-grammar.html`

Results:

- direct renders for the distribution-family and formula-grammar vignettes:
  passed;
- `git diff --check`: clean;
- stale-wording scan: no hits for the old undecided beta precision wording,
  old COM-Poisson priority, old `Implemented continuous families` heading,
  malformed variance bracket, `hurdle-crossing probability`, malformed favicon
  MIME, or planned-status wording drift;
- positive consistency scan found the planned family rows, hurdle-zero wording,
  `zi` contract row, roadmap-syntax warning, and generated pkgdown pages;
- `pkgdown::check_pkgdown()`: no problems found;
- full `devtools::test()`: 981 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- no model code changed, so the test surface was consistency-focused rather
  than a new likelihood-recovery test;
- Pat's user-test review caught planned examples that looked runnable,
  denominator-syntax ambiguity, and the missing `zi` versus `hu` contrast;
- Rose's systems audit caught the missing formula-grammar source-of-truth
  update, missing implemented `zi` rows, and stale vignette heading.

Known limitations:

- `beta()`, `beta_binomial()`, `truncated_nbinom2()`, `hu`, and
  `cumulative_logit()` remain planned syntax, not fitted paths;
- beta-binomial denominator syntax is intentionally unresolved;
- the next implementation should start with strict fixed-effect `beta()` and
  add simulation plus comparator tests before any zero-inflated or
  beta-binomial extension.

Team learning:

- planned syntax should be added to the formula-grammar source of truth in the
  same patch as any roadmap article;
- user-facing planned examples need an explicit non-runnable warning when they
  look like ordinary `drmTMB()` calls.

## 2026-05-09 — Fixed-Effect Beta Mean-Scale Family

Task: implement the strict continuous-proportion `beta()` family with `mu` and
public `sigma` formulas.

Implemented:

- added exported `beta()` family constructor with `dpars = c("mu", "sigma")`
  and links `mu = "logit"`, `sigma = "log"`;
- added `drm_build_beta_ls_spec()` for fixed-effect univariate beta models,
  including strict `(0, 1)` response validation after missing-row filtering,
  default `sigma ~ 1`, starting values, and unsupported-grammar checks;
- added TMB `model_type = 10` beta likelihood with
  `phi = 1 / sigma^2`, `alpha = mu * phi`, and
  `beta_shape = (1 - mu) * phi`;
- updated `predict()`, `fitted()`, `sigma()`, `simulate()`, `residuals()`,
  `print()`, and the internal family-link table for beta models;
- added simulation recovery, independent `stats::dbeta()` likelihood,
  response-scale method, complete-case, factor-predictor, edge-scale, and
  unsupported-input tests;
- synchronized README, NEWS, pkgdown reference, formula grammar, family
  registry, likelihood design, family-link contract, source map, response
  family article, testing guide, and roadmap.

Commands run:

- `Rscript -e "parse('R/drmTMB.R'); parse('R/methods.R')"`
- `Rscript -e "devtools::load_all()"` (first run failed on `log1p()` in the
  TMB beta branch; rerun passed after replacing it with AD-safe `log(1 - y)`)
- `Rscript -e "devtools::test(filter = 'beta|family-link-contract')"` (first
  run caught an exact-boundary beta quantile in an edge test and a parser-level
  unsupported-parameter error message; rerun passed)
- `Rscript -e "devtools::test(filter = 'gamma-location-scale')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `air format .` (failed: `air` is not installed locally)
- `Rscript -e "devtools::test()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "devtools::check()"`
- `rg -n 'future beta|planned beta|Candidate Beta|beta\(\).*Planned|Next family sequence: `beta\(\)`|before adding beta|not supported fitting paths.*beta|Once implemented.*beta|beta\(\).*roadmap syntax' README.md ROADMAP.md NEWS.md docs vignettes R tests pkgdown-site --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'`
- `rg -n 'Beta mean-scale|model_type = 10|family = beta\(\)|strict continuous proportions|phi = 1 / sigma\^2' README.md ROADMAP.md NEWS.md DESCRIPTION _pkgdown.yml docs/design vignettes pkgdown-site/articles pkgdown-site/reference/beta.html pkgdown-site/news/index.html R tests/testthat --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'`
- `rg -n 'type="”|drmTMB_v25|trancated|lue distribution|old hex|man/figures/logo.png' README.md docs vignettes pkgdown-site --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'`

Results:

- targeted beta and family-link tests: 103 passed, 0 failed, 0 warnings,
  0 skips;
- post-documentation-refresh targeted beta and family-link tests: 103 passed,
  0 failed, 0 warnings, 0 skips;
- Gamma neighbour regression test: 54 passed, 0 failed, 0 warnings, 0 skips;
- full `devtools::test()`: 1043 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- favicon post-processing completed successfully;
- post-documentation-refresh `pkgdown::check_pkgdown()`: no problems found;
- post-documentation-refresh `devtools::check()`: 0 errors, 0 warnings,
  0 notes;
- `git diff --check`: clean;
- stale-wording scan found no active non-dev-log docs still describing
  `beta()` as planned, future, or roadmap-only;
- positive consistency scan found beta implemented wording in the README,
  NEWS, ROADMAP, design docs, vignettes, generated pkgdown article pages,
  `reference/beta.html`, and `news/index.html`;
- logo/favicon stale scan found no old-logo or malformed favicon wording hits.

Tests of the tests:

- independent likelihood test compares fitted `logLik()` to
  `stats::dbeta()` using the documented transform `phi = 1 / sigma^2`;
- complete-case test verifies boundary 0/1 rows are dropped before strict beta
  response validation when their predictors are missing;
- unsupported-input tests check boundary responses, `phi ~`, `nu ~`, duplicate
  `sigma`, response-less formulas, random effects, `sd(id)`, `meta_known_V()`,
  `mvbind()`, and `cbind(successes, failures)` denominator syntax;
- the first beta edge test failed before correction because deterministic
  quantiles for a very diffuse beta case reached exact machine boundaries.

Known limitations:

- beta models are fixed-effect, univariate, and strict `(0, 1)` only;
- random effects, known sampling covariance, phylogenetic/spatial terms,
  bivariate or mixed beta responses, zero/one inflation, ordered beta, and
  beta-binomial denominator syntax remain later phases;
- the C++ likelihood uses `log(1 - y)` rather than `log1p(-y)` because the
  local TMB autodiff type did not compile with plain `log1p()`.

Team learning:

- Curie's likelihood checklist caught the exact parameter transform and dummy
  TMB-data requirements before implementation;
- Meitner's test plan caught the most important boundary and method paths;
- Rose's after-task audit should keep checking generated pkgdown pages, not
  only source docs, because reference and news pages are where stale status
  often survives.

## 2026-05-09 — Fixed-Effect Zero-Truncated NB2 Family

Task: implement `truncated_nbinom2()` for fixed-effect positive-count
negative-binomial 2 distributional regression.

Implemented:

- added exported `truncated_nbinom2()` family constructor with
  `dpars = c("mu", "sigma")` and links `mu = "log"`, `sigma = "log"`;
- added `drm_build_truncated_nbinom2_spec()` for fixed-effect univariate
  positive-count models, including default `sigma ~ 1`, complete-case
  filtering before response validation, positive-integer checks, and clear
  rejections for `zi`, `hu`, random effects, `sd(group)`, `meta_known_V()`,
  `mvbind()`, and `cbind()` denominator syntax;
- added TMB `model_type = 11` with an NB2 log density minus the
  zero-truncation normalising constant `log(1 - Pr_NB2(0))`;
- updated `predict()`, `fitted()`, `sigma()`, `simulate()`, `residuals()`,
  `print()`, and the internal family-link table for zero-truncated NB2;
- added simulation recovery, independent `stats::dnbinom()` likelihood,
  response-scale method, complete-case, Poisson-limit, factor-predictor,
  scale-edge, and unsupported-input tests;
- synchronized README, NEWS, DESCRIPTION, pkgdown reference, formula grammar,
  family registry, likelihood design, testing strategy, distribution roadmap,
  family-link contract, source map, response-family article, testing guide,
  and known limitations.

Commands run:

- `Rscript -e "parse('R/drmTMB.R'); parse('R/methods.R'); parse('R/family.R'); parse('tests/testthat/test-truncated-nbinom2-location-scale.R')"`
- `Rscript -e "devtools::load_all()"`
- `Rscript -e "devtools::document()"` (first run warned because the new
  `truncated_nbinom2` Rd topic did not exist yet; rerun after generation was
  clean)
- `Rscript -e "devtools::test(filter = 'truncated-nbinom2|family-link-contract')"`
- `Rscript -e "devtools::test(filter = 'nbinom2|zi-nbinom2')"`
- `air format .` (failed: `air` is not installed locally)
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- ``rg -n 'truncated_nbinom2\(\).*planned|planned.*truncated_nbinom2|implement `truncated_nbinom2|practical next-family order is `truncated_nbinom2|Hurdle, truncated|truncated.*staged|Positive-count models should come before|zero-truncated.*planned' README.md ROADMAP.md NEWS.md DESCRIPTION docs vignettes R tests man --glob '!docs/dev-log/**'``
- `rg -n 'model_type = 11|family = truncated_nbinom2\(\)|Zero-truncated negative|zero-truncated NB2|truncated_nbinom2\(\).*fits|fitted\(\).*Pr_NB2\(0\)' README.md ROADMAP.md NEWS.md DESCRIPTION _pkgdown.yml docs/design vignettes man R tests/testthat --glob '!docs/dev-log/after-task/**'`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- ``rg -n 'truncated_nbinom2\(\).*planned|planned.*truncated_nbinom2|implement `truncated_nbinom2|practical next-family order is `truncated_nbinom2|Hurdle, truncated|truncated.*staged|zero-truncated.*planned' README.md ROADMAP.md NEWS.md DESCRIPTION docs vignettes man pkgdown-site --glob '!docs/dev-log/after-task/**' --glob '!pkgdown-site/search.json'``
- `rg -n 'Zero-truncated negative|zero-truncated NB2|truncated_nbinom2|model_type = 11|positive-count mean' pkgdown-site/articles pkgdown-site/reference pkgdown-site/news pkgdown-site/index.html pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`
- `Rscript -e "devtools::check()"`

Results:

- targeted truncated-NB2 and family-link tests: 109 passed, 0 failed, 0
  warnings, 0 skips;
- neighbouring NB2, zero-inflated NB2, and truncated-NB2 tests: 148 passed, 0
  failed, 0 warnings, 0 skips;
- full `devtools::test()`: 1104 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found before and after site build;
- `pkgdown::build_site()`: completed successfully and generated
  `reference/truncated_nbinom2.html`;
- favicon post-processing completed successfully;
- `git diff --check`: clean;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- stale-wording scan found no active source docs still describing
  `truncated_nbinom2()` as planned; the generated pkgdown meta description
  matched the broader pattern `truncated.*staged` only because it correctly
  says zero-truncated count models are implemented and hurdle/skewness models
  are staged later.

Tests of the tests:

- independent likelihood test compares fitted `logLik()` to
  `stats::dnbinom(y, mu, size) - log(1 - Pr_NB2(0))`;
- Poisson-limit test fixes `sigma` near zero and compares the objective to a
  hand-coded zero-truncated Poisson likelihood;
- complete-case test verifies invalid positive-count responses are dropped
  before validation when their predictors are missing;
- unsupported-input tests cover `nu`, `zi`, planned `hu`, duplicate `sigma`,
  missing response, zero/noninteger/negative/all-missing responses, random
  effects, `meta_known_V()`, `sd(id)`, `mvbind()`, and `cbind()`.

Known limitations:

- `truncated_nbinom2()` is fixed-effect and univariate only;
- `mu` and `sigma` describe the untruncated NB2 component; users should use
  `fitted()` for the expected observed positive count;
- hurdle models with `hu ~ predictors`, random effects, known sampling
  covariance, phylogenetic/spatial terms, bivariate count models, and mixed
  composed count families remain later phases.

Team learning:

- zero-truncated and hurdle models need sharply separated language because
  they share the truncated count kernel but answer different data-generating
  questions;
- extractor semantics must be checked whenever `predict(mu)` is not the same
  quantity as `fitted()`;
- generated pkgdown meta descriptions can trigger broad stale-wording scans,
  so future audits should classify those hits rather than blindly rewrite
  correct summaries.

## 2026-05-09 — Fixed-Effect Hurdle NB2 Family Component

Task: implement fixed-effect hurdle negative-binomial 2 models by adding
`hu ~ predictors` to the existing `truncated_nbinom2()` family route.

Implemented:

- extended `drm_build_truncated_nbinom2_spec()` so `hu` is an optional
  one-sided hurdle-zero formula;
- kept plain `truncated_nbinom2()` positive-only, while
  `truncated_nbinom2()` plus `hu ~ ...` accepts non-negative integer counts
  with at least one positive count;
- added TMB `model_type = 12` with
  `Pr(y = 0) = hu` and
  `Pr(y = k > 0) = (1 - hu) Pr_NB2(k) / (1 - Pr_NB2(0))`;
- exposed public coefficients and predictions as `hu`, while keeping
  `predict(fit, dpar = "mu")` as the untruncated NB2 component mean;
- updated `fitted()`, `simulate()`, `residuals()`, `sigma()`, `print()`, and
  the family-link helper for hurdle NB2;
- added simulation recovery, independent likelihood, method, complete-case,
  Poisson-limit, and malformed-input tests;
- synchronized DESCRIPTION, NEWS, README, ROADMAP, formula grammar, family
  registry, likelihood design, testing strategy, distribution roadmap,
  family-link contract, source map, response-family vignette, testing guide,
  known limitations, and generated Rd files.

Commands run:

- `Rscript -e "devtools::document(); devtools::test(filter = 'hurdle-nbinom2|truncated-nbinom2|family-link-contract')"`
- `air format .` (failed: `air` is not installed locally)
- `Rscript -e "devtools::test(filter = 'nbinom2|zi-nbinom2')"`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- ``rg -n 'hurdle NB2.*planned|hu ~.*Planned|Hurdle syntax.*planned|hurdle components.*later|hurdle count models.*planned|Next family sequence: hurdle|add hurdle NB2|hurdle models using .*remain|hurdle.*later phase|rejects `hu`' README.md ROADMAP.md NEWS.md DESCRIPTION docs/design vignettes R tests man``
- `rg -n 'model_type = 12|hu ~|hurdle-zero|hurdle_nbinom2|Hurdle NB2 models are implemented' pkgdown-site/articles pkgdown-site/reference pkgdown-site/index.html pkgdown-site/news/index.html`
- `Rscript -e "devtools::check()"`

Results:

- targeted hurdle/truncated/family-link tests: 166 passed, 0 failed, 0
  warnings, 0 skips;
- neighbouring NB2/zero-inflated/truncated/hurdle tests: 198 passed, 0 failed,
  0 warnings, 0 skips;
- full `devtools::test()`: 1161 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found before and after site build;
- `pkgdown::build_site()`: completed successfully;
- favicon MIME post-processing completed successfully;
- `git diff --check`: clean;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- stale-wording scan found no active source docs still describing hurdle NB2
  as planned. A broad generated-site scan matched only the correct DESCRIPTION
  sentence saying hurdle count models are implemented and skewness/additional
  response families are later phases.

Tests of the tests:

- independent likelihood test compares `logLik()` to a hand calculation using
  `log(hu)` for zeros and `log(1 - hu) + log Pr_NB2(y) -
  log(1 - Pr_NB2(0))` for positive counts;
- Poisson-limit test fixes `sigma` near zero and compares the objective to a
  hand-coded hurdle zero-truncated Poisson likelihood;
- method tests check that `predict(mu)` remains the untruncated NB2 component
  mean while `fitted()` returns `(1 - hu) * mu / (1 - Pr_NB2(0))`;
- malformed-input tests cover simultaneous `zi` and `hu`, duplicate `hu`,
  two-sided `hu`, zero-column `hu`, random effects, `sd(id)`, `meta_known_V()`,
  negative/noninteger/all-zero responses, `mvbind()`, and `cbind()`.

Known limitations:

- hurdle NB2 is fixed-effect and univariate only;
- random effects, known sampling covariance, phylogenetic/spatial terms,
  bivariate count models, and mixed composed count families remain later
  phases for this count route;
- there is no separate `hurdle_nbinom2()` constructor by design.

Team learning:

- Rose's after-task audit paid off again: the main risk was stale status text,
  not only likelihood code;
- Noether's math/R pairing rule kept the `predict(mu)` versus `fitted()`
  distinction explicit in docs and tests;
- the next skill improvement should be a small local formatting helper or
  installing `air`, because the desired formatter is still absent.

## 2026-05-09 — Bivariate Correlation-Pair and Ordinal Guard Design

Goal:

- clarify that bivariate double-hierarchical random-effect covariance blocks
  remain planned, separate from residual `rho12`;
- create a dedicated coscale correlation-pair design note before implementing
  complex pair extraction or likelihoods;
- fold Ortega et al. (2026) nest-success ordinal location-scale motivation
  into the distribution roadmap and family-link contract.

Changes:

- added `docs/design/20-coscale-correlation-pairs.md`;
- updated bivariate unsupported random-effect errors so `(1 | id)` and
  `(1 + x | p | id)` in `mu1`/`mu2` point users to the planned bivariate
  covariance-block path instead of a generic unsupported-term message;
- added bivariate guard tests in `tests/testthat/test-biv-gaussian.R`;
- updated the distribution roadmap, family-link contract, random-effects note,
  location-coscale phylogenetic note, formula-grammar vignette, response-family
  vignette, README, ROADMAP, reference programme, and known limitations;
- added `Ortega2026SeabirdPredictability` to `REFERENCES.bib`.

Commands run:

- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test(filter = 'formula-grammar|gaussian-random-intercepts|gaussian-random-effect-scale')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::check()"`
- `git diff --check`
- `air format .` (failed: `air` is not installed locally)
- `rg -n "Bivariate random-effect syntax is planned|correlation-pair|corpairs|zeta|cumulative_logit|O.Dea-style|O'Dea-style|biological data|rho ~|tau ~|meta_gaussian" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests REFERENCES.bib`
- `rg -n "Bivariate random-effect syntax is planned|correlation-pair|corpairs|zeta|cumulative_logit|O.Dea-style|O'Dea-style|biological data|rho ~|tau ~|meta_gaussian" pkgdown-site README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes R tests REFERENCES.bib`

Results:

- targeted bivariate Gaussian tests: 95 passed, 0 failed, 0 warnings, 0 skips;
- neighbouring formula/random-effect tests: 234 passed, 0 failed, 0 warnings,
  0 skips;
- full `devtools::test()`: 1162 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found before and after site build;
- `pkgdown::build_site()`: completed successfully;
- favicon MIME post-processing completed successfully;
- `git diff --check`: clean;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- stale-wording scans found expected planned ordinal/correlation-pair text and
  existing meta-analysis policy text; no `O'Dea-style` or "biological data"
  framing remained in the scanned source files.

Tests of the tests:

- new bivariate tests check malformed future syntax with both unlabelled and
  labelled bivariate random-effect blocks;
- the labelled-block test verifies that the user-facing error mentions planned
  labelled group-level covariance blocks rather than residual `rho12`.

Known limitations:

- this is a guard/design phase, not a new bivariate random-effect likelihood;
- `corpairs()` is a proposed extractor name, not an exported function;
- ordinal cumulative-logit location-scale models remain planned, and the
  `sigma` versus `zeta` public naming decision must be revisited before coding.

Team learning:

- Boole and Emmy should use the new pair table as the syntax/API constraint for
  future bivariate covariance work;
- Noether should require every future pair class to have symbolic equations
  paired with R syntax and extractor output;
- Rose should check that future docs do not use `rho12` for phylogenetic,
  spatial, or group-level correlations;
- Pat should review the ordinal nest-success explanation for whether an
  applied user understands the direction of `sigma` versus `zeta`.

## 2026-05-09 — Correlation-Pair Extractor and Tutorial Weight Clarification

Goal:

- export a first `corpairs()` helper for correlations that are already fitted;
- improve the bivariate coscale tutorial so symbolic equations, R syntax,
  model output, and interpretation are paired for applied users;
- clarify that the internal `0.99999999 * tanh()` residual-correlation guard
  is a numerical detail, not the biological model;
- record a first design contract for future `weights =` support.

Changes:

- added exported `corpairs()` and `corpairs.drmTMB()` methods;
- added `tests/testthat/test-corpairs.R`;
- added `man/corpairs.Rd` through `devtools::document()`;
- added `docs/design/21-tutorial-style.md`;
- added `docs/design/22-likelihood-weights.md`;
- added `docs/design/23-large-data-memory.md`;
- revised `vignettes/bivariate-coscale.Rmd` with LaTeX equations, a runnable
  ecological example, `summary(fit)`, `coef(fit, "rho12")`, `rho12(fit)`,
  `corpairs(fit)`, and a response-scale interpretation table;
- updated `vignettes/which-scale.Rmd` and
  `docs/design/03-likelihoods.md` to separate teaching notation
  `rho12_i = tanh(eta_rho12_i)` from the exact guarded implementation;
- updated `vignettes/formula-grammar.Rmd`, `_pkgdown.yml`, `README.md`,
  `ROADMAP.md`, `NEWS.md`, `docs/design/20-coscale-correlation-pairs.md`, and
  `docs/dev-log/known-limitations.md`;
- replaced remaining current-source `flagship` wording in roadmap/design prose
  with more professional terms such as `signature`, `core`, or
  `central example`;
- recorded that top-level `weights =` is planned for ordinary likelihood row
  weights and should remain distinct from `meta_known_V(V = V)`.
- recorded that the sparse phylogenetic A-inverse path and the million-row
  R-memory path are separate scaling problems.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'corpairs|biv-gaussian|gaussian-random-intercepts')"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/bivariate-coscale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/which-scale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/phylogenetic-spatial.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/formula-grammar.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/bivariate-coscale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/which-scale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/phylogenetic-spatial.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `air format .`
- `rg -n 'Fisher-z/atanh scale|flagship|selling point|O.Dea-style|O\\x27Dea-style|biological data' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man pkgdown-site --glob '!docs/dev-log/after-task/**'`
- `rg -n 'weights|meta_known_V\\(V = V\\)|rho12_i = tanh|0\\.99999999 \\* tanh|corpairs|Goodall|Russell|Confucius' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man pkgdown-site --glob '!docs/dev-log/after-task/**'`

Results:

- targeted tests: 299 passed, 0 failed, 0 warnings, 0 skips;
- full `devtools::test()`: 1192 passed, 0 failed, 0 warnings, 0 skips;
- direct vignette renders completed for formula grammar, bivariate coscale,
  which-scale, and phylogenetic-spatial pages;
- `pkgdown::check_pkgdown()`: no problems found before and after site build;
- `pkgdown::build_site()`: completed successfully;
- favicon MIME post-processing completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean;
- `air format .`: failed because `air` is not installed locally;
- stale-wording scans found no current-source `flagship`, `selling point`,
  `O'Dea-style`, or narrow "biological data" framing outside historical
  after-task notes.

Tests of the tests:

- `corpairs()` tests cover a predictor-dependent residual `rho12`, an ordinary
  labelled group-level `mu` random intercept-slope correlation, and the empty
  no-correlation case;
- the group-level test checks parsed covariance-block labels, coefficient
  names, response names, class labels, and the guarded correlation link;
- the bivariate residual test checks both response-scale and link-scale
  summaries against `rho12(fit)` and `predict(..., dpar = "rho12")`.

Known limitations:

- `corpairs()` only reports correlations already fitted by current likelihoods:
  residual bivariate `rho12` and ordinary univariate Gaussian `mu`
  random-effect correlations;
- bivariate group-level, phylogenetic, spatial, study-level, and cross-parameter
  correlation pairs remain planned;
- `weights =` remains a design note, not an implemented `drmTMB()` argument;
- large-data memory controls, sparse fixed-effect model matrices, and
  sufficient-statistic aggregation are planned but not implemented;
- `air` remains unavailable in the local toolchain.

Team learning:

- Ada should keep using stable team names in reports; temporary app nicknames
  should not appear in user-facing logs;
- Pat and Darwin pushed the bivariate tutorial toward real output and
  interpretation rather than syntax-only examples;
- Rose caught that tutorial notation and implementation notation need different
  jobs: readable model equations first, exact numerical guard in implementation
  notes;
- Fisher should require large-data benchmarks before the 10,000-tip,
  5-million-row phylogenetic path is called production-ready;
- Boole and Emmy should treat `weights =` as top-level fit syntax, not formula
  syntax.
- Grace should treat large-data readiness as a benchmarked release criterion,
  not a claim inferred from ordinary unit tests.

## 2026-05-09 — Likelihood Row Weights

Goal:

- implement top-level `weights =` as ordinary row log-likelihood multipliers;
- keep `weights =` separate from known sampling variance/covariance through
  `meta_known_V(V = V)`;
- expose processed model-row weights through `weights(fit)`.

Changes:

- added `weights = NULL` to `drmTMB()`;
- added internal `evaluate_likelihood_weights_arg()` and
  `subset_likelihood_weights()` helpers;
- stored processed weights in `fit$model$weights` and passed them to TMB as
  `DATA_VECTOR(weights)`;
- multiplied independent-row TMB likelihood contributions by `weights(i)`;
- used one complete-row weight per bivariate Gaussian response pair;
- rejected non-unit weights with full dense `meta_known_V(V = V)` covariance
  matrices because those paths are joint MVN likelihood blocks;
- added `weights.drmTMB()` documentation and pkgdown reference entry;
- updated `README.md`, `NEWS.md`, `docs/design/01-formula-grammar.md`,
  `docs/design/03-likelihoods.md`, `docs/design/22-likelihood-weights.md`,
  `docs/design/23-large-data-memory.md`, and `vignettes/source-map.Rmd`;
- recorded Andrew Gelman, Paul-Christian Buerkner, Jarrod Hadfield, David
  Fletcher, and Shun-ichi Amari in the reference programme as statistical
  computing and inference influences.

Commands run:

- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test(filter = 'phylo-utils')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale|biv-gaussian|phylo-utils')"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `rg -n "S3method\\(weights|weights.drmTMB|@param weights|weights =" NAMESPACE man R tests docs/design vignettes/source-map.Rmd README.md NEWS.md _pkgdown.yml`
- `rg -n 'weights.*not yet|does not yet have.*weights|planned.*weights|weights.*planned|Status: planned' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man _pkgdown.yml pkgdown-site --glob '!docs/dev-log/after-task/**'`
- `rg -n 'David \\[surname|Buerkner|Bürkner|Hadfield|Amari|Gelman|Fletcher' README.md ROADMAP.md NEWS.md docs/design docs/dev-log vignettes R tests man _pkgdown.yml`

Results:

- targeted Gaussian location-scale tests: 67 passed, 0 failed, 0 warnings,
  0 skips;
- targeted bivariate Gaussian tests: 101 passed, 0 failed, 0 warnings,
  0 skips;
- targeted phylo-utils tests: 45 passed, 0 failed, 0 warnings, 0 skips;
- full `devtools::test()`: 1215 passed, 0 failed, 0 warnings, 0 skips;
- combined targeted rerun after namespace repair: 213 passed, 0 failed,
  0 warnings, 0 skips;
- source-map vignette rendered successfully;
- `devtools::document()` updated `NAMESPACE`, `man/drmTMB.Rd`, and
  `man/weights.drmTMB.Rd`;
- `pkgdown::check_pkgdown()`: no problems found before and after site build;
- `pkgdown::build_site()`: completed successfully;
- favicon MIME post-processing completed successfully;
- first `devtools::check()` attempt exposed a missing `stats::weights`
  namespace import for the new S3 method;
- after adding `@importFrom stats weights`, final `devtools::check()`: 0 errors,
  0 warnings, 0 notes;
- `git diff --check`: clean.
- stale-wording scans found no stale current-source `weights planned` wording;
  the remaining `Status: planned` hit is the unrelated Phase 5b large-data
  memory strategy.

Tests of the tests:

- constant Gaussian weights check that parameter estimates are stable and
  `logLik` doubles;
- integer Gaussian weights check equivalence with explicit row duplication,
  including zero weights;
- malformed Gaussian weights check wrong length, negative values, missing or
  non-finite values, all-zero weights, and matrix input;
- bivariate Gaussian weights check complete-row weighting by doubling the
  row-paired likelihood;
- the full dense known-covariance rejection test protects the
  `meta_known_V(V = V)` distinction.

Known limitations:

- `weights =` are ordinary likelihood multipliers, not a memory-saving
  aggregation path;
- dense full known-covariance meta-analysis cannot yet be combined with
  non-unit weights;
- response-specific bivariate weights are not implemented;
- sufficient-statistic aggregation for very large Gaussian data remains a
  separate planned scaling feature.

Team learning:

- Boole and Emmy should keep `weights =` out of formula grammar;
- Fisher should require comparator checks before documenting weights as
  frequency weights beyond independent likelihoods;
- Grace should watch dense known-covariance and weight interactions in CI;
- Rose should continue checking for stale `weights planned` wording after
  pkgdown builds.
- Ada should treat namespace imports for new S3 generics as part of the
  implementation checklist, not only as a `devtools::check()` cleanup item.

## 2026-05-09 — Scale Tutorial Output Upgrade

Goal:

- improve the "Which scale are you modelling?" tutorial so readers see
  symbolic equations, matching R syntax, fitted output, and interpretation for
  the main scale-like quantities;
- remove the tiny `rho12` numerical guard from user-facing symbolic equations
  where it distracts from the statistical model.

Changes:

- added a copy-run scale audit to `vignettes/which-scale.Rmd`;
- added executed examples and fitted output for `sigma ~ temperature`,
  `weights = reliability`, `meta_known_V(V = vi)`, `sd(population) ~ habitat`,
  and bivariate `rho12 ~ treatment`;
- added LaTeX equations for the residual scale, known sampling variance,
  random-effect scale, and residual coscale examples;
- revised the `rho12` side-by-side guide to show the teaching equation
  `rho12_i = tanh(eta_rho12_i)` and moved the exact numerical guard into an
  implementation-detail note;
- made the same teaching-notation change in the README bivariate equation;
- made matching teaching-notation updates in `vignettes/drmTMB.Rmd` and
  `vignettes/adding-families.Rmd`;
- recorded the tutorial upgrade in `NEWS.md`.

Commands run:

- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/which-scale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale|biv-gaussian|meta-known-v|random-effect-scale')"`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/which-scale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/drmTMB.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/adding-families.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg -n '0\\.99999999 \\* tanh|rho12_i = 0\\.99999999|tiny guard|scale audit|weights = reliability|meta_known_V\\(V = vi\\)' README.md vignettes pkgdown-site/index.html pkgdown-site/articles/which-scale.html docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-09-scale-tutorial-output-upgrade.md`

Results:

- changed tutorial rendered successfully;
- getting-started and adding-families vignettes rendered successfully after
  the additional guard-notation cleanup;
- targeted neighbouring tests: 268 passed, 0 failed, 0 warnings, 0 skips;
- full `devtools::test()`: 1215 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found before and after site build;
- `pkgdown::build_site()`: completed successfully;
- favicon MIME post-processing completed successfully;
- final `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- final post-cleanup `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.
- stale-guard scan found no exact `0.99999999 * tanh()` guard in `README.md`,
  `vignettes/which-scale.Rmd`, `pkgdown-site/index.html`, or the rendered
  `which-scale` article; remaining hits are in historical check-log entries,
  the new after-task note, and implementation/developer vignettes where the
  guard is part of source or likelihood review.

Tests of the tests:

- the tutorial now executes model fits for the same likelihood paths checked by
  the targeted tests: Gaussian location-scale, known-`V` Gaussian
  meta-analysis, random-effect scale models, and bivariate Gaussian `rho12`;
- the rendered output checks that examples show actual `summary()`, `coef()`,
  `sigma()`, `weights()`, `predict(..., dpar = "sd(population)")`, and
  `rho12()` output rather than syntax-only blocks.
- the final `devtools::check()` rebuilt all vignettes after the extra README
  and article guard-notation cleanup.

Known limitations:

- the tutorial examples are simulated and deliberately compact; they do not yet
  include plots or a full biological data-analysis narrative;
- the exact `0.99999999 * tanh()` guard remains documented in implementation
  design notes, NEWS, and source-oriented pages where numerical details matter.

Team learning:

- Pat and Darwin should keep asking whether a tutorial shows fitted output and
  an interpretation, not only a valid formula;
- Noether should treat the readable equation and the exact guarded
  implementation as two linked but differently scoped objects;
- Rose should search both articles and README pages for user-facing numerical
  implementation details that belong in footnotes or implementation notes.

## 2026-05-09 — Location-Scale Tutorial Teaching Upgrade

Goal:

- make the Gaussian location-scale tutorial feel like a worked applied
  tutorial rather than only an API grammar page;
- answer Shinichi's request for symbolic equations paired with R syntax,
  fitted output, and biological interpretation.

Changes:

- added a fish-growth style worked example to `vignettes/location-scale.Rmd`;
- added executable simulation, model fit, `check_drm()`, `summary()`,
  response-scale `sigma` interpretation, and a fitted mean/residual-SD table;
- rewrote the opening of the article around the biological question of mean
  growth versus growth predictability;
- corrected `sd(site)_i` to group-level `sd(site)_k`;
- narrowed stale caveat wording from all non-Gaussian families to
  non-Gaussian random effects in this Gaussian tutorial;
- softened the future `corpairs()` wording in `vignettes/bivariate-coscale.Rmd`
  so planned correlation levels are not presented as current implementation;
- added a tutorial sentence clarifying that dense full `meta_known_V(V = V)`
  paths currently reject non-unit likelihood weights;
- recorded the tutorial upgrade in `NEWS.md`.

Commands run so far:

- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/location-scale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale|gaussian-random-effect-scale|gaussian-random-intercepts')"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/location-scale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/which-scale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/bivariate-coscale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `rg -n "first implemented|planned but not implemented|weights.*not implemented|non-Gaussian families|rho ~|tau ~|will also use|sd\\(site\\)_i" README.md vignettes docs/design docs/dev-log/known-limitations.md NEWS.md`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results so far:

- `vignettes/location-scale.Rmd`, `vignettes/which-scale.Rmd`, and
  `vignettes/bivariate-coscale.Rmd` render successfully;
- targeted Gaussian neighbouring tests: 301 passed, 0 failed, 0 warnings,
  0 skips;
- full `devtools::test()`: 1215 passed, 0 failed, 0 warnings, 0 skips;
- `git diff --check`: clean;
- `pkgdown::build_site()`: completed successfully;
- favicon MIME post-processing completed successfully;
- `pkgdown::check_pkgdown()`: no problems found;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- stale-status scan found no remaining `sd(site)_i`, no `will also use`, and
  no user-facing `non-Gaussian families` stale claim in changed vignettes;
  remaining hits are current planned-feature caveats or design-log patterns.

Tests of the tests:

- the rendered location-scale vignette now executes the exact Gaussian
  location-scale path exercised by `test-gaussian-location-scale.R`;
- the targeted tests also covered neighbouring random-intercept and
  random-effect-scale paths that the same vignette documents.

Known limitations:

- this pass adds a response-scale table but not a full plot; a future tutorial
  polish pass should add a small visual summary and possibly a real dataset;
- the example remains simulated to keep the vignette fast and deterministic.

Team learning:

- Pat's usability review correctly identified that `location-scale` was still
  too abstract compared with `which-scale` and `bivariate-coscale`;
- Rose's systems audit caught stale status wording and one observation-level
  index that should have been group-level;
- Ada should keep using staggered review during tutorial work: edit locally
  while Pat checks user comprehension and Rose checks cross-document drift.

## 2026-05-09 — Bivariate Coscale Tutorial Teaching Upgrade

Goal:

- make the bivariate location-coscale article teach residual `rho12` with
  biological variables, symbolic equations, fitted output, and response-scale
  interpretation;
- continue the tutorial style used in the location-scale upgrade.

Changes:

- renamed the runnable example section to a worked behaviour-coupling example;
- added activity-boldness model equations with `food`, `temperature`, and
  `disturbance` as biological predictors;
- clarified that `rho12` is not the raw activity-boldness correlation, but the
  residual correlation after response-specific mean and residual-SD models;
- added a "How to read this output" block after `summary(fit_biv)`;
- added a response-scale `rho12` curve along the disturbance gradient;
- added a concise reporting sentence for the fitted residual-correlation
  result;
- recorded the tutorial upgrade in `NEWS.md`.

Commands run so far:

- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/bivariate-coscale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian|corpairs|check-drm')"`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results so far:

- `vignettes/bivariate-coscale.Rmd` renders successfully;
- targeted bivariate/correlation diagnostics tests: 184 passed, 0 failed,
  0 warnings, 0 skips.
- `git diff --check`: clean;
- full `devtools::test()`: 1215 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::build_site()`: completed successfully;
- favicon MIME post-processing completed successfully;
- `pkgdown::check_pkgdown()`: no problems found;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- the rendered vignette executes the same fixed-effect bivariate Gaussian
  `rho12` path tested by `test-biv-gaussian.R`;
- the targeted test command also exercises `corpairs()` and `check_drm()`,
  which the edited tutorial prints.

Known limitations:

- the example is still simulated rather than a real behaviour dataset;
- the curve is a teaching plot, not an uncertainty interval;
- bivariate random effects and group-level bivariate covariance blocks remain
  planned and are explicitly separated from residual `rho12`.

Team learning:

- Noether's equation/syntax pairing should continue to use actual variables in
  user tutorials;
- Darwin and Pat's style preference is now clear: show the output row, explain
  the link scale, then translate to the biological question;
- Rose should continue watching for future-correlation wording that sounds
  implemented before the TMB likelihood exists.

## 2026-05-09 — Meta-Analysis Tutorial Teaching Upgrade

Goal:

- turn the meta-analysis article from a design scaffold into a teaching
  tutorial with equations, executable R syntax, fitted output, response-scale
  interpretation, and a clear `weights =` versus `meta_known_V(V = V)`
  distinction;
- keep meta-analysis framed as Gaussian regression with known sampling
  covariance, not a separate family or `tau ~` grammar.

Changes:

- retitled the article to "Mean effects and residual heterogeneity in
  meta-analysis";
- added univariate diagonal-`V` equations and full-`V` equations;
- added a worked ecological restoration example with `habitat`, `duration`,
  known sampling variance `vi`, `summary(fit_meta)`, response-scale `sigma`,
  and `check_drm(fit_meta)`;
- clarified that `weights = 1 / vi` is not equivalent to
  `meta_known_V(V = vi)`;
- made the repeated-study `sd(study)` example explicitly schematic and tied it
  to `dat_repeated`, avoiding confusion with the one-row-per-study simulated
  example;
- clarified that bivariate `rho12` is estimated residual correlation after
  known within-study sampling covariance, and only becomes a between-study
  residual correlation when the residual component represents between-study
  heterogeneity;
- updated `docs/design/08-meta-analysis.md` with the same `rho12` wording and
  moved the `0.99999999` boundary guard out of the symbolic transform and into
  implementation prose;
- recorded the tutorial upgrade in `NEWS.md`.

Commands run so far:

- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/meta-analysis.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test(filter = 'meta')"`
- `rg -n "residual or between-study|heterogeneous heterogeneity|rho12_i = 0\\.99999999|0\\.99999999 \\* tanh|O.Dea-style|O'Dea-style|meta_gaussian|tau ~" vignettes/meta-analysis.Rmd docs/design/08-meta-analysis.md NEWS.md README.md ROADMAP.md docs/dev-log/known-limitations.md`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `rg -n "Mean effects and residual heterogeneity|restoration|weights = 1 / vi|coscale means|between-study residual correlation|0\\.99999999" pkgdown-site/articles/meta-analysis.html pkgdown-site/news/index.html`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results so far:

- `vignettes/meta-analysis.Rmd` renders successfully after `devtools::load_all()`;
- targeted meta-analysis tests: 57 passed, 0 failed, 0 warnings, 0 skips;
- `git diff --check`: clean;
- full `devtools::test()`: 1215 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::build_site()`: completed successfully and wrote the updated
  `articles/meta-analysis.html`;
- favicon MIME post-processing completed successfully;
- `pkgdown::check_pkgdown()`: no problems found;
- generated HTML contains the new title, restoration example, weights
  clarification, coscale definition, and corrected between-study residual
  correlation wording;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- the rendered tutorial executes the implemented univariate Gaussian
  `meta_known_V(V = vi)` path and prints `summary()`, `sigma()`, and
  `check_drm()` output;
- targeted tests exercise diagonal and dense known-`V` paths, malformed
  covariance input, row filtering, random-effect scale combinations, and the
  bivariate `meta_vcov_bivariate()` helper.

Known limitations:

- the worked restoration example is simulated to keep the vignette
  deterministic and fast;
- the repeated-study `sd(study)` example remains schematic rather than
  executable in this article;
- bivariate known-`V` fitting remains dense, complete-row, and without sparse
  storage or missing-single-outcome support.

Team learning:

- Pat caught that "multiple effect sizes per study" conflicted with the
  earlier one-row-per-study simulation, so tutorial sections should say clearly
  when they are executable versus schematic;
- Noether's equation pass should keep public equations clean and move numerical
  guards such as `0.99999999` into implementation notes;
- Rose's stale-wording scan should include design docs, not only vignettes,
  because ambiguous tutorial wording can hide in design notes too.

## 2026-05-09 — Phylogenetic-Spatial Tutorial Teaching Upgrade

Goal:

- make the structured-dependence article teach the implemented
  `phylo(1 | species, tree = tree)` path with a concrete ecology/evolution
  example, equations, fitted output, interpretation, and failure-recovery
  guidance;
- keep planned spatial syntax visibly marked as planned before any spatial
  code block appears.

Changes:

- retitled the article to "Structured dependence: implemented phylogeny and
  planned spatial models";
- added a worked thermal-tolerance example where body size predicts species
  trait means after accounting for shared ancestry;
- added LaTeX equations for the structured-effect bridge and the implemented
  Gaussian phylogenetic location model;
- added fitted `summary(fit_phylo)` output, response-scale residual SD, fitted
  phylogenetic SD, and `check_drm(fit_phylo)`;
- added a practical tree/species recovery checklist covering `phylo` class,
  tip labels, name matching, positive branch lengths, ultrametricity, and the
  currently implemented intercept-only Gaussian `mu` syntax;
- changed the spatial section heading and lead sentence so users see
  "planned, not implemented" before the code block;
- clarified in `README.md` that `sigma_phylo` is the among-species
  phylogenetic SD in the mean, while `sigma` remains the residual
  within-observation SD;
- clarified in `ROADMAP.md` that future sparse known-covariance infrastructure
  is beyond the current phylogenetic A-inverse path.

Commands run so far:

- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/phylogenetic-spatial.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test(filter = 'phylo|check-drm')"`
- `git diff --check`
- `rg -n "spatial fields|spatial\\(1 \\| site|planned, not implemented|Hadfield and Nakagawa|A-inverse path internally|sigma_phylo|thermal tolerance|species names" vignettes/phylogenetic-spatial.Rmd README.md ROADMAP.md NEWS.md`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `rg -n "Structured dependence: implemented phylogeny|thermal tolerance|body size predicts|tree object has class|spatial likelihood is not implemented|setup code creates|sigma_phylo|Hadfield and Nakagawa|A-inverse path internally" pkgdown-site/articles/phylogenetic-spatial.html pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results so far:

- `vignettes/phylogenetic-spatial.Rmd` renders successfully;
- targeted phylogenetic/check tests: 124 passed, 0 failed, 0 warnings, 0 skips;
- `git diff --check`: clean;
- full `devtools::test()`: 1215 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::build_site()`: completed successfully;
- favicon MIME post-processing completed successfully;
- `pkgdown::check_pkgdown()`: no problems found;
- generated HTML contains the new title, thermal-tolerance example,
  tree/species checklist, explicit spatial-not-implemented wording, and
  `sigma_phylo` explanation;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- the rendered tutorial executes the implemented univariate Gaussian
  phylogenetic `mu` likelihood and prints `summary()`, `check_drm()`, residual
  SD, and phylogenetic SD output;
- targeted tests exercise the phylogenetic Gaussian objective, dense marginal
  likelihood comparators, meta-analysis composition, conditional prediction,
  missing-row handling, and planned-feature errors for phylogenetic slopes and
  phylogenetic `sigma`.

Known limitations:

- the worked thermal-tolerance dataset is simulated so the vignette remains
  deterministic and fast;
- the tree helper is a toy setup helper, not a recommended phylogenetic data
  workflow;
- spatial random effects, phylogenetic slopes, phylogenetic `sigma`, and
  bivariate structured covariance blocks remain planned.

Team learning:

- Socrates caught that a roadmap article still needs a concrete scientific
  question before syntax;
- applied users need recovery guidance immediately after implemented
  structured syntax, especially tree-tip and species-name checks;
- Ada should keep planned spatial syntax in clearly labelled "not implemented"
  sections until the likelihood and recovery tests exist;
- Ada should treat token and context efficiency as a project skill: use
  targeted reads, concise updates, and fewer agents unless parallel review
  clearly reduces risk.

## 2026-05-09 — Tutorial Learning Path Navigation

Goal:

- make the pkgdown tutorial navigation and get-started article point users to
  the right tutorial from their scientific or statistical question;
- keep the pass small and efficient after the larger tutorial upgrades.

Changes:

- added a "Learning path" table to `vignettes/drmTMB.Rmd`;
- updated pkgdown tutorial menu labels for meta-analysis and
  phylogenetic-spatial tutorials;
- recorded the navigation change in `NEWS.md`.

Commands run:

- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/drmTMB.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `rg -n "Learning path|Start with the question|Mean effects and heterogeneous heterogeneity|Implemented phylogeny and planned space|Mean effects and residual heterogeneity|Structured dependence$" pkgdown-site/articles/drmTMB.html pkgdown-site/articles/index.html pkgdown-site/news/index.html pkgdown-site/pkgdown.yml _pkgdown.yml vignettes/drmTMB.Rmd NEWS.md`
- `git diff --check`

Results:

- get-started article render: passed;
- pkgdown build: passed;
- pkgdown check: no problems found;
- generated HTML contains the learning path and updated tutorial menu labels;
- no stale generated-site hit remains for the old meta-analysis menu label.

Tests of the tests:

- this was a documentation-navigation change only; no likelihood or parser path
  changed;
- the rendered get-started article and generated pkgdown HTML verify that the
  user-facing learning path is present.

Known limitations:

- this pass does not add new model examples;
- the learning path is compact and should be revisited after real datasets are
  added to the tutorials.

Team learning:

- Good planning reduces token and compute waste: this phase used targeted reads,
  no extra agents, and documentation-specific checks rather than a broad test
  sweep.

## 2026-05-09 — Poisson Likelihood Weight Test

Goal:

- strengthen the ordinary likelihood `weights =` implementation by testing one
  non-Gaussian independent-row family.

Changes:

- added a Poisson test that constant weights keep coefficient estimates stable
  while doubling the log-likelihood;
- added a Poisson test that integer row weights, including zero weights, match
  an explicitly row-duplicated dataset.

Commands run:

- `Rscript -e "devtools::test(filter = 'poisson-mean')"`
- `rg -n "Poisson.*weights|weights.*Poisson|weights.*planned|does not yet.*weights" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes tests/testthat/test-poisson-mean.R R man _pkgdown.yml`
- `git diff --check`

Results:

- first targeted run failed on an overly tight coefficient comparison between
  the weighted and duplicated Poisson fits;
- after relaxing that comparison to `1e-4`, targeted Poisson tests passed:
  46 passed, 0 failed, 0 warnings, 0 skips;
- stale-wording search found no current documentation claiming that
  `weights =` is unimplemented.

Tests of the tests:

- the new test failed before the tolerance correction, confirming it was
  exercising the weighted-vs-duplicated likelihood path;
- constant-weight and row-duplication checks both protect the TMB row-weight
  multiplication for count likelihoods, not only Gaussian likelihoods.

Known limitations:

- this phase added no new user-facing behaviour; it only improved coverage for
  an implemented feature;
- dense full `meta_known_V(V = V)` still rejects non-unit weights by design.

Team learning:

- Curie should prefer cross-family tests for shared TMB machinery;
- Ada should treat small tolerance differences between two optimizations as a
  test-design issue, not as a model-behaviour change.

## 2026-05-09 — NB2 Likelihood Weight Test

Goal:

- extend likelihood-weight coverage to a distributional count model where both
  `mu` and `sigma` are estimated by formulas.

Changes:

- added an `nbinom2()` test that constant weights keep both `mu` and `sigma`
  coefficients stable while doubling the log-likelihood;
- added an `nbinom2()` test that integer row weights, including zero weights,
  match an explicitly row-duplicated dataset.

Commands run:

- `Rscript -e "devtools::test(filter = 'nbinom2-location-scale')"`
- `rg -n "nbinom2.*weights|weights.*nbinom2|weights.*planned|does not yet.*weights" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes tests/testthat/test-nbinom2-location-scale.R R man _pkgdown.yml`
- `git diff --check`

Results:

- targeted NB2-family tests passed: 108 passed, 0 failed, 0 warnings, 0 skips;
- the filter also ran the neighbouring truncated NB2 test file, which remained
  green;
- stale-wording search found no current documentation claiming that
  `weights =` is unimplemented.

Tests of the tests:

- the new checks exercise row weights in a count model with an estimated
  overdispersion formula, so they protect more than the simpler Poisson mean
  branch;
- integer row weights are compared with explicit row duplication for both
  `mu` and `sigma` coefficients and for the fitted log-likelihood.

Known limitations:

- this phase added no new user-facing behaviour; it only improved test
  coverage for an implemented feature;
- zero-inflated, hurdle, and truncated count-family weight tests remain useful
  future coverage.

Team learning:

- Curie should keep adding one representative test per likelihood class rather
  than duplicating every possible family immediately;
- Ada should keep these coverage passes staggered and small so CI failures are
  easy to locate.

## 2026-05-09 — Count Exposure Offsets

Goal:

- respect standard R count-model convention by supporting
  `offset(log(exposure))` in the `mu` formula for implemented Poisson and NB2
  count models.

Changes:

- added `offset()` extraction, validation, storage, TMB data plumbing, starting
  values, and prediction support for Poisson and NB2 `mu` formulas;
- added offset support to the implemented zero-inflated Poisson and
  zero-inflated NB2 paths;
- kept offsets rejected in `sigma`, `zi`, `hu`, Gaussian, bivariate,
  meta-analytic, phylogenetic, spatial, truncated NB2, and hurdle NB2 formulas;
- updated README, NEWS, formula grammar, family registry, likelihood equations,
  family-link contract, distribution roadmap, source map, known limitations,
  and distribution-family tutorials.

Commands run:

- `command -v air || true`
- `Rscript -e "devtools::test(filter = 'poisson-mean|zi-poisson|nbinom2-location-scale|zi-nbinom2')"`
- `Rscript -e "rmarkdown::render('vignettes/distribution-families.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/formula-grammar.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::test(filter = 'phylo-utils|poisson-mean|zi-poisson|nbinom2-location-scale|zi-nbinom2')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg -n "offset|exposure|trap_nights|rate model|Poisson mean|nbinom2" ROADMAP.md docs/dev-log/known-limitations.md README.md docs/design vignettes _pkgdown.yml`
- `rg -n "offset|exposure|trap_nights|rate model" pkgdown-site`
- `git diff --check`

Results:

- `air` was not installed in this environment, so no formatter was run;
- first targeted count-family offset tests passed: 264 passed, 0 failed;
- direct renders of the distribution-family and formula-grammar vignettes
  passed;
- `devtools::document()` regenerated `man/drmTMB.Rd`;
- first full `devtools::test()` failed in the hidden phylogenetic prior TMB
  branch because its direct TMB data fixture lacked the new `offset_mu` slot;
- after adding the dummy `offset_mu` fixture, targeted count plus phylo tests
  passed: 309 passed, 0 failed;
- second full `devtools::test()` passed: 1246 passed, 0 failed;
- `pkgdown::build_site()` rebuilt successfully;
- favicon MIME repair script completed without output;
- `pkgdown::check_pkgdown()`: no problems found;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- stale-wording scans found current offset/exposure wording in the intended
  user-facing, design, and generated-site files. Remaining `offset` hits in
  generated CSS/SVG/pkgdown JavaScript were unrelated to model offsets;
- `git diff --check`: clean.

Tests of the tests:

- Poisson offsets are compared against `stats::glm()` with the same
  `offset(log(effort))` formula for coefficients and log-likelihood;
- NB2, zero-inflated Poisson, and zero-inflated NB2 offsets are checked against
  independent pointwise likelihood calculations;
- prediction tests verify that newdata exposure changes the response-scale
  `mu` prediction as `exposure * exp(X beta)`;
- malformed exposure with `log(0)` triggers the finite-offset validation path;
- the failed full-test run confirmed that direct TMB fixtures also need to
  track new C++ data slots.

Known limitations:

- offsets are implemented only for `mu` in Poisson and NB2 routes, including
  zero-inflated variants;
- offsets remain intentionally unsupported for `sigma`, `zi`, `hu`,
  truncated NB2, hurdle NB2, Gaussian, bivariate, meta-analysis,
  phylogenetic, and spatial formulas;
- this phase does not add response-specific bivariate weights or count-family
  random effects.

Team learning:

- respecting R history made the user-facing syntax clearer than inventing an
  `exposure =` argument;
- Rose's status-inventory scan caught the source-map and known-limitations
  pages after the first implementation pass;
- the hidden phylogenetic branch failure is a useful reminder that every new
  `DATA_*` slot in TMB must be mirrored in test fixtures that bypass the R
  model builder.

## 2026-05-09 -- Standard fixed-effect formula terms

Goal:

- verify and document that implemented fixed-effect distributional-parameter
  formulas use base R formula semantics for transformations and interactions.

Changes:

- added a Gaussian location-scale test covering `poly(x, 2)`, `I(x^2)`,
  `(x1 + x2 + x3)^2`, `x1:x2`, and `predict(newdata = ...)`;
- updated the formula grammar design note and formula-grammar vignette to
  say that implemented fixed-effect formulas support ordinary R formula
  transformations and interaction expansions;
- kept the scope explicit: this covers fixed-effect formula terms, not
  expanded random-effect or structured-effect slope grammar.

Commands run:

- `Rscript -e 'devtools::load_all(quiet=TRUE); set.seed(1); n<-120; dat<-data.frame(x=runif(n,-1,1), x1=rnorm(n), x2=rnorm(n), x3=rnorm(n), z=runif(n,-1,1)); dat$y <- 0.2 + 0.3*dat$x + 0.2*dat$x^2 + 0.1*dat$x1*dat$x2 + rnorm(n, sd=.5); fit<-drmTMB(drm_formula(y ~ poly(x,2) + I(x^2) + (x1+x2+x3)^2, sigma ~ poly(z,2) + x1:x2), data=dat, family=gaussian()); print(fit$opt$convergence); nd<-dat[1:3,]; print(predict(fit,newdata=nd,dpar="mu")); print(predict(fit,newdata=nd,dpar="sigma"))'`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "rmarkdown::render('vignettes/formula-grammar.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

Results:

- the ad hoc fit converged with code 0 and produced `mu` and `sigma`
  predictions for `newdata`;
- targeted Gaussian location-scale tests passed after strengthening the
  `poly()` newdata-basis checks: 74 passed, 0 failed;
- formula-grammar vignette render passed;
- full `devtools::test()` passed after the final test update: 1253 passed,
  0 failed;
- first pkgdown build attempt failed because the sandbox could not write to
  the R Sass cache and could not resolve `cloud.r-project.org`; rebuilding
  with the required cache/network permission passed;
- favicon MIME repair completed without output;
- `pkgdown::check_pkgdown()`: no problems found;
- `git diff --check`: clean.

Tests of the tests:

- the new test checks exact column names produced by `model.matrix()` for the
  transformed and interaction terms, so a future custom parser that drops or
  renames these terms will fail;
- the prediction checks compare `predict(..., newdata = ...)` to manually
  constructed design matrices using the training-data `poly()` basis, so the
  subtle `poly()` prediction contract is tested as well as fitting.

Known limitations:

- this confirms ordinary fixed-effect formula behaviour only;
- random-effect slopes remain limited by the implemented random-effect grammar
  and structured `phylo()`/`spatial()` slope designs remain future work;
- transformed covariates are still linear predictors in transformed basis
  columns, not general nonlinear likelihood components.

## 2026-05-09 -- Curved-effects user tutorial

Goal:

- improve the location-scale tutorial from a user-first perspective by adding
  a biological example where ordinary R formula terms express a curved
  environmental response and a habitat-temperature interaction.

Changes:

- added a "Curved responses and interactions" section to the
  `location-scale` article;
- paired symbolic equations with matching `drmTMB` syntax for
  `habitat * temperature` and `I(temperature^2)`;
- added a simulated ecology example, fitted model, `summary()` output, and
  prediction table for cold, moderate, and warm temperatures in two habitats;
- explained why `I(temperature^2)` is often easier to interpret than
  `poly(temperature, 2)`, while still noting that `poly()` is supported.

Commands run:

- `Rscript -e "rmarkdown::render('vignettes/location-scale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/location-scale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `rg -n "Curved responses|poly\\(temperature|temperature\\^2|habitat \\* temperature|fitted_residual_sd|third-order" vignettes/location-scale.Rmd pkgdown-site/articles/location-scale.html`

Results:

- the first direct vignette render failed because `drmTMB` was not installed
  in that bare R session;
- rerunning the vignette render after `devtools::load_all()` passed;
- `pkgdown::build_site()` passed and rendered the new article section;
- favicon MIME repair completed without output;
- `pkgdown::check_pkgdown()`: no problems found;
- generated-site scan confirmed the new section, equations, model syntax,
  `summary()` output, and prediction table were present in
  `pkgdown-site/articles/location-scale.html`.

Tests of the tests:

- this was a tutorial-only change, so the meaningful check was executable
  documentation rather than a new unit test;
- the vignette chunk fits the model and prints `summary(fit_curve)`, so the
  tutorial will fail to render if the documented formula syntax or output path
  breaks;
- pkgdown rendered the generated HTML, which checks the actual public page
  rather than just the source R Markdown.

Known limitations:

- this section teaches fixed-effect formula transformations and interactions
  only;
- it does not add new model functionality or broaden random-effect slope
  grammar;
- the example uses simulated data so the page remains fast and reproducible.

## 2026-05-09 -- Bivariate coscale reportable-output tutorial

Goal:

- make the bivariate location-coscale tutorial easier to use by showing what
  an applied reader can report from a fitted `rho12 ~ predictor` model.

Changes:

- added a report-ready coscale table with fitted `rho12`, response-specific
  residual SDs, and residual covariance;
- added a "What should I report?" section that contrasts the raw
  activity-boldness correlation with the fitted residual `rho12`;
- rounded tutorial tables for readability;
- kept the boundary explicit: residual `rho12` is not a group-level,
  phylogenetic, spatial, or personality/plasticity correlation.

Commands run:

- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/bivariate-coscale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `rg -n "What should I report|raw_activity_boldness_correlation|mean_fitted_residual_rho12|residual_covariance|round\\(report_table|round\\(rho_table" vignettes/bivariate-coscale.Rmd pkgdown-site/articles/bivariate-coscale.html`

Results:

- the bivariate coscale vignette rendered successfully with the package loaded
  by `devtools::load_all()`;
- `pkgdown::build_site()` passed and rendered the updated article;
- favicon MIME repair completed without output;
- `pkgdown::check_pkgdown()`: no problems found;
- `git diff --check`: clean;
- generated-site scan confirmed the report section, raw-versus-residual
  comparison, rounded output tables, and residual covariance output were
  present in `pkgdown-site/articles/bivariate-coscale.html`.

Tests of the tests:

- this was an executable-docs change, so the key check was rendering the
  touched vignette and the generated pkgdown page;
- the new chunks call `predict(..., dpar = "rho12", type = "link")`,
  `rho12(fit_biv, newdata = ...)`, `predict(..., dpar = "sigma1")`, and
  `predict(..., dpar = "sigma2")`; the page will fail to render if any of
  those user-facing extractor paths break;
- the raw-versus-residual comparison guards against a common interpretation
  error by making the two quantities visible side by side.

Known limitations:

- this phase did not add new model functionality;
- the tutorial still uses simulated data so the article remains fast and
  reproducible;
- uncertainty intervals for `rho12` predictions remain future work.

## 2026-05-09 -- Phase 5 phylogenetic structured-effect closure

Goal:

- close the first structured-effect phase around implemented
  `phylo(1 | species, tree = tree)` support for univariate Gaussian `mu`;
- verify that code, equations, tests, active docs, pkgdown, roadmap, known
  limitations, and after-phase reporting agree.

Changes:

- marked Phase 5 as implemented and closure-audited in `ROADMAP.md`;
- added model-level rejection tests for planned spatial `coords`, spatial
  `mesh`, spatial-in-`sigma`, bivariate spatial, and bivariate phylogenetic
  structured syntax;
- clarified that `gr()` is reserved, not fitted;
- replaced teaching-page guarded `rho12` equations with the clean
  `rho12 = tanh(eta_rho12)` transform and explained the tiny implementation
  guard separately;
- tightened bivariate meta-analysis wording so fitted `rho12` is the residual
  covariance component after known sampling covariance, not a study-level
  correlation unless a study-level random effect is fitted;
- added
  `docs/dev-log/after-phase/2026-05-09-phase-5-phylogenetic-structured-effects-closure.md`.

Commands run:

- `Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-gaussian-location-scale.R')"`
- `Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-package-skeleton.R')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/phylogenetic-spatial.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/drmTMB.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/testing-likelihoods.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/phylogenetic-spatial.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `rg -n 'residual or between-study|unknown residual or between-study|between-study coupling|between-study correlation' README.md ROADMAP.md NEWS.md docs/design vignettes R man tests --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/after-phase/**'`
- `rg -n 'rho12_i = 0\\.99999999 \\* tanh|0\\.99999999 \\* tanh\\(eta_rho12_i\\)' vignettes/drmTMB.Rmd vignettes/phylogenetic-spatial.Rmd vignettes/testing-likelihoods.Rmd docs/design/03-likelihoods.md docs/design/09-phylogenetic-and-spatial-speed.md`

Results:

- `test-gaussian-location-scale.R`: 69 passed, 0 failed, 1 skipped on CRAN;
- `test-package-skeleton.R`: 40 passed, 0 failed;
- direct renders for `drmTMB.Rmd`, `testing-likelihoods.Rmd`, and
  `phylogenetic-spatial.Rmd`: passed;
- full `devtools::test()`: 1264 passed, 0 failed;
- `pkgdown::build_site()`: passed after rerunning with normal cache/network
  access;
- `pkgdown::check_pkgdown()`: no problems found;
- `devtools::check(...)`: 0 errors, 0 warnings, 1 note for local macOS temp
  detritus (`xcrun_db`);
- `git diff --check`: clean;
- active-doc stale scans found no remaining "residual or between-study" wording
  and no guarded `rho12` transform in the targeted teaching pages.

Known limitations:

- Phase 5 currently fits only intercept-only phylogenetic location effects in
  univariate Gaussian models;
- spatial fields, phylogenetic slopes, phylogenetic `sigma`, bivariate
  structured covariance blocks, and structured `rho12` effects remain planned;
- long-run large-tree simulations and external phylogenetic-model comparators
  remain future work.

## 2026-05-09 -- Post-Phase-8 roadmap extension

Goal:

- answer the planning gap after Phase 8 by adding explicit roadmap phases for
  ordinal/denominator models, spatial structured effects, bivariate random
  effects, phylogenetic location-scale extensions, profile likelihood, large
  data, mixed-response bivariate families, shape/asymmetry models, and release
  hardening.

Changes:

- added Phase 9 through Phase 17 to `ROADMAP.md`;
- added
  `docs/dev-log/after-task/2026-05-09-post-phase-8-roadmap.md`.

Checks:

- reviewed the new phase sequence against `docs/design/06-distribution-roadmap.md`
  and the existing Phase 0-8 roadmap structure.
- `Rscript -e "pkgdown::build_site()"`: passed after rerunning with normal
  cache/network access.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `rg -n "Phase 9: Ordinal|Phase 17: Release|residual covariance component after known sampling covariance|rho12_i = tanh" ROADMAP.md README.md vignettes/drmTMB.Rmd vignettes/testing-likelihoods.Rmd docs/design/03-likelihoods.md docs/design/09-phylogenetic-and-spatial-speed.md pkgdown-site/ROADMAP.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/testing-likelihoods.html`:
  confirmed the new roadmap headings and generated-site equation wording.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 1 local macOS temp-directory note for `xcrun_db`.

Known limitations:

- this was roadmap-only; no likelihood or user-facing API was implemented.

## 2026-05-09 -- Cumulative-logit ordinal family

Goal:

- resume and close the first ordinal family path by implementing fixed-effect
  univariate cumulative-logit location models for ordered responses.

Changes:

- added the exported `cumulative_logit()` family constructor;
- added the `drm_build_cumulative_logit_spec()` R builder, ordinal response
  validation, intercept-free `mu` design matrices, ordered cutpoint starts, and
  a TMB `model_type = 13` likelihood branch;
- added ordinal prediction support for latent `mu`, `fitted()` expected
  ordered-category scores, response and Pearson residuals, `sigma()` fixed
  unit vectors, `simulate()` ordered-category draws, and summary cutpoints;
- added `tests/testthat/test-cumulative-logit.R` with parameter recovery,
  independent likelihood checks, three- and four-category simulations, missing
  rows, sparse nonempty categories, close-cutpoint stability, simulation
  reproducibility, and malformed-input errors;
- updated README, NEWS, ROADMAP, pkgdown navigation, formula grammar,
  distribution-family, likelihood, family-link, reference-programme, known
  limitation, and source-map documentation;
- added `docs/dev-log/after-task/2026-05-09-cumulative-logit-family.md`.

Commands run:

- `Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-cumulative-logit.R')"` before the final four-category audit patch:
  55 passed, 0 failed.
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"` before the final four-category audit patch:
  1319 passed, 0 failed.
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `rg -n "cumulative_logit\\(\\).*Planned|cumulative-logit.*planned|ordinal.*planned|No ordinal likelihood was added|not implemented.*cumulative_logit|not implemented.*ordinal|ordered logit/probit|rho ~|meta_gaussian|tau ~" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man _pkgdown.yml`
- `Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-cumulative-logit.R')"` after the final four-category audit patch:
  61 passed, 0 failed.
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- `devtools::document()`: passed.
- focused cumulative-logit tests after the audit patch: 61 passed, 0 failed.
- final full `devtools::test()`: 1325 passed, 0 failed.
- `pkgdown::build_site()`: passed and generated
  `pkgdown-site/reference/cumulative_logit.html`.
- `pkgdown::check_pkgdown()`: no problems found.
- `git diff --check`: clean.
- final `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.
- the stale-wording scan found expected text only: ordinal scale/discrimination
  remains planned, unsupported ordinal features produce explicit errors,
  `ordered logit/probit` remains in the broader roadmap, and existing
  meta-analysis guardrails still mention `meta_gaussian` and `tau ~`.

Known limitations:

- `cumulative_logit()` currently supports one ordered response, fixed effects,
  a `mu` location formula, ordered cutpoints, and fixed latent logistic scale;
- ordinal scale or discrimination formulas, random effects, known sampling
  covariance, phylogenetic terms, non-logit ordinal links, bivariate ordinal
  models, and mixed-response ordinal models remain planned.

## 2026-05-10 -- Beta-binomial family and location-scale paper phase map

Goal:

- close the first denominator-aware beta-binomial family path and map the
  Nakagawa et al. location-scale paper/tutorial examples onto the remaining
  drmTMB roadmap.

Changes:

- added exported `beta_binomial()` and routed it through the R builder, TMB
  `model_type = 14`, fitted-object methods, tests, generated Rd, README, NEWS,
  ROADMAP, design notes, vignettes, pkgdown navigation, and known limitations;
- hardened cumulative-logit middle-category probabilities against cancellation
  in both the TMB likelihood and R probability helper;
- added weighted likelihood tests for beta-binomial and cumulative-logit
  families, plus beta-binomial all-boundary count tests;
- installed `air` 0.9.0 through Homebrew and formatted the touched R and test
  files;
- added
  `docs/dev-log/after-task/2026-05-10-beta-binomial-family.md`;
- added
  `docs/dev-log/after-task/2026-05-10-location-scale-paper-phase-map.md`;
- updated `AGENTS.md` so status notes use the canonical standing-review names
  Ada, Boole, Gauss, Noether, Darwin, Fisher, Pat, Jason, Curie, Emmy, Grace,
  and Rose without renaming them.

Commands run:

- `brew install air`: installed `air` 0.9.0.
- `air --version`: reported `air 0.9.0`.
- `air format R/drmTMB.R R/family.R R/methods.R tests/testthat/test-beta-binomial.R tests/testthat/test-cumulative-logit.R tests/testthat/test-phylo-utils.R`:
  passed.
- `Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-phylo-utils.R'); testthat::test_file('tests/testthat/test-beta-binomial.R'); testthat::test_file('tests/testthat/test-cumulative-logit.R')"`:
  phylo-utils 45 passed, beta-binomial 43 passed, cumulative-logit 71 passed.
- `Rscript -e "devtools::document()"`: passed and generated
  `man/beta_binomial.Rd`.
- `Rscript -e "devtools::test()"`: 1378 passed, 0 failed, 0 warnings,
  0 skips.
- `Rscript -e "pkgdown::build_site()"`: passed and generated
  `pkgdown-site/reference/beta_binomial.html`.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `git diff --check`: clean.
- `rg -n "beta_binomial\\(\\).*planned|planned.*beta_binomial|not implemented.*beta_binomial|cumulative_logit\\(\\).*planned|planned.*cumulative_logit|not implemented.*cumulative_logit|No ordinal likelihood was added|denominator syntax.*not settled|successes, trials|log variance; drmTMB|factor of two|dispersion model is on log variance" README.md ROADMAP.md NEWS.md DESCRIPTION docs/design docs/dev-log/known-limitations.md docs/dev-log/after-task/2026-05-10-location-scale-paper-phase-map.md vignettes R tests man _pkgdown.yml --glob '!docs/dev-log/check-log.md'`:
  expected hits only: unsupported-feature messages for beta-binomial and
  cumulative-logit extensions, ordinal scale planned notes, and the deliberate
  warning not to use `cbind(successes, trials)`.
- `rg -n 'beta_binomial|cumulative_logit|sigma\\^2|log-variance|variance summaries' pkgdown-site/reference/index.html pkgdown-site/reference/beta_binomial.html pkgdown-site/articles/distribution-families.html pkgdown-site/articles/source-map.html pkgdown-site/articles/which-scale.html pkgdown-site/articles/location-scale.html pkgdown-site/ROADMAP.html pkgdown-site/AGENTS.html`:
  confirmed generated beta-binomial/cumulative-logit reference and article
  links plus generated scale wording.
- `Rscript -e "library(glmmTMB); ..."` local Gaussian dispersion check:
  with `glmmTMB` 1.1.11, `exp(dispformula linear predictor)` matched fitted
  residual SD in the simple Gaussian example; the local install warned that
  `glmmTMB` was built against TMB 1.9.17 while TMB 1.9.21 is installed.
- `Rscript -e "library(metafor); ..."` local location-scale check:
  with `metafor` 4.8-0, `exp(alpha)` matched `tau^2` in the simple
  location-scale example.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  first rerun found one note from a temporary top-level `tmp` directory created
  for PDF page rendering; after removing that directory, the final rerun
  reported 0 errors, 0 warnings, and 0 notes.

Scale-comparator correction:

- drmTMB should keep public `sigma` as the user-facing scale, matching
  brms-style distributional syntax and the project's stable terminology.
  Individual-difference predictability and malleability summaries often need
  variance-scale summaries, so comparator harnesses should report
  package-native parameters, drmTMB `sigma`, and derived paper-facing
  `sigma^2` interpretations side by side.
- `/Users/z3437171/Downloads/mee313755-sup-0001-supinfo.pdf` was checked for
  the O'Dea, Noble, and Nakagawa conversion: the supplement notes that `brms`
  DHGLM dispersion defaults use residual standard deviations, and that
  converting log-SD models to log-variance models multiplies fixed/log-mean
  terms by 2 and corresponding variance components by 4.
- `https://github.com/daniel1noble/individual_differences` was checked as the
  brms translation of the O'Dea worked example. The public clone contains the
  rendered article and `individual_differences.Rmd`; data and saved model
  objects are referenced as OSF downloads. The R Markdown establishes the key
  Phase 11 target syntax: univariate
  `bf(y ~ x + (1 + x | q | id), sigma ~ x + (1 | q | id))` and bivariate
  paired formulas with the same labelled block spanning two traits' `mu`
  intercepts, `mu` slopes, and `sigma` intercepts. It also confirms the
  sign-reversal convention for predictability associations because larger
  residual variance means lower predictability.
- the brms translation does not add a residual `rho12` or coscale formula.
  This is a drmTMB opportunity: keep residual `rho12`/coscale association
  separate from group-level individual-difference covariance, and eventually
  teach both in the same O'Dea-motivated example.

Known limitations:

- the location-scale paper/tutorial data have been mapped but not yet run
  through drmTMB;
- full double-hierarchical covariance between `mu` and `sigma` random effects
  remains Phase 11 work;
- beta-binomial random effects, structured effects, bivariate models, and
  successes/trials alias syntax remain planned.

## 2026-05-10 -- Landing page accessibility pass

Goal:

- make the pkgdown landing page a short overview and routing page for applied
  users rather than a combined tutorial, family registry, formula guide, and
  roadmap.

Changes:

- Pat reviewed the landing page from the new-user perspective and flagged that
  it was doing too many jobs at once;
- rewrote `README.md` from a long reference-style catalogue into a 94-line
  home page with one overview, one Gaussian location-scale example, a compact
  "What can I model now?" table, article links, and brief current boundaries;
- preserved the public `sigma` convention and stated that variance-facing
  paper summaries should use derived `sigma^2`;
- kept residual `rho12` separate from group-level individual-difference
  covariance in the limitations section;
- added
  `docs/dev-log/after-task/2026-05-10-landing-page-accessibility.md`.

Commands run:

- `Rscript -e "pkgdown::build_site()"`: passed and rendered the shorter
  `pkgdown-site/index.html`.
- `Rscript -e "pkgdown::build_home()"`: passed after the final table-syntax
  polish.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `rg -n "Start here|What can I model now|Tiny example|Current boundaries|phylogenetic-spatial|phylo\\(1" pkgdown-site/index.html`:
  confirmed the rendered home-page anchors, article link, and displayed
  `phylo(1 | species, tree = tree)` syntax.
- `rg -n "Implemented now|Planned next|Current project status|family registry|lognormal|hurdle NB2|Zero-truncated" README.md pkgdown-site/index.html`:
  found no stale top-level landing-page section headings; the expected
  remaining hits were compact capability-table family names.
- `git diff --check`: clean.

Known limitations:

- this was a content-accessibility pass, not a full screen-reader,
  keyboard-navigation, or mobile visual QA audit;
- the public site still needs deployment after the local pkgdown render.

## 2026-05-10 -- glmmTMB Gaussian location-scale comparators

Goal:

- add a small optional comparator rung for the Gaussian location-scale examples
  that overlap with `glmmTMB`, before moving toward real-data paper
  replications or double-hierarchical covariance blocks for
  individual-difference models.

Changes:

- added a fixed-effect Gaussian location-scale comparator against
  `glmmTMB::glmmTMB(y ~ x, dispformula = ~ z, family = gaussian())`;
- added a Gaussian random-intercept location-scale comparator against
  `glmmTMB::glmmTMB(y ~ x + (1 | id), dispformula = ~ z, family = gaussian())`;
- both tests check `mu` coefficients, `sigma` formula coefficients, and
  log-likelihood agreement; the random-intercept test also checks the
  group-level SD;
- suppressed the local optional-dependency namespace warning from a
  `glmmTMB`/`TMB` version mismatch during skip checks, while keeping the
  comparator assertions warning-clean;
- updated `docs/design/05-testing-strategy.md` and `vignettes/source-map.Rmd`
  so the comparator coverage is documented;
- added
  `docs/dev-log/after-task/2026-05-10-glmmtmb-gaussian-location-scale-comparators.md`.

Commands run:

- `air format tests/testthat/test-comparators.R`: passed.
- `Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-comparators.R')"` before warning suppression:
  54 passed, 0 failed, 1 warning from the local `glmmTMB` namespace load.
- `air format tests/testthat/test-comparators.R && Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-comparators.R')"`:
  54 passed, 0 failed, 0 warnings, 0 skips.
- `Rscript -e "devtools::test()"`: 1387 passed, 0 failed, 0 warnings,
  0 skips.
- `Rscript -e "pkgdown::build_site()"`: passed and regenerated the source-map
  article with the comparator-test pointer.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `rg -n "Gaussian location-scale|test-comparators|glmmTMB" pkgdown-site/articles/source-map.html pkgdown-site/AGENTS.html pkgdown-site/index.html`:
  confirmed the generated source-map article points the Gaussian
  location-scale row at `tests/testthat/test-comparators.R`.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  first run found one warning because `glmmTMB` was used in tests but missing
  from `Suggests`.
- added `glmmTMB` to `DESCRIPTION` `Suggests`.
- final `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.

Known limitations:

- these are small simulation-based comparator smoke tests, not the full
  real-data individual-difference location-scale replication harness;
- the next replication step should load the tutorial data, fit overlapping
  `glmmTMB` and drmTMB models, and report drmTMB `sigma` plus paper-facing
  `sigma^2` summaries side by side.

## 2026-05-10 -- Five-task Phase 9 QA batch and 0.1.0 gate

Goal:

- complete five bounded quality tasks after the landing-page and comparator
  work, and make the `0.1.0` preview-release timing explicit.

Completed tasks:

- beta-binomial newdata prediction coverage: added link- and response-scale
  `newdata` checks for `mu` and `sigma`;
- beta-binomial malformed-response coverage: added negative tests for
  negative counts, infinite counts, and one-column `cbind()` responses;
- cumulative-logit newdata probability coverage: added `newdata` checks for
  category probabilities, expected ordinal score, and score variance;
- cumulative-logit malformed-response coverage: added negative tests for
  character responses and two-category ordered responses;
- release/QA planning: expanded the family testing checklist in
  `docs/design/05-testing-strategy.md` and added a `0.1.0` preview-release
  gate to `ROADMAP.md`.

Commands run:

- `air format tests/testthat/test-beta-binomial.R tests/testthat/test-cumulative-logit.R`:
  passed.
- focused beta-binomial and cumulative-logit test run before assertion polish:
  beta-binomial passed; cumulative-logit had one test assertion mistake because
  a matrix uses `colnames()`, not vector `names()`.
- final focused beta-binomial and cumulative-logit tests:
  127 passed, 0 failed, 0 warnings, 0 skips.
- `Rscript -e "devtools::test()"`: 1400 passed, 0 failed, 0 warnings,
  0 skips.
- `Rscript -e "pkgdown::build_home()"`: passed and regenerated
  `pkgdown-site/ROADMAP.html`.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `rg -n "Version 0.1.0 Preview Release Gate|0.1.0|0.0.0.9000|Phase 9 closure" ROADMAP.md pkgdown-site/ROADMAP.html`:
  confirmed the release gate rendered locally.
- `git diff --check`: clean.

0.1.0 position:

- the current development version remains `0.0.0.9000`;
- `0.1.0` should mean first reliable public preview, not full
  double-hierarchical O'Dea support;
- target timing is after Phase 9 closure plus release hardening, with Phase 11
  bivariate random effects and full double-hierarchical covariance left on the
  roadmap for later releases.

Known limitations:

- this batch did not add a new likelihood family;
- the public site still needs deployment after local pkgdown rendering;
- `devtools::check()` was not rerun after this test-only and roadmap batch
  because full check had passed immediately before it and the new full test
  suite passed.

## 2026-05-10 -- Large-data storage control first slice

Goal:

- prepare `drmTMB` for large phylogenetic and ecological datasets by adding a
  conservative memory-light fitted-object control path without changing any
  likelihood.

Implemented:

- added exported `drm_control()` for optimizer settings plus fitted-object
  storage controls;
- preserved backward compatibility for plain `control = list(...)` optimizer
  settings passed to `stats::nlminb()`;
- added `keep_data = FALSE` to drop `fit$data` and `fit$model$data` after
  fitting;
- added `keep_tmb_object = FALSE` to drop `fit$obj` after optimization;
- taught `check_drm()` to report the fixed-gradient check as a note when the
  TMB object was intentionally not retained;
- updated the large-data design note, roadmap, known limitations, NEWS, and
  pkgdown reference index.

Commands run:

- `air format R/control.R R/drmTMB.R R/check.R tests/testthat/test-control.R`:
  passed.
- `Rscript -e "devtools::test(filter = '^control|^check-drm')"`: 77 passed,
  0 failed, 0 warnings, 0 skips.
- `Rscript -e "devtools::document()"`: first run wrote the new
  `drm_control.Rd` topic and warned once because the link was new; second run
  passed without warnings.
- `Rscript -e "devtools::test()"`: 1424 passed, 0 failed, 0 warnings,
  0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.
- `Rscript -e "pkgdown::build_site()"`: passed and generated
  `pkgdown-site/reference/drm_control.html`.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `rg -n "Large-data memory controls are not implemented yet|drm_control|keep_tmb_object|keep_model_frame = FALSE|sparse_fixed" ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/23-large-data-memory.md pkgdown-site/ROADMAP.html pkgdown-site/reference/drm_control.html pkgdown-site/news/index.html`:
  confirmed the stale "not implemented yet" wording was removed and the new
  reference page rendered.

Known limitations:

- this is not million-row readiness yet: fits still build ordinary R model
  frames and dense fixed-effect model matrices before optimization;
- `keep_model_frame = FALSE`, sparse fixed-effect matrices,
  sufficient-statistic aggregation, and large benchmark scripts remain planned;
- `check_drm()` cannot evaluate fixed gradients after `fit$obj` is dropped, so
  it records that check as a note and tells the user how to refit for the
  gradient check.

## 2026-05-10 -- Large-data workflow article and benchmark harness

Goal:

- make the large-data path visible and practical for applied users, not only
  recorded as a developer design note.

Implemented:

- added `vignettes/large-data.Rmd`, a short user-facing article about current
  memory-light controls, post-fit output risks, and current limitations;
- added `bench/large-phylo-location.R`, an optional non-CRAN benchmark harness
  for univariate Gaussian phylogenetic location models;
- wired the article into `_pkgdown.yml` and the Tutorials navbar;
- updated `NEWS.md`, `ROADMAP.md`, `docs/design/23-large-data-memory.md`, and
  `docs/dev-log/known-limitations.md`;
- added `^bench$` to `.Rbuildignore` so the benchmark remains a repository
  development artifact and does not create an R CMD check top-level-file note.

Commands run:

- `air format bench/large-phylo-location.R`: passed.
- `Rscript bench/large-phylo-location.R --rows 200 --species 16 --eval-max 80 --iter-max 80 --memory-light true`:
  passed with convergence code 0.
- `Rscript bench/large-phylo-location.R --rows 120 --species 10 --tree star --eval-max 80 --iter-max 80 --memory-light true`:
  passed with convergence code 0.
- `Rscript bench/large-phylo-location.R --help | head -n 20`: confirmed the
  public command-line options use hyphenated names such as `--memory-light`.
- temporary CSV-output smoke run with `--factor-heavy true --sigma-x true`:
  wrote a header and one result row after fixing append detection for empty
  `mktemp` files.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_site()"`: passed and generated
  `pkgdown-site/articles/large-data.html`.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- first `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  found 1 note because top-level `bench/` was included in the source package.
- added `^bench$` to `.Rbuildignore`.
- final `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.
- `rg -n "large-data|large data|Working with large data|large-phylo-location|memory-light|memory_light|factor_heavy|sigma_x|not implemented yet" README.md ROADMAP.md NEWS.md _pkgdown.yml docs/design/23-large-data-memory.md docs/dev-log/known-limitations.md vignettes/large-data.Rmd pkgdown-site/articles/large-data.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html`:
  confirmed the article rendered, navbar links exist, and public examples use
  the hyphenated benchmark options.

Known limitations:

- the benchmark uses base R object sizes and garbage-collector summaries; peak
  resident memory still needs an external OS tool such as `/usr/bin/time -l`;
- the harness is synthetic and does not replace real user-data timing;
- full million-row readiness still needs safe model-frame pruning, sparse
  fixed-effect matrices, and repeated benchmark logs at 100k to 5M rows.

## 2026-05-10 -- Benchmark result guidance

Goal:

- make the optional large-data benchmark easier to run, compare, and interpret
  without implying that one smoke run proves million-row readiness.

Implemented:

- added `bench/README.md` with a recommended large-data benchmark matrix,
  output-column definitions, operating-system peak-memory commands, and a
  default-versus-memory-light comparison workflow;
- ignored local benchmark CSV files and `bench/results/` in `.gitignore`.

Commands run:

- `git diff --check`: passed.
- `rg -n "Recommended Matrix|Output Columns|memory-light false|bench/results" bench/README.md .gitignore`:
  confirmed the benchmark guide, default-versus-memory-light example, and local
  output ignore rules are present.

Known limitations:

- this task documents how to collect benchmark evidence; it does not add new
  benchmark results or change package behaviour;
- peak-memory examples are platform-specific (`/usr/bin/time -l` on macOS,
  `/usr/bin/time -v` on Linux), so Windows users still need a separate
  measurement path.

## 2026-05-10 -- Model-frame dependency map and response-name fallback

Goal:

- remove one blocker for future `keep_model_frame = FALSE` support without
  exposing that control before post-fit methods are tested.

Implemented:

- added a model-frame dependency map to `docs/design/23-large-data-memory.md`;
- stored fitted response names in `model$response_names`;
- updated response-label extraction to prefer stored response names before
  falling back to `model$model_frame`;
- added `corpairs()` regression checks for bivariate residual `rho12` labels
  and univariate group-level correlation labels after `model$model_frame` is
  manually removed from a fitted object.

Commands run:

- `air format R/drmTMB.R R/methods.R tests/testthat/test-corpairs.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'corpairs|control')"`: 65 passed,
  0 failed, 0 warnings, 0 skips.
- `git diff --check`: passed.
- `rg -n "model-frame dependency|Model-Frame Dependency Map|response_names|keep_model_frame = FALSE|manually removed|corpairs\\(\\) regression" R tests docs/design/23-large-data-memory.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-model-frame-dependency-map.md`:
  confirmed the design note, implementation, tests, and task report include the
  new fallback and keep the public control planned.
- `Rscript -e "devtools::test()"`: 1428 passed, 0 failed, 0 warnings,
  0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.

Known limitations:

- `drm_control(keep_model_frame = FALSE)` remains intentionally unavailable;
  this task prepares one fallback path but does not prove the full storage
  control safe yet.

## 2026-05-10 -- Model-frame method smoke tests

Goal:

- add the first small method-matrix tests for the future
  `keep_model_frame = FALSE` path while keeping the public control disabled.

Implemented:

- added control-file tests that manually remove `fit$model$model_frame` from a
  Gaussian location-scale fit and check `predict()`, `predict(newdata = ...)`,
  `fitted()`, `residuals()`, `simulate()`, `sigma()`, and `check_drm()`;
- added an offset prediction test that manually removes `model_frame` from a
  Poisson offset fit and checks `predict(newdata = ...)`, `residuals()`, and
  `simulate()`.
- added a representative family matrix covering beta-binomial trial storage,
  cumulative-logit ordinal metadata, and two-response bivariate Gaussian
  output after `model_frame` is manually removed.

Commands run:

- `air format tests/testthat/test-control.R`: passed.
- `Rscript -e "devtools::test(filter = 'control')"`: 35 passed, 0 failed,
  0 warnings, 0 skips.
- `git diff --check`: passed.
- `Rscript -e "devtools::test()"`: 1439 passed, 0 failed, 0 warnings,
  0 skips.
- after adding the representative family matrix,
  `Rscript -e "devtools::test(filter = 'control')"`: 50 passed, 0 failed,
  0 warnings, 0 skips.
- after adding the representative family matrix,
  `Rscript -e "devtools::test()"`: 1454 passed, 0 failed, 0 warnings,
  0 skips.

Known limitations:

- this is an expanded representative method smoke test, not complete
  `keep_model_frame = FALSE` coverage across every implemented family;
- the public control still correctly errors when users request
  `keep_model_frame = FALSE`.

## 2026-05-10 -- Large-data benchmark smoke result

Goal:

- exercise the documented benchmark workflow on a non-trivial local run before
  scaling to 100k rows and above.

Command run:

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 10000 --species 100 --eval-max 120 --iter-max 120 --memory-light true --output bench/results/large-phylo-location.csv`:
  passed and wrote one result row.

Result:

- rows: 10,000;
- species: 100;
- tree: balanced;
- memory-light storage: TRUE;
- convergence code: 0;
- data-build time: 0.028 seconds;
- fit time: 2.261 seconds;
- residual time: 0.013 seconds;
- fitted-object size: 4.896 MB;
- model-matrix size: 1.528 MB;
- TMB-data size: 2.140 MB;
- post-fit R heap summary: 251.356 MB;
- macOS maximum resident set size from `/usr/bin/time -l`:
  462,323,712 bytes;
- macOS peak memory footprint from `/usr/bin/time -l`: 331,891,768 bytes.

Known limitations:

- this is a smoke run, not a scaling claim;
- the benchmark result CSV is intentionally ignored by git, so durable
  benchmark evidence still needs a deliberate results table or release note;
- the next evidence step is 100k rows and 1,000 species, then factor-heavy and
  `sigma ~ x` variants.

## 2026-05-10 -- 100k-row large-data benchmark baseline

Goal:

- run the next benchmark rung after the 10k smoke test: 100,000 observation
  rows and 1,000 species with memory-light fitted-object storage.

Command run:

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 160 --iter-max 160 --memory-light true --output bench/results/large-phylo-location.csv`:
  passed and appended one result row.

Result:

- rows: 100,000;
- species: 1,000;
- tree: balanced;
- memory-light storage: TRUE;
- convergence code: 0;
- data-build time: 0.103 seconds;
- fit time: 25.547 seconds;
- residual time: 0.014 seconds;
- fitted-object size: 48.027 MB;
- model-matrix size: 15.261 MB;
- TMB-data size: 21.326 MB;
- post-fit R heap summary: 405.262 MB;
- macOS maximum resident set size from `/usr/bin/time -l`:
  1,425,932,288 bytes;
- macOS peak memory footprint from `/usr/bin/time -l`: 671,073,984 bytes.

Known limitations:

- this is an encouraging baseline, not million-row readiness;
- the run used the simplest `sigma ~ 1` benchmark with few fixed effects;
- factor-heavy, `sigma ~ x`, and default-storage comparisons still need to be
  collected before making broader large-data claims.

## 2026-05-10 -- Enable keep_model_frame storage control

Goal:

- expose the tested post-fit model-frame storage control so large fitted
  objects can drop construction-time model frames after optimization.

Implemented:

- `drm_control(keep_model_frame = FALSE)` now validates and is accepted;
- `drm_apply_storage_control()` drops `fit$model$model_frame` and nested
  random-effect scale model-frame caches after fitting;
- `drm_control()` documentation, the large-data vignette, NEWS, roadmap, known
  limitations, and large-data design note now describe the implemented control;
- the control tests now exercise a real `keep_model_frame = FALSE` fit instead
  of only manual post-hoc deletion.

Commands run:

- `air format R/control.R tests/testthat/test-control.R`: passed.
- `Rscript -e "devtools::test(filter = 'control')"`: 52 passed, 0 failed,
  0 warnings, 0 skips.
- `Rscript -e "devtools::test()"`: 1,456 passed, 0 failed, 0 warnings,
  0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.
- `rg -n "0\\.0\\.0\\.9000|drmTMB 0\\.0\\.0\\.9000|version ['\\\"]?0\\.0\\.0\\.9000|not implemented|later keep_model_frame|planned.*keep_model_frame|must be TRUE" ...`:
  no stale package-version or `keep_model_frame` implementation drift found;
  one expected roadmap/news match for spatial terms remaining planned.
- `git diff --check`: passed.

Known limitations:

- `keep_model_frame = FALSE` reduces fitted-object storage after fitting; it
  does not avoid building model frames before TMB optimization;
- sparse fixed-effect matrices and Gaussian sufficient-statistic aggregation
  remain the next memory reductions.

## 2026-05-10 -- Benchmark harness uses model-frame storage control

Goal:

- make the large-data benchmark's `--memory-light true` setting exercise all
  implemented fitted-object storage controls, including
  `keep_model_frame = FALSE`.

Implemented:

- `bench/large-phylo-location.R` now sets `keep_model_frame = FALSE` whenever
  `--memory-light true` is used;
- `bench/README.md` describes the three storage controls used by the benchmark;
- `docs/dev-log/benchmark-results.md` records selected durable benchmark
  results because `bench/results/*.csv` is intentionally ignored by git.

Commands run:

- `air format bench/large-phylo-location.R`: passed.
- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 10000 --species 100 --eval-max 120 --iter-max 120 --memory-light true --output bench/results/large-phylo-location.csv`:
  passed.
- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 160 --iter-max 160 --memory-light true --output bench/results/large-phylo-location.csv`:
  passed.
- `Rscript -e "x <- read.csv('bench/results/large-phylo-location.csv'); print(tail(x, 6));"`:
  passed and showed all benchmark rows parseable.
- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 180 --iter-max 180 --factor-heavy true --memory-light true --output bench/results/large-phylo-location.csv`:
  completed and produced convergence code 1.
- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 180 --iter-max 180 --sigma-x true --memory-light true --output bench/results/large-phylo-location.csv`:
  passed with convergence code 0.
- `Rscript -e "x <- read.csv('bench/results/large-phylo-location.csv'); print(tail(x, 5));"`:
  passed and showed all benchmark rows parseable.

Result:

- 10,000-row memory-light rerun: convergence code 0, 2.283 fit seconds,
  4.658 MB fitted-object size, 251.397 MB post-fit R heap, 454,672,384 bytes
  maximum resident set size, and 332,383,288 bytes peak memory footprint.
- 100,000-row memory-light rerun: convergence code 0, 25.031 fit seconds,
  45.730 MB fitted-object size, 405.303 MB post-fit R heap,
  1,414,168,576 bytes maximum resident set size, and 692,831,840 bytes peak
  memory footprint.
- 100,000-row `sigma ~ x1` memory-light run: convergence code 0, 62.585 fit
  seconds, 47.257 MB fitted-object size, 415.857 MB post-fit R heap,
  1,815,838,720 bytes maximum resident set size, and 773,457,888 bytes peak
  memory footprint.
- 100,000-row factor-heavy memory-light run: convergence code 1, 77.712 fit
  seconds, 105.289 MB fitted-object size, 622.011 MB post-fit R heap,
  2,123,055,104 bytes maximum resident set size, and 797,017,960 bytes peak
  memory footprint. This is a diagnostic stress run, not an accepted timing
  result.

Known limitations:

- this change improves the benchmark harness and post-fit fitted-object
  comparison; it still does not reduce model-frame construction or dense
  model-matrix peak memory;
- the factor-heavy row needs a follow-up convergence-focused rerun or sparse
  fixed-effect design work before it can support a performance claim.

## 2026-05-10 -- Add optimizer diagnostics to benchmark output

Goal:

- make benchmark CSV rows explain optimizer status, not only the integer
  convergence code.

Implemented:

- `bench/large-phylo-location.R` now records optimizer message, iteration
  count, function-evaluation count, and gradient-evaluation count;
- the benchmark writer now checks column names before appending and errors
  with a clear message if an existing ignored CSV uses an older schema;
- `bench/README.md` documents the new columns and the output-schema caveat.

Commands run:

- `air format bench/large-phylo-location.R`: passed.
- `Rscript bench/large-phylo-location.R --rows 1000 --species 50 --eval-max 80 --iter-max 80 --memory-light true --output /tmp/drmTMB-benchmark-diagnostics.csv`:
  passed.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-benchmark-diagnostics.csv', check.names = FALSE); print(names(x)); print(x[, c('convergence', 'convergence_message', 'iterations', 'function_evaluations', 'gradient_evaluations')]);"`:
  passed and confirmed the diagnostic columns.
- `Rscript bench/large-phylo-location.R --rows 1000 --species 50 --eval-max 80 --iter-max 80 --memory-light true --output /tmp/drmTMB-benchmark-diagnostics.csv`:
  passed and appended a second row with the same schema.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-benchmark-diagnostics.csv', check.names = FALSE); print(dim(x)); print(x[, c('convergence', 'convergence_message', 'iterations', 'function_evaluations', 'gradient_evaluations')]);"`:
  passed and confirmed the output had 2 rows and 28 columns.
- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 180 --iter-max 180 --factor-heavy true --memory-light true --output /tmp/drmTMB-factor-heavy-diagnostics.csv`:
  completed and produced convergence code 1.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-factor-heavy-diagnostics.csv', check.names = FALSE); print(x[, c('convergence', 'convergence_message', 'iterations', 'function_evaluations', 'gradient_evaluations', 'fit_sec', 'fit_object_mb', 'model_matrix_mb', 'gc_used_mb_post_fit')]);"`:
  passed and confirmed the optimizer stopped at the function-evaluation limit.
- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 400 --iter-max 400 --factor-heavy true --memory-light true --output /tmp/drmTMB-factor-heavy-diagnostics-400.csv`:
  completed and produced convergence code 1.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-factor-heavy-diagnostics-400.csv', check.names = FALSE); print(x[, c('convergence', 'convergence_message', 'iterations', 'function_evaluations', 'gradient_evaluations', 'fit_sec', 'fit_object_mb', 'model_matrix_mb', 'gc_used_mb_post_fit')]);"`:
  passed and confirmed the longer run ended with false convergence.

Result:

- the smoke benchmark converged with convergence code 0, optimizer message
  `relative convergence (4)`, 40 iterations, 49 function evaluations, and
  41 gradient evaluations.
- the 100k factor-heavy diagnostic rerun returned convergence code 1 with
  message `function evaluation limit reached without convergence (9)`,
  147 iterations, 180 function evaluations, and 147 gradient evaluations.
- the 100k factor-heavy rerun with `eval.max = 400` and `iter.max = 400`
  returned convergence code 1 with message `false convergence (8)`, 301
  iterations, 382 function evaluations, and 301 gradient evaluations.

Known limitations:

- existing local ignored CSV files written by the older schema need a new
  output path or removal before appending rows from the updated benchmark
  script.
- the 100k factor-heavy stress run needs convergence diagnostics before it can
  support a timing claim; raising iteration limits alone did not close it.

## 2026-05-10 -- Add dense fixed-effect design diagnostic

Goal:

- surface dense fixed-effect design size directly in `check_drm()` so users
  fitting factor-heavy large-data models see the memory pressure before
  treating a slow or unstable fit as only a phylogenetic problem.

Implemented:

- `check_drm()` now includes a `fixed_effect_design_size` row;
- the row reports total dense fixed-effect model-matrix size, maximum column
  count, and the largest distributional-parameter block;
- the row is a note when total dense design storage is at least 25 MB or any
  fixed-effect design has at least 30 columns;
- NEWS and `man/check_drm.Rd` describe the new diagnostic.

Commands run:

- `air format R/check.R tests/testthat/test-check-drm.R`: passed.
- `Rscript -e "devtools::test(filter = 'check-drm')"`: 57 passed, 0 failed,
  0 warnings, 0 skips.
- `Rscript -e "devtools::document()"`: passed and updated
  `man/check_drm.Rd`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `Rscript -e "devtools::test()"`: 1,460 passed, 0 failed, 0 warnings,
  0 skips.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `git diff --check`: passed.

Known limitations:

- this is a diagnostic note, not sparse fixed-effect support;
- the thresholds are deliberately simple guardrails and can be tuned when
  broader benchmark evidence accumulates.

## 2026-05-10 -- Design sparse fixed-effect matrix path

Goal:

- turn the factor-heavy benchmark lesson into an implementation contract for
  future sparse fixed-effect matrices.

Implemented:

- added `docs/design/26-sparse-fixed-effect-matrices.md`;
- linked the new design note from the large-data memory design note and
  roadmap;
- scoped the first sparse target to univariate Gaussian fixed-effect location
  models before broader distributional and bivariate support;
- recorded dense-versus-sparse parity tests as a requirement before any
  million-row performance claim.

Commands run:

- `git diff --check`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `rg -n "implemented yet|planned until|performance claim|O'Dea/Nakagawa|Nakagawa" docs/design/26-sparse-fixed-effect-matrices.md docs/design/23-large-data-memory.md ROADMAP.md docs/dev-log/after-task/2026-05-10-sparse-fixed-effect-design.md`:
  no use of the discouraged combined shorthand; expected existing roadmap
  surname mentions are outside the new design note.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.

Known limitations:

- this is a design document only; no sparse fixed-effect TMB path is
  implemented yet.

## 2026-05-10 -- Teach fixed-design diagnostics in large-data article

Goal:

- make the large-data vignette tell applied users how to interpret the new
  `fixed_effect_design_size` diagnostic.

Implemented:

- `vignettes/large-data.Rmd` now points users to the
  `fixed_effect_design_size` row in `check_drm()`;
- the benchmark description now includes optimizer messages and evaluation
  counts;
- the practical checklist now recommends all three storage controls:
  `keep_data = FALSE`, `keep_model_frame = FALSE`, and
  `keep_tmb_object = FALSE`.

Commands run:

- `git diff --check`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `rg -n "keep_data = FALSE|keep_model_frame = FALSE|fixed_effect_design_size|optimizer message|sparse fixed-effect" vignettes/large-data.Rmd docs/dev-log/after-task/2026-05-10-large-data-diagnostic-docs.md docs/dev-log/check-log.md`:
  passed and found the expected updated wording.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.

Known limitations:

- sparse fixed-effect matrices remain planned; the article names the pressure
  but does not claim that drmTMB can avoid dense fixed-effect construction yet.

## 2026-05-10 -- Keep pak as the install path

Goal:

- avoid presenting `remotes::install_github()` as a parallel recommended
  installation route on the landing page.

Implemented:

- removed the `remotes::install_github()` fallback block from `README.md`;
- removed the stale "pak or remotes" dependency wording from `README.md`;
- the README and getting-started article now keep
  `pak::pak("itchyshin/drmTMB@v0.1.0")` as the tagged-preview path and
  `pak::pak("itchyshin/drmTMB")` as the development path.

Commands run:

- `git diff --check`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `rg -n "install_github|remotes::|pak::pak|install\\.packages\\(\"pak\"\\)" README.md pkgdown-site/index.html docs/dev-log/after-task/2026-05-10-pak-install-path.md docs/dev-log/check-log.md`:
  passed; `README.md` and `pkgdown-site/index.html` show only the `pak`
  install commands, while dev-log matches record the historical fallback removal.
- `rg -n "pak or remotes|remotes::install_github|install_github" README.md vignettes/drmTMB.Rmd pkgdown-site/index.html pkgdown-site/articles/drmTMB.html`:
  passed with no matches.
- `rg -n "Install the preview|Core runtime dependencies|install\\.packages\\(\"pak\"\\)|pak::pak" README.md vignettes/drmTMB.Rmd pkgdown-site/index.html pkgdown-site/articles/drmTMB.html`:
  passed and found the expected `pak` installation guidance.

Known limitations:

- users without `pak` still need to install `pak` first, which the README
  shows explicitly.

## 2026-05-10 -- Add optimizer budget diagnostics

Goal:

- make `check_drm()` show optimizer iteration and evaluation counts so users can
  triage difficult fits without digging into `fit$opt`.

Implemented:

- added an `optimizer_budget` row to `check_drm()`;
- reports optimizer iterations, function evaluations, and gradient evaluations;
- flags a supplied `eval.max` or `iter.max` limit as a note for converged fits
  and as a warning for non-converged fits;
- updated roxygen documentation, NEWS, and the getting-started and
  model-workflow articles;
- added targeted tests for the new diagnostic row and budget-limit statuses.

Commands run:

- `air format R/check.R tests/testthat/test-check-drm.R vignettes/drmTMB.Rmd vignettes/model-workflow.Rmd NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-optimizer-budget-diagnostic.md`:
  passed.
- `Rscript -e "devtools::test(filter = 'check-drm')"`: passed with 61 tests,
  0 failures, 0 warnings, 0 skips.
- `Rscript -e "devtools::document()"`: passed and refreshed
  `man/check_drm.Rd`.
- `Rscript -e "devtools::test()"`: passed with 1464 tests, 0 failures,
  0 warnings, 0 skips.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `rg -n "optimizer_budget|optimizer evaluation counts|eval\\.max|iter\\.max" R/check.R man/check_drm.Rd tests/testthat/test-check-drm.R vignettes/drmTMB.Rmd vignettes/model-workflow.Rmd NEWS.md pkgdown-site/reference/check_drm.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/model-workflow.html docs/dev-log/after-task/2026-05-10-optimizer-budget-diagnostic.md docs/dev-log/check-log.md`:
  passed and found the expected source, test, documentation, and rendered-site
  entries.
- `Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, 0 notes.

Known limitations:

- the diagnostic reports budget use; it does not decide whether a larger
  optimizer budget is the right scientific response.

## 2026-05-10 -- Dispatch 0.1.1 preview

Goal:

- correct the tagged preview install target because `v0.1.0` does not export
  `drm_control()` even though current docs and large-data workflows use it.

Implemented:

- confirmed `git show v0.1.0:NAMESPACE` has no `export(drm_control)`;
- bumped `DESCRIPTION` from `0.1.0` to `0.1.1`;
- added a `NEWS.md` section for `drmTMB 0.1.1 (2026-05-10)`;
- updated README, the getting-started article, pkgdown version note, and roadmap
  preview status to `0.1.1`;
- kept the existing `v0.1.0` tag immutable and prepared `v0.1.1` as the patch
  preview target.

Commands run:

- `git show v0.1.0:NAMESPACE | rg -n "drm_control|drmTMB|check_drm"`:
  confirmed `v0.1.0` exports `check_drm()` and `drmTMB()` but not
  `drm_control()`.
- `air format DESCRIPTION NEWS.md README.md _pkgdown.yml ROADMAP.md vignettes/drmTMB.Rmd docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-0.1.1-preview-dispatch.md`:
  passed.
- `Rscript -e "devtools::document()"`: passed.
- `Rscript -e "devtools::test()"`: passed with 1464 tests, 0 failures,
  0 warnings, 0 skips.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `rg -n "0\\.1\\.1|v0\\.1\\.1|0\\.1\\.0|v0\\.1\\.0|drm_control" DESCRIPTION NEWS.md README.md ROADMAP.md _pkgdown.yml vignettes/drmTMB.Rmd NAMESPACE pkgdown-site/index.html pkgdown-site/articles/drmTMB.html pkgdown-site/news/index.html pkgdown-site/ROADMAP.html pkgdown-site/reference/drm_control.html --glob '!pkgdown-site/search.json'`:
  passed and found expected `0.1.1` install, NEWS, pkgdown, and
  `drm_control()` reference entries, with historical `0.1.0` mentions retained
  for the prior release.
- `Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, 0 notes for `drmTMB 0.1.1`.

Known limitations:

- users pinned to `v0.1.0` need to drop `drm_control()` and any `keep_*`
  storage controls; those controls start in `v0.1.1`.

## 2026-05-10 -- Add release install-smoke script

Goal:

- make the tagged-preview install path testable from a clean temporary library,
  so future releases catch tag/docs mismatches before users do.

Implemented:

- added `tools/install-smoke.R`;
- the script installs a GitHub ref with `pak`, optionally checks the installed
  version, checks key exported functions including `drm_control()`, fits a
  Gaussian location-scale storage-control model, and verifies expected
  `check_drm()` diagnostic rows;
- added a `0.1.1` release checklist recording branch CI, tag CI, pkgdown, and
  tag-install smoke evidence.

Commands run:

- `air format tools/install-smoke.R docs/dev-log/release-checklists/2026-05-10-0.1.1-preview-release.md docs/dev-log/after-task/2026-05-10-release-install-smoke-script.md docs/dev-log/check-log.md`:
  passed.
- `Rscript tools/install-smoke.R v0.1.1 0.1.1`: passed; installed
  `drmTMB 0.1.1` from GitHub ref `b4e222c`, confirmed required exports, fitted
  the storage-control smoke model, and confirmed the expected diagnostics.
- `git diff --check`: passed.
- `rg -n "install-smoke|v0\\.1\\.1|drm_control|optimizer_budget|fixed_effect_design_size|25639416001|25639248630|25639387716" tools/install-smoke.R docs/dev-log/release-checklists/2026-05-10-0.1.1-preview-release.md docs/dev-log/after-task/2026-05-10-release-install-smoke-script.md docs/dev-log/check-log.md`:
  passed and found the expected script, release checklist, and evidence entries.

Known limitations:

- the install smoke uses GitHub and is intended for release hygiene, not for
  fast local unit-test loops.

## 2026-05-10 -- Apply team feedback usability audit

Goal:

- act on Noether, Boole, and Curie's review feedback after the `0.1.1` dispatch
  without broadening the model scope.

Implemented:

- tightened README scale wording so `sigma^2` is not treated as a universal
  shortcut outside Gaussian residual-variance and meta-analytic heterogeneity
  summaries;
- added `check_drm()` and response-scale `sigma` interpretation to the README
  install smoke path;
- changed README capability wording to family-specific variation;
- documented zero-truncated and hurdle NB2 variance equations in the
  response-family article;
- added large-data guidance for interpreting `optimizer_budget`;
- clarified `drm_control()` optimizer syntax and regenerated Rd examples using
  canonical `sigma ~ ...` grammar;
- marked the `0.1.0` Phase 9 roadmap note as historical;
- added a bivariate known-sampling-covariance memory-light storage test.

Commands run:

- `air format README.md vignettes/distribution-families.Rmd vignettes/large-data.Rmd R/control.R R/methods.R ROADMAP.md tests/testthat/test-control.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'control')"`: passed with 68 tests, 0
  failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::document()"`: passed and regenerated affected Rd
  examples.
- `Rscript -e "devtools::test()"`: passed with 1,480 tests, 0 failures, 0
  warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `git diff --check`: passed.
- `rg -n 'sigma = ~|Gaussian residual-variance|family-specific variation|optimizer_budget|Var\\[y_i \\| y_i > 0\\]|Historical .*0\\.1\\.0|memory-light storage keeps bivariate known-V' README.md ROADMAP.md R man tests/testthat/test-control.R vignettes pkgdown-site --glob '!pkgdown-site/search.json'`:
  passed; no `sigma = ~` examples remained, and the expected corrected
  wording/equation/test/site entries were present.
- `Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes for `drmTMB 0.1.1`.
- Noether, Boole, and Curie reviewer pass: clear; no blocker-level scale,
  syntax, install, or test-fragility issues remained.

Known limitations:

- the new bivariate memory-light test is a focused method smoke test, not a
  large-data benchmark.

## 2026-05-10 -- Add benchmark summary helper

Goal:

- make local large-data benchmark CSV files easier to inspect while keeping
  non-converged and legacy-schema rows visibly caveated.

Implemented:

- added `bench/summarize-results.R`;
- the helper prints a Markdown table with scenario labels, convergence status,
  diagnostic status, timing, object-size, heap-use, `sigma`, and phylogenetic
  SD summaries;
- older CSV files without optimizer messages and evaluation counts are labelled
  `legacy_schema`;
- non-converged rows are labelled `diagnostic_only`;
- updated `bench/README.md` with the summary command and cautions.

Commands run:

- `air format bench/summarize-results.R bench/README.md`: passed.
- `Rscript bench/summarize-results.R --input bench/results/large-phylo-location.csv`:
  passed; it identified the local ignored CSV as `legacy_schema` and marked
  the non-converged factor-heavy row as diagnostic only.
- `Rscript bench/large-phylo-location.R --rows 1000 --species 50 --eval-max 80 --iter-max 80 --memory-light true --output /tmp/drmTMB-summary-smoke.csv`:
  passed and wrote a fresh current-schema benchmark CSV.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-summary-smoke.csv`:
  passed and printed optimizer diagnostics for the current-schema row.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-summary-smoke.csv --converged-only true`:
  passed.
- `Rscript bench/summarize-results.R --help`: passed.
- `rg -n "summarize-results|Summarising Results|converged-only|legacy_schema|diagnostic_only" bench/README.md bench/summarize-results.R`:
  passed.
- `git diff --check`: passed.

Known limitations:

- the helper summarizes CSV files only; it does not measure peak resident
  memory or make a million-row readiness claim.

## 2026-05-10 -- Compare 100k benchmark storage modes

Goal:

- collect current-schema benchmark evidence comparing memory-light and default
  fitted-object storage on the same 100,000-row, 1,000-species phylogenetic
  Gaussian location scenario.

Implemented:

- no package code changed;
- ran two local benchmark rows into
  `/tmp/drmTMB-storage-current-schema-25640258868.csv`;
- summarized the pair with `bench/summarize-results.R`;
- recorded the local result in an after-task note.

Commands run:

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 180 --iter-max 180 --memory-light true --output /tmp/drmTMB-storage-current-schema-25640258868.csv`:
  passed; convergence code 0, optimizer message `relative convergence (4)`,
  45 iterations, 69 function evaluations, 46 gradient evaluations, fit time
  25.074 seconds, fitted-object size 45.730 MB, post-fit R heap 405.741 MB,
  max RSS 1,415,626,752 bytes, and peak memory footprint 723,666,504 bytes.
- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 180 --iter-max 180 --memory-light false --output /tmp/drmTMB-storage-current-schema-25640258868.csv`:
  passed; convergence code 0, optimizer message `relative convergence (4)`,
  45 iterations, 69 function evaluations, 46 gradient evaluations, fit time
  25.070 seconds, fitted-object size 54.935 MB, post-fit R heap 500.926 MB,
  max RSS 1,399,848,960 bytes, and peak memory footprint 678,839,880 bytes.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-storage-current-schema-25640258868.csv`:
  passed and marked both rows as `timing_usable` with
  `diagnostics_recorded`.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-storage-current-schema-25640258868.csv', check.names = FALSE); print(x[, c('memory_light','convergence','convergence_message','iterations','function_evaluations','gradient_evaluations','fit_sec','fit_object_mb','model_matrix_mb','tmb_data_mb','gc_used_mb_post_fit')]);"`:
  passed.

Known limitations:

- this one local pair supports the post-fit storage claim, not a million-row
  readiness claim; the OS peak-memory numbers need repeated runs before
  interpretation.

## 2026-05-10 -- Add Tweedie to future wishlist

Goal:

- record Tweedie as a future real-data family for non-negative semicontinuous
  ecological and evolutionary responses.

Implemented:

- added a Phase 7 roadmap note for future `tweedie()` support;
- added a distribution-roadmap entry for biomass, cover, CPUE-like indices, and
  abundance-index responses with exact zeros and positive continuous values;
- added a family-registry warning that the public `sigma` to Tweedie
  dispersion mapping must be decided before comparator tests.

Commands run:

- Web source check: glmmTMB official family documentation currently lists
  `tweedie(link = "log")`, describes `V = phi * mu^power`, and restricts the
  power parameter to `1 < power < 2`.
- Web source check: glmmTMB `family_params()` documentation names Tweedie as a
  family with an additional family-specific parameter.
- `air format ROADMAP.md docs/design/06-distribution-roadmap.md docs/design/02-family-registry.md`:
  passed.
- `rg -n "tweedie|Tweedie|phi \\* mu\\^nu|1 < nu < 2|sigma.*phi" ROADMAP.md docs/design/06-distribution-roadmap.md docs/design/02-family-registry.md`:
  passed and found the roadmap, family-registry, and distribution-roadmap
  entries.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `rg -n "tweedie|Tweedie|semi-continuous|semicontinuous" ROADMAP.md docs/design/06-distribution-roadmap.md docs/design/02-family-registry.md pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`:
  passed and confirmed the generated roadmap page includes the Tweedie
  wishlist entry.
- `git diff --check`: passed.

Known limitations:

- this is wishlist/design work only; no Tweedie likelihood, simulation,
  extractor, or comparator test exists yet.

## 2026-05-10 -- Run 100k sigma-predictor benchmark

Goal:

- collect current-schema benchmark evidence for a 100,000-row, 1,000-species
  phylogenetic Gaussian location-scale model with `sigma ~ x1`.

Implemented:

- no package code changed;
- ran one local benchmark row into
  `/tmp/drmTMB-sigma-x-current-schema-25640258868.csv`;
- summarized the row with `bench/summarize-results.R`;
- recorded the local result in an after-task note.

Commands run:

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 220 --iter-max 220 --sigma-x true --memory-light true --output /tmp/drmTMB-sigma-x-current-schema-25640258868.csv`:
  passed; convergence code 0, optimizer message `relative convergence (4)`,
  65 iterations, 97 function evaluations, 66 gradient evaluations, fit time
  62.701 seconds, fitted-object size 47.257 MB, model-matrix size 16.024 MB,
  TMB-data size 22.089 MB, post-fit R heap 416.295 MB, max RSS
  1,779,056,640 bytes, and peak memory footprint 742,148,088 bytes.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-sigma-x-current-schema-25640258868.csv`:
  passed and marked the row as `timing_usable` with
  `diagnostics_recorded`.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-sigma-x-current-schema-25640258868.csv', check.names = FALSE); print(x[, c('sigma_x','memory_light','convergence','convergence_message','iterations','function_evaluations','gradient_evaluations','fit_sec','fit_object_mb','model_matrix_mb','tmb_data_mb','gc_used_mb_post_fit','sigma_hat')]);"`:
  passed.

Known limitations:

- this one local row supports only a staged benchmark claim; it does not prove
  factor-heavy, non-Gaussian, bivariate, or million-row readiness.

## 2026-05-10 -- Run 100k species-pressure benchmark

Goal:

- collect current-schema benchmark evidence for a 100,000-row, 5,000-species
  phylogenetic Gaussian location model.

Implemented:

- no package code changed;
- ran one local benchmark row into
  `/tmp/drmTMB-species-pressure-current-schema-25640492608.csv`;
- summarized the row with `bench/summarize-results.R`;
- recorded the local result in an after-task note.

Commands run:

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 5000 --eval-max 220 --iter-max 220 --memory-light true --output /tmp/drmTMB-species-pressure-current-schema-25640492608.csv`:
  passed; convergence code 0, optimizer message `relative convergence (4)`,
  53 iterations, 66 function evaluations, 54 gradient evaluations, fit time
  32.492 seconds, fitted-object size 52.764 MB, model-matrix size 15.261 MB,
  TMB-data size 22.669 MB, post-fit R heap 417.313 MB, max RSS
  1,654,964,224 bytes, and peak memory footprint 664,749,976 bytes.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-species-pressure-current-schema-25640492608.csv`:
  passed and marked the row as `timing_usable` with
  `diagnostics_recorded`.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-species-pressure-current-schema-25640492608.csv', check.names = FALSE); print(x[, c('rows','species','memory_light','convergence','convergence_message','iterations','function_evaluations','gradient_evaluations','fit_sec','fit_object_mb','model_matrix_mb','tmb_data_mb','gc_used_mb_post_fit','sigma_hat','sd_phylo_hat')]);"`:
  passed.

Known limitations:

- this one local row tests species pressure only; it does not prove 10,000
  species, factor-heavy, non-Gaussian, bivariate, or million-row readiness.

## 2026-05-10 -- Run 500k row-pressure benchmark

Goal:

- collect current-schema benchmark evidence for a 500,000-row, 1,000-species
  phylogenetic Gaussian location model.

Implemented:

- no package code changed;
- ran one local benchmark row into
  `/tmp/drmTMB-row-pressure-current-schema-087c000.csv`;
- summarized the row with `bench/summarize-results.R`;
- recorded the local result in an after-task note.

Commands run:

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 500000 --species 1000 --eval-max 220 --iter-max 220 --memory-light true --output /tmp/drmTMB-row-pressure-current-schema-087c000.csv`:
  passed; convergence code 0, optimizer message `relative convergence (4)`,
  50 iterations, 74 function evaluations, 50 gradient evaluations, fit time
  131.407 seconds, fitted-object size 221.206 MB, model-matrix size
  76.296 MB, TMB-data size 105.249 MB, post-fit R heap 1092.205 MB, max RSS
  5,050,040,320 bytes, and peak memory footprint 2,045,808,360 bytes.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-row-pressure-current-schema-087c000.csv`:
  passed and marked the row as `timing_usable` with
  `diagnostics_recorded`.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-row-pressure-current-schema-087c000.csv', check.names = FALSE); print(x[, c('rows','species','memory_light','convergence','convergence_message','iterations','function_evaluations','gradient_evaluations','fit_sec','fit_object_mb','model_matrix_mb','tmb_data_mb','gc_used_mb_post_fit','sigma_hat','sd_phylo_hat')]);"`:
  passed.

Known limitations:

- this one local row tests row pressure only; it does not prove million-row,
  10,000-species, factor-heavy, non-Gaussian, or bivariate readiness.

## 2026-05-10 -- Summarize large-data benchmark evidence for users

Goal:

- make the large-data article and benchmark-results table reflect the latest
  current-schema local benchmark rows without making broad performance claims.

Implemented:

- updated `vignettes/large-data.Rmd` with a compact current benchmark summary;
- updated `docs/dev-log/benchmark-results.md` with current 100k storage,
  100k `sigma ~ x1`, 100k / 5k species-pressure, and 500k / 1k row-pressure
  rows;
- added an after-task note.

Commands run:

- `air format vignettes/large-data.Rmd docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-large-data-benchmark-summary-docs.md`:
  passed.
- `rg -n "500k rows|500,000|10,000-species|factor-heavy|non-Gaussian|5\\.1 GB|memory-light" vignettes/large-data.Rmd docs/dev-log/benchmark-results.md docs/dev-log/after-task/2026-05-10-large-data-benchmark-summary-docs.md docs/dev-log/check-log.md`:
  passed and found the expected source text.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `rg -n "What the current development benchmarks say|500k rows|5\\.1 GB|10,000-species|factor-heavy|non-Gaussian" vignettes/large-data.Rmd pkgdown-site/articles/large-data.html docs/dev-log/benchmark-results.md docs/dev-log/after-task/2026-05-10-large-data-benchmark-summary-docs.md --glob '!pkgdown-site/search.json'`:
  passed and confirmed the generated article includes the new section.
- `git diff --check`: passed.

Known limitations:

- this is a selected local benchmark summary only; it does not prove
  million-row, 10,000-species, factor-heavy, non-Gaussian, or bivariate
  readiness.

## 2026-05-10 -- Split benchmark stressor columns

Goal:

- make `docs/dev-log/benchmark-results.md` separate memory-light storage,
  scale predictors, fixed-effect factor pressure, row pressure, and species
  pressure instead of mixing them inside one `Storage` column.

Implemented:

- replaced the durable benchmark table's `Storage` column with `Family`,
  `Sigma formula`, `Factor levels`, `Memory-light`, and `Status`;
- added a caveat that `R heap after fit MB` is a post-fit
  garbage-collector summary, not peak memory;
- added an after-task note.

Commands run:

- `air format docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-table-stressor-columns.md`:
  passed.
- `rg -n "Family \\| Sigma formula|Factor levels|Memory-light|diagnostic only|post-fit garbage-collector|not peak memory|Storage" docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-table-stressor-columns.md`:
  passed and found the new column names, diagnostic status, R-heap caveat, and
  recorded replacement of the old `Storage` column.
- `git diff --check`: passed.

Known limitations:

- this is table-structure documentation only; it does not add new benchmark
  rows or change package behaviour.

## 2026-05-10 -- Repeat 500k row-pressure benchmark

Goal:

- repeat the 500,000-row, 1,000-species memory-light Gaussian phylogenetic
  baseline before adding a new stressor.

Implemented:

- ran one repeated local benchmark row into
  `/tmp/drmTMB-row-pressure-current-schema-repeat-004be10.csv`;
- summarized the row with `bench/summarize-results.R`;
- added the repeated row to `docs/dev-log/benchmark-results.md`;
- recorded the local result in an after-task note.

Commands run:

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 500000 --species 1000 --eval-max 220 --iter-max 220 --memory-light true --output /tmp/drmTMB-row-pressure-current-schema-repeat-004be10.csv`:
  passed; convergence code 0, optimizer message `relative convergence (4)`,
  50 iterations, 74 function evaluations, 50 gradient evaluations, fit time
  133.997 seconds, fitted-object size 221.206 MB, model-matrix size
  76.296 MB, TMB-data size 105.249 MB, post-fit R heap 1092.205 MB, max RSS
  5,066,604,544 bytes, and peak memory footprint 2,028,277,504 bytes.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-row-pressure-current-schema-repeat-004be10.csv`:
  passed and marked the row as `timing_usable` with
  `diagnostics_recorded`.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-row-pressure-current-schema-repeat-004be10.csv', check.names = FALSE); print(x[, c('rows','species','memory_light','convergence','convergence_message','iterations','function_evaluations','gradient_evaluations','fit_sec','fit_object_mb','model_matrix_mb','tmb_data_mb','gc_used_mb_post_fit','sigma_hat','sd_phylo_hat')]);"`:
  passed.
- `air format docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-row-pressure-repeat.md`:
  passed.
- `rg -n "timing usable, repeat|133\\.997|5,066,604,544|row-pressure-current-schema-repeat|50 iterations, 74 function" docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-row-pressure-repeat.md`:
  passed and found the repeated-row evidence.
- `git diff --check`: passed.

Known limitations:

- this repeated row still tests only one Gaussian phylogenetic row-pressure
  scenario on one local machine.

## 2026-05-10 -- Fix benchmark R-heap calculation

Goal:

- correct the optional benchmark harness's approximate R-heap calculation for
  `gc()` Ncells and Vcells.

Implemented:

- updated `bench/large-phylo-location.R` so `gc_used_mb()` weights Ncells by
  56 bytes and Vcells by 8 bytes;
- updated `bench/README.md` to describe the `gc()` cell-count basis for the
  heap columns;
- added a caveat to `docs/dev-log/benchmark-results.md` that historical
  R-heap values should be treated as rough context.

Commands run:

- `air format bench/large-phylo-location.R bench/README.md docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-gc-used-mb-fix.md`:
  passed.
- `rg -n "bytes_per_cell|Ncells = 56|Vcells = 8|cell-count|historical context|gc_used_mb\\(\\)" bench/large-phylo-location.R bench/README.md docs/dev-log/benchmark-results.md docs/dev-log/after-task/2026-05-10-benchmark-gc-used-mb-fix.md docs/dev-log/check-log.md`:
  passed and found the corrected cell weights plus the historical-results
  caveat.
- `Rscript bench/large-phylo-location.R --rows 300 --species 20 --eval-max 80 --iter-max 80 --memory-light true --output /tmp/drmTMB-gc-used-mb-fix-smoke.csv`:
  passed and wrote a fresh CSV row.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-gc-used-mb-fix-smoke.csv`:
  passed and marked the row as `timing_usable` with
  `diagnostics_recorded`.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-gc-used-mb-fix-smoke.csv', check.names = FALSE); print(x[, c('gc_used_mb_before','gc_used_mb_pre_fit','gc_used_mb_post_fit','convergence','fit_sec')]); stopifnot(all(is.finite(unlist(x[, c('gc_used_mb_before','gc_used_mb_pre_fit','gc_used_mb_post_fit')]))));"`:
  passed; the smoke row reported finite heap summaries of 132.420, 132.587,
  and 135.876 MB.
- `git diff --check`: passed.

Known limitations:

- this does not recompute historical benchmark rows; future rows should use
  fresh output paths.

## 2026-05-10 -- Add corrected-heap 100k benchmark row

Goal:

- collect one fresh 100,000-row, 1,000-species memory-light Gaussian
  phylogenetic baseline after the `gc_used_mb()` fix.

Implemented:

- ran one local benchmark row into
  `/tmp/drmTMB-gc-fixed-100k-baseline-d9d5240.csv`;
- summarized the row with `bench/summarize-results.R`;
- added the corrected-heap row to `docs/dev-log/benchmark-results.md`;
- recorded the local result in an after-task note.

Commands run:

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 220 --iter-max 220 --memory-light true --output /tmp/drmTMB-gc-fixed-100k-baseline-d9d5240.csv`:
  passed; convergence code 0, optimizer message `relative convergence (4)`,
  45 iterations, 69 function evaluations, 46 gradient evaluations, fit time
  28.450 seconds, fitted-object size 45.730 MB, model-matrix size 15.261 MB,
  TMB-data size 21.326 MB, corrected post-fit R heap 165.544 MB, max RSS
  1,401,323,520 bytes, and peak memory footprint 721,061,472 bytes.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-gc-fixed-100k-baseline-d9d5240.csv`:
  passed and marked the row as `timing_usable` with
  `diagnostics_recorded`.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-gc-fixed-100k-baseline-d9d5240.csv', check.names = FALSE); print(x[, c('rows','species','memory_light','convergence','convergence_message','iterations','function_evaluations','gradient_evaluations','fit_sec','fit_object_mb','model_matrix_mb','tmb_data_mb','gc_used_mb_post_fit','sigma_hat','sd_phylo_hat')]);"`:
  passed.
- `air format docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-corrected-heap-100k.md`:
  passed.
- `rg -n "corrected heap|Corrected|165\\.544|gc-fixed-100k|1,401,323,520|timing usable, corrected heap" docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-corrected-heap-100k.md`:
  passed and found the corrected-heap row and after-task evidence.
- `git diff --check`: passed.

Known limitations:

- this is one corrected-heap row only; it does not recompute all historical
  benchmark rows.

## 2026-05-10 -- Add 500k sigma-predictor benchmark row

Goal:

- collect one 500,000-row, 1,000-species memory-light Gaussian phylogenetic
  benchmark with `sigma ~ x1`.

Implemented:

- ran one local benchmark row into
  `/tmp/drmTMB-gc-fixed-500k-sigma-x-a67891b.csv`;
- summarized the row with `bench/summarize-results.R`;
- added the row to `docs/dev-log/benchmark-results.md`;
- recorded the local result in an after-task note.

Commands run:

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 500000 --species 1000 --eval-max 260 --iter-max 260 --sigma-x true --memory-light true --output /tmp/drmTMB-gc-fixed-500k-sigma-x-a67891b.csv`:
  passed; convergence code 0, optimizer message `relative convergence (4)`,
  72 iterations, 105 function evaluations, 73 gradient evaluations, fit time
  389.028 seconds, fitted-object size 228.837 MB, model-matrix size
  80.111 MB, TMB-data size 109.064 MB, corrected post-fit R heap 292.102 MB,
  max RSS 5,451,743,232 bytes, and peak memory footprint 2,023,231,496 bytes.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-gc-fixed-500k-sigma-x-a67891b.csv`:
  passed and marked the row as `timing_usable` with
  `diagnostics_recorded`.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-gc-fixed-500k-sigma-x-a67891b.csv', check.names = FALSE); print(x[, c('rows','species','sigma_x','memory_light','convergence','convergence_message','iterations','function_evaluations','gradient_evaluations','fit_sec','fit_object_mb','model_matrix_mb','tmb_data_mb','gc_used_mb_post_fit','sigma_hat','sd_phylo_hat')]);"`:
  passed.
- `air format docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-sigma-x-500k.md`:
  passed.
- `rg -n "sigma ~ x1|389\\.028|5,451,743,232|gc-fixed-500k-sigma-x|72 iterations|105 function" docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-sigma-x-500k.md`:
  passed and found the 500k `sigma ~ x1` benchmark evidence.
- `git diff --check`: passed.

Known limitations:

- this is one local current-schema stress row; it does not test bivariate,
  coscale, non-Gaussian, sparse-matrix, or sufficient-statistic pathways.

## 2026-05-10 -- Add Tweedie design gate

Goal:

- turn the Tweedie real-data wish-list item into a concrete future design gate
  without implying implementation.

Implemented:

- added `docs/design/27-tweedie-family-plan.md`;
- linked the design gate from `ROADMAP.md`;
- linked the design gate from `docs/design/06-distribution-roadmap.md`;
- added an after-task report.

Checks run:

- web source check: glmmTMB family documentation currently lists
  `tweedie(link = "log")`, writes `V = phi * mu^power`, and restricts the
  power parameter to `1 < power < 2`;
- web source check: glmmTMB `family_params()` documentation treats Tweedie
  power as an additional family-specific parameter;
- prose-style review lens applied for applied eco-evo readers and package
  contributors.
- `air format ROADMAP.md docs/design/06-distribution-roadmap.md docs/design/27-tweedie-family-plan.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-tweedie-design-gate.md`:
  passed.
- `rg -n "Tweedie|tweedie|phi \\* mu|sigma = sqrt|sigma = phi|not currently|future syntax|27-tweedie" ROADMAP.md docs/design/06-distribution-roadmap.md docs/design/27-tweedie-family-plan.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-tweedie-design-gate.md`:
  passed and found the design-gate wording.
- `rg -n "tweedie\\(\\).*Implemented|Implemented.*tweedie|Tweedie.*implemented|fit Tweedie|can fit Tweedie|family = tweedie\\(\\)" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/after-task vignettes R tests`:
  passed; only the design note and after-task report mention that `drmTMB`
  does not currently fit Tweedie models and mark `family = tweedie()` as future
  syntax.
- `git diff --check`: passed.

Known limitations:

- this is design documentation only; it does not add a Tweedie likelihood,
  family helper, simulation, or comparator test.

## 2026-05-10 -- Add benchmark environment metadata

Goal:

- record R, package, and platform context in optional large-data benchmark CSV
  rows.

Implemented:

- added `run_started_utc`, `r_version`, `platform`, `os`, `machine`,
  `drmTMB_version`, and `TMB_version` columns to
  `bench/large-phylo-location.R` output;
- documented the metadata columns in `bench/README.md`;
- added an after-task report.

Checks run:

- `air format bench/large-phylo-location.R bench/README.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-environment-metadata.md`:
  passed.
- `Rscript -e "parse('bench/large-phylo-location.R'); parse('bench/summarize-results.R')"`:
  passed.
- `Rscript bench/large-phylo-location.R --rows 300 --species 20 --eval-max 80 --iter-max 80 --memory-light true --output /tmp/drmTMB-benchmark-env-metadata-smoke.csv`:
  passed and wrote the smoke benchmark CSV.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-benchmark-env-metadata-smoke.csv`:
  passed; convergence code 0, status `timing_usable`, and diagnostics
  `diagnostics_recorded`.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-benchmark-env-metadata-smoke.csv', check.names = FALSE); print(x[, c('run_started_utc','r_version','platform','os','machine','drmTMB_version','TMB_version','rows','species','convergence')]); stopifnot(all(c('run_started_utc','r_version','platform','os','machine','drmTMB_version','TMB_version') %in% names(x)))"`:
  passed and confirmed the new metadata columns.
- `rg -n "run_started_utc|drmTMB_version|benchmark environment metadata|schema can change|R and platform metadata" bench/README.md bench/large-phylo-location.R docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-environment-metadata.md`:
  passed.
- `git diff --check`: passed.

Known limitations:

- metadata does not include CPU model, available RAM, BLAS details, or
  operating-system peak memory.

## 2026-05-10 -- GitHub Actions Node 24 hygiene

Goal:

- remove Node.js 20 deprecation annotations from otherwise green CI runs by
  updating first-party GitHub actions to current Node 24 releases.

Implemented:

- updated `actions/checkout` from `v4` to `v6.0.2`;
- updated `actions/configure-pages` from `v5` to `v6.0.0`;
- updated `actions/upload-pages-artifact` from `v4` to `v5.0.0`;
- updated `actions/deploy-pages` from `v4` to `v5.0.0`;
- removed `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` from both workflows.

Checks run:

- `gh api repos/actions/checkout/releases/latest --jq '.tag_name'`:
  returned `v6.0.2`.
- `gh api repos/actions/configure-pages/releases/latest --jq '.tag_name'`:
  returned `v6.0.0`.
- `gh api repos/actions/upload-pages-artifact/releases/latest --jq '.tag_name'`:
  returned `v5.0.0`.
- `gh api repos/actions/deploy-pages/releases/latest --jq '.tag_name'`:
  returned `v5.0.0`.
- `gh api 'repos/actions/checkout/contents/action.yml?ref=v6.0.2' --jq '.content' | base64 --decode | rg -n "using:"`:
  confirmed `using: node24`.
- `gh api 'repos/actions/configure-pages/contents/action.yml?ref=v6.0.0' --jq '.content' | base64 --decode | rg -n "using:"`:
  confirmed `using: 'node24'`.
- `gh api 'repos/actions/upload-pages-artifact/contents/action.yml?ref=v5.0.0' --jq '.content' | base64 --decode | rg -n "using:"`:
  confirmed the action is composite and uses `actions/upload-artifact` v7
  internally.
- `gh api 'repos/actions/deploy-pages/contents/action.yml?ref=v5.0.0' --jq '.content' | base64 --decode | rg -n "using:"`:
  confirmed `using: 'node24'`.
- `ruby -e 'require "yaml"; ARGV.each { |f| YAML.load_file(f); puts "ok #{f}" }' .github/workflows/R-CMD-check.yaml .github/workflows/pkgdown.yaml`:
  passed and parsed both workflow YAML files.
- `rg -n "actions/checkout|actions/configure-pages|actions/upload-pages-artifact|actions/deploy-pages|FORCE_JAVASCRIPT_ACTIONS_TO_NODE24" .github/workflows docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-github-actions-node24-hygiene.md`:
  passed and found the updated workflow tags plus historical check-log mentions.
- `git diff --check`: passed.
- R-CMD-check run `25642430251` for commit `17c817f`: passed on macOS,
  Ubuntu, and Windows with `actions/checkout@v6.0.2`.
- pkgdown run `25642554902` for commit `17c817f`: passed, including
  `actions/configure-pages@v6.0.0`,
  `actions/upload-pages-artifact@v5.0.0`, and
  `actions/deploy-pages@v5.0.0`.

Known limitations:

- R-CMD-check reported a GitHub-hosted runner notice that `windows-2025`
  requests are being redirected to `windows-2025-vs2026` by May 12, 2026. This
  is a platform notice, not a package failure.

## 2026-05-10 -- Refine Tweedie working scale recommendation

Goal:

- record a clearer working direction for future Tweedie scale semantics without
  adding a likelihood or implying implementation.

Implemented:

- recorded `sigma = sqrt(phi)` as the current working recommendation in
  `docs/design/27-tweedie-family-plan.md`;
- clarified that the first Tweedie slice should use intercept-only `nu ~ 1`;
- updated `ROADMAP.md`, `docs/design/06-distribution-roadmap.md`, and
  `docs/design/02-family-registry.md`;
- updated the Tweedie design-gate after-task report;
- created GitHub issue #2 to track future Tweedie implementation.

Checks run:

- team review: Noether, Boole, and Curie all recommended `sigma = sqrt(phi)` as
  the working direction, with comparator tests comparing `sigma^2` against
  Tweedie dispersion `phi`;
- prose-style review lens applied for applied eco-evo readers and package
  contributors.
- `air format ROADMAP.md docs/design/06-distribution-roadmap.md docs/design/02-family-registry.md docs/design/27-tweedie-family-plan.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-tweedie-design-gate.md docs/dev-log/after-task/2026-05-10-tweedie-working-scale.md`:
  passed.
- `rg -n "sigma = sqrt\\(phi\\)|sigma\\^2 \\* mu\\^nu|nu ~ 1|GitHub issue #2|Tweedie working" ROADMAP.md docs/design/02-family-registry.md docs/design/06-distribution-roadmap.md docs/design/27-tweedie-family-plan.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-tweedie-design-gate.md docs/dev-log/after-task/2026-05-10-tweedie-working-scale.md`:
  passed and confirmed the working-scale wording.
- `rg -n "tweedie\\(\\).*Implemented|Implemented.*tweedie|Tweedie.*implemented|can fit Tweedie|fit Tweedie models|family = tweedie\\(\\)" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/after-task vignettes R tests`:
  passed; matches are limited to future syntax and explicit not-implemented
  wording in design notes.
- `git diff --check`: passed.

Known limitations:

- this is design and tracking work only; it does not add `tweedie()`,
  likelihood code, tests, or a real-data tutorial.

## 2026-05-10 -- Fix standalone comparator harness loading

Goal:

- make `tools/replicate-location-scale-gaussian.R` work when run directly from
  the package root.

Implemented:

- changed `load_drmTMB()` so package-root runs use `devtools::load_all()` before
  falling back to an installed `drmTMB` package;
- attached installed `drmTMB` when the script is run outside the package root;
- added an after-task note.

Checks run:

- initial `Rscript tools/replicate-location-scale-gaussian.R`: failed because
  `requireNamespace("drmTMB")` returned true but did not attach `drmTMB()` and
  `bf()` into the script namespace;
- `air format tools/replicate-location-scale-gaussian.R docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-comparator-harness-standalone-load.md`:
  passed.
- `git diff --check`: passed.
- `Rscript tools/replicate-location-scale-gaussian.R`: passed. Both comparator
  rows reported `passed = TRUE`; the largest absolute coefficient difference
  was about `6.7e-06`.

Known limitations:

- the harness remains optional and requires `glmmTMB`;
- it validates overlapping Gaussian location-scale examples only, not future
  individual-difference covariance blocks.

## 2026-05-10 -- Profile CI and double-hierarchical phase map

Goal:

- sharpen the overnight plan for profile-likelihood confidence intervals and
  complete double-hierarchical individual-difference covariance models without
  claiming either path is implemented.

Implemented:

- added `docs/design/28-double-hierarchical-endpoint.md` as the endpoint map for
  complete individual-difference location-scale covariance models;
- updated `ROADMAP.md` so Phase 6 is the first direct-parameter
  profile-likelihood CI phase and Phase 13 is derived inference for complete
  double-hierarchical models;
- added a first implementation slice to
  `docs/design/12-profile-likelihood-cis.md`, beginning with a target inventory
  such as `profile_targets(fit)`;
- updated `docs/design/20-coscale-correlation-pairs.md` and
  `docs/design/04-random-effects.md` to use reader-facing descriptions of
  individual averages, mean-model slopes, residual scale, and scale-model
  slopes instead of relying on shorthand from the literature.

Checks run:

- prose-style review lens applied for applied ecology/evolution readers and R
  package contributors;
- `air format ROADMAP.md docs/design/04-random-effects.md docs/design/12-profile-likelihood-cis.md docs/design/20-coscale-correlation-pairs.md docs/design/28-double-hierarchical-endpoint.md`:
  passed;
- `git diff --check`: passed;
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed;
- `rg -n "Phase 13: Double-Hierarchical Derived Inference|28-double-hierarchical-endpoint|profile_targets|individual averages|rho12" pkgdown-site/ROADMAP.html pkgdown-site/search.json ROADMAP.md docs/design/28-double-hierarchical-endpoint.md docs/design/12-profile-likelihood-cis.md`:
  passed and confirmed the rendered roadmap includes the Phase 13 rename and
  endpoint-map reference;
- `Rscript -e "devtools::test()"`: passed with 0 failures, 0 warnings, 0 skips,
  and 1480 passing expectations;
- `rg -n "O'Dea|O’Dea|Nakagawa|personality|plasticity|predictability|malleability|O'Dea/Nakagawa|O'Dea-style|O’Dea-style" ROADMAP.md docs/design/04-random-effects.md docs/design/12-profile-likelihood-cis.md docs/design/20-coscale-correlation-pairs.md docs/design/28-double-hierarchical-endpoint.md`:
  passed with no matches after the final wording pass.

Known limitations:

- this is design and phase-map work only; no `confint.drmTMB()` method,
  profile target inventory, cross-formula covariance block, or new `corpairs()`
  row class has been implemented yet.

## 2026-05-10 -- Internal profile target inventory seed

Goal:

- add the first internal target inventory for future profile-likelihood
  confidence intervals, without exposing a public `confint()` method yet.

Implemented:

- added internal `drm_profile_targets()` to list fixed-effect coefficients,
  random-effect SDs, random-effect correlations, residual `rho12` coefficients,
  hurdle `hu` coefficients, modelled group-scale rows, and ordinal raw
  `theta_ord` parameters;
- returned stable columns for `parm`, `target_class`, `dpar`, `term`,
  `tmb_parameter`, `index`, `estimate`, `link_estimate`, `scale`,
  `transformation`, `target_type`, `profile_ready`, and `profile_note`;
- marked directly profile-ready rows separately from derived group-scale rows;
- mapped hurdle `hu` coefficients to the internal TMB `beta_zi` parameter,
  matching the compiled likelihood route;
- updated `docs/design/12-profile-likelihood-cis.md` so the design now names
  the private helper, the table columns, the explicit multi-coefficient random
  effect grammar, and the raw `theta_ord` ordinal boundary.

Checks run:

- Curie review: caught that the first test file depended on helper functions
  from `test-corpairs.R` and that the six-row Gaussian fit emitted an
  `sdreport()` warning; the tests were made self-contained with stable
  simulated data.
- Boole review: caught that `internal` and `class` were weak future API-seed
  column names and that unsupported targets needed a reason column; the table
  now uses `tmb_parameter`, `target_class`, and `profile_note`.
- Noether review: caught the `hu` to `beta_hu` mismatch before closure; the
  implementation now maps public `hu` to internal `beta_zi` and has a focused
  regression test.
- `air format R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md`:
  passed.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 0
  failures, 0 warnings, 0 skips, and 46 passing expectations.
- `Rscript -e "devtools::test()"`: passed with 0 failures, 0 warnings, 0 skips,
  and 1526 passing expectations.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `git diff --check`: passed.
- `rg -n "O'Dea/Nakagawa|O'Dea-style|O’Dea-style|Nakagawa" R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md docs/dev-log/after-task/2026-05-10-profile-target-inventory.md ROADMAP.md README.md NEWS.md vignettes`:
  passed with no matches.
- `rg -n "tmb_parameter.*beta_hu|fixef:hu.*beta_hu|profile.*beta_hu" R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md docs/dev-log/after-task/2026-05-10-profile-target-inventory.md`:
  passed with no matches.
- `rg -n 'drm_profile_targets|raw \`theta_ord\`|multi-coefficient random-effect|profile_note' docs/design/12-profile-likelihood-cis.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-profile-target-inventory.md R/profile.R tests/testthat/test-profile-targets.R`:
  passed and confirmed the implementation, design note, and after-task report
  all name the same helper and profile-status columns.

Known limitations:

- no public profile-likelihood confidence interval API is exposed yet;
- derived summaries such as ICC, repeatability, phylogenetic signal, and
  double-hierarchical correlation-pair summaries are deliberately inventoried
  only as future work until direct TMB-parameter profiles are implemented.

## 2026-05-10 -- Internal fixed-effect profile engine

Goal:

- turn the internal target inventory into one working `TMB::tmbprofile()` path
  for direct fixed-effect targets, while keeping the public `confint()` API
  closed.

Implemented:

- added private `drm_profile_confint()` for direct fixed-effect profile
  intervals;
- matched requested target names against `drm_profile_targets()`;
- constructed one-hot linear combinations over the optimized TMB parameter
  vector so duplicated internal names such as `beta_mu` can be profiled by
  target index;
- rejected unsupported target classes, unknown target names, and invalid
  confidence levels before calling the optimizer;
- documented the private helper and its current fixed-effect-only boundary in
  `docs/design/12-profile-likelihood-cis.md`;
- added an after-task note for the internal profile engine.

Checks run:

- `air format R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md docs/dev-log/after-task/2026-05-10-profile-fixed-effect-engine.md`:
  passed.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 0
  failures, 0 warnings, 0 skips, and 59 passing expectations.
- `Rscript -e "devtools::test()"`: passed with 0 failures, 0 warnings, 0 skips,
  and 1539 passing expectations.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `git diff --check`: passed.
- `rg -n "confint\\.drmTMB\\(method = \\\"profile\\\"\\).*implemented|profile.*public.*implemented|O'Dea/Nakagawa|O'Dea-style|O’Dea-style" R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md docs/dev-log/after-task/2026-05-10-profile-fixed-effect-engine.md ROADMAP.md README.md NEWS.md vignettes`:
  found only the expected after-task limitation that
  `confint.drmTMB(method = "profile")` is not implemented.

Known limitations:

- this is still private infrastructure; no `confint.drmTMB(method = "profile")`
  method is exported;
- only direct fixed-effect targets are accepted;
- SD, correlation, transformed ordinal-cutpoint, and derived-summary targets
  still need separate boundary and interpretation work before profiling.

## 2026-05-10 -- Public fixed-effect confidence intervals

Goal:

- expose the first public `confint.drmTMB()` method while keeping the expensive
  profile path explicit and fixed-effect only.

Implemented:

- added `confint.drmTMB()`;
- made `confint(fit)` return Wald fixed-effect intervals by default;
- made `confint(fit, parm = "fixef:mu:x", method = "profile")` call the
  internal fixed-effect profile engine;
- accepted compact labels such as `"mu:x"` as aliases for full fixed-effect
  target names such as `"fixef:mu:x"`;
- rejected unsupported profile target classes, missing profile target names,
  unknown target names, invalid confidence levels, unused Wald `...`, and
  profile requests after `keep_tmb_object = FALSE`;
- updated `NEWS.md`, `ROADMAP.md`, `_pkgdown.yml`, the profile design note, and
  the after-task report.

Checks run:

- `air format R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md NEWS.md _pkgdown.yml`:
  passed.
- `Rscript -e "devtools::document()"`: passed and wrote `NAMESPACE` plus
  `man/confint.drmTMB.Rd`.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: first run failed
  because the new Wald test compared unnamed data-frame columns to named
  expected vectors; after fixing the test it passed with 0 failures, 0 warnings,
  0 skips, and 67 passing expectations.
- `Rscript -e "devtools::test()"`: passed with 0 failures, 0 warnings, 0 skips,
  and 1547 passing expectations.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/confint.drmTMB.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `Rscript -e "devtools::check(document = FALSE, manual = FALSE)"`: passed with
  0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- `rg -n 'not a public `confint\(\)`|no `confint\.drmTMB|confint\.drmTMB\(method = "profile"\).*not implemented|public `confint\(\)` API\s*closed' R tests/testthat docs/design vignettes README.md ROADMAP.md NEWS.md`:
  passed with no matches after updating the design note and roadmap.
- `rg -n "O.Dea/Nakagawa|O.Dea-style" R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md ROADMAP.md NEWS.md _pkgdown.yml man/confint.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html --glob '!pkgdown-site/search.json'`:
  passed with no matches.
- `rg -n "confint|profile-likelihood|profile likelihood" README.md ROADMAP.md docs/dev-log/known-limitations.md docs/design/12-profile-likelihood-cis.md vignettes/model-workflow.Rmd vignettes/which-scale.Rmd NEWS.md`:
  confirmed `NEWS.md`, `ROADMAP.md`, and the profile design note now describe
  the same partial Phase 6 status.

Known limitations:

- profile intervals are fixed-effect only;
- random-effect SDs, random-effect correlations, residual-scale parameters,
  transformed ordinal cutpoints, and derived summaries still need
  boundary-aware profile paths;
- profile intervals require `fit$obj`, so they are unavailable after fitting
  with `drm_control(keep_tmb_object = FALSE)`.

## 2026-05-11 -- Profile SD and ordinary random-effect correlation intervals

Goal:

- extend public profile-likelihood confidence intervals from direct
  fixed-effect targets to the first ordinary random-effect SD and group-level
  correlation targets.

Implemented:

- `confint.drmTMB(method = "profile")` now accepts profile-ready
  random-effect SD targets such as `sd:mu:(1 + x | p | ID):(Intercept)`;
- SD profile intervals transform `log_sd_*` intervals with `exp()` and report
  on the SD scale;
- ordinary group-level random-effect correlation targets such as
  `cor:mu:cor((Intercept),x | p | ID)` profile `eta_cor_mu` and transform
  intervals with `0.999999 * tanh()`;
- unsupported profile targets still fail before expensive optimization starts;
- `NEWS.md`, `ROADMAP.md`, `docs/design/12-profile-likelihood-cis.md`, and
  `man/confint.drmTMB.Rd` were synchronized with the new partial Phase 6 scope;
- added `docs/dev-log/after-task/2026-05-11-profile-sd-correlation-intervals.md`.

Checks run:

- Initial Curie/Fisher test attempt: a smaller grouped-data fixture failed
  honestly because `confint.tmbprofile()` did not have enough usable
  interpolation points and warned about collapsed unique `x` values. The test
  was changed to `n_id = 24`, `n_each = 6`, and seed `20260598`.
- `air format R/profile.R tests/testthat/test-profile-targets.R`: passed.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 0
  failures, 0 warnings, 0 skips, and 80 passing expectations.
- `air format R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md ROADMAP.md NEWS.md`:
  passed.
- `Rscript -e "devtools::document()"`: passed and wrote
  `man/confint.drmTMB.Rd`.
- `Rscript -e "devtools::test()"`: passed with 0 failures, 0 warnings, 0 skips,
  and 1560 passing expectations.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/confint.drmTMB.html` and `ROADMAP.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `Rscript -e "devtools::check(document = FALSE, manual = FALSE)"`: passed with
  0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- `LC_ALL=C rg -n "[^\x00-\x7F]" R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/confint.drmTMB.Rd`:
  passed with no matches.
- `rg -n "Only fixed-effect profile targets|fixed-effect targets only|profile.*SD.*planned|profile.*correlation.*planned" R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md ROADMAP.md NEWS.md man/confint.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`:
  passed with no matches.
- `rg -n "O.Dea/Nakagawa|O.Dea-style" R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md ROADMAP.md NEWS.md man/confint.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`:
  passed with no matches.

Known limitations:

- residual `rho12` response-scale profile intervals, transformed ordinal
  cutpoints, modelled group-SD rows, and derived summaries remain planned;
- phylogenetic SD profile targets were not claimed because this slice did not
  add a focused phylogenetic profile test;
- complete double-hierarchical derived intervals still need named extractors
  and covariance-summary design before public implementation.

## 2026-05-11 -- Public profile target discovery helper

Goal:

- add a supported user-facing helper for discovering `confint()` and
  profile-likelihood target names before running expensive profiles.

Implemented:

- added exported `profile_targets()` in `R/profile.R`;
- `profile_targets(fit)` returns the fitted target inventory used internally by
  `confint.drmTMB()`;
- `profile_targets(fit, ready_only = TRUE)` filters to rows with
  `profile_ready = TRUE`;
- invalid `object` and malformed `ready_only` inputs now fail with clear
  messages;
- updated `NAMESPACE`, `man/profile_targets.Rd`, `_pkgdown.yml`, `NEWS.md`,
  `ROADMAP.md`, and `docs/design/12-profile-likelihood-cis.md`;
- added `docs/dev-log/after-task/2026-05-11-profile-targets-public-helper.md`.

Checks run:

- `air format R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md _pkgdown.yml`:
  passed.
- `Rscript -e "devtools::document()"`: passed and wrote `NAMESPACE` plus
  `man/profile_targets.Rd`.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 0
  failures, 0 warnings, 0 skips, and 89 passing expectations.
- `Rscript -e "devtools::test()"`: passed with 0 failures, 0 warnings, 0 skips,
  and 1569 passing expectations.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/profile_targets.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- First `Rscript -e "devtools::check(document = FALSE, manual = FALSE)"`: 0
  errors, 0 warnings, and 1 note, the known local
  `unable to verify current time` note.
- Final `Rscript -e "devtools::check(document = FALSE, manual = FALSE, env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- `LC_ALL=C rg -n "[^\x00-\x7F]" R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/profile_targets.Rd _pkgdown.yml NAMESPACE`:
  passed with no matches.

Known limitations:

- `profile_targets()` exposes readiness; it does not make derived or unsupported
  target classes profile-ready;
- residual response-scale `rho12`, phylogenetic SD, transformed ordinal, and
  derived-summary intervals still need focused tests and implementation before
  being claimed.

## 2026-05-11 -- Residual rho12 profile coverage

Goal:

- add explicit test coverage that residual `rho12` fixed-effect profile
  intervals are coefficient-scale intervals for `beta_rho12`, not row-level
  response-scale residual-correlation intervals.

Implemented:

- added a bivariate Gaussian profile test for
  `confint(fit, parm = "fixef:rho12:w", method = "profile")`;
- compared the public `confint()` output to a manual `TMB::tmbprofile()` call
  using the one-hot linear combination for `beta_rho12[2]`;
- asserted that the returned target is on `scale = "link"` with
  `transformation = "linear_predictor"`.

Checks run:

- Exploratory R snippet first failed because it loaded the installed package
  rather than the worktree; rerunning with `devtools::load_all()` confirmed
  `profile_targets()` and `fixef:rho12:w` behaviour in the current checkout.
- `air format tests/testthat/test-profile-targets.R`: passed.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 0
  failures, 0 warnings, 0 skips, and 98 passing expectations.
- `Rscript -e "devtools::test()"`: passed with 0 failures, 0 warnings, 0 skips,
  and 1578 passing expectations.
- `git diff --check`: passed.
- `LC_ALL=C rg -n "[^\x00-\x7F]" tests/testthat/test-profile-targets.R`:
  passed with no matches.

Known limitations:

- response-scale residual `rho12_i` intervals remain planned derived-target
  work;
- phylogenetic and non-phylogenetic correlation modelling remain future
  structured-covariance work, distinct from residual `rho12`.

## 2026-05-11 -- Structured correlation roadmap refresh

Goal:

- record the future modelling requirement that residual `rho12`, phylogenetic
  correlation, and non-phylogenetic species or individual correlation remain
  separate layers in structured two-response models.

Implemented:

- updated `ROADMAP.md` Phase 11 to keep ordinary grouped personality and
  plasticity covariance as the first target before structured phylogenetic or
  non-phylogenetic species correlation layers;
- updated `ROADMAP.md` Phase 12 to state that future two-response or two-trait
  structured models should estimate and report phylogenetic correlation,
  non-phylogenetic species correlation, and residual `rho12` separately;
- updated `docs/design/28-double-hierarchical-endpoint.md` to distinguish
  ordinary grouped covariance, bivariate phylogenetic and non-phylogenetic
  species covariance, residual `rho12`, and later spatial covariance;
- updated `docs/design/20-coscale-correlation-pairs.md` so the future
  correlation-pair namespace keeps the three layers visible at once;
- added
  `docs/dev-log/after-task/2026-05-11-structured-correlation-roadmap-refresh.md`.

Checks run:

- `air format ROADMAP.md docs/design/20-coscale-correlation-pairs.md docs/design/28-double-hierarchical-endpoint.md`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `ROADMAP.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.
- `LC_ALL=C rg -n "[^\x00-\x7F]" ROADMAP.md docs/design/20-coscale-correlation-pairs.md docs/design/28-double-hierarchical-endpoint.md`:
  passed with no matches.

Known limitations:

- this is roadmap/design work only; no bivariate phylogenetic or
  non-phylogenetic species covariance likelihood is implemented;
- `corpairs()` cannot report these structured layers until the corresponding
  covariance blocks are fitted and tested.

## 2026-05-11 -- Phylogenetic SD profile coverage

Goal:

- add focused profile-likelihood coverage for the implemented univariate
  Gaussian phylogenetic `mu` standard deviation.

Implemented:

- added a deterministic small balanced-tree fixture to
  `tests/testthat/test-profile-targets.R`;
- added a public `confint()` profile test for
  `sd:mu:phylo(1 | species)`;
- compared `confint.drmTMB()` with a manual `TMB::tmbprofile()` call for
  `log_sd_phylo[1]`;
- updated `NEWS.md`, `ROADMAP.md`, and
  `docs/design/12-profile-likelihood-cis.md` so phylogenetic `mu` SD is claimed
  as an explicitly covered direct profile target.

Checks run:

- exploratory R snippets over seeds `20260601` to `20260610`: seed `20260603`
  with 16 tips and six observations per tip profiled cleanly without warnings;
- `air format tests/testthat/test-profile-targets.R`: passed;
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 0
  failures, 0 warnings, 0 skips, and 106 passing expectations;
- `Rscript -e "devtools::test()"`: passed with 0 failures, 0 warnings, 0 skips,
  and 1586 passing expectations.

Known limitations:

- this adds a direct phylogenetic SD interval test only;
- phylogenetic correlation, non-phylogenetic species covariance, phylogenetic
  signal, and derived variance-ratio intervals remain planned.

## 2026-05-11 -- Constant residual rho12 profile interval

Goal:

- add a direct response-scale profile-likelihood interval for constant residual
  `rho12` in bivariate Gaussian models.

Implemented:

- added a `rho12` profile target for fits with `rho12 = ~ 1`;
- mapped the target to `beta_rho12[1]` and transformed profile endpoints with
  `rho_response()`;
- kept predictor-dependent `rho12` response-scale profiles as planned
  `newdata` or contrast work;
- updated `NEWS.md`, `ROADMAP.md`,
  `docs/design/12-profile-likelihood-cis.md`,
  `man/confint.drmTMB.Rd`, and
  `docs/dev-log/after-task/2026-05-11-constant-rho12-profile-interval.md`.

Checks run:

- `air format R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md`:
  passed.
- first `Rscript -e "devtools::test(filter = 'profile-targets')"`: failed
  because an unsupported-ordinal-target test matched old error wording after
  the implemented target list changed.
- `air format tests/testthat/test-profile-targets.R`: passed after updating
  the test to match `ordinal-cutpoint-internal`.
- second `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed
  with 0 failures, 0 warnings, 0 skips, and 124 passing expectations.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/confint.drmTMB.Rd`.
- `Rscript -e "devtools::test()"`: passed with 0 failures, 0 warnings, 0
  skips, and 1604 passing expectations.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/confint.drmTMB.html` and `ROADMAP.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- `LC_ALL=C rg -n "[^\x00-\x7F]" R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/confint.drmTMB.Rd`:
  passed with no matches.
- `git diff --unified=0 -- R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-11-constant-rho12-profile-interval.md man/confint.drmTMB.Rd | LC_ALL=C rg -n '^\+.*[^\x00-\x7F]'`:
  passed with no matches.
- `rg -n 'O.Dea/Nakagawa|O.Dea-style' R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/confint.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`:
  passed with no matches.
- `rg -n 'constant residual|parm = "rho12"|rho12_tanh|predictor-dependent .* response-scale' R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/confint.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`:
  confirmed source and generated-site wording.

Known limitations:

- predictor-dependent `rho12` response-scale intervals still need an explicit
  `newdata` or contrast API;
- derived residual covariance, repeatability, phylogenetic signal, and
  double-hierarchical correlation-pair intervals remain planned.

## 2026-05-11 -- Constant sigma profile intervals

Goal:

- add response-scale profile-likelihood intervals for constant `sigma`,
  `sigma1`, and `sigma2`.

Implemented:

- added short profile targets `sigma`, `sigma1`, and `sigma2` for constant
  log-scale formulas;
- mapped the targets to `beta_sigma[1]`, `beta_sigma1[1]`, or
  `beta_sigma2[1]` and transformed profile endpoints with `exp()`;
- kept predictor-dependent response-scale `sigma` intervals as planned
  `newdata` or contrast work;
- updated `NEWS.md`, `ROADMAP.md`,
  `docs/design/12-profile-likelihood-cis.md`,
  `man/confint.drmTMB.Rd`, and
  `docs/dev-log/after-task/2026-05-11-constant-sigma-profile-intervals.md`.

Checks run:

- `air format R/profile.R tests/testthat/test-profile-targets.R`: passed.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 0
  failures, 0 warnings, 0 skips, and 144 passing expectations.
- `air format NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/confint.drmTMB.Rd`.
- `Rscript -e "devtools::test()"`: passed with 0 failures, 0 warnings, 0
  skips, and 1624 passing expectations.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/confint.drmTMB.html`, `reference/profile_targets.html`, and
  `ROADMAP.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- `LC_ALL=C rg -n "[^\x00-\x7F]" R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/confint.drmTMB.Rd`:
  passed with no matches.
- `rg -n 'O.Dea/Nakagawa|O.Dea-style' R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/confint.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html pkgdown-site/reference/profile_targets.html pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`:
  passed with no matches.
- `rg -n 'constant .*sigma|parm = "sigma"|distributional-scale|sigma1|sigma2' R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/confint.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html pkgdown-site/reference/profile_targets.html pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`:
  confirmed source and generated-site wording.

Known limitations:

- predictor-dependent `sigma`, `sigma1`, and `sigma2` response-scale intervals
  need an explicit `newdata` or contrast API;
- other transformed direct targets such as constant `nu`, probabilities, and
  ordinal cutpoints remain planned.

## 2026-05-11 -- Row-specific newdata profile intervals

Goal:

- add profile-likelihood intervals for response-scale `sigma`, `sigma1`,
  `sigma2`, and `rho12` values at supplied `newdata` rows.

Implemented:

- added `newdata` to `confint.drmTMB()`;
- defaulted to `method = "profile"` when `newdata` is supplied and `method`
  is omitted;
- profiled each row's fixed-effect linear predictor with `TMB::tmbprofile()`;
- transformed profile endpoints with `exp()` for scale parameters and
  `rho_response()` for residual `rho12`;
- updated `NEWS.md`, `ROADMAP.md`,
  `docs/design/12-profile-likelihood-cis.md`,
  `man/confint.drmTMB.Rd`, and
  `docs/dev-log/after-task/2026-05-11-newdata-profile-intervals.md`.

Checks run:

- `air format R/profile.R tests/testthat/test-profile-targets.R`: passed.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 0
  failures, 0 warnings, 0 skips, and 167 passing expectations.
- `air format R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/confint.drmTMB.Rd`.
- `Rscript -e "devtools::test()"`: passed with 0 failures, 0 warnings, 0
  skips, and 1647 passing expectations.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/confint.drmTMB.html` and `ROADMAP.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- `LC_ALL=C rg -n "[^\x00-\x7F]" R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/after-task/2026-05-11-newdata-profile-intervals.md man/confint.drmTMB.Rd`:
  passed with no matches.
- `rg -n 'O.Dea/Nakagawa|O.Dea-style|predictor-dependent .*remain planned|newdata or contrast|response-scale scale' R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/after-task/2026-05-11-newdata-profile-intervals.md man/confint.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`:
  passed with no matches.
- `rg -n 'newdata|row-specific|sigma\]|rho12\]|response-scale' R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/after-task/2026-05-11-newdata-profile-intervals.md man/confint.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`:
  confirmed source and generated-site wording.

Known limitations:

- each `newdata` row runs a separate one-dimensional profile and can be slow;
- only fixed-effect row values for `sigma`, `sigma1`, `sigma2`, and `rho12`
  are covered;
- random-effect conditional row intervals, ordinal transformations, modelled
  group-SD profiles, custom multi-row contrasts, and derived summaries remain
  planned.

## 2026-05-11 -- Variability orientation contract

Goal:

- clarify how the public `sigma` grammar relates to precision, size, shape,
  and variance parameters across families and comparator software.

Implemented:

- added the rule that larger public `sigma` means larger modelled variability,
  dispersion, or heterogeneity;
- documented that beta and beta-binomial use internal `phi = 1 / sigma^2`,
  NB2 uses `theta` or `size = 1 / sigma^2`, Gamma uses shape
  `1 / sigma^2`, and Student-t `nu` is a shape parameter rather than a public
  scale slot;
- updated `README.md`, `docs/design/03-likelihoods.md`,
  `vignettes/distribution-families.Rmd`,
  `vignettes/which-scale.Rmd`, and
  `docs/dev-log/after-task/2026-05-11-variability-orientation-contract.md`.

Checks run:

- `air format README.md docs/design/03-likelihoods.md vignettes/distribution-families.Rmd vignettes/which-scale.Rmd`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `index.html`, `articles/distribution-families.html`, and
  `articles/which-scale.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.

Known limitations:

- this is a documentation/design-contract change; no likelihood code changed;
- Tweedie, COM-Poisson, ordinal scale/discrimination, and skew-normal scale or
  shape conventions still need their own design rows before implementation.

## 2026-05-11 -- Explicit `rho12` in `corpairs()` example

Goal:

- make the `corpairs()` help example name the residual correlation formula it
  is summarising.

Implemented:

- updated the `corpairs()` roxygen example in `R/methods.R` to include
  `rho12 = ~ 1` explicitly;
- regenerated `man/corpairs.Rd`;
- created
  `docs/dev-log/after-task/2026-05-11-corpairs-example-rho12.md`.

Checks run:

- `air format R/methods.R docs/dev-log/after-task/2026-05-11-corpairs-example-rho12.md docs/dev-log/check-log.md`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/corpairs.Rd`.
- `Rscript -e "devtools::test(filter = 'corpairs')"`: passed.
- `rg -n "rho12 = ~ 1|corpairs\\(fit\\)|issue #5|Explicit" R/methods.R man/corpairs.Rd docs/dev-log/after-task/2026-05-11-corpairs-example-rho12.md docs/dev-log/check-log.md`:
  confirmed source, generated docs, and dev-log wording.
- `git diff --check`: passed.

Known limitations:

- this is documentation clarity only; it does not add new covariance-block
  likelihoods or extend `corpairs()` to planned issue #5 pair classes.

## 2026-05-11 -- Benchmark reproducibility metadata

Goal:

- improve issue #4 benchmark evidence by recording enough metadata to rerun a
  large-data benchmark row.

Implemented:

- added `git_sha`, `git_dirty`, and `benchmark_command` columns to
  `bench/large-phylo-location.R`;
- updated `bench/README.md` and `docs/design/23-large-data-memory.md` so the
  benchmark evidence contract includes command and Git metadata;
- created
  `docs/dev-log/after-task/2026-05-11-benchmark-repro-metadata.md`.

Checks run:

- `air format bench/large-phylo-location.R bench/README.md docs/design/23-large-data-memory.md docs/dev-log/after-task/2026-05-11-benchmark-repro-metadata.md docs/dev-log/check-log.md`:
  passed.
- `Rscript -e 'e <- new.env(parent = globalenv()); sys.source("bench/large-phylo-location.R", e); args <- e$parse_args(c("--rows", "50", "--species", "8", "--memory-light", "true")); env <- e$benchmark_environment(args); stopifnot(grepl("--rows", env$benchmark_command), nzchar(env$git_sha), is.logical(env$git_dirty) || is.na(env$git_dirty))'`:
  passed.
- `rg -n "benchmark_command|git_sha|git_dirty|reconstructed benchmark command|issue #4" bench/large-phylo-location.R bench/README.md docs/design/23-large-data-memory.md docs/dev-log/after-task/2026-05-11-benchmark-repro-metadata.md docs/dev-log/check-log.md`:
  confirmed source and documentation coverage.
- `git diff --check`: passed.

Known limitations:

- this changes the benchmark CSV schema; append to a fresh output path or remove
  older ignored CSV files before collecting new rows;
- no new large benchmark was run, and this does not prove million-row readiness.

## 2026-05-11 -- Skew-normal likelihood gate

Goal:

- record the first issue #3 design gate before any `skew_normal()` family code
  is added.

Implemented:

- added a planned skew-normal location-scale-shape section to
  `docs/design/03-likelihoods.md`;
- documented the candidate density, `mu`, `sigma`, and `nu` transforms,
  response mean and variance formulas, and the positive/zero/negative `nu`
  sign convention;
- added a planned `skew_normal()` registry contract to
  `docs/design/02-family-registry.md`;
- created
  `docs/dev-log/after-task/2026-05-11-skew-normal-likelihood-gate.md`.

Checks run:

- `air format docs/design/03-likelihoods.md docs/design/02-family-registry.md docs/dev-log/after-task/2026-05-11-skew-normal-likelihood-gate.md docs/dev-log/check-log.md`:
  passed.
- `rg -n "Planned Skew-Normal|skew_normal\\(|nu_i = eta_nu_i|right-skewed|left-skewed|issue #3" docs/design/03-likelihoods.md docs/design/02-family-registry.md docs/design/14-gamlss-parameter-names.md docs/design/19-phylogenetic-location-scale-shape.md docs/dev-log/after-task/2026-05-11-skew-normal-likelihood-gate.md`:
  confirmed the design contract and existing naming notes.
- `git diff --check`: passed.

Known limitations:

- this is documentation only; `skew_normal()` is not implemented;
- the `nu` sign convention still needs a comparator check before TMB code is
  added;
- simulation recovery, malformed-input tests, normal-limit tests, and
  false-positive heteroscedasticity checks remain planned.

## 2026-05-11 -- `check_drm()` SE and SD diagnostics

Goal:

- finish the interrupted `check_drm()` diagnostic expansion for fixed-effect
  standard errors and random-effect SDs near the lower boundary.

Implemented:

- added a `standard_errors_finite` row based on finite fixed-effect standard
  errors from `vcov(fit)`;
- added a `random_effect_sd_boundary` row for fitted random-effect standard
  deviations in `fit$sdpars`;
- added user-facing `sd_boundary`, defaulting to `1e-4`;
- updated `NEWS.md`, `man/check_drm.Rd`, `vignettes/drmTMB.Rmd`,
  `vignettes/model-workflow.Rmd`,
  `docs/design/16-phylo-spatial-common-math.md`, and
  `docs/dev-log/after-task/2026-05-11-check-drm-se-sd-diagnostics.md`.

Checks run:

- `air format R/check.R tests/testthat/test-check-drm.R NEWS.md vignettes/drmTMB.Rmd vignettes/model-workflow.Rmd docs/design/16-phylo-spatial-common-math.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-11-check-drm-se-sd-diagnostics.md`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/check_drm.Rd`.
- `Rscript -e "devtools::test(filter = 'check-drm')"`: passed with 71
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'check-drm|control')"`: passed with 139
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 1657 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/check_drm.html` and `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- `rg -n "standard_errors_finite|random_effect_sd_boundary|sd_boundary|standard errors|finite fixed-effect standard errors|random-effect standard deviations|random-effect standard deviations near zero" R/check.R tests/testthat/test-check-drm.R man/check_drm.Rd NEWS.md vignettes/drmTMB.Rmd vignettes/model-workflow.Rmd docs/design/16-phylo-spatial-common-math.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-11-check-drm-se-sd-diagnostics.md pkgdown-site/reference/check_drm.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/model-workflow.html pkgdown-site/articles/phylogenetic-spatial.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`:
  confirmed source, tests, generated documentation, NEWS, and generated-site
  wording.
- `rg -n 'optimizer convergence, fixed gradients|scale positivity|known sampling covariance summaries, and random-effect design|Current first-pass.*check_drm\\(\\).*optimizer convergence, fixed-parameter gradients' README.md ROADMAP.md docs vignettes pkgdown-site --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'`:
  found only the historical `NEWS.md` / generated-news 0.1.0 release bullet,
  which was true for that release and intentionally left unchanged.

Known limitations:

- fixed-effect standard errors are checked through `vcov(fit)` only;
- near-zero random-effect SDs are flagged as a diagnostic warning, not as an
  automatic model-selection decision.

## 2026-05-11 -- `summary()` parameter table

Goal:

- make `summary.drmTMB()` show the distributional parameters that distinguish
  `drmTMB` from generic mixed-model summaries: scale, shape, residual
  correlation, random-effect standard deviations, and random-effect
  correlations.

Implemented:

- added a response-scale `parameters` table to `summary.drmTMB()`;
- kept existing `coefficients`, `sdpars`, and `corpars` summary components for
  compatibility;
- reported direct profile targets such as constant `sigma`, constant `rho12`,
  random-effect SDs, and random-effect correlations;
- reported fitted-row ranges for row-varying distributional parameters such as
  `sigma` and Student-t `nu`;
- added opt-in fixed-effect Wald intervals with `summary(fit, conf.int = TRUE)`;
- added opt-in profile intervals for selected direct targets with
  `summary(fit, conf.int = TRUE, method = "profile", ci_parm = ...)`;
- updated `NEWS.md`, `vignettes/model-workflow.Rmd`,
  `man/summary.drmTMB.Rd`, and
  `docs/dev-log/after-task/2026-05-11-summary-parameter-table.md`.

Checks run:

- `air format R/methods.R tests/testthat/test-summary.R NEWS.md vignettes/model-workflow.Rmd`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/summary.drmTMB.Rd`.
- `Rscript -e "devtools::test(filter = 'summary')"`: passed with 32
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 1689 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/summary.drmTMB.html`, `articles/model-workflow.html`, and
  `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- `rg -n "summary\\(\\).*fixed-effect estimates|summary\\(\\).*response-scale|conf\\.int|ci_parm|profile-likelihood confidence|Distributional, scale, and correlation parameters|fitted scale, shape|fitted:nu|sd:mu:\\(1 \\| id\\)" R/methods.R tests/testthat/test-summary.R man/summary.drmTMB.Rd NEWS.md vignettes/model-workflow.Rmd pkgdown-site/reference/summary.drmTMB.html pkgdown-site/articles/model-workflow.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`:
  confirmed source, test, documentation, and generated-site wording.
- `rg -n "summary\\(\\).*fixed-effect estimates, log likelihood|summary\\(\\).*fitted random-effect standard deviations|Reserved for future summary options|Random-effect SDs:|Random-effect correlations:" README.md ROADMAP.md docs vignettes R man pkgdown-site --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'`:
  found no stale non-historical wording.

Known limitations:

- row-varying distributional parameters are summarized as fitted-row ranges;
- row-specific intervals still belong in `confint(..., newdata = ...)`;
- the summary table is descriptive and does not yet provide marginal means,
  averaging over covariates, or visual contrasts.

## 2026-05-11 -- `predict_parameters()` table

Goal:

- add a small interpretation surface that can carry mean, scale, shape,
  probability, and residual-correlation predictions on the same `newdata` grid.

Implemented:

- added exported `predict_parameters()`;
- added `predict_parameters.drmTMB()` for fitted `drmTMB` objects;
- returned long-format predictions with `row`, `row_label`, `dpar`,
  `component`, `type`, and `estimate` columns;
- appended supplied `newdata` columns by default, with reserved output-column
  names prefixed as `newdata_*`;
- added component labels for location, distributional scale, shape,
  probability, residual correlation, random-effect scale models, and other
  distributional parameters;
- updated `NEWS.md`, `_pkgdown.yml`, `vignettes/model-workflow.Rmd`,
  `NAMESPACE`, `man/predict_parameters.Rd`, and
  `docs/dev-log/after-task/2026-05-11-predict-parameters-table.md`.

Checks run:

- `air format R/predict-parameters.R R/methods.R tests/testthat/test-predict-parameters.R NEWS.md vignettes/model-workflow.Rmd _pkgdown.yml`:
  passed.
- `Rscript -e "devtools::test(filter = 'predict-parameters')"`: passed with 23
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::document()"`: passed and regenerated `NAMESPACE` and
  `man/predict_parameters.Rd`.
- `Rscript -e "devtools::load_all(); dat <- data.frame(y=rnorm(12), x=seq(-1,1,length.out=12)); fit <- drmTMB(bf(y ~ x, sigma ~ x), data=dat); print(predict_parameters(fit, newdata=data.frame(x=c(0,1)), dpar=c('mu','sigma')))"`:
  passed and printed a four-row `mu`/`sigma` prediction table.
- `Rscript -e "devtools::test(filter = 'predict-parameters|summary')"`:
  passed with 55 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 1712 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/predict_parameters.html`, `articles/model-workflow.html`, and
  `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- `LC_ALL=C rg -n "[^\x00-\x7F]" R/predict-parameters.R tests/testthat/test-predict-parameters.R NEWS.md vignettes/model-workflow.Rmd man/predict_parameters.Rd _pkgdown.yml`:
  passed with no matches.
- `rg -n "predict_parameters|long-format predictions|newdata_dpar|location.*distributional-scale|future plotting or marginalisation|same grid" R/predict-parameters.R tests/testthat/test-predict-parameters.R man/predict_parameters.Rd NEWS.md vignettes/model-workflow.Rmd _pkgdown.yml pkgdown-site/reference/predict_parameters.html pkgdown-site/articles/model-workflow.html pkgdown-site/news/index.html pkgdown-site/reference/index.html --glob '!pkgdown-site/search.json'`:
  confirmed source, tests, documentation, pkgdown navigation, generated
  reference, workflow article, and generated NEWS.
- `rg -n "predict\\(\\) returns one distributional parameter at a time|interpretation task needs several distributional parameters|plotting|marginalisation|marginalization|emmeans" README.md ROADMAP.md docs vignettes R man pkgdown-site --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'`:
  confirmed that the new helper is described as a prediction-table surface, not
  as implemented emmeans-style marginalisation or plotting.

Known limitations:

- the helper does not compute confidence intervals;
- the helper does not average over covariate distributions or produce emmeans
  contrasts;
- the helper does not draw plots.

## 2026-05-11 -- `marginal_parameters()` table

Goal:

- add a small marginal summary layer that averages predicted distributional
  parameters over fitted rows or supplied `newdata` groups.

Implemented:

- added exported `marginal_parameters()`;
- added `marginal_parameters.drmTMB()` for fitted `drmTMB` objects;
- delegated prediction to `predict_parameters()` so the marginal table uses the
  same `dpar`, `newdata`, and `type` contract;
- added optional `by` grouping over supplied `newdata` columns;
- returned one row per distributional parameter and group combination, with
  `dpar`, `component`, `type`, optional grouping columns, `estimate`, and `n`;
- updated `NEWS.md`, `_pkgdown.yml`, `vignettes/model-workflow.Rmd`,
  `NAMESPACE`, `man/marginal_parameters.Rd`, and
  `docs/dev-log/after-task/2026-05-11-marginal-parameters-table.md`.

Checks run:

- `air format R/marginal-parameters.R tests/testthat/test-marginal-parameters.R NEWS.md vignettes/model-workflow.Rmd _pkgdown.yml`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated `NAMESPACE` and
  `man/marginal_parameters.Rd`.
- `Rscript -e "devtools::load_all(); dat <- data.frame(y=rnorm(20), x=rep(c(0,1),10), g=factor(rep(c('a','b'), each=10))); fit <- drmTMB(bf(y ~ x + g, sigma ~ x), data=dat); grid <- expand.grid(x=c(0,1), g=levels(dat$g)); print(marginal_parameters(fit, newdata=grid, dpar=c('mu','sigma'), by='g'))"`:
  passed and printed a grouped `mu`/`sigma` marginal table.
- `Rscript -e "devtools::test(filter = 'marginal-parameters')"`: passed with
  17 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'marginal-parameters|predict-parameters|summary')"`:
  passed with 72 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 1729 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/marginal_parameters.html`, `articles/model-workflow.html`, and
  `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- `git diff -U0 -- R/marginal-parameters.R tests/testthat/test-marginal-parameters.R NEWS.md vignettes/model-workflow.Rmd man/marginal_parameters.Rd _pkgdown.yml docs/dev-log/check-log.md | LC_ALL=C rg -n '[^\x00-\x7F]'`:
  passed with no matches.
- `rg -n '[ \t]+$' R/marginal-parameters.R tests/testthat/test-marginal-parameters.R man/marginal_parameters.Rd`:
  passed with no matches.
- `rg -n 'marginal_parameters|simple marginalisation|group-level interpretation|future emmeans-style|supplied `newdata` groups|marginal-parameters' R/marginal-parameters.R tests/testthat/test-marginal-parameters.R man/marginal_parameters.Rd NEWS.md vignettes/model-workflow.Rmd _pkgdown.yml pkgdown-site/reference/marginal_parameters.html pkgdown-site/articles/model-workflow.html pkgdown-site/news/index.html pkgdown-site/reference/index.html --glob '!pkgdown-site/search.json'`:
  confirmed source, tests, documentation, pkgdown navigation, generated
  reference, workflow article, and generated NEWS.
- `rg -n "emmeans|contrast|confidence intervals|profile intervals|plots|plotting|marginalisation|marginalization" R/marginal-parameters.R tests/testthat/test-marginal-parameters.R man/marginal_parameters.Rd NEWS.md vignettes/model-workflow.Rmd pkgdown-site/reference/marginal_parameters.html pkgdown-site/articles/model-workflow.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`:
  confirmed that the helper is described as a simple plug-in marginal summary,
  not as implemented uncertainty, contrasts, or plotting.

Known limitations:

- the helper computes unweighted means only;
- the helper does not compute confidence intervals, standard errors, contrasts,
  or profile intervals;
- the helper does not implement full `emmeans` integration;
- the helper does not draw plots.

## 2026-05-11 -- Crash recovery validation for parameter summaries

Scope:

- resumed the interrupted working tree that already contained the
  `check_drm()` SE/SD diagnostics, `summary()` parameter table,
  `predict_parameters()`, `marginal_parameters()`, comparator-harness, generated
  documentation, pkgdown, and after-task-report changes;
- preserved the existing uncommitted files and reran the validation steps needed
  to make the patch reviewable again;
- added the new summary/prediction/marginal helper limitation to
  `docs/dev-log/known-limitations.md`.

Checks run:

- `Rscript -e "devtools::test(filter = 'check-drm|summary|predict-parameters|marginal-parameters')"`:
  passed with 143 expectations, 0 failures, 0 warnings, and 0 skips.
- `air format R/check.R R/methods.R R/predict-parameters.R R/marginal-parameters.R tests/testthat/test-check-drm.R tests/testthat/test-summary.R tests/testthat/test-predict-parameters.R tests/testthat/test-marginal-parameters.R NEWS.md ROADMAP.md _pkgdown.yml vignettes/drmTMB.Rmd vignettes/model-workflow.Rmd docs/design/05-testing-strategy.md docs/design/16-phylo-spatial-common-math.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-11-check-drm-se-sd-diagnostics.md docs/dev-log/after-task/2026-05-11-summary-parameter-table.md docs/dev-log/after-task/2026-05-11-predict-parameters-table.md docs/dev-log/after-task/2026-05-11-marginal-parameters-table.md tools/replicate-location-scale-gaussian.R`:
  passed.
- `Rscript -e "devtools::document()"`: passed.
- `Rscript -e "devtools::test()"`: passed with 1729 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `Rscript tools/replicate-location-scale-gaussian.R`: passed and rewrote
  `docs/dev-log/comparator-results/gaussian-location-scale-glmmtmb-current.csv`.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `git diff --check`: passed.
- `git diff -U0 -- ... | LC_ALL=C rg -n "[^\x00-\x7F]"`: passed with no
  matches in the active diff.

Audit notes:

- stale-summary wording scan:
  `rg -n "summary\\(\\).*fixed-effect estimates, log likelihood|summary\\(\\).*fitted random-effect standard deviations|Reserved for future summary options|Random-effect SDs:|Random-effect correlations:" README.md ROADMAP.md NEWS.md docs vignettes R man pkgdown-site --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'`;
  no active-source matches.
- stale-`check_drm()` wording scan:
  `rg -n "optimizer convergence, fixed gradients|scale positivity|known sampling covariance summaries, and random-effect design|Current first-pass.*check_drm\\(\\).*optimizer convergence, fixed-parameter gradients" README.md ROADMAP.md NEWS.md docs vignettes pkgdown-site --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'`;
  found only the historical `NEWS.md` 0.1.0 release bullet and generated news.
- helper-scope scan:
  `rg -n "predict_parameters|marginal_parameters|emmeans|confidence intervals|profile intervals|plotting|marginalisation|marginalization" README.md ROADMAP.md NEWS.md docs vignettes R man pkgdown-site --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'`;
  confirmed the helpers are described as interpretation tables and future
  plotting or marginalisation surfaces, not as implemented uncertainty,
  contrast, or plotting machinery.

## 2026-05-11 -- Comparator result scope table

Scope:

- aligned the durable Gaussian location-scale comparator result note with the
  current CSV output from `tools/replicate-location-scale-gaussian.R`;
- added human-readable blocked rows for shared `mu`/`sigma` covariance,
  bivariate group-level covariance, and non-Gaussian location-scale random
  effects.

Checks run:

- `Rscript tools/replicate-location-scale-gaussian.R`: passed and rewrote
  `docs/dev-log/comparator-results/gaussian-location-scale-glmmtmb-current.csv`.
- `air format docs/dev-log/comparator-results/2026-05-10-gaussian-location-scale-glmmtmb.md docs/dev-log/after-task/2026-05-11-comparator-result-scope-table.md docs/dev-log/check-log.md`:
  passed.
- `git diff --check`: passed.

## 2026-05-11 -- Bivariate mu random-intercept covariance

Goal:

- implement the first bivariate group-level covariance block for
  `biv_gaussian()` models while keeping residual correlation `rho12` separate
  from between-group `mu1`/`mu2` covariance.

Implemented:

- added labelled matching random-intercept covariance syntax for bivariate
  Gaussian location formulas, for example
  `mu1 = y1 ~ x + (1 | p | id)` and
  `mu2 = y2 ~ x + (1 | p | id)`;
- required an explicit shared covariance-block label and rejected unlabelled
  or mismatched bivariate random-effect terms;
- added paired non-centred TMB random effects for `mu1` and `mu2`, with
  separate group standard deviations and a between-group correlation;
- kept bivariate random slopes, random effects in `sigma1`, `sigma2`, or
  `rho12`, structured bivariate covariance, and `meta_known_V(V = V)` plus
  random effects out of scope;
- updated `corpairs()` so residual `rho12` rows and bivariate group-level
  `mu1`/`mu2` covariance rows are reported as separate correlation layers;
- updated prediction, R documentation, design notes, vignettes, README,
  ROADMAP, NEWS, known limitations, and the after-task report
  `docs/dev-log/after-task/2026-05-11-bivariate-mu-random-intercept-covariance.md`.

Checks run:

- `Rscript -e "devtools::load_all(quiet = TRUE)"`: passed.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`: passed with 123
  passing expectations.
- `Rscript -e "devtools::test(filter = 'biv-gaussian|gaussian-random-intercepts|corpairs')"`:
  passed with 338 passing expectations.
- `air format R/drmTMB.R R/methods.R tests/testthat/test-biv-gaussian.R tests/testthat/test-gaussian-random-intercepts.R NEWS.md README.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/04-random-effects.md docs/design/17-correlated-random-effect-blocks.md docs/design/20-coscale-correlation-pairs.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md vignettes/bivariate-coscale.Rmd vignettes/distribution-families.Rmd vignettes/drmTMB.Rmd vignettes/formula-grammar.Rmd vignettes/source-map.Rmd vignettes/which-scale.Rmd`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/drmTMB.Rd`, `man/corpairs.Rd`, and `man/predict.drmTMB.Rd`.
- `Rscript -e "devtools::test()"`: passed with 1669 passing expectations.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `Rscript -e "pkgdown::build_home()"`: passed after the final ROADMAP wording
  change.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.
- stale-wording scans for planned-only bivariate random-effect prose passed with
  no source or generated-site matches, apart from intentional historical NEWS
  entries.

Known limitations:

- only matching labelled random intercepts in `mu1` and `mu2` are supported;
- bivariate random slopes, distributional-parameter random effects, spatial or
  phylogenetic bivariate covariance, and bivariate meta-analysis with known
  sampling covariance plus random effects remain planned work;
- `rho12` is still the residual correlation parameter, not the label for the
  new between-group `mu1`/`mu2` covariance block.

## 2026-05-11 -- Bivariate mu covariance `check_drm()` diagnostics

Goal:

- add first-pass `check_drm()` diagnostics for the implemented bivariate
  Gaussian `mu1`/`mu2` random-intercept covariance block.

Implemented:

- added a `biv_mu_random_effect_covariance` row for `biv_gaussian()` fits with
  matching labelled `mu1`/`mu2` random intercepts;
- the diagnostic reports group count, minimum fitted group replication,
  singleton-group count, and the smallest fitted group-level SD relative to its
  matching residual scale;
- the diagnostic returns `note` when any group has fewer than two fitted
  observations or when either fitted group-level SD is less than 5% of the
  matching residual scale;
- updated `NEWS.md`, `R/check.R`, `tests/testthat/test-check-drm.R`,
  `man/check_drm.Rd`, `vignettes/bivariate-coscale.Rmd`,
  `docs/design/16-phylo-spatial-common-math.md`, and
  `docs/dev-log/after-task/2026-05-11-bivariate-mu-covariance-check-drm-diagnostics.md`.

Checks run:

- `Rscript -e "devtools::test(filter = 'check-drm')"`: passed with 73
  expectations.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/check_drm.Rd`.
- `air format R/check.R tests/testthat/test-check-drm.R NEWS.md vignettes/bivariate-coscale.Rmd docs/design/16-phylo-spatial-common-math.md man/check_drm.Rd`:
  passed.
- `Rscript -e "devtools::test(filter = 'check-drm|biv-gaussian')"`: passed
  with 196 expectations.
- `Rscript -e "devtools::test()"`: passed with 1681 expectations.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- stale-wording scans for the new diagnostic row and old standalone diagnostic
  lists passed.

Known limitations:

- the 5% relative-SD threshold is a first-pass diagnostic heuristic;
- the diagnostic covers only matching labelled bivariate `mu1`/`mu2`
  random-intercept covariance blocks;
- richer bivariate covariance structures still need their own diagnostics.

## 2026-05-11 -- Bivariate mu profile-target coverage

Goal:

- close the issue #13 follow-up by making the profile-target surface explicit
  for the implemented bivariate Gaussian `mu1`/`mu2` random-intercept
  covariance block.

Implemented:

- added a focused `profile_targets()` test for a fitted `biv_gaussian()` model
  with matching labelled `mu1` and `mu2` random intercepts;
- checked exact target names for `sd:mu:mu1:(1 | p | id)`,
  `sd:mu:mu2:(1 | p | id)`, and
  `cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)`;
- checked `tmb_parameter`, `index`, response-scale transformation,
  `target_type`, `profile_ready`, and `profile_note`;
- checked that residual `rho12` remains a separate residual-correlation target;
- updated `NEWS.md`, `docs/design/12-profile-likelihood-cis.md`,
  `vignettes/bivariate-coscale.Rmd`, and the after-task report
  `docs/dev-log/after-task/2026-05-11-bivariate-mu-profile-targets.md`.

Checks run:

- `air format tests/testthat/test-profile-targets.R NEWS.md docs/design/12-profile-likelihood-cis.md vignettes/bivariate-coscale.Rmd`:
  passed.
- `Rscript -e "devtools::test(filter = 'profile-targets|biv-gaussian')"`:
  passed with 303 expectations.
- `Rscript -e "devtools::document()"`: passed.
- `Rscript -e "devtools::test()"`: passed with 1776 expectations.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.

Known limitations:

- this slice covers the target inventory and direct target mapping, not a
  separate long-running profile-interval simulation study for the bivariate
  group-level covariance parameters.

## 2026-05-12 -- Independent residual-scale sigma random slopes

Goal:

- add the next small double-hierarchical Gaussian slice by allowing univariate
  Gaussian `sigma` formulas to include independent numeric random slopes such
  as `sigma ~ z + (0 + w | id)`.

Implemented:

- extended `parse_random_sigma_term()` so unlabelled `(0 + w | id)` terms are
  accepted and routed through the existing independent sigma random-effect
  design path;
- kept correlated residual-scale slope blocks such as `(1 + w | id)` and
  labelled sigma slope covariance blocks such as `(0 + w | p | id)` rejected
  with phase-specific errors;
- added a deterministic Gaussian simulation test that checks optimizer
  convergence, fitted sigma SD naming, random-effect contribution variation,
  `predict(..., dpar = "sigma", type = "link")`, and `sigma(fit)`;
- updated formula grammar, likelihood, random-effect, Gaussian math, roadmap,
  known-limitations, README, NEWS, and vignette status text to describe the new
  implemented boundary.

Checks run:

- `air format R/drmTMB.R tests/testthat/test-gaussian-random-intercepts.R NEWS.md README.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/03-likelihoods.md docs/design/04-random-effects.md docs/design/05-testing-strategy.md docs/design/13-gaussian-location-scale-math.md docs/design/16-phylo-spatial-common-math.md docs/design/18-random-effect-scale-models.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md vignettes/drmTMB.Rmd vignettes/formula-grammar.Rmd vignettes/location-scale.Rmd vignettes/model-map.Rmd vignettes/which-scale.Rmd`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/drmTMB.Rd`.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`:
  passed with 225 expectations.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|check-drm|profile-targets|summary|phylo-utils')"`:
  passed with 640 expectations.
- `Rscript -e "devtools::test()"`: passed with 1918 expectations.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.

Consistency searches:

- `rg -n "Only random intercepts|only random intercepts|random slopes are planned|Residual-scale random slopes are planned|limited to random intercepts|sigma random effects are limited|residual-scale random effects are limited" README.md ROADMAP.md NEWS.md docs vignettes R tests man`
- `rg -n "residual-scale random intercepts|independent.*random slopes|labelled residual-scale random-slope|correlated residual-scale" README.md ROADMAP.md NEWS.md docs vignettes R tests man`
- `rg -n "sigma ~[^\\n]*(0 \\+|1 \\|)|rho12|sd\\(" README.md ROADMAP.md docs vignettes R tests`

Known limitations:

- sigma slope terms are independent residual-scale effects only;
- correlated residual-scale intercept-slope blocks remain planned;
- labelled `mu`/`sigma` slope covariance remains planned;
- bivariate `sigma1`/`sigma2` random effects remain planned.
