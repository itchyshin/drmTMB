#!/usr/bin/env Rscript

# Fail-closed contract for the reader-facing vignette corpus.  The scanner
# operates on source text rather than fit-object names: a private field remains
# private whether it is reached through `fit`, `x`, or another object name.

reader_contract_private_fields <- c(
  "opt", "sdr", "sdpars", "corpars", "optimizer_used", "optimizer_attempts",
  "obj", "model", "missing_data", "random_effects"
)

reader_contract_contributor_permissions <- c(
  "adding-families.Rmd" = "opt",
  "testing-likelihoods.Rmd" = "model",
  "source-map.Rmd" = "model"
)

reader_contract_contributors <- names(reader_contract_contributor_permissions)

reader_contract_expected_exceptions <- data.frame(
  vignette = c(
    "large-data.Rmd",
    "figure-gallery.Rmd",
    "figure-gallery.Rmd",
    "figure-gallery.Rmd"
  ),
  field = c("obj", "model", "model", "model"),
  clause = c(
    "`fit$obj` was intentionally dropped",
    'pred_tail$model <- "Tail weight"',
    'pred_zi$model <- "Structural-zero probability"',
    'pred_rho$model <- "Residual correlation"'
  ),
  rationale = c(
    "Explains the negative case: gradient re-evaluation is unavailable after deliberately dropping the TMB object.",
    "`model` is an ordinary plotting-data column, not a drmTMB fit slot.",
    "`model` is an ordinary plotting-data column, not a drmTMB fit slot.",
    "`model` is an ordinary plotting-data column, not a drmTMB fit slot."
  ),
  stringsAsFactors = FALSE
)

reader_contract_problem <- function(problems, message) {
  c(problems, message)
}

reader_contract_exception_key <- function(records) {
  paste(records$vignette, records$field, records$clause, records$rationale, sep = "\r")
}

reader_contract_exception_label <- function(records) {
  paste0(records$vignette, " $", records$field, " :: ", records$clause)
}

reader_contract_read_csv <- function(path, required_columns) {
  if (!file.exists(path)) {
    stop("Reader-contract file is missing: ", path, call. = FALSE)
  }

  value <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    colClasses = "character",
    na.strings = character()
  )
  missing_columns <- setdiff(required_columns, names(value))
  if (length(missing_columns)) {
    stop(
      "Reader-contract file has no column(s): ",
      paste(missing_columns, collapse = ", "), " in ", path,
      call. = FALSE
    )
  }
  value
}

reader_contract_split_fields <- function(value) {
  if (is.na(value) || !nzchar(trimws(value))) return(character())
  trimws(unlist(strsplit(value, ";", fixed = TRUE), use.names = FALSE))
}

reader_contract_private_accesses <- function(path) {
  lines <- readLines(path, warn = FALSE)
  field_pattern <- paste(reader_contract_private_fields, collapse = "|")
  dollar_pattern <- paste0(
    "\\$\\s*(", field_pattern, ")(?![[:alnum:]_.])"
  )
  bracket_pattern <- paste0(
    "\\[\\[\\s*['\"](",
    field_pattern,
    ")['\"]\\s*\\]\\]"
  )
  # Reader prose can label a private extracted component directly, for example
  # `sdpars$mu`, without spelling `fit$sdpars`.  Recognize those bare and
  # Markdown-backticked routes while requiring a following extraction operator:
  # ordinary prose such as "the model" is not a private-field access.
  route_pattern <- paste0(
    "(?<![[:alnum:]_.])`?(", field_pattern, ")`?\\s*(?=\\$|\\[\\[)"
  )

  access_matches <- function(pattern, line, line_number) {
    locations <- gregexpr(pattern, line, perl = TRUE)[[1L]]
    if (identical(locations, -1L)) return(NULL)
    tokens <- regmatches(line, list(locations))[[1L]]
    fields <- vapply(
      tokens,
      function(token) regmatches(token, regexpr(field_pattern, token, perl = TRUE)),
      character(1)
    )
    field_offsets <- vapply(
      tokens,
      function(token) as.integer(regexpr(field_pattern, token, perl = TRUE)),
      integer(1)
    )
    data.frame(
      line = rep.int(line_number, length(fields)),
      field = fields,
      field_start = as.integer(locations) + field_offsets - 1L,
      text = rep.int(line, length(fields)),
      stringsAsFactors = FALSE
    )
  }

  records <- lapply(seq_along(lines), function(line_number) {
    line <- lines[[line_number]]
    matches <- Filter(
      Negate(is.null),
      list(
        access_matches(dollar_pattern, line, line_number),
        access_matches(bracket_pattern, line, line_number),
        access_matches(route_pattern, line, line_number)
      )
    )
    if (!length(matches)) return(NULL)
    matches <- do.call(rbind, matches)
    # `fit$sdpars$mu` satisfies both the direct-access and route patterns.
    # It is one private access, not two exception candidates.
    matches[!duplicated(matches[c("field", "field_start")]), , drop = FALSE]
  })
  records <- Filter(Negate(is.null), records)
  if (!length(records)) {
    return(data.frame(
      line = integer(), field = character(), field_start = integer(), text = character()
    ))
  }
  records <- do.call(rbind, records)
  records[c("line", "field", "text")]
}

