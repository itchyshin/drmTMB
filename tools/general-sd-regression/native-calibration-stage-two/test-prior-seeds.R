args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Supply adapter directory")
source(file.path(args[[1L]], "verify-prior-seeds.R"))
tmp <- tempfile("prior-seed-test-"); dir.create(tmp)
make_manifest <- function(n, master, mode) {
  set.seed(master); seed <- sample.int(.Machine$integer.max, n)
  if (mode == "pilot") {
    # Match the frozen expand.grid(a, pilot) order used by runner-at-launch.R:
    # a varies fastest and pilot labels form two contiguous three-row blocks.
    manifest <- expand.grid(a = c(-.5, 0, .5), pilot = 1:2)
    manifest$seed <- seed
    manifest$manifest_row <- seq_len(n)
    manifest
  } else {
    truth <- rep(c(-.5, 0, .5), each = n / 3L)
    data.frame(index = seq_len(n), a = truth,
      replicate = rep(seq_len(n / 3L), 3L), seed = seed, groups = 160L,
      repeats = 16L, beta0 = -.3, beta1 = .6, alpha0 = log(.8),
      design_mode = mode, master_seed = master)
  }
}
cases <- list(list(n=6L, master=2026101702L, mode="pilot"),
              list(n=3000L, master=2026101703L, mode="production"),
              list(n=3000L, master=2026101704L, mode="qualification"))
for (case in cases) {
  manifest <- make_manifest(case$n, case$master, case$mode)
  path <- file.path(tmp, paste0(case$mode, ".csv"))
  write.csv(manifest, path, row.names=FALSE)
  verify_native_sd_prior_manifest(path, case$n, case$master, case$mode)
  for (field in c("seed", "a", if (case$mode == "pilot") "pilot" else c("replicate", "design_mode"))) {
    mutant <- manifest
    if (field == "design_mode") mutant[[field]][[case$n]] <- "corrupted"
    else if (field == "replicate") mutant[[field]][[case$n]] <- mutant[[field]][[case$n]] + 1L
    else if (field == "a") mutant[[field]][[1L]] <- 0.5
    else mutant[[field]][[case$n]] <- mutant[[field]][[case$n]] + 1L
    bad_path <- file.path(tmp, paste0(case$mode, "-bad-", field, ".csv"))
    write.csv(mutant, bad_path, row.names=FALSE)
    failed <- try(verify_native_sd_prior_manifest(bad_path, case$n, case$master, case$mode), silent=TRUE)
    if (!inherits(failed, "try-error")) stop("corruption was accepted: ", case$mode, "/", field)
  }
}
pilot_fixture <- data.frame(
  a = rep(c(-.5, 0, .5), times = 2L),
  pilot = rep(1:2, each = 3L),
  seed = c(1746912062L, 1475354618L, 1120801948L,
           131856170L, 883057618L, 661797416L),
  manifest_row = seq_len(6L)
)
pilot_fixture_path <- file.path(tmp, "retained-totoro-pilot.csv")
write.csv(pilot_fixture, pilot_fixture_path, row.names = FALSE)
verify_native_sd_prior_manifest(pilot_fixture_path, 6L, 2026101702L, "pilot")
if (!identical(as.numeric(pilot_fixture$a), rep(c(-.5, 0, .5), times = 2L)) ||
    !identical(as.integer(pilot_fixture$pilot), rep(1:2, each = 3L))) {
  stop("retained Totoro pilot fixture no longer matches its frozen expand.grid order")
}
legacy_pilot <- pilot_fixture[c("a", "pilot", "seed")]
legacy_pilot_path <- file.path(tmp, "retained-totoro-pilot-without-row-id.csv")
write.csv(legacy_pilot, legacy_pilot_path, row.names = FALSE)
verify_native_sd_prior_manifest(legacy_pilot_path, 6L, 2026101702L, "pilot")
wrong_truth_legacy_pilot <- legacy_pilot
wrong_truth_legacy_pilot$a[[1L]] <- 0.5
wrong_truth_legacy_path <- file.path(tmp, "pilot-without-row-id-wrong-truth.csv")
write.csv(wrong_truth_legacy_pilot, wrong_truth_legacy_path, row.names = FALSE)
if (!inherits(try(verify_native_sd_prior_manifest(wrong_truth_legacy_path, 6L,
                                                  2026101702L, "pilot"), silent = TRUE), "try-error")) {
  stop("a legacy pilot with corrupted truth and no row IDs was accepted")
}
reordered_legacy_pilot <- legacy_pilot[c(2L, 1L, 3L, 4L, 5L, 6L), ]
reordered_legacy_path <- file.path(tmp, "pilot-without-row-id-reordered.csv")
write.csv(reordered_legacy_pilot, reordered_legacy_path, row.names = FALSE)
if (!inherits(try(verify_native_sd_prior_manifest(reordered_legacy_path, 6L,
                                                  2026101702L, "pilot"), silent = TRUE), "try-error")) {
  stop("a reordered legacy pilot without explicit row IDs was accepted")
}
qualification_without_id <- make_manifest(3000L, 2026101704L, "qualification")
qualification_without_id$index <- NULL
qualification_without_id_path <- file.path(tmp, "qualification-without-row-id.csv")
write.csv(qualification_without_id, qualification_without_id_path, row.names = FALSE)
if (!inherits(try(verify_native_sd_prior_manifest(qualification_without_id_path, 3000L,
                                                  2026101704L, "qualification"), silent = TRUE), "try-error")) {
  stop("a qualification stream without explicit row IDs was accepted")
}
grouped_old_order <- pilot_fixture
grouped_old_order$a <- rep(c(-.5, 0, .5), each = 2L)
grouped_old_order$pilot <- rep(1:2, times = 3L)
bad_grouped <- file.path(tmp, "pilot-bad-old-grouped-order.csv")
write.csv(grouped_old_order, bad_grouped, row.names = FALSE)
if (!inherits(try(verify_native_sd_prior_manifest(bad_grouped, 6L, 2026101702L,
                                                  "pilot"), silent = TRUE), "try-error")) {
  stop("the old grouped pilot ordering was accepted")
}
reordered_pilot <- pilot_fixture[c(2L, 1L, 3L, 4L, 5L, 6L), ]
bad_reordered <- file.path(tmp, "pilot-bad-row-order.csv")
write.csv(reordered_pilot, bad_reordered, row.names = FALSE)
if (!inherits(try(verify_native_sd_prior_manifest(bad_reordered, 6L, 2026101702L,
                                                  "pilot"), silent = TRUE), "try-error")) {
  stop("a reordered pilot manifest was accepted")
}
cat("PRIOR_SEED_STREAM_NEGATIVES_PASS streams=3\n")
