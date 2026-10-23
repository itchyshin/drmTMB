# Null-default operator. Base R only exports `%||%` from 4.4.0, but the
# package declares R >= 4.1.0, so keep an internal copy with the same
# definition. Only NULL is replaced; empty vectors and NA are kept.
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
