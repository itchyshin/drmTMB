# Gate oracles for parity leaf A5 (ordinary random effects through the bridge).
# Reads the TSVs census.R / parity_ordinary_re.R wrote and asserts the ledger's
# observable outcomes. Usage: Rscript check_gates.R <G1|G2|G3|G4> [dir]
# Prints "<gate> OK" and exits 0, or names the first violation and exits 1.
# Every check is a positive assertion on rows that must EXIST: an empty table
# is a failure, never a pass.

args <- commandArgs(trailingOnly = TRUE)
gate <- if (length(args) >= 1L) args[[1]] else stop("gate id required")
dir <- if (length(args) >= 2L) args[[2]] else dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
PIN <- "430ef64ccca5642c5abebd72194e00895314dfc2"
fail <- function(...) { cat(gate, "FAIL:", sprintf(...), "\n"); quit(status = 1L) }
read_tsv <- function(name) {
  p <- file.path(dir, name)
  if (!file.exists(p)) fail("missing %s", p)
  utils::read.delim(p, stringsAsFactors = FALSE, quote = "", check.names = FALSE, na.strings = "NA")
}
shapes <- c("gaussian_random_intercept", "gaussian_random_slope", "gaussian_sigma_random_intercept")
cell_ids <- c(gaussian_random_intercept.ML = "ordre_gaussian_random_intercept_ml",
              gaussian_random_intercept.REML = "ordre_gaussian_random_intercept_reml",
              gaussian_random_slope.ML = "ordre_gaussian_random_slope_ml",
              gaussian_random_slope.REML = "ordre_gaussian_random_slope_reml",
              gaussian_sigma_random_intercept.ML = "ordre_gaussian_sigma_random_intercept_ml",
              gaussian_sigma_random_intercept.REML = "ordre_gaussian_sigma_random_intercept_reml")
ENGINE_PHRASE <- "method = :REML is not implemented for this model on the generic univariate Gaussian route"
ledger_ids <- c(gaussian_random_intercept = "gaussian_random_intercept_mu", gaussian_random_slope = "gaussian_random_slope_mu",
                gaussian_sigma_random_intercept = "gaussian_sigma_random_intercept")
R_PHRASE <- "does not support `method = \"REML\"` with a random intercept on `sigma`"

census <- read_tsv("census.tsv")
if (nrow(census) == 0L) fail("census.tsv is empty")
if (!all(census$drmjl_ref == PIN)) fail("census rows not all at pin %s", PIN)

if (gate == "G1") {
  for (layer in c("shipped", "engine-direct")) for (sh in shapes) for (m in c("ML", "REML")) {
    r <- census[census$layer == layer & census$shape == sh & census$requested == m, ]
    if (nrow(r) != 1L) fail("expected exactly one row for %s/%s/%s, found %d", layer, sh, m, nrow(r))
    if (!r$verdict %in% c("FITS", "REFUSED", "DOWNGRADED", "NO_ESTIM_METHOD_REPORTED")) fail("bad verdict %s", r$verdict)
    if (r$verdict == "FITS") {
      if (is.na(r$estim_method) || r$estim_method != m) fail("%s/%s/%s FITS without matching estim_method", layer, sh, m)
      if (!is.finite(r$ml_loglik)) fail("%s/%s/%s FITS without finite ml_loglik", layer, sh, m)
      if (m == "REML" && !is.finite(r$reml_loglik)) fail("%s/%s/%s REML FITS without finite reml_loglik", layer, sh, m)
    }
    if (r$verdict == "REFUSED" && (is.na(r$message) || !nzchar(r$message))) fail("%s/%s/%s REFUSED without a message", layer, sh, m)
  }
  if (nrow(census) != 12L) fail("expected 12 census rows, found %d", nrow(census))
  n_fits <- sum(census$verdict == "FITS"); n_ref <- sum(census$verdict == "REFUSED")
  cat(sprintf("G1 OK: 12 cells (2 layers x 3 shapes x 2 methods); FITS=%d REFUSED=%d DOWNGRADED=%d\n",
              n_fits, n_ref, sum(census$verdict == "DOWNGRADED")))
}

if (gate == "G2") {
  fx <- read_tsv("parity-fixtures-ordinary-re.tsv"); se <- read_tsv("parity-se-ordinary-re.tsv")
  if (nrow(fx) == 0L || nrow(se) == 0L) fail("parity tables empty")
  if (!all(fx$drmjl_ref == PIN) || !all(se$drmjl_ref == PIN)) fail("parity rows not all at pin")
  verified <- census[census$layer == "shipped" & census$verdict == "FITS", ]
  if (nrow(verified) == 0L) fail("no verified cells to compare")
  n <- 0L
  for (i in seq_len(nrow(verified))) {
    id <- cell_ids[[paste(verified$shape[i], verified$requested[i], sep = ".")]]
    f <- fx[fx$cell_id == id, ]; s <- se[se$cell_id == id, ]
    if (nrow(f) != 1L) fail("no fixture row for verified cell %s", id)
    if (nrow(s) != 1L) fail("no SE row for verified cell %s", id)
    if (!f$status %in% c("PARITY_PASS", "PARITY_FAIL")) fail("%s fixture status %s is not a measurement", id, f$status)
    if (!is.finite(f$max_abs_coef_diff) || !is.finite(f$loglik_diff)) fail("%s fixture row lacks measured numbers", id)
    if (!s$status %in% c("SE_PASS", "SE_FAIL")) fail("%s SE status %s is not a measurement", id, s$status)
    if (!is.finite(s$max_rel_se_diff)) fail("%s SE row lacks measured numbers", id)
    if (identical(f$reml, TRUE) != identical(verified$requested[i], "REML")) fail("%s reml flag mismatch", id)
    n <- n + 1L
  }
  nc <- se[se$cell_id == "negative_control_perturbed", ]
  if (nrow(nc) != 1L || nc$status != "NEGATIVE_CONTROL_OK") fail("SE negative control missing or not OK")
  cat(sprintf("G2 OK: %d verified cells each carry a fixture row and an SE row (PASS=%d FAIL=%d); SE negative control rejects\n",
              n, sum(fx$status == "PARITY_PASS"), sum(fx$status == "PARITY_FAIL")))
}

