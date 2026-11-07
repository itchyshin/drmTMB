args <- commandArgs(trailingOnly = TRUE)
if (!(length(args) %in% c(1L, 2L)) || (length(args) == 2L && args[[2L]] != "--qualification"))
  stop("Usage: Rscript prepare.R NEW_OUTPUT_DIRECTORY [--qualification]")
mode <- if (length(args) == 2L) "qualification" else "production"
master_seed <- if (mode == "qualification") 2026101704L else 2026101703L
out <- args[[1L]]
if (file.exists(out)) stop("Refusing to overwrite existing calibration directory: ", out)
root <- normalizePath(".", mustWork = TRUE)
if (!file.exists(file.path(root, "DESCRIPTION"))) stop("Run from the drmTMB repository root")
library_path <- Sys.getenv("DRMTMB_SD_TEST_LIBRARY")
if (!nzchar(library_path)) stop("Set DRMTMB_SD_TEST_LIBRARY to the isolated installed package library")
.libPaths(c(library_path, .libPaths()))
if (!requireNamespace("drmTMB", quietly = TRUE) || !requireNamespace("digest", quietly = TRUE)) stop("Installed drmTMB and digest are required")
pkg <- normalizePath(find.package("drmTMB"), mustWork = TRUE)
if (!identical(pkg, normalizePath(file.path(library_path, "drmTMB"), mustWork = TRUE))) stop("Loaded package is not from DRMTMB_SD_TEST_LIBRARY")
source(file.path(root, "tests/testthat/helper-binomial-sd-regression.R"), local = TRUE)
source(file.path(root, "tools/general-sd-regression/native-calibration/generator.R"), local = TRUE)
source(file.path(root, "tools/general-sd-regression/native-calibration/stage-two-seeds.R"), local = TRUE)
sd_regression_generator_self_test()
# Bind the staged look-two seed file to its deterministic producer before any
# campaign directory is created. CSV parsing changes the final alpha0 digits,
# so require exact identity for discrete fields and <= 1e-14 for numeric fields.
stage_two_path <- file.path(root, "docs/dev-log/general-sd-regression/stage-two-manifest.csv")
stage_two_sha <- "8fd627ccb8a7f8689c56e629a5ff12e53405be1a508167216632bcf445652e96"
if (!file.exists(stage_two_path) || !identical(digest::digest(stage_two_path, algo="sha256", file=TRUE), stage_two_sha))
  stop("Frozen stage-two manifest SHA-256 mismatch")
stage_two_frozen <- read.csv(stage_two_path, stringsAsFactors=FALSE)
stage_two_generated <- native_sd_stage_two_manifest()
if (!identical(names(stage_two_frozen), names(stage_two_generated)) || nrow(stage_two_frozen) != 9000L)
  stop("Frozen stage-two manifest shape differs from its producer")
numeric_cols <- names(stage_two_generated)[vapply(stage_two_generated, is.numeric, logical(1L))]
character_cols <- setdiff(names(stage_two_generated), numeric_cols)
if (any(vapply(character_cols, function(nm) !identical(as.character(stage_two_frozen[[nm]]), as.character(stage_two_generated[[nm]])), logical(1L))) ||
    any(vapply(numeric_cols, function(nm) max(abs(as.numeric(stage_two_frozen[[nm]]) - stage_two_generated[[nm]]), na.rm=TRUE) > 1e-14, logical(1L))))
  stop("Frozen stage-two CSV does not match deterministic seed producer")
# Reproduce the pilot seed stream exactly, then prove disjointness.
stream <- function(seed, n) { set.seed(seed); sample.int(.Machine$integer.max, n) }
pilot_seeds <- stream(2026101702L, 6L)
production_seeds <- stream(2026101703L, 3000L)
qualification_seeds <- stream(2026101704L, 3000L)
prod_seeds <- if (mode == "production") production_seeds else qualification_seeds
if (anyDuplicated(prod_seeds) || length(intersect(prod_seeds, pilot_seeds)) ||
    length(intersect(prod_seeds, if(mode == "production") qualification_seeds else production_seeds)))
  stop("Selected seed stream overlaps pilot or the other campaign stream")
