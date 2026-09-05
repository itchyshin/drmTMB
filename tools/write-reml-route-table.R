#!/usr/bin/env Rscript
## Generate docs/design/261-reml-by-route.md: ONE table of REML support per
## route across native TMB (engine = "tmb"), native DRM.jl, and the R<->Julia
## bridge (engine = "julia"). drmTMB #1142 / DRM.jl #624.
##
## Regeneration is deterministic: every cell below is either (a) a value
## measured live in THIS leaf (A9f, 2026-09-05, drmTMB worktree HEAD at
## generation time, DRM.jl pin 430ef64cc), with its receipt under
## docs/dev-log/evidence/julia-r-parity/reml-by-route/, or (b) a citation to
## an existing receipt (A3 PR #1168, A5 PR #1170, DRM.jl issues/tests, prior
## drmTMB commits/comments) reproduced verbatim rather than re-measured, per
## the leaf's instruction not to re-measure what a sibling leaf already
## measured. No cell says "expected".
##
## Route list provenance (G1 -- printed below, not hand-typed away): every
## `capability_id` below is copied from the CURRENT `inst/extdata/julia-
## capabilities.tsv` (checked against it at `drm_reml_route_table_rows()`
## call time) or is one of A5's three ordinary-random-effect shapes
## (PR #1170), which is not yet a TSV row (A2 in the ultra-plan backlog owns
## adding one).
##
## Usable two ways: `Rscript tools/write-reml-route-table.R` regenerates
## `docs/design/261-reml-by-route.md` in place; `source()`-ing this file (as
## tests/testthat/test-reml-route-table.R does) defines
## `drm_reml_route_table_rows()` / `drm_reml_route_table_lines()` without any
## side effect, so a test can call the generator in-process instead of
## shelling out.

evidence_dir <- "docs/dev-log/evidence/julia-r-parity/reml-by-route"

## ---------------------------------------------------------------------
## Route rows. `id` must be a capability_id from the TSV, OR one of A5's
## three literal shape names (flagged `source = "A5-census"`).
## `verdict` values: "FITS" | "REFUSES" | "N/A" (route does not exist under
## any estimator on that engine).
## ---------------------------------------------------------------------
drm_reml_route_table_row <- function(id, sub, source, source_ref, formula,
                                      tmb, tmb_ev, drmjl, drmjl_ev, bridge, bridge_ev,
                                      agree, gap) {
  data.frame(
    capability_id = id, sub_family = sub, source = source, source_ref = source_ref,
    formula = formula, tmb_reml = tmb, tmb_evidence = tmb_ev,
    drmjl_reml = drmjl, drmjl_evidence = drmjl_ev,
    bridge_reml = bridge, bridge_evidence = bridge_ev,
    agree = agree, gap = gap,
    stringsAsFactors = FALSE
  )
}

