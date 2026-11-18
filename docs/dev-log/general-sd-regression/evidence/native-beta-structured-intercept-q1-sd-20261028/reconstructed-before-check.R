# Controlled pre-change builder check. This loads a verified extracted prior
# source file in an isolated environment; it does not change the worktree.
pkgload::load_all(".", quiet = TRUE)
current <- parse("tests/testthat/test-beta-structured-intercept-q1-sd-regression.R")
fixture_env <- new.env(parent = globalenv())
for (i in 1:2) eval(current[[i]], envir = fixture_env)
prior <- parse("/tmp/drmtmb-beta-q1-before.R")
is_builder <- vapply(prior, function(expr) {
  is.call(expr) && identical(expr[[1L]], as.name("<-")) &&
    identical(expr[[2L]], as.name("drm_build_beta_ls_spec"))
}, logical(1L))
stopifnot(sum(is_builder) == 1L)
old_env <- new.env(parent = asNamespace("drmTMB"))
eval(prior[[which(is_builder)]], envir = old_env)
for (provider in c("relmat", "spatial")) {
  fx <- fixture_env$beta_structured_q1_fixture(provider,
    seed = if (provider == "relmat") 2026102810L else 2026102811L)
  K <- fx$K; coords <- fx$coords
  form <- fixture_env$beta_structured_q1_form(provider, K, coords = coords)
  result <- tryCatch(old_env$drm_build_beta_ls_spec(form, fx$data),
    error = function(e) conditionMessage(e))
  if (!is.character(result)) stop("Prior builder unexpectedly accepted ", provider)
  cat("RECONSTRUCTED_BEFORE_REJECTION", provider, ": ", result, "\n", sep = "")
}
