lib <- Sys.getenv("R_LIBS_USER")
tmp <- Sys.getenv("TMPDIR")
art <- Sys.getenv("DRMTMB_T101_ART")
requested <- c("cli", "RcppEigen", "TMB")
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, .libPaths()))
options(repos = c(CRAN = "https://cloud.r-project.org"))
ncpus <- suppressWarnings(as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", "1")))
if (is.na(ncpus) || ncpus < 1L) ncpus <- 1L
write_tsv <- function(x, path) {
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA")
}
write_tsv(data.frame(package = requested, requested_top_level = TRUE), file.path(art, "requested-top-level-packages.tsv"))
write_tsv(data.frame(order = seq_along(.libPaths()), libpath = .libPaths()), file.path(art, "r-libpaths-before-install.tsv"))
before <- utils::installed.packages()
before_keys <- paste(rownames(before), before[, "LibPath"], sep = "@@")
install_results <- data.frame(package = requested, attempted = FALSE, status = "not_attempted", message = "", stringsAsFactors = FALSE)
for (pkg in requested) {
  i <- install_results$package == pkg
  if (requireNamespace(pkg, quietly = TRUE)) {
    install_results$attempted[i] <- FALSE
    install_results$status[i] <- "already_available"
    install_results$message[i] <- "available_before_install"
    next
  }
  install_results$attempted[i] <- TRUE
  res <- tryCatch({
    utils::install.packages(pkg, lib = lib, dependencies = c("Depends", "Imports", "LinkingTo"), Ncpus = ncpus)
    TRUE
  }, error = function(e) e)
  if (isTRUE(res) && requireNamespace(pkg, quietly = TRUE)) {
    install_results$status[i] <- "installed"
    install_results$message[i] <- "available_after_install"
  } else {
    install_results$status[i] <- "failed"
    install_results$message[i] <- conditionMessage(res)
  }
}
write_tsv(install_results, file.path(art, "install-packages-status.tsv"))
after <- utils::installed.packages()
after_keys <- paste(rownames(after), after[, "LibPath"], sep = "@@")
new_keys <- setdiff(after_keys, before_keys)
if (length(new_keys)) {
  idx <- match(new_keys, after_keys)
  closure <- data.frame(package = rownames(after)[idx], version = after[idx, "Version"], libpath = after[idx, "LibPath"], stringsAsFactors = FALSE)
} else {
  closure <- data.frame(package = character(), version = character(), libpath = character())
}
write_tsv(closure, file.path(art, "installed-package-closure.tsv"))
avail <- do.call(rbind, lapply(requested, function(pkg) {
  ok <- requireNamespace(pkg, quietly = TRUE)
  path <- if (ok) find.package(pkg, quiet = TRUE) else NA_character_
  version <- if (ok) as.character(utils::packageVersion(pkg)) else NA_character_
  data.frame(package = pkg, installed = ok, version = version, libpath = path, stringsAsFactors = FALSE)
}))
write_tsv(avail, file.path(art, "dependency-availability.tsv"))
write_tsv(data.frame(order = seq_along(.libPaths()), libpath = .libPaths()), file.path(art, "r-libpaths-after-install.tsv"))
capture.output(sessionInfo(), file = file.path(art, "sessionInfo-after-dependency-install.txt"))
if (!all(avail$installed)) {
  quit(status = 10, save = "no")
}
