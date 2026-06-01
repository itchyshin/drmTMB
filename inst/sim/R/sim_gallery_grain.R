phase18_gallery_can_draw_replicate_cloud <- function(
  data,
  required_columns = character()
) {
  if (!is.data.frame(data) || nrow(data) == 0L) {
    return(FALSE)
  }
  if (!all(required_columns %in% names(data))) {
    return(FALSE)
  }

  has_artifact_grain <- "artifact_grain" %in% names(data)
  has_cloud_gate <- "replicate_cloud_gate" %in% names(data)
  if (!has_artifact_grain && !has_cloud_gate) {
    return(FALSE)
  }

  artifact_ready <- if (has_artifact_grain) {
    phase18_gallery_all_values(
      data$artifact_grain,
      "replicate"
    )
  } else {
    TRUE
  }
  gate_ready <- if (has_cloud_gate) {
    phase18_gallery_all_values(
      data$replicate_cloud_gate,
      "replicate_clouds_allowed"
    )
  } else {
    TRUE
  }

  artifact_ready && gate_ready
}

phase18_gallery_all_values <- function(x, value) {
  x <- as.character(x)
  isTRUE(all(!is.na(x) & nzchar(x) & x == value))
}
