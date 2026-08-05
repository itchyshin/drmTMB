#!/usr/bin/env Rscript
# Ten-clause review of 135-trace Totoro receipts.
# Authority: PREREGISTRATION.md §4–§5 · LOOP/GOAL.md

receipt_dir <- commandArgs(trailingOnly = TRUE)[1L]
if (is.na(receipt_dir) || !nzchar(receipt_dir)) {
  receipt_dir <- "docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/totoro-receipts"
}
out <- "docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign"

files <- list.files(receipt_dir, pattern = "-receipt\\.tsv$", recursive = TRUE, full.names = TRUE)
if (length(files) != 135L) {
  stop("Expected 135 receipts, found ", length(files), " under ", receipt_dir, call. = FALSE)
}

as_log <- function(x) {
  if (is.logical(x)) return(x)
  toupper(as.character(x)) %in% c("TRUE", "T", "1")
}

rows <- lapply(files, function(f) {
  utils::read.table(f, header = TRUE, sep = "\t", stringsAsFactors = FALSE, check.names = FALSE)
})
d <- do.call(rbind, rows)

for (nm in c(
  "brackets_truth", "clamp_limited", "lr_both_sides", "unimodal",
  "promotion_eligible", "pdHess", "profile_boundary",
  "structured_sigma_claim_required"
)) {
  if (nm %in% names(d)) d[[nm]] <- as_log(d[[nm]])
}
d$rel_err <- as.numeric(d$rel_err)
d$estimate <- as.numeric(d$estimate)
d$lower <- as.numeric(d$lower)
d$upper <- as.numeric(d$upper)
d$true_value <- as.numeric(d$true_value)
d$convergence <- as.integer(d$convergence)
d$failure_reason <- as.character(d$failure_reason)
d$failure_reason[is.na(d$failure_reason)] <- ""

# Per-seed clauses (Fisher location review = c10, applied at cell close)
# Vector-safe (isTRUE() is length-1 only and would zero every clause).
true1 <- function(x) !is.na(x) & (x %in% TRUE)
false1 <- function(x) !is.na(x) & (x %in% FALSE)

d$c1_seed <- is.finite(d$rel_err) & (d$rel_err <= 0.35)
d$c3 <- (d$conf_status == "profile") &
  is.finite(d$lower) & is.finite(d$estimate) & is.finite(d$upper) &
  (d$lower < d$estimate) & (d$estimate < d$upper)
d$c4 <- (d$convergence == 0L) & true1(d$pdHess)
# NA clamp/boundary = fail-closed
d$c5 <- false1(d$profile_boundary) & false1(d$clamp_limited)
d$c6 <- true1(d$lr_both_sides) & true1(d$unimodal)
d$c7 <- d$profile_engine == "tmbprofile"
d$c8 <- true1(d$brackets_truth)
d$c9 <- is.finite(d$true_value) & (d$true_value != 0)
d$seed_pass <- d$c1_seed & d$c3 & d$c4 & d$c5 & d$c6 & d$c7 & d$c8 & d$c9

cell_order <- c(
  "mc-0568", "mc-0576", "mc-0593", "mc-0594", "mc-0595", "mc-0596", "mc-0597",
  "mc-0418", "mc-0436", "mc-0446", "mc-0450", "mc-0454", "mc-0425", "mc-0653"
)

