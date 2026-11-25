#' Validate and store capture histories for conditional CJS models
#'
#' @param histories Numeric/logical encounter matrix, individuals in rows and
#'   ordered occasions in columns. `NA` is allowed only where `observed` is
#'   `FALSE`.
#' @param id Optional unique individual identifiers.
#' @param observed Optional logical matrix marking surveyed encounters.
#' @param occasions Strictly increasing numeric occasion values. Their
#'   differences define occasion order; use `intervals` to supply model-time
#'   lengths independently.
#' @param intervals Positive finite interval lengths between occasions.
#' @param units Non-empty string naming the time unit used by `intervals`,
#'   such as `"years"`. Interval lengths are already expressed in this unit.
#' @param end Optional 1-based administrative endpoint per individual. It is
#'   follow-up truncation, never the last sighting.
#' @param frequency Positive integer history replication counts.
#' @return A validated `cmr_data` object.
#' @export
cmr_data <- function(histories, id = NULL, observed = NULL,
                     occasions = NULL, intervals = NULL, units = "occasion", end = NULL,
                     frequency = 1L) {
  y <- as.matrix(histories)
  if (length(dim(y)) != 2L || nrow(y) < 1L || ncol(y) < 1L)
    stop("`histories` must be a non-empty individuals-by-occasions matrix.", call. = FALSE)
  if (!is.numeric(y) && !is.logical(y))
    stop("`histories` must contain only 0, 1, or masked NA values.", call. = FALSE)
  if (any(!is.na(y) & !(y %in% c(0, 1))))
    stop("`histories` must contain only 0, 1, or masked NA values.", call. = FALSE)
  n <- nrow(y); nt <- ncol(y)
  if (is.null(id)) id <- if (is.null(rownames(y))) seq_len(n) else rownames(y)
  if (length(id) != n || anyNA(id) || anyDuplicated(id))
    stop("`id` must contain one unique, non-missing value per individual.", call. = FALSE)
  if (is.null(observed)) observed <- matrix(TRUE, nrow(y), ncol(y))
  observed <- as.matrix(observed)
  if (!is.logical(observed) || !identical(dim(observed), dim(y)) || anyNA(observed))
    stop("`observed` must be a non-missing logical matrix matching `histories`.", call. = FALSE)
  if (any(observed & is.na(y)))
    stop("an observed encounter cannot be missing; mark it unobserved explicitly.", call. = FALSE)
  if (any(!observed & !is.na(y) & y == 1))
    stop("a capture cannot be marked unobserved.", call. = FALSE)
  if (is.null(occasions)) occasions <- seq_len(nt)
  if (length(occasions) != nt || !is.numeric(occasions) || any(!is.finite(occasions)) ||
      (nt > 1L && any(diff(occasions) <= 0)))
    stop("`occasions` must be finite and strictly increasing.", call. = FALSE)
  if (is.null(intervals)) intervals <- diff(occasions)
  if (length(intervals) != nt - 1L || !is.numeric(intervals) ||
      any(!is.finite(intervals)) || any(intervals <= 0))
    stop("`intervals` must contain one positive finite value between each pair of occasions.", call. = FALSE)
  if (length(units) != 1L || !is.character(units) || is.na(units) ||
      !nzchar(trimws(units)))
    stop("`units` must be one non-empty character label, such as 'years'.", call. = FALSE)
  units <- trimws(units)
  y[!observed] <- 0L
  y <- matrix(as.integer(y), nrow = n, ncol = nt, dimnames = dimnames(histories))
  first <- apply(ifelse(observed, y, 0L), 1L, function(z) {
    w <- which(z == 1L); if (length(w)) w[[1L]] else NA_integer_
  })
  if (anyNA(first)) stop("all-zero capture histories are not valid CJS data.", call. = FALSE)
  if (is.null(end)) end <- rep.int(nt, n)
  if (length(end) != n || anyNA(end) || any(end != as.integer(end)) ||
      any(end < first) || any(end > nt))
    stop("`end` must give a valid 1-based administrative endpoint for each individual.", call. = FALSE)
  if (any(vapply(seq_len(n), function(i) {
    end[i] < nt && any(y[i, seq.int(end[i] + 1L, nt)] == 1L)
  }, logical(1))))
    stop("a capture cannot occur after the administrative endpoint.", call. = FALSE)
  if (length(frequency) == 1L) frequency <- rep(frequency, n)
  if (!is.numeric(frequency) || length(frequency) != n || anyNA(frequency) || any(!is.finite(frequency)) ||
      any(frequency < 1) || any(frequency != as.integer(frequency)))
    stop("`frequency` must contain positive integer replication counts.", call. = FALSE)
  delta <- matrix(rep(intervals, each = n), nrow = n, ncol = max(nt - 1L, 0L))
  structure(list(y = y, observed = observed, id = id, occasions = occasions,
                 units = units, first = as.integer(first), end = as.integer(end),
                 delta = delta, frequency = as.integer(frequency)), class = "cmr_data")
}
