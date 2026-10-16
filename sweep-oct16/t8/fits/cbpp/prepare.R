chr_factor <- function(x) {
  x <- as.character(x)
  if (length(x) && all(grepl("^[0-9]+$", x))) x <- paste0("g", x)
  factor(x, levels = sort(unique(x)))
}
data(cbpp, package = "lme4")
d <- lme4::cbpp
d$herd <- chr_factor(d$herd)
d$period <- chr_factor(d$period)
d$fail <- d$size - d$incidence
