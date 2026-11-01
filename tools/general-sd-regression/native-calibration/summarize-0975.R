args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Usage: Rscript summarize-0975.R CALIBRATION_DIRECTORY EXTERNAL_REGISTRY_SHA256")
out <- normalizePath(args[[1L]], mustWork = TRUE)
if (!requireNamespace("digest", quietly = TRUE)) stop("digest is required for artifact verification")
script_arg <- grep("^--file=", commandArgs(), value = TRUE)
if (length(script_arg) != 1L) stop("Cannot identify the running summarizer script")
analysis_script_path <- normalizePath(sub("^--file=", "", script_arg), mustWork = TRUE)
analysis_script_sha256 <- digest::digest(analysis_script_path, algo = "sha256", file = TRUE)
manifest_path <- file.path(out, "manifest.csv")
hashes_path <- file.path(out, "source-hashes.csv")
receipt_path <- file.path(out, "supervisor-receipt.json")
if (!all(file.exists(c(manifest_path, hashes_path, receipt_path)))) stop("Manifest, artifact hashes, and supervisor receipt are required")
hashes <- read.csv(hashes_path, stringsAsFactors = FALSE)
if (!all(c("path", "sha256") %in% names(hashes)) || anyDuplicated(hashes$path)) stop("Invalid or duplicate source hash registry")
registered_summarizer <- hashes$path[endsWith(hashes$path, "native-calibration/summarize-0975.R")]
if (length(registered_summarizer) > 1L) stop("Multiple first-look summarizer entries in source registry")
summary_tool_registered <- length(registered_summarizer) == 1L &&
  identical(normalizePath(registered_summarizer, mustWork = TRUE), analysis_script_path)
if (length(registered_summarizer) == 1L && !summary_tool_registered)
  stop("Running summarizer differs from the source-registry entry")
manifest_sha <- digest::digest(manifest_path, algo="sha256", file=TRUE)
manifest_paths <- normalizePath(hashes$path[basename(hashes$path) == "manifest.csv"], mustWork=FALSE)
direct_manifest_pin <- normalizePath(manifest_path) %in% manifest_paths
required_suffixes <- c("R/drmTMB.R", "R/methods.R", "R/profile.R", "src/drmTMB.cpp",
  "tests/testthat/helper-binomial-sd-regression.R", "native-calibration/prepare-0975.R",
  "native-calibration/worker-0975.R", "native-calibration/generator.R", "native-calibration/run.py",
  "native-calibration/run-0975.py", "native-calibration/integrity.py",
  "native-calibration/self-test.py",
  "native-calibration/staged-decision.R", "native-calibration/test-staged-decision.R",
  "native-calibration/stage-two-seeds.R", "native-calibration/contention.py",
  "native-calibration/test-contention.py", "stage-two-manifest.csv",
  "staged-calibration-contract.md",
  "native-calibration-design.md", "drmTMB.rdb", "drmTMB.rdx", "drmTMB/DESCRIPTION",
  "drmTMB/NAMESPACE", "drmTMB/Meta/package.rds", "/bin/R")
if (!all(vapply(required_suffixes, function(s) any(endsWith(hashes$path, s)), logical(1L))) ||
    !any(grepl("/drmTMB[^/]*\\.(so|dylib|dll)$", hashes$path, ignore.case=TRUE))) stop("Source or installed-library artifact is absent from the integrity registry")
for (i in seq_len(nrow(hashes))) {
  p <- hashes$path[[i]]
  if (!file.exists(p) || !identical(digest::digest(p, algo = "sha256", file = TRUE), hashes$sha256[[i]])) stop("Artifact hash mismatch or missing file: ", p)
}
stage_two_entry <- which(endsWith(hashes$path, "stage-two-manifest.csv"))
if (length(stage_two_entry) != 1L || !identical(hashes$sha256[[stage_two_entry]],
    "8fd627ccb8a7f8689c56e629a5ff12e53405be1a508167216632bcf445652e96"))
  stop("Frozen stage-two manifest is absent or has a different pinned digest")
