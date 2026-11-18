script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- sub("^--file=", "", script_arg[[1L]])
script_dir <- dirname(normalizePath(script_path))
implementation <- file.path(script_dir, "clean-manifests.R")
if (!file.exists(implementation)) {
  stop("clean Bernoulli manifest generator is not implemented yet", call. = FALSE)
}
source(implementation)

source(file.path(dirname(implementation), "prepare-095.R"), local = TRUE)
root <- normalizePath(file.path(dirname(implementation), "../../.."), mustWork = TRUE)
frozen_dir <- file.path(root,
  "docs/dev-log/general-sd-regression/evidence/calibration-20261019/clean-current-seed-design-v1")
validate_clean_bernoulli_seed_bundle(frozen_dir)
clean_receipt <- c(
  design_mode = "clean_current", master_seed = "2026101901",
  profile_level = "0.95", planned_attempts = "3000",
  calibration_claim = "true", clean_current_seed_stream = "2026101901",
  excluded_historical_streams =
    "2026101702:6,2026101703:3000,2026101704:3000,2026101705:10000",
  stage_two_manifest_sha256 = digest::digest(
    file.path(frozen_dir, "look2.csv"), algo = "sha256", file = TRUE),
  stage_two_status =
    "clean_current_manifest_frozen_adapter_reconciliation_outstanding_not_authorized"
)
stopifnot(isTRUE(validate_clean_current_receipt(
  clean_receipt, file.path(frozen_dir, "look2.csv"))))
for (field in c("design_mode", "master_seed", "profile_level", "planned_attempts", "calibration_claim",
                "clean_current_seed_stream", "excluded_historical_streams",
                "stage_two_status")) {
  bad_receipt <- clean_receipt
  bad_receipt[[field]] <- "wrong"
  rejected_receipt <- try(validate_clean_current_receipt(
    bad_receipt, file.path(frozen_dir, "look2.csv")), silent = TRUE)
  stopifnot(inherits(rejected_receipt, "try-error"))
}
bad_receipt <- clean_receipt
bad_receipt[["stage_two_manifest_sha256"]] <- "wrong"
stopifnot(inherits(try(validate_clean_current_receipt(
  bad_receipt, file.path(frozen_dir, "look2.csv")), silent = TRUE), "try-error"))

first <- build_clean_bernoulli_manifests()
second <- build_clean_bernoulli_manifests()
stopifnot(identical(first, second))
stopifnot(identical(names(first), c("timing", "look1", "look2")))

timing <- first$timing
look1 <- first$look1
look2 <- first$look2
stopifnot(nrow(timing) == 45L, nrow(look1) == 3000L, nrow(look2) == 9000L)
stopifnot(identical(as.integer(timing$index), seq_len(45L)))
stopifnot(identical(as.integer(look1$index), seq_len(3000L)))
stopifnot(identical(as.integer(look2$index), seq_len(9000L)))
stopifnot(identical(as.numeric(table(timing$a)), rep(15, 3L)))
stopifnot(identical(as.numeric(table(look1$a)), rep(1000, 3L)))
stopifnot(identical(as.numeric(table(look2$a)), rep(3000, 3L)))
stopifnot(identical(sort(unique(look1$replicate)), 1:1000))
stopifnot(identical(sort(unique(look2$replicate)), 1001:4000))

all_seeds <- c(timing$seed, look1$seed, look2$seed)
stopifnot(length(all_seeds) == 12045L, !anyDuplicated(all_seeds))
historical <- c(
  { set.seed(2026101702L); sample.int(.Machine$integer.max, 6L) },
  { set.seed(2026101703L); sample.int(.Machine$integer.max, 3000L) },
  { set.seed(2026101704L); sample.int(.Machine$integer.max, 3000L) },
  { set.seed(2026101705L); sample.int(.Machine$integer.max, 10000L) }
)
stopifnot(!length(intersect(all_seeds, historical)))
stopifnot(identical(unique(timing$design_mode), "timing_only"))
stopifnot(identical(unique(look1$design_mode), "clean_current"))
stopifnot(identical(unique(look2$design_mode), "clean_current"))
stopifnot(identical(unique(look1$master_seed), 2026101901L))
stopifnot(identical(unique(look2$master_seed), 2026101902L))
for (nm in names(first)) {
  frozen <- read.csv(file.path(frozen_dir, paste0(nm, ".csv")), stringsAsFactors = FALSE)
  stopifnot(isTRUE(all.equal(frozen, first[[nm]], tolerance = 1e-14,
                             check.attributes = FALSE)))
}
seed_design <- readLines(file.path(frozen_dir, "seed-design.txt"), warn = FALSE)
stopifnot("status=manifests_frozen_no_fits_launched" %in% seed_design,
          "look1_master_seed=2026101901" %in% seed_design,
          "look2_master_seed=2026101902" %in% seed_design,
          "existing_v8_attempts_reused=false" %in% seed_design)
