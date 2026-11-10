# Shared SHA-256 helper for 071 ordinary-Laplace parity evidence scripts.
# Prefer drmTMB::sha256_file_portable when the package is available; otherwise
# load the same implementation from the repository R/ tree.

r071_helper_dir <- function() {
  n <- sys.nframe()
  for (fr in rev(seq_len(n))) {
    ofile <- tryCatch(sys.frames()[[fr]]$ofile, error = function(e) NULL)
    if (!is.null(ofile) && grepl("r071-file-sha256\\.R$", ofile)) {
      return(dirname(normalizePath(ofile, mustWork = TRUE)))
    }
  }
  candidate <- "docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/r071-file-sha256.R"
  if (file.exists(candidate)) {
    return(dirname(normalizePath(candidate, mustWork = TRUE)))
  }
  stop("cannot locate the 071 SHA-256 helper directory", call. = FALSE)
}

r071_repo_root <- function() {
  root <- Sys.getenv("DRMTMB_ROOT", unset = NA_character_)
  if (!is.na(root) && file.exists(file.path(root, "DESCRIPTION"))) {
    return(normalizePath(root, mustWork = TRUE))
  }
  normalizePath(
    file.path(r071_helper_dir(), "..", "..", "..", "..", ".."),
    mustWork = TRUE
  )
}

r071_load_portable_sha256 <- function() {
  if (requireNamespace("drmTMB", quietly = TRUE) &&
      exists("sha256_file_portable", asNamespace("drmTMB"), inherits = FALSE)) {
    return(getFromNamespace("sha256_file_portable", "drmTMB"))
  }
  helper <- file.path(r071_repo_root(), "R", "sha256-portable.R")
  if (!file.exists(helper)) {
    stop("Missing portable SHA-256 helper: ", helper, call. = FALSE)
  }
  env <- new.env(parent = baseenv())
  sys.source(helper, envir = env, keep.source = FALSE)
  env$sha256_file_portable
}

r071_file_sha256 <- function(path) {
  r071_load_portable_sha256()(path)
}

r071_s7_sha256 <- r071_file_sha256