registry_sha <- digest::digest(hashes_path, algo="sha256", file=TRUE)
if (!identical(tolower(args[[2L]]), registry_sha)) stop("External source registry seal mismatch")
if (direct_manifest_pin) {
  if (!manifest_sha %in% hashes$sha256[basename(hashes$path) == "manifest.csv"]) stop("Prepared manifest hash differs from its pinned registry entry")
} else {
  subset_path <- file.path(out,"subset-receipt.json")
  if (!file.exists(subset_path)) stop("Prepared manifest is not pinned and no subset receipt is present")
  subset_identity <- jsonlite::fromJSON(subset_path)
  if (!identical(subset_identity$subset_copy, "byte-identical full frozen 3000-row manifest"))
    stop("Subset receipt does not identify a byte-identical full-manifest copy")
  source_directory <- normalizePath(subset_identity$source_directory, mustWork=TRUE)
  if (identical(source_directory,out)) stop("Subset source directory cannot be the subset itself")
  source_hashes_path <- file.path(source_directory,"source-hashes.csv")
  source_manifest_path <- file.path(source_directory,"manifest.csv")
  if (!file.exists(source_hashes_path) || !file.exists(source_manifest_path)) stop("Subset source directory lacks its prepared registry or manifest")
  source_registry_paths <- normalizePath(hashes$path[basename(hashes$path) == "manifest.csv"], mustWork=FALSE)
  if (!normalizePath(source_manifest_path) %in% source_registry_paths ||
      !identical(readBin(hashes_path,"raw",n=file.info(hashes_path)$size),
                 readBin(source_hashes_path,"raw",n=file.info(source_hashes_path)$size)))
    stop("Subset registry is not byte-identical to its pinned source registry")
  source_manifest_sha <- digest::digest(source_manifest_path,algo="sha256",file=TRUE)
  if (!identical(manifest_sha,source_manifest_sha) ||
      !identical(subset_identity$manifest_sha256,manifest_sha))
    stop("Subset manifest does not match the source manifest and subset receipt")
}
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
receipt <- jsonlite::fromJSON(receipt_path, simplifyVector = TRUE)
if (nrow(manifest) != 3000L || !identical(as.integer(manifest$index), 1:3000)) stop("Expected immutable 3,000-row manifest")
if (!identical(receipt$manifest_sha256, digest::digest(manifest_path, algo = "sha256", file = TRUE))) stop("Supervisor manifest identity mismatch")
if (!identical(receipt$registry_sha256, registry_sha)) stop("Supervisor registry identity mismatch")
design <- strsplit(readLines(file.path(out,"design-receipt.txt")), "=", fixed=TRUE)
design <- setNames(vapply(design, function(x) if(length(x)>1L) paste(x[-1L],collapse="=") else "", character(1L)),
                   vapply(design, `[[`, character(1L), 1L))
design_mode <- unname(design["design_mode"]); master_seed <- as.integer(design["master_seed"])
if (any(is.na(manifest$master_seed)) || any(manifest$design_mode != design_mode) || any(manifest$master_seed != master_seed) ||
    !identical(receipt$design_mode, design_mode)) stop("Manifest, design receipt, and supervisor mode differ")
planned_ix <- as.integer(unlist(receipt$planned_indices))
if (!length(planned_ix) || anyDuplicated(planned_ix) || any(!planned_ix %in% manifest$index)) stop("Invalid planned subset in supervisor receipt")
if (!is.finite(as.numeric(receipt$finished_at))) stop("Supervisor receipt is not terminal")
if (design_mode == "qualification") {
  subset_path <- file.path(out,"subset-receipt.json")
  if (!file.exists(subset_path)) stop("Qualification summary requires its subset receipt")
  subset <- jsonlite::fromJSON(subset_path)
  if (!identical(as.integer(unlist(subset$planned_indices)),planned_ix) ||
      !identical(subset$registry_sha256,registry_sha) || !identical(subset$design_mode,design_mode) ||
      as.integer(subset$master_seed) != master_seed) stop("Qualification subset receipt identity mismatch")
}
cases <- as.data.frame(receipt$cases, stringsAsFactors = FALSE)
if (anyDuplicated(cases$index) || !setequal(as.integer(cases$index), planned_ix)) stop("Supervisor receipt cases do not exactly cover planned indices")
case_state <- setNames(as.character(cases$status), as.character(cases$index))
case_code <- setNames(as.integer(cases$returncode), as.character(cases$index))
unresolved_campaign_states <- c("interrupted", "not_started", "campaign_timeout", "launch_error")
if (isTRUE(receipt$campaign_complete) &&
    (isTRUE(receipt$interrupted) || any(case_state %in% unresolved_campaign_states))) {
  stop("Supervisor receipt claims campaign completion despite interrupted or unresolved cases")
}
campaign_complete <- identical(design_mode,"production") && master_seed == 2026101703L &&
  identical(planned_ix,1:3000) && isFALSE(receipt$interrupted) && isTRUE(receipt$campaign_complete) &&
  all(case_state[as.character(planned_ix)] %in% c("completed","error","timeout"))
