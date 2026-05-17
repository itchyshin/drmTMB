phase18_named_pair <- function(x, expected, name) {
  if (!is.numeric(x) || length(x) != 2L || any(!is.finite(x))) {
    stop(
      "`",
      name,
      "` must be a finite numeric vector of length 2.",
      call. = FALSE
    )
  }
  current <- names(x)
  if (is.null(current) || any(!nzchar(current))) {
    names(x) <- expected
    return(x)
  }
  if (!setequal(current, expected)) {
    stop(
      "`",
      name,
      "` must be unnamed or named with ",
      paste(expected, collapse = " and "),
      ".",
      call. = FALSE
    )
  }
  x[expected]
}

assert_phase18_correlation <- function(x, name) {
  ok <- is.numeric(x) &&
    length(x) == 1L &&
    is.finite(x) &&
    abs(x) < 1
  if (!ok) {
    stop(
      "`",
      name,
      "` must be one finite number with absolute value below 1.",
      call. = FALSE
    )
  }
  invisible(x)
}

assert_phase18_positive_number <- function(x, name) {
  ok <- is.numeric(x) &&
    length(x) == 1L &&
    is.finite(x) &&
    x > 0
  if (!ok) {
    stop("`", name, "` must be one positive finite number.", call. = FALSE)
  }
  invisible(x)
}

phase18_with_seed <- function(seed, code) {
  assert_positive_whole_number(seed, "seed")
  old_seed <- if (
    exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  ) {
    get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  } else {
    NULL
  }
  on.exit(
    {
      if (is.null(old_seed)) {
        rm(list = ".Random.seed", envir = .GlobalEnv)
      } else {
        assign(".Random.seed", old_seed, envir = .GlobalEnv)
      }
    },
    add = TRUE
  )

  set.seed(seed)
  code()
}
