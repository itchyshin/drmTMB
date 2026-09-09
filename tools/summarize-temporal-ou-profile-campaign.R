#!/usr/bin/env Rscript

# Read-only verifier/summarizer for immutable temporal OU profile campaign shards.
# It never calls drmTMB or starts a fit.

args <- commandArgs(trailingOnly = TRUE)
script_file <- sub("^--file=", "", commandArgs(trailingOnly = FALSE)[grep("^--file=", commandArgs(trailingOnly = FALSE))])
if (length(script_file) != 1L) stop("Cannot locate the campaign summarizer script.", call. = FALSE)
sys.source(file.path(dirname(normalizePath(script_file)), "temporal-ou-profile-campaign-assessment.R"))
value <- function(name) {
  hit <- grep(paste0('^--', name, '='), args, value = TRUE)
  if (length(hit) != 1L) stop(sprintf('Require exactly one --%s=<path>.', name), call. = FALSE)
  sub(paste0('^--', name, '='), '', hit)
}
input_dir <- value('input-dir')
mode <- if (any(args == '--reverify')) 'reverify' else if (any(args == '--write-summary')) 'write' else stop('Choose --reverify or --write-summary.', call. = FALSE)
if (length(args) != 3L) stop('Usage: ... --input-dir=<dir> --output-dir=<dir> [--reverify|--write-summary]', call. = FALSE)
output_dir <- value('output-dir')
summary_file <- file.path(output_dir, 'temporal-ou-profile-campaign-summary.csv')

