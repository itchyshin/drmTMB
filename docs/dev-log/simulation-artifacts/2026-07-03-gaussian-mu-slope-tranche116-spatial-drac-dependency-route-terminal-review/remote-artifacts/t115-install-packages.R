art <- Sys.getenv("DRMTMB_T114_ART")
lib <- Sys.getenv("DRMTMB_T114_LIB")
dependency_lib <- Sys.getenv("DRMTMB_T114_DEPENDENCY_LIB")
repo <- Sys.getenv("DRMTMB_T114_REPO")
requested <- c("cli", "Matrix", "RcppEigen", "TMB")

write_tsv <- function(x, path) {
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA")
}

status <- data.frame(
  stage = character(),
  status = character(),
  exit_code = character(),
  note = character(),
  stringsAsFactors = FALSE
)
append_status <- function(stage, status_value, exit_code, note) {
  status <<- rbind(
    status,
    data.frame(
      stage = stage,
      status = status_value,
      exit_code = as.character(exit_code),
      note = note,
      stringsAsFactors = FALSE
    )
  )
  write_tsv(status, file.path(art, "install-packages-status.tsv"))
}

if (!nzchar(art) || !nzchar(lib) || !nzchar(dependency_lib)) {
  stop("DRMTMB_T114_ART, DRMTMB_T114_LIB, and DRMTMB_T114_DEPENDENCY_LIB are required")
}
dir.create(art, recursive = TRUE, showWarnings = FALSE)
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
dir.create(dependency_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, dependency_lib, .libPaths()))

write_tsv(data.frame(package = requested, requested_top_level = TRUE), file.path(art, "requested-top-level-packages.tsv"))
write_tsv(data.frame(order = seq_along(.libPaths()), libpath = .libPaths()), file.path(art, "r-libpaths-before-install.tsv"))

if (!nzchar(repo)) {
  append_status("dependency_source_guard", "failed", 126, "DRMTMB_T114_REPO_missing")
  quit(status = 126, save = "no")
}
if (grepl("^https?://cloud[.]r-project[.]org", repo)) {
  append_status("dependency_source_guard", "failed", 126, "direct_CRAN_on_allocation_rejected")
  quit(status = 126, save = "no")
}
if (!(grepl("^file://", repo) || dir.exists(repo))) {
  append_status("dependency_source_guard", "failed", 126, "dependency_source_must_be_file_url_or_existing_directory")
  quit(status = 126, save = "no")
}
append_status("dependency_source_guard", "passed", 0, paste0("repo=", repo))
options(repos = c(CRAN = repo))

ncpus <- suppressWarnings(as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", "1")))
if (is.na(ncpus) || ncpus < 1L) ncpus <- 1L

before <- utils::installed.packages()
before_keys <- paste(rownames(before), before[, "LibPath"], sep = "@@")
install_results <- data.frame(
  package = requested,
  attempted = FALSE,
  status = "not_attempted",
  message = "",
  stringsAsFactors = FALSE
)

message_from_result <- function(result, pkg) {
  if (inherits(result, "condition")) {
    return(conditionMessage(result))
  }
  if (isTRUE(result)) {
    return(paste0("install.packages returned TRUE but ", pkg, " is unavailable"))
  }
  paste0("install.packages returned class ", paste(class(result), collapse = "/"))
}

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
    utils::install.packages(
      pkg,
      lib = lib,
      dependencies = c("Depends", "Imports", "LinkingTo"),
      Ncpus = ncpus
    )
    TRUE
  }, error = function(e) e)
  if (isTRUE(res) && requireNamespace(pkg, quietly = TRUE)) {
    install_results$status[i] <- "installed"
    install_results$message[i] <- "available_after_install"
  } else {
    install_results$status[i] <- "failed"
    install_results$message[i] <- message_from_result(res, pkg)
  }
  write_tsv(install_results, file.path(art, "install-packages-detail.tsv"))
}

write_tsv(install_results, file.path(art, "install-packages-detail.tsv"))
after <- utils::installed.packages()
after_keys <- paste(rownames(after), after[, "LibPath"], sep = "@@")
new_keys <- setdiff(after_keys, before_keys)
if (length(new_keys)) {
  idx <- match(new_keys, after_keys)
  closure <- data.frame(
    package = rownames(after)[idx],
    version = after[idx, "Version"],
    libpath = after[idx, "LibPath"],
    stringsAsFactors = FALSE
  )
} else {
  closure <- data.frame(package = character(), version = character(), libpath = character())
}
write_tsv(closure, file.path(art, "installed-package-closure.tsv"))

availability <- do.call(rbind, lapply(requested, function(pkg) {
  ok <- requireNamespace(pkg, quietly = TRUE)
  data.frame(
    package = pkg,
    installed = ok,
    version = if (ok) as.character(utils::packageVersion(pkg)) else NA_character_,
    libpath = if (ok) find.package(pkg, quiet = TRUE) else NA_character_,
    stringsAsFactors = FALSE
  )
}))
write_tsv(availability, file.path(art, "dependency-availability.tsv"))
write_tsv(data.frame(order = seq_along(.libPaths()), libpath = .libPaths()), file.path(art, "r-libpaths-after-install.tsv"))
capture.output(sessionInfo(), file = file.path(art, "sessionInfo-after-dependency-install.txt"))

if (!all(availability$installed)) {
  append_status("install_packages", "failed", 10, "requested_dependency_install_failed_or_missing")
  quit(status = 10, save = "no")
}
append_status("install_packages", "passed", 0, "requested_dependencies_available")
