target_lib <- "/home/snakagaw/R/lib"
repo <- "https://cloud.r-project.org"
pkgs <- c("RcppEigen", "TMB")
root <- Sys.getenv("REMOTE_ROOT", unset = getwd())
metadata_dir <- file.path(root, "metadata")
tarball_dir <- file.path(root, "source-tarballs")
dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tarball_dir, recursive = TRUE, showWarnings = FALSE)
Sys.setenv(
  R_LIBS_USER = "~/R/lib",
  MAKEFLAGS = "-j1",
  OMP_NUM_THREADS = "1",
  OPENBLAS_NUM_THREADS = "1",
  MKL_NUM_THREADS = "1",
  TMB_NTHREADS = "1"
)
.libPaths(unique(c(target_lib, .libPaths())))
writeLines(
  c(
    paste("timestamp", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"), sep = "\t"),
    paste("target_lib", target_lib, sep = "\t"),
    paste("repo", repo, sep = "\t"),
    paste("packages", paste(pkgs, collapse = ","), sep = "\t"),
    paste("r_version", R.version.string, sep = "\t"),
    paste("libPaths", paste(.libPaths(), collapse = ";"), sep = "\t"),
    paste("MAKEFLAGS", Sys.getenv("MAKEFLAGS"), sep = "\t"),
    paste("OMP_NUM_THREADS", Sys.getenv("OMP_NUM_THREADS"), sep = "\t"),
    paste("OPENBLAS_NUM_THREADS", Sys.getenv("OPENBLAS_NUM_THREADS"), sep = "\t"),
    paste("MKL_NUM_THREADS", Sys.getenv("MKL_NUM_THREADS"), sep = "\t"),
    paste("TMB_NTHREADS", Sys.getenv("TMB_NTHREADS"), sep = "\t")
  ),
  file.path(metadata_dir, "install-command.tsv")
)
writeLines(capture.output(sessionInfo()), file.path(metadata_dir, "sessionInfo-before.txt"))
pre <- installed.packages(lib.loc = .libPaths())
pre_keep <- pre[rownames(pre) %in% c(pkgs, "Rcpp", "Matrix"), , drop = FALSE]
utils::write.table(
  as.data.frame(pre_keep),
  file.path(metadata_dir, "pre-install-installed-packages.tsv"),
  sep = "\t",
  quote = FALSE,
  row.names = TRUE,
  col.names = NA
)
avail <- available.packages(repos = repo, type = "source")
avail_keep <- avail[rownames(avail) %in% pkgs, , drop = FALSE]
utils::write.table(
  as.data.frame(avail_keep),
  file.path(metadata_dir, "available-packages.tsv"),
  sep = "\t",
  quote = FALSE,
  row.names = TRUE,
  col.names = NA
)
downloaded <- download.packages(pkgs, destdir = tarball_dir, repos = repo, type = "source")
utils::write.table(
  as.data.frame(downloaded),
  file.path(metadata_dir, "downloaded-packages.tsv"),
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)
download_paths <- downloaded[match(pkgs, downloaded[, "Package"]), "dest"]
install_error <- ""
install_warning <- character()
tryCatch(
  withCallingHandlers(
    utils::install.packages(
      download_paths,
      lib = target_lib,
      repos = NULL,
      type = "source",
      dependencies = FALSE
    ),
    warning = function(w) {
      install_warning <<- c(install_warning, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  ),
  error = function(e) {
    install_error <<- conditionMessage(e)
  }
)
post <- installed.packages(lib.loc = .libPaths())
post_keep <- post[rownames(post) %in% c(pkgs, "Rcpp", "Matrix"), , drop = FALSE]
utils::write.table(
  as.data.frame(post_keep),
  file.path(metadata_dir, "post-install-installed-packages.tsv"),
  sep = "\t",
  quote = FALSE,
  row.names = TRUE,
  col.names = NA
)
namespace_ok <- vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)
utils::write.table(
  data.frame(Package = names(namespace_ok), requireNamespace = as.logical(namespace_ok)),
  file.path(metadata_dir, "namespace-check.tsv"),
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)
for (pkg in c(pkgs, "Rcpp", "Matrix")) {
  desc <- tryCatch(utils::packageDescription(pkg, lib.loc = .libPaths()), error = function(e) e)
  out <- if (inherits(desc, "error")) conditionMessage(desc) else capture.output(print(desc))
  writeLines(out, file.path(metadata_dir, paste0("packageDescription-", pkg, ".txt")))
}
writeLines(capture.output(sessionInfo()), file.path(metadata_dir, "sessionInfo-after.txt"))
writeLines(install_warning, file.path(metadata_dir, "install-warnings.txt"))
writeLines(install_error, file.path(metadata_dir, "install-error.txt"))
status <- if (all(namespace_ok) && identical(install_error, "")) 0L else 1L
writeLines(as.character(status), file.path(metadata_dir, "install-exit-status.txt"))
quit(save = "no", status = status)