files <- list.files(out, pattern = "^result-[0-9]{4}\\.csv$", full.names = TRUE)
results <- if (length(files)) do.call(rbind, lapply(files, read.csv, stringsAsFactors = FALSE)) else data.frame()
if (nrow(results) && (anyDuplicated(results$index) || any(!results$index %in% planned_ix))) stop("Duplicate result index or result outside planned subset")
if (nrow(results)) {
  rules_path <- hashes$path[endsWith(hashes$path,
    "native-calibration-stage-two/stage-two-rules.R")]
  if (length(rules_path) != 1L) stop("Cannot resolve the pinned profile-level validator")
  source(rules_path)
  native_sd_stage_two_validate_profile_level(results)
}
if (nrow(results)) for (f in files) {
  r <- read.csv(f, stringsAsFactors=FALSE)
  if (nrow(r) != 1L || basename(f) != sprintf("result-%04d.csv", as.integer(r$index[[1L]]))) stop("Result file name/index mismatch: ", f)
}
by_index <- if (nrow(results)) setNames(split(results, results$index), as.character(results$index)) else list()
identity_ok <- function(i, v) {
  m <- manifest[match(i, manifest$index), ]
  isTRUE(v$index[[1L]] == m$index) && isTRUE(v$a[[1L]] == m$a) &&
    isTRUE(v$replicate[[1L]] == m$replicate) && isTRUE(v$seed[[1L]] == m$seed)
}
for (name in names(by_index)) if (!identity_ok(as.integer(name), by_index[[name]])) stop("Result identity does not match manifest index ", name)
for (name in names(by_index)) {
  result <- by_index[[name]]
  status <- case_state[[name]]
  if (isTRUE(result$valid_interval[[1L]]) && !identical(status, "completed")) {
    stop("Worker marks interval valid despite non-completed supervisor status at index ", name)
  }
}
for (i in planned_ix) {
  status <- case_state[[as.character(i)]]
  has <- as.character(i) %in% names(by_index)
  if (status == "completed" && (!has || case_code[[as.character(i)]] != 0L)) stop("Completed supervisor case lacks exactly one zero-exit worker result: ", i)
  if (status == "not_started" && has) stop("Non-started case has a worker result: ", i)
}
staged_decision_path <- hashes$path[endsWith(hashes$path, "native-calibration/staged-decision.R")]
if (length(staged_decision_path) != 1L) stop("Cannot resolve pinned staged-decision.R")
source(normalizePath(staged_decision_path, mustWork=TRUE))
standardized <- lapply(seq_len(nrow(manifest)), function(i) {
  key <- as.character(i)
  v <- by_index[[key]]
  status <- if (key %in% names(case_state)) as.character(case_state[[key]]) else "not_started"
  estimate <- if (!is.null(v) && is.finite(v$estimate[[1L]])) as.numeric(v$estimate[[1L]]) else NA_real_
  lower <- if (!is.null(v) && is.finite(v$lower[[1L]])) as.numeric(v$lower[[1L]]) else NA_real_
  upper <- if (!is.null(v) && is.finite(v$upper[[1L]])) as.numeric(v$upper[[1L]]) else NA_real_
  valid <- !is.null(v) && identical(status, "completed") && identical(case_code[[key]], 0L) &&
    identical(as.character(v$state[[1L]]), "completed") && isTRUE(v$valid_interval[[1L]]) &&
    isTRUE(v$oracle_pass[[1L]]) && is.finite(v$laplace_oracle_error[[1L]]) &&
    abs(v$laplace_oracle_error[[1L]]) < 1e-6 && identical(as.integer(v$convergence[[1L]]), 0L) &&
    isTRUE(v$pdHess[[1L]]) && is.finite(v$max_abs_gradient[[1L]]) && v$max_abs_gradient[[1L]] < 1e-3 &&
    identical(as.character(v$clamp_at_optimum[[1L]]), "ok") &&
    identical(as.character(v$interval_status[[1L]]), "profile") && isFALSE(v$profile_boundary[[1L]]) &&
    is.finite(v$profile_level[[1L]]) && abs(v$profile_level[[1L]] - 0.975) <= 1e-12 &&
    (is.na(v$error[[1L]]) || !nzchar(as.character(v$error[[1L]]))) &&
    is.finite(lower) && is.finite(upper) && lower < upper
  data.frame(truth=as.numeric(manifest$a[[i]]), estimate=estimate, lower=lower, upper=upper,
    profile_level=if(!is.null(v)) as.numeric(v$profile_level[[1L]]) else NA_real_,
    valid=isTRUE(valid), status=status, stringsAsFactors=FALSE)
})
standardized <- do.call(rbind, standardized)
eligible_first_look <- identical(design_mode, "production") && master_seed == 2026101703L &&
  identical(planned_ix, 1:3000) && isTRUE(campaign_complete)
