# Shared SHA-256 helper for 071 ordinary-Laplace parity evidence scripts.
# Prefer drmTMB::sha256_file_portable when the package is available; otherwise
# load the same implementation from the repository R/ tree.

r071_helper_script <- function(frame, name) {
  value <- tryCatch(get(name, envir = frame, inherits = FALSE), error = function(e) NULL)
  if (is.character(value) && length(value) == 1L && !is.na(value) && nzchar(value)) {
    return(chartr("\\", "/", value))
  }
  NULL
}

# source() stores the path in ofile. sys.source() stores it in file.
# Fall back to DRMTMB_ROOT, then to a cwd-relative path.
r071_helper_dir <- function() {
  n <- sys.nframe()
  if (n > 0L) {
    for (fr in rev(seq_len(n))) {
      frame <- sys.frames()[[fr]]
      for (name in c("ofile", "file")) {
        path <- r071_helper_script(frame, name)
        if (is.null(path) || !grepl("r071-file-sha256\\.R$", path)) next
        hit <- tryCatch(dirname(normalizePath(path, mustWork = TRUE)), error = function(e) NULL)
        if (!is.null(hit)) return(hit)
      }
    }
  }
  rel <- "docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/r071-file-sha256.R"
  root <- Sys.getenv("DRMTMB_ROOT", unset = "")
  candidates <- if (nzchar(root)) c(file.path(root, rel), rel) else rel
  for (candidate in candidates) {
    if (file.exists(candidate)) return(dirname(normalizePath(candidate, mustWork = TRUE)))
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