summarize_cell <- function(x) {
  targets <- unique(x$profile_parameter)
  tgt_ok <- vapply(targets, function(t) {
    xt <- x[x$profile_parameter == t, , drop = FALSE]
    need <- if (grepl("^cor:", t)) 8L else 5L
    nrow(xt) >= need && all(xt$seed_pass)
  }, logical(1))
  mean_rel <- mean(x$rel_err, na.rm = TRUE)
  c1 <- all(x$c1_seed) && is.finite(mean_rel) && mean_rel <= 0.35
  all_seed_pass <- all(x$seed_pass)
  verdict <- if (c1 && all(tgt_ok) && all_seed_pass) "PASS" else "WITHHOLD"
  notes <- character()
  if (!isTRUE(c1)) notes <- c(notes, "c1_rel_err")
  if (!all(tgt_ok)) notes <- c(notes, "c2_seed_count_or_fail")
  if (any(!x$c3, na.rm = TRUE) || any(is.na(x$c3))) notes <- c(notes, "c3_status")
  if (any(!x$c4, na.rm = TRUE) || any(is.na(x$c4))) notes <- c(notes, "c4_fit")
  if (any(!x$c5, na.rm = TRUE) || any(is.na(x$c5))) notes <- c(notes, "c5_boundary_clamp")
  if (any(!x$c6, na.rm = TRUE) || any(is.na(x$c6))) notes <- c(notes, "c6_lr_unimodal")
  if (any(!x$c7, na.rm = TRUE) || any(is.na(x$c7))) notes <- c(notes, "c7_engine")
  if (any(!x$c8, na.rm = TRUE) || any(is.na(x$c8))) notes <- c(notes, "c8_truth")
  if (any(!x$c9, na.rm = TRUE) || any(is.na(x$c9))) notes <- c(notes, "c9_truth_zero")
  data.frame(
    cell_id = x$cell_id[[1L]],
    n_receipts = nrow(x),
    n_targets = length(targets),
    n_seed_pass = sum(x$seed_pass, na.rm = TRUE),
    n_truth_bracket = sum(true1(x$brackets_truth)),
    mean_rel_err = round(mean_rel, 4),
    max_rel_err = round(max(x$rel_err, na.rm = TRUE), 4),
    any_clamp = any(true1(x$clamp_limited)),
    any_boundary = any(true1(x$profile_boundary)),
    any_lr_fail = any(!true1(x$lr_both_sides)),
    any_unimodal_fail = any(!true1(x$unimodal)),
    structured_sigma_claim_required = any(true1(x$structured_sigma_claim_required)),
    verdict = verdict,
    fail_notes = paste(unique(notes), collapse = ","),
    stringsAsFactors = FALSE
  )
}

by_cell <- split(d, d$cell_id)
summ <- do.call(rbind, lapply(cell_order, function(id) {
  if (is.null(by_cell[[id]])) {
    stop("Missing cell in receipts: ", id, call. = FALSE)
  }
  summarize_cell(by_cell[[id]])
}))

print(summ, row.names = FALSE)
message("PASS=", sum(summ$verdict == "PASS"), " WITHHOLD=", sum(summ$verdict == "WITHHOLD"))

utils::write.table(d, file.path(out, "all-receipts.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
utils::write.table(summ, file.path(out, "CELL-VERDICTS.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)

fails <- d[
  !d$seed_pass,
  c(
    "cell_id", "seed", "profile_parameter", "rel_err", "conf_status",
    "brackets_truth", "clamp_limited", "profile_boundary",
    "lr_both_sides", "unimodal", "failure_reason"
  ),
  drop = FALSE
]
utils::write.table(fails, file.path(out, "seed-failures.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
message("n_seed_failures=", nrow(fails))
if (nrow(fails)) print(fails, row.names = FALSE)

# Markdown verdict board
lines <- c(
  "# 135-trace cell verdicts (mechanical ten-clause)",
  "",
  paste0("Source SHA: `", trimws(readLines(file.path(out, "totoro-meta/SOURCE_SHA.txt"), warn = FALSE)[1]), "`."),
  paste0("Receipts: ", length(files), " under `totoro-receipts/`."),
  "Clause 10 (Fisher location review) is recorded separately before promotion.",
  "",
  "| cell | n | pass seeds | mean|max rel_err | clamp | boundary | LR fail | unimodal fail | verdict | notes |",
  "|---|---:|---:|---|---|---|---|---|---|---|"
)
for (i in seq_len(nrow(summ))) {
  r <- summ[i, ]
  lines <- c(lines, sprintf(
    "| %s | %d | %d/%d | %.3f|%.3f | %s | %s | %s | %s | **%s** | %s |",
    r$cell_id, r$n_receipts, r$n_seed_pass, r$n_receipts,
    r$mean_rel_err, r$max_rel_err,
    r$any_clamp, r$any_boundary, r$any_lr_fail, r$any_unimodal_fail,
    r$verdict, r$fail_notes
  ))
}
writeLines(lines, file.path(out, "CELL-VERDICTS.md"))
message("wrote ", file.path(out, "CELL-VERDICTS.md"))