reader_contract_lint <- function(root = ".", contract_dir = file.path(root, "inst", "reader-contracts")) {
  root <- normalizePath(root, mustWork = TRUE)
  vignette_dir <- file.path(root, "vignettes")
  manifest <- reader_contract_read_csv(
    file.path(contract_dir, "vignette-manifest.csv"),
    c("vignette", "audience", "permitted_private_fields", "rationale")
  )
  exceptions <- reader_contract_read_csv(
    file.path(contract_dir, "private-access-exceptions.csv"),
    c("vignette", "field", "clause", "rationale")
  )
  source_vignettes <- sort(basename(list.files(vignette_dir, pattern = "\\.Rmd$", full.names = TRUE)))
  problems <- character()

  if (anyDuplicated(manifest$vignette)) {
    duplicated_names <- unique(manifest$vignette[duplicated(manifest$vignette)])
    problems <- reader_contract_problem(
      problems,
      paste0("Duplicate manifest row(s): ", paste(duplicated_names, collapse = ", "))
    )
  }
  manifest_names <- manifest$vignette
  missing_rows <- setdiff(source_vignettes, manifest_names)
  stale_rows <- setdiff(manifest_names, source_vignettes)
  if (length(missing_rows)) {
    problems <- reader_contract_problem(
      problems,
      paste0("Missing manifest row(s): ", paste(missing_rows, collapse = ", "))
    )
  }
  if (length(stale_rows)) {
    problems <- reader_contract_problem(
      problems,
      paste0("Manifest references absent vignette(s): ", paste(stale_rows, collapse = ", "))
    )
  }
  invalid_audience <- setdiff(unique(manifest$audience), c("reader", "contributor"))
  if (length(invalid_audience)) {
    problems <- reader_contract_problem(
      problems,
      paste0("Invalid audience value(s): ", paste(invalid_audience, collapse = ", "))
    )
  }

  contributor_rows <- manifest$vignette[manifest$audience == "contributor"]
  if (!setequal(contributor_rows, reader_contract_contributors)) {
    problems <- reader_contract_problem(
      problems,
      paste0(
        "Contributor vignette set must be exactly: ",
        paste(reader_contract_contributors, collapse = ", ")
      )
    )
  }

  for (vignette in reader_contract_contributors) {
    manifest_row <- manifest[manifest$vignette == vignette, , drop = FALSE]
    if (nrow(manifest_row) != 1L) next
    declared <- reader_contract_split_fields(manifest_row$permitted_private_fields[[1L]])
    expected <- unname(reader_contract_contributor_permissions[[vignette]])
    if (!identical(declared, expected)) {
      problems <- reader_contract_problem(
        problems,
        paste0(
          "Contributor permission must be exactly ", vignette, " -> ", expected,
          "; found ", paste(declared, collapse = ";")
        )
      )
    }
  }

  for (index in seq_len(nrow(manifest))) {
    fields <- reader_contract_split_fields(manifest$permitted_private_fields[[index]])
    invalid_fields <- setdiff(fields, reader_contract_private_fields)
    if (length(invalid_fields)) {
      problems <- reader_contract_problem(
        problems,
        paste0(
          "Invalid declared private field(s) for ", manifest$vignette[[index]], ": ",
          paste(invalid_fields, collapse = ", ")
        )
      )
    }
    if (manifest$audience[[index]] == "reader" && length(fields)) {
      problems <- reader_contract_problem(
        problems,
        paste0("Reader vignette declares private field(s): ", manifest$vignette[[index]])
      )
    }
    if (manifest$audience[[index]] == "contributor" && !nzchar(trimws(manifest$rationale[[index]]))) {
      problems <- reader_contract_problem(
        problems,
        paste0("Contributor permission has no rationale: ", manifest$vignette[[index]])
      )
    }
  }

  exception_key <- reader_contract_exception_key(exceptions)
  if (anyDuplicated(exception_key)) {
    problems <- reader_contract_problem(problems, "Duplicate private-access exception record(s).")
  }
  expected_exception_key <- reader_contract_exception_key(reader_contract_expected_exceptions)
  missing_exceptions <- setdiff(expected_exception_key, exception_key)
  extra_exceptions <- setdiff(exception_key, expected_exception_key)
  if (length(missing_exceptions)) {
    missing_records <- reader_contract_expected_exceptions[
      match(missing_exceptions, expected_exception_key), , drop = FALSE
    ]
    problems <- reader_contract_problem(
      problems,
      paste0(
        "Approved private-access exception record(s) missing: ",
        paste(reader_contract_exception_label(missing_records), collapse = " | ")
      )
    )
  }
  if (length(extra_exceptions)) {
    extra_records <- exceptions[match(extra_exceptions, exception_key), , drop = FALSE]
    problems <- reader_contract_problem(
      problems,
      paste0(
        "Unauthorized private-access exception record(s): ",
        paste(reader_contract_exception_label(extra_records), collapse = " | ")
      )
    )
  }
  for (index in seq_len(nrow(exceptions))) {
    exception <- exceptions[index, , drop = FALSE]
    if (!(exception$vignette[[1L]] %in% source_vignettes)) {
      problems <- reader_contract_problem(
        problems,
        paste0("Exception references absent vignette: ", exception$vignette[[1L]])
      )
    }
    if (!(exception$field[[1L]] %in% reader_contract_private_fields)) {
      problems <- reader_contract_problem(
        problems,
        paste0("Invalid exception private field: ", exception$field[[1L]])
      )
    }
    audience <- manifest$audience[match(exception$vignette[[1L]], manifest$vignette)]
    if (length(audience) && identical(audience, "contributor")) {
      problems <- reader_contract_problem(
        problems,
        paste0("Contributor vignette must not use a reader exception: ", exception$vignette[[1L]])
      )
    }
    if (!nzchar(trimws(exception$clause[[1L]])) || !nzchar(trimws(exception$rationale[[1L]]))) {
      problems <- reader_contract_problem(
        problems,
        paste0("Private-access exception needs a clause and rationale: ", exception$vignette[[1L]])
      )
    }
  }

  for (vignette in intersect(source_vignettes, manifest_names)) {
    manifest_row <- manifest[match(vignette, manifest$vignette), , drop = FALSE]
    accesses <- reader_contract_private_accesses(file.path(vignette_dir, vignette))
    declared <- reader_contract_split_fields(manifest_row$permitted_private_fields[[1L]])
    used_declared <- character()

    if (manifest_row$audience[[1L]] == "contributor") {
      undeclared <- accesses[!(accesses$field %in% declared), , drop = FALSE]
      used_declared <- unique(accesses$field)
      if (nrow(undeclared)) {
        problems <- reader_contract_problem(
          problems,
          paste0(
            "Undeclared private access in ", vignette, " line ", undeclared$line[[1L]],
            ": ", undeclared$field[[1L]]
          )
        )
      }
      unused <- setdiff(declared, used_declared)
      if (length(unused)) {
        problems <- reader_contract_problem(
          problems,
          paste0("Unused contributor permission in ", vignette, ": ", paste(unused, collapse = ", "))
        )
      }
      next
    }

    vignette_exceptions <- exceptions[exceptions$vignette == vignette, , drop = FALSE]
    matched_accesses <- logical(nrow(accesses))
    for (index in seq_len(nrow(vignette_exceptions))) {
      exception <- vignette_exceptions[index, , drop = FALSE]
      candidates <- which(
        accesses$field == exception$field[[1L]] &
          vapply(accesses$text, function(text) {
            grepl(exception$clause[[1L]], text, fixed = TRUE)
          }, logical(1))
      )
      if (length(candidates) != 1L) {
        problems <- reader_contract_problem(
          problems,
          paste0("Stale or ambiguous private-access exception in ", vignette, ": ", exception$field[[1L]])
        )
      } else {
        matched_accesses[[candidates]] <- TRUE
      }
    }
    undeclared <- accesses[!matched_accesses, , drop = FALSE]
    if (nrow(undeclared)) {
      problems <- reader_contract_problem(
        problems,
        paste0(
          "Undeclared private access in ", vignette, " line ", undeclared$line[[1L]],
          ": ", undeclared$field[[1L]]
        )
      )
    }
  }

  unique(problems)
}

reader_contract_check <- function(root = ".", contract_dir = file.path(root, "inst", "reader-contracts")) {
  problems <- reader_contract_lint(root = root, contract_dir = contract_dir)
  if (length(problems)) {
    stop(paste(c("Reader vignette contract failed:", paste0("- ", problems)), collapse = "\n"), call. = FALSE)
  }
  invisible(TRUE)
}

if (identical(environment(), globalenv()) && !interactive()) {
  reader_contract_check()
  message("Reader vignette contract: OK")
}
