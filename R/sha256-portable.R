#' Portable SHA-256 hex digest for a file
#'
#' Uses `tools::sha256sum()` when the running R version exports it (R 4.5+),
#' otherwise optional Suggested packages or the `sha256sum` / `shasum` system
#' utilities. Returns a 64-character lowercase hexadecimal string, matching
#' `tools::sha256sum()` byte-for-byte on R 4.5+.
#' @param path Path to an existing file.
#' @return Character scalar SHA-256 hex digest.
#' @keywords internal
#' @noRd
sha256_file_portable <- function(path) {
  path <- normalizePath(path, mustWork = TRUE)
  if (exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE)) {
    return(unname(tools::sha256sum(path)[[1L]]))
  }
  if (requireNamespace("openssl", quietly = TRUE)) {
    digest <- openssl::sha256(file(path, "rb"))
    return(paste0(sprintf("%02x", as.integer(digest)), collapse = ""))
  }
  if (requireNamespace("digest", quietly = TRUE)) {
    return(digest::digest(file = path, algo = "sha256"))
  }
  sha256sum <- Sys.which("sha256sum")
  if (nzchar(sha256sum)) {
    out <- suppressWarnings(system2(sha256sum, path, stdout = TRUE, stderr = TRUE))
    if (length(out) && grepl("^[0-9a-fA-F]{64}", out[[1L]])) {
      return(tolower(sub("[[:space:]].*$", "", out[[1L]])))
    }
  }
  shasum <- Sys.which("shasum")
  if (nzchar(shasum)) {
    out <- suppressWarnings(system2(shasum, c("-a", "256", path), stdout = TRUE, stderr = TRUE))
    if (length(out) && grepl("^[0-9a-fA-F]{64}", out[[1L]])) {
      return(tolower(sub("[[:space:]].*$", "", out[[1L]])))
    }
  }
  stop(
    "Cannot compute SHA-256 for ", path,
    ": need R 4.5+ tools::sha256sum, the openssl or digest package, ",
    "or a sha256sum/shasum system utility.",
    call. = FALSE
  )
}