if (gate == "G3") {
  led <- read_tsv("ledger.tsv")
  need <- c("capability_id","route","syntax","r_bridge_status","drmjl_status","claim_status","evidence_url","claim_boundary","next_action","issue")
  if (!identical(names(led), need)) fail("ledger.tsv columns differ from the registry")
  if (nrow(led) != length(shapes)) fail("expected %d ledger rows, found %d", length(shapes), nrow(led))
  if (!all(nzchar(led$claim_boundary))) fail("empty claim_boundary")
  if (!all(grepl(PIN, led$claim_boundary, fixed = TRUE))) fail("a claim_boundary does not name the pin")
  for (sh in shapes) {
    row <- led[led$capability_id == ledger_ids[[sh]], ]
    if (nrow(row) != 1L) fail("no ledger row for %s", sh)
    eng_ref <- census[census$layer == "engine-direct" & census$shape == sh & census$verdict == "REFUSED", ]
    if (nrow(eng_ref) > 0L && !grepl(ENGINE_PHRASE, row$claim_boundary, fixed = TRUE))
      fail("%s: engine refused REML but claim_boundary does not quote the engine's message", sh)
    ship_ref <- census[census$layer == "shipped" & census$shape == sh & census$verdict == "REFUSED", ]
    if (nrow(ship_ref) > 0L && !grepl("REML: UNSUPPORTED", row$claim_boundary, fixed = TRUE))
      fail("%s: shipped bridge refused REML but claim_boundary does not say REML: UNSUPPORTED", sh)
    if (sh == "gaussian_sigma_random_intercept" && !grepl(R_PHRASE, row$claim_boundary, fixed = TRUE))
      fail("%s: drmTMB's own pre-Julia refusal message not quoted", sh)
    fits <- census[census$layer == "shipped" & census$shape == sh & census$verdict == "FITS", ]
    for (j in seq_len(nrow(fits))) {
      m <- fits$requested[j]
      if (!grepl(paste0(m, ": SUPPORTED"), row$claim_boundary, fixed = TRUE))
        fail("%s: verified %s cell not recorded as SUPPORTED in claim_boundary", sh, m)
      # the numbers quoted in the boundary must be the census's own, verbatim
      for (v in c(fits$ml_loglik[j], if (m == "REML") fits$reml_loglik[j])) {
        if (!grepl(format(v, digits = 15), row$claim_boundary, fixed = TRUE))
          fail("%s/%s: claim_boundary does not quote the measured value %s verbatim", sh, m, format(v, digits = 15))
      }
    }
  }
  cat(sprintf("G3 OK: %d registry-shaped rows; every refused cell's boundary quotes the engine's message; every verified cell is recorded\n", nrow(led)))
}

if (gate == "G4") {
  bad <- census[census$ledger == "SUPPORTED" & !(census$verdict == "FITS" & !is.na(census$estim_method) & census$estim_method == census$requested), ]
  if (nrow(bad) > 0L) fail("%d cell(s) recorded SUPPORTED without estim_method == requested: %s",
                           nrow(bad), paste(bad$layer, bad$shape, bad$requested, collapse = "; "))
  down <- census[census$verdict != "FITS" & census$ledger != "UNSUPPORTED", ]
  if (nrow(down) > 0L) fail("%d non-FITS cell(s) not recorded UNSUPPORTED", nrow(down))
  reml_req <- census[census$requested == "REML", ]
  if (nrow(reml_req) == 0L) fail("no REML-requested cells")
  led <- read_tsv("ledger.tsv")
  for (sh in shapes) {
    r <- census[census$layer == "shipped" & census$shape == sh & census$requested == "REML", ]
    row <- led[led$capability_id == ledger_ids[[sh]], ]
    if (nrow(row) != 1L) fail("no ledger row for %s", sh)
    if (r$verdict != "FITS" && !grepl("REML: UNSUPPORTED", row$claim_boundary, fixed = TRUE)) fail("%s REML not FITS yet ledger row does not say UNSUPPORTED", sh)
    if (r$verdict == "FITS" && !grepl("REML: SUPPORTED", row$claim_boundary, fixed = TRUE)) fail("%s REML FITS but ledger row does not say SUPPORTED", sh)
  }
  cat(sprintf("G4 OK: %d SUPPORTED cells all have estim_method == requested; %d non-FITS cells all UNSUPPORTED; no requested-REML/got-ML cell exists\n",
              sum(census$ledger == "SUPPORTED"), sum(census$verdict != "FITS")))
}
