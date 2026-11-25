cmr_profile_target_result <- function(interval) {
  if (!is.matrix(interval) || nrow(interval) != 1L ||
      !all(c("lower", "upper") %in% colnames(interval)))
    stop("profile result must be a one-row matrix with lower and upper columns.", call. = FALSE)
  target_status <- attr(interval, "target_status")
  status <- if (is.null(target_status) || !length(target_status)) {
    "status_unavailable"
  } else if (is.matrix(target_status) || is.data.frame(target_status)) {
    as.character(target_status[1L, 1L])
  } else {
    as.character(target_status[[1L]])
  }
  list(status = status,
       lower = unname(as.numeric(interval[1L, "lower"])),
       upper = unname(as.numeric(interval[1L, "upper"])))
}