manifest <- data.frame(index = seq_len(3000L),
  a = rep(c(-0.5, 0, 0.5), each = 1000L), replicate = rep(seq_len(1000L), 3L),
  seed = prod_seeds, groups = 160L, repeats = 16L,
  beta0 = -0.3, beta1 = 0.6, alpha0 = log(0.8),
  design_mode = mode, master_seed = master_seed,
  stringsAsFactors = FALSE)
# Create only after all prerequisites are checked.
dir.create(out, recursive = TRUE, showWarnings = FALSE)
if (!dir.exists(out)) stop("Could not create output directory")
out <- normalizePath(out, mustWork = TRUE)
write.csv(manifest, file.path(out, "manifest.csv"), row.names = FALSE)
writeLines(as.character(packageVersion("drmTMB")), file.path(out, "package-version.txt"))
writeLines(capture.output(sessionInfo()), file.path(out, "sessionInfo.txt"))
loaded <- getLoadedDLLs()[["drmTMB"]]
if (is.null(loaded) || !file.exists(loaded[["path"]])) stop("drmTMB compiled DLL is not loaded")
source_files <- c("R/drmTMB.R", "R/methods.R", "R/profile.R", "src/drmTMB.cpp",
  "tests/testthat/helper-binomial-sd-regression.R",
  "tools/general-sd-regression/native-calibration/prepare.R",
  "tools/general-sd-regression/native-calibration/worker.R",
  "tools/general-sd-regression/native-calibration/generator.R",
  "tools/general-sd-regression/native-calibration/run.py",
  "tools/general-sd-regression/native-calibration/integrity.py",
  "tools/general-sd-regression/native-calibration/summarize.R",
  "tools/general-sd-regression/native-calibration/self-test.py",
  "tools/general-sd-regression/native-calibration/contention.py",
  "tools/general-sd-regression/native-calibration/test-contention.py",
  "tools/general-sd-regression/native-calibration/staged-decision.R",
  "tools/general-sd-regression/native-calibration/test-staged-decision.R",
  "tools/general-sd-regression/native-calibration/stage-two-seeds.R",
  "docs/dev-log/general-sd-regression/stage-two-manifest.csv",
  "docs/dev-log/general-sd-regression/staged-calibration-contract.md",
  "docs/dev-log/general-sd-regression/native-calibration-design.md")
files <- c(file.path(root, source_files), loaded[["path"]],
  file.path(pkg, c("DESCRIPTION", "NAMESPACE", "Meta/package.rds")),
  file.path(pkg, "R", c("drmTMB.rdb", "drmTMB.rdx")), R.home("bin/R"))
files <- c(files, file.path(out, "manifest.csv"))
if (!all(file.exists(files))) stop("Cannot hash all source/runtime artifacts: ", paste(files[!file.exists(files)], collapse = ", "))
sha <- vapply(files, digest::digest, character(1L), file = TRUE, algo = "sha256")
hashes <- data.frame(path = files, sha256 = unname(sha))
write.csv(hashes, file.path(out, "source-hashes.csv"), row.names = FALSE)
writeLines(c("design_id=native-bernoulli-sd-ordinary-q1-v1",
  paste0("design_mode=", mode), paste0("master_seed=", master_seed), "pilot_master_seed=2026101702",
  "production_master_seed=2026101703", "qualification_master_seed=2026101704",
  "planned_attempts=3000", "workers=16", "per_case_timeout_seconds=120",
  "campaign_timeout_seconds=3600", paste0("stage_two_manifest_sha256=", stage_two_sha),
  "stage_two_status=frozen_not_authorized", "status=prepared_not_launched"),
  file.path(out, "design-receipt.txt"))
cat(sprintf("PREPARED 3000 rows mode=%s master_seed=%d; no fits launched\n", mode, master_seed))
cat(sprintf("REGISTRY_SHA256=%s\n", digest::digest(file.path(out, "source-hashes.csv"), algo="sha256", file=TRUE)))