#' Build the REML-by-route table as a data.frame.
#'
#' @param pkg_root Package root (must contain
#'   `inst/extdata/julia-capabilities.tsv`), used ONLY to assert every
#'   TSV-sourced `capability_id` below is a real row in that TSV (G1).
drm_reml_route_table_rows <- function(pkg_root = ".") {
  row <- drm_reml_route_table_row
  rows <- list(
    row("base_gaussian_location_scale", "", "TSV", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x, sigma ~ x), gaussian()",
        "FITS", "measured this run: logLik=-50.3636628254 (native_reml_probe.R, row 1)",
        "FITS", "DRM.jl #624 census (14-fit list, item 1: \"univariate fixed-effect Gaussian location-scale\")",
        "FITS", "measured this run: bridge fit succeeded, 31.4s incl. Julia boot (bridge_reml_probe.R, row 1)",
        "YES", ""),

    row("biv_gaussian_residual", "", "TSV", "inst/extdata/julia-capabilities.tsv",
        "bf(mu1=y1~x, mu2=y2~x, sigma1=~1, sigma2=~1, rho12=~1), biv_gaussian()",
        "FITS", "measured this run: logLik=-97.0212058184 (native_reml_probe.R, row 2); no abort branch in drm_validate_reml_spec_biv() triggers for a fixed-effect-only bivariate model",
        "REFUSES", "DRM.jl #624 comment 2, 16-refuse list: \"bivariate residual-only Gaussian/LogNormal/Student\"",
        "REFUSES", "measured this run: `engine=\"julia\" cannot fit bivariate Gaussian models by REML=TRUE` (bridge_reml_probe.R, row 2); drm_julia_reml_supported() requires biv_phylo_dimension()==\"q4\", which a plain residual model never has",
        "NO", "NEW finding (drmTMB #1142 / DRM.jl #624, \"REML wherever possible\" half): native TMB fits a plain fixed-effect bivariate Gaussian REML that neither DRM.jl native nor the bridge admits. Not one of #624's three named items."),

    row("gaussian_phylo_mean", "", "TSV", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x + phylo(1|species, tree=tree), sigma ~ 1), gaussian()",
        "FITS", "measured this run: logLik=-14.6046181690 (native_reml_probe.R, row 6); corroborated by tests/testthat/test-reml-phylo-location.R (existing suite, not re-run here)",
        "REFUSES", "DRM.jl #624 item (c) verbatim: \"a Gaussian mean-only phylo(1|species) model refuses REML, while the same tree with an sd() submodel fits it... certainly possible; that asymmetry is a capability gap\"",
        "REFUSES", "measured this run: `engine=\"julia\" cannot fit mean-only phylogenetic Gaussian models by REML=TRUE` (bridge_reml_probe.R, row 3)",
        "NO", "DRM.jl #624 item (c) -- explicitly OUT OF SCOPE for this leaf per the task brief; recorded verbatim, not re-litigated."),

    row("gaussian_response_mask", "", "TSV", "inst/extdata/julia-capabilities.tsv",
        "same phylo-mean cell as above, missing=miss_control(response=\"include\")",
        "REFUSES", "measured this run: `REML is not implemented with explicit missing-data engines yet` (native_reml_probe.R, row 7) -- a DIFFERENT refusal reason than the phylo-mean gate above; response=\"include\" itself trips a generic missing-data-engine gate for ANY family",
        "REFUSES", "same underlying cell as gaussian_phylo_mean (DRM.jl #624 item (c)); no separate native call corresponds to \"include\" outside the bridge",
        "REFUSES", "measured this run: same mean-only-phylo refusal text as gaussian_phylo_mean (bridge_reml_probe.R, row 4) -- the missing-data mask does not change which REML gate fires first",
        "YES", "Agree on REFUSE, but for two DIFFERENT reasons across engines (TMB: missing-data-engine gate; bridge: mean-only-phylo gate). Noted, not a defect."),

    row("biv_q4_phylo_reml", "", "TSV", "inst/extdata/julia-capabilities.tsv",
        "biv_gaussian() q4 phylo on mu1,mu2,sigma1,sigma2, REML=TRUE",
        "FITS", "existing evidence, not re-run (expensive fixture): R/julia-bridge.R capability-comparison comment block; max|d_coef|=0.002889, loglik constant residual 0.001938",
        "FITS", "DRM.jl #624 census (14-fit list): \"bivariate q=4 phylo native AND through drm_bridge\"",
        "FITS", "existing evidence, not re-run: same comment block, PARITY_PASS 33/33",
        "YES", "Agree on FITTING, but SE/vcov are NOT comparable: DRM.jl #624 item 3 (`_q4_fd_vcov` finite-differences the ML objective on a REML fit; 10.5% SE gap on the committed biv-q4-phylo-reml fixture). Explicitly named out of scope by this leaf's brief (\"the q4_vcov-on-REML question\" remains unresolved for A11)."),

    row("phylo_count_large_p", "poisson", "TSV", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x + phylo(1|species, tree=tree)), poisson()",
        "REFUSES", "measured this run: `REML is implemented for univariate/bivariate Gaussian and binomial models` (native_reml_probe.R, row 9)",
        "FITS", "DRM.jl test suite test_cox_reid_poisson_phylo.jl (#450, \"Cox-Reid REML on Poisson phylo/relmat Laplace\"); DRM.jl #624 census (14-fit list): \"Poisson phylo(1|species) Laplace\"",
        "FITS", "RE-VERIFIED this run at pin 430ef64cc (prior citation in R/julia-bridge.R was at pin e0a65f96b): bridge fit succeeded, 6.3s (bridge_reml_probe.R, row 5)",
        "NO", "Not a defect: this is \"REML wherever possible\" working -- DRM.jl/the bridge offer a genuine REML route (Cox-Reid Laplace) that native TMB's REML implementation (Gaussian/binomial only) does not have. Documents the asymmetric REML surface drmTMB #1142 item 4 asks about."),

    row("phylo_count_large_p", "nbinom2", "TSV", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x + phylo(1|species, tree=tree)), nbinom2()",
        "REFUSES", "same shared code branch as the poisson sub-row (model_type not in {gaussian, binomial}); not re-run separately",
        "REFUSES", "DRM.jl's Cox-Reid REML route (#443/#450) is wired for Poisson only, not NB2 (test_cox_reid_poisson_ranef.jl, test_cox_reid_poisson_phylo.jl)",
        "REFUSES", "drm_julia_reml_supported()'s poisson_reml branch checks family_type==\"poisson\" only; nbinom2 falls through to REFUSE",
        "YES", ""),

    row("phylo_gamma_beta_binomial", "gamma", "TSV", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x + phylo(1|species, tree=tree)), Gamma(link=\"log\")",
        "REFUSES", "shared code branch (model_type not in {gaussian,binomial}); measured this run for the fe_gamma row (identical branch)",
        "REFUSES", "not among DRM.jl's two Cox-Reid REML families (Poisson only)",
        "REFUSES", "family_type \"Gamma\" not in drm_julia_reml_supported()'s gate",
        "YES", ""),

    row("phylo_gamma_beta_binomial", "beta", "TSV", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x + phylo(1|species, tree=tree)), beta()",
        "REFUSES", "shared code branch, not re-run separately",
        "REFUSES", "not among DRM.jl's two Cox-Reid REML families",
        "REFUSES", "family_type \"beta\" not in gate",
        "YES", ""),

    row("phylo_gamma_beta_binomial", "binomial", "TSV", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x + phylo(1|species, tree=tree)), stats::binomial()",
        "REFUSES", "measured this run (shared branch with plain_binomial_nonphylo): binomial REML requires exactly one ORDINARY unlabelled mu random-effect term; a phylo term does not count",
        "REFUSES", "DRM.jl test_cox_reid_poisson_phylo.jl testset \"Binomial still rejects :REML\"",
        "REFUSES", "family_type \"binomial\" not in drm_julia_reml_supported()'s gate",
        "YES", ""),

    row("general_covariance_structured", "gaussian", "TSV", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x + relmat(1|g, K=K), sigma ~ 1), gaussian()",
        "FITS", "measured this run: logLik=-51.6093435424 (native_reml_probe.R, row 8) -- matches the ordinary-random-intercept logLik exactly because the toy K used (compound-symmetric) is mathematically equivalent to an exchangeable random intercept, confirming the fit is genuine, not a fallback",
        "REFUSES", "DRM.jl #624 comment 2, 16-refuse list: \"Gaussian mean-only structured markers (phylo/relmat) with no sd() submodel\"",
        "REFUSES", "measured this run: `engine=\"julia\" cannot fit structured-effect models by REML=TRUE` (bridge_reml_probe.R, row 7) -- drm_julia_has_structured_term() (relmat/animal/spatial) is checked BEFORE any family dispatch and refuses unconditionally",
        "NO", "Same asymmetry as gaussian_phylo_mean (DRM.jl #624 item (c)-adjacent), for relmat instead of phylo. Not a new issue number; recorded alongside item (c)."),

    row("general_covariance_structured", "poisson", "TSV", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x + relmat(1|g, K=K)), poisson()",
        "REFUSES", "shared code branch (model_type not in {gaussian,binomial}); not re-run separately",
        "FITS", "DRM.jl's OWN test suite, test_cox_reid_poisson_phylo.jl lines 134-142, testset \"relmat/animal share the same spine\" (#450): `drm(bf(y~x+relmat(1|id)), Poisson(); A=K, method=:REML)` fits and `estimation_method(fit_rel) === :REML`",
        "REFUSES", "RE-VERIFIED live this run (bridge_reml_probe2.R): `engine=\"julia\" cannot fit structured-effect models by REML=TRUE`. drm_julia_has_structured_term() intercepts relmat/animal/spatial for EVERY family, before drm_julia_reml_supported()'s Poisson-specific branch is ever consulted.",
        "NO", "NEW FINDING (drmTMB #1142 / DRM.jl #624, opposite direction from the fe_poisson gap below): the bridge UNDER-admits relative to DRM.jl's own real capability. DRM.jl natively fits Poisson+relmat/animal REML (#450, its own passing test), but engine=\"julia\" can never reach it because the R-side structured-term gate fires first for every family, not just the ones (Gaussian) that gate is meant to police. Not filed as a GitHub issue in this leaf; flagged for A11/follow-up."),

    row("general_covariance_structured", "nbinom2", "TSV", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x + relmat(1|g, K=K)), nbinom2()",
        "REFUSES", "shared code branch, not re-run separately",
        "REFUSES", "not among DRM.jl's two Cox-Reid REML families (Poisson only, even for relmat)",
        "REFUSES", "double-refused: structured-term gate fires first, and nbinom2 is not in the poisson-only gate either",
        "YES", ""),

    row("general_covariance_structured", "gamma", "TSV", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x + relmat(1|g, K=K)), Gamma(link=\"log\")",
        "REFUSES", "shared code branch, not re-run separately",
        "REFUSES", "not a Cox-Reid REML family",
        "REFUSES", "double-refused (structured-term gate, and family not in gate)",
        "YES", ""),

    row("cross_family_latent", "", "TSV", "inst/extdata/julia-capabilities.tsv",
        "bf(mu1=y1~x, mu2=y2~x), c(gaussian(), poisson())",
        "N/A", "measured this run: the model itself does not exist natively under ANY estimator -- `Mixed-response bivariate families are not implemented yet` (native_reml_probe.R, row 11); this is not a REML-specific refusal",
        "N/A", "cross-family is a bridge-only construct (drm_julia_is_cross_family()); no single native drm() call corresponds to it, so DRM.jl-native REML does not apply here either",
        "REFUSES", "measured this run: `engine=\"julia\" cannot fit cross-family models by REML=TRUE`, refused BEFORE dispatch, unconditionally (bridge_reml_probe.R, row 9)",
        "YES", "Both sides land on \"no REML\", but for structurally different reasons (TMB: the model doesn't exist at all; bridge: an explicit design refusal per its permanent claim_boundary, D-179 #3). Not a gap on the REML axis specifically."),

    row("engine_control_surface", "", "TSV", "inst/extdata/julia-capabilities.tsv",
        "drm_control(optimizer = list(g_tol = ..., algorithm = ...))",
        "N/A", "orthogonal to the estimator choice -- optimizer control knobs apply identically under ML and REML",
        "N/A", "same",
        "N/A", "same",
        "N/A", "Not classified: this route is not a REML/ML fork."),

    row("plain_binomial_nonphylo", "", "TSV", "inst/extdata/julia-capabilities.tsv",
        "bf(cbind(succ, fail) ~ x), stats::binomial()",
        "REFUSES", "measured this run: `Binomial REML requires exactly one admitted ordinary unlabelled mu random-effect term... no ordinary mu random intercept` (native_reml_probe.R, row 10)",
        "REFUSES", "DRM.jl test_cox_reid_poisson_phylo.jl testset \"Binomial still rejects :REML\"",
        "REFUSES", "measured this run: `engine=\"julia\" cannot fit non-Gaussian (binomial) models by REML=TRUE` (bridge_reml_probe.R, row 8)",
        "YES", ""),

    row("location_scale_scale", "", "TSV", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x + phylo(1|sp, tree=tr), sigma ~ x, sd_phylo(sp) ~ x)",
        "FITS", "RE-RUN this session: testthat::test_file(\"tests/testthat/test-reml-direct-sd-phylo.R\") -- 8/8 pass, 0 failures, NOT_CRAN=true",
        "FITS", "DRM.jl #624 census (14-fit list): \"LSS sd_phylo dense and sparse (#551)\"",
        "FITS", "commit 79e8f0951 (\"widen Julia REML support for LSS models & promote Capability Row 12 to covered\"): drm_julia_reml_supported() widened for sd()/sd_phylo(); tests/testthat/test-julia-sigma-phylo-reml.R",
        "YES", ""),

    row("fe_student", "", "TSV (A3, PR #1168)", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x, sigma ~ 1, nu ~ 1), student(), fixed-effect only",
        "REFUSES", "shared code branch (measured live for fe_gamma/fe_poisson, identical branch: model_type not in {gaussian,binomial})",
        "REFUSES", "not a Cox-Reid REML family; also has zero random effects",
        "REFUSES", "family_type \"student\" not in drm_julia_reml_supported()'s gate",
        "YES", ""),

    row("fe_lognormal", "", "TSV (A3, PR #1168)", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x, sigma ~ 1), lognormal(), fixed-effect only",
        "REFUSES", "shared code branch, not re-run separately",
        "REFUSES", "not a Cox-Reid REML family",
        "REFUSES", "family_type \"lognormal\" not in gate",
        "YES", ""),

    row("fe_gamma", "", "TSV (A3, PR #1168)", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x), Gamma(link=\"log\"), fixed-effect only",
        "REFUSES", "measured this run: `REML is implemented for univariate/bivariate Gaussian and binomial models` (native_reml_probe.R, row 12)",
        "REFUSES", "not a Cox-Reid REML family",
        "REFUSES", "family_type \"Gamma\" not in gate",
        "YES", ""),

    row("fe_poisson", "", "TSV (A3, PR #1168)", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x), poisson(), fixed-effect only (ZERO random effects)",
        "REFUSES", "measured this run: `REML is implemented for univariate/bivariate Gaussian and binomial models` (native_reml_probe.R, row 13)",
        "REFUSES", "DRM.jl's OWN test suite, test_cox_reid_poisson_ranef.jl: \"Fixed-effects-only Poisson has no variance component to restrict\" -> ArgumentError",
        "REFUSES (via a RAW Julia stack trace, not the polished refusal)", "measured this run (bridge_reml_probe.R, rows 6-7): `ArgumentError: drm (Poisson): method = :REML is not available with no random effect (fixed-effects-only / zi / hu)` surfaces as \"Error happens in Julia\" plus the full Julia stacktrace",
        "YES", "OUTCOME agrees (all three refuse) but the INTERFACE does not: NEW FINDING, honesty-of-interface class (cf. #625's own fixes). drm_julia_reml_supported()'s poisson_reml branch checks only `!sigma_phylo && !has_sd` -- it never checks whether the model has ANY random effect at all -- so a fixed-effect-only Poisson REML request is forwarded to Julia instead of being caught by the R-side drm_julia_refuse_reml_unsupported() cli_abort. DRM.jl itself then throws, and the user sees a raw ArgumentError + full Julia stacktrace instead of the clean, actionable refusal every other cell in this table gets. Not filed as a GitHub issue in this leaf; flagged for A11/follow-up."),

    row("fe_nbinom2", "", "TSV (A3, PR #1168)", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x), nbinom2(), fixed-effect only",
        "REFUSES", "shared code branch, not re-run separately",
        "REFUSES", "not a Cox-Reid REML family",
        "REFUSES", "family_type \"nbinom2\" not in the poisson-only gate; refused cleanly (no raw stack trace -- unlike fe_poisson, nbinom2 never reaches Julia at all)",
        "YES", ""),

    row("fe_beta", "", "TSV (A3, PR #1168)", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x, sigma ~ 1), beta(), fixed-effect only",
        "REFUSES", "shared code branch, not re-run separately",
        "REFUSES", "not a Cox-Reid REML family",
        "REFUSES", "family_type \"beta\" not in gate",
        "YES", ""),

    row("zi_poisson", "", "TSV (A3, PR #1168)", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x, zi ~ x), poisson(), ZERO mu random effects",
        "REFUSES", "shared code branch (model_type check runs before any dpar-specific logic)",
        "REFUSES", "DRM.jl's own ArgumentError names `zi`/`hu` explicitly alongside fixed-effects-only as having no variance component to restrict",
        "REFUSES (via a RAW Julia stack trace)", "measured this run (bridge_reml_probe.R, row 8): identical ArgumentError/stacktrace class as fe_poisson -- family_type is still \"poisson\", so drm_julia_reml_supported() forwards it",
        "YES", "Same honesty-of-interface gap as fe_poisson (see that row); not a second distinct defect, just a second cell hitting the identical unguarded branch."),

    row("zi_nbinom2", "", "TSV (A3, PR #1168)", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x, sigma ~ 1, zi ~ 1), nbinom2(), fixed-effect only",
        "REFUSES", "shared code branch, not re-run separately",
        "REFUSES", "not a Cox-Reid REML family",
        "REFUSES", "family_type \"nbinom2\" not in the poisson-only gate -- refused CLEANLY (the polished cli_abort fires; nbinom2 is not swept up in the same over-admission as poisson)",
        "YES", ""),

    row("hurdle_nbinom2", "", "TSV (A3, PR #1168)", "inst/extdata/julia-capabilities.tsv",
        "bf(y ~ x, sigma ~ 1, hu ~ 1), nbinom2() [bridge spelling], fixed-effect only",
        "REFUSES", "shared code branch (native fits the same target via truncated_nbinom2()+hu, also non-Gaussian/non-binomial, also refuses REML identically)",
        "REFUSES", "not a Cox-Reid REML family",
        "REFUSES", "family_type \"nbinom2\" not in the poisson-only gate -- refused cleanly",
        "YES", ""),

    row("gaussian_random_intercept", "", "A5-census", "PR #1170, docs/dev-log/evidence/julia-r-parity/ordinary-re-census/census.tsv",
        "bf(y ~ x + (1|g), sigma ~ 1), gaussian()",
        "FITS", "measured this run: logLik=-51.6093435424 (native_reml_probe.R, row 3)",
        "FITS", "A5 census.tsv, layer=engine-direct: ml_loglik=-171.636217965634 reml_loglik=-174.437057568359 (cited verbatim, a5-census-verbatim.tsv row 6)",
        "FITS", "A5 census.tsv, layer=shipped: identical ml_loglik/reml_loglik (a5-census-verbatim.tsv row 2)",
        "YES", ""),

    row("gaussian_random_slope", "", "A5-census", "PR #1170, docs/dev-log/evidence/julia-r-parity/ordinary-re-census/census.tsv",
        "bf(y ~ x + (1+x|g), sigma ~ 1), gaussian()",
        "FITS", "measured this run: logLik=-50.4273340933 (native_reml_probe.R, row 4); validated Gaussian ordinary random effects, including slopes, are an admitted REML route (R/drmTMB.R comments, recovery ladders cited there)",
        "REFUSES", "A5 census.tsv, layer=engine-direct: REFUSED/UNSUPPORTED (a5-census-verbatim.tsv row 10)",
        "REFUSES (via a RAW Julia stack trace)", "A5 census.tsv, layer=shipped (a5-census-verbatim.tsv row 4): `ArgumentError: drm: method = :REML is not implemented for this model on the generic univariate Gaussian route (random slopes, ...)`, surfaced as \"Error happens in Julia\" -- the SAME honesty-of-interface class as fe_poisson: drm_julia_reml_supported()'s Gaussian branch only checks phylo/sigma_phylo/has_sd, never whether the mu-side random effect is a plain single intercept vs a slope, so it forwards a slope model to Julia instead of refusing it on the R side",
        "NO", "drmTMB #1142 / DRM.jl #624's OWN central example (item 2, 16-refuse list: \"Gaussian random slopes\"). Not new as a capability gap, but the INTERFACE half (raw Julia stack trace instead of drm_julia_refuse_reml_unsupported()) is the same unfiled defect class as fe_poisson/zi_poisson/general_covariance_structured-poisson above -- four cells now, all sharing one root cause: drm_julia_reml_supported() only screens for phylo/sd/structured-term presence, never for \"is the random-effect shape itself one DRM.jl actually restricts.\""),

    row("gaussian_sigma_random_intercept", "", "A5-census", "PR #1170, docs/dev-log/evidence/julia-r-parity/ordinary-re-census/census.tsv",
        "bf(y ~ x, sigma ~ (1|g)), gaussian()",
        "FITS", "measured this run: logLik=-53.3331996169 (native_reml_probe.R, row 5); native TMB admits ordinary sigma-side random intercepts under REML (R/drmTMB.R comment, 2026-07-08)",
        "REFUSES", "A5 census.tsv, layer=engine-direct: REFUSED/UNSUPPORTED",
        "REFUSES", "A5 census.tsv, layer=shipped: `engine=\"julia\" does not support method=\"REML\" with a random intercept on sigma` -- the POLISHED cli_abort DOES fire here (drm_julia_check_ordinary_sigma_ranef_route_limits() catches this case explicitly, unlike the mu-side slope case above)",
        "NO", "drmTMB #1142's own motivating example (the ArgumentError quoted in the issue body is this exact cell). Not new; the interface here is HONEST (clean R-side refusal, no raw stack trace) because this is the one case the maintainers already special-cased (\"Night question 14\" comment in R/julia-bridge.R).")
  )

  reml_table <- do.call(rbind, rows)

  ## Sanity: every TSV-sourced capability_id must actually exist in the
  ## committed TSV (G1 -- no hand-typed route disconnected from its source).
  tsv_path <- file.path(pkg_root, "inst/extdata/julia-capabilities.tsv")
  if (file.exists(tsv_path)) {
    tsv <- utils::read.delim(tsv_path, sep = "\t", stringsAsFactors = FALSE, quote = "")
    tsv_sourced <- reml_table$capability_id[grepl("^TSV", reml_table$source)]
    missing_from_tsv <- setdiff(unique(tsv_sourced), tsv$capability_id)
    if (length(missing_from_tsv) > 0L) {
      stop(
        "route(s) claimed as TSV-sourced but absent from inst/extdata/julia-capabilities.tsv: ",
        paste(missing_from_tsv, collapse = ", ")
      )
    }
  }

  reml_table
}