staged <- native_sd_staged_decision(
  standardized, manifest_count=3000L, look=1L,
  completed_campaign=eligible_first_look
)
saveRDS(staged, file.path(out, "staged-decision.rds"))
write.csv(staged$metrics, file.path(out, "staged-metrics.csv"), row.names=FALSE)
write.csv(staged$gates, file.path(out, "staged-gates.csv"), row.names=FALSE)
write.csv(staged$status_counts, file.path(out, "staged-status-counts.csv"), row.names=FALSE)
gate_state <- function(truth, metric) {
  if (!nrow(staged$gates)) return("incomplete")
  hit <- staged$gates$truth == truth & staged$gates$metric == metric
  if (sum(hit) != 1L) return("incomplete")
  as.character(staged$gates$state[hit])
}
decision_accept <- eligible_first_look && identical(staged$decision, "accept")
exact_ci <- function(success, n) if (n <= 0) c(NA_real_, NA_real_) else unname(stats::binom.test(success, n, conf.level=.975)$conf.int)
mean_ci <- function(x) {
  x <- x[is.finite(x)]; if (length(x) < 2L) return(c(NA_real_, NA_real_, ifelse(length(x), mean(x), NA_real_)))
  m <- mean(x); h <- stats::qt(.9875, length(x)-1) * stats::sd(x) / sqrt(length(x)); c(m-h,m+h,m)
}
rows <- lapply(c(-.5, 0, .5), function(a) {
  ix <- planned_ix[manifest$a[planned_ix] == a]; n <- length(ix)
  result <- lapply(ix, function(i) if (as.character(i) %in% names(by_index)) by_index[[as.character(i)]] else NULL)
  estimate <- vapply(result, function(v) if (is.null(v)) NA_real_ else v$estimate[[1L]], numeric(1L))
  fits <- is.finite(estimate)
  healthy <- vapply(seq_along(result), function(j) {
    v <- result[[j]]; !is.null(v) && is.finite(v$convergence[[1L]]) && v$convergence[[1L]] == 0L &&
      isTRUE(v$pdHess[[1L]]) && is.finite(v$max_abs_gradient[[1L]]) && v$max_abs_gradient[[1L]] < 1e-3 &&
      identical(as.character(v$clamp_at_optimum[[1L]]), "ok")
  }, logical(1L))
  valid <- vapply(seq_along(result), function(j) {
    v <- result[[j]]; i <- ix[[j]]; k <- as.character(i)
    !is.null(v) && identical(case_state[[k]], "completed") && identical(case_code[[k]], 0L) &&
      identical(as.character(v$state[[1L]]), "completed") && isTRUE(v$valid_interval[[1L]]) && isTRUE(v$oracle_pass[[1L]]) &&
      is.finite(v$laplace_oracle_error[[1L]]) && abs(v$laplace_oracle_error[[1L]]) < 1e-6 &&
      identical(as.integer(v$convergence[[1L]]), 0L) && isTRUE(v$pdHess[[1L]]) &&
      is.finite(v$max_abs_gradient[[1L]]) && v$max_abs_gradient[[1L]] < 1e-3 &&
      identical(as.character(v$clamp_at_optimum[[1L]]), "ok") &&
      identical(as.character(v$interval_status[[1L]]), "profile") &&
      isFALSE(v$profile_boundary[[1L]]) && (is.na(v$error[[1L]]) || !nzchar(as.character(v$error[[1L]]))) &&
      all(is.finite(c(v$lower[[1L]], v$upper[[1L]]))) && v$lower[[1L]] < v$upper[[1L]]
  }, logical(1L))
  covered <- vapply(seq_along(result), function(j) {
    v <- result[[j]]; !is.null(v) && valid[[j]] && v$lower[[1L]] <= a && v$upper[[1L]] >= a
  }, logical(1L))
  fp <- if (a == 0) vapply(seq_along(result), function(j) {
    v <- result[[j]]; !is.null(v) && valid[[j]] && (v$lower[[1L]] > 0 || v$upper[[1L]] < 0)
  }, logical(1L)) else rep(NA, n)
  covci <- exact_ci(sum(covered), n); fpci <- if (a == 0) exact_ci(sum(fp), n) else c(NA_real_,NA_real_)
  fp_cond_n <- if (a == 0) sum(valid) else NA_integer_
  fp_cond_success <- if (a == 0) sum(fp) else NA_integer_
  fp_cond_ci <- if (a == 0) exact_ci(fp_cond_success,fp_cond_n) else c(NA_real_,NA_real_)
  attempted <- st <- case_state[as.character(ix)]
  attempted <- attempted %in% c("started","completed","error","timeout","campaign_timeout","interrupted")
  attempted_ci <- exact_ci(sum(covered[attempted]), sum(attempted))
  vci <- exact_ci(sum(valid), n); bias <- mean_ci(estimate[fits]-a); ratio <- mean_ci(exp(estimate[fits]-a)-1)
  data.frame(a=a, planned=n, attempted_process=sum(st != "not_started" & st != "launch_error"),
    supervisor_started=sum(st %in% c("started","completed","error","timeout","campaign_timeout","interrupted")),
    supervisor_completed=sum(st == "completed"), worker_errors=sum(st == "error"),
    launch_errors=sum(st == "launch_error"), timeouts=sum(st %in% c("timeout","campaign_timeout")),
    interrupted=sum(st == "interrupted"), nonstarted=sum(st == "not_started"), fit_results=sum(fits),
    healthy_fits=sum(healthy), valid_intervals=sum(valid), coverage_all_success=sum(covered), coverage_all_n=n,
    coverage_all_lo=covci[[1L]], coverage_all_hi=covci[[2L]],
    coverage_attempted_success=sum(covered[attempted]), coverage_attempted_n=sum(attempted),
    coverage_attempted_lo=attempted_ci[[1L]], coverage_attempted_hi=attempted_ci[[2L]],
    coverage_conditional=if(sum(valid)) sum(covered)/sum(valid) else NA_real_, coverage_conditional_n=sum(valid),
    valid_fraction=if(n) sum(valid)/n else NA_real_, valid_fraction_exact_lo=vci[[1L]], valid_fraction_exact_hi=vci[[2L]],
    logsd_bias_mean=bias[[3L]],logsd_bias_mc_lo=bias[[1L]],logsd_bias_mc_hi=bias[[2L]],logsd_bias_n=sum(fits),
    ratio_relative_bias_mean=ratio[[3L]],ratio_relative_bias_mc_lo=ratio[[1L]],ratio_relative_bias_mc_hi=ratio[[2L]],ratio_bias_n=sum(fits),
    false_positive_success=if(a==0) sum(fp) else NA_integer_,false_positive_n=if(a==0)n else NA_integer_,
    false_positive_exact_lo=fpci[[1L]],false_positive_exact_hi=fpci[[2L]],
    false_positive_conditional_success=fp_cond_success,false_positive_conditional_n=fp_cond_n,
    false_positive_conditional_rate=if(a==0 && fp_cond_n>0) fp_cond_success/fp_cond_n else NA_real_,
    false_positive_conditional_exact_lo=fp_cond_ci[[1L]],false_positive_conditional_exact_hi=fp_cond_ci[[2L]],
    campaign_complete=campaign_complete, design_mode=design_mode,
    staged_decision=staged$decision, qualification_eligible=decision_accept,
    qualification_denominator_complete=decision_accept && n==1000L,
    coverage_threshold=decision_accept && gate_state(a,"coverage")=="pass",
    false_positive_threshold=if(a==0) decision_accept && gate_state(0,"false_positive")=="pass" else NA,
    bias_diagnostics_only=TRUE,
    valid_fraction_threshold=decision_accept && gate_state(a,"valid_fraction")=="pass", stringsAsFactors=FALSE)
})
summary <- do.call(rbind, rows)
overall_qualified <- decision_accept
summary$overall_qualified <- overall_qualified
write.csv(summary,file.path(out,"summary.csv"),row.names=FALSE)
writeLines(capture.output(str(staged)), file.path(out,"staged-decision.txt"))
writeLines(c("# Native Bernoulli SD-regression calibration summary","",
  "Bias estimates and intervals are descriptive diagnostics only; they do not enter the staged decision and do not establish point-estimator recovery.",
  paste0("Artifact hashes and exact result/supervisor/manifest identities passed. Campaign complete: ",campaign_complete,"; staged look-1 decision: ",staged$decision,"; overall qualification: ",overall_qualified,"; prepared mode: ",design_mode," (master seed ",master_seed,"). The two-look intervals use 97.5% confidence. Coverage and false-positive intervals use the planned denominator; invalid intervals are noncoverage. Conditional false-positive rate uses valid null intervals only. Bias intervals show finite-fit denominators. Qualification flags can be true only for a complete production look-1 campaign whose staged decision is accept. A staged fail is operational nonqualification, not proof that the method is invalid. Look two is frozen but not authorized or summarized by this first-look adapter."),
  paste0("Summary script source-registry pinned: ",summary_tool_registered,"; summary script SHA-256: ",analysis_script_sha256,"."),
  "",paste(capture.output(print(summary,row.names=FALSE)),collapse="\n"),"",
  "No acceptance claim is made; inspect source hashes, worker logs, warnings, and retained fit diagnostics."),file.path(out,"summary.md"))
analysis_receipt <- list(
  analysis_script_path=analysis_script_path,
  analysis_script_sha256=analysis_script_sha256,
  summary_tool_registered=summary_tool_registered,
  source_registry_sha256=registry_sha,
  manifest_sha256=manifest_sha,
  supervisor_receipt_sha256=digest::digest(receipt_path, algo="sha256", file=TRUE),
  summary_csv_sha256=digest::digest(file.path(out,"summary.csv"), algo="sha256", file=TRUE),
  summary_md_sha256=digest::digest(file.path(out,"summary.md"), algo="sha256", file=TRUE),
  generated_at=format(Sys.time(), tz="UTC", usetz=TRUE))
jsonlite::write_json(analysis_receipt,file.path(out,"summary-tool-receipt.json"),auto_unbox=TRUE,pretty=TRUE)
cat(sprintf("SUMMARY_WRITTEN planned=%d attempted=%d campaign_complete=%s overall_qualified=%s summary_tool_registered=%s\n",length(planned_ix),sum(case_state[as.character(planned_ix)] %in% c("started","completed","error","timeout","campaign_timeout","interrupted")),campaign_complete,overall_qualified,summary_tool_registered))
