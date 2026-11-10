#' Portable SHA-256 hex digest for a file
#'
#' Uses `tools::sha256sum()` when the running R version exports it (R 4.5+),
#' otherwise optional Suggested packages or the `sha256sum` / `shasum` system
#' utilities. Returns a 64-character lowercase hexadecimal string, matching
#' `tools::sha256sum()` byte-for-byte on R 4.5+.
#' @param path Path to an existing file.
#' @param backend Force a hashing backend for tests (`"auto"` picks the same
#'   order as production).
#' @return Character scalar SHA-256 hex digest.
#' @keywords internal
#' @noRd
sha256_file_portable <- function(
    path,
    backend = c("auto", "tools", "openssl", "digest", "sha256sum", "shasum")) {
  path <- normalizePath(path, mustWork = TRUE)
  backend <- match.arg(backend)
  sha256_with_tools <- function() {
    if (!exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE)) {
      stop("tools::sha256sum is not available", call. = FALSE)
    }
    unname(tools::sha256sum(path)[[1L]])
  }
  sha256_with_openssl <- function() {
    if (!requireNamespace("openssl", quietly = TRUE)) {
      stop("the openssl package is not installed", call. = FALSE)
    }
    raw_digest <- openssl::sha256(file(path, "rb"))
    paste0(sprintf("%02x", as.integer(raw_digest)), collapse = "")
  }
  sha256_with_digest <- function() {
    if (!requireNamespace("digest", quietly = TRUE)) {
      stop("the digest package is not installed", call. = FALSE)
    }
    digest::digest(file = path, algo = "sha256")
  }
  sha256_with_sha256sum <- function() {
    sha256sum <- Sys.which("sha256sum")
    if (!nzchar(sha256sum)) {
      stop("sha256sum is not on PATH", call. = FALSE)
    }
    quoted <- shQuote(path)
    out <- suppressWarnings(system2(sha256sum, quoted, stdout = TRUE, stderr = TRUE))
    if (!length(out) || !grepl("^[0-9a-fA-F]{64}", out[[1L]])) {
      stop("sha256sum failed for ", path, call. = FALSE)
    }
    tolower(sub("[[:space:]].*$", "", out[[1L]]))
  }
  sha256_with_shasum <- function() {
    shasum <- Sys.which("shasum")
    if (!nzchar(shasum)) {
      stop("shasum is not on PATH", call. = FALSE)
    }
    out <- suppressWarnings(system2(shasum, c("-a", "256", shQuote(path)), stdout = TRUE, stderr = TRUE))
    if (!length(out) || !grepl("^[0-9a-fA-F]{64}", out[[1L]])) {
      stop("shasum failed for ", path, call. = FALSE)
    }
    tolower(sub("[[:space:]].*$", "", out[[1L]]))
  }
  dispatch <- c(
    tools = sha256_with_tools,
    openssl = sha256_with_openssl,
    digest = sha256_with_digest,
    sha256sum = sha256_with_sha256sum,
    shasum = sha256_with_shasum
  )
  if (!identical(backend, "auto")) {
    return(dispatch[[backend]]())
  }
  errors <- character()
  for (name in names(dispatch)) {
    got <- tryCatch(
      dispatch[[name]](),
      error = function(e) {
        errors <<- c(errors, paste0(name, ": ", conditionMessage(e)))
        NULL
      }
    )
    if (!is.null(got)) {
      return(got)
    }
  }
  stop(
    "Cannot compute SHA-256 for ", path,
    ": need R 4.5+ tools::sha256sum, Suggested openssl or digest, ",
    "or a sha256sum/shasum system utility.",
    if (length(errors)) paste0("\n", paste(errors, collapse = "\n")) else "",
    call. = FALSE
  )
}