fail <- function(...) stop(..., call. = FALSE)
read_task <- function(path, task) {
  needed <- c('raw-attempts.csv', 'profile-pilot-results.csv', 'profile-intervals.csv', 'provenance.csv', 'RESULTS.md')
  if (!all(file.exists(file.path(path, needed)))) fail('Incomplete campaign task ', task, '.')
  p <- read.csv(file.path(path, 'provenance.csv'), stringsAsFactors = FALSE)
  source_commit <- p$value[p$key == 'source_commit']; runner_md5 <- p$value[p$key == 'runner_md5']
  if (length(source_commit) != 1L || length(runner_md5) != 1L ||
      !grepl('^[0-9a-f]{40}$', source_commit) || !grepl('^[0-9a-f]{32}$', runner_md5)) fail('Invalid provenance in task ', task, '.')
  results <- read.csv(file.path(path, 'profile-pilot-results.csv'), stringsAsFactors = FALSE)
  attempts <- read.csv(file.path(path, 'raw-attempts.csv'), stringsAsFactors = FALSE)
  intervals <- read.csv(file.path(path, 'profile-intervals.csv'), stringsAsFactors = FALSE)
  required <- c('fixture','cell','seed','parm','coefficient','truth','estimate','lower','upper','interval_available','covered','conf.status')
  if (nrow(results) != 1L || nrow(attempts) != 2L || nrow(intervals) != 3L || !all(required %in% names(intervals)) ||
      !identical(sort(intervals$parm), sort(c('fixef:mu:(Intercept)', 'fixef:mu:between', 'fixef:mu:within'))) ||
      anyDuplicated(intervals$parm) || any(intervals$cell != results$cell[[1L]]) || any(intervals$seed != results$seed[[1L]])) fail('Malformed retained rows in task ', task, '.')
  intervals$task <- task; intervals$source_commit <- source_commit; intervals$runner_md5 <- runner_md5
  intervals
}
paths <- file.path(input_dir, sprintf('task-%04d', 1:3000))
cleanup_root <- NULL
if (!dir.exists(input_dir)) fail('Campaign input directory is absent.')
if (!all(dir.exists(paths))) {
  shards <- file.path(input_dir, sprintf('shard-%03d.tar.gz', 1:60))
  if (!all(file.exists(shards))) fail('Require task-0001 through task-3000 directories or 60 immutable shard tarballs.')
  cleanup_root <- tempfile('temporal-ou-campaign-shards-')
  dir.create(cleanup_root)
  on.exit(unlink(cleanup_root, recursive = TRUE), add = TRUE)
  for (shard in shards) utils::untar(shard, exdir = cleanup_root)
  paths <- file.path(cleanup_root, sprintf('task-%04d', 1:3000))
  if (!all(dir.exists(paths))) fail('Immutable shard tarballs do not contain every task-0001 through task-3000 directory.')
}
rows <- do.call(rbind, Map(read_task, paths, 1:3000))
if (length(unique(rows$source_commit)) != 1L || length(unique(rows$runner_md5)) != 1L) fail('Campaign shards do not share one frozen source and worker fingerprint.')
source_commit <- unique(rows$source_commit)
runner_md5 <- unique(rows$runner_md5)
if (system2('git', c('cat-file', '-e', paste0(source_commit, '^{commit}'))) != 0L) fail('Campaign provenance names a source commit absent from this checkout.')
source_worker <- tempfile('temporal-ou-campaign-worker-', fileext = '.R')
on.exit(unlink(source_worker), add = TRUE)
if (system2('git', c('show', paste0(source_commit, ':tools/run-temporal-ou-profile-pilot.R')), stdout = source_worker, stderr = FALSE) != 0L || !file.exists(source_worker)) fail('Campaign source commit does not contain the declared worker.')
if (!identical(unname(tools::md5sum(source_worker)), runner_md5)) fail('Campaign worker MD5 does not match the declared immutable source commit.')
if (anyDuplicated(paste(rows$cell, rows$seed, rows$parm)) || any(table(rows$cell) != 3000L) || any(table(rows$cell, rows$parm) != 1000L)) fail('Campaign denominator is not exactly 1,000 data sets per cell and coefficient.')
summary <- do.call(rbind, lapply(split(rows, interaction(rows$cell, rows$parm, drop = TRUE)), function(x) {
  available <- as.logical(x$interval_available); covered <- as.logical(x$covered)
  coverage <- mean(covered); mcse <- sqrt(coverage * (1 - coverage) / nrow(x)); empirical_sd <- stats::sd(x$estimate, na.rm = TRUE)
  data.frame(cell=x$cell[[1L]], parm=x$parm[[1L]], n_attempted=nrow(x), n_available=sum(available),
    availability=mean(available), coverage_all=coverage,
    coverage_conditional=if (any(available)) mean(covered[available]) else NA_real_, coverage_mcse=mcse,
    bias=mean(x$estimate-x$truth, na.rm=TRUE), empirical_sd=empirical_sd,
    mean_interval_width=mean(x$upper[available]-x$lower[available]),
    source_commit=x$source_commit[[1L]], runner_md5=x$runner_md5[[1L]], stringsAsFactors=FALSE)
}))
summary <- summary[order(summary$cell, summary$parm), ]; row.names(summary) <- NULL
summary <- temporal_ou_profile_campaign_assess(summary)
if (mode == 'write') {
  dir.create(output_dir, recursive=TRUE, showWarnings=FALSE)
  if (file.exists(summary_file)) fail('Refuse to overwrite retained campaign summary.')
  write.csv(summary, summary_file, row.names=FALSE)
} else {
  if (!file.exists(summary_file)) fail('G15 requires a retained campaign summary; reverify will not write one.')
  old <- read.csv(summary_file, stringsAsFactors=FALSE)
  if (!isTRUE(all.equal(old, summary, check.attributes=FALSE))) fail('Retained campaign summary does not reproduce from immutable shards.')
}
cat('TEMPORAL_OU_PROFILE_CAMPAIGN_SUMMARY_PASS\n')
if (all(summary$qualification == "qualified_in_simulated_cell")) {
  cat('TEMPORAL_OU_PROFILE_CAMPAIGN_QUALIFIED\n')
} else {
  cat('TEMPORAL_OU_PROFILE_CAMPAIGN_UNQUALIFIED\n')
}