#' Render the REML-by-route table as markdown lines (no file I/O).
drm_reml_route_table_lines <- function(pkg_root = ".") {
  reml_table <- drm_reml_route_table_rows(pkg_root)
  tsv_path <- file.path(pkg_root, "inst/extdata/julia-capabilities.tsv")
  n_tsv <- if (file.exists(tsv_path)) {
    nrow(utils::read.delim(tsv_path, sep = "\t", stringsAsFactors = FALSE, quote = ""))
  } else {
    21L
  }

  lines <- character(0)
  add <- function(...) lines <<- c(lines, paste0(...))

  add("# 261: REML support by route -- native TMB vs native DRM.jl vs the bridge")
  add("")
  add("GENERATED by `tools/write-reml-route-table.R`. Do not hand-edit; re-run the")
  add("script to regenerate. drmTMB #1142 / DRM.jl #624 (\"Capability parity between")
  add("engines: ML everywhere, REML where possible, and no silent REML-to-ML")
  add("downgrade\"). DRM.jl pin `430ef64cc`. Measured 2026-09-05 (arc A9f).")
  add("")
  add("## Scope and how to read this")
  add("")
  add(sprintf(
    "%d routes, drawn from two sources: the %d rows of the committed",
    nrow(reml_table), n_tsv
  ))
  add("`inst/extdata/julia-capabilities.tsv` (which already carries A3's nine")
  add("fixed-effect routes, PR #1168), plus A5's three ordinary-random-effect")
  add("shapes (PR #1170), which are bridge-admitted routes with no TSV row yet")
  add("(A2 in the ultra-plan backlog owns adding one). A route with more than one")
  add("REML-relevant family (`phylo_count_large_p`, `phylo_gamma_beta_binomial`,")
  add("`general_covariance_structured`) is split into one row per family. No")
  add("route below was hand-typed without a source: the generator asserts every")
  add("`TSV`-sourced `capability_id` is present in the committed TSV at")
  add("generation time.")
  add("")
  add("Every cell is FITS, REFUSES, or N/A (the model or the estimator fork does")
  add("not exist on that engine at all), each with a receipt: either measured in")
  add("THIS run (script + log path under")
  add(paste0("`", evidence_dir, "/`), or a citation to an existing receipt (A3/A5's own"))
  add("PRs, a DRM.jl issue, or DRM.jl's own committed test suite) reproduced")
  add("verbatim rather than re-measured. \"Do NOT implement REML anywhere\" held:")
  add("every disagreement below is recorded as a finding, not fixed.")
  add("")
  add("## Summary")
  add("")
  add("| Route | Native TMB | Native DRM.jl | Bridge | Agree? |")
  add("|---|---|---|---|---|")
  for (i in seq_len(nrow(reml_table))) {
    r <- reml_table[i, ]
    label <- if (nzchar(r$sub_family)) paste0(r$capability_id, " (", r$sub_family, ")") else r$capability_id
    add(sprintf("| %s | %s | %s | %s | %s |", label, r$tmb_reml, r$drmjl_reml, r$bridge_reml, r$agree))
  }
  add("")

  n_gap <- sum(reml_table$agree == "NO")
  n_na <- sum(reml_table$agree == "N/A")
  n_yes <- sum(reml_table$agree == "YES")
  add(sprintf(
    "%d rows: %d agree (all three engines/layers land the same way), %d disagree, %d not classified (orthogonal to REML/ML, or the model does not exist under any estimator).",
    nrow(reml_table), n_yes, n_gap, n_na
  ))
  add("")

  add("## Detail, one row per route")
  add("")
  for (i in seq_len(nrow(reml_table))) {
    r <- reml_table[i, ]
    label <- if (nzchar(r$sub_family)) paste0(r$capability_id, " -- ", r$sub_family) else r$capability_id
    add(sprintf("### %s", label))
    add("")
    add(sprintf("- **Source**: %s (`%s`)", r$source, r$source_ref))
    add(sprintf("- **Formula**: `%s`", r$formula))
    add(sprintf("- **Native TMB**: %s -- %s", r$tmb_reml, r$tmb_evidence))
    add(sprintf("- **Native DRM.jl**: %s -- %s", r$drmjl_reml, r$drmjl_evidence))
    add(sprintf("- **Bridge (`engine = \"julia\"`)**: %s -- %s", r$bridge_reml, r$bridge_evidence))
    add(sprintf("- **Agree?**: %s%s", r$agree, if (nzchar(r$gap)) paste0(" -- ", r$gap) else ""))
    add("")
  }

  add("## Gaps (every disagreement, with its issue)")
  add("")
  gap_rows <- reml_table[reml_table$agree == "NO", ]
  for (i in seq_len(nrow(gap_rows))) {
    r <- gap_rows[i, ]
    label <- if (nzchar(r$sub_family)) paste0(r$capability_id, " (", r$sub_family, ")") else r$capability_id
    add(sprintf("%d. **%s**: %s", i, label, r$gap))
  }
  add("")

  add("## Not covered by this leaf")
  add("")
  add("- The q4_vcov-on-REML question (DRM.jl #624 item 3): SE/vcov correctness")
  add("  on the one route where all three columns already agree the model FITS.")
  add("- DRM.jl #624 item (c), mean-only phylogenetic Gaussian REML: recorded as a")
  add("  gap on two rows above (`gaussian_phylo_mean`, and the Gaussian sub-row of")
  add("  `general_covariance_structured`); not implemented here.")
  add("- The four cells sharing the drm_julia_reml_supported() honesty-of-interface")
  add("  gap (`fe_poisson`, `zi_poisson`, `general_covariance_structured`/poisson,")
  add("  `gaussian_random_slope`) are recorded, not fixed. No GitHub issue was")
  add("  filed for this in this leaf; it is flagged for A11 or a follow-up leaf.")
  add("- No REML implementation changed anywhere in this leaf (scope: MEASURE and")
  add("  TABLE only).")
  add("")

  lines
}

## Only write the file when run as a script (Rscript tools/write-reml-route-table.R),
## never as a side effect of source()-ing the definitions above for a test.
if (sys.nframe() == 0L) {
  this_file <- commandArgs(trailingOnly = FALSE)
  file_arg <- sub("^--file=", "", this_file[grepl("^--file=", this_file)])
  pkg_root <- if (length(file_arg) == 1L && nzchar(file_arg)) {
    normalizePath(file.path(dirname(file_arg), ".."))
  } else {
    normalizePath(".")
  }
  out_path <- file.path(pkg_root, "docs/design/261-reml-by-route.md")
  out_lines <- drm_reml_route_table_lines(pkg_root)
  writeLines(out_lines, out_path)
  cat(sprintf(
    "wrote %d REML route rows to %s\n",
    nrow(drm_reml_route_table_rows(pkg_root)), out_path
  ))
}