stopifnot(all(vapply(first, function(x) all(x$groups == 160L) &&
                     all(x$repeats == 16L), logical(1L))))

tampered_bundle <- tempfile("tampered-clean-seeds-")
dir.create(tampered_bundle)
file.copy(file.path(frozen_dir, c("look1.csv", "look2.csv", "timing.csv", "seed-design.txt")),
          tampered_bundle)
writeLines("tampered", file.path(tampered_bundle, "look1.csv"))
rejected_bundle <- try(validate_clean_bernoulli_seed_bundle(tampered_bundle), silent = TRUE)
stopifnot(inherits(rejected_bundle, "try-error"),
          grepl("SHA-256 mismatch", as.character(rejected_bundle), fixed = TRUE))
unlink(tampered_bundle, recursive = TRUE)

look1_path <- tempfile("clean-look1-")
write.csv(look1, look1_path, row.names = FALSE)
validated_look1 <- validate_clean_look1_manifest(look1_path, look1)
stopifnot(isTRUE(all.equal(validated_look1, look1, tolerance = 1e-14,
                           check.attributes = FALSE)))
route_test <- system2(
  "python3",
  c(shQuote(file.path(dirname(implementation), "test-clean-current-route.py")),
    shQuote(look1_path)),
  stdout = TRUE,
  stderr = TRUE
)
route_status <- attr(route_test, "status")
if (is.null(route_status)) route_status <- 0L
if (route_status != 0L) stop(paste(route_test, collapse = "\n"), call. = FALSE)
historical_look1 <- look1
historical_look1$seed <- {
  set.seed(2026101703L)
  sample.int(.Machine$integer.max, 3000L)
}
write.csv(historical_look1, look1_path, row.names = FALSE)
rejected_historical <- try(
  validate_clean_look1_manifest(look1_path, look1),
  silent = TRUE
)
stopifnot(inherits(rejected_historical, "try-error"),
          grepl("does not match", as.character(rejected_historical), fixed = TRUE))
unlink(look1_path)

set.seed(71301L)
rng_before <- .Random.seed
invisible(build_clean_bernoulli_manifests())
stopifnot(identical(.Random.seed, rng_before))
extra_seed <- look2$seed[[1L]]
with_extra <- build_clean_bernoulli_manifests(additional_excluded = extra_seed)
stopifnot(!extra_seed %in% c(with_extra$timing$seed, with_extra$look1$seed,
                             with_extra$look2$seed))

temporary_parent <- tempfile("clean-seed-manifests-")
dir.create(temporary_parent)
temporary_output <- file.path(temporary_parent, "campaign-seeds")
written <- write_clean_bernoulli_manifests(temporary_output)
stopifnot(identical(normalizePath(written), normalizePath(temporary_output)))
for (name in names(first)) {
  disk <- read.csv(file.path(temporary_output, paste0(name, ".csv")),
                   stringsAsFactors = FALSE)
  stopifnot(isTRUE(all.equal(disk, first[[name]], tolerance = 1e-14)))
}
stopifnot(file.exists(file.path(temporary_output, "seed-design.txt")))
overwrite <- try(write_clean_bernoulli_manifests(temporary_output), silent = TRUE)
stopifnot(inherits(overwrite, "try-error"),
          grepl("Refusing to overwrite", as.character(overwrite), fixed = TRUE))
unlink(temporary_parent, recursive = TRUE)

cat("PASS: frozen clean-current look-one/look-two manifests match the deterministic producer and exclude historical streams\n")
